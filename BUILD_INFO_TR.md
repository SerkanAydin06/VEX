# VEX // Yapı Bilgisi

- Yapı: `COMPLETE BUILD 3.1.1`
- Oyun sürümü: `3.1.1`
- Godot hedefi: `4.5` / GL Compatibility
- Başlangıç sahnesi: `res://scenes/ui/splash_screen.tscn`
- Oyun akışı: `VEX-01 → sonuç ekranı → VEX-02 → sonuç ekranı`
- Görsel biçimi: çalışma zamanındaki görseller PNG; SVG bağımlılığı yok
- Kayıt sistemi: kapalı; ölümde mevcut bölüm baştan ve 100 canla açılır

## VEX-01 // Karantina Tesisi

- Harita sürümü: `VEX01-R26-PRO-AUTOMAP`
- Alan: `36 × 60` dünya birimi; `3 × 6 = 18` oda
- Harita kaynağı: canlı oda/kapı verisi; keşif sisi ve oyuncu yönü çalışma anında çizilir
- İçerik: 71 geometri parçası, 19 kapı, 28 düşman yerleşimi, 22 pickup, 4 patlayıcı varil, 18 rota noktası ve 38 kırmızı duvar lambası
- Zorluk başına düşman: Kolay 11, Normal 18, Zor 23, Kâbus 28
- Zorluk başına pickup: Kolay 22, Normal 16, Zor 12, Kâbus 9
- Final koşulu: mavi + kırmızı anahtar ve nihai muhafız
- Gizli alan: 0

## VEX-02 // Kırık Omurga

- Harita sürümü: `VEX02-R46-PRO-AUTOMAP`
- Harita ızgarası: `9 × 7`; dünya sınırı `72 × 56`; 33 yürünebilir hücre
- Harita kaynağı: canlı oda/kapı verisi; bitiş, başlangıç ve kilitler aynı koordinat sistemindedir
- İçerik: 195 geometri parçası, 5 kapı, 31 düşman yerleşimi, 24 pickup, 6 patlayıcı varil, 33 rota noktası ve 10 kırmızı duvar lambası
- Zorluk başına düşman: Kolay 14, Normal 20, Zor 26, Kâbus 31
- Zorluk başına pickup: Kolay 24, Normal 18, Zor 14, Kâbus 11
- Gizli alan: 2; gizli AK-47 ve MP90 rotaları
- Final koşulu: iki anahtar ve `v2_badredviper_final_guard`

## Üretim düzeltmeleri

- `finish_switch` adı ve yolları tek biçime getirildi; Level 1'in Level 2 yolunu `complete_level(next_level_path)` akışına aktarması sağlandı.
- Kapılarda tekli/çoklu anahtar, özel anahtar etiketi ve açılma sonrası görev alanları çalışır hâle getirildi.
- HUD sahne UID uyarıları kaldırıldı; iki bölümün haritası gerçek PNG oda sınırlarına piksel hassasiyetinde bağlandı ve en-boy oranı korunarak ortalandı.
- AK-47 ve MP90 HUD kareleri silah alınana kadar yüklenmez.
- RedViper hızı ve saldırı menzili dengelendi; görüş/mesafe yeniden doğrulaması, yakın müttefik uyarısı ve duvar çarpışması yan geçişi eklendi.
- Pickup görselleri yalnızca Y ekseninde kameraya döner; yandan kaybolmaz ve kamera yüksekliğine eğilmez. Variller sabit kalır; kırmızı lambalar dar açılı `SpotLight3D` kullanır.
- Dört düşmanın 96 animasyon karesi ortak karanlık palete ve tek zemin satırına getirildi. Ravager/RedViper normal insan, BadRedViper orta, HellMagma mevcut büyük boy sınıfındadır; sprite, kapsül, görüş/atış noktası ve temas gölgesi birlikte hizalandı.
- Düşman billboard'ları ortam ışığını alır, fakat performans için dinamik gölge üretmez; ortak düşük maliyetli temas gölgesi kullanır. Kapı açılma yüksekliği HellMagma'ya güvenli görsel ve fizik payı bırakacak şekilde `4,2 m` oldu.
- Gece görüşü test üretimi kaldırıldı ve Level 1 sahnesinde gerçek pickup olarak yerleştirildi.
- Kullanılmayan Shardskin prototip kareleri, eski tek-kare AK ateşi, hitmarker, mavi lamba ve artık bağlı olmayan eski prop/duvar kaynakları teslim paketinden çıkarıldı.

## Performans Paketi 1

- GL Compatibility korunarak proje oklüzyon sistemi etkinleştirildi. Yalnız duvar profilleri basit kutu oklüder üretir; zemin/tavan oklüder CPU maliyetine eklenmez.
- Kapı oklüderi açılma başlar başlamaz kapanır ve yalnız kapı tam kapandığında yeniden etkinleşir.
- 48 duvar lambası, iki mermi ışığı ve varil patlama ışığı uzaklık LOD'u kullanır. Ravager/HellMagma mermi ışıklarının dinamik gölgesi kapalıdır.
- Dört düşman tipi sahneden ayarlanabilir `dormant_distance` ile uzakta pasifleşir. Viper görüş ışınları önbellekli aralıklarla, Ravager/HellMagma ışınları kademeli aralıklarla çalışır.
- Ayarlar menüsündeki `3B GÖRÜNTÜ KALİTESİ` seçimi 3B dünya için `0,75 / 0,85 / 1,00` ölçeklerini anında uygular; HUD ve nişangah tam çözünürlükte kalır.
- Harita konumu ve etkileşim metni sorguları 20 Hz'de örneklenir; nişangah, hasar geri bildirimi ve silah animasyonları kare hızında kalır.
