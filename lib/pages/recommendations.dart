import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RecomandationsPage extends StatefulWidget {
  const RecomandationsPage({super.key});

  @override
  State<RecomandationsPage> createState() => _RecomandationsPageState();
}

class _RecomandationsPageState extends State<RecomandationsPage> {
  final Set<String> expandedFields = {};
  Map<String, Map<String, TextEditingController>> recommendationControllers =
      {};
  Map<String, dynamic> recommendations = {};
  bool isLoading = true;
  List<MapEntry<String, dynamic>> fields = [];

  @override
  void initState() {
    super.initState();
    _loadCachedThenFirestore();
  }

  Future<void> _loadCachedThenFirestore() async {
    await _loadCachedRecommendations();
    await _fetchAndUpdateFromFirestore();
  }

  Future<void> _loadCachedRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('recommendations');
    if (jsonString != null) {
      recommendations = json.decode(jsonString) as Map<String, dynamic>;
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchAndUpdateFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('diagnostic_results')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final recs =
          doc.data()?['recommendations'] as Map<String, dynamic>? ?? {};
      if (recs.isNotEmpty) {
        recommendations = recs;
        await _cacheRecommendations(recs);
        setState(() {});
      }
    }
  }

  Future<void> _cacheRecommendations(Map<String, dynamic> recs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recommendations', json.encode(recs));
  }

  void _initializeControllers(Map<String, dynamic> data) {
    for (final field in data.keys) {
      recommendationControllers[field] ??= {};
      final answers = Map<String, dynamic>.from(data[field]['answers'] ?? {});
      for (final question in answers.keys) {
        final recText =
            recommendations[field] != null
                ? (recommendations[field][question] ?? '')
                : '';
        recommendationControllers[field]![question] ??= TextEditingController(
          text: recText,
        );
      }
    }
  }

  Future<void> saveRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Build recommendations map from controllers
    final recs = recommendationControllers.map((field, questions) {
      return MapEntry(
        field,
        questions.map((question, controller) {
          return MapEntry(question, controller.text.trim());
        }),
      );
    });

    recommendations = recs;
    await _cacheRecommendations(recs);

    try {
      await FirebaseFirestore.instance
          .collection('diagnostic_results')
          .doc(user.uid)
          .update({'recommendations': recs});
    } catch (e) {
      // Firestore failed, but cache is updated
    }

    // Prepare action_plan items
    final List<Map<String, dynamic>> actionPlanItems = [];
    recs.forEach((field, questions) {
      questions.forEach((question, recommendation) {
        actionPlanItems.add({
          'محور': field,
          'التوصيات_العملية': recommendation,
          'سؤال': question,
          // Add default fields for action plan
          'عمق_الأثر': 1,
          'سهولة_التطبيق': 1,
          'الأولوية': 'منخفضة',
          'البداية': null,
          'النهاية': null,
          'المدة_أيام': 0,
          'حالة_المهمة': 'لم تبدأ بعد',
          'التفاصيل_والتعليقات': '',
        });
      });
    });

    // Save to action_plan collection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('action_plan', json.encode(actionPlanItems));
    try {
      await FirebaseFirestore.instance
          .collection('action_plan')
          .doc(user.uid)
          .set({
        'action_plan': actionPlanItems,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Firestore failed, but cache is updated
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ التوصيات بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('التوصيات', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF1A6F8E)),
          elevation: 1,
        ),
        body:
            isLoading
                ? Center(
                  child: CircularPercentIndicator(
                    radius: 40,
                    lineWidth: 8,
                    percent: 0.7,
                    center: CircularProgressIndicator(
                      color: Color(0xFF1A6F8E),
                      strokeWidth: 5,
                    ),
                    progressColor: Color(0xFF1A6F8E),
                    backgroundColor: Colors.grey[200]!,
                    animation: true,
                  ),
                )
                : StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('diagnostic_results')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    Map<String, dynamic> data = {};
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final docData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      data = docData['answers'] as Map<String, dynamic>? ?? {};
                    }
                    if (data.isEmpty) {
                      return Center(
                        child: Text(
                          'لم تقم بإجراء الاختبار التشخيصي بعد\nيرجى إجراء الاختبار التشخيصي',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            color: Color(0xFF1A6F8E),
                          ),
                        ),
                      );
                    }
                    fields = data.entries.toList();
                    _initializeControllers(data);

                    return ListView.builder(
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
                            double.tryParse(
                              fieldData['percentage']?.toString() ?? '0',
                            ) ??
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
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: answers.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, qIdx) {
                                      final qEntry = answers.entries.elementAt(
                                        qIdx,
                                      );
                                      recommendationControllers[fieldName] ??=
                                          {};
                                      recommendationControllers[fieldName]![qEntry
                                          .key] ??= TextEditingController(
                                        text:
                                            recommendations[fieldName] != null
                                                ? (recommendations[fieldName][qEntry
                                                        .key] ??
                                                    '')
                                                : '',
                                      );
                                      final controller =
                                          recommendationControllers[fieldName]![qEntry
                                              .key]!;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                                labelStyle: TextStyle(
                                                  fontFamily: 'Cairo',
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 12,
                                                    ),
                                              ),
                                              maxLines: 2,
                                              onChanged: (val) {
                                                recommendations[fieldName] ??=
                                                    {};
                                                recommendations[fieldName][qEntry
                                                        .key] =
                                                    val;
                                              },
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
              label: const Text(
                'حفظ التوصيات',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
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
