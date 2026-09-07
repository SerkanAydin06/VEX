# VEX — YARIK PROTOKOLÜ

## Belge durumu ve kaynak-of-truth

Bu belge VEX'in **ana hikâye, perde yapısı ve 30 bölümlük ana kampanya planı** için kanonik taslak kaynaktır.

- Güncel ana kampanya: **30 bölüm**.
- 30 bölümün tamamı saha operasyonudur. **Bastion-7 numaralı bir bölüm değildir**; bölümler arasında geri dönülen, hikâye ve sistemlerle büyüyen ana merkezdir.
- Oyuncuya dönük bölüm adlandırmasında **VEX-01 / VEX-02 / VEX-03 dizilimi kullanılmaz**. Mevcut üretilmiş sahnelerde eski dahili operasyon kimlikleri teknik uyumluluk için bir süre kalabilir; yeni kampanya isimleri oyuncuya dönük kanondur.
- İlk 25 bölüm, beş ana gerçekliği beşer bölümlük ayrı yaylar hâlinde işler. Erken oyunda farklı evrenlerin yaratıkları karıştırılmaz.
- Bölüm 26-30 yakınsama ve final perdesidir. Bu noktada aileler aynı operasyon içinde görülebilir; ancak tek bir ortak “xeno ordusu” gibi anlatılmaz.
- Yaratıkların aktif roster ve gerçek savaş davranışı için `Enemies_VEX.md` ile `scenes/actors/*.tscn` ve ilgili scriptler kaynak-of-truth'tur.
- Güncel ana kampanya **18 aktif yaratık / 5 ana evren** üzerine kuruludur. Planlanan yaratıklar ana hikâyeyi tamamlamak için zorunlu değildir.

Bu 30 bölümlük yapı yalnız oyunu uzatmak için tasarlanmamıştır. Ana amaç, oyuncunun her yeni gerçekliği önce anlaması, o gerçekliğin yaratıklarını kademeli öğrenmesi, sonra daha karmaşık encounter'lara geçmesi ve finalde öğrendiği bütün karşı oyunları kullanmasıdır.

---

# Hikâyenin özü

Yakın gelecekte Dünya uzun süren bir enerji krizinin içindedir. Şehirlerin elektrik şebekeleri, su arıtma sistemleri, ağır sanayi ve savunma altyapısı sürekli kapasite sınırında çalışmaktadır. Devletler görünürde ortak çözüm ararken perde arkasında enerji üstünlüğü için yarışır.

Bu yarışın en gizli projelerinden biri **VEX — Vektörel Enerji ve Xenoaraştırma Dairesi**dir.

VEX'in amacı yakıt tüketmeden sürekli enerji sağlayacak bir sistem geliştirmektir. Yıllar süren deneylerin sonunda **Sıfır Kaynak Reaktörü** çalıştırılır. İlk sonuçlar olağanüstüdür. Reaktör görünürde hiçbir kaynaktan beslenmeden devasa miktarda güç üretmektedir.

Fakat enerji yoktan gelmemektedir.

Sıfır Kaynak, mikroskobik boyutsal yarıklar üzerinden başka gerçekliklerden enerji ve madde özellikleri çekmektedir. VEX başlangıçta bunu anlamaz. Daha sonra akışın içinde jeotermal ısı, biyolojik enerji, sinirsel iletim örüntüleri, düşük ışık/faz maddesi ve fiziksel uzay dokusuna ait anomaliler tespit edilir.

VEX böylece beş ana kaynak sınıfını keşfeder:

1. **Korvath Ocağı** — ısı, basınç ve jeotermal güç.
2. **Thornwild Sürüsü** — biyokütle, enzim ve rejeneratif doku.
3. **Vaskari Lejyonu** — biyotoksin, sinir iletimi ve savaş biyolojisi.
4. **Nhal Veil** — düşük ışık/faz maddesi ve perde dokusu.
5. **Aether Loom** — faz dengesi ve gerçeklik örüntüsü.

Başlangıçta VEX yönetimi bu kaynakların cansız veya kendini yenileyen boyutsal alanlardan geldiğini varsayar. Sonraki araştırmalar bunun yanlış olduğunu gösterir. Bazı akışlarda yapılaşmış bölgeler, biyolojik döngüler, davranış örüntüleri ve yaşayan toplumlara ait izler bulunur.

Bu noktada proje durdurulmaz.

Dünya'nın enerji altyapısı Sıfır Kaynak'a bağlanmaya başlamıştır. Sistemi kapatmak ekonomik çöküş, siyasi kriz ve stratejik güç kaybı anlamına gelecektir. VEX yönetimi tehlikeyi ortadan kaldırmak yerine sınıflandırır:

> **“Harici gerçeklik etkisi: kabul edilebilir operasyonel maliyet.”**

Daha fazla güç için yeni düğümler açılır. Mikroskobik yarıklar birbirini bulur ve senkronize olur. Bir noktadan sonra sistem tek reaktör olmaktan çıkar; kendi faz referansını kullanan dev bir **Yarık Ağı**na dönüşür.

Son kapasite artışında sınır kırılır.

VEX tesislerinde eş zamanlı patlamalar yaşanır. Kalıcı geçitler açılır. Dünya'ya yalnız enerji değil, başka gerçekliklerin canlıları, biyolojik yapıları ve fiziksel koşulları da geçmeye başlar.

Fakat bu tek bir istila değildir.

- Korvath, kaybettiği ısı ve basıncın kaynağına yönelir.
- Thornwild'ın av zinciri parçalanır ve türler yeni habitatlara taşar.
- Vaskari, kaynak çekimini doğrudan düşman saldırısı sayarak organize karşı cephe kurar.
- Nhal Veil'in av yolları Dünya'nın karanlık bölgeleriyle üst üste biner.
- Aether Loom, kırılmış gerçeklik desenini kendi kurallarına göre onarmaya çalışır.

İnsanlık bunların hepsine önce aynı adı verir: **istila**.

Aras Koral'ın hikâyesi, bu kelimenin ne kadar yetersiz olduğunu öğrenmesiyle büyür.

---

# Ana tema

VEX “bilim kötüdür” hikâyesi değildir. Bilgiye ulaşmak felaketin sebebi değildir; **anlaşılmayan bilginin sonuçları bilindikten sonra bile güç uğruna kullanılmaya devam edilmesi** felaketin merkezidir.

VEX yönetiminin savunması tamamen anlamsız değildir. Sıfır Kaynak gerçekten şehirleri ayakta tutmuş, enerji kıtlığını azaltmış ve milyonlarca insanın yaşamını kolaylaştırmıştır.

Sorun, sistemin bedeli ortaya çıktığında başlar.

VEX şu kararı verir:

> Dünya'nın refahı için bedeli başka gerçeklikler ödeyebilir.

Aras'ın yolculuğu bu kararın sonuçlarını beş farklı dünyada görmesidir.

Hikâye boyunca oyuncunun soruları aşamalı değişir:

