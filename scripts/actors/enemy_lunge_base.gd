class_name VexEnemyLungeBase
extends "res://scripts/actors/enemy_base.gd"

@export_category("01 - Kimlik, Can ve Zorluk")
## Kayıt ve yenilgi takibinde kullanılan benzersiz yaratık kimliğidir.
@export var enemy_id: StringName = &"enemy"
## Savaş mesafesi rolüdür: Yakın, Orta veya Uzak.
@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.CLOSE
## Zorluk çarpanı uygulanmadan önceki temel can değeridir.
@export_range(1, 1000, 1) var maximum_health := 90
## Yaratığın doğabileceği en düşük zorluk seviyesidir; 0 tüm seviyelerdir.
@export_range(0, 3, 1) var spawn_min_difficulty := 0
## Açıksa sahnedeki zorluk çarpanları cana, hasara, hıza, algılamaya ve saldırı sürelerine uygulanır.
@export var apply_difficulty_scaling := true

@export_category("01B - Zorluk Çarpanları (Sahne)")
## zorluk can çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_health_multipliers := PackedFloat32Array([0.75, 1.0, 1.20, 1.45])
## zorluk hasar çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_damage_multipliers := PackedFloat32Array([0.65, 1.0, 1.25, 1.55])
## zorluk hız çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_speed_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.15])
## zorluk algılama çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_detection_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.20])
## zorluk bekleme çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_cooldown_multipliers := PackedFloat32Array([1.25, 1.0, 0.85, 0.70])
## zorluk hazırlık çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_windup_multipliers := PackedFloat32Array([1.20, 1.0, 0.90, 0.75])

@export_category("02 - Hareket ve Sabit Bekleme")
## Alarmdan sonra hedefe yaklaşırken kullanılan normal hareket hızıdır (metre/saniye).
@export_range(0.5, 10.0, 0.1) var move_speed := 2.35
## Oyuncu takip edilirken kullanılan hızdır (metre/saniye); Combatant ailesinde 0 normal hızı kullanır.
@export_range(0.5, 16.0, 0.1) var chase_speed := 5.8
## Yaratığın hedef hareket hızına ulaşma ivmesidir.
@export_range(0.5, 40.0, 0.5) var movement_acceleration := 12.0
## Durma ve yön değiştirme sırasında kullanılan yavaşlama ivmesidir.
@export_range(0.5, 40.0, 0.5) var braking_acceleration := 12.0
## Projenin yerçekimine uygulanan çarpandır; 0 yerçekimini kapatır.
@export_range(0.0, 4.0, 0.05) var gravity_scale := 1.0
## Eğimlerde gövdeyi zemine bağlı tutan aşağı yönlü hızdır.
@export_range(-5.0, 0.0, 0.05) var floor_stick_velocity := -0.1
## zemin çarpışma katmanları kontrolünde dikkate alınacak fizik katmanlarıdır.
@export_flags_3d_physics var floor_collision_mask := 1
## Yaratığın zemin oturtma en yüksek düzeltme mesafesi ayarını belirler.
@export_range(0.1, 5.0, 0.1) var floor_snap_max_correction := 2.0
## zemin oturtma ışın başlangıç yükseklik değeridir (metre).
@export_range(0.0, 2.0, 0.05) var floor_snap_ray_start_height := 0.5
## Yaratığın zemin oturtma ışın ek derinlik ayarını belirler.
@export_range(0.0, 4.0, 0.1) var floor_snap_ray_extra_depth := 2.0
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var patrol_offset := Vector3(2.0, 0.0, 0.0)
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var patrol_pause_duration := 0.65
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_wander_radius := 2.8
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_wander_attempts := 12
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_wander_min_radius_ratio := 0.35
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_pause_min := 0.35
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_pause_max := 0.95
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_turn_speed := 0.32
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_target_min_distance := 0.25
@export_category("03 - Algılama ve Takip")
## Oyuncunun ilk kez algılanabileceği azami yatay mesafedir (metre).
@export_range(1.0, 50.0, 0.5) var detection_range := 30.0
## Takip başladıktan sonra kovalamaya devam edilen azami mesafedir (metre).
@export_range(5.0, 60.0, 0.5) var pursuit_range := 38.0
## İlk algılamada kullanılan yatay görüş açısıdır (derece); 360 tam çevredir.
@export_range(30.0, 360.0, 5.0) var initial_view_angle := 360.0
## Görüş kesildikten sonra doğrudan takibin sürdürüleceği süredir (saniye).
@export_range(1.0, 30.0, 0.5) var lost_sight_timeout := 20.0
## Oyuncu kaybedildiğinde arama durumunda kalınacak süredir (saniye).
@export_range(1.0, 20.0, 0.5) var search_duration := 10.0
## arama yoklama yarıçap değeridir (metre).
@export_range(0.5, 5.0, 0.1) var search_probe_radius := 2.0
## Uyarıyı alabilecek müttefiklerin yarıçapıdır (metre).
@export_range(2.0, 20.0, 0.5) var ally_alert_radius := 9.0
## görüş başlangıç yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var sight_origin_height := 0.65
## görüş hedef yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var sight_target_height := 0.45
## Görüş ışınlarını engelleyebilecek fizik katmanlarıdır.
@export_flags_3d_physics var sight_collision_mask := 1 | 2
## Çömelmiş oyuncunun normal mesafede algılanma olasılığıdır.
@export_range(0.0, 1.0, 0.05) var crouch_detection_chance := 0.45
## Çömelmiş oyuncunun kesin algılanacağı mesafedir (metre).
@export_range(0.5, 5.0, 0.25) var crouch_guaranteed_detection_distance := 3.0
## Açıksa yaratık hasar aldığında saldırgan duruma geçer.
@export var aggro_on_damage := true
## Açıksa oyuncu görüldüğünde yakındaki müttefikler uyarılır.
@export var alert_allies_on_detection := true
## Açıksa hasar alındığında yakındaki müttefikler uyarılır.
@export var alert_allies_on_damage := true
## hasar tepki menzil değeridir (metre).
@export_range(1.0, 120.0, 1.0) var damage_reaction_range := 80.0
## hasar tepki süre değeridir (saniye).
@export_range(1.0, 30.0, 0.5) var damage_reaction_duration := 12.0
## Yaratığın hasar takip en düşük ilerleme ayarını belirler.
@export_range(0.01, 1.0, 0.01) var damage_pursuit_min_progress := 0.20
## hasar takip tıkanma timeout değeridir (saniye).
@export_range(0.1, 10.0, 0.1) var damage_pursuit_stall_timeout := 3.0
## hasar takip kararlılık süre değeridir (saniye).
@export_range(0.0, 2.0, 0.01) var damage_pursuit_commit_time := 0.12
@export_category("03B - İşitme / Stealth")
## Ses olaylarının duyulabileceği temel yarıçaptır (metre).
@export_range(2.0, 40.0, 0.5) var hearing_radius := 16.0
## Ses yüksekliğine uygulanan çarpandır; yükseldikçe işitme menzili artar.
@export_range(0.1, 2.0, 0.05) var hearing_loudness_scale := 1.0
## ses engeli çarpışma katmanları kontrolünde dikkate alınacak fizik katmanlarıdır.
@export_flags_3d_physics var acoustic_collision_mask := 1
## ses engeli yoklama yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var acoustic_probe_height := 0.8
## Doğrudan alarm oluşturacak en düşük ses yüksekliğidir.
@export_range(0.0, 2.0, 0.05) var loud_noise_alert_threshold := 0.9
## kafa vuruşu yükseklik oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.1, 1.0, 0.05) var headshot_height_ratio := 0.62
## kafa vuruşu referans yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var headshot_reference_height := 0.95
## Açıksa diğer düşmanlardan gelen uyarılar kabul edilir.
@export var receive_ally_alerts := true

