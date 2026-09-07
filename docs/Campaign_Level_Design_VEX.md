# VEX — 30 Bölümlük Kampanya / Level Tasarım Ana Planı

> Bu belge `Story_VEX.md` içindeki 30 bölümlük kanonik hikâyeyi **oynanış süresi, silah/ekipman kazanımı, kayıt yerleşimi, yaratık tanıtımı ve bilgi bildirimleri** açısından üretim planına dönüştürür.

## 1. Kaynak-of-truth ve kapsam

- Hikâye, bölüm adı, evren sırası ve anlatı sonucu: `Story_VEX.md`.
- Aktif yaratık roster'ı ve gerçek savaş davranışı: `Enemies_VEX.md` + `scenes/actors/*.tscn` + ilgili scriptler.
- Silah kimliği ve özellik planı: `Weapons_VEX.md`; oynanabilir modellerde gerçek sayılar `resources/weapons/*.tres`.
- Bu belge **level üretim hedefidir**. Burada planlanan fakat henüz uygulanmamış silah/ekipman, runtime'da varmış gibi kabul edilmez.
- İlk 25 bölümde farklı evren aileleri ana encounter içinde karıştırılmaz. İlk kontrollü karma operasyon Bölüm 26'dır.

---

# 2. Bölüm süresi standardı

Normal bölüm hedefi **18–22 dakika**, beşli yay finalleri **20–24 dakika**, son iki bölüm **22–26 dakika**dır. İlk oynayışta keşif yapan oyuncu bu aralığın üstüne çıkabilir; rotayı bilen oyuncu daha kısa bitirebilir.

Her normal bölüm yaklaşık dört ritim bloğu kullanır:

1. **0–4 dk — Giriş / keşif:** ortamı oku, ilk kayıt veya hedefi bul.
2. **4–9 dk — Öğret:** yeni yaratık, silah, ekipman veya çevresel kural güvenli bağlamda tanıtılır.
3. **9–15 dk — Birleştir:** önceki kurallarla yeni kural aynı encounter / rota probleminde birleşir.
4. **15–20+ dk — Zirve / çıkış:** bölümün en güçlü encounter'ı, hikâye kaydı ve dönüş noktası.

VEX'te mevcut kampanya kuralı gereği **mid-level checkpoint yoktur**. Bu nedenle 15–20 dakikalık görevlerde:

- yaklaşık 8–11. dakikada bir ara ikmal,
- final encounter öncesinde kontrollü mühimmat/sağlık erişimi,
- ölümcül çevresel sürprizlerin açık telegraph'ı,
- bölümün son üçte birinde kör RNG baskısından kaçınma

zorunlu tasarım kuralıdır.

---

# 3. Her bölümde bilgi ilerlemesi

Her bölüm oyuncuya en az bir yeni şey öğretir. Bu yalnız yeni düşman demek değildir. Yeni bilgi şu sınıflardan biri olabilir:

- yeni aktif yaratık veya yeni aile kombinasyonu,
- yeni silah,
- yeni saha ekipmanı / araç,
- yeni çevresel etkileşim,
- yeni Bastion kapasitesi,
- yeni evren gerçeği,
- VEX yönetiminin yeni bir kaydı,
- yeni NPC / uzman,
- Yarık Ağı hakkında yeni teknik bilgi.

Bir bölüm **yalnız düşman sayısını artırarak** ilerlemiş sayılmaz.

---

# 4. Kayıt sistemi standardı

Her bölümde **3 ana kayıt** bulunur; toplam ana kampanya hedefi **90 kayıt**tır.

1. **Ana rota kaydı:** oyuncunun kaçırması zor; ana hikâyeyi taşır.
2. **Yan rota kaydı:** kısa keşif / risk karşılığı; karakter, tesis veya evren ayrıntısı verir.
3. **Gizli kayıt:** secret rota, kilitli oda veya çevresel ipucu; yönetim, prototip veya olayın daha karanlık tarafını açar.

Kayıt türleri:

- `YÖNETİM` — VEX kararları, emirler, sansür ve üst seviye notlar.
- `PERSONEL` — bilim insanı, güvenlik, teknisyen ve sivil günlükleri.
- `XENO` — yaratık / evren saha gözlemleri.
- `TEKNİK` — reaktör, silah, Yarık Ağı, faz ve enerji belgeleri.
- `OLAY` — güvenlik kamerası, ses kaydı, tahliye veya felaket anı.

Kayıt bulunduğunda daha sonra VEX Ana Terminali > **KAYITLAR** altında okunabilir olmalıdır. Bulunmamış kayıt başlığı spoiler vermeyecek biçimde şifreli/kapalı görünmelidir.

---

# 5. Achievement-benzeri keşif bildirimi

Bu sistem gerçek platform achievement'ı değildir. Oyun içi kısa **keşif / arşiv bildirimi**dir.

Yeni bir bilgi ilk kez kalıcı olarak açıldığında HUD'ın sağ üst veya üst-orta bölgesinde 3.5–5 saniyelik kart görünür:

### Xeno
`YENİ XENO KAYDI`
`CINDER HOUND // KORVATH OCAĞI`
`VEX ANA TERMİNALİNE EKLENDİ`

### Silah
`SİLAH ARŞİVİ GÜNCELLENDİ`
`SG-04 BREACHER`
`TEKNİK VERİ VE GELİŞTİRME HATTI AÇILDI`

### Ekipman
`SAHA EKİPMANI KAZANILDI`
`GECE GÖRÜŞ MODÜLÜ`

### Kayıt
`KAYIT ÇÖZÜLDÜ`
`KOR-TERMAL / TEST 12`

### Evren
`GERÇEKLİK PROFİLİ GÜNCELLENDİ`
`THORNWILD SÜRÜSÜ // VERİ %34`

Kurallar:

- Yeni yaratık kartı ilk kalıcı xeno keşfinde çıkar. Mevcut `ArchiveManager` bunu ilk yenilgide kaydediyor; ileride kart bu sinyale bağlanabilir.
- Yeni silah kartı ilk kalıcı edinimde çıkar; aynı silahı tekrar yerden almak kartı tekrar göstermez.
- Kayıt kartları kuyruklanır; üst üste üç HUD mesajı aynı anda bindirilmez.
- Kart gameplay'i durdurmaz.
- Kartta uzun lore metni gösterilmez; ayrıntı terminale yönlendirilir.
- Gerçek achievements ayrı sistemdir ve daha büyük başarılar için saklanır: bölüm yayını tamamlama, 18 xeno kaydı, 20 silah, 90 kayıt vb.

---

# 6. Saha ekipmanı katmanları

## Mevcut / uygulanmış

