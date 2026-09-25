#!/usr/bin/env python3
"""Koda gömülü _t("tr", "en") metinlerini translations/vex.csv + tr("ANAHTAR")'a taşır.

Kullanım:  python3 tools/extract_inline_text.py scripts/ui/dosya.gd ONEK [--apply]
--apply olmadan yalnız rapor verir. Aynı (tr, en) çifti CSV'de varsa mevcut anahtarı kullanır.
_t("A" % x, "B" % x) biçimi tr("KEY") % x olur; iki taraftaki biçim argümanları farklıysa
dönüştürülmez ve raporlanır (elle eşitle). Sonra `func _t` kaldırılır ve ilgili denetimler
tests/translation_text.py `with_translations` ile güncellenir.
"""
import re, sys, csv, io
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
src_path=ROOT/sys.argv[1]; prefix=sys.argv[2]; apply="--apply" in sys.argv
src=src_path.read_text(encoding="utf-8")
STR=r'"(?:[^"\\]|\\.)*"'
def unq(s): return s[1:-1]  # keep gdscript escapes (\n, \") as-is -> CSV unescape
csvp=ROOT/"translations/vex.csv"
rows=list(csv.reader(io.StringIO(csvp.read_text(encoding="utf-8"))))
existing={r[0]:(r[1],r[2]) for r in rows[1:]}
by_pair={v:k for k,v in existing.items()}
def slug(en):
    s=re.sub(r'%[sd]','',en); s=re.sub(r'\\n',' ',s)
    s=re.sub(r'[^A-Za-z0-9]+','_',s.upper()).strip('_')
    return '_'.join(s.split('_')[:6]) or "TEXT"
new={}
def repl_pair(tr_,en):
    pair=(tr_,en)
    if pair in by_pair: return 'tr("%s")'%by_pair[pair]
    k=prefix+"_"+slug(en); base=k; i=2
    while (k in existing and existing[k]!=pair) or (k in new and new[k]!=pair):
        k=f"{base}_{i}"; i+=1
    new[k]=pair; by_pair[pair]=k
    return 'tr("%s")'%k

# Ön adım: dil koşullu kalıpları _t("A", "B") biçimine indir.
COND=r'(?:turkish|is_turkish|TranslationServer\.get_locale\(\)\.begins_with\("tr"\))'
VAL=STR+r'(?:[ \t]*%[ \t]*[^\n]+?)?'
src=re.sub(r'\(\s*('+STR+r')\s+if\s+'+COND+r'\s+else\s+('+STR+r')\s*\)', r'_t(\1, \2)', src)
src=re.sub(r'('+STR+r')[ \t]+if[ \t]+'+COND+r'[ \t]+else[ \t]+('+STR+r')', r'_t(\1, \2)', src)
src=re.sub(r'if '+COND+r':\n(\t+)return ('+VAL+r')\n\t*return ('+VAL+r')\n',
           lambda m: 'return _t(%s, %s)\n' % (m.group(2), m.group(3)), src)
src=re.sub(r'if '+COND+r':\n(\t+)([\w.]+) = ('+VAL+r')\n(\t*)else:\n\t+\2 = ('+VAL+r')\n',
           lambda m: '%s = _t(%s, %s)\n' % (m.group(2), m.group(3), m.group(5)), src)
for var in ("turkish", "is_turkish"):
    decl=re.compile(r'\n\t+var '+var+r' := [^\n]+')
    if decl.search(src) and not re.search(r'\b'+var+r'\b', decl.sub('', src)):
        src=decl.sub('', src)


def scan_args(text,i):
    # i: index after '_t(' ; returns (args list, end index after ')')
    depth=0; args=[]; cur=i; j=i; n=len(text)
    while j<n:
        c=text[j]
        if c=='"':
            j+=1
            while text[j]!='"':
                j+= 2 if text[j]=='\\' else 1
        elif c in '([{': depth+=1
        elif c in ')]}':
            if depth==0:
                args.append(text[cur:j]); return args,j+1
            depth-=1
        elif c==',' and depth==0:
            args.append(text[cur:j]); cur=j+1
        j+=1
    raise ValueError
lead=re.compile(r'\s*('+STR+r')\s*(?:%\s*(.*))?\s*$',re.S)
def norm(e): return re.sub(r'\s+','',e or '').rstrip(',')
out=[]; i=0; bad=[]
for m in re.finditer(r'(?<![\w.])_t\(',src):
    if m.start()<i: continue
    if src[m.start()-5:m.start()]=='func ': continue
    args,end=scan_args(src,m.end())
    args=[a for a in args if a.strip()]
    ma=[lead.match(a) for a in args]
    if len(args)!=2 or not all(ma) or norm(ma[0].group(2))!=norm(ma[1].group(2)):
        bad.append(src[m.start():end][:100]); continue
    call=repl_pair(unq(ma[0].group(1)),unq(ma[1].group(1)))
    rest=ma[0].group(2)
    if rest:
        rest=rest.rstrip().rstrip(',').rstrip()
        call=call+" % "+rest
    out.append(src[i:m.start()]); out.append(call); i=end
out.append(src[i:]); out=''.join(out)
left=bad
print("new keys:",len(new),"unconverted:",len(bad)); [print("  ",b) for b in bad]
for k,v in list(new.items())[:5]: print(k,v)
if apply:
    src_path.write_text(out,encoding="utf-8")
    buf=io.StringIO(); w=csv.writer(buf,lineterminator="\n")
    for k,(a,b) in new.items(): w.writerow([k,a,b])
    t=csvp.read_text(encoding="utf-8"); t=t if t.endswith("\n") else t+"\n"
    csvp.write_text(t+buf.getvalue(),encoding="utf-8")