@export_category("03C - Görüş ve Arama Örnekleme")
## görünürlük dikey örnekleme açıklığı çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.1, 1.0, 0.05) var visibility_vertical_span_scale := 0.55
## Yaratığın görünürlük dikey örnekleme açıklığı en düşük ayarını belirler.
@export_range(0.0, 1.0, 0.05) var visibility_vertical_span_min := 0.20
## Yaratığın görünürlük dikey örnekleme açıklığı en yüksek ayarını belirler.
@export_range(0.0, 2.0, 0.05) var visibility_vertical_span_max := 0.68
## görünürlük yan örnekleme açıklığı çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.1, 1.0, 0.05) var visibility_lateral_span_scale := 0.82
## Yaratığın görünürlük yan örnekleme açıklığı en düşük ayarını belirler.
@export_range(0.0, 1.0, 0.05) var visibility_lateral_span_min := 0.15
## Yaratığın görünürlük yan örnekleme açıklığı en yüksek ayarını belirler.
@export_range(0.0, 1.0, 0.05) var visibility_lateral_span_max := 0.38
## görünürlük omuz yükseklik oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.01) var visibility_shoulder_height_ratio := 0.08
## görünürlük alt gövde oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.05) var visibility_lower_body_ratio := 0.45
## çömelmiş hedef yükseklik çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.5, 0.05) var crouched_target_height_scale := 0.50
## çömelmiş hedef en düşük yükseklik değeridir (metre).
@export_range(-1.0, 1.0, 0.05) var crouched_target_min_height := -0.20
## arama yoklama çapraz ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 2.0, 0.05) var search_probe_diagonal_weight := 0.85

@export_category("04 - Saldırı")
## Normal saldırının başlatılabildiği yatay mesafedir (metre).
@export_range(0.5, 16.0, 0.05) var attack_range := 1.45
## Normal saldırının zorluk çarpanından önceki temel hasarıdır.
@export_range(1, 100, 1) var attack_damage := 10
## İki normal saldırı arasındaki temel bekleme süresidir (saniye).
@export_range(0.3, 3.0, 0.05) var attack_cooldown := 1.0
## Hasar veya mermi çıkmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 1.0, 0.01) var attack_windup := 0.28
## Yaratığın saldırı menzil tolerans ayarını belirler.
@export_range(0.0, 2.0, 0.05) var attack_range_tolerance := 0.45
## saldırı atılma hız değeridir (metre/saniye).
@export_range(0.0, 16.0, 0.1) var attack_lunge_speed := 7.5
## Yaratığın saldırı atılma ivme ayarını belirler.
@export_range(0.0, 80.0, 0.5) var attack_lunge_acceleration := 36.0
## saldırı atılma süre değeridir (saniye).
@export_range(0.0, 1.0, 0.01) var attack_lunge_duration := 0.28
## saldırı atılma durma mesafe değeridir (metre).
@export_range(0.2, 2.0, 0.05) var attack_lunge_stop_distance := 1.2

@export_category("05 - Yol Bulma")
## devriye ulaşma mesafe değeridir (metre).
@export_range(0.1, 1.5, 0.05) var patrol_reach_distance := 0.35
## araştırma ulaşma mesafe değeridir (metre).
@export_range(0.1, 2.0, 0.05) var investigation_reach_distance := 0.55
## sapma süre değeridir (saniye).
@export_range(0.0, 3.0, 0.05) var detour_duration := 0.55
## navigation boşluk değeridir (metre).
@export_range(0.3, 1.2, 0.05) var navigation_clearance := 0.55
## Yol bulma ve engel kontrollerinde kullanılan fizik katmanlarıdır.
@export_flags_3d_physics var navigation_collision_mask := 1 | 8
## rota yenileme aralığı değeridir (saniye).
@export_range(0.1, 1.0, 0.05) var path_refresh_interval := 0.30
## rota hedef değişim mesafe değeridir (metre).
@export_range(0.1, 5.0, 0.1) var path_target_change_distance := 1.20
## Yaratığın çalışma anı ızgara adım ayarını belirler.
@export_range(0.6, 2.0, 0.05) var runtime_grid_step := 0.78
## Çalışma anı yol bulma ızgarasının kullanabileceği en fazla düğüm sayısıdır.
@export_range(200, 6000, 100) var runtime_grid_max_nodes := 2600
## çalışma anı ızgara arama pay değeridir (metre).
@export_range(4.0, 30.0, 0.5) var runtime_grid_search_margin := 18.0
## wall normal y eşik ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.05) var wall_normal_y_threshold := 0.55

