import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../widgets/common_widgets.dart';
import 'confirmation_screen.dart';
import 'manual_log_screen.dart';

// ─────────────────────────────────────────
// MEAL LOG SCREEN
// ─────────────────────────────────────────
class MealLogScreen extends ConsumerStatefulWidget {
  const MealLogScreen({super.key});

  @override
  ConsumerState<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends ConsumerState<MealLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealLogViewModelProvider.notifier).reset();
      _checkPermission();
    });
  }

  Future<void> _checkPermission() async {
    final status = await ph.Permission.camera.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await ph.Permission.camera.request();
      if (!result.isGranted && mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        title: Text('Camera Required',
            style: AppTextStyles.headingMedium()),
        content: Text(
          'Fit Foodie needs camera access to analyse your meals. Our 3-photo mould system is the core feature.',
          style: AppTextStyles.bodyMedium(
              color: AppColors.accent.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Cancel',
                style: AppTextStyles.bodySmall(
                    color: AppColors.accent.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ph.openAppSettings();
            },
            child: Text('Open Settings',
                style: AppTextStyles.bodySmall(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _goToResults() {
    final state = ref.read(mealLogViewModelProvider);
    if (state.photo1 == null ||
        state.photo2 == null ||
        state.photo3 == null) {
      return;
    }
    // Navigate to confirmation screen first
    // User verifies dish names before nutrition is calculated
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          photo1: state.photo1!,
          photo2: state.photo2!,
          photo3: state.photo3!,
          oilLevel: state.oilLevel,
          cookingLocation: state.cookingLocation,
          photos: [state.photo1!, state.photo2!, state.photo3!],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealLogViewModelProvider);

    if (state.photosComplete) {
      return _QuestionsView(onAnalyse: _goToResults);
    }

    return _LiveCameraScreen(
      photoStep: state.currentPhotoStep,
      photo1: state.photo1,
      photo2: state.photo2,
      onPhotoCaptured: (file, step) {
        final vm = ref.read(mealLogViewModelProvider.notifier);
        if (step == 1) {
          vm.setPhoto1(file);
        } else if (step == 2) {
          vm.setPhoto2(file);
        } else {
          vm.setPhoto3(file);
        }
      },
      onClose: () => Navigator.pop(context),
      onManualLog: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManualLogScreen()),
      ),
    );
  }
}

// ─────────────────────────────────────────
// LIVE CAMERA SCREEN
// How it works:
// 1. Live camera preview opens immediately
// 2. Mould overlay drawn on top of feed — white/dim
// 3. User moves phone to align food inside mould
// 4. When user is satisfied with alignment → they tap
//    "ALIGNED" button at the bottom
// 5. Mould turns green + haptic feedback
// 6. Capture button becomes active — user taps to photograph
// 7. This is honest — user is in full control
// ─────────────────────────────────────────
class _LiveCameraScreen extends StatefulWidget {
  final int photoStep;
  final File? photo1;
  final File? photo2;
  final Function(File, int) onPhotoCaptured;
  final VoidCallback onClose;
  final VoidCallback onManualLog;

  const _LiveCameraScreen({
    required this.photoStep,
    required this.photo1,
    required this.photo2,
    required this.onPhotoCaptured,
    required this.onClose,
    required this.onManualLog,
  });

  @override
  State<_LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<_LiveCameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _cameraError = false;
  String _errorMessage = '';

  // ── ALIGNMENT STATE ──
  // false = user has NOT confirmed alignment yet (mould is white)
  // true  = user tapped "Aligned" (mould turns green)
  bool _userConfirmedAlignment = false;

  late AnimationController _alignCtrl;
  late Animation<double> _alignAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _alignCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _alignAnim = CurvedAnimation(
      parent: _alignCtrl,
      curve: Curves.easeOut,
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await ph.Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _errorMessage =
            'Camera permission denied. Please allow camera access in Settings.';
          });
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _errorMessage = 'No camera found on this device.';
          });
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Flash on for close-up photo (reveals oil content)
      await _controller!.setFlashMode(
        widget.photoStep == 3 ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _errorMessage = 'Camera error: ${e.toString()}';
        });
      }
    }
  }

  // ── USER CONFIRMS ALIGNMENT ──
  // This is the key function.
  // User has looked at the live feed, positioned your food,
  // and they tap this button to say "yes, my food is aligned."
  // Only then does the mould turn green and capture activate.
  void _confirmAlignment() {
    setState(() => _userConfirmedAlignment = true);
    _alignCtrl.forward();
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  // ── RESET ALIGNMENT ──
  // Called after each photo so user re-confirms for the next shot
  void _resetAlignment() {
    setState(() => _userConfirmedAlignment = false);
    _alignCtrl.reverse();
  }

  // ── CAPTURE PHOTO ──
  // Only works when user has confirmed alignment
  Future<void> _capturePhoto() async {
    if (!_userConfirmedAlignment || _isCapturing || !_isInitialized) return;
    setState(() => _isCapturing = true);

    try {
      HapticFeedback.heavyImpact();
      final XFile image = await _controller!.takePicture();
      widget.onPhotoCaptured(File(image.path), widget.photoStep);

      // Reset for next photo
      if (widget.photoStep < 3) {
        _resetAlignment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Capture failed. Try again.',
              style: AppTextStyles.bodySmall(color: Colors.white),
            ),
            backgroundColor: AppColors.cardLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _alignCtrl.dispose();
    super.dispose();
  }

  String get _stepTitle {
    switch (widget.photoStep) {
      case 1: return "PHOTO 1 OF 3 · BIRD'S EYE";
      case 2: return "PHOTO 2 OF 3 · LEAN IN 45°";
      case 3: return "PHOTO 3 OF 3 · CLOSE UP";
      default: return '';
    }
  }

  String get _stepInstruction {
    switch (widget.photoStep) {
      case 1:
        return 'Hold directly above\nFit your food or drink inside the frame';
      case 2:
        return 'Tilt your phone to 45°\nShow the depth and volume';
      case 3:
        return 'Move close to your main dish\nFlash is on — reveals oil content';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── CAMERA PREVIEW or STATES ──
          if (_cameraError)
            _CameraErrorView(
              message: _errorMessage,
              onClose: widget.onClose,
              onSettings: () => ph.openAppSettings(),
            )
          else if (!_isInitialized)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2),
                    const SizedBox(height: AppSizes.paddingLG),
                    Text('Starting camera...',
                        style: AppTextStyles.bodySmall(
                            color: AppColors.accent.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            )
          else
          // Live camera feed — full screen
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

          // ── DARK GRADIENTS top and bottom ──
          if (_isInitialized) ...[
            Positioned(
              top: 0, left: 0, right: 0,
              height: size.height * 0.25,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: size.height * 0.40,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEE000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],

          // ── MOULD OVERLAY ──
          // Drawn on top of live feed
          // White when not confirmed, green when confirmed
          if (_isInitialized)
            AnimatedBuilder(
              animation: _alignAnim,
              builder: (ctx, _) {
                final mouldColor = Color.lerp(
                  AppColors.accent.withValues(alpha: 0.75),
                  const Color(0xFF4CAF50),
                  _alignAnim.value,
                )!;
                return _MouldOverlay(
                  photoStep: widget.photoStep,
                  color: mouldColor,
                  isConfirmed: _userConfirmedAlignment,
                  screenSize: size,
                );
              },
            ),

          // ── ALL UI CONTROLS ──
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                const SizedBox(height: AppSizes.paddingMD),

                // Step title + instruction
                _buildStepInfo(),

                const Spacer(),

                // ── ALIGNMENT SECTION ──
                // This is the heart of Option 2
                if (_isInitialized) _buildAlignmentSection(size),

                const SizedBox(height: AppSizes.paddingXXL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ALIGNMENT SECTION ─────────────────────────────────────────────
  // Before confirmed: Shows "ALIGNED" button prominently
  // After confirmed: Shows green status + capture button
  Widget _buildAlignmentSection(Size size) {
    if (!_userConfirmedAlignment) {
      // ── NOT YET CONFIRMED ──
      // User is still positioning. Big visible button.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              'POSITION YOUR FOOD INSIDE THE FRAME',
              style: AppTextStyles.label(
                  color: AppColors.accent.withValues(alpha: 0.65)),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // Row: thumbnails + confirm button
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXXL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PhotoThumb(
                    photo: widget.photoStep > 1 ? widget.photo1 : null),

                // ── BIG CONFIRM ALIGNMENT BUTTON ──
                GestureDetector(
                  onTap: _confirmAlignment,
                  child: Container(
                    width: 140,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: Colors.black, size: 20),
                          const SizedBox(height: 2),
                          Text(
                            'ALIGNED',
                            style: AppTextStyles.buttonPrimary().copyWith(
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                _PhotoThumb(
                    photo: widget.photoStep > 2 ? widget.photo2 : null),
              ],
            ),
          ),
        ],
      );
    } else {
      // ── CONFIRMED ──
      // Mould is green. Now show the capture button.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Green status badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Color(0xFF4CAF50)),
                const SizedBox(width: 7),
                Text(
                  'ALIGNED · NOW CAPTURE',
                  style: AppTextStyles.label(
                      color: const Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingXL),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXXL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Re-adjust button (if user wants to reposition)
                GestureDetector(
                  onTap: _resetAlignment,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.6)),
                        Text('REDO',
                            style: TextStyle(
                              fontSize: 7,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            )),
                      ],
                    ),
                  ),
                ),

                // ── CAPTURE BUTTON — green, prominent ──
                GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x664CAF50),
                          blurRadius: 32,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: _isCapturing
                        ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5),
                    )
                        : const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                ),

                // Previous photo thumbnail
                _PhotoThumb(
                    photo: widget.photoStep > 2 ? widget.photo2 : null),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL, vertical: AppSizes.paddingMD),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.8), size: 20),
            ),
          ),
          const Spacer(),

          // Progress dots
          Row(
            children: List.generate(3, (i) {
              final done = i < widget.photoStep - 1;
              final active = i == widget.photoStep - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                      : active
                      ? AppColors.accent.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: done
                    ? const Icon(Icons.check, size: 7, color: Colors.white)
                    : null,
              );
            }),
          ),

          const Spacer(),

          // Manual log shortcut
          GestureDetector(
            onTap: widget.onManualLog,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius:
                BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text('MANUAL',
                  style: AppTextStyles.label(
                      color: Colors.white.withValues(alpha: 0.65))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXXL),
      child: Column(
        children: [
          // Flash badge for photo 3
          if (widget.photoStep == 3)
            Container(
              margin: const EdgeInsets.only(bottom: AppSizes.paddingSM),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius:
                BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 12,
                      color: Colors.amber.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text('FLASH ON',
                      style: AppTextStyles.label(
                          color: Colors.amber.withValues(alpha: 0.85))),
                ],
              ),
            ),

          Text(
            _stepTitle,
            style: AppTextStyles.label(
                color: Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _stepInstruction,
            style: AppTextStyles.bodySmall(
                color: Colors.white.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// MOULD OVERLAY
// White when not confirmed
// Green when user confirms alignment
// ─────────────────────────────────────────
class _MouldOverlay extends StatelessWidget {
  final int photoStep;
  final Color color;
  final bool isConfirmed;
  final Size screenSize;

  const _MouldOverlay({
    required this.photoStep,
    required this.color,
    required this.isConfirmed,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final mouldW = screenSize.width * 0.78;
    final mouldH = photoStep == 2 ? mouldW * 0.65 : mouldW;
    final left = (screenSize.width - mouldW) / 2;
    final top = (screenSize.height - mouldH) / 2 - 50;

    return Positioned(
      left: left,
      top: top,
      width: mouldW,
      height: mouldH,
      child: CustomPaint(
        painter: _MouldPainter(
          photoStep: photoStep,
          color: color,
          isConfirmed: isConfirmed,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                photoStep == 1
                    ? 'FIT HERE'
                    : photoStep == 2
                    ? 'FIT HERE'
                    : 'FIT HERE',
                style: AppTextStyles.label(
                  color: color.withValues(alpha: 0.5),
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

class _MouldPainter extends CustomPainter {
  final int photoStep;
  final Color color;
  final bool isConfirmed;

  const _MouldPainter({
    required this.photoStep,
    required this.color,
    required this.isConfirmed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = w * 0.1; // corner bracket size

    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = isConfirmed ? 4.0 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = color.withValues(alpha: isConfirmed ? 0.12 : 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isConfirmed ? 0.07 : 0.0)
      ..style = PaintingStyle.fill;

    final crosshairPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (photoStep == 2) {
      // ── TRAPEZOID — for 45° lean-in shot ──
      final path = Path()
        ..moveTo(c, 0)
        ..lineTo(w - c, 0)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, innerPaint);

      // Corner brackets
      canvas.drawLine(Offset(0, 0), Offset(c * 1.5, 0), cornerPaint);
      canvas.drawLine(Offset(w - c * 1.5, 0), Offset(w, 0), cornerPaint);
      canvas.drawLine(Offset(0, 0), Offset(0, c), cornerPaint);
      canvas.drawLine(Offset(w, 0), Offset(w, c), cornerPaint);
      canvas.drawLine(Offset(0, h), Offset(c, h), cornerPaint);
      canvas.drawLine(Offset(w - c, h), Offset(w, h), cornerPaint);

      _drawBadge(canvas, w, '2 OF 3');
    } else {
      // ── RECTANGLE — for bird's eye and close-up ──
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fillPaint);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), innerPaint);

      // Corner brackets — the signature Fit Foodie mould
      canvas.drawLine(Offset(0, c), Offset(0, 0), cornerPaint);
      canvas.drawLine(Offset(0, 0), Offset(c, 0), cornerPaint);

      canvas.drawLine(Offset(w - c, 0), Offset(w, 0), cornerPaint);
      canvas.drawLine(Offset(w, 0), Offset(w, c), cornerPaint);

      canvas.drawLine(Offset(0, h - c), Offset(0, h), cornerPaint);
      canvas.drawLine(Offset(0, h), Offset(c, h), cornerPaint);

      canvas.drawLine(Offset(w - c, h), Offset(w, h), cornerPaint);
      canvas.drawLine(Offset(w, h - c), Offset(w, h), cornerPaint);

      // Crosshair in center
      canvas.drawLine(
        Offset(w / 2 - 18, h / 2),
        Offset(w / 2 + 18, h / 2),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(w / 2, h / 2 - 18),
        Offset(w / 2, h / 2 + 18),
        crosshairPaint,
      );

      _drawBadge(canvas, w, photoStep == 1 ? '1 OF 3' : '3 OF 3');
    }
  }

  void _drawBadge(Canvas canvas, double w, String text) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, 0),
          width: text.length * 7.5 + 20,
          height: 20,
        ),
        const Radius.circular(10),
      ),
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MouldPainter old) =>
      old.color != color || old.isConfirmed != isConfirmed;
}

// ─────────────────────────────────────────
// PHOTO THUMBNAIL
// ─────────────────────────────────────────
class _PhotoThumb extends StatelessWidget {
  final File? photo;
  const _PhotoThumb({this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: photo != null
              ? const Color(0xFF4CAF50).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.1),
          width: photo != null ? 2 : 1,
        ),
      ),
      child: photo != null
          ? Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius:
            BorderRadius.circular(AppSizes.radiusMD - 1),
            child: Image.file(photo!, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.check, size: 8, color: Colors.white),
            ),
          ),
        ],
      )
          : Icon(
        Icons.photo_outlined,
        size: 24,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CAMERA ERROR VIEW
// ─────────────────────────────────────────
class _CameraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final VoidCallback onSettings;

  const _CameraErrorView({
    required this.message,
    required this.onClose,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined,
                  size: 64,
                  color: AppColors.accent.withValues(alpha: 0.3)),
              const SizedBox(height: AppSizes.paddingXXL),
              Text('Camera Unavailable',
                  style: AppTextStyles.headingMedium(),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.paddingMD),
              Text(message,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.accent.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.paddingXXL),
              PrimaryButton(
                label: 'OPEN SETTINGS',
                onTap: onSettings,
                margin: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSizes.paddingMD),
              GestureDetector(
                onTap: onClose,
                child: Text('Go Back',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.4))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// QUESTIONS VIEW — after all 3 photos done
// ─────────────────────────────────────────
class _QuestionsView extends ConsumerWidget {
  final VoidCallback onAnalyse;
  const _QuestionsView({required this.onAnalyse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealLogViewModelProvider);
    final vm = ref.read(mealLogViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.paddingXL),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: AppDecorations.dishIcon(),
                    child: Icon(Icons.arrow_back_rounded,
                        size: 18,
                        color: AppColors.accent.withValues(alpha: 0.7)),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXL),

                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Text('ALL 3 PHOTOS CAPTURED',
                        style: AppTextStyles.label(
                            color: const Color(0xFF4CAF50))),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingMD),
                Text('Two quick questions',
                    style: AppTextStyles.headingMedium()),
                const SizedBox(height: AppSizes.paddingSM),
                Text(
                  'Helps us deliver maximum accuracy',
                  style: AppTextStyles.bodySmall(
                      color: AppColors.accent.withValues(alpha: 0.55)),
                ),

                const SizedBox(height: AppSizes.paddingXXL),

                Text('HOW OILY IS THE FOOD?',
                    style: AppTextStyles.label()),
                const SizedBox(height: AppSizes.paddingMD),
                Row(
                  children: [
                    _OptionBtn('None', '🥗', 'none',
                        state.oilLevel, () => vm.setOilLevel('none')),
                    const SizedBox(width: AppSizes.paddingSM),
                    _OptionBtn('Light', '💧', 'light',
                        state.oilLevel, () => vm.setOilLevel('light')),
                    const SizedBox(width: AppSizes.paddingSM),
                    _OptionBtn('Medium', '🫕', 'medium',
                        state.oilLevel, () => vm.setOilLevel('medium')),
                    const SizedBox(width: AppSizes.paddingSM),
                    _OptionBtn('Heavy', '🛢️', 'heavy',
                        state.oilLevel, () => vm.setOilLevel('heavy')),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingXXL),

                Text('WHERE WAS IT MADE?',
                    style: AppTextStyles.label()),
                const SizedBox(height: AppSizes.paddingMD),
                Row(
                  children: [
                    _OptionBtn('Home', '🏠', 'home',
                        state.cookingLocation,
                            () => vm.setCookingLocation('home')),
                    const SizedBox(width: AppSizes.paddingSM),
                    _OptionBtn('Restaurant', '🍴', 'restaurant',
                        state.cookingLocation,
                            () => vm.setCookingLocation('restaurant')),
                    const SizedBox(width: AppSizes.paddingSM),
                    _OptionBtn('Ordered', '📦', 'ordered',
                        state.cookingLocation,
                            () => vm.setCookingLocation('ordered')),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Photo strip
                if (state.photo1 != null &&
                    state.photo2 != null &&
                    state.photo3 != null)
                  Row(
                    children: [
                      _MiniPhoto(file: state.photo1!, label: '1'),
                      const SizedBox(width: AppSizes.paddingSM),
                      _MiniPhoto(file: state.photo2!, label: '2'),
                      const SizedBox(width: AppSizes.paddingSM),
                      _MiniPhoto(file: state.photo3!, label: '3'),
                    ],
                  ),

                const SizedBox(height: AppSizes.paddingXXL),

                PrimaryButton(
                  label: 'ANALYSE MEAL',
                  icon: const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: Colors.black),
                  onTap: onAnalyse,
                  margin: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSizes.paddingSM),
                Center(
                  child: Text(
                    'ANALYSING · ~5 SECONDS',
                    style: AppTextStyles.label(
                        color: AppColors.accent.withValues(alpha: 0.28)),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionBtn extends StatelessWidget {
  final String label, emoji, id, current;
  final VoidCallback onTap;
  const _OptionBtn(
      this.label, this.emoji, this.id, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = current == id;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingMD, horizontal: 4),
          decoration: sel
              ? AppDecorations.regionSelected()
              : AppDecorations.regionUnselected(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.dishName(
                    color: sel ? Colors.black : AppColors.textPrimary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPhoto extends StatelessWidget {
  final File file;
  final String label;
  const _MiniPhoto({required this.file, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              child: Image.file(file, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}