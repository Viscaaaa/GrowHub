<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\PointRule;
use App\Services\GamificationService;
use Illuminate\Http\Request;

class CourseController extends Controller
{
    public function __construct(private GamificationService $gamification) {}

    public function index(Request $request)
    {
        $user = $request->user();

        $q = Course::where('is_published', true)
            ->withCount('completions')
            ->withExists(['completions as is_completed' => fn ($c) => $c->where('user_id', $user->id)]);

        if ($cat = $request->query('category')) {
            $q->where('category', $cat);
        }
        if ($s = trim((string) $request->query('q'))) {
            $q->where('title', 'ilike', "%$s%");
        }

        $courses = $q->orderBy('id')->get()->makeHidden('body');
        $courseRule = PointRule::where('action', 'course_completed')->first();
        if ($courseRule) {
            $courses->each(function (Course $course) use ($courseRule) {
                $course->points_reward = $courseRule->is_active
                    ? ($courseRule->points > 0 ? (int) $courseRule->points : (int) $course->points_reward)
                    : 0;
            });
        }

        return response()->json([
            'courses' => $courses,
            'categories' => Course::where('is_published', true)->distinct()->orderBy('category')->pluck('category'),
            'completed' => $user->completedCourses()->count(),
            'total' => Course::where('is_published', true)->count(),
        ]);
    }

    public function show(Request $request, Course $course)
    {
        $user = $request->user();
        $course->loadCount('completions');
        $course->loadExists(['completions as is_completed' => fn ($c) => $c->where('user_id', $user->id)]);

        $courseRule = PointRule::where('action', 'course_completed')->first();
        if ($courseRule) {
            $course->points_reward = $courseRule->is_active
                ? ($courseRule->points > 0 ? (int) $courseRule->points : (int) $course->points_reward)
                : 0;
        }

        return $course;
    }

    public function complete(Request $request, Course $course)
    {
        $user = $request->user();

        if ($course->completions()->where('user_id', $user->id)->exists()) {
            return response()->json(['message' => 'Materi ini sudah kamu selesaikan.', 'points_earned' => 0]);
        }

        $course->completions()->attach($user->id);
        $earned = $this->gamification->award($user, 'course_completed', "Menyelesaikan materi \"{$course->title}\"", $course, $course->points_reward);

        return response()->json(['message' => 'Selamat! Materi selesai.', 'points_earned' => $earned]);
    }
}
