<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\RequestOtpRequest;
use App\Http\Requests\VerifyOtpRequest;
use App\Http\Resources\UserResource;
use App\Services\Auth\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class AuthController extends Controller
{
    public function requestOtp(RequestOtpRequest $request, OtpService $otp): JsonResponse
    {
        $debugCode = $otp->send($request->validated('phone'));

        return response()->json(array_filter([
            'message' => 'Un code vous a été envoyé par SMS.',
            'expires_in' => (int) config('harmony.otp.ttl_minutes') * 60,
            // Uniquement en démonstration (OTP_EXPOSE_CODE), tant qu'aucun prestataire SMS n'est branché.
            'debug_code' => $debugCode,
        ]), 202);
    }

    public function verifyOtp(VerifyOtpRequest $request, OtpService $otp): JsonResponse
    {
        $user = $otp->verify($request->validated('phone'), $request->validated('code'));

        if (! $user->name && $request->filled('name')) {
            $user->update(['name' => $request->validated('name')]);
        }

        $token = $user->createToken('mobile', ['*'], now()->addDays(30))->plainTextToken;

        return response()->json(['token' => $token, 'user' => new UserResource($user)]);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    public function updateProfile(Request $request): UserResource
    {
        $data = $request->validate([
            'name' => ['nullable', 'string', 'max:80'],
            'email' => ['nullable', 'email', 'max:120'],
        ]);
        $request->user()->update($data);

        return new UserResource($request->user());
    }

    public function logout(Request $request): Response
    {
        $request->user()->currentAccessToken()->delete();

        return response()->noContent();
    }
}
