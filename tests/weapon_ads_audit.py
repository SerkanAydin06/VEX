#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
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


def numeric_property(text: str, key: str) -> float | None:
    match = re.search(rf"^{re.escape(key)}\s*=\s*(-?\d+(?:\.\d+)?)$", text, re.M)
    return float(match.group(1)) if match else None


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
    require(
        definition,
        '@export_range(1.0, 1.5, 0.01) var hud_ads_scale_multiplier := 1.0',
        "WeaponDefinition ADS HUD scale tuning alanını taşımıyor",
    )
    require(
        definition,
        '@export_enum("small_cross", "red_dot", "ring") var hud_ads_reticle_style := "small_cross"',
        "WeaponDefinition silah-bazlı ADS reticle stilini taşımıyor",
    )
    require(
        definition,
        '@export var hud_preserve_authored_frame_motion := false',
        "WeaponDefinition authored HUD kare hareketini koruma ayarını taşımıyor",
    )
    require(
        definition,
        '@export var hud_aim_fire_preserve_frame_motion := false',
        "WeaponDefinition art-authored ADS fire frame hareketi ayarını taşımıyor",
    )
    require(definition, "+X silah/arpacığı sağa", "hud_zoom_offset mikro-kalibrasyon yönü belgelenmemiş")
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
        ("spread_multiplier = weapon.ads_spread_multiplier", "Silah-bazlı ADS spread override eksik"),
    ]:
        require(controller, contract, message)

    for contract, message in [
        ("return player != null and is_instance_valid(player) and player.is_aiming", "HUD zoom pozu gerçek player.is_aiming durumuna bağlı değil"),
        ("crosshair_node.visible = not _is_weapon_ads_active()", "ADS sırasında normal crosshair gizlenmiyor"),
        ('ADS_RETICLE_SCENE := preload("res://scenes/ui/ads_reticle.tscn")', "HUD presenter ADS reticle sahnesini yüklemiyor"),
        ("_ensure_ads_reticle()", "HUD presenter ADS reticle kurulumunu çağırmıyor"),
        ("hud_root.add_child(_ads_reticle)", "ADS reticle HUD Root altına eklenmiyor"),
        ("const ADS_SCREEN_PIVOT := Vector2(960.0, 540.0)", "ADS HUD scale pivot'i ekran merkezinde değil"),
        ('sprite.set_meta("vex_base_position", sprite.position)', "HUD presenter silahın baz pozisyonunu saklamıyor"),
        ('sprite.set_meta("vex_base_scale", sprite.scale)', "HUD presenter silahın baz scale değerini saklamıyor"),
        ('sprite.set_meta("vex_ads_scale_multiplier", definition.hud_ads_scale_multiplier)', "HUD presenter silah-bazlı ADS scale değerini saklamıyor"),
        ('sprite.animation in [&"zoom", &"aim_fire"]', "ADS scale yalnız zoom/aim_fire pozlarına bağlı değil"),
        ('sprite.position = ADS_SCREEN_PIVOT + (base_position - ADS_SCREEN_PIVOT) * ads_scale_multiplier', "ADS silah görseli hedef pivot etrafında ölçeklenmiyor"),
        ('sprite.scale = base_scale * ads_scale_multiplier', "ADS silah görseli baz scale üzerinden büyütülmüyor"),
        ('sprite.position = base_position', "ADS dışı animasyonlarda baz pozisyona dönüş eksik"),
        ('sprite.scale = base_scale', "ADS dışı animasyonlarda baz scale'e dönüş eksik"),
        ('_set_ads_reticle_fire_suppressed(requested_animation == &"aim_fire")', "ADS reticle aim_fire başında gizlenmiyor"),
        ('if sprite.animation == &"aim_fire":', "ADS presenter aim_fire bitişini ayırt etmiyor"),
        ('_set_ads_reticle_fire_suppressed(false)', "ADS reticle aim_fire sonrasında geri açılmıyor"),
        ('has_method("set_fire_animation_suppressed")', "Presenter reticle recoil-suppression API'sini kullanmıyor"),
        ('if definition.hud_preserve_authored_frame_motion:', "Presenter authored pistol kare yerleşimini koruyamıyor"),
        ('offsets[frame_key] = Vector2.ZERO', "Presenter authored hip-fire/reload karelerini alpha bounds ile yeniden merkezliyor"),
        ('if definition.hud_aim_fire_preserve_frame_motion:', "Presenter art-authored ADS fire frame hareketini seçemiyor"),
        ('offsets[frame_key] = definition.hud_zoom_offset + definition.hud_aim_fire_offset', "Presenter preserve modunda transient alpha bounds ile aim_fire karesini yeniden merkezliyor"),
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
        ('cross_half_length = 4.0', "Ironsight ADS + işareti küçük kalibrasyonda değil"),
        ('cross_thickness = 1.25', "Ironsight ADS + işareti ince kalibrasyonda değil"),
        ('dot_radius = 1.8', "Optik ADS kırmızı nokta boyutu kalibrasyonda değil"),
        ('dot_outline_radius = 3.0', "Optik ADS nokta konturu kalibrasyonda değil"),
    ]:
        require(reticle_scene, contract, message)

    for contract, message in [
        ("or not player.is_aiming", "ADS reticle gerçek player.is_aiming durumuna bağlı değil"),
        ('get_node_or_null("MapOverlay")', "ADS reticle automap sırasında gizlenmiyor"),
        ('get_node_or_null("PauseMenu")', "ADS reticle pause menüsünde gizlenmiyor"),
        ("GameState.hit_confirmed.connect(_on_hit_confirmed)", "ADS reticle hit feedback almıyor"),
        ("GameState.headshot_confirmed.connect(_on_headshot_confirmed)", "ADS reticle headshot feedback almıyor"),
        ('if _reticle_style == "ring"', "ADS reticle halka stilini çizmiyor"),
        ("draw_arc(center, ring_radius", "ADS halka reticle çizimi eksik"),
        ('if _reticle_style == "red_dot"', "ADS reticle optik red-dot stilini çizmiyor"),
        ("draw_circle(center, dot_radius, _display_color)", "Optik ADS hedef noktası gerçek küçük nokta olarak çizilmiyor"),
        ("draw_line(horizontal_from, horizontal_to", "Ironsight ADS küçük + yatay kolu çizilmiyor"),
        ("draw_line(vertical_from, vertical_to", "Ironsight ADS küçük + dikey kolu çizilmiyor"),
        ('next_style = definition.hud_ads_reticle_style', "ADS reticle stili mevcut silahın WeaponDefinition verisinden gelmiyor"),
        ("var _fire_animation_suppressed := false", "ADS reticle recoil suppression durumu taşımıyor"),
        ("func set_fire_animation_suppressed(suppressed: bool) -> void:", "ADS reticle recoil suppression API'si eksik"),
        ("or _fire_animation_suppressed", "ADS reticle presenter suppression durumunu dikkate almıyor"),
        ("or _is_weapon_fire_animation_active()", "ADS reticle canlı aim_fire animasyonunu doğrudan kontrol etmiyor"),
        ('get_node_or_null("WeaponLayer")', "ADS reticle HUD WeaponLayer içindeki gerçek silah sprite'ını bulmuyor"),
        ('sprite.animation == &"aim_fire"', "ADS reticle gerçek aim_fire animasyon adını kontrol etmiyor"),
        ("sprite.is_playing()", "ADS reticle aim_fire'ın gerçekten oynadığını doğrulamıyor"),
    ]:
        require(reticle_script, contract, message)

    expected_multiplier = {
        "p01": 0.72,
        "p07": 0.64,
        "p14": 0.50,
        "p20": 0.58,
    }
    expected_ads_scale = {
        "p01": 1.34,
        "p07": 1.34,
        "p14": 1.29,
        "p20": 1.27,
    }
    expected_reticle_style = {
        "p01": "small_cross",
        "p07": "small_cross",
        "p14": "red_dot",
        "p20": "red_dot",
    }
    observed: list[float] = []
    for weapon_id, multiplier in expected_multiplier.items():
        weapon = read(f"resources/weapons/{weapon_id}.tres")
        view = read(f"scenes/ui/weapons/{weapon_id}_view.tscn")
        require(weapon, "supports_ads_pose = true", f"{weapon_id} ADS pose desteğini kaybetmiş")
        require(
            weapon,
            "hud_preserve_authored_frame_motion = true",
            f"{weapon_id} yeni authored 1536x1024 animasyon karelerinin yerleşimini korumuyor",
        )
        fov_value = numeric_property(weapon, "ads_fov_multiplier")
        if fov_value is None or abs(fov_value - multiplier) > 0.000001:
            ERRORS.append(f"{weapon_id} ads_fov_multiplier beklenen {multiplier:.2f} değil")
        require(
            weapon,
            "hud_zoom_offset = Vector2(",
            f"{weapon_id} ADS zoom görseli mikro-kalibrasyon alanını taşımıyor",
        )
        scale_value = numeric_property(weapon, "hud_ads_scale_multiplier")
        if scale_value is None or abs(scale_value - expected_ads_scale[weapon_id]) > 0.000001:
            ERRORS.append(f"{weapon_id} ADS HUD scale değeri ekran altını dolduran kalibrasyonda değil")
        style_key = "hud_ads_reticle_style ="
        expected_style = f'hud_ads_reticle_style = "{expected_reticle_style[weapon_id]}"'
        if expected_reticle_style[weapon_id] == "small_cross":
            if style_key in weapon and expected_style not in weapon:
                ERRORS.append(f"{weapon_id} beklenen small_cross ADS reticle stilini kullanmıyor")
        else:
            require(weapon, expected_style, f"{weapon_id} beklenen ADS reticle stilini kullanmıyor")
        if "hud_aim_fire_offset =" in weapon and "hud_aim_fire_offset = Vector2(0, 0)" not in weapon:
            ERRORS.append(f"{weapon_id} ADS ateş animasyonu zoom baz hizasına ek ofset taşıyor")
        if "ads_fov =" in weapon:
            ERRORS.append(f"{weapon_id} hâlâ eski mutlak ads_fov değerini taşıyor")
        require(view, 'animation = &"idle"', f"{weapon_id} WeaponView editor başlangıç animasyonu idle değil")
        require(view, 'autoplay = "idle"', f"{weapon_id} WeaponView idle autoplay sözleşmesini kaybetmiş")
        observed.append(multiplier)

    p14 = read("resources/weapons/p14.tres")
    require(p14, "hud_aim_fire_preserve_frame_motion = true", "P14 aim_fire karelerinin çizilmiş recoil hareketini korumuyor")

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
