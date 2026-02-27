import 'package:flutter/material.dart';

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

  EventScheduleType _type = EventScheduleType.oneTime;

  DateTime? _onceStart;
  DateTime? _onceEnd;

  // recurring (weekly-like)
  final Set<int> _days = {1, 2, 3, 4, 5}; // 1..7 (Mon..Sun)
  TimeOfDay _weeklyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _weeklyEnd = const TimeOfDay(hour: 18, minute: 0);

  final Set<String> _pickedProductIds = {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _discount = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _name.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final disc = double.tryParse(_discount.text.replaceAll(',', '.')) ?? 0;

    final canCommit = _name.text.trim().isNotEmpty &&
        disc > 0 &&
        disc <= 100 &&
        _pickedProductIds.isNotEmpty &&
        (_type == EventScheduleType.recurring ||
            (_onceStart != null &&
                _onceEnd != null &&
                _onceEnd!.isAfter(_onceStart!)));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, controller) => Material(
          color: t.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: t.dividerColor,
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
                      style: t.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canCommit ? _commit : null,
                    child: const Text('Oluştur'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Kampanya adı'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _discount,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'İndirim (%)',
                  hintText: '10',
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Zaman',
                style: t.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              SegmentedButton<EventScheduleType>(
                segments: const [
                  ButtonSegment(
                    value: EventScheduleType.oneTime,
                    label: Text('Tek'),
                    icon: Icon(Icons.event),
                  ),
                  ButtonSegment(
                    value: EventScheduleType.recurring,
                    label: Text('Tekrar'),
                    icon: Icon(Icons.repeat),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),

              const SizedBox(height: 10),
              if (_type == EventScheduleType.oneTime)
                ..._buildOnce(t)
              else
                ..._buildRecurring(t),

              const SizedBox(height: 18),
              Text(
                'Ürün seç',
                style: t.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              ...widget.products.map((p) {
                final on = _pickedProductIds.contains(p.id);
                return Card(
                  elevation: 0,
                  child: CheckboxListTile(
                    value: on,
                    title: Text(p.name),
                    subtitle:
                    Text('${p.price.toStringAsFixed(2).replaceAll('.', ',')} ₺'),
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

  List<Widget> _buildOnce(ThemeData t) {
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
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime();
                      if (!mounted) return;
                      if (picked == null) return;
                      setState(() => _onceStart = picked);
                    },
                    child: const Text('Seç'),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _onceEnd == null ? 'Bitiş seç' : 'Bitiş: ${_fmtDT(_onceEnd!)}',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await _pickDateTime();
                      if (!mounted) return;
                      if (picked == null) return;
                      setState(() => _onceEnd = picked);
                    },
                    child: const Text('Seç'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRecurring(ThemeData t) {
    Widget dayChip(int day, String label) {
      final on = _days.contains(day);
      return FilterChip(
        selected: on,
        label: Text(label),
        onSelected: (v) => setState(() {
          if (v) _days.add(day);
          if (!v) _days.remove(day);
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
              Text('Günler',
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
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
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final p = await showTimePicker(
                        context: context,
                        initialTime: _weeklyStart,
                      );
                      if (!mounted) return;
                      if (p == null) return;
                      setState(() => _weeklyStart = p);
                    },
                    child: const Text('Seç'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bitiş: ${_fmtTOD(_weeklyEnd)}',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final p = await showTimePicker(
                        context: context,
                        initialTime: _weeklyEnd,
                      );
                      if (!mounted) return;
                      if (p == null) return;
                      setState(() => _weeklyEnd = p);
                    },
                    child: const Text('Seç'),
                  ),
                ],
              ),
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
      // MVP: end-before-start check optional
    }

    final weekly = (_type == EventScheduleType.recurring)
        ? WeeklyRuleDraft(days: {..._days}, start: _weeklyStart, end: _weeklyEnd)
        : null;

    Navigator.pop(
      context,
      EventDraft(
        id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
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
}
