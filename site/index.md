---
layout: home

hero:
  name: "Table Content Loader"
  text: "Upload, edit and download table content as JSON, CSV or XLSX."
  image:
    src: /favicon.png
    alt: abap2UI5
  actions:
    - theme: brand
      text: Get started
      link: /guide
    - theme: alt
      text: GitHub
      link: https://github.com/abap2UI5-addons/table-content-loader
    - theme: alt
      text: All addons
      link: https://abap2ui5-addons.github.io/

features:
  - title: "Start page with one tile per format (JSON, CSV, XLSX) and direction"
  - title: "JSON upload: convert a file into table rows, preview and save with MODIFY"
  - title: "JSON download: convert table content to JSON, preview and download"
  - title: "CSV and XLSX upload: view or edit the content as a table and download it again"
  - title: "XLSX download with configurable sheet head and columns"
  - title: "Table chosen at runtime, no SAP GUI or Eclipse needed"
---

## What it does

A start page with one tile per format and direction leads into small step-by-step abap2UI5 apps: pick a table, convert its content to or from a file, preview it and download it or save it to the database. It is meant for developers who move test data or Z table content between systems, on ABAP Cloud as well as on Standard ABAP. It is a developer tool, not an end-user app: it reads from any table the user names and writes into Z/Y tables without an authorization check of its own.

## Requirements

- abap2UI5
- Standard ABAP on SAP NetWeaver AS ABAP 7.50 or higher
- ABAP Cloud supported (XLSX upload and download not ready for ABAP Cloud yet)
- abap2UI5-addons/popups (file upload, input and confirmation popups)
- abap2xlsx (reads and writes the XLSX files)

## Installation

With [abapGit](https://abapgit.org), from [the repository](https://github.com/abap2UI5-addons/table-content-loader):

- Install with abapGit in this order: abap2UI5, abap2UI5-addons/popups, abap2xlsx, then this repository (branch main)
- Start the start page with ?app_start=z2ui5_cl_tcl_app_00; every app can also be started directly with ?app_start=&lt;class&gt;
- Add your own authorization checks before using it beyond a development system

The [Guide](/guide) has every step.

## A first app

```abap
?app_start=z2ui5_cl_tcl_app_00
```

## Links

- [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups)
- [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)
- [The repository](https://github.com/abap2UI5-addons/table-content-loader) - issues and pull requests welcome
