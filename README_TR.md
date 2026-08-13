# VEX 3.1.2

Godot 4.5.1 hedefiyle hazırlanmış, 2D sprite tabanlı pseudo-3D bir FPS projesidir. Paket iki oynanabilir bölüm, dört zorluk seviyesi, iki anahtarlı geri dönüşlü rota, keşif sisli TAB haritası, dört silah, gece görüşü, sabit cesetler ve zincirleme patlayan variller içerir.

## Çalıştırma

1. Klasördeki `project.godot` dosyasını Godot 4.5 ile içe aktar.
2. Ana proje sahnesini çalıştır (`F6` değil, `F5`).
3. Oyun `splash_screen.tscn` üzerinden ana menüye açılır.

`Ayarlar → 3B Görüntü Kalitesi` seçeneğinde `Yüksek` özgün çözünürlüğü, `Dengeli` daha düşük GPU yükünü, `Performans` ise en düşük 3B piksel maliyetini kullanır. HUD ve nişangah bütün profillerde tam çözünürlüktedir.

## Kontroller

| İşlem | Tuş |
| --- | --- |
| Hareket | W A S D |
| Koşu | Shift |
| Ateş | Sol fare |
| Etkileşim | E |
| Şarjör doldur | R |
| Silah seç | 1, 2, 3, 4 veya fare tekerleği |
| Tesis haritası | Tab |
| Gece görüşü | N (pickup alındıktan sonra) |
| Duraklat | Esc |

## Oyun akışı

- VEX-01: 3×6 oda düzeninde mavi ve kırmızı erişim anahtarlarını bul, nihai muhafızı indir ve `finish_switch` üzerinden VEX-02'ye geç.
- VEX-02: dallanan 9×7 labirentte anahtar rotalarını tamamla; AK-47 ve MP90 iki gizli alandadır.
- Kontrol noktası yoktur. Ölümde bölüm baştan açılır, can 100'e döner ve bölüm başlangıcındaki silah durumu korunur.
- Tab haritasında yalnızca ziyaret edilen hücreler açılır. Menüde Tab devre dışıdır.

## Proje doğrulama

`tests/integrity_test.gd` iki bölümün kritik sahne yollarını, içerik sayılarını, benzersiz kimlikleri, kapı/final ayarlarını, silah kaynaklarını, oklüzyon/ışık performans ayarlarını, 3B kalite profillerini ve geçiş zincirini denetleyen Godot bütünlük testidir.

Yapı ayrıntıları ve kesin içerik sayıları için `BUILD_INFO_TR.md`; kullanıcı tarafından sağlanan görsellerin değişim noktaları için `GORSEL_DEGISTIRME_REHBERI.md` dosyasına bak.
