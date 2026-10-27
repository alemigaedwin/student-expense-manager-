class NoteModel {
  final String id;
  final String accountId;
  String text;
  DateTime dateTime;
  bool completed;

  NoteModel({
    required this.id,
    required this.accountId,
    required this.text,
    required this.dateTime,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'text': text,
        'dateTime': dateTime.toIso8601String(),
        'completed': completed,
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? 'default',
        text: json['text']?.toString() ?? '',
        dateTime: DateTime.tryParse(json['dateTime']?.toString() ?? '') ??
            DateTime.now(),
        completed: json['completed'] == true || json['completed'] == 1,
      );
}
