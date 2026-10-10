<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Payments\InvalidWebhook;
use App\Services\Payments\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentWebhookController extends Controller
{
    public function fedapay(Request $request, PaymentService $payments): JsonResponse
    {
        if (blank(config('services.fedapay.webhook_secret'))) {
            return response()->json(['message' => 'Webhook non configuré.'], 503);
        }

        try {
            $payments->handleWebhook('fedapay', $request);
        } catch (InvalidWebhook) {
            return response()->json(['message' => 'Signature invalide.'], 400);
        }

        return response()->json(['received' => true]);
    }
}
