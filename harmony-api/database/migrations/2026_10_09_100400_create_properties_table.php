<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 2 : annonces immobilières génériques (location, vente, programme neuf).
 * Préparé dès maintenant ; exposé seulement quand FEATURE_SALES est actif.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('properties', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->string('listing_type', 20)->index();
            $table->string('status', 20)->default('draft')->index();
            $table->string('title');
            $table->text('description')->nullable();
            // Prix de vente ou de lancement en FCFA (peut dépasser 2^31).
            $table->unsignedBigInteger('price')->nullable();
            $table->foreignId('zone_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('apartment_id')->nullable()->constrained()->nullOnDelete();
            $table->date('delivery_expected_on')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('properties');
    }
};
