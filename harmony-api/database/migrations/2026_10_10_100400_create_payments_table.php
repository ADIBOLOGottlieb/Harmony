<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Journal des transactions (acompte, solde, remboursement), tous moyens confondus. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->string('gateway', 30);
            $table->string('method', 30);
            $table->string('kind', 20);
            $table->unsignedInteger('amount');
            $table->string('currency', 3)->default('XOF');
            $table->string('status', 20)->default('pending')->index();
            $table->string('provider_reference')->nullable();
            $table->text('checkout_url')->nullable();
            $table->text('instructions')->nullable();
            $table->json('meta')->nullable();
            $table->timestampTz('paid_at')->nullable();
            $table->foreignId('validated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['gateway', 'provider_reference']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
