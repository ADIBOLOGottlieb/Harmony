<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\ArtworkStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\ArtworkIndexRequest;
use App\Http\Resources\ArtistResource;
use App\Http\Resources\ArtworkResource;
use App\Models\Artist;
use App\Models\Artwork;
use App\Services\Gallery\GalleryService;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/** Galerie publique : artistes et œuvres publiées. */
class GalleryController extends Controller
{
    public function __construct(private GalleryService $gallery) {}

    public function artists(): AnonymousResourceCollection
    {
        return ArtistResource::collection(
            Artist::query()->withCount(['artworks' => fn ($q) => $q->published()])->orderBy('name')->get()
        );
    }

    public function index(ArtworkIndexRequest $request): AnonymousResourceCollection
    {
        $this->gallery->releaseExpired();

        $artworks = Artwork::query()->published()
            ->with(['artist', 'photos'])
            ->when($request->validated('artist'), fn ($q, $slug) => $q->whereHas('artist', fn ($a) => $a->where('slug', $slug)))
            ->when($request->boolean('available'), fn ($q) => $q->where('status', ArtworkStatus::Available))
            ->when($request->validated('max_price'), fn ($q, $max) => $q->where('price', '<=', $max))
            // Disponibles d'abord, puis à la une, puis les plus récentes.
            ->orderByRaw("CASE status WHEN 'available' THEN 0 WHEN 'reserved' THEN 1 ELSE 2 END")
            ->orderByDesc('featured')
            ->latest()
            ->get();

        return ArtworkResource::collection($artworks);
    }

    public function show(Artwork $artwork): ArtworkResource
    {
        abort_unless($artwork->published, 404);
        $this->gallery->releaseExpired($artwork->id);

        return new ArtworkResource($artwork->refresh()->load(['artist', 'photos']));
    }
}
