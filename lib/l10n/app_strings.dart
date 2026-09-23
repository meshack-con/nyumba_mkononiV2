import 'locale_controller.dart';

/// Maandishi ya app kwa Kiswahili na English.
/// Matumizi: AppStrings.t('key')
class AppStrings {
  static String t(String key) {
    final table = LocaleController.instance.isEnglish ? _en : _sw;
    return table[key] ?? _sw[key] ?? key;
  }

  /// Majina ya miezi (Jan-Des) kulingana na lugha iliyochaguliwa.
  static List<String> get months =>
      LocaleController.instance.isEnglish ? _monthsEn : _monthsSw;

  static const List<String> _monthsSw = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  static const List<String> _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const Map<String, String> _sw = {
    'guest': 'Mgeni',
    'member': 'Mwanachama wa Nyumba Mkononi',
    'accountReady': 'Akaunti yako iko tayari',
    'signInPrompt': 'Ingia ili kuhifadhi nyumba na kuwasiliana',
    'appearance': 'MUONEKANO',
    'theme': 'Theme',
    'white': 'Nyeupe',
    'dark': 'Giza',
    'primaryColor': 'RANGI KUU',
    'account': 'AKAUNTI',
    'personalInfo': 'Taarifa binafsi',
    'notifications': 'Arifa',
    'language': 'Lugha',
    'chooseLanguage': 'Chagua lugha',
    'signOut': 'Toka',
    'signIn': 'Ingia',
    'feedbackSection': 'FEEDBACK',
    'feedback': 'Feedback',
    'feedbackSubtitle': 'Tuambie unachofikiria kuhusu jukwaa hili',
    'feedbackTitle': 'Toa maoni yako',
    'feedbackHint': 'Andika maoni yako kuhusu Nyumba Mkononi...',
    'feedbackSend': 'Tuma',
    'feedbackThanks': 'Asante kwa maoni yako!',
    'feedbackEmpty': 'Tafadhali andika maoni kwanza.',
    'feedbackFailed': 'Imeshindwa kutuma maoni. Jaribu tena.',

    // Favorites screen
    'favoritesTitle': 'Zilizopendwa',
    'favoritesSubtitle': 'Nyumba ulizoweka pembeni.',
    'favoritesEmpty': 'Bado hujapenda nyumba yoyote.',

    // Notification detail screen
    'notifDetailAppBarTitle': 'Ujumbe kutoka Nyumba Mkononi',
    'notifDetailAtTime': 'saa',

    // Role selection screen
    'roleSelectionAppBarTitle': 'Karibu Nyumba Mkononi',
    'roleSelectionHeading': 'Unaanza upande gani?',
    'roleSelectionSubtitle': 'Chagua jukumu lako. Unaweza kuvinjari bila akaunti.',
    'buyerRoleTitle': 'Mpangaji au Mnunuzi',
    'buyerRoleDescription': 'Tafuta nyumba, linganisha chaguo na upate eneo lako linalofuata.',
    'sellerRoleTitle': 'Muuzaji au Mpangishaji',
    'sellerRoleDescription': 'Weka mali yako mbele ya watu wanaotafuta nyumba Tanzania.',
  };

  static const Map<String, String> _en = {
    'guest': 'Guest',
    'member': 'Nyumba Mkononi member',
    'accountReady': 'Your account is ready',
    'signInPrompt': 'Sign in to save properties and get in touch',
    'appearance': 'APPEARANCE',
    'theme': 'Theme',
    'white': 'White',
    'dark': 'Dark',
    'primaryColor': 'PRIMARY COLOR',
    'account': 'ACCOUNT',
    'personalInfo': 'Personal information',
    'notifications': 'Notifications',
    'language': 'Language',
    'chooseLanguage': 'Choose language',
    'signOut': 'Sign out',
    'signIn': 'Sign in',
    'feedbackSection': 'FEEDBACK',
    'feedback': 'Feedback',
    'feedbackSubtitle': 'Tell us what you think about this platform',
    'feedbackTitle': 'Share your feedback',
    'feedbackHint': 'Write your thoughts about Nyumba Mkononi...',
    'feedbackSend': 'Send',
    'feedbackThanks': 'Thank you for your feedback!',
    'feedbackEmpty': 'Please write your feedback first.',
    'feedbackFailed': 'Could not send feedback. Please try again.',

    // Favorites screen
    'favoritesTitle': 'Favorites',
    'favoritesSubtitle': 'Properties you have saved.',
    'favoritesEmpty': 'You have not favorited any property yet.',

    // Notification detail screen
    'notifDetailAppBarTitle': 'Message from Nyumba Mkononi',
    'notifDetailAtTime': 'at',

    // Role selection screen
    'roleSelectionAppBarTitle': 'Welcome to Nyumba Mkononi',
    'roleSelectionHeading': 'Which side are you starting from?',
    'roleSelectionSubtitle': 'Choose your role. You can browse without an account.',
    'buyerRoleTitle': 'Tenant or Buyer',
    'buyerRoleDescription': 'Search homes, compare options and find your next place.',
    'sellerRoleTitle': 'Seller or Landlord',
    'sellerRoleDescription': 'Put your property in front of people looking for homes in Tanzania.',
  };
}
