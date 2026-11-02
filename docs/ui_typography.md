# VEX — Profesyonel Tipografi Sistemi

## Yazı ailesi ve amaç

VEX, Windows'a çıkan tek oyunculu bir FPS'tir. Ekranlar arasında **tek bir tipografik hiyerarşi** kullanılır:

| Rol | Kaynak | Windows yazı ailesi | Ağırlık | Kullanım |
| --- | --- | --- | --- | --- |
| Gövde / açıklama | `resources/ui/fonts/vex_body_font.tres` | Segoe UI → Arial | 400 | Görevler, arşiv makaleleri, diyaloglar, açıklamalar |
| Başlık / eylem | `resources/ui/fonts/vex_heading_font.tres` | Segoe UI → Arial | 600 | Ekran/sekme başlıkları, güçlü durum başlıkları, butonlar |
| Teknik veri | `resources/ui/fonts/vex_mono_font.tres` | Cascadia Mono → Consolas | 400 | Mühimmat, HUD sayıları, terminal kodları, aşama ve durum bilgileri |

Üç kaynak da Godot `SystemFont` kullanır; yeni harici font veya lisansı belirsiz binary eklenmez. Windows dışında oynatım hedeflenirse aynı ağırlıkları koruyan lisanslı font dosyaları paketlenmelidir. Var olan `assets/fonts/vex_ui_bold.ttf` ve `vex_mono_bold.ttf` yalnız 3B tesis tabelalarında ve dünyadaki fiziksel ekran/işaretlerde hâlâ kullanılabilir.

## Tipografik ölçüler

| Bağlam | Ebat (Godot arayüz birimi) | Kural |
| --- | --- | --- |
| Ekran başlığı | 26–36 | Semibold; az kelimeli |
| İkincil başlık / kart başlığı | 18–24 | Semibold |
| Ana açıklama / lore okuyucu | 17–19 | Regular; uzun metinde bol satır aralığı ve scroll |
| Buton / sekme | 14–20 | Semibold; dar panellerde çok satırlı |
| Teknik metadata | 12–16 | Mono; güçlü kontrast ve yeterli boşluk |
| Ana HUD rakamı | 34–58 | Mono; net rakam hizası |
| Görünür UI için minimum | 12 | 8–11 birimlik mikro yazılar kullanılmaz |

Özellikle dar Bastion-7 kontrol panelinde yazıyı 8–9'a düşürmek yerine **butonun yüksekliğini artır**; gerekirse metni kısalt veya satır kaydır. 3B ekranlarda font boyu dünya ölçeği ve pixel_size ile birlikte değerlendirilir.

## Tutarlılık kuralları

1. Yeni UI düğümleri `res://resources/ui/vex_theme.tres` temasını miras alır; kodla oluşturulan katmanlarda açıkça ata.
2. Uzun bilgi için semibold/monospace kullanma. Gövde metni regular, başlık semibold, teknik rakam mono olsun.
3. `RichTextLabel` normal/bold/mono fontları temada tanımlı kalır.
4. Font rengi ve arka plan arasında okunabilir kontrast koru; pasif butonları neredeyse görünmez yapma.
5. Otomatik satır kaydırma ve scroll'u kaldırma; metinleri `clip_text` ile saklama.
6. Türkçe `İ ı Ğ ğ Ş ş Ö ö Ü ü Ç ç`, İngilizce uzun başlıklar, rakamlar ve noktalama birlikte kontrol edilir.
7. Başlıklar/ayırıcılar için ayrıca `docs/ui_copy_style.md` takip edilir.

## Doğrulama

- `tests/ui_typography_audit.py`: font rolleri, küçük UI yazıları, önemli sahneler, runtime okuyucu ve 3B tabelalar.
- `validate_local.ps1`: bütün Python denetimleri ve Godot runtime testleri.
- Editörde/görevde kontrol: Türkçe ve İngilizce, 1920×1080 ve 1280×720; HUD + Bastion-7 yönetimi + üç terminal + silah arşivi + eğitim/bölüm brifingi + saha kaydı + duraklatma/ayarlar.
- Görsel doğrulama yapmadan tüm çözünürlüklerde taşma olmadığı iddia edilmez.
