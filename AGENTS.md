# Agent notları — BrewLog

## Ürün

Flutter offline dial-in günlüğü. **Uygulama içinde crew yok.**

## Geliştirme crew (Cursor)

Prompt’tan **otomatik rota** (full / domain-up / data-up / ui-up / fix / qa-only / hotfix).
Kullanıcı aşama veya pipeline adı söylemez. Kural: `.cursor/rules/crewai-dev-standards.mdc`

| Aşama | Agent | Dosya |
|------:|-------|-------|
| 0 | Product Lead | `.cursor/agents/product-lead.md` |
| 1 | Domain Engineer | `.cursor/agents/domain-engineer.md` |
| 2 | Data Engineer | `.cursor/agents/data-engineer.md` |
| 3 | Flutter UI | `.cursor/agents/flutter-ui.md` |
| 4 | QA | `.cursor/agents/qa.md` |

Orchestrator: `.cursor/agents/brew-orchestrator.md`  
`/feature-pipeline` = sadece **full** rotayı zorlamak için (opsiyonel)

## Handoff

Canlı durum: **`PROGRESS.md`** — her oturum/özellik bitince güncelle.
Yeni chat: önce `PROGRESS.md` oku, oradan devam et.

## Referans (ürün kodu değil)

- `tooling/local_crew/` — dial-in analiz agent kalıbı (Grind → Extraction → Sensory → History)
- App’e import etme

## App yapısı

```
lib/
  core/theme/
  features/dial_in/
    data/repositories/
    domain/entities/
    presentation/bloc|pages/
  main.dart
```
