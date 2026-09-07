# VEX

VEX, Godot 4.7 ile geliştirilen tek oyunculu bir FPS projesidir.

## Gereksinimler

- Godot 4.7 stable
- Python 3.12 (depo denetimleri için)
- Windows/PowerShell yerel doğrulaması için `godot` ve `python` komutlarının PATH üzerinde bulunması önerilir.

## Yerel doğrulama

Windows'ta proje kökünden önerilen tek komut:

```powershell
.\validate_local.ps1
```

Godot PATH üzerinde değilse executable yolu açıkça verilebilir:

```powershell
.\validate_local.ps1 -Godot "C:\\Godot\\Godot_v4.7.1-stable_win64.exe"
```

Script sırasıyla bütün `tests/*_audit.py` denetimlerini, Godot headless import/parse kontrolünü, `integrity_test.tscn` sahnesini ve bütün `*_runtime_test.tscn` sahnelerini çalıştırır. İlk hatada durur ve başarısız adımı gösterir.

Windows release export'unu da aynı doğrulamaya eklemek için:

```powershell
.\validate_local.ps1 -Export
```

Bash kullanan ortamlarda temel karşılık:

```bash
for audit in tests/*_audit.py; do python "$audit"; done
godot --headless --editor --path . --quit
godot --headless --path . tests/integrity_test.tscn
for scene in tests/*_runtime_test.tscn; do godot --headless --path . "$scene"; done
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
- `docs/Campaign_Level_Design_VEX.md`
- `docs/levels/Level_01_First_Fracture.md`

Önemli gameplay tuning değerleri ve sahnede bulunan görsel/oyunsal elemanlar
Inspector/sahne otoritelidir. Geçici efektler ve yardımcı runtime sistemleri doğal
olarak kod içinde kalabilir.

`translations/vex.csv` ana yerelleştirme kaynağıdır. Godot tarafından üretilen
`.translation` dosyaları depoya eklenmez.
