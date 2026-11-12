<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Comment;
use App\Models\Content;
use App\Models\ContentView;
use App\Models\Course;
use App\Models\PointTransaction;
use App\Models\RankSetting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /** Halaman Home */
    public function home(Request $request)
    {
        $user = $request->user();
        $with = [ContentController::AUTHOR_COLUMNS, 'category', 'media'];

        $trending = Content::published()
            ->with($with)->withViewerState($user)
            ->orderByRaw('(likes_count * 2 + comments_count * 3 + shares_count * 2 + saves_count * 2 + views_count * 0.1) DESC')
            ->orderByDesc('published_at')
            ->orderByDesc('id')
            ->limit(3)->get();

        $latest = Content::published()
            ->with($with)->withViewerState($user)
            ->latest('published_at')->limit(6)->get();

        $recentlyViewed = ContentView::where('user_id', $user->id)
            ->whereHas('content', fn ($q) => $q->published())
            ->with([
                'content' => fn ($q) => $q->with($with)->withViewerState($user),
            ])
            ->orderByDesc('viewed_at')
            ->orderByDesc('id')
            ->limit(3)
            ->get()
            ->map(function (ContentView $view) {
                $content = $view->content;
                $content->setAttribute('viewed_at', $view->viewed_at?->toIso8601String());

                return $content;
            })
            ->values();

        $homeLimit = RankSetting::getHomeWidgetLimit();
        $topWeekly = $this->periodLeaders(now()->startOfWeek(), $homeLimit);

        $categories = Category::withCount(['contents' => fn ($q) => $q->published()])
            ->orderBy('sort_order')->get();

        $courses = Course::where('is_published', true)
            ->withExists(['completions as is_completed' => fn ($q) => $q->where('user_id', $user->id)])
            ->latest()->limit(3)->get(['id', 'title', 'slug', 'category', 'level', 'summary', 'cover_color', 'duration_minutes', 'points_reward']);

        return response()->json([
            'stats' => [
                'published_contents' => Content::published()->count(),
                'contributors' => Content::published()->distinct('user_id')->count('user_id'),
                'employees' => User::where('is_active', true)->count(),
                'contents_this_week' => Content::published()->where('published_at', '>=', now()->startOfWeek())->count(),
            ],
            'my_rank' => $this->rankOf($user),
            'trending' => $trending,
            'latest' => $latest,
            'recently_viewed' => $recentlyViewed,
            'top_weekly' => $topWeekly,
            'categories' => $categories,
            'courses' => $courses,
        ]);
    }

    /** Halaman My Dashboard */
    public function me(Request $request)
    {
        $user = $request->user();

        $statusCounts = $user->contents()->selectRaw('status, count(*) as total')->groupBy('status')->pluck('total', 'status');
        $engagement = $user->contents()->published()->selectRaw(
            'COALESCE(SUM(likes_count),0) as likes, COALESCE(SUM(comments_count),0) as comments, COALESCE(SUM(views_count),0) as views, COALESCE(SUM(shares_count),0) as shares, COALESCE(SUM(saves_count),0) as saves'
        )->first();

        // Point 30 hari terakhir per hari
        $from = today()->subDays(29);
        $daily = PointTransaction::where('user_id', $user->id)
            ->where('created_at', '>=', $from)
            ->selectRaw('DATE(created_at) as day, SUM(points) as total')
            ->groupBy('day')->pluck('total', 'day');
        $chart = collect(range(0, 29))->map(function ($i) use ($from, $daily) {
            $d = $from->copy()->addDays($i)->toDateString();

            return ['date' => $d, 'points' => (int) ($daily[$d] ?? 0)];
        });

        // Kalender aktivitas 12 minggu terakhir
        $activity = PointTransaction::where('user_id', $user->id)
            ->where('created_at', '>=', today()->subDays(83))
            ->selectRaw('DATE(created_at) as day, COUNT(*) as total')
            ->groupBy('day')->pluck('total', 'day');

        $breakdown = PointTransaction::where('user_id', $user->id)
            ->selectRaw('action, SUM(points) as total')
            ->groupBy('action')->orderByDesc('total')->pluck('total', 'action');

        $published = (int) ($statusCounts['published'] ?? 0);
        $commentsGiven = Comment::where('user_id', $user->id)->count();
        $coursesDone = $user->completedCourses()->count();

        $badges = [
            ['key' => 'first_post', 'name' => 'First Seed', 'desc' => 'Publikasikan konten pertama', 'icon' => 'Sprout', 'earned' => $published >= 1, 'progress' => min(1, $published), 'target' => 1],
            ['key' => 'contributor', 'name' => 'Knowledge Sharer', 'desc' => 'Publikasikan 5 konten', 'icon' => 'BookOpen', 'earned' => $published >= 5, 'progress' => min(5, $published), 'target' => 5],
            ['key' => 'loved', 'name' => 'Crowd Favorite', 'desc' => 'Dapatkan 25 like', 'icon' => 'Heart', 'earned' => $engagement->likes >= 25, 'progress' => min(25, (int) $engagement->likes), 'target' => 25],
            ['key' => 'streak7', 'name' => 'On Fire', 'desc' => 'Streak 7 hari berturut-turut', 'icon' => 'Flame', 'earned' => $user->longest_streak >= 7, 'progress' => min(7, $user->longest_streak), 'target' => 7],
            ['key' => 'streak30', 'name' => 'Unstoppable', 'desc' => 'Streak 30 hari berturut-turut', 'icon' => 'Zap', 'earned' => $user->longest_streak >= 30, 'progress' => min(30, $user->longest_streak), 'target' => 30],
            ['key' => 'commenter', 'name' => 'Conversation Starter', 'desc' => 'Tulis 20 komentar', 'icon' => 'MessageCircle', 'earned' => $commentsGiven >= 20, 'progress' => min(20, $commentsGiven), 'target' => 20],
            ['key' => 'learner', 'name' => 'Lifelong Learner', 'desc' => 'Selesaikan 3 materi Learning Center', 'icon' => 'GraduationCap', 'earned' => $coursesDone >= 3, 'progress' => min(3, $coursesDone), 'target' => 3],
            ['key' => 'mentor', 'name' => 'Mentor', 'desc' => 'Capai Level 7', 'icon' => 'Crown', 'earned' => $user->level_info['level'] >= 7, 'progress' => min(7, $user->level_info['level']), 'target' => 7],
        ];

        return response()->json([
            'user' => $user,
            'rank' => $this->rankOf($user),
            'department_rank' => $this->rankOf($user, true),
            'points_this_week' => (int) PointTransaction::where('user_id', $user->id)->where('created_at', '>=', now()->startOfWeek())->sum('points'),
            'points_this_month' => (int) PointTransaction::where('user_id', $user->id)->where('created_at', '>=', now()->startOfMonth())->sum('points'),
            'content_counts' => [
                'draft' => (int) ($statusCounts['draft'] ?? 0),
                'pending' => (int) ($statusCounts['pending'] ?? 0),
                'published' => $published,
                'rejected' => (int) ($statusCounts['rejected'] ?? 0),
            ],
            'engagement' => $engagement,
            'chart' => $chart,
            'activity' => $activity,
            'breakdown' => $breakdown,
            'badges' => $badges,
            'courses_completed' => $coursesDone,
            'recent_points' => PointTransaction::where('user_id', $user->id)->latest()->limit(12)->get(),
        ]);
    }

    /** Leaderboard */
    public function leaderboard(Request $request)
    {
        $period = $request->query('period', 'all');
        $department = $request->query('department');
        $user = $request->user();

        $limit = RankSetting::getLeaderboardLimit();
        $showPodium = RankSetting::getShowPodium();
        $showMyRankOutside = RankSetting::getShowMyRankOutside();
        $resetStartDate = RankSetting::getLeaderboardStartDate();
        $resetFreq = RankSetting::getResetFrequency();

        if ($period === 'week') {
            $from = now()->startOfWeek();
            if ($resetStartDate && $resetStartDate->gt($from)) {
                $from = $resetStartDate;
            }
        } elseif ($period === 'month') {
            $from = now()->startOfMonth();
            if ($resetStartDate && $resetStartDate->gt($from)) {
                $from = $resetStartDate;
            }
        } else {
            // period === 'all' (mengikuti siklus reset yang dikonfigurasi)
            $from = $resetStartDate;
        }

        if ($from === null) {
            $q = User::where('is_active', true)
                ->select('id', 'name', 'avatar', 'department', 'position', 'points', 'current_streak')
                ->addSelect(DB::raw('points as score'));
            if ($department) {
                $q->where('department', $department);
            }
            $rows = $q->orderByDesc('points')->orderBy('name')->limit($limit)->get();
        } else {
            $rows = $this->periodLeaders($from, $limit, $department);
        }

        $rows = $rows->values()->map(function ($u, $i) {
            $u->rank = $i + 1;

            return $u;
        });

        $mine = $rows->firstWhere('id', $user->id);

        if (!$mine) {
            $userScore = $from === null
                ? (int) $user->points
                : (int) PointTransaction::where('user_id', $user->id)->where('created_at', '>=', $from)->sum('points');

            $actualRank = $this->rankOfUserInPeriod($user, $period, $from, $department);

            $mine = [
                'id' => $user->id,
                'name' => $user->name,
                'avatar' => $user->avatar,
                'department' => $user->department,
                'rank' => $actualRank,
                'score' => $userScore,
                'is_outside_limit' => true,
            ];
        }

        return response()->json([
            'period' => $period,
            'leaders' => $rows,
            'top_limit' => $limit,
            'settings' => [
                'leaderboard_limit' => $limit,
                'show_podium' => $showPodium,
                'show_my_rank_outside' => $showMyRankOutside,
                'reset_frequency' => $resetFreq,
                'reset_frequency_label' => RankSetting::getResetFrequencyLabel(),
                'last_reset_at' => RankSetting::getLastResetAt(),
                'next_reset_at' => RankSetting::getNextResetDate(),
                'start_date' => $resetStartDate?->toIso8601String(),
            ],
            'me' => $mine,
            'departments' => User::whereNotNull('department')->distinct()->orderBy('department')->pluck('department'),
        ]);
    }

    private function rankOfUserInPeriod(User $user, string $period, $from = null, ?string $department = null): int
    {
        if ($from === null) {
            return $this->rankOf($user, (bool) $department);
        }

        $userScore = (int) PointTransaction::where('user_id', $user->id)
            ->where('created_at', '>=', $from)
            ->sum('points');

        $scores = PointTransaction::where('created_at', '>=', $from)
            ->selectRaw('user_id, SUM(points) as s')
            ->groupBy('user_id')
            ->havingRaw('SUM(points) > ?', [$userScore]);

        $q = User::joinSub($scores, 's', 's.user_id', '=', 'users.id')
            ->where('users.is_active', true);

        if ($department) {
            $q->where('users.department', $department);
        }

        return $q->count() + 1;
    }

    private function periodLeaders($from, int $limit, ?string $department = null)
    {
        $scores = PointTransaction::where('created_at', '>=', $from)
            ->selectRaw('user_id, SUM(points) as score')
            ->groupBy('user_id');

        $q = User::joinSub($scores, 's', 's.user_id', '=', 'users.id')
            ->where('users.is_active', true)
            ->select('users.id', 'users.name', 'users.avatar', 'users.department', 'users.position', 'users.points', 'users.current_streak', 's.score');
        if ($department) {
            $q->where('users.department', $department);
        }

        return $q->orderByDesc('s.score')->orderBy('users.name')->limit($limit)->get()
            ->each(fn ($u) => $u->score = (int) $u->score);
    }

    private function rankOf(User $user, bool $department = false): int
    {
        $q = User::where('is_active', true)->where('points', '>', $user->points);
        if ($department && $user->department) {
            $q->where('department', $user->department);
        }

        return $q->count() + 1;
    }
}
