class_name VexArchiveDatabase
extends RefCounted

# Bastion-7 ana terminalinin oyuncuya dönük veri kaynağı.
# Sayısal combat tuning burada tutulmaz; savaş davranışının kaynağı enemy sahne/scriptleridir.

const UNIVERSES := [
	{
		"id": &"korvath",
		"name": "KORVATH OCAĞI",
		"name_en": "KORVATH FORGE",
		# Köken/kaynak gerçeği hikâyede bu bölüm tamamlanınca doğrulanır.
		"reveal_stage": 4,
		"identity_provisional_tr": "Aşırı ısı ve basınca dayanıklı xeno formlar. Kamera kayıtları bu türlerin laboratuvardan kaçmadığını, doğrudan yarıktan geçtiğini gösteriyor. Köken gerçekliğin yapısı ve türlerin burada bulunma nedeni henüz doğrulanmadı.",
		"identity_provisional_en": "Xeno forms resistant to extreme heat and pressure. Camera records show these species did not escape a laboratory; they crossed directly through the rift. The structure of their origin reality and why they are here remain unverified.",
		"extraction_provisional_tr": "Kaynak ilişkisi henüz doğrulanmadı. Sıfır Kaynak akışında ısı ve basınç anomalileri ölçülüyor; VEX'in bu gerçeklikten ne çektiği ve karşı tarafa etkisi bilinmiyor.",
		"extraction_provisional_en": "Source relationship unverified. Heat and pressure anomalies are measured in the Zero Source flow; what VEX drew from this reality and its effect on the far side remain unknown.",
		"identity_tr": "Aşırı sıcaklık ve basınç altında kurulmuş yeraltı ocak uygarlığı. İş organizmaları, termal taşıyıcılar ve enerji kuyusu muhafızları aynı ekosistemin parçalarıdır.",
		"identity_en": "A subterranean forge civilization adapted to extreme heat and pressure. Labor organisms, thermal carriers and well guardians belong to one industrial ecosystem.",
		"extraction_tr": "VEX bu gerçeklikten jeotermal güç, ısı ve basınç dengesi çekti. Ocakların soğuması ve damar çökmeleri Korvath canlılarını yarık kaynağına sürükledi.",
		"extraction_en": "VEX extracted geothermal power, heat and pressure balance from this reality. Cooling forges and collapsing veins drove Korvath life toward the rift source.",
		"pressure_tr": "Yüksek dayanıklılık // sıcak projectile baskısı // yakın termal alan kontrolü",
		"pressure_en": "High durability // heated projectile pressure // close thermal area control",
		"palette_tr": "Bazalt siyahı, kızıl, turuncu, sıcak sarı",
		"palette_en": "Basalt black, crimson, orange, hot yellow",
		"enemy_ids": [&"basalt_juggernaut", &"cinderhound", &"cinder_spitter", &"furnice_carrier", &"crucible_warden"],
	},
	{
		"id": &"thornwild",
		"name": "THORNWILD SÜRÜSÜ",
		"name_en": "THORNWILD SWARM",
		# Köken/kaynak gerçeği hikâyede bu bölüm tamamlanınca doğrulanır.
		"reveal_stage": 8,
		"identity_provisional_tr": "Bu gerçekliğe ait türler doğrulandı. Köken ekolojisi ve davranış nedeni henüz sınıflandırılmadı.",
		"identity_provisional_en": "Species from this reality are verified. Their origin ecology and motives have not been classified yet.",
		"extraction_provisional_tr": "Kaynak ilişkisi henüz doğrulanmadı.",
		"extraction_provisional_en": "Source relationship unverified.",
		"identity_tr": "Et, kemik, diken ve spor dokusunun iç içe geçtiği sert bir av-avcı ekosistemi. Askerî bir kuvvet değil; bozulan habitatına tepki veren canlı zinciridir.",
		"identity_en": "A harsh predator-prey ecosystem of flesh, bone, thorns and spores. It is not an army, but a living chain reacting to a damaged habitat.",
		"extraction_tr": "VEX biyokütle, enzim ve rejeneratif doku çekti. Habitat ve av zinciri bozulunca türler yarık çevresinde yeni yaşam alanlarına yayıldı.",
		"extraction_en": "VEX extracted biomass, enzymes and regenerative tissue. As habitats and food chains collapsed, species spread around the rifts in search of new territory.",
		"pressure_tr": "Organik ranged baskı // hibrit avcılık // charge // zehirli alan kontrolü",
		"pressure_en": "Organic ranged pressure // hybrid hunting // charge // toxic area control",
		"palette_tr": "Koyu et/kızıl, kemik, kirli sarı-yeşil biyolüminesans",
		"palette_en": "Dark flesh/crimson, bone, dirty yellow-green bioluminescence",
		"enemy_ids": [&"ravager", &"briar_skulker", &"gorehorn", &"spore_matriarch"],
	},
	{
		"id": &"vaskari",
		"name": "VASKARI LEJYONU",
		"name_en": "VASKARI LEGION",
		# Köken/kaynak gerçeği hikâyede bu bölüm tamamlanınca doğrulanır.
		"reveal_stage": 15,
		"identity_provisional_tr": "Bu gerçekliğe ait türler doğrulandı. Köken ekolojisi ve davranış nedeni henüz sınıflandırılmadı.",
		"identity_provisional_en": "Species from this reality are verified. Their origin ecology and motives have not been classified yet.",
		"extraction_provisional_tr": "Kaynak ilişkisi henüz doğrulanmadı.",
		"extraction_provisional_en": "Source relationship unverified.",
		"identity_tr": "Biyozırh, zehir ve askerî kast düzeni üzerine kurulmuş organize savaş uygarlığı. Yarıkları tesadüfi geçiş değil kontrol edilmesi gereken cephe olarak görüyor.",
		"identity_en": "An organized war civilization built around bio-armor, toxins and military castes. It treats rifts as fronts to control rather than accidental passages.",
		"extraction_tr": "VEX biyotoksin, sinir iletimi ve rejeneratif savaş biyolojisi örnekleri çekti. Lejyon bunu doğrudan kaynak saldırısı olarak sınıflandırdı.",
		"extraction_en": "VEX extracted biotoxins, neural transmission material and regenerative war biology. The Legion classified this as a direct resource attack.",
		"pressure_tr": "Tamamlayıcı askerî roller // ön hat // uzun menzil // komuta desteği",
		"pressure_en": "Complementary military roles // frontline // long range // command support",
		"palette_tr": "Koyu mor, viyole, magenta, siyah biyozırh",
		"palette_en": "Dark purple, violet, magenta, black bio-armor",
		"enemy_ids": [&"vaskari_raptor", &"vaskari_ravager", &"coil_lancer", &"vaskari_bulwark", &"venom_marshall"],
	},
	{
		"id": &"nhal",
		"name": "NHAL VEIL",
		"name_en": "NHAL VEIL",
		# Köken/kaynak gerçeği hikâyede bu bölüm tamamlanınca doğrulanır.
		"reveal_stage": 18,
		"identity_provisional_tr": "Bu gerçekliğe ait türler doğrulandı. Köken ekolojisi ve davranış nedeni henüz sınıflandırılmadı.",
		"identity_provisional_en": "Species from this reality are verified. Their origin ecology and motives have not been classified yet.",
		"extraction_provisional_tr": "Kaynak ilişkisi henüz doğrulanmadı.",
		"extraction_provisional_en": "Source relationship unverified.",
		"identity_tr": "Düşük görünürlük, sis, titreşim ve perde benzeri madde akışlarıyla şekillenmiş av ekosistemi. Tehdidi görünmezlikten değil bilgi ve görüş alanını bozmasından gelir.",
		"identity_en": "A hunting ecosystem shaped by low visibility, mist, vibration and veil-like matter flows. Its threat comes from disrupting information and sight rather than invisibility.",
		"extraction_tr": "VEX düşük ışık/faz maddesi ve perde dokusu çekti. Av yolları Dünya'nın karanlık bölgeleriyle istemsiz biçimde bağlandı.",
		"extraction_en": "VEX extracted low-light phase matter and veil tissue. Hunting routes became unintentionally linked to Earth's dark spaces.",
		"pressure_tr": "Açı değiştirme // düşük görünürlük // görüş bozma // menzilli taciz",
		"pressure_en": "Angle changes // low visibility // vision disruption // ranged harassment",
		"palette_tr": "Mat siyah, lacivert, soğuk mavi",
		"palette_en": "Matte black, navy, cold blue",
		"enemy_ids": [&"veilmaw", &"husk_leech"],
	},
	{
		"id": &"aether",
		"name": "AETHER LOOM",
		"name_en": "AETHER LOOM",
		# Köken/kaynak gerçeği hikâyede bu bölüm tamamlanınca doğrulanır.
		"reveal_stage": 22,
		"identity_provisional_tr": "Bu gerçekliğe ait türler doğrulandı. Köken ekolojisi ve davranış nedeni henüz sınıflandırılmadı.",
		"identity_provisional_en": "Species from this reality are verified. Their origin ecology and motives have not been classified yet.",
		"extraction_provisional_tr": "Kaynak ilişkisi henüz doğrulanmadı.",
		"extraction_provisional_en": "Source relationship unverified.",
		"identity_tr": "Klasik biyolojiden çok enerji, örüntü ve uzamsal düzen üzerinden işleyen gerçeklik. Aether formları yarıkları bozuk bir desen olarak algılıyor.",
		"identity_en": "A reality governed more by energy, patterns and spatial order than conventional biology. Aether forms interpret rifts as damaged patterns.",
		"extraction_tr": "VEX faz dengesi ve gerçeklik örüntüsü çekti. Aether organizmaları kırılmış çizgileri yeniden bağlamaya çalışırken Dünya maddesini tehlikeli biçimde dönüştürüyor.",
		"extraction_en": "VEX extracted phase balance and reality structure. Aether organisms dangerously transform Earth matter while attempting to reconnect broken patterns.",
		"pressure_tr": "Enerji örgüleri // geniş açı baskısı // güvenli kısa faz kaymaları",
		"pressure_en": "Energy weaves // wide-angle pressure // short safe phase shifts",
		"palette_tr": "Camgöbeği, elektrik mavisi, buz beyazı, siyah yarık çizgileri",
		"palette_en": "Cyan, electric blue, ice white, black rift lines",
		"enemy_ids": [&"voidweaver", &"rift_reaver"],
	},
]

