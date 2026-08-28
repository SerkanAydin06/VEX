from pathlib import Path

path = Path("scripts/actors/ravager.gd")
s = path.read_text(encoding="utf-8")

old = """\t\telif _uses_ranged_tactics() and _last_visibility_ratio < ranged_cover_visibility_threshold:\n\t\t\t# Atış bittikten sonra oyuncu yalnız duvar/kapı kenarından görünüyorsa\n\t\t\t# cooldown boyunca kule gibi bekleme; daha açık bir atış açısı ara.\n\t\t\t_reposition_for_clear_shot(delta)\n"""
new = """\t\telif _uses_cover_reposition_tactics() and _last_visibility_ratio < ranged_cover_visibility_threshold:\n\t\t\t# Yalnız gerçek projectile shooter'lar kısmi görüşte yan/çapraz atış açısı arar.\n\t\t\t# Warden gibi geniş attack_range kullanan yakın baskı elitleri burada strafe etmez.\n\t\t\t_reposition_for_clear_shot(delta)\n"""
if old not in s:
    raise SystemExit("attack recovery cover block not found")
s = s.replace(old, new, 1)

old = """\t\tif _uses_ranged_tactics() and _last_visibility_ratio < ranged_cover_visibility_threshold:\n\t\t\tstate = State.CHASE\n\t\t\t_reposition_for_clear_shot(delta)\n\t\t\treturn\n"""
new = """\t\tif _uses_cover_reposition_tactics() and _last_visibility_ratio < ranged_cover_visibility_threshold:\n\t\t\tstate = State.CHASE\n\t\t\t_reposition_for_clear_shot(delta)\n\t\t\treturn\n"""
if old not in s:
    raise SystemExit("visible cover block not found")
s = s.replace(old, new, 1)

old = """func _uses_ranged_tactics() -> bool:\n\treturn projectile_scene != null or attack_range >= 4.0\n\n\nfunc _damage_source_approach_position"""
new = """func _uses_ranged_tactics() -> bool:\n\t# Geniş menzil, oyuncunun kısmen görünür olduğu durumlarda çoklu LOS örneklemesi\n\t# için yeterlidir; fakat tek başına düşmanın cover-strafe yapan bir shooter olduğu\n\t# anlamına gelmez.\n\treturn projectile_scene != null or attack_range >= 4.0\n\n\nfunc _uses_cover_reposition_tactics() -> bool:\n\t# Rastgele sağ/sol/çapraz atış pozisyonu yalnız gerçek projectile shooter'larda\n\t# kullanılmalı. Warden kendi yakın/orta menzil baskı saldırılarına sahip ve\n\t# projectile_scene kullanmadığı için chase/navigation davranışında kalır.\n\treturn projectile_scene != null\n\n\nfunc _damage_source_approach_position"""
if old not in s:
    raise SystemExit("ranged tactics helper anchor not found")
s = s.replace(old, new, 1)

path.write_text(s, encoding="utf-8")
