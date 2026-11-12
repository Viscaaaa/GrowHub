import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main/main_navigation_screen.dart';
import 'change_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  final String? noticeMessage;

  const LoginScreen({super.key, this.noticeMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nipController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default demo NIP for quick employee testing
    _nipController.text = '202301002';
    _passwordController.text = '202301002';

    if (widget.noticeMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNotice(widget.noticeMessage!);
      });
    }
  }

  @override
  void dispose() {
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showNotice(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          nip: _nipController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _showServerSettings() {
    final storage = context.read<LocalStorage>();
    final apiClient = context.read<ApiClient>();
    final serverController = TextEditingController(text: storage.getBaseUrl());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Pengaturan Server',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah alamat URL API backend GrowHub jika menggunakan emulator atau perangkat fisik (LAN):',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8000/api',
                labelText: 'Base API URL',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text(
                    'Emulator (10.0.2.2)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      serverController.text = 'http://10.0.2.2:8000/api',
                ),
                ActionChip(
                  label: const Text(
                    'Localhost (127.0.0.1)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      serverController.text = 'http://127.0.0.1:8000/api',
                ),
                ActionChip(
                  label: const Text(
                    'Wi-Fi LAN (192.168.85.44)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      serverController.text = 'http://192.168.85.44:8000/api',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = serverController.text.trim();
              if (newUrl.isNotEmpty) {
                await storage.setBaseUrl(newUrl);
                apiClient.updateBaseUrl(newUrl);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL diperbarui: $newUrl'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.mustChangePassword) {
            showDialog<Object?>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const ChangePasswordDialog(isMandatory: true),
            ).then((result) {
              if (!context.mounted) return;
              if (result is UserModel) {
                context.read<AuthBloc>().add(AuthUserUpdated(result));
              } else {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            });
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          }
        } else if (state is AuthFailure) {
          _showNotice(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Pengaturan Server',
                onPressed: _showServerSettings,
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Header
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.darkForest],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'GrowHub',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkForest,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryLightBorder,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'EMPLOYEE APP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Platform Gamifikasi & Knowledge Sharing Karyawan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Role Restriction Notice Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryLightBorder,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'User employee ini tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkForest,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NIP Input
                      CustomTextField(
                        controller: _nipController,
                        label: 'NIP Karyawan',
                        hint: 'Masukkan 9-10 digit NIP',
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'NIP wajib diisi';
                          }
                          if (!RegExp(r'^\d{9,10}$').hasMatch(val.trim())) {
                            return 'NIP harus terdiri dari 9-10 digit angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Input
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Masukkan password Anda',
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        helperText:
                            'Awal login: password sama dengan NIP Anda.',
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),

                      // Login Button
                      CustomButton(
                        text: 'Masuk Sekarang',
                        isLoading: isLoading,
                        icon: Icons.login,
                        onPressed: _submitLogin,
                      ),
                      const SizedBox(height: 20),

                      // Help text
                      Center(
                        child: Text(
                          'Lupa password? Hubungi Administrator HC/IT cabang Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
