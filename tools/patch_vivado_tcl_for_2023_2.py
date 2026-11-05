#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Patch MathWorks / HDL Coder generated Vivado Tcl scripts so they run on
Vivado 2023.2 instead of the 2024.1 they were generated for (MATLAB R2025b,
"Deploy and Verify Modulation Classification on RFSoC Devices").

What it changes
---------------
  * Replaces the hard "wrong Vivado version" abort with a warning.
  * Adds the compat_2023_2.tcl helper layer (copied next to every output).
  * Resolves IP VLNV versions against the installed Vivado IP catalog.
  * Falls back to per-property CONFIG application on older IP revisions.
  * Makes sourcing of MathWorks support Tcl files path-independent.
  * Inserts the AI / deep learning IP from add_DLIP.tcl with clear diagnostics.
  * Removes GUI-only commands (regenerate_bd_layout, start_gui) in batch mode.
  * Reads constr.xdc from the project folder instead of the current directory.

Usage
-----
  # patch one file, keep a backup
  python3 tools/patch_vivado_tcl_for_2023_2.py add_system.tcl --in-place

  # patch every generated Tcl in the HDL Coder project folder
  python3 tools/patch_vivado_tcl_for_2023_2.py --dir C:/work/hdl_prj/vivado_ip_prj

  # write a patched copy instead of overwriting
  python3 tools/patch_vivado_tcl_for_2023_2.py add_system.tcl -o add_system_2023_2.tcl

Re-running is safe: already patched files (marker comment) are skipped unless
--force is given. Originals are saved as <name>.2024_1.bak on --in-place.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

MARKER = "# >>> MW-2023.2 PATCH"
REPO_ROOT = Path(__file__).resolve().parent.parent
COMPAT_LIB = REPO_ROOT / "vivado2023_2" / "compat_2023_2.tcl"

TRIGGERS = (
    "scripts_vivado_version",
    "create_bd_cell -type ip -vlnv",
    "set_property -dict",
    "regenerate_bd_layout",
    "start_gui",
    "DLIPcoreName",
    "get_ipdefs -all",
    "read_xdc",
    "source ",
)

HEADER = """# >>> MW-2023.2 PATCH (tools/patch_vivado_tcl_for_2023_2.py) ----------------
# Generated for Vivado 2024.1, patched to run under Vivado 2023.2 in batch mode.
if {![info exists ::mwcompat::loaded]} {
    source [file join [file dirname [file normalize [info script]]] "compat_2023_2.tcl"]
}
mw_check_version
# <<< MW-2023.2 PATCH --------------------------------------------------------
"""

VERSION_BLOCK = """set scripts_vivado_version 2023.2
set current_vivado_version [version -short]
if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   mw_log "WARNING: script was generated for Vivado $scripts_vivado_version, running on $current_vivado_version. Continuing with the 2023.2 compatibility layer."
}
"""

DLIP_BLOCK = """# MW-2023.2: add the deep learning (AI) IP core next to the subsystem IPs.
if {![info exists DLIPcoreName] || $DLIPcoreName eq ""} {
    if {[info exists ::env(MW_DLIP_NAME)]} { set DLIPcoreName $::env(MW_DLIP_NAME) }
}
if {[info exists DLIPcoreName] && $DLIPcoreName ne ""} {
    mw_log "adding DL IP core <$DLIPcoreName> via add_DLIP.tcl"
    if {[catch {mw_source_required "add_DLIP.tcl"} e]} {
        error "MW-2023.2: could not add the DL IP core: $e . Check 'DL Processor IP Name', 'DL Processor IP Location' and 'DL Processor IP Vendor' in step 1.2, and make sure the IP folder is in ip_repo_paths."
    }
} else {
    mw_log "WARNING: DLIPcoreName is empty, so the AI IP will NOT be added. Set it in step 1.2 or set the MW_DLIP_NAME environment variable."
}
"""

FOOTER = """
# >>> MW-2023.2 PATCH footer
if {[info exists design_name]} {
    mw_log "block design <$design_name> finished on Vivado [version -short] (no GUI layout used)."
}
# <<< MW-2023.2 PATCH footer
"""


