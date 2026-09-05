# VEX — ENEMY / YARATIK TASARIM KILAVUZU

## 1. Temel konsept

VEX dünyasındaki her düşman rastgele bir “canavar” değil; **belirli bir evrene, ekosisteme ve toplumsal yapıya ait bir varlık** olmalıdır.

Ana ilke:

- Her yaratık ailesi **tek bir ana evrene** aittir.
- Aynı evrenden gelen yaratıklar ortak bir biyolojiye, görsel dile ve savaş mantığına sahip olur.
- Aynı ailedeki yaratıklar birbirinin kopyası olmaz; her biri ayrı rol, tehdit tipi ve karşı oyun üretir.
- Yaratıkların saldırganlığı çoğu zaman “kötü oldukları” için değil; kaynak kaybı, yabancı çevre stresi, savunma içgüdüsü, görev programı veya bozulan ekolojik düzen nedeniyle ortaya çıkar.
- Hikâye, uygulanmamış bir gameplay özelliğini varmış gibi anlatmamalıdır. Lore ile güncel sahne/script davranışı çelişirse **oyundaki gerçek davranış kaynak kabul edilir ve metin güncellenir**.

> **Evren = ortak kimlik**  
> **Yaratık = özgün rol**  
> **Gameplay = anlatılan tehdidin gerçek karşılığı**

---

## 2. Güncel kaynak-of-truth kuralı

Bu dosya güncel enemy sahneleriyle birlikte düşünülür.

- Can, hız, menzil, saldırı tipi ve özel yetenek gibi uygulanmış özelliklerin kaynağı `scenes/actors/*.tscn` ve ilgili enemy scriptleridir.
- Bu doküman sayısal denge tablosu değildir; **rol, görsel aile ve hikâye kimliğini** tarif eder.
- Bir yaratığın oyunda olmayan görünmezlik, teleport, yön değiştiren mermi, ally buff vb. özelliği bu belgede “mevcut” gibi yazılmamalıdır.
- Planlanan yaratıklar mevcut roster’dan açık biçimde ayrılır.

Güncel aktif roster: **18 yaratık**.

---

## 3. Beş ana evren ve aktif roster

| Evren | Genel kimlik | Aktif yaratıklar |
|---|---|---|
| **Korvath Ocağı** | Isı, basınç, bazalt, ağır endüstriyel biyoloji | Basalt Juggernaut, Cinder Hound, Cinder Spitter, Furnace Carrier, Crucible Warden |
| **Thornwild Sürüsü** | Et, kemik, diken, spor ve sert av-avcı ekolojisi | Ravager, Briar Skulker, Gorehorn, Spore Matriarch |
| **Vaskari Lejyonu** | Disiplinli savaş kastı, mor biyozırh, zehir ve takım baskısı | Vaskari Raptor, Vaskari Ravager, Coil Lancer, Vaskari Bulwark, Venom Marshall |
| **Nhal Veil** | Karanlık, düşük görünürlük, soğuk perde dokusu ve algı bozma | Veilmaw, Husk Leech |
| **Aether Loom** | Yarık dokusu, akıllı enerji örüntüleri ve uzamsal anormallik | Voidweaver, Rift Reaver |

---

## 4. Görsel aile standardı

Aile rengi tek başına bütün sprite'ı boyamak anlamına gelmez. Ama oyuncu yaratığa veya saldırı efektine baktığında **hangi evrene ait olduğunu hızlıca ayırt edebilmelidir**.

| Evren | Ana palet | Görsel anahtar | Kaçınılacak karışıklık |
|---|---|---|---|
| **Korvath** | Siyah/bazalt, kızıl, turuncu, sıcak sarı | Kor, magma çatlağı, ağır kabuk | Soğuk mavi/camgöbeği ana enerji rengi olmamalı |
| **Thornwild** | Koyu et/kızıl, kemik, kirli sarı-yeşil biyolüminesans | Kas, diken, spor, organik yüzey | Fazla teknolojik neon veya düzgün askerî zırh olmamalı |
| **Vaskari** | **Koyu mor, viyole, magenta, siyah** | Biyozırh plakaları, keskin savaş silueti | Aether'in camgöbeği/beyaz enerji diliyle karışmamalı |
| **Nhal Veil** | Mat siyah, lacivert, **soğuk mavi** | Gölge/perde hissi, ince ve rahatsız edici siluet | Vaskari'nin parlak mor askerî paletiyle aynı görünmemeli |
| **Aether Loom** | **Camgöbeği, elektrik mavisi, buz beyazı**, siyah yarık çizgileri | Yarı-maddesel enerji, kırık geometri, faz izi | Ana palet olarak Vaskari moru kullanılmamalı |

