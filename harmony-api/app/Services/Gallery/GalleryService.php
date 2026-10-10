<?php

namespace App\Services\Gallery;

use App\Enums\ArtworkOrderStatus;
use App\Enums\ArtworkStatus;
use App\Enums\DeliveryMethod;
use App\Models\Artwork;
use App\Models\ArtworkOrder;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

/**
 * Ventes de la galerie. Une demande d'acquisition réserve l'œuvre au client pendant
 * `harmony.gallery.hold_hours` ; la conciergerie confirme le règlement (œuvre vendue)
 * ou annule (œuvre de nouveau disponible).
 */
class GalleryService
{
    private const REFERENCE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    public function order(User $user, Artwork $artwork, DeliveryMethod $delivery, ?string $address, ?string $note): ArtworkOrder
    {
        if ($delivery === DeliveryMethod::Delivery && blank($address)) {
            throw GalleryException::addressRequired();
        }

        try {
            return DB::transaction(function () use ($user, $artwork, $delivery, $address, $note) {
                $this->releaseExpired($artwork->id);
                $locked = Artwork::query()->whereKey($artwork->id)->lockForUpdate()->firstOrFail();
                if (! $locked->published || $locked->status !== ArtworkStatus::Available) {
                    throw GalleryException::unavailable();
                }

                $fee = $delivery === DeliveryMethod::Delivery ? (int) config('harmony.gallery.delivery_fee') : 0;
                $order = ArtworkOrder::query()->create([
                    'reference' => $this->newReference(),
                    'artwork_id' => $locked->id,
                    'user_id' => $user->id,
                    'status' => ArtworkOrderStatus::Pending,
                    'price' => $locked->price,
                    'delivery_method' => $delivery,
                    'delivery_fee' => $fee,
                    'total' => $locked->price + $fee,
                    'delivery_address' => $delivery === DeliveryMethod::Delivery ? trim((string) $address) : null,
                    'note' => filled($note) ? trim((string) $note) : null,
                    'expires_at' => now()->addHours((int) config('harmony.gallery.hold_hours')),
                ]);
                $locked->update(['status' => ArtworkStatus::Reserved]);

                return $order;
            });
        } catch (QueryException $e) {
            // Index unique partiel : une autre demande active existe déjà pour cette œuvre.
            if (in_array($e->getCode(), ['23505', '23000'], true)) {
                throw GalleryException::unavailable();
            }

            throw $e;
        }
    }

    public function cancel(ArtworkOrder $order, string $reason): ArtworkOrder
    {
        if ($order->status !== ArtworkOrderStatus::Pending) {
            throw GalleryException::notCancellable();
        }

        DB::transaction(function () use ($order, $reason) {
            $order->update([
                'status' => ArtworkOrderStatus::Cancelled,
                'cancelled_at' => now(),
                'cancel_reason' => $reason,
            ]);
            Artwork::query()->whereKey($order->artwork_id)->where('status', ArtworkStatus::Reserved)
                ->update(['status' => ArtworkStatus::Available]);
        });

        return $order->refresh();
    }

    /** Règlement reçu par la galerie : l'œuvre est vendue. */
    public function markPaid(ArtworkOrder $order, User $staff): ArtworkOrder
    {
        if ($order->status !== ArtworkOrderStatus::Pending) {
            throw GalleryException::notCancellable();
        }

        DB::transaction(function () use ($order, $staff) {
            $order->update([
                'status' => ArtworkOrderStatus::Paid,
                'paid_at' => now(),
                'expires_at' => null,
                'handled_by' => $staff->id,
            ]);
            Artwork::query()->whereKey($order->artwork_id)->update(['status' => ArtworkStatus::Sold]);
        });

        return $order->refresh();
    }

    /** Libère les œuvres dont la réservation n'a pas été réglée à temps. */
    public function releaseExpired(?int $artworkId = null): int
    {
        $expired = ArtworkOrder::query()
            ->where('status', ArtworkOrderStatus::Pending)
            ->where('expires_at', '<=', now())
            ->when($artworkId, fn ($q) => $q->where('artwork_id', $artworkId));

        $artworkIds = (clone $expired)->pluck('artwork_id');
        if ($artworkIds->isEmpty()) {
            return 0;
        }

        $count = $expired->update([
            'status' => ArtworkOrderStatus::Cancelled,
            'cancelled_at' => now(),
            'cancel_reason' => 'expired',
        ]);
        Artwork::query()->whereIn('id', $artworkIds)->where('status', ArtworkStatus::Reserved)
            ->update(['status' => ArtworkStatus::Available]);

        return $count;
    }

    private function newReference(): string
    {
        do {
            $suffix = '';
            for ($i = 0; $i < 6; $i++) {
                $suffix .= self::REFERENCE_ALPHABET[random_int(0, strlen(self::REFERENCE_ALPHABET) - 1)];
            }
            $reference = 'GA-'.$suffix;
        } while (ArtworkOrder::query()->where('reference', $reference)->exists());

        return $reference;
    }
}
