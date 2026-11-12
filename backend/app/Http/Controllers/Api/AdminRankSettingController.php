<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RankSetting;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminRankSettingController extends Controller
{
    /**
     * Tampilkan konfigurasi Rank Settings, statistik karyawan, dan sampel leaderboard preview.
     */
    public function index(Request $request): JsonResponse
    {
        $settings = RankSetting::getAllFormatted();
        $limit = RankSetting::getLeaderboardLimit();

        // Sample preview dari data aktual untuk live mock di admin
        $previewUsers = User::where('is_active', true)
            ->select('id', 'name', 'avatar', 'department', 'position', 'points', 'current_streak')
            ->orderByDesc('points')
            ->orderBy('name')
            ->limit(min(10, $limit))
            ->get()
            ->values()
            ->map(function ($u, $idx) {
                $u->rank = $idx + 1;
                $u->score = (int) $u->points;
                return $u;
            });

        $stats = [
            'current_leaderboard_limit' => $limit,
            'current_home_limit' => RankSetting::getHomeWidgetLimit(),
            'show_podium' => RankSetting::getShowPodium(),
            'show_my_rank_outside' => RankSetting::getShowMyRankOutside(),
            'reset_frequency' => RankSetting::getResetFrequency(),
            'reset_frequency_label' => RankSetting::getResetFrequencyLabel(),
            'last_reset_at' => RankSetting::getLastResetAt(),
            'next_reset_at' => RankSetting::getNextResetDate(),
            'leaderboard_start_date' => RankSetting::getLeaderboardStartDate()?->toIso8601String(),
            'total_active_employees' => User::where('is_active', true)->count(),
            'total_employees_with_points' => User::where('is_active', true)->where('points', '>', 0)->count(),
        ];

        return response()->json([
            'settings' => $settings,
            'stats' => $stats,
            'preview_leaders' => $previewUsers,
        ]);
    }

    /**
     * Perbarui konfigurasi batas ranking dan jadwal reset leaderboard.
     */
    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'leaderboard_limit' => ['required', 'integer', 'min:3', 'max:500'],
            'home_widget_limit' => ['required', 'integer', 'min:1', 'max:20'],
            'show_podium' => ['required', 'boolean'],
            'show_my_rank_outside' => ['required', 'boolean'],
            'reset_frequency' => ['sometimes', 'string', 'in:never,weekly,monthly,quarterly,yearly'],
        ]);

        foreach ($validated as $key => $val) {
            $setting = RankSetting::where('key', $key)->first();
            if ($setting) {
                $setting->value = is_bool($val) ? ($val ? '1' : '0') : (string) $val;
                $setting->save();
            } else {
                RankSetting::set($key, $val);
            }
        }

        return response()->json([
            'message' => 'Konfigurasi batas peringkat dan siklus reset berhasil disimpan!',
            'settings' => RankSetting::getAllFormatted(),
            'stats' => [
                'current_leaderboard_limit' => RankSetting::getLeaderboardLimit(),
                'current_home_limit' => RankSetting::getHomeWidgetLimit(),
                'show_podium' => RankSetting::getShowPodium(),
                'show_my_rank_outside' => RankSetting::getShowMyRankOutside(),
                'reset_frequency' => RankSetting::getResetFrequency(),
                'reset_frequency_label' => RankSetting::getResetFrequencyLabel(),
                'last_reset_at' => RankSetting::getLastResetAt(),
                'next_reset_at' => RankSetting::getNextResetDate(),
                'leaderboard_start_date' => RankSetting::getLeaderboardStartDate()?->toIso8601String(),
                'total_active_employees' => User::where('is_active', true)->count(),
                'total_employees_with_points' => User::where('is_active', true)->where('points', '>', 0)->count(),
            ],
        ]);
    }

    /**
     * Lakukan reset leaderboard manual sekarang juga.
     */
    public function manualReset(): JsonResponse
    {
        $now = now()->toIso8601String();
        RankSetting::set('last_reset_at', $now);

        return response()->json([
            'message' => 'Leaderboard berhasil direset sekarang! Perhitungan skor musim baru dimulai sejak saat ini.',
            'settings' => RankSetting::getAllFormatted(),
            'stats' => [
                'current_leaderboard_limit' => RankSetting::getLeaderboardLimit(),
                'current_home_limit' => RankSetting::getHomeWidgetLimit(),
                'show_podium' => RankSetting::getShowPodium(),
                'show_my_rank_outside' => RankSetting::getShowMyRankOutside(),
                'reset_frequency' => RankSetting::getResetFrequency(),
                'reset_frequency_label' => RankSetting::getResetFrequencyLabel(),
                'last_reset_at' => $now,
                'next_reset_at' => RankSetting::getNextResetDate(),
                'leaderboard_start_date' => $now,
                'total_active_employees' => User::where('is_active', true)->count(),
                'total_employees_with_points' => User::where('is_active', true)->where('points', '>', 0)->count(),
            ],
        ]);
    }

    /**
     * Batalkan reset manual dan kembalikan ke jadwal siklus normal.
     */
    public function clearManualReset(): JsonResponse
    {
        RankSetting::set('last_reset_at', '');

        return response()->json([
            'message' => 'Status reset manual telah dibatalkan. Leaderboard kembali mengikuti siklus normal.',
            'settings' => RankSetting::getAllFormatted(),
            'stats' => [
                'current_leaderboard_limit' => RankSetting::getLeaderboardLimit(),
                'current_home_limit' => RankSetting::getHomeWidgetLimit(),
                'show_podium' => RankSetting::getShowPodium(),
                'show_my_rank_outside' => RankSetting::getShowMyRankOutside(),
                'reset_frequency' => RankSetting::getResetFrequency(),
                'reset_frequency_label' => RankSetting::getResetFrequencyLabel(),
                'last_reset_at' => null,
                'next_reset_at' => RankSetting::getNextResetDate(),
                'leaderboard_start_date' => RankSetting::getLeaderboardStartDate()?->toIso8601String(),
                'total_active_employees' => User::where('is_active', true)->count(),
                'total_employees_with_points' => User::where('is_active', true)->where('points', '>', 0)->count(),
            ],
        ]);
    }

    /**
     * Kembalikan pengaturan batas ranking ke default bawaan sistem.
     */
    public function resetDefaults(): JsonResponse
    {
        $defaults = [
            'leaderboard_limit' => '50',
            'home_widget_limit' => '5',
            'show_podium' => '1',
            'show_my_rank_outside' => '1',
            'reset_frequency' => 'never',
            'last_reset_at' => '',
        ];

        foreach ($defaults as $key => $val) {
            $setting = RankSetting::where('key', $key)->first();
            if ($setting) {
                $setting->value = $val;
                $setting->save();
            }
        }

        return response()->json([
            'message' => 'Pengaturan batas peringkat berhasil dikembalikan ke default sistem!',
            'settings' => RankSetting::getAllFormatted(),
            'stats' => [
                'current_leaderboard_limit' => RankSetting::getLeaderboardLimit(),
                'current_home_limit' => RankSetting::getHomeWidgetLimit(),
                'show_podium' => RankSetting::getShowPodium(),
                'show_my_rank_outside' => RankSetting::getShowMyRankOutside(),
                'reset_frequency' => 'never',
                'reset_frequency_label' => 'Tidak Pernah Reset (Sepanjang Waktu)',
                'last_reset_at' => null,
                'next_reset_at' => null,
                'leaderboard_start_date' => null,
                'total_active_employees' => User::where('is_active', true)->count(),
                'total_employees_with_points' => User::where('is_active', true)->where('points', '>', 0)->count(),
            ],
        ]);
    }
}
