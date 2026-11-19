import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_mastery_screen.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_screen.dart';

void main() {
  test('JobInterviewMasteryScreen is an alias of JobInterviewScreen', () {
    const screen = JobInterviewMasteryScreen(level: 1);
    expect(screen, isA<JobInterviewScreen>());
  });
}
