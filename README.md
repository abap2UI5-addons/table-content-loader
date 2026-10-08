# table-content-loader

[![abap2UI5-addons](https://img.shields.io/badge/abap2UI5--addons-app-1873b4)](https://github.com/abap2UI5-addons)
[![ABAP](https://img.shields.io/badge/ABAP-Cloud%20%7C%20Standard%20%E2%89%A5%207.50-blue)](#installation)
[![abap2UI5](https://img.shields.io/badge/requires-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![popups](https://img.shields.io/badge/requires-popups-blue)](https://github.com/abap2UI5-addons/popups)
[![abap2xlsx](https://img.shields.io/badge/requires-abap2xlsx-blue)](https://github.com/abap2xlsx/abap2xlsx)
[![License](https://img.shields.io/github/license/abap2UI5-addons/table-content-loader)](LICENSE)
<br>
[![ABAP Cloud](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/table-content-loader/abap-cloud.yaml?branch=main&label=ABAP%20Cloud)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/abap-cloud.yaml)
[![ABAP Standard](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/table-content-loader/abap-standard.yaml?branch=main&label=ABAP%20Standard)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/abap-standard.yaml)
[![rename](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/table-content-loader/check-rename.yaml?branch=main&label=rename)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-rename.yaml)
[![check-abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Ftable-content-loader%2Fbadges%2Fcheck-abap2ui5.json)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-abap2ui5.yaml)
[![abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Ftable-content-loader%2Fbadges%2Fabap2ui5.json)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-abap2ui5.yaml)

**Upload, edit and download the content of database tables as JSON, CSV or
XLSX - in the browser.** A start page with one tile per format and direction
leads into small step-by-step abap2UI5 apps: pick a table, convert its content
to or from a file, preview it and download it or save it to the database. For
developers who move test data or Z table content between systems, on ABAP
Cloud as well as on Standard ABAP.

> Part of [abap2UI5-addons](https://github.com/abap2UI5-addons) - addons and apps for [abap2UI5](https://github.com/abap2UI5/abap2UI5), installed with [abapGit](https://abapgit.org).

<img width="700" alt="Table Content Loader start page with tiles for JSON, CSV and XLSX upload and download" src="https://github.com/abap2UI5-addons/table-content-loader/assets/102328295/73e044dc-137d-49fe-b6ac-0247fb542a0f">

## Why

Getting the content of a table into a file and back is a frequent chore -
test data for another system, a Z table filled from a spreadsheet, a quick
export for a colleague. table-content-loader does it in the browser, with the
table chosen at runtime, and without SAP GUI or Eclipse.

It is a developer tool, not an end-user app - read [Security](#security)
before you use it beyond a development system.

## Installation

**Requirements**

- ABAP Cloud (S/4 Public Cloud, BTP ABAP Environment, S/4 Private Cloud or
  On-Premise with ABAP for Cloud) or Standard ABAP on SAP NetWeaver AS ABAP
  7.50 or higher. XLSX upload and download are not ready for ABAP Cloud yet
  (see [Limitations & Todo](#limitations--todo)).
- [abap2UI5](https://github.com/abap2UI5/abap2UI5)
- [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups) - file
  upload, input and confirmation popups
- [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx) - reads and writes the
  XLSX files (`z2ui5_cl_tcl_xlsx_api`)

**Steps** - with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5)
2. [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups)
3. [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)
4. this repository (branch `main`)

**Start** - open the start page like any abap2UI5 app:

```
?app_start=z2ui5_cl_tcl_app_00
```

## Usage

The start page `z2ui5_cl_tcl_app_00` shows one tile per format and direction.
Tiles whose app is not finished yet are shown disabled; every app can also be
started directly with `?app_start=<class>`.

| Tile | Class | What you do |
|---|---|---|
| JSON - Upload DB Content | `z2ui5_cl_tcl_app_01` | (1) upload a JSON file, (2) check the target table, (3) convert the JSON into the table's rows, (4) preview the first rows, (5) save - the table content is deleted and replaced by the file's rows, after a confirmation |
| JSON - Download DB Content | `z2ui5_cl_tcl_app_03` | (1) set the table, (2) convert its content to JSON, (3) preview the JSON, (4) download it |
| CSV - Upload / Download DB Content | `z2ui5_cl_tcl_app_04` | upload a CSV file, view or edit its content as a table, download it as CSV (no database write yet) |
| XLSX - Upload DB Content | `z2ui5_cl_tcl_app_05` | upload an XLSX file, view or edit its content as a table, download it as XLSX (no database write yet) |
| XLSX - Download DB Content | `z2ui5_cl_tcl_app_06` | create a draft for a table, then (1) preview the data, (2) configure the sheet head, (3) configure the columns, (4) preview the XLSX, (5) download it; drafts can be saved and loaded again |

`z2ui5_cl_tcl_app_02` (view/edit/download) is not on the start page: it
shows the import - edit - export round trip on a demo table of flight
connections.

## Features

* Upload & Download Data
* Table Content Editor
* Data Preview

## Security

This is a developer tool. It reads from and writes to any table the user names, without an authorization check of its own (the Z/Y namespace hint on write is only a warning, not an enforced restriction). Before using it beyond a development system, add your own authorization checks (e.g. `AUTHORITY-CHECK` on `S_TABU_DIS`/`S_TABU_NAM`) and restrict who may run the app.

## Limitations & Todo

* CSV Upload & Download
* JSON Download
* XLSX Upload/Download for ABAP Cloud

## Development

```sh
npm ci
npm run check   # abaplint Standard + ABAP Cloud, abap2UI5-linter, rename check
```

`npm run check` runs the same steps as CI. The manual `build-rename` workflow
pushes a namespace-renamed copy to a branch `rename_<name>` for a parallel
installation.

## Contributing

Issues and pull requests are welcome - whether you're fixing bugs, adding new
functionality, or improving documentation. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT - see [LICENSE](LICENSE).
