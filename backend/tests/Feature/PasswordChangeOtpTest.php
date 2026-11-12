<?php

namespace Tests\Feature;

use App\Mail\PasswordOtpMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PasswordChangeOtpTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_without_email_cannot_send_change_password_otp(): void
    {
        Mail::fake();

        $user = User::create([
            'nip' => '202601001',
            'name' => 'No Email User',
            'email' => null,
            'password' => Hash::make('202601001'),
            'role' => 'employee',
            'must_change_password' => true,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        $response = $this->postJson('/api/auth/change-password/send-otp');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        Mail::assertNothingSent();
    }

    public function test_first_change_password_requires_email_otp_verification(): void
    {
        Mail::fake();

        $user = User::create([
            'nip' => '202601002',
            'name' => 'Email User',
            'email' => 'email.user@growhub.co.id',
            'password' => Hash::make('202601002'),
            'role' => 'employee',
            'must_change_password' => true,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        // Cannot bypass OTP step directly
        $this->postJson('/api/auth/first-change-password', [
            'password' => 'NewSecret123!',
            'password_confirmation' => 'NewSecret123!',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['otp_verification_token']);

        // Send OTP to registered email
        $capturedOtp = null;
        $this->postJson('/api/auth/change-password/send-otp')
            ->assertOk()
            ->assertJsonStructure(['message', 'masked_email', 'expires_in', 'resend_cooldown']);

        Mail::assertSent(PasswordOtpMail::class, function (PasswordOtpMail $mail) use ($user, &$capturedOtp) {
            $capturedOtp = $mail->otpCode;

            return $mail->hasTo($user->email) && strlen($mail->otpCode) === 6;
        });

        // Resend within cooldown returns 429
        $this->postJson('/api/auth/change-password/send-otp')
            ->assertStatus(429);

        // Wrong OTP is rejected
        $wrongOtp = $capturedOtp === '000000' ? '111111' : '000000';
        $this->postJson('/api/auth/change-password/verify-otp', [
            'otp' => $wrongOtp,
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['otp']);

        // Correct OTP returns verification token
        $verifyRes = $this->postJson('/api/auth/change-password/verify-otp', [
            'otp' => $capturedOtp,
        ])->assertOk()
            ->assertJsonStructure(['message', 'otp_verification_token']);

        $token = $verifyRes->json('otp_verification_token');

        // Change password succeeds with verification token
        $this->postJson('/api/auth/first-change-password', [
            'otp_verification_token' => $token,
            'password' => 'NewSecret123!',
            'password_confirmation' => 'NewSecret123!',
        ])->assertOk()
            ->assertJsonPath('user.must_change_password', false);

        $user->refresh();
        $this->assertFalse((bool) $user->must_change_password);
        $this->assertTrue(Hash::check('NewSecret123!', $user->password));

        // Same token cannot be reused
        $user->update(['must_change_password' => true]);
        $this->postJson('/api/auth/first-change-password', [
            'otp_verification_token' => $token,
            'password' => 'AnotherPass123!',
            'password_confirmation' => 'AnotherPass123!',
        ])->assertStatus(422);
    }

    public function test_admin_must_provide_email_when_creating_or_updating_user(): void
    {
        $admin = User::create([
            'nip' => '1000000099',
            'name' => 'Admin Test',
            'email' => 'admin.test@growhub.co.id',
            'password' => Hash::make('AdminPass123!'),
            'role' => 'admin',
            'must_change_password' => false,
            'is_active' => true,
        ]);

        Sanctum::actingAs($admin);

        $this->postJson('/api/admin/users', [
            'nip' => '202601009',
            'name' => 'Missing Email',
            'role' => 'employee',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        $createRes = $this->postJson('/api/admin/users', [
            'nip' => '202601009',
            'name' => 'Valid Email User',
            'email' => 'valid.user@growhub.co.id',
            'role' => 'employee',
        ])->assertStatus(201);

        $createdId = $createRes->json('user.id');

        $this->putJson("/api/admin/users/{$createdId}", [
            'name' => 'Valid Email User',
            'email' => '',
            'role' => 'employee',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_profile_password_update_requires_otp_verification(): void
    {
        Mail::fake();

        $admin = User::create([
            'nip' => '1000000088',
            'name' => 'Admin Profile',
            'email' => 'admin.profile@growhub.co.id',
            'password' => Hash::make('OldPassword1!'),
            'role' => 'admin',
            'must_change_password' => false,
            'is_active' => true,
        ]);

        Sanctum::actingAs($admin);

        $capturedOtp = null;
        $this->postJson('/api/profile/password/send-otp')->assertOk();

        Mail::assertSent(PasswordOtpMail::class, function (PasswordOtpMail $mail) use ($admin, &$capturedOtp) {
            $capturedOtp = $mail->otpCode;

            return $mail->hasTo($admin->email);
        });

        $token = $this->postJson('/api/profile/password/verify-otp', [
            'otp' => $capturedOtp,
        ])->assertOk()->json('otp_verification_token');

        $this->putJson('/api/profile/password', [
            'otp_verification_token' => $token,
            'current_password' => 'OldPassword1!',
            'password' => 'NewPassword2!',
            'password_confirmation' => 'NewPassword2!',
        ])->assertOk();

        $this->assertTrue(Hash::check('NewPassword2!', $admin->fresh()->password));
    }

    public function test_otp_expires_after_one_minute(): void
    {
        Mail::fake();

        $user = User::create([
            'nip' => '202601003',
            'name' => 'Expiry User',
            'email' => 'expiry.user@growhub.co.id',
            'password' => Hash::make('202601003'),
            'role' => 'employee',
            'must_change_password' => true,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        $capturedOtp = null;
        $this->postJson('/api/auth/change-password/send-otp')
            ->assertOk()
            ->assertJsonPath('expires_in', 60);

        Mail::assertSent(PasswordOtpMail::class, function (PasswordOtpMail $mail) use (&$capturedOtp) {
            $capturedOtp = $mail->otpCode;

            return $mail->expiresMinutes === 1;
        });

        $this->travel(61)->seconds();

        $this->postJson('/api/auth/change-password/verify-otp', [
            'otp' => $capturedOtp,
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['otp']);
    }

    public function test_old_password_and_local_default_passwords_are_rejected_after_password_change(): void
    {
        Mail::fake();
        $this->app->detectEnvironment(fn () => 'local');

        $admin = User::create([
            'nip' => '1000000095',
            'name' => 'Admin Reset',
            'email' => 'admin.reset@growhub.co.id',
            'password' => Hash::make('1000000095'),
            'role' => 'admin',
            'must_change_password' => false,
            'is_active' => true,
        ]);

        $user = User::create([
            'nip' => '202601004',
            'name' => 'Target User',
            'email' => 'target.user@growhub.co.id',
            'password' => Hash::make('PreviousPass1!'),
            'role' => 'employee',
            'must_change_password' => false,
            'is_active' => true,
        ]);

        // 1. Admin logs in with real token and resets user password to default NIP
        $adminToken = $this->postJson('/api/auth/login', [
            'nip' => $admin->nip,
            'password' => $admin->nip,
        ])->assertOk()->json('token');

        $this->withToken($adminToken)->postJson("/api/admin/users/{$user->id}/reset-password")->assertOk();
        $this->app['auth']->forgetGuards();

        // 2. User logs in using default NIP (now hashed as current password)
        $loginRes = $this->withoutToken()->postJson('/api/auth/login', [
            'nip' => $user->nip,
            'password' => $user->nip,
        ])->assertOk();
        $this->assertSame($user->id, $loginRes->json('user.id'));
        $token = $loginRes->json('token');
        $this->app['auth']->forgetGuards();

        // 3. User verifies email OTP and sets a new password
        $capturedOtp = null;
        $this->withToken($token)->postJson('/api/auth/change-password/send-otp')->assertOk();
        Mail::assertSent(PasswordOtpMail::class, function (PasswordOtpMail $mail) use ($user, &$capturedOtp) {
            $capturedOtp = $mail->otpCode;
            $this->assertSame($user->id, $mail->user->id);
            $this->assertSame($user->email, $mail->user->email);

            return true;
        });

        $otpToken = $this->withToken($token)->postJson('/api/auth/change-password/verify-otp', [
            'otp' => $capturedOtp,
        ])->assertOk()->json('otp_verification_token');

        $this->withToken($token)->postJson('/api/auth/first-change-password', [
            'otp_verification_token' => $otpToken,
            'password' => 'BrandNewPass99!',
            'password_confirmation' => 'BrandNewPass99!',
        ])->assertOk();

        $this->assertTrue(Hash::check('BrandNewPass99!', $user->fresh()->password));
        $this->app['auth']->forgetGuards();

        // 4. Old passwords & common default strings must ALL fail login, even in local env
        foreach ([$user->nip, 'PreviousPass1!', 'password', 'admin', 'admin123'] as $invalidPass) {
            $this->postJson('/api/auth/login', [
                'nip' => $user->nip,
                'password' => $invalidPass,
            ])->assertStatus(422)
                ->assertJsonValidationErrors(['nip']);
        }

        // 5. Only the new password succeeds
        $this->postJson('/api/auth/login', [
            'nip' => $user->nip,
            'password' => 'BrandNewPass99!',
        ])->assertOk()
            ->assertJsonStructure(['token', 'user']);
    }
}

