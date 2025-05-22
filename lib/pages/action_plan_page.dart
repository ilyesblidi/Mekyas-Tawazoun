import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActionPlanPage extends StatefulWidget {
  const ActionPlanPage({super.key});

  @override
  State<ActionPlanPage> createState() => _ActionPlanPageState();
}

class _ActionPlanPageState extends State<ActionPlanPage> {
  Future<Map<String, dynamic>?> fetchActionPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('action_plan')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خطة العمل', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchActionPlan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('لا توجد بيانات خطة عمل'));
          }
          final data = snapshot.data!;
          final recs = data['recommendations'] as Map<String, dynamic>? ?? {};
          if (recs.isEmpty) {
            return const Center(child: Text('لا توجد توصيات محفوظة'));
          }
          // Flatten recommendations for display
          final items = <Map<String, String>>[];
          recs.forEach((category, questions) {
            (questions as Map<String, dynamic>).forEach((question, rec) {
              items.add({
                'category': category,
                'question': question,
                'recommendation': rec ?? '',
              });
            });
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final item = items[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    item['category'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A6F8E),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['question'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['recommendation'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}