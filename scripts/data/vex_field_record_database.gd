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
		"id": &"vex02_thermal_transfer_delta",
		"order": 4,
		"chapter": 2,
		"room": "R08",
		"category_tr": "TEKNİK // TRANSFER HATTI",
		"category_en": "TECHNICAL // TRANSFER LINE",
		"title_tr": "TERMAL TRANSFER // DELTA HATTI",
		"title_en": "THERMAL TRANSFER // DELTA LINE",
		"body_tr": "DELTA HATTI // EŞZAMANLI ÖLÇÜM\n\nYerel reaktör çıkışı yükselirken karşı taraftaki kabuk sıcaklığı aynı zaman aralığında düşüyor. Isı burada üretilmiyor; iki sistem arasında zorlanmış olarak taşınıyor.\n\nKül Koridoru ana üretim bölmesi değil. Uzak kaynaktan çekilen termal ve basınç enerjisinin Zero Source omurgasına aktarıldığı bir transfer hattı.",
		"body_en": "DELTA LINE // SYNCHRONIZED MEASUREMENT\n\nAs local reactor output rises, crust temperature on the far side falls during the same interval. Heat is not being generated here; it is being forcibly moved between two systems.\n\nThe Ash Corridor is not a primary generation chamber. It is a transfer line feeding thermal and pressure energy drawn from a remote source into the Zero Source backbone.",
	},
	{
		"id": &"vex02_spitter_contact_report",
		"order": 5,
		"chapter": 2,
		"room": "R19",
		"category_tr": "XENO // GÜVENLİK",
		"category_en": "XENO // SECURITY",
		"title_tr": "SPITTER TEMAS RAPORU",
		"title_en": "SPITTER CONTACT REPORT",
		"body_tr": "GÜVENLİK GÖZLEMİ // YENİ FORM\n\nİkinci Korvath formu sıcak transfer hatlarının çevresinde görüldü. Cinder Hound gibi doğrudan kovalamıyor; mesafeyi koruyup uzaktan sıcak madde püskürtüyor ve hareket koridorlarını baskı altında tutuyor.\n\nDavranış, planlı bir işgal birliğinden çok bozulmuş endüstriyel bir ekolojinin savunma tepkisine benziyor. Kaynak gerçekliğin altyapısıyla biyolojisi birbirinden ayrı olmayabilir.",
		"body_en": "SECURITY OBSERVATION // NEW FORM\n\nA second Korvath form was observed around hot transfer lines. Unlike the Cinder Hound it does not rely on direct pursuit; it maintains distance, ejects heated matter from range and pressures movement lanes.\n\nThe behavior resembles a defensive response from a damaged industrial ecology more than a planned invasion force. Biology and infrastructure in the source reality may not be separate systems.",
	},
	{
		"id": &"vex02_source_world_pressure_loss",
		"order": 6,
		"chapter": 2,
		"room": "R27",
		"category_tr": "YÖNETİM // SINIFLANDIRILMIŞ",
		"category_en": "EXECUTIVE // CLASSIFIED",
		"title_tr": "KAYNAK DÜNYA // BASINÇ KAYBI",
		"title_en": "SOURCE WORLD // PRESSURE LOSS",
		"body_tr": "KRV-TH KAYNAK PROFİLİ // YÖNETİM KOPYASI\n\nUzak jeolojik sistemde basınç düşüşü güvenlik sınırını geçti. Yerel verim aynı dönemde yüzde 21 arttı. Transferi azaltma önerisi reddedildi; sonraki test penceresi için çekim kotası yükseltildi.\n\nİç etiket: KRV-TH / KORVATH OCAĞI.\n\nNot: Karşı taraftaki yapısal çöküş artık model hatası olarak sınıflandırılamaz. Yönetim kaybı biliyor ve çekimi sürdürüyordu.",
		"body_en": "KRV-TH SOURCE PROFILE // EXECUTIVE COPY\n\nPressure loss in the remote geological system exceeded the safety threshold. Local yield increased by 21 percent during the same period. A proposal to reduce transfer was rejected; the extraction quota was raised for the next test window.\n\nInternal tag: KRV-TH / KORVATH FORGE.\n\nNote: Structural collapse on the far side can no longer be classified as model error. Management knew the cost and continued extraction.",
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
