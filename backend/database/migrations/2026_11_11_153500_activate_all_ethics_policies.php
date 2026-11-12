<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('ethics_policies')) {
            DB::table('ethics_policies')
                ->where('is_active', false)
                ->update([
                    'is_active' => true,
                    'updated_at' => now(),
                ]);
        }
    }

    public function down(): void
    {
        // No-op
    }
};

