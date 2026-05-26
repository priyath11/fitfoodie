import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../auth/auth_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────
// SPLASH SCREEN
// Logic:
// - No account → show intro slides every time
// - Has account + onboarding done + < 10 logins → show intro
// - Has account + onboarding done + >= 10 logins → go straight to home
// ─────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 500), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final firebaseService = ref.read(firebaseServiceProvider);
    final user = firebaseService.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const IntroSlidesScreen()));
      return;
    }

    final hasOnboarding =
    await firebaseService.hasCompletedOnboarding(user.uid);
    if (!mounted) return;

    if (!hasOnboarding) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    final loginCount = prefs.getInt('login_count') ?? 0;
    await prefs.setInt('login_count', loginCount + 1);

    if (loginCount < 10) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const IntroSlidesScreen()));
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarBackground(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.restaurant_outlined,
                      size: 38,
                      color: AppColors.accent.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 28),
                Text('Fit Foodie', style: AppTextStyles.logoHero()),
                const SizedBox(height: 8),
                Text(
                  "DON'T DIET. JUST TRACK.",
                  style: AppTextStyles.label(
                      color: AppColors.accent.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// INTRO SLIDES
// 5 slides — last two are accuracy comparison
// ─────────────────────────────────────────
class IntroSlidesScreen extends StatefulWidget {
  const IntroSlidesScreen({super.key});

  @override
  State<IntroSlidesScreen> createState() => _IntroSlidesScreenState();
}

class _IntroSlidesScreenState extends State<IntroSlidesScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  Future<void> _next() async {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _skip();
    }
  }

  // ── 5 SLIDES ──────────────────────────
  static const List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.restaurant_outlined,
      tag: 'MADE FOR INDIA',
      title: 'Your laddoo\nand your abs.',
      body: 'Fit Foodie is built around real Indian food. Biryani, butter chicken, Kerala sadya, street chaat. No guilt — just awareness.',
      slideType: _SlideType.standard,
    ),
    _SlideData(
      icon: Icons.calendar_today_outlined,
      tag: 'WEEKLY BUDGET',
      title: 'A weekly wallet,\nnot a daily prison.',
      body: 'Splurge on Wednesday. Balance on Thursday. One budget for the whole week gives you real freedom without losing progress.',
      slideType: _SlideType.standard,
    ),
    _SlideData(
      icon: Icons.camera_alt_outlined,
      tag: 'THE MOULD SYSTEM',
      title: '3 photos.\nNot 1.',
      body: 'Most apps use one photo. We use three — top, side, close-up. Each angle tells the AI something the others cannot.',
      slideType: _SlideType.standard,
    ),
    _SlideData(
      icon: Icons.analytics_outlined,
      tag: 'ACCURACY',
      title: 'Why 3 photos\nchanges everything.',
      body: '',
      slideType: _SlideType.accuracy,
    ),
    _SlideData(
      icon: Icons.science_outlined,
      tag: 'HOW IT WORKS',
      title: 'What each photo\ntells our AI.',
      body: '',
      slideType: _SlideType.howItWorks,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingXXL, AppSizes.paddingMD,
                      AppSizes.paddingXXL, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.restaurant_outlined,
                            size: 12,
                            color: AppColors.accent.withValues(alpha: 0.3)),
                        const SizedBox(width: 5),
                        Text('Fit Foodie',
                            style: AppTextStyles.logoSmall(
                                color: AppColors.accent.withValues(alpha: 0.3))),
                      ]),
                      GestureDetector(
                        onTap: _skip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.06),
                            borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.12)),
                          ),
                          child: Text('SKIP',
                              style: AppTextStyles.label(
                                  color: AppColors.accent.withValues(alpha: 0.6))),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _slides.length,
                    itemBuilder: (ctx, i) {
                      final slide = _slides[i];
                      switch (slide.slideType) {
                        case _SlideType.accuracy:
                          return const _AccuracySlide();
                        case _SlideType.howItWorks:
                          return const _HowItWorksSlide();
                        case _SlideType.standard:
                          return _StandardSlide(data: slide);
                      }
                    },
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingXXL, 0,
                      AppSizes.paddingXXL, AppSizes.paddingXXL),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.accent.withValues(alpha: 0.85)
                                  : AppColors.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSizes.paddingXL),

                      // Next button
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingMD + 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            _currentPage < _slides.length - 1
                                ? 'NEXT'
                                : "LET'S GO",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonPrimary(),
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

// ── SLIDE TYPES ───────────────────────────
enum _SlideType { standard, accuracy, howItWorks }

class _SlideData {
  final IconData icon;
  final String tag;
  final String title;
  final String body;
  final _SlideType slideType;

  const _SlideData({
    required this.icon,
    required this.tag,
    required this.title,
    required this.body,
    required this.slideType,
  });
}

// ── STANDARD SLIDE ────────────────────────
class _StandardSlide extends StatelessWidget {
  final _SlideData data;
  const _StandardSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
            ),
            child: Icon(data.icon, size: 28,
                color: AppColors.accent.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: AppDecorations.tag(),
            child: Text(data.tag, style: AppTextStyles.tag()),
          ),
          const SizedBox(height: AppSizes.paddingLG),
          Text(data.title, style: AppTextStyles.logoLarge()),
          const SizedBox(height: AppSizes.paddingLG),
          Text(data.body,
              style: AppTextStyles.bodyMedium(
                  color: AppColors.accent.withValues(alpha: 0.65))),
          const Spacer(),
          const SizedBox(height: AppSizes.paddingXXL),
        ],
      ),
    );
  }
}

