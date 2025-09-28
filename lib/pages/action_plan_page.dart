import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActionPlanPage extends StatefulWidget {
  const ActionPlanPage({super.key});

  @override
  State<ActionPlanPage> createState() => _ActionPlanPageState();
}

class _ActionPlanPageState extends State<ActionPlanPage> {
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, Color> statusColors = {
    'لم تبدأ بعد': Colors.red,
    'قيد التنفيذ': Colors.orange,
    'منتهية': Colors.green,
  };

  final List<String> statusList = ['لم تبدأ بعد', 'قيد التنفيذ', 'منتهية'];

  @override
  void initState() {
    super.initState();
    _loadActionPlan();
  }

  dynamic _convertTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, _convertTimestamps(v)));
    } else if (value is List) {
      return value.map(_convertTimestamps).toList();
    }
    return value;
  }

  Future<void> _loadActionPlan() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('action_plan');
    List<Map<String, dynamic>> items = [];
    if (jsonString != null) {
      items = List<Map<String, dynamic>>.from(json.decode(jsonString));
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('action_plan')
                .doc(user.uid)
                .get();
        final data = doc.data();
        if (data != null && data['action_plan'] is List) {
          items = List<Map<String, dynamic>>.from(data['action_plan']);
          await prefs.setString(
            'action_plan',
            json.encode(_convertTimestamps(items)),
          );
        }
      }
    }
    // Filter out empty recommendations
    items = items.where((item) =>
      (item['التوصيات_العملية'] != null) &&
      item['التوصيات_العملية'].toString().trim().isNotEmpty
    ).toList();

    setState(() {
      _allItems = items;
      _isLoading = false;
    });
  }

  Future<void> _saveActionPlan() async {
    setState(() => _isSaving = true);
    for (var item in _allItems) {
      int impact =
          (item['عمق_الأثر'] is int)
              ? item['عمق_الأثر']
              : int.tryParse(item['عمق_الأثر']?.toString() ?? '') ?? 1;
      int ease =
          (item['سهولة_التطبيق'] is int)
              ? item['سهولة_التطبيق']
              : int.tryParse(item['سهولة_التطبيق']?.toString() ?? '') ?? 1;
      item['الأولوية'] = _calculatePriority(impact, ease);

      DateTime? start = _parseDate(item['البداية']);
      DateTime? end = _parseDate(item['النهاية']);
      item['المدة_أيام'] = _calculateDuration(start, end);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'action_plan',
      json.encode(_convertTimestamps(_allItems)),
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('action_plan')
          .doc(user.uid)
          .set({
            'action_plan': _allItems,
            'updated_at': FieldValue.serverTimestamp(),
          });
    }
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
  }

  String _calculatePriority(int impact, int ease) {
    final sum = impact + ease;
    if (sum >= 5) return 'عالية';
    if (sum == 4) return 'متوسطة';
    return 'منخفضة';
  }

  int _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    return end.difference(start).inDays + 1;
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String) return DateTime.tryParse(date);
    if (date is DateTime) return date;
    return null;
  }

  Map<String, List<Map<String, dynamic>>> _groupByMahwar(
    List<Map<String, dynamic>> items,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final key = item['محور'] as String? ?? 'غير محدد';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text(
                'خطة العمل',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _isSaving ? null : _saveActionPlan,
                  tooltip: 'حفظ التعديلات',
                ),
              ],
            ),
            body:
                _isLoading
                    ? Center(
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      strokeWidth: 7,
                      color: Color(0xFF1A6F8E),
                    ),
                  ),
                )
                    : _allItems.isEmpty
                    ? const Center(
                      child: Text(
                        'لا توجد توصيات محفوظة',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    )
                    : ListView(
                      padding: const EdgeInsets.all(16),
                      children:
                          _groupByMahwar(_allItems).entries.map((entry) {
                            final mahwar = entry.key;
                            final items = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    mahwar,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFF1A6F8E),
                                    ),
                                  ),
                                ),
                                ...items.asMap().entries.map(
                                  (itemEntry) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 14.0,
                                    ),
                                    child: _buildEditableActionPlanItem(
                                      itemEntry.value,
                                    ),
                                  ),
                                ),
                                const Divider(height: 32, thickness: 1.2),
                              ],
                            );
                          }).toList(),
                    ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableActionPlanItem(Map<String, dynamic> item) {
    int impact = (item['عمق_الأثر'] is int) ? item['عمق_الأثر'] : int.tryParse(item['عمق_الأثر']?.toString() ?? '') ?? 1;
    int ease = (item['سهولة_التطبيق'] is int) ? item['سهولة_التطبيق'] : int.tryParse(item['سهولة_التطبيق']?.toString() ?? '') ?? 1;
    String priority = _calculatePriority(impact, ease);

    DateTime? start = _parseDate(item['البداية']);
    DateTime? end = _parseDate(item['النهاية']);
    int duration = _calculateDuration(start, end);

    String status = item['حالة_المهمة'] as String? ?? statusList[0];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recommendation Title
            Row(
              children: [
                Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['التوصيات_العملية'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Impact, Ease, Priority (responsive)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 120,
                  child: _buildDropdownField(
                    'عمق الأثر',
                    impact,
                    [1, 2, 3],
                    (v) => setState(() => item['عمق_الأثر'] = v),
                    icon: Icons.trending_up,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _buildDropdownField(
                    'سهولة التطبيق',
                    ease,
                    [1, 2, 3],
                    (v) => setState(() => item['سهولة_التطبيق'] = v),
                    icon: Icons.speed,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _buildLabelField(
                    'الأولوية',
                    priority,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Dates and Duration (responsive)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 120,
                  child: _buildDateField(
                    'البداية',
                    start,
                    (picked) => setState(() => item['البداية'] = picked.toIso8601String()),
                    icon: Icons.calendar_today,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _buildDateField(
                    'النهاية',
                    end,
                    (picked) => setState(() => item['النهاية'] = picked.toIso8601String()),
                    icon: Icons.event,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _buildLabelField(
                    'المدة',
                    '$duration يوم',
                    icon: Icons.timelapse,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Status
            Row(
              children: [
                Icon(Icons.info, color: statusColors[status] ?? Colors.grey, size: 20),
                const SizedBox(width: 6),
                Text('حالة المهمة:', style: const TextStyle(fontFamily: 'Cairo')),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    items: statusList
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontFamily: 'Cairo'))))
                        .toList(),
                    onChanged: (v) => setState(() => item['حالة_المهمة'] = v),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Details/Comments
            TextFormField(
              initialValue: item['التفاصيل_والتعليقات'] ?? '',
              decoration: InputDecoration(
                labelText: 'تفاصيل / تعليقات',
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.comment, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                fillColor: Colors.grey[50],
                filled: true,
              ),
              maxLines: 1,
              onChanged: (v) => item['التفاصيل_والتعليقات'] = v,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets with icons and improved spacing
  Widget _buildDropdownField(String label, int value, List<int> options, ValueChanged<int?> onChanged, {IconData? icon}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: Colors.grey[700]),
              if (icon != null) const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            ],
          ),
          DropdownButtonFormField<int>(
            value: value,
            items: options.map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelField(String label, String value, {Color? color, IconData? icon}) {
    return Expanded(
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 16, color: Colors.grey[700]),
          if (icon == null) const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: color ?? Colors.black, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, ValueChanged<DateTime> onPicked, {IconData? icon}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: Colors.grey[700]),
              if (icon != null) const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            ],
          ),
          InkWell(
            onTap: () async {
              DateTime initial = date ?? DateTime.now();
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                locale: const Locale('ar', ''), // Arabic calendar
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              );
              if (picked != null) onPicked(picked);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[50],
              ),
              child: Text(
                date != null
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                    : 'اختر تاريخ',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.blue,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
