<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ZoneResource;
use App\Models\Zone;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ZoneController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $zones = Zone::query()->withCount('apartments')->orderBy('name')->get();

        return ZoneResource::collection($zones);
    }
}