- **Gece görüşü:** gerçek pickup ve oyuncu sahiplik state'i mevcut.
- **Mavi / kırmızı / sarı erişim kartları:** bölüm içi kapı zinciri için mevcut.
- **Sağlık, zırh ve mühimmat pickup'ları:** mevcut.
- **Automap:** mevcut HUD sistemi; kalıcı yeni pickup olarak sayılmaz.

## Planlanan kalıcı veya yarı-kalıcı saha araçları

Bunlar bu dokümanda kampanya yerleşimi için tanımlıdır; runtime sistemleri uygulanmadan aktif kabul edilmez.

| Araç | İlk planlanan bölüm | Rol |
|---|---:|---|
| **FieldLink Veri Modülü** | 1 | Kayıt tarama, keşif kartı ve terminale veri aktarımının kurgu cihazı |
| **Güç Bypass Kuplörü** | 2 | Seçilmiş güç panolarında alternatif/secret rota açma |
| **Bakım Multi-Tool** | 4 | Bakım panelleri, hasarlı dolap ve servis kapakları için keşif aracı |
| **Xeno Numune Kiti** | 6 | Opsiyonel biyolojik/teknik örnekleri Bastion araştırmasına taşıma |
| **Hareket Sensörü** | 8 | Kısa menzilli çevre farkındalığı; kalıcı wallhack olmamalı |
| **Vaskari Sinyal Çözücü** | 12 | Vaskari işaret/sinyal kayıtlarını kısmen çözme |
| **Gece Görüş Modülü** | 16 | Karanlık Nhal görevlerinde aktif görüş aracı; mevcut sistem |
| **Toksik Maruziyet Monitörü** | 18 | Husk Leech / zehir durumunu HUD'da okunur kılma; direnç vermek zorunda değil |
| **Faz Tarayıcı** | 21 | Aether ortamındaki kararsız yüzey ve faz düğümlerini tanımlama |
| **Faz Sabitleyici** | 23 | Yalnız tasarlanmış faz geçişlerinde kısa güvenli pencere oluşturma |
| **Taşınabilir Yarık Ankrajı** | 26 | Final perdesindeki görev hedeflerini geçici olarak sabitleyen operasyon aracı |

---

# 7. 20 silahın kampanya edinim planı

Bu tablo **ilk kalıcı edinim hedefidir**. Dokuz model bugün oynanabilir; diğer on bir model `Weapons_VEX.md` durumuna göre planlıdır.

| Bölüm | Silah | Durum | Kazanım amacı |
|---:|---|---|---|
| 1 | P-01 | Oynanabilir | Temel silah okuryazarlığı |
| 2 | SG-04 | Oynanabilir | Yakın mesafe / durdurma |
| 3 | P-07 | Oynanabilir | Taktik fener / hızlı tabanca |
| 4 | VX-47 | Oynanabilir | İlk ana orta menzil tüfeği |
| 6 | MP-90 | Oynanabilir | Hareketli sürü baskısı |
| 7 | SG-09 | Oynanabilir | Hızlı ikinci pompalı atışı |
| 9 | P-14 | Oynanabilir | Hassas/sessiz alternatif |
| 10 | VX-58 | Planlandı | Ateş modu seçimi / kontrollü seri |
| 11 | P-20 | Oynanabilir | Ağır tek atış / zırh baskısı |
| 13 | SG-15 | Oynanabilir | Tam otomatik + ısı yönetimi |
| 14 | MP-96 | Planlandı | Sessiz SMG |
| 15 | VX-72 | Planlandı | DMR / uzun menzil |
| 17 | MP-110 | Planlandı | Yüksek ateş yoğunluğu |
| 20 | VX-90 | Planlandı | Programlanabilir ileri tüfek |
| 21 | LX-01 | Planlandı | Enerji yuvasını ilk kez aktif etme |
| 22 | SG-21 | Planlandı | Ağır hedef / özel fişek |
| 23 | LX-07 | Planlandı | Sekmeli enerji ışını |
| 24 | MP-120 | Planlandı | Faz dengeli ileri SMG |
| 25 | LX-13 | Planlandı | Şarjlı uzun menzil enerji |
| 28 | LX-20 | Planlandı | Son deneysel boyutsal silah |

Bölüm 5, 8, 12, 16, 18, 19, 26, 27, 29 ve 30'da yeni silah zorunlu değildir; bu bölümlerin yeniliği elit yaratık, ekipman, hikâye veya sistem kombinasyonundan gelir. Böylece oyuncuya her görevde yeni silah yağdırılmaz.

---

# 8. Bölüm bölüm üretim planı

## BÖLÜM 1 — İLK KIRILMA

**Hedef süre:** 18–20 dk  
**Evren:** Korvath  
**Yeni yaratık:** Cinder Hound  
**Yeni silah:** P-01  
**Yeni araç:** FieldLink Veri Modülü (planlanan anlatı/UI omurgası)

### Akış
- **0–4 dk:** Aras güvenlik sığınağında uyanır; güç, kapı ve basit etkileşimler öğretilir. P-01 güvenlik dolabından fiziksel olarak alınır.
- **4–9 dk:** İlk Cinder Hound tekli encounter'ları. Oyuncu geri hareket, yeniden doldurma ve yakın tehdidi okur.
- **9–15 dk:** Hasarlı laboratuvar/reaktör gözlem hattı; iki yönlü kısa combat + ilk secret rota.
- **15–20 dk:** Karantina çıkışı ve son Hound baskısı; dışarıda çoklu enerji sütunları görülür, Bastion-7 koordinatı alınır.

### Kayıtlar
1. **OLAY — “Acil Test Emri / 04:17”** — ana güvenlik terminali; son kapasite artışının saatini verir.
2. **PERSONEL — “Güvenlik Kamerası 07”** — yan kontrol odası; yaratığın yarıktan geldiğini doğrular.
3. **TEKNİK — “Enerji Üretmiyoruz”** — gizli laboratuvar; `Bir yerden çekiyoruz` cümlesinin tam bağlamı.

### Keşif kartları
- P-01 ilk alım: `SİLAH ARŞİVİ GÜNCELLENDİ`.
- İlk Cinder Hound yenilgisi: `YENİ XENO KAYDI`.

### Bölümün öğrendiği gerçek
Felaket tek bir laboratuvar kazası değildir; VEX ağı boyunca eş zamanlı kırılma vardır.

---

## BÖLÜM 2 — KÜL KORİDORU

**Hedef süre:** 18–21 dk  
**Yeni yaratık:** Cinder Spitter  
**Yeni silah:** SG-04 Breacher  
**Yeni araç:** Güç Bypass Kuplörü (planlandı)

