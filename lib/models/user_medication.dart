/// Model representing a medication selected by a user
class UserMedication {
  const UserMedication({
    required this.drugId,
    required this.brandName,
    this.prescriptionUrl,
    this.verificationStatus = 'unverified',
  });

  final String drugId;
  final String brandName;
  final String? prescriptionUrl;
  
  /// Status of prescription verification: 'pending', 'verified', 'rejected', 'unverified'
  final String verificationStatus;

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'drugId': drugId,
      'brandName': brandName,
      if (prescriptionUrl != null) 'prescriptionUrl': prescriptionUrl,
      'verificationStatus': verificationStatus,
    };
  }

  factory UserMedication.fromMap(Map<String, dynamic> map) {
    return UserMedication(
      drugId: map['drugId'] ?? '',
      brandName: map['brandName'] ?? '',
      prescriptionUrl: map['prescriptionUrl'],
      verificationStatus: map['verificationStatus'] ?? 'unverified',
    );
  }

  UserMedication copyWith({
    String? drugId,
    String? brandName,
    String? prescriptionUrl,
    String? verificationStatus,
  }) {
    return UserMedication(
      drugId: drugId ?? this.drugId,
      brandName: brandName ?? this.brandName,
      prescriptionUrl: prescriptionUrl ?? this.prescriptionUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMedication && 
        other.drugId == drugId && 
        other.brandName == brandName &&
        other.prescriptionUrl == prescriptionUrl &&
        other.verificationStatus == verificationStatus;
  }

  @override
  int get hashCode => Object.hash(drugId, brandName, prescriptionUrl, verificationStatus);
}
