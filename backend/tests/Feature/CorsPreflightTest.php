<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class CorsPreflightTest extends TestCase
{
    use RefreshDatabase;

    public function test_preflight_options_request_for_login_returns_cors_headers(): void
    {
        $response = $this->withHeaders([
            'Origin' => 'http://growhubdev.rcoid.com',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'content-type,authorization',
        ])->options('/api/auth/login');

        $response->assertStatus(204);
        $response->assertHeader('Access-Control-Allow-Origin', '*');
        $this->assertStringContainsString('POST', strtoupper((string) $response->headers->get('Access-Control-Allow-Methods')));
        $this->assertStringContainsString('content-type', strtolower((string) $response->headers->get('Access-Control-Allow-Headers')));
    }

    public function test_cross_origin_login_and_error_responses_include_cors_headers(): void
    {
        User::create([
            'nip' => '202609001',
            'name' => 'Deploy Test User',
            'email' => 'deploy.test@growhub.co.id',
            'password' => Hash::make('202609001'),
            'role' => 'employee',
            'department' => 'IT',
            'position' => 'Staff',
            'is_active' => true,
            'must_change_password' => false,
        ]);

        // Valid login
        $this->withHeaders(['Origin' => 'http://growhubdev.rcoid.com'])
            ->postJson('/api/auth/login', [
                'nip' => '202609001',
                'password' => '202609001',
            ])
            ->assertOk()
            ->assertHeader('Access-Control-Allow-Origin', '*');

        // Validation error (422)
        $this->withHeaders(['Origin' => 'http://growhubdev.rcoid.com'])
            ->postJson('/api/auth/login', [
                'nip' => '202609001',
                'password' => 'wrong-password',
            ])
            ->assertStatus(422)
            ->assertHeader('Access-Control-Allow-Origin', '*');

        // Missing endpoint (404)
        $this->withHeaders(['Origin' => 'http://growhubdev.rcoid.com'])
            ->getJson('/api/non-existent-endpoint')
            ->assertStatus(404)
            ->assertHeader('Access-Control-Allow-Origin', '*');
    }
}

