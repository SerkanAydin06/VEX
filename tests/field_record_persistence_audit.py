from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "scripts" / "data" / "vex_field_record_database.gd"
MANAGER = ROOT / "scripts" / "autoload" / "record_manager.gd"
BASE = ROOT / "scripts" / "autoload" / "base_manager.gd"
TERMINAL = ROOT / "scripts" / "props" / "field_record_terminal.gd"
BRIDGE = ROOT / "scripts" / "ui" / "field_record_archive_bridge.gd"
PROJECT = ROOT / "project.godot"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_database_reserves_ninety_campaign_records_and_has_level01_three() -> None:
    db = _read(DB)
    assert "const TOTAL_CAMPAIGN_RECORDS := 90" in db
    for record_id in [
        "vex01_emergency_test_order_0417",
        "vex01_security_camera_07",
        "vex01_we_do_not_produce_energy",
    ]:
        assert f'&"{record_id}"' in db
    assert db.count('"chapter": 1') == 3
    assert '"room": "R03"' in db
    assert '"room": "R17"' in db
    assert '"room": "R29"' in db


def test_base_campaign_state_owns_record_state_without_new_autoload() -> None:
    base = _read(BASE)
    project = _read(PROJECT)
    assert 'preload("res://scripts/autoload/record_manager.gd")' in base
    assert "var field_record_state: Dictionary = {}" in base
    assert "field_record_state = _record_manager.capture_state()" in base
    assert '"field_record_state": field_record_state' in base
    assert 'state.get("field_record_state", {})' in base
    assert "_record_manager.restore_state" in base
    assert "_record_manager.reset_campaign_state()" in base
    assert "func discover_field_record" in base
    assert "func get_discovered_field_record_ids" in base
    assert "signal field_record_changed" in base
    assert 'RecordManager="*res://scripts/autoload/record_manager.gd"' not in project


def test_typed_record_id_accessor_has_explicit_empty_array() -> None:
    base = _read(BASE)
    assert "func get_discovered_field_record_ids() -> Array[StringName]:" in base
    assert "var empty_ids: Array[StringName] = []" in base
    assert "return _record_manager.get_discovered_record_ids() if" not in base


def test_record_discovery_saves_only_level_start_boundary() -> None:
    manager = _read(MANAGER)
    assert "GameState.current_level_start_state.is_empty()" in manager
    assert "GameState.save_campaign_progress(" in manager
    assert "GameState.current_level_path" in manager
    assert "GameState.current_level_start_state" in manager
    assert '"field_record"' in manager
    assert "discovered_record_ids.erase(record_id)" in manager
    assert "capture_run_state" not in manager


def test_field_terminal_uses_campaign_discovery_and_canonical_database_text() -> None:
    terminal = _read(TERMINAL)
    assert 'preload("res://scripts/data/vex_field_record_database.gd")' in terminal
    assert "RecordDB.get_record(record_id)" in terminal
    assert 'RecordDB.localized(database_entry, "category")' in terminal
    assert 'RecordDB.localized(database_entry, "title")' in terminal
    assert 'RecordDB.localized(database_entry, "body")' in terminal
    assert "BaseManager.discover_field_record(record_id)" in terminal
    assert "if newly_discovered:" in terminal
    assert "_discovery_announced" not in terminal


def test_main_terminal_records_bridge_lists_only_discovered_field_records() -> None:
    bridge = _read(BRIDGE)
    assert "BaseManager.get_discovered_field_record_ids()" in bridge
    assert "RecordDB.TOTAL_CAMPAIGN_RECORDS" in bridge
    assert "SAHA KAYITLARI" in bridge
    assert "FIELD RECORDS" in bridge
    assert "SAHA KAYDI BULUNMADI" in bridge
    assert "RecordDB.get_record(record_id)" in bridge
    assert "ArchiveDB.LOGS" not in bridge
    assert "BaseManagementDashboard" not in bridge
    assert "kendi sekme görünürlüğünün sahibidir" in bridge


def test_record_manager_attaches_bridge_without_project_autoload() -> None:
    manager = _read(MANAGER)
    assert 'preload("res://scripts/ui/field_record_archive_bridge.gd")' in manager
    assert "get_tree().node_added" in manager
    assert 'node.name != "VexArchiveTerminal"' in manager
    assert 'bridge.name = "FieldRecordArchiveBridge"' in manager
