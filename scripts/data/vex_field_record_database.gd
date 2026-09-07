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
