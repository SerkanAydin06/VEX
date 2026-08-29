# VEX

VEX, Godot 4.7 ile geliştirilen tek oyunculu bir FPS projesidir.

## Gereksinimler

- Godot 4.7 stable
- Python 3.12 (depo denetimleri için)

## Yerel doğrulama

```bash
for audit in tests/*_audit.py; do python "$audit"; done
godot --headless --editor --path . --quit
godot --headless --path . tests/integrity_test.tscn
godot --headless --path . tests/warden_door_runtime_test.tscn
```

## Windows export

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/VEX.exe
```

Canonical tasarım kaynakları:

- `STANDART.txt`
- `Weapons_VEX.md`
- `Enemies_VEX.md`
- `Story_VEX.md`

Önemli gameplay tuning değerleri ve sahnede bulunan görsel/oyunsal elemanlar
Inspector/sahne otoritelidir. Geçici efektler ve yardımcı runtime sistemleri doğal
olarak kod içinde kalabilir.

`translations/vex.csv` ana yerelleştirme kaynağıdır. Godot tarafından üretilen
`.translation` dosyaları depoya eklenmez.
