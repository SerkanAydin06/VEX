class_name WeaponDefinition
extends Resource

@export var weapon_id: StringName = &"p01"
@export var display_name := "TABANCA"
@export var ammo_type: StringName = &"bullets"

@export_category("Cephanelik ve Teçhizat")
@export var loadout_group: StringName = &"sidearm"
@export_range(1, 8, 1) var loadout_slot := 1
@export var loadout_group_label := "ARMORY_GROUP_SIDEARM"

@export_category("HUD ve Sunum")
@export var hud_slot_label_key := "HUD_SLOT_UNKNOWN"
@export var hud_ammo_label_key := "HUD_AMMUNITION"
@export var hud_view_scene: PackedScene
@export var world_pickup_texture: Texture2D
@export var supports_ads_pose := false
## ADS FOV'u oyuncunun normal FOV'una oranlıdır. 0.80 = hafif zoom,
## 0.58 = daha güçlü precision zoom. Böylece kullanıcı FOV ayarı zoom miktarını bozmaz.
@export_range(0.35, 0.95, 0.01) var ads_fov_multiplier := 0.70
@export var supports_lowered_pose := false
@export var hud_auto_lower_enabled := false
@export_range(1.0, 30.0, 0.5) var hud_lower_after_seconds := 6.0
## Aynı canvas üzerinde elle hizalanmış animasyon karelerinin kendi hareketini korur.
## true iken el/şarjör/kovan/flash gibi geçici alpha alanları tüm silahı yeniden merkezlemez.
@export var hud_preserve_authored_frame_motion := false
## ADS silah görselinin mikro hizasıdır. Reticle ve mermi merkezi sabit kalır.
## +X silah/arpacığı sağa, -X sola; +Y aşağı, -Y yukarı taşır.
@export var hud_zoom_offset := Vector2.ZERO
## ADS pozu, ölçülmüş nişan noktasını ekran merkezinde sabit tutarak bu oranla büyütülür.
## 1.0 = normal HUD ölçeği; 1.30 = ADS görselini yaklaşık %30 büyütür.
@export_range(1.0, 1.5, 0.01) var hud_ads_scale_multiplier := 1.0
## small_cross = gez/arpacık; red_dot = optik pencere.
@export_enum("small_cross", "red_dot") var hud_ads_reticle_style := "small_cross"
@export var hud_aim_fire_offset := Vector2.ZERO
## true olduğunda aim_fire karelerinin PNG içinde çizilmiş recoil hareketi korunur.
## Muzzle flash/kovan gibi geçici alpha alanları kareyi otomatik yeniden merkezlemez.
@export var hud_aim_fire_preserve_frame_motion := false
@export var hud_lowered_offset := Vector2.ZERO

@export_category("Gelecek Silah Yetenekleri")
@export var supports_flashlight := false
@export var flashlight_color := Color(0.76, 0.88, 1.0, 1.0)
@export_range(0.0, 16.0, 0.1) var flashlight_energy := 4.0
@export_range(1.0, 60.0, 0.5) var flashlight_range := 18.0
@export_range(5.0, 80.0, 0.5) var flashlight_angle_degrees := 28.0
@export var supports_alt_fire := false
@export var uses_heat := false
@export var uses_charge := false
@export_range(0.0, 10.0, 0.05) var penetration_power := 0.0
@export_range(0.0, 2.0, 0.05) var gunshot_noise_multiplier := 1.15

@export_category("Şarjör ve Atış")
@export_range(1, 100, 1) var magazine_size := 12
@export_range(1, 100, 1) var damage_per_pellet := 18
@export_category("Vuruş")
@export_range(1.0, 3.0, 0.05) var headshot_multiplier := 1.75
@export_range(1, 20, 1) var pellet_count := 1
@export_range(0.05, 2.0, 0.01) var fire_interval := 0.28
@export_range(0.1, 5.0, 0.05) var reload_duration := 1.1
@export_range(0.0, 20.0, 0.1) var spread_degrees := 1.0
@export_range(5.0, 200.0, 1.0) var maximum_range := 80.0
@export_range(1, 1000, 1) var reserve_ammo_capacity := 180
@export var automatic := false

@export_category("Sekme")
@export_range(0.0, 12.0, 0.05) var recoil_vertical_degrees := 1.0
@export_range(0.0, 6.0, 0.05) var recoil_horizontal_degrees := 0.2
@export_range(0.0, 20.0, 0.1) var recoil_max_vertical_degrees := 4.0
@export_range(0.0, 10.0, 0.1) var recoil_max_horizontal_degrees := 1.0
@export_range(0.1, 30.0, 0.1) var recoil_recovery_degrees_per_second := 7.0
