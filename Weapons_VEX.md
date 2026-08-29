# VEX Silah Tasarım ve Geliştirme Ana Belgesi

> Bu dosya VEX evrenindeki oyuncu silahları için tek ana referanstır. Model adları, kod kimlikleri, sınıflar, temel istatistikler, özel yetenekler, geliştirme sırası ve görsel üretim standardı burada tanımlanır. Yeni bir silah veya geliştirme kararı alındığında önce bu dosya güncellenmelidir.

**Belge sürümü:** 1.1 — canonical ID / 5-slot / data-driven presentation
**Planlanan toplam:** 20 silah
**Sınıf sayısı:** 5
**Her sınıftaki model sayısı:** 4
**Geliştirme sistemi:** Silah başına 3 kalıcı kademe

---

## 1. Ana tasarım kuralları

### 1.1 Taşıma ve cephanelik

- Oyuncu aynı anda her silah sınıfından en fazla **bir** silah taşıyabilir.
- Taşınmayan fakat daha önce edinilmiş silahlar Bastion-7 cephaneliğindeki kendi 2×2 raflarına bırakılır.
- Rafa bırakılan silahın mühimmatı, takılı geliştirmeleri ve keşif durumu korunur.
- Bastion-7 cephaneliğinde yeni bir model kuşanıldığında aynı sınıftaki taşınan silah otomatik olarak rafa döner.
- Görev içindeki fiziksel bir tabanca pickup'ı alındığında taşınan tabanca pickup noktasının yanına düşer ve yeniden alınabilir; tabanca yuvasında aynı anda yalnız bir model kalır.
- Oyuncu hiçbir silah taşımadan operasyona çıkamaz.
- Silahların kaybedilmesi ölüm cezası değildir. Oyuncu ölünce bölüm baştan başlar ve bölüm başlangıcındaki teçhizat durumu geri yüklenir.

### 1.2 Hedef teçhizat yuvaları

| Tuş / yuva | Sınıf | Grup kimliği | Rol |
|---:|---|---|---|
| 1 | Tabanca | `sidearm` | Güvenilir yedek silah, hassas tekli atış |
| 2 | Pompalı / savaş tüfeği | `shotgun` | Yakın mesafe, yüksek durdurma gücü |
| 3 | Taarruz / nişancı tüfeği | `rifle` | Orta ve uzun mesafe ana silah |
| 4 | Hafif otomatik | `smg` | Hareketli yakın-orta mesafe çatışması |
| 5 | Lazer / enerji | `laser` | İleri teknoloji ve özel boyut etkileri |

> 5. yuva altyapısı artık aktiftir: InputMap, WeaponController ve HUD localization hazırdır. Oynanabilir lazer silahı henüz eklenmediği için yuva içerik gelene kadar boş kalır.

### 1.3 Silah kademeleri

| Kademe | Anlamı | Modeller |
|---|---|---|
| I — Standart | Güvenlik ve saha operasyonu üretimi | P-01, SG-04, VX-47, MP-90, LX-01 |
| II — Geliştirilmiş | Bastion araştırmasıyla açılan taktik modeller | P-07, SG-09, VX-58, MP-96, LX-07 |
| III — Uzman | Kurtarılan VEX prototipleri ve boyutsal malzemeler | P-14, SG-15, VX-72, MP-110, LX-13 |
| IV — Deneysel | Yarık Ağı teknolojisiyle üretilen son seviye modeller | P-20, SG-21, VX-90, MP-120, LX-20 |

### 1.4 Geliştirme sistemi

- Her silahın diğer modellerden bağımsız **üç geliştirmesi** vardır.
- Geliştirmeler sıra ile açılır: Kademe 1 → Kademe 2 → Kademe 3.
- Geliştirmeler kalıcıdır; silah rafa bırakılsa da kaybolmaz.
- Son geliştirme silahın kimliğini güçlendirmeli, başka bir silahın rolüne dönüştürmemelidir.
- Hasar, atış aralığı, yayılım ve şarjör değerleri Inspector üzerinden düzenlenebilir olmalıdır.
- Fener, optik, alternatif atış, ısı ve delme gibi sistemler `WeaponDefinition` içindeki özellik bayraklarıyla veri odaklı yönetilmelidir.

### 1.5 Uygulanmış runtime mimarisi

- Canonical resource dosyaları `p01.tres`, `sg04.tres`, `vx47.tres`, `mp90.tres` olarak kullanılır.
- HUD presentation bilgisi `WeaponDefinition.hud_view_scene` üzerinden gelir.
- P-01, P-07, P-14, SG-04, VX-47 ve MP-90 kendi `scenes/ui/weapons/*_view.tscn` presentation sahnelerini kullanır.
- Yeni bir silah için HUD içine silah kimliğine özel sprite kurulum bloğu eklenmez.
- `supports_ads_pose`, `supports_lowered_pose`, `supports_flashlight`, `supports_alt_fire`, `uses_heat`, `uses_charge` ve `penetration_power` gelecek model davranışları için capability alanlarıdır.
- Silah sesleri bu mimari geçişte değiştirilmemiştir; VX-47/MP-90 özgün ses seti ayrı audio pass olarak yapılacaktır.

---

## 2. Kimlik ve kayıt uyumluluğu