### Özel efekt istisnası

**Husk Leech'in toksik yeşil görüş efekti**, Nhal ailesinin ana rengi değil; oyuncuya bulaşan özel durum etkisinin rengidir. Bu nedenle yeşil yalnız zehir/perde etkisinde belirgin olabilir.

---

# 5. Korvath Ocağı

## 5.1 Evren özeti

Korvathlar aşırı sıcak ve basınç altında yaşam kurmuş endüstriyel bir yeraltı uygarlığıdır. VEX, bu evrenden jeotermal enerji ve ısı akışı çekerken ocakların sıcaklık dengesini bozmuş, bazı damarları soğutmuş ve yeraltı altyapısında çökmelere yol açmıştır.

Korvath yaratıkları Dünya'yı ele geçirmek için tasarlanmış bir ordu değildir. Bir bölümü iş canlısı, bir bölümü bakım/taşıma organizması, bir bölümü ise enerji kuyularını koruyan güvenlik kastıdır. Dünya'daki VEX donanımını kaynak kaybının nedeni olarak algılamaları çatışmayı büyütür.

## 5.2 Oynanış kimliği

Korvath yalnız “yavaş yakın dövüş” ailesi değildir. Güncel roster daha doğru biçimde şunu temsil eder:

**yüksek dayanıklılık + ısı tabanlı projectile baskısı + yakın alan termal tehdit + ağır saha kontrolü.**

### 1. Basalt Juggernaut

- **Rol:** Ağır orta menzil kırıcı / tank shooter.
- **Güncel savaş kimliği:** Çok yüksek canla ağır adımlarla ilerler ve yaklaşık 15 m menzilden yüksek hasarlı, büyük sıcak projectile atar. Atışı hızlı spam yerine belirgin hazırlık ve daha yavaş projectile uçuşuyla okunabilir ağır darbe olarak tasarlanmıştır.
- **Hikâye rolü:** Kaya kırma ve lav akışını yönlendirme için yetiştirilmiş yüksek basınç iş organizması.
- **Görsel rol:** Ailenin en iri bazalt kütlesi; kızıl-turuncu çekirdek hissi Korvath kimliğini taşımalıdır.
- **Ayırt edici özellik:** Dayanıklılık ve ağır ranged baskıyı aynı gövdede birleştirir; gücü hızlı ateş hızından değil tek atışın ağırlığından gelir.

### 2. Cinder Hound

- **Rol:** Hızlı yakın menzil takipçisi.
- **Güncel savaş kimliği:** Çok yüksek chase hızı ve oyuncunun fiziksel temasına kadar yaklaşan kısa lunge ile saldırır. Küçük gövdesi ve yakın temas saldırısı Korvath'ın ağır ranged birimlerine karşı tempo katmanı oluşturur.
- **Hikâye rolü:** Dar ocak tünellerinde kaçak ısı, çatlak ve hareket tespiti yapan avcı/bakım canlısı.
- **Ayırt edici özellik:** Korvath'ın ağır yaratıklarının tersine hafif ve saldırgandır; oyuncuyu ranged birimlerin güvenli alanından çıkarır.

### 3. Cinder Spitter

- **Rol:** Mobil orta menzil ısı atıcısı.
- **Güncel savaş kimliği:** Yaklaşık 14 m menzilden **iki atışlık kısa sıcak projectile serisi** kullanır; cover/reposition davranışıyla açı değiştirir ve orta mesafeyi tutmaya çalışır.
- **Hikâye rolü:** Ocaklarda basınç ve sıcak gaz birikimini boşaltan, tehlike anında kızgın madde püskürten çevik bakım organizması.
- **Görsel rol:** Korvath turuncu/kızıl projectile dili güçlü olmalıdır; Basalt kadar iri görünmemelidir.
- **Ayırt edici özellik:** Basalt'ın tek ağır atışının tersine kısa seriyle ritmik baskı kuran, daha hızlı ve daha kırılgan ranged katmandır.

