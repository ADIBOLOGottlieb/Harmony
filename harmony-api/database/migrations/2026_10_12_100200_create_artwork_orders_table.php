<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Galerie : demandes d'acquisition. L'œuvre est réservée au client le temps du règlement,
 * finalisé avec la galerie (Mobile Money, virement ou sur place).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('artwork_orders', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 12)->unique();
            $table->foreignId('artwork_id')->constrained()->restrictOnDelete();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->string('status', 20)->default('pending')->index();
            $table->unsignedInteger('price');
            $table->string('delivery_method', 20);
            $table->unsignedInteger('delivery_fee')->default(0);
            $table->unsignedInteger('total');
            $table->string('delivery_address')->nullable();
            $table->text('note')->nullable();
            $table->timestampTz('expires_at')->nullable();
            $table->timestampTz('paid_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->string('cancel_reason')->nullable();
            $table->foreignId('handled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['user_id', 'created_at']);
        });

        // Double sécurité contre la double vente : une seule demande active par œuvre.
        DB::statement("CREATE UNIQUE INDEX artwork_orders_one_active ON artwork_orders (artwork_id) WHERE status IN ('pending', 'paid')");
    }

    public function down(): void
    {
        Schema::dropIfExists('artwork_orders');
    }
};