### Akış
- **0–4 dk:** Bastion iletişim rölesine giden servis hattı; SG-04 bakım acil durum rafından alınır.
- **4–9 dk:** Spitter tek başına ve sonra Hound ile kontrollü encounter; yakın/orta menzil seçimi öğretilir.
- **9–15 dk:** Güç kesintili iki rota. Ana rota sigorta zinciri; bypass kullanan kısa ama riskli yan rota.
- **15–21 dk:** Röle odası savunması, sinyalin yeniden açılması ve ilk Korvath kaynak imzası.

### Kayıtlar
1. **TEKNİK — “KOR-TERMAL Kaynak İmzası”** — ana röle konsolu.
2. **PERSONEL — “Röle Teknisyeni / Son Vardiya”** — yan servis odası.
3. **YÖNETİM — “Basınç Sapması Önemsizdir”** — bypass ile açılan gizli kabin.

### Bölümün öğrendiği gerçek
VEX yıllardır `KOR-TERMAL` adlı düzenli bir dış kaynak frekansı izliyordur.

---

## BÖLÜM 3 — BASINÇ HATTI

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Basalt Juggernaut  
**Yeni silah:** P-07 Sentinel  
**NPC:** Dr. Selin Erdem

### Akış
- **0–4 dk:** Yüksek basınç servis galerileri; P-07 karanlık bakım cebinde bulunur ve silah feneri güvenli bir alanda öğretilir.
- **4–10 dk:** Juggernaut ilk kez tek başına geniş odada; ağır projectile telegraph'ı okunur.
- **10–16 dk:** Hound + Spitter + Juggernaut küçük kombinasyonları; Selin'in sinyaline yaklaşılır.
- **16–22 dk:** Reaktör servis odası, kurtarma ve tahliye hattı.

### Kayıtlar
1. **TEKNİK — “Düzenlenmiş Jeotermal Akış”** — ana laboratuvar.
2. **PERSONEL — “Selin Erdem / İtiraz Taslağı”** — onun çalışma odası.
3. **YÖNETİM — “Rapor 7-C Sınıflandırıldı”** — sarı erişim arkasındaki arşiv.

### Bölümün öğrendiği gerçek
Akış doğal/boş bir alandan değil, düzenlenmiş bir enerji sisteminden geliyor olabilir; VEX bu şüpheyi felaketten önce bastırmıştır.

---

## BÖLÜM 4 — ERİMİŞ DAMAR

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Furnace Carrier  
**Yeni silah:** VX-47 Striker  
**Yeni araç:** Bakım Multi-Tool (planlandı)

### Akış
- **0–5 dk:** Maden şehri üst bakım hattı; VX-47 ağır güvenlik kasasından edinilir.
- **5–10 dk:** Furnace Carrier uzun menzilde tanıtılır; yakına girildiğinde Thermal Burst tehdidi ayrı alanda gösterilir.
- **10–16 dk:** Multi-Tool ile alternatif bakım geçidi/secret; büyük iki katlı maden encounter'ı.
- **16–22 dk:** Karşı gerçekliğe ait düzenli tünel izleri ve termal transfer odası.

### Kayıtlar
1. **XENO — “İşlenmiş Bazalt Yüzeyi”** — zorunlu inceleme noktası.
2. **PERSONEL — “Maden Ekibi / Ses Kaydı 12”** — devrilmiş servis aracı.
3. **YÖNETİM — “Harici Yapılaşma Şüphesi”** — multi-tool gizli arşiv paneli.

### Bölümün öğrendiği gerçek
Korvath tarafında yalnız doğal mağaralar değil, işlenmiş altyapı vardır; kaynak çekimi oradaki yapıları bozmuştur.

---

## BÖLÜM 5 — SÖNEN ÇEKİRDEK

**Hedef süre:** 21–24 dk  
**Yeni yaratık:** Crucible Warden  
**Yeni silah:** Yok  
**Yeni sistem:** İlk tam aile sınavı / ilk ana ankraj kapatma

### Akış
- **0–5 dk:** Termal ankraj dış katmanı; önceki dört Korvath rolü kısa tekrar.
- **5–11 dk:** Warden tek başına okunabilir arena; Ground Slam / Heatwave ritmi öğrenilir.
- **11–17 dk:** İki farklı kontrollü Korvath kombinasyonu ve ana ankraj erişim zinciri.
- **17–24 dk:** Warden merkezli final encounter, ankrajın manuel kapatılması ve uzun hikâye konsolu.

### Kayıtlar
1. **YÖNETİM — “Harici Kaynak Stabilizasyonu”** — ana hedef terminali.
2. **XENO — “Korvath Enerji Kuyusu Sınıflandırması”** — yan gözlem odası.
3. **YÖNETİM — “Kayıp Kabul Edilebilir”** — gizli yönetici kasası.

### Achievement adayı
`SÖNEN ÇEKİRDEK` — Korvath beşli yayını tamamla.

### Bölümün öğrendiği gerçek
VEX yaşayan ve zarar gören bir kaynak alanı olduğunu bilmesine rağmen çekişi sürdürmüştür. Beş farklı kaynak imzası vardır.

---

# THORNWILD BLOĞU

## BÖLÜM 6 — YEŞİL KARANTİNA

**Hedef süre:** 18–21 dk  
**Yeni yaratık:** Ravager  
**Yeni silah:** MP-90 Viper  
**Yeni araç:** Xeno Numune Kiti (planlandı)

### Akış
- **0–4 dk:** Biyolojik araştırma kompleksinin dış karantinası; MP-90 güvenlik ekibinden kalmıştır.
- **4–9 dk:** Ravager açık görüş hattında precision ranged tehdit olarak öğretilir.
- **9–15 dk:** Organik büyüme arasından iki rota; numune alınabilen opsiyonel biyokütle cepleri.
- **15–21 dk:** Karantina arşivi ve ilk Thornwild geçit dokusu.

### Kayıtlar
1. **TEKNİK — “Biyolojik Üretkenlik Kaynağı”** — ana laboratuvar.
2. **XENO — “Ravager İlk Gözlem”** — yan gözlem noktası.
3. **YÖNETİM — “Rejeneratif Doku Lisanslama”** — gizli finans terminali.

### Bölümün öğrendiği gerçek
VEX yalnız enerji değil, biyokütle ve rejeneratif özellik de çekmiştir.

---

## BÖLÜM 7 — DİKEN İZLERİ

**Hedef süre:** 18–22 dk  
**Yeni yaratık:** Briar Skulker  
**Yeni silah:** SG-09 Aegis

### Akış
- **0–4 dk:** Seralar ve bakım hatları; SG-09 güvenlik müdahale dolabında.
- **4–9 dk:** Briar uzakta projectile / yakında melee geçişiyle tek başına öğretilir.
- **9–15 dk:** Ravager + Briar mesafe problemli encounter; kırılmış seralarda yön seçimi.
- **15–22 dk:** Ana sera kök düğümü ve biyolojik rota haritası.

