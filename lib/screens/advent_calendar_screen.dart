import 'dart:math';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:confetti/confetti.dart';

import '../models/advent_mission.dart';
import '../widgets/snowfall_widget.dart';
import '../services/advent_service.dart';

class AdventCalendarScreen extends StatefulWidget {
  const AdventCalendarScreen({super.key});

  @override
  State<AdventCalendarScreen> createState() => _AdventCalendarScreenState();
}

class _AdventCalendarScreenState extends State<AdventCalendarScreen> {
  final AdventService _adventService = AdventService();
  late List<AdventMission> _missions;
  bool _isLoading = true;

  late ConfettiController _confettiController;

  final DateTime _today = DateTime.now();
  final DateTime _decemberFirst = DateTime(_getValidYear(), 12, 1);
  final DateTime _decemberLast = DateTime(_getValidYear(), 12, 31);

  static int _getValidYear() {
    final now = DateTime.now();
    return now.year;
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadMissions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    final missions = await _adventService.getMissions();
    setState(() {
      _missions = missions;
      _isLoading = false;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay.month != 12 || selectedDay.day > 24) return;

    if (selectedDay.isAfter(_today.add(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('아직 열 수 없어요. 그날이 오면 다시 만나요! 🎁'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mission = _missions.firstWhere((m) => m.day == selectedDay.day);
    _showMissionDialog(mission);
  }

  void _showMissionDialog(AdventMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎄 ${mission.day}일차 미션',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mission.task,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (mission.isCompleted)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    '미션 완료!',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기')),
          if (!mission.isCompleted)
            ElevatedButton(
              onPressed: () async {
                await _adventService.completeMission(mission.day);
                setState(() {
                  mission.isCompleted = true;
                });
                Navigator.pop(context);
                _confettiController.play();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF463F)),
              child: const Text(
                '미션 완료!',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '🎄 어드벤트 캘린더',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB71C1C), Color(0xFF6D001A)],
              ),
            ),
          ),

          const SnowfallWidget(numberOfSnowflakes: 50),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.only(top: 100, left: 8, right: 8),
              child: TableCalendar(
                locale: 'ko_KR',
                focusedDay: _decemberFirst,
                firstDay: _decemberFirst,
                lastDay: _decemberLast,
                headerStyle: const HeaderStyle(
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white70),
                  weekendStyle: TextStyle(color: Colors.white),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.month != 12 || day.day > 24) return null;
                    final mission =
                        _missions.firstWhere((m) => m.day == day.day);
                    final isLocked = day.isAfter(_today);
                    return _buildCalendarCell(
                        day.day, mission.isCompleted, isLocked);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final mission =
                        _missions.firstWhere((m) => m.day == day.day);
                    return _buildCalendarCell(
                        day.day, mission.isCompleted, false,
                        isToday: true);
                  },
                  outsideBuilder: (_, __, ___) =>
                      const SizedBox.shrink(),
                  disabledBuilder: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
                onDaySelected: _onDaySelected,
              ),
            ),

          // ⭐ Star Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.white,
                Colors.green,
                Color(0xFFFBCB0A),
                Colors.lightBlue,
              ],
              numberOfParticles: 30,
              emissionFrequency: 0.05,
              maxBlastForce: 25,
              minBlastForce: 5,
              gravity: 0.1,
              particleDrag: 0.05,
              createParticlePath: (size) => _drawStar(size),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ Star Path
  Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const points = 5;
    final half = size.width / 2;
    final outer = half;
    final inner = half / 2.5;
    final step = degToRad(360 / points);
    final halfStep = step / 2;

    final path = Path();
    path.moveTo(size.width, half);

    for (double angle = 0; angle < degToRad(360); angle += step) {
      path.lineTo(
        half + outer * cos(angle),
        half + outer * sin(angle),
      );
      path.lineTo(
        half + inner * cos(angle + halfStep),
        half + inner * sin(angle + halfStep),
      );
    }

    path.close();
    return path;
  }

  Widget _buildCalendarCell(int day, bool isCompleted, bool isLocked,
      {bool isToday = false}) {
    final icons = ['🎁', '🎄', '🔔', '⭐', '🧦', '🕯️', '🦌', '🎅'];
    final icon = icons[day % icons.length];

    Color bg;
    Widget content;

    if (isLocked) {
      bg = Colors.black.withOpacity(0.3);
      content = const Icon(Icons.lock, color: Colors.white54);
    } else if (isCompleted) {
      bg = const Color(0xFFFBCB0A);
      content = const Icon(Icons.star, color: Colors.white, size: 32);
    } else {
      bg = const Color(0xFFEF463F);
      content = Text(icon, style: const TextStyle(fontSize: 28));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border:
            isToday ? Border.all(color: Colors.yellow, width: 2.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(child: content),
    );
  }
}
