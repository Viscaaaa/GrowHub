<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('rank_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key', 50)->unique();
            $table->string('label', 100);
            $table->text('value');
            $table->string('type', 20)->default('integer');
            $table->text('description')->nullable();
            $table->json('options')->nullable();
            $table->timestamps();
        });

        // Seed default rank settings
        $now = now();
        $defaults = [
            [
                'key' => 'leaderboard_limit',
                'label' => 'Batas Top Leaderboard',
                'value' => '50',
                'type' => 'integer',
                'description' => 'Jumlah maksimal peringkat karyawan teratas yang diambil dan ditampilkan pada tabel Leaderboard utama.',
                'options' => json_encode([10, 20, 25, 50, 100]),
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'key' => 'home_widget_limit',
                'label' => 'Batas Top Widget Beranda',
                'value' => '5',
                'type' => 'integer',
                'description' => 'Jumlah peringkat karyawan teratas mingguan yang ditampilkan pada widget ringkasan di halaman Beranda.',
                'options' => json_encode([3, 5, 10]),
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'key' => 'show_podium',
                'label' => 'Tampilkan Podium Top 3',
                'value' => '1',
                'type' => 'boolean',
                'description' => 'Menampilkan visual panggung podium medali Emas (#1), Perak (#2), dan Perunggu (#3) di atas tabel Leaderboard.',
                'options' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'key' => 'show_my_rank_outside',
                'label' => 'Tampilkan Posisi Saya di Luar Top Limit',
                'value' => '1',
                'type' => 'boolean',
                'description' => 'Tetap menampilkan nomor peringkat aktual pengguna pada kartu sticky bawah meskipun karyawan belum masuk ke dalam kuota Top X.',
                'options' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ];

        DB::table('rank_settings')->insert($defaults);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rank_settings');
    }
};

