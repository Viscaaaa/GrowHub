<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $now = now();
        $newSettings = [
            [
                'key' => 'reset_frequency',
                'label' => 'Jadwal / Siklus Reset Leaderboard',
                'value' => 'never',
                'type' => 'string',
                'description' => 'Frekuensi otomatis reset peringkat pada Leaderboard: never (tidak pernah reset / sepanjang waktu), weekly (mingguan), monthly (bulanan), quarterly (triwulan), atau yearly (tahunan).',
                'options' => json_encode(['never', 'weekly', 'monthly', 'quarterly', 'yearly']),
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'key' => 'last_reset_at',
                'label' => 'Waktu Reset Terakhir',
                'value' => '',
                'type' => 'string',
                'description' => 'Pencatatan tanggal dan waktu saat Leaderboard terakhir kali direset secara manual atau otomatis.',
                'options' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ];

        foreach ($newSettings as $setting) {
            $exists = DB::table('rank_settings')->where('key', $setting['key'])->exists();
            if (!$exists) {
                DB::table('rank_settings')->insert($setting);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('rank_settings')->whereIn('key', ['reset_frequency', 'last_reset_at'])->delete();
    }
};

