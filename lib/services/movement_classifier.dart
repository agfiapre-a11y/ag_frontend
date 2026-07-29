/// Auto-classification service that assigns users/members to church movements
/// based on age, gender, marital status, and employment status.
///
/// Rules:
///   - Age < 13 → Children's Ministry
///   - Age 13–35, single → Youth
///   - Age > 13, married, male → Men's Fellowship
///   - Age > 13, married, female → Women's Fellowship
///   - Employed → also tagged for Church Welfare
class MovementClassifier {
  static const String childrensMinistry = "Children's Ministry";
  static const String youth = 'Youth';
  static const String mensFellowship = "Men's Fellowship";
  static const String womensFellowship = "Women's Fellowship";
  static const String churchWelfare = 'Church Welfare';

  /// Calculates age from date of birth. Returns null if dob is null.
  static int? calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Classifies a person into a movement based on the given attributes.
  /// Returns the movement name, or empty string if classification is not possible.
  static String classify({
    DateTime? dateOfBirth,
    required String gender,
    required String maritalStatus,
    required bool isEmployed,
  }) {
    // Employed persons belong to Church Welfare
    if (isEmployed) return churchWelfare;

    final age = calculateAge(dateOfBirth);
    if (age == null) return '';

    // Under 13 → Children's Ministry
    if (age < 13) return childrensMinistry;

    // 13–35 and single → Youth
    if (age >= 13 && age <= 35 && maritalStatus == 'single') return youth;

    // Over 13 and married → gender-based fellowship
    if (age > 13 && maritalStatus == 'married') {
      return gender == 'female' ? womensFellowship : mensFellowship;
    }

    // Over 35 and single → gender-based fellowship
    if (age > 35) {
      return gender == 'female' ? womensFellowship : mensFellowship;
    }

    return '';
  }

  /// Returns a human-readable description of the classification rules.
  static String get rulesDescription =>
      'Age < 13: Children\'s Ministry · Age 13–35 single: Youth · '
      'Married male: Men\'s Fellowship · Married female: Women\'s Fellowship · '
      'Employed: Church Welfare';
}