@export_category("06 - Performans")
## yakın görüş aralığı değeridir (saniye).
@export_range(0.02, 1.0, 0.01) var near_sight_interval := 0.08
## uzak görüş aralığı değeridir (saniye).
@export_range(0.05, 1.0, 0.01) var far_sight_interval := 0.20
## Oyuncu bundan uzaktayken pahalı AI işlemlerinin uykuya alınacağı mesafedir (metre).
@export_range(12.0, 80.0, 1.0) var dormant_distance := 44.0

@export_category("07 - Görsel ve Animasyon")
## arka görüş eşik ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(-1.0, 1.0, 0.05) var back_view_threshold := -0.15
## Açıksa hasar alan yaratığın görseline kısa ve hafif bir sarsıntı uygulanır.
@export var hurt_shake_enabled := true
## Hasar sarsıntısının toplam süresidir (saniye); saldırı ve hareketi durdurmaz.
@export_range(0.02, 0.3, 0.01) var hurt_shake_duration := 0.08
## Sarsıntının sprite üzerindeki en yüksek uzaklığıdır (piksel).
@export_range(0.0, 8.0, 0.25) var hurt_shake_amount_pixels := 2.0
## Sarsıntının saniyedeki titreşim hızıdır.
@export_range(4.0, 60.0, 1.0) var hurt_shake_frequency := 32.0
## Yaratığın ceset görsel y ayarını belirler.
@export_range(-2.0, 2.0, 0.01) var corpse_visual_y := 0.4032225
## ölüm oturma süre değeridir (saniye).
@export_range(0.0, 3.0, 0.05) var death_settle_duration := 0.55
## ceset kalma süre değeridir (saniye).
@export_range(0.0, 4.0, 0.05) var corpse_hold_duration := 2.2
## ceset zemin boşluk değeridir (metre).
@export_range(0.005, 0.1, 0.005) var corpse_floor_clearance := 0.02
## boşta kare y dikey düzeltmeleri; her eleman aynı sıradaki animasyon karesinin zemin hizasını düzeltir.
@export var idle_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## boşta arka kare y dikey düzeltmeleri; her eleman aynı sıradaki animasyon karesinin zemin hizasını düzeltir.
@export var idle_back_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## yürüme kare y dikey düzeltmeleri; her eleman aynı sıradaki animasyon karesinin zemin hizasını düzeltir.
@export var walk_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## yürüme arka kare y dikey düzeltmeleri; her eleman aynı sıradaki animasyon karesinin zemin hizasını düzeltir.
@export var walk_back_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## saldırı kare y dikey düzeltmeleri; her eleman aynı sıradaki animasyon karesinin zemin hizasını düzeltir.
@export var attack_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## ölüm kare y dikey düzeltmeleri; her eleman aynı sıradaki animasyon karesinin zemin hizasını düzeltir.
@export var death_frame_y_offsets := PackedFloat32Array([0.0, -0.008, -0.016, -0.024])

@export_category("08 - Ölüm Sonrası İz")
## Yanarak ölen yaratığın yerine üretilecek kalıntı sahnesidir.
@export var burn_remains_scene: PackedScene
## yanık kalıntı çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.4, 3.0, 0.05) var burn_remains_scale := 1.0
## yanık kalıntı çarpan çarpanı ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.1, 2.0, 0.01) var burn_remains_scale_multiplier := 1.0
## yanık kömür rengi değeridir.
@export var burn_scorch_tint := Color(0.44, 0.04, 0.04, 0.95)
## yanık köz rengi değeridir.
@export var burn_ember_tint := Color(0.78, 0.10, 0.10, 0.34)
## Yaratığın yanık köz yayım enerjisi ayarını belirler.
@export_range(0.0, 2.0, 0.01) var burn_ember_emission_energy := 0.14
## Açıksa yanık kalıntı üzerinde duman efekti oluşturulur.
@export var burn_smoke_enabled := false
## yanık duman süre değeridir (saniye).
@export_range(0.0, 20.0, 0.1) var burn_smoke_duration := 8.5
## Yaratığın yanık duman saydamlık ayarını belirler.
@export_range(0.0, 1.0, 0.01) var burn_smoke_alpha := 0.14

@export_category("09 - Özel Yetenekler")
## Bu yaratığa özgü saldırı ayarlarını içerir; kaynağı genişleterek alt alanları düzenleyin.
@export var special_ability_settings: VexEnemyAbilitySettings

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

var health := 0
var _spawn_position := Vector3.ZERO
var _gravity := 20.0
var _dead := false
var _player: Node3D = null
var _attack_locked := false
var _aggro := false
var _lost_sight_remaining := 0.0
var _search_remaining := 0.0
var _search_probe_index := 0
var _search_probe_target := Vector3.ZERO
var _has_search_probe := false
var _damage_reaction_remaining := 0.0
var _forced_damage_target := Vector3.ZERO
var _has_forced_damage_target := false
var _forced_damage_best_distance := INF
var _forced_damage_stall_remaining := 0.0
var _forced_damage_commit_remaining := 0.0
var _last_seen_position := Vector3.ZERO
var _facing_direction := Vector3.FORWARD
var _detour_direction := Vector3.ZERO
var _detour_remaining := 0.0
var _movement_target := Vector3.ZERO
var _navigation_path := PackedVector3Array()
var _navigation_path_index := 0
var _navigation_target := Vector3.ZERO
var _has_navigation_target := false
var _navigation_refresh_remaining := 0.0
var _attack_generation := 0
var _attack_lunge_remaining := 0.0
var _base_sprite_modulate := Color.WHITE
var _runtime_maximum_health := 1
var _runtime_move_speed := 0.5
var _runtime_chase_speed := 0.5
var _runtime_detection_range := 1.0
var _runtime_pursuit_range := 1.0
var _runtime_attack_damage := 1
var _runtime_attack_cooldown := 1.0
var _runtime_attack_windup := 0.1
var _runtime_attack_lunge_speed := 0.0
var _sight_check_remaining := 0.0
var _path_refresh_remaining := 0.0
var _cached_player_visible := false
var _dormant_active := false
var _burn_remains: Node3D = null
var _visual_base_y := 0.0


