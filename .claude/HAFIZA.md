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

## Yapılanlar (2026-09, PR #80–#113)

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
- #99 Anahtar olarak metin kullanan 73 çeviri satırı `LABEL_*` kimlik anahtarına taşındı (186 sahne/betik referansı); `finish_switch`/`discovery_notification_overlay` dil yardımcıları da `tr()`'ye geçti. `translation_usage_audit` artık metin anahtarını reddediyor. Açık iş kalmadı.
- #100 Tarama: 5 sahne alanında anahtar yerine düz metin (BAKIM ZIRHI, Bastion silah arşivi terminali, kısıtlı kapı mesajı, OPERATÖR PLATFORMU tabelası, test kapısı) düzeltildi; Bastion giriş mesajı zamanlayıcıları duraklatmaya duyarlı. Bölümler/hub/menü headless açılışta hatasız; kayıt, düşman ölümü, içerik kimlikleri temiz bulundu.
- #101 Oyuncuya hiç görünmeyen 66 eski çeviri satırı silindi (VEX-01/Kırık Omurga/Kül Madeni prototip brifingleri, kullanılmayan eğitim ipuçları, test sahnesine özel etiketler). `tests/translation_reachability.py` yapı kaynaklarında yalnız kurulan kökleri ve sıfırlanmayan kapı alanlarını sayar; test sahneleri sayılmaz.
- #102 Metin cilası: Türkçede İngilizce oyun jargonu (projectile, lunge, charge, pellet…) ve oyuncuya görünen geliştirici dili temizlendi; İngilizcede LEVEL→CHAPTER; arşiv/silah terminallerinde sabit İngilizce etiketler çeviriye bağlandı; ana menü görev paneli ve HUD hedef kutusu taşma/kesilme düzeltildi; silah rafının sahne geçişindeki eski oyuncu referansı hatası giderildi.
- #103 (2026-11-02) Oyuncunun yerde hareket tuşunu bırakınca kayarak durması giderildi: yatay hız anında sıfırlanır; zıplama momentumu, havadaki hareket ve darbe savrulması korunur. Movement runtime testi ve statik audit eklendi. Kaynak sözleşmeleri doğrulandı; Godot bu ortamda bulunmadığından headless/runtime kontrolü yerelde bekliyor.
- #104 (2026-11-02) #103 anlık duruşu fazla sert hissettirdi: yere basarken tuş bırakılınca Inspector ayarlı `ground_stop_deceleration=100` ile yaklaşık 0,1 saniyede yumuşak frenleme; havada önceki yavaşlama ve savrulma önceliği korundu. Hareket testi ve audit güncellendi. Godot çalışma testi yerelde bekliyor.
- #105 (2026-11-02) Oyuncuya görünen `//` metin ayırıcıları; TR/EN görev, başlık, HUD, arşiv, terminal, Bastion kontrol paneli, saha kayıtları, oda tabelaları ve etkileşim etiketlerinde semantik metin, başlık çizgisi (`—`) veya hafif metadata ayırıcısı (`·`) ile değiştirildi. Editör önizleme/denetimler güncellendi; `tests/ui_copy_separator_audit.py` ve `docs/ui_copy_style.md` eklendi. Godot çalışma testi yerelde bekliyor.
- #106 (2026-11-02) Tipografi standardı: tüm ekranlarda regular Segoe UI gövde, semibold başlık/buton, monospace teknik rakam. Bastion-7 8–9 piksellik yazılar 12+ yapıldı, kartlar genişletildi; menü/HUD/arşiv/terminal, sinematik brifing/okuyucu ve 3B tesis tabelaları düzenlendi. `docs/ui_typography.md`, `tests/ui_typography_audit.py`. Godot görsel/runtime kontrolü bekliyor.
- #107 (2026-11-02) #106'daki Godot sahne yükleme hatası: `main_menu.tscn` içinde `ext_resource` satırları `sub_resource` sonrasına eklenmişti. Ana menü, HUD, keşif bildirimi sahnelerinde font kaynakları dosya başına taşındı; `tests/ui_typography_audit.py` tüm sahne/kaynak dosyalarında sıralamayı denetler. Godot çalışma testi bekliyor.
- #108 (2026-11-02) `level_test.gd` üst sınıfı `@tool VexBaseLevel` olduğu hâlde kendisi @tool değildi; `MISSING_TOOL` uyarısı. Çocuğa `@tool` eklendi, editör modunda Loom Herald spawn edilmedi, `super._ready()` preview davranışı korundu. Kalıtım testi (`tests/tool_inheritance_audit.py`) ve Loom Herald audit'i güncellendi. Godot runtime testi yerelde bekliyor.
- #109 (2026-11-05) #103–#108 bu oturumda Godot ile doğrulandı (import + 18 sahne, hareket testi dahil); #106 sonrası kırık kalan bildirim kartı denetimi düzeltildi. Görsel: HUD ikincil etiketleri 12 → 15–16, silah arşivi sayaç kutusu 225 → 400 (tek satır), ana menü sol panel boş şeridi giderildi (yetki etiketine genişlik). Ayarlar ekranı #106 ile zaten düzelmişti. xvfb ekran görüntüleriyle kontrol edildi.
- #110 Kullanıcının bildirdiği `reload_sg04_shells: null::_get_sg04_reload_generation` hatası: doldurma beklerken ölüm/sahne geçişi WeaponController'ı serbest bırakıyordu. `VexWeaponReloadRuntime._is_alive` await sonrası önce canlılığa bakar (düz şarjör dolumundaki ikinci hata da giderildi); runtime testi oyuncuyu doldurma ortasında silerek hatayı yeniden üretir.
- #111 `GameState.player`/`hud` sahne geçişinde serbest kalmış eski düğümü göstermeye devam ediyordu (2. ve 3. bölüm açılışında 19× "Trying to cast a freed object", Cinder Hound `_ready`). Oyuncu ve HUD `_exit_tree`'de `GameState.unregister_*` ile kaydını düşürüyor. `tools/smoke_scene_transitions.gd` duman testi eklendi (5 sahne, ateş/doldur/ölüm/ani geçiş; temiz).
- #112 `tools/smoke_combat.gd`: test alanındaki 18 düşman türünü sırayla gerçek silah yoluyla vurur; saldırı, ölüm ve sayaç ölçülür. Bulgu: isabet efekti (`hit_impact_v1.gd`) VRAM sıkıştırmalı düşman sayfalarından piksel okumaya çalışıp her isabette onlarca hata basıyordu; sıkıştırılmışsa yedek renge geçiyor (görünüm değişmedi). Diğer şüpheler test kaynaklı çıktı (Warden'ı Venom Marshall iyileştiriyor, Gorehorn 500 can).
- #113 Yaratığa göre isabet/kan rengi ilk kez çalışıyor: sıkıştırılmış sayfa ilk isabette `WorkerThreadPool` ile açılıp 1/4 küçük kopya önbelleğe alınır (en fazla 12 sayfa); hazır olana kadar yedek renk. İsabet başına ana iş parçacığı ~0,1–0,5 ms, takılma yok.