### Kayıtlar
1. **XENO — “Av Zinciri Haritası”** — ana sera konsolu.
2. **PERSONEL — “Botanikçi G. Arel / Gün 41”** — yan laboratuvar.
3. **YÖNETİM — “Habitat Kaybı Simülasyonu”** — gizli veri dolabı.

### Bölümün öğrendiği gerçek
Thornwild tek bir sürü değil; birbirine bağlı av-avcı ekosistemidir.

---

## BÖLÜM 8 — BOYNUZ GEÇİDİ

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Gorehorn  
**Yeni silah:** Yok  
**Yeni araç:** Hareket Sensörü (planlandı)

### Akış
- **0–5 dk:** Otoyol bakım kompleksi ve drenaj vadisi; geniş alan.
- **5–10 dk:** Gorehorn charge düz hat üzerinde güvenli arena ile öğretilir.
- **10–16 dk:** Ravager ateş hattı + Gorehorn charge kesişimi; sensör ilk kez kör köşe öncesi kullanılabilir.
- **16–22 dk:** Biyokütle göç koridorunun kapatılması.

### Kayıtlar
1. **XENO — “Göç Şeridi 03”** — ana rota sensör istasyonu.
2. **PERSONEL — “Tahliye Konvoyu / Kayıp 6”** — yan servis kulübesi.
3. **TEKNİK — “Yarık Çevresi Habitat Yoğunluğu”** — secret drenaj odası.

### Bölümün öğrendiği gerçek
Thornwild canlıları yarık çevresini yeni habitat olarak kullanmaya başlamıştır; bu fetih emri değil ekolojik göçtür.

---

## BÖLÜM 9 — SPOR BAHÇESİ

**Hedef süre:** 20–23 dk  
**Yeni yaratık:** Spore Matriarch  
**Yeni silah:** P-14 Specter  
**NPC:** Dr. Ece Tan

### Akış
- **0–5 dk:** Biyoteknoloji kampüsü; P-14 sessiz operasyon kasasında bulunur.
- **5–10 dk:** Matriarch zehir alanı açık/okunur encounter ile tanıtılır.
- **10–17 dk:** Yaralı ekibe ulaşmak için zehir alanları ve Thornwild kombinasyonları arasında rota.
- **17–23 dk:** Ece'nin bulunduğu tıp istasyonunu savun, ardından ekstraksiyon.

### Kayıtlar
1. **TEKNİK — “Rejeneratif Tedavi Denemesi”** — tıbbi ana kayıt.
2. **PERSONEL — “Ece Tan / Hasta 17”** — tedavi odası.
3. **YÖNETİM — “Kaynak Etik Kurulu İptali”** — gizli yönetim ofisi.

### Bölümün öğrendiği gerçek
Çalınan Thornwild materyali Dünya'da gerçekten hayat kurtarmıştır; etik çatışma daha zor hâle gelir.

---

## BÖLÜM 10 — KÖKLERİN HAFIZASI

**Hedef süre:** 21–24 dk  
**Yeni yaratık:** Yok; tam Thornwild sınavı  
**Yeni silah:** VX-58 Vanguard (planlandı)

### Akış
- **0–5 dk:** Büyük biyokütle kolonisi ve VX-58 prototip saha kasası.
- **5–12 dk:** Dört Thornwild rolü iki kontrollü encounter'da birleştirilir.
- **12–18 dk:** Emiş modülünün davranış ölçüm katı; oyuncu kısa keşif/puzzle yapar.
- **18–24 dk:** Matriarch merkezli final, biyolojik emiş modülü kapatılır.

### Kayıtlar
1. **TEKNİK — “Üretkenlik Tepe Saatleri”** — ana emiş terminali.
2. **XENO — “Besin Zinciri Modeli 8”** — yan analiz odası.
3. **YÖNETİM — “Canlı Kaynak Verim Optimizasyonu”** — gizli root terminali.

### Achievement adayı
`KÖKLERİN HAFIZASI` — Thornwild yayını tamamla.

### Bölümün öğrendiği gerçek
VEX yaşayan ekosistemi yalnız keşfetmemiş, daha verimli sömürmek için davranışını modellemiştir.

---

# VASKARI BLOĞU

## BÖLÜM 11 — MOR CEPHE

**Hedef süre:** 18–21 dk  
**Yeni yaratık:** Vaskari Raptor  
**Yeni silah:** P-20 Magnum

### Akış
- **0–4 dk:** Sınır dinleme tesisi; P-20 ağır güvenlik kasasında.
- **4–9 dk:** Raptor tekli hızlı lunge karşılaşmaları.
- **9–15 dk:** Tekrar eden Vaskari hatları ve enerji ekipmanı hedefleri gözlemlenir.
- **15–21 dk:** Dinleme antenini yeniden çalıştırma + Raptor dalga encounter'ı.

### Kayıtlar
1. **OLAY — “Mor Hat İlk Temas”** — ana radar.
2. **PERSONEL — “Saha Gözcüsü / Disiplinli Hareket”** — yan kule.
3. **YÖNETİM — “Harici Muhalefet Senaryosu”** — gizli güvenlik arşivi.

### Bölümün öğrendiği gerçek
Vaskari rastgele yayılmıyor; hedef seçiyor ve operasyon yürütüyor.

---

## BÖLÜM 12 — KIRICI HAT

**Hedef süre:** 18–22 dk  
**Yeni yaratık:** Vaskari Ravager  
**Yeni silah:** Yok  
**Yeni araç:** Vaskari Sinyal Çözücü (planlandı)

### Akış
- **0–5 dk:** Ele geçirilmiş lojistik tüneli; sinyal çözücü prototipi alınır.
- **5–10 dk:** Vaskari Ravager tek başına ağır lunge ritmiyle tanıtılır.
- **10–16 dk:** Raptor + Ravager tempo farkı, sinyal düğümü taraması.
- **16–22 dk:** Bir VEX enerji düğümünün Vaskari tarafından işaretlendiği final oda.

### Kayıtlar
1. **TEKNİK — “Sinyal Kümesi K-3”** — ana decoder terminali.
2. **XENO — “Ravager Saha Rolü”** — yan gözetleme odası.
3. **YÖNETİM — “Yarık Savunma Simülasyonu”** — secret VEX taktik sunucusu.

### Bölümün öğrendiği gerçek
Vaskari'nin öncelikli hedefi insan şehirleri değil Yarık Ağı ekipmanıdır.

---

## BÖLÜM 13 — MIZRAK MENZİLİ

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Coil Lancer  
**Yeni silah:** SG-15 Tempest  
**NPC:** Cem “Kurt” Yalın

### Akış
- **0–4 dk:** Açık radar kompleksi; SG-15 saha müdahale kasasında, ısı sistemi düşük baskıda öğretilir.
- **4–10 dk:** Coil Lancer uzun görüş hattında tek başına.
- **10–16 dk:** Raptor yakın baskısı + Lancer uzak baskısı; cover rotası.
- **16–22 dk:** Cem'e ulaş, radar platformunu savun ve ekstraksiyon.

