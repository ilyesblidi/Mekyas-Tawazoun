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
  final doc =
      await FirebaseFirestore.instance
          .collection('diagnostic_results')
          .doc(user.uid)
          .get();
  if (!doc.exists) return null; // User hasn't taken the diagnostic yet
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

  @override
  void initState() {
    super.initState();
    loadDiagnosticResults()
        .then((data) {
          setState(() {
            diagnosticData = data;
            isLoading = false;
          });
        })
        .catchError((e) {
          setState(() {
            errorMsg = 'حدث خطأ أثناء تحميل النتائج';
            isLoading = false;
          });
        });
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
    // Show message if no diagnostic data
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
            'المخطط العملي',
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
                                  textDirection: TextDirection.rtl,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 0,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'التوصيات',
                                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    // suffixIcon: IconButton(
                                    //   icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                                    //   onPressed: () {
                                    //   },
                                    //   tooltip: 'توليد تلقائي',
                                    // ),
                                  ),
                                  maxLines: 2,
                                )
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
      ),
    );
  }
}