const ENEMIES := [
	{
		"id": &"basalt_juggernaut", "name": "BASALT JUGGERNAUT", "universe": &"korvath", "threat": "IV",
		"role_tr": "Ağır orta menzil kırıcı / tank", "role_en": "Heavy mid-range breaker / tank",
		"behavior_tr": "Çok yüksek dayanıklılıkla ilerler ve ağır, okunabilir sıcak projectile atışlarıyla koridoru baskılar.",
		"behavior_en": "Advances with very high durability and pressures lanes with heavy, readable heated projectiles.",
		"tactic_tr": "Tek atışın ağırlığını küçümseme. Hazırlık penceresinde açı değiştir; açık alanda uzun süre kalma.",
		"tactic_en": "Do not underestimate each shot. Change angle during the windup and avoid lingering in open lanes.",
		"lore_tr": "Korvath ocaklarında kaya kırma ve lav akışını yönlendirme için yetiştirilen yüksek basınç iş organizması.",
		"lore_en": "A high-pressure labor organism bred to break rock and redirect lava flows in Korvath forges.",
		"asset_folder": "basalt_juggernaut",
	},
	{
		"id": &"cinderhound", "name": "CINDER HOUND", "universe": &"korvath", "threat": "II",
		"role_tr": "Hızlı yakın takipçi", "role_en": "Fast close-range pursuer",
		"behavior_tr": "Yüksek chase hızıyla mesafeyi hızla kapatır ve kısa lunge ile fiziksel temasa zorlar.",
		"behavior_en": "Closes distance rapidly with high chase speed and forces physical contact through short lunges.",
		"tactic_tr": "Düz geri kaçmak yerine yön değiştir. Ağır Korvath birimlerinin atış hattına sürüklenmemeye dikkat et.",
		"tactic_en": "Strafe instead of retreating in a straight line. Avoid being driven into the firing lanes of heavier Korvath units.",
		"lore_tr": "Dar ocak tünellerinde kaçak ısı, çatlak ve hareket tespiti yapan avcı/bakım canlısı.",
		"lore_en": "A hunter-maintenance organism that tracks heat leaks, fractures and movement in narrow forge tunnels.",
		"asset_folder": "cinder_hound",
	},
	{
		"id": &"cinder_spitter", "name": "CINDER SPITTER", "universe": &"korvath", "threat": "II",
		"role_tr": "Mobil orta menzil ısı atıcısı", "role_en": "Mobile mid-range heat shooter",
		"behavior_tr": "İki atışlık kısa sıcak projectile serileri kullanır ve görüş açısını korumak için yeniden konumlanır.",
		"behavior_en": "Uses short two-shot heated projectile bursts and repositions to preserve firing angles.",
		"tactic_tr": "Serinin ilk atışından sonra aynı yönde kaçmayı sürdürme; ikinci atış için ritmi boz.",
		"tactic_en": "Do not keep dodging in the same direction after the first shot; break rhythm before the second.",
		"lore_tr": "Ocaklarda basınç ve sıcak gaz birikimini boşaltan çevik bakım organizması.",
		"lore_en": "An agile maintenance organism that vents pressure and heated gas buildup inside the forges.",
		"asset_folder": "cinder_spitter",
	},
	{
		"id": &"furnice_carrier", "name": "FURNACE CARRIER", "universe": &"korvath", "threat": "III",
		"role_tr": "Ağır ranged destek / termal alan bozucu", "role_en": "Heavy ranged support / thermal area disruptor",
		"behavior_tr": "Uzaktan projectile baskısı kurar; oyuncu yaklaştığında Thermal Burst ile çevresini temizler.",
		"behavior_en": "Applies ranged projectile pressure and clears nearby threats with Thermal Burst when approached.",
		"tactic_tr": "Ne çok uzakta sabit kal ne de körlemesine üzerine koş. Burst penceresini tetikleyip güvenli mesafeye dön.",
		"tactic_en": "Neither camp at long range nor rush blindly. Bait the burst window and return to a safe distance.",
		"lore_tr": "Korvath sahalarında ısı çekirdeği ve termal yük taşıyan yarı-organik taşıyıcı.",
		"lore_en": "A semi-organic carrier used to transport heat cores and thermal loads through Korvath sites.",
		"asset_folder": "furnice_carrier",
	},
	{
		"id": &"crucible_warden", "name": "CRUCIBLE WARDEN", "universe": &"korvath", "threat": "V",
		"role_tr": "Elit enerji kuyusu muhafızı", "role_en": "Elite energy-well guardian",
		"behavior_tr": "Ground Slam ve yakın Heatwave halkasıyla geniş alanı kontrol eder; yüksek canı nedeniyle karşılaşmanın merkez hedefidir.",
		"behavior_en": "Controls broad space with Ground Slam and close Heatwave rings; high health makes it the encounter's central target.",
		"tactic_tr": "Slam ritmini oku, yakın Heatwave menzilinde kalma ve küçük hedefler varken Warden'a kör tünel görüşü geliştirme.",
		"tactic_en": "Read the slam rhythm, avoid close Heatwave range and do not tunnel-vision the Warden while lesser threats remain.",
		"lore_tr": "Korvath enerji kuyularını ve kritik akış düğümlerini koruyan güvenlik kastı.",
		"lore_en": "A security caste that protects Korvath energy wells and critical flow nodes.",
		"asset_folder": "crucible_warden",
	},
	{
		"id": &"ravager", "name": "RAVAGER", "universe": &"thornwild", "threat": "III",
		"role_tr": "Uzun menzilli organik avcı", "role_en": "Long-range organic hunter",
		"behavior_tr": "Uzun menzilden hızlı ve isabetli tek projectile kullanır; açık görüş hattını korumaya çalışır.",
		"behavior_en": "Fires a fast precision projectile from long range and tries to maintain a clear line of sight.",
		"tactic_tr": "Açık koridorda düz hareket etme. Atış çizgisini kapatıp yeni açı almaya zorla.",
		"tactic_en": "Avoid straight movement in open lanes. Break line of sight and force it to acquire a new angle.",
		"lore_tr": "Avını üzerine atlamak yerine uzaktan zayıflatabilen orta seviye Thornwild sürü avcısı.",
		"lore_en": "A mid-tier Thornwild pack hunter capable of weakening prey from range instead of immediately pouncing.",
		"asset_folder": "ravager",
	},
	{
		"id": &"briar_skulker", "name": "BRIAR SKULKER", "universe": &"thornwild", "threat": "III",
		"role_tr": "Hibrit pusu / yakın-menzilli avcı", "role_en": "Hybrid ambush / close-range hunter",
		"behavior_tr": "Uzakta organik projectile kullanır; yakın saldırı eşiğinde melee davranışına geçer.",
		"behavior_en": "Uses organic projectiles at range and switches to melee behavior once close enough.",
		"tactic_tr": "Tek bir güvenli mesafe yoktur. Menzil değiştikçe saldırı tipinin değişeceğini hesaba kat.",
		"tactic_en": "There is no single safe distance. Expect its attack type to change as range changes.",
		"lore_tr": "Biyokütle katmanlarında saklanarak zayıf hedef temizleyen keşif avcısı.",
		"lore_en": "A scouting hunter that hides in biomass layers and picks off weakened prey.",
		"asset_folder": "briar_skulker",
	},
	{
		"id": &"gorehorn", "name": "GOREHORN", "universe": &"thornwild", "threat": "IV",
		"role_tr": "Ağır charge avcısı", "role_en": "Heavy charge hunter",
		"behavior_tr": "Kısa hazırlık sonrası yönünü kilitleyip çok hızlı düz hat şarjı yapar; duvar çarpışması uzun açık yaratır.",
		"behavior_en": "Locks direction after a short windup and performs a very fast linear charge; wall impacts create a long opening.",
		"tactic_tr": "Son anda yanal kaçış en güçlü karşı oyundur. Onu güvenli biçimde duvara yönlendirebilirsen büyük hasar penceresi kazanırsın.",
		"tactic_en": "A late lateral dodge is the strongest counterplay. Safely baiting it into a wall creates a major damage window.",
		"lore_tr": "Kalın kabuklu avları ve biyolojik engelleri devirmek için evrimleşmiş koçbaşı türü.",
		"lore_en": "A battering-ram species evolved to break armored prey and biological barriers.",
		"asset_folder": "gorehorn",
	},
	{
		"id": &"spore_matriarch", "name": "SPORE MATRIARCH", "universe": &"thornwild", "threat": "IV",
		"role_tr": "Zehirli bölge kontrolü / DoT destek", "role_en": "Toxic area control / DoT support",
		"behavior_tr": "Projectile'ları zeminde geniş zehir alanına dönüşür; alan tick hasarı ve süreli poison uygular.",
		"behavior_en": "Its projectiles become broad toxic ground zones that apply ticking damage and timed poison.",
		"tactic_tr": "Hasardan önce zemini oku. Zehir alanları rotanı kapatmadan güvenli koridor bırak.",
		"tactic_en": "Read the floor before focusing damage. Preserve an escape lane before toxic zones cut off your route.",
		"lore_tr": "Thornwild ekosisteminde spor dağıtan ve yeni habitat oluşturan çoğaltıcı kast.",
		"lore_en": "A reproductive caste that distributes spores and creates new habitat within the Thornwild ecosystem.",
		"asset_folder": "spore_matriarch",
	},
	{
		"id": &"vaskari_raptor", "name": "VASKARI RAPTOR", "universe": &"vaskari", "threat": "III",
		"role_tr": "Hızlı yakın taarruz birimi", "role_en": "Fast close-assault unit",
		"behavior_tr": "Yüksek takip temposu ve kısa saldırı döngüsüyle oyuncuya sürekli kapanır.",
		"behavior_en": "Maintains constant pressure through high pursuit tempo and short attack cycles.",
		"tactic_tr": "Raptor'u uzun süre serbest bırakma; sürekli baskısı diğer Vaskari rollerinin nişan almasını kolaylaştırır.",
		"tactic_en": "Do not leave a Raptor unchecked; its constant pressure creates clean firing opportunities for other Vaskari roles.",
		"lore_tr": "Lejyonun öncü hücum ve takip kastı.",
		"lore_en": "The Legion's vanguard assault and pursuit caste.",
		"asset_folder": "vaskari_raptor",
	},
	{
		"id": &"vaskari_ravager", "name": "VASKARI RAVAGER", "universe": &"vaskari", "threat": "IV",
		"role_tr": "Ağır yakın hücum varyantı", "role_en": "Heavy close-assault variant",
		"behavior_tr": "Raptor'dan daha yavaş takip eder fakat daha dayanıklı ve daha sert lunge saldırısı yapar.",
		"behavior_en": "Pursues more slowly than a Raptor but is tougher and delivers a much heavier lunge.",
		"tactic_tr": "Saldırı aralarındaki uzun açığı değerlendir. Lunge patlamasını normal takip hızıyla karıştırma.",
		"tactic_en": "Exploit its longer recovery windows. Do not confuse its lunge speed burst with its normal pursuit speed.",
		"lore_tr": "Savunma hattını fiziksel olarak kırmak için yetiştirilmiş ağır saldırı kastı.",
		"lore_en": "A heavy assault caste bred to physically break defensive lines.",
		"asset_folder": "vaskari_ravager",
	},
	{
		"id": &"coil_lancer", "name": "COIL LANCER", "universe": &"vaskari", "threat": "IV",
		"role_tr": "Uzun menzil nişancı", "role_en": "Long-range marksman",
		"behavior_tr": "Çok hızlı ve yüksek hasarlı projectile ile uzak çizgileri kapatır; yakın sıçrama saldırısı kullanmaz.",
		"behavior_en": "Controls long sightlines with a very fast high-damage projectile and has no close leap attack.",
		"tactic_tr": "Ön hat birimlerinden önce güvenli açı bulabiliyorsan Lancer'ı sustur. Uzun açık görüş hattı bırakma.",
		"tactic_en": "If a safe angle exists, suppress the Lancer before frontline units. Never gift it a long open sightline.",
		"lore_tr": "Lejyonun uzaktan hedef kıran atış/mızrak kastı.",
		"lore_en": "The Legion's long-range target-breaking lancer caste.",
		"asset_folder": "coil_lancer",
	},
	{
		"id": &"vaskari_bulwark", "name": "VASKARI BULWARK", "universe": &"vaskari", "threat": "IV",
		"role_tr": "Ağır ön hat tutucu", "role_en": "Heavy frontline holder",
		"behavior_tr": "Çok yüksek dayanıklılıkla ilerler ve ağır melee/lunge tehdidiyle alan kapatır.",
		"behavior_en": "Advances with very high durability and denies space through heavy melee/lunge pressure.",
		"tactic_tr": "Bulwark'ın gövdesine takılıp arka hattı unutma. Destek ve ranged Vaskari'leri önceliklendirmek çoğu zaman daha değerlidir.",
		"tactic_en": "Do not tunnel-vision its body and forget the backline. Prioritizing Vaskari support and ranged units is often more valuable.",
		"lore_tr": "Hücum kolunun ilerleme hattını koruyan kalın biyozırhlı kalkan kastı.",
		"lore_en": "A thick bio-armored shield caste that protects the advance of assault formations.",
		"asset_folder": "vaskari_bulwark",
	},
	{
		"id": &"venom_marshall", "name": "VENOM MARSHALL", "universe": &"vaskari", "threat": "V",
		"role_tr": "Komutan / ranged destek eliti", "role_en": "Commander / elite ranged support",
		"behavior_tr": "Ranged saldırıya ek olarak kendi çevresinde müttefikleri iyileştiren ve hasarlarını geçici yükselten destek alanı kurar.",
		"behavior_en": "Combines ranged attacks with a local support field that heals allies and temporarily increases their damage.",
		"tactic_tr": "Karışık Vaskari grubunda birincil hedeflerden biridir. Destek alanı aktifken savaşı uzatma.",
		"tactic_en": "It is a primary target in mixed Vaskari groups. Do not prolong the fight while its support field is active.",
		"lore_tr": "Küçük Vaskari saldırı kollarını sahada ayakta tutan komuta ve biyokimyasal destek kastı.",
		"lore_en": "A command and biochemical support caste that keeps small Vaskari assault groups operational in the field.",
		"asset_folder": "venom_marshall",
	},
	{
		"id": &"veilmaw", "name": "VEILMAW", "universe": &"nhal", "threat": "III",
		"role_tr": "Orta menzil harrier / görüş hattı avcısı", "role_en": "Mid-range harrier / sightline hunter",
		"behavior_tr": "Her atıştan sonra kısa reposition penceresiyle yeni görüş açısı arar ve orta mesafeyi korur.",
		"behavior_en": "Uses a brief reposition window after each shot to seek a new angle while maintaining mid range.",
		"tactic_tr": "Son gördüğün konuma ateş etmeye saplanma. Her atıştan sonra yeni açıyı kontrol et.",
		"tactic_en": "Do not commit to its last known position. Recheck angles after every shot.",
		"lore_tr": "Nhal av bölgelerinde açık hedefi uzaktan taciz eden çevik avcı formu.",
		"lore_en": "An agile hunting form that harasses exposed prey from range inside Nhal hunting grounds.",
		"asset_folder": "veilmaw",
	},
	{
		"id": &"husk_leech", "name": "HUSK LEECH", "universe": &"nhal", "threat": "III",
		"role_tr": "Algı bozucu ranged destek", "role_en": "Perception-disrupting ranged support",
		"behavior_tr": "Zehir/perde projectile isabeti oyuncunun görüşünü saniyeler boyunca animasyonlu toksik doku ile kaplar.",
		"behavior_en": "A poison/veil projectile covers the player's vision with animated toxic tissue for several seconds.",
		"tactic_tr": "Efekt aktifken paniğe kapılıp açık alana koşma. Son güvenli konumu ve ses bilgisini kullan.",
		"tactic_en": "Do not panic-run into open space while blinded. Rely on your last safe position and audio information.",
		"lore_tr": "Avın yön tayinini ve görsel algısını bozmak için kullanılan düşük kütleli parazit/perde canlısı.",
		"lore_en": "A low-mass parasitic veil organism used to disrupt prey orientation and visual perception.",
		"asset_folder": "husk_leech",
	},
	{
		"id": &"voidweaver", "name": "VOIDWEAVER", "universe": &"aether", "threat": "IV",
		"role_tr": "Havada süzülen enerji dokuyucusu", "role_en": "Hovering energy weaver",
		"behavior_tr": "Üç kollu enerji örgüsü atar; merkez projectile ana hasarı taşırken yan kollar geniş açı kapatır.",
		"behavior_en": "Fires a three-pronged energy weave; the center projectile carries the main damage while side arms cover a broad angle.",
		"tactic_tr": "Tek merkez mermi gibi davranma. Yan kolları hesaba katıp daha geniş kaçış payı bırak.",
		"tactic_en": "Do not treat it as a single center projectile. Account for the side arms and reserve a wider dodge lane.",
		"lore_tr": "Aether Loom'da yarık ve enerji akışlarını düzenleyen dokuyucu saha organizması.",
		"lore_en": "A field organism that weaves and regulates rift and energy flows within the Aether Loom.",
		"asset_folder": "voidweaver",
	},
	{
		"id": &"rift_reaver", "name": "RIFT REAVER", "universe": &"aether", "threat": "IV",
		"role_tr": "Hızlı yakın yarık avcısı", "role_en": "Fast close-range rift hunter",
		"behavior_tr": "Güvenli nokta doğrulanırsa saldırı öncesi oyuncunun çevresine kısa phase step yapar ve ardından lunge uygular.",
		"behavior_en": "If a safe point is validated, it performs a short phase step around the player before committing to a lunge.",
		"tactic_tr": "Phase hareketini noclip sanma; güvenli komşu alanlara bağlıdır. Yakın çevrendeki açık varış noktalarını kontrol et.",
		"tactic_en": "Its phase is not noclip and depends on safe adjacent space. Track viable arrival points around you.",
		"lore_tr": "Bozuk yarık örüntüsündeki yabancı maddeleri fiziksel olarak parçalamaya çalışan saldırı formu.",
		"lore_en": "An assault form that physically breaks foreign matter embedded in damaged rift patterns.",
		"asset_folder": "rift_reaver",
	},
]