### Kayıtlar
1. **XENO — “Coil Lancer Nişan Disiplini”** — ana radar kayıt cihazı.
2. **PERSONEL — “Cem Yalın / İfade Tutanağı”** — tutulduğu güvenlik bölmesi.
3. **YÖNETİM — “Harici Canlı Muhalefet Eğitimi”** — secret eğitim sunucusu.

### Bölümün öğrendiği gerçek
VEX yönetimi başka taraftan organize bir direnç gelebileceğini felaketten önce öngörmüştür.

---

## BÖLÜM 14 — KALKAN DUVARI

**Hedef süre:** 19–23 dk  
**Yeni yaratık:** Vaskari Bulwark  
**Yeni silah:** MP-96 Whisper (planlandı)  
**NPC:** Derya Keskin

### Akış
- **0–5 dk:** Ağır yük terminali; MP-96 bakım lojistik kasasında.
- **5–10 dk:** Bulwark geniş koridorda tek başına; dayanıklılık ve pozisyon problemi.
- **10–17 dk:** Bulwark ön hat + Coil Lancer arka hat; alternatif sessiz yan rota MP-96 rolünü gösterir.
- **17–23 dk:** Derya ve taşınabilir çekirdek manifestoları bulunur.

### Kayıtlar
1. **YÖNETİM — “Çekirdek Tahliye Emri”** — ana lojistik terminali.
2. **PERSONEL — “Derya Keskin / Zorunlu Sevk”** — depo ofisi.
3. **TEKNİK — “Taşınabilir Sıfır Kaynak Çekirdeği”** — gizli prototip konteyneri.

### Bölümün öğrendiği gerçek
Felaket sonrasında bile VEX'in bir kısmı sistemi yeniden kurmak için çekirdekleri korumaya çalışmıştır.

---

## BÖLÜM 15 — ZEHİRLİ EMİR

**Hedef süre:** 21–24 dk  
**Yeni yaratık:** Venom Marshall  
**Yeni silah:** VX-72 Warden (planlandı)

### Akış
- **0–5 dk:** Komuta düğümüne yaklaşım; VX-72 uzun menzilli VEX keskin nişancı kasasında.
- **5–11 dk:** Venom Marshall tek destek birimi + basit eskort; oyuncuya support önceliği öğretilir.
- **11–18 dk:** Raptor/Ravager/Bulwark/Lancer kombinasyonlarında Marshall hedef seçimi.
- **18–24 dk:** Komuta düğümü ve Vardar imzalı kayıt.

### Kayıtlar
1. **YÖNETİM — “Harici Uygarlık Tepkisi”** — zorunlu ana kayıt.
2. **XENO — “Venom Marshall / Destek Alanı”** — yan saha analiz noktası.
3. **YÖNETİM — “Kaynak Sürekliliği Korunacaktır”** — secret Vardar mesajı.

### Achievement adayı
`KARŞI CEPHE` — Vaskari yayını tamamla.

### Bölümün öğrendiği gerçek
Vardar, yaşayan ve organize bir uygarlığın tepkisini projenin stratejik değerinden daha önemsiz saymıştır.

---

# NHAL VEIL BLOĞU

## BÖLÜM 16 — SESSİZ GÖKYÜZÜ

**Hedef süre:** 18–21 dk  
**Yeni yaratık:** Veilmaw  
**Yeni silah:** Yok  
**Yeni ekipman:** Gece Görüş Modülü — mevcut sistem

### Akış
- **0–5 dk:** Dağ gözlemevi ve ilk tam karanlık alan; gece görüş pickup'ı kontrollü biçimde edinilir.
- **5–10 dk:** Veilmaw orta menzil + reposition tek başına.
- **10–16 dk:** Işık açık/kapalı rotalar, sınırlı enerji/gerilim hissi; NV kullanımı.
- **16–21 dk:** Gözlemevi kubbesi ve Nhal düşük ışık/faz ölçümleri.

### Kayıtlar
1. **TEKNİK — “Perde Maddesi Spektrumu”** — ana teleskop terminali.
2. **PERSONEL — “Gece Vardiyası / Hiç Yıldız Yok”** — yan gözlem odası.
3. **YÖNETİM — “Düşük Işık Araştırma Lisansı”** — gizli araştırma sunucusu.

### Bölümün öğrendiği gerçek
Nhal'dan çekilen şey klasik enerji değil, düşük ışık/faz ve çevresel perde özellikleridir.

---

## BÖLÜM 17 — PERDE ALTINDA

**Hedef süre:** 18–22 dk  
**Yeni yaratık:** Yok; Veilmaw gelişimi  
**Yeni silah:** MP-110 Cyclone (planlandı)  
**NPC:** Uzman Kerem Aksu

### Akış
- **0–4 dk:** Yeraltı haberleşme istasyonu; MP-110 test kasası.
- **4–10 dk:** Veilmaw daha karmaşık görüş çizgileri; silahın yüksek ateş/ısı riski uygulanırsa güvenli öğretim.
- **10–16 dk:** Kerem sinyalini takip eden karanlık route-memory sekansı.
- **16–22 dk:** Kerem kurtarma ve merkezi emir kaydı.

### Kayıtlar
1. **YÖNETİM — “Üretimi Durdurmayın”** — Kerem'in sakladığı zorunlu kayıt.
2. **PERSONEL — “Kerem Aksu / Frekans Günlüğü”** — yan haberleşme kabini.
3. **OLAY — “Merkez Kanalı 00:43”** — gizli ses arşivi.

### Bölümün öğrendiği gerçek
Felaket yaklaşırken kararsızlık bilinmesine rağmen üretim açık emirle sürdürülmüştür.

---

## BÖLÜM 18 — KÖR NOKTA

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Husk Leech  
**Yeni silah:** Yok  
**Yeni araç:** Toksik Maruziyet Monitörü (planlandı)

### Akış
- **0–5 dk:** Metro bakım ağı; monitor ekipmanı bulunur.
- **5–10 dk:** Husk Leech tek başına, görüş kapatma güvenli encounter ile öğretilir.
- **10–16 dk:** Veilmaw reposition + Leech görüş kaybı; rota hafızası.
- **16–22 dk:** Metro güç istasyonu ve Nhal av yolu gözlemi.

### Kayıtlar
1. **XENO — “Husk Leech / Algı Bozma”** — ana saha terminali.
2. **PERSONEL — “Metro Bakım Ekibi / Işıklar Yetmiyor”** — servis odası.
3. **TEKNİK — “Nhal Av Rotası Eşleşmesi”** — gizli bakım harita odası.

