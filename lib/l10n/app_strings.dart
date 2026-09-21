import 'locale_controller.dart';

/// Maandishi ya app kwa Kiswahili na English.
/// Matumizi: AppStrings.t('key')
class AppStrings {
  static String t(String key) {
    final table = LocaleController.instance.isEnglish ? _en : _sw;
    return table[key] ?? _sw[key] ?? key;
  }

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
  };
}
