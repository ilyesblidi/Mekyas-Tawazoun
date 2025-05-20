import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActionPlanPage extends StatefulWidget {
  const ActionPlanPage({super.key});

  @override
  State<ActionPlanPage> createState() => _ActionPlanPageState();
}

class _ActionPlanPageState extends State<ActionPlanPage> {
  int? expandedIndex;
  final List<Map<String, String>> recommendations = List.generate(
    15,
    (i) => {
      'category': 'المحور ${i + 1}',
      'recommendation': 'التوصية العملية ${i + 1}',
    },
  );

  // Controllers and state for each card
  final List<int> impact = List.filled(15, 1);
  final List<int> ease = List.filled(15, 1);
  final List<DateTime?> startDates = List.filled(15, null);
  final List<DateTime?> endDates = List.filled(15, null);
  final List<String> status = List.filled(15, 'قيد التنفيذ');
  final List<TextEditingController> notes = List.generate(
    15,
    (_) => TextEditingController(),
  );

  String getPriority(int i) {
    int sum = impact[i] + ease[i];
    if (sum <= 2) return 'منخفضة';
    if (sum == 3 || sum == 4) return 'متوسطة';
    return 'مرتفعة';
  }

  int getDuration(int i) {
    if (startDates[i] != null && endDates[i] != null) {
      return endDates[i]!.difference(startDates[i]!).inDays + 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خطة العمل', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recommendations.length,
        itemBuilder: (context, idx) {
          final rec = recommendations[idx];
          final isExpanded = expandedIndex == idx;
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: isExpanded ? 10 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: isExpanded ? const Color(0xFFE3F6FF) : Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    rec['category'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A6F8E),
                    ),
                  ),
                  subtitle: Text(
                    rec['recommendation'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF1A6F8E),
                  ),
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : idx;
                    });
                  },
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: impact[idx],
                                decoration: const InputDecoration(
                                  labelText: 'عمق الأثر',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    [1, 2, 3]
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text('$v'),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  setState(() => impact[idx] = v ?? 1);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: ease[idx],
                                decoration: const InputDecoration(
                                  labelText: 'سهولة التطبيق',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    [1, 2, 3]
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text('$v'),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  setState(() => ease[idx] = v ?? 1);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'الأولوية',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          controller: TextEditingController(
                            text: getPriority(idx),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        startDates[idx] ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => startDates[idx] = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'البداية',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    startDates[idx] != null
                                        ? DateFormat(
                                          'yyyy/MM/dd',
                                        ).format(startDates[idx]!)
                                        : 'اختر تاريخ',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        endDates[idx] ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => endDates[idx] = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'النهاية',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    endDates[idx] != null
                                        ? DateFormat(
                                          'yyyy/MM/dd',
                                        ).format(endDates[idx]!)
                                        : 'اختر تاريخ',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'المدة (أيام)',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          controller: TextEditingController(
                            text: getDuration(idx).toString(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: status[idx],
                          decoration: const InputDecoration(
                            labelText: 'حالة المهمة',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'قيد التنفيذ',
                              child: Text('قيد التنفيذ'),
                            ),
                            DropdownMenuItem(
                              value: 'مكتملة',
                              child: Text('مكتملة'),
                            ),
                            DropdownMenuItem(
                              value: 'مؤجلة',
                              child: Text('مؤجلة'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => status[idx] = v ?? 'قيد التنفيذ');
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: notes[idx],
                          decoration: const InputDecoration(
                            labelText: 'تفاصيل وتعليقات',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.save),
        label: const Text('حفظ الكل', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1A6F8E),
      ),
    );
  }
}