### Bölümün öğrendiği gerçek
Nhal organize bir ordu değil; av yolları Dünya'nın karanlık alanlarıyla ekolojik olarak birleşiyor.

---

## BÖLÜM 19 — AV YOLLARI

**Hedef süre:** 19–23 dk  
**Yeni yaratık:** Yok; tam Nhal kombinasyonu  
**Yeni silah:** Yok  
**Yeni görev aracı:** Sinyal İşaret Fişeği (mission-only plan)

### Akış
- **0–5 dk:** Metro/depo/servis şehri bağlantıları; oyuncu geri dönüş noktalarını işaretlemeyi öğrenir.
- **5–12 dk:** Uzun Veilmaw + Leech encounter, güvenli oda araları.
- **12–18 dk:** İki alternatif rota; kayıt/secret için karanlık risk.
- **18–23 dk:** Ana av yolunu enerji hattından ayırma.

### Kayıtlar
1. **TEKNİK — “Çevresel Düzen Kaybı”** — ana enerji arayüzü.
2. **XENO — “Av Yolu / Dünya Eşleşmesi”** — yan harita terminali.
3. **PERSONEL — “Karanlıkta 11 Dakika”** — gizli sığınak ses kaydı.

### Bölümün öğrendiği gerçek
VEX bu evrenden bir yakıt değil, çevresel koşulların kendisini çekerek av düzenini bozmuştur.

---

## BÖLÜM 20 — SESİ OLMAYAN DÜNYA

**Hedef süre:** 21–24 dk  
**Yeni yaratık:** Yok; Nhal yay zirvesi  
**Yeni silah:** VX-90 Chimera (planlandı)

### Akış
- **0–5 dk:** Ana Nhal ankrajı; VX-90 ileri güvenlik laboratuvarında.
- **5–12 dk:** İki Nhal rolü karanlık çok katlı encounter'larda.
- **12–18 dk:** Ağ yönlendirme terminallerini sırayla kapatma; başka hatların yeniden açıldığı görülür.
- **18–24 dk:** Ankraj finali ve ağ dengeleme keşfi.

### Kayıtlar
1. **TEKNİK — “Otomatik Faz Yeniden Yönlendirme”** — ana zorunlu kayıt.
2. **YÖNETİM — “Kendi Kendini Dengeleyen Ağ”** — yan yönetim paneli.
3. **TEKNİK — “Nexus Referansı / Sansürlü”** — gizli çekirdek logu.

### Achievement adayı
`KAYIP ALGI` — Nhal yayını tamamla.

### Bölümün öğrendiği gerçek
Yarık Ağı düğümler kapanınca enerjiyi başka hatlara taşıyan kendi dengeleme davranışına sahiptir.

---

# AETHER LOOM BLOĞU

## BÖLÜM 21 — CAM DENİZ

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Voidweaver  
**Yeni silah:** LX-01 Lumen (planlandı)  
**Yeni araç:** Faz Tarayıcı (planlandı)

### Akış
- **0–5 dk:** Kıyı tesisi; faz tarayıcı ve ilk enerji silahı araştırma kasasında edinilir.
- **5–10 dk:** Voidweaver üç kollu enerji fanı tek başına.
- **10–16 dk:** Faz tarayıcıyla kararsız yüzeylerin okunması ve iki rota.
- **16–22 dk:** Cam Deniz gözlem güvertesi ve uzamsal veri.

### Kayıtlar
1. **TEKNİK — “Faz Kararlılığı / Kaynak Sınıfı 5”** — ana laboratuvar.
2. **XENO — “Voidweaver Örüntü Davranışı”** — yan gözlem camı.
3. **YÖNETİM — “Uzamsal Referans Hasadı”** — gizli Aether sunucusu.

### Bölümün öğrendiği gerçek
Aether'dan çekilen şey enerjiden öte, uzayın kararlılık/örüntü özelliğidir.

---

## BÖLÜM 22 — ÖRÜNTÜ HATASI

**Hedef süre:** 19–23 dk  
**Yeni yaratık:** Yok; Voidweaver gelişimi  
**Yeni silah:** SG-21 Rupture (planlandı)  
**NPC:** Dr. Nadir Volkan

### Akış
- **0–5 dk:** Geometrisi bozuk araştırma kulesi; SG-21 prototip kasası.
- **5–11 dk:** Voidweaver geniş açı baskısı + bozuk görüş hatları.
- **11–17 dk:** Nadir'e ulaşmak için faz tarama/power route.
- **17–23 dk:** Nadir kurtarma, Aether davranışının yorumlanması.

### Kayıtlar
1. **PERSONEL — “Nadir Volkan / Örüntü Notu 6”** — zorunlu.
2. **TEKNİK — “Yara mı, Kapı mı?”** — yan analiz terminali.
3. **YÖNETİM — “Aether Onarım Davranışı / Askerî Değer”** — gizli arşiv.

### Bölümün öğrendiği gerçek
Aether formları yarıkları fetih kapısı değil, bozuk bir desen olarak görüyor olabilir; onarımları Dünya için yine ölümcüldür.

---

## BÖLÜM 23 — FAZ YARIĞI

**Hedef süre:** 19–22 dk  
**Yeni yaratık:** Rift Reaver  
**Yeni silah:** LX-07 Prism (planlandı)  
**Yeni araç:** Faz Sabitleyici (planlandı)

### Akış
- **0–5 dk:** Kırık platformlar; sabitleyici güvenli tutorial geçişinde.
- **5–10 dk:** Rift Reaver phase step + lunge tek başına tanıtılır.
- **10–16 dk:** Voidweaver uzak açı + Reaver yakın açı kombinasyonu.
- **16–22 dk:** İlk Nexus referans terminali ve faz köprüsü kapanışı.

### Kayıtlar
1. **XENO — “Rift Reaver / Komşu Faz Çizgisi”** — ana analiz terminali.
2. **TEKNİK — “Ortak Referans Merkezi”** — yan enerji odası.
3. **YÖNETİM — “NEXUS / Proje Adı”** — secret şifreli terminal.

### Bölümün öğrendiği gerçek
Farklı evrenlerin faz verileri `NEXUS` adlı tek merkezde senkronize edilmiştir.

---

## BÖLÜM 24 — KIRIK GEOMETRİ

**Hedef süre:** 20–23 dk  
**Yeni yaratık:** Yok; tam Aether kombinasyonu  
**Yeni silah:** MP-120 Phantom (planlandı)

### Akış
- **0–5 dk:** Faz dengeleme tesisi; MP-120 saha prototipi.
- **5–12 dk:** Voidweaver + Rift Reaver farklı yükseklik ve açı katmanlarında.
- **12–18 dk:** Faz sabitleme ile iki bağlantı odası ve secret rota.
- **18–23 dk:** Nexus koordinat tablosunun parçaları toplanır.