Yeni içerikte her silah kendi model kimliğini kullanacaktır. Mevcut kayıtların bozulmaması için eski kimlikler göç tablosunda korunmalıdır.

| Görünen model | Hedef `weapon_id` | Mevcut/eski kimlik | Durum |
|---|---|---|---|
| P-01 | `p01` | `pistol` | Oynanabilir; canonical ID aktif, legacy migration hazır |
| P-07 | `p07` | Yok | Oynanabilir; Level 1 gizli bakım deposundan açılır |
| SG-04 | `sg04` | `shotgun` | Oynanabilir; canonical ID aktif, legacy migration hazır |
| VX-47 | `vx47` | `ak47` | Oynanabilir; canonical ID aktif, legacy migration hazır |
| MP-90 | `mp90` | `mp90` | Oynanabilir; kimlik uyumlu |
| Diğer modeller | Küçük harf model kodu | Yok | Planlandı |

**Kayıt göçü kuralı:**

```text
pistol  -> p01
shotgun -> sg04
ak47    -> vx47
mp90    -> mp90
```

Bir kayıt dosyasında hem eski hem yeni kimlik bulunursa yeni kimlik esas alınmalı, mühimmat ve geliştirme seviyesi en yüksek geçerli değer üzerinden birleştirilmelidir.

---

## 3. Hızlı silah kataloğu

| Model | Tam ad | Sınıf | Ana rol | Ayırt edici özellik | Durum |
|---|---|---|---|---|---|
| P-01 | P-01 Taktik Tabanca | Tabanca | Dengeli başlangıç silahı | Güvenilir mekanik nişangâh | Oynanabilir |
| P-07 | P-07 Sentinel | Tabanca | Karanlık alan / hızlı takip | Entegre taktik fener | Oynanabilir |
| P-14 | P-14 Specter | Tabanca | Gizli operasyon / hassasiyet | Fener, susturucu, gelişmiş optik | Oynanabilir; Level 1 başlangıcında test pickup'ı |
| P-20 | P-20 Magnum | Tabanca | Zırhlı hedef / tek atış gücü | Standart tabanca mühimmatı ve delme | Oynanabilir |
| SG-04 | SG-04 Kırıcı | Pompalı | Yakın mesafe durdurma | Manuel pompa ve yüksek saçma | Oynanabilir |
| SG-09 | SG-09 Aegis | Pompalı | Savunma / seri takip | Yarı otomatik mekanizma | Oynanabilir |
| SG-15 | SG-15 Tempest | Pompalı | Kalabalık kontrolü | Tam otomatik tambur ve ısı yönetimi | Oynanabilir |
| SG-21 | SG-21 Graviton | Pompalı | Ağır yaratık / alan kontrolü | Adaptif şok ve gravitasyon fişeği | Planlandı |
| VX-47 | VX-47 Taarruz Tüfeği | Tüfek | Dengeli orta mesafe | Sağlam tam otomatik platform | Oynanabilir |
| VX-58 | VX-58 Vanguard | Tüfek | Kontrollü hücum | Seçilebilir üçlü seri | Planlandı |
| VX-72 | VX-72 Warden | Tüfek | Uzun mesafe / zayıf nokta | Yarı otomatik DMR ve termal optik | Planlandı |
| VX-90 | VX-90 Chimera | Tüfek | Uyarlanabilir son seviye tüfek | Programlanabilir mühimmat | Planlandı |
| MP-90 | MP-90 Viper | Hafif otomatik | Hareketli yakın çatışma | 50 mermilik yüksek atış hızı | Oynanabilir |
| MP-96 | MP-96 Whisper | Hafif otomatik | Gizlilik / bastırma | Entegre susturucu | Planlandı |
| MP-110 | MP-110 Cyclone | Hafif otomatik | Çok yüksek ateş yoğunluğu | Vektörel geri tepme ve tambur | Planlandı |
| MP-120 | MP-120 Phantom | Hafif otomatik | Hassas ileri teknoloji SMG | Faz dengeli akıllı atış | Planlandı |
| LX-01 | LX-01 Lumen | Enerji | İlk enerji silahı | Darbeli lazer ve ısı yönetimi | Planlandı |
| LX-07 | LX-07 Prism | Enerji | Sekmeli ışın / grup hedefi | Prizmatik yansıma | Planlandı |
| LX-13 | LX-13 Helios | Enerji | Şarjlı uzun menzil | Yüksek enerjili tek darbe | Planlandı |
| LX-20 | LX-20 Null | Enerji | Boyutsal son seviye silah | Faz delme ve Null alanı | Planlandı |

---

## 4. Tabancalar

### P-01 Taktik Tabanca

**Kimlik:** `p01` — legacy save alias: `pistol`
**Rol:** Oyunun başlangıç silahı; güvenilir, sade ve dengeli.
**Temel özellik:** Fener veya elektronik hedefleme içermez. Mekanik gez–arpacık ile gerçek ADS kullanır.

| Değer | Plan |
|---|---:|
| Hasar | 18 |
| Şarjör | 12 |
| Atış aralığı | 0,28 sn |
| Yeniden doldurma | 1,10 sn |
| Yayılım | 0,80° |
| Etkili menzil | 80 m |
| Kafa vuruşu | ×1,75 |
| Yedek mühimmat | 180 |

