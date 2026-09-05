# VEX Enemy Asset Standard

Bu belge, VEX'te bundan sonra üretilecek ve oyuna entegre edilecek yaratık karakter kareleri ile projectile / impact / decal / effect karelerinin sabit boyut standardıdır.

## 1. Karakter animasyon kareleri

Kaynak görselin yönü ne ise runtime kare aynı en-boy oranını korur:

| Kaynak yönü | Kaynak/master örneği | Canonical runtime frame |
| --- | ---: | ---: |
| Dikey (portrait) | 1024 x 1536 | **512 x 768** |
| Yatay (landscape) | 1536 x 1024 | **768 x 512** |

Kurallar:

- Tüm karakter kareleri PNG ve tamamen şeffaf arka planlıdır.
- Kare canvas boyutu yukarıdaki ölçülerden biri olmak zorundadır.
- Görsel esnetilmez; kaynak en-boy oranı korunur.
- Karakter alfa sınırına göre her kare ayrı ayrı crop edilmez. Aynı animasyon setindeki kareler ortak, sabit canvas kullanır.
- Baş, uzuv, silah, saldırı parlaması veya ölüm parçaları canvas dışında kesilmez.
- Yaratığın dünya boyutu texture çözünürlüğüyle değil sahnedeki `AnimatedSprite3D.pixel_size` ve frame Y offset kalibrasyonuyla belirlenir.
- Yeni veya yeniden boyutlandırılmış sheet entegre edilirken atlas region'ları, `pixel_size` ve `*_frame_y_offsets` yeni frame ölçülerine göre doğrulanır.

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

## 3. Projectile / impact / decal / effect kareleri

Master effect kaynakları 1254 x 1254 olabilir. Oyunda kullanılacak canonical runtime kare:

**512 x 512 px**

Bu ölçü tüm kare effect türleri için ortaktır:

- projectile
- projectile trail frame
- impact
- decal
- explosion / burst
- charge / cast effect
- diğer enemy VFX sprite kareleri

Kurallar:

- PNG ve şeffaf arka plan kullanılır.
- Runtime frame her zaman **512 x 512** canvas'tır.
- Effect görseli alfa sınırına göre canvas'tan kırpılıp farklı ölçüye dönüştürülmez.
- Animasyonun frame sayısı serbesttir; sheet grid'i frame sayısına göre belirlenir.

Örnek sheet ölçüleri:

| Grid | Sheet ölçüsü |
| --- | ---: |
| 4 x 1 | 2048 x 512 |
| 2 x 2 | 1024 x 1024 |
| 4 x 2 | 2048 x 1024 |
| 4 x 4 | 2048 x 2048 |

## 4. Dosya ve import standardı

- Dosya adları lowercase `snake_case` kullanır.
- Runtime enemy asset'leri `assets/enemies/<enemy_id>/` altında tutulur.
- Yüksek çözünürlüklü orijinal/master dosyalar istenirse `art_source/enemies/<enemy_id>/` altında arşivlenebilir. `art_source/.gdignore` nedeniyle Godot bunları import etmez.
- Oyun scene'leri yalnız runtime asset'lere referans verir; `art_source` dosyalarına referans verilmez.
- 3D enemy sprite filtreleme standardı mevcut proje standardıyla uyumlu olarak Linear Mipmap + Fixed-Y billboard'dur.

## 5. Bundan sonra üretim kuralı

Yeni görsel hazırlanırken mümkünse doğrudan canonical runtime frame boyutunda teslim edilir:

- Dikey karakter: **512 x 768**
- Yatay karakter: **768 x 512**
- Projectile / impact / decal / effect: **512 x 512**

Böylece ayrı bir runtime küçültme pipeline'ına ihtiyaç duyulmaz. Yüksek çözünürlüklü master üretmek istenirse master ayrıca saklanabilir; oyuna giren kopya yine bu canonical runtime ölçülerine dönüştürülür.

## 6. Geçiş kuralı

Bu belge yeni canonical hedeftir. Eski enemy asset'leri topluca körlemesine resize edilmez. Her yaratık kendi sheet'i güncellendiğinde yeni frame standardına geçirilir ve scene atlas / pixel size / ground-contact kalibrasyonu birlikte güncellenir.
