#!/bin/bash
# Publica uma versão da Noosfera na vitrine (este repositório público, só com instaladores).
#
#   ./publicar.sh android 1.134.0 caminho/do.apk [notas.md] [--tambem-comentor]
#   ./publicar.sh mac 1.10.1 caminho/do.dmg [notas.md]
#
# Cria a release android-vX.Y.Z ou mac-vX.Y.Z com o instalador de nome fixo (Noosfera-Android.apk /
# Noosfera-Mac.dmg) e a linha "SHA-256: …" no fim das notas — é dela que os apps tiram o hash para conferir o
# arquivo antes de instalar. A página https://consciencia.eco.br/noosfera e o /noosfera/versao enxergam a release
# nova em até 5 minutos.
#
# --tambem-comentor (só Android, na transição): publica também como vX.Y.Z no claudiogonzaga/comentor, onde os
# celulares com o atualizador antigo ainda procuram. Some quando o comentor ficar privado.
set -euo pipefail
REPO=claudiogonzaga/noosfera-releases
so="${1:?android|mac}"; versao="${2:?versão}"; arquivo="${3:?instalador}"; notas="${4:-}"; extra="${5:-}"
[[ "$notas" == --* ]] && { extra="$notas"; notas=""; }
case "$so" in
  android) nome=Noosfera-Android.apk ;;
  mac) nome=Noosfera-Mac.dmg ;;
  *) echo "plataforma: android ou mac" >&2; exit 1 ;;
esac
[[ -f "$arquivo" ]] || { echo "não achei $arquivo" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cp "$arquivo" "$tmp/$nome"
hash="$(shasum -a 256 "$tmp/$nome" | cut -d' ' -f1)"
corpo="$tmp/notas.md"
{ [[ -n "$notas" ]] && cat "$notas" && echo; echo; echo "SHA-256: $hash"; } > "$corpo"
titulo="Noosfera $versao ($([[ $so == android ]] && echo Android || echo Mac))"
gh release create "$so-v$versao" "$tmp/$nome" -R "$REPO" --title "$titulo" --notes-file "$corpo"
if [[ "$extra" == "--tambem-comentor" && "$so" == "android" ]]; then
  cp "$arquivo" "$tmp/noosfera-$versao.apk"
  gh release create "v$versao" "$tmp/noosfera-$versao.apk" -R claudiogonzaga/comentor --title "Noosfera $versao" --notes-file "$corpo"
fi
echo "publicada: $so $versao · SHA-256 $hash"