func get_behavior_family() -> StringName:
	return &"lunge"


func _ready() -> void:
	_base_sprite_modulate = animated_sprite.modulate
	_visual_base_y = animated_sprite.position.y
	if not animated_sprite.frame_changed.is_connected(_on_visual_frame_changed):
		animated_sprite.frame_changed.connect(_on_visual_frame_changed)
	_apply_frame_ground_offset()
	# Editörde de RedViper görünsün ve idle animasyonu oynasın.
	# AI, GameState ve devriye kodları editör modunda çalıştırılmaz.
	if Engine.is_editor_hint():
		_play_animation(&"idle")
		return

	if GameState.active_difficulty < spawn_min_difficulty:
		queue_free()
		return

	add_to_group("enemy")
	add_to_group("damageable")
	if not GameState.noise_emitted.is_connected(_on_noise_emitted):
		GameState.noise_emitted.connect(_on_noise_emitted)
	_configure_runtime_stats()
	health = _runtime_maximum_health
	_spawn_position = global_position
	_player = GameState.player as Node3D
	_gravity = (
		float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
		* gravity_scale
	)
	_snap_body_to_floor(floor_snap_max_correction)

	if GameState.was_enemy_defeated(enemy_id):
		_restore_defeated_state()
		return

	# Çok sayıdaki Viper aynı fizik karesinde görüş ışını atmasın.
	_sight_check_remaining = randf_range(0.0, near_sight_interval)
	_play_animation(&"idle")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _dead:
		return
	_update_damage_shake(animated_sprite, delta, hurt_shake_frequency)

	if _player == null or not is_instance_valid(_player):
		_player = GameState.player as Node3D
	_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)
	_forced_damage_commit_remaining = maxf(0.0, _forced_damage_commit_remaining - delta)
	_navigation_refresh_remaining = maxf(0.0, _navigation_refresh_remaining - delta)

	if _should_use_dormant_mode():
		_enter_dormant_mode()
		_apply_dormant_physics(delta)
		return
	_exit_dormant_mode()

	_apply_gravity(delta)
	_detour_remaining = maxf(0.0, _detour_remaining - delta)

	# Başlamış saldırı hasar tepkisinden önceliklidir; vurulmak hamleyi veya
	# saldırı zamanlayıcısını kesmez.
	if _attack_locked:
		_update_attack_lunge(delta)
		move_and_slide()
		return

	# Saldırı yokken hasar kaynağına ulaş veya en yakın erişilebilir noktaya ilerle.
	if _has_forced_damage_target:
		if _can_handoff_damage_pursuit_to_combat():
			_has_forced_damage_target = false
			_damage_reaction_remaining = 0.0
			_forced_damage_stall_remaining = 0.0
			_reset_navigation_path()
		else:
			var forced_distance := _horizontal_distance(global_position, _forced_damage_target)
			if forced_distance < _forced_damage_best_distance - damage_pursuit_min_progress:
				_forced_damage_best_distance = forced_distance
				_forced_damage_stall_remaining = damage_pursuit_stall_timeout
			else:
				_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)
			if EnemyNavigationRuntime.has_reached_walkable_target(
				self,
				_forced_damage_target,
				investigation_reach_distance,
				navigation_collision_mask,
				floor_collision_mask,
				navigation_clearance,
				floor_snap_ray_start_height,
				floor_snap_ray_extra_depth
			):
				_has_forced_damage_target = false
				_damage_reaction_remaining = 0.0
				_last_seen_position = _forced_damage_target
				_search_remaining = search_duration
				_reset_search_probe()
			else:
				_chase_position(delta, _forced_damage_target)
				move_and_slide()
				_update_chase_detour()
				if (
					_forced_damage_stall_remaining <= 0.0
					and (_navigation_path.is_empty() or _navigation_path_index >= _navigation_path.size())
				):
					_has_forced_damage_target = false
					_damage_reaction_remaining = 0.0
					_last_seen_position = _forced_damage_target
					_search_remaining = search_duration
					_reset_search_probe()
			return

	if _player != null and is_instance_valid(_player):
		var player_distance: float = _horizontal_distance(
			global_position,
			_player.global_position
		)
		var active_sight_range: float = (
			_runtime_pursuit_range
			if _aggro
			else _runtime_detection_range
		)
		if _damage_reaction_remaining > 0.0:
			active_sight_range = maxf(active_sight_range, damage_reaction_range)
		var can_see_player := _get_cached_player_visibility(
			delta,
			player_distance,
			active_sight_range
		)
		# Yakın dövüşçü oyuncunun dibindeyken cache yüzünden saldırı kaçıramaz.
		if (
			combat_role == EnemyCombatProfiles.Role.CLOSE
			and player_distance <= attack_range + attack_range_tolerance
		):
			can_see_player = _check_line_of_sight()
			_cached_player_visible = can_see_player
			if can_see_player:
				_sight_check_remaining = near_sight_interval

		# İlk algılama ve alarm sonrası takip menzilleri sahne kökünden bağımsız
		# olarak ayarlanır.
		if can_see_player and player_distance <= active_sight_range:
			var was_aggro := _aggro
			_aggro = true
			_last_seen_position = _player.global_position
			_lost_sight_remaining = lost_sight_timeout
			_search_remaining = search_duration
			_reset_search_probe()
			if not was_aggro and alert_allies_on_detection:
				_alert_nearby_allies(_last_seen_position)

			if player_distance <= attack_range:
				_face_player()
				_attempt_attack()
				move_and_slide()
				return

			_chase_position(delta, _player.global_position)
			move_and_slide()
			_update_chase_detour()
			return

		# Görüş kesilince son görülen noktaya kadar kovala. Noktaya ulaşıldığında
		# kalan hafıza süresini boşta beklemek yerine aktif köşe/yan aramasına geçir.
		if _aggro and _lost_sight_remaining > 0.0:
			_lost_sight_remaining = maxf(0.0, _lost_sight_remaining - delta)
			if _horizontal_distance(global_position, _last_seen_position) > investigation_reach_distance:
				_chase_position(delta, _last_seen_position)
				move_and_slide()
				_update_chase_detour()
				return
			_lost_sight_remaining = 0.0

		if _aggro and _search_remaining > 0.0:
			_search_remaining = maxf(0.0, _search_remaining - delta)
			_investigate_last_seen(delta)
			move_and_slide()
			_update_chase_detour()
			return


		if _aggro:
			_aggro = false
			_cached_player_visible = false
			_sight_check_remaining = 0.0
			_lost_sight_remaining = 0.0
			_search_remaining = 0.0
			_reset_search_probe()
			_reset_navigation_path()

	_hold_idle_position(delta)
	return


