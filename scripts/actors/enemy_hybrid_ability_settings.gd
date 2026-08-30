@tool
class_name VexEnemyHybridAbilitySettings
extends VexEnemyAbilitySettings

@export_category("01 - Yakın Saldırı Seçimi")
## Oyuncu bu mesafeye girdiğinde menzilli saldırı yerine yakın saldırı öncelik kazanır (metre).
@export_range(0.5, 8.0, 0.05) var melee_trigger_range := 2.15
## Yakın saldırının zorluk çarpanından önceki temel hasarıdır.
@export_range(1, 150, 1) var melee_damage := 20
## Yakın saldırı hasarı uygulanmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 2.0, 0.01) var melee_windup := 0.24
## İki yakın saldırı arasındaki temel bekleme süresidir (saniye).
@export_range(0.15, 6.0, 0.05) var melee_cooldown := 0.90
## Hazırlık sırasında oyuncu az miktarda uzaklaşırsa saldırının boşa gitmesini önleyen mesafe payıdır (metre).
@export_range(0.0, 2.0, 0.05) var melee_range_tolerance := 0.40
## Yakın saldırının oyuncuda hedeflediği dikey noktadır (metre).
@export_range(0.0, 2.5, 0.05) var melee_hit_height := 0.75
## Yakın saldırının çevrede oluşturduğu işitilebilir ses şiddetidir.
@export_range(0.0, 2.0, 0.05) var melee_noise_loudness := 0.70
## Açıksa yakın mesafede mermi yerine daima yakın saldırı seçilir.
@export var prefer_melee_when_close := true

@export_category("02 - Yakın Saldırı Görsel Hizası")
## Yakın saldırı animasyon karelerinin dikey zemin hizalama düzeltmeleridir.
@export var attack_close_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
