<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Comment;
use App\Models\Community;
use App\Models\Content;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HomeFeedAndPrivacyTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role = 'employee', string $nip = '202604001', int $points = 20): User
    {
        return User::create([
            'nip' => $nip,
            'name' => ucfirst($role).' '.$nip,
            'email' => "{$role}.{$nip}@growhub.co.id",
            'password' => Hash::make($nip),
            'role' => $role,
            'department' => 'Store Operations',
            'position' => 'Staff',
            'points' => $points,
            'last_activity_date' => today(),
            'is_active' => true,
            'must_change_password' => false,
        ]);
    }

    public function test_full_feed_with_trending_sort_does_not_drop_older_published_contents(): void
    {
        $author = $this->makeUser('employee', '202604001', 40);
        $viewer = $this->makeUser('employee', '202604002', 20);
        $category = Category::create(['name' => 'Best Practice', 'slug' => 'best-practice']);

        $recent = Content::create([
            'user_id' => $author->id,
            'category_id' => $category->id,
            'title' => 'Konten Baru Hari Ini',
            'body' => 'Isi konten baru.',
            'status' => Content::STATUS_PUBLISHED,
            'published_at' => now()->subDays(2),
            'likes_count' => 1,
        ]);

        $olderThan14Days = Content::create([
            'user_id' => $author->id,
            'category_id' => $category->id,
            'title' => 'Konten 20 Hari Lalu',
            'body' => 'Isi konten 20 hari lalu.',
            'status' => Content::STATUS_PUBLISHED,
            'published_at' => now()->subDays(20),
            'likes_count' => 10,
        ]);

        $olderThan35Days = Content::create([
            'user_id' => $author->id,
            'category_id' => $category->id,
            'title' => 'Konten 35 Hari Lalu',
            'body' => 'Isi konten 35 hari lalu.',
            'status' => Content::STATUS_PUBLISHED,
            'published_at' => now()->subDays(35),
            'likes_count' => 5,
        ]);

        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/contents?sort=trending&per_page=10')
            ->assertOk();

        $ids = collect($response->json('data'))->pluck('id')->all();
        $this->assertSame([$olderThan14Days->id, $olderThan35Days->id, $recent->id], $ids);
    }

    public function test_home_returns_at_most_three_trending_items_and_public_endpoints_omit_nip(): void
    {
        $author = $this->makeUser('employee', '202604011', 100);
        $viewer = $this->makeUser('employee', '202604012', 50);
        $category = Category::create(['name' => 'Tips & Trick', 'slug' => 'tips-trick']);
        $community = Community::create([
            'name' => 'Store Champions',
            'slug' => 'store-champions',
            'created_by' => $author->id,
        ]);
        $community->members()->attach([$author->id, $viewer->id]);

        $created = [];
        for ($i = 1; $i <= 5; $i++) {
            $created[] = Content::create([
                'user_id' => $author->id,
                'category_id' => $category->id,
                'community_id' => $community->id,
                'title' => "Topik {$i}",
                'body' => "Isi topik {$i}",
                'status' => Content::STATUS_PUBLISHED,
                'published_at' => now()->subDays($i * 5),
                'likes_count' => $i * 2,
            ]);
        }

        $parent = Comment::create([
            'content_id' => $created[4]->id,
            'user_id' => $author->id,
            'body' => 'Komentar utama',
        ]);
        Comment::create([
            'content_id' => $created[4]->id,
            'user_id' => $author->id,
            'parent_id' => $parent->id,
            'body' => 'Balasan komentar',
        ]);

        Sanctum::actingAs($viewer);

        // /api/home: max 3 trending items & no NIP in trending/latest/top_weekly
        $home = $this->getJson('/api/home')->assertOk();
        $this->assertCount(3, $home->json('trending'));
        foreach ($home->json('trending') as $item) {
            $this->assertArrayNotHasKey('nip', $item['author']);
        }
        foreach ($home->json('latest') as $item) {
            $this->assertArrayNotHasKey('nip', $item['author']);
        }
        foreach ($home->json('top_weekly') as $leader) {
            $this->assertArrayNotHasKey('nip', $leader);
        }

        // /api/contents & /api/contents/{id}: no author.nip
        $feed = $this->getJson('/api/contents')->assertOk();
        foreach ($feed->json('data') as $item) {
            $this->assertArrayNotHasKey('nip', $item['author']);
        }
        $detail = $this->getJson("/api/contents/{$created[4]->id}")->assertOk();
        $this->assertArrayNotHasKey('nip', $detail->json('content.author'));

        // /api/contents/{id}/comments: no user.nip in comments or replies
        $comments = $this->getJson("/api/contents/{$created[4]->id}/comments")->assertOk()->json();
        $this->assertArrayNotHasKey('nip', $comments[0]['user']);
        $this->assertArrayNotHasKey('nip', $comments[0]['replies'][0]['user']);

        // /api/leaderboard: no nip on leaders or me
        $leaderboard = $this->getJson('/api/leaderboard?period=all')->assertOk();
        foreach ($leaderboard->json('leaders') as $leader) {
            $this->assertArrayNotHasKey('nip', $leader);
        }
        $this->assertArrayNotHasKey('nip', $leaderboard->json('me'));

        // /api/communities/{slug}: no nip on top_members
        $comm = $this->getJson("/api/communities/{$community->slug}")->assertOk();
        foreach ($comm->json('top_members') as $member) {
            $this->assertArrayNotHasKey('nip', $member);
        }

        // /api/users/{other}: omits nip & email; /api/users/{self}: includes nip & email
        $otherProfile = $this->getJson("/api/users/{$author->id}")->assertOk();
        $this->assertArrayNotHasKey('nip', $otherProfile->json('user'));
        $this->assertArrayNotHasKey('email', $otherProfile->json('user'));

        $ownProfile = $this->getJson("/api/users/{$viewer->id}")->assertOk();
        $this->assertSame($viewer->nip, $ownProfile->json('user.nip'));
        $this->assertSame($viewer->email, $ownProfile->json('user.email'));
    }
}

