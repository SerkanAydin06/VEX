# VEX — Claude hafızası

Bu dosya oturumlar arası hafızadır; `CLAUDE.md` tarafından her oturumda yüklenir.
**Her iş bitince aynı PR içinde güncelle:** tamamlananı "Yapılanlar"a tek satır ekle,
"Açık işler"den düş, yeni karar/ders varsa yaz. Kısa tut; ayrıntı git geçmişinde ve PR açıklamalarında.

## Kullanıcı tercihleri

- Türkçe konuş. Kullanıcı oyun geliştiricisi; teknik ayrıntıyı sade anlat.
- "Direk uygula": işi dalda yap → doğrula → PR aç → `main`'e merge et. Ayrıca onay isteme; yalnız gerçek tasarım kararlarını sor (denge değerleri, içerik tercihleri).
- İşleri **sırayla**, her birini ayrı PR olarak yap.
- Jeton/verim önemli: gereksiz keşif yapma, `tools/validate.sh` özetini kullan, büyük skill paketi / MCP ekleme.
- GitHub Actions kotası yok; CI kurma, yerel doğrulama kullan.
- Önemli bilgiyi (tercih, karar, ders, yeni açık iş) kullanıcı söylemeden `HAFIZA.md`'ye kendin ekle.

## Yapılanlar (2026-09, PR #80–#98)

- #80 Oynanış hataları: Level 2 prop geri dönüşü, düşük can kilidi (yeniden başlama min %50, Bastion'da tam can), pause'a duyarlı düşman/kapı zamanlayıcıları, eski denetimler kanonik bölümlere uyarlandı.
- #81 15 düşmanın kare zemin ofsetleri spritesheet'lere göre yeniden hizalandı (8 mm temas).
- #82 Anlamsız binary boyut denetimi kaldırıldı.
- #83 3. bölüm sonrası tek seferlik ara son ekranı (`VexBaseLevel.shows_campaign_end_screen`, level_03'te açık).
- #84 Hikâye tutarlılığı: arşiv kayıtları kanonik Bölüm 1–3, evren `reveal_stage` ile erken sır açığa çıkmıyor, Leyla Sönmez Bastion'a eklendi (aşamalı replik), belgelerde P-07/P-14/Loom Herald düzeltmeleri.
- #85 Bölüm tamamlanınca Bastion aydınlatması otomatik yükselir (SAVE_VERSION 7 göçü).
- #86 Ara son ekranı "Ana Menü"ye rağmen kayıtta bekler.
- #87 Hiç çalışmayan 25 pytest tarzı denetim (175 test) çalışır hâle getirildi; bölüm yapı kurulumu `VexBaseLevel`'da birleştirildi.
- #88 `CLAUDE.md`, `tools/validate.sh`, Godot kuran session-start hook'u.
- #89 Oturumlar arası hafıza (`.claude/HAFIZA.md`, `CLAUDE.md`'den yüklenir).
- #90 Otomatik hafıza hook'ları: `memory-reminder.sh` (UserPromptSubmit) ve `memory-guard.sh` (Stop, `HAFIZA.md` güncellenmeden bitirmeyi bir kez durdurur).
- #91 Pre-push git hook'u (`tools/git-hooks/pre-push` → `tools/validate.sh`; yalnız `.md`/`.claude/` değişikliğinde ya da aynı ağaç zaten doğrulandıysa atlar). Web oturumunda `session-start.sh` `core.hooksPath`'i ayarlar; Windows'ta bir kez `git config core.hooksPath tools/git-hooks`.
- #92 Arşiv terminali metinleri (121 anahtar, `ARCHIVE_UI_*`) `translations/vex.csv` + `tr()`'ye taşındı; `tools/extract_inline_text.py` dönüştürücü, `tests/translation_text.py` denetim yardımcısı; oyuncuya görünen `VEX-%02d` → `BÖLÜM %02d`.
- #93 Silah arşivi terminali metinleri (30 anahtar, `WEAPON_UI_*`) taşındı; taşınan betikler `tests/inline_text_migration_audit.py` listesinde korunuyor.
- #94 Bastion üs yönetimi paneli metinleri (22 yeni anahtar, `BASE_UI_*`) taşındı.
- #95 Saha kaydı köprüsü metinleri (8 anahtar, `FIELD_RECORD_UI_*`) taşındı; `scripts/` içinde `_t()` yardımcısı kalmadı.
- #96 Kalan dil koşullu metinler (`settings_panel`, `terminal_menu`, `hub_terminal`, `game_state`; `SETTINGS_UI_*`, `TERMINAL_UI_*`, `HUB_TERMINAL_UI_*`, `SAVE_UI_*`) taşındı; dönüştürücü artık `"A" if turkish else "B"` ve if/return kalıplarını da çeviriyor. Koda gömülü metin taşıma işi bitti.
- #97 Temizlik: 120 kullanılmayan çeviri satırı silindi (`tests/translation_usage_audit.py` artık ölü satırı yakalıyor); eğitim akışı kapı için `VexDoor.refresh_combat_lock()` kullanıyor.
- #98 Crucible Warden canı 260 → 400 (kullanıcı kararı; miniboss, Bulwark 300'ün üstünde).

