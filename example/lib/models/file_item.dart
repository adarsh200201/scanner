class FileItem {
  String name; // Mutable to allow renaming
  final String type; // 'folder' or 'file'
  final int fileCount;
  final String date;
  final String? thumbnail;
  
  FileItem({
    required this.name,
    required this.type,
    required this.fileCount,
    required this.date,
    this.thumbnail,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'fileCount': fileCount,
      'date': date,
      'thumbnail': thumbnail,
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'],
      type: json['type'],
      fileCount: json['fileCount'],
      date: json['date'],
      thumbnail: json['thumbnail'],
    );
  }
}