const LOGS := [
	{
		"id": &"zero_source", "unlock_stage": 0,
		"title_tr": "SIFIR KAYNAK // KÖK KAYIT", "title_en": "ZERO SOURCE // ROOT RECORD",
		"body_tr": "Resmî kayıtlarda Sıfır Kaynak Reaktörü, yakıt tüketmeden sürekli enerji üreten stratejik temiz enerji projesi olarak tanımlanıyor. Son kapasite testinde birden fazla VEX tesisinde eşzamanlı kırılma yaşandı ve kalıcı yarıklar açıldı. İç teknik notlar reaktörün enerjiyi üretmediğini, bir yerden çektiğini söylüyor. Kaynağın ne olduğu henüz doğrulanmadı.",
		"body_en": "Official records describe the Zero Source Reactor as a strategic clean-energy project producing continuous power without fuel. During the final capacity test, several VEX facilities fractured simultaneously and persistent rifts opened. Internal technical notes state the reactor did not produce energy but drew it from somewhere. The source remains unverified.",
	},
	{
		"id": &"bastion", "unlock_stage": 0,
		"title_tr": "BASTION-7 // OPERASYON ÜSSÜ", "title_en": "BASTION-7 // OPERATIONS BASE",
		"body_tr": "Ana Yarık Ağı'ndan fiziksel olarak ayrılmış eski askerî sığınak. Doğrudan yarık darbesi almaması nedeniyle VEX karşı operasyonunun güvenli merkezi olarak kullanılıyor. Operasyon koordinasyonu Yüzbaşı Leyla Sönmez'de. Operasyon terminali görev çıkışlarını; ana terminal ise xenoarşiv ve ağ analizini yönetir.",
		"body_en": "An old military shelter physically isolated from the main Rift Network. Because it avoided a direct rift strike, it now serves as the secure center of the VEX counter-operation. Operations are coordinated by Captain Leyla Sönmez. The operations terminal handles deployment while the main terminal manages xeno-archive and network analysis.",
	},
	{
		"id": &"vex01", "unlock_stage": 1,
		"title_tr": "BÖLÜM 01 // İLK KIRILMA", "title_en": "CHAPTER 01 // FIRST FRACTURE",
		"body_tr": "Aras Koral felaketten dakikalar sonra bir VEX araştırma kompleksinin güvenlik odasında bilincini kazandı. Kamera 07 kaydı, Cinder Hound'ların laboratuvardan kaçmadığını, doğrudan açılan yarıktan geçtiğini gösterdi. Kurtarılan teknik not: ‘Enerji üretmiyoruz. Bir yerden çekiyoruz.’ Tesis dışında başka VEX noktalarından yükselen enerji sütunları görüldü; olay tek tesisle sınırlı değil. Aras acil durum protokolündeki Bastion-7'ye ulaştı ve Yüzbaşı Leyla Sönmez ile temas kurdu.",
		"body_en": "Aras Koral regained consciousness in the security room of a VEX research complex minutes after the disaster. Camera 07 showed that the Cinder Hounds did not escape a laboratory; they crossed directly through an opening rift. Recovered technical note: ‘We are not producing energy. We are drawing it from somewhere.’ Energy columns were seen rising from other VEX sites; the event is not limited to one facility. Aras reached Bastion-7 from the emergency protocol and made contact with Captain Leyla Sönmez.",
	},
	{
		"id": &"vex02", "unlock_stage": 2,
		"title_tr": "BÖLÜM 02 // KÜL KORİDORU", "title_en": "CHAPTER 02 // ASH CORRIDOR",
		"body_tr": "Bastion'ın dış iletişimi için eski aktarım rölesi yeniden çalıştırıldı. Servis tünellerinde Dünya jeolojisine ait olmayan bazalt oluşumları ve menzilli yeni bir form, Cinder Spitter, görüldü. Röle kayıtları Sıfır Kaynak'ın farklı frekanslarda enerji çektiğini ve KOR-TERMAL adlı bir dış kaynak imzasının yıllardır izlendiğini gösteriyor. Leyla aynı imzaya bağlı daha büyük bir yüksek basınç tesisinde hayatta kalan bir mühendisin sinyalini yakaladı: Dr. Selin Erdem.",
		"body_en": "The old transfer relay was restarted to restore Bastion's external communications. Basalt formations foreign to Earth's geology and a new ranged form, the Cinder Spitter, were seen in the service tunnels. Relay records show the Zero Source drawing energy on different frequencies and an external source signature named KOR-THERMAL being tracked for years. Leyla picked up a surviving engineer's signal from a larger high-pressure facility tied to the same signature: Dr. Selin Erdem.",
	},
	{
		"id": &"vex03", "unlock_stage": 3,
		"title_tr": "BÖLÜM 03 // BASINÇ HATTI", "title_en": "CHAPTER 03 // PRESSURE LINE",
		"body_tr": "Basınç Hattı arşivindeki Akış Modeli 7-C, KOR-TERMAL akışının doğal jeolojik gürültü değil düzenlenmiş bir sistem gibi davrandığını gösteriyor. Rapor 7-C bu bulguyu sınıflandırmış ve Dr. Selin Erdem'in test durdurma önerisini reddetmişti: VEX yönetimi akışın düzenli bir sisteme bağlı olduğunu kazadan aylar önce biliyordu. Selin kurtarılıp Bastion-7'ye katıldı. İlk analizine göre Yarık Ağı tek bir reaktörden oluşmuyor; farklı kaynak düğümleri ortak bir senkronizasyon sistemi kullanıyor.",
		"body_en": "Flow Model 7-C in the Pressure Line archive shows the KOR-THERMAL flow behaving like a regulated system rather than natural geological noise. Report 7-C classified this finding and rejected Dr. Selin Erdem's recommendation to halt testing: VEX leadership knew months before the disaster that the flow was tied to a regulated system. Selin was rescued and joined Bastion-7. Her first analysis shows the Rift Network is not a single reactor; separate source nodes share a common synchronization system.",
	},
]

