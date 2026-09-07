# VEX — Bölüm 3: Basınç Hattı

Bu belge Bölüm 3'ün kanonik üretim planı ve uygulanmış gameplay omurgasıdır.

## 1. Bölüm hedefi

- Oyuncuya dönük ad: **Bölüm 03 // Basınç Hattı**
- Hedef süre: **19–22 dakika**
- Evren odağı: **Korvath Ocağı**
- Aktif düşmanlar: **Cinder Hound + Cinder Spitter + Basalt Juggernaut**
- Yeni yaratık: **Basalt Juggernaut**
- Yeni silah: **P-07 Sentinel**
- NPC: **Dr. Selin Erdem**
- Kayıt: **3**
- Secret: **1 — 7-C sınıflandırılmış arşivi**
- Final: Selin'i stabilize et ve Bastion tahliye bağlantısını etkinleştir.

Ravager, Vaskari Raptor, Vaskari Ravager, Voidweaver ve Loom Herald bu bölümün aktif kanonik içeriği değildir.

## 2. Sahne mimarisi

Eski iki katlı maden/servis sahnesinin fiziksel emeği korunurken ana bölüm artık Godot editöründe doğrudan okunabilir:

- `level_03.tscn` → ana bölüm sahnesi; Player, HUD, müzik, briefing/automap metadata, P-07 fener öğretim trigger'ı ve aşağıdaki iki kanonik katmanı doğrudan içerir.
- `level_03_pressure_line_content.tscn` → ana sahnede doğrudan instance ve **Editable Children**; kanonik düşmanlar, P-07, erişim yetkileri, ikmal, kayıtlar, Selin kurtarma ünitesi ve detaylı VEX tahliye konsolu viewport'ta görünür.
- `level_03_environment_story.tscn` → ana sahnede doğrudan instance ve **Editable Children**; collision'sız basınç boruları, sıcaklık izleri, oda kodları ve hikâye ışıkları doğrudan görünür.
- `level_03_structure_source.tscn` → eski authored iki katlı fiziksel kaynak. İçindeki legacy gameplay nedeniyle tamamı ana level'a instance edilmez.

`level_03.gd` `@tool` preview ile structure source içinden yalnız `WorldEnvironment`, `Geometry`, `Doors`, `Props`, `RoomLights` ve `Lights` root'larını filtreler. Eski `Enemies`, `Pickups`, `Objectives`, `Secrets` ve `LoreTerminals` aktif göreve veya editor preview'a girmez.

Runtime structure `_enter_tree()` aşamasında gameplay çocuklarından önce kurulur. `VexDoor` runtime scripti non-tool kalır; editörde yalnız authored kapı geometrisi gösterilir, legacy kilitler nötrlenip mavi/sarı/kırmızı kanonik erişim semantiği yalnız oyun çalışırken kapılar SceneTree'ye girmeden önce uygulanır. Fiziksel geometri değişiklikleri structure source'ta, gameplay/environment yerleşimleri ana level içindeki editable alt sahnelerde yapılır.

## 3. 19–22 dakikalık ritim

### 0–4 dakika — karanlık bakım galerisi

- L01 başlangıcından bakım kanadına sapılır.
- Bölüm 1–2 bilgisi kısa Hound baskısıyla tazelenir.
- L06 karanlık bakım cebinde **P-07 Sentinel** bulunur.
- P-07'nin silah feneri güvenli/okunabilir bir cepte tek kullanımlık `CH03_FLASHLIGHT_HINT` bildirimiyle öğretilir.
- Pickup ilk edinimde 16'lık dolu şarjör + **32 bonus bullet reserve** verir.

### 4–10 dakika — ilk Basalt Juggernaut

- İlk Juggernaut L04 geniş operasyon/basınç odasında **tek başına** tanıtılır.
- Actor sahnesinin gerçek değerleri kullanılır: **240 base health, 28 base damage**.
- Eski prototipteki 520 HP / 26 damage `KorvathWarden` override'ı kaldırılmıştır.
- Encounter'ın amacı ağır projectile telegraph, mesafe değiştirme ve cover disiplinini öğretmektir.

