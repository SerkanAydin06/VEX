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

Eski iki katlı maden/servis sahnesinin fiziksel emeği korunur:

- `level_03.tscn` → küçük görev kabuğu: Player, HUD, müzik, briefing ve automap metadata.
- `level_03_structure_source.tscn` → eski authored iki katlı yapı.
- `level_03_pressure_line_content.tscn` → kanonik düşmanlar, P-07, erişim yetkileri, ikmal, kayıtlar, Selin kurtarma ve tahliye.
- `level_03_environment_story.tscn` → collision'sız basınç boruları, sıcaklık izleri, oda kodları ve hikâye ışıkları.

Runtime'a structure source içinden yalnız `WorldEnvironment`, `Geometry`, `Doors`, `Props`, `RoomLights` ve `Lights` taşınır. Eski `Enemies`, `Pickups`, `Objectives`, `Secrets` ve `LoreTerminals` canlı SceneTree'ye girmez.

## 3. 19–22 dakikalık ritim

### 0–4 dakika — karanlık bakım galerisi

- L01 başlangıcından bakım kanadına sapılır.
- Bölüm 1–2 bilgisi kısa Hound baskısıyla tazelenir.
- L06 karanlık bakım cebinde **P-07 Sentinel** bulunur.
- P-07'nin silah feneri güvenli/okunabilir bir cepte öğretilir.
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
- Tahliye şalteri `VexLevel03ExtractionSwitch` kullanır ve Selin stabilize edilmeden bölümün tamamlanmasına izin vermez.
- Tamamlanınca campaign stage `3` olur; Selin bundan sonra Bastion-7'de görünür.

## 4. Encounter bütçesi

| Zorluk | Hound | Spitter | Juggernaut | Toplam |
|---|---:|---:|---:|---:|
| Easy | 7 | 3 | 1 | **11** |
| Normal | 9 | 4 | 2 | **15** |
| Hard | 10 | 6 | 3 | **19** |
| Nightmare | 11 | 7 | 4 | **22** |

Zorluk katmanları `spawn_min_difficulty` ile ek encounter olarak gelir. Species sağlık/hasar/hız değerleri content scene içinde override edilmez. Yalnız staging için bazı detection/hearing/ally-alert değerleri daraltılabilir.

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
3. `red` → **Kırmızı Reaktör Yetkisi** → Selin/rektör servis hattı.

Loader önce tüm legacy kapıları nötrler; eski combat lock veya eski objective string'leri aktif göreve sızmaz. Sonra yalnız bu üç kanonik kapı yeniden kilitlenir.

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

- [x] Aktif `level_03.tscn` legacy gameplay içermeyen küçük görev kabuğudur.
- [x] Eski iki katlı authored yapı `level_03_structure_source.tscn` içinde korunur.
- [x] Karma evren düşmanları runtime'a alınmaz.
- [x] Aktif aile yalnız Cinder Hound + Cinder Spitter + Basalt Juggernaut.
- [x] Easy/Normal/Hard/Nightmare toplamları 11/15/19/22.
- [x] Basalt Juggernaut actor statları content scene'de override edilmez.
- [x] P-07 Sentinel Bölüm 3'te fiziksel pickup'tır.
- [x] Mavi/sarı/kırmızı erişim zinciri uygulanmıştır.
- [x] 3 kanonik kayıt persistent database'e bağlıdır.
- [x] Selin kurtarma etkileşimi uygulanmıştır.
- [x] Selin kurtarılmadan tahliye tamamlanamaz.
- [x] Selin Bastion'da yalnız campaign stage 3 sonrası görünür.
- [ ] Godot runtime parse/playthrough testi yapılacak.
- [ ] Gerçek playtest ile 19–22 dakika hedefi ölçülecek.