func _hold_idle_position(delta: float) -> void:
	# Alarm öncesinde rota üretme, dönme veya sahne başlangıcından uzaklaşma yoktur.
	velocity.x = move_toward(velocity.x, 0.0, delta * braking_acceleration)
	velocity.z = move_toward(velocity.z, 0.0, delta * braking_acceleration)
	_reset_navigation_path()
	_play_animation(&"idle")
	move_and_slide()


func _chase_position(delta: float, target_position: Vector3, use_chase_speed: bool = true) -> void:
	var resolved_target := _resolve_enemy_door_step(target_position)
	resolved_target.y = global_position.y
	_movement_target = resolved_target

	var target_changed := (
		not _has_navigation_target
		or _horizontal_distance(_navigation_target, resolved_target) > path_target_change_distance
	)
	if _navigation_refresh_remaining <= 0.0 or target_changed:
		_navigation_path = EnemyNavigationRuntime.build_shortest_path(
			self,
			resolved_target,
			navigation_collision_mask,
			floor_collision_mask,
			navigation_clearance,
			floor_snap_ray_start_height,
			floor_snap_ray_extra_depth,
			runtime_grid_step,
			runtime_grid_max_nodes,
			runtime_grid_search_margin
		)
		_navigation_path_index = 1 if _navigation_path.size() > 1 else 0
		_navigation_target = resolved_target
		_has_navigation_target = true
		_navigation_refresh_remaining = path_refresh_interval

	while (
		_navigation_path_index < _navigation_path.size()
		and EnemyNavigationRuntime.has_reached_walkable_target(
			self,
			_navigation_path[_navigation_path_index],
			investigation_reach_distance,
			navigation_collision_mask,
			floor_collision_mask,
			navigation_clearance,
			floor_snap_ray_start_height,
			floor_snap_ray_extra_depth
		)
	):
		_navigation_path_index += 1

	var movement_point := resolved_target
	if _navigation_path_index < _navigation_path.size():
		movement_point = _navigation_path[_navigation_path_index]

	var direction: Vector3 = movement_point - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		_play_animation(&"idle")
		return
	direction = direction.normalized()

	# Collision tangent is now only a fallback when the shared global path is
	# temporarily obstructed by a moving body/door.
	if _detour_remaining > 0.0 and _detour_direction.length_squared() > 0.001:
		direction = _detour_direction

	_facing_direction = direction
	var desired_speed := _runtime_chase_speed if use_chase_speed else _runtime_move_speed
	velocity.x = move_toward(
		velocity.x,
		direction.x * desired_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * desired_speed,
		delta * movement_acceleration
	)
	rotation.y = atan2(-direction.x, -direction.z)
	_play_animation(&"walk")


func _reset_navigation_path() -> void:
	_navigation_path = PackedVector3Array()
	_navigation_path_index = 0
	_has_navigation_target = false
	_navigation_refresh_remaining = 0.0


func _update_chase_detour() -> void:
	for collision_index: int in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var normal := collision.get_normal()
		if absf(normal.y) >= wall_normal_y_threshold:
			continue
		normal.y = 0.0
		if normal.length_squared() <= 0.001:
			continue
		normal = normal.normalized()
		var tangent_a := Vector3(-normal.z, 0.0, normal.x)
		var tangent_b: Vector3 = -tangent_a
		var target_direction := _movement_target - global_position
		target_direction.y = 0.0
		if target_direction.length_squared() > 0.001:
			target_direction = target_direction.normalized()
		_detour_direction = (
			tangent_a
			if tangent_a.dot(target_direction) >= tangent_b.dot(target_direction)
			else tangent_b
		)
		_detour_remaining = detour_duration
		return


func is_pursuing_player() -> bool:
	return not _dead and _aggro


func _resolve_enemy_door_step(target_position: Vector3) -> Vector3:
	return EnemyNavigationRuntime.resolve_enemy_door_step(
		self,
		target_position,
		navigation_clearance,
		investigation_reach_distance
	)

func _face_position(target_position: Vector3) -> void:
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		_facing_direction = direction
		rotation.y = atan2(-direction.x, -direction.z)


func _face_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_face_position(_player.global_position)


func _reset_search_probe() -> void:
	_search_probe_index = 0
	_search_probe_target = Vector3.ZERO
	_has_search_probe = false


func _advance_search_probe() -> void:
	_search_probe_target = VexEnemyRuntimeUtils.investigation_probe(
		_last_seen_position,
		_facing_direction,
		_search_probe_index,
		search_probe_radius,
		search_probe_diagonal_weight
	)
	_search_probe_target.y = global_position.y
	_search_probe_index += 1
	_has_search_probe = true
	_detour_remaining = 0.0


func _investigate_last_seen(delta: float) -> void:
	if (
		not _has_search_probe
		or _horizontal_distance(global_position, _search_probe_target) <= investigation_reach_distance
	):
		_advance_search_probe()
	_chase_position(delta, _search_probe_target)


