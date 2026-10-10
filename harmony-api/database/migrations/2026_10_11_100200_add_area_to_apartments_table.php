<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Quartier affiché publiquement, distinct de l'adresse exacte
 * (révélée uniquement après confirmation d'une réservation).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('apartments', function (Blueprint $table) {
            $table->string('area')->nullable()->after('address');
        });

        DB::table('apartments')->whereNull('area')->update(['area' => DB::raw('address')]);
    }

    public function down(): void
    {
        Schema::table('apartments', function (Blueprint $table) {
            $table->dropColumn('area');
        });
    }
};
