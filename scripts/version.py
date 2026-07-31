#!/usr/bin/env python3
"""Patch clang/flang/lld Version.cpp: put vendor info on a separate line."""

import sys
from pathlib import Path

PATCHES = {
    "clang": {
        "path": "clang/lib/Basic/Version.cpp",
        "old": 'OS << getClangVendor() << ToolName << " version " CLANG_VERSION_STRING;',
        "new": (
            'OS << ToolName << " version " CLANG_VERSION_STRING;\n'
            '  std::string Vendor = getClangVendor();\n'
            '  if (!Vendor.empty())\n'
            '    OS << "\\nVendor: " << Vendor;'
        ),
    },
    "flang": {
        "path": "flang/lib/Support/Version.cpp",
        "old": (
            "#ifdef FLANG_VENDOR\n"
            "  OS << FLANG_VENDOR;\n"
            "#endif\n"
            '  OS << ToolName << " version " FLANG_VERSION_STRING;'
        ),
        "new": (
            'OS << ToolName << " version " FLANG_VERSION_STRING;\n'
            "#ifdef FLANG_VENDOR\n"
            '  OS << "\\nVendor: " << FLANG_VENDOR;\n'
            "#endif"
        ),
    },
    "lld": {
        "path": "lld/Common/Version.cpp",
        "old": (
            "#ifdef LLD_VENDOR\n"
            '#define LLD_VENDOR_DISPLAY LLD_VENDOR " "\n'
            "#else\n"
            "#define LLD_VENDOR_DISPLAY\n"
            "#endif\n"
            "#if defined(LLVM_REPOSITORY) && defined(LLVM_REVISION)\n"
            '  return LLD_VENDOR_DISPLAY "LLD " LLD_VERSION_STRING " (" LLVM_REPOSITORY\n'
            '                            " " LLVM_REVISION ")";\n'
            "#else\n"
            '  return LLD_VENDOR_DISPLAY "LLD " LLD_VERSION_STRING;\n'
            "#endif\n"
            "#undef LLD_VENDOR_DISPLAY"
        ),
        "new": (
            "#if defined(LLVM_REPOSITORY) && defined(LLVM_REVISION)\n"
            '  std::string Version = "LLD " LLD_VERSION_STRING " (" LLVM_REPOSITORY\n'
            '                          " " LLVM_REVISION ")";\n'
            "#else\n"
            '  std::string Version = "LLD " LLD_VERSION_STRING;\n'
            "#endif\n"
            "#ifdef LLD_VENDOR\n"
            '  Version += "\\nVendor: " LLD_VENDOR;\n'
            "#endif\n"
            "  return Version;"
        ),
    },
}

def patch_file(root: Path, name: str):
    p = PATCHES[name]
    path = root / p["path"]

    if not path.exists():
        print(f"[WARN] {name}: {path} not found, skipping")
        return

    src = path.read_text(encoding="utf-8")

    if p["old"] in src:
        src = src.replace(p["old"], p["new"])
        src = src.replace('OS << " " << repo;', 'OS << "\\n" << repo;')
        path.write_text(src, encoding="utf-8")
        print(f"[INFO] Patched {name}: {path}")
    elif p["new"].split("\n")[0] in src:
        print(f"[INFO] {name}: already patched, skipping")
    else:
        print(f"[ERROR] {name}: pattern not found, upstream may have changed")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <llvm-project-root>")
        sys.exit(1)

    root = Path(sys.argv[1])
    for name in PATCHES:
        patch_file(root, name)

if __name__ == "__main__":
    main()