1. **Ne oldu?**
2. **Bu canlılar nereden geliyor?**
3. **Neden Dünya'dalar?**
4. **VEX neyi çekiyordu?**
5. **Yönetim yaşayan dünyalara zarar verdiğini biliyor muydu?**
6. **Bu felaket gerçekten kazayla mı büyüdü?**
7. **Yarık Ağı artık kendi kendini mi sürdürüyor?**
8. **Dünya'nın enerji ihtiyacı başka dünyaları sömürmeyi haklı çıkarır mı?**
9. **Ağ kapatılırsa Dünya'nın ödeyeceği bedel kabul edilebilir mi?**
10. **Sistemi yok etmek yerine onu kontrol etmenin güvenli bir yolu gerçekten var mı?**

---

# Oyuncu karakteri — Başçavuş Aras Koral

Oyuncu **Başçavuş Aras Koral**'ı yönetir. Aras, VEX'in saha güvenliğinde görev yapan askerî personeldir. Projenin gerçek amacı kendisinden gizlenmiştir; ona stratejik temiz enerji araştırmalarını koruduğu söylenmiştir.

Aras seçilmiş kişi değildir. Özel güçleri yoktur. Onu merkeze taşıyan şey eğitimli olması, felaketin ilk saatlerinde hayatta kalması ve gerçeği öğrendikçe sorumluluktan kaçmamasıdır.

## Aras'ın 30 bölümlük karakter yayı

### Bölüm 1-5 — Hayatta kalma ve ilk şüphe

Aras yaratıkları saldırgan istilacılar olarak görür. Korvath yayının sonunda ilk kez onların Dünya'ya gelişinin VEX'in kaynak çekimiyle doğrudan bağlantılı olduğunu öğrenir.

### Bölüm 6-10 — Suçun ölçeğini görme

Thornwild, VEX'in yalnız enerji değil yaşayan ekosistemleri de “kaynak” olarak sınıflandırdığını gösterir. Aras'ın sorusu artık “onları nasıl durdururuz?” değil, “biz onlara ne yaptık?” hâline gelir.

### Bölüm 11-15 — Karşı savaş

Vaskari, Aras'ın ilk kez planlı ve organize bir karşılıkla yüzleşmesini sağlar. VEX'in başka bir uygarlığın gözünde saldırgan taraf olduğunu kabul etmek zorunda kalır.

### Bölüm 16-20 — Kontrolün kaybı

Nhal Veil yayı, felaketin askerî veya teknolojik bir savaş olmaktan çıkıp gerçekliklerin ekolojik olarak birbirine karışmasına dönüştüğünü gösterir. Aras artık tek tek portal kapatmanın yeterli olmadığını anlar.

### Bölüm 21-25 — Gerçeğin yapısı

Aether Loom, Yarık Ağı'nın yalnız bağlantı kurmadığını; farklı gerçeklikleri yapay bir ara yapıda birbirine zorladığını ortaya çıkarır. Nexus gerçeği burada anlaşılır.

### Bölüm 26-30 — Sorumluluk ve seçim

Aras ağı susturmanın Dünya'yı yeniden ağır enerji krizine sokacağını öğrenir. Buna rağmen başka dünyaların sürekli çöküşü üzerine kurulu bir sistemin “kurtuluş” olamayacağına karar verir.

---

# Bastion-7 — Bölümler arasındaki ana merkez

Bastion-7 numaralı bir bölüm değildir. Aras **Bölüm 1'in sonunda** ana Yarık Ağı'ndan fiziksel olarak ayrılmış bu eski güvenli tesise ulaşır ve Yüzbaşı **Leyla Sönmez** ile birlikte burayı operasyon merkezine dönüştürür.

Her görevden sonra oyuncu Bastion'a dönebilir. Hikâyedeki ilerleme burada fiziksel olarak görünür:

- yeni odalar açılır,
- aydınlatma ve enerji geri gelir,
- kurtarılan uzmanlar üste görünür,
- xeno arşivi yeni yaratıkları ve evrenleri kaydeder,
- yeni operasyonlar açılır,
- önce boş olan alanlar yaşayan bir karargâha dönüşür.

Planlanan ana uzman kadrosu:

| Kişi | Ana hikâye rolü | Kampanyadaki ana kazanım noktası |
|---|---|---:|
| Yüzbaşı Leyla Sönmez | Operasyon koordinasyonu | Bölüm 1 sonrası |
| Dr. Selin Erdem | Enerji / reaktör mühendisliği | Bölüm 3 |
| Dr. Ece Tan | Saha tıbbı / biyolojik analiz | Bölüm 9 |
| Cem “Kurt” Yalın | Eski VEX güvenliği / saha doktrini | Bölüm 13 |
| Derya Keskin | Lojistik / tesis operasyonu | Bölüm 14 |
| Uzman Kerem Aksu | Haberleşme / istihbarat | Bölüm 17 |
| Dr. Nadir Volkan | Boyutsal fizik | Bölüm 22 |

Bu kişiler hikâyeye ve Bastion'ın fiziksel gelişimine bağlanır. Gerçek gameplay sistemi uygulanmadan kesin buff, ekonomi bonusu veya savaş avantajı varmış gibi anlatılmaz.

---

# Zorluk ve yaratık tanıtım kuralı

İlk 25 bölümde temel kural şudur:

> **Önce evreni öğret, sonra o evrenin yeni rolünü ekle, en son aile kombinasyonunu sınav hâline getir.**

Bu nedenle ilk bölümlerde karışık evren spawn'ları kullanılmaz.

## Evren blokları

| Bölümler | Ana gerçeklik | Tasarım amacı |
|---|---|---|
| 1-5 | Korvath Ocağı | Temel savaş, takip, ranged baskı, ağır düşman, elit alan kontrolü |
| 6-10 | Thornwild Sürüsü | Organik ranged, hibrit avcı, charge, zehirli alan ve hareket yönetimi |
| 11-15 | Vaskari Lejyonu | Organize yakın hat, sniper baskısı, tank ön hat ve destek önceliği |
| 16-20 | Nhal Veil | Karanlık, açı okuma, görüş kaybı ve bilgi baskısı |
| 21-25 | Aether Loom | Enerji fanı, açı kontrolü, güvenli phase step ve uzamsal baskı |
| 26-30 | Yakınsama / Nexus | Öğrenilen bütün ailelerin kontrollü birleşimi ve final sınavı |

---

# PERDE I — KORVATH: SÖNEN ÇEKİRDEK

## Bölüm 1 — İlk Kırılma

### Ana ortam

Yeraltındaki bir VEX enerji araştırma kompleksi. Felaket birkaç dakika önce yaşanmıştır. Acil aydınlatma çalışır, bazı koridorlarda buhar ve sıcaklık artışı vardır, güvenlik kapıları otomatik karantinaya geçmiştir.

### Düşman tanıtımı

**Cinder Hound** kampanyanın ilk aktif yaratığıdır. İlk bölüm bilinçli olarak tek ana düşman rolü üzerine kurulur. Oyuncu hareket, nişan, mühimmat ve hızlı yakın takipçiye karşı mesafe korumayı öğrenir.

### Hikâye

Aras bir güvenlik odasında bilincini kazanır. Komuta kanalı ölüdür. Tesis içindeki yaratıkların önce kaçmış deney organizmaları olduğunu düşünür. Güvenlik görüntülerinde ise kırmızı-siyah bir yarığın açıldığı ve Cinder Hound'ların doğrudan o geçitten geldiği görülür.

Bir laboratuvar kaydında yarım kalmış cümle vardır:

