#!/usr/bin/env python3
"""Merge the tracked codex config (plugins, marketplaces, model provider, mcp_servers)
into the machine-local ~/.codex/config.toml.

usage: merge_config.py TRACKED LOCAL

"$HOME" and a leading "~/" inside TRACKED values are expanded to the real home dir
(codex does not expand them itself).

LOCAL is edited in place (codex writes its own state there). Managed keys/tables in
LOCAL are dropped and replaced by the ones from TRACKED; everything else is kept.
If LOCAL is a symlink (old setup) it is replaced by a real file seeded from its target.
"""
import os, re, shutil, sys

MANAGED_TABLES = {"plugins", "marketplaces", "mcp_servers", "model_providers"}
MANAGED_KEYS = {"model_provider"}
HEADER = re.compile(r"^\s*\[\[?\s*([A-Za-z0-9_-]+)")
KEY = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=")


def split(text):
    """-> (top-level lines, [(root_table, lines)])"""
    top, tables, cur = [], [], None
    for line in text.splitlines():
        m = HEADER.match(line)
        if m:
            cur = (m.group(1), [line])
            tables.append(cur)
        elif cur:
            cur[1].append(line)
        else:
            top.append(line)
    return top, tables


def drop_managed_top(lines):
    out, skipping = [], False
    for line in lines:
        m = KEY.match(line)
        if m:
            skipping = m.group(1) in MANAGED_KEYS
        if not skipping:
            out.append(line)
    return out


def main(tracked_path, local_path):
    if os.path.islink(local_path):
        seed = open(local_path).read()
        os.remove(local_path)
        open(local_path, "w").write(seed)
    elif not os.path.exists(local_path):
        open(local_path, "w").write("")

    home = os.path.expanduser("~")
    tracked = open(tracked_path).read().replace("$HOME", home).replace('"~/', '"' + home + "/")
    t_top, t_tables = split(tracked)
    l_top, l_tables = split(open(local_path).read())

    managed_top = [l for l in t_top if l.strip()]
    top = managed_top + [""] + drop_managed_top(l_top)
    blocks = [lines for root, lines in l_tables if root not in MANAGED_TABLES]
    blocks += [lines for root, lines in t_tables if root in MANAGED_TABLES]

    parts = ["\n".join(top).strip("\n")]
    for b in blocks:
        parts.append("\n".join(b).strip("\n"))
    tmp = local_path + ".tmp"
    open(tmp, "w").write("\n\n".join(p for p in parts if p) + "\n")
    os.replace(tmp, local_path)


if __name__ == "__main__":
    main(*sys.argv[1:3])
