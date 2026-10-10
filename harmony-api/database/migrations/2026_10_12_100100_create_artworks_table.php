<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Galerie : œuvres proposées à la vente (prix en FCFA, entiers). */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('artworks', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->foreignId('artist_id')->constrained()->restrictOnDelete();
            $table->string('title');
            $table->text('description');
            $table->string('medium');
            $table->string('dimensions');
            $table->unsignedSmallInteger('year')->nullable();
            $table->unsignedInteger('price');
            $table->string('status', 20)->default('available');
            $table->boolean('featured')->default(false);
            $table->boolean('published')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->index(['published', 'status']);
        });

        Schema::create('artwork_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('artwork_id')->constrained()->cascadeOnDelete();
            $table->string('path');
            $table->unsignedSmallInteger('position')->default(0);
            $table->timestamps();
            $table->index(['artwork_id', 'position']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('artwork_photos');
        Schema::dropIfExists('artworks');
    }
};
