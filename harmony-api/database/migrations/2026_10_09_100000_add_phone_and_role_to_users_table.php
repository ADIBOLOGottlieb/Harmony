<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Comptes par numéro de téléphone (OTP) et rôles. L'e-mail, le mot de passe
 * et le nom deviennent facultatifs : un client peut s'inscrire avec son seul numéro.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 20)->nullable()->unique()->after('name');
            $table->string('role', 20)->default('client')->index()->after('phone');
            $table->string('name')->nullable()->change();
            $table->string('email')->nullable()->change();
            $table->string('password')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['phone']);
            $table->dropIndex(['role']);
            $table->dropColumn(['phone', 'role']);
        });
    }
};
