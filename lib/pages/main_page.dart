import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mekyas_tawazoun/pages/action_plan_page.dart';
import 'home_page.dart';
import 'diagnostic_page.dart';
import 'recommendations.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String firstName = '';
  String lastName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        firstName = doc.data()?['first name'] ?? '';
        lastName = doc.data()?['last name'] ?? '';
        isLoading = false;
      });
    }
  }

  List<Widget> get _pages => [
    HomePage(firstName: firstName, lastName: lastName, isLoading: isLoading,
      onStartDiagnostic: () => setState(() => _selectedIndex = 1),
    ),
    DiagnosticPage( onStartRecomendations: () => setState(() => _selectedIndex = 2), ),
    const RecomandationsPage(),
    const ActionPlanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF6FB),
        body: _pages[_selectedIndex],

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A6F8E), Color(0xFF83C5BE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18, // Increased size
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16, // Increased size
              ),
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 30),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services, size: 30),
                  label: 'التشخيص',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.tips_and_updates, size: 30),
                  label: 'التوصيات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checklist, size: 30),
                  label: 'خطة العمل',
                ),
              ],
            ),
          ),
        ),


      ),
    );
  }
}
