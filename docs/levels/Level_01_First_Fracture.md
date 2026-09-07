# VEX — Bölüm 1: İlk Kırılma

Bu belge Bölüm 1'in güncel **kanonik üretim planı ve uygulanmış gameplay dengesi**dir.

## 1. Bölüm hedefi

- Oyuncuya dönük ad: **İlk Kırılma**
- İlk oynayış hedefi: **18–20 dakika**
- Evren odağı: **Korvath Ocağı**
- Aktif düşman türü: yalnız **Cinder Hound**
- İlk kalıcı silah: **P-01 Taktik Tabanca**
- Kayıt sayısı: **3**
- Secret: **R29 bakım/arşiv cebi**
- Çıkış: **Bastion-7**
- Bölüm içinde checkpoint yoktur.

SG-04, P-07, P-14, P-20, Gece Görüşü, Ravager ve Veilmaw bu bölümün kanonik içeriği değildir.

## 2. Hikâye amacı

Aras tesisin içinde silahsız uyanır. İlk varsayım, VEX'in tuttuğu deney canlılarının kontrolden çıktığıdır. Bölüm boyunca bu yorum üç kayıtla parçalanır:

1. **Acil Test Emri / 04:17** — çekim kapasitesinin güvenlik itirazlarına rağmen artırıldığını gösterir.
2. **Güvenlik Kamerası 07** — Cinder Hound'un bir kafesten kaçmadığını, doğrudan yarıktan geçtiğini kanıtlar.
3. **Enerji Üretmiyoruz** — VEX'in enerji üretmediğini, başka bir gerçeklikten çektiğini açığa çıkarır.

Bölüm finalinde R37'de görülen mavi-beyaz Yarık Ağı izi henüz Korvath kimliğini açıklamaz. Oyuncu yalnız felaketin yerel bir reaktör arızası olmadığını öğrenir ve Bastion-7 koordinatına yönlendirilir.

## 3. Sahne mimarisi

Aktif `level_01.tscn` küçük ve temiz bir mission shell'dir. Runtime'da üç ayrı authored katman kurulmaktadır:

- `level_01_structure_source.tscn` → yalnız 37 odalık fiziksel omurga, kapılar, authored oda ışıkları ve temel props.
- `level_01_environment_story.tscn` → oda kodları, hasar izleri, acil ışık vurguları ve final Yarık Ağı vistası.
- `level_01_first_fracture_content.tscn` → düşmanlar, pickup'lar, kayıt terminalleri, secret ve finish switch.

`level_01.gd`, structure source içinden yalnız `WorldEnvironment`, `Geometry`, `Doors`, `RoomLights`, `Lights` ve `Props` root'larını alır. Legacy `Enemies/Pickups/Triggers` aktif SceneTree'ye girmez.

## 4. Sektörler ve süre

| Sektör | Odalar | Rol | Hedef süre |
|---|---|---|---:|
| A — Güvenlik | R01–R13 | Uyanış, P-01, ilk temas | 0:00–4:30 |
| B — Karantina | R14–R25 | Mavi kart, kayıt, kontrollü baskı | 4:30–10:30 |
| C — Reaktör | R26–R33 | Secret, teknik gerçek, kırmızı kart | 10:30–15:30 |
| D — Tahliye | R34–R37 | Final encounter ve Bastion çıkışı | 15:30–20:00 |

Ana rota:

`R01 → R03 → R07 → R11 → R13 → R15 → R19 → R23 → R25 → R27 → R31 → R35 → R37`

Zorunlu erişim yan rotaları:

- **R17** → mavi erişim kartı + Kayıt 2
- **R33** → kırmızı erişim kartı

Opsiyonel ana secret:

- **R29** → Kayıt 3 + mühimmat/zırh ödülü

## 5. P-01 ve ilk combat ritmi

P-01 artık R03'te ana geçiş çizgisine yakın konumdadır. Oyuncu kampanya aşaması 0'da bölüme silahsız girer; global Player varsayılanı değiştirilmez.

P-01 ilk alımda:

- 12 mermilik authored şarjör,
- 24 başlangıç reserve mermi

sağlar.

Live silah verisine göre P-01 gövde hasarı 18, Cinder Hound Normal canı 85'tir. Bu nedenle yaklaşık 5 isabet/Hound temel bütçe kabul edilir. Bölüm ikmali bu değer üzerinden ayarlanmıştır; kritik mühimmat secret'a bağlı değildir.

## 6. Encounter dağılımı

Zorluk başına fiziksel Hound sayısı:

- **Easy: 9**
- **Normal: 12**
- **Hard/Nightmare: 13**

Normal akış:

| Oda | Encounter |
|---|---|
| R07 | 1 Hound — ilk temas |
| R11 | 1 Hound — mesafe/reload tekrarı |
| R13 | 2 Hound — ilk ikili baskı |
| R15 | 1 Hound |
| R18 | 1 Hound — yalnız Normal+ |
| R25 | 1 Hound |
| R27 | 1 Hound |
| R31 | 1 Hound |
| R33 | yalnız Hard+ ek Hound |
| R35 | Easy 2 / Normal+ 3 Hound final |

### R17 kararı

