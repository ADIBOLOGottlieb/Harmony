<?php

namespace App\Providers;

use App\Enums\UserRole;
use App\Models\User;
use App\Services\Payments\Gateways\FedaPayGateway;
use App\Services\Sms\NullSmsSender;
use App\Services\Sms\SmsSender;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Aucun prestataire SMS choisi pour l'instant : envoi désactivé (et jamais journalisé).
        $this->app->bind(SmsSender::class, NullSmsSender::class);

        $this->app->bind(FedaPayGateway::class, fn () => new FedaPayGateway(
            (string) config('services.fedapay.secret_key'),
            (string) config('services.fedapay.webhook_secret'),
            (string) config('services.fedapay.environment'),
        ));
    }

    public function boot(): void
    {
        // L'administrateur passe tous les contrôles d'accès.
        Gate::before(fn (User $user) => $user->role === UserRole::Admin ? true : null);

        // Lecture du catalogue.
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(120)->by($request->user()?->id ?: $request->ip()));

        // Envoi et vérification de codes OTP : par numéro et par adresse IP.
        RateLimiter::for('otp', fn (Request $request) => [
            Limit::perMinute(3)->by('otp-phone:'.$request->input('phone')),
            Limit::perMinute(10)->by('otp-ip:'.$request->ip()),
        ]);

        // Vérification des codes : plus tolérante (fautes de frappe), le blocage après 5 essais est géré par OtpService.
        RateLimiter::for('otp-verify', fn (Request $request) => Limit::perMinute(10)->by('otp-verify:'.$request->input('phone').'|'.$request->ip()));

        // Création de réservations et de paiements.
        RateLimiter::for('booking', fn (Request $request) => Limit::perMinute(10)->by($request->user()?->id ?: $request->ip()));
    }
}
