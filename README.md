# Torres del Paine Camping Availability

Scripts for finding back-to-back availability across Torres → Cuernos → Frances campsites (Nov 1 – Dec 15 2026).

## Steps

1. **Fetch availability** — scrapes the booking site and writes results to `availability.csv`:
   ```
   bash check_availability.sh
   ```

2. **Find valid itineraries** — reads `availability.csv` and writes 4-night combinations (2 nights Torres, 1 Cuernos, 1 Frances) to `valid_combos.csv`:
   ```
   bash find_combos.sh
   ```

## Output

`valid_combos.csv` has one row per valid itinerary. Each cell shows the date and available camping types (FE, semi, ground) for that night.

## Notes

- A night is considered available if at least one camping option has **3+ spots**.
- Dates in `availability.csv` must be consecutive for a combo to be valid.
