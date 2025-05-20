import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DiagnosticResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onRetake;
  final VoidCallback onCreatePlan;

  const DiagnosticResultPage({
    super.key,
    required this.result,
    required this.onRetake,
    required this.onCreatePlan,
  });

  static const Map<String, String> fieldNames = {
    'الجانب_الروحي': 'الجانب الروحي',
    'الجانب_الاجتماعي': 'الجانب الاجتماعي',
    'الجانب_العلمي': 'الجانب العلمي',
    'الجانب_الصحي': 'الجانب الصحي',
    'جانب_تطوير_المهارات': 'جانب تطوير المهارات',
    'الجانب_المالي': 'الجانب المالي',
  };

  static String interpretScore(double avg) {
    if (avg < 1) return 'تطبيق ضعيف جدًا';
    if (avg < 2) return 'تطبيق ضعيف';
    if (avg < 3) return 'تطبيق متوسط';
    if (avg < 4) return 'تطبيق جيد';
    return 'تطبيق ممتاز';
  }

  Color scoreColor(double percent) {
    if (percent < 20) return Colors.red;
    if (percent < 40) return Colors.orange;
    if (percent < 60) return Colors.amber;
    if (percent < 80) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final fields = fieldNames.keys.toList();
    final percentages =
        fields
            .map((f) => double.tryParse(result[f]?['percentage'] ?? '0') ?? 0.0)
            .toList();
    final avgs =
        fields.map((f) {
          final answers = Map<String, dynamic>.from(
            result[f]?['answers'] ?? {},
          );
          if (answers.isEmpty) return 0.0;
          return answers.values.fold(0, (a, b) => a + (b as int)) /
              answers.length;
        }).toList();

    // Calculate general percentage
    final generalPercent =
        percentages.isNotEmpty
            ? (percentages.reduce((a, b) => a + b) / percentages.length)
            : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title: const Text(
            'نتائج التشخيص',
            style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF1A6F8E)),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Color(0xFF1A6F8E)),
              tooltip: 'مشاركة النتائج',
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 300,
                    child: RadarChart(
                      features: fields.map((f) => fieldNames[f]!).toList(),
                      data: [percentages], // percentages are 0–100
                      ticks: [20, 40, 60, 80, 100],
                      featuresTextStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: Color(0xFF1A6F8E),
                      ),
                      outlineColor: Colors.grey[300]!,
                      graphColors: [const Color(0xFF1A6F8E)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                color: const Color(0xFF1A6F8E),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'النسبة العامة للتشخيص',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${generalPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(fields.length, (i) {
                final avg = avgs[i];
                final percent = percentages[i];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularPercentIndicator(
                          radius: 32,
                          lineWidth: 7,
                          percent: (percent / 100).clamp(0.0, 1.0),
                          center: Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          progressColor: scoreColor(percent),
                          backgroundColor: Colors.grey[200]!,
                          animation: true,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fieldNames[fields[i]]!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A6F8E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                interpretScore(avg),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: scoreColor(percent),
                                ),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: (percent / 100).clamp(0.0, 1.0),
                                minHeight: 7,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scoreColor(percent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D77),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.event_note, color: Colors.white),
                      label: const Text(
                        'إنشاء خطة عمل',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: onCreatePlan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A6F8E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.refresh, color: Color(0xFF1A6F8E)),
                      label: const Text(
                        'إعادة التشخيص',
                        style: TextStyle(color: Color(0xFF1A6F8E)),
                      ),
                      onPressed: onRetake,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