def patch_text(src: str) -> str:
    """Apply all compatibility transformations to one Tcl script."""
    if MARKER in src:
        return src  # already patched: keep this function idempotent
    s = src

    # 1. Hard version check -> tolerant check.
    s = re.sub(
        r"set scripts_vivado_version\s+[^\n]*\n.*?return 1\s*\n\}",
        VERSION_BLOCK.rstrip("\n"),
        s,
        count=1,
        flags=re.S,
    )
    # Some generated scripts only have the assignment, without the check block.
    s = re.sub(
        r"set scripts_vivado_version\s+\d{4}\.\d+",
        "set scripts_vivado_version 2023.2",
        s,
    )

    # 2. IP creation: resolve the VLNV against the installed catalog.
    s = re.sub(
        r"create_bd_cell -type ip -vlnv ([^\s\]]+) ([^\s\]]+)",
        r"mw_create_bd_ip \1 \2",
        s,
    )

    # 3. The IP-catalog pre-check must use the same resolver.
    s = s.replace(
        "set ip_obj [get_ipdefs -all $ip_vlnv]",
        "set ip_obj [mw_ip_exists $ip_vlnv]",
    )
    s = s.replace("if { $ip_obj eq \"\" }", "if { !$ip_obj }")
    s = s.replace("if {$ip_obj eq \"\"}", "if {!$ip_obj}")

    # 4. CONFIG properties: fall back to per-property application.
    def _apply(m: re.Match) -> str:
        return f"mw_apply_ip_config {m.group(2)} {m.group(1)}"

    s = re.sub(
        r"set_property -dict (\[ list \\\n.*?\n\]) (\$\w+)",
        _apply,
        s,
        flags=re.S,
    )

    # 5. Path-independent sourcing of the MathWorks support scripts.
    for old, new in (
        ("source $mw_hdl_dir/mw_compile_dma.tcl", 'mw_source_required "mw_compile_dma.tcl"'),
        ("source $mw_hdl_dir/hsb_xil.tcl", 'mw_source_required "hsb_xil.tcl"'),
        ("source $mw_hdl_dir/add_DLIP.tcl", 'mw_source_required "add_DLIP.tcl"'),
        ("source add_pl_ddr.tcl", 'mw_source_required "add_pl_ddr.tcl"'),
        ("source add_rfdc_ip.tcl", 'mw_source_required "add_rfdc_ip.tcl"'),
    ):
        s = s.replace(old, new)

    # 6. Explicit, diagnosable insertion of the AI IP core.
    s = re.sub(
        r"if \{\[info exists DLIPcoreName\]\} \{\s*\n\s*mw_source_required \"add_DLIP\.tcl\"\s*\n\s*\}",
        DLIP_BLOCK.rstrip("\n"),
        s,
        count=1,
    )

    # 7. Do not let validation abort the batch run without a readable message.
    s = s.replace(
        "validate_bd_design\n",
        'if {[catch {validate_bd_design} e]} { mw_log "WARNING: validate_bd_design reported: $e" }\n',
        1,
    )

    # 8. Constraints must come from the project folder, not the shell CWD.
    s = s.replace(
        "read_xdc $mts_constr_filename",
        "read_xdc [mw_required_file $mts_constr_filename]",
    )

    # 9. GUI-only commands: this is the step that closed Vivado in GUI mode.
    s = s.replace("regenerate_bd_layout", "mw_regenerate_layout")
    s = re.sub(
        r"(?m)^\s*start_gui[^\n]*$",
        'mw_ignore_gui "start_gui (batch mode)"',
        s,
    )

    # 10. Standalone projects need the ZCU111 board part for the RFDC IP.
    s = s.replace(
        "create_project project_1 myproj -part xczu28dr-ffvg1517-2-e",
        "create_project project_1 myproj -part xczu28dr-ffvg1517-2-e\n"
        "catch {set_property board_part xilinx.com:zcu111:part0:1.1 [current_project]}",
    )

    return HEADER + s.rstrip("\n") + "\n" + FOOTER


def patch_file(path: Path, out: Path | None, in_place: bool, force: bool) -> bool:
    src = path.read_text(encoding="utf-8", errors="surrogateescape")
    if MARKER in src:
        if not force:
            print(f"  skip (already patched): {path}")
            return False
        backup = path.with_suffix(path.suffix + ".2024_1.bak")
        if backup.is_file():
            src = backup.read_text(encoding="utf-8", errors="surrogateescape")
            print(f"  --force: re-patching from backup {backup}")
        else:
            print(f"  skip (patched, --force needs {backup}): {path}")
            return False
    if not any(t in src for t in TRIGGERS):
        print(f"  skip (no Vivado block-design commands): {path}")
        return False

    patched = patch_text(src)
    if out is None:
        if in_place:
            backup = path.with_suffix(path.suffix + ".2024_1.bak")
            if not backup.exists():
                shutil.copy2(path, backup)
            target = path
        else:
            target = path.with_name(path.stem + "_2023_2" + path.suffix)
    else:
        target = out

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(patched, encoding="utf-8", errors="surrogateescape")

    # The patched script sources compat_2023_2.tcl from its own folder.
    if COMPAT_LIB.is_file():
        dest = target.parent / COMPAT_LIB.name
        if COMPAT_LIB.resolve() != dest.resolve():
            shutil.copy2(COMPAT_LIB, dest)

    print(f"  patched: {path} -> {target}")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", nargs="?", type=Path, help="single Tcl file to patch")
    ap.add_argument("-o", "--output", type=Path, help="write patched copy to this path")
    ap.add_argument("--dir", type=Path, help="patch every *.tcl under this folder (recursive)")
    ap.add_argument("--in-place", action="store_true", help="overwrite input, keeping a .2024_1.bak backup")
    ap.add_argument("--force", action="store_true", help="re-patch files that already carry the marker")
    args = ap.parse_args()

    if not COMPAT_LIB.is_file():
        print(f"ERROR: compatibility library not found: {COMPAT_LIB}", file=sys.stderr)
        return 2

    count = 0
    if args.dir:
        if not args.dir.is_dir():
            print(f"ERROR: not a folder: {args.dir}", file=sys.stderr)
            return 2
        files = sorted(
            p for p in args.dir.rglob("*.tcl")
            if p.name != COMPAT_LIB.name and ".2024_1.bak" not in p.name
        )
        print(f"Patching {len(files)} Tcl file(s) under {args.dir}")
        for p in files:
            count += patch_file(p, None, True, args.force)
    elif args.input:
        if not args.input.is_file():
            print(f"ERROR: not a file: {args.input}", file=sys.stderr)
            return 2
        count += patch_file(args.input, args.output, args.in_place, args.force)
    else:
        ap.print_help()
        return 2

    print(f"Done. {count} file(s) patched. compat_2023_2.tcl was copied next to each output.")
    print("Now run vivado -mode batch -source build_2023_2.tcl ... (see README.md).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
