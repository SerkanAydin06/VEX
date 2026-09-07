# VEX — Bölüm 1 Üretim Planı: İlk Kırılma

> Bu belge `Story_VEX.md` ve `docs/Campaign_Level_Design_VEX.md` içindeki **Bölüm 1 — İlk Kırılma** kararını, mevcut `scenes/levels/level_01.tscn` geometrisine uygulanabilir gerçek level üretim planına dönüştürür.

## 1. Kanonik sınırlar

- Oyuncuya dönük bölüm adı: **İlk Kırılma**.
- Hedef ilk oynayış süresi: **18–20 dakika**.
- Ana gerçeklik: **Korvath Ocağı**.
- Bölümde aktif xeno ailesi yalnız **Korvath**tır.
- Bölümde tanıtılan tek aktif düşman türü **Cinder Hound**dur.
- İlk kalıcı silah edinimi **P-01 Taktik Tabanca**dır.
- Bölümde SG-04, P-07, P-14, P-20, Ravager, Veilmaw veya Gece Görüş Modülü kanonik edinim / düşman içeriği olarak kullanılmaz.
- Mevcut `level_01.tscn` içindeki 37 odalı geometri ve kapı omurgası korunur; odaların içeriği, amaçları ve encounter dağılımı yeni kanona göre değiştirilir.
- Düşman sayısı artırılarak değil; mesafe, rota, görüş ve ikmal baskısı kademeli yükseltilerek zorluk oluşturulur.
- Bölüm içinde mid-level checkpoint yoktur. Bu nedenle ara ikmal ve final öncesi güvenli kaynak penceresi tasarımın zorunlu parçasıdır.

## 2. Bölümün dramatik amacı

Oyuncu Bölüm 1'in başında ne olduğunu bilmez. İlk varsayımı, VEX tesisinde saklanan deney canlılarının kontrolden çıktığıdır. Bölüm boyunca üç kanıt bu varsayımı parçalar:

1. Güvenlik kameraları Cinder Hound'un laboratuvardan değil **yarıktan geçtiğini** gösterir.
2. Test emri son kapasite artışının tesadüf olmadığını gösterir.
3. Gizli teknik kayıtta bir araştırmacı açıkça şunu söyler: **“Enerji üretmiyoruz. Bir yerden çekiyoruz.”**

Bölüm finalinde oyuncu yüzeye çıktığında uzak VEX tesislerinden yükselen başka enerji sütunlarını görür. Felaket tek bina ile sınırlı değildir. Acil durum ağı Aras'a **Bastion-7** koordinatını verir.

## 3. Mevcut 37 odalı iskeletin yeni sektörleri

Mevcut sahne yeniden kullanılacak ve dört ana sektöre ayrılacaktır:

| Sektör | Odalar | İşlev | Hedef süre |
|---|---|---|---:|
| **A — Güvenlik Sığınağı** | R01–R13 | Uyanış, P-01, temel hareket, ilk Hound | 0:00–4:30 |
| **B — Karantina / Personel Kanadı** | R14–R25 | Hound ritmini büyütme, mavi erişim, iki kayıt, ara ikmal | 4:30–10:30 |
| **C — Reaktör Gözlem / Gizli Araştırma** | R26–R33 | Kırılmanın fiziksel kanıtı, secret R29, teknik kayıt, kırmızı erişim | 10:30–15:30 |
| **D — Tahliye Hattı** | R34–R37 | Final Hound baskısı, son ikmal, yüzey çıkışı, Bastion koordinatı | 15:30–20:00 |

## 4. Ana rota

Ana rota oyuncuya okunur fakat düz bir koridor gibi hissettirilmez:

`R01 → R03 → R07 → R11 → R13 → R15 → R19 → R23 → R25 → R27 → R31 → R35 → R37`

Yan kollar iki amaç taşır:

- kaynak / kayıt / erişim kartı kazanmak,
- ana rota üzerinde görülen fakat hemen erişilemeyen kapıları sonradan açtırarak haritanın birbirine bağlı olduğu hissini vermek.

## 5. Dakika dakika akış

### 0:00–1:15 — R01 / Uyanış