> **“Enerji üretmiyoruz. Bir yerden çekiyoruz.”**

Aras tesisten çıkar ve gecenin karanlığında başka VEX noktalarından yükselen enerji sütunlarını görür. Olay tek tesise ait değildir.

### Bölüm sonu

Aras acil durum protokolünde geçen bağımsız güvenli tesis **Bastion-7**'ye yönelir. Burada Leyla Sönmez ile temas kurulur ve oyun boyunca kullanılacak ana üs kurulur.

---

## Bölüm 2 — Kül Koridoru

### Ana ortam

Bastion'a en yakın enerji aktarım tünelleri ve eski jeotermal servis hattı.

### Yeni düşman

**Cinder Spitter** ilk kez eklenir. Artık oyuncu Cinder Hound'un yakın baskısıyla Spitter'ın orta menzil projectile baskısını aynı aile içinde okumayı öğrenir.

### Hikâye

Bastion'ın dış iletişimini açmak için eski aktarım rölesinin tekrar çalıştırılması gerekir. Aras ilerledikçe tünellerde normal Dünya jeolojisine ait olmayan bazalt yapıların oluştuğunu görür.

Röle kayıtlarında Sıfır Kaynak'ın farklı frekanslarda enerji çektiği ve “KOR-TERMAL” adlı bir kaynak imzasının yıllardır izlendiği ortaya çıkar. Bu noktada VEX'in karşı taraftaki dünyayı ne kadar bildiği hâlâ belirsizdir.

### Bölüm sonu keşfi

Leyla, aynı termal imzaya bağlı daha büyük bir tesis tespit eder. Orada hayatta kalan mühendis sinyali vardır: **Dr. Selin Erdem**.

---

## Bölüm 3 — Basınç Hattı

### Ana ortam

Yüksek basınç boruları, reaktör servis galerileri ve çökmüş test odaları.

### Yeni düşman

**Basalt Juggernaut** tanıtılır. Hound hızlı yakın tehdit, Spitter mobil ranged baskı, Juggernaut ise yüksek dayanıklılık ve ağır projectile ile üçüncü katmanı oluşturur.

### Hikâye

Aras Selin'e ulaşmaya çalışırken tesis arşivinde ilk gerçek kanıtı bulur: VEX, enerji akışının jeolojik olarak aktif ve düzenli bir sisteme bağlı olduğunu kazadan aylar önce biliyordur.

Selin kurtarıldığında daha ağır gerçeği açıklar. Akış doğal bir yıldız veya boşluk alanından değil, **düzenlenmiş ısı damarlarından** gelmektedir. Başka bir gerçeklikte bu enerjiyi kullanan yapıların olabileceğinden şüphelenmiştir; raporu gizlenmiştir.

### Bölüm sonu

Selin Bastion'a katılır. İlk kez Yarık Ağı'nın tek reaktörden oluşmadığını ve farklı kaynak düğümlerinin ortak bir senkronizasyon sistemi kullandığını gösterir.

---

## Bölüm 4 — Erimiş Damar

### Ana ortam

Terk edilmiş bir maden şehrinin altındaki büyük ısı aktarım istasyonu.

### Yeni düşman

**Furnace Carrier** tanıtılır. Oyuncu artık uzak menzil baskısı ile yakına girildiğinde oluşan termal tehdit arasında karar vermek zorundadır.

### Hikâye

Aras tesisin alt katlarında Dünya'ya ait olmayan işaretler, düzenli tünel yüzeyleri ve yapısal izler bulur. Bunlar vahşi bir mağara sistemine değil, karşı tarafta işlenmiş bir altyapıya işaret eder.

VEX kayıtları sonunda gerçeği doğrular: yıllar süren enerji çekimi Korvath tarafındaki ısı ve basınç dengesini düşürmüş, bazı galerilerin çökmesine neden olmuştur.

Aras ilk kez şu ihtimalle yüzleşir:

> Korvathlar Dünya'yı işgal etmiyor olabilir; **kaybettikleri enerjinin yönüne doğru geliyor olabilirler.**

---

## Bölüm 5 — Sönen Çekirdek

### Ana ortam

Korvath bağlantısının Dünya'daki en büyük termal ankrajı. Bazalt ve VEX endüstriyel yapıları iç içe geçmiştir.

### Yeni düşman / yay zirvesi

**Crucible Warden** tanıtılır. Beş Korvath yaratığının tamamı artık kullanılabilir. Encounter'lar önce ayrı roller, sonra kontrollü aile kombinasyonları şeklinde yükselir.

### Hikâye

Aras ankrajı kapatmak için merkeze ilerlerken VEX'in “harici kaynak stabilizasyonu” adlı belgelerine ulaşır. Yönetim, Korvath tarafında yapılaşmış alanların zarar gördüğünü öğrenmiş fakat enerji akışını azaltmak yerine çekiş yönünü değiştirmiştir.

Bu bölüm Korvathların toplum yapısını tamamen açıklamaz; ama onların yalnız vahşi yaratık sürüsü olmadığını kesinleştirir.

### Büyük kırılma

Aras ilk büyük ankrajı devre dışı bırakır. Ancak sistem kapanmaz. Selin beş farklı kaynak imzasının aynı ağ üzerinde çalıştığını tespit eder.

Korvath yalnızca **birinci kaynaktır**.

---

# PERDE II — THORNWILD: YARALI EKOSİSTEM

## Bölüm 6 — Yeşil Karantina

### Ana ortam

Bir VEX biyolojik araştırma sahasının çevresi. Beton koridorlar kök, kas benzeri doku ve hızlı büyüyen organik yüzeylerle kaplanmaktadır.

### Yeni düşman

**Ravager** tanıtılır. Thornwild yayı Korvath'tan farklı olarak uzun menzilli organik precision baskıyla başlar.

### Hikâye

VEX'in ikinci kaynak sınıfının enerji değil, doğrudan **biyolojik üretkenlik** olduğu ortaya çıkar. Rejeneratif dokular, enzimler ve yüksek hızlı hücresel yenilenme yıllardır laboratuvarlarda incelenmektedir.

Aras'ın ilk görevi karantina merkezindeki örnek arşivini güvenceye almak ve yayılmanın yönünü belirlemektir.

---

## Bölüm 7 — Diken İzleri

### Ana ortam

Terk edilmiş tarım araştırma alanları, seralar ve yarık biyokütlesiyle kaplanmış servis tünelleri.

### Yeni düşman

**Briar Skulker** eklenir. Uzakta projectile, yakında melee davranışıyla oyuncuya mesafe değiştiren ilk Thornwild hibritini öğretir.

### Hikâye

Aras canlıların rastgele yayılmadığını görür. Bazı türler belirli biyokütle ceplerini takip etmekte, bazı bölgeleri ise tamamen terk etmektedir. VEX araştırma kayıtları Thornwild'ın karmaşık bir av-avcı zincirine sahip olduğunu gösterir.

Kaynak çekimi yalnız tek türü değil, tüm besin zincirini bozmuştur.

---

## Bölüm 8 — Boynuz Geçidi

### Ana ortam

Yarık bitki örtüsünün bir otoyol bakım kompleksi ve drenaj vadisiyle birleştiği geniş saha.

### Yeni düşman

