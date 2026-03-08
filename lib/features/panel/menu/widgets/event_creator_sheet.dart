import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/tokens.dart';
import '../menu_models.dart';

class EventCreatorSheet extends StatefulWidget {
  final String title;
  final List<ProductModel> products;

  const EventCreatorSheet({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  State<EventCreatorSheet> createState() => _EventCreatorSheetState();
}

class _EventCreatorSheetState extends State<EventCreatorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _discount;

  final Uuid _uuid = const Uuid();

  EventScheduleType _type = EventScheduleType.oneTime;

  DateTime? _onceStart;
  DateTime? _onceEnd;

  final Set<int> _days = {1, 2, 3, 4, 5}; // 1..7
  TimeOfDay _weeklyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _weeklyEnd = const TimeOfDay(hour: 18, minute: 0);

  final Set<String> _pickedProductIds = {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _discount = TextEditingController(text: '10');

    _name.addListener(() => setState(() {}));
    _discount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _discount.dispose();
    super.dispose();
  }

  bool get _isWeeklyTimeValid {
    final startMinutes = (_weeklyStart.hour * 60) + _weeklyStart.minute;
    final endMinutes = (_weeklyEnd.hour * 60) + _weeklyEnd.minute;
    return endMinutes > startMinutes;
  }

  bool get _canCommit {
    final disc = double.tryParse(_discount.text.replaceAll(',', '.')) ?? 0;
    final hasName = _name.text.trim().isNotEmpty;
    final validDiscount = disc > 0 && disc <= 100;
    final hasProducts = _pickedProductIds.isNotEmpty;

    if (!hasName || !validDiscount || !hasProducts) return false;

    if (_type == EventScheduleType.oneTime) {
      if (_onceStart == null || _onceEnd == null) return false;
      return _onceEnd!.isAfter(_onceStart!);
    }

    return _days.isNotEmpty && _isWeeklyTimeValid;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, controller) => Material(
          color: t.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.rLg),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: tokens.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.title.copyWith(
                        color: tokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Kapat',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canCommit ? _commit : null,
                    child: Text(
                      'Oluştur',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Kampanya adı',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _discount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'İndirim (%)',
                  hintText: '10',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                  hintStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Zaman',
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<EventScheduleType>(
                segments: [
                  ButtonSegment(
                    value: EventScheduleType.oneTime,
                    label: Text(
                      'Tek',
                      style: AppTypography.caption.copyWith(
                        color: tokens.text,
                      ),
                    ),
                    icon: const Icon(Icons.event),
                  ),
                  ButtonSegment(
                    value: EventScheduleType.recurring,
                    label: Text(
                      'Tekrar',
                      style: AppTypography.caption.copyWith(
                        color: tokens.text,
                      ),
                    ),
                    icon: const Icon(Icons.repeat),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 10),
              if (_type == EventScheduleType.oneTime)
                ..._buildOnce(context)
              else
                ..._buildRecurring(context),
              const SizedBox(height: 18),
              Text(
                'Ürün seç',
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.products.isEmpty)
                _emptyHint(context, 'Bu menüde ürün yok. Önce ürün oluşturmalısın.')
              else
                ...widget.products.map((p) {
                  final on = _pickedProductIds.contains(p.id);

                  return Card(
                    elevation: 0,
                    child: CheckboxListTile(
                      value: on,
                      title: Text(
                        p.name,
                        style: AppTypography.bodyStrong.copyWith(
                          color: tokens.text,
                        ),
                      ),
                      subtitle: Text(
                        '${p.price.toStringAsFixed(2).replaceAll('.', ',')} ₺',
                        style: AppTypography.caption.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        if (v == true) _pickedProductIds.add(p.id);
                        if (v == false) _pickedProductIds.remove(p.id);
                      }),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOnce(BuildContext context) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return [
      Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _onceStart == null
                          ? 'Başlangıç seç'
                          : 'Başlangıç: ${_fmtDT(_onceStart!)}',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime();
                      if (!mounted || picked == null) return;
                      setState(() => _onceStart = picked);
                    },
                    child: Text(
                      'Seç',
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _onceEnd == null
                          ? 'Bitiş seç'
                          : 'Bitiş: ${_fmtDT(_onceEnd!)}',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime();
                      if (!mounted || picked == null) return;
                      setState(() => _onceEnd = picked);
                    },
                    child: Text(
                      'Seç',
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_onceStart != null &&
                  _onceEnd != null &&
                  !_onceEnd!.isAfter(_onceStart!)) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bitiş zamanı başlangıçtan sonra olmalı.',
                    style: AppTypography.caption.copyWith(
                      color: t.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRecurring(BuildContext context) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    Widget dayChip(int day, String label) {
      final on = _days.contains(day);
      return FilterChip(
        selected: on,
        label: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: on ? tokens.text : tokens.muted,
          ),
        ),
        onSelected: (v) => setState(() {
          if (v) {
            _days.add(day);
          } else {
            _days.remove(day);
          }
        }),
      );
    }

    return [
      Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Günler',
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  dayChip(1, 'Pzt'),
                  dayChip(2, 'Sal'),
                  dayChip(3, 'Çar'),
                  dayChip(4, 'Per'),
                  dayChip(5, 'Cum'),
                  dayChip(6, 'Cmt'),
                  dayChip(7, 'Paz'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Başlangıç: ${_fmtTOD(_weeklyStart)}',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final p = await showTimePicker(
                        context: context,
                        initialTime: _weeklyStart,
                      );
                      if (!mounted || p == null) return;
                      setState(() => _weeklyStart = p);
                    },
                    child: Text(
                      'Seç',
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bitiş: ${_fmtTOD(_weeklyEnd)}',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final p = await showTimePicker(
                        context: context,
                        initialTime: _weeklyEnd,
                      );
                      if (!mounted || p == null) return;
                      setState(() => _weeklyEnd = p);
                    },
                    child: Text(
                      'Seç',
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_days.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'En az 1 gün seçmelisin.',
                  style: AppTypography.caption.copyWith(
                    color: t.colorScheme.error,
                  ),
                ),
              ],
              if (!_isWeeklyTimeValid) ...[
                const SizedBox(height: 8),
                Text(
                  'Bitiş saati başlangıç saatinden sonra olmalı.',
                  style: AppTypography.caption.copyWith(
                    color: t.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDate: now,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmtDT(DateTime dt) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _fmtTOD(TimeOfDay t) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  void _commit() {
    final name = _name.text.trim();
    final disc = double.tryParse(_discount.text.replaceAll(',', '.')) ?? 0;

    if (name.isEmpty || disc <= 0 || disc > 100) return;
    if (_pickedProductIds.isEmpty) return;

    if (_type == EventScheduleType.oneTime) {
      if (_onceStart == null || _onceEnd == null) return;
      if (!_onceEnd!.isAfter(_onceStart!)) return;
    } else {
      if (_days.isEmpty) return;
      if (!_isWeeklyTimeValid) return;
    }

    final weekly = (_type == EventScheduleType.recurring)
        ? WeeklyRuleDraft(
      days: {..._days},
      start: _weeklyStart,
      end: _weeklyEnd,
    )
        : null;

    Navigator.pop(
      context,
      EventDraft(
        id: _uuid.v4(),
        name: name,
        discountPercent: disc,
        scheduleType: _type,
        productIds: _pickedProductIds.toList(),
        startsAt: _onceStart,
        endsAt: _onceEnd,
        weekly: weekly,
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(tokens.rMd),
        border: Border.all(
          color: t.dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: tokens.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: tokens.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}