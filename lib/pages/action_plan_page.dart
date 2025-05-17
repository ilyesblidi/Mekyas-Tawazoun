import 'package:flutter/material.dart';

class ActionPlanPage extends StatelessWidget {
  const ActionPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'صفحة المخطط العملي',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A6F8E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}