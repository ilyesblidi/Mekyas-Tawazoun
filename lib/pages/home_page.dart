import 'package:flutter/material.dart';
import 'package:mekyas_tawazoun/pages/profile_page.dart';
import 'package:timeline_tile/timeline_tile.dart';


class _WelcomeUserCard extends StatelessWidget {
  final String firstName;

  const _WelcomeUserCard({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A6F8E), Color(0xFF83C5BE)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1A6F8E), size: 38),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبًا${firstName.isNotEmpty ? '، $firstName' : ''} 👋',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'نتمنى لك تجربة متوازنة وملهمة!',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final bool isLoading;
  final VoidCallback onStartDiagnostic;

  const HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.isLoading,
    required this.onStartDiagnostic,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Icon(Icons.balance, color: Color(0xFF006D77), size: 32),
            // const SizedBox(width: 8),
            const Text(
              'مقياس التوازن الشخصي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006D77),
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child:
            widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeUserCard(firstName: widget.firstName),
                      const _ProgramMessageCard(),
                      const SizedBox(height: 24),
                      const _DimensionsGrid(),
                      const SizedBox(height: 32),
                      const _VerticalTimeline(),
                      const SizedBox(height: 32),
                      _StartButton(onPressed: widget.onStartDiagnostic),
                    ],
                  ),
                ),
      ),
    );
  }
}


// 1. Program Message Card
class _ProgramMessageCard extends StatelessWidget {
  const _ProgramMessageCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Slogan Card
        Card(
          color: const Color(0xFF1A6F8E),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Center(
              child: Text(
                'النجاح = التوازن + الأهداف + خطة عمل',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // Description Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FAFC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'مقياس التوازن الشخصي هو أداة تساعدك على تقييم جوانب حياتك الستة، واكتشاف نقاط القوة والضعف لديك، ثم تحويل نتائج التقييم إلى خطة عمل عملية لتحقيق التوازن والنجاح في حياتك.',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: Color(0xFF006D77),
              height: 1.7,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// 2. Dimensions Grid
class _DimensionsGrid extends StatelessWidget {
  const _DimensionsGrid();

  static final List<_DimensionData> _dimensions = [
    _DimensionData(
      icon: Icons.self_improvement,
      label: 'الجانب الروحي',
      description:
          'تعزيز العلاقة مع الله والالتزام بالشعائر الدينية، القيم النبيلة والسلوكيات الإيمانية، العلاقات الاجتماعية وخدمة المجتمع',
      color: Color(0xFF83C5BE),
    ),
    _DimensionData(
      icon: Icons.school,
      label: 'الجانب العلمي',
      description:
          'التفوق الأكاديمي، التطوير الشخصي، التفكير النقدي وتعزيز الإبداع',
      color: Color(0xFFCAE9FF),
    ),
    _DimensionData(
      icon: Icons.people,
      label: 'الجانب الاجتماعي',
      description:
          'إدارة العلاقات الإنسانية، تطوير الذكاء العاطفي، المسؤولية الاجتماعية',
      color: Color(0xFFFFE066),
    ),
    _DimensionData(
      icon: Icons.health_and_safety,
      label: 'الجانب الصحي',
      description:
          'العناية بالصحة الجسدية والنظام الغذائي، الراحة النفسية، النظافة الشخصية',
      color: Color(0xFFB7E4C7),
    ),
    _DimensionData(
      icon: Icons.psychology,
      label: 'جانب تطوير المهارات',
      description:
          'إدارة الوقت والمهام، التواصل والمهارات الشخصية، القيادة واتخاذ القرارات',
      color: Color(0xFFFFB4A2),
    ),
    _DimensionData(
      icon: Icons.attach_money,
      label: 'الجانب المالي',
      description:
          'التحكم في النفقات، التخطيط المالي، الوعي بالقيم الإسلامية في التعامل مع المال',
      color: Color(0xFFB5D0FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: _dimensions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final dim = _dimensions[i];
        return _DimensionCard(data: dim);
      },
    );
  }
}

class _DimensionData {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _DimensionData({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

class _DimensionCard extends StatelessWidget {
  final _DimensionData data;

  const _DimensionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    data.label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006D77),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  content: Text(
                    data.description,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: Color(0xFF006D77),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Color(0xFF006D77),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: data.color,
                radius: 28,
                child: Icon(
                  data.icon,
                  color: const Color(0xFF006D77),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF006D77),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Vertical Timeline
class _VerticalTimeline extends StatelessWidget {
  const _VerticalTimeline();

  static final List<_TimelineStep> _steps = [
    _TimelineStep(
      icon: Icons.checklist,
      title: 'تقييم',
      subtitle: 'قيّم جوانب حياتك الستة',
    ),
    _TimelineStep(
      icon: Icons.lightbulb,
      title: 'استخراج النقاط',
      subtitle: 'حدد نقاط القوة والضعف',
    ),
    _TimelineStep(
      icon: Icons.star,
      title: 'تحديد الأولويات',
      subtitle: 'اختر ما يحتاج تركيزك أولاً',
    ),
    _TimelineStep(
      icon: Icons.assignment,
      title: 'خطة عمل',
      subtitle: 'ضع خطة عملية للتحسين',
    ),
    _TimelineStep(
      icon: Icons.track_changes,
      title: 'متابعة',
      subtitle: 'تابع تقدمك وقيّم النتائج',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: List.generate(_steps.length, (index) {
            final step = _steps[index];
            return TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.1,
              isFirst: index == 0,
              isLast: index == _steps.length - 1,
              indicatorStyle: IndicatorStyle(
                width: 36,
                height: 36,
                indicator: CircleAvatar(
                  backgroundColor: const Color(0xFF006D77),
                  child: Icon(step.icon, color: Colors.white, size: 20),
                ),
                padding: EdgeInsets.zero,
              ),
              beforeLineStyle: const LineStyle(
                color: Color(0xFF83C5BE),
                thickness: 3,
              ),
              afterLineStyle: const LineStyle(
                color: Color(0xFF83C5BE),
                thickness: 3,
              ),
              endChild: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 24, top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FFF8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF006D77),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Color(0xFF83C5BE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              startChild: const SizedBox(width: 0),
            );
          }),
        ),
      ),
    );
  }
}

class _TimelineStep {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// 4. Start Button
class _StartButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _StartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006D77),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: const Text(
          'ابدأ التقييم الآن',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
