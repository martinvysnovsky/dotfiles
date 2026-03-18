---
description: Extract business costs from Fio banka CSV export
---

Process a Fio banka CSV export and extract business costs from a given month until today.

## Usage

`/naklady <path-to-csv> <year> <month>`

Arguments from user: $ARGUMENTS

Parse the arguments: first is the CSV file path, second is the year (e.g. 2026), third is the month number (e.g. 3). This defines the **start date** (1st of that month). Keep all entries from that date up to and including today.

## Input format

Fio banka CSV export with semicolon delimiter, UTF-8 with BOM, columns:
`"Dátum";"Objem";"Mena";"Protiúčet";"Kód banky";"Správa pre príjemcu";"Poznámka";"Typ"`

- Date format: `DD.MM.YYYY`
- Amount: comma decimal (e.g. `-57,06`), negative = cost, positive = income

## Processing rules

1. **Filter by date**: Keep only rows where the date is on or after the 1st of the specified month/year (up to and including today)
2. **Keep only costs**: Keep rows with negative amounts only — remove all positive amounts (incoming payments)
3. **Remove internal transfers**: Remove rows where Protiúčet is `SK0383300000002901380134` (own Fio account)
4. **Remove company payments**: Remove rows where Správa pre príjemcu contains `Ketler` or `Kelter` (case-insensitive) — both spelling variants exist in the data. This covers all payroll (vyplata), insurance (odvody), tax advances (dan-preddavok), DPH payments, and invoice payments (uhrada faktury)
5. **Categorize** remaining rows into 3 sections:
   - **Transakčná daň**: rows where Typ contains `Transakčná daň` — **only from the specified month** (not until today)
   - **Pohonné hmoty (Shell)**: rows where Správa pre príjemcu contains `SHELL` (case-insensitive) — **only from the specified month** (not until today)
   - **Regular costs**: everything else — from the specified month **until today**

## Output format

**4-column CSV** with semicolon delimiter. File: `naklady_od_MM_YYYY.csv` saved in the same directory as the input file. Do NOT modify the original file.

### Columns

| Column | Format | Example |
|--------|--------|---------|
| Dátum | `D.M.YYYY` (no leading zeros) | `7.1.2026` |
| Mesiac | `YYYY/M` (derived from each row's date) | `2026/3` |
| Popis | Short vendor name + Slovak month name (see rules below) | `Claude marec` |
| Suma | Positive number, comma decimal | `180,00` |

### Vendor name mapping

Extract vendor from the `Správa pre príjemcu` field (usually starts with `Nákup: VENDOR_NAME,`). Map known vendors:

| Pattern in message | Popis name |
|-------------------|------------|
| `CLAUDE.AI` | Claude |
| `ANTHROPIC` | Claude API |
| `SENTRY` | Sentry |
| `ATLASSIAN` | Atlassian |
| `Google ADS` | Google Ads |
| `Google CLOUD` | Google Cloud |
| `MUI.COM` | Mui Licence |
| `SHELL` | Shell |
| `MOJEO2` or `O2` | O2 |
| `DIRECT DEBIT` | O2 |
| `BITBUCKET` | Bitbucket |
| `HETZNER` | Hetzner |
| `VERCEL` | Vercel |
| `NAMECHEAP` | Namecheap |

For unknown vendors: extract the name after `Nákup:` up to the first comma. If no `Nákup:` prefix, use the raw Správa pre príjemcu field trimmed to first meaningful words.

### Popis month derivation rules

The **Mesiac column** always uses the bank posting date (`Dátum` column). But the **month name in Popis** follows these rules:

1. **Card transactions** (`Transakcia kartou`): Extract the `dne D.M.YYYY` date from the Správa pre príjemcu field. Use that date's month for the Slovak month name in Popis.
   - **Exception — Google Cloud**: Use `dne month - 1`. Google bills on the 1st of the next month for the previous month's usage (e.g. `dne 1.2.2026` → "január").
2. **O2 / DIRECT DEBIT** (`Inkaso` type): Use the bank posting date's month - 1. SEPA inkaso is posted in the following month (e.g. posted `20.2.2026` → "január").
3. **Transakčná daň**: Use the bank posting date's month.
4. **Other non-card transactions**: Use the bank posting date's month.

### Slovak month names

1=január, 2=február, 3=marec, 4=apríl, 5=máj, 6=jún, 7=júl, 8=august, 9=september, 10=október, 11=november, 12=december

### Section separators

Separate the 3 sections with a label row followed by the header row:

```
"Dátum";"Mesiac";"Popis";"Suma"
"1.3.2026";"2026/3";"Atlassian marec";"57,06"
...regular costs...

"TRANSAKČNÁ DAŇ"
"Dátum";"Mesiac";"Popis";"Suma"
"13.3.2026";"2026/3";"Transakčná daň";"3,60"
...
"";"";"Spolu";"9,43"

"POHONNÉ HMOTY (SHELL)"
"Dátum";"Mesiac";"Popis";"Suma"
"18.1.2026";"2026/1";"Shell január";"99,77"
...
"";"";"Spolu";"99,77"
```

## After creating the file

Print a summary:
- Number of regular costs, their total
- Number of transakčná daň entries, their total
- Number of Shell entries, their total
- Grand total of all costs
