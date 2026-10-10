<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Réservations. Anti double-réservation en deux couches :
 * 1. BookingService : transaction + verrou sur l'appartement + contrôle de chevauchement ;
 * 2. PostgreSQL : contrainte d'exclusion sur [start_at, blocked_until) pour les statuts actifs.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 12)->unique();
            $table->foreignId('apartment_id')->constrained()->restrictOnDelete();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->string('stay_type', 20);
            $table->timestampTz('start_at');
            $table->timestampTz('end_at');
            // Fin de séjour + battement pour le ménage.
            $table->timestampTz('blocked_until');
            $table->unsignedSmallInteger('nights')->default(0);
            $table->unsignedSmallInteger('guests');
            $table->string('status', 20)->default('pending')->index();
            // Montants en FCFA, entiers, figés à la création.
            $table->unsignedInteger('accommodation_amount');
            $table->unsignedInteger('service_fee');
            $table->unsignedInteger('total_amount');
            $table->unsignedInteger('security_deposit');
            $table->unsignedInteger('advance_amount');
            $table->unsignedInteger('amount_paid')->default(0);
            $table->json('price_breakdown');
            $table->timestampTz('cancellation_deadline')->nullable();
            $table->timestampTz('expires_at')->nullable();
            $table->timestampTz('confirmed_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->string('cancel_reason')->nullable();
            $table->timestamps();

            $table->index(['apartment_id', 'start_at', 'blocked_until']);
            $table->index(['user_id', 'start_at']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('CREATE EXTENSION IF NOT EXISTS btree_gist');
            DB::statement(<<<'SQL'
                ALTER TABLE bookings ADD CONSTRAINT bookings_no_overlap
                EXCLUDE USING gist (
                    apartment_id WITH =,
                    tstzrange(start_at, blocked_until, '[)') WITH &&
                ) WHERE (status IN ('pending', 'confirmed'))
                SQL);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
