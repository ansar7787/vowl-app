import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('assets/curriculum/vocabulary');
  final files = dir.listSync().where((f) => f.path.contains('topicVocab_')).toList();
  
  Map<String, List<String>> questionUniqueness = {};
  int totalQuests = 0;
  int duplicates = 0;
  
  for (var file in files) {
    if (file is File) {
      final content = file.readAsStringSync();
      final json = jsonDecode(content);
      final quests = json['quests'] as List;
      
      for (var q in quests) {
        totalQuests++;
        final qContent = "${q['topicBuckets'].join(',')}|${q['options'].join(',')}";
        if (questionUniqueness.containsKey(qContent)) {
          questionUniqueness[qContent]!.add(q['id']);
          duplicates++;
        } else {
          questionUniqueness[qContent] = [q['id']];
        }
        
        // Field Check
        if (q['interactionType'] != 'sort') {
          print("ERROR: Invalid interactionType in ${q['id']}");
        }
        if (q['topicBuckets'] == null || q['topicBuckets'].isEmpty) {
          print("ERROR: Missing topicBuckets in ${q['id']}");
        }
        if (q['correctAnswer'] == null || !q['correctAnswer'].contains(':')) {
          print("ERROR: Invalid correctAnswer format in ${q['id']}");
        }
      }
    }
  }
  
  print("\n--- Audit Results ---");
  print("Total Quests: $totalQuests");
  print("Unique Quests: ${questionUniqueness.length}");
  print("Duplicate Count: $duplicates");
  
  if (duplicates > 0) {
    print("\nSample Duplicates:");
    questionUniqueness.forEach((key, ids) {
      if (ids.length > 1) {
        print("${ids.length} times: $ids");
      }
    });
  }
}
