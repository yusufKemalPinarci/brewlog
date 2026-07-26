enum BrewMethod {
  espresso,
  v60,
  kalita,
  origami,
  aeropress,
  frenchPress,
  moka,
  other;

  String get label => switch (this) {
        BrewMethod.espresso => 'Espresso',
        BrewMethod.v60 => 'V60',
        BrewMethod.kalita => 'Kalita',
        BrewMethod.origami => 'Origami',
        BrewMethod.aeropress => 'AeroPress',
        BrewMethod.frenchPress => 'French Press',
        BrewMethod.moka => 'Moka',
        BrewMethod.other => 'Diğer',
      };
}

enum TasteTag {
  sour,
  bitter,
  sweet,
  salty,
  astringent,
  thin,
  heavy,
  balanced,
  muted;

  String get label => switch (this) {
        TasteTag.sour => 'Ekşi',
        TasteTag.bitter => 'Acı',
        TasteTag.sweet => 'Tatlı',
        TasteTag.salty => 'Tuzlu',
        TasteTag.astringent => 'Buruk',
        TasteTag.thin => 'İnce gövde',
        TasteTag.heavy => 'Ağır gövde',
        TasteTag.balanced => 'Dengeli',
        TasteTag.muted => 'Kapalı aroma',
      };
}