**Geliştirmeler:**

1. `match_barrel` — **Eşlenmiş Namlu:** Hasar `×1,12`.
2. `quick_mag` — **Hızlı Şarjör:** Doldurma süresi `×0,82`, şarjör `+3`.
3. `ghost_trigger` — **Hayalet Tetik:** Yayılım `×0,55`, kafa vuruşu `×1,15`.

**Oynanış kimliği:** Her zaman güvenilir kalır. Üst modeller kadar özel sistem sunmaz; mühimmat verimliliği ve hassasiyetle değerini korur.

### P-07 Sentinel

**Kimlik:** `p07`
**Rol:** Karanlık tesisler ve hızlı yakın-orta mesafe takibi.
**Temel özellik:** Silaha bağlı taktik fener. Fener açıldığında yakın hedefler daha net seçilir; yaratık algısı ve gizlilik dengesi ayrıca ayarlanır.

| Değer | Plan |
|---|---:|
| Hasar | 17 |
| Şarjör | 16 |
| Atış aralığı | 0,22 sn |
| Yeniden doldurma | 1,00 sn |
| Yayılım | 0,90° |
| Etkili menzil | 75 m |
| Kafa vuruşu | ×1,80 |
| Optik | 1,25× refleks |

**Geliştirmeler:**

1. `luma_array` — **Luma Fener Dizisi:** Fener menzili `+35%`; merkez ışık daha dar ve güçlü olur.
2. `micro_compensator` — **Mikro Kompansatör:** Dikey geri tepme `−25%`, toparlanma `+20%`.
3. `sentinel_link` — **Sentinel Bağlantısı:** Fener konisindeki hedeflerin zayıf noktası kısa süre işaretlenir; işaretli hedefe ilk atış hasarı `+15%`.

**Oynanış kimliği:** P-01’den daha hızlı ve donanımlıdır; fakat daha düşük mermi verimliliği ve biraz daha fazla temel yayılım kullanır.

### P-14 Specter

**Kimlik:** `p14`
**Rol:** Gizli operasyon, keşif ve hassas hedef temizleme.
**Temel özellik:** Entegre susturucu, düşük parlamalı fener ve değişken büyütmeli akıllı optik.

| Değer | Plan |
|---|---:|
| Hasar | 22 |
| Şarjör | 14 |
| Atış aralığı | 0,25 sn |
| Yeniden doldurma | 1,15 sn |
| Yayılım | 0,45° |
| Etkili menzil | 100 m |
| Kafa vuruşu | ×2,00 |
| Optik | 2× / 4× |

**Geliştirmeler:**

1. `variable_sight` — **Specter Değişken Optik:** 2× ve 4× büyütme arasında geçiş; ADS salınımı `−20%`.
2. `silent_baffle` — **Sessiz Baffle Çekirdeği:** Atış gürültüsü ve düşman uyarma yarıçapı `−60%`; namlu parlaması kaldırılır.
3. `needle_rounds` — **İğne Çekirdekli Mühimmat:** Zırhın `%25` bölümünü yok sayar; zayıf nokta hasarı `+20%`.

**Oynanış kimliği:** Kalabalık çatışması için değil; düşmanları uyarmadan seçerek ortadan kaldırmak için kullanılır.

### P-20 Magnum

**Kimlik:** `p20`
**Rol:** Zırhlı yaratık, seçkin düşman ve kritik tek atış.
**Temel özellik:** Ortak `bullets` tabanca mühimmatı, yüksek geri tepme ve bir hedefi delme ihtimali.

| Değer | Plan |
|---|---:|
| Hasar | 42 |
| Şarjör | 8 |
| Atış aralığı | 0,45 sn |
| Yeniden doldurma | 1,35 sn |
| Yayılım | 0,70° |
| Etkili menzil | 85 m |
| Kafa vuruşu | ×2,10 |
| Optik | 1,5× ağır refleks |

**Geliştirmeler:**

1. `inertial_piston` — **Atalet Pistonu:** Geri tepme `−30%`; nişangâh hedefe daha hızlı döner.
2. `overpressure_core` — **Aşırı Basınç Çekirdeği:** Hasar `+20%`, geri tepme `+10%`.
3. `rupture_round` — **Rupture Mühimmatı:** Bir düşmanı veya ince korumayı deler; zırhlı zayıf nokta hasarı `+25%`.

**Oynanış kimliği:** Tabanca sınıfının en yüksek anlık hasarıdır. Küçük şarjör ve sert geri tepme yanlış atışı pahalı hâle getirir.

---

## 5. Pompalı ve savaş tüfekleri

### SG-04 Kırıcı

**Kimlik:** `sg04` — legacy save alias: `shotgun`
**Rol:** Yakın mesafede güvenilir durdurma gücü.
**Temel özellik:** Manuel pompa; sekiz saçmalı standart fişek.

| Değer | Plan |
|---|---:|
| Saçma hasarı | 11 × 8 |
| Tüp kapasitesi | 6 |
| Atış aralığı | 0,82 sn |
| Yeniden doldurma | 1,45 sn |
| Yayılım | 5,50° |
| Etkili menzil | 48 m |
| Kafa vuruşu | ×1,60 |
| Yedek fişek | 60 |

**Geliştirmeler:**

