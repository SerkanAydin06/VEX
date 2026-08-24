# VEX — ENEMY / YARATIK TASARIM KILAVUZU

## 1. Temel konsept

VEX dünyasındaki her düşman, rastgele “canavar” değil; **belirli bir evrene, ekosisteme ve toplumsal yapıya ait bir varlık** olmalıdır.

Ana ilke:

- Her yaratık ailesi **tek bir ana evrene** aittir.
- Aynı evrenden gelen yaratıklar ortak bir biyolojiye, görsel dile ve savaş mantığına sahip olur.
- Ancak aynı evrenin yaratıkları birbirinin kopyası olmaz; her biri **ayrı rol, ayrı tehdit tipi ve ayrı kişilik** taşır.
- Yaratıkların saldırganlığı “kötü oldukları” için değil; çoğu zaman **kaynak kaybı, yön kaybı, yabancı çevre stresi, savunma içgüdüsü veya görev programı** nedeniyle ortaya çıkar.
- Oyun ilerledikçe oyuncu yalnız yaratıkların ne yaptığını değil, **neden burada olduklarını** da öğrenir.

Bu yapı hem hikâyeyi güçlendirir hem de düşman tasarımında net bir çerçeve sağlar:

> **Evren = ortak kimlik**  
> **Yaratık = özgün rol**

---

## 2. Ana tasarım omurgası

Her düşman ailesi aşağıdaki 6 sütuna göre tasarlanmalıdır:

| Başlık | Anlamı |
|---|---|
| Evren kimliği | Geldiği boyutun doğası, kültürü ve fizik mantığı |
| Ortak görsel dil | Siluet, renk, doku, ışık, hareket karakteri |
| Ortak biyoloji / teknoloji | Canlı, yarı-organik, biyomekanik, enerji temelli vb. |
| Ana savaş özelliği | Oyuncuya karşı aileyi ayırt eden ana oynanış davranışı |
| Hikâye nedeni | VEX’in o dünyadan ne çektiği ve neden çatışma çıktığı |
| Bireysel rol farkı | Aynı evrendeki 4 yaratığın birbirinden nasıl ayrıldığı |

---

## 3. Beş ana evren

Şimdilik VEX düşman ekosistemi 5 farklı evrenden oluşur. Mevcut düşmanlar bu yapının içine yerleştirilmiştir.

| Evren | Kod adı | Genel kimlik | Mevcut yaratık |
|---|---|---|---|
| 1 | **Korvath Ocağı** | Aşırı sıcak, basınç, jeotermal madencilik ve kızıl endüstri | HellMagma |
| 2 | **Thornwild Sürüsü** | Kas, kemik, yırtıcılık, sürü baskısı ve biyolojik avcılık | Ravager |
| 3 | **Vaskari Lejyonu** | Disiplinli savaş kastı, zehir, biyozırh ve saldırı düzeni | RedViper, BadRedViper |
| 4 | **Nhal Veil** | Karanlık, perdeleşme, pusudan av, titreşim ve sessiz yaklaşım | Veilmaw |
| 5 | **Aether Loom** | Boşluk, yarık dokusu, akıllı enerji organizmaları ve uzamsal örüntüler | Voidweaver |

---

## 4. Evren 1 — Korvath Ocağı

## 4.1 Evren özeti

Korvathlar, aşırı sıcak ve basınç altında yaşam kurmuş endüstriyel bir yeraltı uygarlığıdır. Enerji, magma kanalları ve derin kaya damarları üzerinden taşınır. VEX, bu evrenden jeotermal enerji ve ısı akışı çekerek Korvath şehirlerinin dengesini bozmuştur.

Korvath varlıkları saldırırken “istila” yapmaz; daha çok **enerji sömürüsünü durdurmaya çalışan, yönünü kaybetmiş ya da işlev bozulmasına uğramış ağır saha organizmaları** gibi davranırlar.

## 4.2 Ortak özellikler

