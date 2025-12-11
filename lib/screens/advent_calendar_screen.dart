import 'dart:math';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:confetti/confetti.dart';
import '../models/advent_mission.dart';
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
    // 12월이 아니면 작년 12월 캘린더를 보여주거나, 올해 12월을 준비
    return now.month == 12 ? now.year : DateTime.now().year;
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
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

    // 오늘 이전 날짜이거나 오늘 날짜인 경우에만 미션 확인 가능
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🎄 ${mission.day}일차 미션', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(mission.task, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (mission.isCompleted)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('미션 완료!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF463F)),
              child: const Text('미션 완료!', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎄 어드벤트 캘린더'),
        centerTitle: true,
        actions: [
          // 테스트용 리셋 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _adventService.resetAllMissions();
              _loadMissions();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                locale: 'ko_KR',
                focusedDay: _decemberFirst,
                firstDay: _decemberFirst,
                lastDay: _decemberLast,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.month != 12 || day.day > 24) return null;

                    final mission = _missions.firstWhere((m) => m.day == day.day);
                    final isLocked = day.isAfter(_today);

                    return _buildCalendarCell(day.day, mission.isCompleted, isLocked);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    if (day.month != 12 || day.day > 24) return null;
                    final mission = _missions.firstWhere((m) => m.day == day.day);
                    return _buildCalendarCell(day.day, mission.isCompleted, false, isToday: true);
                  },
                  outsideBuilder: (context, day, focusedDay) => const SizedBox(),
                ),
                onDaySelected: _onDaySelected,
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green, Colors.red, Colors.yellow, Colors.blue, Colors.white
              ],
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(int day, bool isCompleted, bool isLocked, {bool isToday = false}) {
    final List<String> icons = ['🎁', '❄️', '🔔', '⭐', '🧦', '🕯️'];
    final randomIcon = icons[day % icons.length];

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.shade300
            : isCompleted
                ? Colors.green.shade100
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: const Color(0xFFEF463F), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isCompleted) Text(randomIcon, style: const TextStyle(fontSize: 20)),
          Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey.shade600 : Colors.black87,
              fontSize: 16,
            ),
          ),
          if (isCompleted)
            const Text('✅', style: TextStyle(fontSize: 24)),
          if (isLocked)
            const Icon(Icons.lock, color: Colors.black54, size: 20),
        ],
      ),
    );
  }
}