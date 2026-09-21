/// Aina za mali zinazotumika kwenye app: Chumba, Nyumba na Kiwanja.
///
/// Matangazo ya zamani yanaweza bado kuwa na aina za zamani
/// (apartment, studio, villa). Hizi zinaonyeshwa/kuchujwa kama ifuatavyo:
/// studio -> Chumba, apartment na villa -> Nyumba.
class PropertyTypes {
  const PropertyTypes._();

  static const chumba = 'chumba';
  static const nyumba = 'nyumba';
  static const kiwanja = 'kiwanja';

  /// Thamani zinazotumwa kwa backend (kwa mpangilio wa kuonyesha).
  static const values = [chumba, nyumba, kiwanja];

  /// Inabadilisha aina ya zamani kuwa moja ya aina tatu mpya.
  static String normalize(String type) {
    switch (type.toLowerCase()) {
      case 'chumba':
      case 'studio':
        return chumba;
      case 'kiwanja':
        return kiwanja;
      default:
        // nyumba, apartment, villa na nyingine zote za zamani.
        return nyumba;
    }
  }

  /// Jina la kuonyesha kwa mtumiaji.
  static String label(String type) {
    switch (normalize(type)) {
      case chumba:
        return 'Chumba';
      case kiwanja:
        return 'Kiwanja';
      default:
        return 'Nyumba';
    }
  }
}
