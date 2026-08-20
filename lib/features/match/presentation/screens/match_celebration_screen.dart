import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/widgets/app_cached_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MatchCelebrationScreen extends StatefulWidget {
  final DetailedProfileModel currentUser;
  final DetailedProfileModel matchedUser;
  final String? conversationId; // Optionnel pour la phase 2

  const MatchCelebrationScreen({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    this.conversationId,
  });

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background avec flou et opacité
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: isDark 
                  ? Colors.black.withOpacity(0.8) 
                  : Colors.black.withOpacity(0.6),
            ),
          ),
          
          // Confettis (CustomPainter)
          CustomPaint(
            painter: _ConfettiPainter(_controller),
            size: Size.infinite,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Titre
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const Column(
                        children: [
                          Text(
                            "C'est un match !",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryLight,
                              letterSpacing: -1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Vous vous plaisez mutuellement",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Photos
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle Moi (gauche)
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 120,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
                            )),
                            child: _buildProfileCircle(widget.currentUser),
                          ),
                        ),
                        
                        // Cercle Match (droite)
                        Positioned(
                          right: MediaQuery.of(context).size.width / 2 - 120,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
                            )),
                            child: _buildProfileCircle(widget.matchedUser),
                          ),
                        ),

                        // Coeur central
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLight.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.heart,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Boutons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (widget.conversationId != null) {
                                // TODO: Phase 2 - Go to chat screen
                                // context.push('/chat/${widget.conversationId}');
                              } else {
                                // Fallback (ou avant phase 2) on va sur l'onglet message/match
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Envoyer un message",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Continuer à découvrir",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCircle(DetailedProfileModel profile) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipOval(
        child: profile.primaryPhotoUrl != null
            ? AppCachedImage(
                imageUrl: profile.primaryPhotoUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey.shade300,
                child: const Icon(LucideIcons.user, size: 60, color: Colors.grey),
              ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Particle> particles;

  _ConfettiPainter(this.animation)
      : particles = List.generate(40, (index) => _Particle()),
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    for (var particle in particles) {
      final progress = animation.value;
      
      // Position calculation based on progress
      final currentX = center.dx + particle.dx * progress * size.width;
      final currentY = center.dy + particle.dy * progress * size.height + (progress * progress * 200); // Gravity effect

      paint.color = particle.color.withOpacity(1.0 - progress);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(particle.rotation * progress * 10);
      
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size * 2,
            height: particle.size * 2,
          ),
          paint,
        );
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Particle {
  late double dx;
  late double dy;
  late Color color;
  late double size;
  late bool isCircle;
  late double rotation;

  _Particle() {
    final random = Random();
    // Angle in radians
    final angle = random.nextDouble() * 2 * pi;
    // Velocity/Distance
    final speed = 0.2 + random.nextDouble() * 0.8;
    
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
    
    final colors = [
      AppColors.primaryLight,
      const Color(0xFFFE3C72),
      Colors.white,
      Colors.blue,
      Colors.green,
    ];
    color = colors[random.nextInt(colors.length)];
    
    size = 4.0 + random.nextDouble() * 6.0;
    isCircle = random.nextBool();
    rotation = random.nextDouble() * 2 * pi;
  }
}