- Aras yerde veya hasarlı güvenlik yatağında bilincini kazanır.
- Silah yoktur.
- Acil kırmızı ışık, düşük güç uğultusu, uzakta metal darbeleri vardır.
- İlk görev: **“GÜVENLİK BÖLMESİNDEN ÇIK”**.
- Hareket, bakış ve etkileşim kısa çevresel yönlendirmeyle öğretilir; uzun tutorial kutuları kullanılmaz.

### 1:15–2:30 — R03 / Güvenlik Dolabı

- P-01 fiziksel güvenlik dolabından alınır.
- P-01 alınmadan ilerideki karantina kapısı açılmaz.
- İlk silah kartı gösterilir:
  - `SİLAH ARŞİVİ GÜNCELLENDİ`
  - `P-01 TAKTİK TABANCA`
- Oyuncuya boş bir güvenlik hedefi / kırılmış panel üzerinden nişan ve ateş için 20–30 saniyelik güvenli alan verilir.
- İlk ana rota kaydı burada veya R03-R07 geçişindeki terminalde bulunur: **Acil Test Emri / 04:17**.

### 2:30–4:30 — R07–R13 / İlk temas

- İlk Cinder Hound, oyuncu onu görmeden önce sesle haber verir.
- İlk encounter **tek Hound**dur; kapı kapanmaz, oyuncunun geri çekilme alanı vardır.
- İlk Hound yenilince:
  - `YENİ XENO KAYDI`
  - `CINDER HOUND // KORVATH OCAĞI`
- R11'de ikinci tekli Hound farklı açıdan gelir.
- R13'te kısa iki-Hound encounter'ı ile reload + geri hareket birlikte sınanır.
- Bu noktaya kadar başka düşman türü yoktur.

### 4:30–7:00 — R15–R19 / Karantina personel kanadı

- Ana rota R15'ten R19'a ilerler.
- Sağ kol `R14 → R18 → R17` güvenlik gözetim alanıdır.
- R17'de **mavi erişim kartı** bulunur.
- Aynı yan kolda ikinci kayıt vardır: **Güvenlik Kamerası 07**.
- Kayıt görüntüsü / metni ilk kez yaratığın açık yarıktan geçtiğini doğrular.
- Encounter düzeni:
  - R15: 1 Hound,
  - R18: 1 Hound,
  - R17 dönüşü: 2 Hound kontrollü pusu.

### 7:00–10:30 — R19–R25 / Hasarlı laboratuvar hattı

- Mavi kart R25→R27 geçişinin güvenli açılma zincirine katkı verir.
- R19–R23 arasında oyuncu cam arkasından doğrudan savaşmadan kırılma bölgesini görür: yanmış VEX ekipmanı, bazalt kalıntısı, ısı deformasyonu.
- R23 **ara ikmal odasıdır**:
  - garantili tabanca mühimmatı,
  - küçük sağlık,
  - Normal ve üzeri zorlukta sınırlı zırh.
- R24 gibi kısa yan cepte çevresel hikâye bulunabilir ama yeni kalıcı silah verilmez.
- R25'te 2 Hound; biri görüşte, biri sesle sonradan katılır. Oyuncuya yapay spawn hissi vermemek için ikincisi yan servis kapısından fiziksel olarak gelir.

### 10:30–12:30 — R27 / Reaktör gözlem sektörü

- Oyuncu ilk kez ana yarık hasarını açık biçimde görür.
- Alanın amacı büyük savaş değil, atmosfer ve kanıttır.
- R27'de 1 Hound, daha sonra R30 bağlantısından ikinci Hound gelir.
- Ana hedef güncellenir: **“TAHLİYE KONTROLÜNE ULAŞ”**.

### 12:30–14:30 — R29 / Gizli araştırma cebi

- Existing `R29` secret odası korunur ve Bölüm 1'in ana secret alanına dönüştürülür.
- Secret ana rotadan zorunlu değildir; çevresel kablo izi, kırık duvar işareti veya bakım paneliyle okunur.
- Burada **P-07 verilmez**.
- Ödül:
  - üçüncü kayıt **TEKNİK — Enerji Üretmiyoruz**,
  - yüksek miktarda P-01 mühimmatı,
  - küçük sağlık veya zırh,
  - ilk `KAYIT ÇÖZÜLDÜ` kartı için güçlü bir lore anı.
