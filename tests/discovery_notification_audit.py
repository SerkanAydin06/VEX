from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OVERLAY_SCENE = ROOT / "scenes" / "ui" / "discovery_notification_overlay.tscn"
OVERLAY_SCRIPT = ROOT / "scripts" / "ui" / "discovery_notification_overlay.gd"
PICKUP = ROOT / "scripts" / "props" / "pickup.gd"
ARCHIVE = ROOT / "scripts" / "autoload" / "archive_manager.gd"
RECORD = ROOT / "scripts" / "props" / "field_record_terminal.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_overlay_is_authored_ui_and_starts_hidden_above_record_reader() -> None:
    scene = _read(OVERLAY_SCENE)
    record = _read(RECORD)
    assert '[node name="DiscoveryNotificationOverlay" type="CanvasLayer"]' in scene
    assert "layer = 120" in scene
    assert '_reader_layer.layer = 80' in record
    assert '[node name="Card" type="PanelContainer" parent="Root"]' in scene
    assert "visible = false" in scene
    for unique_name in ["Accent", "Category", "Title", "Subtitle"]:
        assert f'[node name="{unique_name}"' in scene
        assert "unique_name_in_owner = true" in scene


def test_overlay_queues_and_runs_while_world_is_paused() -> None:
    script = _read(OVERLAY_SCRIPT)
    assert "var _queue: Array[Dictionary] = []" in script
    assert "_queue.append" in script
    assert "_queue.pop_front()" in script
    assert 'add_to_group(&"discovery_notification_overlay")' in script
    assert "tree.get_first_node_in_group" in script
    assert "Tween.TWEEN_PAUSE_PROCESS" in script
    assert "call_deferred(\"_show_next\")" in script


def test_first_weapon_acquisition_requests_weapon_archive_card() -> None:
    pickup = _read(PICKUP)
    assert "DISCOVERY_WEAPON_TYPES := [" in pickup
    assert "_is_first_weapon_acquisition(body)" in pickup
    assert "not bool(controller.call(\"owns_weapon\", weapon_id))" in pickup
    assert '"SİLAH ARŞİVİ GÜNCELLENDİ"' in pickup
    assert '"WEAPON ARCHIVE UPDATED"' in pickup
    assert '&"weapon"' in pickup


def test_first_xeno_archive_discovery_requests_xeno_card() -> None:
    archive = _read(ARCHIVE)
    assert "_show_discovery_card(enemy_id)" in archive
    assert "ArchiveDatabase.get_enemy(enemy_id)" in archive
    assert "ArchiveDatabase.get_universe(universe_id)" in archive
    assert '"YENİ XENO KAYDI"' in archive
    assert '"NEW XENO RECORD"' in archive
    assert '&"xeno"' in archive


def test_record_terminal_announces_only_new_campaign_discovery() -> None:
    record = _read(RECORD)
    assert "BaseManager.discover_field_record(record_id)" in record
    assert "var newly_discovered := false" in record
    assert "if newly_discovered:" in record
    assert "_discovery_announced" not in record
    assert '"KAYIT ÇÖZÜLDÜ"' in record
    assert '"RECORD DECODED"' in record
    assert '&"record"' in record
