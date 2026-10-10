<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\AvailabilityRequest;
use App\Models\Apartment;
use App\Services\Booking\AvailabilityService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;

class AvailabilityController extends Controller
{
    public function show(AvailabilityRequest $request, Apartment $apartment, AvailabilityService $availability): JsonResponse
    {
        $tz = config('app.timezone');
        $days = $availability->calendar(
            $apartment,
            CarbonImmutable::createFromFormat('!Y-m-d', $request->validated('from'), $tz),
            CarbonImmutable::createFromFormat('!Y-m-d', $request->validated('to'), $tz),
        );

        return response()->json([
            'data' => $days,
            'meta' => [
                'check_in_time' => config('harmony.check_in_time'),
                'check_out_time' => config('harmony.check_out_time'),
                'bookable' => $apartment->isBookable(),
            ],
        ]);
    }
}
