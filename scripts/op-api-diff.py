#!/usr/bin/env python3
"""Diff two Openplanet game-class JSON dumps (OpenplanetNext.json shape).

Shows what changed between two builds: added/removed namespaces, classes, and
members, plus changed member offsets/types and changed class metadata (base,
instantiable flag, id, size). Adapted from op-tm-api-docs/diff-json.py with a
cleaner grouped report and correct handling of the optional `sz` size field
(present only in op-tm-api-docs customized `_with_offsets` copies).

Usage:
  op-api-diff.py OLD.json NEW.json                 # human-readable grouped diff
  op-api-diff.py OLD.json NEW.json --summary       # counts only
  op-api-diff.py OLD.json NEW.json --class CHms    # only classes matching /CHms/

Exit status is 0 when the dumps are identical, 1 when they differ, 2 on error.
"""
import argparse
import json
import re
import sys
from collections import defaultdict


def load(path: str) -> dict:
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def members_by_name(cls: dict) -> dict:
    return {m.get("n"): m for m in cls.get("m", []) if isinstance(m, dict) and "n" in m}


def diff_members(c1: dict, c2: dict) -> dict:
    """Return {added, removed, changed} member lists between two class descriptors."""
    m1 = members_by_name(c1)
    m2 = members_by_name(c2)
    added = [m2[k] for k in m2.keys() - m1.keys()]
    removed = [m1[k] for k in m1.keys() - m2.keys()]
    changed = []
    for name in m1.keys() & m2.keys():
        a, b = m1[name], m2[name]
        diffs = []
        for field, label in (("o", "offset"), ("t", "type"), ("r", "range")):
            if a.get(field) != b.get(field):
                diffs.append(f"{label} {a.get(field)} -> {b.get(field)}")
        if diffs:
            changed.append((name, "; ".join(diffs)))
    return {"added": added, "removed": removed, "changed": changed}


def class_meta(cls: dict) -> dict:
    # sz is optional (only in _with_offsets copies); report it only if either side has it.
    meta = {"base": cls.get("p"), "instantiable": cls.get("c"), "id": cls.get("i")}
    if "sz" in cls:
        meta["sz"] = cls.get("sz")
    return meta


def diff(game1: dict, game2: dict) -> dict:
    ns1 = game1.get("ns", {})
    ns2 = game2.get("ns", {})
    report = {
        "ns_added": sorted(ns2.keys() - ns1.keys()),
        "ns_removed": sorted(ns1.keys() - ns2.keys()),
        "class_added": [],
        "class_removed": [],
        "class_changed": [],   # (fqname, member diff, meta changes)
    }
    for ns in sorted(ns1.keys() | ns2.keys()):
        c1 = ns1.get(ns, {})
        c2 = ns2.get(ns, {})
        for cname in sorted(c2.keys() - c1.keys()):
            report["class_added"].append(f"{ns}::{cname}")
        for cname in sorted(c1.keys() - c2.keys()):
            report["class_removed"].append(f"{ns}::{cname}")
        for cname in sorted(c1.keys() & c2.keys()):
            mdiff = diff_members(c1[cname], c2[cname])
            meta1, meta2 = class_meta(c1[cname]), class_meta(c2[cname])
            meta_changes = []
            for key in meta1.keys() | meta2.keys():
                if meta1.get(key) != meta2.get(key):
                    meta_changes.append(f"{key} {meta1.get(key)} -> {meta2.get(key)}")
            if mdiff["added"] or mdiff["removed"] or mdiff["changed"] or meta_changes:
                report["class_changed"].append((f"{ns}::{cname}", mdiff, meta_changes))
    return report


def is_empty(report: dict) -> bool:
    return not any(report[k] for k in report)


def print_report(report: dict, class_filter: str | None):
    rx = re.compile(class_filter, re.IGNORECASE) if class_filter else None

    def wanted(fqname: str) -> bool:
        return rx is None or rx.search(fqname) is not None

    if report["ns_added"]:
        print("== namespaces added ==")
        for ns in report["ns_added"]:
            print(f"  + {ns}")
    if report["ns_removed"]:
        print("== namespaces removed ==")
        for ns in report["ns_removed"]:
            print(f"  - {ns}")
    added = [c for c in report["class_added"] if wanted(c)]
    removed = [c for c in report["class_removed"] if wanted(c)]
    changed = [c for c in report["class_changed"] if wanted(c[0])]
    if added:
        print(f"\n== classes added ({len(added)}) ==")
        for c in added:
            print(f"  + {c}")
    if removed:
        print(f"\n== classes removed ({len(removed)}) ==")
        for c in removed:
            print(f"  - {c}")
    if changed:
        print(f"\n== classes changed ({len(changed)}) ==")
        for fqname, mdiff, meta_changes in changed:
            print(f"  ~ {fqname}")
            for mc in meta_changes:
                print(f"      {mc}")
            for m in mdiff["added"]:
                print(f"      + member {m.get('t','?')} {m.get('n')}")
            for m in mdiff["removed"]:
                print(f"      - member {m.get('t','?')} {m.get('n')}")
            for name, what in mdiff["changed"]:
                print(f"      ~ member {name}: {what}")


def print_summary(report: dict):
    member_changes = sum(
        len(m["added"]) + len(m["removed"]) + len(m["changed"]) for _, m, _ in report["class_changed"]
    )
    print(f"namespaces  +{len(report['ns_added'])} -{len(report['ns_removed'])}")
    print(f"classes     +{len(report['class_added'])} -{len(report['class_removed'])} ~{len(report['class_changed'])}")
    print(f"members     changed across {member_changes} member entries")


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="op-api-diff", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("old", help="older OpenplanetNext.json / op-*.json")
    p.add_argument("new", help="newer OpenplanetNext.json / op-*.json")
    p.add_argument("--summary", action="store_true", help="print counts only")
    p.add_argument("--class", dest="class_filter", help="only report classes matching this regex")
    args = p.parse_args(argv)

    try:
        game1 = load(args.old)
        game2 = load(args.new)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    report = diff(game1, game2)
    mp1, mp2 = game1.get("mp", "?"), game2.get("mp", "?")
    op1, op2 = game1.get("op", "?"), game2.get("op", "?")
    print(f"old: mp={mp1} op={op1}")
    print(f"new: mp={mp2} op={op2}\n")

    if is_empty(report):
        print("no differences")
        return 0
    if args.summary:
        print_summary(report)
    else:
        print_report(report, args.class_filter)
    return 1


if __name__ == "__main__":
    sys.exit(main())
