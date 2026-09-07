# VEX — Bölüm 2: Kül Koridoru

Bu belge Bölüm 2'nin güncel **kanonik üretim planı ve uygulanmış gameplay omurgası**dır. Ana kampanya planındaki `BÖLÜM 2 — KÜL KORİDORU` bloğu kaynak-of-truth kabul edilmiştir.

## 1. Bölüm hedefi

- Oyuncuya dönük ad: **Bölüm 02 // Kül Koridoru**
- Hedef süre: **18–21 dakika**
- Evren odağı: **Korvath Ocağı**
- Aktif düşman türleri: **Cinder Hound + Cinder Spitter**
- Yeni yaratık: **Cinder Spitter**
- İlk kalıcı shotgun: **SG-04 Breacher**
- Yeni araç: **Güç Bypass Kuplörü — planlandı, runtime sistemi henüz aktif değil**
- Kayıt sayısı: **3**
- Secret: **R27 bakım/yönetim cebi**
- Final hedefi: **Bastion iletişim rölesini yeniden açmak ve KOR-TERMAL imzasını yakalamak**
- Bölüm içinde checkpoint yoktur.

Ravager, Vaskari Raptor, Vaskari Ravager, Basalt Juggernaut ve Voidweaver bu bölümün kanonik aktif içeriği değildir.

## 2. Sahne mimarisi

Eski `level_02.tscn`, fiziksel tesis üretimi açısından değerli fakat gameplay açısından 30 bölümlük yeni kampanyadan önce hazırlanmış bir sahneydi. Bu nedenle yapı iki katmana ayrıldı:

- `level_02.tscn` → küçük canonical mission shell; Player, HUD, müzik ve briefing metadata.
- `level_02_structure_source.tscn` → eski sahnenin authored fiziksel kaynağı. Runtime'a yalnız şu kökler aktarılır: `WorldEnvironment`, `Geometry`, `EnemyNavigation`, `Doors`, `RoomLights`, `Lights`, `Props`.
- `level_02_ash_corridor_content.tscn` → yalnız kanonik düşmanlar, SG-04, sigorta zinciri, kaynaklar, kayıtlar, secret ve finish control.
- `level_02_environment_story.tscn` → collision'sız termal izler, oda ekranları, yanık yüzeyler ve sıcaklık ışıkları.

Eski structure source içindeki `Enemies`, `Pickups` ve `Triggers` aktif SceneTree'ye **hiç eklenmez**. Böylece legacy düşmanların `_ready()` çalıştırması veya enemy count'a girmesi engellenir.

## 3. Hikâye amacı

Bastion-7 iletişim rölesine giden servis hattı Kül Koridoru'nda sustu. İlk Kırılma kayıtları aynı hatta düzenli bir dış kaynak frekansı olduğunu göstermektedir. Aras'ın görevi servis hattını yeniden beslemek, röleyi çevrimiçi getirmek ve kaynak imzasını Bastion'a aktarmaktır.

Bölüm sonunda öğrenilen ana gerçek:

> VEX, `KOR-TERMAL` adlı düzenli bir dış kaynak frekansını kazadan **yıllar önce** ayrı bir ölçüm sınıfı olarak izliyordu.

Bu bölüm karşı gerçekliğin tüm yapısal çöküşünü henüz açıklamaz; daha ağır kanıtlar sonraki Korvath bölümlerine bırakılır.

## 4. Akış ve tempo

### 0–4 dakika — Batı servis hattı

- Oyuncu merkez servis düğümünden batı kanadına yönelir.
- İlk Hound baskıları Bölüm 1 bilgisini tazeler.
- **SG-04 Breacher** eski acil durum silah rafında fiziksel pickup olarak bulunur.
- SG-04 pickup'ı 12 başlangıç shell desteği verir; canlı silah resource'u 6'lık şarjör kullanır.

### 4–9 dakika — İlk Spitter teması

- İlk Cinder Spitter tek başına ve düşük alert yarıçapıyla tanıtılır.
- Sonraki encounter Hound + Spitter rol ayrımını öğretir: Hound hareket alanını zorlar, Spitter mesafeden baskı kurar.
- Species health/damage/speed değerleri sahneden override edilmez; yalnız encounter staging için bazı detection/hearing/ally-alert değerleri düşürülür.

### 9–15 dakika — Güç hattı / sigorta zinciri

Mevcut sağlam key-door altyapısı bu bölümde kurgu olarak **röle güç sigortaları** şeklinde kullanılır:

1. Mavi key state → **Mavi Hat Sigortası**
2. Sarı key state → **Sarı Röle Sigortası**
3. Kırmızı key state → **Kırmızı Çıkış Sigortası**

Bu, kapı ve inventory sistemini tekrar yazmadan kampanya planındaki ana rota sigorta zincirini uygular.

**Güç Bypass Kuplörü henüz uygulanmış gameplay sistemi değildir.** Kampanya planındaki kısa/riskli bypass rotası için fiziksel ve hikâyesel alan ayrılmıştır; ileride gerçek ekipman state'i ve bypass paneli uygulandığında bu gizli cep ona bağlanacaktır. Şu an gizli yönetim kaydı authored maintenance pocket içinde keşif ödülü olarak erişilebilir.

### 15–21 dakika — Röle savunması

