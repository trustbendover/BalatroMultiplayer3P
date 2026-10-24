#!/usr/bin/env python3
"""Build the release zips for Balatro Multiplayer 3P.

  python3 tools/build_release.py            # version from mod/Multiplayer.json
  python3 tools/build_release.py --out dist-release --vendor-cache .vendor

Produces in --out:
  BalatroMultiplayer3P-v<X>-Installer.zip   (Install.bat, Update.bat, payload/ with Lovely, Steamodded, the mod)
  BalatroMultiplayer3P-v<X>-source.zip      (this repository, tracked files only)
  SHA256SUMS-v<X>.txt
Third-party pieces (Lovely 0.10.0, Steamodded 1.0.0~BETA-1620a) are downloaded from their
official GitHub releases and checked against pinned SHA256 hashes.
"""
import argparse, hashlib, io, json, os, re, shutil, subprocess, sys, urllib.request, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VENDOR = {
    "lovely": ("https://github.com/ethangreen-dev/lovely-injector/releases/download/v0.10.0/lovely-x86_64-pc-windows-msvc.zip",
               "7f481f984ab8ee633c90ce18220c88a2da8f93ca86b6c3e3ff70a725c05807ab"),
    "smods": ("https://github.com/Steamodded/smods/archive/refs/tags/1.0.0-beta-1620a.zip",
              "c98754fdf009f0addd198fe062989ef0f5bf212220c54cc89ed27ad5b0ea56ec"),
}
MOD_EXCLUDE = re.compile(r"(^|/)(\.git|\.github|\.env|node_modules|dist|logs?)(/|$)|\.log$")
FORBIDDEN = [b"playit.gg/claim", b".ply.gg", b"joinmc.link"]
# extra private words (e.g. local account names) can be passed without committing them:
FORBIDDEN += [w.strip().lower().encode() for w in os.environ.get("RELEASE_FORBIDDEN", "").split(",") if w.strip()]


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def fetch(name, cache):
    url, want = VENDOR[name]
    path = os.path.join(cache, name + ".zip") if cache else None
    if path and os.path.exists(path):
        data = open(path, "rb").read()
    else:
        req = urllib.request.Request(url, headers={"User-Agent": "BalatroMultiplayer3P-build"})
        data = urllib.request.urlopen(req, timeout=120).read()
        if path:
            os.makedirs(cache, exist_ok=True)
            open(path, "wb").write(data)
    got = sha256(data)
    if got != want:
        sys.exit(f"{name}: SHA256 mismatch {got} != {want}")
    return zipfile.ZipFile(io.BytesIO(data))


def tracked_files():
    try:
        out = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, check=True).stdout
        files = [f for f in out.decode().split("\0") if f]
        if files:
            return files
    except Exception:
        pass
    files = []
    for d, dirs, fs in os.walk(ROOT):
        rel = os.path.relpath(d, ROOT).replace("\\", "/")
        dirs[:] = [x for x in dirs if x not in (".git", "node_modules", "dist", "data", "out", ".vendor", "dist-release")]
        for f in fs:
            r = f if rel == "." else rel + "/" + f
            if not MOD_EXCLUDE.search(r) or r.endswith(".env.example"):
                files.append(r)
    return sorted(files)


def add_tree(zf, src, arc, exclude=None):
    for d, dirs, fs in os.walk(src):
        dirs.sort()
        for f in sorted(fs):
            full = os.path.join(d, f)
            rel = os.path.relpath(full, src).replace("\\", "/")
            if exclude and exclude.search(rel) and not rel.endswith(".env.example"):
                continue
            zf.write(full, arc + "/" + rel)


def check_clean(path):
    with zipfile.ZipFile(path) as z:
        for n in z.namelist():
            base = n.rsplit("/", 1)[-1]
            if base == ".env" or n.endswith(".log") or "/node_modules/" in n:
                sys.exit(f"{path}: forbidden file {n}")
            if base == "build_release.py":
                continue  # contains the forbidden list itself
            data = z.read(n)
            for bad in FORBIDDEN:
                if bad in data.lower():
                    sys.exit(f"{path}: forbidden text {bad!r} in {n}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "dist-release"))
    ap.add_argument("--vendor-cache", default=os.path.join(ROOT, ".vendor"))
    ap.add_argument("--version")
    a = ap.parse_args()
    ver = a.version or json.load(open(os.path.join(ROOT, "mod", "Multiplayer.json")))["version"]
    tag = "v" + ver.split("~")[0]
    os.makedirs(a.out, exist_ok=True)
    inst_name = f"BalatroMultiplayer3P-{tag}-Installer"
    inst_zip = os.path.join(a.out, inst_name + ".zip")
    src_zip = os.path.join(a.out, f"BalatroMultiplayer3P-{tag}-source.zip")

    lovely, smods = fetch("lovely", a.vendor_cache), fetch("smods", a.vendor_cache)
    with zipfile.ZipFile(inst_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for f in sorted(os.listdir(os.path.join(ROOT, "installer"))):
            if f == "LOVELY_LICENSE.txt":
                z.write(os.path.join(ROOT, "installer", f), f"{inst_name}/payload/{f}")
            else:
                z.write(os.path.join(ROOT, "installer", f), f"{inst_name}/{f}")
        z.write(os.path.join(ROOT, "mod", "updater", "Update.bat"), f"{inst_name}/Update.bat")
        z.write(os.path.join(ROOT, "mod", "updater", "update.ps1"), f"{inst_name}/update.ps1")
        z.writestr(f"{inst_name}/payload/winmm.dll", lovely.read("winmm.dll"))
        prefix = smods.namelist()[0].split("/")[0] + "/"
        for n in smods.namelist():
            if n.endswith("/") or not n.startswith(prefix):
                continue
            z.writestr(f"{inst_name}/payload/smods/" + n[len(prefix):], smods.read(n))
        add_tree(z, os.path.join(ROOT, "mod"), f"{inst_name}/payload/BalatroMultiplayer3P", MOD_EXCLUDE)

    src_name = f"BalatroMultiplayer3P-{tag}-source"
    with zipfile.ZipFile(src_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for f in tracked_files():
            if os.path.isfile(os.path.join(ROOT, f)):
                z.write(os.path.join(ROOT, f), f"{src_name}/{f}")

    for p in (inst_zip, src_zip):
        check_clean(p)
    sums = os.path.join(a.out, f"SHA256SUMS-{tag}.txt")
    with open(sums, "w", newline="\n") as fh:
        for p in (inst_zip, src_zip):
            fh.write(f"{sha256(open(p, 'rb').read())}  {os.path.basename(p)}\n")
    print(open(sums).read(), end="")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as fh:
            fh.write(f"tag={tag}\nversion={ver}\n")


if __name__ == "__main__":
    main()
