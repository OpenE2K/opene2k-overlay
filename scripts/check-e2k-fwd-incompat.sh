#!/bin/bash
# ./check-e2k-fwd-incompat.sh [ROOT] (default ROOT: /usr/e2k-mcst-linux-gnu)
set -u

ROOT=${1:-/usr/e2k-mcst-linux-gnu}
INCOMPAT=$((0x10))
total=0
bad=0

export LC_ALL=C

scan() {
	find "$ROOT" -type d \( -path "$ROOT/tmp" -o -path "$ROOT/var/tmp" \) -prune -o -type f -print0 |
	while IFS= read -r -d '' f; do
		read -r -N4 m < "$f" 2>/dev/null

		[ "$m" = $'\x7fELF' ] || continue

		h=$(readelf -h "$f" 2>/dev/null) || continue

		case $h in *Elbrus*) ;; *) continue ;; esac

		printf '%s\t%s\n' "$(printf '%s\n' "$h" | awk '/Flags:/{print $2}')" "$f"
	done
}

while IFS=$'\t' read -r flags f; do
	total=$((total + 1))
	(( (flags & INCOMPAT) != 0 )) && {
		bad=$((bad + 1))
		printf 'INCOMPAT %s  %s\n' "$flags" "${f#"$ROOT"}"
	}
done < <(scan)

echo "scanned ${total} e2k ELF(s) under ${ROOT}; ${bad} with EF_E2K_INCOMPAT (0x10) set"
[ "${bad}" -eq 0 ]
