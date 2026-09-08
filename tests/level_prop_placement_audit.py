from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


level01 = _read("scenes/levels/level_01.tscn")
level02 = _read("scenes/levels/level_02.tscn")
level03 = _read("scenes/levels/level_03.tscn")
env02 = _read("scenes/levels/level_02_environment_story.tscn")
env03 = _read("scenes/levels/level_03_environment_story.tscn")
structure01 = _read("scenes/levels/level_01_structure_source.tscn")
structure02 = _read("scenes/levels/level_02_structure_source.tscn")
structure03 = _read("scenes/levels/level_03_structure_source.tscn")
finish_scene = _read("scenes/props/finish_switch.tscn")
record_scene = _read("scenes/props/field_record_terminal.tscn")
rescue_scene = _read("scenes/props/survivor_rescue_terminal.tscn")


# Reusable prop facing conventions used by all placement calculations.
assert 'position = Vector3(0, 1.5, 0.265)' in finish_scene  # finish front = local +Z
assert 'position = Vector3(0, 0.22, -0.227)' in record_scene  # record front = local -Z
assert 'position = Vector3(0, 1.05, 0.44)' in rescue_scene  # rescue front = local +Z


# Level 1: final console is flush to the east R37 wall, faces west into the room,
# and starts at floor height. All three field terminals sit on the floor and touch
# an actual wall instead of floating in the room volume.
assert 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6, 3.5, -60)' in structure01
for token in [
    'Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, -3.8, 0.78, 45.41)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -29.59, 0.78, -2.4)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -29.59, 0.78, -38.4)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 5.72, 0, -60)',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.85, -54.78)',
]:
    assert token in level01, token


# Level 2 environment source is the authority. Main scene must not carry stale
# per-child editor overrides such as the previously displaced TransferHallDisplay.
assert 'parent="Level02EnvironmentStory/RoomCodes"' not in level02
assert 'parent="Level02EnvironmentStory/ThermalConduits"' not in level02
assert 'parent="Level02EnvironmentStory/WarningBars"' not in level02

# The wall displays, conduits and warning bars hug the inside surface of the
# authored 0.4 m walls. Conduits are vertical rather than suspended through rooms.
for token in [
    'position = Vector3(-24, 4.85, -34.72)',
    'position = Vector3(-53.72, 4.85, 10)',
    'position = Vector3(24, 4.85, -14.72)',
    'position = Vector3(53.72, 4.85, 20)',
    'position = Vector3(48, 4.85, 34.72)',
    'rotation = Vector3(0, 3.14159, 0)',
    'position = Vector3(-29.72, 3.5, -20)',
    'position = Vector3(29.72, 3.5, -10)',
    'position = Vector3(42.28, 3.5, 20)',
    'size = Vector3(2.8, 0.28, 0.055)',
    'position = Vector3(-24, 4.65, -34.77)',
    'position = Vector3(24, 4.65, -14.77)',
    'position = Vector3(48, 4.65, 34.77)',
]:
    assert token in env02, token

for wall_token in [
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -54, 3.5, 10)',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 30, 3.5, -10)',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 42, 3.5, 20)',
]:
    assert wall_token in structure02, wall_token

# Level 2 gameplay wall props share the same east-wall convention and the new
# two-metre extraction console starts at floor height instead of hanging high.
for token in [
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 53.59, 0.78, 28.8)',
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 29.59, 0.78, -8)',
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 53.59, 0.78, 20.6)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 53.72, 0, 30)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 53.76, 4.85, 30)',
]:
    assert token in level02, token


# Level 3 pressure pipes now lie against real boundary/door-frame walls instead
# of crossing the centre of rooms. Displays and warning strips use the same flush
# offsets as the other chapters.
for token in [
    'position = Vector3(-23.72, 4.85, -5)',
    'position = Vector3(23.72, 4.85, 15)',
    'position = Vector3(-11.72, 12.65, -5)',
    'position = Vector3(23.72, 12.65, -5)',
    'position = Vector3(23.72, 12.65, -15)',
    'position = Vector3(12, 3.9, 19.68)',
    'position = Vector3(0, 3.9, -9.68)',
    'position = Vector3(12, 11.7, -9.68)',
    'size = Vector3(3.0, 0.3, 0.055)',
    'position = Vector3(-6, 12.45, -9.77)',
    'position = Vector3(18, 12.45, -19.77)',
]:
    assert token in env03, token

for wall_token in [
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.5, 20)',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6, 3.5, -10)',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 24, 11.3, -5)',
]:
    assert wall_token in structure03, wall_token

# Level 3 records, Selin stabilization and extraction all face the playable room.
# Upper-floor roots use the authored floor top (7.8 m), not the old floating Y.
for token in [
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 11.59, 0.78, 13.8)',
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 23.59, 8.58, -3.6)',
    'Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, -4.2, 8.58, -9.59)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 23.375, 7.81, -6.8)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 23.72, 7.8, -17)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 23.76, 12.4, -17)',
]:
    assert token in level03, token

print("level prop placement audit passed")