### 10–16 dakika — üç rolü birleştirme

- Hound yakın alanı bozar.
- Spitter orta/uzak menzil baskısı kurar.
- Juggernaut ağır alan tehdidi üretir.
- Kombinasyonlar küçük tutulur; oyuncuya aynı anda büyük sürü verilmez.
- Mavi bakım yetkisi üst kata geçişi açar.
- Sarı arşiv yetkisi 7-C sınıflandırılmış arşiv kapısını açar.
- Kırmızı reaktör yetkisi Selin'in bulunduğu servis hattını açar.

### 16–22 dakika — Selin kurtarma ve tahliye

- Üst reaktör servisinde Dr. Selin Erdem'in acil medikal stabilizasyon ünitesi bulunur.
- Selin fiziksel character model yerine şimdilik **kanonik kurtarma/stabilizasyon etkileşimi** ile temsil edilir; sahte karakter modeli üretilmez.
- `[E]` ile stabilize edilince hedef tahliye kontrolüne döner.
- Detaylı `VexLevel03ExtractionSwitch` VEX tahliye konsolu kullanılır ve Selin stabilize edilmeden bölümün tamamlanmasına izin vermez.
- Konsolun interaction collider'ı yeni yaklaşık 2 metrelik görsel gövdeye hizalanmıştır; oyuncu ekrana/üst gövdeye nişan aldığında etkileşim ray'i inherited `PanelBody` collider'ını yakalar.
- Tamamlanınca campaign stage `3` olur; Selin bundan sonra Bastion-7'de görünür.

## 4. Encounter bütçesi

| Zorluk | Hound | Spitter | Juggernaut | Toplam |
|---|---:|---:|---:|---:|
| Easy | 7 | 3 | 1 | **11** |
| Normal | 9 | 4 | 2 | **15** |
| Hard | 10 | 6 | 3 | **19** |
| Nightmare | 11 | 7 | 4 | **22** |

Zorluk katmanları `spawn_min_difficulty` ile ek encounter olarak gelir. Species sağlık/hasar/hız değerleri content scene içinde override edilmez. Yalnız staging için bazı detection/hearing/ally-alert değerleri daraltılabilir.

Global defeat mantığında `enemy_id` kanonik species/condition kimliği olarak tekilleştirilir; fakat `kills` her fiziksel yaratık ölümünde artar. Böylece aynı bölümdeki 9 ayrı Cinder Hound tek species kaydı üretirken level sonucu doğru şekilde 9 fiziksel kill sayabilir.

## 5. P-07 ekonomisi

Canlı `P-07 Sentinel` definition:

- şarjör: **16**
- damage: **17**
- fire interval: **0.22 sn**
- ADS destekli
- silah feneri destekli

P-07 ilk fiziksel edinimde 32 bonus bullets verir. Bölüm boyunca P-01/P-07'nin ortak bullet ekonomisi için küçük paketler, SG-04 için sınırlı shell paketleri bulunur. Yeni silahın güvenli öğrenme alanından sonra ikmal yoğunluğu azalır.

## 6. Erişim zinciri

Mevcut key sistemi yeni hikâyede erişim kartı/anahtar yerine yetki modülleri olarak kullanılır:

1. `blue` → **Mavi Bakım Yetkisi** → üst kat merdiveni.
2. `yellow` → **Sarı Arşiv Yetkisi** → 7-C sınıflandırılmış arşivi.
3. `red` → **Kırmızı Reaktör Yetkisi** → Selin/reaktör servis hattı.

Loader runtime'da önce tüm legacy kapıları nötrler; eski combat lock veya eski objective string'leri aktif göreve sızmaz. Sonra yalnız bu üç kanonik kapı yeniden kilitlenir. Editor preview kapı scriptlerini çalıştırmaz; yalnız authored fiziksel kapıları gösterir.

