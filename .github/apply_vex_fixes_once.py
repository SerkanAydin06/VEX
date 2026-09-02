from pathlib import Path
import re

ROOT = Path(".")


def replace_once(path: str, old: str, new: str) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old!r}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


# Reload timers obey SceneTree pause.
replace_once(
    "scripts/player/weapon_controller.gd",
    'await get_tree().create_timer(weapon.reload_duration * float(_modifiers(weapon).reload)).timeout',
    'await get_tree().create_timer(weapon.reload_duration * float(_modifiers(weapon).reload), false).timeout',
)
replace_once(
    "scripts/player/weapon_controller.gd",
    'await get_tree().create_timer(shell_cycle_duration).timeout',
    'await get_tree().create_timer(shell_cycle_duration, false).timeout',
)
replace_once(
    "scripts/player/weapon_controller.gd",
    'await get_tree().create_timer(finish_duration).timeout',
    'await get_tree().create_timer(finish_duration, false).timeout',
)

# Player canonical default.
replace_once(
    "scripts/player/player.gd",
    '@export_range(1, 500, 1) var maximum_health := 10000000',
    '@export_range(1, 500, 1) var maximum_health := 100',
)

# Full-health restart uses live player maximum.
replace_once(
    "scripts/autoload/game_state.gd",
    '\tpending_player_restore_state = current_level_start_state.duplicate(true)\n\tpending_player_restore_state["health"] = 100 if _restore_full_health else int(pending_player_restore_state.get("health", 100))',
    '\tpending_player_restore_state = current_level_start_state.duplicate(true)\n\tvar restart_health := int(pending_player_restore_state.get("health", 100))\n\tif _restore_full_health and player != null and is_instance_valid(player):\n\t\trestart_health = int(player.get("maximum_health"))\n\tpending_player_restore_state["health"] = restart_health',
)

# Ignore input held through scene transition before briefing starts.
replace_once(
    "scripts/levels/base_level.gd",
    '\n\tawait get_tree().create_timer(briefing_start_delay, true, false, true).timeout\n\tawait _type_text(story, briefing_character_delay)',
    '\n\t# Scene değişiminden taşınan basılı hareket/ateş girdisini yeni bir briefing\n\t# basışı sayma. Oyuncu önce tuşu bırakmalı; sonraki basış normal şekilde işler.\n\tawait _wait_for_continue_release()\n\tawait get_tree().create_timer(briefing_start_delay, true, false, true).timeout\n\tawait _type_text(story, briefing_character_delay)',
)

# Canonical enemy documentation sync.
replace_once(
    "Enemies_VEX.md",
    "| Bireysel rol farkı | Aynı evrendeki 4 yaratığın birbirinden nasıl ayrıldığı |",
    "| Bireysel rol farkı | Aynı evrendeki yaratıkların birbirinden nasıl ayrıldığı |",
)
replace_once(
    "Enemies_VEX.md",
    "| 2 | **Thornwild Sürüsü** | Kas, kemik, yırtıcılık, sürü baskısı ve biyolojik avcılık | Ravager, Briar Skulker |",
    "| 2 | **Thornwild Sürüsü** | Kas, kemik, yırtıcılık, sürü baskısı ve biyolojik avcılık | Ravager, Briar Skulker, Gorehorn, Spore Matriarch |",
)
replace_once(
    "Enemies_VEX.md",
    "| 3 | **Vaskari Lejyonu** | Disiplinli savaş kastı, zehir, biyozırh ve saldırı düzeni | RedViper, BadRedViper |",
    "| 3 | **Vaskari Lejyonu** | Disiplinli savaş kastı, zehir, biyozırh ve saldırı düzeni | RedViper, BadRedViper, Coil Lancer, Vaskari Bulwark, Venom Marshall |",
)
replace_once(
    "Enemies_VEX.md",
    "### 4. Spore Matriarch\n\n**Durum:** Planlandı",
    "### 4. Spore Matriarch\n\n**Durum:** Mevcut",
)
replace_once("Enemies_VEX.md", "## 6.3 Dört yaratık", "## 6.3 Beş yaratık")
replace_once(
    "Enemies_VEX.md",
    "### 3. Coil Lancer\n\n**Durum:** Planlandı",
    "### 3. Coil Lancer\n\n**Durum:** Mevcut",
)

