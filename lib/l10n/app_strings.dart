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

  /// Ujumbe wa maendeleo wakati wa kutafuta eneo (auth screen).
  static List<String> get locationProgressMessages =>
      LocaleController.instance.isEnglish ? _locationProgressEn : _locationProgressSw;

  static const List<String> _locationProgressSw = [
    'Inaendelea...', 'Inachakata eneo lako...', 'Bado kidogo...',
  ];

  static const List<String> _locationProgressEn = [
    'Working on it...', 'Processing your location...', 'Almost there...',
  ];

  /// Ujumbe wa maendeleo wakati wa kuchakata malipo (add property screen).
  static List<String> get paymentProgressMessages =>
      LocaleController.instance.isEnglish ? _paymentProgressEn : _paymentProgressSw;

  static const List<String> _paymentProgressSw = [
    '📍 Inachakata malipo yako...', '🔄 Inaendelea...', '✅ Inamalizia mchakato...',
  ];

  static const List<String> _paymentProgressEn = [
    '📍 Processing your payment...', '🔄 In progress...', '✅ Finishing up...',
  ];

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

    // Personal info screen
    'personalInfoLoadError': 'Imeshindikana kupakia taarifa zako. Angalia mtandao wako.',
    'personalInfoLoadErrorShort': 'Imeshindikana kupakia taarifa zako.',
    'photoUpdated': 'Profile picha imesasishwa.',
    'photoUploadFailed': 'Imeshindikana kupakia picha. Jaribu tena.',
    'infoSaved': 'Taarifa zako zimehifadhiwa.',
    'infoSaveFailed': 'Imeshindikana kuhifadhi taarifa. Jaribu tena.',
    'edit': 'Hariri',
    'save': 'Hifadhi',
    'tapCameraHint': 'Gusa ikoni ya kamera kubadilisha profile picha',
    'fullNameLabel': 'Jina kamili',
    'phoneLabel': 'Namba ya simu',
    'emailLabel': 'Barua pepe',
    'noEmailSet': 'Hujaweka barua pepe',
    'noAreaSet': 'Hujaweka eneo',
    'accountTypeLabel': 'Aina ya akaunti',
    'joinDateLabel': 'Tarehe ya kujiunga',
    'sellerRoleLabel': 'Muuzaji / Mpangishaji',
    'buyerRoleLabel': 'Mnunuzi / Mpangaji',
    'usernameLabel': 'Jina la mtumiaji',

    // Property details screen
    'propertyDetailsTitle': 'Maelezo ya nyumba',
    'contactLoadFailed': 'Imeshindwa kupata taarifa za mmiliki',
    'locationPermNotAllowed': 'Ruhusa ya eneo (GPS) haikuruhusiwa. Iwashe kwenye mipangilio ya simu.',
    'distanceFetchFailed': 'Imeshindwa kupata eneo lako. Hakikisha GPS iko wazi.',
    'forRent': 'Kwa kukodisha',
    'forSale': 'Kwa kuuza',
    'noWifi': 'Hakuna Wi-Fi',
    'aboutThisHome': 'Kuhusu nyumba hii',
    'hideLocation': 'Ficha eneo',
    'viewPropertyLocation': 'Angalia eneo la nyumba',
    'distanceFromYou': 'Umbali kutoka ulipo: {km} km',
    'propertyOwner': 'Mmiliki wa nyumba',
    'viewOwnerContact': 'Ona jina na mawasiliano ya mmiliki',
    'sendMessage': 'Tuma ujumbe',

    // Auth screen
    'serverConnectFailed': 'Imeshindikana kuwasiliana na server.',
    'registerTitle': 'Fungua akaunti',
    'loginTitle': 'Karibu tena',
    'registerSubtitle': 'Taarifa zako zitatusaidia kukupa uzoefu bora.',
    'loginSubtitle': 'Ingia ili uendelee na hatua yako.',
    'loginTab': 'Ingia',
    'registerTab': 'Jisajili',
    'passwordFieldLabel': 'Password',
    'confirmPasswordLabel': 'Thibitisha password',
    'confirmPasswordRequired': 'Thibitisha password yako',
    'passwordMismatch': 'Password hazifanani',
    'yourRoleLabel': 'Jukumu lako',
    'fillField': 'Jaza {label}',
    'areaFieldHint': 'Bonyeza kitufe hapa chini kupata eneo lako',
    'areaRequiredMsg': 'Bonyeza "Weka eneo" kupata eneo lako',
    'detectLocationAgain': 'Tafuta eneo tena',

    // Seller dashboard screen
    'deleteListingTitle': 'Futa tangazo?',
    'deleteListingBody': 'Una uhakika unataka kufuta "{name}"? Hatua hii haiwezi kutenduliwa.',
    'listingDeleted': 'Tangazo limefutwa.',
    'listingDeleteFailed': 'Imeshindikana kufuta tangazo.',
    'dashboardTab': 'Dashibodi',
    'addPropertyLabel': 'Weka nyumba',
    'yourPropertiesLabel': 'Mali zako',
    'welcomeName': 'Karibu, {name}',
    'trackListingsSubtitle': 'Fuatilia matangazo yako ya nyumba hapa.',
    'totalLabel': 'Jumla',
    'approvedLabel': 'Imeidhinishwa',
    'pendingLabel': 'Inapitiwa',
    'expiredLabel': 'Imeisha',
    'noListingsYetTitle': 'Bado hujaweka nyumba',
    'noListingsYetSubtitle': 'Anza kwa kuongeza tangazo la kwanza la nyumba yako.',

    // Add property screen (wizard)
    'addPropertyTitle': 'Weka nyumba mpya',
    'stepHeader': 'Hatua {step} ya {total}',
    'goBackStep': 'Rudi nyuma',
    'photosStepTitle': 'Picha za nyumba',
    'photosCompleteCaption': 'Picha 3/3 zimechaguliwa',
    'photosCountCaption': '{n}/3 picha zimechaguliwa',
    'photosInstruction': 'Weka picha 3 zinazoonyesha nyumba yako vizuri.',
    'descriptionStepTitle': 'Maelezo',
    'descriptionStepCaption': 'Toa maelezo kamili',
    'descriptionHint': 'Mfano: Nyumba ya vyumba 2, jikoni la kisasa, karibu na barabara kuu...',
    'autoLocationCaption': 'Bonyeza kitufe, tutatafuta eneo lako',
    'pickOnMapInstead': 'Chagua kwenye ramani badala yake',
    'locationFound': 'Eneo limepatikana!',
    'ownershipVerificationTitle': 'Uthibitisho wa umiliki',
    'documentRequiredCaption': 'Hati inahitajika',
    'documentInfoText': 'Hapa utapakia nyaraka yoyote inayothibitisha umiliki wako wa nyumba hii (inaweza kuwa picha au faili). '
        'Nyaraka hii itapitiwa na timu yetu ili kuhakikisha umiliki wako ni halali kabla ya nyumba yako kuwekwa kwenye mfumo.',
    'uploadDocument': 'Pakia hati',
    'paymentSubmitTitle': 'Malipo na kutuma',
    'finalStepCaption': 'Hatua ya mwisho',
    'paymentCompleteMsg': 'Malipo ya TZS 10,000 yamekamilika. Sasa unaweza kutuma tangazo.',
    'paymentPendingMsg': 'Malipo ya tangazo ni TZS 10,000 (kupitia ClickPesa - M-Pesa/Tigo Pesa/Airtel Money/Halopesa). '
        'Tangazo litapitiwa ndani ya masaa 24 baada ya kutumwa.',
    'confirmOrRetryPayment': 'Thibitisha / jaribu malipo tena',
    'payToContinue': 'Lipa TZS 10,000 kuendelea',
    'submitPayFirst': 'Tuma tangazo — lipa kwanza',
    'submitListing': 'Tuma tangazo',
    'payTzs10000Title': 'Lipa TZS 10,000',
    'paymentPhoneInstruction': 'Weka namba ya simu (M-Pesa / Tigo Pesa / Airtel Money / Halo Pesa) utakayotumia kulipia ada ya kutangaza nyumba.',
    'phoneHintExample': '07XXXXXXXX',
    'continueToPay': 'Endelea kulipa',
    'confirmPaymentTitle': 'Thibitisha malipo',
    'checkingPaymentStatus': 'Tunaangalia hali ya malipo yako...',
    'confirmPaymentInstruction': 'Angalia simu yako{channel} - utaona ombi la kuweka PIN ili kuidhinisha malipo ya TZS 10,000. '
        'Ukishaweka PIN, bonyeza "Nimeshalipa" hapa kuthibitisha.',
    'confirmPaymentChannelSuffix': ' ya {channel}',
    'confirmLater': 'Nitathibitisha baadaye',
    'iHavePaid': 'Nimeshalipa',
    'paymentInitFailed': 'Imeshindikana kuanzisha malipo. Jaribu tena.',
    'photosRequiredError': 'Weka picha 3 za nyumba kabla ya kuendelea.',
    'streetWardRequiredError': 'Jaza jina la mtaa au kata.',
    'priceRequiredError': 'Jaza bei ya nyumba.',
    'priceMustBeNumberError': 'Bei lazima iwe namba.',
    'descriptionRequiredError': 'Andika maelezo ya nyumba.',
    'locationRequiredError': 'Bonyeza "Weka eneo" kupata eneo la nyumba.',
    'documentRequiredError': 'Pakia hati ya umiliki.',
    'paymentRequiredError': 'Lipa TZS 10,000 kwanza kabla ya kutuma tangazo.',
    'listingSubmitted': 'Tangazo limetumwa. Litapitiwa ndani ya masaa 24.',
    'listingSubmitFailed': 'Imeshindikana kutuma tangazo.',

    // Buyer home screen (nav, hero, search, categories, listings — Phase 8a)
    'navSearchLabel': 'Tafuta',
    'navFavoritesLabel': 'Pendwa',
    'navMessagesLabel': 'Ujumbe',
    'navHelpLabel': 'Msaada',
    'navProfileLabel': 'Wasifu',
    'bottomFavoritesLabel': 'Zilizohifadhiwa',
    'heroHeadline': 'Tafuta nyumba, viwanja na fursa bora za makazi',
    'heroTagline': 'Nyumba Mkononi – Mahali sahihi kwa mahitaji yako ya makazi',
    'welcomeComma': 'Karibu,',
    'searchHint': 'Dar es Salaam, Kariakoo...',
    'filtersTooltip': 'Vichujio',
    'rentModeButtonLabel': 'Kwa Kupanga',
    'buyModeButtonLabel': 'Kwa Kununua',
    'allCategoriesLabel': 'Zote',
    'noMatchingListings': 'Hakuna matangazo yanayolingana na utafutaji wako.',
    'verifiedPropertiesTitle': 'Mali zilizothibitishwa',
    'propertiesCount': '{n} nyumba',

    // Buyer home screen (filters sheet, property card — Phase 8b)
    'filtersTitle': 'Vichujio',
    'filtersSubtitle': 'Chagua vigezo unavyotaka. Si lazima uchague vyote.',
    'priceRangeLabel': 'Bei (TZS)',
    'tshPrefix': 'Tsh ',
    'fromPriceLabel': 'Kuanzia',
    'toPriceLabel': 'Hadi',
    'postedWithinLabel': 'Tangazo limewekwa lini',
    'anyTimeLabel': 'Wakati wowote',
    'todayLabel': 'Leo',
    'thisWeekLabel': 'Wiki hii',
    'thisMonthLabel': 'Mwezi huu',
    'thisYearLabel': 'Mwaka huu',
    'requiredAmenitiesLabel': 'Huduma zinazohitajika',
    'filterWifiLabel': 'Wi-Fi',
    'filterElectricityLabel': 'Umeme',
    'filterWaterInsideLabel': 'Maji ndani',
    'filterWaterNearbyLabel': 'Maji karibu',
    'filterFurnishedLabel': 'Samani (furnished)',
    'filterSwimmingPoolLabel': 'Swimming pool',
    'clearFiltersButton': 'Futa vichujio',
    'applyFiltersButton': 'Tafuta',
    'propertyBadgeApproved': 'Imethibitishwa',
    'priceMonthSuffix': ' / mwezi',
    'comingSoonMessage': 'Sehemu hii itakuwa tayari baada ya kuwasiliana na mwenye nyumba.',
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

    // Personal info screen
    'personalInfoLoadError': 'Could not load your information. Check your connection.',
    'personalInfoLoadErrorShort': 'Could not load your information.',
    'photoUpdated': 'Profile photo updated.',
    'photoUploadFailed': 'Could not upload photo. Please try again.',
    'infoSaved': 'Your information has been saved.',
    'infoSaveFailed': 'Could not save your information. Please try again.',
    'edit': 'Edit',
    'save': 'Save',
    'tapCameraHint': 'Tap the camera icon to change your profile photo',
    'fullNameLabel': 'Full name',
    'phoneLabel': 'Phone number',
    'emailLabel': 'Email',
    'noEmailSet': 'No email set',
    'noAreaSet': 'No area set',
    'accountTypeLabel': 'Account type',
    'joinDateLabel': 'Joined on',
    'sellerRoleLabel': 'Seller / Landlord',
    'buyerRoleLabel': 'Buyer / Tenant',
    'usernameLabel': 'Username',

    // Property details screen
    'propertyDetailsTitle': 'Property details',
    'contactLoadFailed': 'Could not get the owner\'s details',
    'locationPermNotAllowed': 'Location (GPS) permission was not granted. Turn it on in your phone settings.',
    'distanceFetchFailed': 'Could not get your location. Make sure GPS has a clear signal.',
    'forRent': 'For rent',
    'forSale': 'For sale',
    'noWifi': 'No Wi-Fi',
    'aboutThisHome': 'About this home',
    'hideLocation': 'Hide location',
    'viewPropertyLocation': 'View property location',
    'distanceFromYou': 'Distance from you: {km} km',
    'propertyOwner': 'Property owner',
    'viewOwnerContact': 'View owner\'s name and contact',
    'sendMessage': 'Send message',

    // Auth screen
    'serverConnectFailed': 'Could not reach the server.',
    'registerTitle': 'Create account',
    'loginTitle': 'Welcome back',
    'registerSubtitle': 'Your details help us give you a better experience.',
    'loginSubtitle': 'Sign in to continue.',
    'loginTab': 'Sign in',
    'registerTab': 'Sign up',
    'passwordFieldLabel': 'Password',
    'confirmPasswordLabel': 'Confirm password',
    'confirmPasswordRequired': 'Please confirm your password',
    'passwordMismatch': 'Passwords do not match',
    'yourRoleLabel': 'Your role',
    'fillField': 'Please enter {label}',
    'areaFieldHint': 'Tap the button below to get your location',
    'areaRequiredMsg': 'Tap "Set location" to get your location',
    'detectLocationAgain': 'Detect location again',

    // Seller dashboard screen
    'deleteListingTitle': 'Delete listing?',
    'deleteListingBody': 'Are you sure you want to delete "{name}"? This cannot be undone.',
    'listingDeleted': 'Listing deleted.',
    'listingDeleteFailed': 'Could not delete the listing.',
    'dashboardTab': 'Dashboard',
    'addPropertyLabel': 'Add property',
    'yourPropertiesLabel': 'Your properties',
    'welcomeName': 'Welcome, {name}',
    'trackListingsSubtitle': 'Track your property listings here.',
    'totalLabel': 'Total',
    'approvedLabel': 'Approved',
    'pendingLabel': 'Under review',
    'expiredLabel': 'Expired',
    'noListingsYetTitle': 'No properties yet',
    'noListingsYetSubtitle': 'Get started by adding your first property listing.',

    // Add property screen (wizard)
    'addPropertyTitle': 'Add new property',
    'stepHeader': 'Step {step} of {total}',
    'goBackStep': 'Go back',
    'photosStepTitle': 'Property photos',
    'photosCompleteCaption': 'Photos 3/3 selected',
    'photosCountCaption': '{n}/3 photos selected',
    'photosInstruction': 'Add 3 photos that show your property clearly.',
    'descriptionStepTitle': 'Description',
    'descriptionStepCaption': 'Give a full description',
    'descriptionHint': 'e.g. 2-bedroom house, modern kitchen, near the main road...',
    'autoLocationCaption': 'Tap the button, we\'ll find your location',
    'pickOnMapInstead': 'Choose on the map instead',
    'locationFound': 'Location found!',
    'ownershipVerificationTitle': 'Proof of ownership',
    'documentRequiredCaption': 'Document required',
    'documentInfoText': 'Here you\'ll upload any document proving your ownership of this property (it can be a photo or a file). '
        'This document will be reviewed by our team to confirm your ownership is valid before your property is listed.',
    'uploadDocument': 'Upload document',
    'paymentSubmitTitle': 'Payment & submit',
    'finalStepCaption': 'Final step',
    'paymentCompleteMsg': 'Your TZS 10,000 payment is complete. You can now submit the listing.',
    'paymentPendingMsg': 'The listing fee is TZS 10,000 (via ClickPesa - M-Pesa/Tigo Pesa/Airtel Money/Halopesa). '
        'The listing will be reviewed within 24 hours after submission.',
    'confirmOrRetryPayment': 'Confirm / retry payment',
    'payToContinue': 'Pay TZS 10,000 to continue',
    'submitPayFirst': 'Submit listing — pay first',
    'submitListing': 'Submit listing',
    'payTzs10000Title': 'Pay TZS 10,000',
    'paymentPhoneInstruction': 'Enter the phone number (M-Pesa / Tigo Pesa / Airtel Money / Halo Pesa) you will use to pay the listing fee.',
    'phoneHintExample': '07XXXXXXXX',
    'continueToPay': 'Continue to pay',
    'confirmPaymentTitle': 'Confirm payment',
    'checkingPaymentStatus': 'Checking your payment status...',
    'confirmPaymentInstruction': 'Check your phone{channel} - you\'ll see a prompt to enter your PIN to approve the TZS 10,000 payment. '
        'Once you\'ve entered it, tap "I\'ve paid" here to confirm.',
    'confirmPaymentChannelSuffix': ' on {channel}',
    'confirmLater': 'I\'ll confirm later',
    'iHavePaid': 'I\'ve paid',
    'paymentInitFailed': 'Could not start the payment. Please try again.',
    'photosRequiredError': 'Add 3 property photos before continuing.',
    'streetWardRequiredError': 'Enter the street or ward name.',
    'priceRequiredError': 'Enter the property price.',
    'priceMustBeNumberError': 'Price must be a number.',
    'descriptionRequiredError': 'Write a description of the property.',
    'locationRequiredError': 'Tap "Set location" to get the property location.',
    'documentRequiredError': 'Upload the ownership document.',
    'paymentRequiredError': 'Pay TZS 10,000 before submitting the listing.',
    'listingSubmitted': 'Listing submitted. It will be reviewed within 24 hours.',
    'listingSubmitFailed': 'Could not submit the listing.',

    // Buyer home screen (nav, hero, search, categories, listings — Phase 8a)
    'navSearchLabel': 'Search',
    'navFavoritesLabel': 'Favorites',
    'navMessagesLabel': 'Messages',
    'navHelpLabel': 'Help',
    'navProfileLabel': 'Profile',
    'bottomFavoritesLabel': 'Saved',
    'heroHeadline': 'Find homes, plots and the best places to live',
    'heroTagline': 'Nyumba Mkononi – The right place for your housing needs',
    'welcomeComma': 'Welcome,',
    'searchHint': 'Dar es Salaam, Kariakoo...',
    'filtersTooltip': 'Filters',
    'rentModeButtonLabel': 'To Rent',
    'buyModeButtonLabel': 'To Buy',
    'allCategoriesLabel': 'All',
    'noMatchingListings': 'No listings match your search.',
    'verifiedPropertiesTitle': 'Verified properties',
    'propertiesCount': '{n} properties',

    // Buyer home screen (filters sheet, property card — Phase 8b)
    'filtersTitle': 'Filters',
    'filtersSubtitle': 'Choose the criteria you want. You don\'t have to pick them all.',
    'priceRangeLabel': 'Price (TZS)',
    'tshPrefix': 'Tsh ',
    'fromPriceLabel': 'From',
    'toPriceLabel': 'To',
    'postedWithinLabel': 'When it was listed',
    'anyTimeLabel': 'Any time',
    'todayLabel': 'Today',
    'thisWeekLabel': 'This week',
    'thisMonthLabel': 'This month',
    'thisYearLabel': 'This year',
    'requiredAmenitiesLabel': 'Required amenities',
    'filterWifiLabel': 'Wi-Fi',
    'filterElectricityLabel': 'Electricity',
    'filterWaterInsideLabel': 'Water inside',
    'filterWaterNearbyLabel': 'Water nearby',
    'filterFurnishedLabel': 'Furnished',
    'filterSwimmingPoolLabel': 'Swimming pool',
    'clearFiltersButton': 'Clear filters',
    'applyFiltersButton': 'Search',
    'propertyBadgeApproved': 'Verified',
    'priceMonthSuffix': ' / month',
    'comingSoonMessage': 'This section will be available once you contact the property owner.',
  };
}
