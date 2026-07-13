# Table Content Loader
Upload, Edit & Download Table Content <br><br>
_Supported Formats: JSON, CSV, XLSX..._

#### Key Features
* Upload & Download Data
* Table Content Editor
* Data Preview

#### Compatibility
* S/4 Public Cloud ABAP and BTP ABAP Environment (ABAP for Cloud)
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
Pull Requests are welcome! Whether you're fixing a bug, adding new functionality, or improving the documentation, your contributions are always appreciated. If you run into problems, feel free to open an issue.
