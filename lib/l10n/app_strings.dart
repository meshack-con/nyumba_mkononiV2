import 'locale_controller.dart';

/// Maandishi ya app kwa Kiswahili na English.
/// Matumizi: AppStrings.t('key')
class AppStrings {
  static String t(String key) {
    final table = LocaleController.instance.isEnglish ? _en : _sw;
    return table[key] ?? _sw[key] ?? key;
  }

  /// Kama [t] lakini inabadilisha `{n}` na namba uliyotoa. Muhimu kwa
  /// maandishi yenye idadi, mfano 'Dakika {n} zilizopita'.
  static String tCount(String key, num n) => t(key).replaceFirst('{n}', '$n');

  /// Kama [t] lakini inabadilisha vibadala vingi vya `{jina}` kwa wakati
  /// mmoja, mfano tParams('assistantConnectFailed', {'detail': '...'}).
  static String tParams(String key, Map<String, String> params) {
    var result = t(key);
    for (final entry in params.entries) {
      result = result.replaceFirst('{${entry.key}}', entry.value);
    }
    return result;
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

    // Messages inbox screen
    'messagesTitle': 'Ujumbe',
    'noMessagesYet': 'Bado hujapata ujumbe wowote.',

    // Notifications screen
    'notifLoadError': 'Imeshindikana kupakia arifa. Angalia mtandao wako.',
    'justNow': 'Sasa hivi',
    'minutesAgo': 'Dakika {n} zilizopita',
    'daysAgo': 'Siku {n} zilizopita',
    'tryAgain': 'Jaribu tena',
    'noNotificationsYet': 'Bado huna arifa.',

    // Splash screen
    'back': 'Rudi',
    'continueButton': 'Endelea',
    'start': 'Anza',

    // Chat screen
    'sendFailed': 'Imeshindwa kutuma ujumbe',
    'deleteMessageTitle': 'Futa ujumbe?',
    'deleteMessageBody': 'Ujumbe huu utafutwa kabisa kwenye mfumo.',
    'cancel': 'Ghairi',
    'delete': 'Futa',
    'noChatMessagesYet': 'Bado hakuna ujumbe. Anza mazungumzo.',
    'deleteMessageFailed': 'Imeshindwa kufuta ujumbe',
    'chatInputHint': 'Andika ujumbe...',

    // Property form (edit + add property screens)
    'basicInfoSection': 'Taarifa za msingi',
    'basicInfoCaption': 'Eleza nyumba yako kwa uwazi',
    'streetWardLabel': 'Jina la mtaa / kata',
    'streetWardHint': 'Mfano: Sinza, Mikocheni',
    'typeLabel': 'Aina',
    'propTypeChumba': 'Chumba',
    'propTypeNyumba': 'Nyumba',
    'propTypeKiwanja': 'Kiwanja',
    'modeLabel': 'Hali',
    'modeRent': 'Kukodisha',
    'modeSale': 'Kuuza',
    'priceLabelTzs': 'Bei kwa TZS',
    'propertyDescriptionLabel': 'Maelezo ya nyumba',
    'amenitiesSection': 'Huduma zilizopo',
    'amenitiesCaption': 'Chagua zote zinazopatikana',
    'wifiAvailable': 'Wi-Fi ipo',
    'carParkingLabel': 'Sehemu ya kuegesha gari',
    'indoorToiletLabel': 'Choo cha ndani',
    'electricityAvailable': 'Umeme upo',
    'waterInsideLabel': 'Maji ndani ya nyumba',
    'waterNearbyLabel': 'Maji karibu na nyumba',
    'furnishedLabel': 'Ina samani (furnished)',
    'swimmingPoolLabel': 'Ina swimming pool',
    'locationSection': 'Eneo',
    'locationSectionCaption': 'Ruhusu GPS ya simu yako',
    'photoNotice': 'Picha na hati ya umiliki haziwezi kubadilishwa hapa. Wasiliana na msaada ikiwa unahitaji kuzibadilisha.',
    'saveChanges': 'Hifadhi mabadiliko',
    'requiredField': 'Sehemu hii inahitajika',
    'editPropertyTitle': 'Hariri tangazo',
    'propertyUpdated': 'Tangazo limehaririwa.',
    'propertyUpdateFailed': 'Imeshindikana kuhariri tangazo.',

    // Location field / location service
    'detectingLocation': 'Inatafuta eneo...',
    'setLocation': 'Weka eneo',
    'locationSetConfirmed': 'Eneo la nyumba limewekwa',
    'openSettingsAction': 'Fungua mipangilio',
    'locationPermDenied': 'Ruhusa ya eneo imekataliwa. Bonyeza "Weka eneo" tena kisha uchague "Ruhusu".',
    'locationPermDeniedWeb': 'Ruhusa ya eneo imezuiwa. Iruhusu kwenye mipangilio ya browser kisha jaribu tena.',
    'locationPermDeniedApp': 'Ruhusa ya eneo imezuiwa. Iruhusu kwenye mipangilio ya app kisha jaribu tena.',
    'gpsDisabled': 'GPS ya simu imezimwa. Iwashe kisha bonyeza "Weka eneo" tena.',
    'locationTimeout': 'Imechukua muda mrefu kupata eneo. Hakikisha GPS imewashwa na uko eneo wazi, kisha jaribu tena.',
    'locationFetchFailed': 'Imeshindikana kupata eneo lako. Jaribu tena.',

    // Help assistant screen
    'helpAppBarTitle': 'Msaada',
    'helpWelcomeMessage': 'Habari! Mimi ni Msaidizi wa Nyumba Mkononi. '
        'Naweza kukusaidia kuhusu kutafuta nyumba, kuweka tangazo, vichujio vya utafutaji, '
        'malipo ya tangazo, na huduma nyingine za jukwaa hili. Una swali gani leo?',
    'helpNetworkError': 'Samahani, kuna tatizo la mtandao. Jaribu tena baadaye.',
    'helpInputHint': 'Andika swali lako kuhusu Nyumba Mkononi...',
    'assistantTyping': 'Msaidizi anaandika...',
    'assistantConnectFailed': 'Imeshindikana kuwasiliana na msaidizi ({detail}). Jaribu tena.',
    'genericErrorCode': 'kosa {code}',

    // Location picker screen
    'pickLocationTitle': 'Chagua eneo la nyumba',
    'useCurrentLocationTooltip': 'Tumia eneo langu la sasa',
    'tapMapInstruction': 'Bonyeza mahali popote kwenye ramani kuweka eneo la nyumba',
    'resolvingLabelText': 'Inatafuta jina la eneo...',
    'useThisLocation': 'Tumia eneo hili',
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

    // Messages inbox screen
    'messagesTitle': 'Messages',
    'noMessagesYet': 'You have not received any messages yet.',

    // Notifications screen
    'notifLoadError': 'Could not load notifications. Check your connection.',
    'justNow': 'Just now',
    'minutesAgo': '{n} minutes ago',
    'daysAgo': '{n} days ago',
    'tryAgain': 'Try again',
    'noNotificationsYet': 'You have no notifications yet.',

    // Splash screen
    'back': 'Back',
    'continueButton': 'Continue',
    'start': 'Get started',

    // Chat screen
    'sendFailed': 'Could not send message',
    'deleteMessageTitle': 'Delete message?',
    'deleteMessageBody': 'This message will be permanently deleted from the system.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'noChatMessagesYet': 'No messages yet. Start the conversation.',
    'deleteMessageFailed': 'Could not delete message',
    'chatInputHint': 'Type a message...',

    // Property form (edit + add property screens)
    'basicInfoSection': 'Basic information',
    'basicInfoCaption': 'Describe your property clearly',
    'streetWardLabel': 'Street / ward name',
    'streetWardHint': 'e.g. Sinza, Mikocheni',
    'typeLabel': 'Type',
    'propTypeChumba': 'Room',
    'propTypeNyumba': 'House',
    'propTypeKiwanja': 'Plot',
    'modeLabel': 'Listing type',
    'modeRent': 'For rent',
    'modeSale': 'For sale',
    'priceLabelTzs': 'Price in TZS',
    'propertyDescriptionLabel': 'Property description',
    'amenitiesSection': 'Available amenities',
    'amenitiesCaption': 'Select all that apply',
    'wifiAvailable': 'Wi-Fi available',
    'carParkingLabel': 'Car parking space',
    'indoorToiletLabel': 'Indoor toilet',
    'electricityAvailable': 'Electricity available',
    'waterInsideLabel': 'Water inside the house',
    'waterNearbyLabel': 'Water nearby',
    'furnishedLabel': 'Furnished',
    'swimmingPoolLabel': 'Has swimming pool',
    'locationSection': 'Location',
    'locationSectionCaption': 'Allow your phone\'s GPS',
    'photoNotice': 'Photos and the ownership document cannot be changed here. Contact support if you need to update them.',
    'saveChanges': 'Save changes',
    'requiredField': 'This field is required',
    'editPropertyTitle': 'Edit listing',
    'propertyUpdated': 'Listing updated.',
    'propertyUpdateFailed': 'Could not update the listing.',

    // Location field / location service
    'detectingLocation': 'Finding location...',
    'setLocation': 'Set location',
    'locationSetConfirmed': 'Property location has been set',
    'openSettingsAction': 'Open settings',
    'locationPermDenied': 'Location permission denied. Tap "Set location" again and choose "Allow".',
    'locationPermDeniedWeb': 'Location permission is blocked. Allow it in your browser settings, then try again.',
    'locationPermDeniedApp': 'Location permission is blocked. Allow it in the app settings, then try again.',
    'gpsDisabled': 'Your phone\'s GPS is off. Turn it on, then tap "Set location" again.',
    'locationTimeout': 'Getting your location took too long. Make sure GPS is on and you\'re in an open area, then try again.',
    'locationFetchFailed': 'Could not get your location. Please try again.',

    // Help assistant screen
    'helpAppBarTitle': 'Help',
    'helpWelcomeMessage': 'Hi! I\'m the Nyumba Mkononi assistant. '
        'I can help with finding homes, listing a property, search filters, '
        'listing payments, and other things on this platform. What can I help with today?',
    'helpNetworkError': 'Sorry, there\'s a network problem. Please try again later.',
    'helpInputHint': 'Type your question about Nyumba Mkononi...',
    'assistantTyping': 'Assistant is typing...',
    'assistantConnectFailed': 'Could not reach the assistant ({detail}). Please try again.',
    'genericErrorCode': 'error {code}',

    // Location picker screen
    'pickLocationTitle': 'Pick property location',
    'useCurrentLocationTooltip': 'Use my current location',
    'tapMapInstruction': 'Tap anywhere on the map to set the property location',
    'resolvingLabelText': 'Finding place name...',
    'useThisLocation': 'Use this location',
  };
}