- **Görsel dil:** Siyah bazalt, kızıl çatlaklar, turuncu lav ışığı, ağır sanayi silueti.
- **Beden yapısı:** Yoğun kütleli, yüksek ısı taşıyan, kalın kabuklu.
- **Ana oynanış özelliği:** Alan baskısı, sıcaklık tehdidi, ağır yakın çatışma.
- **Doğal avantaj:** Zırh, yüksek dayanıklılık, ateş/ısı direnci.
- **Genel zayıflık:** Soğutma şoku, parlak çekirdek bölgeleri, yavaş yön değiştirme.

## 4.3 Dört yaratık

### 1. HellMagma

**Durum:** Mevcut

- **Rol:** Ağır ön hat kırıcı
- **Hikâye rolü:** Korvath madenlerinde kaya kırma ve lav akışı yönlendirme için kullanılan biyolojik iş makinesi.
- **Savaş kimliği:** Yavaş ama tehditkâr ilerler; yakın mesafede ezici hasar verir, orta mesafede kızgın çekirdek fırlatabilir.
- **Ayırt edici özellik:** Göğüs/omuz hattındaki erimiş çekirdek zayıf noktadır.

### 2. Cinder Hound

**Durum:** Planlandı

- **Rol:** Hızlı flank yaratığı
- **Hikâye rolü:** Ocak tünellerinde arıza ve sızıntı tespiti yapan avcı canlı.
- **Savaş kimliği:** Çember çizerek yaklaşır, kısa sıçramalar yapar, oyuncuyu pozisyon değiştirmeye zorlar.
- **Ayırt edici özellik:** HellMagma’nın aksine küçük ama agresiftir; sürat ile baskı kurar.

### 3. Furnace Carrier

**Durum:** Planlandı

- **Rol:** Destek / alan bozucu
- **Hikâye rolü:** Isı çekirdeği ve işçi sürüleri taşıyan yarı-organik saha taşıyıcısı.
- **Savaş kimliği:** Öldüğünde yere sıcak alan bırakır; zaman zaman küçük lav kapsülleri bırakır.
- **Ayırt edici özellik:** Doğrudan hasardan çok arena kontrolü yapar.

### 4. Crucible Warden

**Durum:** Planlandı

- **Rol:** Elit koruyucu / miniboss sınıfı
- **Hikâye rolü:** Korvath enerji kuyularının nöbetçi kastı.
- **Savaş kimliği:** Ağır zırhlıdır, kısa menzilli ısı dalgası yayar, saldırıdan sonra açıklık verir.
- **Ayırt edici özellik:** Diğer Korvathlara göre daha “askerî” ve amaçlı davranır.

---

## 5. Evren 2 — Thornwild Sürüsü

## 5.1 Evren özeti

Thornwild, bitki ve hayvan dokusunun birbirine karıştığı, av-avcı dengesinin çok sert olduğu biyolojik bir evrendir. VEX bu dünyadan biyokütle enerjisi, rejeneratif doku örnekleri ve enzimatik güç kaynakları çekmiştir. Bunun sonucu Thornwild’ın üst seviye avcıları yönlerini kaybedip geçitlerden Dünya’ya taşınmıştır.

Bu evrenin yaratıkları daha “kültürlü medeniyet” değil, **vahşi fakat son derece etkili ekolojik savaş organizmaları** gibidir.

## 5.2 Ortak özellikler

- **Görsel dil:** Koyu et tonları, kemik çıkıntılar, diken, kas lifleri, organik yeşil/sarı biyolüminesans.
- **Beden yapısı:** Kaslı, esnek, düşük zırhlı ama atılgan.
- **Ana oynanış özelliği:** Baskın, ani hızlanma, sürü koordinasyonu.
- **Doğal avantaj:** Hızlı kapanma, baskı, yakın mesafe öldürücülük.
- **Genel zayıflık:** Susturucu ateş yerine ani burst hasar, kafatası/boğaz gibi açık organ bölgeleri.

## 5.3 Dört yaratık

### 1. Ravager

**Durum:** Mevcut

