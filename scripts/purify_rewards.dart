import 'dart:io';
import 'dart:convert';

void main() async {
  final curriculumDir = Directory('assets/curriculum');
  if (!await curriculumDir.exists()) {
    print('Curriculum directory not found!');
    return;
  }

  int filesProcessed = 0;
  int fieldsRemoved = 0;

  await for (var entity in curriculumDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        final content = await entity.readAsString();
        final data = json.decode(content);

        bool modified = false;

        void processNode(dynamic node) {
          if (node is List) {
            for (var item in node) {
              processNode(item);
            }
          } else if (node is Map) {
            if (node.containsKey('xpReward')) {
              node.remove('xpReward');
              modified = true;
              fieldsRemoved++;
            }
            if (node.containsKey('coinReward')) {
              node.remove('coinReward');
              modified = true;
              fieldsRemoved++;
            }
            // Recurse into nested maps
            for (var value in node.values) {
              processNode(value);
            }
          }
        }

        processNode(data);

        if (modified) {
          final encoder = const JsonEncoder.withIndent('  ');
          await entity.writeAsString(encoder.convert(data));
          filesProcessed++;
          if (filesProcessed % 100 == 0) {
            print('Processed $filesProcessed files...');
          }
        }
      } catch (e) {
        print('Error processing ${entity.path}: $e');
      }
    }
  }

  print('\n✅ REWARD PURIFICATION COMPLETE!');
  print('Total Files Modified: $filesProcessed');
  print('Total Fields Removed: $fieldsRemoved');
}
