import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/expedition_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen({super.key});

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _joinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _joinCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    try {
      await ref.read(expeditionFormProvider.notifier).create();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('შეცდომა: $e')));
      }
    }
  }

  Future<void> _confirmCreate() async {
    final code = await ref.read(expeditionFormProvider.notifier).confirmCreate();
    if (code != null && mounted) context.pop(code);
  }

  Future<void> _join() async {
    final code = _joinCtrl.text.trim().toUpperCase();
    final result = await ref.read(expeditionFormProvider.notifier).join(code);
    if (result != null && mounted) context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(expeditionFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expeditionMode),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(icon: const Icon(Icons.add_circle_outline), text: l10n.createTab),
            Tab(icon: const Icon(Icons.login_outlined), text: l10n.joinTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CreateTab(
            state: state,
            onCreate: _create,
            onConfirm: _confirmCreate,
          ),
          _JoinTab(
            state: state,
            controller: _joinCtrl,
            onJoin: _join,
            onCodeChanged: (_) {
              if (state.joinError != null) {
                ref.read(expeditionFormProvider.notifier).clearJoinError();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Create tab ─────────────────────────────────────────────────────────────────

class _CreateTab extends StatelessWidget {
  final ExpeditionFormState state;
  final VoidCallback onCreate;
  final VoidCallback onConfirm;

  const _CreateTab({
    required this.state,
    required this.onCreate,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.newExpeditionTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    l10n.newExpeditionDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          if (state.createdCode != null) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    l10n.expeditionCodeLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: state.createdCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.codeCopied)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.createdCode!,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.copy_outlined,
                              color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapToCopy,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: state.busy ? null : onConfirm,
              icon: const Icon(Icons.check),
              label: Text(l10n.confirmExpedition),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: state.busy ? null : onCreate,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.generateCode),
            ),
          ] else ...[
            const Spacer(),
            FilledButton.icon(
              onPressed: state.busy ? null : onCreate,
              icon: state.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_circle_outline),
              label: Text(l10n.createExpedition),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

// ── Join tab ───────────────────────────────────────────────────────────────────

class _JoinTab extends StatelessWidget {
  final ExpeditionFormState state;
  final TextEditingController controller;
  final VoidCallback onJoin;
  final ValueChanged<String> onCodeChanged;

  const _JoinTab({
    required this.state,
    required this.controller,
    required this.onJoin,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.group_outlined,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.joinExistingTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    l10n.joinExistingDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: l10n.expeditionCodeLabel,
              hintText: 'XXXXXX',
              errorText: state.joinError,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: onCodeChanged,
            onSubmitted: (_) => onJoin(),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: state.busy ? null : onJoin,
            icon: state.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login_outlined),
            label: Text(l10n.joinTab),
          ),
        ],
      ),
    );
  }
}
