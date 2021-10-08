import 'dart:io';

import 'package:doctor_consultant/resources/resources.dart';
import 'package:test/test.dart';

void main() {
  test('images assets test', () {
    expect(true, File(Images.barbellPullToTheBelt).existsSync());
    expect(true, File(Images.card1).existsSync());
    expect(true, File(Images.gymnasticsWithDumbbells).existsSync());
    expect(true, File(Images.human).existsSync());
    expect(true, File(Images.pushupsUnderHead).existsSync());
    expect(true, File(Images.ropeExercises).existsSync());
    expect(true, File(Images.t201).existsSync());
    expect(true, File(Images.vecteezyOldPeople).existsSync());
    expect(true, File(Images.vector).existsSync());
  });
}
