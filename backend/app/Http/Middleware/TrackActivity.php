<?php

namespace App\Http\Middleware;

use App\Models\PointTransaction;
use App\Services\GamificationService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TrackActivity
{
    public function __construct(private GamificationService $gamification) {}

    /**
     * Setiap request terautentikasi pertama di hari itu akan menambah streak.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user) {
            $needsStreak = ! $user->last_activity_date || ! $user->last_activity_date->isToday();
            $needsDailyPoint = ! PointTransaction::where('user_id', $user->id)
                ->where('action', 'daily_login')
                ->whereDate('created_at', today())
                ->exists();

            if ($needsStreak || $needsDailyPoint) {
                $this->gamification->recordActivity($user);
            }
        }

        return $next($request);
    }
}
