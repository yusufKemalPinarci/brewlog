import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/brew_theme.dart';
import '../../domain/entities/brew_method.dart';
import '../../domain/entities/dial_in.dart';
import '../bloc/dial_in_cubit.dart';
import '../widgets/shot_score.dart';

class DialInEditorPage extends StatefulWidget {
  const DialInEditorPage({super.key, this.existing});

  final DialIn? existing;

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
  late BrewMethod _method;
  late int _score;
  late Set<TasteTag> _tags;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _bean = TextEditingController(text: e?.beanName ?? '');
    _roaster = TextEditingController(text: e?.roaster ?? '');
    _grind = TextEditingController(text: e?.grindSetting ?? '');
    _grinder = TextEditingController(text: e?.grinderName ?? '');
    _dose = TextEditingController(text: e?.doseGrams.toString() ?? '18');
    _yield = TextEditingController(text: e?.yieldGrams.toString() ?? '36');
    _seconds = TextEditingController(text: e?.brewSeconds.toString() ?? '30');
    _temp = TextEditingController(text: e?.waterTempC.toString() ?? '93');
    _notes = TextEditingController(text: e?.notes ?? '');
    _method = e?.method ?? BrewMethod.espresso;
    _score = e?.score ?? 7;
    _tags = {...?e?.tasteTags};
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
    super.dispose();
  }

  DialIn _buildModel() {
    return DialIn(
      id: widget.existing?.id ?? const Uuid().v4(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      beanName: _bean.text.trim(),
      roaster: _roaster.text.trim(),
      method: _method,
      grindSetting: _grind.text.trim(),
      doseGrams: double.parse(_dose.text.replaceAll(',', '.')),
      yieldGrams: double.parse(_yield.text.replaceAll(',', '.')),
      brewSeconds: int.parse(_seconds.text),
      waterTempC: double.parse(_temp.text.replaceAll(',', '.')),
      score: _score,
      notes: _notes.text.trim(),
      tasteTags: _tags.toList(),
      grinderName: _grinder.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final model = _buildModel();
    await context.read<DialInCubit>().save(model);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrewTheme.espresso,
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Yeni deneme' : 'Denemeyi düzenle',
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _bean,
              decoration: const InputDecoration(labelText: 'Çekirdek'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roaster,
              decoration: const InputDecoration(labelText: 'Kavurucu'),
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
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grinder,
              decoration: const InputDecoration(labelText: 'Öğütücü'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grind,
              decoration: const InputDecoration(
                labelText: 'Öğütü ayarı',
                hintText: 'örn. 14 / 2.3.0',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dose,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Doz (g)'),
                    validator: _numValidator,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _yield,
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Su °C'),
                    validator: _numValidator,
                  ),
                ),
              ],
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
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: BrewTheme.chartreuse,
              foregroundColor: BrewTheme.espresso,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text('Kaydet · ${shotTitle(_score)}'),
          ),
        ),
      ),
    );
  }

  String get _liveRatio {
    final dose = double.tryParse(_dose.text.replaceAll(',', '.'));
    final yieldG = double.tryParse(_yield.text.replaceAll(',', '.'));
    if (dose == null || yieldG == null || dose <= 0) return '—';
    return '1:${(yieldG / dose).toStringAsFixed(1)}';
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
