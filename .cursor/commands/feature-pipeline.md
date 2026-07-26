---
description: Full pipeline’ı zorla (opsiyonel — normalde prompt’tan otomatik seçilir).
---

# Feature pipeline (full)

Normalde rota **otomatik** seçilir; bu komut **full** rotayı zorlar: 0→1→2→3→4.

1. **product-lead** — kapsam, Türkçe UX, kabul kriterleri  
2. **domain-engineer** — `features/dial_in/domain/`  
3. **data-engineer** — `features/dial_in/data/`  
4. **flutter-ui** — presentation + tema  
5. **qa** — `flutter analyze` + `flutter test`

`Rota: full → …` diye başla. Her aşamada Task çıktısı yaz. App içinde crew UI yok.
