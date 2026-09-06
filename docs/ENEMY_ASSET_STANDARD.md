# VEX Enemy Asset Standard

Bu belge, VEX'te bundan sonra üretilecek ve oyuna entegre edilecek yaratık karakter kareleri ile world-space ve screen-space VFX karelerinin sabit boyut standardıdır.

## 1. Karakter animasyon kareleri

Kaynak görselin yönü ne ise runtime kare aynı en-boy oranını korur:

| Kaynak yönü | Kaynak/master örneği | Canonical runtime frame |
| --- | ---: | ---: |
| Dikey (portrait) | 1024 x 1536 | **512 x 768** |
| Yatay (landscape) | 1536 x 1024 | **768 x 512** |

Kurallar:

- Tüm karakter kareleri PNG ve tamamen şeffaf arka planlıdır.
- Yeni standart karakter canvas boyutu yukarıdaki ölçülerden biri olmalıdır.
- Görsel esnetilmez; kaynak en-boy oranı korunur.
- Karakter alfa sınırına göre her kare ayrı ayrı crop edilmez. Aynı animasyon setindeki kareler ortak, sabit canvas kullanır.
- Baş, uzuv, silah, saldırı parlaması veya ölüm parçaları canvas dışında kesilmez.
- Yaratığın dünya boyutu texture çözünürlüğüyle değil sahnedeki `AnimatedSprite3D.pixel_size` ve frame Y offset kalibrasyonuyla belirlenir.
- Yeni veya yeniden boyutlandırılmış sheet entegre edilirken atlas region'ları, `pixel_size` ve `*_frame_y_offsets` yeni frame ölçülerine göre doğrulanır.
- Mevcut bir yaratığın kaynak en-boy oranı canonical portrait/landscape oranına uymuyorsa görsel körlemesine esnetilmez. Dedicated art re-export yapılana kadar o yaratığın mevcut sabit frame oranı per-enemy istisna olarak korunabilir.

## 2. Karakter spritesheet düzeni

Canonical temel düzen **4 sütun x 6 satır**dır:

1. `idle`
2. `walk`
3. `attack`
4. `death`
5. `idle_back`
6. `walk_back`

Her satırda varsayılan olarak 4 frame bulunur.

Buna göre temel sheet ölçüleri:

| Frame tipi | 4 x 6 sheet |
| --- | ---: |
| Portrait `512 x 768` | **2048 x 4608** |
| Landscape `768 x 512` | **3072 x 3072** |

Bir yaratıkta `attack_close`, özel yetenek veya başka ek animasyon satırı varsa frame boyutu değişmez; yalnız satır sayısı artar. Örneğin 7 satırlı bir portrait sheet `2048 x 5376` olur.

## 3. World-space projectile / impact / decal / effect kareleri

Master effect kaynakları 1254 x 1254 olabilir. 3D dünya içinde kullanılan normal enemy VFX için canonical runtime kare:

**256 x 256 px**

Bu ölçü normal world-space enemy effect türleri için ortaktır:

- projectile
- projectile trail frame
- impact
- ground decal
- explosion / burst
- charge / cast effect
- diğer 3D enemy VFX sprite kareleri

Kurallar:

- PNG ve şeffaf arka plan kullanılır.
- Normal runtime world VFX frame **256 x 256** canvas'tır.
- Effect görseli alfa sınırına göre canvas'tan kırpılıp farklı ölçüye dönüştürülmez.
- Animasyonun frame sayısı serbesttir; sheet grid'i frame sayısına göre belirlenir.
- Yalnız çok büyük boss veya 3D dünyada çok geniş görünen özel VFX gerçekten ihtiyaç duyuyorsa **512 x 512** world-space istisnası kullanılabilir. Normal projectile / impact / decal için 512 kullanılmaz.
- **512 x 512 world-space istisnası, tam ekran HUD/Canvas efektleri için kullanılmaz.** Tam ekran efektlerin ayrı standardı aşağıdadır.

