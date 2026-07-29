import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/brew_theme.dart';
import '../../domain/entities/brew_method.dart';
import '../../domain/entities/dial_in.dart';
import '../../domain/entities/dial_in_hints.dart';
import '../../domain/entities/dial_in_insights.dart';
import '../bloc/dial_in_cubit.dart';
import '../widgets/brew_timer.dart';
import '../widgets/hint_banner.dart';
import '../widgets/shot_score.dart';

class DialInEditorPage extends StatefulWidget {
  const DialInEditorPage({super.key, this.existing, this.seed});

  /// Düzenlenen kayıt (varsa güncelleme).
  final DialIn? existing;

  /// Yeni deneme için ön doldurma (tekrar dene).
  final DialIn? seed;

  @override
  State<DialInEditorPage> createState() => _DialInEditorPageState();
}

class _DialInEditorPageState extends State<DialInEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bean;
  late final TextEditingController _roaster;
  late final TextEditingController _grind;
  late final TextEditingController _grinder;
  late final TextEditingController _dose;
  late final TextEditingController _yield;
  late final TextEditingController _seconds;
  late final TextEditingController _temp;
  late final TextEditingController _notes;
  late final TextEditingController _pour;
  late final TextEditingController _waterNote;
  late BrewMethod _method;
  late int _score;
  late Set<TasteTag> _tags;
  DateTime? _roastDate;
  bool _saving = false;
  bool _applyDefaultsOnMethodChange = false;
  bool _notesExpanded = false;

  bool get _isEditing => widget.existing != null;

  static const _decimal = TextInputType.numberWithOptions(decimal: true);

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? widget.seed;
    _applyDefaultsOnMethodChange = e == null;
    final blank = e == null
        ? DialIn.blank(id: const Uuid().v4())
        : null;
    final source = e ?? blank!;
    _bean = TextEditingController(text: source.beanName);
    _roaster = TextEditingController(text: source.roaster);
    _grind = TextEditingController(text: source.grindSetting);
    _grinder = TextEditingController(text: source.grinderName);
    _dose = TextEditingController(text: _numText(source.doseGrams));
    _yield = TextEditingController(text: _numText(source.yieldGrams));
    _seconds = TextEditingController(text: '${source.brewSeconds}');
    _temp = TextEditingController(text: _numText(source.waterTempC));
    _notes = TextEditingController(text: source.notes);
    _pour = TextEditingController(text: source.pourNotes);
    _waterNote = TextEditingController(text: source.waterNote);
    _method = source.method;
    _score = DialIn.clampScore(source.score);
    _tags = {...source.tasteTags};
    _roastDate = source.roastDate;
    // Dolu demleme notları varsa bölümü açık başlat.
    _notesExpanded = source.roastDate != null ||
        source.pourNotes.trim().isNotEmpty ||
        source.waterNote.trim().isNotEmpty;
  }

  String _numText(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toString();
  }

  @override
  void dispose() {
    _bean.dispose();
    _roaster.dispose();
    _grind.dispose();
    _grinder.dispose();
    _dose.dispose();
    _yield.dispose();
    _seconds.dispose();
    _temp.dispose();
    _notes.dispose();
    _pour.dispose();
    _waterNote.dispose();
    super.dispose();
  }

  void _applyMethodDefaults(BrewMethod method) {
    final d = DialInHints.defaultsFor(method);
    _dose.text = _numText(d.doseGrams);
    _yield.text = _numText(d.yieldGrams);
    _seconds.text = '${d.brewSeconds}';
    _temp.text = _numText(d.waterTempC);
  }

  DialIn _buildModel() {
    return DialIn(
      id: widget.existing?.id ??
          widget.seed?.id ??
          const Uuid().v4(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      beanName: _bean.text.trim(),
      roaster: _roaster.text.trim(),
      method: _method,
      grindSetting: _grind.text.trim(),
      doseGrams: double.parse(_dose.text.replaceAll(',', '.')),
      yieldGrams: double.parse(_yield.text.replaceAll(',', '.')),
      brewSeconds: int.parse(_seconds.text),
      waterTempC: double.parse(_temp.text.replaceAll(',', '.')),
      score: DialIn.clampScore(_score),
      notes: _notes.text.trim(),
      tasteTags: _tags.toList(),
      grinderName: _grinder.text.trim(),
      isFavorite: widget.existing?.isFavorite ?? false,
      roastDate: _roastDate,
      pourNotes: _pour.text.trim(),
      waterNote: _waterNote.text.trim(),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final model = _buildModel();
      await context.read<DialInCubit>().save(model);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickRoastDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _roastDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BrewTheme.chartreuse,
              onPrimary: BrewTheme.espresso,
              surface: BrewTheme.roast,
              onSurface: BrewTheme.foam,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _roastDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? 'Denemeyi düzenle'
        : (widget.seed != null ? 'Yeni deneme (kopya)' : 'Yeni deneme');
    final state = context.watch<DialInCubit>().state;
    final liveRatio = _liveRatioValue;
    final ratioHint = liveRatio == null
        ? null
        : DialInHints.ratioHint(_method, liveRatio);
    final freshness = DialInHints.freshnessHint(_roastDate);
    final best = DialInInsights.bestForBeanMethod(
      state.items,
      beanName: _bean.text,
      method: _method,
      excludeId: widget.existing?.id,
    );

    return Scaffold(
      backgroundColor: BrewTheme.espresso,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              'Ne demledin?',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (best != null) ...[
              const SizedBox(height: 12),
              HintBanner(
                label: 'Bu çekirdekte en iyi',
                body:
                    '${best.beanName} · ${best.score}/10 · ${best.formattedRatio} · ${best.grindSetting}',
              ),
            ],
            const SizedBox(height: 12),
            _SuggestionField(
              controller: _bean,
              label: 'Çekirdek',
              suggestions: state.recentBeans,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _SuggestionField(
              controller: _roaster,
              label: 'Kavurucu',
              suggestions: state.recentRoasters,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BrewMethod>(
              key: ValueKey(_method),
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Yöntem'),
              items: BrewMethod.values
                  .map(
                    (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _method = v;
                  if (_applyDefaultsOnMethodChange) {
                    _applyMethodDefaults(v);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _SuggestionField(
              controller: _grinder,
              label: 'Öğütücü',
              suggestions: state.recentGrinders,
              textInputAction: TextInputAction.next,
              onSelected: (name) {
                final last =
                    DialInInsights.lastGrindForGrinder(state.items, name);
                if (last != null && _grind.text.trim().isEmpty) {
                  setState(() => _grind.text = last);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grind,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Öğütüm ayarı',
                hintText: 'örn. 14 / 2.3.0',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
            ),
            if (state.recentGrinders.isNotEmpty &&
                _grinder.text.trim().isEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.recentGrinders.take(4).map((g) {
                  return ActionChip(
                    label: Text(g),
                    onPressed: () {
                      final last = DialInInsights.lastGrindForGrinder(
                        state.items,
                        g,
                      );
                      setState(() {
                        _grinder.text = g;
                        if (last != null && _grind.text.trim().isEmpty) {
                          _grind.text = last;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dose,
                    keyboardType: _decimal,
                    decoration: const InputDecoration(labelText: 'Doz (g)'),
                    validator: _numValidator,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _yield,
                    keyboardType: _decimal,
                    decoration: const InputDecoration(labelText: 'Verim (g)'),
                    validator: _numValidator,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Oran $_liveRatio',
              style: GoogleFonts.figtree(color: BrewTheme.chartreuse),
            ),
            if (ratioHint != null) ...[
              const SizedBox(height: 4),
              Text(
                ratioHint,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  color: ratioHint.contains('dışında')
                      ? BrewTheme.cherry
                      : BrewTheme.mute,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _seconds,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Süre (sn)'),
                    validator: _intValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _temp,
                    keyboardType: _decimal,
                    decoration: const InputDecoration(labelText: 'Su °C'),
                    validator: _numValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BrewTimer(
              onApplySeconds: (s) {
                setState(() => _seconds.text = '$s');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Süre $s sn olarak yazıldı'),
                    backgroundColor: BrewTheme.roast,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: _notesExpanded,
                onExpansionChanged: (v) => setState(() => _notesExpanded = v),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text(
                  'Demleme notları',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BrewTheme.foam,
                  ),
                ),
                subtitle: Text(
                  _notesExpanded
                      ? 'Kavrum, pour, su'
                      : 'Kavrum · pour · su (isteğe bağlı)',
                  style: const TextStyle(
                    color: BrewTheme.mute,
                    fontSize: 13,
                  ),
                ),
                iconColor: BrewTheme.chartreuse,
                collapsedIconColor: BrewTheme.mute,
                children: [
                  InkWell(
                    onTap: _pickRoastDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kavurma tarihi (opsiyonel)',
                        suffixIcon: _roastDate == null
                            ? const Icon(Icons.calendar_today_outlined)
                            : IconButton(
                                tooltip: 'Temizle',
                                onPressed: () =>
                                    setState(() => _roastDate = null),
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      child: Text(
                        _roastDate == null
                            ? 'Seçilmedi'
                            : DateFormat('d MMMM yyyy', 'tr')
                                .format(_roastDate!),
                        style: TextStyle(
                          color: _roastDate == null
                              ? BrewTheme.mute
                              : BrewTheme.foam,
                        ),
                      ),
                    ),
                  ),
                  if (freshness != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        freshness,
                        style: GoogleFonts.figtree(
                          color: BrewTheme.chartreuse,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pour,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Pour notu',
                      hintText: 'örn. 40g bloom · 2. pour 150g',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _waterNote,
                    decoration: const InputDecoration(
                      labelText: 'Su notu',
                      hintText: 'örn. yumuşak / filtreli',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ne kadar beğendin?',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_score/10 · ${shotTitle(_score)}',
              style: TextStyle(
                color: shotAccent(_score),
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _score.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: shotTitle(_score),
              activeColor: shotAccent(_score),
              onChanged: (v) => setState(() => _score = v.round()),
            ),
            const SizedBox(height: 8),
            Text('Tat', style: GoogleFonts.figtree()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TasteTag.values.map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag.label),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (DialInHints.tasteTip(_tags.toList()) != null) ...[
              const SizedBox(height: 10),
              HintBanner(
                label: 'Sonraki tek değişken',
                body: DialInHints.tasteTip(_tags.toList())!,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notlar'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: BrewTheme.chartreuse,
              foregroundColor: BrewTheme.espresso,
              disabledBackgroundColor:
                  BrewTheme.chartreuse.withValues(alpha: 0.4),
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Kaydet · ${shotTitle(_score)}'),
          ),
        ),
      ),
    );
  }

  double? get _liveRatioValue {
    final dose = double.tryParse(_dose.text.replaceAll(',', '.'));
    final yieldG = double.tryParse(_yield.text.replaceAll(',', '.'));
    if (dose == null || yieldG == null || dose <= 0) return null;
    return yieldG / dose;
  }

  String get _liveRatio {
    final r = _liveRatioValue;
    if (r == null) return '—';
    return '1:${r.toStringAsFixed(1)}';
  }

  String? _numValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Zorunlu';
    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Sayı gir';
    return null;
  }

  String? _intValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Zorunlu';
    if (int.tryParse(v) == null) return 'Tam sayı gir';
    return null;
  }
}

class _SuggestionField extends StatefulWidget {
  const _SuggestionField({
    required this.controller,
    required this.label,
    required this.suggestions,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSelected,
  });

  final TextEditingController controller;
  final String label;
  final List<String> suggestions;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;

  @override
  State<_SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<_SuggestionField> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return widget.suggestions;
        return widget.suggestions.where((s) => s.toLowerCase().contains(q));
      },
      onSelected: (value) {
        widget.controller.text = value;
        widget.controller.selection =
            TextSelection.collapsed(offset: value.length);
        widget.onSelected?.call(value);
        widget.onChanged?.call(value);
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(labelText: widget.label),
          validator: widget.validator,
          onChanged: widget.onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final opts = options.toList();
        if (opts.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: BrewTheme.roast,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (context, index) {
                  final option = opts[index];
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
