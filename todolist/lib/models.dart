import 'dart:io';

class Member {
  String id;
  String name;
  String role;
  int productivity;
  File? avatar;

  Member({
    required this.id,
    required this.name,
    required this.role,
    this.productivity = 0,
    this.avatar,
  });
}

class TaskItem {
  String id;
  String title;
  String description;
  Member assignee;
  DateTime deadline;
  String status; // Todo, InProgress, Done
  int progress;
  List<File> attachments;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.deadline,
    this.status = 'Todo',
    this.progress = 0,
    this.attachments = const [],
  });
}

class Project {
  String name;
  String description;
  DateTime startDate;
  DateTime deadline;
  Member leader;
  List<Member> members;
  List<TaskItem> tasks;
  double progress;

  Project({
    required this.name,
    required this.description,
    required this.startDate,
    required this.deadline,
    required this.leader,
    this.members = const [],
    this.tasks = const [],
    this.progress = 0,
  });
}
