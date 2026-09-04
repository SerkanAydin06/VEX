extends RefCounted

# Rift Reaver başka bir yaratığın WAV dosyasını ödünç almaz. Kısa Aether sesleri
# ilk Rift Reaver hazır olduğunda deterministik olarak üretilir ve tüm örnekler
# aynı AudioStreamWAV nesnelerini paylaşır.
const MIX_RATE := 22050
const ATTACK_DURATION := 0.34
const HURT_DURATION := 0.28
const DEATH_DURATION := 0.92

enum SoundKind {
	ATTACK,
	HURT,
	DEATH,
}

static var _attack_stream: AudioStreamWAV
static var _hurt_stream: AudioStreamWAV
static var _death_stream: AudioStreamWAV


static func attack_stream() -> AudioStreamWAV:
	if _attack_stream == null:
		_attack_stream = _build_stream(ATTACK_DURATION, SoundKind.ATTACK)
	return _attack_stream


static func hurt_stream() -> AudioStreamWAV:
	if _hurt_stream == null:
		_hurt_stream = _build_stream(HURT_DURATION, SoundKind.HURT)
	return _hurt_stream


static func death_stream() -> AudioStreamWAV:
	if _death_stream == null:
		_death_stream = _build_stream(DEATH_DURATION, SoundKind.DEATH)
	return _death_stream


static func _build_stream(duration: float, kind: int) -> AudioStreamWAV:
	var sample_count := maxi(1, roundi(duration * float(MIX_RATE)))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample_index: int in range(sample_count):
		var time := float(sample_index) / float(MIX_RATE)
		var sample := clampf(_sample(kind, time, duration), -0.92, 0.92)
		var encoded := int(round(sample * 32767.0))
		if encoded < 0:
			encoded += 65536
		pcm[sample_index * 2] = encoded & 0xFF
		pcm[sample_index * 2 + 1] = (encoded >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = pcm
	return stream


static func _sample(kind: int, time: float, duration: float) -> float:
	match kind:
		SoundKind.ATTACK:
			return _attack_sample(time, duration)
		SoundKind.HURT:
			return _hurt_sample(time, duration)
		_:
			return _death_sample(time, duration)


static func _linear_chirp_phase(
	time: float,
	duration: float,
	start_hz: float,
	end_hz: float
) -> float:
	var slope := (end_hz - start_hz) / maxf(duration, 0.001)
	return TAU * (start_hz * time + 0.5 * slope * time * time)


static func _electric_texture(time: float) -> float:
	return (
		sin(TAU * 1733.0 * time + sin(TAU * 97.0 * time))
		* sin(TAU * 2711.0 * time + 0.7)
	)


static func _attack_sample(time: float, duration: float) -> float:
	var envelope := (1.0 - exp(-time / 0.006)) * exp(-time / 0.15)
	var primary := sin(_linear_chirp_phase(time, duration, 980.0, 230.0))
	var crystal := sin(_linear_chirp_phase(time, duration, 1960.0, 480.0))
	var low_body := sin(TAU * (112.0 * time + 0.015 * sin(TAU * 3.0 * time)))
	return (
		0.50 * primary * envelope
		+ 0.18 * crystal * envelope
		+ 0.16 * _electric_texture(time) * exp(-time / 0.085)
		+ 0.18 * low_body * exp(-time / 0.22)
	)


static func _hurt_sample(time: float, duration: float) -> float:
	var envelope := (1.0 - exp(-time / 0.003)) * exp(-time / 0.09)
	var crack := sin(_linear_chirp_phase(time, duration, 740.0, 145.0))
	var gate := 1.0 if sin(TAU * 47.0 * time) >= 0.0 else 0.45
	var low_body := sin(TAU * 91.0 * time) * exp(-time / 0.16)
	return (
		0.48 * crack * envelope * gate
		+ 0.23 * _electric_texture(time) * exp(-time / 0.055)
		+ 0.28 * low_body
	)


static func _death_sample(time: float, duration: float) -> float:
	var envelope := (1.0 - exp(-time / 0.008)) * exp(-time / 0.50)
	var primary := sin(_linear_chirp_phase(time, duration, 430.0, 48.0))
	var overtone := sin(_linear_chirp_phase(time, duration, 820.0, 72.0))
	var collapse_pulse := 0.72 + 0.28 * sin(TAU * 8.0 * time)
	var low_body := sin(TAU * 54.0 * time) * exp(-time / 0.78)
	return (
		(0.45 * primary + 0.20 * overtone) * envelope * collapse_pulse
		+ 0.18 * _electric_texture(time) * exp(-time / 0.58)
		+ 0.22 * low_body
	)
