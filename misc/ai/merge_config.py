#!/usr/bin/env python3
"""Merge a tracked AI-tool config into the machine-local copy the tool rewrites.

usage: merge_config.py TRACKED LOCAL        (format chosen by TRACKED's extension)

.toml (codex ~/.codex/config.toml)
  "$HOME" and a leading "~/" inside TRACKED values are expanded to the real home dir
  (codex does not expand them itself). LOCAL is edited in place (codex writes its own
  state there). Managed keys/tables in LOCAL are dropped and replaced by the ones from
  TRACKED; everything else is kept.

.json (claude ~/.claude/settings.json)
  Deep merge of TRACKED and LOCAL: objects merge recursively, arrays are unioned
  (TRACKED order first), scalars come from TRACKED when it defines them, else LOCAL.
  The merged result is written to BOTH files, so settings added locally (e.g. an
  "always allow" permission) are promoted into the tracked file.

If LOCAL is a symlink (old setup) it is replaced by a real file seeded from its target.
"""
import json, os, re, sys

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


def deep_merge(base, over):
    """base wins on scalar conflicts; dicts merge recursively; lists are unioned."""
    if isinstance(base, dict) and isinstance(over, dict):
        out = dict(base)
        for k, v in over.items():
            out[k] = deep_merge(base[k], v) if k in base else v
        return out
    if isinstance(base, list) and isinstance(over, list):
        return base + [x for x in over if x not in base]
    return base


def write_atomic(path, text):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def merge_json(tracked_path, local_path):
    if os.path.islink(local_path):
        seed = open(local_path).read()
        os.remove(local_path)
        write_atomic(local_path, seed)
    tracked = json.load(open(tracked_path))
    local = json.load(open(local_path)) if os.path.exists(local_path) else {}
    text = json.dumps(deep_merge(tracked, local), indent=2, ensure_ascii=False) + "\n"
    # tracked_path may itself be a symlink into the repo; write through to the real file
    write_atomic(os.path.realpath(tracked_path), text)
    write_atomic(local_path, text)


def merge_toml(tracked_path, local_path):
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
    tracked, local = sys.argv[1:3]
    (merge_json if tracked.endswith(".json") else merge_toml)(tracked, local)
