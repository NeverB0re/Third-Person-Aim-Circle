"""Build Third-Person Aim Circle into a mod zip:  python build_aim_circle.py -> dist/Third-Person Aim Circle v<version>.zip

The bundled archive writer is adapted from Boot Mod Loader (MIT); see THIRD-PARTY-NOTICES.md.
"""
import json
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
from archive_writer import write_module

SOURCE = os.path.join(HERE, "aim_circle.lua")
DIST = os.path.join(HERE, "dist")
NAME = "Third-Person Aim Circle"
FOLDER = "Addon"
RESOURCE = "mods/codex/third_person_aim_circle"

MANIFEST = {
    "Version": 1,
    "Guid": "c83e2d51-7f0a-4b96-a1d4-6e59b02f7c18",
    "Name": NAME,
    "Description": "The aim circle in third person for rifles the game gives none: Anti-Materiel Rifle, Apex, Sightliner. "
                   "Requires Chef Shared Loader.",
    "Options": [{"Name": NAME, "Description": "Requires Chef Shared Loader.", "Include": [FOLDER]}],
}


def build():
    with open(SOURCE, encoding="utf-8") as f:
        source = f.read()
    if not source.startswith("-- HD2-Addon: " + RESOURCE + "\n"):
        raise SystemExit("the first line must declare " + RESOURCE)
    version = re.search(r"local VERSION = '([0-9A-Za-z.-]+)'", source).group(1)
    out_dir = os.path.join(DIST, "%s v%s" % (NAME, version))
    if os.path.exists(out_dir):
        raise SystemExit("%s exists: bump VERSION or delete it" % out_dir)
    write_module(os.path.join(out_dir, FOLDER), RESOURCE, source)
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(MANIFEST, f, indent=2)
        f.write("\n")
    zip_path = out_dir + ".zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for base, _dirs, files in os.walk(out_dir):
            for name in sorted(files):
                full = os.path.join(base, name)
                z.write(full, os.path.relpath(full, out_dir))
    print("wrote %s" % zip_path)


if __name__ == "__main__":
    sys.exit(build())
