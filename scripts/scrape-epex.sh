#!/usr/bin/env bash
set -euo pipefail

# EPEX Day-Ahead Spotpreise via aWATTar API
# Speichert stündliche Börsenpreise in data/epex/YYYY/MM-Monatsname.csv
# Preise werden von EUR/MWh in Cent/kWh umgerechnet (÷ 10)

API_BASE="https://api.awattar.de/v1/marketdata"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data/epex"

declare -A MONATE=(
  [01]="Januar" [02]="Februar" [03]="März"     [04]="April"
  [05]="Mai"    [06]="Juni"    [07]="Juli"      [08]="August"
  [09]="September" [10]="Oktober" [11]="November" [12]="Dezember"
)

# Zeitraum: optional START_DATE und END_DATE als YYYY-MM-DD, sonst letzte 48h
if [ -n "${1:-}" ] && [ -n "${2:-}" ]; then
  START_MS=$(date -u -d "$1" '+%s')000
  END_MS=$(date -u -d "$2" '+%s')000
else
  START_MS=$(date -u -d '2 days ago 00:00' '+%s')000
  END_MS=$(date -u '+%s')000
fi

echo "Abruf EPEX-Daten: $(date -u -d @$((${START_MS%000})) '+%Y-%m-%d') bis $(date -u -d @$((${END_MS%000})) '+%Y-%m-%d')"

RESPONSE=$(curl -sf --max-time 30 "${API_BASE}?start=${START_MS}&end=${END_MS}") || {
  echo "FEHLER: aWATTar-API-Abruf fehlgeschlagen" >&2
  exit 1
}

ENTRIES=$(echo "${RESPONSE}" | jq -r '
  .data[] |
  [
    (.start_timestamp / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ")),
    (.end_timestamp / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ")),
    (.marketprice / 10 | . * 100000 | round / 100000 | tostring)
  ] | @csv
')

if [ -z "${ENTRIES}" ]; then
  echo "Keine EPEX-Einträge gefunden."
  exit 0
fi

COUNT=0
SKIPPED=0

while IFS= read -r line; do
  FROM=$(echo "${line}" | cut -d',' -f1 | tr -d '"')

  YEAR=$(echo "${FROM}" | cut -c1-4)
  MONTH=$(echo "${FROM}" | cut -c6-7)
  MONATSNAME="${MONATE[${MONTH}]}"

  TARGET_DIR="${DATA_DIR}/${YEAR}"
  TARGET_FILE="${TARGET_DIR}/${MONTH}-${MONATSNAME}.csv"

  mkdir -p "${TARGET_DIR}"

  if [ ! -f "${TARGET_FILE}" ]; then
    echo "from,to,value" > "${TARGET_FILE}"
  fi

  if grep -q "^\"${FROM}\"" "${TARGET_FILE}" 2>/dev/null; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "${line}" >> "${TARGET_FILE}"
  COUNT=$((COUNT + 1))

done <<< "${ENTRIES}"

echo "EPEX: ${COUNT} neue Einträge, ${SKIPPED} Duplikate übersprungen."