### Kayıtlar
1. **TEKNİK — “Beş Kaynak / Tek Referans”** — ana laboratuvar.
2. **PERSONEL — “Faz Ekibi / Oda 4 Yok Oldu”** — yan ses kaydı.
3. **YÖNETİM — “Nexus Senkronizasyon Bütçesi”** — gizli yönetim terminali.

### Bölümün öğrendiği gerçek
Daha önce kapatılan düğümlerin koordinatları Nexus tarafından tutulduğu için gerçeklik parçaları yeniden bağlanabiliyor.

---

## BÖLÜM 25 — DOKUMA MERKEZİ

**Hedef süre:** 21–24 dk  
**Yeni yaratık:** Yok; Aether yay zirvesi  
**Yeni silah:** LX-13 Helios (planlandı)  
**Yeni sistem:** Ters Akış Protokolü taslağı

### Akış
- **0–5 dk:** En büyük Aether ankrajı; LX-13 şarjlı atış güvenli test alanında.
- **5–12 dk:** Aether tam aile yoğun encounter.
- **12–18 dk:** Nadir/Selin uzaktan yönlendirirken üç senkronizasyon düğümü kesilir.
- **18–24 dk:** Merkez veri çekimi ve Ters Akış protokolünün ilk uygulanabilir planı.

### Kayıtlar
1. **TEKNİK — “Ters Akış / Taslak 1”** — ana zorunlu kayıt.
2. **PERSONEL — “Nadir + Selin / Ortak Not”** — yan terminal.
3. **YÖNETİM — “Nexus Acil Kontrol Yetkisi”** — secret yönetici anahtarı.

### Achievement adayı
`KIRIK ÖRÜNTÜ` — Aether yayını tamamla.

### Bölümün öğrendiği gerçek
Ağı kapatmak için Dünya senkronizasyonu, ana Sıfır Kaynak referansı ve Nexus ortak faz bağı üç ayrı aşamada kesilmelidir.

---

# YAKINSAMA / FİNAL BLOĞU

## BÖLÜM 26 — KESİŞİM HATTI

**Hedef süre:** 20–24 dk  
**Yeni yaratık:** Yok  
**Yeni silah:** Yok  
**Yeni araç:** Taşınabilir Yarık Ankrajı (planlandı)  
**İlk karma evren operasyonu:** Evet

### Akış
- **0–5 dk:** Metropol sanayi kuşağı; oyuncu taşınabilir ankrajı kurmayı öğrenir.
- **5–12 dk:** Aileler ayrı sektörlerde: Korvath enerji, Thornwild yeşil alan, Nhal alt geçit vb.
- **12–18 dk:** İki sektör sınırında kontrollü çapraz tehdit; ailelerin ittifak olmadığı çevresel olarak gösterilir.
- **18–24 dk:** Sivil tahliye hattı + ilk Ters Akış saha verisi.

### Kayıtlar
1. **OLAY — “Sivil Acil Yayın / Kesişim”** — ana tahliye merkezi.
2. **TEKNİK — “Dengeleme Tepkisi”** — yan ağ kabini.
3. **YÖNETİM — “Kamu Sızıntısını Bastır”** — gizli VEX terminali.

### Bölümün öğrendiği gerçek
Felaket artık gizli tesislerle sınırlı değildir; beş gerçekliğin etkileri Dünya üzerinde fiziksel olarak yakınsamaktadır.

---

## BÖLÜM 27 — BASTION KUŞATMASI

**Hedef süre:** 21–24 dk  
**Yeni yaratık:** Yok  
**Yeni silah:** Yok  
**Yeni sistem:** Üs yatırımlarının görsel/anlatısal karşılığı

### Akış
- **0–5 dk:** Bastion alarmı; oyuncu tanıdığı merkezde hızla savunma görevlerine dağıtılır.
- **5–12 dk:** Sektör bazlı aile tehdidi; ışık/enerji/kapı durumları üs yönetim kararlarını görünür kılar.
- **12–18 dk:** İç servis katı ve veri merkezi savunması.
- **18–24 dk:** Ana terminalin korunması, Vardar konumunun çözülmesi.

### Kayıtlar
1. **PERSONEL — “Leyla / Bastion Savunma Günlüğü”** — ana operasyon odası.
2. **TEKNİK — “Ters Akış Hesaplama Yükü”** — araştırma bölümü.
3. **OLAY — “Vardar Açık Kanalı”** — gizli/opsiyonel yakalanan yayın.

### Achievement adayı
`BASTION AYAKTA` — kuşatmayı tamamla.

### Bölümün öğrendiği gerçek
Vardar'ın ana VEX merkezindeki Sıfır Kaynak referansını hâlâ çalışır tuttuğu kesinleşir.

---

## BÖLÜM 28 — SIFIR KAYNAK

**Hedef süre:** 21–25 dk  
**Yeni yaratık:** Yok  
**Yeni silah:** LX-20 Null (planlandı)  
**Yeni bilgi:** Tam yönetim suç zinciri

### Akış
- **0–5 dk:** Ana VEX merkezi; LX-20 yalnız en yüksek yetkili deneysel kasada, güçlü ama enerji/ısı maliyetiyle.
- **5–12 dk:** Kanat bazlı farklı aile bulaşmaları; encounter kimliği okunur tutulur.
- **12–19 dk:** Yönetim arşivinin üç kilit katmanı, ana kayıtların toplanması.
- **19–25 dk:** Sıfır Kaynak ana referansı kesilir; Vardar Nexus'a geçer.

### Kayıtlar
1. **YÖNETİM — “Canlı Gerçeklik Doğrulandı”** — ana arşiv 1.
2. **YÖNETİM — “Zarar Ölçümü / Devam Kararı”** — ana arşiv 2.
3. **YÖNETİM — “Vardar / Dünya Önceliklidir”** — gizli direktör kaydı.

### Keşif kartı
LX-20 alındığında `SİLAH ARŞİVİ GÜNCELLENDİ // DENEYSEL SINIF IV`.

### Bölümün öğrendiği gerçek
VEX'in suç zinciri tartışmasızdır: kaynak, yaşam, zarar ve olası direnç bilindiği hâlde üretim büyütülmüştür.

---

## BÖLÜM 29 — NEXUS EŞİĞİ

**Hedef süre:** 23–26 dk  
**Yeni yaratık:** Yok  
**Yeni silah:** Yok  
**Yeni sistem:** Beş evrenin ustalık sınavı / ankraj anahtarları

### Akış
- **0–4 dk:** Nexus dış halkası ve merkez hedefinin kurulması.
- **4–8 dk:** Korvath ankraj sektörü.
- **8–12 dk:** Thornwild ankraj sektörü.
- **12–16 dk:** Vaskari ankraj sektörü.
- **16–20 dk:** Nhal ankraj sektörü.
- **20–24 dk:** Aether ankraj sektörü.
- **24–26 dk:** Beş anahtarın senkronizasyondan çıkarılması ve final kapısı.

