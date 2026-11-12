<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Content;
use App\Models\Course;
use App\Models\PointRule;
use App\Models\PointTransaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PointRuleActivationTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role = 'employee', string $nip = '202605001', int $points = 0): User
    {
        return User::create([
            'nip' => $nip,
            'name' => ucfirst($role).' '.$nip,
            'email' => "{$role}.{$nip}@growhub.co.id",
            'password' => Hash::make($nip),
            'role' => $role,
            'points' => $points,
            'is_active' => true,
            'must_change_password' => false,
        ]);
    }

    public function test_enabling_daily_login_mid_day_awards_points_even_if_last_activity_was_recorded_today(): void
    {
        $admin = $this->makeUser('admin', '1000000097', 0);
        $employee = $this->makeUser('employee', '202605001', 10);

        $dailyRule = PointRule::where('action', 'daily_login')->firstOrFail();

        // Simulate daily_login was disabled when employee first logged in today
        $adminToken = $this->postJson('/api/auth/login', [
            'nip' => $admin->nip,
            'password' => $admin->nip,
        ])->assertOk()->json('token');

        $this->withToken($adminToken)->putJson("/api/admin/point-rules/{$dailyRule->id}", [
            'points' => 4,
            'daily_cap' => 1,
            'is_active' => false,
        ])->assertOk();

        $this->app['auth']->forgetGuards();
        $empToken = $this->withoutToken()->postJson('/api/auth/login', [
            'nip' => $employee->nip,
            'password' => $employee->nip,
        ])->assertOk()->json('token');

        $employee->refresh();
        $this->assertTrue($employee->last_activity_date->isToday());
        $this->assertSame(10, $employee->points);
        $this->assertSame(1, $employee->current_streak);

        // Admin activates daily_login and saves
        $this->app['auth']->forgetGuards();
        $this->withToken($adminToken)->putJson("/api/admin/point-rules/{$dailyRule->id}", [
            'points' => 4,
            'daily_cap' => 1,
            'is_active' => true,
        ])->assertOk();

        // Employee acts again today -> daily_login points are now awarded, streak does NOT double count
        $this->app['auth']->forgetGuards();
        $this->withToken($empToken)->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('points', 14);

        $employee->refresh();
        $this->assertSame(14, $employee->points);
        $this->assertSame(1, $employee->current_streak);
        $this->assertDatabaseHas('point_transactions', [
            'user_id' => $employee->id,
            'action' => 'daily_login',
            'points' => 4,
        ]);
    }

    public function test_enabling_content_viewed_awards_points_and_returns_points_earned_in_show_response(): void
    {
        $admin = $this->makeUser('admin', '1000000098', 0);
        $author = $this->makeUser('employee', '202605002', 20);
        $reader = $this->makeUser('employee', '202605003', 10);

        // Mark daily_login as already rewarded for reader so only content_viewed is measured
        $reader->update(['last_activity_date' => today()]);
        PointTransaction::create([
            'user_id' => $reader->id,
            'points' => 2,
            'action' => 'daily_login',
            'description' => 'Initial daily login',
        ]);

        $category = Category::create(['name' => 'Best Practice', 'slug' => 'best-practice']);
        $content = Content::create([
            'user_id' => $author->id,
            'category_id' => $category->id,
            'title' => 'Artikel Panduan',
            'body' => 'Isi panduan lengkap.',
            'status' => Content::STATUS_PUBLISHED,
            'published_at' => now(),
        ]);

        $viewRule = PointRule::where('action', 'content_viewed')->firstOrFail();
        $this->assertFalse($viewRule->is_active);

        Sanctum::actingAs($admin);
        $this->putJson("/api/admin/point-rules/{$viewRule->id}", [
            'points' => 3,
            'daily_cap' => 10,
            'is_active' => true,
        ])->assertOk();

        Sanctum::actingAs($reader);
        $this->getJson("/api/contents/{$content->id}")
            ->assertOk()
            ->assertJsonPath('points_earned', 3);

        $this->assertSame(13, $reader->fresh()->points);
    }

    public function test_enabling_save_received_awards_author_not_saver_and_courses_reflect_rule_status(): void
    {
        $admin = $this->makeUser('admin', '1000000099', 0);
        $author = $this->makeUser('employee', '202605004', 20);
        $saver = $this->makeUser('employee', '202605005', 10);
        $saver->update(['last_activity_date' => today()]);
        PointTransaction::create([
            'user_id' => $saver->id,
            'points' => 2,
            'action' => 'daily_login',
            'description' => 'Initial daily login',
        ]);

        $category = Category::create(['name' => 'Tips', 'slug' => 'tips']);
        $content = Content::create([
            'user_id' => $author->id,
            'category_id' => $category->id,
            'title' => 'Tips Operasional',
            'body' => 'Detail tips.',
            'status' => Content::STATUS_PUBLISHED,
            'published_at' => now(),
        ]);

        $course = Course::create([
            'title' => 'Modul Test',
            'slug' => 'modul-test',
            'category' => 'Umum',
            'level' => 'Beginner',
            'summary' => 'Ringkasan',
            'body' => 'Materi',
            'duration_minutes' => 10,
            'points_reward' => 25,
            'is_published' => true,
        ]);

        $saveRule = PointRule::where('action', 'save_received')->firstOrFail();
        $courseRule = PointRule::where('action', 'course_completed')->firstOrFail();

        Sanctum::actingAs($admin);
        $this->putJson("/api/admin/point-rules/{$saveRule->id}", [
            'points' => 5,
            'daily_cap' => null,
            'is_active' => true,
        ])->assertOk();

        $this->putJson("/api/admin/point-rules/{$courseRule->id}", [
            'points' => 15,
            'daily_cap' => null,
            'is_active' => false,
        ])->assertOk();

        Sanctum::actingAs($saver);
        $this->postJson("/api/contents/{$content->id}/save")
            ->assertOk()
            ->assertJsonPath('saved', true);

        // Save rewards the content author (+5), not the user who clicked save
        $this->assertSame(25, $author->fresh()->points);
        $this->assertSame(10, $saver->fresh()->points);

        // Course endpoints reflect disabled course_completed rule (0 pts reward)
        $this->getJson("/api/courses/{$course->slug}")
            ->assertOk()
            ->assertJsonPath('points_reward', 0);
    }
}
