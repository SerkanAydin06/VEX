#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        ERRORS.append(f"Eksik dosya: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def require(text: str, contract: str, message: str) -> None:
    if contract not in text:
        ERRORS.append(message)


def main() -> int:
    definition = read("scripts/player/weapon_definition.gd")
    player = read("scripts/player/player.gd")
    controller = read("scripts/player/weapon_controller.gd")
    presenter = read("scripts/ui/hud_weapon_presenter.gd")
    reticle_script = read("scripts/ui/ads_reticle.gd")
    reticle_scene = read("scenes/ui/ads_reticle.tscn")

    require(
        definition,
        '@export_range(0.35, 0.95, 0.01) var ads_fov_multiplier := 0.70',
        "WeaponDefinition silah-bazlı göreli ADS FOV çarpanı taşımıyor",
    )
    if 'var ads_fov := ' in definition:
        ERRORS.append("WeaponDefinition hâlâ mutlak ads_fov otoritesi taşıyor")

    for contract, message in [
        ('@export_range(0.0, 1.0, 0.01) var ads_spread_multiplier := 0.0', "ADS spread sıfır değil"),
        ('current_weapon = weapon_controller.call("get_current_weapon") as WeaponDefinition', "Player mevcut silah tanımını ADS için okumuyor"),
        ("current_weapon != null and current_weapon.supports_ads_pose", "Player ADS desteğini silah verisinden doğrulamıyor"),
        ('is_aiming = supports_ads and Input.is_action_pressed("aim")', "ADS durumu desteklemeyen silahlarda engellenmiyor"),
        ("_default_fov * current_weapon.ads_fov_multiplier", "Kamera FOV'u normal FOV'a göre silah çarpanı kullanmıyor"),
        ("Vector2.ZERO", "ADS sırasında HUD recoil ofseti sıfırlanmıyor"),
        ('GameState.hud.call("set_weapon_recoil_offset", hud_recoil)', "HUD recoil/optik merkez senkronu eksik"),
    ]:
        require(player, contract, message)

    for contract, message in [
        ("var uses_ads_optical_center := _player.is_aiming and weapon.supports_ads_pose", "Hitscan ADS optik-merkez koşulu eksik"),
        ("not uses_ads_optical_center", "Hip-fire/ADS hedef ayrımı eksik"),
        ('GameState.hud.has_method("get_crosshair_screen_position")', "Hip-fire HUD crosshair hedeflemesi kaybolmuş"),
        ("camera.get_viewport().get_visible_rect().size * 0.5", "ADS için kamera ekran merkezi hesaplanmıyor"),
    ]:
        require(controller, contract, message)

    for contract, message in [
        ("return player != null and is_instance_valid(player) and player.is_aiming", "HUD zoom pozu gerçek player.is_aiming durumuna bağlı değil"),
        ("crosshair_node.visible = not _is_weapon_ads_active()", "ADS sırasında normal crosshair gizlenmiyor"),
        ('ADS_RETICLE_SCENE := preload("res://scenes/ui/ads_reticle.tscn")', "HUD presenter ADS reticle sahnesini yüklemiyor"),
        ("_ensure_ads_reticle()", "HUD presenter ADS reticle kurulumunu çağırmıyor"),
        ("hud_root.add_child(_ads_reticle)", "ADS reticle HUD Root altına eklenmiyor"),
    ]:
        require(presenter, contract, message)
    if 'or Input.is_action_pressed("aim")' in presenter:
        ERRORS.append("HUD presenter hâlâ raw aim input ile sahte ADS gösterebiliyor")

    for contract, message in [
        ('anchors_preset = 8', "ADS reticle ekran merkezine anchor'lı değil"),
        ('anchor_left = 0.5', "ADS reticle yatay merkez anchor'ı eksik"),
        ('anchor_top = 0.5', "ADS reticle dikey merkez anchor'ı eksik"),
        ('offset_left = -12.0', "ADS reticle sol offset sözleşmesi bozuk"),
        ('offset_right = 12.0', "ADS reticle sağ offset sözleşmesi bozuk"),
        ('[node name="CenterDot" type="ColorRect" parent="."]', "ADS reticle merkez noktası eksik"),
        ('[node name="LeftArm" type="ColorRect" parent="."]', "ADS reticle sol kolu eksik"),
        ('[node name="RightArm" type="ColorRect" parent="."]', "ADS reticle sağ kolu eksik"),
        ('[node name="TopArm" type="ColorRect" parent="."]', "ADS reticle üst kolu eksik"),
        ('[node name="BottomArm" type="ColorRect" parent="."]', "ADS reticle alt kolu eksik"),
    ]:
        require(reticle_scene, contract, message)

    for contract, message in [
        ("or not player.is_aiming", "ADS reticle gerçek player.is_aiming durumuna bağlı değil"),
        ('get_node_or_null("MapOverlay")', "ADS reticle automap sırasında gizlenmiyor"),
        ('get_node_or_null("PauseMenu")', "ADS reticle pause menüsünde gizlenmiyor"),
        ("GameState.hit_confirmed.connect(_on_hit_confirmed)", "ADS reticle hit feedback almıyor"),
        ("GameState.headshot_confirmed.connect(_on_headshot_confirmed)", "ADS reticle headshot feedback almıyor"),
    ]:
        require(reticle_script, contract, message)

    expected_multiplier = {
        "p01": 0.72,
        "p07": 0.64,
        "p14": 0.50,
        "p20": 0.58,
    }
    observed: list[float] = []
    for weapon_id, multiplier in expected_multiplier.items():
        weapon = read(f"resources/weapons/{weapon_id}.tres")
        require(weapon, "supports_ads_pose = true", f"{weapon_id} ADS pose desteğini kaybetmiş")
        require(
            weapon,
            f"ads_fov_multiplier = {multiplier:.2f}",
            f"{weapon_id} ads_fov_multiplier beklenen {multiplier:.2f} değil",
        )
        require(
            weapon,
            "hud_zoom_offset = Vector2(-176, 0)",
            f"{weapon_id} ADS zoom görseli ortak optik merkez kalibrasyonunu kullanmıyor",
        )
        require(
            weapon,
            "hud_aim_fire_offset = Vector2(0, 0)",
            f"{weapon_id} ADS ateş animasyonu zoom optik merkezinden sapıyor",
        )
        if "ads_fov =" in weapon:
            ERRORS.append(f"{weapon_id} hâlâ eski mutlak ads_fov değerini taşıyor")
        observed.append(multiplier)

    if len(set(observed)) != len(observed):
        ERRORS.append("Tabanca ADS zoom çarpanları birbirinden ayrışmıyor")
    if not (
        expected_multiplier["p14"]
        < expected_multiplier["p20"]
        < expected_multiplier["p07"]
        < expected_multiplier["p01"]
    ):
        ERRORS.append("Tabanca zoom hiyerarşisi precision -> heavy -> tactical -> standard sırasını korumuyor")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"WEAPON ADS VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