- **Rol:** Temel saldırı sınıfı / yakın baskı
- **Hikâye rolü:** Thornwild’ın baskın sürülerine ait orta seviye avcı.
- **Savaş kimliği:** Oyuncuya doğrudan baskı kurar, zigzag yaklaşabilir, boşluk bulunca atılır.
- **Ayırt edici özellik:** “Standart düşman” gibi görünse de aile içinde saldırganlığın temel omurgasıdır.

### 2. Briar Skulker

**Durum:** Planlandı

- **Rol:** Pusu / yan rota baskısı
- **Hikâye rolü:** Sürüye görünmeden yaklaşan keşif ve zayıf hedef temizleme organizması.
- **Savaş kimliği:** Gölge hatlarında kalır, kısa süreli kamuflaj benzeri perdeleme yapar.
- **Ayırt edici özellik:** Ravager’dan daha kırılgan, ama daha sinsi.

### 3. Gorehorn

**Durum:** Planlandı

- **Rol:** Orta-ağır şarj birimi
- **Hikâye rolü:** Thornwild’da kalın kabuklu avları devirmek için kullanılan koçbaşı türü avcı.
- **Savaş kimliği:** Kısa hazırlık sonrası düz hat şarj yapar, çarpınca oyuncunun ritmini bozar.
- **Ayırt edici özellik:** Saf hız yerine ivmelenme tehdidi yaratır.

### 4. Spore Matriarch

**Durum:** Planlandı

- **Rol:** Destek / bölge kontrolü
- **Hikâye rolü:** Ekosistemde sürü feromonlarını ve rejeneratif sporları dağıtan çoğaltıcı kast.
- **Savaş kimliği:** Yakındaki Thornwild birimlerini güçlendirir, yere spor havuzları bırakır.
- **Ayırt edici özellik:** Vurulmadığında karşılaşmayı ciddi şekilde zorlaştırır.

---

## 6. Evren 3 — Vaskari Lejyonu

## 6.1 Evren özeti

Vaskari Lejyonu, savaş kastlarıyla yaşayan, biyozırh ve zehir temelli disiplinli bir uygarlıktır. VEX’in bu evrenden çektiği enerji yalnız güç değil; aynı zamanda biyotoksin, rejeneratif serum ve sinir iletim örnekleridir. Bu da Vaskari savunma ağlarını ve askerî üretim zincirini bozmuştur.

Bu evrenin yaratıkları “vahşi canavar” değildir; **çatışmayı bilen, pozisyon alan, hücum düzeni kuran askerî canlılar** gibi çalışır.

## 6.2 Ortak özellikler

- **Görsel dil:** Koyu kırmızı, siyah, kemiksi biyozırh, yılanımsı hatlar, keskin yüzeyler.
- **Beden yapısı:** Kaslı ama kontrollü; organik zırh plakaları taşır.
- **Ana oynanış özelliği:** Takım baskısı, flank, zehir/kanama, hücum düzeni.
- **Doğal avantaj:** Orta dayanıklılık, iyi takip, agresif hücum kararları.
- **Genel zayıflık:** Kafa, boyun altı, iç karın segmentleri; çevresel patlayıcılar.

## 6.3 Dört yaratık

### 1. RedViper

**Durum:** Mevcut

- **Rol:** Hızlı saldırı / orta seviye elit
- **Hikâye rolü:** Vaskari öncü taarruz kastı.
- **Savaş kimliği:** Oyuncuyu yan açılardan zorlar, ani ataklarla güvenli alan hissini bozar.
- **Ayırt edici özellik:** Sürat ve saldırı kararlılığıyla aileye tempo kazandırır.

### 2. BadRedViper

**Durum:** Mevcut

- **Rol:** Ağırlaştırılmış hücum varyantı
- **Hikâye rolü:** Lejyonun daha saldırgan, daha acımasız kırma birimi.
- **Savaş kimliği:** RedViper’dan daha dirençli ve daha sert vurur; koridor baskısında öne çıkar.
- **Ayırt edici özellik:** Aynı aile içinde “brute” varyantı görevi görür.