## Kararlar (tekrar tartışma)

- Kullanıcı bütün yazıları profesyonel istiyor: kodla oluşturulanlar dahil tema/gövde/başlık/teknik font hiyerarşisi ve okunabilir ölçü; eski 8–9 px etiketlere geri dönme. `docs/ui_typography.md` standardıdır.

- Doku boyutu sorun değil: yalnız Windows/D3D11 (ANGLE), sınır ≥8192 px; en büyük sayfa 5376 px.
- Xeno arşiv keşifleri Yeni Oyun'da sıfırlanmaz — bilinçli (belgede yazılı). Saha kayıtları sıfırlanır.
- Loom Herald yalnız Level Test sandbox prototipi; kampanyada/arşivde yok.
- Ayrılmış çeviri anahtarları (planlı içerik): `HUD_SLOT_05`, `HUD_AMMO_MAGNUM`, `CH02_BYPASS_RESERVED` — silme.
- `furnice_carrier` iç kimliği (dosya/enemy_id) değişmez: arşiv keşfi kayıtta saklanıyor. Oyuncuya görünen ad zaten "FURNACE CARRIER".
- Tesis tabelaları `VEX 01` ve `R03 · SEC` gibi dilden bağımsız kodlardır; bunlar oyuncuya dönük eski VEX-01 prototip bölüm adları değildir. Oyuncuya görünen metinlerde `//` kullanılmaz.
- Ana menünün temel sloganı "BOŞLUĞU YOK ET" / "ERASE THE VOID" ve logo alt yazısı "VOID EXTERMINATION" (VEX adı) korunur; `//` yerine metin hiyerarşisi kullanılır.
- Silah/yetenek özel adları (Thermal Burst, Ground Slam, Heatwave, P-07 Sentinel…) Türkçe metinde İngilizce kalır.
- Can sıralaması: Crucible Warden 400 (miniboss) > Vaskari Bulwark 300 > Basalt Juggernaut 240. Zorluk çarpanları `enemy_base.gd` varsayılanı (×0.75/1/1.2/1.45).

## Açık işler (sırayla)

- Windows'ta `validate_local.ps1` ve gerçek Segoe UI/Cascadia fontlarıyla TR/EN görsel kontrol (Linux'ta fontlar yedek fonta düşüyor; yerleşim ve Godot testleri bu oturumda geçti).

