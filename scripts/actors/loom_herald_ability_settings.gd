@tool
class_name VexLoomHeraldAbilitySettings
extends VexEnemyAbilitySettings

@export_category("01 - Çift El Örgüsü")
## İki el arasındaki yatay yarı açıklıktır (metre); attack 3 görselindeki enerji odaklarına göre ayarlanır.
@export_range(0.1, 0.8, 0.01) var emitter_half_span := 0.36
## İki projectile'ın merkez doğrultudan dışa açıldığı yarım açıdır (derece).
@export_range(0.0, 8.0, 0.25) var volley_half_angle_degrees := 2.5
## Her bir projectile'ın normal saldırı hasarından aldığı paydır.
@export_range(0.2, 1.0, 0.05) var projectile_damage_scale := 0.65
