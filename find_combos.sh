#!/usr/bin/env bash

# Find all valid 3-night sequences: Torres -> Cuernos -> Frances on consecutive nights.
# Reads availability.csv and writes valid_combos.csv.
#
# "Available" means the summary column (Central/Cuernos/Frances) is "Yes",
# which the original script sets when at least one site option has stock >= 3.

INPUT="availability.csv"
OUTPUT="valid_combos.csv"

echo "Torres Night 1,Torres Night 2,Cuernos Night,Frances Night" > "$OUTPUT"

# Load dates and per-campsite availability into parallel arrays.
# Skip header row (NR>1). Columns are 1-indexed in awk.
# Col 1: Date, Col 20: Central (Torres), Col 21: Cuernos, Col 22: Frances
declare -a dates torres_avail cuernos_avail frances_avail
declare -a torres_types cuernos_types frances_types

# Returns a comma-separated list of available camping types (FE, semi, ground)
# given the six Yes/empty column values for a site.
site_types() {
  local fe1=$1 fe2=$2 s1=$3 s2=$4 g1=$5 g2=$6
  local types=()
  [[ "$fe1" == "Yes" || "$fe2" == "Yes" ]] && types+=("FE")
  [[ "$s1"  == "Yes" || "$s2"  == "Yes" ]] && types+=("semi")
  [[ "$g1"  == "Yes" || "$g2"  == "Yes" ]] && types+=("ground")
  local IFS=', '
  echo "${types[*]}"
}

while IFS=',' read -r date t_fe1 t_fe2 t_s1 t_s2 t_g1 t_g2 \
                              c_fe1 c_fe2 c_s1 c_s2 c_g1 c_g2 \
                              f_fe1 f_fe2 f_s1 f_s2 f_g1 f_g2 \
                              central cuernos frances; do
  dates+=("$date")
  torres_avail+=("$central")
  cuernos_avail+=("$cuernos")
  frances_avail+=("$frances")
  torres_types+=("$(site_types "$t_fe1" "$t_fe2" "$t_s1" "$t_s2" "$t_g1" "$t_g2")")
  cuernos_types+=("$(site_types "$c_fe1" "$c_fe2" "$c_s1" "$c_s2" "$c_g1" "$c_g2")")
  frances_types+=("$(site_types "$f_fe1" "$f_fe2" "$f_s1" "$f_s2" "$f_g1" "$f_g2")")
done < <(tail -n +2 "$INPUT")

count=0
total=${#dates[@]}

for (( i=0; i <= total-4; i++ )); do
  j=$(( i + 1 ))
  k=$(( i + 2 ))
  l=$(( i + 3 ))

  # Verify the four dates are actually consecutive calendar days.
  date_i="${dates[$i]}"
  date_j="${dates[$j]}"
  date_k="${dates[$k]}"
  date_l="${dates[$l]}"

  expected_j=$(date -j -v+1d -f "%Y-%m-%d" "$date_i" "+%Y-%m-%d" 2>/dev/null \
               || date -d "$date_i + 1 day" "+%Y-%m-%d")
  expected_k=$(date -j -v+1d -f "%Y-%m-%d" "$date_j" "+%Y-%m-%d" 2>/dev/null \
               || date -d "$date_j + 1 day" "+%Y-%m-%d")
  expected_l=$(date -j -v+1d -f "%Y-%m-%d" "$date_k" "+%Y-%m-%d" 2>/dev/null \
               || date -d "$date_k + 1 day" "+%Y-%m-%d")

  [[ "$date_j" != "$expected_j" ]] && continue
  [[ "$date_k" != "$expected_k" ]] && continue
  [[ "$date_l" != "$expected_l" ]] && continue

  if [[ "${torres_avail[$i]}" == "Yes" ]] && \
     [[ "${torres_avail[$j]}" == "Yes" ]] && \
     [[ "${cuernos_avail[$k]}" == "Yes" ]] && \
     [[ "${frances_avail[$l]}" == "Yes" ]]; then
    printf '"%s (%s)","%s (%s)","%s (%s)","%s (%s)"\n' \
      "${dates[$i]}" "${torres_types[$i]}" \
      "${dates[$j]}" "${torres_types[$j]}" \
      "${dates[$k]}" "${cuernos_types[$k]}" \
      "${dates[$l]}" "${frances_types[$l]}" \
      >> "$OUTPUT"
    (( count++ ))
  fi
done

echo "Found $count valid 3-night combinations. Results written to $OUTPUT"