func _is_player_inside_initial_view() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if initial_view_angle >= 359.9:
		return true
	var player_direction := _player.global_position - global_position
	player_direction.y = 0.0
	if player_direction.length_squared() <= 0.001:
		return true
	player_direction = player_direction.normalized()
	var view_threshold := cos(deg_to_rad(initial_view_angle * 0.5))
	return _facing_direction.dot(player_direction) >= view_threshold


func _check_line_of_sight() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var origin := global_position + Vector3.UP * sight_origin_height
	if not VexEnemyRuntimeUtils.has_visual_contact(
		get_world_3d(),
		origin,
		_player,
		sight_collision_mask,
		get_rid(),
		sight_target_height,
		visibility_vertical_span_scale,
		visibility_vertical_span_min,
		visibility_vertical_span_max,
		visibility_lateral_span_scale,
		visibility_lateral_span_min,
		visibility_lateral_span_max,
		visibility_shoulder_height_ratio,
		visibility_lower_body_ratio
	):
		return false

	var player_distance := _horizontal_distance(global_position, _player.global_position)
	if (
		not _aggro
		and _player.get("is_crouching") == true
		and player_distance > crouch_guaranteed_detection_distance
	):
		return randf() <= crouch_detection_chance
	return true


func _get_crouched_sight_target_height() -> float:
	var shape_node := _player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule != null:
			var top_height := shape_node.position.y + (capsule.height * 0.5)
			return clampf(
				top_height * crouched_target_height_scale,
				crouched_target_min_height,
				sight_target_height
			)
	return 0.0


func _is_player_collider(collider: Node) -> bool:
	if collider == null:
		return false
	if collider == _player:
		return true
	return collider.get_parent() == _player


func _get_cached_player_visibility(
	delta: float,
	player_distance: float,
	active_sight_range: float
) -> bool:
	_sight_check_remaining = maxf(_sight_check_remaining - delta, 0.0)
	if player_distance > active_sight_range:
		_cached_player_visible = false
		return false
	if _sight_check_remaining > 0.0:
		return _cached_player_visible

	_sight_check_remaining = (
		far_sight_interval
		if _aggro and player_distance > _runtime_detection_range
		else near_sight_interval
	)
	_cached_player_visible = (
		_check_line_of_sight()
		and (_aggro or _is_player_inside_initial_view())
	)
	return _cached_player_visible


func _can_handoff_damage_pursuit_to_combat() -> bool:
	if _forced_damage_commit_remaining > 0.0:
		return false
	if _player == null or not is_instance_valid(_player):
		return false
	if _horizontal_distance(global_position, _player.global_position) > attack_range + attack_range_tolerance:
		return false
	if not _check_line_of_sight():
		return false
	_aggro = true
	_cached_player_visible = true
	_sight_check_remaining = near_sight_interval
	_last_seen_position = _player.global_position
	_last_seen_position.y = global_position.y
	_lost_sight_remaining = lost_sight_timeout
	_search_remaining = search_duration
	return true


func _update_attack_lunge(delta: float) -> void:
	if (
		_attack_lunge_remaining <= 0.0
		or _runtime_attack_lunge_speed <= 0.0
		or _player == null
		or not is_instance_valid(_player)
	):
		_attack_lunge_remaining = 0.0
		velocity.x = move_toward(velocity.x, 0.0, delta * braking_acceleration)
		velocity.z = move_toward(velocity.z, 0.0, delta * braking_acceleration)
		return

	_attack_lunge_remaining = maxf(0.0, _attack_lunge_remaining - delta)
	var direction := _player.global_position - global_position
	direction.y = 0.0
	var distance := direction.length()
	if distance <= attack_lunge_stop_distance or distance <= 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_face_position(_player.global_position)
	direction /= distance
	velocity.x = move_toward(
		velocity.x,
		direction.x * _runtime_attack_lunge_speed,
		delta * attack_lunge_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * _runtime_attack_lunge_speed,
		delta * attack_lunge_acceleration
	)


func _attempt_attack() -> void:
	if _attack_locked or _dead:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _horizontal_distance(global_position, _player.global_position) > attack_range:
		return
	if not _check_line_of_sight():
		return

	_attack_generation += 1
	var attack_generation := _attack_generation
	_attack_locked = true
	_attack_lunge_remaining = minf(
		attack_lunge_duration,
		_runtime_attack_windup
	)
	_play_animation(&"attack")
	if attack_audio.stream != null:
		attack_audio.play()

	# 8 FPS'lik 4 kare saldırının 3. karesine yaklaşırken darbe uygulanır.
	await get_tree().create_timer(_runtime_attack_windup).timeout
	if not is_inside_tree() or _dead or attack_generation != _attack_generation:
		return
	_attack_lunge_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0

	if _player != null and is_instance_valid(_player):
		var still_in_range: bool = (
			_horizontal_distance(global_position, _player.global_position)
			<= attack_range + attack_range_tolerance
		)
		if still_in_range and _check_line_of_sight() and _player.has_method("take_damage"):
			_player.call("take_damage", _runtime_attack_damage, global_position, self)

	# Darbe penceresi bittiğinde saldırı karesini cooldown boyunca dondurma.
	# Lunge ailesi toparlanma sırasında yerinde beklediği için nötr idle pozu kullanır.
	_play_animation(&"idle")

	var remaining: float = maxf(
		0.0,
		_runtime_attack_cooldown - _runtime_attack_windup
	)
	await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or _dead or attack_generation != _attack_generation:
		return
	_attack_locked = false

	if _player != null and is_instance_valid(_player):
		if _horizontal_distance(global_position, _player.global_position) <= attack_range:
			_face_player()
			_play_animation(&"idle")
			return
	_play_animation(&"walk")