const PROTOCOLS := [
	{
		"unlock_stage": 0,
		"title_tr": "SAHA TEMASI // XENO SINIFLANDIRMA", "title_en": "FIELD CONTACT // XENO CLASSIFICATION",
		"body_tr": "Yeni türle temas edildiğinde görsel aile, saldırı menzili, hareket paterni ve özel alan etkisi ayrı kaydedilir. Uygulanmamış bir yetenek arşive ‘mevcut’ olarak girilemez.",
		"body_en": "On first contact with a new species, visual family, attack range, movement pattern and special area effects are logged separately. An unimplemented ability may never be archived as an active capability.",
	},
	{
		"unlock_stage": 0,
		"title_tr": "YARIK TEMASI // GÜVENLİK", "title_en": "RIFT CONTACT // SAFETY",
		"body_tr": "Kalıcı yarıklar tesis arızası değil, Sıfır Kaynak akışına bağlı açık geçitlerdir. Yarık çevresindeki ani ısı ve basınç değişimleri yeni temasın habercisidir. Kaynak doğrulanmadan geçit bölgesinde tek başına ilerleme ve tam karantina ilan etme.",
		"body_en": "Persistent rifts are not facility faults; they are open passages tied to the Zero Source flow. Sudden heat and pressure changes around a rift herald new contact. Do not advance alone through a passage zone or declare full containment before its source is verified.",
	},
	{
		"unlock_stage": 11,
		"title_tr": "VASKARI TEMASI // ÖNCELİK MATRİSİ", "title_en": "VASKARI CONTACT // PRIORITY MATRIX",
		"body_tr": "Vaskari tehdidi tek birimin gücünden çok rol kombinasyonundan gelir. Komuta/destek ve uzun menzil birimleri güvenli biçimde erişilebiliyorsa öncelikli; ön hat yalnız seni kilitliyorsa önce hareket alanı aç.",
		"body_en": "Vaskari threat comes from role combinations more than individual strength. Prioritize command/support and ranged units when safely accessible; clear frontline space first only when movement is being locked down.",
	},
	{
		"unlock_stage": 18,
		"title_tr": "TOKSİK MARUZİYET // GÖRÜŞ KAYBI", "title_en": "TOXIC EXPOSURE // VISION LOSS",
		"body_tr": "Görüş bozulduğunda bilinmeyen alana sprint yasaktır. Son doğrulanmış güvenli konumu koru, ses bilgisini kullan ve efekt sona ermeden kapı/kenar geçişlerine körlemesine girme.",
		"body_en": "When vision is compromised, sprinting into unknown space is prohibited. Hold the last verified safe position, use audio information and avoid blind transitions through doors or ledges until the effect clears.",
	},
	{
		"unlock_stage": 23,
		"title_tr": "AETHER TEMASI // FAZ DOĞRULAMA", "title_en": "AETHER CONTACT // PHASE VALIDATION",
		"body_tr": "Kısa faz hareketleri sınırsız teleport değildir. VEX saha modeli varış zemini, yükseklik farkı ve fiziksel geçiş güvenliğini ayrı değerlendirir. Faz izi görüldüğünde çevredeki güvenli varış açılarını kontrol et.",
		"body_en": "Short phase movement is not unlimited teleportation. VEX field models validate arrival floor, height difference and physical traversal safety separately. When a phase trace appears, check safe arrival angles around your position.",
	},
]