### 3. Coil Lancer

**Durum:** Planlandı

- **Rol:** Orta menzilli baskı / sıçrama hücumu
- **Hikâye rolü:** Düşman hattını kırmak için biyolojik mızrak bezleri geliştirilmiş savaşçı.
- **Savaş kimliği:** Oyuncuya çizgisel zehirli diken atar veya ani mızrak sıçrayışı yapar.
- **Ayırt edici özellik:** Aileye ilk gerçek menzilli tehdit hissini getirir.

### 4. Venom Marshal

**Durum:** Planlandı

- **Rol:** Komutan / aura destekli elit
- **Hikâye rolü:** Küçük Vaskari saldırı kollarını sahada yöneten subay kastı.
- **Savaş kimliği:** Yakındaki Vaskari yaratıklara hız ve saldırı cesareti verir; oyuncuyu sürekli yer değiştirmeye zorlar.
- **Ayırt edici özellik:** Tek başına çok tehlikeli olmak yerine grubu ölümcül hale getirir.

---

## 7. Evren 4 — Nhal Veil

## 7.1 Evren özeti

Nhal Veil, sis, gölge, titreşim ve düşük görünürlükle tanımlanan bir av evrenidir. Buradaki canlılar fiziksel güç kadar **görünmezlik hissi, perdeleşme ve sessiz konum alma** üzerine evrimleşmiştir. VEX’in bu evrenden çektiği güç; düşük ışık enerjisi, faz kayması ve perde benzeri madde akışlarıdır.

Bu evrenin yaratıkları Dünya’da özellikle karanlık koridorlarda, görüşün bozulduğu alanlarda ve oyuncunun güven duygusunu zayıflatmak için etkilidir.

## 7.2 Ortak özellikler

- **Görsel dil:** Mat siyah, koyu mor, soğuk mavi kenar ışıması, ince uzun siluet.
- **Beden yapısı:** Hafif, esnek, bazen perde gibi dağılan organik yapı.
- **Ana oynanış özelliği:** Pusu, perdeleme, sessiz yaklaşım, görüş oyunu.
- **Doğal avantaj:** Düşük görünürlükte ölümcüllük, ani baskın.
- **Genel zayıflık:** Güçlü ışık, yakın mesafede açığa çıkan ana gövde merkezi, disiplinli takip ateşi.

## 7.3 Dört yaratık

### 1. Veilmaw

**Durum:** Mevcut

- **Rol:** Pusu avcısı / orta tehdit
- **Hikâye rolü:** Nhal Veil’in avcı kastı; titreşim ve korku tepkisini takip eder.
- **Savaş kimliği:** Perde arkasından yaklaşır, oyuncu fark ettiğinde çoktan etkili mesafeye girmiş olur.
- **Ayırt edici özellik:** Sahne gerilimini doğrudan artıran düşmandır.

### 2. Murk Stalker

**Durum:** Planlandı

- **Rol:** Hızlı yakın pusu
- **Hikâye rolü:** Dar alanlarda ve düşük ışıkta sürü dışı tekil avcı.
- **Savaş kimliği:** Duvar çizgilerine yakın hareket eder, son anda açığa çıkar.
- **Ayırt edici özellik:** Veilmaw’dan daha hızlı, daha kırılgan.

### 3. Hush Leech

**Durum:** Planlandı

- **Rol:** Destek / algı bozucu
- **Hikâye rolü:** Avın yön tayinini bozan düşük kütleli perde canlısı.
- **Savaş kimliği:** Kısa süreli görsel bozulma, nişan dağıtma, perde alanı bırakma.
- **Ayırt edici özellik:** Doğrudan yüksek hasar değil; çatışma ritmini bozar.

### 4. Shade Anchor

**Durum:** Planlandı

