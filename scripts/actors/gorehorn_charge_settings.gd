@tool
class_name VexGorehornChargeSettings
extends VexEnemyAbilitySettings

@export_category("Boynuz Şarjı")
## Şarj sırasında oyuncuyla temasın kesin vuruş sayılacağı yatay mesafedir (metre).
@export_range(0.5, 2.5, 0.05) var hit_distance := 1.10
## Başarılı veya boşa giden şarjdan sonra Gorehorn'un yeniden hareket etmeden önce beklediği süredir (saniye).
@export_range(0.0, 2.0, 0.05) var recovery_duration := 0.75
## Duvara çarpan şarjdan sonra uygulanan daha uzun sersemleme süresidir (saniye).
@export_range(0.0, 3.0, 0.05) var blocked_recovery_duration := 1.10
## Boynuz darbesinin oyuncuya uyguladığı yatay itme hızıdır (metre/saniye).
@export_range(0.0, 20.0, 0.25) var knockback_horizontal_speed := 9.5
## Boynuz darbesinin oyuncuya uyguladığı yukarı kaldırma hızıdır (metre/saniye).
@export_range(0.0, 8.0, 0.1) var knockback_upward_speed := 2.2
## Oyuncu kontrolünün itme kuvvetini geri kazanma süresidir (saniye).
@export_range(0.05, 1.5, 0.01) var knockback_duration := 0.32
## Başarılı boynuz darbesinde kamera sarsıntısı kullanılıp kullanılmayacağını belirler.
@export var impact_shake_enabled := true
## Kamera sarsıntısının şiddetidir; genel ekran sarsıntısı ayarı kapalıysa uygulanmaz.
@export_range(0.0, 0.3, 0.005) var impact_shake_strength := 0.09
## Kamera sarsıntısının toplam süresidir (saniye).
@export_range(0.0, 1.0, 0.01) var impact_shake_duration := 0.26

