# VEX — Arayüz Metni ve Tipografik Hiyerarşi

Oyuncuya görünen başlıklar ve bildirimler tutarlı, kısa ve kolay taranabilir olmalı. Eski `//` ayırıcısı arayüz metinlerinde kullanılmaz. Dosya yollarındaki `res://`, `user://`, `uid://` ve kod işleçleri bu kuralın dışındadır.

## Görsel dil

- **Başlık:** Mümkünse tek güçlü ad kullan: `BASTION-7 ÜS KONTROLÜ`, `TESİSİN GÜNCEL DURUMU`. Gereksiz marka öneki ve ikinci açıklamayı sil.
- **Bölüm / rapor başlığı:** Tek bir uzun çizgiyle adlandır: `BÖLÜM 01 — İLK KIRILMA`. Türkçe/İngilizce başlık yapısı eşdeğer olmalı.
- **Kısa, eş ağırlıklı veri kümeleri:** Sınırlı sayıda hafif orta nokta kullan: `KAYIT 12 · EDİNİLEN 5 · KUŞANILAN 2`. Uzun cümleleri veya her başlığı noktalarla bölme.
- **Eylem bildirimi:** Durumla talimatı doğal iki cümleye ayır: `ŞARJÖR BOŞ. R İLE DOLDUR.` Karmaşık hedefleri daha kısa ve açık yaz.
- **Liste kartları:** İlk satır nesne adı, ikinci satır sade durum. Durum satırını sembolle başlatma. Örnek: `SİLAH ATÖLYESİ\nBÖLÜM 02 GEREKLİ`.
- **Dünya tabelası:** `VEX 01` üst kodu ve `R03 · SEC` oda kodu. Kodlar dil bağımsız; oyuncuya gösterilen eski `VEX-01` prototip bölüm adları kullanılmaz.
- **Erişilebilirlik / sığma:** Tek satır başlıklarda az kelime, uzun içerikte otomatik satır kaydırma. Çeviri büyümesini düşün; metni kesen `clip_text` uygulama.
- **Yerelleştirme:** Metnin asıl kaynağı `translations/vex.csv` veya ilgili `chapter0N.csv`. İki dilde aynı bilgi/placeholder sayısını koru. Sahne editör önizleme metinleri de bu standardı izler.

## Kalite kapısı

`tests/ui_copy_separator_audit.py` oyun senaryoları, GDScript'ler ve çeviri tablolarında unutulan mekanik ayırıcıları denetler. `validate_local.ps1` veya `tools/validate.sh` bu denetimi içerir. Görsel metin taşması için Godot'ta TR/EN 1280×720 ve 1920×1080 kontrol edilir.
