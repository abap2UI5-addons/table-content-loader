# table-content-loader

[![abap2UI5-addons](https://img.shields.io/badge/abap2UI5--addons-app-1873b4)](https://github.com/abap2UI5-addons)
[![ABAP](https://img.shields.io/badge/ABAP-Cloud%20%7C%20Standard%20%E2%89%A5%207.50%20%7C%207.02-blue)](#installation)
[![abap2UI5](https://img.shields.io/badge/requires-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![layout-management](https://img.shields.io/badge/requires-layout--management-blue)](https://github.com/abap2UI5-addons/layout-management)
[![popups](https://img.shields.io/badge/requires-popups-blue)](https://github.com/abap2UI5-addons/popups)
[![abap2xlsx](https://img.shields.io/badge/requires-abap2xlsx-blue)](https://github.com/abap2xlsx/abap2xlsx)
[![License](https://img.shields.io/github/license/abap2UI5-addons/table-content-loader)](LICENSE)
<br>
[![CI](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/table-content-loader/ci.yaml?branch=main&label=CI)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/ci.yaml)
[![ABAP 7.02](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/table-content-loader/ci-702.yaml?branch=main&label=ABAP%207.02)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/ci-702.yaml)
[![check-abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Ftable-content-loader%2Fbadges%2Fcheck-abap2ui5.json)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/ci.yaml)
[![abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Ftable-content-loader%2Fbadges%2Fabap2ui5.json)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/ci.yaml)

**Upload, edit and download the content of database tables as JSON, CSV or
XLSX - in the browser.** A start page with one tile per format and direction
leads into small step-by-step abap2UI5 apps: pick a table, convert its content
to or from a file, preview it and download it or save it to the database. For
developers who move test data or Z table content between systems, on ABAP
Cloud as well as on Standard ABAP.

> Part of [abap2UI5-addons](https://github.com/abap2UI5-addons) - addons and apps for [abap2UI5](https://github.com/abap2UI5/abap2UI5), installed with [abapGit](https://abapgit.org). Documentation: [abap2ui5-addons.github.io/table-content-loader](https://abap2ui5-addons.github.io/table-content-loader/).

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
  (see [Limitations](#limitations)).
- NetWeaver 7.02 - 7.40: the branch `702`, downported automatically from
  `main` on every push - pull abap2UI5, layout-management and popups from
  their `702` branches as well
- [abap2UI5](https://github.com/abap2UI5/abap2UI5)
- [abap2UI5-addons/layout-management](https://github.com/abap2UI5-addons/layout-management) -
  needed by popups, whose value help and search help popups fail activation
  without it
- [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups) - file
  upload, input and confirmation popups
- [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx) - reads and writes the
  XLSX files (`z2ui5_cl_tcl_xlsx_api`)

**Steps** - with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5)
2. [abap2UI5-addons/layout-management](https://github.com/abap2UI5-addons/layout-management)
3. [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups)
4. [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)
5. this repository - branch `main`, or `702` on NetWeaver 7.02 - 7.40

**Start** - open the start page like any abap2UI5 app:

```
?app_start=z2ui5_cl_tcl_app_00
```

### Parallel installation (namespace rename)

To run a second copy next to the original in the same system, rename it the
way abap2UI5 itself is renamed: run the workflow **build-rename** (Actions →
build-rename → Run workflow) with the name your abap2UI5 installation was
renamed to - e.g. `ZMYUI5` or `/CA2UI5/`. It pushes the branch `rename_<name>`, in
which every object and every reference to abap2UI5 and to the addons this one
needs carries that name; pull it with abapGit. Rename abap2UI5 and every addon
of the installation with the same name.

## Usage

The start page `z2ui5_cl_tcl_app_00` shows one tile per format and direction.
Tiles whose app is not finished yet are shown disabled; every app can also be
started directly with `?app_start=<class>`.

| Tile | Class | What you do |
|---|---|---|
| JSON - Upload DB Content | `z2ui5_cl_tcl_app_01` | tile disabled, start it directly. (1) upload a JSON file, (2) check the target table, (3) convert the JSON into the table's rows, (4) preview the first rows, (5) save - after a confirmation the file's rows are written to the table: a row whose key exists is overwritten, a new key is inserted, rows that are not in the file stay (`MODIFY`) |
| JSON - Download DB Content | `z2ui5_cl_tcl_app_03` | (1) set the table, (2) convert its content to JSON, (3) preview the JSON, (4) download it |
| CSV - Upload / Download DB Content | `z2ui5_cl_tcl_app_04` | upload a CSV file, view or edit its content as a table, download it as CSV (no database write yet). The file is read as UTF-8 (Excel's "CSV UTF-8"), and as Windows-1252 (Excel's plain "CSV" on Windows) when it is not valid UTF-8 |
| XLSX - Upload DB Content | `z2ui5_cl_tcl_app_05` | upload an XLSX file, view or edit its content as a table, download it as XLSX (no database write yet) |
| XLSX - Download DB Content | `z2ui5_cl_tcl_app_06` | create a draft for a table, then (1) preview the data, (2) configure the sheet head, (3) configure the columns, (4) preview the XLSX, (5) download it; **Load** reads the table's rows again (the draft itself is not stored, see [Limitations](#limitations)) |
| Demo - Import, Edit, Export | `z2ui5_cl_tcl_app_02` | the import - edit - export round trip on a demo table of flight connections |

## Features

* Upload & Download Data
* Table Content Editor
* Data Preview

## Security

This is a developer tool. It reads from any table the user names and, without an authorization check of its own, writes into tables of the Z/Y namespace (the JSON upload is the only app that writes). Before using it beyond a development system, add your own authorization checks (e.g. `AUTHORITY-CHECK` on `S_TABU_DIS`/`S_TABU_NAM`) and restrict who may run the app.

The write boundary is a check of the table **name**, not of who owns the data:

* the upload writes only into a table whose name starts with `Z` or `Y`;
* it refuses every table of abap2UI5 and of its addons - every name with the
  framework's prefix (`Z2UI5_`, or the name a namespace rename gave it). Their
  drafts, configuration and histories are read back as program state, so rows
  planted there would act in other users' sessions. A table of your own that
  starts with that prefix is refused as well;
* any other Z/Y table is written as the file says, whoever's data it holds -
  an existing key is overwritten.

**That is a deliberate decision, not an open item.** abap2UI5 itself has no
central authorization hook either: the framework leaves the check to the app,
and this addon leaves it to the installation. Which check is the right one -
`S_TABU_NAM`, `S_TABU_DIS`, an authorization object of your own, or what ABAP
Cloud releases - depends on the system the addon runs in, so none is built in
and none is planned. Whoever opens the app to more people than its developers
adds the check that fits their system.

## Limitations

* CSV Upload & Download
* JSON Upload - the start-page tile is disabled
* XLSX Upload/Download for ABAP Cloud
* Saving and reloading an XLSX draft

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