**Gorehorn** tanıtılır. Düz hat charge baskısı, Ravager ve Briar'ın kurduğu pozisyon oyununu bozar. Oyuncu artık yalnız cover aramak yerine güvenli kaçış hattını da düşünmek zorundadır.

### Hikâye

Bastion ekibi Thornwild canlılarının yarık çevresinde kalıcı yuva alanları kurduğunu fark eder. Bu davranış planlı fetih değil, çöken habitat zincirinin başka tarafa taşmasıdır.

VEX ise felaketten önce bu göç belirtilerini “örnek yoğunluğunda artış” olarak kaydetmiş ve projeyi durdurmamıştır.

---

## Bölüm 9 — Spor Bahçesi

### Ana ortam

Eski bir tıbbi biyoteknoloji merkezi ve çevresindeki sporla kaplanmış yerleşke.

### Yeni düşman

**Spore Matriarch** tanıtılır. Zehir alanı ve DoT baskısı, Thornwild ailesinin hareket alanı kontrolünü tamamlar.

### Hikâye

Aras tesiste mahsur kalan **Dr. Ece Tan** ve yaralı personelin sinyalini bulur. Ece'nin biyolojik analizleri, VEX'in Thornwild'dan çektiği rejeneratif maddelerin Dünya'daki tıbbi programlarda kullanılmaya başlandığını gösterir.

Bu keşif hikâyeyi ahlaki olarak zorlaştırır: VEX'in çaldığı kaynaklar gerçekten hayat kurtarmıştır.

Ancak aynı kaynak çekimi karşı taraftaki ekosistemin çöküşünü hızlandırmıştır.

### Bölüm sonu

Ece Bastion'a katılır. Xeno örnekleri artık yalnız “düşman dokusu” değil, başka ekosistemlerin parçaları olarak sınıflandırılmaya başlanır.

---

## Bölüm 10 — Köklerin Hafızası

### Ana ortam

Dünya tarafında yarık üzerinden büyümüş en büyük Thornwild biyokütle kolonisi.

### Yay sınavı

Ravager, Briar Skulker, Gorehorn ve Spore Matriarch birlikte kullanılır. Encounter'lar oyuncuyu precision ateş, hibrit yaklaşma, charge hattı ve zehir alanı arasında hareket etmeye zorlar.

### Hikâye

Koloninin merkezinde VEX'in eski biyolojik emiş modülü bulunur. Aras modülü kapatırken kayıtların yalnız veri toplamadığını, karşı taraftaki biyolojik döngünün verimliliğini ölçüp en yüksek üretim anlarında çekiş yaptığını keşfeder.

Yani VEX Thornwild'ın yaşayan bir ekosistem olduğunu yalnız bilmemiş; **onu daha verimli sömürmek için davranışını modellemiştir.**

### Büyük kırılma

Aras için felaket artık yalnız bir kaza değildir. Sistem kazadan önce etik sınırı çoktan aşmıştır.

Aynı anda Bastion, üçüncü kaynak imzasında düzenli ve tekrarlayan askerî benzeri sinyal paketleri algılar.

---

# PERDE III — VASKARI: KARŞI CEPHE

## Bölüm 11 — Mor Cephe

### Ana ortam

Bir VEX sınır dinleme tesisi ve çevresinde yeni oluşan mor biyozırhlı geçiş hattı.

### Yeni düşman

**Vaskari Raptor** tanıtılır. Hızlı takip ve kısa lunge döngüsüyle Vaskari'nin agresif ön hat kimliği kurulur.

### Hikâye

Korvath ve Thornwild'dan farklı olarak bu bölgede davranışlar rastgele değildir. Vaskari birimleri belirli enerji ekipmanlarını hedef almakta, geçitleri korumakta ve tekrar eden hatlar üzerinden hareket etmektedir.

Aras ilk kez karşı tarafın yalnız tepki vermediğini; **operasyon yürüttüğünü** anlar.

---

## Bölüm 12 — Kırıcı Hat

### Ana ortam

VEX lojistik tünelleri ve ele geçirilmiş ağır servis hangarları.

### Yeni düşman

**Vaskari Ravager** eklenir. Raptor'ın hızına karşı daha ağır, daha yavaş ve daha sert yakın lunge tehdidi oluşturur.

### Hikâye

Selin ve Leyla, ele geçirilen sinyal dizilerinin VEX enerji düğümleriyle eşleştiğini fark eder. Vaskari birlikleri rastgele insan yerleşimlerini değil, öncelikle **Yarık Ağı altyapısını** işaretlemektedir.

Bu onları dost yapmaz; yollarındaki insan unsurlarını tehdit olarak görmektedirler. Ancak amaçları Dünya'yı kolonileştirmekten çok saldırının kaynağını susturmaktır.

---

## Bölüm 13 — Mızrak Menzili

### Ana ortam

Açık saha radar kompleksi, uzun görüş koridorları ve hasarlı savunma platformları.

### Yeni düşman

**Coil Lancer** tanıtılır. Uzun menzilli yüksek hızlı atış, oyuncuyu Vaskari yakın birimleriyle uğraşırken açık alanda kalmamaya zorlar.

### Hikâye

Aras tesiste eski VEX güvenlik personeli **Cem “Kurt” Yalın**'a ulaşır. Cem, felaketten önce bazı VEX saha birimlerinin “harici kaynak alanlarında canlı muhalefet” ihtimaline karşı eğitildiğini anlatır.

Bu, yönetimin olası karşı tepkiyi düşündüğünü kanıtlar.

Cem emirlere itiraz ettiği için operasyon dışına alınmış ve olay başladığında tesiste mahsur kalmıştır. Kurtarıldıktan sonra Bastion'a katılır.

---

## Bölüm 14 — Kalkan Duvarı

### Ana ortam

Ağır yük terminali ve taşınabilir Sıfır Kaynak çekirdeklerinin depolandığı lojistik merkez.

### Yeni düşman

**Vaskari Bulwark** tanıtılır. Çok dayanıklı yakın ön hat birimi, Coil Lancer'ın geriden kurduğu baskıya alan kazandırır.

### Hikâye

Aras burada **Derya Keskin**'i ve VEX lojistik kayıtlarını bulur. Felaket sonrasında bile bazı üst yönetim emirleri taşınabilir çekirdeklerin güvenli bölgelere gönderilmesini istemiştir.

Amaç ağı kapatmak değildir.

Amaç, sistemi **yeniden kurabilmek için çekirdekleri korumaktır**.

Derya Bastion'a katılır ve VEX'in hangi tesislerinin hâlâ malzeme ve enerji taşıdığını haritalandırır.

---

## Bölüm 15 — Zehirli Emir

### Ana ortam

Vaskari'nin Dünya tarafında kurduğu en büyük geçiş cephesi ile bir VEX komuta düğümünün üst üste bindiği bölge.

### Yeni düşman / yay zirvesi

**Venom Marshall** tanıtılır. Ranged saldırı ve destek alanı, Vaskari'yi ilk kez tam bir rol kombinasyonu ailesine dönüştürür. Oyuncu yalnız en yakın hedefi değil, savaş hattını ayakta tutan destek birimini önceliklendirmeyi öğrenir.

### Hikâye