### 4. Furnace Carrier

**Dahili uyumluluk adı:** Sahne/script kimliği `furnice_carrier` olarak korunur; oyuncuya dönük ad **Furnace Carrier**dır.

- **Rol:** Ağır ranged destek / yakın alan termal bozucu.
- **Güncel savaş kimliği:** Uzun menzilli normal projectile kullanır; oyuncu yaklaştığında ayrı **Thermal Burst** saldırısına geçer. Normal atışın zemin etkisi de alan baskısına katkı verir.
- **Hikâye rolü:** Korvath sahalarında ısı çekirdeği ve termal yük taşıyan yarı-organik taşıyıcı.
- **Ayırt edici özellik:** Oyuncuyu hem uzak kalmak hem yaklaşmak konusunda cezalandırabilen iki modlu ağır birimdir.

### 5. Crucible Warden

- **Rol:** Elit koruyucu / miniboss sınıfı.
- **Güncel savaş kimliği:** **Ground Slam** ile çevresel alan baskısı kurar; çok yakına geldiğinde **Heatwave** halkası üretir. Yüksek canı nedeniyle karşılaşmanın merkez hedefidir.
- **Hikâye rolü:** Korvath enerji kuyularını ve kritik akış düğümlerini koruyan güvenlik kastı.
- **Ayırt edici özellik:** Korvath'ın iş canlılarından farklı olarak bilinçli savunma davranışı ve özel saldırı ritmi taşır.

---

# 6. Thornwild Sürüsü

## 6.1 Evren özeti

Thornwild, bitki ve hayvan dokusunun iç içe geçtiği sert bir av-avcı ekosistemidir. VEX bu dünyadan biyokütle enerjisi, enzimatik kaynaklar ve rejeneratif doku örnekleri çekmiştir. Bu müdahale habitat zincirini bozmuş, av bölgelerini daraltmış ve bazı türleri yarık hatlarına doğru sürmüştür.

Thornwild canlıları askerî birlik değildir. Aynı türler birbirinin kokusunu, hareketini ve tehdit davranışını okuyabilir; fakat amaçları fetih değil **hayatta kalma ve yeni av alanına tutunmadır**.

## 6.2 Oynanış kimliği

Thornwild'ın ortak hissi yalnız yakın rush değildir. Güncel aile:

**organik ranged baskı + hibrit avcılık + sert charge + zehirli alan kontrolü** üretir.

### 1. Ravager

- **Rol:** Uzun menzilli organik baskı avcısı.
- **Güncel savaş kimliği:** Yaklaşık 20 m menzilden **tek ve hızlı precision projectile** atar, güçlü lead kullanır ve açık görüş hattını korumaya çalışır.
- **Hikâye rolü:** Avını doğrudan üzerine atlamak yerine uzaktan zayıflatabilen orta seviye sürü avcısı.
- **Ayırt edici özellik:** Thornwild'ın temel uzun menzil avcı atışıdır; Cinder Spitter gibi seri atış veya Coil Lancer gibi askerî nişancı ritmi kullanmaz.

### 2. Briar Skulker

- **Rol:** Hibrit pusu / yakın-menzilli avcı.
- **Güncel savaş kimliği:** Uzakta organik projectile kullanır; oyuncu yakın saldırı eşiğine girince melee saldırıya öncelik verir.
- **Hikâye rolü:** Çalılık ve biyokütle katmanlarında saklanarak zayıf hedef temizleyen keşif avcısı.
- **Ayırt edici özellik:** Mesafeye göre saldırı biçimini gerçek zamanlı değiştirir.

### 3. Gorehorn

- **Rol:** Ağır charge avcısı.
- **Güncel savaş kimliği:** Kısa hazırlık sonrası yönünü kilitler ve düz hat üzerinde çok hızlı şarj olur. Temas oyuncuyu iter ve güçlü darbe hissi üretir; duvara çarpınca daha uzun açık verir.
- **Hikâye rolü:** Kalın kabuklu avları veya biyolojik engelleri devirmek için evrimleşmiş koçbaşı türü.
- **Ayırt edici özellik:** Okunabilir ama çok yüksek ivmeli koridor tehdididir.

