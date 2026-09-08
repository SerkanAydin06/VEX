from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


level01 = _read("scenes/levels/level_01.tscn")
level02 = _read("scenes/levels/level_02.tscn")
level03 = _read("scenes/levels/level_03.tscn")
env01 = _read("scenes/levels/level_01_environment_story.tscn")
env02 = _read("scenes/levels/level_02_environment_story.tscn")
env03 = _read("scenes/levels/level_03_environment_story.tscn")
structure01 = _read("scenes/levels/level_01_structure_source.tscn")
structure02 = _read("scenes/levels/level_02_structure_source.tscn")
structure03 = _read("scenes/levels/level_03_structure_source.tscn")
finish_scene = _read("scenes/props/finish_switch.tscn")
record_scene = _read("scenes/props/field_record_terminal.tscn")
rescue_scene = _read("scenes/props/survivor_rescue_terminal.tscn")
room_display_scene = _read("scenes/world/room_name_display.tscn")


# Reusable prop facing/depth conventions used by placement calculations.
assert 'position = Vector3(0, 1.5, 0.265)' in finish_scene  # finish front = local +Z
assert 'position = Vector3(0, 0.22, -0.227)' in record_scene  # record front = local -Z
assert 'position = Vector3(0, 1.05, 0.44)' in rescue_scene  # rescue front = local +Z
assert 'position = Vector3(0, 0, 0.0825)' in room_display_scene  # room display front = local +Z


# -----------------------------------------------------------------------------
# LEVEL 1
# -----------------------------------------------------------------------------
# R03 and R35 have doorway openings at z=55 / z=-55. Their room displays must
# live on the solid TopFill above those doors, not at normal wall height in the
# opening. R23 uses its full east wall instead of the R23<->R25 doorway opening.
for wall_token in [
    'R01_03_TopFill',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 5.86, 55)',
    'R23_24_FullWall',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6, 3.5, -10)',
    'R35_37_TopFill',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 5.86, -55)',
]:
    assert wall_token in structure01, wall_token

for token in [
    'position = Vector3(0, 6.15, 54.74)',
    'rotation = Vector3(0, 3.14159, 0)',
    'position = Vector3(-29.74, 4.85, 0)',
    'position = Vector3(5.74, 4.85, -10)',
    'rotation = Vector3(0, -1.5708, 0)',
    'position = Vector3(-29.74, 4.85, -40)',
    'position = Vector3(0, 6.15, -54.74)',
    'position = Vector3(0, 4.85, -64.74)',
]:
    assert token in env01, token

# These were the known doorway-floating placements; they must never return.
assert 'position = Vector3(0, 4.85, 54.72)' not in env01
assert 'position = Vector3(0, 4.85, -14.72)' not in env01
assert 'position = Vector3(0, 4.85, -54.72)' not in env01

# Final console and field records remain physically flush and player-facing.
assert 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6, 3.5, -60)' in structure01
for token in [
    'Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, -3.8, 0.78, 45.41)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -29.59, 0.78, -2.4)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -29.59, 0.78, -38.4)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 5.72, 0, -60)',
]:
    assert token in level01, token


# -----------------------------------------------------------------------------
# LEVEL 2
# -----------------------------------------------------------------------------
# Environment source is authoritative; main scene must not carry stale per-child
# overrides that can silently move props away from their verified wall segment.
assert 'parent="Level02EnvironmentStory/RoomCodes"' not in level02
assert 'parent="Level02EnvironmentStory/ThermalConduits"' not in level02
assert 'parent="Level02EnvironmentStory/WarningBars"' not in level02

# Verified continuous wall segments used by the environment props.
for wall_token in [
    # West service display: full north wall of C2/R0.
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -24, 3.5, -35)',
    # Breacher display: full west wall at x=-54.
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -54, 3.5, 10)',
    # Transfer display/conduit: full east wall of the x=24,z=-10 room.
    'Outer_6_2_E',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 30, 3.5, -10)',
    # West conduit: full z=-15 wall; x=-30,z=-20 is a doorway and is forbidden.
    'Outer_2_1_S',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -24, 3.5, -15)',
    # South conduit: full blocking wall between the x=36 and x=48 rooms.
    'Wall_Block_7_5_8_5',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 42, 3.5, 20)',
    # Relay display/warning: full south wall at z=35.
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 48, 3.5, 35)',
]:
    assert wall_token in structure02, wall_token