- **Rol:** Alan sabitleyici elit
- **Hikâye rolü:** Nhal geçitlerini kararlı tutan, perde alanını yoğunlaştıran çekirdek canlı.
- **Savaş kimliği:** Yakın çevresini karartır, diğer Nhal yaratıklarına yaklaşma avantajı sağlar.
- **Ayırt edici özellik:** Öncelikli hedef hâline gelir; öldürülünce alan rahatlar.

---

## 8. Evren 5 — Aether Loom

## 8.1 Evren özeti

Aether Loom, maddeden çok **örüntü, alan, enerji ve uzamsal düzen** üzerinden işleyen bir gerçekliktir. Buradaki yaşam formları klasik biyolojiye benzemez; bazıları enerji örüntüsü, bazıları yarı-kristal örgü, bazıları da “varlık” ile “mekanizma” arasında duran akıllı yapılardır. VEX bu evrenden yalnız enerji değil; boyutsal faz dengesi ve gerçeklik dokusu çekmektedir.

Bu yüzden Aether Loom yaratıkları en “yabancı” ve en az insanî görünen aile olur.

## 8.2 Ortak özellikler

- **Görsel dil:** Menekşe, indigo, beyaz parlama, yarık çizgileri, örümcekimsi veya geometri bozucu şekiller.
- **Beden yapısı:** Yarı-maddesel, enerji omurgalı, bazen havada asılı.
- **Ana oynanış özelliği:** Uzaysal baskı, menzilli enerji, yer değiştirme ve örüntü kurma.
- **Doğal avantaj:** Beklenmedik açı saldırıları, alışılmadık hareket.
- **Genel zayıflık:** Kararlı çekirdek noktaları, yoğun ateşle faz dengesini bozma, enerji odaklarının kırılması.

## 8.3 Dört yaratık

### 1. Voidweaver

**Durum:** Mevcut

- **Rol:** Menzilli uzaysal tehdit
- **Hikâye rolü:** Aether Loom’da yarık akışını dokuyan akıllı saha organizması.
- **Savaş kimliği:** Oyuncuya enerji/örümsi atışlar gönderir, güvenli mesafe hissini bozar.
- **Ayırt edici özellik:** Fiziksel değil, uzamsal tehdit olarak hissedilir.

### 2. Rift Spindle

**Durum:** Planlandı

- **Rol:** Sabit topçu / taret benzeri destek
- **Hikâye rolü:** Alan istikrarı için belirli noktalara köklenen örüntü düğümü.
- **Savaş kimliği:** Sabit durur ama çizgisel enerji darbeleri ve alan işaretleri üretir.
- **Ayırt edici özellik:** Öncelikli yıkım hedefidir; savaş alanını bölümlere ayırır.

### 3. Parallax Drone

**Durum:** Planlandı

- **Rol:** Hafif rahatsız edici / hareketli menzilli birim
- **Hikâye rolü:** Ana dokuyuculara bilgi ve enerji akışı taşıyan küçük örüntü yaratığı.
- **Savaş kimliği:** Sürekli yer değiştirir, oyuncunun nişan alışkanlığını bozar.
- **Ayırt edici özellik:** Tek başına zayıf, grup içinde sinir bozucu.

### 4. Loom Herald

**Durum:** Planlandı

- **Rol:** Elit koordinatör / miniboss
- **Hikâye rolü:** Aether Loom’da geçit örüntülerini koruyan üst düzey bilinç düğümü.
- **Savaş kimliği:** Voidweaver ve drone türlerini koordine eder, kısa faz kaymalarıyla konum değiştirir.
- **Ayırt edici özellik:** Bu evrenin en “zeki” saha temsilcisidir.

---

## 9. Mevcut düşmanların yeni evren haritası

| Mevcut oyun düşmanı | Bağlı evren | Aile rolü |
|---|---|---|
| Ravager | Thornwild Sürüsü | Temel yakın baskı avcısı |
| RedViper | Vaskari Lejyonu | Hızlı elit hücum birimi |
| BadRedViper | Vaskari Lejyonu | Ağır hücum varyantı |
| Veilmaw | Nhal Veil | Pusu avcısı |
| HellMagma | Korvath Ocağı | Ağır zırhlı kırıcı |
| Voidweaver | Aether Loom | Uzaysal menzilli tehdit |