### 4. Spore Matriarch

- **Rol:** Zehirli bölge kontrolü / DoT ranged support.
- **Güncel savaş kimliği:** Projectile isabet veya süre sonunda zeminde geniş bir **zehir alanına** dönüşür. Alan oyuncuya tick hasarı ve süreli poison DoT uygular.
- **Hikâye rolü:** Thornwild ekosisteminde spor dağıtan, habitat oluşturan çoğaltıcı kast.
- **Ayırt edici özellik:** **Müttefik buff'lamaz.** Güncel rolü oyuncunun güvenli zeminini azaltmak ve hareket rotasını zehir alanlarıyla bölmektir.

---

# 7. Vaskari Lejyonu

## 7.1 Evren özeti

Vaskari Lejyonu biyozırh, zehir ve askerî kast düzeni üzerine kurulmuş disiplinli bir uygarlıktır. VEX'in çektiği biyotoksin, sinir iletimi ve rejeneratif biyoloji örnekleri Vaskari üretim ve savunma zincirini bozmuştur.

Vaskari diğer ailelerden farklı olarak Dünya'daki yarıkları yalnız kazara geçiş noktası değil, **kontrol edilmesi gereken askerî cepheler** olarak görmeye başlamıştır. Bu onları en organize düşman ailesi yapar.

## 7.2 Görsel kimlik

Vaskari'nin tanınabilir aile rengi **mor/viyole**dir. Siyah-kemiksi biyozırh üzerine mor/magenta enerji veya toksin vurgusu kullanılmalıdır. Aether Loom'un camgöbeği/beyaz diliyle karıştırılmamalıdır.

## 7.3 Beş aktif yaratık

### 1. Vaskari Raptor

- **Rol:** Hızlı yakın menzil taarruz birimi.
- **Güncel savaş kimliği:** Vaskari Ravager'dan daha yüksek sürekli takip temposu ve daha kısa saldırı döngüsüyle oyuncuya hızla kapanır.
- **Hikâye rolü:** Öncü hücum ve takip kastı.
- **Ayırt edici özellik:** Lejyonun tempo kuran hızlı melee birimidir; Ravager'ın ağır saldırı rolünü tekrar etmez.

### 2. Vaskari Ravager

- **Rol:** Ağır yakın menzil hücum varyantı.
- **Güncel savaş kimliği:** Raptor'dan daha dayanıklı ve daha sert vurur. Normal takipte daha yavaştır; asıl hız patlamasını daha güçlü lunge sırasında üretir ve saldırılar arasında daha uzun açık bırakır.
- **Hikâye rolü:** Savunma hattını fiziksel olarak kırmak için yetiştirilmiş ağır saldırı kastı.
- **Ayırt edici özellik:** Raptor süreklilik ve takip temposunu, Ravager ise tek hamlede yüksek fiziksel baskıyı temsil eder.

### 3. Coil Lancer

- **Rol:** Uzun menzil nişancı / çizgisel baskı.
- **Güncel savaş kimliği:** Yaklaşık 22 m menzilden çok hızlı, yüksek hasarlı projectile kullanır. Yakın dövüş sıçraması yoktur.
- **Hikâye rolü:** Lejyonun uzaktan hedef kıran mızrak/atış kastı.
- **Görsel rol:** Projectile ışığı Vaskari ailesine uygun **viyole-mor** ekseninde kalmalıdır.
- **Ayırt edici özellik:** Vaskari'nin gerçek uzun menzil tehdididir.

### 4. Vaskari Bulwark

- **Rol:** Ağır yakın menzil ön hat tutucu.
- **Güncel savaş kimliği:** Çok yüksek dayanıklılıkla yaklaşır ve ağır melee/lunge darbesi uygular.
- **Hikâye rolü:** Hücum kolunun ilerleme hattını koruyan kalın biyozırhlı kalkan kastı.
- **Ayırt edici özellik:** Raptor'un hızını tersine çevirir; alanı dayanıklılık ve gövde tehdidiyle kapatır.

