import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

  class RegisterPage extends StatefulWidget {
    final VoidCallback? showLoginPage;
    const RegisterPage({super.key, this.showLoginPage});

    @override
    State<RegisterPage> createState() => _RegisterPageState();
  }

  class _RegisterPageState extends State<RegisterPage> {
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    @override
    void dispose() {
      _firstNameController.dispose();
      _lastNameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      super.dispose();
    }

    Future<void> signUp() async {
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String confirmPassword = _confirmPasswordController.text.trim();

      if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى ملء جميع الحقول'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كلمات المرور غير متطابقة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

        // Optionally, you can store the user's first and last name in the database
        // For example, using Firestore:
        // await FirebaseFirestore.instance.collection('users').add({
        //   'first_name': firstName,
        //   'last_name': lastName,
        //   'email': email,
        //   'uid': FirebaseAuth.instance.currentUser?.uid,
        // });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'حدث خطأ أثناء إنشاء الحساب'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ غير متوقع'),
            backgroundColor: Colors.red,
          ),
        );


      }

    }

    @override
    Widget build(BuildContext context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFEAF6FB), // Soft pastel blue
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'إنشاء حساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A6F8E),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // First Name
                        TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'الاسم',
                            labelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Color(0xFF1A6F8E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1A6F8E)),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 16),
                        // Last Name
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'اللقب',
                            labelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Color(0xFF1A6F8E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1A6F8E)),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 16),
                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            labelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Color(0xFF1A6F8E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A6F8E)),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            labelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Color(0xFF1A6F8E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A6F8E)),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            labelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Color(0xFF1A6F8E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A6F8E)),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 28),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A6F8E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'إنشاء حساب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Login Link
                        GestureDetector(
                          onTap: widget.showLoginPage,
                          child: Text(
                            'هل لديك حساب؟ تسجيل الدخول',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: const Color(0xFF1A6F8E),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }