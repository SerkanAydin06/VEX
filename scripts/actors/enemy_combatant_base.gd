class_name VexEnemyCombatantBase
extends "res://scripts/actors/enemy_base.gd"

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	SEARCH,
	RETURN,
	DEAD,
}

@export_category("01 - Kimlik, Can ve Zorluk")
## Kayıt ve yenilgi takibinde kullanılan benzersiz yaratık kimliğidir.
@export var enemy_id: StringName = &"enemy"
## Savaş mesafesi rolüdür: Yakın, Orta veya Uzak.
@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.MID
## Zorluk çarpanı uygulanmadan önceki temel can değeridir.
@export_range(1, 1000, 1) var maximum_health := 75
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
@export_range(0.5, 10.0, 0.1) var move_speed := 2.7
## Oyuncu takip edilirken kullanılan hızdır (metre/saniye); Combatant ailesinde 0 normal hızı kullanır.
@export_range(0.0, 16.0, 0.1) var chase_speed := 0.0
## Yaratığın hedef hareket hızına ulaşma ivmesidir.
@export_range(0.5, 40.0, 0.5) var movement_acceleration := 12.0
## Durma ve yön değiştirme sırasında kullanılan yavaşlama ivmesidir.
@export_range(0.5, 40.0, 0.5) var braking_acceleration := 21.0
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
@export_storage var patrol_offset := Vector3(0, 0, 3.0)
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_wander_radius := 2.0
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_wander_attempts := 12
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_wander_min_radius_ratio := 0.35
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_pause_min := 0.55
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_pause_max := 0.95
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_turn_speed := 0.28
## Eski sahnelerle veri uyumluluğu içindir; sabit bekleme davranışında kullanılmaz.
@export_storage var idle_target_min_distance := 0.25

@export_category("03 - Algılama ve Takip")
## Oyuncunun ilk kez algılanabileceği azami yatay mesafedir (metre).
@export_range(1.0, 50.0, 0.5) var detection_range := 30.0
## Takip başladıktan sonra kovalamaya devam edilen azami mesafedir (metre).
@export_range(1.0, 60.0, 0.5) var pursuit_range := 38.0
## İlk algılamada kullanılan yatay görüş açısıdır (derece); 360 tam çevredir.
@export_range(30.0, 360.0, 5.0) var initial_view_angle := 240.0
## Görüş kesildikten sonra doğrudan takibin sürdürüleceği süredir (saniye).
@export_range(1.0, 60.0, 0.5) var lost_sight_timeout := 20.0
## Oyuncu kaybedildiğinde arama durumunda kalınacak süredir (saniye).
@export_range(1.0, 30.0, 0.5) var search_duration := 10.0
## arama yoklama yarıçap değeridir (metre).
@export_range(0.5, 5.0, 0.1) var search_probe_radius := 2.2
## arama dönüş hız değeridir (metre/saniye).
@export_range(15.0, 180.0, 5.0) var search_turn_speed := 45.0
## Uyarıyı alabilecek müttefiklerin yarıçapıdır (metre).
@export_range(1.0, 30.0, 0.5) var ally_alert_radius := 10.5
## görüş başlangıç yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var sight_origin_height := 0.55
## görüş hedef yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var sight_target_height := 0.45
## Çömelmiş oyuncunun normal mesafede algılanma olasılığıdır.
@export_range(0.0, 1.0, 0.05) var crouch_detection_chance := 0.45
## Çömelmiş oyuncunun kesin algılanacağı mesafedir (metre).
@export_range(0.5, 5.0, 0.25) var crouch_guaranteed_detection_distance := 3.0
## Görüş ışınlarını engelleyebilecek fizik katmanlarıdır.
@export_flags_3d_physics var sight_collision_mask := 1 | 2
## Açıksa yaratık hasar aldığında saldırgan duruma geçer.
@export var aggro_on_damage := true
## Açıksa hasar alındığında yakındaki müttefikler uyarılır.
@export var alert_allies_on_damage := true
## Açıksa oyuncu görüldüğünde yakındaki müttefikler uyarılır.
@export var alert_allies_on_detection := true
## Açıksa diğer düşmanlardan gelen uyarılar kabul edilir.
@export var receive_ally_alerts := true
## hasar tepki menzil değeridir (metre).
@export_range(1.0, 120.0, 1.0) var damage_reaction_range := 80.0
## hasar tepki süre değeridir (saniye).
@export_range(1.0, 30.0, 0.5) var damage_reaction_duration := 12.0
## Yaratığın hasar takip en düşük ilerleme ayarını belirler.
@export_range(0.01, 1.0, 0.01) var damage_pursuit_min_progress := 0.20
## hasar takip tıkanma timeout değeridir (saniye).
@export_range(0.1, 10.0, 0.1) var damage_pursuit_stall_timeout := 3.0
## hasar takip kararlılık süre değeridir (saniye).
@export_range(0.0, 2.0, 0.01) var damage_pursuit_commit_time := 0.16
## menzilli siper görünürlük eşik ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.1, 1.0, 0.05) var ranged_cover_visibility_threshold := 0.60
## menzilli siper yeniden konumlanma mesafe değeridir (metre).
@export_range(0.8, 6.0, 0.1) var ranged_cover_reposition_distance := 2.6
## Yaratığın menzilli siper yeniden konumlanma yenileme ayarını belirler.
@export_range(0.15, 2.0, 0.05) var ranged_cover_reposition_refresh := 0.55
## hasar yaklaşma ofset değeridir (metre).
@export_range(0.2, 3.0, 0.1) var damage_approach_offset := 1.4
## hasar yaklaşma mesafe oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.05) var damage_approach_distance_ratio := 0.30
@export_category("03B - İşitme / Stealth")
## Ses olaylarının duyulabileceği temel yarıçaptır (metre).
@export_range(2.0, 40.0, 0.5) var hearing_radius := 14.0
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
@export_category("03C - Görüş Örnekleme")
## Açıksa menzilli saldırı görüşü gövdedeki birden fazla noktadan örneklenir.
@export var ranged_visibility_sampling_enabled := true
## Açıksa menzilli yaratık görüş kapandığında daha açık bir konuma geçer.
@export var cover_reposition_enabled := true
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
## Normal saldırının zorluk çarpanından önceki temel hasarıdır.
@export_range(1, 100, 1) var attack_damage := 12
## Normal saldırının başlatılabildiği yatay mesafedir (metre).
@export_range(0.5, 20.0, 0.1) var attack_range := 9.0
## İki normal saldırı arasındaki temel bekleme süresidir (saniye).
@export_range(0.2, 5.0, 0.05) var attack_cooldown := 0.80
## Hasar veya mermi çıkmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 2.0, 0.05) var attack_windup := 0.25
## Yaratığın saldırı menzil tolerans ayarını belirler.
@export_range(0.0, 8.0, 0.05) var attack_range_tolerance := 0.65
## Normal menzilli saldırıda üretilecek mermi sahnesidir.
@export var projectile_scene: PackedScene
## mermi doğma yükseklik değeridir (metre).
@export_range(-2.0, 3.0, 0.01) var projectile_spawn_height := 0.55
## mermi doğma yan ofset değeridir (metre).
@export_range(-2.0, 2.0, 0.01) var projectile_spawn_side_offset := 0.0
## mermi doğma ileri ofset değeridir (metre).
@export_range(0.0, 2.0, 0.01) var projectile_spawn_forward_offset := 0.0
## mermi hedef yükseklik değeridir (metre).
@export_range(0.0, 3.0, 0.05) var projectile_target_height := 0.40
## mermi önden nişan oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.05) var projectile_lead_factor := 0.0
## Yaratığın mermi en yüksek önden nişan süre ayarını belirler.
@export_range(0.0, 2.0, 0.05) var projectile_max_lead_time := 0.0
## saldırı yaklaşma hız değeridir (metre/saniye).
@export_range(0.0, 10.0, 0.1) var attack_approach_speed := 0.0
## saldırı yana hareket hız değeridir (metre/saniye).
@export_range(0.0, 10.0, 0.1) var attack_strafe_speed := 0.0
## Menzilli yaratığın korumaya çalıştığı ideal savaş mesafesidir (metre).
@export_range(0.5, 20.0, 0.1) var attack_preferred_distance := 6.0
## Oyuncu bundan yakınsa yaratığın geri çekilmeyi tercih edeceği mesafedir (metre).
@export_range(0.0, 20.0, 0.1) var attack_minimum_distance := 3.1
## saldırı toparlanma yana hareket çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 2.0, 0.05) var attack_recovery_strafe_scale := 0.72
## saldırı geri çekilme hız çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 2.0, 0.05) var attack_retreat_speed_scale := 0.58
## saldırı yaklaşma mesafe pay değeridir (metre).
@export_range(0.0, 3.0, 0.05) var attack_approach_distance_margin := 0.35
## saldırı yaklaşma en düşük hız çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 2.0, 0.05) var attack_approach_min_speed_scale := 0.45

@export_category("05 - Yol Bulma")
## rota yenileme aralığı değeridir (saniye).
@export_range(0.1, 1.0, 0.05) var path_refresh_interval := 0.35
## takip rota yenileme aralığı değeridir (saniye).
@export_range(0.1, 1.0, 0.05) var chase_path_refresh_interval := 0.36
## yol noktası bağlantı mesafe değeridir (metre).
@export_range(4.0, 15.0, 0.5) var waypoint_link_distance := 9.0
## navigation boşluk değeridir (metre).
@export_range(0.3, 1.2, 0.05) var navigation_clearance := 0.7
## yol noktası ulaşma mesafe değeridir (metre).
@export_range(0.3, 1.5, 0.05) var waypoint_reach_distance := 0.65
## rota hedef değişim mesafe değeridir (metre).
@export_range(0.1, 5.0, 0.1) var path_target_change_distance := 1.0
## devriye rota yenileme aralığı değeridir (saniye).
@export_range(0.1, 2.0, 0.05) var patrol_path_refresh_interval := 0.5
## uç nokta bağlantı mesafe çarpanı ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(1.0, 4.0, 0.1) var endpoint_link_distance_multiplier := 1.5
## uç nokta aday sayısı değeridir; yükseltmek daha fazla aday veya işlem kullanır.
@export_range(1, 32, 1) var endpoint_candidate_count := 10
## uç nokta bağlantı sınırı değeridir; yükseltmek daha fazla aday veya işlem kullanır.
@export_range(1, 16, 1) var endpoint_connection_limit := 5
## araştırma aday sayısı değeridir; yükseltmek daha fazla aday veya işlem kullanır.
@export_range(1, 64, 1) var investigation_candidate_count := 18
## Yaratığın çalışma anı ızgara adım ayarını belirler.
@export_range(0.6, 2.0, 0.05) var runtime_grid_step := 1.0
## Çalışma anı yol bulma ızgarasının kullanabileceği en fazla düğüm sayısıdır.
@export_range(200, 6000, 100) var runtime_grid_max_nodes := 1800
## çalışma anı ızgara arama pay değeridir (metre).
@export_range(4.0, 30.0, 0.5) var runtime_grid_search_margin := 12.0
## Yol bulma ve engel kontrollerinde kullanılan fizik katmanlarıdır.
@export_flags_3d_physics var navigation_collision_mask := 1 | 8
## arama rota deneme sayısı değeridir; yükseltmek daha fazla aday veya işlem kullanır.
@export_range(1, 12, 1) var search_path_attempts := 4
## devriye uzak mesafe çarpanı ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.5, 4.0, 0.05) var patrol_far_distance_multiplier := 2.0
## yerel sapma süre değeridir (saniye).
@export_range(0.0, 3.0, 0.05) var local_detour_duration := 0.90
## yerel sapma boşluk çarpanı ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.5, 4.0, 0.05) var local_detour_clearance_multiplier := 1.45
## yerel sapma en düşük adım değeridir (metre).
@export_range(0.1, 3.0, 0.05) var local_detour_min_step := 0.90
## yerel sapma yan çarpanları ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export var local_detour_lateral_multipliers := PackedFloat32Array([1.0, 1.8, 2.8, 4.0])
## yerel sapma ileri çarpanları ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export var local_detour_forward_multipliers := PackedFloat32Array([0.0, 0.75, 1.5])
## yerel sapma ilerleme ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 4.0, 0.05) var local_detour_progress_weight := 1.5
## yerel sapma mesafe ceza ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.01) var local_detour_distance_penalty := 0.08
## yerel sapma doğrudan rota bonus ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 20.0, 0.1) var local_detour_direct_path_bonus := 8.0
## yerel sapma süreklilik bonus ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 3.0, 0.05) var local_detour_persistence_bonus := 0.45

@export_category("05B - Cover Yeniden Konumlanma")
## siper çapraz mesafe çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(1.0, 3.0, 0.05) var cover_diagonal_distance_scale := 1.35
## siper ileri mesafe çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 2.0, 0.05) var cover_forward_distance_scale := 0.35
## siper görünürlük puan ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 10.0, 0.1) var cover_visibility_score_weight := 4.0
## siper mesafe puan ceza ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 1.0, 0.01) var cover_distance_score_penalty := 0.08
## siper eşik puan bonus ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.0, 10.0, 0.1) var cover_threshold_score_bonus := 2.0
## siper başarısız yeniden deneme aralığı değeridir (saniye).
@export_range(0.05, 2.0, 0.05) var cover_failed_retry_interval := 0.20

@export_category("06 - Performans")
## boşta algılama pay değeridir (metre).
@export_range(0.0, 30.0, 0.5) var idle_detection_margin := 6.0
## yakın görüş aralığı değeridir (saniye).
@export_range(0.02, 1.0, 0.01) var near_sight_interval := 0.12
## orta görüş aralığı değeridir (saniye).
@export_range(0.02, 1.0, 0.01) var medium_sight_interval := 0.18
## uzak düşünme mesafe değeridir (metre).
@export_range(12.0, 80.0, 1.0) var distant_think_distance := 24.0
## uzak görüş aralığı değeridir (saniye).
@export_range(0.1, 1.0, 0.05) var distant_sight_interval := 0.2
## boşta uzak görüş aralığı değeridir (saniye).
@export_range(0.1, 1.0, 0.05) var idle_far_sight_interval := 0.32
## uzak rota yenileme aralığı değeridir (saniye).
@export_range(0.3, 2.0, 0.05) var distant_path_refresh_interval := 0.6
## Oyuncu bundan uzaktayken pahalı AI işlemlerinin uykuya alınacağı mesafedir (metre).
@export_range(12.0, 80.0, 1.0) var dormant_distance := 44.0

@export_category("07 - Görsel ve Animasyon")
## arka görüş eşik ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(-1.0, 1.0, 0.05) var back_view_threshold := -0.15
## Açıksa hasar alan yaratığın görseline kısa ve hafif bir sarsıntı uygulanır.
@export var hurt_shake_enabled := true
## Hasar sarsıntısının toplam süresidir (saniye); saldırı ve hareketi durdurmaz.
@export_range(0.02, 0.3, 0.01) var hurt_shake_duration := 0.10
## Sarsıntının sprite üzerindeki en yüksek uzaklığıdır (piksel).
@export_range(0.0, 8.0, 0.25) var hurt_shake_amount_pixels := 2.0
## Sarsıntının saniyedeki titreşim hızıdır.
@export_range(4.0, 60.0, 1.0) var hurt_shake_frequency := 28.0
## Yaratığın ceset görsel y ayarını belirler.
@export_range(-1.0, 2.0, 0.01) var corpse_visual_y := -0.0999775
## Yaratığın arka ceset görsel y ayarını belirler.
@export_range(-1.0, 2.0, 0.01) var back_corpse_visual_y := -0.0999775
## Yaratığın ölüm düşme süre ayarını belirler.
@export_range(0.05, 1.0, 0.05) var death_fall_time := 0.3
## ceset kalma süre değeridir (saniye).
@export_range(0.0, 4.0, 0.05) var corpse_hold_duration := 2.4
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
@export var death_frame_y_offsets := PackedFloat32Array([0.0, -0.008, -0.016, -0.025])

@export_category("08 - Ölüm Sonrası İz")
## Yanarak ölen yaratığın yerine üretilecek kalıntı sahnesidir.
@export var burn_remains_scene: PackedScene
## yanık kalıntı çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.4, 3.5, 0.05) var burn_remains_scale := 1.0
## yanık kalıntı çarpan çarpanı ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
@export_range(0.1, 2.0, 0.01) var burn_remains_scale_multiplier := 1.0
## yanık kömür rengi değeridir.
@export var burn_scorch_tint := Color(0.18, 0.03, 0.06, 0.96)
## yanık köz rengi değeridir.
@export var burn_ember_tint := Color(0.44, 0.08, 0.14, 0.22)
## Yaratığın yanık köz yayım enerjisi ayarını belirler.
@export_range(0.0, 2.0, 0.01) var burn_ember_emission_energy := 0.10
## Açıksa yanık kalıntı üzerinde duman efekti oluşturulur.
@export var burn_smoke_enabled := false
## yanık duman süre değeridir (saniye).
@export_range(0.0, 20.0, 0.1) var burn_smoke_duration := 9.0
## Yaratığın yanık duman saydamlık ayarını belirler.
@export_range(0.0, 1.0, 0.01) var burn_smoke_alpha := 0.14

@export_category("09 - Özel Yetenekler")
## Bu yaratığa özgü saldırı ayarlarını içerir; kaynağı genişleterek alt alanları düzenleyin.
@export var special_ability_settings: VexEnemyAbilitySettings

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

var health := 0
var state := State.IDLE

var _spawn_position := Vector3.ZERO
var _facing_direction := Vector3.FORWARD
var _alerted := false
var _attack_locked := false
var _attack_windup_active := false
var _attack_strafe_direction := -1.0
var _gravity := 20.0
var _player: Node3D = null

var _sight_check_remaining := 0.0
var _player_visible := false
var _seconds_without_sight := 0.0
var _last_seen_position := Vector3.ZERO
var _has_last_seen_position := false
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
var _combat_interrupt_generation := 0
var _last_visibility_ratio := 0.0
var _ranged_reposition_target := Vector3.ZERO
var _has_ranged_reposition_target := false
var _ranged_reposition_remaining := 0.0
var _local_detour_side := 0.0
var _local_detour_remaining := 0.0

static var _shared_navigation_scene_id := -1
static var _shared_navigation_caches: Dictionary = {}

var _navigation_points: Array[Vector3] = []
var _valid_edges: Array[Vector2i] = []
var _navigation_graph: AStar3D = null
var _current_path := PackedVector3Array()
var _path_index := 0
var _path_refresh_remaining := 0.0
var _path_target := Vector3.ZERO
var _has_path_target := false
var _runtime_maximum_health := 1
var _runtime_attack_damage := 1
var _runtime_move_speed := 0.5
var _runtime_chase_speed := 0.5
var _runtime_detection_range := 1.0
var _runtime_pursuit_range := 1.0
var _runtime_attack_cooldown := 1.0
var _runtime_attack_windup := 0.1
var _dormant_active := false
var _burn_remains: Node3D = null
var _visual_base_y := 0.0


func get_behavior_family() -> StringName:
	return &"combatant"


func _ready() -> void:
	_visual_base_y = animated_sprite.position.y
	if not animated_sprite.frame_changed.is_connected(_on_visual_frame_changed):
		animated_sprite.frame_changed.connect(_on_visual_frame_changed)
	_apply_frame_ground_offset()
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
	_gravity = (
		float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
		* gravity_scale
	)

	if GameState.was_enemy_defeated(enemy_id):
		_restore_defeated_state()
		return

	# Aynı karede onlarca düşmanın raycast/path yenilemesini engelle.
	_sight_check_remaining = randf_range(0.0, near_sight_interval)
	_path_refresh_remaining = randf_range(0.0, path_refresh_interval)
	_play_directional_animation(&"idle", &"idle_back")
	call_deferred("_cache_navigation_waypoints")


func _configure_runtime_stats() -> void:
	_runtime_maximum_health = maximum_health
	_runtime_attack_damage = attack_damage
	_runtime_move_speed = move_speed
	_runtime_chase_speed = chase_speed if chase_speed > 0.0 else move_speed
	_runtime_detection_range = detection_range
	_runtime_pursuit_range = pursuit_range
	_runtime_attack_cooldown = attack_cooldown
	_runtime_attack_windup = attack_windup
	if not apply_difficulty_scaling:
		return

	var health_scale := _scene_difficulty_multiplier(difficulty_health_multipliers)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	var speed_scale := _scene_difficulty_multiplier(difficulty_speed_multipliers)
	var detection_scale := _scene_difficulty_multiplier(difficulty_detection_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	_runtime_maximum_health = maxi(1, int(round(float(maximum_health) * health_scale)))
	_runtime_attack_damage = maxi(1, int(round(float(attack_damage) * damage_scale)))
	_runtime_move_speed = maxf(0.0, move_speed * speed_scale)
	_runtime_chase_speed = maxf(0.0, (chase_speed if chase_speed > 0.0 else move_speed) * speed_scale)
	_runtime_detection_range = maxf(0.0, detection_range * detection_scale)
	_runtime_pursuit_range = maxf(0.0, pursuit_range * detection_scale)
	_runtime_attack_cooldown = maxf(0.01, attack_cooldown * cooldown_scale)
	_runtime_attack_windup = maxf(0.0, attack_windup * windup_scale)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_update_damage_shake(animated_sprite, delta, hurt_shake_frequency)

	if _player == null or not is_instance_valid(_player):
		_player = GameState.player as Node3D
	_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)
	_forced_damage_commit_remaining = maxf(0.0, _forced_damage_commit_remaining - delta)
	_ranged_reposition_remaining = maxf(0.0, _ranged_reposition_remaining - delta)
	_local_detour_remaining = maxf(0.0, _local_detour_remaining - delta)

	if _should_use_dormant_mode():
		_enter_dormant_mode()
		_apply_dormant_physics(delta)
		return
	_exit_dormant_mode()

	_path_refresh_remaining -= delta
	_update_perception(delta)
	_update_behavior(delta)
	_apply_gravity(delta)
	move_and_slide()

	if get_slide_collision_count() > 0:
		# Bir kapı kapanırsa veya rota fiziksel olarak değişirse yolu erken yenile.
		_path_refresh_remaining = 0.0


func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if state == State.DEAD or amount <= 0:
		return

	health -= amount
	_exit_dormant_mode()
	if health <= 0:
		_die()
		return

	var retaliation_target := Vector3.ZERO
	var has_retaliation_target := false
	if _source is Node3D:
		retaliation_target = (_source as Node3D).global_position
		has_retaliation_target = true
	elif _player != null and is_instance_valid(_player):
		retaliation_target = _player.global_position
		has_retaliation_target = true
	if aggro_on_damage:
		_alerted = true
		if not _attack_locked:
			state = State.CHASE
		_damage_reaction_remaining = damage_reaction_duration
		_seconds_without_sight = 0.0
		_search_remaining = 0.0
		_sight_check_remaining = 0.0
		if has_retaliation_target:
			retaliation_target.y = global_position.y
			_forced_damage_target = retaliation_target
			_has_forced_damage_target = true
			_forced_damage_best_distance = _horizontal_distance(global_position, retaliation_target)
			_forced_damage_stall_remaining = damage_pursuit_stall_timeout
			_forced_damage_commit_remaining = damage_pursuit_commit_time
			_last_seen_position = retaliation_target
			_has_last_seen_position = true
		_path_refresh_remaining = 0.0
		_ranged_reposition_remaining = 0.0
		_has_ranged_reposition_target = false
		_local_detour_remaining = 0.0
		_local_detour_side = 0.0
		_clear_path()
		if _has_last_seen_position and not _attack_locked:
			_face_toward_position(_last_seen_position)
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


func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:
	if state == State.DEAD or source == self:
		return
	if not VexEnemyPerceptionRuntime.should_hear_noise(
		global_position,
		noise_position,
		hearing_radius,
		loudness,
		hearing_loudness_scale
	):
		return
	var hearing_origin := global_position + Vector3.UP * acoustic_probe_height
	var hearing_target := noise_position + Vector3.UP * acoustic_probe_height
	if not VexEnemyRuntimeUtils.has_clear_acoustic_path(
		get_world_3d(), hearing_origin, hearing_target, acoustic_collision_mask
	):
		return
	_exit_dormant_mode()
	_alerted = true
	_player_visible = false
	_seconds_without_sight = 0.0
	_search_remaining = search_duration
	_last_seen_position = noise_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true
	state = State.CHASE
	_clear_path()
	_path_refresh_remaining = 0.0
	if VexEnemyPerceptionRuntime.should_broadcast_noise_alert(
		loudness, loud_noise_alert_threshold
	):
		_alert_nearby_allies(noise_position)

func get_weapon_hit_multiplier(hit_position: Vector3, base_headshot_multiplier: float) -> float:
	var local_y := hit_position.y - global_position.y
	var head_threshold := headshot_reference_height * headshot_height_ratio
	return base_headshot_multiplier if local_y >= head_threshold else 1.0


func receive_ally_alert(suspected_position: Vector3) -> void:
	if not VexEnemyPerceptionRuntime.should_accept_ally_alert(
		state == State.DEAD,
		_player_visible,
		receive_ally_alerts
	):
		return

	_exit_dormant_mode()
	_alerted = true
	_player_visible = false
	_seconds_without_sight = 0.0
	_search_remaining = 0.0
	_last_seen_position = suspected_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true
	state = State.CHASE
	_clear_path()
	_path_refresh_remaining = 0.0
	_facing_direction = VexEnemyPerceptionRuntime.ally_alert_facing_direction(
		global_position,
		_last_seen_position,
		_facing_direction
	)

func _alert_nearby_allies(suspected_position: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not (node is Node3D):
			continue
		if not node.has_method("receive_ally_alert"):
			continue

		var ally := node as Node3D
		if not VexEnemyPerceptionRuntime.is_within_horizontal_range(
			global_position,
			ally.global_position,
			ally_alert_radius
		):
			continue
		if not VexEnemyRuntimeUtils.has_clear_acoustic_path(
			get_world_3d(),
			global_position + Vector3.UP * acoustic_probe_height,
			ally.global_position + Vector3.UP * acoustic_probe_height,
			acoustic_collision_mask
		):
			continue
		ally.call("receive_ally_alert", suspected_position)

func _update_perception(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player_visible = false
		if _alerted:
			_seconds_without_sight += delta
		return

	var player_distance := _horizontal_distance(global_position, _player.global_position)
	# Oyuncu çok uzaktaysa ve düşman zaten alarm durumunda değilse her kare
	# görüş ışını atmaya gerek yok. Bu erken çıkış özellikle geniş haritada
	# 20+ düşman varken fizik raycast yükünü hissedilir biçimde düşürür.
	if VexEnemyPerceptionRuntime.should_skip_idle_sight(
		_alerted,
		player_distance,
		_runtime_detection_range,
		idle_detection_margin
	):
		_player_visible = false
		_sight_check_remaining = VexEnemyPerceptionRuntime.next_sight_check_remaining(
			_sight_check_remaining,
			delta,
			idle_far_sight_interval
		)
		return

	var sight_interval := VexEnemyPerceptionRuntime.sight_interval(
		player_distance,
		_alerted,
		_runtime_detection_range,
		distant_think_distance,
		near_sight_interval,
		medium_sight_interval,
		distant_sight_interval,
		idle_far_sight_interval
	)
	var sight_check_due := VexEnemyPerceptionRuntime.is_sight_check_due(
		_sight_check_remaining, delta
	)
	_sight_check_remaining = VexEnemyPerceptionRuntime.next_sight_check_remaining(
		_sight_check_remaining,
		delta,
		sight_interval
	)
	if sight_check_due:
		_player_visible = _can_see_player()
		# Son görülen konumu yalnızca yeni bir görüş ışını gerçekten oyuncuya
		# ulaştığında güncelle. Önceki görüş sonucunu ara karelerde kullanmak,
		# koşan oyuncunun duvar arkasındaki konumunu yanlışlıkla kaydediyordu.
		if _player_visible:
			_last_seen_position = _player.global_position
			_has_last_seen_position = true

	if _player_visible:
		var was_alerted := _alerted
		_alerted = true
		_seconds_without_sight = 0.0
		if not was_alerted and alert_allies_on_detection and _has_last_seen_position:
			_alert_nearby_allies(_last_seen_position)
	elif _alerted:
		_seconds_without_sight += delta

func _update_behavior(delta: float) -> void:
	# Başlamış saldırı hasar tepkisinden önceliklidir. Vurulmak saldırı zamanlayıcısını,
	# animasyonunu veya saldırı sonrası hareketini kesmez.
	if _attack_locked:
		state = State.ATTACK
		var attack_target := global_position
		var has_attack_target := false
		if _player_visible and _player != null and is_instance_valid(_player):
			attack_target = _player.global_position
			has_attack_target = true
		elif _has_last_seen_position:
			attack_target = _last_seen_position
			has_attack_target = true

		if not has_attack_target:
			_stop_horizontal_motion()
		elif _attack_windup_active:
			_face_toward_position(attack_target)
			_stop_horizontal_motion()
		elif _uses_cover_reposition_tactics() and _last_visibility_ratio < _cover_visibility_threshold():
			_reposition_for_clear_shot(delta)
		else:
			_move_during_attack_recovery(attack_target, delta)
		return

	# Saldırı yokken hasar kaynağına ulaş veya en yakın erişilebilir noktaya ilerle.
	if _has_forced_damage_target:
		# Hasar geldiği anda önce kaynağa yönel; fakat oyuncu artık gerçekten
		# saldırı menzilindeyse ve arada duvar yoksa exact eski koordinata
		# ulaşmaya çalışıp gövdenin içine yürümek yerine combat'a teslim et.
		if _can_handoff_damage_pursuit_to_combat():
			_has_forced_damage_target = false
			_damage_reaction_remaining = 0.0
			_forced_damage_stall_remaining = 0.0
			_clear_path()
		else:
			var forced_distance := _horizontal_distance(global_position, _forced_damage_target)
			if forced_distance < _forced_damage_best_distance - damage_pursuit_min_progress:
				_forced_damage_best_distance = forced_distance
				_forced_damage_stall_remaining = damage_pursuit_stall_timeout
			else:
				_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)
			if _has_reached_walkable_target(_forced_damage_target, waypoint_reach_distance):
				_has_forced_damage_target = false
				_damage_reaction_remaining = 0.0
				_last_seen_position = _forced_damage_target
				_has_last_seen_position = true
				_begin_search()
				return
			state = State.CHASE
			_navigate_to(_forced_damage_target, delta)
			if (
				_forced_damage_stall_remaining <= 0.0
				and (_current_path.is_empty() or _path_index >= _current_path.size())
			):
				_has_forced_damage_target = false
				_damage_reaction_remaining = 0.0
				_last_seen_position = _forced_damage_target
				_has_last_seen_position = true
				_begin_search()
			return
	# CLOSE rolünde point-blank saldırı kararı cache'lenmiş görüş sonucunu
	# beklemez. Oyuncu menzildeyse LOS'u bu fizik karesinde doğrula.
	_refresh_close_combat_visibility()

	if (
		_player_visible
		and _has_last_seen_position
		and _player != null
		and is_instance_valid(_player)
	):
		# Görüş örnekleri arasındaki karelerde oyuncunun duvar arkasındaki canlı
		# konumunu değil, doğrulanmış son görünür konumu kullan.
		# Menzilli düşman oyuncunun yalnız küçük bir parçasını görüyorsa mevcut
		# noktadan atış spamlamak yerine gerçek bir yeni görüş açısı arar.
		if _uses_cover_reposition_tactics() and _last_visibility_ratio < _cover_visibility_threshold():
			state = State.CHASE
			_reposition_for_clear_shot(delta)
			return
		var distance_to_player := _horizontal_distance(global_position, _last_seen_position)
		if distance_to_player <= attack_range:
			state = State.ATTACK
			_face_toward_position(_last_seen_position)
			_stop_horizontal_motion()
			_attempt_attack()
		else:
			state = State.CHASE
			_navigate_to(_last_seen_position, delta)
		return

	if state == State.SEARCH:
		_search_last_seen_area(delta)
		return

	if _alerted:
		if _seconds_without_sight >= lost_sight_timeout:
			_begin_search()
			return
		if _has_last_seen_position:
			state = State.CHASE
			# İnce duvarın öbür tarafındaki hedef yakın görünse bile fiziksel olarak
			# ulaşılmış sayılmaz. Duvar varsa chase devam eder.
			if _has_reached_walkable_target(_last_seen_position, waypoint_reach_distance):
				_begin_search()
			else:
				_navigate_to(_last_seen_position, delta)
			return

	if state == State.RETURN:
		_return_to_patrol(delta)
	else:
		_patrol(delta)


func _refresh_close_combat_visibility() -> void:
	if combat_role != EnemyCombatProfiles.Role.CLOSE:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _horizontal_distance(global_position, _player.global_position) > attack_range + attack_range_tolerance:
		return
	if not _check_line_of_sight():
		return
	_player_visible = true
	_alerted = true
	_seconds_without_sight = 0.0
	_last_seen_position = _player.global_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true


func _can_handoff_damage_pursuit_to_combat() -> bool:
	if _forced_damage_commit_remaining > 0.0:
		return false
	if _player == null or not is_instance_valid(_player):
		return false
	if _horizontal_distance(global_position, _player.global_position) > attack_range + attack_range_tolerance:
		return false
	if not _check_line_of_sight():
		return false
	_player_visible = true
	_alerted = true
	_seconds_without_sight = 0.0
	_last_seen_position = _player.global_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true
	return true


func is_pursuing_player() -> bool:
	return state != State.DEAD and _alerted


func _resolve_enemy_door_step(target_position: Vector3) -> Vector3:
	return EnemyNavigationRuntime.resolve_enemy_door_step(
		self,
		target_position,
		navigation_clearance,
		waypoint_reach_distance
	)

func _patrol(_delta: float) -> void:
	# Alarm öncesinde rota üretme, dönme veya sahne başlangıcından uzaklaşma yoktur.
	# Algılama, ses, müttefik alarmı ve hasar normal takip state'lerini başlatır.
	state = State.IDLE
	_clear_path()
	_stop_horizontal_motion()


func _return_to_patrol(_delta: float) -> void:
	# Takip sona erdiğinde bulunduğu noktada sabit beklemeye geçer.
	state = State.IDLE
	_clear_path()
	_stop_horizontal_motion()


func _begin_search() -> void:
	state = State.SEARCH
	_search_remaining = search_duration
	_reset_search_probe()
	_advance_search_probe()


func _reset_search_probe() -> void:
	_search_probe_index = 0
	_search_probe_target = Vector3.ZERO
	_has_search_probe = false


func _advance_search_probe() -> void:
	if not _has_last_seen_position:
		_reset_search_probe()
		return
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
	_clear_path()
	_path_refresh_remaining = 0.0


func _search_last_seen_area(delta: float) -> void:
	_search_remaining -= delta
	if _search_remaining <= 0.0 or not _has_last_seen_position:
		_give_up_chase()
		return

	if (
		not _has_search_probe
		or _has_reached_walkable_target(_search_probe_target, waypoint_reach_distance)
	):
		_advance_search_probe()

	# Ulaşılamayan tek bir probe bütün aramayı kilitlemesin. AStar rota bulamazsa
	# aynı karede birkaç alternatif köşe/yan probe dene.
	for _attempt: int in range(search_path_attempts):
		_navigate_to(_search_probe_target, delta)
		if not _current_path.is_empty() and _path_index < _current_path.size():
			return
		_advance_search_probe()

	_stop_horizontal_motion()
	_facing_direction = _facing_direction.rotated(
		Vector3.UP,
		deg_to_rad(search_turn_speed) * delta
	).normalized()
	rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)


func _give_up_chase() -> void:
	_alerted = false
	_player_visible = false
	_seconds_without_sight = 0.0
	_search_remaining = 0.0
	_has_last_seen_position = false
	_has_forced_damage_target = false
	_reset_search_probe()
	state = State.IDLE
	_clear_path()
	_stop_horizontal_motion()


func _navigate_to(target: Vector3, delta: float) -> void:
	var destination := _resolve_enemy_door_step(target)
	destination.y = global_position.y

	var target_changed := (
		not _has_path_target
		or _horizontal_distance(_path_target, destination) > path_target_change_distance
	)
	var refresh_interval := (
		chase_path_refresh_interval
		if state == State.CHASE
		else path_refresh_interval
	)
	if _player != null and is_instance_valid(_player):
		var player_distance := _horizontal_distance(global_position, _player.global_position)
		if player_distance > distant_think_distance:
			refresh_interval = maxf(refresh_interval, distant_path_refresh_interval)
		elif (
			state == State.PATROL
			and player_distance > attack_range * patrol_far_distance_multiplier
		):
			refresh_interval = maxf(refresh_interval, patrol_path_refresh_interval)
	# Pahalı fizik raylarını her fizik karesinde çalıştırma. Doğrudan yol ve
	# rota yalnızca hedef anlamlı biçimde değiştiğinde veya yenileme süresi
	# dolduğunda tekrar doğrulanır. move_and_slide() gerçek bir engelle
	# karşılaşırsa _physics_process() yolu bir sonraki karede zorla yeniler.
	if _path_refresh_remaining <= 0.0 or target_changed or not _has_path_target:
		if _is_walk_segment_clear(global_position, destination):
			_current_path = PackedVector3Array([global_position, destination])
			_path_index = 1
			_path_target = destination
			_has_path_target = true
		else:
			_rebuild_path(destination)
		_path_refresh_remaining = refresh_interval

	while (
		_path_index < _current_path.size()
		and _has_reached_walkable_target(
			_current_path[_path_index],
			waypoint_reach_distance
		)
	):
		_path_index += 1

	if _path_index >= _current_path.size():
		_stop_horizontal_motion()
		return

	_move_toward_point(_current_path[_path_index], delta)


func _rebuild_path(destination: Vector3) -> void:
	_current_path = PackedVector3Array()
	_path_index = 0
	_path_target = destination
	_has_path_target = true

	# Aktif takipte elle yerleştirilmiş waypoint'lere bağlı kalma. Fizik dünyasını
	# grid olarak arayıp hedefe giden en kısa yürünebilir rotayı çıkar. Böylece
	# düşman, ateşin geldiği nokta duvar arkasındaysa haritanın hangi tarafından
	# dolaşması gerektiğini yerel sağ/sol tahmin yerine A* ile seçer.
	if state == State.CHASE:
		_current_path = _build_runtime_shortest_path(destination)
		if _current_path.size() > 1:
			_path_index = 1
			return

	# Ortak AStar ağı da harita başına bir kez oluşturulur. Rota ararken yalnızca
	# geçici başlangıç/hedef noktaları eklenir; yüzlerce sabit bağlantı tekrar
	# oluşturulmaz. GDScript fizik işlemleri ana iş parçacığında sıralı olduğu
	# için bu geçici noktalar aynı fonksiyon içinde güvenle eklenip kaldırılır.
	var graph := _navigation_graph
	if graph == null:
		graph = _build_astar_graph()
		_navigation_graph = graph

	var start_id := _navigation_points.size()
	var target_id := start_id + 1
	graph.add_point(start_id, global_position)
	graph.add_point(target_id, destination)

	if _is_walk_segment_clear(global_position, destination):
		graph.connect_points(start_id, target_id, true)
	else:
		_connect_endpoint_to_graph(graph, start_id, global_position)
		_connect_endpoint_to_graph(graph, target_id, destination)

	_current_path = graph.get_point_path(start_id, target_id)
	if _current_path.is_empty():
		# Önce sahne waypoint ağını dene.
		_current_path = _find_investigation_path(graph, start_id, destination)
	if _current_path.is_empty():
		# Waypoint bulunmayan test/level sahnelerinde boş rota ile donmak yerine
		# yerel sağ/sol detour üret ve köşeyi adım adım ara.
		_current_path = _build_local_detour_path(destination)
	if _current_path.size() > 1:
		_path_index = 1

	# Ortak grafiği bir sonraki düşman için temiz bırak.
	graph.remove_point(target_id)
	graph.remove_point(start_id)


func _build_runtime_shortest_path(destination: Vector3) -> PackedVector3Array:
	return EnemyNavigationRuntime.build_shortest_path(
		self,
		destination,
		navigation_collision_mask,
		floor_collision_mask,
		navigation_clearance,
		floor_snap_ray_start_height,
		floor_snap_ray_extra_depth,
		runtime_grid_step,
		runtime_grid_max_nodes,
		runtime_grid_search_margin
	)


func _build_local_detour_path(destination: Vector3) -> PackedVector3Array:
	var toward_target := destination - global_position
	toward_target.y = 0.0
	if toward_target.length_squared() <= 0.001:
		return PackedVector3Array()

	var forward := toward_target.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	var base_step := maxf(
		navigation_clearance * local_detour_clearance_multiplier,
		local_detour_min_step
	)
	var lateral_steps := PackedFloat32Array()
	for multiplier: float in local_detour_lateral_multipliers:
		lateral_steps.append(base_step * multiplier)
	var forward_steps := PackedFloat32Array()
	for multiplier: float in local_detour_forward_multipliers:
		forward_steps.append(base_step * multiplier)
	var side_signs := PackedFloat32Array([-1.0, 1.0])
	if _local_detour_remaining > 0.0 and absf(_local_detour_side) > 0.5:
		side_signs = PackedFloat32Array([_local_detour_side, -_local_detour_side])

	var best_path := PackedVector3Array()
	var best_score := -INF
	var best_side := 0.0
	var current_remaining := _horizontal_distance(global_position, destination)

	for side_sign: float in side_signs:
		for lateral_distance: float in lateral_steps:
			for forward_distance: float in forward_steps:
				var candidate := (
					global_position
					+ side * side_sign * lateral_distance
					+ forward * forward_distance
				)
				candidate.y = global_position.y
				if not _has_navigation_floor(candidate):
					continue
				if not _is_walk_segment_clear(global_position, candidate):
					continue

				var approach_point := _furthest_walkable_point_toward(candidate, destination)
				var remaining := _horizontal_distance(approach_point, destination)
				var progress := current_remaining - remaining
				var direct_open := _is_walk_segment_clear(candidate, destination)
				var score := (
					-remaining
					+ progress * local_detour_progress_weight
					- lateral_distance * local_detour_distance_penalty
				)
				if direct_open:
					score += local_detour_direct_path_bonus
				if _local_detour_remaining > 0.0 and side_sign == _local_detour_side:
					score += local_detour_persistence_bonus

				if score <= best_score:
					continue
				best_score = score
				best_side = side_sign
				best_path = PackedVector3Array([global_position, candidate])
				if (
					_horizontal_distance(candidate, approach_point)
					> waypoint_reach_distance * 0.35
				):
					best_path.append(approach_point)

	if not best_path.is_empty():
		_local_detour_side = best_side
		_local_detour_remaining = local_detour_duration
	return best_path


func _has_navigation_floor(probe_position: Vector3) -> bool:
	var ray_start := probe_position + Vector3.UP * maxf(floor_snap_ray_start_height, 0.65)
	var ray_end := probe_position + Vector3.DOWN * maxf(floor_snap_ray_extra_depth, 2.0)
	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		floor_collision_mask,
		[get_rid()]
	)
	query.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _has_reached_walkable_target(target: Vector3, reach_distance: float) -> bool:
	if _horizontal_distance(global_position, target) > reach_distance:
		return false

	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.000001:
		return true
	var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
	perpendicular *= navigation_clearance
	var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
	var space_state := get_world_3d().direct_space_state
	for offset: Vector3 in offsets:
		var ray_start := global_position + offset
		var ray_end := target + offset
		ray_start.y = global_position.y
		ray_end.y = global_position.y
		var query := PhysicsRayQueryParameters3D.create(
			ray_start,
			ray_end,
			navigation_collision_mask,
			[get_rid()]
		)
		query.collide_with_areas = false
		if not space_state.intersect_ray(query).is_empty():
			return false
	return true


func _build_astar_graph() -> AStar3D:
	var graph := AStar3D.new()
	for point_index: int in range(_navigation_points.size()):
		graph.add_point(point_index, _navigation_points[point_index])
	for edge: Vector2i in _valid_edges:
		graph.connect_points(edge.x, edge.y, true)
	return graph


func _find_investigation_path(
	graph: AStar3D,
	start_id: int,
	destination: Vector3
) -> PackedVector3Array:
	# Hedef (özellikle oyuncunun duvar kenarındaki merkezi) doğrudan erişilemez
	# olabilir. Hedefe düz görüş şartı aramak boş rota üretip AI'ı donduruyordu.
	# Erişilebilir waypoint'lerden hedefe fiziksel olarak en çok yaklaşılabilen
	# noktayı seç; dolaşma yolu varsa hedefe tamamen ulaşan aday doğal olarak kazanır.
	var nearby_indices := _nearest_waypoint_indices(
		destination,
		INF,
		_navigation_points.size()
	)
	var best_path := PackedVector3Array()
	var best_remaining_distance := INF
	var reachable_candidates := 0

	for point_index: int in nearby_indices:
		var candidate_path := graph.get_point_path(start_id, point_index)
		if candidate_path.is_empty():
			continue
		reachable_candidates += 1
		var waypoint := _navigation_points[point_index]
		var approach_point := _furthest_walkable_point_toward(waypoint, destination)
		var remaining_distance := _horizontal_distance(approach_point, destination)

		if remaining_distance < best_remaining_distance:
			best_remaining_distance = remaining_distance
			best_path = candidate_path.duplicate()
			if (
				best_path.is_empty()
				or _horizontal_distance(best_path[best_path.size() - 1], approach_point)
				> waypoint_reach_distance * 0.25
			):
				best_path.append(approach_point)

		if best_remaining_distance <= waypoint_reach_distance * 0.25:
			break
		if (
			reachable_candidates >= investigation_candidate_count
			and best_remaining_distance <= search_probe_radius * 1.5
		):
			break

	return best_path


func _furthest_walkable_point_toward(from_position: Vector3, destination: Vector3) -> Vector3:
	var start := from_position
	start.y = global_position.y
	var target := destination
	target.y = global_position.y
	if _is_walk_segment_clear(start, target):
		return target

	# Gövde açıklığını hesaba katarak hedef yönünde yürünebilen son noktayı bul.
	var low := 0.0
	var high := 1.0
	for _step: int in range(8):
		var middle := (low + high) * 0.5
		var probe := start.lerp(target, middle)
		probe.y = global_position.y
		if _is_walk_segment_clear(start, probe):
			low = middle
		else:
			high = middle

	var result := start.lerp(target, low)
	result.y = global_position.y
	return result


func _connect_endpoint_to_graph(graph: AStar3D, endpoint_id: int, endpoint: Vector3) -> void:
	var maximum_distance := waypoint_link_distance * endpoint_link_distance_multiplier
	var nearby_indices := _nearest_waypoint_indices(
		endpoint,
		maximum_distance,
		endpoint_candidate_count
	)
	var connected_count := 0
	for point_index: int in nearby_indices:
		if _is_walk_segment_clear(endpoint, _navigation_points[point_index]):
			graph.connect_points(endpoint_id, point_index, true)
			connected_count += 1
			if connected_count >= endpoint_connection_limit:
				break


func _nearest_waypoint_indices(
	endpoint: Vector3,
	maximum_distance: float,
	maximum_count: int
) -> Array[int]:
	var indices: Array[int] = []
	var distances: Array[float] = []

	for point_index: int in range(_navigation_points.size()):
		var distance := _horizontal_distance(endpoint, _navigation_points[point_index])
		if distance > maximum_distance:
			continue

		var insert_at := distances.size()
		while insert_at > 0 and distance < distances[insert_at - 1]:
			insert_at -= 1
		distances.insert(insert_at, distance)
		indices.insert(insert_at, point_index)

		if indices.size() > maximum_count:
			indices.pop_back()
			distances.pop_back()

	return indices


func _cache_navigation_waypoints() -> void:
	var current_scene := get_tree().current_scene
	var scene_id := current_scene.get_instance_id() if current_scene != null else 0
	if _shared_navigation_scene_id != scene_id:
		_shared_navigation_scene_id = scene_id
		_shared_navigation_caches.clear()

	var cache_key := "%.3f|%.3f|%d" % [
		waypoint_link_distance,
		navigation_clearance,
		navigation_collision_mask,
	]
	var cached_data: Dictionary = _shared_navigation_caches.get(cache_key, {})
	if not cached_data.is_empty():
		_navigation_points.clear()
		_valid_edges.clear()
		for cached_point: Vector3 in cached_data.get("points", []):
			_navigation_points.append(cached_point)
		for cached_edge: Vector2i in cached_data.get("edges", []):
			_valid_edges.append(cached_edge)
		_navigation_graph = cached_data.get("graph") as AStar3D
		_path_refresh_remaining = 0.0
		return

	_navigation_points.clear()
	_valid_edges.clear()

	for node: Node in get_tree().get_nodes_in_group("enemy_navigation_waypoint"):
		if node is Node3D:
			var waypoint := node as Node3D
			_navigation_points.append(waypoint.global_position)

	# Bu pahalı doğrulama her harita ve gövde açıklığı bileşimi için yalnızca bir
	# kez yapılır. Aynı ayarlardaki düşmanlar noktaları, bağlantıları ve AStar
	# grafiğini doğrudan ortak önbellekten alır.
	for first_index: int in range(_navigation_points.size()):
		for second_index: int in range(first_index + 1, _navigation_points.size()):
			if (
				_horizontal_distance(
					_navigation_points[first_index],
					_navigation_points[second_index]
				) > waypoint_link_distance
			):
				continue
			if _is_walk_segment_clear(
				_navigation_points[first_index],
				_navigation_points[second_index]
			):
				_valid_edges.append(Vector2i(first_index, second_index))

	_navigation_graph = _build_astar_graph()
	_shared_navigation_caches[cache_key] = {
		"points": _navigation_points.duplicate(),
		"edges": _valid_edges.duplicate(),
		"graph": _navigation_graph,
	}
	_path_refresh_remaining = 0.0


func _is_walk_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return true

	var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
	perpendicular *= navigation_clearance
	var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
	var space_state := get_world_3d().direct_space_state

	for offset: Vector3 in offsets:
		var ray_start := from_position + offset
		var ray_end := to_position + offset
		var query := PhysicsRayQueryParameters3D.create(
			ray_start,
			ray_end,
			navigation_collision_mask,
			[get_rid()]
		)
		if not space_state.intersect_ray(query).is_empty():
			return false
	return true


func _is_center_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return true

	var ray_start := from_position
	var ray_end := to_position
	ray_start.y = global_position.y
	ray_end.y = global_position.y
	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		navigation_collision_mask,
		[get_rid()]
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _move_toward_point(target: Vector3, delta: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if (
		direction.length_squared() < 0.05
		and _has_reached_walkable_target(target, sqrt(0.05))
	):
		_stop_horizontal_motion()
		return

	direction = direction.normalized()
	_facing_direction = direction
	var travel_speed := (
		_runtime_chase_speed
		if state == State.CHASE or state == State.SEARCH
		else _runtime_move_speed
	)
	velocity.x = move_toward(
		velocity.x,
		direction.x * travel_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * travel_speed,
		delta * movement_acceleration
	)
	if animated_sprite.animation != &"attack":
		_play_directional_animation(&"walk", &"walk_back")


func _face_toward_position(target: Vector3) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return
	_facing_direction = direction.normalized()
	rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)


