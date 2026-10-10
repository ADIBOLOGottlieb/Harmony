<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('apartments', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('zone_id')->constrained()->restrictOnDelete();
            $table->string('title');
            $table->text('description');
            $table->string('type', 20);
            $table->unsignedSmallInteger('bedrooms');
            $table->unsignedSmallInteger('bathrooms');
            $table->unsignedSmallInteger('capacity');
            $table->unsignedSmallInteger('surface_m2');
            $table->json('amenities');
            // Montants en FCFA, entiers.
            $table->unsignedInteger('price_per_night');
            $table->unsignedInteger('deposit');
            $table->unsignedInteger('short_stay_three_hours_price')->nullable();
            $table->unsignedInteger('short_stay_day_price')->nullable();
            $table->string('status', 20)->default('available');
            $table->decimal('latitude', 9, 6);
            $table->decimal('longitude', 9, 6);
            $table->string('address');
            $table->json('rules');
            $table->decimal('rating', 2, 1)->default(0);
            $table->unsignedInteger('review_count')->default(0);
            $table->boolean('featured')->default(false);
            $table->timestampTz('listed_at');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['zone_id', 'status']);
            $table->index(['featured', 'listed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('apartments');
    }
};
