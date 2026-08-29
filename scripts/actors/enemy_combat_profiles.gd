class_name VexEnemyCombatProfiles
extends RefCounted

# Ortak yapay zekâ yalnızca taktik rol sınıflandırmasını paylaşır.
# Hareket, algı, navigasyon ve saldırı değerleri yaratık sahnesinin
# Inspector ayarlarından gelir; burada gizli davranış varsayılanı tutulmaz.
enum Role {
	CLOSE,
	MID,
	LONG,
}
