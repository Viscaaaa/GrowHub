<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RankSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'label',
        'value',
        'type',
        'description',
        'options',
    ];

    protected function casts(): array
    {
        return [
            'options' => 'array',
        ];
    }

    /**
     * Ambil nilai setting berdasarkan key dengan casting tipe yang sesuai.
     */
    public static function get(string $key, mixed $default = null): mixed
    {
        $setting = static::where('key', $key)->first();
        if (!$setting) {
            return $default;
        }

        return static::castValue($setting->value, $setting->type);
    }

    /**
     * Simpan / perbarui nilai setting.
     */
    public static function set(string $key, mixed $value): self
    {
        $setting = static::firstOrNew(['key' => $key]);
        $setting->value = is_bool($value) ? ($value ? '1' : '0') : (string) $value;
        $setting->save();

        return $setting;
    }

    /**
     * Konversi value database ke tipe data yang semestinya.
     */
    public static function castValue(mixed $value, string $type): mixed
    {
        return match ($type) {
            'integer', 'int' => (int) $value,
            'boolean', 'bool' => in_array($value, [1, '1', true, 'true', 'yes', 'on'], true),
            'array', 'json' => is_string($value) ? json_decode($value, true) : (array) $value,
            default => (string) $value,
        };
    }

    /**
     * Batas jumlah top user yang ditampilkan di Leaderboard.
     */
    public static function getLeaderboardLimit(): int
    {
        $val = static::get('leaderboard_limit', 50);
        return max(3, min(500, (int) $val));
    }

    /**
     * Batas jumlah top user di widget Beranda.
     */
    public static function getHomeWidgetLimit(): int
    {
        $val = static::get('home_widget_limit', 5);
        return max(1, min(20, (int) $val));
    }

    /**
     * Apakah menampilkan podium visual Top 3 (Emas, Perak, Perunggu).
     */
    public static function getShowPodium(): bool
    {
        return (bool) static::get('show_podium', true);
    }

    /**
     * Apakah tetap menampilkan rank aktual karyawan di kartu sticky bawah jika di luar batas Top.
     */
    public static function getShowMyRankOutside(): bool
    {
        return (bool) static::get('show_my_rank_outside', true);
    }

    /**
     * Ambil frekuensi reset leaderboard: 'never', 'weekly', 'monthly', 'quarterly', 'yearly'
     */
    public static function getResetFrequency(): string
    {
        $val = (string) static::get('reset_frequency', 'never');
        return in_array($val, ['never', 'weekly', 'monthly', 'quarterly', 'yearly'], true) ? $val : 'never';
    }

    /**
     * Label bahasa manusia untuk frekuensi reset.
     */
    public static function getResetFrequencyLabel(): string
    {
        return match (static::getResetFrequency()) {
            'weekly' => 'Mingguan (Setiap Hari Senin)',
            'monthly' => 'Bulanan (Setiap Tanggal 1)',
            'quarterly' => 'Triwulan / Kuartal (3 Bulan Sekali)',
            'yearly' => 'Tahunan (Setiap 1 Januari)',
            default => 'Tidak Pernah Reset (Sepanjang Waktu)',
        };
    }

    /**
     * Waktu kapan leaderboard terakhir direset.
     */
    public static function getLastResetAt(): ?string
    {
        $val = static::get('last_reset_at');
        return !empty($val) ? (string) $val : null;
    }

    /**
     * Tanggal perkiraan reset otomatis berikutnya.
     */
    public static function getNextResetDate(): ?string
    {
        $freq = static::getResetFrequency();
        if ($freq === 'never') {
            return null;
        }

        $now = now();
        return match ($freq) {
            'weekly' => $now->copy()->endOfWeek()->addSecond()->toIso8601String(),
            'monthly' => $now->copy()->endOfMonth()->addSecond()->toIso8601String(),
            'quarterly' => $now->copy()->endOfQuarter()->addSecond()->toIso8601String(),
            'yearly' => $now->copy()->endOfYear()->addSecond()->toIso8601String(),
            default => null,
        };
    }

    /**
     * Hitung tanggal awal ($from) perhitungan skor leaderboard berdasarkan kebijakan reset.
     * Mengembalikan null jika 'never' dan belum pernah direset manual (menghitung total akumulasi poin).
     */
    public static function getLeaderboardStartDate(): ?\Carbon\Carbon
    {
        $freq = static::getResetFrequency();
        $lastResetStr = static::getLastResetAt();
        $lastReset = $lastResetStr ? \Carbon\Carbon::parse($lastResetStr) : null;

        if ($freq === 'never') {
            return $lastReset; // null jika tidak pernah reset sama sekali, atau tanggal manual reset terakhir
        }

        $now = now();
        $cycleStart = match ($freq) {
            'weekly' => $now->copy()->startOfWeek(),
            'monthly' => $now->copy()->startOfMonth(),
            'quarterly' => $now->copy()->startOfQuarter(),
            'yearly' => $now->copy()->startOfYear(),
            default => null,
        };

        if (!$cycleStart) {
            return $lastReset;
        }

        if ($lastReset && $lastReset->gt($cycleStart)) {
            return $lastReset;
        }

        return $cycleStart;
    }

    /**
     * Ambil seluruh konfigurasi rank settings yang sudah diformat untuk API.
     */
    public static function getAllFormatted(): array
    {
        $settings = static::orderBy('id', 'asc')->get();
        $formatted = [];

        foreach ($settings as $s) {
            $formatted[$s->key] = [
                'id' => $s->id,
                'key' => $s->key,
                'label' => $s->label,
                'value' => static::castValue($s->value, $s->type),
                'type' => $s->type,
                'description' => $s->description,
                'options' => $s->options,
            ];
        }

        return $formatted;
    }
}
