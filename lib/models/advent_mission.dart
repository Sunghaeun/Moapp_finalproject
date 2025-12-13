class AdventMission {
  final int day;
  final String task;
  bool isCompleted;

  AdventMission({
    required this.day,
    required this.task,
    this.isCompleted = false,
  });

  factory AdventMission.fromJson(Map<String, dynamic> json) {
    return AdventMission(
      day: json['day'],
      task: json['task'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'task': task,
      'isCompleted': isCompleted,
    };
  }
}