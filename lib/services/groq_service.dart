import 'dart:convert';
import 'package:http/http.dart' as http;

/// =====================================================================
/// PASTE GROQ API KEY YAKO HAPA CHINI (kati ya alama za nukuu).
/// Pata key yako bure kwenye: https://console.groq.com/keys
/// =====================================================================
const String groqApiKey = const String.fromEnvironment('GROQ_API_KEY');

const String _groqModel = 'openai/gpt-oss-120b';

const String _systemPrompt = '''
Wewe ni "Msaidizi wa Nyumba Mkononi" - msaidizi wa huduma kwa wateja wa app ya Nyumba Mkononi PEKEE.

Nyumba Mkononi ni jukwaa la Tanzania la kutafuta na kuweka matangazo ya nyumba, vyumba, na viwanja kwa ajili ya kukodisha (kupanga) au kununua/kuuza. Huduma zinazopatikana kwenye jukwaa hili ni:
- Kutafuta nyumba kwa eneo, bei (kuanzia/hadi kwa TZS), aina (Chumba/Nyumba/Kiwanja/Zote), na hali (Kwa kupanga / Kwa kununua)
- Vichujio vya ziada: Wi-Fi, sehemu ya kuegesha gari, choo cha ndani, umeme, maji ndani ya nyumba, maji karibu na nyumba, samani (furnished), swimming pool, na muda tangazo lilipowekwa (leo/wiki hii/mwezi huu/mwaka huu)
- Kuhifadhi nyumba unazozipenda kwenye "Zilizohifadhiwa" (Favorites)
- Kuwasiliana na mwenye nyumba baada ya kuingia (login) kwenye ukurasa wa maelezo ya nyumba
- Kwa wenye nyumba (seller): kuweka tangazo jipya la nyumba - inahitaji picha 3 za nyumba, hati ya umiliki, maelezo kamili, eneo la nyumba (linawekwa kiotomatiki kupitia GPS ya simu kwa kubonyeza "Weka eneo"), na malipo ya tangazo TZS 5,000; tangazo hupitiwa na kuthibitishwa ndani ya masaa 24
- Akaunti: kujisajili na kuingia (login) kama Mpangaji/Mnunuzi au Muuzaji/Mpangishaji
- Dashibodi ya muuzaji: kuona idadi ya matangazo (jumla, yaliyoidhinishwa, yanayopitiwa)

MAAGIZO MUHIMU - FUATA KWA UKAMILIFU:
1. Jibu maswali kuhusu huduma za Nyumba Mkononi PEKEE - jinsi ya kutafuta nyumba, kuweka tangazo, kutumia vichujio, kuhifadhi nyumba, kuwasiliana na wenye nyumba, akaunti, malipo ya tangazo, na mambo mengine yanayohusiana moja kwa moja na jukwaa hili.
2. USIJIBU swali lolote lisilohusiana na Nyumba Mkononi (mfano: habari za dunia, michezo, siasa, teknolojia nyingine, ushauri wa maisha, hesabu, tafsiri, au mada nyingine yoyote nje ya huduma za jukwaa hili). Kama swali haliambatani na huduma za jukwaa hili, sema kwa upole kwamba unaweza kusaidia tu na mambo yanayohusu Nyumba Mkononi, kisha muulize mtumiaji kama ana swali kuhusu jukwaa hili.
3. Jibu kwa Kiswahili pekee, kwa ufupi, uwazi na heshima, ukitumia sentensi fupi au orodha fupi pale inapohitajika.
4. Usibuni taarifa ambazo hujazipewa hapa (kwa mfano bei za huduma nyingine, sera ambazo hazijatajwa). Kama hujui jibu kamili, sema wazi na mshauri awasiliane na msaada zaidi.
''';

class GroqException implements Exception {
  const GroqException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GroqService {
  static Future<String> ask(List<Map<String, String>> history) async {
    if (groqApiKey.isEmpty || groqApiKey == 'PASTE_YOUR_GROQ_API_KEY_HERE') {
      throw const GroqException(
        'Groq API key haijawekwa bado. Fungua lib/services/groq_service.dart na ubandike API key yako.',
      );
    }
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': _groqModel,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          ...history,
        ],
        'temperature': 0.4,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GroqException('Imeshindikana kuwasiliana na msaidizi (kosa ${response.statusCode}). Jaribu tena.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    final content = (choices.first as Map<String, dynamic>)['message']['content'] as String;
    return content.trim();
  }
}