### 5. Venom Marshall

- **Rol:** Komutan / ranged support eliti.
- **Güncel savaş kimliği:** Normal menzilli projectile saldırısına ek olarak **kendi bulunduğu noktada destek alanı kurar**. Bu alan içindeki uygun müttefikleri iyileştirir ve hasarlarını geçici olarak yükseltir.
- **Hikâye rolü:** Küçük Vaskari saldırı kollarını sahada ayakta tutan komuta ve biyokimyasal destek kastı.
- **Ayırt edici özellik:** Diğer Vaskari'lerle beraberken öncelikli hedef hâline gelir; desteği bir hedefe fırlatmaz, kendi savaş hattını güçlendirir.

---

# 8. Nhal Veil

## 8.1 Evren özeti

Nhal Veil, düşük görünürlük, sis, titreşim ve perde benzeri madde akışlarıyla şekillenmiş bir av ekosistemidir. VEX'in düşük ışık/faz maddesi çekimi, bu dünyanın duyusal ve fiziksel sınırlarını bozmuş; av yolları ile yarık ağı arasında istemsiz bağlantılar kurmuştur.

Nhal'ın gerilimi “gerçek invisibility” zorunluluğundan gelmez. Güncel gameplay için aile kimliği daha doğru biçimde:

**karanlıkta konum alma + düşük görünürlük hissi + menzilli taciz + oyuncu görüşünü bozma**dır.

## 8.2 Görsel kimlik

Ana palet **mat siyah, lacivert ve soğuk mavi** olmalıdır. Vaskari moruyla karışmaması gerekir. Husk Leech'in toksik yeşili yalnız özel zehir/görüş etkisi olarak kullanılabilir.

### 1. Veilmaw

- **Durum:** Mevcut.
- **Rol:** Orta menzil harrier / görüş hattı avcısı.
- **Güncel savaş kimliği:** Yaklaşık 12 m menzilden projectile atar; **her atıştan sonra kısa bir reposition penceresiyle** yeni görüş açısı arar ve orta mesafeyi korur.
- **Hikâye rolü:** Nhal av bölgelerinde açık hedefi uzaktan taciz eden çevik avcı formu.
- **Görsel rol:** Projectile ışığı mor yerine Nhal'a ait **soğuk mavi** ekseninde kalmalıdır.
- **Ayırt edici özellik:** Güncel oyunda görünmezlik veya faza girip çıkma yeteneği yoktur; gerilim hareketi, karanlık çevre ve sürekli açı değiştirmesinden gelir.

### 2. Husk Leech

- **Durum:** Mevcut.
- **Rol:** Menzilli algı bozucu / görüş engelleyici destek.
- **Güncel savaş kimliği:** Orta menzilden zehir/perde projectile atar. Oyuncuya isabet ettiğinde ekranı yaklaşık 5 saniye boyunca animasyonlu toksik doku ile kaplar; tekrar isabet mevcut efektin süresini yeniler.
- **Hikâye rolü:** Nhal avcılarının avın yön tayinini ve görsel algısını bozmak için kullandığı düşük kütleli parazit/perde canlısı.
- **Ayırt edici özellik:** Hasardan çok oyuncunun bilgi akışını bozar.

### Planlanan Nhal yaratıkları

#### Murk Stalker
- **Rol:** Hızlı yakın pusu.
- Veilmaw'ın ranged rolünü tekrar etmemeli; Nhal'a eksik olan gerçek yakın mesafe ambush katmanını eklemelidir.

#### Shade Anchor
- **Rol:** Alan sabitleyici elit.
- Çevresel kararma/perde alanı gibi yeni bir gameplay mekaniği gerçekten uygulanırsa roster'a eklenmelidir; uygulanmadan “mevcut” sayılmamalıdır.

---

# 9. Aether Loom

## 9.1 Evren özeti

Aether Loom klasik biyolojiden çok **örüntü, alan, enerji ve uzamsal düzen** üzerinden işleyen bir gerçekliktir. VEX bu evrenden yalnız enerji değil, faz dengesi ve yarık dokusu çekmiştir. Bunun sonucu bazı bölgelerde gerçeklik örüntüsü parçalanmış ve Aether organizmaları Dünya'daki yarıkları doğal bir yara, düğüm veya onarılması gereken bozuk desen gibi algılamaya başlamıştır.

