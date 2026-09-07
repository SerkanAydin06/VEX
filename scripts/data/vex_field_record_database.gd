class_name VexFieldRecordDatabase
extends RefCounted

const TOTAL_CAMPAIGN_RECORDS := 90

# Saha kayıtlarının kalıcı arşiv kaynağı. Bölüm sahneleri fiziksel terminal
# yerleşimini ve sunumunu taşır; burada ise Bastion-7 ana terminalinde tekrar
# okunabilmesi için kanonik kayıt metni ve sıralama bilgisi tutulur.
const RECORDS := [
	{
		"id": &"vex01_emergency_test_order_0417",
		"order": 1,
		"chapter": 1,
		"room": "R03",
		"category_tr": "OLAY",
		"category_en": "INCIDENT",
		"title_tr": "ACİL TEST EMRİ / 04:17",
		"title_en": "EMERGENCY TEST ORDER / 04:17",
		"body_tr": "ZERO SOURCE // TEST EMRİ 04:17\n\nÇekim kapasitesi %18 artırıldı. Emniyet ekibinin kararlılık itirazı yönetim yetkisiyle geçersiz kılındı. Eşzamanlı saha düğümleri aynı test penceresine bağlandı.\n\nNOT: Dalgalanma görülürse yerel reaktör kapatılmayacak; ağ senkronizasyonu korunacak.",
		"body_en": "ZERO SOURCE // TEST ORDER 04:17\n\nExtraction capacity increased by 18%. The safety team's stability objection was overridden by executive authorization. Synchronized field nodes were tied to the same test window.\n\nNOTE: If oscillation occurs, do not shut down the local reactor; preserve network synchronization.",
	},
	{
		"id": &"vex01_security_camera_07",
		"order": 2,
		"chapter": 1,
		"room": "R17",
		"category_tr": "PERSONEL // GÜVENLİK",
		"category_en": "PERSONNEL // SECURITY",
		"title_tr": "GÜVENLİK KAMERASI 07",
		"title_en": "SECURITY CAMERA 07",
		"body_tr": "KAMERA 07 // KARANTİNA KORİDORU\n\n04:22:11 — Koridorda canlı temas yok.\n04:22:13 — Duvar yüzeyinde termal bozulma.\n04:22:14 — Kısa süreli yarık oluşumu.\n04:22:15 — Bilinmeyen organizma doğrudan yarıktan tesise geçiyor.\n\nGüvenlik notu: Numune kafeslerinde kırılma kaydı yok. Temas laboratuvardan kaçmadı.",
		"body_en": "CAMERA 07 // QUARANTINE CORRIDOR\n\n04:22:11 — No biological contact in corridor.\n04:22:13 — Thermal distortion on wall surface.\n04:22:14 — Short-lived rift formation.\n04:22:15 — Unknown organism crosses directly through the rift into the facility.\n\nSecurity note: No sample cage breach recorded. The contact did not escape from the laboratory.",
	},
	{
		"id": &"vex01_we_do_not_produce_energy",
		"order": 3,
		"chapter": 1,
		"room": "R29",
		"category_tr": "TEKNİK // SINIFLANDIRILMIŞ",
		"category_en": "TECHNICAL // CLASSIFIED",
		"title_tr": "ENERJİ ÜRETMİYORUZ",
		"title_en": "WE ARE NOT PRODUCING ENERGY",
		"body_tr": "ZERO SOURCE // DAHİLİ TEKNİK NOT\n\nReaktör verisi artık termodinamik açıklamalarla uyuşmuyor. Çıkış, yerel sisteme giren hammaddeden büyük. Kaynak içeride değil.\n\nEnerji üretmiyoruz. Bir yerden çekiyoruz.\n\nYarık kısa süreli değil; ağ onu açık tutuyor. Yönetim bu ayrımı aylardır biliyor olabilir.",
		"body_en": "ZERO SOURCE // INTERNAL TECHNICAL NOTE\n\nReactor data no longer matches thermodynamic explanations. Output exceeds the material entering the local system. The source is not inside the facility.\n\nWe are not producing energy. We are drawing it from somewhere.\n\nThe rift is not momentary; the network is holding it open. Management may have known this distinction for months.",
	},
	{
		"id": &"vex02_kor_thermal_source_signature",
		"order": 4,
		"chapter": 2,
		"room": "R33",
		"category_tr": "TEKNİK // RÖLE",
		"category_en": "TECHNICAL // RELAY",
		"title_tr": "KOR-TERMAL KAYNAK İMZASI",
		"title_en": "KOR-THERMAL SOURCE SIGNATURE",
		"body_tr": "BASTION RÖLE HATTI // OTOMATİK SPEKTRUM KAYDI\n\nKOR-TERMAL frekansı yeniden yakalandı. İmza rastgele bir yarık paraziti değil; aynı faz aralığında düzenli olarak tekrar ediyor ve termal transfer yükseldiğinde güçleniyor.\n\nArşiv eşleşmesi: VEX bu dış kaynak frekansını kazadan yıllar önce ayrı bir ölçüm sınıfı olarak izlemeye başlamış. Kaynak konumu hâlâ çözülemiyor.",
		"body_en": "BASTION RELAY LINE // AUTOMATED SPECTRUM RECORD\n\nThe KOR-THERMAL frequency has been reacquired. The signature is not random rift noise; it repeats inside the same phase interval and strengthens as thermal transfer rises.\n\nArchive match: VEX began tracking this external source frequency as a separate measurement class years before the disaster. The source location is still unresolved.",
	},
	{
		"id": &"vex02_relay_technician_last_shift",
		"order": 5,
		"chapter": 2,
		"room": "R19",
		"category_tr": "PERSONEL // SERVİS",
		"category_en": "PERSONNEL // SERVICE",
		"title_tr": "RÖLE TEKNİSYENİ / SON VARDİYA",
		"title_en": "RELAY TECHNICIAN / LAST SHIFT",
		"body_tr": "VARDİYA NOTU // SERVİS HATTI\n\nRöle üç kez kendi kendine yeniden başlatıldı. Batı hattında güç düşüyor ama sensörler aşırı ısı okuyor. Koridordaki metal kapakların arkasından tıklama ve basınç sesi geliyor.\n\nGüvenlik birimi bunun boru genleşmesi olduğunu söyledi. Son kontrolde ilk kez uzaktan sıcak madde püskürten bir canlı gördüm. Eğer bu kayıt çıkarsa röleyi kapatın ve hattı boşaltın.",
		"body_en": "SHIFT NOTE // SERVICE LINE\n\nThe relay restarted itself three times. Power is dropping on the west line while the sensors report extreme heat. Clicking and pressure noise is coming from behind the metal service panels.\n\nSecurity said it was pipe expansion. During the last inspection I saw a living form eject heated matter from range. If this record gets out, shut the relay down and clear the line.",
	},
	{
		"id": &"vex02_pressure_deviation_insignificant",
		"order": 6,
		"chapter": 2,
		"room": "R27",
		"category_tr": "YÖNETİM // SINIFLANDIRILMIŞ",
		"category_en": "EXECUTIVE // CLASSIFIED",
		"title_tr": "BASINÇ SAPMASI ÖNEMSİZDİR",
		"title_en": "PRESSURE DEVIATION IS INSIGNIFICANT",
		"body_tr": "KOR-TERMAL // YÖNETİM DEĞERLENDİRMESİ\n\nDış kaynak ölçümünde tekrar eden basınç sapması doğrulandı. Sapma, yerel enerji verimini etkileyen bir risk olarak sınıflandırılmayacak. KOR-TERMAL takibi devam edecek; üretim raporlarında kaynak tarafı değişimleri ayrı tutulacaktır.\n\nEk not: Teknik ekibin transfer azaltma talebi operasyon öncelikleriyle uyumlu değildir. Frekans kararlı kaldığı sürece çekim kotası değiştirilmeyecek.",
		"body_en": "KOR-THERMAL // EXECUTIVE ASSESSMENT\n\nA repeating pressure deviation in the external source measurement has been confirmed. The deviation will not be classified as a risk to local energy yield. KOR-THERMAL monitoring will continue; source-side changes are to remain separate from production reports.\n\nAddendum: The technical team's request to reduce transfer is not aligned with operational priorities. Extraction quotas will remain unchanged while the frequency stays stable.",
	},
	{
		"id": &"vex03_regulated_geothermal_flow",
		"order": 7,
		"chapter": 3,
		"room": "L03",
		"category_tr": "TEKNİK // AKIŞ ANALİZİ",
		"category_en": "TECHNICAL // FLOW ANALYSIS",
		"title_tr": "DÜZENLENMİŞ JEOTERMAL AKIŞ",
		"title_en": "REGULATED GEOTHERMAL FLOW",
		"body_tr": "KOR-TERMAL // AKIŞ MODELİ 7-C\n\nKaynak tarafındaki sıcaklık ve basınç salınımları doğal jeolojik gürültüyle uyuşmuyor. Darbeler sabit aralıklarla düşüyor, ardından sistem kendi basıncını yeniden dengeliyor. Bu davranış kontrol vanası veya yük dengeleme ağına benziyor.\n\nÖn değerlendirme: Enerji boş bir jeolojik cepten gelmiyor olabilir. Karşı tarafta düzenlenen bir altyapı sistemi bulunma olasılığı araştırılmalıdır.",
		"body_en": "KOR-THERMAL // FLOW MODEL 7-C\n\nTemperature and pressure oscillations on the source side do not match natural geological noise. Pulses fall at fixed intervals, followed by active pressure rebalancing. The behavior resembles a control valve or load-balancing network.\n\nPreliminary assessment: The energy may not be coming from an empty geological pocket. The possibility of regulated infrastructure on the far side should be investigated.",
	},
	{
		"id": &"vex03_selin_erdem_objection_draft",
		"order": 8,
		"chapter": 3,
		"room": "U06",
		"category_tr": "PERSONEL // SELİN ERDEM",
		"category_en": "PERSONNEL // SELIN ERDEM",
		"title_tr": "SELİN ERDEM / İTİRAZ TASLAĞI",
		"title_en": "SELIN ERDEM / OBJECTION DRAFT",
		"body_tr": "GÖNDERİLMEMİŞ TASLAK // DR. SELİN ERDEM\n\nKOR-TERMAL akışı dış müdahaleye tepki veriyor. Çekim arttığında karşı sistem önce basınç kaybediyor, sonra farklı bir hat üzerinden denge kuruyor. Doğal bir rezervuar böyle davranmaz.\n\nYeni testleri durdurmamız gerekiyor. Kaynağın düzenlenmiş olması, karşı tarafta bunu düzenleyen bir sistem — ve muhtemelen onu kullanan bir yaşam düzeni — bulunduğu anlamına gelebilir. Bu ihtimali üretim hedeflerinden ayrı değerlendiremeyiz.",
		"body_en": "UNSENT DRAFT // DR. SELIN ERDEM\n\nThe KOR-THERMAL flow responds to external intervention. When extraction rises, the far system loses pressure, then compensates through a different line. A natural reservoir does not behave like this.\n\nWe need to stop the new tests. A regulated source implies a regulating system on the far side — and possibly a living order that depends on it. We cannot separate that possibility from production targets.",
	},
	{
		"id": &"vex03_report_7c_classified",
		"order": 9,
		"chapter": 3,
		"room": "U04",
		"category_tr": "YÖNETİM // 7-C",
		"category_en": "EXECUTIVE // 7-C",
		"title_tr": "RAPOR 7-C SINIFLANDIRILDI",
		"title_en": "REPORT 7-C CLASSIFIED",
		"body_tr": "YÖNETİM KARARI // RAPOR 7-C\n\n'Düzenlenmiş kaynak altyapısı' değerlendirmesi doğrulanmış bulgu olarak kabul edilmeyecektir. İlgili akış anomalileri operasyon raporlarından çıkarılacak ve yalnız Zero Source yönetim arşivinde tutulacaktır.\n\nDr. Selin Erdem'in test durdurma önerisi reddedildi. KOR-TERMAL verimi hedef aralıkta kaldığı sürece çekim programı değiştirilmeyecektir.",
		"body_en": "EXECUTIVE DECISION // REPORT 7-C\n\nThe 'regulated source infrastructure' assessment will not be treated as a confirmed finding. Related flow anomalies are to be removed from operational reports and retained only in the Zero Source executive archive.\n\nDr. Selin Erdem's recommendation to halt testing was rejected. The extraction schedule will remain unchanged while KOR-THERMAL yield stays within target range.",
	},
]


static func get_record(record_id: StringName) -> Dictionary:
	for entry: Dictionary in RECORDS:
		if StringName(str(entry.get("id", ""))) == record_id:
			return entry
	return {}


static func has_record(record_id: StringName) -> bool:
	return not get_record(record_id).is_empty()


static func get_records_for_chapter(chapter: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in RECORDS:
		if int(entry.get("chapter", 0)) == chapter:
			result.append(entry)
	result.sort_custom(_record_order_less)
	return result


static func localized(entry: Dictionary, field: String) -> String:
	var suffix := "_tr" if TranslationServer.get_locale().begins_with("tr") else "_en"
	return str(entry.get(field + suffix, entry.get(field, "")))


static func _record_order_less(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("order", 0)) < int(b.get("order", 0))