func _move_during_attack_recovery(target: Vector3, delta: float) -> void:
	var direction_to_target := target - global_position
	direction_to_target.y = 0.0
	var distance_to_target := direction_to_target.length()
	if distance_to_target <= 0.001:
		_stop_horizontal_motion()
		return

	var forward_direction := direction_to_target / distance_to_target
	var right_direction := forward_direction.cross(Vector3.UP).normalized()
	var preferred_distance := attack_preferred_distance
	var minimum_distance := minf(attack_minimum_distance, preferred_distance)
	var speed_scale := _runtime_move_speed / maxf(move_speed, 0.001)
	var desired_velocity := Vector3.ZERO

	var strafe_scale := attack_recovery_strafe_scale
	if strafe_scale > 0.0 and attack_strafe_speed > 0.0:
		desired_velocity += (
			right_direction
			* attack_strafe_speed
			* _attack_strafe_direction
			* speed_scale
			* strafe_scale
		)

	if combat_role == EnemyCombatProfiles.Role.CLOSE:
		if distance_to_target > preferred_distance:
			desired_velocity = forward_direction * _runtime_chase_speed
	elif distance_to_target > preferred_distance + attack_approach_distance_margin:
		var approach_speed := maxf(
			attack_approach_speed * speed_scale,
			_runtime_move_speed * attack_approach_min_speed_scale
		)
		desired_velocity += forward_direction * approach_speed
	elif distance_to_target < minimum_distance:
		desired_velocity -= (
			forward_direction
			* _runtime_move_speed
			* attack_retreat_speed_scale
		)

	var maximum_speed := _runtime_chase_speed if combat_role == EnemyCombatProfiles.Role.CLOSE else _runtime_move_speed
	if desired_velocity.length() > maximum_speed:
		desired_velocity = desired_velocity.normalized() * maximum_speed

	_facing_direction = forward_direction
	rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
	if desired_velocity.length_squared() <= 0.001:
		_stop_horizontal_motion()
		return

	velocity.x = move_toward(velocity.x, desired_velocity.x, delta * movement_acceleration)
	velocity.z = move_toward(velocity.z, desired_velocity.z, delta * movement_acceleration)
	_play_directional_animation(&"walk", &"walk_back")


func _stop_horizontal_motion() -> void:
	var braking_step := braking_acceleration * get_physics_process_delta_time()
	velocity.x = move_toward(velocity.x, 0.0, braking_step)
	velocity.z = move_toward(velocity.z, 0.0, braking_step)
	if not _attack_locked:
		_play_directional_animation(&"idle", &"idle_back")


func _play_directional_animation(
	front_animation: StringName,
	back_animation: StringName
) -> void:
	var target_animation := _directional_animation(front_animation, back_animation)
	if not _has_animation(target_animation):
		return
	if animated_sprite.animation == target_animation and animated_sprite.is_playing():
		return

	var previous_frame := animated_sprite.frame
	animated_sprite.play(target_animation)
	var frame_count := animated_sprite.sprite_frames.get_frame_count(target_animation)
	if frame_count > 0:
		animated_sprite.frame = mini(previous_frame, frame_count - 1)
	_apply_frame_ground_offset()


func _directional_animation(
	front_animation: StringName,
	back_animation: StringName
) -> StringName:
	if (
		_is_observer_behind_enemy()
		and _has_animation(back_animation)
	):
		return back_animation
	return front_animation


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

	# Oyuncu yaratığın baktığı yönün ters tarafındaysa arka kareleri göster.
	# Küçük eşik, tam yandan geçerken ön/arka görselinin titremesini engeller.
	return (
		_facing_direction.dot(direction_to_observer.normalized())
		< back_view_threshold
	)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = floor_stick_velocity


func _should_use_dormant_mode() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _alerted or _attack_locked:
		return false
	if state != State.IDLE and state != State.PATROL:
		return false
	return (
		_horizontal_distance(global_position, _player.global_position)
		> dormant_distance
	)


func _enter_dormant_mode() -> void:
	if _dormant_active:
		return
	_dormant_active = true
	_player_visible = false
	_clear_path()
	velocity.x = 0.0
	velocity.z = 0.0
	_play_directional_animation(&"idle", &"idle_back")


func _exit_dormant_mode() -> void:
	if not _dormant_active:
		return
	_dormant_active = false
	_sight_check_remaining = 0.0
	_path_refresh_remaining = 0.0


func _apply_dormant_physics(delta: float) -> void:
	# Uzak ve alarma geçmemiş düşman zemindeyken CharacterBody çözümü, rota ve
	# algı çalıştırmaz. Havada doğmuşsa güvenli biçimde zemine oturmaya devam eder.
	if is_on_floor():
		velocity.y = floor_stick_velocity
		return
	_apply_gravity(delta)
	move_and_slide()


func _can_see_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var active_range := VexEnemyPerceptionRuntime.active_detection_range(
		_alerted,
		_runtime_detection_range,
		_runtime_pursuit_range,
		_damage_reaction_remaining,
		damage_reaction_range
	)
	var player_distance := _horizontal_distance(global_position, _player.global_position)
	if player_distance > active_range:
		return false
	if (not _alerted or state == State.SEARCH) and not _is_player_inside_initial_view():
		return false
	if not _check_line_of_sight():
		return false
	return VexEnemyPerceptionRuntime.passes_crouch_detection(
		_alerted,
		_player.get("is_crouching") == true,
		player_distance,
		crouch_guaranteed_detection_distance,
		crouch_detection_chance
	)

func _is_player_inside_initial_view() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return VexEnemyPerceptionRuntime.is_player_inside_initial_view(
		global_position,
		_facing_direction,
		_player.global_position,
		initial_view_angle
	)

func _check_line_of_sight() -> bool:
	if _player == null or not is_instance_valid(_player):
		_last_visibility_ratio = 0.0
		return false
	var origin := global_position + Vector3.UP * sight_origin_height
	if _uses_ranged_tactics():
		_last_visibility_ratio = _ranged_visibility_ratio_from(origin)
		return _last_visibility_ratio > 0.0
	var has_contact := VexEnemyPerceptionRuntime.has_visual_contact(
		self,
		_player,
		origin,
		sight_collision_mask,
		sight_target_height,
		visibility_vertical_span_scale,
		visibility_vertical_span_min,
		visibility_vertical_span_max,
		visibility_lateral_span_scale,
		visibility_lateral_span_min,
		visibility_lateral_span_max,
		visibility_shoulder_height_ratio,
		visibility_lower_body_ratio
	)
	_last_visibility_ratio = 1.0 if has_contact else 0.0
	return has_contact

func _get_crouched_sight_target_height() -> float:
	return VexEnemyPerceptionRuntime.crouched_sight_target_height(
		_player,
		sight_target_height,
		crouched_target_height_scale,
		crouched_target_min_height
	)

func _is_player_collider(collider: Node) -> bool:
	return VexEnemyPerceptionRuntime.is_player_collider(_player, collider)

func _uses_ranged_tactics() -> bool:
	return ranged_visibility_sampling_enabled


func _uses_cover_reposition_tactics() -> bool:
	return cover_reposition_enabled and projectile_scene != null


func _cover_visibility_threshold() -> float:
	return ranged_cover_visibility_threshold


func _damage_source_approach_position(source_position: Vector3) -> Vector3:
	# Oyuncu duvar kenarından ateş ettiğinde karakter merkezi fiziksel olarak
	# düşmanın sığamayacağı kadar duvara yakın olabilir. Tam merkeze rota vermek
	# yerine merminin geldiği açık koridora doğru küçük bir adım öne hedefle.
	var result := source_position
	result.y = global_position.y
	var toward_enemy := global_position - result
	toward_enemy.y = 0.0
	var distance := toward_enemy.length()
	if distance > 0.001:
		var offset := minf(damage_approach_offset, distance * damage_approach_distance_ratio)
		result += (toward_enemy / distance) * offset
	return result


func _ranged_visibility_ratio_from(observer_position: Vector3) -> float:
	return VexEnemyPerceptionRuntime.ranged_visibility_ratio_from(
		self,
		_player,
		observer_position,
		sight_collision_mask,
		sight_target_height,
		visibility_vertical_span_scale,
		visibility_vertical_span_min,
		visibility_vertical_span_max,
		visibility_lateral_span_scale,
		visibility_lateral_span_min,
		visibility_lateral_span_max,
		visibility_shoulder_height_ratio,
		visibility_lower_body_ratio
	)

