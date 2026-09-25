# VEX — Claude Code proje notları

Godot **4.7.1** (GL Compatibility, yalnız Windows export) ile 2.5D sprite düşmanlı tek oyunculu FPS. Kullanıcı Türkçe konuşur; yanıtlar Türkçe. Oynanabilir içerik: Bölüm 1–3 + Bastion-7 hub'ı; hikâye 30 bölüm olarak planlı.

## Doğrulama (her değişiklikten sonra)

- `tools/validate.sh` → 107+ Python denetimi paralel, yalnız hataları yazar (~2 dk).
- `tools/validate.sh --godot` → + Godot import, `tests/integrity_test.tscn`, `tests/*_runtime_test.tscn`.
- Web oturumunda Godot'u `.claude/hooks/session-start.sh` kurar (`$GODOT`, `godot` PATH'te). Godot'u elle indirme.
- Windows: `validate_local.ps1` (aynı denetimler).

Denetimler çoğunlukla **metin sözleşmesi**dir (kaynakta belirli satırları arar). Kodu değiştirince ilgili `tests/*_audit.py` sözleşmesini de aynı commit'te güncelle; oyun doğruysa testi, test doğruysa oyunu düzelt. pytest yok: `def test_` içeren denetimler dosya sonundaki `if __name__ == "__main__":` bloğuyla çalışır — yeni denetimde bu bloğu unutma.

## Mimari (nereye bakılır)

- **Bölümler:** `scenes/levels/level_0N.tscn` kabuk sahnesi; fiziksel yapı `level_0N_structure_source.tscn`'den `VexBaseLevel` (`scripts/levels/base_level.gd`) tarafından runtime'da kurulur (yalnız güvenli kökler: Geometry, Doors, RoomLights, Lights, Props…). Oynanış `level_0N_*_content.tscn` (düşman, pickup, kayıt, finish), atmosfer `level_0N_environment_story.tscn`. Structure source'taki eski Enemies/Pickups kökleri **kullanılmaz**. Kapı kilitleri her `level_0N.gd` içindeki `_configure_authored_doors`.
- **Durum/kayıt:** `scripts/autoload/game_state.gd` (kampanya, kayıt, `SAVE_VERSION` + `_migrate_save_state`), `base_manager.gd` (Bastion alanları/aydınlatma), `archive_manager.gd` (xeno keşif — kampanyalar arası kalıcı, bilinçli).
- **Düşmanlar:** `scenes/actors/*.tscn` + `scripts/actors/enemy_*_base.gd`. Can/hız/menzil/kare ofsetleri sahnede (Inspector otoritesi); script'e ikinci tuning değeri yazma.
- **Hub:** `scenes/hub/bastion_7.tscn`, `scripts/hub/`. Görevler `resources/missions/vex0N.tres` (id/scene/stage açıkça yazılı olmalı).
- **Arşiv/lore verisi:** `scripts/data/vex_archive_database.gd` (evren `reveal_stage` ile hikâye bölümüne kadar geçici metin), `vex_field_record_database.gd` (saha kayıtları).
- **Çeviri:** `translations/vex.csv` + `chapter0N.csv` (`keys,tr,en`); runtime'da `SettingsManager` kaydeder. Yeni bölüm metni ilgili `chapter0N.csv`'ye.

## Kanon ve kurallar

- Hikâye/yaratık/silah kaynakları: `Story_VEX.md`, `Enemies_VEX.md`, `Weapons_VEX.md`, `docs/Campaign_Level_Design_VEX.md`, `docs/levels/*.md`. Oyunda olmayan yeteneği belgede "mevcut" yazma; oyuncuya hikâyenin henüz açıklamadığı bilgiyi gösterme.
- Oyuncuya dönük adlar "BÖLÜM 0N // AD"; eski `VEX-01/02/03`, "Kül Madeni", "Kırık Omurga" prototip adlarıdır.
- Oynanış zamanlayıcıları duraklatmaya duyarlı olmalı: `get_tree().create_timer(t, false)`.
- Kayıt formatı anlamı değişirse `SAVE_VERSION` artır ve göç ekle.

## Tuzaklar

- Godot 4.7 sahne başlıklarına `unique_id=` ekler; denetimler bunu normalize eder.
- Editörde açılan `level_0N.tscn` eski child override'larıyla kaydedilebilir (prop'ları duvardan kaydıran geri dönüş yaşandı). `level_0N.tscn` diff'lerini kontrol et; `tests/level_prop_placement_audit.py` yakalar.
- Headless Godot deneme sahneleri `user://` kayıtlarına yazar: geçici kopyada (scratchpad) çalıştır, depoya ekleme.
- `assets/` ~425 MB binary; PNG'leri okumaya/greplemeye çalışma, `*_manifest.json` dosyalarını kullan.
- GitHub Actions kotası yok; CI yerine yerel doğrulama kullanılır.
