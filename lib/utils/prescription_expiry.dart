/// Prescription expiry escalation levels.
///
/// The system uses 3 levels of control instead of immediate blocking:
/// - [none]  : Prescription is still valid – no restrictions.
/// - [green] : Expired 0–30 days  – warning banner, pharmacist notified.
/// - [yellow]: Expired 30–60 days – strong popup every interaction, pharmacist reminder.
/// - [red]   : Expired 60+ days   – cannot mark as taken, must request consultation.
enum PrescriptionExpiryLevel {
  none,
  green,
  yellow,
  red,
}

/// Utility helpers for prescription-expiry escalation logic.
class PrescriptionExpiryHelper {
  PrescriptionExpiryHelper._(); // prevent instantiation

  /// Determines the escalation level based on the prescription expiry date.
  static PrescriptionExpiryLevel getExpiryLevel(DateTime? expiryDate) {
    if (expiryDate == null) return PrescriptionExpiryLevel.none;

    final now = DateTime.now();
    if (now.isBefore(expiryDate) || now.isAtSameMomentAs(expiryDate)) {
      return PrescriptionExpiryLevel.none;
    }

    final daysSinceExpiry = now.difference(expiryDate).inDays;

    if (daysSinceExpiry <= 30) {
      return PrescriptionExpiryLevel.green;
    } else if (daysSinceExpiry <= 60) {
      return PrescriptionExpiryLevel.yellow;
    } else {
      return PrescriptionExpiryLevel.red;
    }
  }

  /// Returns the number of days since the prescription expired.
  /// Returns 0 if the prescription is still valid.
  static int getDaysSinceExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 0;
    final now = DateTime.now();
    if (now.isBefore(expiryDate)) return 0;
    return now.difference(expiryDate).inDays;
  }

  /// Whether the patient is allowed to mark a medication as "taken".
  static bool canMarkAsTaken(PrescriptionExpiryLevel level) {
    return level != PrescriptionExpiryLevel.red;
  }

  /// Short warning message appropriate for the escalation level.
  static String getWarningMessage(PrescriptionExpiryLevel level, int daysSinceExpiry) {
    switch (level) {
      case PrescriptionExpiryLevel.none:
        return '';
      case PrescriptionExpiryLevel.green:
        return 'Prescription expired $daysSinceExpiry day${daysSinceExpiry == 1 ? '' : 's'} ago. Please renew.';
      case PrescriptionExpiryLevel.yellow:
        return 'Prescription expired $daysSinceExpiry days ago. Please consult your doctor to renew.';
      case PrescriptionExpiryLevel.red:
        return 'Prescription has been expired for over 60 days. For your safety, you cannot take this medicine without a valid prescription.';
    }
  }

  /// Icon appropriate for the escalation level.
  static String getWarningEmoji(PrescriptionExpiryLevel level) {
    switch (level) {
      case PrescriptionExpiryLevel.none:
        return '';
      case PrescriptionExpiryLevel.green:
        return '⚠️';
      case PrescriptionExpiryLevel.yellow:
        return '🟡';
      case PrescriptionExpiryLevel.red:
        return '🔴';
    }
  }
}