Bastion ekibi Vaskari sinyal düzenini tam dil olarak çeviremez; fakat tekrar eden askeri işaretleri ve hedef önceliklerini çözer. VEX'in biyotoksin, sinir iletimi ve savaş biyolojisi örneklerini uzun süre çektiği anlaşılır.

Vaskari bunu doğal kaynak kaybı değil **düşmanca biyolojik saldırı** olarak sınıflandırmıştır.

### Büyük kırılma

Aras VEX Genel Direktörü **Haluk Vardar** imzalı eski bir emre ulaşır:

> “Harici uygarlık tepkisi projenin stratejik değerini değiştirmez. Kaynak sürekliliği korunacaktır.”

Vardar artık hikâyenin insan tarafındaki ana karşıt görüşünü temsil eder: Dünya'nın hayatta kalmasının başka gerçekliklerin haklarından daha önemli olduğuna inanmaktadır.

---

# PERDE IV — NHAL VEIL: KAYIP ALGI

## Bölüm 16 — Sessiz Gökyüzü

### Ana ortam

Dağlık bölgede bulunan bir VEX gözlemevi. Tesisin büyük kısmı karanlıktır; çevredeki sis ve düşük ışık Dünya koşullarına ait değildir.

### Yeni düşman

**Veilmaw** tanıtılır. Orta menzil projectile ve atış sonrası reposition davranışıyla oyuncu sabit bir tehdidi değil sürekli değişen görüş hattını takip etmeyi öğrenir.

### Hikâye

Nhal bağlantısında ilk kez büyük enerji üretimi yerine düşük ışık, faz maddesi ve algısal perde ölçümleri görülür. VEX bu gerçekliği enerji santralinden çok özel araştırma kaynağı olarak kullanmıştır.

---

## Bölüm 17 — Perde Altında

### Ana ortam

Yeraltı haberleşme istasyonu, güç kesintileri ve birbirinden kopmuş karanlık servis odaları.

### Düşman gelişimi

Henüz yalnız Veilmaw ailesi kullanılır; zorluk yeni düşman eklemek yerine görüş hattı, karanlık alanlar ve açı değiştirme üzerinden büyür.

### Hikâye

Aras **Uzman Kerem Aksu**'nun sinyalini takip eder. Kerem, felaketten önce merkezi yönetimden gönderilen kritik bir emri saklamıştır:

> “Kararsızlık kabul edilebilir sınırda. Üretimi durdurmayın.”

Kerem Bastion'a katılır ve kayıp sinyalleriyle Yarık Ağı yoğunluk haritasını çıkarmaya başlar.

---

## Bölüm 18 — Kör Nokta

### Ana ortam

Nhal etkisinin bir metro bakım ağına yayıldığı kapalı ve yön duygusunu zorlayan alan.

### Yeni düşman

**Husk Leech** tanıtılır. Görüşü kapatan saldırı ilk kez doğrudan oyuncunun bilgi akışını hedef alır.

Veilmaw açı değiştirirken Husk Leech'in görüş engeli devreye girdiğinde oyuncu yalnız hasar değil, bilgi kaybıyla mücadele eder.

### Hikâye

Ece ve Kerem'in verileri Nhal türlerinin koordineli bir ordu kurmadığını gösterir. Geçitler Nhal'ın doğal av yolları ile Dünya'nın tünel, gece ve düşük ışık alanlarını birbirine bağlamaktadır.

İki dünyanın ekolojik sınırı fiziksel olarak karışmaktadır.

---

## Bölüm 19 — Av Yolları

### Ana ortam

Karanlık servis şehri, birbirine bağlanan metro, depo ve yarık koridorları.

### Aile sınavı

Veilmaw ve Husk Leech birlikte daha yoğun kullanılır. Oyuncu hangi yönden atış geldiğini takip ederken görüş kaybı yaşadığında güvenli rota hafızasına güvenmek zorunda kalır.

### Hikâye

VEX'in Nhal tarafındaki düşük ışık/faz maddesi çekimi, karşı gerçeklikte yalnız fiziksel kayıp yaratmamıştır. Nhal canlılarının çevreyi algılama ve av rotalarını belirleme koşulları da değişmiştir.

Bu kez sömürülen şey bir “yakıt” değil, **bir dünyanın çevresel düzenidir**.

---

## Bölüm 20 — Sesi Olmayan Dünya

### Ana ortam

Nhal bağlantısının ana Dünya ankrajı. Tesis bölümleri ile karanlık perde katmanları iç içedir.

### Yay zirvesi

Nhal'ın iki aktif yaratığı tam kombinasyon hâlinde kullanılır. Zorluk sayısal çeşitlilikten değil, sınırlı görüş ve bilgi kaybının daha karmaşık encounter alanlarıyla birleşmesinden gelir.

### Büyük keşif

Kerem ve Selin aynı anda farklı düğümlerin birbirini yeniden açtığını tespit eder. Aras bir ankrajı kapattığında enerji başka bir hatta kaymaktadır.

Yarık Ağı artık pasif kablolardan oluşan bir sistem değildir.

**Kendi bağlantılarını dengeleyen bir ağ hâline gelmiştir.**

Ağı tek tek düğüm kapatarak bitirmek mümkün değildir.

---

# PERDE V — AETHER LOOM: KIRIK ÖRÜNTÜ

## Bölüm 21 — Cam Deniz

### Ana ortam

Kıyı araştırma merkezi ve arkasında açılan kristal/faz bozulması. Su, yansıma ve geometri normal davranmaz.

### Yeni düşman

**Voidweaver** tanıtılır. Havada süzülen gövde ve üç kollu enerji örgüsü, oyuncuya geniş açı baskısını okumayı öğretir.

### Hikâye

Aether Loom'dan çekilen şey yalnız enerji değildir. VEX kayıtlarında “faz kararlılığı”, “uzamsal referans” ve “gerçeklik örgüsü” gibi terimler bulunur.

Aras ilk kez Yarık Ağı'nın portalları açmakla kalmayıp uzayın davranışını da değiştirdiğini görür.

---

## Bölüm 22 — Örüntü Hatası

### Ana ortam

Geometrisi bozulmuş araştırma kulesi ve birbirine yanlış açılarla bağlanan servis bölümleri.

### Düşman gelişimi

Henüz yalnız Voidweaver kullanılır; encounter zorluğu geniş enerji fanı, görüş hattı ve yeniden pozisyon alma üzerinden artar.

### Hikâye

Aras, tesiste mahsur kalan **Dr. Nadir Volkan**'a ulaşır. Nadir, Aether formlarının davranışını klasik canlı hareketi olarak yorumlamanın yanlış olabileceğini söyler.

Onlara göre Dünya'daki yarıklar “kapı” değil, bozulmuş bir desenin düğümleridir.

Voidweaver'lar bu düğümleri kendi fizik mantığına göre tekrar bağlamaya çalışıyor olabilir.

Sorun şudur: bu onarım işlemi Dünya maddesini korunması gereken canlı bir çevre olarak görmez.

---

## Bölüm 23 — Faz Yarığı

### Ana ortam

Kırılmış köprüler, kısa mesafeli faz çizgileri ve parçalanmış araştırma platformları.

### Yeni düşman

**Rift Reaver** tanıtılır. Güvenli phase step ve yakın lunge ile oyuncunun “uzaktaki hedef orada kalır” varsayımını bozar.

### Hikâye

