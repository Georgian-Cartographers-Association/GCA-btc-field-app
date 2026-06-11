import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = await ref.read(authFormProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (uid == null || !mounted) return;
    await _handleMigration(uid);
  }

  Future<void> _handleMigration(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final upload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.migrateLocalTitle),
        content: Text(l10n.migrateLocalContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('არა'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.upload),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (upload == true) {
      final count =
          await ref.read(authFormProvider.notifier).uploadLocalData(uid);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count != null
                ? l10n.uploadSuccess(count)
                : l10n.uploadFailed),
          ),
        );
      }
    }

    await ref.read(authFormProvider.notifier).activateCloudMode();
    if (mounted) context.pop(true);
  }

  Future<void> _forgotPassword() async {
    // Pre-fill with whatever is already typed in the email field.
    final prefill = _emailCtrl.text.trim();
    final inputCtrl = TextEditingController(text: prefill);

    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('პაროლის აღდგენა'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'შეიყვანეთ ელ-ფოსტა — გამოგიგზავნოთ '
              'განახლების ბმული.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: inputCtrl,
              autofocus: prefill.isEmpty,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'ელ-ფოსტა',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('გაუქმება'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, inputCtrl.text.trim()),
            child: const Text('გაგზავნა'),
          ),
        ],
      ),
    );

    inputCtrl.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    final sent =
        await ref.read(authFormProvider.notifier).forgotPassword(email);

    if (!mounted) return;

    final error = ref.read(authFormProvider).error;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(sent != null ? 'გაიგზავნა ✓' : 'შეცდომა'),
        content: Text(
          sent != null
              ? 'პაროლის განახლების ბმული გამოიგზავნა:\n\n$sent\n\n'
                  'შეამოწმეთ ელ-ფოსტა (spam-საც).'
              : (error ?? 'უცნობი შეცდომა'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('კარგი'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authFormProvider);
    final notifier = ref.read(authFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isLogin ? l10n.signIn : l10n.signUp),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cloudSync,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cloudSyncDesc,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.enterEmail;
                      }
                      if (!v.contains('@')) return l10n.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: state.obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) =>
                        state.busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(state.obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: notifier.toggleObscure,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.enterPassword;
                      if (!state.isLogin && v.length < 6) {
                        return l10n.minSixChars;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Error banner
                  if (state.error != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 16),

                  // Submit
                  FilledButton(
                    onPressed: state.busy ? null : _submit,
                    child: state.busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(state.isLogin ? l10n.signIn : l10n.signUp),
                  ),
                  const SizedBox(height: 12),

                  // Toggle login / register
                  TextButton(
                    onPressed: state.busy ? null : notifier.toggleMode,
                    child: Text(
                      state.isLogin
                          ? l10n.noAccountSignUp
                          : l10n.haveAccountSignIn,
                    ),
                  ),

                  // Forgot password — opens dialog
                  if (state.isLogin)
                    TextButton(
                      onPressed: state.busy ? null : _forgotPassword,
                      child: Text(l10n.forgotPassword),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
