# AGENTS.md — AI Assistant Guide for abap2UI5 table-content-loader

> This file follows the cross-tool AGENTS.md convention and is the single
> agent instruction file of this repository — `CLAUDE.md` only points here.

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
| `src/z2ui5_cl_tcl_context`, `src/z2ui5_cx_tcl_error` | Vendored utility copies — **see below** |

## The Utility Copy Principle

`z2ui5_cl_tcl_context` is a **renamed copy** of `zabaputil_cl_util_context`
from the [abap-util](https://github.com/abap-util/abap-util) **master catalog**,
**trimmed to the methods this addon uses** (conv/itab/json/xml/rtti helpers)
plus the private helpers, types and constants those need.
`z2ui5_cx_tcl_error` is the master's `zabaputil_cx_util_error`, renamed and
copied as-is. This keeps the install dependency-free (abapGit has no
dependency management).

1. **Nothing from the core's frozen `src/99/01`.** `z2ui5_cl_util*` and
   `z2ui5_cx_util_error` are kept in abap2UI5 for compatibility only; the app
   calls `z2ui5_cl_tcl_context=>…`, every utility exception is
   `z2ui5_cx_tcl_error`. The JSON methods use the core's `z2ui5_cl_ajson`,
   which every abap2UI5 installation ships.
2. **Method-level trimming** applies to the context class only, and keeps
   every helper a kept method needs.
3. **New methods are added locally.** If the method already exists in
   abap-util, copy it from there (with its helpers) instead of re-implementing
   it. Do not add a dependency on another project's copy.
4. **Periodic AI sync-back:** abap-util compares all consumers every few weeks
   and merges what was added or fixed here back into the master.

## Dependencies

Installed alongside via abapGit; declared in the abaplint configs:

* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)

## Security

This is a developer tool. It reads from any table the user names and writes into
tables of the Z/Y namespace only (the JSON upload's save refuses any other),
without an authorization check of its own. Before using it beyond a development
system, add your own `AUTHORITY-CHECK`s and restrict who may run the app.

## Coding Style

Follows the abap2UI5 core conventions (see its
[AGENTS.md](https://github.com/abap2UI5/abap2UI5/blob/main/AGENTS.md)): Clean
ABAP with Hungarian prefixes, backtick string literals, string templates
(`|…{ }…|`) instead of `&&`.

## Validation

Run `npm run check` before considering changes complete: it runs the same
abaplint, abap2UI5-linter and rename steps as CI, and all of them must pass.
CI:

* `abap-standard` / `abap-cloud` — lint against Standard ABAP
  (`abaplint.jsonc`) and ABAP Cloud (`.github/abaplint/abap_cloud.jsonc`)
* `check-abap2ui5` — the abap2UI5-linter over the app classes and their
  views (`abap2ui5lint.jsonc`)
* `check-rename` — namespace-rename check (`npm run rename`, `.github/scripts/rename.mjs`)
* `build-rename` — manual workflow that pushes a namespace-renamed branch
  `rename_<name>` for a parallel install

* `publish-702` / `abap-702` — `publish-702` writes the downported `702`
  branch on every push to `main` (`npm run auto_downport` against
  `.github/abaplint/abap_702.jsonc`), and `abap-702` lints it. abap2xlsx needs
  no `702` branch: its `main` is written for 7.02. Never commit to `702` by
  hand.

All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).

## Namespace rename

`npm run rename` (CI: `check-rename`) and the manual `build-rename` workflow
are abap2UI5's namespace rename for this addon - `.github/scripts/rename.mjs`,
the same file in every addon that has one. Every `z2ui5_` object becomes
`<name>_...`, for a customer name such as `ZMYUI5` or a registered namespace
such as `/CA2UI5/` (at most 10 characters), and so does every reference to
abap2UI5 and to the addons this one builds on: the branch `rename_<name>` runs
on an abap2UI5 renamed with the same name by its own `build-rename`. What
follows from it:

- Every object name has at most 25 characters (a transparent table
  11, an ICF node 10) - 30 minus what the longest new name adds.
- No literal names a `z2ui5_` object: the rename rewrites references, never a
  literal. Derive the name - from a typed reference, or behind the prefix of
  the class's own name.
- A change that spans several repositories: `RENAME_DEPS_FROM=<dir> npm run
  rename` takes the dependencies from the clones in `<dir>`.