1. `choke` — **Taktik Şok:** Yayılım `×0,72`.
2. `drum_extension` — **Tüp Uzatması:** Kapasite `+2`, doldurma süresi `×0,90`.
3. `breacher` — **Kırıcı Yük:** Hasar `×1,18`, geri tepme `×1,12`.

### SG-09 Aegis

**Durum:** Oyunda uygulanmış (`resources/weapons/sg09.tres`, `scenes/ui/weapons/sg09_view.tscn`).
**Kimlik:** `sg09`
**Rol:** Koridor savunması ve hızlı ikinci atış.
**Temel özellik:** Yarı otomatik mekanizma ve namlu altı fener.

| Değer | Plan |
|---|---:|
| Saçma hasarı | 10 × 8 |
| Şarjör | 8 |
| Atış aralığı | 0,38 sn |
| Yeniden doldurma | 1,60 sn |
| Yayılım | 4,80° |
| Etkili menzil | 50 m |
| Ateş modu | Yarı otomatik |

**Geliştirmeler:**

1. `aegis_gas_drive` — **Aegis Gaz Sistemi:** Atış aralığı `−12%`, mekanizma sarsıntısı azalır.
2. `smart_caddy` — **Akıllı Şarjör Yuvası:** Şarjör `+2`, doldurma süresi `−20%`.
3. `flechette_load` — **Flechette Yükü:** Saçma yayılımı `−15%`; zırhın `%20` bölümünü yok sayar.

### SG-15 Tempest

**Kimlik:** `sg15`
**Durum:** Oyunda uygulanmış (`resources/weapons/sg15.tres`, `scenes/ui/weapons/sg15_view.tscn`).
**Rol:** Hızlı yaratık sürüleri ve acil alan temizliği.
**Temel özellik:** Tam otomatik ateş ve tambur şarjör; uzun kullanımda ısı biriktirir.

| Değer | Plan |
|---|---:|
| Saçma hasarı | 8 × 7 |
| Tambur | 12 |
| Atış aralığı | 0,18 sn |
| Yeniden doldurma | 2,00 sn |
| Yayılım | 6,20° |
| Etkili menzil | 42 m |
| Ateş modu | Tam otomatik |

**Geliştirmeler:**

1. `tempest_drum` — **Geniş Tambur:** Kapasite `+6`; doldurma süresi `+10%`.
2. `thermal_jacket` — **Isı Ceketi:** Aşırı ısınma eşiği `+40%`, soğuma hızı `+25%`.
3. `cyclone_bolt` — **Cyclone Sürgü:** Atış aralığı `−15%`; tam otomatik yayılım `+8%`.

### SG-21 Graviton

**Kimlik:** `sg21`
**Rol:** Ağır yaratıklar, dar geçitler ve alan kontrolü.
**Temel özellik:** ADS sırasında daralan adaptif şok; alternatif tek çekirdekli gravitasyon fişeği.

| Değer | Plan |
|---|---:|
| Saçma hasarı | 15 × 9 |
| Hücreli şarjör | 6 |
| Atış aralığı | 0,70 sn |
| Yeniden doldurma | 1,80 sn |
| Yayılım | 3,80° |
| Etkili menzil | 60 m |
| Alternatif atış | Gravitasyon fişeği |

**Geliştirmeler:**

1. `adaptive_choke` — **Adaptif Şok:** ADS sırasında yayılım ilave `−35%`; kalça atışında mevcut alan etkisi korunur.
2. `dual_feed` — **Çift Besleme:** Standart saçma ve tek çekirdekli fişek arasında anında geçiş.
3. `gravity_payload` — **Gravitasyon Yükü:** Vuruş merkezindeki küçük hedefleri geriye iter; ağır hedefleri kısa süre yavaşlatır.

---

## 6. Taarruz ve nişancı tüfekleri

### VX-47 Taarruz Tüfeği

**Kimlik:** `vx47` — legacy save alias: `ak47`
**Rol:** Orta mesafede dengeli ana silah.
**Temel özellik:** Sağlam tam otomatik VEX askerî platformu.

| Değer | Plan |
|---|---:|
| Hasar | 14 |
| Şarjör | 30 |
| Atış aralığı | 0,10 sn |
| Yeniden doldurma | 1,20 sn |
| Yayılım | 1,10° |
| Etkili menzil | 90 m |
| Kafa vuruşu | ×1,80 |
| Yedek mühimmat | 240 |

**Geliştirmeler:**

1. `gas_regulator` — **Gaz Regülatörü:** Geri tepme `×0,82`.
2. `smart_feed` — **Akıllı Besleme:** Doldurma süresi `×0,80`.
3. `overpressure` — **Aşırı Basınç:** Hasar `×1,16`, yayılım `×1,10`.

### VX-58 Vanguard

**Kimlik:** `vx58`
**Rol:** Kontrollü hücum ve orta-uzun mesafe baskısı.
**Temel özellik:** Tekli, üçlü seri ve tam otomatik ateş seçimi; 1×/3× savaş optiği.

| Değer | Plan |
|---|---:|
| Hasar | 13 |
| Şarjör | 36 |
| Atış aralığı | 0,085 sn |
| Yeniden doldurma | 1,25 sn |
| Yayılım | 0,85° |
| Etkili menzil | 95 m |
| Ateş modu | Tekli / üçlü / otomatik |

