/// Tamil translations for the entire RespiriCare app
/// Usage: TamilTranslations.getLabel('English Text') returns Tamil if available
class TamilTranslations {
  TamilTranslations._();

  // ============ UI Labels ============
  static const Map<String, String> labels = {
    // ===== Drug Info Labels =====
    'Generic Name': 'பொதுப் பெயர்',
    'Brand Name': 'வர்த்தக பெயர்',
    'Brand Names': 'வர்த்தக பெயர்கள்',
    'Category': 'வகை',
    'Manufacturer': 'உற்பத்தியாளர்',
    'Price': 'விலை',
    'Description': 'விளக்கம்',
    'Side Effects': 'பக்க விளைவுகள்',
    'Precautions': 'முன்னெச்சரிக்கைகள்',
    'Dosage': 'மருந்தளவு',
    'Dose Form': 'மருந்து வடிவம்',
    'Drug Directory': 'மருந்து அடைவு',
    'Drug Inventory': 'மருந்து சரக்கு',
    'Search': 'தேடு',
    'All Drugs': 'அனைத்து மருந்துகள்',
    'Custom Added': 'தனிப்பயன் சேர்க்கப்பட்டது',
    'medications': 'மருந்துகள்',
    'No medications found': 'மருந்துகள் எதுவும் கிடைக்கவில்லை',
    'Try a different search term': 'வேறு தேடல் சொல்லை முயற்சிக்கவும்',
    'Close': 'மூடு',
    
    // ===== Drawer Menu Labels =====
    'Profile': 'சுயவிவரம்',
    'Notifications': 'அறிவிப்புகள்',
    'Settings': 'அமைப்புகள்',
    'About': 'பற்றி',
    'Logout': 'வெளியேறு',
    
    // ===== Home Screen Labels =====
    'RespiriCare': 'ரெஸ்பிரிகேர்',
    'Welcome back,': 'மீண்டும் வரவேற்கிறோம்,',
    "Today's Summary": 'இன்றைய சுருக்கம்',
    'Taken': 'எடுத்தது',
    'Pending': 'நிலுவை',
    'Missed': 'தவறவிட்டது',
    'Overdue Medications': 'காலாவதியான மருந்துகள்',
    'Upcoming Medications': 'வரவிருக்கும் மருந்துகள்',
    'Quick Actions': 'விரைவு செயல்கள்',
    'My Medications': 'என் மருந்துகள்',
    'Set Reminders': 'நினைவூட்டல்கள் அமை',
    'Log Symptoms': 'அறிகுறிகளை பதிவு செய்',
    'Track health': 'ஆரோக்கியத்தை கண்காணி',
    'Chat': 'அரட்டை',
    'Ask Pharmacist': 'மருந்தாளரிடம் கேள்',
    'Consultations': 'ஆலோசனைகள்',
    'Video Calls': 'வீடியோ அழைப்புகள்',
    'A-Z Medications': 'அ-ஃ மருந்துகள்',
    'My Prescriptions': 'என் மருந்து சீட்டுகள்',
    'Language & More': 'மொழி மற்றும் மேலும்',
    
    // ===== Login/Signup Labels =====
    'Login': 'உள்நுழை',
    'Sign Up': 'பதிவு செய்',
    'Email': 'மின்னஞ்சல்',
    'Password': 'கடவுச்சொல்',
    'Phone Number': 'தொலைபேசி எண்',
    'Full Name': 'முழு பெயர்',
    'Age': 'வயது',
    'Gender': 'பாலினம்',
    'Male': 'ஆண்',
    'Female': 'பெண்',
    'Other': 'மற்றவை',
    'Continue': 'தொடர்க',
    'Cancel': 'ரத்து செய்',
    'Save': 'சேமி',
    'Submit': 'சமர்ப்பி',
    'Edit': 'திருத்து',
    'Delete': 'நீக்கு',
    'Add': 'சேர்',
    'Confirm': 'உறுதிப்படுத்து',
    
    // ===== Medication/Reminder Labels =====
    'Add Medication': 'மருந்து சேர்',
    'Medication Name': 'மருந்து பெயர்',
    'Reminder': 'நினைவூட்டல்',
    'Reminders': 'நினைவூட்டல்கள்',
    'Add Reminder': 'நினைவூட்டல் சேர்',
    'Time': 'நேரம்',
    'Frequency': 'அதிர்வெண்',
    'Daily': 'தினமும்',
    'Weekly': 'வாரந்தோறும்',
    'Active': 'செயலில்',
    'Inactive': 'செயலற்ற',
    'Take Now': 'இப்போது எடு',
    'Mark as Taken': 'எடுத்ததாக குறி',
    'Mark as Missed': 'தவறவிட்டதாக குறி',
    'Was due': 'திட்டமிடப்பட்டது',
    'Scheduled': 'திட்டமிடப்பட்டது',
    
    // ===== Symptoms Labels =====
    'Symptom History': 'அறிகுறி வரலாறு',
    'Log New Symptom': 'புதிய அறிகுறி பதிவு',
    'Symptoms': 'அறிகுறிகள்',
    'Severity': 'தீவிரம்',
    'Mild': 'லேசான',
    'Moderate': 'மிதமான',
    'Severe': 'கடுமையான',
    'Notes': 'குறிப்புகள்',
    'Date': 'தேதி',
    
    // ===== Consultations Labels =====
    'Request Consultation': 'ஆலோசனை கோரு',
    'Upcoming': 'வரவிருக்கும்',
    'Completed': 'முடிந்தது',
    'Join Call': 'அழைப்பில் சேர்',
    
    // ===== Common Actions =====
    'Refresh': 'புதுப்பி',
    'Loading...': 'ஏற்றுகிறது...',
    'Error': 'பிழை',
    'Success': 'வெற்றி',
    'No data': 'தரவு இல்லை',
    'No results': 'முடிவுகள் இல்லை',
    
    // ===== Common Terms =====
    'Tablet': 'மாத்திரை',
    'Capsule': 'காப்ஸ்யூல்',
    'Syrup': 'சிரப்',
    'Injection': 'ஊசி',
    'Inhaler': 'உள்ளிழுப்பான்',
    'Suspension': 'சஸ்பென்ஷன்',
    'Solution': 'கரைசல்',
    'Cream': 'கிரீம்',
    'Ointment': 'மருந்து',
    'Drops': 'சொட்டுகள்',
    'patient': 'நோயாளி',
    'pharmacist': 'மருந்தாளர்',
  };

