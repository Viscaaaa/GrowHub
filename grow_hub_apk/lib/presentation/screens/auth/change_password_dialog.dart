import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ChangePasswordDialog extends StatefulWidget {
  final bool isMandatory;

  const ChangePasswordDialog({super.key, this.isMandatory = true});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpVerified = false;
  bool _otpSent = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _submittingPassword = false;
  int _resendCountdown = 0;
  Timer? _cooldownTimer;

  String? _otpVerificationToken;
  String? _maskedEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userEmail.isNotEmpty) {
        _sendOtp();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _userEmail {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.email ?? '';
    }
    return context.read<AuthRepository>().localStorage.getUser()?.email ?? '';
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _resendCountdown = seconds > 0 ? seconds : 0;
    });
    if (_resendCountdown <= 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_userEmail.isEmpty) {
      setState(() {
        _errorMessage =
            'Akun Anda belum memiliki alamat email terdaftar. Silakan hubungi Administrator.';
      });
      return;
    }

    setState(() {
      _sendingOtp = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> res;
      if (widget.isMandatory) {
        res = await context.read<AuthRepository>().sendChangePasswordOtp();
      } else {
        res = await context.read<ProfileRepository>().sendPasswordOtp();
      }

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _maskedEmail = res['masked_email'] as String? ?? _userEmail;
      });
      final cooldown = res['resend_cooldown'] is int
          ? res['resend_cooldown'] as int
          : int.tryParse('${res['resend_cooldown']}') ?? 60;
      _startCooldown(cooldown);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 429) {
        setState(() {
          _otpSent = true;
          _errorMessage = e.message;
        });
        _startCooldown(60);
      } else {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengirim kode OTP. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _verifyingOtp = true;
      _errorMessage = null;
    });

    try {
      final String token;
      if (widget.isMandatory) {
        token = await context
            .read<AuthRepository>()
            .verifyChangePasswordOtp(otp: _otpController.text.trim());
      } else {
        token = await context
            .read<ProfileRepository>()
            .verifyPasswordOtp(otp: _otpController.text.trim());
      }

      if (!mounted) return;
      setState(() {
        _otpVerificationToken = token;
        _otpVerified = true;
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memverifikasi kode OTP.');
    } finally {
      if (mounted) {
        setState(() => _verifyingOtp = false);
      }
    }
  }

  Future<void> _submitPassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    if (_otpVerificationToken == null || _otpVerificationToken!.isEmpty) {
      setState(() {
        _otpVerified = false;
        _errorMessage = 'Silakan verifikasi kode OTP terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _submittingPassword = true;
      _errorMessage = null;
    });

    try {
      if (widget.isMandatory) {
        final updatedUser =
            await context.read<AuthRepository>().firstChangePassword(
                  otpVerificationToken: _otpVerificationToken!,
                  password: _newPasswordController.text,
                  passwordConfirmation: _confirmPasswordController.text,
                );
        if (!mounted) return;
        Navigator.of(context).pop(updatedUser);
      } else {
        await context.read<ProfileRepository>().changePassword(
              otpVerificationToken: _otpVerificationToken!,
              currentPassword: _currentPasswordController.text,
              newPassword: _newPasswordController.text,
              confirmPassword: _confirmPasswordController.text,
            );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final hasOtpTokenErr = e.errors?.containsKey('otp_token') == true ||
          e.errors?.containsKey('otp_verification_token') == true;
      if (hasOtpTokenErr) {
        setState(() {
          _otpVerified = false;
          _otpVerificationToken = null;
          _otpController.clear();
          _errorMessage = e.message;
        });
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memperbarui password.');
    } finally {
      if (mounted) {
        setState(() => _submittingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = _userEmail.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _otpVerified
                        ? AppColors.primaryLight
                        : AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _otpVerified
                        ? Icons.lock_reset
                        : Icons.mark_email_read_outlined,
                    color: _otpVerified ? AppColors.primary : AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otpVerified
                            ? 'Ganti Password Baru'
                            : 'Verifikasi OTP Email',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _otpVerified
                            ? 'Langkah 2 dari 2 • Buat password baru'
                            : 'Langkah 1 dari 2 • Autentikasi kode OTP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (!hasEmail) ...[
              const Text(
                'Akun Anda belum memiliki email terdaftar untuk menerima kode OTP. Hubungi Administrator untuk melengkapi data email Anda terlebih dahulu.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: widget.isMandatory ? 'Kembali ke Login' : 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ] else if (!_otpVerified) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLightBorder),
                ),
                child: Text(
                  _sendingOtp
                      ? 'Mengirim kode OTP 6 digit ke email terdaftar Anda...'
                      : _otpSent
                          ? 'Kode OTP 6 digit telah dikirim ke ${_maskedEmail ?? _userEmail}. Berlaku 1 menit.'
                          : 'Kirim kode OTP verifikasi ke email ${_maskedEmail ?? _userEmail}.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.darkForest,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _otpFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kode OTP (6 Digit)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        counterText: '',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 6) {
                          return 'Masukkan 6 digit kode OTP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tidak menerima kode?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: (_sendingOtp || _resendCountdown > 0)
                              ? null
                              : _sendOtp,
                          child: Text(
                            _sendingOtp
                                ? 'Mengirim...'
                                : _resendCountdown > 0
                                    ? 'Kirim Ulang (${_resendCountdown}s)'
                                    : (_otpSent
                                        ? 'Kirim Ulang OTP'
                                        : 'Kirim Kode OTP'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _verifyingOtp
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              widget.isMandatory ? 'Batal' : 'Tutup',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: 'Verifikasi OTP',
                            isLoading: _verifyingOtp,
                            onPressed: _verifyingOtp ? null : _verifyOtp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isMandatory
                          ? 'OTP berhasil diverifikasi. Silakan buat password baru minimal 8 karakter.'
                          : 'OTP berhasil diverifikasi. Masukkan password saat ini dan password baru Anda.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!widget.isMandatory) ...[
                      CustomTextField(
                        controller: _currentPasswordController,
                        label: 'Password Saat Ini',
                        hint: 'Masukkan password saat ini',
                        isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password saat ini wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'Password Baru',
                      hint: 'Minimal 8 karakter',
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password baru wajib diisi';
                        }
                        if (val.length < 8) {
                          return 'Minimal 8 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Password Baru',
                      hint: 'Ulangi password baru',
                      isPassword: true,
                      validator: (val) {
                        if (val != _newPasswordController.text) {
                          return 'Konfirmasi password tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        if (!widget.isMandatory)
                          Expanded(
                            child: TextButton(
                              onPressed: _submittingPassword
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: 'Simpan Password',
                            isLoading: _submittingPassword,
                            onPressed:
                                _submittingPassword ? null : _submitPassword,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
