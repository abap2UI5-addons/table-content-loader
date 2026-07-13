# AGENTS.md — AI Assistant Guide for abap2UI5 table-content-loader

> This file follows the cross-tool AGENTS.md convention and is the single
> agent instruction file of this repository — Claude Code reads `AGENTS.md`
> natively, there is no separate `CLAUDE.md`.

## Project Overview

Upload, edit and download table content (JSON, CSV, XLSX) for
[abap2UI5](https://github.com/abap2UI5/abap2UI5) (`z2ui5_cl_tcl_*`).

**Language:** English — all code, comments, commit messages, PRs, issues and
documentation must be in English.

## Package Structure

| Package | Content |
|---|---|
| `src/` | App classes `z2ui5_cl_tcl_app_00` … `_06` |
| `src/01/z2ui5_cl_tcl_xlsx_api` | XLSX helper |
| `src/z2ui5_cl_tcl_context` | Vendored utility copy — **see below** |

## The Utility Copy Principle

`z2ui5_cl_tcl_context` is a **trimmed, renamed copy** of the abap2UI5 utility
class (`z2ui5_cl_util` in the core), carrying only the methods this addon uses
(conv/itab/json/xml/rtti helpers) plus the private helpers and char constants
those need. The app calls `z2ui5_cl_tcl_context=>…`, never `z2ui5_cl_util=>…`
directly. This keeps the install dependency-free (abapGit has no dependency
management). The core and the other addons use the same pattern. When a new
utility method is needed, copy it from the core utility class (with its private
helpers) into the context copy rather than adding a dependency.

## Dependencies

Installed alongside via abapGit; declared in the abaplint configs:

* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)

## Security

This is a developer tool. It reads from and writes to any table the user names,
without an authorization check of its own (the Z/Y namespace hint on write is
only a warning, not enforced). Before using it beyond a development system, add
your own `AUTHORITY-CHECK`s and restrict who may run the app.

## Coding Style

Follows the abap2UI5 core conventions (see its
[AGENTS.md](https://github.com/abap2UI5/abap2UI5/blob/main/AGENTS.md)): Clean
ABAP with Hungarian prefixes, backtick string literals, string templates
(`|…{ }…|`) instead of `&&`.

## Validation

Run `npx abaplint` before considering changes complete (config `abaplint.jsonc`,
0 issues expected). CI:

* `ABAP_STANDARD` / `ABAP_CLOUD` — lint against Standard ABAP and ABAP Cloud
* `renaming` (`rename_test.yaml`) — namespace-rename check
* `build_rename` — manual workflow that pushes a namespace-renamed branch
  `rename_<name>` for a parallel install

There is no 702 downport: the abap2xlsx dependency has no `702` branch.
All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).
