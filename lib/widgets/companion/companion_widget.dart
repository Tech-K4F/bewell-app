import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';

/// Stato emotivo di Welly — mappato su video specifici.
/// Regola fondamentale: nessuno stato visivamente negativo.
/// Welly non soffre, non è triste, non rimproverara mai.
enum WellyMood {
  calm,       // mattino, nessuna azione ancora — idle rotation (sit / breathe)
  present,    // acqua iniziata (1-3 bicchieri) — look
  engaged,    // acqua a metà (4-6 bicchieri) — sit2
  radiant,    // giornata completata — happy
  welcoming,  // primo accesso del giorno — hug
  wondering,  // sera senza azioni (dopo le 20) — look con loop lento
  returning,  // rientro dopo 2+ giorni — encourage
  resting,    // notte (dopo le 22) — sleep
  drinking,   // animazione specifica al bicchiere — drink
  breathing,  // durante sessione respirazione — meditate
}

class CompanionWidget extends StatefulWidget {
  final double size;
  final WellyMood mood;
  final bool showPhase; // mostra fase di crescita invece del video

  const CompanionWidget({
    super.key,
    this.size = 120,
    this.mood = WellyMood.calm,
    this.showPhase = false,
  });

  @override
  State<CompanionWidget> createState() => _CompanionWidgetState();
}

class _CompanionWidgetState extends State<CompanionWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  int _idleIndex = 0;
  Timer? _idleTimer;

  // Video per ogni mood (eccetto calm che usa idle rotation)
  static const _moodVideos = {
    WellyMood.present:   'assets/images/companion/companion_look.mp4',
    WellyMood.engaged:   'assets/images/companion/companion_sit2.mp4',
    WellyMood.radiant:   'assets/images/companion/companion_happy.mp4',
    WellyMood.welcoming: 'assets/images/companion/companion_hug.mp4',
    WellyMood.wondering: 'assets/images/companion/companion_look.mp4',
    WellyMood.returning: 'assets/images/companion/companion_encourage.mp4',
    WellyMood.resting:   'assets/images/companion/companion_sleep.mp4',
    WellyMood.drinking:  'assets/images/companion/companion_drink.mp4',
    WellyMood.breathing: 'assets/images/companion/companion_meditate.mp4',
  };

  // Idle videos in rotation per WellyMood.calm
  static const _idleVideos = [
    'assets/images/companion/companion_breathe.mp4',
    'assets/images/companion/companion_breathe.mp4',
    'assets/images/companion/companion_look.mp4',
    'assets/images/companion/companion_breathe.mp4',
    'assets/images/companion/companion_cozy.mp4',
    'assets/images/companion/companion_breathe.mp4',
    'assets/images/companion/companion_sit.mp4',
    'assets/images/companion/companion_breathe.mp4',
    'assets/images/companion/companion_sit2.mp4',
  ];

  // Moods che usano loop continuo
  static bool _isLooping(WellyMood mood) {
    switch (mood) {
      case WellyMood.calm:
      case WellyMood.present:
      case WellyMood.engaged:
      case WellyMood.wondering:
      case WellyMood.resting:
      case WellyMood.breathing:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.showPhase) {
      _loadVideo();
      if (widget.mood == WellyMood.calm) {
        _startIdleRotation();
      }
    }
  }

  @override
  void didUpdateWidget(CompanionWidget old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.showPhase != widget.showPhase) {
      _idleTimer?.cancel();
      _disposeController();
      if (!widget.showPhase) {
        _loadVideo();
        if (widget.mood == WellyMood.calm) {
          _startIdleRotation();
        }
      }
    }
  }

  String get _currentVideoPath {
    if (widget.mood == WellyMood.calm) {
      return _idleVideos[_idleIndex % _idleVideos.length];
    }
    return _moodVideos[widget.mood] ??
        'assets/images/companion/companion_breathe.mp4';
  }

  Future<void> _loadVideo() async {
    _disposeController();
    final controller = VideoPlayerController.asset(_currentVideoPath);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.setLooping(_isLooping(widget.mood));
      controller.setVolume(0);
      controller.play();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('CompanionWidget video error: $e');
    }
  }

  void _startIdleRotation() {
    // Cambia video idle ogni 25-45 secondi casualmente
    final rng = Random();
    final delay = Duration(seconds: 25 + rng.nextInt(20));
    _idleTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _idleIndex++;
        _isInitialized = false;
      });
      _loadVideo();
      _startIdleRotation();
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  // Fase di crescita dalla base di progressione
  String _phaseImage(int phase) {
    const phases = [
      'assets/images/companion/companion_phase1_seed.png',
      'assets/images/companion/companion_phase2_sprout.png',
      'assets/images/companion/companion_phase3_young.png',
      'assets/images/companion/companion_phase4_mature.png',
      'assets/images/companion/companion_phase5_radiant.png',
    ];
    return phases[(phase - 1).clamp(0, 4)];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.showPhase
          ? _buildPhaseImage(context)
          : _buildVideo(),
    );
  }

  Widget _buildPhaseImage(BuildContext context) {
    final progression = context.watch<ProgressionProvider>();
    final phase = progression.currentPhase;
    return Image.asset(
      _phaseImage(phase),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _buildVideo() {
    if (!_isInitialized || _controller == null) {
      return _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: AspectRatio(
        aspectRatio: 1,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/images/companion/companion_base.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
  }
}