**Geliştirmeler:**

1. `burst_controller` — **Darbe Denetleyicisi:** Üçlü serinin ikinci ve üçüncü atış geri tepmesi `−35%`.
2. `vanguard_optic` — **Vanguard Optik:** 1×/3× geçiş; büyütmede yayılım `−20%`.
3. `smart_ap` — **Akıllı Zırh Delici:** Zırhlı hedefe hasar `+18%`; seri son mermisi zayıf noktaya `+15%` verir.

### VX-72 Warden

**Kimlik:** `vx72`
**Rol:** Uzun mesafe, zayıf nokta ve seçkin hedef avı.
**Temel özellik:** Yarı otomatik DMR; 3×/6× termal optik.

| Değer | Plan |
|---|---:|
| Hasar | 30 |
| Şarjör | 20 |
| Atış aralığı | 0,24 sn |
| Yeniden doldurma | 1,35 sn |
| Yayılım | 0,30° |
| Etkili menzil | 140 m |
| Kafa vuruşu | ×2,20 |

**Geliştirmeler:**

1. `warden_receiver` — **Eşlenmiş Gövde:** Yayılım `−30%`, ilk atış geri tepmesi `−20%`.
2. `thermal_scope` — **Termal Optik:** 3×/6×; sis ve düşük ışıkta canlı hedef konturu.
3. `phase_penetrator` — **Faz Delici:** Bir düşmanı veya ince yüzeyi deler; ikinci hedefe `%70` hasar taşır.

### VX-90 Chimera

**Kimlik:** `vx90`
**Rol:** Son seviye uyarlanabilir taarruz tüfeği.
**Temel özellik:** Standart, şok ve parçalayıcı mühimmat davranışı arasında programlanabilir geçiş.

| Değer | Plan |
|---|---:|
| Hasar | 16 |
| Şarjör | 40 |
| Atış aralığı | 0,075 sn |
| Yeniden doldurma | 1,50 sn |
| Yayılım | 0,65° |
| Etkili menzil | 110 m |
| Optik | 1×/2,5× akıllı optik |

**Geliştirmeler:**

1. `adaptive_stock` — **Uyarlanabilir Dipçik:** Hareketli atış yayılımı `−25%`; çömelmede geri tepme `−30%`.
2. `programmable_ammo` — **Programlanabilir Mühimmat:** Darbe, şok ve zırh delici profil arasında geçiş.
3. `predictive_link` — **Öngörülü Hedef Bağı:** Aynı hedefe art arda isabetlerde hassasiyet ve hasar kademeli olarak en fazla `+20%` artar.

---

## 7. Hafif otomatik silahlar

### MP-90 Viper

**Kimlik:** `mp90`
**Rol:** Hızlı hareket sırasında yakın-orta mesafe baskısı.
**Temel özellik:** 50 mermilik şarjör ve yüksek ateş hızı.

| Değer | Plan |
|---|---:|
| Hasar | 10 |
| Şarjör | 50 |
| Atış aralığı | 0,07 sn |
| Yeniden doldurma | 1,35 sn |
| Yayılım | 1,20° |
| Etkili menzil | 75 m |
| Kafa vuruşu | ×1,70 |
| Yedek mühimmat | 300 |

**Geliştirmeler:**

1. `vector_grip` — **Vektör Kabza:** Geri tepme `×0,76`.
2. `helical_feed` — **Helisel Besleme:** Şarjör `+10`.
3. `phase_cycler` — **Faz Çevrimcisi:** Atış aralığı `×0,84`, yayılım `×1,12`.

### MP-96 Whisper

**Kimlik:** `mp96`
**Rol:** Sessiz ilerleme ve devriyeleri uyarmadan yakın hedef temizleme.
**Temel özellik:** Entegre susturucu ve düşük parlamalı mühimmat.

| Değer | Plan |
|---|---:|
| Hasar | 12 |
| Şarjör | 36 |
| Atış aralığı | 0,08 sn |
| Yeniden doldurma | 1,10 sn |
| Yayılım | 0,80° |
| Etkili menzil | 65 m |
| Gürültü | Standart SMG’nin `%35`i |

**Geliştirmeler:**

1. `whisper_baffles` — **Whisper Baffle:** Gürültü yarıçapı ek `−40%`, namlu parlaması tamamen kapanır.
2. `subsonic_feed` — **Ses Altı Besleme:** İlk beş atışta geri tepme ve yayılım `−25%`.
3. `ghost_link` — **Hayalet Bağlantı:** Fark edilmemiş hedefe hasar `+25%`; öldürme çevredeki alarm artışını azaltır.

### MP-110 Cyclone

**Kimlik:** `mp110`
**Rol:** Çok yüksek ateş yoğunluğu ve kısa süreli hasar patlaması.
**Temel özellik:** Vektörel geri tepme sistemi, büyük tambur ve ısı sınırı.

| Değer | Plan |
|---|---:|
| Hasar | 9 |
| Tambur | 60 |
| Atış aralığı | 0,05 sn |
| Yeniden doldurma | 1,70 sn |
| Yayılım | 1,50° |
| Etkili menzil | 60 m |
| Özel sistem | Isınma |

**Geliştirmeler:**

