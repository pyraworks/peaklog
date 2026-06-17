enum BestType { pb, pr }

extension BestTypeX on BestType {
  String get label => this == BestType.pb ? 'PB' : 'PR';
}