## Öğrenilen dersler

- Godot'ta `@tool` ile çalışan temel GDScript sınıfından miras alan alt betik de `@tool` olmalı; editörde çalışan `_ready()` gibi metotların runtime spawn/oyun mantığı `Engine.is_editor_hint()` ile korunmalı.

- Godot `.tscn` dosyasında `[ext_resource]` kayıtları her zaman `[sub_resource]` ve `[node]` bölümlerinden **önce** olmalı. Sonradan eklenen font kaynaklarını ilk node önüne değil ilk `sub_resource` önüne taşı; `ui_typography_audit.py` kontrolü bunu yakalar.

- Headless Godot denemelerini scratchpad kopyasında yap (`git ls-files -co --exclude-standard | tar …`), depoya ekleme.
- Denetim başarısız olursa önce `main`'de de başarısız mı bak: eskiden bozuk mu, yeni mi ayırt et.
- Değişiklik denetim sözleşmesini bozuyorsa, oyunun mu testin mi doğru olduğuna karar ver ve doğru tarafı düzelt.
- Veri sözlüklerindeki `_tr`/`_en` alan seçimi (`vex_archive_database`, `vex_field_record_database`) çeviri dosyasına taşınmaz; veri kalıbıdır.
- `@tool` terminal betiklerinde `tr()` kullanımı mevcut kalıp (`terminal_menu.gd`); editör önizlemesinde anahtar görünmesi kabul.
- Push'tan önce `tools/validate.sh` çalıştırmak yeterli: başarılı ve temiz çalışma kopyası ağacı damgalar, pre-push hook'u tekrar çalıştırmaz.
- Web konteyneri uzun aradan sonra sıfırlanabilir: commit'lenmemiş iş kaybolur; her adımı hemen commit+push et.
- Yeni çeviri anahtarı daima kimlik biçiminde (`[A-Z][A-Z0-9_]*`); sahnedeki `display_name` vb. alanlara metin değil anahtar yaz.
- `tools/extract_inline_text.py | head` kullanma: boru kırılınca `--apply` yazmadan çıkar.
- `tests/`'teki bazı denetimler `git ls-files` çalıştırır: Godot doğrulama kopyasını `git clone` ile oluştur.
- Çeviri kullanım denetimi `tests/translation_reachability.py` ile ölçülür: `tests/` sahneleri ve `level_0N_structure_source.tscn` kök/sıfırlanan alanları "kullanım" sayılmaz.
- Gerçek ekran görüntüsü: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path <klon> --resolution 1280x720 --rendering-driver opengl3 -s shot.gd` (Mesa llvmpipe çalışıyor); `root.get_viewport().get_texture().get_image().save_png()`.
- Autowrap etiketlere genişlik verilmezse Godot yüksekliği kelime başına satır sayar; paneller şişer. `custom_minimum_size.x` ver.
- Başka oturumlar da `main`'e PR birleştiriyor: işe başlamadan `git fetch` + `git log` ile yeni PR'ları ve HAFIZA değişikliklerini oku; dalı `origin/main`'e eşitle.
- HUD tabanı 1920×1080 (canvas_items); 12 birim 720p'de ~8 px olur. Oyun içi ikincil HUD yazısı için 15–16 kullan.
- Await sonrası düğüm/Callable kullanmadan önce `is_instance_valid` ile bak; serbest kalmış nesneyi tipli parametreye (`owner: Node`) vermek de SCRIPT ERROR üretir; yardımcıda `Variant` kullan.
- Oyun içi hata avı için `godot --headless --path <klon> -s tools/smoke_scene_transitions.gd` çalıştır; `ERROR` satırlarını say. Godot testleri geçse bile gerçek sahne geçişi hataları ancak böyle görünür.
- Yeni `.gd` dosyası eklerken Godot'un ürettiği `.gd.uid` eşini de commit'le (geçici klonda `godot --headless --editor --quit` üretir); `resource_uid_audit` ister.
- Headless testte süreyi kare sayarak ölçme (kare hızı 60'ın çok üstü); `Time.get_ticks_msec()` kullan. Headless'ta fare yakalanamadığı için `WeaponController` tetik girdisini yok sayar; testte `_try_fire()`/`reload()` çağır, nişan için `PlayerViewRuntime._pitch` ve geri tepme alanlarını ayarla.
- `WorkerThreadPool` görevlerinde `Texture.get_image()` ana iş parçacığında alınır; işçi yalnız kendi `Image` kopyasına dokunur. Her görev bir kez `wait_for_task_completion` ile teslim alınmalı.
- `tests/__pycache__` commit'e girmesin (artık `.gitignore`'da; `validate.sh` bytecode yazmaz).
