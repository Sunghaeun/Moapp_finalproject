// lib/widgets/snowfall_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class SnowfallWidget extends StatefulWidget {
  final int numberOfSnowflakes;

  const SnowfallWidget({Key? key, this.numberOfSnowflakes = 150})
      : super(key: key);

  @override
  State<SnowfallWidget> createState() => _SnowfallWidgetState();
}

class _SnowfallWidgetState extends State<SnowfallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Snowflake> _snowflakes;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSnowflakes();
  }

  void _initializeSnowflakes() {
    final size = MediaQuery.of(context).size;
    _snowflakes = List.generate(
      widget.numberOfSnowflakes,
      (index) => _Snowflake(
        x: _random.nextDouble() * size.width,
        y: _random.nextDouble() * size.height,
        radius: _random.nextDouble() * 2 + 1,
        speed: _random.nextDouble() * 30 + 20,
        random: _random,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var snowflake in _snowflakes) {
          snowflake.fall(MediaQuery.of(context).size);
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _SnowPainter(_snowflakes),
        );
      },
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  _SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    for (var snowflake in snowflakes) {
      canvas.drawCircle(Offset(snowflake.x, snowflake.y), snowflake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Snowflake {
  double x, y, radius, speed;
  final Random random;

  _Snowflake({required this.x, required this.y, required this.radius, required this.speed, required this.random});

  void fall(Size size) {
    y += speed * 0.01; // 속도 조절
    if (y > size.height) {
      y = 0;
      x = random.nextDouble() * size.width;
    }
  }
}