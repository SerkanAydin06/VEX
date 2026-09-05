@tool
class_name VexVoidweaverAbilitySettings
extends VexEnemyAbilitySettings

@export_category("01 - Enerji Örgüsü")
## Tek saldırıda aynı anda örülen projectile sayısıdır; tekli, üçlü veya beşli kullanılabilir.
@export_enum("Tekli:1", "Üçlü:3", "Beşli:5") var weave_projectile_count := 3
## En dış enerji projectile'larının merkez atıştan yatay açı farkıdır (derece).
@export_range(1.0, 12.0, 0.5) var weave_half_angle_degrees := 7.0
## Merkez dışındaki enerji projectile'larının normal saldırı hasarından aldığı paydır.
@export_range(0.2, 1.0, 0.05) var weave_side_damage_scale := 0.45