Bu yaklaşım Aether'ı “hepsi Dünya'yı fethetmek isteyen kötü uzaylılar” olmaktan çıkarır. İnsan için ölümcül davranışları, kendi gerçeklik düzenlerini yeniden kurmaya çalışırken Dünya maddesini yanlış bir parçaya dönüştürmelerinden kaynaklanabilir.

## 9.2 Görsel kimlik

Aether Loom, Vaskari'den kesin ayrılmalıdır:

- Ana enerji: **camgöbeği / elektrik mavisi / buz beyazı**.
- İkincil öğe: siyah yarık çizgileri, saydam veya yarı-maddesel bölgeler.
- Mor/viyole yalnız çok küçük geçiş tonu olabilir; aileyi tanımlayan ana renk değildir.

## 9.3 Aktif yaratıklar

### 1. Voidweaver

- **Rol:** Havada süzülen orta menzil enerji dokuyucusu.
- **Güncel savaş kimliği:** Görsel olarak zeminin üzerinde süzülür ve yaklaşık 13.5 m menzilden **üç kollu enerji örgüsü** atar. Merkez projectile ana hasarı taşır; daha düşük hasarlı yan kollar geniş açıyla alan kapatır. Cover/reposition davranışıyla atış açısını düzeltir.
- **Hikâye rolü:** Aether Loom'da yarık ve enerji akışlarını düzenleyen dokuyucu saha organizması; Dünya'da da kırılmış faz çizgilerini çoklu enerji yollarıyla yeniden bağlamaya çalışır.
- **Görsel rol:** Projectile ışığı sıcak turuncu değil, **camgöbeği/soğuk enerji** kimliğini taşımalıdır. Ground shadow yerde kalırken gövde havada okunmalıdır.
- **Ayırt edici özellik:** Uçuş sırasında teleport eden mermi kullanmaz; imzası havada süzülen siluet ve geniş üçlü enerji fanıdır.

### 2. Rift Reaver

- **Rol:** Hızlı yakın menzil yarık avcısı.
- **Güncel savaş kimliği:** Oyuncuya yaklaşır; saldırı başlarken uygun ve güvenli bir nokta varsa oyuncunun çevresine kısa **phase step** yapıp lunge uygular. Saldırı döngüsü bittiğinde güvenli hedef bulunursa recovery phase ile tekrar açı açar.
- **Phase güvenlik kuralı:** Phase noclip değildir; zemin, yükseklik farkı, süpürülmüş gövde yolu ve varış görüş hattı doğrulanır. Duvar/engel üzerinden geçemez ve güvenli nokta yoksa normal lunge'a devam eder.
- **Hikâye rolü:** Yarık sınırlarında yoğunlaşan, bozuk örüntünün içindeki yabancı maddeleri fiziksel olarak parçalayan saldırı formu. Kısa phase hareketi gerçekliği sınırsız teleport etmek değil, yalnız sağlam kalan komşu yarık çizgileri arasında kendini yeniden bağlamaktır.
- **Ayırt edici özellik:** Aether ailesine Voidweaver'ın tersine gerçek yakın mesafe ve uzamsal açı değiştirme baskısı ekler.

## 9.4 Planlanan Aether yaratıkları

### Rift Spindle
- Sabit topçu / alan düğümü. Voidweaver'ın mobil ranged rolünü tekrar etmemeli; sabit alan bölme davranışı getirmelidir.

### Parallax Drone
- Hafif mobil rahatsız edici. Küçük hedef, farklı hareket profili veya yeni nişan baskısı uygulanmadan eklenmemelidir.

### Loom Herald
- Elit koordinatör / miniboss. Faz kayması veya unit coordination gibi gerçek, uygulanmış bir özel sistemle gelmelidir.
- **Tasarımı tamamlanmadan ve nihai sprite/animasyon seti hazır olmadan aktif roster'a alınmamalıdır.**

---

# 10. Güncel enemy haritası

