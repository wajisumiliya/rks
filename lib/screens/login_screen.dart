import 'package:flutter/material.dart';

import '../services/app_service.dart';
import '../services/notification_service.dart';
import 'admin_dashboard.dart';
import 'branch_dashboard.dart';
import 'employee_portal.dart';
import 'request_admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.showThemePreview = false});

  final bool showThemePreview;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppService service = AppService.instance;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await service.restore();

      if (!mounted) return;

      final user = service.currentUser;

      if (user != null) {
        _openCorrectPortal(user);
      }
    } catch (_) {
      // Session restoration failure is handled by the normal login flow.
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _showForgotPasswordDialog() async {
    final username =
        TextEditingController(text: usernameController.text.trim());
    final identity = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    String? resetToken;
    String? dialogError;
    bool submitting = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final completed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (submitting) return;
            if (resetToken == null) {
              if (username.text.trim().isEmpty ||
                  identity.text.trim().isEmpty) {
                setDialogState(
                    () => dialogError = 'Enter your username and IC number.');
                return;
              }
              setDialogState(() {
                submitting = true;
                dialogError = null;
              });
              final result = await service.verifyForgotPasswordIdentity(
                username: username.text,
                identityNumber: identity.text,
              );
              if (!dialogContext.mounted) return;
              setDialogState(() {
                submitting = false;
                if (result['ok'] == true && result['resetToken'] != null) {
                  resetToken = result['resetToken'].toString();
                } else {
                  dialogError = result['message']?.toString() ??
                      'The details entered do not match.';
                }
              });
              return;
            }

            if (newPassword.text.length < 8) {
              setDialogState(() =>
                  dialogError = 'Password must contain at least 8 characters.');
              return;
            }
            if (newPassword.text != confirmPassword.text) {
              setDialogState(() => dialogError = 'New passwords do not match.');
              return;
            }
            setDialogState(() {
              submitting = true;
              dialogError = null;
            });
            final result = await service.resetForgottenPassword(
              resetToken: resetToken!,
              newPassword: newPassword.text,
            );
            if (!dialogContext.mounted) return;
            if (result['ok'] == true) {
              Navigator.of(dialogContext).pop(true);
            } else {
              setDialogState(() {
                submitting = false;
                dialogError = result['message']?.toString() ??
                    'Unable to reset your password.';
              });
            }
          }

          InputDecoration fieldDecoration(String label, IconData icon) =>
              InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                  border: const OutlineInputBorder());

          return AlertDialog(
            title: Text(
                resetToken == null ? 'Forgot Password' : 'Create New Password'),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(resetToken == null
                      ? 'Verify your account using the IC number in your employee record.'
                      : 'Identity verified. Choose a new password for your account.'),
                  const SizedBox(height: 18),
                  if (resetToken == null) ...[
                    TextField(
                        controller: username,
                        enabled: !submitting,
                        decoration: fieldDecoration(
                            'Username / Employee ID', Icons.person_outline)),
                    const SizedBox(height: 14),
                    TextField(
                        controller: identity,
                        enabled: !submitting,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submit(),
                        decoration:
                            fieldDecoration('IC Number', Icons.badge_outlined)),
                  ] else ...[
                    TextField(
                        controller: newPassword,
                        enabled: !submitting,
                        obscureText: obscureNew,
                        decoration:
                            fieldDecoration('New Password', Icons.lock_outline)
                                .copyWith(
                                    suffixIcon: IconButton(
                                        onPressed: () => setDialogState(
                                            () => obscureNew = !obscureNew),
                                        icon: Icon(obscureNew
                                            ? Icons.visibility
                                            : Icons.visibility_off)))),
                    const SizedBox(height: 14),
                    TextField(
                        controller: confirmPassword,
                        enabled: !submitting,
                        obscureText: obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submit(),
                        decoration: fieldDecoration(
                                'Confirm New Password', Icons.lock_reset)
                            .copyWith(
                                suffixIcon: IconButton(
                                    onPressed: () => setDialogState(
                                        () => obscureConfirm = !obscureConfirm),
                                    icon: Icon(obscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off)))),
                  ],
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(dialogError!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(
                  onPressed:
                      submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL')),
              FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(resetToken == null
                          ? 'VERIFY IDENTITY'
                          : 'RESET PASSWORD')),
            ],
          );
        },
      ),
    );
    username.dispose();
    identity.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    if (completed == true && mounted) {
      passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Password reset successfully. Sign in with your new password.'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty) {
      _showError(
        'Please enter your username or Employee ID.',
      );
      return;
    }

    if (password.isEmpty) {
      _showError(
        'Please enter your password.',
      );
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await service.login(
        username,
        password,
      );

      if (!mounted) return;

      // ==========================================================
      // LOGIN FAILED
      // ==========================================================

      if (result != null && result != 'FIRST_LOGIN_PASSWORD_REQUIRED') {
        setState(() {
          loading = false;
          errorMessage = result;
        });


        return;
      }

      // ==========================================================
      // FIRST LOGIN
      //
      // The backend/app service has detected that the employee
      // must create a new password before opening the dashboard.
      // ==========================================================

      if (result == 'FIRST_LOGIN_PASSWORD_REQUIRED') {
        setState(() {
          loading = false;
        });

        await _showFirstLoginPasswordDialog();


        return;
      }

      // ==========================================================
      // NORMAL LOGIN SUCCESS
      // ==========================================================

      final user = service.currentUser;

      if (user == null) {
        setState(() {
          loading = false;

          errorMessage =
              'Login succeeded, but your account information could not be loaded.';
        });


        return;
      }

      setState(() {
        loading = false;
      });

      // Request-admin accounts do not represent an employee or branch device.
      // Notification setup must never prevent a successful login.
      if (!user.isRequestAdmin) {
        try {
          await NotificationService.registerCurrentDevice(
            employeeId: user.employeeId,
            branchId: user.branchId,
          );
        } catch (_) {
          // Device notification registration is best-effort.
        }
      }

      if (!mounted) return;
      _openCorrectPortal(user);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;

        errorMessage = 'Unable to connect to the payroll server. '
            'Please check your connection and try again.';
      });
    }
  }

  // ============================================================
  // FIRST LOGIN PASSWORD CHANGE
  // ============================================================

  Future<void> _showFirstLoginPasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool savingPassword = false;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> savePassword() async {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (newPassword.length < 8) {
                  setDialogState(() {
                    dialogError =
                        'Password must contain at least 8 characters.';
                  });
                  return;
                }

                if (newPassword != confirmPassword) {
                  setDialogState(() {
                    dialogError = 'New passwords do not match.';
                  });
                  return;
                }

                if (newPassword == passwordController.text) {
                  setDialogState(() {
                    dialogError =
                        'Your new password must be different from the default password.';
                  });
                  return;
                }

                setDialogState(() {
                  savingPassword = true;
                  dialogError = null;
                });

                final result = await service.completeFirstLogin(newPassword);

                if (!mounted || !dialogContext.mounted) return;

                if (result != null) {
                  setDialogState(() {
                    savingPassword = false;
                    dialogError = result;
                  });
                  return;
                }

                Navigator.of(dialogContext).pop();
                passwordController.clear();

                final user = service.currentUser;
                if (user != null) {
                  try {
                    await NotificationService.registerCurrentDevice(
                      employeeId: user.employeeId,
                      branchId: user.branchId,
                    );
                  } catch (_) {
                    // Notification setup must not block first-login completion.
                  }
                  if (mounted) _openCorrectPortal(user);
                }
              }

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded),
                    SizedBox(width: 12),
                    Expanded(child: Text('Create Your New Password')),
                  ],
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This is your first login. You must replace the default password before opening your dashboard.',
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: newPasswordController,
                          obscureText: obscureNewPassword,
                          enabled: !savingPassword,
                          autofocus: true,
                          decoration: _inputDecoration(
                            'New Password',
                            Icons.lock_outline,
                          ).copyWith(
                            helperText: 'Use at least 8 characters.',
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(() {
                                obscureNewPassword = !obscureNewPassword;
                              }),
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          enabled: !savingPassword,
                          onSubmitted: (_) {
                            if (!savingPassword) savePassword();
                          },
                          decoration: _inputDecoration(
                            'Retype New Password',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              }),
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            dialogError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: savingPassword ? null : savePassword,
                            icon: savingPassword
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              savingPassword
                                  ? 'SAVING...'
                                  : 'SAVE PASSWORD & CONTINUE',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: savingPassword
                        ? null
                        : () {
                            service.cancelFirstLoginOtp();
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('CANCEL'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  // ============================================================
  // PORTAL ROUTING
  // ============================================================

  void _openCorrectPortal(dynamic user) {
    if (!mounted) return;

    if (user.isAdmin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.staffScope == 'requests'
              ? const RequestAdminDashboard()
              : const AdminDashboard(),
        ),
      );
      return;
    }

    if (user.isBranch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const BranchPortal(),
        ),
      );
      return;
    }

    if (user.isEmployee) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EmployeePortal(),
        ),
      );
      return;
    }

    setState(() {
      loading = false;

      errorMessage = 'Your account does not have a valid portal role.';
    });
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      errorMessage = message;
    });
  }


  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF12243C);
    const blue = Color(0xFF2459C4);
    const muted = Color(0xFF526279);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login_office_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xA8112037), Color(0x40112037)],
              ),
            ),
          ),
          SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 40 : 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 920 : 460),
              child: Material(
                color: Colors.white,
                elevation: 3,
                shadowColor: const Color(0x26203960),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    if (wide)
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 535),
                          padding: const EdgeInsets.all(44),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [navy, Color(0xFF225079)],
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 44, color: Color(0xFF9DC2FF)),
                              SizedBox(height: 88),
                              Text('Company Payroll',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  )),
                              SizedBox(height: 16),
                              Text(
                                'Access payroll, attendance and employee records from one place.',
                                style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Color(0xFFD3E0F3)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(wide ? 46 : 24),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Image.asset(
                                  'assets/hasani_books_logo.jpg',
                                  width: 88,
                                  height: 58,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text('Sign in',
                                  style: TextStyle(
                                      color: navy,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              const Text('Use your payroll account to continue.',
                                  style: TextStyle(color: muted)),
                              const SizedBox(height: 26),
                              TextField(
                                controller: usernameController,
                                enabled: !loading,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Username or email',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: passwordController,
                                enabled: !loading,
                                autofillHints: const [AutofillHints.password],
                                obscureText: obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!loading) _login();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    tooltip: obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(
                                        () => obscurePassword = !obscurePassword),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: loading ? null : _showForgotPasswordDialog,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              if (errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(errorMessage!,
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.error)),
                                  ),
                                ),
                              FilledButton(
                                onPressed: loading ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: blue,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                child: loading
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}
