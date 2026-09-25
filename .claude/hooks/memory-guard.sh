#!/usr/bin/env bash
# Stop hook: kod/içerik değiştiyse ama .claude/HAFIZA.md güncellenmediyse bitirmeyi bir kez engeller.
input="$(cat)"
# Aynı durdurma döngüsünde ikinci kez engelleme (sonsuz döngü koruması).
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
	exit 0
fi
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed="$(
	{
		git rev-parse --verify -q origin/main >/dev/null && git diff --name-only origin/main...HEAD
		git diff --name-only
		git diff --name-only --cached
		git ls-files --others --exclude-standard
	} 2>/dev/null | sort -u
)"
[ -z "$changed" ] && exit 0
printf '%s\n' "$changed" | grep -qx '.claude/HAFIZA.md' && exit 0

cat <<'JSON'
{"decision":"block","reason":"Kod/içerik değişti ama .claude/HAFIZA.md güncellenmedi. Kullanıcı istemese de şimdi güncelle: yapılanı 'Yapılanlar'a tek satır ekle, biten işi 'Açık işler'den düş, yeni karar/tercih/dersi ilgili bölüme yaz; sonra aynı PR'a dahil edip bitir."}
JSON
exit 0
