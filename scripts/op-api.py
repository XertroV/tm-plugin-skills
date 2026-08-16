#!/usr/bin/env python3
"""Search Openplanet's exported AngelScript API JSON dumps.

Two dumps, auto-detected under ~/OpenplanetNext/ (override with --core/--game or
positional paths):

  OpenplanetCore.json  {op, functions[], classes[], enums[], funcdefs[], props[]}
      Openplanet's scripting API (UI::, Math::, Time::, Json::, Net::, ...).

  OpenplanetNext.json  {mp, op, ns{Namespace{Class{...}}}}
      Game classes reflected into AngelScript (single-letter field encoding).

The `sz` class-size field on game classes is an optional extra added by
op-tm-api-docs customized copies; it is reported when present and ignored when
absent.

Examples:
  op-api.py class CHmsPortal            # game class + its members
  op-api.py member AddLine              # members named AddLine anywhere
  op-api.py func DrawList               # scripting-API functions matching
  op-api.py enum Col                    # scripting-API enums matching
  op-api.py const PI                    # exposed constants/props
  op-api.py search GetCurLap            # everything matching a substring
  op-api.py type CTrackMania            # classes whose name matches (game + core)
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

OP_DIR = Path(os.environ.get("OPENPLANET_DIR", str(Path.home() / "OpenplanetNext")))


def _load(path: Path) -> dict:
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def load_core(path: Path | None) -> dict:
    return _load(path or OP_DIR / "OpenplanetCore.json")


def load_game(path: Path | None) -> dict:
    return _load(path or OP_DIR / "OpenplanetNext.json")


def _match(pat: str, name: str, exact: bool) -> bool:
    return name.lower() == pat.lower() if exact else pat.lower() in name.lower()


def _rx(pattern: str | None, name: str) -> bool:
    if pattern is None:
        return True
    return re.search(pattern, name, re.IGNORECASE) is not None


# --------------------------------------------------------------------------- #
# Game dump (OpenplanetNext.json: ns -> class -> {p,c,i,sz?,m,e,d,f})          #
# --------------------------------------------------------------------------- #

def game_classes(game: dict, pattern: str | None = None, exact: bool = False):
    out = []
    for ns, classes in game.get("ns", {}).items():
        for cname, cls in classes.items():
            if pattern is None or _match(pattern, cname, exact):
                out.append((ns, cname, cls))
    return out


def show_game_class(ns: str, cname: str, cls: dict, member_pat: str | None = None):
    size = cls.get("sz")
    size_txt = f" sz={size}" if size is not None else ""
    base = f" : {cls['p']}" if cls.get("p") else ""
    create = " instantiable" if cls.get("c") == 1 else ""
    print(f"{ns}::{cname}{base}{create} id={cls.get('i')}{size_txt}")
    if cls.get("d"):
        print(f"    {cls['d']}")
    members = cls.get("m", [])
    shown = 0
    for m in members:
        if member_pat and not _rx(member_pat, m.get("n", "")):
            continue
        offset = m.get("o")
        off_txt = f"@{offset}" if offset is not None else ""
        mtype = m.get("t")
        type_txt = mtype if mtype not in (None, 0, "0") else "(method)"
        extra = ""
        if m.get("r"):
            extra += f" range={m['r']}"
        if m.get("a"):
            extra += " accessor"
        if m.get("c"):
            extra += " const"
        print(f"    {off_txt:>6} {type_txt:<24} {m.get('n')}{extra}")
        shown += 1
    if member_pat:
        print(f"    ({shown} of {len(members)} members matched /{member_pat}/)")


def cmd_class(args):
    game = load_game(args.game)
    hits = game_classes(game, args.name, exact=not args.substr)
    if not hits:
        print(f"no game class matching '{args.name}'", file=sys.stderr)
        return 1
    for ns, cname, cls in hits:
        show_game_class(ns, cname, cls, member_pat=args.member)
    return 0


def cmd_member(args):
    game = load_game(args.game)
    pat = args.name
    count = 0
    for ns, classes in game.get("ns", {}).items():
        for cname, cls in classes.items():
            for m in cls.get("m", []):
                if _match(pat, m.get("n", ""), exact=not args.substr):
                    offset = m.get("o")
                    off_txt = f"@{offset}" if offset is not None else ""
                    print(f"{ns}::{cname}  {m.get('t','?')} {m.get('n')} {off_txt}")
                    count += 1
    if count == 0:
        print(f"no member matching '{pat}'", file=sys.stderr)
        return 1
    print(f"({count} members)")
    return 0


def cmd_type(args):
    """Class names across both game and core dumps."""
    game = load_game(args.game)
    for ns, cname, cls in game_classes(game, args.name):
        size = cls.get("sz")
        size_txt = f" sz={size}" if size is not None else ""
        print(f"game  {ns}::{cname}{size_txt}")
    try:
        core = load_core(args.core)
    except FileNotFoundError:
        return 0
    for cls in core.get("classes", []):
        if _match(args.name, cls.get("name", ""), exact=False):
            print(f"core  {cls.get('name')} id={cls.get('id')}")
    return 0


# --------------------------------------------------------------------------- #
# Core dump (OpenplanetCore.json)                                              #
# --------------------------------------------------------------------------- #

def _fmt_args(args):
    return ", ".join(f"{a.get('typedecl', a.get('typename', '?'))} {a.get('name', '')}".strip() for a in args)


def cmd_func(args):
    core = load_core(args.core)
    pat = args.name
    count = 0
    for fn in core.get("functions", []):
        fq = f"{fn.get('ns', '')}::{fn.get('name', '')}"
        if _match(pat, fn.get("name", ""), exact=False) or _match(pat, fq, exact=False):
            ret = fn.get("returntypedecl", fn.get("returntypename", "?"))
            print(f"{ret} {fq}({_fmt_args(fn.get('args', []))})")
            if fn.get("desc"):
                print(f"    {fn['desc']}")
            count += 1
    if count == 0:
        print(f"no function matching '{pat}'", file=sys.stderr)
        return 1
    print(f"({count} functions)")
    return 0


def cmd_enum(args):
    core = load_core(args.core)
    pat = args.name
    count = 0
    for en in core.get("enums", []):
        fq = f"{en.get('ns', '')}::{en.get('name', '')}"
        values = en.get("values", {})
        # match on enum name OR any of its value names
        value_hits = [v for v in values if _match(pat, v, exact=False)]
        if _match(pat, en.get("name", ""), exact=False) or _match(pat, fq, exact=False) or value_hits:
            print(f"enum {fq}")
            if en.get("desc"):
                print(f"    {en['desc']}")
            to_show = value_hits if (value_hits and not _match(pat, en.get("name",""), exact=False)) else list(values.keys())
            for v in to_show:
                print(f"    {v} = {values[v].get('v')}")
            count += 1
    if count == 0:
        print(f"no enum matching '{pat}'", file=sys.stderr)
        return 1
    print(f"({count} enums)")
    return 0


def cmd_const(args):
    core = load_core(args.core)
    pat = args.name
    count = 0
    for p in core.get("props", []):
        fq = f"{p.get('ns', '')}::{p.get('name', '')}"
        if _match(pat, p.get("name", ""), exact=False) or _match(pat, fq, exact=False):
            print(f"{p.get('typedecl', '?')} {fq}")
            if p.get("desc"):
                print(f"    {p['desc']}")
            count += 1
    if count == 0:
        print(f"no constant matching '{pat}'", file=sys.stderr)
        return 1
    print(f"({count} constants)")
    return 0


def cmd_method(args):
    """Search methods on core script classes (e.g. DrawList::AddLine)."""
    core = load_core(args.core)
    pat = args.name
    count = 0
    for cls in core.get("classes", []):
        for m in cls.get("methods", []):
            fq = f"{cls.get('name')}::{m.get('name', '')}"
            if _match(pat, m.get("name", ""), exact=False) or _match(pat, fq, exact=False):
                ret = m.get("returntypedecl", "?")
                print(f"{ret} {fq}({_fmt_args(m.get('args', []))})")
                if m.get("desc"):
                    print(f"    {m['desc']}")
                count += 1
    if count == 0:
        print(f"no class method matching '{pat}'", file=sys.stderr)
        return 1
    print(f"({count} methods)")
    return 0


# --------------------------------------------------------------------------- #
# Cross-dump substring search                                                  #
# --------------------------------------------------------------------------- #

def cmd_search(args):
    """Quiet cross-dump substring search: only print sections that have hits."""
    pat = args.name
    sections = []

    game = load_game(args.game)
    game_hits = []
    for ns, classes in game.get("ns", {}).items():
        for cname, cls in classes.items():
            if _match(pat, cname, exact=False):
                game_hits.append(f"class  {ns}::{cname}")
            for m in cls.get("m", []):
                if _match(pat, m.get("n", ""), exact=False):
                    game_hits.append(f"member {ns}::{cname}  {m.get('t','?')} {m.get('n')}")
    if game_hits:
        sections.append((f"game classes/members matching '{pat}'", game_hits))

    try:
        core = load_core(args.core)
    except FileNotFoundError:
        core = None
    if core is not None:
        fn_hits = []
        for fn in core.get("functions", []):
            fq = f"{fn.get('ns', '')}::{fn.get('name', '')}"
            if _match(pat, fn.get("name", ""), exact=False) or _match(pat, fq, exact=False):
                ret = fn.get("returntypedecl", fn.get("returntypename", "?"))
                fn_hits.append(f"{ret} {fq}({_fmt_args(fn.get('args', []))})")
        if fn_hits:
            sections.append((f"scripting functions matching '{pat}'", fn_hits))

        method_hits = []
        for cls in core.get("classes", []):
            for m in cls.get("methods", []):
                fq = f"{cls.get('name')}::{m.get('name', '')}"
                if _match(pat, m.get("name", ""), exact=False) or _match(pat, fq, exact=False):
                    method_hits.append(f"{m.get('returntypedecl', '?')} {fq}({_fmt_args(m.get('args', []))})")
        if method_hits:
            sections.append((f"scripting class methods matching '{pat}'", method_hits))

        enum_hits = []
        for en in core.get("enums", []):
            fq = f"{en.get('ns', '')}::{en.get('name', '')}"
            value_hits = [v for v in en.get("values", {}) if _match(pat, v, exact=False)]
            if _match(pat, en.get("name", ""), exact=False) or _match(pat, fq, exact=False) or value_hits:
                enum_hits.append(f"enum {fq} ({len(en.get('values', {}))} values)")
        if enum_hits:
            sections.append((f"scripting enums matching '{pat}'", enum_hits))

        const_hits = []
        for p in core.get("props", []):
            fq = f"{p.get('ns', '')}::{p.get('name', '')}"
            if _match(pat, p.get("name", ""), exact=False) or _match(pat, fq, exact=False):
                const_hits.append(f"{p.get('typedecl', '?')} {fq}")
        if const_hits:
            sections.append((f"scripting constants matching '{pat}'", const_hits))

    if not sections:
        print(f"nothing matching '{pat}' in either dump", file=sys.stderr)
        return 1
    for i, (title, lines) in enumerate(sections):
        if i:
            print()
        print(f"== {title} ==")
        for line in lines:
            print(line)
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="op-api", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--core", type=Path, help="path to OpenplanetCore.json")
    p.add_argument("--game", type=Path, help="path to OpenplanetNext.json (or an op-*.json snapshot)")
    sub = p.add_subparsers(dest="cmd", required=True)

    def add(name, fn, help_text, with_member=False):
        sp = sub.add_parser(name, help=help_text)
        sp.add_argument("name")
        sp.add_argument("--substr", action="store_true", help="substring match (default for most commands)")
        if with_member:
            sp.add_argument("--member", help="only show members matching this regex")
        sp.set_defaults(fn=fn)
        return sp

    add("class", cmd_class, "show a game class and its members", with_member=True)
    add("member", cmd_member, "find game-class members by name")
    add("type", cmd_type, "class names across game + core dumps")
    add("func", cmd_func, "search scripting-API global/namespace functions")
    add("method", cmd_method, "search methods on scripting-API classes (e.g. DrawList::AddLine)")
    add("enum", cmd_enum, "search scripting-API enums")
    add("const", cmd_const, "search scripting-API constants/props")
    add("search", cmd_search, "substring search across everything")
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.fn(args)
    except FileNotFoundError as exc:
        print(f"error: {exc.filename} not found (set OPENPLANET_DIR or pass --core/--game)", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
