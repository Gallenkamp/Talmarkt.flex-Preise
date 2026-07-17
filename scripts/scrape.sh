#!/usr/bin/env bash
set -euo pipefail

# WSW Tal.Markt Flex – Preise Scraper
# Speichert FINAL-Preise in data/YYYY/MM-Monatsname.csv (dedupliziert)
# Speichert FORECAST-Preise in data/forecasts/YYYY/MM-Monatsname.csv (jeder Snapshot)

API_URL="https://energiepreisuhr.wsw-online.de/api/energy-priceForecast"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"

# Deutsche Monatsnamen
declare -A MONATE=(
  [01]="Januar" [02]="Februar" [03]="März"     [04]="April"
  [05]="Mai"    [06]="Juni"    [07]="Juli"      [08]="August"
  [09]="September" [10]="Oktober" [11]="November" [12]="Dezember"
)

# API abrufen
echo "Abruf: ${API_URL}"
RESPONSE=$(curl -sf --max-time 30 "${API_URL}") || {
  echo "FEHLER: API-Abruf fehlgeschlagen" >&2
  exit 1
}

# Zeitstempel des Abrufs (UTC)
CAPTURED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# FINAL-Einträge extrahieren (from, to, value)
FINALS=$(echo "${RESPONSE}" | jq -r '
  .[] | select(.status == "FINAL") |
  [.from, .to, (.value | tostring)] | @csv
')

if [ -z "${FINALS}" ]; then
  echo "Keine FINAL-Einträge gefunden."
  exit 0
fi

COUNT=0
SKIPPED=0

while IFS= read -r line; do
  # from-Feld extrahieren (erstes CSV-Feld, z.B. "2026-06-07T00:00:00Z")
  FROM=$(echo "${line}" | cut -d',' -f1 | tr -d '"')

  # Jahr und Monat aus UTC-Zeitstempel
  YEAR=$(echo "${FROM}" | cut -c1-4)
  MONTH=$(echo "${FROM}" | cut -c6-7)
  MONATSNAME="${MONATE[${MONTH}]}"

  # Zielverzeichnis und -datei
  TARGET_DIR="${DATA_DIR}/${YEAR}"
  TARGET_FILE="${TARGET_DIR}/${MONTH}-${MONATSNAME}.csv"

  # Verzeichnis anlegen
  mkdir -p "${TARGET_DIR}"

  # Header schreiben falls Datei neu
  if [ ! -f "${TARGET_FILE}" ]; then
    echo "from,to,value,captured_at" > "${TARGET_FILE}"
  fi

  # Deduplizierung: prüfen ob from-Zeitstempel am Zeilenanfang bereits vorhanden
  if grep -q "^\"${FROM}\"" "${TARGET_FILE}" 2>/dev/null; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Zeile anhängen (mit Abruf-Zeitstempel)
  echo "${line},\"${CAPTURED_AT}\"" >> "${TARGET_FILE}"
  COUNT=$((COUNT + 1))

done <<< "${FINALS}"

echo "FINAL: ${COUNT} neue Einträge, ${SKIPPED} Duplikate übersprungen."

# --- FORECAST-Einträge speichern (ohne Deduplizierung – jeder Snapshot zählt) ---

FORECAST_DIR="${DATA_DIR}/forecasts"
FORECASTS=$(echo "${RESPONSE}" | jq -r '
  .[] | select(.status == "FORECAST") |
  [.from, .to, (.value | tostring)] | @csv
')

if [ -z "${FORECASTS}" ]; then
  echo "Keine FORECAST-Einträge gefunden."
  exit 0
fi

FC_COUNT=0

while IFS= read -r line; do
  FROM=$(echo "${line}" | cut -d',' -f1 | tr -d '"')

  YEAR=$(echo "${FROM}" | cut -c1-4)
  MONTH=$(echo "${FROM}" | cut -c6-7)
  MONATSNAME="${MONATE[${MONTH}]}"

  TARGET_DIR="${FORECAST_DIR}/${YEAR}"
  TARGET_FILE="${TARGET_DIR}/${MONTH}-${MONATSNAME}.csv"

  mkdir -p "${TARGET_DIR}"

  if [ ! -f "${TARGET_FILE}" ]; then
    echo "captured_at,from,to,value" > "${TARGET_FILE}"
  fi

  echo "\"${CAPTURED_AT}\",${line}" >> "${TARGET_FILE}"
  FC_COUNT=$((FC_COUNT + 1))

done <<< "${FORECASTS}"

echo "FORECAST: ${FC_COUNT} Einträge gespeichert."