## 7. Kayıtlar

### L03 — TEKNİK / Düzenlenmiş Jeotermal Akış

KOR-TERMAL basınç darbelerinin rastgele jeolojik gürültü olmadığını; sabit aralıklarla düşüp başka bir hat üzerinden yeniden dengelendiğini gösterir.

### U06 — PERSONEL / Selin Erdem / İtiraz Taslağı

Selin, doğal bir rezervuarın bu şekilde tepki veremeyeceğini ve testlerin durdurulması gerektiğini yazmıştır. Karşı tarafta düzenleyen bir sistem ve ona bağlı yaşam olabileceği ihtimalini açıkça gündeme getirir.

### U04 — YÖNETİM / Rapor 7-C Sınıflandırıldı

Sarı arşiv yetkisinin arkasındaki secret kayıt. Yönetim, 'düzenlenmiş kaynak altyapısı' değerlendirmesinin operasyon raporlarından çıkarılmasını ve Selin'in testleri durdurma önerisinin reddedilmesini emreder.

Bu kayıtlar campaign save'e kalıcı olarak eklenir ve Bastion Ana Terminali → **KAYITLAR** altında tekrar okunur.

## 8. Çevresel hikâye

`level_03_environment_story.tscn` navigation/collision otoritesi değildir.

- L06: soğuk mavi P-07 bakım ışığı.
- L04: ilk Juggernaut odasında sıcak basınç izi.
- U04: kırmızı 7-C arşiv uyarısı.
- U06: Selin'in stabilizasyon ünitesi çevresinde medikal mavi ışık.
- U08: kırmızı tahliye/basınç alarmı.

## 9. Hikâye sonucu

Bölümün yeni bilgisi:

> KOR-TERMAL akış doğal bir boşluktan gelmiyor olabilir; karşı tarafta basıncı düzenleyen gerçek bir altyapı vardır ve VEX bu ihtimali felaketten önce bastırmıştır.

Selin'in kurtarılması Aras'ın yalnız dosya bulmaktan canlı bir tanığa ulaşmasına geçiştir. Bölüm 4'te Korvath tarafındaki **işlenmiş fiziksel yüzeyleri** araştırmak için motivasyon buradan doğar.

## 10. Kabul kriterleri

- [x] Ana `level_03.tscn` canonical content/environment katmanlarını editörde doğrudan gösteriyor ve Editable Children ile açabiliyor.
- [x] Eski iki katlı authored yapı `level_03_structure_source.tscn` içinde korunur ve yalnız güvenli fiziksel root'lar filtrelenir.
- [x] Karma evren düşmanları runtime'a alınmaz.
- [x] Aktif aile yalnız Cinder Hound + Cinder Spitter + Basalt Juggernaut.
- [x] Easy/Normal/Hard/Nightmare toplamları 11/15/19/22.
- [x] Basalt Juggernaut actor statları content scene'de override edilmez.
- [x] P-07 Sentinel Bölüm 3'te fiziksel pickup'tır.
- [x] P-07 feneri yalnız silah edinildikten sonra tek seferlik bildirimle öğretilir.
- [x] Mavi/sarı/kırmızı erişim zinciri uygulanmıştır.
- [x] 3 kanonik kayıt persistent database'e bağlıdır.
- [x] Selin kurtarma etkileşimi uygulanmıştır.
- [x] Selin kurtarılmadan tahliye tamamlanamaz.
- [x] Yeni detaylı VEX tahliye konsolunun interaction collider'ı görsel gövdeye hizalanmıştır.
- [x] Selin Bastion'da yalnız campaign stage 3 sonrası görünür.
- [x] Tekil species kimliği korunurken fiziksel düşman ölümleri ayrı ayrı sayılır.
- [ ] Godot runtime parse/playthrough testi yapılacak.
- [ ] Gerçek playtest ile 19–22 dakika hedefi ölçülecek.
