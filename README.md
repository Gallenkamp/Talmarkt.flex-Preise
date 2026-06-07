# Tal.Markt Flex – Preisarchiv

Automatische Archivierung der stündlichen Strompreise des WSW Tal.Markt Flex Tarifs.

## Datenquelle

[WSW Energiepreisuhr API](https://energiepreisuhr.wsw-online.de/api/energy-priceForecast)

## Struktur

```
data/
  2026/
    06-Juni.csv
    07-Juli.csv
  2027/
    01-Januar.csv
    ...
```

Jede CSV-Datei enthält die bestätigten (`FINAL`) Stundenpreise eines Monats:

| Spalte  | Beschreibung                          |
|---------|---------------------------------------|
| `from`  | Beginn des Zeitfensters (ISO 8601, UTC) |
| `to`    | Ende des Zeitfensters (ISO 8601, UTC)   |
| `value` | Preis in Cent/kWh                       |

## Zeitplan

GitHub Actions ruft die API alle 12 Stunden ab (08:00 und 20:00 MESZ). Nur neue `FINAL`-Einträge werden angehängt – Duplikate werden übersprungen.

Der Workflow kann auch manuell über *Actions → WSW Preise scrapen → Run workflow* gestartet werden.

## Lokal ausführen

```bash
bash scripts/scrape.sh
```

Voraussetzungen: `curl`, `jq`.
