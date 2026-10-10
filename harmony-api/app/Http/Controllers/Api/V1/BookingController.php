<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\BookingStatus;
use App\Enums\PaymentKind;
use App\Enums\PaymentMethod;
use App\Enums\StayType;
use App\Http\Controllers\Controller;
use App\Http\Requests\BookingRequest;
use App\Http\Requests\ReviewRequest;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use App\Services\Booking\BookingException;
use App\Services\Booking\BookingService;
use App\Services\Payments\PaymentService;
use App\Services\Reviews\ReviewService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\Response;

class BookingController extends Controller
{
    public function __construct(private BookingService $bookings, private PaymentService $payments) {}

    /** Devis sans engagement (public) : prix, frais, acompte, caution. */
    public function quote(BookingRequest $request): JsonResponse
    {
        $quote = $this->bookings->quote($request->apartment(), $request->window(), (int) $request->validated('guests'));

        return response()->json(['data' => $quote->toArray()]);
    }

    /** Création de la réservation et lancement du premier paiement (acompte, ou totalité pour un séjour court). */
    public function store(BookingRequest $request): JsonResponse
    {
        $window = $request->window();
        $method = PaymentMethod::from($request->validated('payment_method'));

        $booking = $this->bookings->create(
            $request->user(), $request->apartment(), $window, (int) $request->validated('guests'), $method,
        );

        $kind = $window->type === StayType::Night ? PaymentKind::Advance : PaymentKind::Full;
        $this->payments->start($booking, $kind, $method);

        return (new BookingResource($booking->load(['apartment.zone', 'payments', 'review'])))
            ->response()
            ->setStatusCode(201);
    }

    public function index(Request $request): AnonymousResourceCollection
    {
        // Sans planificateur (hébergement gratuit) : statuts mis à jour à la consultation.
        $this->bookings->expireStale();
        $this->bookings->completeFinished();

        $bookings = Booking::query()
            ->where('user_id', $request->user()->id)
            ->with(['apartment.zone', 'payments', 'review'])
            ->latest('start_at')
            ->get();

        return BookingResource::collection($bookings);
    }

    public function show(Booking $booking): BookingResource
    {
        Gate::authorize('view', $booking);

        return new BookingResource($booking->load(['apartment.zone', 'payments', 'review']));
    }

    public function cancel(Booking $booking): BookingResource
    {
        Gate::authorize('cancel', $booking);

        $booking = $this->bookings->cancel($booking, 'cancelled_by_guest');

        return new BookingResource($booking->load(['apartment.zone', 'payments', 'review']));
    }

    /** Paiement du solde d'une réservation confirmée. */
    public function payBalance(Request $request, Booking $booking): BookingResource
    {
        Gate::authorize('pay', $booking);
        $data = $request->validate(['payment_method' => ['required', Rule::enum(PaymentMethod::class)]]);

        if ($booking->status !== BookingStatus::Confirmed) {
            throw BookingException::nothingToPay();
        }

        $this->payments->start($booking, PaymentKind::Balance, PaymentMethod::from($data['payment_method']));

        return new BookingResource($booking->refresh()->load(['apartment.zone', 'payments', 'review']));
    }

    /** Avis du client sur un séjour terminé (modéré avant publication). */
    public function review(ReviewRequest $request, Booking $booking, ReviewService $reviews): BookingResource
    {
        Gate::authorize('review', $booking);
        $reviews->submit($booking, (int) $request->validated('rating'), $request->validated('comment'));

        return new BookingResource($booking->refresh()->load(['apartment.zone', 'payments', 'review']));
    }

    /** Reçu PDF avec la référence unique. */
    public function receipt(Booking $booking): Response
    {
        Gate::authorize('view', $booking);

        return Pdf::loadView('receipts.booking', ['booking' => $booking->load(['apartment.zone', 'user', 'payments'])])
            ->download("recu-{$booking->reference}.pdf");
    }
}
