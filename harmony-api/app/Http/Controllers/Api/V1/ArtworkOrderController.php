<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DeliveryMethod;
use App\Http\Controllers\Controller;
use App\Http\Requests\ArtworkOrderRequest;
use App\Http\Resources\ArtworkOrderResource;
use App\Models\Artwork;
use App\Models\ArtworkOrder;
use App\Services\Gallery\GalleryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

/** Acquisitions d'œuvres par le client connecté. */
class ArtworkOrderController extends Controller
{
    public function __construct(private GalleryService $gallery) {}

    public function store(ArtworkOrderRequest $request, Artwork $artwork): JsonResponse
    {
        abort_unless($artwork->published, 404);

        $order = $this->gallery->order(
            $request->user(),
            $artwork,
            DeliveryMethod::from($request->validated('delivery_method')),
            $request->validated('delivery_address'),
            $request->validated('note'),
        );

        return (new ArtworkOrderResource($order->load('artwork.artist')))->response()->setStatusCode(201);
    }

    public function index(Request $request): AnonymousResourceCollection
    {
        $this->gallery->releaseExpired();

        return ArtworkOrderResource::collection(
            ArtworkOrder::query()->where('user_id', $request->user()->id)->with('artwork.artist')->latest()->get()
        );
    }

    public function cancel(ArtworkOrder $order): ArtworkOrderResource
    {
        Gate::authorize('cancel', $order);

        return new ArtworkOrderResource($this->gallery->cancel($order, 'cancelled_by_client')->load('artwork.artist'));
    }
}
