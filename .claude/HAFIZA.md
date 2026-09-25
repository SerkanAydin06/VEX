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

## Yapılanlar (2026-09, PR #80–#88)

- #80 Oynanış hataları: Level 2 prop geri dönüşü, düşük can kilidi (yeniden başlama min %50, Bastion'da tam can), pause'a duyarlı düşman/kapı zamanlayıcıları, eski denetimler kanonik bölümlere uyarlandı.
- #81 15 düşmanın kare zemin ofsetleri spritesheet'lere göre yeniden hizalandı (8 mm temas).
- #82 Anlamsız binary boyut denetimi kaldırıldı.
- #83 3. bölüm sonrası tek seferlik ara son ekranı (`VexBaseLevel.shows_campaign_end_screen`, level_03'te açık).
- #84 Hikâye tutarlılığı: arşiv kayıtları kanonik Bölüm 1–3, evren `reveal_stage` ile erken sır açığa çıkmıyor, Leyla Sönmez Bastion'a eklendi (aşamalı replik), belgelerde P-07/P-14/Loom Herald düzeltmeleri.
- #85 Bölüm tamamlanınca Bastion aydınlatması otomatik yükselir (SAVE_VERSION 7 göçü).
- #86 Ara son ekranı "Ana Menü"ye rağmen kayıtta bekler.
- #87 Hiç çalışmayan 25 pytest tarzı denetim (175 test) çalışır hâle getirildi; bölüm yapı kurulumu `VexBaseLevel`'da birleştirildi.
- #88 `CLAUDE.md`, `tools/validate.sh`, Godot kuran session-start hook'u.

## Kararlar (tekrar tartışma)

- Doku boyutu sorun değil: yalnız Windows/D3D11 (ANGLE), sınır ≥8192 px; en büyük sayfa 5376 px.
- Xeno arşiv keşifleri Yeni Oyun'da sıfırlanmaz — bilinçli (belgede yazılı). Saha kayıtları sıfırlanır.
- Loom Herald yalnız Level Test sandbox prototipi; kampanyada/arşivde yok.
- Kullanılmayan eski prototip çeviri satırları henüz silinmedi (açık iş 3).

## Açık işler (sırayla)

1. **Pre-push git hook:** `tools/git-hooks/pre-push` → `tools/validate.sh`; Windows Git Bash uyumlu; `git config core.hooksPath tools/git-hooks`; README.
2. **Koda gömülü metinler:** `scripts/` içindeki ~156 `_t("tr","en")` / `begins_with("tr")` metnini `translations/*.csv` + `tr()`'ye taşı. Önce `scripts/ui/vex_archive_terminal.gd`, dosya dosya ayrı PR.
3. **Temizlik:** kullanılmayan `LEVEL0x_*`, `HUB_VEX0x_*`, `SURVIVOR_SELIN_DIALOGUE_STAGE2/3`, `TERMINAL_FACILITY_ASH_MINE`, `MAIN_CREDITS_BODY`, `MAIN_CONFIRM_BODY` satırları (bağlı denetimleri de güncelle); `level_01_training_flow.gd` kapının iç alanlarını değiştirmek yerine `VexDoor` açık metodu kullansın; `furnice`/`furnace` adlandırması (dosya adları değişmez, yalnız oyuncuya dönük metin).
4. **Karar bekliyor — Crucible Warden canı:** "elit/miniboss" ama 260 HP (Basalt Juggernaut 240). Kullanıcıya sor; Warden kampanyada Bölüm 5'te.

## Öğrenilen dersler

- Headless Godot denemelerini scratchpad kopyasında yap (`git ls-files -co --exclude-standard | tar …`), depoya ekleme.
- Denetim başarısız olursa önce `main`'de de başarısız mı bak: eskiden bozuk mu, yeni mi ayırt et.
- Değişiklik denetim sözleşmesini bozuyorsa, oyunun mu testin mi doğru olduğuna karar ver ve doğru tarafı düzelt.
- `tests/__pycache__` commit'e girmesin (artık `.gitignore`'da; `validate.sh` bytecode yazmaz).