func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if _dead or amount <= 0:
		return

	health -= amount
	_exit_dormant_mode()
	if health <= 0:
		_die()
		return

	if _player == null or not is_instance_valid(_player):
		_player = GameState.player as Node3D
	var retaliation_target := Vector3.ZERO
	var has_retaliation_target := false
	if _source is Node3D:
		retaliation_target = (_source as Node3D).global_position
		has_retaliation_target = true
	elif _player != null and is_instance_valid(_player):
		retaliation_target = _player.global_position
		has_retaliation_target = true
	if aggro_on_damage:
		_aggro = true
		_damage_reaction_remaining = damage_reaction_duration
		if has_retaliation_target:
			retaliation_target.y = global_position.y
			_forced_damage_target = retaliation_target
			_has_forced_damage_target = true
			_forced_damage_best_distance = _horizontal_distance(global_position, retaliation_target)
			_forced_damage_stall_remaining = damage_pursuit_stall_timeout
			_forced_damage_commit_remaining = damage_pursuit_commit_time
			_last_seen_position = retaliation_target
		_lost_sight_remaining = lost_sight_timeout
		_search_remaining = search_duration
		_cached_player_visible = false
		_sight_check_remaining = 0.0
		_detour_remaining = 0.0
		_reset_search_probe()
		_reset_navigation_path()
		if has_retaliation_target:
			_face_position(retaliation_target)
	if alert_allies_on_damage:
		_alert_nearby_allies(retaliation_target if has_retaliation_target else global_position)

	if hurt_audio.stream != null and not hurt_audio.playing:
		hurt_audio.play()
	if hurt_shake_enabled:
		_trigger_damage_shake(
			animated_sprite,
			hurt_shake_duration,
			hurt_shake_amount_pixels
		)


func _collision_floor_local_y() -> float:
	return VexEnemyRuntimeUtils.collision_floor_local_y(collision_shape)


func _snap_body_to_floor(max_correction: float) -> void:
	if not is_inside_tree() or collision_shape == null or collision_shape.shape == null:
		return
	var ray_origin := global_position + Vector3.UP * floor_snap_ray_start_height
	var ray_end := global_position + Vector3.DOWN * (max_correction + floor_snap_ray_extra_depth)
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		floor_collision_mask,
		[get_rid()]
	)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target_root_y := float(hit["position"].y) - _collision_floor_local_y()
	if absf(target_root_y - global_position.y) > max_correction:
		return
	global_position.y = target_root_y
	velocity.y = floor_stick_velocity




func _on_visual_frame_changed() -> void:
	_apply_frame_ground_offset()


func _apply_frame_ground_offset() -> void:
	if animated_sprite == null:
		return
	var offsets := _frame_offsets_for_animation(animated_sprite.animation)
	var frame_offset := 0.0
	if not offsets.is_empty():
		frame_offset = offsets[mini(animated_sprite.frame, offsets.size() - 1)]
	animated_sprite.position.y = _visual_base_y + frame_offset


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	match animation_name:
		&"idle":
			return idle_frame_y_offsets
		&"idle_back":
			return idle_back_frame_y_offsets
		&"walk":
			return walk_frame_y_offsets
		&"walk_back":
			return walk_back_frame_y_offsets
		&"attack":
			return attack_frame_y_offsets
		&"death":
			return death_frame_y_offsets
	return PackedFloat32Array()


func _get_animation_duration(animation_name: StringName) -> float:
	if animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	var speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or speed <= 0.001:
		return 0.0
	return float(frame_count) / speed



func _restore_defeated_state() -> void:
	_dead = true
	_clear_damage_shake(animated_sprite)
	_attack_generation += 1
	_attack_locked = false
	_attack_lunge_remaining = 0.0
	_aggro = false
	_lost_sight_remaining = 0.0
	_search_remaining = 0.0
	velocity = Vector3.ZERO
	_snap_body_to_floor(floor_snap_max_correction)
	collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(4, false)
	_finalize_death_visual()


func _finalize_death_visual() -> void:
	animated_sprite.visible = false
	animated_sprite.pause()
	if ground_shadow != null:
		ground_shadow.visible = false
	_show_burn_remains()


func _show_burn_remains() -> void:
	if _burn_remains != null and is_instance_valid(_burn_remains):
		return
	if burn_remains_scene == null:
		return
	var remains := burn_remains_scene.instantiate()
	if not (remains is Node3D):
		remains.queue_free()
		return
	(remains as Node3D).position = Vector3(0.0, _collision_floor_local_y(), 0.0)
	remains.set("scorch_size", burn_remains_scale * burn_remains_scale_multiplier)
	remains.set("smoke_enabled", burn_smoke_enabled)
	remains.set("smoke_duration", burn_smoke_duration)
	remains.set("smoke_alpha", burn_smoke_alpha)
	remains.set("scorch_tint", burn_scorch_tint)
	remains.set("ember_tint", burn_ember_tint)
	remains.set("ember_emission_energy", burn_ember_emission_energy)
	add_child(remains)
	_burn_remains = remains as Node3D


func _die() -> void:
	if _dead:
		return
	_dead = true
	_clear_damage_shake(animated_sprite)
	_attack_generation += 1
	_attack_locked = false
	_attack_lunge_remaining = 0.0
	_aggro = false
	_lost_sight_remaining = 0.0
	_search_remaining = 0.0
	velocity = Vector3.ZERO
	_snap_body_to_floor(floor_snap_max_correction)
	collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(4, false)
	if attack_audio.stream != null and attack_audio.playing:
		attack_audio.stop()
	if hurt_audio.stream != null and hurt_audio.playing:
		hurt_audio.stop()
	if death_audio.stream != null:
		death_audio.stop()
		death_audio.play()
	GameState.register_enemy_defeated(enemy_id)

	animated_sprite.modulate = _base_sprite_modulate
	if animated_sprite.sprite_frames != null \
	and animated_sprite.sprite_frames.has_animation(&"death") \
	and animated_sprite.sprite_frames.get_frame_count(&"death") > 0:
		_play_animation(&"death")
		var death_duration := maxf(death_settle_duration, _get_animation_duration(&"death"))
		await get_tree().create_timer(death_duration).timeout
		if not is_inside_tree():
			return
		animated_sprite.pause()
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"death") - 1
		_place_corpse_visual_on_floor()
		await get_tree().create_timer(corpse_hold_duration).timeout
		if not is_inside_tree():
			return
	else:
		_play_animation(&"idle")
		animated_sprite.pause()
		_place_corpse_visual_on_floor()
		await get_tree().create_timer(corpse_hold_duration).timeout
		if not is_inside_tree():
			return
	_finalize_death_visual()


