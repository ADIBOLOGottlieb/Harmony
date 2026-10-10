<?php

namespace App\Services\Gallery;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/** Erreur métier de la galerie, rendue en JSON avec un code stable pour l'app. */
class GalleryException extends RuntimeException
{
    public function __construct(string $message, public readonly string $errorCode, public readonly int $status = 422)
    {
        parent::__construct($message);
    }

    public static function unavailable(): self
    {
        return new self(__('Cette œuvre vient d’être réservée ou vendue.'), 'artwork_unavailable', 409);
    }

    public static function addressRequired(): self
    {
        return new self(__('Indiquez l’adresse de livraison.'), 'address_required');
    }

    public static function notCancellable(): self
    {
        return new self(__('Cette demande ne peut plus être annulée.'), 'not_cancellable', 409);
    }

    public function render(): JsonResponse
    {
        return response()->json(['message' => $this->getMessage(), 'code' => $this->errorCode], $this->status);
    }
}
