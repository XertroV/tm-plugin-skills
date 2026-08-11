#!/usr/bin/env python3
"""Dependency-free CLI for a fixed-route DEV semantic-control bridge."""

import argparse
import json
import sys

from semantic_control.client import AssertionFailed, ClientError, assert_response, call

ROUTES = ("ping", "component.action", "component.state")


def scalar(value):
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value


def key_values(values):
    result = {}
    for item in values:
        if "=" not in item:
            raise argparse.ArgumentTypeError(f"expected KEY=VALUE: {item}")
        key, value = item.split("=", 1)
        result[key] = scalar(value)
    return result


def parser():
    result = argparse.ArgumentParser(description="DEV-only localhost semantic control")
    result.add_argument("--host", default="127.0.0.1", choices=("127.0.0.1", "localhost", "::1"))
    result.add_argument("--port", type=int, required=True)
    result.add_argument("--timeout", type=float, default=2.0)
    commands = result.add_subparsers(dest="command", required=True)

    raw = commands.add_parser("call")
    raw.add_argument("route", choices=ROUTES)
    raw.add_argument("--id", required=True)
    raw.add_argument("--arg", action="append", default=[])
    raw.add_argument("--assert", dest="assertions", action="append", default=[])

    action = commands.add_parser("action")
    action.add_argument("component")
    action.add_argument("action", choices=("click", "hover", "mouse_button"))
    action.add_argument("--id", required=True)
    action.add_argument("--force", action="store_true")
    action.add_argument("--mouse-button", choices=("left", "right", "middle"))
    action.add_argument("--assert", dest="assertions", action="append", default=[])
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    if args.command == "call":
        route = args.route
        try:
            payload = key_values(args.arg)
        except argparse.ArgumentTypeError as exc:
            parser().error(str(exc))
    else:
        route = "component.action"
        payload = {"component": args.component, "action": args.action, "force": args.force}
        if args.mouse_button is not None:
            payload["mouse_button"] = args.mouse_button
    request = {"v": 1, "id": args.id, "route": route, "args": payload}
    try:
        response = call(args.host, args.port, request, timeout=args.timeout)
        print(json.dumps(response, sort_keys=True))
        if not response.get("ok"):
            return 3
        assert_response(response, args.assertions)
    except AssertionFailed as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 4
    except ClientError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
