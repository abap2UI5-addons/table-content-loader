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

1. **Nothing of abap2UI5-ext.** `z2ui5_cl_util*` and `z2ui5_cx_util_error`
   left the core with its `src/99/01` for abap2UI5-ext; the app
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

`.github/abap-util.json` names the copies and their masters for abap-util's
`sync-check`: with abap-util checked out next to this repository,
`node ../abap-util/.github/scripts/sync-check.mjs --consumer . --report`
lists every method whose body or declaration differs from the master and
every method only this copy has. `commit` is the abap-util commit the copies
match: run the script without `--report` at that commit and it fails on any
difference that is not named under `settled` or `own`. After a refresh, set
`commit` to the commit the copies were taken from.

## Dependencies

Installed alongside via abapGit; declared in the abaplint configs:

* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx)

popups (and layout-management, which popups builds on, for the unit run) are
pinned by commit in `.github/deps.json`: CI and `npm run unit` resolve them
there, the monthly `bump-deps` moves the pins, and the weekly `ci` run checks
their `main` tips. abap2UI5 and abap2xlsx are still resolved from their
default branch. The 702 config gives popups' `702` branch a folder of its own
(`/popups-702`), beside the one the CI template fills with the pinned commit.

## Security

This is a developer tool. It reads from any table the user names and writes into
tables of the Z/Y namespace (the JSON upload is the only writer), without an
authorization check of its own. Before using it beyond a development system,
add your own `AUTHORITY-CHECK`s and restrict who may run the app.

The write boundary is a name check, not a data-ownership check
(`z2ui5_cl_tcl_app_01=>get_write_refusal`, applied on Save and again right
before the `MODIFY`): a name must start with `Z`/`Y` and must not carry
abap2UI5's prefix - every table of the framework and of its addons (the draft
table, config-management's configuration, sql-console's histories) is read
back as program state, so a planted row acts in another user's session. The
prefix is derived from `z2ui5_if_app` by type, never written as a literal, so
the namespace rename carries it. A new writing path must go through the same
method. Every dynamic `FROM` / `CREATE DATA ... TYPE (name)` takes its name
from `z2ui5_cl_tcl_context=>db_get_table_name` (one plain DDIC table or view
name) - never straight from a bound field; where the name outlives the
roundtrip (app 06) the checked name is kept in a protected attribute.

**Shipping without an authorization check is a deliberate decision of the
maintainer (2026-11-17), stated in the README - do not add one and do not
report its absence as a finding.**

## Coding Style

Follows the abap2UI5 core conventions (see its
[AGENTS.md](https://github.com/abap2UI5/abap2UI5/blob/main/AGENTS.md)): Clean
ABAP with Hungarian prefixes, backtick string literals, string templates
(`|…{ }…|`) instead of `&&`.

## Validation

Run `npm run check` before considering changes complete: it runs the same
abaplint, abap2UI5-linter and rename steps as CI, and all of them must pass.
CI comes from the shared CI template of abap2UI5-addons (reusable workflows in
[rap-ext](https://github.com/abap2UI5-addons/rap-ext/blob/main/.github/ci/README.md),
pinned by commit in the `uses:` lines and moved by `bump-deps`):

* `ci` - one job per check: abaplint against Standard ABAP
  (`abaplint.jsonc`) and ABAP Cloud (`.github/abaplint/abap_cloud.jsonc`),
  `abap2ui5lint` (the app classes and their views, `abap2ui5lint.jsonc`),
  `rename` (`npm run rename`, `.github/scripts/rename.mjs`) and `unit`:
  `npm run unit` (`.github/scripts/unit.mjs`) copies the classes the tests
  reach (`z2ui5_cl_tcl_app_01`, `_context`, `z2ui5_cx_tcl_error` - the rest
  builds on abap2xlsx) into a checkout of abap2UI5's `main` with
  abap2UI5-ext, layout-management and popups, downports, transpiles and runs
  the tests on the Node runtime. `file_windows_1252` is skipped there (the
  runtime has no Windows-1252 converter) and runs in a system only - and
  `npm run check:702`, the 7.02 gate of a pull request:
  `.github/scripts/check-702.sh` downports a scratch copy of `src/` in
  `build/702` and lints it with `.github/abaplint/abap_702.jsonc` (`src/`
  itself is never rewritten)
* `build-rename` — manual workflow that pushes a namespace-renamed branch
  `rename_<name>` for a parallel install
* `ci-702` — writes the downported `702` branch on every push to `main`
  (`npm run auto_downport` against `.github/abaplint/abap_702.jsonc`) and
  lints it. abap2xlsx needs no `702` branch: its `main` is written for 7.02.
  Never commit to `702` by hand.

All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).

## Namespace rename

`npm run rename` (CI: the `rename` job of `ci`) and the manual `build-rename` workflow
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