# Every display is flush to a real wall and faces into its playable room.
for token in [
    'position = Vector3(-24, 4.85, -34.74)',
    'position = Vector3(-53.74, 4.85, 10)',
    'position = Vector3(29.74, 4.85, -12.0)',
    'rotation = Vector3(0, -1.5708, 0)',
    'position = Vector3(53.74, 4.85, 20)',
    'position = Vector3(48, 4.85, 34.74)',
    'rotation = Vector3(0, 3.14159, 0)',
]:
    assert token in env02, token

# Conduits are wall-mounted HORIZONTAL runs. The old x=-30,z=-20 placement sat
# in a doorway, and the old X=90 rotations turned all three into vertical bars.
for token in [
    'position = Vector3(-24, 2.7, -15.28)',
    'rotation = Vector3(0, 1.5708, 0)',
    'position = Vector3(29.72, 2.8, -8.0)',
    'position = Vector3(42.28, 2.7, 20)',
]:
    assert token in env02, token
assert 'position = Vector3(-29.72, 3.5, -20)' not in env02
assert 'rotation = Vector3(1.5708, 0, 0)\nmesh = SubResource("Mesh_conduit")' not in env02

# Warning bars sit below the room displays. Their thin 0.055 m depth only touches
# the wall plane; it is not used as the vertical dimension and they do not overlap
# the display frame at y=4.85.
assert 'size = Vector3(2.8, 0.28, 0.055)' in env02
for token in [
    'position = Vector3(-24, 4.22, -34.7725)',
    'position = Vector3(29.7725, 4.22, -12.0)',
    'position = Vector3(48, 4.22, 34.7725)',
]:
    assert token in env02, token
assert 'position = Vector3(24, 4.65, -14.77)' not in env02

# Gameplay wall props continue to use full east walls and correct facing.
for token in [
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 53.59, 0.78, 28.8)',
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 29.59, 0.78, -8)',
    'Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 53.59, 0.78, 20.6)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 53.72, 0, 30)',
    'Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 53.76, 4.85, 30)',
]:
    assert token in level02, token


# -----------------------------------------------------------------------------
# LEVEL 3
# -----------------------------------------------------------------------------
# Displays use the continuous outer walls, with their backing plate touching the
# inner wall face instead of hovering a few centimetres away.
for token in [
    'position = Vector3(-23.74, 4.85, -5)',
    'position = Vector3(23.74, 4.85, 15)',
    'position = Vector3(-11.74, 12.65, -5)',
    'position = Vector3(23.74, 12.65, -5)',
    'position = Vector3(23.74, 12.65, -15)',
]:
    assert token in env03, token

# Lower pipes fit completely on continuous lower boundaries. The 5 m upper pipe
# must use the continuous x=24 UpperEastBoundary; z=-10 is broken into short door
# frame pieces and cannot support a 5 m pipe without bridging empty doorway space.
for wall_token in [
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.5, 20)',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6, 3.5, -10)',
    'UpperEastBoundary',
    'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 24, 11.3, -5)',
]:
    assert wall_token in structure03, wall_token
for token in [
    'position = Vector3(12, 3.9, 19.68)',
    'position = Vector3(0, 3.9, -9.68)',
    'position = Vector3(23.68, 11.7, -5)',
    'rotation = Vector3(1.5708, 0, 0)',
]:
    assert token in env03, token
assert 'position = Vector3(12, 11.7, -9.68)' not in env03

# Warning bars are shallow wall strips, not wall-volume blocks.
assert 'size = Vector3(3.0, 0.3, 0.055)' in env03
for token in [
    'position = Vector3(-6, 12.45, -9.7725)',
    'position = Vector3(18, 12.45, -19.7725)',
]:
    assert token in env03, token

# Records, Selin stabilization and extraction continue to be floor-correct,
# wall-flush and player-facing.
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