R17 artık combat odası değildir. Oyuncunun mavi kartı alıp **Güvenlik Kamerası 07** kaydını okuyabildiği kısa bir bilgi/nefes alanıdır. Normal+ ek baskı R18'de tutulur.

### R35 final kademesi

R35'te Hound'lar aynı anda oyuncunun üstüne açılmaz. Scene-authored algılama/hearing değerleri kademelidir:

- A: detection 13.0
- B: detection 5.5
- C: detection 3.4, Normal+

Ally alert yarıçapları da küçültülmüştür. Amaç ilk Hound'un önden çıkması, ikinci tehdidin oyuncu odaya girdikçe devreye girmesi ve üçüncü Normal+ tehdidin daha derinde aktive olmasıdır. Can/hasar/hız değerleri override edilmez; species sahnesi kaynak-of-truth olarak kalır.

## 7. Kaynak ekonomisi

### Ana rota / zorunlu kaynak pencereleri

- R03 — P-01 + 24 reserve
- R13 — 12 mermi + 10 hafif zırh
- R19 — 10 mermi
- R23 — 24 mermi + 25 sağlık + 16 zırh
- R33 — 12 mermi
- R35 — 24 mermi + 25 sağlık + 15 zırh

### Keşif ödülleri

- R06 — 10 mermi
- R10 — 15 sağlık
- R20 — 10 zırh
- R28 — 10 mermi
- R29 secret — 18 mermi + 12 zırh

Pickup'ların mevcut difficulty amount multiplier sistemi korunur. P-01 ilk bonus mühimmatı bilerek difficulty scaling dışında tutulur.

## 8. Kayıtlar

### R03 — OLAY / Acil Test Emri / 04:17

Ana rotada, kaçırılması zor. VEX'in test kapasitesini bilerek yükselttiğini gösterir.

### R17 — PERSONEL / Güvenlik Kamerası 07

Mavi kart odasında. İlk Hound'un laboratuvar kafesinden değil doğrudan yarıktan geldiğini doğrular.

### R29 — TEKNİK / Enerji Üretmiyoruz

Secret kayıt. Ana cümle:

> **Enerji üretmiyoruz. Bir yerden çekiyoruz.**

Bu kayıt ana hikâyeyi anlamak için zorunlu değildir fakat VEX gerçeğini erken kavrayan oyuncuyu ödüllendirir.

## 9. Erişim akışı

- Mavi kart: **R17**
- Mavi kart kapısı: **R25 → R27**
- Kırmızı kart: **R33**
- Final hava kilidi: **R35 → R37**, mavi + kırmızı kart ister.
- Finish switch: düşman `enemy_id` gate'i yoktur; kart akışı tamamlandıktan sonra Bastion-7'ye döner.

## 10. Çevresel hikâye

Önemli authored işaretler:

- R03 — güvenlik kod ekranı / daha temiz soğuk ışık
- R07/R13 — düşmüş metal paneller
- R17 — acil kırmızı ışık + duvar hasarı
- R23 — kısa güvenli medikal/ikmal tonu
- R29 — soğuk kaçak ışığı + secret hasar izi
- R35 — tahliye alarmı
- R37 — mavi-beyaz titreşen Yarık Ağı izi

Bu çevresel story prop'ları collision'sızdır; navigation veya kapı açıklıklarını değiştirmez.

## 11. Tutorial

Kısa contextual tutorial korunur:

1. hareket/bakış
2. etkileşim/P-01
3. aim/fire
4. reload
5. tamamlandı

Enemy species ID tutorial için değiştirilmez. Bütün Cinder Hound örnekleri kanonik `cinderhound` kimliğini kullanır.

## 12. Discovery/UI hedefi

Bölüm 1'de oyuncuya bilgi kartı verilmesi gereken ana anlar:

- ilk P-01 edinimi → `SİLAH ARŞİVİ GÜNCELLENDİ`
- ilk Cinder Hound discovery → `YENİ XENO KAYDI`
- üç kayıt → `KAYIT ÇÖZÜLDÜ`

Mevcut pickup notification altyapısı silah pickup'ını zaten bildirir. Ayrı, kuyruklu ve daha büyük discovery-card katmanı sonraki UI uygulama pass'inde bağlanacaktır; bu belge onu tamamlanmış runtime özellik olarak işaretlemez.

## 13. Kabul kriterleri

- [x] Aktif level shell legacy Ravager/Veilmaw/pickup bloklarından temiz.
- [x] 37 odalık geometri ve kapı omurgası korunuyor.
- [x] Yalnız Cinder Hound kullanılıyor.
- [x] Easy/Normal/Hard+ sayıları 9/12/13.
- [x] P-01 ilk kalıcı silah ve R03 ana rota üzerinde.
- [x] R17 mavi kart + kayıt bilgi odası.
- [x] R33 kırmızı kart.
- [x] R29 secret ve üçüncü kayıt mevcut.
- [x] R23/R35 zorunlu ikmal pencereleri mevcut.
- [x] R37 Bastion-7'ye dönüyor.
- [x] Çevresel hikâye katmanı collision'sız.
- [ ] Discovery-card UI kuyruk sistemi tamamlanacak.
- [ ] Godot runtime parse/playthrough testi yapılacak.
- [ ] Gerçek playtest ile 18–20 dakika hedefi ölçülecek.
