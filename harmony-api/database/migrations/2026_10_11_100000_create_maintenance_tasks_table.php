<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Ménage et maintenance : une tâche par intervention, rattachée à un bien
 * (et à la réservation qui l'a déclenchée pour le ménage de sortie).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('maintenance_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('apartment_id')->constrained()->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type', 20);
            $table->string('status', 20)->default('todo')->index();
            $table->string('title');
            $table->text('notes')->nullable();
            $table->timestampTz('due_at')->nullable();
            $table->timestampTz('completed_at')->nullable();
            $table->unsignedInteger('cost')->nullable();
            $table->timestamps();
            $table->index(['apartment_id', 'due_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('maintenance_tasks');
    }
};