- Kayıt metninin kilit cümlesi: **“Enerji üretmiyoruz. Bir yerden çekiyoruz.”**
- Bu kaydı bulan oyuncu hikâyenin gerçek yönünü Bölüm 1 içinde erken kavrar; bulmayan oyuncu ana hikâyeyi yine anlayabilir ama ayrıntıyı Bastion arşivinde daha sonra eksik görür.

### 14:30–15:30 — R31–R33 / Kırmızı erişim

- Sol yan kol `R28 → R32 → R33` tahliye kontrol hattıdır.
- **Kırmızı erişim kartı R33**te kalır.
- Oyuncu R33'e giderken iki Hound'u dar koridor yerine küçük açık servis odasında karşılar.
- Kırmızı kart, R35→R37 final karantina kapısı için gereklidir.

### 15:30–18:30 — R34–R35 / Final baskısı

- R35 öncesinde final ikmali:
  - en az bir şarjör P-01 mühimmatı,
  - orta sağlık,
  - zorluk moduna göre küçük zırh.
- Final encounter Normal zorlukta **3 Hound** olarak kademeli gelir:
  1. biri önden görülür,
  2. ikinci yan kapıdan 1.5–2 saniye sonra girer,
  3. üçüncü oyuncu pozisyon değiştirdikten sonra arka servis hattından katılır.
- Aynı anda üç Hound oyuncunun üstünde doğmaz.
- Hard/Nightmare zorluk artışı ek dalga veya daha kısa giriş aralığıyla yapılabilir; Cinder Hound'un scene-authored temel statları bu bölüm için ayrıca ezilmez.

### 18:30–20:00 — R37 / Tahliye ve dış dünya

- R37 savaş sonrası sessiz bir dekompresyon alanıdır.
- Finish switch sıradan “bölümü bitir” düğmesi gibi görünmemeli; **acil tahliye / dış kapı kontrolü** olarak yeniden sunulmalıdır.
- Kapı açıldığında oyuncu dış alana veya kısa kontrollü vista noktasına çıkar.
- Uzakta birden fazla VEX tesisinden yükselen enerji sütunları görülür.
- Leyla'nın zayıf acil durum sinyali veya otomatik ağ mesajı Bastion-7 koordinatını verir.
- Bölüm sonucu: **“BASTION-7 KOORDİNATI ALINDI”**.
- Sonraki sahne Bastion-7 olmalıdır; Bölüm 2 seçimi/operasyonu hub üzerinden açılır.

## 6. Oda oda üretim tablosu

