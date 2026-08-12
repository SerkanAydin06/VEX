# VEX — Görsel Değiştirme Rehberi

Bu projedeki görseller kullanıcı tarafından sağlanan PNG dosyalarıdır. En güvenli değişim yöntemi, yeni görseli aynı ad ve aynı tuval hizasıyla mevcut dosyanın yerine koymaktır. Godot yeniden içe aktardığında sahne yolları değişmez.

## Ana görsel yolları

| Sistem | Dosya / sahne |
| --- | --- |
| Ana menü arka planı | `assets/ui/main_menu_background_v2.png` / `scenes/ui/main_menu.tscn` |
| Logo ve ikon | `assets/ui/vex_logo.png`, `assets/ui/icon.png` |
| Nişangâh | `assets/ui/crosshair_doom3_circle.png` / `scenes/ui/hud.tscn > Crosshair` |
| HUD çerçeveleri | `assets/ui/hud_frame.png`, `hud_bottom_panel.png`, `hud_objective_panel.png` |
| Kan efektleri | `assets/ui/blood_vignette_v2.png`, `blood_vignette_critical_v2.png` |
| Profesyonel harita konsolu | `assets/ui/automap_console_frame_v2.png` / `scenes/ui/hud.tscn` |
| Canlı harita çizimi | `scripts/ui/automap_view.gd` |
| Tabanca / pompalı | `assets/weapons/pistol_*_v2.png`, `shotgun_*_v2.png` |
| AK-47 / MP90 | `assets/weapons/ak47_*.png`, `mp90_*.png` |
| Ravager | `assets/enemies/Ravager/ravager_*.png` |
| Ravager mermi çarpma sesi | `assets/audio/ravager_projectile_hit_pro.wav` |
| HellMagma | `assets/enemies/HellMagma/HellMagma_*.png` |
| RedViper | `assets/enemies/redviper/redviper_*.png` |
| BadRedViper | `assets/enemies/badredviper/badredviper_*.png` |
| Pickup'lar | `assets/pickups/*.png` |
| Kapı | `assets/world/door_vex_v5.png` / `resources/materials/door_blue.tres` |
| Finish switch | `assets/world/finish_switch.png` / `scenes/props/finish_switch.tscn` |
| Varil / patlama | `assets/world/barrel_v2.png`, `explosion_v2.png` |
| Kırmızı lamba | `assets/world/wall_lamp_red.png` / `scenes/world/wall_lamp_red.tscn` |
| Duvar / zemin / tavan | `wall_panel_v2.png`, `floor_plate_v2.png`, `ceiling_panel_v2.png` |

İsabet için ayrı bir hitmarker kullanılmaz; nişangâh kısa süre kırmızıya döner.

## Silah kareleri

Her silah şu animasyon adlarını kullanır: `idle`, `fire`, `reload`, `equip`. Tuvalin alt merkez hizasını koru. AK-47 ve MP90 görselleri performans için silah ilk kez seçildiğinde yüklenir; dosya adlarını değiştirme.

- Tabanca: `620×520` temel tuval
- Pompalı: `860×560` temel tuval
- AK-47 doldurma: `ak47_reload_1..4.png`, 1,2 saniye
- MP90 doldurma: `mp90_reload_1..4.png`, 1,35 saniye

## Düşman kareleri

Ravager, HellMagma, RedViper ve BadRedViper aynı görsel standardını kullanır. Her yaratıkta `attack`, `death`, `idle`, `idle_back`, `walk` ve `walk_back` grupları bulunur; her grupta tam 4 kare vardır. Ayrı bir hurt dosyası kullanılmaz: `hurt` animasyonu aynı yaratığın `death_1` karesini paylaşır.

Tüm yaratık kareleri `543×543`, sRGBA ve saydam PNG olmalıdır. Kaynak görselin en-boy oranını bozma; görseli 543×543 saydam tuvalde yatay ortala. Alfa değeri 16'dan büyük son görünür piksel satırı bütün karelerde `Y=542` olmalıdır; böylece idle, yürüme, saldırı, hurt ve ölüm sırasında ayak/ceset zeminden sıçramaz.

Karanlık oyun renk standardı kare başına otomatik pozlama kullanmaz; bütün set aynı doğrusal-RGB `0,60` pozlama katsayısıyla işlenir. Alfa kanalı değişmez. Set toplamında görünür piksellerin yaklaşık P90 parlaklığı `100–138/255`, P99 vurgu parlaklığı `165–210/255` aralığında tutulur. Bu ortak dönüşüm animasyon sırasında parlaklık titreşimini önler; sahnedeki `AnimatedSprite3D > Shaded` ayarı da çevre ışığının yaratığa gerçek zamanlı etki etmesini sağlar. Kareler ile FPS değerleri kendi `AnimatedSprite3D > Sprite Frames` kaynağında tutulur; script çalışma anında bunları yeniden oluşturmaz.

