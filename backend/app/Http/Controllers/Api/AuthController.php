<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\GamificationService;
use App\Services\PasswordOtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function __construct(
        private GamificationService $gamification,
        private PasswordOtpService $otpService,
    ) {}

    public function login(Request $request)
    {
        $data = $request->validate([
            'nip' => ['required', 'regex:/^\d{9,10}$/'],
            'password' => ['required', 'string'],
        ], [
            'nip.regex' => 'NIP harus terdiri dari 9 - 10 digit angka.',
        ]);

        $user = User::where('nip', $data['nip'])->first();

        $validPassword = $user && Hash::check($data['password'], $user->password);

        if (! $validPassword) {
            throw ValidationException::withMessages(['nip' => 'NIP atau password salah.']);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages(['nip' => 'Akun Anda dinonaktifkan. Hubungi administrator.']);
        }

        $this->gamification->recordActivity($user);

        $token = $user->createToken('growhub-web')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($this->userPayload($request->user()->fresh()));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Berhasil logout.']);
    }

    public function sendChangePasswordOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($denied = $this->ensureCanChangePassword($user)) {
            return $denied;
        }

        $result = $this->otpService->sendOtp($user, 'first_change_password');

        return response()->json($result);
    }

    public function verifyChangePasswordOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($denied = $this->ensureCanChangePassword($user)) {
            return $denied;
        }

        $data = $request->validate([
            'otp' => ['required', 'digits:6'],
        ], [
            'otp.required' => 'Kode OTP wajib diisi.',
            'otp.digits' => 'Kode OTP harus terdiri dari 6 digit angka.',
        ]);

        $token = $this->otpService->verifyOtp($user, $data['otp'], 'first_change_password');

        return response()->json([
            'message' => 'Kode OTP berhasil diverifikasi. Silakan buat password baru Anda.',
            'otp_verification_token' => $token,
        ]);
    }

    public function firstChangePassword(Request $request)
    {
        $user = $request->user();

        if ($denied = $this->ensureCanChangePassword($user)) {
            return $denied;
        }

        $data = $request->validate([
            'otp_verification_token' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ], [
            'otp_verification_token.required' => 'Verifikasi OTP email diperlukan sebelum mengganti password.',
            'password.required' => 'Password baru wajib diisi.',
            'password.min' => 'Password baru minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password baru tidak cocok.',
        ]);

        if ($data['password'] === $user->nip) {
            throw ValidationException::withMessages([
                'password' => 'Password baru tidak boleh sama dengan NIP default.',
            ]);
        }

        $otpRecord = $this->otpService->validateVerifiedToken(
            $user,
            $data['otp_verification_token'],
            'first_change_password'
        );

        DB::transaction(function () use ($user, $data, $otpRecord) {
            $user->update([
                'password' => $data['password'],
                'must_change_password' => false,
            ]);

            $otpRecord->update([
                'used_at' => now(),
            ]);

            $currentToken = $user->currentAccessToken();
            if ($currentToken instanceof PersonalAccessToken) {
                $user->tokens()->where('id', '!=', $currentToken->id)->delete();
            } else {
                $user->tokens()->delete();
            }
        });

        return response()->json([
            'message' => 'Password berhasil diperbarui. Selamat datang di GrowHub!',
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    private function ensureCanChangePassword(User $user): ?JsonResponse
    {
        // If user is not required to change password and is not admin, prevent self-reset
        if (! $user->must_change_password && $user->role !== 'admin') {
            return response()->json([
                'message' => 'Reset password mandiri dinonaktifkan. Password hanya dapat direset oleh Administrator.',
            ], 403);
        }

        return null;
    }

    private function userPayload(User $user): array
    {
        return array_merge($user->toArray(), [
            'is_reviewer' => $user->isReviewer(),
            'unread_notifications' => $user->appNotifications()->whereNull('read_at')->count(),
            'points_today' => (int) $user->pointTransactions()->whereDate('created_at', today())->sum('points'),
            'default_password' => Hash::check($user->nip, $user->password),
            'must_change_password' => (bool) $user->must_change_password,
            'has_email' => ! empty($user->email),
            'masked_email' => ! empty($user->email) ? $this->otpService->maskEmail($user->email) : null,
        ]);
    }
}
