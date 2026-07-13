class Chapter {
  final int id;
  final int bookId;
  final String title;
  final String content;
  final int index;
  final DateTime? readAt;

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    required this.index,
    this.readAt,
  });

  Chapter copyWith({
    int? id,
    int? bookId,
    String? title,
    String? content,
    int? index,
    DateTime? readAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      content: content ?? this.content,
      index: index ?? this.index,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book_id': bookId,
        'title': title,
        'content': content,
        'index': index,
        'read_at': readAt?.toIso8601String(),
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as int,
        bookId: json['book_id'] as int,
        title: json['title'] as String,
        content: json['content'] as String,
        index: json['index'] as int,
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
      );
}
