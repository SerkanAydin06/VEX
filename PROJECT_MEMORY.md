# VEX — Proje Hafızası

## Proje özeti
Godot 4.7 tek oyunculu FPS.

## Önceki bağlam / dikkat noktaları
Mevcut validate_local.ps1 ve tools/validate.sh doğrulamalarını kullan. Önce README ve mevcut ajan talimatlarını oku.

## Kalıcı çalışma protokolü
- Kaynak: Bu deponun güncel kodu ve belgeleri. Sohbet hafızası eksik veya eski olabilir.
- Başlangıç: GitHub bağlantısını ve depo erişimini kontrol et. Kullanıcıyı yeniden bağlantı kurmaya yönlendirmeden önce mevcut GitHub araçlarını dene.
- İşe başlamadan önce bu dosyayı, README.md ve varsa AGENTS.md / CLAUDE.md / başka proje kurallarını incele.
- Kodda bir değişiklik yapmadan önce en son durumu incele; kullanıcıdan gelmeyen ayrıntıları karar gibi sunma.
- İstenen değişiklikleri, mümkün ve yetkili olduğunda doğrudan GitHub'da uygula; commit/PR bağlantısı ile sonuç bildir.
- Her önemli görevden sonra bu dosyanın "Çalışma günlüğü" bölümünü yeni karar, değişen dosyalar, test sonucu, commit bağlantısı ve bekleyen işlerle güncelle.
- Eski tercihlerin uygulanmış olduğunu sadece bu dosyadan çıkarsama: kod ile doğrula.
- Yanıt dili Türkçe; kısa, net, gereksiz anlatımdan uzak.
- Var olan AGENTS.md ve depo yönergeleri öncelikle korunur; bu dosya onları geçersiz kılmaz.

## Çalışma günlüğü
- 2026-10-30: Süreklilik için PROJECT_MEMORY.md başlatıldı. Bu dosya kod değişikliği veya geçmişte tamamlanmış işlerin doğrulaması değildir.
- 2026-11-02 — Oyuncu yere basarken hareket tuşu bırakılınca anında duruş eklendi; zıplama, hava hareketi ve dış darbe momentumu korunuyor. Dosyalar: `scripts/player/player.gd`, `scripts/player/player_movement_runtime.gd`, `tests/player_movement_runtime_test.gd`, `tests/player_movement_audit.py`. PR: https://github.com/SerkanAydin06/VEX/pull/103. Kaynak ve test sözleşmesi statik olarak kontrol edildi; Godot kurulu olmadığı için gerçek runtime/oynanış testi çalıştırılamadı.
- Son tamamlanan teknik görev: #103 — yerde anında durma düzeltmesi.
- Son doğrulanan commit: #103 dalında statik kaynak doğrulaması; Godot runtime doğrulaması bekleniyor.
- Bekleyen işler: Windows/Godot 4.7 ile `validate_local.ps1`, kısa oynanış smoke testi (WASD bırakma, zıplama, darbe etkisi).
