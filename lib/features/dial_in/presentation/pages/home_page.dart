import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/brew_theme.dart';
import '../../domain/entities/brew_method.dart';
import '../../domain/entities/dial_in.dart';
import '../bloc/dial_in_cubit.dart';
import '../widgets/shot_score.dart';
import 'dial_in_detail_page.dart';
import 'dial_in_editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1612),
              BrewTheme.espresso,
              Color(0xFF0E0C0A),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<DialInCubit, DialInState>(
            listenWhen: (a, b) => a.error != b.error && b.error != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bir şey ters gitti. Tekrar dene.'),
                  backgroundColor: BrewTheme.cherry,
                ),
              );
            },
            builder: (context, state) {
              final visible = state.visible;
              final count = state.items.length;
              final isEmptyLibrary = count == 0 && !state.loading;
              final legendary = state.legendary;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  'BrewLog',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 46,
                                    height: 1.02,
                                    fontWeight: FontWeight.w600,
                                    color: BrewTheme.foam,
                                  ),
                                ),
                              ),
                              PopupMenuButton<_BackupAction>(
                                tooltip: 'Yedek',
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: BrewTheme.mute,
                                ),
                                color: BrewTheme.roast,
                                onSelected: (action) =>
                                    _onBackupAction(context, action),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: _BackupAction.export,
                                    child: Text('Yedeği dışa aktar'),
                                  ),
                                  PopupMenuItem(
                                    value: _BackupAction.importMerge,
                                    child: Text('Yedekten içe al'),
                                  ),
                                  PopupMenuItem(
                                    value: _BackupAction.importReplace,
                                    child: Text('Yedekle değiştir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Demlemelerini kaydet. En iyiyi bul.',
                            style: GoogleFonts.figtree(
                              fontSize: 17,
                              height: 1.4,
                              color: BrewTheme.mute,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 14),
                            Text(
                              count == 1
                                  ? '1 deneme · devam'
                                  : '$count deneme · devam',
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: BrewTheme.chartreuse,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.92, end: 1),
                            duration: const Duration(milliseconds: 480),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: FilledButton(
                              onPressed: () => _openEditor(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: BrewTheme.chartreuse,
                                foregroundColor: BrewTheme.espresso,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                textStyle: GoogleFonts.figtree(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Yeni deneme'),
                            ),
                          ),
                          if (!isEmptyLibrary) ...[
                            if (state.bestShot != null) ...[
                              const SizedBox(height: 20),
                              _ChampionStrip(
                                dialIn: state.bestShot!,
                                onTap: () =>
                                    _openDetail(context, state.bestShot!),
                              ),
                            ],
                            if (legendary.length > 1) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Efsane shot’lar',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: BrewTheme.mute,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: legendary.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final item = legendary[index];
                                    return ActionChip(
                                      avatar: Text(
                                        '${item.score}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: BrewTheme.chartreuse,
                                        ),
                                      ),
                                      label: Text(item.beanName),
                                      onPressed: () =>
                                          _openDetail(context, item),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            TextField(
                              controller: _search,
                              onChanged:
                                  context.read<DialInCubit>().setQuery,
                              decoration: const InputDecoration(
                                hintText: 'Çekirdek veya kavurucu ara',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChip(
                                    label: const Text('Favoriler'),
                                    selected: state.favoritesOnly,
                                    onSelected: context
                                        .read<DialInCubit>()
                                        .setFavoritesOnly,
                                  ),
                                  const SizedBox(width: 8),
                                  ...BrewMethod.values.map((m) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(m.label),
                                        selected: state.methodFilter == m,
                                        onSelected: (_) => context
                                            .read<DialInCubit>()
                                            .setMethodFilter(m),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<DialInSort>(
                                    value: state.sort,
                                    dropdownColor: BrewTheme.roast,
                                    items: const [
                                      DropdownMenuItem(
                                        value: DialInSort.newest,
                                        child: Text('En yeni'),
                                      ),
                                      DropdownMenuItem(
                                        value: DialInSort.score,
                                        child: Text('En yüksek skor'),
                                      ),
                                      DropdownMenuItem(
                                        value: DialInSort.bean,
                                        child: Text('Çekirdek'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        context
                                            .read<DialInCubit>()
                                            .setSort(v);
                                      }
                                    },
                                  ),
                                ),
                                if (state.hasActiveFilters)
                                  TextButton(
                                    onPressed: () {
                                      _search.clear();
                                      context
                                          .read<DialInCubit>()
                                          .clearFilters();
                                    },
                                    child: const Text('Filtreyi temizle'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state.loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEmptyLibrary
                                  ? 'Henüz shot yok.\nİlk denemeni kaydet — skorunu ver.'
                                  : 'Burada bir şey yok.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.figtree(
                                color: BrewTheme.mute,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            if (!isEmptyLibrary &&
                                state.hasActiveFilters) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  _search.clear();
                                  context
                                      .read<DialInCubit>()
                                      .clearFilters();
                                },
                                child: const Text('Filtreyi temizle'),
                              ),
                            ],
                            if (isEmptyLibrary) ...[
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () => _openEditor(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: BrewTheme.chartreuse,
                                  foregroundColor: BrewTheme.espresso,
                                ),
                                child: const Text('İlk denemeyi başlat'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = visible[index];
                          return _DialInTile(
                            dialIn: item,
                            onOpen: () => _openDetail(context, item),
                            onEdit: () =>
                                _openEditor(context, existing: item),
                            onFavorite: () => context
                                .read<DialInCubit>()
                                .toggleFavorite(item),
                            onDelete: () =>
                                _confirmDelete(context, item),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onBackupAction(
    BuildContext context,
    _BackupAction action,
  ) async {
    final cubit = context.read<DialInCubit>();
    try {
      switch (action) {
        case _BackupAction.export:
          final path = await cubit.exportBackupPath();
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(path)],
              subject: 'BrewLog yedek',
              text: 'BrewLog dial-in yedeği',
            ),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yedek hazır — paylaşım sayfasından kaydet.'),
                backgroundColor: BrewTheme.roast,
              ),
            );
          }
        case _BackupAction.importMerge:
          await _importBackup(context, replace: false);
        case _BackupAction.importReplace:
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: BrewTheme.roast,
              title: Text(
                'Mevcut kayıtlar silinsin mi?',
                style: GoogleFonts.fraunces(color: BrewTheme.foam),
              ),
              content: const Text(
                'Yedek dosyasındaki kayıtlar mevcut listenin yerini alır. '
                'Önce dışa aktarman iyi olur.',
                style: TextStyle(color: BrewTheme.mute),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: BrewTheme.cherry,
                  ),
                  child: const Text('Değiştir'),
                ),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            await _importBackup(context, replace: true);
          }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek işlemi başarısız: $e'),
            backgroundColor: BrewTheme.cherry,
          ),
        );
      }
    }
  }

  Future<void> _importBackup(
    BuildContext context, {
    required bool replace,
  }) async {
    final controller = TextEditingController();
    final choice = await showDialog<_ImportChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrewTheme.roast,
        title: Text(
          replace ? 'Yedekle değiştir' : 'Yedekten içe al',
          style: GoogleFonts.fraunces(color: BrewTheme.foam),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'JSON yedeğini yapıştır veya son dışa aktarılan dosyayı yükle.',
                style: TextStyle(color: BrewTheme.mute),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '[ { "id": ... } ]',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _ImportChoice.fromBackupFile),
            child: const Text('Son yedek dosyası'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ImportChoice.fromPaste),
            style: FilledButton.styleFrom(
              backgroundColor: BrewTheme.chartreuse,
              foregroundColor: BrewTheme.espresso,
            ),
            child: const Text('Yapıştırılanı al'),
          ),
        ],
      ),
    );

    if (choice == null || !context.mounted) {
      controller.dispose();
      return;
    }

    final cubit = context.read<DialInCubit>();
    String raw;
    try {
      if (choice == _ImportChoice.fromBackupFile) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/brewlog_backup.json');
        if (!await file.exists()) {
          throw StateError(
            'Önce “Yedeği dışa aktar” ile bir yedek oluştur.',
          );
        }
        raw = await file.readAsString();
      } else {
        raw = controller.text.trim();
        if (raw.isEmpty) {
          final clip = await Clipboard.getData(Clipboard.kTextPlain);
          raw = clip?.text?.trim() ?? '';
        }
        if (raw.isEmpty) {
          throw StateError('Yapıştırılacak JSON yok.');
        }
      }
    } finally {
      controller.dispose();
    }

    final count = await cubit.importJson(raw, replace: replace);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            replace
                ? '$count kayıt yüklendi (liste değiştirildi).'
                : '$count kayıt içe alındı.',
          ),
          backgroundColor: BrewTheme.roast,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, DialIn item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrewTheme.roast,
        title: Text(
          'Silinsin mi?',
          style: GoogleFonts.fraunces(color: BrewTheme.foam),
        ),
        content: Text(
          '${item.beanName} kaydı gidecek.',
          style: const TextStyle(color: BrewTheme.mute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: BrewTheme.cherry),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DialInCubit>().remove(item.id);
    }
  }

  Future<void> _openDetail(BuildContext context, DialIn dialIn) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<DialInCubit>(),
          child: DialInDetailPage(dialInId: dialIn.id),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {DialIn? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<DialInCubit>(),
          child: DialInEditorPage(existing: existing),
        ),
      ),
    );
  }
}

