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

Bash / Git Bash kullanan ortamlarda karşılığı:

```bash
tools/validate.sh           # Python denetimleri (paralel, yalnız hataları yazar)
tools/validate.sh --godot   # + Godot import, integrity_test ve runtime testleri
```

Godot PATH'te değilse `GODOT=/yol/godot tools/validate.sh --godot`. Claude Code on the web
oturumlarında Godot 4.7.1 `.claude/hooks/session-start.sh` ile otomatik kurulur.

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