- Güney/east loop oyuncuyu Bastion iletişim rölesine taşır.
- Normal ve üzeri zorluklarda final alanına ek Spitter katmanları gelir.
- Finish control blue + yellow + red underlying key state'lerini ister; oyuncuya bunlar sigorta olarak sunulur.
- Finalde düşman-ID kilidi yoktur; bölüm erişim zinciri ve final rota savunması üzerinden tamamlanır.
- Finish switch tekrar Bastion-7'ye döner ve campaign completion stage `2` olur.

## 5. Encounter bütçesi

Düşmanlar yalnız Cinder Hound ve Cinder Spitter'dır.

| Zorluk | Hound | Spitter | Toplam |
|---|---:|---:|---:|
| Easy | 8 | 3 | **11** |
| Normal | 10 | 5 | **15** |
| Hard | 11 | 7 | **18** |
| Nightmare | 12 | 8 | **20** |

Dağılım `spawn_min_difficulty` üzerinden yapılır:

- Easy baseline: 11
- Normal+: +4
- Hard+: +3
- Nightmare: +2

Cinder Spitter'ın kanonik species resource'u korunur: 95 base health, ranged burst davranışı ve kendi difficulty multiplier'ları actor sahnesinin otoritesidir.

## 6. SG-04 ve kaynak ekonomisi

SG-04 canlı definition değerleri:

- şarjör: 6
- pellet: 8 × 11 base damage
- fire interval: 0.82 sn
- reserve kapasitesi: 60

Bölüm SG-04'ü 12 başlangıç shell ile verir. Ek shell kaynakları encounter aralarında 8 / 8 / 10 / 12 paketleri halinde dağıtılır; pickup difficulty amount multiplier sistemi korunur.

P-01 için bullets, sağlık ve zırh pencereleri de ana rota üzerinde bulunur. Secret alan kritik mühimmat için zorunlu değildir.

## 7. Kayıtlar

Üç kayıt `VexFieldRecordDatabase` içinde kalıcı koleksiyona bağlıdır.

### R08 — TEKNİK / KOR-TERMAL Kaynak İmzası

Ana servis/röle kaydı. `KOR-TERMAL` frekansının rastgele rift noise değil, tekrarlayan düzenli bir dış kaynak imzası olduğunu ve VEX'in bunu yıllardır izlediğini gösterir.

### R19 — PERSONEL / Röle Teknisyeni / Son Vardiya

Yan servis kaydı. Röle arızası, aşırı ısı ve ilk ranged Korvath formunun çalışan gözlemi üzerinden Cinder Spitter'ın sahadaki varlığını insani bir bakışla doğrular.

### R27 — YÖNETİM / Basınç Sapması Önemsizdir

Secret yönetim kaydı. Teknik ekibin dış kaynak tarafındaki tekrarlayan basınç sapmasını raporladığını, yönetimin bunu yerel verim için risk saymayıp takip/çekim politikasını sürdürdüğünü gösterir.

Bulunan kayıtlar campaign save'e kalıcı yazılır ve Bastion-7 Ana Terminali → **KAYITLAR** altında tekrar okunur. Ölüm/Continue bölüm girişinden başlatır; kayıt discovery state'i korunur.

## 8. Çevresel hikâye

`level_02_environment_story.tscn` yalnız görsel katmandır; navigation/collision otoritesi değildir.

- Batı servis/SG-04 alanı: soğuk güvenlik vurgusu.
- İlk Spitter hattı: sıcak turuncu-kızıl transfer izi.
- Röle transfer alanı: emissive termal conduit vurguları.
- R27 gizli cep: sıcak basınç/yönetim arşivi tonu.
- Final röle hattı: kırmızı acil durum ışığı.

## 9. Canon sınırları

- Basalt Juggernaut Bölüm 3'e saklanır.
- Dr. Selin Erdem Bölüm 3'e saklanır.
- P-07 Bölüm 3'e saklanır.
- Vaskari türleri bu Korvath bloğunda görünmez.
- Güç Bypass Kuplörü planlanmıştır ama henüz fake gameplay özelliği olarak gösterilmez.
- Ana öğrenim `KOR-TERMAL` düzenli dış kaynak frekansıdır; sonraki bölümlerin daha ağır Korvath/VEX kanıtları erkenden açılmaz.

## 10. Kabul kriterleri

- [x] Aktif `level_02.tscn` legacy enemy/pickup/trigger içermeyen küçük mission shell.
- [x] Eski fiziksel geometri ayrı structure source olarak korunuyor.
- [x] Runtime yalnız fiziksel/visual structure köklerini transfer ediyor.
- [x] Aktif düşman ailesi yalnız Cinder Hound + Cinder Spitter.
- [x] Easy/Normal/Hard/Nightmare toplamları 11/15/18/20.
- [x] SG-04 Breacher Bölüm 2 ilk kalıcı shotgun edinimi olarak sahada mevcut.
- [x] Üçlü güç sigorta zinciri mevcut key/door altyapısına bağlandı.
- [x] 3 kanonik kayıt persistent field-record database'e bağlı.
- [x] 1 secret authored bakım cebinde mevcut.
- [x] Final Bastion iletişim rölesi olarak sunuluyor ve Bastion-7'ye dönüyor.
- [x] Çevresel hikâye katmanı collision'sız.
- [ ] Güç Bypass Kuplörü gerçek runtime ekipman/panel sistemi uygulanacak.
- [ ] Godot runtime parse/playthrough testi yapılacak.
- [ ] Gerçek playtest ile 18–21 dakika hedefi ölçülecek.
