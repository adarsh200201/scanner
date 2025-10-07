import 'package:hive/hive.dart';

class ScannedDoc {
  final String id;
  String name;
  String path;
  final DateTime createdAt;
  bool uploaded;
  String type;
  int fileSize;
  List<String> imagePaths;
  String? previewImagePath;
  List<String> tags;
  String? notes;

  ScannedDoc({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.uploaded = false,
    this.type = 'document',
    this.fileSize = 0,
    this.imagePaths = const [],
    this.previewImagePath,
    this.tags = const [],
    this.notes,
  });
}

class ScannedDocAdapter extends TypeAdapter<ScannedDoc> {
  @override
  final int typeId = 29;

  @override
  ScannedDoc read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ScannedDoc(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      uploaded: fields[4] as bool,
      type: fields[5] as String,
      fileSize: fields[6] as int,
      imagePaths: (fields[7] as List).cast<String>(),
      previewImagePath: fields[8] as String?,
      tags: (fields[9] as List?)?.cast<String>() ?? const [],
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedDoc obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.uploaded)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.fileSize)
      ..writeByte(7)
      ..write(obj.imagePaths)
      ..writeByte(8)
      ..write(obj.previewImagePath)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.notes);
  }
}