static func get_universe(universe_id: StringName) -> Dictionary:
	for entry: Dictionary in UNIVERSES:
		if entry["id"] == universe_id:
			return entry
	return {}


static func get_enemy(enemy_id: StringName) -> Dictionary:
	for entry: Dictionary in ENEMIES:
		if entry["id"] == enemy_id:
			return entry
	return {}


static func get_enemy_ids_for_universe(universe_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var universe := get_universe(universe_id)
	if universe.is_empty():
		return result
	for value: StringName in universe.get("enemy_ids", []):
		result.append(value)
	return result


static func universe_name(universe: Dictionary) -> String:
	if not is_turkish() and universe.has("name_en"):
		return str(universe["name_en"])
	return str(universe.get("name", "UNKNOWN"))


static func is_universe_origin_revealed(universe: Dictionary, campaign_stage: int) -> bool:
	return campaign_stage >= int(universe.get("reveal_stage", 0))


## Köken/kaynak alanları hikâyede açıklandığı bölüme kadar geçici metinle gösterilir.
static func universe_story_text(universe: Dictionary, field: String, campaign_stage: int) -> String:
	if not is_universe_origin_revealed(universe, campaign_stage):
		var provisional := localized(universe, field + "_provisional")
		if not provisional.is_empty():
			return provisional
	return localized(universe, field)


static func enemy_lore(entry: Dictionary, campaign_stage: int) -> String:
	var universe := get_universe(StringName(str(entry.get("universe", ""))))
	if not universe.is_empty() and not is_universe_origin_revealed(universe, campaign_stage):
		return (
			"Kökendeki ekolojik ya da toplumsal rolü henüz doğrulanmadı. Kayıt yalnız gözlenen saha davranışına dayanıyor."
			if is_turkish()
			else "Its ecological or social role in its origin reality is unverified. This record relies only on observed field behavior."
		)
	return localized(entry, "lore")


static func entry_title(entry: Dictionary, fallback: String) -> String:
	var key := "title_tr" if is_turkish() else "title_en"
	return str(entry.get(key, entry.get("title", fallback)))


static func is_turkish() -> bool:
	return TranslationServer.get_locale().begins_with("tr")


static func localized(entry: Dictionary, field: String) -> String:
	return str(entry.get("%s_%s" % [field, "tr" if is_turkish() else "en"], ""))


static func enemy_sheet_path(entry: Dictionary) -> String:
	var folder := str(entry.get("asset_folder", ""))
	if folder.is_empty():
		return ""
	return "res://assets/enemies/%s/%s_character_spritesheet.png" % [folder, folder]


static func enemy_manifest_path(entry: Dictionary) -> String:
	var folder := str(entry.get("asset_folder", ""))
	if folder.is_empty():
		return ""
	return "res://assets/enemies/%s/%s_character_spritesheet_manifest.json" % [folder, folder]
