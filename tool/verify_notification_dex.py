#!/usr/bin/env python3
"""Check the notification cache TypeToken signature in a minified Android APK.

Use the mapping.txt produced by the SAME build as the APK. This inspects bytecode;
it does not test device permission, scheduling, delivery, or persisted preferences.

Exit codes: 0 = signature preserved, 1 = signature missing/unexpected,
            2 = input, mapping, or inspection error.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


SUBCLASS = (
    "com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin$1"
)
PARENT = "com.google.gson.reflect.TypeToken"
MODEL = "com.dexterous.flutterlocalnotifications.models.NotificationDetails"
DEFAULT_ANALYZER = Path(
    "/workspace/scratch/3fd06e8c8253/android-build-env/android-sdk/"
    "cmdline-tools/latest/bin/apkanalyzer"
)


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, required=True, help="APK to inspect")
    parser.add_argument(
        "--mapping", type=Path, required=True,
        help="R8 mapping.txt from the same build as --apk",
    )
    parser.add_argument(
        "--apkanalyzer", type=Path,
        default=Path(shutil.which("apkanalyzer") or DEFAULT_ANALYZER),
        help="Android SDK apkanalyzer executable",
    )
    parser.add_argument("--label", default=None, help="Optional comparison label")
    parser.add_argument(
        "--output", type=Path, help="Also write the JSON result to this file",
    )
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def mapped_class(mapping: str, original: str) -> str:
    matches = re.findall(
        r"^" + re.escape(original) + r" -> ([^:\r\n]+):$", mapping, re.M,
    )
    if len(matches) != 1:
        raise ValueError(
            f"Expected exactly one class mapping for {original}; found {len(matches)}"
        )
    if matches[0].startswith("R8$$REMOVED$$CLASS$$"):
        raise ValueError(f"Required class was removed: {original}")
    return matches[0]


def inspect(args: argparse.Namespace) -> dict[str, Any]:
    for name in ("apk", "mapping", "apkanalyzer"):
        path = getattr(args, name)
        if not path.is_file():
            raise ValueError(f"{name} file not found: {path}")

    mapping = args.mapping.read_text(encoding="utf-8")
    classes = {
        "subclass": mapped_class(mapping, SUBCLASS),
        "parent": mapped_class(mapping, PARENT),
        "model": mapped_class(mapping, MODEL),
    }
    completed = subprocess.run(
        [str(args.apkanalyzer), "dex", "code", "--class", classes["subclass"],
         str(args.apk)],
        text=True, capture_output=True, timeout=60, check=False,
    )
    if completed.returncode:
        detail = (completed.stderr or completed.stdout).strip()[:2000]
        raise ValueError(f"apkanalyzer failed ({completed.returncode}): {detail}")

    # Restrict matching to the class header. A method-level generic signature
    # must not satisfy the class-level reflection requirement.
    header = re.split(r"^\.field |^\.method ", completed.stdout,
                      maxsplit=1, flags=re.M)[0]
    super_match = re.search(r"^\.super (\S+)$", header, re.M)
    actual_super = super_match.group(1) if super_match else None
    expected_super = "L" + classes["parent"].replace(".", "/") + ";"
    if actual_super != expected_super:
        raise ValueError(
            "DEX superclass does not match the supplied mapping: "
            f"expected {expected_super}, got {actual_super}"
        )

    match = re.search(
        r"\.annotation system Ldalvik/annotation/Signature;"
        r"(.*?)\.end annotation", header, re.S,
    )
    signature = (
        "".join(re.findall(r'"([^\"]*)"', match.group(1))) if match else None
    )
    expected = (
        "L" + classes["parent"].replace(".", "/")
        + "<Ljava/util/ArrayList<L" + classes["model"].replace(".", "/")
        + ";>;>;"
    )
    preserved = signature == expected
    result = (
        "preserved" if preserved
        else "missing_signature" if signature is None
        else "unexpected_signature"
    )
    return {
        "schema_version": 1,
        "label": args.label,
        "status": "pass" if preserved else "fail",
        "result": result,
        "apk": str(args.apk.resolve()),
        "apk_sha256": sha256(args.apk),
        "mapping": str(args.mapping.resolve()),
        "mapping_sha256": sha256(args.mapping),
        "classes": classes,
        "actual_superclass": actual_super,
        "class_signature": signature,
        "expected_class_signature": expected,
        "explanation": (
            "The notification cache TypeToken retains the parameterized "
            "ArrayList<NotificationDetails> class signature needed by Gson."
            if preserved else
            "The notification cache TypeToken is missing its expected "
            "parameterized class signature; the Gson reflection path remains "
            "unsafe in this APK."
        ),
        "scope": "Static DEX signature check only; no device test performed.",
        "mapping_requirement": (
            "Caller must supply the mapping from this exact APK build. "
            "Superclass consistency is checked, but provenance is not proven."
        ),
    }


def main() -> int:
    args = arguments()
    try:
        report = inspect(args)
        exit_code = 0 if report["status"] == "pass" else 1
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        report = {
            "schema_version": 1,
            "label": args.label,
            "status": "error",
            "error": str(exc),
            "scope": "Inspection incomplete; no APK success/failure conclusion.",
        }
        exit_code = 2

    serialized = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        try:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(serialized, encoding="utf-8")
        except OSError as exc:
            print(f"Could not write JSON output: {exc}", file=sys.stderr)
            exit_code = 2
    print(serialized, end="")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