## Kararlar (tekrar tartışma)

- Doku boyutu sorun değil: yalnız Windows/D3D11 (ANGLE), sınır ≥8192 px; en büyük sayfa 5376 px.
- Xeno arşiv keşifleri Yeni Oyun'da sıfırlanmaz — bilinçli (belgede yazılı). Saha kayıtları sıfırlanır.
- Loom Herald yalnız Level Test sandbox prototipi; kampanyada/arşivde yok.
- Ayrılmış çeviri anahtarları (planlı içerik): `HUD_SLOT_05`, `HUD_AMMO_MAGNUM`, `CH02_BYPASS_RESERVED` — silme.
- `furnice_carrier` iç kimliği (dosya/enemy_id) değişmez: arşiv keşfi kayıtta saklanıyor. Oyuncuya görünen ad zaten "FURNACE CARRIER".
- Can sıralaması: Crucible Warden 400 (miniboss) > Vaskari Bulwark 300 > Basalt Juggernaut 240. Zorluk çarpanları `enemy_base.gd` varsayılanı (×0.75/1/1.2/1.45).

## Açık işler (sırayla)

1. **Metin anahtarlı çeviri satırları:** ~70 satır anahtar olarak Türkçe metin kullanıyor (ör. `"MAVİ ERİŞİM KARTI"`, sahnelerde `tr()` ile). `KEY_CARD_BLUE` gibi kimlik anahtarlarına taşı (sahne/kaynak referanslarıyla birlikte).

## Öğrenilen dersler

- Headless Godot denemelerini scratchpad kopyasında yap (`git ls-files -co --exclude-standard | tar …`), depoya ekleme.
- Denetim başarısız olursa önce `main`'de de başarısız mı bak: eskiden bozuk mu, yeni mi ayırt et.
- Değişiklik denetim sözleşmesini bozuyorsa, oyunun mu testin mi doğru olduğuna karar ver ve doğru tarafı düzelt.
- Veri sözlüklerindeki `_tr`/`_en` alan seçimi (`vex_archive_database`, `vex_field_record_database`) çeviri dosyasına taşınmaz; veri kalıbıdır.
- `@tool` terminal betiklerinde `tr()` kullanımı mevcut kalıp (`terminal_menu.gd`); editör önizlemesinde anahtar görünmesi kabul.
- Push'tan önce `tools/validate.sh` çalıştırmak yeterli: başarılı ve temiz çalışma kopyası ağacı damgalar, pre-push hook'u tekrar çalıştırmaz.
- Web konteyneri uzun aradan sonra sıfırlanabilir: commit'lenmemiş iş kaybolur; her adımı hemen commit+push et.
- `tests/__pycache__` commit'e girmesin (artık `.gitignore`'da; `validate.sh` bytecode yazmaz).
