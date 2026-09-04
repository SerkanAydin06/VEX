@tool
class_name VexVenomMarshallAbilitySettings
extends VexEnemyAbilitySettings

@export_category("01 - Alan Desteği")
## Venom Marshall'ın bulunduğu zeminde güçlendirme alanı kuran skill sahnesidir.
@export var buff_projectile_scene: PackedScene
## Marshall merkezli buff alanını kurmayı tetikleyecek en uzak müttefik mesafesidir.
@export_range(2.0, 15.0, 0.5) var buff_cast_range := 7.0
## İki alan skill'i arasındaki temel bekleme süresidir (saniye).
@export_range(2.0, 30.0, 0.5) var buff_cooldown := 11.5
## Alan kurulmadan önceki ikinci saldırı hazırlık süresidir (saniye).
@export_range(0.05, 3.0, 0.05) var buff_windup := 0.65
## Alan kurulduktan sonra normal state machine'e dönüş süresidir (saniye).
@export_range(0.0, 4.0, 0.05) var buff_recovery := 0.80
## Mevcut buff'ın bitmesine bu kadar süre kaldığında alan yenilenebilir (saniye).
@export_range(0.0, 3.0, 0.1) var buff_refresh_window := 1.2

@export_category("02 - Görsel Hizalama")
## İkinci saldırı karelerinin zemin hizalama düzeltmeleridir; eleman sırası frame sırasıdır.
@export var second_attack_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