1. `dual_vector` — **Çift Vektörleyici:** Yatay geri tepme `−35%`, dikey geri tepme `−20%`.
2. `cyclone_drum` — **Cyclone Tambur:** Kapasite `+15`; doldurma süresi `+8%`.
3. `redline_overclock` — **Redline Hız Aşırtma:** Atış aralığı `−18%`; ısı üretimi `+25%`.

### MP-120 Phantom

**Kimlik:** `mp120`
**Rol:** Hassas, hareketli ve ileri teknoloji yakın-orta mesafe silahı.
**Temel özellik:** Faz dengeli mermi yolu; kısa seri sırasında çok düşük yayılım.

| Değer | Plan |
|---|---:|
| Hasar | 13 |
| Şarjör | 45 |
| Atış aralığı | 0,06 sn |
| Yeniden doldurma | 1,40 sn |
| Yayılım | 0,65° |
| Etkili menzil | 80 m |
| Optik | 1×/2× holografik |

**Geliştirmeler:**

1. `phase_stabilizer` — **Faz Sabitleyici:** Hareket ve havadaki yayılım `−30%`.
2. `smart_magazine` — **Akıllı Şarjör:** Kapasite `+10`; boş şarjör doldurma süresi `−20%`.
3. `phantom_burst` — **Phantom Darbesi:** Her onuncu isabet kısa faz darbesi üretir; ince zırhı deler ve hedefi sendeletir.

---

## 8. Lazer ve enerji silahları

### Enerji sistemi ortak kuralları

- Enerji silahları balistik mühimmat yerine değiştirilebilir güç hücresi kullanır.
- Hücrede enerji varken yeniden doldurma zorunlu değildir; fakat kesintisiz ateş ısı üretir.
- Aşırı ısınan silah kısa süre kilitlenir. Manuel havalandırma, kalan ısıyı daha hızlı düşürür.
- Enerji hasarı bazı boyutsal kalkanlara güçlü, yansıtıcı zırhlara zayıf olabilir.
- Enerji, ısı, ışın sekmesi ve şarj davranışı yeni `WeaponDefinition` alanları gerektirir.

### LX-01 Lumen

**Kimlik:** `lx01`
**Rol:** Oyuncunun ilk enerji silahı; dengeli darbeli lazer.
**Temel özellik:** Mermi yolculuğu olmadan anlık ışın darbesi ve temel ısı yönetimi.

| Değer | Plan |
|---|---:|
| Darbe hasarı | 20 |
| Hücre kapasitesi | 80 |
| Atış maliyeti | 4 enerji |
| Atış aralığı | 0,18 sn |
| Hücre değişimi | 2,00 sn |
| Etkili menzil | 110 m |
| Isı eşiği | 100 birim |

**Geliştirmeler:**

1. `cell_condenser` — **Hücre Yoğunlaştırıcı:** Enerji kapasitesi `+25%`.
2. `lumen_lens` — **Lumen Odak Merceği:** Etkili menzil `+25%`, zayıf nokta hasarı `+15%`.
3. `thermal_governor` — **Isı Yöneticisi:** Isı üretimi `−30%`, manuel soğutma `+35%`.

### LX-07 Prism

**Kimlik:** `lx07`
**Rol:** Birbirine yakın düşman gruplarını sekmeli ışınla temizleme.
**Temel özellik:** İlk hedefe çarpan ışın yakındaki ikinci hedefe düşük güçle seker.

| Değer | Plan |
|---|---:|
| Ana ışın hasarı | 16 |
| Hücre kapasitesi | 100 |
| Atış maliyeti | 5 enerji |
| Atış aralığı | 0,12 sn |
| Etkili menzil | 95 m |
| İlk sekme | `%60` hasar |

**Geliştirmeler:**

1. `prism_array` — **Prizma Dizisi:** İkinci sekme açılır; sekme menzili `+30%`.
2. `split_beam` — **Ayrık Işın:** Alternatif atış, yakın iki hedefe eşit güçte iki ışın yollar.
3. `resonance_loop` — **Rezonans Döngüsü:** Aynı hedefe art arda ışınlarda hasar en fazla `+25%` artar; hedef değişince sıfırlanır.

### LX-13 Helios

**Kimlik:** `lx13`
**Rol:** Uzun menzilli şarjlı enerji keskin nişancı silahı.
**Temel özellik:** Tetik basılı tutularak biriken yüksek enerjili tek darbe.

| Değer | Plan |
|---|---:|
| Tam şarj hasarı | 88 |
| Hücre kapasitesi | 72 |
| Tam şarj maliyeti | 18 enerji |
| Şarj süresi | 1,00 sn |
| Hücre değişimi | 2,20 sn |
| Etkili menzil | 180 m |
| Optik | 3×/8× enerji optiği |

**Geliştirmeler:**

1. `fast_capacitor` — **Hızlı Kapasitör:** Tam şarj süresi `−25%`.
2. `helios_lens` — **Helios Uzun Mercek:** Menzil `+25%`, zayıf nokta hasarı `+20%`.
3. `solar_overload` — **Güneş Aşırı Yükü:** Tam şarjlı vuruş küçük enerji patlaması üretir; ısı üretimi `+20%`.

### LX-20 Null

