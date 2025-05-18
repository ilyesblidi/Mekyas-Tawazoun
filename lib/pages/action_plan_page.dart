import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

Future<Map<String, dynamic>> fetchFromFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');
  final doc =
      await FirebaseFirestore.instance
          .collection('diagnostic_results')
          .doc(user.uid)
          .get();
  if (!doc.exists) throw Exception('No diagnostic results found');
  final data = doc.data();
  if (data == null || data['answers'] == null) {
    throw Exception('Invalid data format');
  }
  return Map<String, dynamic>.from(data['answers']);
}

Future<Map<String, dynamic>> loadDiagnosticResults() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('diagnostic_results');
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    } else {
      final data = await fetchFromFirestore();
      await prefs.setString('diagnostic_results', json.encode(data));
      return data;
    }
  } catch (e, stack) {
    debugPrint('Error loading diagnostic results: $e\n$stack');
    rethrow;
  }
}

class ActionPlanPage extends StatelessWidget {
  const ActionPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: loadDiagnosticResults(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'حدث خطأ أثناء تحميل النتائج',
                style: TextStyle(color: Colors.red, fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        final data = snapshot.data!;
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
                    double.tryParse(
                      fieldData['percentage']?.toString() ?? '0',
                    ) ??
                    0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fieldName,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A6F8E),
                                ),
                              ),
                            ),
                            CircularPercentIndicator(
                              radius: 32,
                              lineWidth: 7,
                              percent: (percent / 100).clamp(0.0, 1.0),
                              center: Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              progressColor: const Color(0xFF1A6F8E),
                              backgroundColor: Colors.grey[200]!,
                              animation: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: answers.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
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

                                  // Inside your ListTile:
                                  trailing: RatingBarIndicator(
                                    rating: (qEntry.value is num) ? qEntry.value.toDouble() : 0.0,
                                    itemBuilder: (context, _) => const Icon(
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
                                    decoration: const InputDecoration(
                                      labelText: 'التوصيات',
                                      labelStyle: TextStyle(
                                        fontFamily: 'Cairo',
                                      ),
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color getScoreColor(dynamic value) {
    // Adjust logic as needed for your score system
    if (value is num) {
      if (value >= 4) return Colors.green;
      if (value == 3 || value == 2) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }
}