func _place_corpse_visual_on_floor() -> void:
	animated_sprite.position.y = corpse_visual_y + corpse_floor_clearance


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = floor_stick_velocity


func _should_use_dormant_mode() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _aggro or _attack_locked:
		return false
	return (
		_horizontal_distance(global_position, _player.global_position)
		> dormant_distance
	)


func _enter_dormant_mode() -> void:
	if _dormant_active:
		return
	_dormant_active = true
	_cached_player_visible = false
	_detour_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_play_animation(&"idle")


func _exit_dormant_mode() -> void:
	if not _dormant_active:
		return
	_dormant_active = false
	_cached_player_visible = false
	_sight_check_remaining = 0.0


func _apply_dormant_physics(delta: float) -> void:
	if is_on_floor():
		velocity.y = floor_stick_velocity
		return
	_apply_gravity(delta)
	move_and_slide()


func _configure_runtime_stats() -> void:
	_runtime_maximum_health = maximum_health
	_runtime_move_speed = move_speed
	_runtime_chase_speed = chase_speed
	_runtime_detection_range = detection_range
	_runtime_pursuit_range = pursuit_range
	_runtime_attack_damage = attack_damage
	_runtime_attack_cooldown = attack_cooldown
	_runtime_attack_windup = attack_windup
	_runtime_attack_lunge_speed = attack_lunge_speed
	if not apply_difficulty_scaling:
		return

	var health_scale := _scene_difficulty_multiplier(difficulty_health_multipliers)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	var speed_scale := _scene_difficulty_multiplier(difficulty_speed_multipliers)
	var detection_scale := _scene_difficulty_multiplier(difficulty_detection_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	_runtime_maximum_health = maxi(1, int(round(float(maximum_health) * health_scale)))
	_runtime_move_speed = maxf(0.0, move_speed * speed_scale)
	_runtime_chase_speed = maxf(0.0, chase_speed * speed_scale)
	_runtime_attack_lunge_speed = maxf(0.0, attack_lunge_speed * speed_scale)
	_runtime_detection_range = maxf(0.0, detection_range * detection_scale)
	_runtime_pursuit_range = maxf(0.0, pursuit_range * detection_scale)
	_runtime_attack_damage = maxi(1, int(round(float(attack_damage) * damage_scale)))
	_runtime_attack_cooldown = maxf(0.01, attack_cooldown * cooldown_scale)
	_runtime_attack_windup = maxf(0.0, attack_windup * windup_scale)


func _play_animation(animation_name: StringName) -> void:
	if not _has_animation(animation_name):
		return
	var target_animation := animation_name
	var observer_is_behind := _is_observer_behind_enemy()
	if observer_is_behind:
		if animation_name == &"idle" and _has_animation(&"idle_back"):
			target_animation = &"idle_back"
		elif animation_name == &"walk" and _has_animation(&"walk_back"):
			target_animation = &"walk_back"
	if animated_sprite.animation == target_animation and animated_sprite.is_playing():
		return
	animated_sprite.play(target_animation)
	_apply_frame_ground_offset()


func _has_animation(animation_name: StringName) -> bool:
	return (
		animated_sprite.sprite_frames != null
		and animated_sprite.sprite_frames.has_animation(animation_name)
		and animated_sprite.sprite_frames.get_frame_count(animation_name) > 0
	)


func _is_observer_behind_enemy() -> bool:
	var observer_position := Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		observer_position = camera.global_position
	elif _player != null and is_instance_valid(_player):
		observer_position = _player.global_position
	else:
		return false
	var direction_to_observer := observer_position - global_position
	direction_to_observer.y = 0.0
	if direction_to_observer.length_squared() <= 0.001:
		return false
	return (
		_facing_direction.dot(direction_to_observer.normalized())
		< back_view_threshold
	)


func receive_ally_alert(suspected_position: Vector3) -> void:
	if _dead or not receive_ally_alerts:
		return
	_exit_dormant_mode()
	_aggro = true
	_last_seen_position = suspected_position
	_lost_sight_remaining = lost_sight_timeout
	_search_remaining = search_duration
	_reset_search_probe()
	_detour_remaining = 0.0


func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:
	if _dead or source == self:
		return
	var distance := _horizontal_distance(global_position, noise_position)
	var effective_range := hearing_radius * maxf(loudness * hearing_loudness_scale, 0.1)
	if distance > effective_range:
		return
	var hearing_origin := global_position + Vector3.UP * acoustic_probe_height
	var hearing_target := noise_position + Vector3.UP * acoustic_probe_height
	if not VexEnemyRuntimeUtils.has_clear_acoustic_path(
		get_world_3d(), hearing_origin, hearing_target, acoustic_collision_mask
	):
		return
	_exit_dormant_mode()
	_aggro = true
	_last_seen_position = noise_position
	_lost_sight_remaining = lost_sight_timeout
	_search_remaining = search_duration
	_reset_search_probe()
	_path_refresh_remaining = 0.0
	if loudness >= loud_noise_alert_threshold:
		_alert_nearby_allies(noise_position)


func get_weapon_hit_multiplier(hit_position: Vector3, base_headshot_multiplier: float) -> float:
	var local_y := hit_position.y - global_position.y
	return (
		base_headshot_multiplier
		if local_y >= headshot_reference_height * headshot_height_ratio
		else 1.0
	)


func _alert_nearby_allies(suspected_position: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not is_instance_valid(node):
			continue
		if not (node is Node3D) or not node.has_method("receive_ally_alert"):
			continue
		var ally := node as Node3D
		if global_position.distance_to(ally.global_position) > ally_alert_radius:
			continue
		if not VexEnemyRuntimeUtils.has_clear_acoustic_path(
			get_world_3d(),
			global_position + Vector3.UP * acoustic_probe_height,
			ally.global_position + Vector3.UP * acoustic_probe_height,
			acoustic_collision_mask
		):
			continue
		ally.call("receive_ally_alert", suspected_position)
