# BrewLog

Tam **offline** specialty kahve dial-in günlüğü.

## Özellikler

- Dial-in kaydı (çekirdek, yöntem, öğütü, doz/verim, süre, sıcaklık, tat, skor)
- Favoriler, arama, yöntem filtresi, sıralama
- Detay + tariften kopyala
- Yerel JSON depolama — hesap/sunucu yok

## Geliştirme

CrewAI standartları ürün UI’sında değil; Cursor kuralları + `tooling/local_crew/` referansındadır.

```bash
flutter pub get
flutter run
flutter test
flutter build apk --release
```
