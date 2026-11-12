<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Content;
use App\Models\User;
use App\Services\PasswordOtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class ProfileController extends Controller
{
    public function __construct(private PasswordOtpService $otpService) {}
    /** Profil publik user lain / diri sendiri */
    public function show(Request $request, User $user)
    {
        $published = $user->contents()->published();

        $fields = ['id', 'name', 'department', 'position', 'location', 'bio', 'points', 'current_streak', 'longest_streak', 'avatar_url', 'level_info', 'role', 'created_at'];
        if ($request->user()?->id === $user->id) {
            $fields[] = 'email';
            $fields[] = 'nip';
        }

        return response()->json([
            'user' => $user->only($fields),
            'rank' => User::where('is_active', true)->where('points', '>', $user->points)->count() + 1,
            'stats' => [
                'contents' => (clone $published)->count(),
                'likes' => (int) (clone $published)->sum('likes_count'),
                'comments' => (int) (clone $published)->sum('comments_count'),
                'views' => (int) (clone $published)->sum('views_count'),
                'communities' => $user->communities()->count(),
                'courses' => $user->completedCourses()->count(),
            ],
            'contents' => Content::published()->where('user_id', $user->id)
                ->with([ContentController::AUTHOR_COLUMNS, 'category', 'media'])
                ->withViewerState($request->user())
                ->latest('published_at')->limit(12)->get(),
            'communities' => $user->communities()->select('communities.id', 'name', 'slug', 'icon', 'color')->get(),
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:150', 'unique:users,email,'.$user->id],
            'bio' => ['nullable', 'string', 'max:300'],
            'location' => ['nullable', 'string', 'max:100'],
        ], [
            'email.required' => 'Email wajib diisi untuk keperluan verifikasi OTP.',
        ]);

        $user->update($data);

        return response()->json(['message' => 'Profil diperbarui.', 'user' => $user->fresh()]);
    }

    public function avatar(Request $request)
    {
        $request->validate(['avatar' => ['required', 'image', 'max:3072']]);
        $user = $request->user();

        if ($user->avatar) {
            Storage::disk('public')->delete($user->avatar);
        }
        $user->update(['avatar' => $request->file('avatar')->store('avatars', 'public')]);

        return response()->json(['message' => 'Foto profil diperbarui.', 'user' => $user->fresh()]);
    }

    public function sendPasswordOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($denied = $this->ensureCanUpdatePassword($user)) {
            return $denied;
        }

        $result = $this->otpService->sendOtp($user, 'profile_change_password');

        return response()->json($result);
    }

    public function verifyPasswordOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($denied = $this->ensureCanUpdatePassword($user)) {
            return $denied;
        }

        $data = $request->validate([
            'otp' => ['required', 'digits:6'],
        ], [
            'otp.required' => 'Kode OTP wajib diisi.',
            'otp.digits' => 'Kode OTP harus terdiri dari 6 digit angka.',
        ]);

        $token = $this->otpService->verifyOtp($user, $data['otp'], 'profile_change_password');

        return response()->json([
            'message' => 'Kode OTP berhasil diverifikasi.',
            'otp_verification_token' => $token,
        ]);
    }

    public function password(Request $request)
    {
        $user = $request->user();

        if ($denied = $this->ensureCanUpdatePassword($user)) {
            return $denied;
        }

        $data = $request->validate([
            'otp_verification_token' => ['required', 'string'],
            'current_password' => ['required'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ], [
            'otp_verification_token.required' => 'Verifikasi OTP email diperlukan sebelum mengubah password.',
            'password.min' => 'Password baru minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak sama.',
        ]);

        if (! Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages(['current_password' => 'Password saat ini salah.']);
        }

        $otpRecord = $this->otpService->validateVerifiedToken(
            $user,
            $data['otp_verification_token'],
            'profile_change_password'
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

        return response()->json(['message' => 'Password berhasil diubah.']);
    }

    private function ensureCanUpdatePassword(User $user): ?JsonResponse
    {
        // Self-service password change is restricted: only admin can freely change, or users required to change
        if ($user->role !== 'admin' && ! $user->must_change_password) {
            return response()->json([
                'message' => 'Reset password mandiri dinonaktifkan. Password hanya dapat direset oleh Administrator.',
            ], 403);
        }

        return null;
    }
}
