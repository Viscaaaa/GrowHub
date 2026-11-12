<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Category;
use App\Models\Community;
use App\Models\Content;
use App\Models\Course;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DatabaseSeederIdempotencyTest extends TestCase
{
    use RefreshDatabase;

    public function test_database_seeder_can_run_multiple_times_without_unique_constraint_errors(): void
    {
        $this->seed(DatabaseSeeder::class);

        $firstRunUserCount = User::count();
        $firstRunContentCount = Content::count();
        $firstRunNotificationCount = AppNotification::count();

        $this->assertSame(20, $firstRunUserCount);
        $this->assertSame(20, User::distinct('email')->count('email'));
        $this->assertSame(8, Category::count());
        $this->assertSame(6, Community::count());
        $this->assertSame(6, Course::count());

        // Re-running db:seed should be completely idempotent
        $this->seed(DatabaseSeeder::class);

        $this->assertSame($firstRunUserCount, User::count());
        $this->assertSame(8, Category::count());
        $this->assertSame(6, Community::count());
        $this->assertSame(6, Course::count());
        $this->assertSame($firstRunContentCount, Content::count());
        $this->assertSame($firstRunNotificationCount, AppNotification::count());
    }

    public function test_database_seeder_recovers_after_partial_seed_with_existing_category_and_admin_email(): void
    {
        Category::create([
            'name' => 'Best Practice',
            'slug' => 'best-practice',
            'icon' => 'Award',
            'color' => '#1e8c45',
            'description' => 'Existing category',
            'sort_order' => 0,
        ]);

        User::create([
            'nip' => '1000000001',
            'name' => 'Administrator GrowHub',
            'role' => 'admin',
            'department' => 'Human Capital',
            'position' => 'HC System Administrator',
            'email' => 'it18.pepito@rcoid.com',
            'password' => Hash::make('1000000001'),
        ]);

        $this->seed(DatabaseSeeder::class);

        $this->assertSame(20, User::count());
        $this->assertSame(8, Category::count());
        $this->assertSame('it18.pepito@rcoid.com', User::where('nip', '1000000001')->value('email'));
        $this->assertNotSame('it18.pepito@rcoid.com', User::where('nip', '1000000002')->value('email'));
    }
}

