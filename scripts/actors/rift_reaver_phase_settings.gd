@tool
class_name VexRiftReaverPhaseSettings
extends VexEnemyAbilitySettings

@export_category("01 - Rift Phase")
## Rift Reaver saldırı öncesi ve sonrası güvenli kısa faz adımı kullanır.
@export var enabled := true
## Saldırıdan hemen önce oyuncunun çevresinde kaç derece yana fazlanacağını belirler.
@export_range(10.0, 60.0, 1.0) var pre_attack_arc_degrees := 32.0
## Saldırı öncesi fazın oyuncudan korumaya çalıştığı yatay yarıçaptır (metre).
@export_range(1.10, 1.95, 0.05) var pre_attack_radius := 1.65
## Saldırı bittikten sonra faz adımının oyuncu çevresindeki açısıdır (derece).
@export_range(5.0, 45.0, 1.0) var recovery_arc_degrees := 20.0
## Saldırı sonrası fazın oyuncudan hedeflediği yatay yarıçaptır (metre).
@export_range(2.05, 3.20, 0.05) var recovery_radius := 2.65
## Faz varış noktasının oyuncuya yaklaşabileceği en düşük yatay mesafedir (metre).
@export_range(0.80, 1.80, 0.05) var minimum_player_distance := 1.10
## Tek bir faz adımının eski konumdan gidebileceği en yüksek yatay mesafedir (metre).
@export_range(0.50, 2.50, 0.05) var maximum_step_distance := 1.85
## Hedef noktada zemin aramasının gövde kökünün ne kadar üstünden başlayacağıdır (metre).
@export_range(0.10, 1.00, 0.05) var floor_probe_height := 0.50
## Zemin ışınının başlangıçtan aşağı doğru tarayacağı toplam derinliktir (metre).
@export_range(0.50, 3.00, 0.05) var floor_probe_depth := 1.80
## Faz sırasında kabul edilen en yüksek zemin seviye farkıdır (metre); büyük basamak/kat atlamayı engeller.
@export_range(0.10, 1.00, 0.05) var maximum_floor_height_change := 0.45