| Oda | Yeni adı / işlev | Combat | İçerik / ödül |
|---|---|---|---|
| **R01** | Güvenlik Sığınağı | Yok | Uyanış, hareket/bakış |
| **R02** | Hasarlı Personel Cebi | Yok | Çevresel ceset/eşya, küçük sağlık opsiyonu |
| **R03** | Güvenlik Dolabı | Yok | **P-01**, Kayıt 1 terminali |
| **R04** | Gözlem Cebi A | Yok | İlk yarık izini uzaktan gösteren pencere |
| **R05** | Bakım Geçidi A | Yok | Kısa alternatif rota / çevresel anlatı |
| **R06** | Kapalı Servis Dolabı | Yok | Küçük mühimmat |
| **R07** | İlk Temas Koridoru | **1 Hound** | İlk xeno discovery |
| **R08** | Güvenlik İzleme Cebi | Yok | İlk Hound sonrası nefes alanı |
| **R09** | Kablo Bakım Cebi | Yok | Secret olmayan küçük kaynak |
| **R10** | Medikal Acil Dolabı | Yok | Küçük sağlık |
| **R11** | Karantina Kavşağı | **1 Hound** | Reload/mesafe tekrar testi |
| **R12** | Personel Dolabı | Yok | Az mühimmat |
| **R13** | Sektör A Çıkışı | **2 Hound** | İlk küçük ikili sınav |
| **R14** | Gözetim Yan Koridoru | Yok | R17 yan rotasına yönlendirme |
| **R15** | Personel Karantina | **1 Hound** | Sektör B girişi |
| **R16** | Sol Servis Cebi | Yok | Kaynak / çevresel bilgi |
| **R17** | Güvenlik Supervisor Odası | Dönüşte **2 Hound** | **Mavi kart**, **Kayıt 2: Güvenlik Kamerası 07** |
| **R18** | Kamera Erişim Koridoru | **1 Hound** | R17 bağlantısı |
| **R19** | Laboratuvar Giriş Holü | Yok | Bazalt/ısı deformasyonu ilk net çevresel işaret |
| **R20** | Soğutma Yan Cebi | Yok | Sağlık veya mühimmat |
| **R21** | Hasarlı Teknik Oda | Yok | Sadece environmental storytelling |
| **R22** | Numune İzleme Cebi | Yok | Yan rota, xeno görünüm detayı |
| **R23** | **Ara İkmal** | Yok | Garantili P-01 mühimmat + sağlık |
| **R24** | Personel Not Cebi | Yok | Opsiyonel kısa metin / kaynak |
| **R25** | Reaktör Ön Karantina | **2 Hound** | Mavi kart sonrası geçiş |
| **R26** | Sağ Servis Geçidi | Yok | R30/R29 secret yönlendirme |
| **R27** | Reaktör Gözlem Holü | **1+1 Hound** | Ana kırılma vistası |
| **R28** | Sol Tahliye Servisi | Yok | R32/R33 kırmızı kart rotası |
| **R29** | **Gizli Araştırma Arşivi** | Yok | **Secret**, **Kayıt 3: Enerji Üretmiyoruz**, güçlü ikmal |
| **R30** | Reaktör Yan Servisi | **1 Hound** | R27'ye katılan fiziksel rota |
| **R31** | Tahliye Ana Hattı | Yok | Tempo düşüşü / alarm sesi |
| **R32** | Tahliye Kontrol Geçidi | **1 Hound** | R33 öncesi tehdit |
| **R33** | Karantina Kontrolü | **1 Hound** | **Kırmızı kart** |
| **R34** | Final Servis Cebi | Yok | Küçük zırh veya sağlık |
| **R35** | Son Karantina Holü | **3 Hound kademeli** | Final encounter öncesi garantili ikmal |
| **R36** | Acil Güç Cebi | Yok | Finale alternatif küçük kaynak |
| **R37** | Tahliye Kontrol / Vista | Yok | Çıkış, enerji sütunları, Bastion koordinatı |

## 7. Encounter bütçesi

### Normal hedefi

Normal zorlukta ana rota ve zorunlu yan rotayla yaklaşık **12–14 Cinder Hound** hedeflenir. Secret odasında düşman zorunlu değildir; secret ödülü keşif olmalıdır.

Önerilen Normal dağılım:

- R07: 1
- R11: 1
- R13: 2
- R15: 1
- R18: 1
- R17 dönüşü: 2
- R25: 2
- R27/R30: 2
- R32/R33 hattı: 2
- R35 final: 3

Bu ham toplam 17 olabilir; üretimde rota çakışmalarına göre 12–14 aktif karşılaşma hedefi korunmalıdır. Bazı yan rota Hound'ları yalnız ilgili rota seçilince yüklenmelidir.

### Zorluk ölçekleme ilkesi

- **Easy:** bazı ikili encounter'lar tekliye iner; daha fazla mühimmat/sağlık.
- **Normal:** planın temel sürümü.
- **Hard:** seçili yan girişlere 1 ek Hound veya dalga aralığı kısalır.
- **Nightmare:** ek Hound + daha az kaynak; fakat kör arkadan spawn kullanılmaz.

Cinder Hound'un can/hasar/hız değerleri `scenes/actors/cinderhound.tscn` ve mevcut difficulty multiplier sistemi kaynak-of-truth'udur. Bölüm 1 scriptine ikinci bir hasar/can tuning tablosu yazılmaz.

## 8. Üç ana kayıt

### Kayıt 1 — OLAY / Acil Test Emri / 04:17

**Yer:** R03 ana rota terminali.  
**Kaçırılabilirlik:** Çok düşük.  
**Amaç:** Son kapasite artışının planlı olduğunu göstermek.

