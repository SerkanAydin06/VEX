@tool
class_name VexWardenAbilitySettings
extends VexEnemyAbilitySettings

@export_category("Ground Slam")
## Ground Slam etkisini oluşturan sahnedir.
@export var ground_slam_scene: PackedScene
## Oyuncu bu yatay mesafeye girdiğinde Ground Slam seçilebilir (metre).
@export_range(1.0, 10.0, 0.1) var ground_slam_trigger_range := 5.2
## Ground Slam'in hasar ve etki yarıçapıdır (metre).
@export_range(1.0, 10.0, 0.1) var ground_slam_radius := 4.6
## Ground Slam'in zorluk çarpanından önceki temel hasarıdır.
@export_range(1, 200, 1) var ground_slam_damage := 42
## İki Ground Slam arasındaki temel bekleme süresidir (saniye).
@export_range(0.2, 10.0, 0.05) var ground_slam_cooldown := 2.7
## Slam hasarı çıkmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 2.0, 0.01) var ground_slam_windup := 0.58
## Slam sonrasında Warden'ın yeniden hareket etmeden önce beklediği süredir (saniye).
@export_range(0.0, 3.0, 0.05) var ground_slam_recovery := 0.85
## Kamera sarsıntısının oyuncuyu etkileyebileceği yarıçaptır (metre).
@export_range(1.0, 16.0, 0.5) var ground_slam_shake_radius := 8.5
## Ground Slam kamera sarsıntısının şiddetidir.
@export_range(0.0, 0.3, 0.005) var ground_slam_shake_strength := 0.075
## Ground Slam kamera sarsıntısının süresidir (saniye).
@export_range(0.0, 1.5, 0.05) var ground_slam_shake_duration := 0.42
## Zemin efektlerinin yüzey ararken çarpışacağı fizik katmanlarıdır.
@export_flags_3d_physics var ground_effect_collision_mask := 1
## Zemin ışınının yetenek merkezinin ne kadar üstünden başlayacağıdır (metre).
@export_range(0.1, 4.0, 0.1) var ground_probe_height := 1.0
## Zemin ışınının aşağı doğru tarayacağı mesafedir (metre).
@export_range(0.5, 6.0, 0.1) var ground_probe_depth := 2.8
## Zemin efektini yüzeyin biraz üstünde tutan paydır (metre).
@export_range(0.0, 0.2, 0.01) var ground_effect_surface_offset := 0.035
## Zemin bulunamazsa efekt merkezine uygulanacak aşağı kaymadır (metre).
@export_range(0.0, 3.0, 0.05) var ground_effect_fallback_drop := 0.90
## Ground Slam'in düşman işitme sistemine yaydığı gürültü katsayısıdır.
@export_range(0.0, 3.0, 0.05) var ground_slam_noise_loudness := 1.50

@export_category("Heatwave")
## Heatwave halkasında çoğaltılacak mermi sahnesidir.
@export var heatwave_projectile_scene: PackedScene
## Warden bu yatay mesafeye ulaştığında Heatwave başlatır (metre).
@export_range(0.5, 5.0, 0.05) var heatwave_trigger_range := 1.65
## Bir Heatwave halkasında üretilecek mermi sayısıdır.
@export_range(4, 24, 1) var heatwave_projectile_count := 12
## Her Heatwave mermisinin zorluk çarpanından önceki temel hasarıdır.
@export_range(1, 100, 1) var heatwave_damage := 18
## Heatwave mermilerinin hareket hızıdır (metre/saniye).
@export_range(1.0, 30.0, 0.5) var heatwave_projectile_speed := 8.5
## Heatwave mermilerinin otomatik silinmeden önceki ömrüdür (saniye).
@export_range(0.25, 4.0, 0.05) var heatwave_projectile_lifetime := 1.45
## Mermilerin Warden merkezinden doğacağı halka yarıçapıdır (metre).
@export_range(0.0, 1.0, 0.05) var heatwave_spawn_radius := 0.35
## İki Heatwave arasındaki temel bekleme süresidir (saniye).
@export_range(0.2, 10.0, 0.05) var heatwave_cooldown := 4.8
## Heatwave mermileri çıkmadan önceki hazırlık süresidir (saniye).
@export_range(0.05, 2.0, 0.01) var heatwave_windup := 0.50
## Heatwave sonrasındaki hareket kilidi süresidir (saniye).
@export_range(0.0, 3.0, 0.05) var heatwave_recovery := 0.75
## Heatwave hazırken oyuncuya yaklaşma hızına uygulanan çarpandır.
@export_range(0.5, 2.0, 0.05) var heatwave_approach_speed_multiplier := 1.20
## Heatwave beklemedeyken Warden'ın durmayı tercih ettiği mesafenin menzile oranıdır.
@export_range(0.0, 1.0, 0.05) var heatwave_cooldown_hold_ratio := 0.85
## Heatwave beklemedeyken yaklaşma hızına uygulanan çarpandır.
@export_range(0.1, 2.0, 0.05) var heatwave_cooldown_approach_speed_multiplier := 0.90
## Yaklaşma ilerlemezse rota yenilenmeden önce beklenecek süredir (saniye).
@export_range(0.3, 3.0, 0.05) var heatwave_approach_stall_timeout := 0.90
## Yaklaşmanın başarılı sayılması için gereken en az konum veya mesafe ilerlemesidir (metre).
@export_range(0.05, 0.5, 0.01) var heatwave_approach_min_progress := 0.12
## Heatwave'in düşman işitme sistemine yaydığı gürültü katsayısıdır.
@export_range(0.0, 3.0, 0.05) var heatwave_noise_loudness := 1.25
## Açıksa Heatwave halkasının başlangıç açısı her saldırıda rastgele seçilir.
@export var heatwave_randomize_rotation := true
## Heatwave animasyon karelerinin dikey hizalama düzeltmeleridir; eleman sırası kare sırasıdır.
@export var heatwave_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])

@export_category("Zırhlı Zayıf Nokta")
## İsabet bu yerel yüksekliğin üstündeyse Warden kafa vuruşu hasarı alır (metre).
@export_range(0.5, 3.0, 0.05) var headshot_local_height := 1.15
