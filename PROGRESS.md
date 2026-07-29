# BrewLog — ilerleme / handoff

> Her oturum veya anlamlı özellik bitince bu dosyayı güncelle.
> Yeni chat: bu dosyayı oku, buradan devam et.

**Son güncelleme:** 2026-07-29  
**Repo:** https://github.com/yusufKemalPinarci/brewlog  
**Branch:** `main`  
**Çalışma ağacı:** P1–P5 commit’li; editör collapse + detay yan yana karşılaştırma eklendi

---

## Ürün (kısa)

- Offline specialty dial-in **günlüğü** — tarif veren app değil
- Veri cihazda; hesap/sunucu/crew UI yok
- Oyunlaştırma: skor rozeti / unvan dili — XP, seviye, görev **yok**
- Akış: liste → detay → kaydet / tekrar dene

---

## Geliştirme orkestrasyonu

- Pipeline otomatik (prompt’tan rota): `full` | `domain-up` | `data-up` | `ui-up` | `fix` | `qa-only` | `hotfix`
- Kural: `.cursor/rules/crewai-dev-standards.mdc`
- Agent’lar: `.cursor/agents/` (product-lead → domain → data → flutter-ui → qa + brew-orchestrator)
- Kullanıcı pipeline adı söylemez; agent rota seçer
- Handoff: bu dosya — her anlamlı iş bitince güncelle

### Prompt iskeleti (tek dilim)

```
Hedef: <tek cümle>
Neden: <acı>
Kapsam içi: <2–4 madde>
Kapsam dışı: <örn. yeni sekme yok>
Kabul: <3–5 checklist>
```

Döngü: kullan → bir acı → tek prompt → analyze/test → bu dosyayı güncelle.

---

## Git durumu

| Ne | Durum |
|----|--------|
| İlk push | ✅ |
| UX polish + domain/cubit fix | ✅ `main` |
| P1–P5 dial-in depth | ✅ commit `93a0f38` (push bekliyor) |
| Editör collapse + yan yana karşılaştırma | ✅ lokal (commit bu oturum) |

---

## Yol haritası durumu

| Faz | Durum | Özet |
|-----|--------|------|
| P0 Temel günlük | ✅ | Liste / detay / editör / favori |
| P1 Dial-in derin | ✅ | Geçmiş zirve, oran bandı, tat ipucu, yöntem varsayılanları, kavurma tarihi |
| P2 Demleme yardım | ✅ | Kronometre → süre, pour notu, su notu |
| P3 Hafıza | ✅ | Çekirdek/kavurucu/öğütücü autocomplete + chip |
| P4 Yerel içgörü | ✅ | Skor trendi, tek değişken notu, efsane strip |
| P5 Veri güvenliği | ✅ | JSON dışa aktar (share) / içe al (yapıştır veya son yedek) |
| Editör sadeleştirme | ✅ | Demleme notları collapse (kavrum/pour/su) |
| Önceki deneme karşılaştırması | ✅ | Detayda skor/öğütü/doz/oran yan yana |

---

## Sonraki adımlar (öncelik)

1. İstenirse `git push` (1–2 commit ahead)
2. Cihazda manuel smoke: yeni kayıt → kronometre → yedek dışa/içe → detay karşılaştırma
3. Sonraki dilim (isteğe bağlı): yöntem şablonları UI / test genişletme / store ikon

---

## Oturum günlüğü (özet)

| Tarih | Ne yapıldı |
|-------|------------|
| 2026-07-26 | Cursor agent pipeline + otomatik rota |
| 2026-07-26 | Gamified ama sade UI |
| 2026-07-26 | Repo GitHub’a yüklendi |
| 2026-07-26 | Polish: favori fix, flicker, silme onayı, boş home… |
| 2026-07-28 | PR split önerildi (kullanılmadı) |
| 2026-07-29 | `PROGRESS.md` handoff; polish + handoff `main`'e push |
| 2026-07-29 | P1–P5: hints/insights domain, editor/detail/home, yedek, testler |
| 2026-07-29 | P1–P5 commit; editör Demleme notları; detay yan yana metrik |