**Kimlik:** `lx20`
**Rol:** Oyunun son seviye boyutsal silahı; zırh, kalkan ve faz hedefleri.
**Temel özellik:** Kısa süreli faz delme ve alternatif Null alanı oluşturma.

| Değer | Plan |
|---|---:|
| Darbe hasarı | 28 |
| Hücre kapasitesi | 120 |
| Atış maliyeti | 8 enerji |
| Atış aralığı | 0,10 sn |
| Hücre değişimi | 2,40 sn |
| Etkili menzil | 130 m |
| Alternatif atış | Null alanı |

**Geliştirmeler:**

1. `phase_reservoir` — **Faz Rezervuarı:** Hücre kapasitesi `+30`, aşırı ısınma eşiği `+15%`.
2. `null_lattice` — **Null Kafesi:** Boyutsal kalkanları deler; normal zırhın `%35` bölümünü yok sayar.
3. `event_horizon` — **Olay Ufku:** Alternatif atış kısa ömürlü Null alanı kurar; küçük hedefleri merkeze çeker ve boyutsal düşmanlara sürekli hasar verir.

**Denge sınırı:** Null alanı yüksek enerji ve ısı tüketmelidir. LX-20 diğer silahları gereksiz hâle getiren sınırsız bir çözüm olmamalıdır.

---

## 9. Mühimmat ve kaynak türleri

| Kaynak | Kullanan modeller | Renk standardı | Not |
|---|---|---|---|
| `bullets` | P-01, P-07, P-14, P-20 | Sarı / pirinç | P-14 özel profili ve P-20 yüksek hasarı silah verisi/geliştirmeyle uygulanır |
| `shells` | SG-04, SG-09, SG-15 | Kırmızı | SG-21 için temel uyumluluk korunabilir |
| `graviton_shells` | SG-21 alternatif atış | Mor kullanılmayacak; cyan-beyaz | Boyutsal ama temiz VEX renk standardı |
| `rifle_ammo` | VX-47, VX-58, VX-72, VX-90 | Turuncu / pirinç | Programlanabilir profil aynı kaynağı tüketir |
| `smg_ammo` | MP-90, MP-96, MP-110, MP-120 | Açık sarı / grafit | Mevcut `mp90_ammo` ileride bu kimliğe taşınır |
| `energy_cell` | LX-01, LX-07, LX-13, LX-20 | Cyan / beyaz | Hücre enerjisi ve ısı ayrı değerlerdir |

Mühimmat pickup’ı oyuncunun kapasitesi doluysa toplanmamalı ve dünyadan kaybolmamalıdır.

---

## 10. Görsel üretim standardı

Her silah için aşağıdaki ana görseller hazırlanacaktır:

| Görsel | Adet | Dosya örneği | Zorunlu |
|---|---:|---|---|
| Elde bekleme | 1 | `p07_idle.png` | Evet |
| Ateş animasyonu | 4 | `p07_fire_1.png` … `p07_fire_4.png` | Evet |
| Yeniden doldurma | 4 | `p07_reload_1.png` … `p07_reload_4.png` | Evet |
| Yandan raf görünüşü | 1 | `p07_side.png` | Evet |
| ADS / zoom | 1 | `p07_zoom.png` | Evet |
| ADS ateş | 4 | `p07_aim_fire_1.png` … `p07_aim_fire_4.png` | Optikli silahlarda evet |
| Alternatif atış | En az 4 | `sg21_alt_fire_1.png` … | Alternatif atışlı modellerde |
| Havalandırma / enerji değişimi | 4 | `lx01_vent_1.png` … | Enerji silahlarında |

### 10.1 Değişmez görsel kurallar

- Bütün birinci şahıs silahlar ekranın altından devam eden aynı oyuncu kolunu kullanır.
- Eldiven modeli, rengi, dikişleri ve malzeme yapısı bütün karelerde sabit kalır.
- Tabancalarda P-07 idle karesi standart kamera mesafesi, ekran konumu ve tutuş açısı referansıdır; silah değişiminde yalnız silah modeli değişir.
- Ateş karelerinde standart tutuş açısı korunur; yalnız geri tepmenin gerektirdiği küçük dikey hareket uygulanır ve silah yana doğru döndürülmez.
- Reload karelerinde kamera ve kıyafet sabit kalır; silah yalnız şarjör işleminin zorunlu kıldığı kadar çevrilir.
- El silahın çok önüne çıkmaz; tutuş oyuncunun gövdesine yakın görünür.
- Bekleme pozu ekranın alt-sağındadır ve silah merkeze doğru hafif açılı tutulur.
- ADS görselinde gez, arpacık, namlu ekseni ve ekran merkezi tek hizada olur.
- Otomatik aşağı indirme görseli şimdilik üretilmez ve kullanılmaz.
- Yandan raf görselinde namlu daima **sağa** bakar.
- Yandan görsel gerçek RGBA şeffaflık kullanır; beyaz, yeşil, magenta veya mor kenar saçağı içermez.
- Tam şeffaf piksellerin gizli RGB değeri komşu silah kenarından türetilmiş nötr gunmetal olmalıdır.
- Silah üzerinde model kodu ve küçük, fabrikada işlenmiş `VEX` markası bulunur.
- Görsellerde dış ışık kaynağından gelen sarı/mor renk bulaşması ve yapay parlak kontur kullanılmaz.

