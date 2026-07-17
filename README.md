# Tal.Markt Flex – Preisarchiv

Automatische Archivierung der stündlichen Strompreise des WSW Tal.Markt Flex Tarifs.

## Datenquelle

- [WSW Energiepreisuhr API](https://energiepreisuhr.wsw-online.de/api/energy-priceForecast) – Tal.Markt Flex Endkundenpreise
- [aWATTar API](https://api.awattar.de/v1/marketdata) – EPEX Day-Ahead Spotpreise (Großhandel)

## Struktur

```
data/
  2026/
    06-Juni.csv
    07-Juli.csv
  forecasts/
    2026/
      06-Juni.csv
      07-Juli.csv
  epex/
    2026/
      06-Juni.csv
      07-Juli.csv
```

### FINAL-Preise (`data/YYYY/MM-Monatsname.csv`)

Bestätigte Stundenpreise, dedupliziert (ein Eintrag pro Stunde):

| Spalte        | Beschreibung                            |
|---------------|-----------------------------------------|
| `from`        | Beginn des Zeitfensters (ISO 8601, UTC) |
| `to`          | Ende des Zeitfensters (ISO 8601, UTC)   |
| `value`       | Preis in Cent/kWh                       |
| `captured_at` | Zeitpunkt des API-Abrufs (UTC)          |

### Forecast-Snapshots (`data/forecasts/YYYY/MM-Monatsname.csv`)

Prognosewerte bei jedem Abruf. Pro Stunde können mehrere Einträge existieren (ein Snapshot je Abruf), um die Schwankung und Treffsicherheit der Prognose auszuwerten.

| Spalte        | Beschreibung                            |
|---------------|-----------------------------------------|
| `captured_at` | Zeitpunkt des API-Abrufs (UTC)          |
| `from`        | Beginn des Zeitfensters (ISO 8601, UTC) |
| `to`          | Ende des Zeitfensters (ISO 8601, UTC)   |
| `value`       | Prognosewert in Cent/kWh                |

### EPEX-Spotpreise (`data/epex/YYYY/MM-Monatsname.csv`)

EPEX Day-Ahead Großhandelspreise (Quelle: aWATTar API), umgerechnet in Cent/kWh. Dedupliziert, ein Eintrag pro Stunde. Ermöglicht den direkten Vergleich mit dem WSW-Endkundenpreis.

| Spalte  | Beschreibung                            |
|---------|-----------------------------------------|
| `from`  | Beginn des Zeitfensters (ISO 8601, UTC) |
| `to`    | Ende des Zeitfensters (ISO 8601, UTC)   |
| `value` | EPEX-Spotpreis in Cent/kWh              |

## Zeitplan

GitHub Actions ruft die API alle 12 Stunden ab (08:00 und 20:00 MESZ). Neue `FINAL`-Einträge werden dedupliziert angehängt, `FORECAST`-Einträge werden bei jedem Abruf als Snapshot gespeichert.

Der Workflow kann auch manuell über *Actions → WSW Preise scrapen → Run workflow* gestartet werden.

## Lokal ausführen

```bash
bash scripts/scrape.sh
```

Voraussetzungen: `curl`, `jq`.
