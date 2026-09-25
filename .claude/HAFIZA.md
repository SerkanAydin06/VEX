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

## Yapılanlar (2026-09, PR #80–#92)

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

## Kararlar (tekrar tartışma)

- Doku boyutu sorun değil: yalnız Windows/D3D11 (ANGLE), sınır ≥8192 px; en büyük sayfa 5376 px.
- Xeno arşiv keşifleri Yeni Oyun'da sıfırlanmaz — bilinçli (belgede yazılı). Saha kayıtları sıfırlanır.
- Loom Herald yalnız Level Test sandbox prototipi; kampanyada/arşivde yok.
- Kullanılmayan eski prototip çeviri satırları henüz silinmedi (açık iş 2).

## Açık işler (sırayla)

1. **Koda gömülü metinler (devam):** `python3 tools/extract_inline_text.py <dosya> <ÖNEK> --apply` ile sırayla `scripts/ui/weapon_archive_terminal.gd` (WEAPON_UI, 30), `base_management_dashboard.gd` (29), `field_record_archive_bridge.gd` (9); sonra `begins_with("tr")` / `if turkish` kalıpları. Bozulan denetimlerde betik okumasını `with_translations(...)` ile sar. Dosya başına ayrı PR.
2. **Temizlik:** kullanılmayan `LEVEL0x_*`, `HUB_VEX0x_*`, `SURVIVOR_SELIN_DIALOGUE_STAGE2/3`, `TERMINAL_FACILITY_ASH_MINE`, `MAIN_CREDITS_BODY`, `MAIN_CONFIRM_BODY` satırları (bağlı denetimleri de güncelle); `level_01_training_flow.gd` kapının iç alanlarını değiştirmek yerine `VexDoor` açık metodu kullansın; `furnice`/`furnace` adlandırması (dosya adları değişmez, yalnız oyuncuya dönük metin).
3. **Karar bekliyor — Crucible Warden canı:** "elit/miniboss" ama 260 HP (Basalt Juggernaut 240). Kullanıcıya sor; Warden kampanyada Bölüm 5'te.

## Öğrenilen dersler

- Headless Godot denemelerini scratchpad kopyasında yap (`git ls-files -co --exclude-standard | tar …`), depoya ekleme.
- Denetim başarısız olursa önce `main`'de de başarısız mı bak: eskiden bozuk mu, yeni mi ayırt et.
- Değişiklik denetim sözleşmesini bozuyorsa, oyunun mu testin mi doğru olduğuna karar ver ve doğru tarafı düzelt.
- `@tool` terminal betiklerinde `tr()` kullanımı mevcut kalıp (`terminal_menu.gd`); editör önizlemesinde anahtar görünmesi kabul.
- Push'tan önce `tools/validate.sh` çalıştırmak yeterli: başarılı ve temiz çalışma kopyası ağacı damgalar, pre-push hook'u tekrar çalıştırmaz.
- `tests/__pycache__` commit'e girmesin (artık `.gitignore`'da; `validate.sh` bytecode yazmaz).
