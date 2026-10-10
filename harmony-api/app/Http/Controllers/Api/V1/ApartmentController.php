<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ApartmentIndexRequest;
use App\Http\Resources\ApartmentResource;
use App\Models\Apartment;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ApartmentController extends Controller
{
    public function index(ApartmentIndexRequest $request): AnonymousResourceCollection
    {
        $filters = $request->validated();

        $query = Apartment::query()
            ->with(['zone', 'photos'])
            ->when($filters['zone'] ?? null, fn ($q, $slug) => $q->whereHas('zone', fn ($z) => $z->where('slug', $slug)))
            ->when($filters['guests'] ?? null, fn ($q, $guests) => $q->where('capacity', '>=', $guests))
            ->when($filters['type'] ?? null, fn ($q, $type) => $q->where('type', $type))
            ->when($filters['min_price'] ?? null, fn ($q, $min) => $q->where('price_per_night', '>=', $min))
            ->when($filters['max_price'] ?? null, fn ($q, $max) => $q->where('price_per_night', '<=', $max))
            ->showcaseOrder();

        $apartments = $query->get();

        // Équipements : filtre applicatif, portable entre PostgreSQL et SQLite.
        // À remplacer par une table pivot indexée si le parc dépasse quelques centaines de biens.
        if (! empty($filters['amenities'])) {
            $apartments = $apartments->filter(
                fn (Apartment $a) => empty(array_diff($filters['amenities'], $a->amenities ?? [])),
            )->values();
        }

        return ApartmentResource::collection($apartments);
    }

    public function show(Apartment $apartment): ApartmentResource
    {
        return new ApartmentResource($apartment->load(['zone', 'photos']));
    }
}