---

## 10. Oynanış standardı

Her evren oyuncuya farklı tür baskı uygular. Böylece düşman çeşitliliği yalnız model farkı değil, **oynanış hissi farkı** üretir.

| Evren | Oyuncuya hissettirdiği ana baskı |
|---|---|
| Korvath Ocağı | “Ağır, sıcak, alanı kaplayan tehdit” |
| Thornwild Sürüsü | “Hızlı, vahşi, üstüne çöken baskı” |
| Vaskari Lejyonu | “Disiplinli ve koordineli saldırı” |
| Nhal Veil | “Görmediğin şeyden gelen korku” |
| Aether Loom | “Gerçeklik bozan, alışılmadık tehdit” |

Bu tablo tasarım sırasında korunmalıdır. Bir evrenin yaratıkları başka bir evrenin işini yapmamalı; örneğin:

- Korvath düşmanı “çok görünmez ve sinsi” olmamalı.
- Nhal düşmanı “çok tank ve kaba kırıcı” olmamalı.
- Vaskari yaratıkları koordinasyon ve disiplin duygusunu kaybetmemeli.
- Thornwild yaratıkları fazla teknolojik görünmemeli.
- Aether Loom düşmanları klasik “zombi koşusu” hissine düşmemeli.

---

## 11. Hikâye uyumu için ana kural

VEX’in felaketi yalnız portallar açmamış; **başka evrenlerin yaşam, enerji ve düzen kaynaklarını sömürmüştür.** Bu yüzden her aile için şu soru zorunludur:

> “VEX bu evrenden ne çaldı ve bunun sonucu bu yaratık neden Dünya’da?”

### Kısa cevap şablonu

- **Korvath:** Isı ve jeotermal güç çalındı.
- **Thornwild:** Biyokütle, enzim ve rejeneratif doku çalındı.
- **Vaskari:** Biyotoksin, sinir iletimi ve savaş biyolojisi örnekleri çalındı.
- **Nhal Veil:** Düşük ışık enerjisi ve perde maddesi çalındı.
- **Aether Loom:** Faz dengesi, yarık enerjisi ve gerçeklik dokusu çalındı.

Bu çerçeve, düşmanları yalnız “cool canavar” olmaktan çıkarıp hikâyenin merkezine bağlar.

---

## 12. Şimdilik önerilen üretim sırası

Düşman tasarım ve üretim sırası için öneri:

### Önce zaten oyunda olanlar
1. Ravager
2. RedViper
3. BadRedViper
4. Veilmaw
5. HellMagma
6. Voidweaver

### Sonra aileleri tamamlayacak en gerekli yeni yaratıklar
7. Cinder Hound
8. Briar Skulker
9. Coil Lancer
10. Murk Stalker
11. Parallax Drone

### Daha sonra elit / destek / miniboss sınıfları
12. Furnace Carrier
13. Crucible Warden
14. Gorehorn
15. Spore Matriarch
16. Venom Marshal
17. Hush Leech
18. Shade Anchor
19. Rift Spindle
20. Loom Herald

---

## 13. Kısa sonuç

Bu dokümanın amacı VEX düşmanlarını tek tek isimlendirmekten çok, onları **ortak ama tutarlı bir evren sistemine oturtmaktır.**

Bundan sonra her yeni yaratık şu sırayla tasarlanmalıdır:

1. Hangi evrenden geliyor?
2. O evrenin ortak kuralı ne?
3. Aile içindeki görevi ne?
4. Oyuncuya hangi yeni baskıyı hissettiriyor?
5. Hikâyede neden burada?

Bu kurala uyulursa VEX’teki yaratıklar hem görsel olarak hem oynanış olarak hem de hikâye açısından birbirini tamamlayan, güçlü bir düşman ekosistemi oluşturur.
