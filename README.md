![ABAP](https://img.shields.io/badge/ABAP-Standard%20%E2%86%92%20Cloud-blue)
[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__tcl-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Ftable-content-loader%2Fmain%2F.github%2Fbadges%2Fabap2ui5.json)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-abap2ui5.yaml)
<br><br>
[![abap-standard](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/abap-cloud.yaml)
<br>
[![check-abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Ftable-content-loader%2Fmain%2F.github%2Fbadges%2Fcheck-abap2ui5.json)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-abap2ui5.yaml)
[![check-rename](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-rename.yaml/badge.svg)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/check-rename.yaml)
<br>
[![build-rename](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/build-rename.yaml/badge.svg)](https://github.com/abap2UI5-addons/table-content-loader/actions/workflows/build-rename.yaml)

# Table Content Loader
Upload, Edit & Download Table Content <br><br>
_Supported Formats: JSON, CSV, XLSX..._

#### Key Features
* Upload & Download Data
* Table Content Editor
* Data Preview

#### Compatibility
* S/4 Public Cloud and BTP ABAP Environment (ABAP for Cloud)
* S/4 Private Cloud or On-Premise (ABAP for Cloud, Standard ABAP)
* SAP NetWeaver AS ABAP 7.50 or higher (Standard ABAP)

#### Security
This is a developer tool. It reads from and writes to any table the user names, without an authorization check of its own (the Z/Y namespace hint on write is only a warning, not an enforced restriction). Before using it beyond a development system, add your own authorization checks (e.g. `AUTHORITY-CHECK` on `S_TABU_DIS`/`S_TABU_NAM`) and restrict who may run the app.

#### Dependencies
* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)

#### Limitations & Todo
* CSV Upload & Download
* JSON Download
* XLSX Upload/Download for ABAP Cloud

#### Demo
<img width="700" alt="Table Content Loader start page with tiles for JSON, CSV and XLSX upload and download" src="https://github.com/abap2UI5-addons/table-content-loader/assets/102328295/73e044dc-137d-49fe-b6ac-0247fb542a0f">

#### Contribution & Support
Pull requests are welcome! Whether you're fixing bugs, adding new functionality, or improving documentation, your contributions are highly appreciated. If you encounter any issues, feel free to open an issue.