Örnek 256 px sheet ölçüleri:

| Grid | Sheet ölçüsü |
| --- | ---: |
| 4 x 1 | 1024 x 256 |
| 2 x 2 | 512 x 512 |
| 4 x 2 | 1024 x 512 |
| 4 x 4 | 1024 x 1024 |

## 4. Screen-space / full-screen enemy VFX

Oyuncunun görüşünü doğrudan HUD / `CanvasLayer` / `TextureRect` üzerinden kaplayan veya bozan efektler world-space VFX değildir. Bu sınıf için canonical runtime frame:

**1280 x 720 px (16:9)**

Örnek kullanım:

- zehir / enfeksiyon görüş efekti
- ekran üstü kan, slime veya corruption overlay'i
- tam ekran hit/debuff görseli

Kurallar:

- Frame en-boy oranı **16:9** tutulur.
- `TextureRect` ile ekranı kaplayan efektlerde `STRETCH_KEEP_ASPECT_COVERED` kullanılabilir; böylece farklı ekran oranlarında boşluk kalmaz.
- Şeffaf PNG tercih edilir. Ancak görsel tasarım bilinçli olarak tüm kareyi kaplıyorsa opaque kaynak frame kullanılabilir ve yoğunluk runtime alpha/modulate ile kontrol edilir.
- Screen-space sheet, frame sayısına göre yatay veya çok satırlı düzenlenebilir. Örneğin 4 frame için **5120 x 720 (4 x 1)**; 8 frame için **5120 x 1440 (4 x 2)** kullanılabilir.
- Full-screen VFX 3D billboard olmadığı için world-space `pixel_size` kuralına tabi değildir.
- Full-screen VFX importunda VRAM compression kullanılabilir; native/near-native ekran çiziminde gereksiz mipmap belleğini önlemek için mipmap varsayılan olarak kapalı tutulabilir.

## 5. Dosya ve import standardı

- Dosya adları lowercase `snake_case` kullanır.
- Runtime enemy asset'leri `assets/enemies/<enemy_id>/` altında tutulur.
- Yüksek çözünürlüklü orijinal/master dosyalar istenirse `art_source/enemies/<enemy_id>/` altında arşivlenebilir. `art_source/.gdignore` nedeniyle Godot bunları import etmez.
- Oyun scene'leri yalnız runtime asset'lere referans verir; `art_source` dosyalarına referans verilmez.
- 3D enemy sprite filtreleme standardı mevcut proje standardıyla uyumlu olarak Linear Mipmap + Fixed-Y billboard'dur.

## 6. Bundan sonra üretim kuralı

Yeni görsel hazırlanırken mümkünse doğrudan canonical runtime frame boyutunda teslim edilir:

- Dikey karakter: **512 x 768**
- Yatay karakter: **768 x 512**
- Normal world-space projectile / impact / decal / enemy effect: **256 x 256**
- Büyük boss / çok geniş world-space özel VFX istisnası: **512 x 512**
- Tam ekran HUD / Canvas enemy VFX: **1280 x 720**

Böylece ayrı bir runtime küçültme pipeline'ına ihtiyaç duyulmaz. Yüksek çözünürlüklü master üretmek istenirse master ayrıca saklanabilir; oyuna giren kopya yine ilgili canonical runtime ölçüsüne dönüştürülür.

## 7. Geçiş kuralı

Bu belge yeni canonical hedeftir. Eski enemy asset'leri topluca körlemesine resize edilmez. Her yaratık kendi sheet'i güncellendiğinde yeni frame standardına geçirilir ve scene atlas / pixel size / ground-contact veya hover kalibrasyonu birlikte güncellenir. Kaynak oranı canonical standarda uymayan özel bir mevcut yaratık, yeni uygun art üretilene kadar esnetilmeden kendi sabit oranıyla tutulur.