### Kayıtlar
1. **TEKNİK — “Nexus Yapı Haritası”** — giriş terminali.
2. **XENO — “Beş Yara / Tek Merkez”** — üçüncü sektör sonrası.
3. **PERSONEL — “İlk Nexus Ekibi / Son Mesaj”** — gizli bozuk platform.

### Bölümün öğrendiği gerçek
Nexus doğal bir dünya değil; VEX'in yıllarca zorla ortak referansa bağladığı gerçeklik parçalarının yapay mezarlığıdır.

---

## BÖLÜM 30 — SESSİZ MERKEZ

**Hedef süre:** 23–26 dk  
**Yeni yaratık:** Yok  
**Yeni silah:** Yok  
**Yeni sistem:** Ters Akış'ın üç aşamalı final uygulaması

### Akış
- **0–5 dk:** Çekirdeğe giriş ve hazırlık; bütün kaynaklar okunabilir şekilde verilir.
- **5–11 dk:** Senkronizasyon kesme: ailelerin kısa, kontrollü final baskıları.
- **11–17 dk:** Emiş durdurma: oyuncu beş faz hattı arasında hareket eder.
- **17–22 dk:** Nexus sessizleştirme: çevre çözülürken zaman baskısı; yeni düşman kuralı eklenmez.
- **22–26 dk:** Vardar/Aras final kararı, Ters Akış tamamlanması ve epilog.

### Kayıtlar
1. **TEKNİK — “Ters Akış / Nihai Protokol”** — zorunlu başlangıç terminali.
2. **YÖNETİM — “Son Yetki / H. Vardar”** — final çekirdek yolu.
3. **PERSONEL — “Aras Koral / Operasyon Sonu”** — epilogda otomatik arşivlenen son kayıt.

### Achievement adayları
- `SESSİZ MERKEZ` — ana hikâyeyi tamamla.
- `XENOARŞİV TAMAMLANDI` — 18 aktif yaratığın tamamını keşfet.
- `CEPHANELİK TAMAMLANDI` — 20 silahın tamamını kalıcı edin.
- `YARIK ARŞİVCİSİ` — 90 ana kampanya kaydını bul.

### Final gerçeği
Aras ağı kapatırken Dünya'nın enerji bedelini bilerek kabul eder. Başka dünyaların sürekli çöküşüne dayalı bolluğun sürdürülebilir kurtuluş olmadığına karar verir.

---

# 9. Bölüm başına içerik yoğunluğu matrisi

| Bölüm grubu | Yeni yaratık sıklığı | Yeni silah/araç sıklığı | Kayıt | Ortalama combat yoğunluğu |
|---|---|---|---:|---|
| 1–5 | Çok yüksek | Yüksek | 3/bölüm | Öğretici → orta |
| 6–10 | Yüksek | Yüksek | 3/bölüm | Orta |
| 11–15 | Çok yüksek | Orta-yüksek | 3/bölüm | Orta → yüksek |
| 16–20 | Düşük | Orta | 3/bölüm | Sayıdan çok bilgi baskısı |
| 21–25 | Orta | Yüksek teknoloji | 3/bölüm | Yüksek ama okunabilir |
| 26–30 | Yeni roster yok | Düşük; ustalık odaklı | 3/bölüm | Kontrollü yüksek |

---

# 10. Bastion geri dönüş ritmi

Her bölümden sonra Bastion'a dönüldüğünde en az bir görünür değişim veya yeni etkileşim hedeflenir:

- yeni xeno/weapon/record için terminalde `YENİ` işareti,
- kurtarılan NPC'nin fiziksel olarak üste gelmesi,
- yeni oda / ışık / ekipman kapasitesi,
- silah rafında yeni model,
- yeni görev brifingi,
- ana terminalde yeni evren yüzdesi,
- aynı NPC'nin önceki bölüm hakkında kısa yorum satırı.

Oyuncu iki bölüm üst üste Bastion'a dönüp **hiçbir şey değişmemiş** hissi yaşamamalıdır.

---

# 11. Gerçek achievement omurgası — plan

Oyun içi discovery kartlarından ayrı olarak gerçek başarımlar büyük kilometre taşlarını temsil eder:

- **İLK TEMAS:** İlk xeno kaydını aç.
- **SÖNEN ÇEKİRDEK:** Bölüm 5'i tamamla.
- **KÖKLERİN HAFIZASI:** Bölüm 10'u tamamla.
- **KARŞI CEPHE:** Bölüm 15'i tamamla.
- **KAYIP ALGI:** Bölüm 20'yi tamamla.
- **KIRIK ÖRÜNTÜ:** Bölüm 25'i tamamla.
- **BASTION AYAKTA:** Bölüm 27'yi tamamla.
- **SESSİZ MERKEZ:** Bölüm 30'u tamamla.
- **BEŞ GERÇEKLİK:** Her ana evrenden en az bir xeno keşfet.
- **XENOARŞİV TAMAMLANDI:** 18 aktif yaratığın tamamını keşfet.
- **CEPHANELİK TAMAMLANDI:** 20 silahın tamamını edin.
- **YARIK ARŞİVCİSİ:** 90 ana kampanya kaydını bul.

Platform achievement entegrasyonu ayrı teknik görevdir; bu belge yalnız tasarım kimliğini tanımlar.

---

# 12. Üretim kontrol listesi

Bir bölüm gerçek üretime geçmeden önce:

- [ ] Hedef süre en az 18 dakika için rota/encounter bütçesi var.
- [ ] Dört ritim bloğu belirlenmiş.
- [ ] İlk 25 bölümde yanlış evrenden düşman yok.
- [ ] Yeni yaratık güvenli okunabilir ilk encounter'a sahip.
- [ ] Yeni silah/araç varsa ilk kullanım için düşük baskılı test alanı var.
- [ ] 3 kayıt için fiziksel yer ve kategori belli.
- [ ] En az bir kayıt ana hikâyeyi ilerletiyor.
- [ ] En az bir kayıt opsiyonel keşfi ödüllendiriyor.
- [ ] En az bir secret/yan rota var.
- [ ] Yaklaşık 8–11. dakikada ikmal penceresi var.
- [ ] Final encounter öncesi kaynak kontrolü var.
- [ ] Bölüm sonunda cevap verilen soru ve açılan yeni soru belli.
- [ ] Bastion'a dönüşte neyin değişeceği tanımlı.
- [ ] Discovery kartlarının hangi olaylarda çıkacağı belli.
- [ ] Planlanan fakat uygulanmamış mekanik dokümanda açıkça `planlandı` olarak işaretli.
