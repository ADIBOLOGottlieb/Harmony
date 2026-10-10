<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('apartment_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('apartment_id')->constrained()->cascadeOnDelete();
            // Chemin relatif : « demo/… » (photo embarquée dans l'app) ou fichier du disque public.
            $table->string('path');
            $table->unsignedSmallInteger('position')->default(0);
            $table->string('caption')->nullable();
            $table->timestamps();

            $table->index(['apartment_id', 'position']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('apartment_photos');
    }
};