## Düşman sahne ayarı standardı

`scenes/actors/ravager.tscn`, `scenes/actors/hellmagma.tscn`, `scenes/actors/redviper.tscn` ve `scenes/actors/badredviper.tscn` aynı düzeni kullanır. HellMagma, Ravager uzak saldırı yapay zekâsını; BadRedViper ise RedViper yakın saldırı yapay zekâsını miras alır fakat bütün temel değerlerini kendi sahnesinde bağımsız saklar. Can, hasar, hız, algılama, takip, saldırı zamanları, zorluk çarpanı, yön bulma ve animasyon davranışı gibi oyun değerleri sahnenin kök düşman düğümünde numaralı Inspector kategorilerindedir. Temel sahnedeki değerler açıkça kayıtlıdır; bir bölümdeki tek düşmanı farklı yapmak için o düşman örneğini seçip aynı alanı yerel olarak değiştir.

| Ayar türü | Inspector konumu |
| --- | --- |
| Kimlik, can ve zorluk | Kök `Ravager` / `HellMagma` / `RedViper` / `BadRedViper` > `01 - Kimlik, Can ve Zorluk` |
| Devriye/takip hızı, ivme ve yerçekimi | Kök > `02 - Hareket ve Devriye` |
| Algılama, görüş açısı ve takip | Kök > `03 - Algılama ve Takip` |
| Hasar, menzil ve saldırı zamanları | Kök > `04 - Saldırı` |
| Yol ve performans ayarları | Ravager / HellMagma kökü > `05 - Yol Bulma`, `06 - Performans` |
| Yön/kamera eşiği, hurt ve ceset | Kök > son `Görsel ve Animasyon` kategorisi |
| Pixel Size, renk, billboard ve kareler/FPS | `AnimatedSprite3D` |
| Çarpışma boyutu | `CollisionShape3D > Shape` |
| Ses dosyası, ses seviyesi ve menzil | `AttackAudio`, `HurtAudio`, `DeathAudio` |
| Temas gölgesinin ölçü, saydamlık ve zemin payı | `GroundShadow` |

Varsayılan boyut ve fizik sınıfları şöyledir:

| Yaratık | Sınıf | Pixel Size | Görsel tuval yüksekliği | Kapsül yarıçap / yükseklik |
| --- | --- | ---: | ---: | ---: |
| Ravager | İnsan ölçeği | `0.003315` | `1.8000 m` | `0.42 / 1.80 m` |
| RedViper | İnsan ölçeği | `0.003315` | `1.8000 m` | `0.42 / 1.80 m` |
| BadRedViper | Orta | `0.0062` | `3.3666 m` | `0.82 / 3.10 m` |
| HellMagma | Büyük / mevcut boy | `0.0073547` | `3.9936 m` | `1.00 / 3.60 m` |

Sprite alt kenarı, kapsül altı ve `GroundShadow` yüksekliği sahnelerde aynı zemin düzlemine göre ayarlanmıştır. Pixel Size'ı sonradan değiştirirsen `AnimatedSprite3D` Y konumunu ve `CollisionShape3D` ölçü/konumunu da birlikte güncelle; yalnız birini değiştirmek görsel temas ile fizik gövdesini ayırır. `GroundShadow` mevcut ortak `assets/world/contact_shadow.png` kaynağını kullanır. Billboard dinamik gölgesi performans için kapalıdır; ucuz temas gölgesi zemine bağlanma hissini korur.

`Apply Difficulty Scaling` açıkken Inspector değerleri temel değer olarak kalır; seçili zorluk çarpanları çalışma zamanı kopyalarına uygulanır ve sahne verisi değiştirilmez. Inspector'da yazdığın değerin hiçbir zorluk çarpanı olmadan aynen kullanılmasını istiyorsan bu seçeneği kapat.

Ravager ve HellMagma uzak saldırı ayarlarının tamamı kök yaratıkta `04 - Saldırı` altındadır. `Projectile Spawn Side Offset` mermi çıkışını yaratığın baktığı yöne göre yatay taşır: pozitif değer yaratığın kendi sağına, negatif değer kendi soluna gider. İnsan boyuna ölçeklenen Ravager'ın sağ kol namlusu için temel değer `0.40 m`dir. `Attack Approach Speed`, mermi çıktıktan sonraki bekleme süresinde oyuncuya yaklaşma hızını; `Attack Strafe Speed`, aynı sıradaki yan hareketi; `Attack Preferred Distance` ise yaklaşmanın duracağı mesafeyi belirler. Saldırı hazırlığı boyunca yaratık ateş animasyonunu zeminde kaydırmaz; atıştan sonra yürüyüş animasyonuna geçerek yeniden konumlanır. Yan yön her atışta değişir, böylece sabit kule görünümü ve tek tarafa yığılma oluşmaz.