func _reposition_for_clear_shot(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_stop_horizontal_motion()
		return

	if (
		not _has_ranged_reposition_target
		or _ranged_reposition_remaining <= 0.0
		or _has_reached_walkable_target(_ranged_reposition_target, waypoint_reach_distance)
	):
		_has_ranged_reposition_target = false
		var forward := _player.global_position - global_position
		forward.y = 0.0
		if forward.length_squared() <= 0.001:
			forward = _facing_direction
		else:
			forward = forward.normalized()
		var right := Vector3(-forward.z, 0.0, forward.x).normalized()
		var radius := ranged_cover_reposition_distance
		var offsets: Array[Vector3] = [
			right * radius,
			-right * radius,
			right * (radius * cover_diagonal_distance_scale)
				+ forward * (radius * cover_forward_distance_scale),
			-right * (radius * cover_diagonal_distance_scale)
				+ forward * (radius * cover_forward_distance_scale),
		]
		var best_score := -INF
		for offset: Vector3 in offsets:
			var candidate := global_position + offset
			candidate.y = global_position.y
			if not _is_walk_segment_clear(global_position, candidate):
				continue
			var ratio := _ranged_visibility_ratio_from(
				candidate + Vector3.UP * sight_origin_height
			)
			var score := (
				ratio * cover_visibility_score_weight
				- offset.length() * cover_distance_score_penalty
			)
			if ratio >= _cover_visibility_threshold():
				score += cover_threshold_score_bonus
			if score > best_score:
				best_score = score
				_ranged_reposition_target = candidate
				_has_ranged_reposition_target = true
		_ranged_reposition_remaining = (
			ranged_cover_reposition_refresh
			if _has_ranged_reposition_target
			else cover_failed_retry_interval
		)
		if _has_ranged_reposition_target:
			_clear_path()
			_path_refresh_remaining = 0.0

	if _has_ranged_reposition_target:
		_navigate_to(_ranged_reposition_target, delta)
	elif _has_last_seen_position:
		_navigate_to(_last_seen_position, delta)
	else:
		_stop_horizontal_motion()


func _attempt_attack() -> void:
	if _attack_locked:
		return
	var combat_generation := _combat_interrupt_generation
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	if _has_animation(&"attack"):
		animated_sprite.play(&"attack")
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.play()

	await get_tree().create_timer(_runtime_attack_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	if _player != null and is_instance_valid(_player):
		var still_in_range := (
			_horizontal_distance(global_position, _player.global_position)
			<= attack_range + attack_range_tolerance
		)
		if still_in_range and _check_line_of_sight():
			_fire_projectile()
	_attack_windup_active = false
	if attack_approach_speed > 0.0 or attack_strafe_speed > 0.0:
		_play_directional_animation(&"walk", &"walk_back")
	else:
		_play_directional_animation(&"idle", &"idle_back")

	var remaining := maxf(
		0.0,
		_runtime_attack_cooldown - _runtime_attack_windup
	)
	await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	var projectile := projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	var spawn_right := _facing_direction.cross(Vector3.UP)
	if spawn_right.length_squared() <= 0.001:
		spawn_right = Vector3.RIGHT
	else:
		spawn_right = spawn_right.normalized()
	var spawn_forward := _facing_direction
	if spawn_forward.length_squared() <= 0.001:
		spawn_forward = -global_transform.basis.z
	else:
		spawn_forward = spawn_forward.normalized()
	projectile.global_position = (
		global_position
		+ Vector3.UP * projectile_spawn_height
		+ spawn_right * projectile_spawn_side_offset
		+ spawn_forward * projectile_spawn_forward_offset
	)
	var target_position := (
		_player.global_position
		+ Vector3.UP * projectile_target_height
	)
	var projectile_speed := maxf(float(projectile.get("speed")), 0.1)
	var target_velocity := Vector3.ZERO
	if _player is CharacterBody3D and projectile_lead_factor > 0.0:
		target_velocity = (_player as CharacterBody3D).velocity
		target_velocity.y = 0.0
	var travel_time := minf(
		_calculate_intercept_time(
			projectile.global_position,
			target_position,
			target_velocity,
			projectile_speed
		),
		projectile_max_lead_time
	)
	if projectile_lead_factor > 0.0:
		target_position += target_velocity * travel_time * projectile_lead_factor
	var shot_direction := (target_position - projectile.global_position).normalized()
	projectile.call("launch", shot_direction, self, _runtime_attack_damage)


func _calculate_intercept_time(
	projectile_position: Vector3,
	target_position: Vector3,
	target_velocity: Vector3,
	projectile_speed: float
) -> float:
	var displacement := target_position - projectile_position
	var fallback_time := displacement.length() / maxf(projectile_speed, 0.1)
	var quadratic_a := target_velocity.length_squared() - projectile_speed * projectile_speed
	var quadratic_b := 2.0 * displacement.dot(target_velocity)
	var quadratic_c := displacement.length_squared()
	if quadratic_c <= 0.0001:
		return 0.0
	if absf(quadratic_a) <= 0.0001:
		if absf(quadratic_b) <= 0.0001:
			return fallback_time
		var linear_time := -quadratic_c / quadratic_b
		return linear_time if linear_time > 0.0 else fallback_time

	var discriminant := (
		quadratic_b * quadratic_b
		- 4.0 * quadratic_a * quadratic_c
	)
	if discriminant < 0.0:
		return fallback_time
	var discriminant_root := sqrt(discriminant)
	var denominator := 2.0 * quadratic_a
	var first_time := (-quadratic_b - discriminant_root) / denominator
	var second_time := (-quadratic_b + discriminant_root) / denominator
	var intercept_time := -1.0
	if first_time > 0.0:
		intercept_time = first_time
	if second_time > 0.0 and (intercept_time < 0.0 or second_time < intercept_time):
		intercept_time = second_time
	return intercept_time if intercept_time > 0.0 else fallback_time


func _clear_path() -> void:
	_current_path = PackedVector3Array()
	_path_index = 0
	_has_path_target = false


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
	var death_animation := _directional_animation(&"death", &"death_back")
	state = State.DEAD
	_clear_damage_shake(animated_sprite)
	velocity = Vector3.ZERO
	_snap_body_to_floor(floor_snap_max_correction)
	_attack_locked = true
	_attack_windup_active = false
	_clear_path()
	collision_shape.set_deferred("disabled", true)
	if death_audio.stream != null:
		death_audio.play()
	var death_duration := maxf(_get_animation_duration(death_animation), death_fall_time)
	if _has_animation(death_animation):
		animated_sprite.play(death_animation)
		_apply_frame_ground_offset()
	else:
		animated_sprite.pause()
	_place_corpse_on_floor(true)
	GameState.register_enemy_defeated(enemy_id)
	await get_tree().create_timer(death_duration).timeout
	if not is_inside_tree():
		return
	if _has_animation(death_animation):
		animated_sprite.pause()
		animated_sprite.frame = maxi(0, animated_sprite.sprite_frames.get_frame_count(death_animation) - 1)
	_apply_frame_ground_offset()
	await get_tree().create_timer(corpse_hold_duration).timeout
	if not is_inside_tree():
		return
	_finalize_death_visual()


func _restore_defeated_state() -> void:
	state = State.DEAD
	_clear_damage_shake(animated_sprite)
	velocity = Vector3.ZERO
	_attack_locked = true
	_attack_windup_active = false
	_clear_path()
	collision_shape.set_deferred("disabled", true)
	var death_animation := _directional_animation(&"death", &"death_back")
	if not _has_animation(death_animation):
		animated_sprite.pause()
		_finalize_death_visual()
		return
	animated_sprite.animation = death_animation
	animated_sprite.frame = maxi(
		0,
		animated_sprite.sprite_frames.get_frame_count(death_animation) - 1
	)
	animated_sprite.pause()
	_finalize_death_visual()


func _get_animation_duration(animation_name: StringName) -> float:
	if animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return 0.0
	var speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.001:
		return 0.0
	return float(frame_count) / speed


func _place_corpse_on_floor(animated: bool) -> void:
	var target_y := (
		back_corpse_visual_y
		if animated_sprite.animation == &"death_back"
		else corpse_visual_y
	) + corpse_floor_clearance
	if not animated:
		animated_sprite.position.y = target_y
		return

	var fall_tween := create_tween()
	fall_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(
		animated_sprite,
		"position:y",
		target_y,
		death_fall_time
	)
