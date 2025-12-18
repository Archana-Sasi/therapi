/// Model representing a medication selected by a user
class UserMedication {
  const UserMedication({
    required this.drugId,
    required this.brandName,
  });

  final String drugId;
  final String brandName;

  Map<String, dynamic> toMap() {
    return {
      'drugId': drugId,
      'brandName': brandName,
    };
  }

  factory UserMedication.fromMap(Map<String, dynamic> map) {
    return UserMedication(
      drugId: map['drugId'] ?? '',
      brandName: map['brandName'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMedication && 
        other.drugId == drugId && 
        other.brandName == brandName;
  }

  @override
  int get hashCode => drugId.hashCode ^ brandName.hashCode;
}
