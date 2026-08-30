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

@export_category("02 - Yönlü Görsel Seçimi")
## Ön görünümün merkezden iki yana kapsadığı yarım açıdır (derece).
@export_range(5.0, 45.0, 0.5) var front_half_angle_degrees := 22.5
## Ön çapraz görünümün yan görünüme geçtiği açı sınırıdır (derece).
@export_range(25.0, 90.0, 0.5) var front_diagonal_limit_degrees := 67.5
## Yan görünümün arka görünüme geçtiği açı sınırıdır (derece).
@export_range(70.0, 160.0, 0.5) var side_limit_degrees := 112.5
## Açıksa sağ/sol yan ve çapraz yönlerden eksik olan taraf yatay aynalama ile otomatik üretilir.
@export var mirror_opposite_directions := true
## Sprite sheet'teki yan ve ön çapraz kaynak karelerin sağa baktığını belirtir; yanlışsa kapatın.
@export var source_frames_face_right := true

@export_category("03 - Yönlü Kare Zemin Hizası")
## Yan boşta animasyon karelerinin dikey zemin hizalama düzeltmeleridir.
@export var idle_side_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## Yan yürüyüş animasyon karelerinin dikey zemin hizalama düzeltmeleridir.
@export var walk_side_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## Ön çapraz boşta animasyon karelerinin dikey zemin hizalama düzeltmeleridir.
@export var idle_front_side_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## Ön çapraz yürüyüş animasyon karelerinin dikey zemin hizalama düzeltmeleridir.
@export var walk_front_side_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## Yakın saldırı animasyon karelerinin dikey zemin hizalama düzeltmeleridir.
@export var attack_close_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
