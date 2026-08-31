@tool
class_name VexGorehornChargeSettings
extends VexEnemyAbilitySettings

@export_category("Boynuz Şarjı")
## Şarj sırasında oyuncuyla temasın kesin vuruş sayılacağı yatay mesafedir (metre).
@export_range(0.5, 2.5, 0.05) var hit_distance := 1.10
## Yakınlık tabanlı boynuz temasının geçerli sayılacağı en yüksek dikey kök farkıdır (metre).
## Gerçek CharacterBody3D çarpışmaları bu toleranstan bağımsızdır; bu ayar yalnız katlar arasından yanlış vuruşu engeller.
@export_range(0.5, 3.0, 0.05) var vertical_hit_tolerance := 1.50
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
@export_range(0.0, 1.0, 0.01) var impact_shake_duration := 0.34

@export_category("Darbe Perdesi")
## Başarılı boynuz darbesinde kısa, koyu bir ekran darbe perdesi gösterilip gösterilmeyeceğini belirler.
@export var impact_shock_enabled := true
## Darbe perdesinin rengidir; koyu kırmızı-siyah tonlar göz yormadan ağır çarpışma hissi verir.
@export var impact_shock_color := Color(0.055, 0.0, 0.0, 1.0)
## Darbe perdesinin en yüksek görünürlüğüdür; 1 ekranı tamamen kapatır.
@export_range(0.0, 0.75, 0.01) var impact_shock_peak_alpha := 0.38
## Darbe perdesinin hızlı yükselip kaybolacağı toplam süredir (saniye).
@export_range(0.05, 0.8, 0.01) var impact_shock_duration := 0.24
