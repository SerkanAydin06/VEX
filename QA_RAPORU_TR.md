# VEX 3.1.1 // QA Raporu

## Sonuç

Kaynak paketi statik doğrulamalarda **0 hata** ile tamamlandı.

| Denetim | Sonuç |
| --- | --- |
| `res://` kaynak yolları | 0 eksik |
| UID karşılaştırması | 0 uyuşmazlık |
| Sahipsiz `.import` | 0 |
| Yinelenen sahne özelliği | 0 |
| Yinelenen düşman / pickup kimliği | 0 |
| GDScript sözdizimi | 27 dosya, 0 tanı |
| Godot `.tscn` / `.tres` sözdizimi | 37 dosya, 0 ayrıştırma hatası |
| PNG bütünlüğü | 154 dosya açıldı, 0 hata |
| Ses bütünlüğü | 25 dosya açıldı |
| Font bütünlüğü | 2 dosya açıldı |
| Sıfır baytlık dosya | 0 |
| Harita kenar/ızgara tanımları | 2 bölüm, geçerli ve artan |
| Pickup yan görünürlüğü | Fixed-Y billboard doğrulandı |
| Düşman renk standardı | 96 kare; P90/P99 karanlık palet aralığında |
| Düşman kare zemin çizgisi | 96/96 kare `Y=542` |
| Sprite / hitbox / temas gölgesi | 4/4 sahne aynı zemin düzleminde |
| Boy ve kapı geçiş sırası | İnsan → orta → büyük; HellMagma için güvenli pay |
| Duvar/kapı oklüzyonu | Etkin; yalnız duvar profilleri ve kapalı kapılar |
| Dinamik ışık bütçesi | 4/4 ışık sahnesinde uzaklık LOD'u; mermi gölgeleri kapalı |
| Düşman işlem bütçesi | 4/4 sahnede uyku mesafesi; Viper görüş önbelleği etkin |
| 3B kalite profilleri | Performans `0,75`; Dengeli `0,85`; Yüksek `1,00` |

## Kritik akışlar

- VEX-01 `FinishSwitch`, `res://scenes/levels/level_02.tscn` yolunu `GameState.complete_level(next_level_path)` akışına aktarır.
- VEX-02 son bölüm olarak sonuç ekranında tekrar oynama seçeneği sunar.
- VEX-01 final kapısı iki anahtar ister; iki bölümün final switch'i ilgili nihai muhafızı doğrular.
- Ölümde bölüm başlangıcı yüklenir ve oyuncu 100 canla başlar.
- HUD referansları metin yollarıyla yüklenir; eski UID uyarısı kaldırılmıştır.
- AK-47 ve MP90 görselleri ilk seçimden önce yüklenmez.
- VEX-01 ve VEX-02 haritaları bölümün canlı hücre/kapı verisinden çizilir; oyuncu işareti ve keşif sisi aynı dünya-koordinat dönüşümünü kullanır.
- Pickup sprite'ı yalnızca Y ekseninde döner; yan açıda görünür kalırken kamera yüksekliğine doğru eğilmez.
- Ravager ve RedViper normal insan boyunda, BadRedViper orta, HellMagma mevcut büyük boyundadır. Görsel, kapsül ve görüş/atış yüksekliği aynı sınıfa göre ayarlanmıştır.
- Dört düşmanın ana sprite'ı çevre ışığını alır; düşük maliyetli `GroundShadow` zemin temasını korur. Dinamik billboard gölgesi kapalıdır.
- Kapı 4,2 metre açılır; 3,9936 metrelik HellMagma görseline ve 3,6 metrelik kapsülüne güvenli üst pay bırakır. Güvenlik sensörü oyuncu/düşman katmanlarını izlemeye devam eder.
- Duvar ve kapı oklüderleri kapalı alanlarda görünmeyen oda içeriğini eler. Kapı oklüderi hareket sırasında kapalıdır; açık geçitte yanlış görünmezlik oluşturmaz.
- Uzak, alarma geçmemiş yaratıklar fizik/rota/görüş yükünden çıkar; hasar veya müttefik alarmı aldıklarında anında uyanır.
- Ayarlardaki 3B kalite seçimi yalnız dünya render ölçeğini değiştirir; menü, HUD, harita ve nişangah yerel çözünürlükte kalır.

## Çalıştırma notu

Bu çalışma ortamında Godot yürütücü dosyası bulunmadığı için motor içi headless oyun testi burada çalıştırılamadı. Paket, Godot 4.5 hedefi için kaynak/sahne ayrıştırması, referans denetimi ve medya bütünlüğüyle doğrulandı. Projedeki `tests/integrity_test.gd`, Godot 4.5 bulunan bir makinede motor içi son denetimi yapmak için hazırdır.
