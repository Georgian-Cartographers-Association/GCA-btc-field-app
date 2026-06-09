import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/locale.dart';
import '../../auth/domain/firebase_auth_provider.dart';
import '../domain/settings_provider.dart';
import '../../../services/sync_service.dart';
import '../../../l10n/generated/app_localizations.dart';

const _githubUrl =
    'https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // ── გარეგნობა ──────────────────────────────────────────────
          _SectionHeader(l10n.appearance),

          // Dark mode: 3-segment (ნათელი / სისტემა / მუქი)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.theme,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(l10n.lightTheme),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_outlined),
                      label: Text(l10n.systemTheme),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(l10n.darkTheme),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => notifier.setTheme(s.first),
                ),
              ],
            ),
          ),
          const Divider(),

          // ── ენა ───────────────────────────────────────────────────
          _SectionHeader(l10n.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<AppLocale>(
              segments: AppLocale.values
                  .map((l) => ButtonSegment(
                        value: l,
                        label: Text(l.displayName),
                        icon: const Icon(Icons.language),
                      ))
                  .toList(),
              selected: {settings.appLocale},
              onSelectionChanged: (s) => notifier.setLocale(s.first),
            ),
          ),
          const Divider(),

          // ── ეკრანი ────────────────────────────────────────────────
          if (!kIsWeb) ...[
            const _SectionHeader('ეკრანი'),
            SwitchListTile(
              secondary: const Icon(Icons.screen_lock_portrait_outlined),
              title: Text(l10n.keepScreenOn),
              subtitle: Text(l10n.keepScreenOnSub),
              value: settings.screenAwake,
              onChanged: (v) async {
                await notifier.setScreenAwake(v);
                await WakelockPlus.toggle(enable: v);
              },
            ),
            const Divider(),
          ],

          // ── ელ-ფოსტების სია ───────────────────────────────────────
          _SectionHeader(l10n.emailListTitle),
          if (settings.emails.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.noEmailsAdded,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ...settings.emails.map((email) => ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(email),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: l10n.delete,
                  onPressed: () => notifier.removeEmail(email),
                ),
                dense: true,
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _AddEmailField(onAdd: notifier.addEmail),
          ),
          const Divider(),

          // ── მონაცემების შენახვა ───────────────────────────────────
          _SectionHeader(l10n.storageTitle),
          _StorageSection(settings: settings, notifier: notifier),
          const Divider(),

          // ── შესახებ ────────────────────────────────────────────────
          const _SectionHeader('შესახებ'),

          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final ver = snapshot.data?.version ?? '—';
              final build = snapshot.data?.buildNumber ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('ვერსია'),
                subtitle: Text('$ver+$build'),
              );
            },
          ),

          const ListTile(
            leading: Icon(Icons.business_outlined),
            title: Text('ორგანიზაცია'),
            subtitle: Text(
                'ალ. ასლანიკაშვილის სახ.\nსაქართველოს კარტოგრაფთა ასოციაცია'),
          ),

          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('უნივერსიტეტი'),
            subtitle: Text('ი. ჯავახიშვილის სახ. თბილისის სახ. უნ-ტი'),
          ),

          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            subtitle: const Text(
              'Georgian-Cartographers-Association/\nGCA-btc-field-app',
              style: TextStyle(fontSize: 11),
            ),
            trailing:
                const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => launchUrl(
              Uri.parse(_githubUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── helper widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

// ── Storage section ────────────────────────────────────────────────────────────

class _StorageSection extends ConsumerStatefulWidget {
  final SettingsState settings;
  final SettingsNotifier notifier;
  const _StorageSection({required this.settings, required this.notifier});

  @override
  ConsumerState<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends ConsumerState<_StorageSection> {
  bool _busy = false;

  // ── Switch helpers ────────────────────────────────────────────────────────

  Future<void> _switchToCloud() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      await context.push('/auth');
      return;
    }
    await widget.notifier.setStorageMode(StorageMode.cloud);
  }

  Future<void> _switchToLocal() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.switchToLocal),
        content: Text(l10n.switchToLocalContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.switchToLocalBtn)),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.notifier.setStorageMode(StorageMode.local);
    }
  }

  Future<void> _switchToExpedition() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      await context.push('/auth');
      if (!mounted) return;
      final u2 = ref.read(authProvider).valueOrNull;
      if (u2 == null) return;
    }
    final code = await context.push<String?>('/expedition');
    if (!mounted) return;
    if (code == null) {
      final currentMode = widget.settings.storageMode;
      if (currentMode == StorageMode.expedition) return;
      await widget.notifier.setStorageMode(StorageMode.cloud);
    }
  }

  Future<void> _leaveExpedition() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.leaveExpeditionTitle),
        content: Text(l10n.leaveExpeditionContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.leave, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.notifier.leaveExpedition();
    }
  }

  Future<void> _downloadCloud() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final count = await SyncService.downloadCloudToLocal(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count ჩანაწერი გადმოიწერა ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('შეცდომა: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.signOut)),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    await widget.notifier.setStorageMode(StorageMode.local);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mode = widget.settings.storageMode;
    final expId = widget.settings.expeditionId;
    final userAsync = ref.watch(authProvider);
    final user = userAsync.valueOrNull;

    return Column(
      children: [
        // ── Mode selector ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<StorageMode>(
            segments: [
              ButtonSegment(
                value: StorageMode.local,
                icon: const Icon(Icons.storage_outlined),
                label: Text(l10n.storageLocal),
              ),
              ButtonSegment(
                value: StorageMode.cloud,
                icon: const Icon(Icons.cloud_outlined),
                label: Text(l10n.storageCloud),
              ),
              ButtonSegment(
                value: StorageMode.expedition,
                icon: const Icon(Icons.group_outlined),
                label: Text(l10n.storageExpedition),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) async {
              switch (s.first) {
                case StorageMode.local:
                  await _switchToLocal();
                case StorageMode.cloud:
                  await _switchToCloud();
                case StorageMode.expedition:
                  await _switchToExpedition();
              }
            },
          ),
        ),

        // ── Cloud mode ─────────────────────────────────────────────────
        if (mode == StorageMode.cloud && user != null) ...[
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.account),
            subtitle: Text(user.email ?? user.uid),
            dense: true,
            trailing: TextButton(
              onPressed: _signOut,
              child: Text(l10n.signOut,
                  style: const TextStyle(color: Colors.red)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.syncCloudToLocal),
            subtitle: Text(l10n.syncCloudToLocalDesc),
            dense: true,
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: _downloadCloud,
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text(l10n.expeditionShortcut),
            subtitle: Text(l10n.expeditionShortcutSub),
            dense: true,
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey),
            onTap: _switchToExpedition,
          ),
        ],

        // ── Expedition mode ────────────────────────────────────────────
        if (mode == StorageMode.expedition) ...[
          if (user != null)
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(l10n.account),
              subtitle: Text(user.email ?? user.uid),
              dense: true,
              trailing: TextButton(
                onPressed: _signOut,
                child: Text(l10n.signOut,
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (expId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined,
                          color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.expeditionCodeShort,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onTertiaryContainer)),
                            const SizedBox(height: 4),
                            Text(
                              expId,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: l10n.copyCode,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: expId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.codeCopied)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.exit_to_app_outlined,
                color: Colors.deepOrange),
            title: Text(l10n.leaveExpeditionShort),
            subtitle: Text(l10n.leaveExpeditionSub),
            dense: true,
            onTap: _leaveExpedition,
          ),
        ],

        // ── Local mode info ────────────────────────────────────────────
        if (mode == StorageMode.local)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.localModeInfo,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}

// ── Email field ─────────────────────────────────────────────────────────────────

class _AddEmailField extends StatefulWidget {
  final Future<void> Function(String) onAdd;
  const _AddEmailField({required this.onAdd});

  @override
  State<_AddEmailField> createState() => _AddEmailFieldState();
}

class _AddEmailFieldState extends State<_AddEmailField> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    await widget.onAdd(email);
    _ctrl.clear();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              labelText: l10n.newEmailHint,
              hintText: 'example@email.com',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _add,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addEmail),
        ),
      ],
    );
  }
}
