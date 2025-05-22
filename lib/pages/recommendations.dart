import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

Future<Map<String, dynamic>?> fetchFromFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');
  final doc = await FirebaseFirestore.instance
      .collection('diagnostic_results')
      .doc(user.uid)
      .get();
  if (!doc.exists) return null;
  final data = doc.data();
  if (data == null || data['answers'] == null) {
    throw Exception('Invalid data format');
  }
  return Map<String, dynamic>.from(data['answers']);
}

Future<Map<String, dynamic>?> loadDiagnosticResults() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('diagnostic_results');
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    } else {
      final data = await fetchFromFirestore();
      if (data != null) {
        await prefs.setString('diagnostic_results', json.encode(data));
      }
      return data;
    }
  } catch (e, stack) {
    debugPrint('Error loading diagnostic results: $e\n$stack');
    rethrow;
  }
}

class RecomandationsPage extends StatefulWidget {
  const RecomandationsPage({super.key});

  @override
  State<RecomandationsPage> createState() => _RecomandationsPageState();
}

class _RecomandationsPageState extends State<RecomandationsPage> {
  final Set<String> expandedFields = {};
  Map<String, dynamic>? diagnosticData;
  bool isLoading = true;
  String? errorMsg;

  Map<String, Map<String, TextEditingController>> recommendationControllers = {};

  @override
  void initState() {
    super.initState();
    loadDiagnosticResults()
        .then((data) {
          diagnosticData = data;
          isLoading = false;
          _initializeControllers(data);
        })
        .catchError((e) {
          setState(() {
            errorMsg = 'حدث خطأ أثناء تحميل النتائج';
            isLoading = false;
          });
        });
  }

  // Save recommendations to SharedPreferences
  Future<void> cacheRecommendations(Map<String, dynamic> recs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recommendations', json.encode(recs));
  }

  // Load recommendations from SharedPreferences
  Future<Map<String, dynamic>> loadCachedRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('recommendations');
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    }
    return {};
  }

  void _initializeControllers(Map<String, dynamic>? data) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || data == null) return;

  // Initialize controllers for all fields/questions
  for (final field in data.keys) {
    recommendationControllers[field] = {};
    for (final question in data[field]['answers'].keys) {
      recommendationControllers[field]![question] = TextEditingController();
    }
  }

  // Try to load recommendations from cache first
  Map<String, dynamic> recs = await loadCachedRecommendations();

  // If cache is empty, fetch from Firestore and cache it
  if (recs.isEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('diagnostic_results')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      recs = doc.data()?['recommendations'] as Map<String, dynamic>? ?? {};
      await cacheRecommendations(recs);
    }
  }

  // Fill controllers
  for (final field in recs.keys) {
    final questions = recs[field] as Map<String, dynamic>? ?? {};
    for (final question in questions.keys) {
      final recText = questions[question] ?? '';
      if (recommendationControllers[field] != null &&
          recommendationControllers[field]![question] != null) {
        recommendationControllers[field]![question]!.text = recText;
      }
    }
  }
  setState(() {});
}

  Future<void> saveRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load existing action plan from cache
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> actionPlanList = [];
    final cached = prefs.getString('action_plan');
    if (cached != null) {
      actionPlanList = List<Map<String, dynamic>>.from(json.decode(cached));
    }

    // Helper to find existing item
    Map<String, dynamic>? findExisting(String field, String question) {
      return actionPlanList.firstWhere(
        (item) => item['محور'] == field && item['السؤال'] == question,
        orElse: () => {},
      );
    }

    // Update or add only modified recommendations
    for (final field in recommendationControllers.keys) {
      for (final question in recommendationControllers[field]!.keys) {
        final controller = recommendationControllers[field]![question]!;
        final recText = controller.text.trim();
        if (recText.isNotEmpty) {
          final existing = findExisting(field, question);
          if (existing!.isNotEmpty) {
            // Update existing
            existing['التوصيات_العملية'] = recText;
          } else {
            // Add new
            actionPlanList.add({
              'محور': field,
              'السؤال': question,
              'التوصيات_العملية': recText,
              'عمق_الأثر': 1,
              'سهولة_التطبيق': 1,
              'الأولوية': '',
              'البداية': DateTime.now().toIso8601String(),
              'النهاية': DateTime.now().toIso8601String(),
              'المدة_أيام': 0,
              'حالة_المهمة': 'لم تبدأ بعد',
              'التفاصيل_والتعليقات': '',
            });
          }
        }
      }
    }

    // Save to Firestore and cache
    await FirebaseFirestore.instance
        .collection('action_plan')
        .doc(user.uid)
        .set({'action_plan': actionPlanList, 'created_at': FieldValue.serverTimestamp()});
    await prefs.setString('action_plan', json.encode(actionPlanList));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التوصيات وخطة العمل بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMsg!,
            style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (diagnosticData == null || diagnosticData!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'لم تقم بإجراء الاختبار التشخيصي بعد\nيرجى إجراء الاختبار التشخيصي',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              color: Color(0xFF1A6F8E),
            ),
          ),
        ),
      );
    }

    final data = diagnosticData!;
    final fields = data.entries.toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'التوصيات',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF1A6F8E)),
          elevation: 1,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fields.length,
          itemBuilder: (context, idx) {
            final entry = fields[idx];
            final fieldName = entry.key;
            final fieldData = entry.value as Map<String, dynamic>;
            final answers = Map<String, dynamic>.from(
              fieldData['answers'] ?? {},
            );
            final percent =
                double.tryParse(fieldData['percentage']?.toString() ?? '0') ??
                0;
            final isExpanded = expandedFields.contains(fieldName);

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      fieldName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1A6F8E),
                      ),
                    ),
                    leading: CircularPercentIndicator(
                      radius: 28,
                      lineWidth: 6,
                      percent: (percent / 100).clamp(0.0, 1.0),
                      center: Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                      progressColor: const Color(0xFF1A6F8E),
                      backgroundColor: Colors.grey[200]!,
                      animation: true,
                    ),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF1A6F8E),
                    ),
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedFields.remove(fieldName);
                        } else {
                          expandedFields.add(fieldName);
                        }
                      });
                    },
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: answers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, qIdx) {
                          final qEntry = answers.entries.elementAt(qIdx);
                          recommendationControllers[fieldName] ??= {};
                          recommendationControllers[fieldName]![qEntry.key] ??= TextEditingController();
                          final controller = recommendationControllers[fieldName]![qEntry.key]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                title: Text(
                                  qEntry.key,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: RatingBarIndicator(
                                  rating:
                                      (qEntry.value is num)
                                          ? qEntry.value.toDouble()
                                          : 0.0,
                                  itemBuilder:
                                      (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                  itemCount: 5,
                                  itemSize: 17,
                                  unratedColor: Colors.grey[300],
                                  direction: Axis.horizontal,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: TextFormField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'التوصيات',
                                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('حفظ التوصيات', style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6F8E),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: saveRecommendations,
            ),
          ),
        ),

      ),
    );
  }
}