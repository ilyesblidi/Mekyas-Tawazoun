import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'diagnostic_result_page.dart';

class DiagnosticPage extends StatefulWidget {

  final VoidCallback onStartRecomendations;

  const DiagnosticPage(
      {
        super.key,
        required this.onStartRecomendations,
  });

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  bool _showResult = false;
  Map<String, dynamic>? _lastResult;

  late Future<Map<String, List<String>>> _questionsFuture;
  final PageController _pageController = PageController();
  int _currentFieldIndex = 0;
  Map<String, Map<String, int>> _answers = {};

  static const Map<int, String> _scoreLabels = {
    0: 'لا يوجد تطبيق',
    1: 'بداية التطبيق أو تطور طفيف',
    2: 'تطبيق أو تطور محدود',
    3: 'تطبيق متوسط أو تطور ملحوظ',
    4: 'تطبيق جيد جدًا أو تطور متقدم',
    5: 'تطبيق مثالي أو تطور كامل',
  };

  static const Map<String, String> _fieldDescriptions = {
    'الجانب_الروحي':
        'هذا الجانب يركز على تطويرك الروحي من خلال العبادات والتأمل.',
    'الجانب_الاجتماعي': 'هذا الجانب يركز على علاقاتك الاجتماعية وصلة الرحم.',
    'الجانب_العلمي': 'هذا الجانب يركز على تطويرك العلمي والمعرفي.',
    'الجانب_الصحي': 'هذا الجانب يركز على صحتك الجسدية والعادات الصحية.',
    'جانب_تطوير_المهارات':
        'هذا الجانب يركز على صحتك النفسية والتعامل مع الضغوط.',
    'الجانب_المالي': 'هذا الجانب يركز على تطورك المهني وإدارة أمورك المالية.',
  };

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
    _checkIfHasResult();
  }

  Future<void> _checkIfHasResult() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('diagnostic_results');
    if (jsonString != null) {
      setState(() {
        _showResult = true;
        _lastResult = Map<String, dynamic>.from(json.decode(jsonString));
      });
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('diagnostic_results')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['answers'] != null) {
            await prefs.setString(
              'diagnostic_results',
              json.encode(data['answers']),
            );
            setState(() {
              _showResult = true;
              _lastResult = Map<String, dynamic>.from(data['answers']);
            });
          }
        }
      }
    }
  }

  Future<Map<String, List<String>>> _loadQuestions() async {
    final jsonString = await rootBundle.loadString('lib/assets/questions.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    return data.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  void _onScoreSelected(String field, String question, int score) {
    setState(() {
      _answers[field] ??= {};
      _answers[field]![question] = score;
    });
  }

  void _goToPage(int index) {
    setState(() => _currentFieldIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  double _calculateFieldPercentage(String field, List<String> questions) {
    final answers = _answers[field] ?? {};
    int total = 0;
    for (var q in questions) {
      total += answers[q] ?? 0;
    }
    int maxTotal = questions.length * 5;
    if (maxTotal == 0) return 0;
    return (total / maxTotal) * 100;
  }

  Future<void> _saveResults(Map<String, List<String>> questionsMap) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> result = {};
    questionsMap.forEach((field, questions) {
      final fieldAnswers = <String, int>{};
      for (var q in questions) {
        fieldAnswers[q] = _answers[field]?[q] ?? 0;
      }
      result[field] = {
        'answers': fieldAnswers,
        'percentage': _calculateFieldPercentage(
          field,
          questions,
        ).toStringAsFixed(1),
      };
    });
    await prefs.setString('diagnostic_results', json.encode(result));
    await _syncToFirestore(result);
  }

  Future<void> _syncToFirestore(Map<String, dynamic> result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('diagnostic_results')
        .doc(user.uid)
        .set({'answers': result, 'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> _onFinish(Map<String, List<String>> questionsMap) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'تأكيد التشخيص',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            content: const Text(
              'هل أنت متأكد من إنهاء التشخيص؟',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text(
                  'تأكيد',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await _saveResults(questionsMap);
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('diagnostic_results');
      if (jsonString != null) {
        setState(() {
          _showResult = true;
          _lastResult = Map<String, dynamic>.from(json.decode(jsonString));
        });
      }
    }
  }

  Widget _buildDiagnosticContent(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ أثناء تحميل الأسئلة',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.red,
                fontSize: 18,
              ),
            ),
          );
        }
        final fields = snapshot.data!.keys.toList();
        final questionsMap = snapshot.data!;
        final field = fields[_currentFieldIndex];
        final questions = questionsMap[field]!;
        final percentage = _calculateFieldPercentage(field, questions);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: (_currentFieldIndex + 1) / fields.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1A6F8E),
                  ),
                  minHeight: 10,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'الجانب ${_currentFieldIndex + 1} من ${fields.length}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF006D77),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: const Color(0xFF1A6F8E),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(
                _fieldDescriptions[field] ?? '',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  color: Color(0xFF1A6F8E),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Chip(
                backgroundColor: const Color(0xFF83C5BE),
                label: Text(
                  'النسبة: ${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                avatar: const Icon(Icons.percent, color: Colors.white),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fields.length,
                itemBuilder: (context, fieldIndex) {
                  final field = fields[fieldIndex];
                  final questions = questionsMap[field]!;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: ListView.separated(
                      key: ValueKey(field),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, qIndex) {
                        final question = questions[qIndex];
                        final selected = _answers[field]?[question] ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  question,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 17,
                                    color: Color(0xFF1A6F8E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (score) {
                                    final isSelected = selected == score;
                                    return GestureDetector(
                                      onTap:
                                          () => _onScoreSelected(
                                            field,
                                            question,
                                            score,
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? const Color(0xFF1A6F8E)
                                                  : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Colors.orange,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            score.toString(),
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _scoreLabels[selected]!,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: Color(0xFF006D77),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentFieldIndex > 0)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF83C5BE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text(
                        'السابق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _goToPage(_currentFieldIndex - 1),
                    )
                  else
                    const SizedBox(width: 100),
                  if (_currentFieldIndex < fields.length - 1)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6F8E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'التالي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _goToPage(_currentFieldIndex + 1),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D77),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'إنهاء التشخيص',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _onFinish(questionsMap),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF6FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'التشخيص',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A6F8E),
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1A6F8E)),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child:
              _showResult && _lastResult != null
                  ? DiagnosticResultPage(
                    result: _lastResult!,
                    onRetake: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text(
                                'تأكيد إعادة التشخيص',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                              content: const Text(
                                'هل أنت متأكد من رغبتك في إعادة التشخيص؟ سيتم حذف الإجابات السابقة.',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                ),
                                ElevatedButton(
                                  child: const Text(
                                    'تأكيد',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                      );
                      if (confirmed == true) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('diagnostic_results');
                        setState(() {
                          _answers.clear();
                          _showResult = false;
                          _lastResult = null;
                          _currentFieldIndex = 0;
                        });
                      }
                    },
                    onCreatePlan: widget.onStartRecomendations,
                  )
                  : _buildDiagnosticContent(context),
        ),
      ),
    );
  }
}