Nadir, phase hareketinin sınırsız ışınlanma olmadığını; sağlam kalan komşu yarık çizgileri arasında yeniden bağlanma olduğunu açıklar. Bu bilgi Aether'ın görünürde kaotik davranışının kendi içinde kuralları olduğunu gösterir.

Aynı bölümde ilk kez VEX'in farklı evrenlerden çektiği faz referanslarını tek bir merkezde senkronize ettiği öğrenilir.

Merkezin eski proje adı: **NEXUS**.

---

## Bölüm 24 — Kırık Geometri

### Ana ortam

Bir VEX faz dengeleme tesisi. Koridorlar normaldir fakat bazı odalar Aether uzayıyla üst üste biner ve yön algısı sürekli sınanır.

### Aile sınavı

Voidweaver'ın ranged açı baskısı ile Rift Reaver'ın yakın phase tehdidi birlikte kullanılır.

### Hikâye

Nadir ve Selin, daha önce kapatılan Korvath, Thornwild, Vaskari ve Nhal düğümlerinin tamamen yok olmadığını fark eder. Enerji çekimi azalmıştır fakat ağ onların koordinatlarını Nexus üzerinden hâlâ tutmaktadır.

Bu nedenle dünya parçaları birbirine yeniden bağlanabilmektedir.

Nexus bir sonuç değil, **Yarık Ağı'nın kendisini ayakta tutan ortak referans merkezidir.**

---

## Bölüm 25 — Dokuma Merkezi

### Ana ortam

Dünya'daki en büyük Aether ankrajı ve Nexus'a en yakın çalışan faz laboratuvarı.

### Yay zirvesi

Voidweaver ve Rift Reaver'ın en yoğun kombinasyonları kullanılır. Yeni aktif düşman eklenmez; oyuncunun iki rolü yüksek baskı altında doğru okuması beklenir.

### Büyük keşif

Nadir, Yarık Ağı'nı kalıcı olarak susturmak için **Ters Akış Protokolü**nün temelini çıkarır. Ama protokol enerjiyi geri patlatmak veya bütün portalları aynı anda kapatmak değildir.

Yapılması gereken:

1. Dünya üzerindeki ana senkronizasyon istasyonlarını susturmak.
2. VEX merkezindeki Sıfır Kaynak ana referansını kesmek.
3. Nexus'a geçip beş gerçekliğin zorla paylaştığı ortak faz bağını çözmek.

### Perde sonu

Tam bu sırada Yarık Ağı büyük bir dengeleme tepkisi verir. Daha önce ayrı kalan bağlantılar Dünya üzerinde aynı bölgelere taşmaya başlar.

İlk kez farklı gerçekliklerin etkileri aynı operasyon alanlarında görülmeye başlayacaktır.

---

# PERDE VI — YAKINSAMA VE YARIK SAVAŞI

## Bölüm 26 — Kesişim Hattı

### Ana ortam

Bir metropolün sanayi dış kuşağı. Yarık Ağı'nın dengeleme tepkisi nedeniyle farklı gerçeklik bağlantıları aynı geniş bölgede ortaya çıkmıştır.

### Karışım kuralı

Bu, kampanyadaki ilk gerçek karma evren bölümüdür. Ancak düşmanlar tek bir birleşik ordu gibi spawn edilmez. Bölgenin farklı sektörlerinde farklı aileler kendi nedenleriyle bulunur.

Örneğin:

- Korvath enerji altyapısına yönelir.
- Thornwild terk edilmiş yeşil alanlarda yuvalanır.
- Vaskari VEX sinyal vericilerini hedefler.
- Nhal karanlık alt geçitlere yayılır.
- Aether aktif yarık düğümlerini yeniden örmeye çalışır.

Bazı sınır alanlarında bu ailelerin rotaları çakışabilir; bu ortak ittifak anlamına gelmez.

### Hikâye

Aras sivillerin tahliye hattını açarken felaketin artık gizli tesislerle sınırlı olmadığını görür. Dünya kamuoyu VEX'in varlığını öğrenmeye başlar.

Bastion ekibi Ters Akış için gereken ilk ana senkronizasyon verisini toplar.

---

## Bölüm 27 — Bastion Kuşatması

### Ana ortam

Oyuncunun oyun boyunca geliştirdiği Bastion-7.

### Hikâye nedeni

Bastion'ın Ters Akış hesaplamaları güçlü bir faz izi üretir. Aynı anda VEX yönetimi Bastion'ın ana ağı susturabilecek bilgiye sahip olduğunu fark eder.

Kuşatma tek bir ordunun planlı ortak saldırısı değildir. Üs çevresindeki yarık aktivitesi farklı aileleri farklı sektörlere çekerken Vardar Bastion'ın veri bağlantısını uzaktan kesmeye ve sistemi ele geçirmeye çalışır.

### Oynanış amacı

Oyuncu 26 bölüm boyunca tanıdığı mekânda savaşır. Farklı sektörler farklı aile kimliği taşır; örneğin karanlık servis katı Nhal, enerji katı Korvath/Aether, dış savunma hattı Vaskari baskısı taşıyabilir.

Kurtarılan uzmanların hikâyesi burada karşılığını verir; Bastion artık boş sığınak değil kurulmuş bir ekip merkezidir.

### Bölüm sonu

Bastion ayakta kalır fakat Vardar'ın konumu belirlenir: Sıfır Kaynak projesinin ilk ana merkezi hâlâ çalışmaktadır.

---

## Bölüm 28 — Sıfır Kaynak

### Ana ortam

VEX'in ana araştırma merkezi. Felaketin başladığı sistemin yönetim çekirdeği burada bulunmaktadır.

### Düşman kullanımı

Tesisin farklı kanatları farklı gerçekliklerle kirlenmiştir. Karışık encounter kullanılabilir; ancak mümkün olduğunda aile kimliği oda/kanat bazında korunur. Böylece final zorluğu okunabilir kalır.

### Hikâye

Aras ana yönetim arşivini açar ve felaketin bütün suç zincirini kanıtlar:

1. Enerjinin başka gerçekliklerden geldiği öğrenildi.
2. Bu gerçekliklerde canlı yaşam bulunduğu tespit edildi.
3. Kaynak çekiminin fiziksel ve ekolojik zarar verdiği ölçüldü.
4. Olası organize karşı tepki için güvenlik senaryoları hazırlandı.
5. Buna rağmen üretim büyütüldü.
6. Felaket sonrasında bile sistemi yeniden çalıştırmak için çekirdekler korundu.

Vardar'ın amacı yalnız gücü ele geçirmek değildir. Ona göre Sıfır Kaynak kapatılırsa Dünya yeniden enerji kıtlığına dönecek, devletler çökecek ve milyarlarca insanın hayatı dolaylı olarak riske girecektir.

Aras'a sunduğu argüman basittir:

> “Bir komutan kendi dünyasını kurtarmak için kimi feda edeceğine karar verir.”

Aras bunun bir kurtuluş değil, bedelin görünmez bir yere aktarılması olduğunu söyler.

### Bölüm sonu

Vardar Nexus'a geçer ve ana referansı oradan sabitlemeye çalışır. Bastion ekibi geçidin koordinatını açar.

---

## Bölüm 29 — Nexus Eşiği

### Ana ortam

