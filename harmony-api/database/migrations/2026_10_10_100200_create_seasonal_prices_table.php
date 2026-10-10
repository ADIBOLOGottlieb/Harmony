<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Prix par nuit sur une période (fêtes, haute saison…), bornes incluses. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('seasonal_prices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('apartment_id')->constrained()->cascadeOnDelete();
            $table->string('label')->nullable();
            $table->date('starts_on');
            $table->date('ends_on');
            $table->unsignedInteger('price_per_night');
            $table->timestamps();

            $table->index(['apartment_id', 'starts_on', 'ends_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seasonal_prices');
    }
};