// ── ACCURACY SLIDE ────────────────────────
// Shows comparison vs single-photo apps
class _AccuracySlide extends StatelessWidget {
  const _AccuracySlide();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.analytics_outlined, size: 28,
                color: AppColors.accent.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: AppDecorations.tag(),
            child: Text('ACCURACY', style: AppTextStyles.tag()),
          ),
          const SizedBox(height: AppSizes.paddingLG),
          Text('Why 3 photos\nchanges everything.',
              style: AppTextStyles.logoLarge()),
          const SizedBox(height: AppSizes.paddingLG),
          Text(
            'Every other app uses a single photo. A single photo gives the AI flat information — it cannot judge depth, volume or oil content.',
            style: AppTextStyles.bodyMedium(
                color: AppColors.accent.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: AppSizes.paddingXXL),

          // Comparison table
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            decoration: AppDecorations.neuCard(),
            child: Column(
              children: [
                // Header
                Row(children: [
                  Expanded(flex: 3, child: Text('METHOD', style: AppTextStyles.label())),
                  Expanded(flex: 2, child: Text('ACCURACY', style: AppTextStyles.label(), textAlign: TextAlign.center)),
                ]),
                const SizedBox(height: AppSizes.paddingMD),
                const Divider(color: Color(0x10FFFFFF)),
                const SizedBox(height: AppSizes.paddingMD),

                _ComparisonRow(
                  method: 'Memory logging',
                  range: '40 – 60%',
                  color: const Color(0xFFFF5252),
                  isUs: false,
                ),
                _ComparisonRow(
                  method: 'Single photo apps',
                  range: '60 – 70%',
                  color: const Color(0xFFFF9800),
                  isUs: false,
                ),
                _ComparisonRow(
                  method: 'Fit Foodie (3 photos)',
                  range: '82 – 88%',
                  color: const Color(0xFF4CAF50),
                  isUs: true,
                ),
                _ComparisonRow(
                  method: 'Weighed + lab analysis',
                  range: '95 – 98%',
                  color: AppColors.accent.withValues(alpha: 0.4),
                  isUs: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMD),

          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Our 3-photo mould system delivers up to 28% more accuracy than single-photo tracking — without any manual effort.',
                    style: AppTextStyles.bodySmall(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingXXL),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String method;
  final String range;
  final Color color;
  final bool isUs;

  const _ComparisonRow({
    required this.method,
    required this.range,
    required this.color,
    required this.isUs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMD),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isUs)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('US',
                        style: AppTextStyles.label(
                            color: const Color(0xFF4CAF50))),
                  ),
                Expanded(
                  child: Text(method,
                      style: AppTextStyles.bodySmall(
                          color: isUs
                              ? AppColors.textPrimary
                              : AppColors.accent.withValues(alpha: 0.6))),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(range,
                    style: AppTextStyles.bodySmall(color: color),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: isUs
                        ? 0.85
                        : method.contains('Memory')
                        ? 0.5
                        : method.contains('Single')
                        ? 0.65
                        : 0.96,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── HOW IT WORKS SLIDE ────────────────────
class _HowItWorksSlide extends StatelessWidget {
  const _HowItWorksSlide();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.science_outlined, size: 28,
                color: AppColors.accent.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: AppDecorations.tag(),
            child: Text('HOW IT WORKS', style: AppTextStyles.tag()),
          ),
          const SizedBox(height: AppSizes.paddingLG),
          Text('What each photo\ntells our AI.',
              style: AppTextStyles.logoLarge()),
          const SizedBox(height: AppSizes.paddingXXL),

          _PhotoExplanation(
            number: '1',
            angle: "BIRD'S EYE",
            title: 'Identifies every dish',
            description: 'Held directly above the plate. Our AI maps every dish present and measures the total plate area relative to the mould frame.',
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSizes.paddingMD),
          _PhotoExplanation(
            number: '2',
            angle: 'LEAN IN 45°',
            title: 'Estimates volume and depth',
            description: 'Tilted at 45 degrees. A flat photo cannot see how deep a bowl of dal is. This angle gives the AI a 3D reference — the single biggest accuracy improvement.',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          _PhotoExplanation(
            number: '3',
            angle: 'CLOSE UP',
            title: 'Reveals oil and texture',
            description: 'Flash on, camera close. Oil content is invisible in distant photos. This angle exposes the surface texture, shine and cooking style — crucial for accurate calorie calculation.',
            color: const Color(0xFFFF9800),
          ),

          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: AppDecorations.insightCard(),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.accent.withValues(alpha: 0.55)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Three angles. One accurate result. This is the Fit Foodie difference.',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingXXL),
        ],
      ),
    );
  }
}

class _PhotoExplanation extends StatelessWidget {
  final String number;
  final String angle;
  final String title;
  final String description;
  final Color color;

  const _PhotoExplanation({
    required this.number,
    required this.angle,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: AppDecorations.neuCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(number,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(angle,
                    style: AppTextStyles.label(color: color)),
                const SizedBox(height: 2),
                Text(title,
                    style: AppTextStyles.bodyLarge(
                        color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.paddingXS),
                Text(description,
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}