Nexus'un dış halkası. Doğal bir dünya değildir; VEX'in yıllarca zorla birbirine bağladığı gerçeklik parçalarından oluşan yapay ara bölgedir.

### Yapı

Bu bölüm beş büyük sektörden oluşur ve önceki 25 bölümün hatırlatma sınavıdır:

1. **Korvath Ankrajı** — ısı, ağır projectile ve Crucible Warden baskısı.
2. **Thornwild Ankrajı** — hareket alanı, charge ve Spore Matriarch zehir kontrolü.
3. **Vaskari Ankrajı** — rol kombinasyonu, Bulwark önü ve Venom Marshall önceliği.
4. **Nhal Ankrajı** — görüş ve bilgi baskısı.
5. **Aether Ankrajı** — Voidweaver açı kontrolü ve Rift Reaver phase tehdidi.

Bu sektörler ailelerin Vardar için savaştığı anlamına gelmez. Nexus onların gerçekliklerinden koparılmış parçaları ortak merkezde tutmaktadır.

### Hikâye

Aras beş ankrajı birer birer senkronizasyondan çıkarır. Her bağlantı çözüldüğünde ilgili gerçekliğe aktif enerji çekimi azalır.

Son kapı açıldığında yalnız ana çekirdek kalır.

---

## Bölüm 30 — Sessiz Merkez

### Ana ortam

Nexus'un çekirdeği. Beş gerçekliğin faz referansları burada tek bir yapay geometri içinde tutulmaktadır.

### Final çatışmasının yapısı

Finalin amacı oyuna yeni, açıklanmamış bir yaratık veya uygulanmamış bir boss sistemi eklemek değildir. Oyuncunun öğrendiği sistemler, çekirdeği kapatma operasyonunun parçaları hâline gelir.

Aras ve Bastion ekibi Ters Akış Protokolünü başlatır. Protokol üç aşamada çalışır:

1. **Senkronizasyonu kes:** Beş ana gerçeklik ortak referanstan ayrılır.
2. **Emişi durdur:** Dünya tarafındaki Sıfır Kaynak düğümleri güç çekemez hâle gelir.
3. **Nexus'u sessizleştir:** Yeni kalıcı geçitleri besleyen yapay merkez çöker.

Vardar son ana kadar sistemi kapatmaya karşı çıkar. Onun hikâyedeki rolü Aras'ın kararını zorlaştırmaktır; uygulanmış ayrı bir insan boss sistemi olmadığı sürece finalin başarısı Vardar'ın can barını sıfırlamak değildir.

Vardar ağı yeniden sabitlemeye çalışırken ana platformlar ayrılır. Aras Ters Akış'ı tamamlar.

### Sonuç

Dünya'daki büyük enerji sütunları sönmeye başlar.

Yeni büyük geçit oluşumu durur.

Yıllardır Dünya'da kalmış yaratıklar bir anda yok olmaz. Bazı biyomlar kalıcı olarak değişmiştir. Küçük, beslenmeyen yarıklar ve izole koloniler hâlâ vardır.

Daha ağır bedel ise insana aittir: Dünya Sıfır Kaynak'ın sağladığı dev enerji kapasitesini kaybeder.

Aras bunu bilerek sistemi kapatmıştır.

Çünkü başka dünyaların sürekli çöküşü üzerine kurulu enerji bolluğunun sürdürülebilir bir kurtuluş olmadığına karar vermiştir.

---

# Final — Son Kapı

VEX'in ana yönetim kayıtları Bastion-7 üzerinden dış dünyaya aktarılır.

Dünya artık üç gerçekle aynı anda yaşamak zorundadır:

1. VEX başka gerçeklikleri bilinçli şekilde sömürmüştür.
2. Sıfır Kaynak gerçekten insanlığın enerji krizini hafifletmiştir.
3. Sistemi kapatmak doğru olsa bile bunun Dünya için ağır ekonomik ve insani sonuçları olacaktır.

Bastion-7 gizli sığınak olmaktan çıkar. Kalan yarıkları izleyen, xeno bölgelerini araştıran, kayıp alanları geri alan ve başka gerçekliklerle yeni temaslarda aynı hatanın tekrarlanmasını engellemeye çalışan operasyon merkezi hâline gelir.

Leyla dünya haritasını açar. Beş büyük enerji sütunu artık yoktur. Fakat yüzlerce küçük sinyal hâlâ yanmaktadır.

> **“Ana ağı susturduk. Şimdi geride bıraktığımızı temizlememiz gerekiyor.”**

Aras silahını bırakmaz.

Ama artık karşısındaki her yaratığa “istilacı” demenin doğru olmadığını bilir.

Ana hikâye burada tamamlanır. Oyun sonu operasyonları, kalan yarık bölgeleri ve ileride gerçekten tasarlanıp aktif roster'a eklenen yeni yaratıklar için doğal alan bırakılır.

---

# 30 bölümlük hızlı kampanya özeti

| # | Bölüm | Ana gerçeklik / işlev | Yeni ana tehdit veya hikâye adımı |
|---:|---|---|---|
| 1 | İlk Kırılma | Korvath | Cinder Hound; felaket ve Bastion'a kaçış |
| 2 | Kül Koridoru | Korvath | Cinder Spitter; ilk kaynak imzası |
| 3 | Basınç Hattı | Korvath | Basalt Juggernaut; Selin kurtarılır |
| 4 | Erimiş Damar | Korvath | Furnace Carrier; Korvath zararının kanıtı |
| 5 | Sönen Çekirdek | Korvath | Crucible Warden; ilk ankraj kapanır |
| 6 | Yeşil Karantina | Thornwild | Ravager; biyolojik kaynak gerçeği |
| 7 | Diken İzleri | Thornwild | Briar Skulker; av zinciri |
| 8 | Boynuz Geçidi | Thornwild | Gorehorn; habitat göçü |
| 9 | Spor Bahçesi | Thornwild | Spore Matriarch; Ece kurtarılır |
| 10 | Köklerin Hafızası | Thornwild | Tam aile; kasıtlı ekosistem sömürüsü |
| 11 | Mor Cephe | Vaskari | Vaskari Raptor; organize karşılık |
| 12 | Kırıcı Hat | Vaskari | Vaskari Ravager; VEX düğümleri hedefte |
| 13 | Mızrak Menzili | Vaskari | Coil Lancer; Cem kurtarılır |
| 14 | Kalkan Duvarı | Vaskari | Vaskari Bulwark; Derya kurtarılır |
| 15 | Zehirli Emir | Vaskari | Venom Marshall; Vardar'ın emri |
| 16 | Sessiz Gökyüzü | Nhal Veil | Veilmaw; düşük ışık/faz kaynağı |
| 17 | Perde Altında | Nhal Veil | Veilmaw gelişimi; Kerem kurtarılır |
| 18 | Kör Nokta | Nhal Veil | Husk Leech; görüş bozma |
| 19 | Av Yolları | Nhal Veil | Tam aile; ekolojik taşma |
| 20 | Sesi Olmayan Dünya | Nhal Veil | Ağın kendi kendini dengelediği keşfedilir |
| 21 | Cam Deniz | Aether Loom | Voidweaver; gerçeklik örüntüsü |
| 22 | Örüntü Hatası | Aether Loom | Nadir kurtarılır |
| 23 | Faz Yarığı | Aether Loom | Rift Reaver; Nexus adı ortaya çıkar |
| 24 | Kırık Geometri | Aether Loom | Tam aile; Nexus'un işlevi anlaşılır |
| 25 | Dokuma Merkezi | Aether Loom | Ters Akış Protokolü hazırlanır |
| 26 | Kesişim Hattı | Yakınsama | İlk kontrollü karma evren operasyonu |
| 27 | Bastion Kuşatması | Yakınsama | Üssün savunması, Vardar'ın konumu |
| 28 | Sıfır Kaynak | VEX merkezi | Tam suç zinciri ve Vardar'ın gerekçesi |
| 29 | Nexus Eşiği | Nexus | Beş evrenin ayrı ankraj sınavları |
| 30 | Sessiz Merkez | Nexus | Ters Akış, Yarık Ağı'nın susturulması |

