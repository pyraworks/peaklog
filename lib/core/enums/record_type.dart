enum RecordType { weight, forTime, amrap, etc }

extension RecordTypeX on RecordType {
  bool get isTimeBased => this == RecordType.forTime;

  String get inputLabel {
    switch (this) {
      case RecordType.weight:  return 'Weight';
      case RecordType.forTime: return 'Time';
      case RecordType.amrap:   return 'Rounds';
      case RecordType.etc:     return 'Value';
    }
  }
}