| Aktif düşman | Evren | Gerçek oyun rolü |
|---|---|---|
| Basalt Juggernaut | Korvath | Yavaş, ağır projectile kullanan yüksek dayanıklılıklı tank |
| Cinder Hound | Korvath | Çok hızlı yakın lunge takipçisi |
| Cinder Spitter | Korvath | İki atışlık kısa seri kullanan mobil ısı atıcısı |
| Furnace Carrier | Korvath | Uzun menzil projectile + yakın Thermal Burst |
| Crucible Warden | Korvath | Ground Slam / Heatwave elit koruyucu |
| Ravager | Thornwild | Uzun menzil tek hızlı precision projectile avcısı |
| Briar Skulker | Thornwild | Ranged + yakın melee hibrit avcı |
| Gorehorn | Thornwild | Düz hat ağır charge birimi |
| Spore Matriarch | Thornwild | Zehir alanı ve DoT kontrolü |
| Vaskari Raptor | Vaskari | Hızlı takip + kısa döngülü yakın lunge taarruzu |
| Vaskari Ravager | Vaskari | Daha yavaş takip + sert ve ağır yakın lunge |
| Coil Lancer | Vaskari | Uzun menzil yüksek hızlı nişancı |
| Vaskari Bulwark | Vaskari | Çok dayanıklı yakın ön hat birimi |
| Venom Marshall | Vaskari | Ranged saldırı + heal/damage buff destek alanı |
| Veilmaw | Nhal Veil | Atış sonrası açı değiştiren orta menzil harrier |
| Husk Leech | Nhal Veil | Görüş kapatan zehir projectile desteği |
| Voidweaver | Aether Loom | Havada süzülen üçlü enerji örgüsü tehdidi |
| Rift Reaver | Aether Loom | Güvenli phase step + yakın lunge yarık avcısı |

---

# 11. Evrenlerin oyuncuya verdiği his

| Evren | Ana baskı hissi |
|---|---|
| **Korvath** | “Ağır gövdeler, sıcak projectile'lar ve termal alan beni sıkıştırıyor.” |
| **Thornwild** | “Organik avcılar farklı mesafelerden beni hareket etmeye zorluyor.” |
| **Vaskari** | “Birbirini tamamlayan askerî roller aynı anda savaş hattı kuruyor.” |
| **Nhal Veil** | “Görüşüm ve güvenli bilgi alanım bozuluyor; karanlıkta yanlış pozisyon ölümcül.” |
| **Aether Loom** | “Enerji örgüleri ve kısa faz kaymaları yüzünden düşmanın açısını sürekli yeniden okumam gerekiyor.” |

### Tasarım korumaları

- Korvath yaratıkları gizlilik ailesine dönüşmemeli.
- Thornwild yaratıkları askerî zırhlı birlik gibi görünmemeli.
- Vaskari birimleri tek tek güçlü olmaktan çok **rol kombinasyonuyla** tehdit üretmeli.
- Nhal yaratıklarına lore gereği görünmezlik yazılacaksa önce gerçek gameplay sistemi uygulanmalı.
- Aether düşmanları Vaskari morunu ana aile rengi olarak kullanmamalı.
- Aether phase davranışı kullanıyorsa fizik/zemin güvenliğini bypass eden sınırsız noclip'e dönüşmemeli.
- Aynı ailede yeni yaratık, mevcut birimin yalnız can/hasar artırılmış kopyası olmamalı.

---

# 12. Hikâye uyumu

VEX felaketi yalnız portal açmadı; **başka evrenlerin yaşam ve düzen kaynaklarını sömürdü**.

Her aile için temel soru:

> **“VEX bu evrenden ne çekti ve bunun sonucu bu yaratık neden Dünya'da?”**