### 10.2 Dosya dizini

```text
assets/weapons/
  p01/
  p07/
  p14/
  p20/
  sg04/
  ...
  lx20/
```

Dosya adları tamamen küçük harf `snake_case` olmalıdır.

---

## 11. Ses standardı

Her model başka bir silah sesinin yalnızca pitch değiştirilmiş kopyasını kullanmamalıdır.

| Ses | Dosya örneği |
|---|---|
| Ateş | `p07_fire.wav` |
| Kuru tetik | `p07_dry.wav` |
| Şarjör çıkarma | `p07_mag_out.wav` |
| Şarjör takma | `p07_mag_in.wav` |
| Sürgü / kurma | `p07_action.wav` |
| Alternatif atış | `sg21_alt_fire.wav` |
| Enerji şarjı | `lx13_charge.wav` |
| Aşırı ısınma | `lx13_overheat.wav` |
| Havalandırma | `lx13_vent.wav` |

Sesler silahın ağırlığını ve çalışma sistemini anlatmalıdır: tabancalar kısa ve mekanik, pompalılar ağır, SMG’ler hızlı, enerji silahları katmanlı fakat kulak yorucu olmayan bir kimlik kullanır.

---

## 12. Uygulama sırası

1. `WeaponDefinition` yapısını yeni kimlikler, özellik bayrakları ve 5. teçhizat yuvası için genişlet.
2. Eski kimliklerden yeni kimliklere kayıt göçünü uygula.
3. P-01, SG-04, VX-47 ve MP-90 canonical kaynaklarını ve bağımsız HUD presentation sahnelerini koru; yeni silahları aynı kalıpla ekle.
4. Her sınıfın Kademe II modelini uygula: P-07, SG-09, VX-58, MP-96, LX-07’den önce LX-01.
5. Fener, değişken optik, ateş modu ve susturucu sistemlerini veri odaklı hâle getir.
6. Isı, enerji hücresi, ışın sekmesi ve şarjlı atış altyapısını kur.
7. Kademe III modellerini ve ilgili hikâye araştırmalarını ekle.
8. Kademe IV modellerini yalnız ileri bölüm dengesi hazır olduğunda aç.
9. Her model için üç geliştirmeyi, HUD bilgisini, raf durumunu ve kayıt kalıcılığını test et.
10. Son görselleri, özgün sesleri, pickup sahnelerini ve cephanelik raf bağlantılarını tamamla.

---

## 13. Uygulama kontrol listesi

Bir silah “tamamlandı” sayılmadan önce:

- [ ] Model adı, `weapon_id`, sınıfı ve teçhizat yuvası tanımlı.
- [ ] Temel hasar, kapasite, atış aralığı, doldurma, yayılım ve menzil Inspector’da.
- [ ] Üç geliştirme uygulanmış ve kayda yazılıyor.
- [ ] Özel özellik başka silahların rolünü geçersiz kılmıyor.
- [ ] Idle, fire, reload, side, zoom ve gerekiyorsa aim-fire/alt-fire görselleri hazır.
- [ ] Bütün animasyon karelerinde eldiven ve kol devamlılığı korunuyor.
- [ ] Raf görseli sağa bakıyor, şeffaf kenarı temiz ve hücrede ortalı.
- [ ] Ateş, mekanizma, doldurma ve kuru tetik sesleri özgün.
- [ ] Mühimmat pickup’ı ve maksimum kapasite tanımlı.
- [ ] HUD adı, mühimmat türü, ateş modu ve geliştirme bilgisi iki dilde.
- [ ] Silah rafa bırakılıp yeniden alınabiliyor.
- [ ] Aynı sınıftan başka silah alındığında doğru model rafa dönüyor.
- [ ] Ölüm ve bölüm yeniden başlatmada başlangıç teçhizatı doğru geri geliyor.
- [ ] Normal, nişanlı, hareketli ve çok yakın hedef atışları test edildi.
- [ ] Kolay, normal, zor ve kâbus dengeleri kontrol edildi.

---

## 14. Değiştirilemeyecek kararlar

Bu kararlar yeni bir ana tasarım kararı alınmadıkça sabittir:

1. Toplam beş silah sınıfı ve her sınıfta dört model bulunur.
2. Oyuncu aynı sınıftan yalnız bir silah taşır.
3. Her silahın birbirinden farklı üç geliştirmesi vardır.
4. Silahlar Bastion-7 raflarında fiziksel olarak saklanır ve tekrar alınabilir.
5. P-01 sade başlangıç silahıdır; fener veya gelişmiş optik içermez.
6. P-07’nin temel farkı taktik fenerdir.
7. P-14 fener, susturucu ve gelişmiş büyütmeli optiği birleştirir.
8. P-20 tabanca sınıfının yüksek hasarlı, düşük kapasiteli ağır modelidir.
9. Silah görsellerinde P-07 ile aynı eldiven, kol kıyafeti, kamera mesafesi ve sınıf içi standart tutuş açısı kullanılır.
10. Silahların yandan raf görsellerinde namlu sağa bakar.
11. Otomatik silahı aşağı indirme sistemi şimdilik kapalıdır.
12. Yeni silahlar kod içindeki sabit `match` bloklarıyla değil, veri kaynaklarıyla tanımlanır.
