@tool
class_name VexFurniceCarrierAbilitySettings
extends VexEnemyAbilitySettings

@export_category("Saldırı Seçimi")
## Oyuncu bu mesafenin içindeyse hazır olan Thermal Burst tercih edilir (metre).
@export_range(0.5, 12.0, 0.1) var close_attack_threshold := 6.0
## İki normal mermi saldırısı arasındaki temel bekleme süresidir (saniye).
@export_range(0.2, 6.0, 0.05) var projectile_attack_cooldown := 1.80
## Normal mermi çıkmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 2.0, 0.05) var projectile_attack_windup := 0.45
## Merminin yerde bıraktığı etkinin her vuruştaki temel hasarıdır.
@export_range(1, 100, 1) var projectile_decal_tick_damage := 4
## Mermi çıkışının saldırı karesindeki piksel konumudur; X sağa, Y aşağı yöndedir.
@export var projectile_muzzle_sprite_offset_pixels := Vector2(0.0, -139.0)
## Mermi çıkışını bakış yönünde öne taşıyan derinlik payıdır (metre).
@export_range(0.0, 0.5, 0.01) var projectile_muzzle_depth_offset := 0.08

@export_category("Thermal Burst")
## Yakın alan Thermal Burst efektini oluşturan sahnedir.
@export var thermal_burst_scene: PackedScene
## Thermal Burst'ün zorluk çarpanından önceki temel hasarıdır.
@export_range(1, 100, 1) var thermal_burst_damage := 22
## İki Thermal Burst arasındaki temel bekleme süresidir (saniye).
@export_range(0.2, 8.0, 0.05) var thermal_burst_cooldown := 3.20
## Thermal Burst çıkmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 2.0, 0.05) var thermal_burst_windup := 0.50
## Thermal Burst animasyon karelerinin dikey hizalama düzeltmeleridir.
@export var thermal_burst_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
## Zemin efektinin yüzey ararken çarpışacağı fizik katmanlarıdır.
@export_flags_3d_physics var ground_effect_collision_mask := 1
## Zemin ışınının efekt merkezinin ne kadar üstünden başlayacağıdır (metre).
@export_range(0.1, 4.0, 0.1) var ground_probe_height := 1.0
## Zemin ışınının aşağı doğru tarayacağı mesafedir (metre).
@export_range(0.5, 6.0, 0.1) var ground_probe_depth := 2.5
## Thermal Burst efektini yüzeyin biraz üstünde tutan paydır (metre).
@export_range(0.0, 0.2, 0.01) var ground_effect_surface_offset := 0.03