- **Korvath:** Isı, basınç dengesi ve jeotermal güç çekildi. Ocaklar soğudu, altyapı çöktü; iş ve koruma canlıları enerji kaynağına doğru sürüklendi.
- **Thornwild:** Biyokütle, enzim ve rejeneratif doku çekildi. Av zinciri bozuldu; yaratıklar yarıkların çevresinde yeni habitat ve av alanı aramaya başladı.
- **Vaskari:** Biyotoksin, sinir iletimi ve savaş biyolojisi örnekleri çekildi. Lejyon bunu düşmanca kaynak saldırısı kabul edip yarıkları askerî cepheye çevirdi.
- **Nhal Veil:** Düşük ışık/faz maddesi ve perde dokusu çekildi. Av yolları ile Dünya'nın karanlık alanları birbirine bağlandı; Nhal türleri istemsiz ekolojik yayılma gösterdi.
- **Aether Loom:** Faz dengesi ve gerçeklik örüntüsü çekildi. Aether formları Dünya yarıklarını bozuk bir desen olarak algılayıp kendi düzenlerini kurmaya çalışırken fiziksel çevreyi tehlikeli biçimde dönüştürdü.

### Ton kuralı

VEX hikâyesinin güçlü tarafı, yaratıkların tamamının “kötü istilacılar” olmamasıdır. Aynı felaket farklı evrenlerde farklı tepki üretir:

- Korvath kaynak kaybına karşılık verir.
- Thornwild göç eder ve avlanır.
- Vaskari organize karşı saldırı yürütür.
- Nhal ekolojik olarak taşar.
- Aether bozuk gerçeklik desenini yeniden düzenlemeye çalışır.

Bu farklı motivasyonlar korunmalıdır.

---

# 13. Güncel üretim durumu

## Aktif / oyunda

1. Basalt Juggernaut
2. Cinder Hound
3. Cinder Spitter
4. Furnace Carrier
5. Crucible Warden
6. Ravager
7. Briar Skulker
8. Gorehorn
9. Spore Matriarch
10. Vaskari Raptor
11. Vaskari Ravager
12. Coil Lancer
13. Vaskari Bulwark
14. Venom Marshall
15. Veilmaw
16. Husk Leech
17. Voidweaver
18. Rift Reaver

## Planlanan ve aileye yeni gameplay katması gerekenler

1. Murk Stalker — Nhal gerçek yakın pusu katmanı
2. Shade Anchor — Nhal alan/perde sabitleme eliti
3. Rift Spindle — Aether sabit alan topçusu
4. Parallax Drone — Aether küçük mobil rahatsız edici
5. Loom Herald — Aether koordinatör/miniboss; tasarım tamamlanana kadar yalnız planned

Eski üretim listesinde mevcut olduğu hâlde “sonra yapılacak” görünen Coil Lancer, Spore Matriarch ve Venom Marshall artık planned listesinde değildir.

---

# 14. İsim ve kimlik standardı

- Oyuncuya dönük ad **Furnace Carrier**; mevcut dosya/kimlik uyumluluğu için `furnice_carrier` korunur.
- Doğru ad **Venom Marshall**dır; `Venom Marshal` kullanılmamalıdır.
- **Vaskari Raptor** ile **Vaskari Ravager** iki ayrı aktif türdür; isimler birbirinin yerine kullanılmamalıdır.
- **Ravager** tek başına kullanıldığında Thornwild yaratığını ifade eder; Vaskari türü her zaman **Vaskari Ravager** olarak yazılır.
- **Rift Reaver** Aether Loom ailesindedir.
- **Cinder Spitter** Korvath Ocağı ailesindedir.

---

# 15. Sonuç

Bu belge bundan sonra yalnız yaratık isimleri listesi değildir. Her enemy için dört şeyin aynı anda tutarlı kalmasını zorunlu kılar:

1. **Görsel aile kimliği**
2. **Gerçek uygulanmış gameplay rolü**
3. **Aile içindeki benzersiz karşı oyun**
4. **VEX felaketiyle doğrudan bağlantılı hikâye nedeni**

Yeni bir yaratık eklenirken şu kontrol yapılmalıdır:

1. Hangi evrenden geliyor?
2. Ailenin ana paletine ve siluet diline uyuyor mu?
3. Mevcut bir yaratığın rolünü tekrar ediyor mu?
4. Oyuncuya gerçekten yeni bir baskı getiriyor mu?
5. Dokümanda anlatılan özel özellik oyunda gerçekten uygulanmış mı?
6. VEX'in o evrenden çektiği kaynakla yaratığın Dünya'da bulunma nedeni mantıklı mı?

Bu altı soruya net cevap verilemiyorsa yaratık henüz VEX roster'ına hazır değildir.