İçerik özeti:
- testin normal çalışma penceresinin dışında zorlandığını,
- bazı sensörlerin kararsızlık uyarısı verdiğini,
- üst komutanın kapasite artışını yine de onayladığını söyler.

### Kayıt 2 — PERSONEL / Güvenlik Kamerası 07

**Yer:** R17 supervisor odası.  
**Kaçırılabilirlik:** Orta; mavi kart almak için rota güçlü biçimde teşvik edilir.  
**Amaç:** Cinder Hound'un laboratuvardan kaçmadığını, yarıktan geldiğini doğrulamak.

İçerik özeti:
- kamera önce termal bozulma gösterir,
- sonra kapalı odada geçit oluşur,
- ilk Hound geçitten çıkar.

### Kayıt 3 — TEKNİK / Enerji Üretmiyoruz

**Yer:** R29 secret araştırma arşivi.  
**Kaçırılabilirlik:** Yüksek.  
**Amaç:** Bölümün en güçlü gizli hikâye ödülü.

İçerik özeti:
- enerji akışında dış termal imza bulunduğu,
- sistemin enerji üretmediği,
- başka bir yerden enerji çektiği,
- raporun üst yönetime gönderilmeden önce kilitlendiği anlaşılır.

Ana cümle:

> **“Enerji üretmiyoruz. Bir yerden çekiyoruz.”**

## 9. Discovery / arşiv bildirimleri

Bölüm 1'de üç kart sınıfı kullanılır:

1. **P-01 ilk kalıcı edinim**
   - `SİLAH ARŞİVİ GÜNCELLENDİ`
   - `P-01 TAKTİK TABANCA`

2. **İlk Cinder Hound kalıcı keşfi**
   - `YENİ XENO KAYDI`
   - `CINDER HOUND // KORVATH OCAĞI`

3. **Kayıt edinimleri**
   - `KAYIT ÇÖZÜLDÜ`
   - kayıt başlığı

Kartlar gameplay'i durdurmaz. Birden fazla kart aynı anda tetiklenirse sıraya alınmalıdır. Ayrıntılı lore kart üzerinde değil, terminalde okunur.

## 10. FieldLink Veri Modülü

FieldLink Bölüm 1'in anlatısal / UI omurgasıdır ve **henüz uygulanmış runtime ekipmanı değildir**.

Üretim hedefi:

- P-01 dolabının yanında veya R03 güvenlik terminalinde Aras'ın güvenlik bilek sistemine veri erişimi yeniden bağlanır.
- Bundan sonra kayıtlar, xeno keşifleri ve silah katalogları Bastion terminaline aktarılabilir.
- Ayrı bir envanter yuvası işgal etmek zorunda değildir.
- FieldLink gerçek gameplay mekaniği geliştirilene kadar yalnız discovery/kayıt sisteminin kurgu açıklaması olarak kalabilir.

## 11. Tutorial sadeleştirme

Mevcut Bölüm 1 prototipindeki uzun eğitim zinciri yeni hikâye temposuna göre sadeleştirilmelidir.

Hedef contextual eğitim:

1. hareket/bakış — R01,
2. etkileşim — R03 P-01 dolabı,
3. aim/fire — R03 güvenli hedef alanı,
4. reload — ilk Hound sonrası,
5. sprint/geri mesafe — R11 civarı,
6. erişim kartı — R17,
7. secret çevresel ipucu — R29 zorunlu olmayan öğreti,
8. final tahliye kontrolü — R37.

Tutorial kapı açma koşulları yaratığın **species `enemy_id`** değerini değiştirerek kurulmaz. `enemy_id` arşiv sisteminin kanonik `cinderhound` kimliği olarak kalmalıdır. Encounter/gate takibi gerekiyorsa ayrı node adı, encounter id veya gate trigger kullanılmalıdır.

## 12. Işık, ses ve atmosfer

### Sektör A
- acil kırmızı ışık + kısa beyaz floresan arızaları,
- uzaktan tırmalama/metal sesi,
- müzik minimal.