venom_old = '''### 4. Venom Marshal

**Durum:** Planlandı

- **Rol:** Komutan / aura destekli elit
- **Hikâye rolü:** Küçük Vaskari saldırı kollarını sahada yöneten subay kastı.
- **Savaş kimliği:** Yakındaki Vaskari yaratıklara hız ve saldırı cesareti verir; oyuncuyu sürekli yer değiştirmeye zorlar.
- **Ayırt edici özellik:** Tek başına çok tehlikeli olmak yerine grubu ölümcül hale getirir.'''
venom_new = '''### 4. Vaskari Bulwark

**Durum:** Mevcut

- **Rol:** Ağır yakın menzil baskı / ön hat tutucu
- **Hikâye rolü:** Vaskari hücum kollarında ilerleme hattını koruyan kalın biyozırhlı kırma kastı.
- **Savaş kimliği:** Yavaş yaklaşır, yüksek dayanıklılıkla alan kapatır ve kısa lunge ile ağır yakın darbe uygular.
- **Ayırt edici özellik:** RedViper ailesinin hız baskısını tersine çevirir; süratten çok dayanıklılık ve tek darbe tehdidiyle alan kazanır.

### 5. Venom Marshall

**Durum:** Mevcut

- **Rol:** Komutan / menzilli destek eliti
- **Hikâye rolü:** Küçük Vaskari saldırı kollarını sahada yöneten subay kastı.
- **Savaş kimliği:** Normal menzilli saldırısına ek olarak yakındaki uygun müttefik kümelerine güçlendirme alanı gönderir ve savaş hattını destekler.
- **Ayırt edici özellik:** Tek başına salt hasar tehdidi olmak yerine takımın dayanıklılığını ve baskısını yükselten öncelikli destek hedefidir.'''
replace_once("Enemies_VEX.md", venom_old, venom_new)
replace_once(
    "Enemies_VEX.md",
    "| Gorehorn | Thornwild Sürüsü | Orta-ağır şarj ve ritim bozma birimi |\n| RedViper | Vaskari Lejyonu | Hızlı elit hücum birimi |",
    "| Gorehorn | Thornwild Sürüsü | Orta-ağır şarj ve ritim bozma birimi |\n| Spore Matriarch | Thornwild Sürüsü | Zehir ve bölge kontrolü destek birimi |\n| RedViper | Vaskari Lejyonu | Hızlı elit hücum birimi |",
)
replace_once(
    "Enemies_VEX.md",
    "| BadRedViper | Vaskari Lejyonu | Ağır hücum varyantı |\n| Veilmaw | Nhal Veil | Pusu avcısı |",
    "| BadRedViper | Vaskari Lejyonu | Ağır hücum varyantı |\n| Coil Lancer | Vaskari Lejyonu | Orta menzilli çizgisel baskı birimi |\n| Vaskari Bulwark | Vaskari Lejyonu | Ağır yakın menzil ön hat birimi |\n| Venom Marshall | Vaskari Lejyonu | Menzilli destek ve müttefik güçlendirme birimi |\n| Veilmaw | Nhal Veil | Pusu avcısı |",
)

# Runtime regression for standard and SG-04 reloads.
test_gd = r'''extends Node

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := PLAYER_SCENE.instantiate() as VexPlayer
	assert(player != null)
	add_child(player)
	await get_tree().process_frame

	var controller := player.weapon_controller as VexWeaponController
	assert(controller != null)
	await _test_standard_reload_pause(controller)
	await _test_sg04_reload_pause(controller)

	get_tree().paused = false
	player.free()
	for _frame: int in range(3):
		await get_tree().process_frame
	print("Weapon pause reload runtime test passed")
	get_tree().quit(0)


func _test_standard_reload_pause(controller: VexWeaponController) -> void:
	var weapon := controller.get_weapon_definition(&"p01")
	assert(weapon != null)
	var original_duration := weapon.reload_duration
	weapon.reload_duration = 0.10
	controller.current_weapon_id = &"p01"
	controller.magazines[&"p01"] = 0
	controller.reserve_ammo[weapon.ammo_type] = 3
	controller.reload()
	assert(controller.is_reloading)

	get_tree().paused = true
	await get_tree().create_timer(0.22, true).timeout
	assert(controller.is_reloading)
	assert(int(controller.magazines.get(&"p01", -1)) == 0)

	get_tree().paused = false
	await get_tree().create_timer(0.18, true).timeout
	assert(not controller.is_reloading)
	assert(int(controller.magazines.get(&"p01", 0)) > 0)
	weapon.reload_duration = original_duration


func _test_sg04_reload_pause(controller: VexWeaponController) -> void:
	var weapon := controller.get_weapon_definition(&"sg04")
	assert(weapon != null)
	var original_duration := weapon.reload_duration
	weapon.reload_duration = 0.12
	if not controller.unlocked_weapons.has(&"sg04"):
		controller.unlocked_weapons.append(&"sg04")
	controller.current_weapon_id = &"sg04"
	controller.magazines[&"sg04"] = 0
	controller.reserve_ammo[weapon.ammo_type] = 1
	controller.reload()
	assert(controller.is_reloading)

	get_tree().paused = true
	await get_tree().create_timer(0.22, true).timeout
	assert(controller.is_reloading)
	assert(int(controller.magazines.get(&"sg04", -1)) == 0)

	get_tree().paused = false
	await get_tree().create_timer(0.24, true).timeout
	assert(not controller.is_reloading)
	assert(int(controller.magazines.get(&"sg04", 0)) == 1)
	weapon.reload_duration = original_duration
'''
(ROOT / "tests/weapon_pause_reload_runtime_test.gd").write_text(test_gd, encoding="utf-8")
(ROOT / "tests/weapon_pause_reload_runtime_test.tscn").write_text(
    '[gd_scene format=3]\n\n'
    '[ext_resource type="Script" path="res://tests/weapon_pause_reload_runtime_test.gd" id="1_script"]\n\n'
    '[node name="WeaponPauseReloadRuntimeTest" type="Node"]\n'
    'process_mode = 3\n'
    'script = ExtResource("1_script")\n',
    encoding="utf-8",
)