RedViper ve BadRedViper için `Move Speed` yalnızca devriye hızıdır; oyuncuyu kovalarken `Chase Speed` kullanılır. Saldırı başladıktan sonra `Attack Lunge Speed`, `Attack Lunge Acceleration` ve `Attack Lunge Duration` yaratığın kısa ileri hamlesini belirler. `Attack Lunge Stop Distance` oyuncunun içine girmesini önler; `Attack Range Tolerance` ise animasyonun darbe karesindeki küçük mesafe farkını karşılar. Varsayılan ayarda normal geri yürüyüşle yaratığı sınırsız şekilde etkisiz bırakmak mümkün değildir, ancak hızlı koşuyla yeterli mesafe açılabilir.

Özellikle RedViper boyutu için kökte ayrı bir sabit değer yoktur. `RedViper > AnimatedSprite3D > Pixel Size` doğrudan tek kaynaktır; script bu değeri başlangıçta, hasarda veya ölümde ezmez. Aynı kural sprite rengi ve SpriteFrames kaynağı için de geçerlidir.

## Haritalar

Harita planı artık bir PNG'ye çizilmiş değildir. `scripts/ui/automap_view.gd`, bölümün `get_automap_config()` verisinden oda ve koridorları dünya koordinatlarıyla canlı çizer. Bu nedenle görsel kırpma, farklı ekran oranı veya eşit olmayan PNG kenarları oyuncu işaretini kaydıramaz.

- VEX-01: 3×6 düzen, 18 oda ve 19 gerçek kapı bağlantısı `scripts/levels/level_01.gd` içindedir. Odalar ayrı bölmeler olarak çizilir ve numaralanır.
- VEX-02: 9×7 düzen ve 33 yürünebilir hücre `scripts/levels/level_02.gd` içindedir. Bitişik hücreler koridor olarak birleşir.
- Kapılar doğrudan sahnedeki `Doors` düğümünden okunur. Normal, açık, mavi kilitli ve kırmızı kilitli durumlar farklı renktedir.
- Keşif sisi oyuncunun gerçek dünya hücresine göre açılır. Turuncu yön işareti oyuncunun konumunu ve baktığı yönü canlı izler.
- Fare tekerleği yakınlaştırır; sol/orta tuşla sürükleme kaydırır; sağ tık veya çift sol tık oyuncuyu yeniden ortalar. `TAB` haritayı açıp kapatır.

Çerçeveyi değiştirmek istersen yalnızca `assets/ui/automap_console_frame_v2.png` dosyasını aynı adla değiştir. Oda planı, kapılar ve oyuncu işareti bu görselin parçası değildir; kod tarafından hizalı çizilir.

## Dünya görselleri

- Pickup ve varil sprite'larında `Billboard = Fixed Y` kullanılır: yalnızca yatay eksende kameraya döner, yandan görünür kalır ve kamera yüksekliğine eğilmez. Yalnızca pickup dikey bob hareketi yapar; varil zemine sabit ve hareketsiz kalır.
- Ravager, HellMagma, RedViper ve BadRedViper sprite'larında `Billboard` açık kalmalıdır.
- Düşman ana sprite'larında `Shaded` açık, `Cast Shadow` kapalı kalmalıdır; zemin teması `GroundShadow` ile sağlanır.
- Kırmızı kapı lambası yataydır ve dar açılı `SpotLight3D` kullanır. Omni ışığa çevirmek duvar arkası sızıntıyı artırır.
- Level 1 duvarları 10 birim yüksekliktedir; tavan altı yaklaşık `Y=10` seviyesindedir.
- Kapı `DoorPanel` düğümü yalnızca yukarı hareket eder; ön ve arka yüz aynı kapı malzemesini kullanır. Varsayılan `Opening Height = 4.2 m`, yaklaşık 4 metrelik HellMagma görselinin ve 3,6 metrelik hitbox'ının üstünde güvenli geçiş payı bırakır.

## Kimlik ve ad kuralları

- Bitiş nesnesinin adı her yerde `finish_switch` / `FinishSwitch` olarak kalmalıdır.
- Her düşmanda benzersiz `enemy_id`, her pickup'ta benzersiz `pickup_id`, her gizli alanda benzersiz `secret_id` kullan.
- Görsel uzantısı olarak PNG kullan; SVG çalışma zamanı bağımlılığı ekleme.
