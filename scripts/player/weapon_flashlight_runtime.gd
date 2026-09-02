class_name VexWeaponFlashlightRuntime
extends RefCounted


static func initialize_light(light: SpotLight3D) -> void:
	if light != null and is_instance_valid(light):
		light.visible = false


static func sync(
	light: SpotLight3D,
	weapon: WeaponDefinition,
	enabled: bool,
	modifiers: Dictionary
) -> void:
	if light == null or not is_instance_valid(light):
		return
	var active := weapon != null and weapon.supports_flashlight and enabled
	light.visible = active
	if weapon == null or not weapon.supports_flashlight:
		return
	light.light_color = weapon.flashlight_color
	light.light_energy = weapon.flashlight_energy * float(modifiers.flashlight_energy)
	light.spot_range = weapon.flashlight_range * float(modifiers.flashlight_range)
	light.spot_angle = weapon.flashlight_angle_degrees


static func is_active(
	light: SpotLight3D,
	weapon: WeaponDefinition,
	enabled: bool
) -> bool:
	return (
		weapon != null
		and weapon.supports_flashlight
		and enabled
		and light != null
		and is_instance_valid(light)
		and light.visible
	)
