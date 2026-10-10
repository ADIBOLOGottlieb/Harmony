<?php

namespace App\Http\Controllers;

use App\Enums\PaymentStatus;
use App\Models\Payment;
use App\Services\Payments\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;
use Illuminate\View\View;

/** Page de paiement simulée (sandbox), protégée par une URL signée. */
class SandboxPaymentController extends Controller
{
    public function show(Payment $payment): View
    {
        $this->guard($payment);

        return view('payments.sandbox', [
            'payment' => $payment->load('booking.apartment'),
            'done' => $payment->status !== PaymentStatus::Pending,
            'action' => URL::temporarySignedRoute('payments.sandbox.complete', now()->addHour(), ['payment' => $payment->id]),
        ]);
    }

    public function complete(Request $request, Payment $payment, PaymentService $payments): View
    {
        $this->guard($payment);
        $outcome = $request->input('outcome') === 'success' ? PaymentStatus::Succeeded : PaymentStatus::Failed;

        $payments->applyOutcome($payment, $outcome);

        return view('payments.sandbox', [
            'payment' => $payment->refresh()->load('booking.apartment'),
            'done' => true,
            'action' => null,
        ]);
    }

    private function guard(Payment $payment): void
    {
        abort_unless(config('harmony.payments.sandbox_enabled') && $payment->gateway === 'sandbox', 404);
    }
}
