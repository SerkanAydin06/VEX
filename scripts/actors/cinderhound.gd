class_name VexCinderHound
extends "res://scripts/actors/enemy_lunge_performance_base.gd"

# Cinder Hound standart yakın dövüş/hamle ailesini kullanır. Türün hızlı takip
# ve kısa windup karakteri cinderhound.tscn Inspector verisidir.


func _die() -> void:
	# enemy_id yaratık türü kimliğidir ve tüm Cinder Hound örneklerinde
	# canonical olarak `cinderhound` kalır. GameState eski discovery uyumluluğu
	# nedeniyle aynı tür kimliğini yalnız ilk ölümde saydığı için sonraki fiziksel
	# Hound ölümlerini anonim kill olarak ayrıca sayarız. Arşiv discovery'si boş
	# kimliği zaten yok sayar; species kimliği encounter kimliğine dönüşmez.
	var species_was_already_discovered := GameState.was_enemy_defeated(enemy_id)
	super._die()
	if species_was_already_discovered:
		GameState.register_enemy_defeated()