  // ============ Drug Categories ============
  static const Map<String, String> categories = {
    'Human Insulin Basal': 'மனித இன்சுலின் பேசல்',
    'Human Insulin Premix': 'மனித இன்சுலின் ப்ரீமிக்ஸ்',
    'Human Insulin Rapid': 'மனித இன்சுலின் ரேபிட்',
    'Human Insulins And Analogues': 'மனித இன்சுலின்கள் மற்றும் அனலாக்கள்',
    'Insulin Analogues Basal': 'இன்சுலின் அனலாக்கள் பேசல்',
    'Insulin Analogues Rapid': 'இன்சுலின் அனலாக்கள் ரேபிட்',
    'Oral Antidiabetics': 'வாய்வழி நீரிழிவு மருந்துகள்',
    'Other Drugs Used In Diabetes': 'நீரிழிவுக்கு பயன்படும் பிற மருந்துகள்',
    'Amebicides': 'அமீபா எதிர்ப்பு மருந்துகள்',
    'Antitubercular Products': 'காசநோய் எதிர்ப்பு மருந்துகள்',
    'Fluoroquinolones': 'ஃபுளோரோகுவினோலோன்கள்',
    'Analgesic': 'வலி நிவாரணி',
    'Antibiotic': 'நுண்ணுயிர் எதிர்ப்பி',
    'Antifungal': 'பூஞ்சை எதிர்ப்பு',
    'Antiviral': 'வைரஸ் எதிர்ப்பு',
    'Respiratory': 'சுவாச மண்டலம்',
    'Cardiovascular': 'இதய சுற்றோட்டம்',
    'Gastrointestinal': 'இரைப்பை குடல்',
  };

  // ============ Common Side Effects ============
  static const Map<String, String> sideEffects = {
    'Nausea': 'குமட்டல்',
    'Vomiting': 'வாந்தி',
    'Headache': 'தலைவலி',
    'Dizziness': 'தலைச்சுற்றல்',
    'Diarrhea': 'வயிற்றுப்போக்கு',
    'Constipation': 'மலச்சிக்கல்',
    'Fatigue': 'சோர்வு',
    'Fever': 'காய்ச்சல்',
    'Rash': 'தோல் அரிப்பு',
    'Itching': 'அரிப்பு',
    'Drowsiness': 'தூக்கம்',
    'Insomnia': 'தூக்கமின்மை',
    'Loss of appetite': 'பசியின்மை',
    'Stomach pain': 'வயிற்று வலி',
    'Abdominal pain': 'அடிவயிற்று வலி',
    'Weight gain': 'எடை அதிகரிப்பு',
    'Weight loss': 'எடை இழப்பு',
    'Dry mouth': 'வாய் வறட்சி',
    'Blurred vision': 'மங்கலான பார்வை',
    'Hypoglycemia (low blood glucose level)': 'இரத்த சர்க்கரை குறைவு',
    'Injection site allergic reaction': 'ஊசி போடும் இடத்தில் ஒவ்வாமை',
    'Allergic reaction': 'ஒவ்வாமை எதிர்வினை',
  };

  /// Get translated label
  static String getLabel(String english) {
    return labels[english] ?? english;
  }

  /// Get translated category
  static String getCategory(String english) {
    return categories[english] ?? english;
  }

  /// Get translated side effect
  static String getSideEffect(String english) {
    return sideEffects[english] ?? english;
  }

  /// Translate a comma-separated side effects string
  static String translateSideEffects(String englishSideEffects) {
    final effects = englishSideEffects.split(',').map((e) => e.trim());
    return effects.map((e) => getSideEffect(e)).join(', ');
  }
}