enum _BackupAction { export, importMerge, importReplace }

enum _ImportChoice { fromPaste, fromBackupFile }

class _ChampionStrip extends StatelessWidget {
  const _ChampionStrip({required this.dialIn, required this.onTap});

  final DialIn dialIn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrewTheme.chartreuse.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ShotScoreBadge(score: dialIn.score, compact: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Şampiyon shot',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BrewTheme.chartreuse,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dialIn.beanName,
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${dialIn.method.label} · ${shotTitle(dialIn.score)}',
                      style: const TextStyle(
                        color: BrewTheme.mute,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BrewTheme.mute),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialInTile extends StatelessWidget {
  const _DialInTile({
    required this.dialIn,
    required this.onOpen,
    required this.onEdit,
    required this.onFavorite,
    required this.onDelete,
  });

  final DialIn dialIn;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM', 'tr').format(dialIn.createdAt);
    return Material(
      color: BrewTheme.roast,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            children: [
              ShotScoreBadge(score: dialIn.score, compact: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dialIn.beanName,
                      style: GoogleFonts.fraunces(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        dialIn.method.label,
                        if (dialIn.roaster.isNotEmpty) dialIn.roaster,
                        date,
                      ].join(' · '),
                      style: const TextStyle(
                        color: BrewTheme.mute,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      shotTitle(dialIn.score),
                      style: TextStyle(
                        color: shotAccent(dialIn.score),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Düzenle',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: BrewTheme.mute),
              ),
              IconButton(
                tooltip: 'Favori',
                onPressed: onFavorite,
                icon: Icon(
                  dialIn.isFavorite ? Icons.star : Icons.star_border,
                  color: dialIn.isFavorite
                      ? BrewTheme.chartreuse
                      : BrewTheme.mute,
                ),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: BrewTheme.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
