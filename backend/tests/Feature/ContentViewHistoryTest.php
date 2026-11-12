<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Content;
use App\Models\ContentView;
use App\Models\PointRule;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ContentViewHistoryTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $nip, string $role = 'employee'): User
    {
        return User::create([
            'nip' => $nip,
            'name' => 'User '.$nip,
            'email' => "u{$nip}@growhub.co.id",
            'password' => Hash::make($nip),
            'role' => $role,
            'department' => 'Operations',
            'position' => 'Staff',
            'points' => 10,
            'last_activity_date' => today(),
            'is_active' => true,
            'must_change_password' => false,
        ]);
    }

    public function test_opening_contents_records_deduplicated_user_history_for_home_and_feed(): void
    {
        // Even with content_viewed rule inactive, opened history must still be tracked
        PointRule::where('action', 'content_viewed')->update(['is_active' => false]);

        $author = $this->makeUser('202609001');
        $reader = $this->makeUser('202609002');
        $otherReader = $this->makeUser('202609003');

        $catOps = Category::create(['name' => 'Best Practice', 'slug' => 'best-practice']);
        $catTips = Category::create(['name' => 'Tips & Trick', 'slug' => 'tips-trick']);

        $contents = [];
        foreach (range(1, 7) as $i) {
            $contents[] = Content::create([
                'user_id' => $author->id,
                'category_id' => $i % 2 === 0 ? $catTips->id : $catOps->id,
                'title' => "Published Content {$i}",
                'body' => "Body content {$i}",
                'status' => Content::STATUS_PUBLISHED,
                'published_at' => now()->subDays(10 - $i),
            ]);
        }

        $draftByReader = Content::create([
            'user_id' => $reader->id,
            'category_id' => $catOps->id,
            'title' => 'My Draft Not Published',
            'body' => 'Draft body',
            'status' => Content::STATUS_DRAFT,
        ]);

        // Other user opens content 7; should NOT appear in $reader's history
        Sanctum::actingAs($otherReader);
        $this->getJson("/api/contents/{$contents[6]->id}")->assertOk();

        // Reader opens 6 contents over time (simulated timestamps), then re-opens #0 and opens draft
        Sanctum::actingAs($reader);
        foreach ([0, 1, 2, 3, 4, 5] as $idx) {
            $this->travel(1)->minutes();
            $this->getJson("/api/contents/{$contents[$idx]->id}")->assertOk();
        }

        // Viewing own draft should NOT add it to published reading history
        $this->getJson("/api/contents/{$draftByReader->id}")->assertOk();

        // Re-opening content #0 should move it to first place without creating a duplicate row
        $this->travel(1)->minutes();
        $this->getJson("/api/contents/{$contents[0]->id}")->assertOk();

        $this->assertSame(6, ContentView::where('user_id', $reader->id)->count());

        // Home endpoint returns top 3 opened contents in most-recent-first order + keeps latest & hides author.nip
        $home = $this->getJson('/api/home')->assertOk();
        $recentlyViewed = $home->json('recently_viewed');
        $this->assertCount(3, $recentlyViewed);
        $this->assertSame([
            $contents[0]->id,
            $contents[5]->id,
            $contents[4]->id,
        ], array_column($recentlyViewed, 'id'));

        foreach ($recentlyViewed as $item) {
            $this->assertArrayNotHasKey('nip', $item['author']);
            $this->assertArrayHasKey('viewed_at', $item);
        }

        // Also still preserves 'latest' for mobile compatibility
        $this->assertNotEmpty($home->json('latest'));

        // Dedicated /api/my/history endpoint returns full opened history with last_viewed_at & search support
        $myHistory = $this->getJson('/api/my/history')->assertOk();
        $this->assertSame(6, $myHistory->json('total'));
        $this->assertSame($contents[0]->id, $myHistory->json('data.0.id'));
        $this->assertNotEmpty($myHistory->json('data.0.last_viewed_at'));
        $this->assertArrayNotHasKey('nip', $myHistory->json('data.0.author'));

        $searchHistory = $this->getJson('/api/my/history?q=Published%20Content%204')->assertOk();
        $this->assertSame(1, $searchHistory->json('total'));
        $this->assertSame($contents[3]->id, $searchHistory->json('data.0.id'));

        // Feed history filter returns reader's opened history in viewed order
        $historyFeed = $this->getJson('/api/contents?history=1')->assertOk();
        $this->assertSame(6, $historyFeed->json('total'));
        $this->assertSame($contents[0]->id, $historyFeed->json('data.0.id'));

        // Can combine history filter with category filter
        $filteredHistory = $this->getJson('/api/contents?history=1&category=tips-trick')->assertOk();
        $this->assertSame(3, $filteredHistory->json('total'));
    }
}