# Static regression contracts.
static_path = ROOT / "tests/static_audit.py"
static = static_path.read_text(encoding="utf-8")
old_core = '"project.godot", "README.md", "STANDART.txt", "Story_VEX.md",\n'
new_core = '"project.godot", "README.md", "STANDART.txt", "Story_VEX.md",\n        "Weapons_VEX.md", "Enemies_VEX.md",\n'
if static.count(old_core) != 1:
    raise SystemExit("static_audit.py: core docs anchor changed")
static = static.replace(old_core, new_core, 1)

anchor = "\ndef check_stale_contracts() -> None:\n"
if static.count(anchor) != 1:
    raise SystemExit("static_audit.py: stale contract anchor changed")
new_checks = r'''
def check_player_gameplay_regressions() -> None:
    player = read("scripts/player/player.gd")
    weapon = read("scripts/player/weapon_controller.gd")
    game_state = read("scripts/autoload/game_state.gd")
    base_level = read("scripts/levels/base_level.gd")
    workflow = read(".github/workflows/validate.yml")
    if '@export_range(1, 500, 1) var maximum_health := 100' not in player:
        fail("Player canonical maximum_health default 100 değil")
    if "maximum_health := 10000000" in player:
        fail("Player debug maximum_health default'u geri gelmiş")
    for contract in [
        'create_timer(weapon.reload_duration * float(_modifiers(weapon).reload), false)',
        'create_timer(shell_cycle_duration, false)',
        'create_timer(finish_duration, false)',
    ]:
        if contract not in weapon:
            fail(f"Pause-aware reload sözleşmesi eksik: {contract}")
    if 'pending_player_restore_state["health"] = 100 if _restore_full_health' in game_state:
        fail("Restart full-health hâlâ 100'e hardcode")
    if 'restart_health = int(player.get("maximum_health"))' not in game_state:
        fail("Restart full-health canlı player maximum_health değerini kullanmıyor")
    if "Scene değişiminden taşınan basılı hareket/ateş girdisini" not in base_level:
        fail("Briefing held-input geçiş koruması eksik")
    for relative in [
        "tests/weapon_pause_reload_runtime_test.gd",
        "tests/weapon_pause_reload_runtime_test.tscn",
    ]:
        exists(relative)
    if "Run weapon pause reload runtime regression" not in workflow:
        fail("Weapon pause/reload runtime regression CI'a bağlı değil")


def check_canonical_documentation() -> None:
    enemies = read("Enemies_VEX.md")
    for name in ["Spore Matriarch", "Coil Lancer", "Vaskari Bulwark", "Venom Marshall"]:
        pattern = rf"^### \d+\. {re.escape(name)}\n\n\*\*Durum:\*\* Mevcut$"
        if re.search(pattern, enemies, re.M) is None:
            fail(f"Enemies_VEX canonical durum drift'i: {name} Mevcut değil")
    if re.search(r"^### \d+\. Venom Marshal$", enemies, re.M):
        fail("Eski Venom Marshal adı canonical belgede geri gelmiş")
    for actor in ["coil_lancer", "spore_matriarch", "vaskari_bulwark", "venom_marshall"]:
        exists(f"scripts/actors/{actor}.gd")
        exists(f"scenes/actors/{actor}.tscn")
'''
static = static.replace(anchor, "\n" + new_checks + anchor, 1)

old_list = "check_save_recovery_and_runtime_ci, check_repository_hygiene,\n        check_stale_contracts,"
new_list = "check_save_recovery_and_runtime_ci, check_player_gameplay_regressions,\n        check_canonical_documentation, check_repository_hygiene, check_stale_contracts,"
if static.count(old_list) != 1:
    raise SystemExit("static_audit.py: check list anchor changed")
static = static.replace(old_list, new_list, 1)
static_path.write_text(static, encoding="utf-8")

# Add runtime test to CI.
workflow_path = ROOT / ".github/workflows/validate.yml"
workflow = workflow_path.read_text(encoding="utf-8")
workflow_anchor = "      - name: Install Windows export templates\n"
if workflow.count(workflow_anchor) != 1:
    raise SystemExit("validate.yml: Windows templates anchor changed")
workflow_step = (
    '      - name: Run weapon pause reload runtime regression\n'
    '        shell: bash\n'
    '        run: |\n'
    '          set -o pipefail\n'
    '          log="$RUNNER_TEMP/weapon-pause-reload-runtime.log"\n'
    '          godot --headless --path . tests/weapon_pause_reload_runtime_test.tscn 2>&1 | tee "$log"\n'
    "          if grep -E 'ERROR:|invalid UID' \"$log\"; then\n"
    '            echo "::error::Weapon pause/reload runtime log contains an error or invalid UID"\n'
    '            exit 1\n'
    '          fi\n'
)
workflow = workflow.replace(workflow_anchor, workflow_step + workflow_anchor, 1)
workflow_path.write_text(workflow, encoding="utf-8")