### Sektör B
- daha fazla sıcak hava/buhar,
- güvenlik hoparlöründe parçalı karantina anonsları,
- Hound sesleri encounter'dan önce yön ipucu verir.

### Sektör C
- Korvath sıcak turuncu/kızıl ışık ilk kez çevreye belirgin şekilde sızar,
- yarık uğultusu ve düşük frekanslı enerji sesi artar,
- secret R29'da müzik geri çekilir, kayıt ön plana çıkar.

### Sektör D
- alarm daha hızlı,
- final encounter sonrası müzik kesilir,
- R37 dış vista anında yalnız rüzgâr, uzak patlamalar ve enerji sütunu uğultuları kalır.

## 13. Kaynak / adalet standardı

Checkpoint olmadığı için Bölüm 1 kaynakları bilinçli yerleştirilir:

- R03: P-01 + başlangıç mühimmatı,
- R10: küçük sağlık,
- R12/R20: küçük mühimmat,
- R23: ana ara ikmal,
- R29 secret: güçlü ama zorunlu olmayan ödül,
- R34/R35: final öncesi sağlık + mühimmat.

Oyuncunun kritik mühimmatı yalnız secret'a bağlı olmamalıdır.

## 14. Mevcut prototipten migration listesi

`level_01.tscn` gerçek sahne dönüşümünde aşağıdaki işlemler yapılacaktır:

### Korunacak

- 37 odalı temel geometri,
- ana koridor / yan kol bağlantıları,
- R17 mavi kart mantığı,
- R33 kırmızı kart mantığı,
- R29 secret alanı,
- R37 final/finish konumu,
- sahne/Inspector-authoritative kapı ve pickup yerleşimleri.

### Bölüm 1'den çıkarılacak / sonraki bölümlere taşınacak

- Ravager encounter'ları,
- Veilmaw encounter'ı,
- Gece Görüş Modülü pickup'ı,
- SG-04 kanonik edinimi,
- P-07 kanonik edinimi,
- P-20 kanonik edinimi,
- Bölüm 1 için uygun olmayan diğer ileri silah test pickup'ları.

### Eklenecek / dönüştürülecek

- Cinder Hound-only encounter seti,
- P-01 fiziksel ilk edinim noktası,
- üç kayıt interactable'ı,
- discovery-card tetikleri,
- R29 gizli teknik arşiv içeriği,
- R37 Bastion-7 çıkış beat'i,
- contextual training akışı.

Bu migration sırasında odaların gameplay yerleşimleri mümkün olduğunca `.tscn`/Inspector otoriteli kalmalıdır; sırf kolaylık için düşman/pickup pozisyonları `level_01.gd` içine sabit Vector3 listeleri olarak taşınmamalıdır.

## 15. Kabul kriterleri

Bölüm 1 yeni kanona göre tamamlandı sayılmadan önce:

- [ ] İlk oynayış hedef süresi 18–20 dakika civarında.
- [ ] Ana ve yan rotalarda yalnız Cinder Hound kullanılıyor.
- [ ] Cinder Spitter henüz spawn olmuyor.
- [ ] P-01 oyuncunun ilk kalıcı silah edinimi.
- [ ] SG-04/P-07/P-20/Gece Görüşü Bölüm 1 kanonik pickup'ı değil.
- [ ] Üç ana kayıt yerleştirilmiş ve kalıcı kayıt sistemine bağlanmış.
- [ ] R29 secret alanı gerçek secret olarak sayılıyor.
- [ ] İlk Cinder Hound keşfi xeno arşivini açıyor.
- [ ] İlk P-01 edinimi silah arşivi kartını gösteriyor.
- [ ] Mavi kart R17, kırmızı kart R33 üzerinden rota geri bağlantısı çalışıyor.
- [ ] R23 ve R35 çevresinde zorunlu ikmal pencereleri var.
- [ ] Finish switch tahliye kontrolü olarak sunuluyor.
- [ ] Bölüm sonu Bastion-7'ye geçiyor.
- [ ] Enemy species kimliği tutorial gate için değiştirilmemiş; `cinderhound` kanonik kalıyor.
- [ ] Godot headless parse + level runtime testi gerçek sahne migration'ından sonra çalıştırılıyor.
