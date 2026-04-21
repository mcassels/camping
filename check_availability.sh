#!/usr/bin/env bash

# Check Torres del Paine Cuernos + Frances camping availability
# Nov 1 2026 – Dec 15 2026
#
# A night is "available" if at least one camping option has stock >= 3.
# Stock is the third param of operacion() in + buttons (server-side, pre-JS).
# -1 = sold out; positive integer = units available.
#
# NOTE: Frances HTML lists Campsite Ground in order 2p, 1p (reversed vs Cuernos).
# This script normalizes Frances columns to 1p, 2p to match Cuernos column order.

CUERNOS_URL="https://book.lastorres.com/Booking/NightIframe?SECTOR=SECTOR_CUERNOS&key=019dadfb-c899-7950-a901-4124bebfa9d5"
FRANCES_URL="https://book.lastorres.com/Booking/NightIframe?SECTOR=SECTOR_FRANCES&key=019dae0f-2e02-7d97-892a-73ed950ec5e7"
TORRES_URL="https://book.lastorres.com/Booking/NightIframe?SECTOR=SECTOR_CENTRAL_Y_NORTE&key=019dae1a-b664-79ee-87b8-033610dcd4b7"
OUTPUT="availability.csv"

echo "Date,Torres FE 1p,Torres FE 2p,Torres Semi 1p,Torres Semi 2p,Torres Ground 1p,Torres Ground 2p,Cuernos FE 1p,Cuernos FE 2p,Cuernos Semi 1p,Cuernos Semi 2p,Cuernos Ground 1p,Cuernos Ground 2p,Frances FE 1p,Frances FE 2p,Frances Semi 1p,Frances Semi 2p,Frances Ground 1p,Frances Ground 2p,Central,Cuernos,Frances" > "$OUTPUT"

echo "Checking Torres Central + Cuernos + Frances camping availability: Nov 1 – Dec 15 2026"
echo "Writing results to: $OUTPUT"
echo ""

# Extract 6 stock values from camping section, returned as newline-separated integers.
get_stocks() {
  local html="$1"
  echo "$html" \
    | awk '/<h4>Camping<\/h4>/{found=1} found && /<h4>/ && !/<h4>Camping/{exit} found{print}' \
    | grep -oE "operacion\('[^']+', 1, -?[0-9]+" \
    | sed "s/.*', 1, //"
}

# Build 6 CSV column values (Yes if stock>=3, else empty) from a stocks array.
# Sets global: cols array, sector_avail bool
build_cols() {
  local -n _stocks=$1
  local -n _cols=$2
  local -n _avail=$3
  _cols=()
  _avail=false
  for stock in "${_stocks[@]}"; do
    if [[ "$stock" =~ ^[0-9]+$ ]] && (( stock >= 3 )); then
      _cols+=("Yes")
      _avail=true
    else
      _cols+=("")
    fi
  done
  while (( ${#_cols[@]} < 6 )); do _cols+=(""); done
}

current="2026-11-01"

while [[ "$current" < "2026-12-15" ]]; do
  next=$(date -j -v+1d -f "%Y-%m-%d" "$current" "+%Y-%m-%d" 2>/dev/null \
        || date -d "$current + 1 day" "+%Y-%m-%d")

  cuernos_html=$(curl -s --max-time 15 "${CUERNOS_URL}&f_inicio=${current}&f_fin=${next}")
  frances_html=$(curl -s --max-time 15 "${FRANCES_URL}&f_inicio=${current}&f_fin=${next}")
  torres_html=$(curl -s --max-time 15 "${TORRES_URL}&f_inicio=${current}&f_fin=${next}")

  # Cuernos: FE1p, FE2p, Semi1p, Semi2p, Ground1p, Ground2p
  mapfile -t c_stocks < <(get_stocks "$cuernos_html")
  build_cols c_stocks c_cols c_avail
  c_summary=$($c_avail && echo "Yes" || echo "")

  # Frances: FE1p, FE2p, Semi1p, Semi2p, Ground2p, Ground1p (reversed last two in HTML)
  mapfile -t f_stocks_raw < <(get_stocks "$frances_html")
  f_stocks=(
    "${f_stocks_raw[0]}" "${f_stocks_raw[1]}"
    "${f_stocks_raw[2]}" "${f_stocks_raw[3]}"
    "${f_stocks_raw[5]}" "${f_stocks_raw[4]}"
  )
  build_cols f_stocks f_cols f_avail
  f_summary=$($f_avail && echo "Yes" || echo "")

  # Torres Central: FE1p, FE2p, Semi1p, Semi2p, Ground1p, Ground2p (same order as Cuernos)
  mapfile -t t_stocks < <(get_stocks "$torres_html")
  build_cols t_stocks t_cols t_avail
  t_summary=$($t_avail && echo "Yes" || echo "")

  if $c_avail || $f_avail || $t_avail; then
    echo "AVAILABLE: $current  [Central: $t_summary  Cuernos: $c_summary  Frances: $f_summary]"
    printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
      "$current" \
      "${t_cols[0]}" "${t_cols[1]}" "${t_cols[2]}" "${t_cols[3]}" "${t_cols[4]}" "${t_cols[5]}" \
      "${c_cols[0]}" "${c_cols[1]}" "${c_cols[2]}" "${c_cols[3]}" "${c_cols[4]}" "${c_cols[5]}" \
      "${f_cols[0]}" "${f_cols[1]}" "${f_cols[2]}" "${f_cols[3]}" "${f_cols[4]}" "${f_cols[5]}" \
      "$t_summary" "$c_summary" "$f_summary" \
      >> "$OUTPUT"
  fi

  current="$next"
  sleep 0.5
done

echo ""
echo "Done. Results written to $OUTPUT"