---

# 18 aktif yaratığın kademeli tanıtım matrisi

Bu tablo ilk güçlü kampanya tanıtımını gösterir. Üretilmiş eski sahnelerde teknik spawn kompozisyonu farklıysa gerçek sahne o an için gameplay kaynak-of-truth'udur; yeni level üretiminde bu kampanya planı hedef alınır.

| Yaratık | Evren | İlk ana tanıtım | Tam aile sınavı |
|---|---|---:|---:|
| Cinder Hound | Korvath | 1 | 5 |
| Cinder Spitter | Korvath | 2 | 5 |
| Basalt Juggernaut | Korvath | 3 | 5 |
| Furnace Carrier | Korvath | 4 | 5 |
| Crucible Warden | Korvath | 5 | 5 |
| Ravager | Thornwild | 6 | 10 |
| Briar Skulker | Thornwild | 7 | 10 |
| Gorehorn | Thornwild | 8 | 10 |
| Spore Matriarch | Thornwild | 9 | 10 |
| Vaskari Raptor | Vaskari | 11 | 15 |
| Vaskari Ravager | Vaskari | 12 | 15 |
| Coil Lancer | Vaskari | 13 | 15 |
| Vaskari Bulwark | Vaskari | 14 | 15 |
| Venom Marshall | Vaskari | 15 | 15 |
| Veilmaw | Nhal Veil | 16 | 19-20 |
| Husk Leech | Nhal Veil | 18 | 19-20 |
| Voidweaver | Aether Loom | 21 | 24-25 |
| Rift Reaver | Aether Loom | 23 | 24-25 |

Planlanan **Murk Stalker, Shade Anchor, Rift Spindle, Parallax Drone ve Loom Herald** bu 30 bölümlük ana kampanyanın zorunlu parçası değildir. Gerçek gameplay rolleri ve üretim setleri tamamlanırsa ilgili evren bloklarına sonradan eklenebilirler; mevcut 18 yaratığın rolünü bozmak için kullanılmamalıdır.

---

# Zorluk eğrisi

## Bölüm 1-5 — Temel savaş okuryazarlığı

Oyuncu hızlı takip, ranged baskı, ağır projectile, iki modlu ağır düşman ve elit alan kontrolünü tek aile içinde öğrenir.

## Bölüm 6-10 — Hareket yönetimi

Precision projectile, hibrit mesafe, charge ve zehir alanı oyuncuyu sürekli pozisyon değiştirmeye zorlar.

## Bölüm 11-15 — Hedef önceliği

Vaskari birimleri tek tek değil rol kombinasyonuyla güçlenir. Oyuncu sniper, tank, rush ve destek ilişkisini okumayı öğrenir.

## Bölüm 16-20 — Bilgi baskısı

Nhal bölümleri düşman sayısını körlemesine artırmak yerine görüş, açı ve bilgi kaybını zorlaştırır.

## Bölüm 21-25 — Uzamsal baskı

Aether bölümleri geniş enerji hatları ve güvenli phase hareketleriyle oyuncunun tehdit açısını sürekli yeniden hesaplamasını ister.

## Bölüm 26-30 — Ustalık

Yeni temel kural öğretmek yerine daha önce öğrenilen kurallar farklı sektörlerde ve kontrollü kombinasyonlarda sınanır. Final zorluğu yalnız düşman canını ve hasarını büyütmeye dayanmaz.

---

# Evrenlerin hikâyedeki işlevi

## Korvath Ocağı — “Kaynağın bir sahibi var.”

Aras'a ilk kez başka tarafın zarar gördüğünü gösterir.

## Thornwild Sürüsü — “Bir ekosistem de sömürülebilir.”

VEX'in canlı dünyaları ölçüp verimli kaynak alanlarına dönüştürdüğünü ortaya çıkarır.

## Vaskari Lejyonu — “Karşı taraf da bizi saldırgan olarak görüyor.”

İlk organize karşı savaş perspektifini getirir ve VEX yönetiminin olası dirençten haberdar olduğunu kanıtlar.

## Nhal Veil — “Felaket artık kontrol edilen bir savaş değil.”

İki gerçekliğin çevresel sınırlarının birbirine karışmasını ve ağın kendi kendini dengelemeye başlamasını gösterir.

## Aether Loom — “Sorun portallar değil, onları birbirine bağlayan yapı.”

Nexus'un varlığını ve Yarık Ağı'nın gerçek çözümünün merkez senkronizasyonu kesmek olduğunu açıklar.

## Nexus — “Dünya ne pahasına kurtarılacak?”

Bütün teknik ve ahlaki soruları tek final kararında toplar.

---

# Anlatım standardı

VEX; askerî bilimkurgu, tesis korkusu, kozmik bilinmezlik ve üs geliştirme hissini birlikte taşır.

- İlk bölümlerde bilgi azdır; oyuncu gördüğü şeyleri yanlış yorumlayabilir.
- Her beş bölümlük evren yayı bir ana soruya cevap verir ve daha büyük bir soru açar.
- Yaratıkların tamamı “kötü istilacılar” olarak yazılmaz.
- Vaskari organize bir düşman güçtür; bu, diğer evrenlerin de ordu olduğu anlamına gelmez.
- Farklı aileler ancak Bölüm 26'dan itibaren ana kampanya encounter'larında bilinçli şekilde karıştırılır.
- Karma encounter, evrenlerin ittifak kurduğu anlamına gelmez.
- Hikâye, oyunda olmayan invisibility, sınırsız teleport, ally buff veya başka özel sistemi uygulanmış gerçek gibi anlatmaz.
- Yeni yaratık yalnız bölüm sayısını doldurmak için aktif roster'a eklenmez.
- Haluk Vardar karikatür kötü olmamalıdır. Yanlış olan gerekçesizce yıkım istemesi değil; Dünya'nın ihtiyacını başka gerçekliklerin yaşam hakkından sistematik olarak üstün tutmasıdır.
- Aras'ın zaferi yalnız düşman öldürmek değil, felaketi üreten mekanizmayı anlamak ve onu susturmaktır.

Oyunun genel duygusal ilerleyişi:

**Hayatta kal → İlk dünyayı tanı → Sömürünün boyutunu gör → Karşı savaşla yüzleş → Gerçekliklerin karıştığını anla → Nexus'u keşfet → Bastion'ı savun → VEX gerçeğini açığa çıkar → Yarık Ağı'nı sustur.**