#!/usr/bin/env python3
"""Catalog contract tests: fixtures and localhost only, never the public API."""

from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
import hashlib
from http.client import IncompleteRead
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock
from urllib.parse import parse_qs, urlsplit
from urllib.error import HTTPError


SCRIPT = Path(__file__).resolve().parents[1] / "skills/openplanet-init/scripts/plugin_catalog.py"
spec = importlib.util.spec_from_file_location("plugin_catalog", SCRIPT)
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)

# Same field names as api.openplanet.dev; these are synthetic examples, not
# assertions that any particular published plugin has these capabilities.
ITEMS = [
    {"id": 1, "identifier": "CafeTimer", "name": "Café Straße Timer",
     "shortdescription": "Checkpoint timing", "description": "Measure laps and compare ghosts.",
     "games": ["Trackmania", "Maniaplanet"], "url": "plugin/cafe-timer",
     "links": {"source": "https://github.com/example/cafe", "issues": None},
     "authors": [{"displayname": "Test Author", "username": "tester"}],
     "future_field": {"preserved": True}},
    {"id": 2, "identifier": "GhostTools", "name": "Ghost Tools",
     "shortdescription": "Replays", "description": "Inspect saved ghosts",
     "games": ["Turbo"], "url": "https://openplanet.dev/plugin/ghost-tools",
     "links": {"source": None}, "authors": []},
]


def payload(items=None):
    items = ITEMS if items is None else items
    return json.dumps({"items": items, "page": 0, "pages": 1, "total": len(items)},
                      ensure_ascii=False, indent=2).encode("utf-8")


def stored_payload(items=None):
    return (json.dumps(ITEMS if items is None else items, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def page_payload(index, items, *, pages=2, total=2):
    return json.dumps({"items": items, "page": index, "pages": pages, "total": total}).encode()


@contextmanager
def local_server(*, body=None, status=200, headers=None, delay=0):
    """Real urllib transport, bounded fixture response, observable request count."""
    state = {"body": payload() if body is None else body, "status": status,
             "headers": headers or {}, "requests": [], "paths": [], "delay": delay}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            state["requests"].append(dict(self.headers))
            state["paths"].append(self.path)
            time.sleep(state["delay"])
            index = int(parse_qs(urlsplit(self.path).query).get("page", [0])[0])
            body = state.get("pages", {}).get(index, state["body"])
            status, headers = state["status"], state["headers"]
            if "route" in state:
                status, headers, body = state["route"](self.path, dict(self.headers), 15)
            self.send_response(status)
            for key, value in headers.items():
                self.send_header(key, value)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    server.daemon_threads = True
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    state["url"] = f"http://127.0.0.1:{server.server_port}/plugins"
    try:
        yield state
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.cache = Path(self.temp.name) / "cache"
        real_urlopen = catalog.urlopen

        def localhost_only(request, *args, **kwargs):
            self.assertEqual(urlsplit(request.full_url).hostname, "127.0.0.1", "tests forbid real network")
            return real_urlopen(request, *args, **kwargs)

        guard = mock.patch.object(catalog, "urlopen", side_effect=localhost_only)
        guard.start()
        self.addCleanup(guard.stop)

    def seed(self, *, age=0, source_url=None, headers=None):
        fetched = (datetime.now(timezone.utc) - timedelta(seconds=age)).isoformat()
        with mock.patch.object(catalog, "_get", return_value=(200, headers or {}, payload())), \
                mock.patch.object(catalog, "_utcnow", return_value=fetched):
            return catalog.load_catalog(self.cache, source_url=source_url)

    def snapshot(self):
        return self.cache / catalog.CACHE_FILENAME

    def mutate(self, callback):
        data = json.loads(self.snapshot().read_text(encoding="utf-8"))
        callback(data)
        self.snapshot().write_text(json.dumps(data), encoding="utf-8")

    def test_cold_one_get_warm_zero_and_preserves_raw_full_response(self):
        with local_server() as server:
            first = catalog.load_catalog(self.cache, source_url=server["url"])
            second = catalog.load_catalog(self.cache, source_url=server["url"])
            self.assertEqual(len(server["requests"]), 1)
        self.assertEqual(first, second)
        snapshot = json.loads(self.snapshot().read_text(encoding="utf-8"))
        self.assertEqual((self.cache / snapshot["catalog_file"]).read_bytes(), stored_payload())
        self.assertEqual(first.plugins[0]["future_field"], {"preserved": True})
        self.assertEqual(first.metadata["sha256"], hashlib.sha256(stored_payload()).hexdigest())
        self.assertEqual(first.metadata["count"], 2)
        self.assertEqual(first.metadata["source_url"], server["url"])
        self.assertEqual(first.metadata["cache_version"], catalog.CACHE_VERSION)
        self.assertFalse(first.stale)

    def test_etag_and_modified_conditional_get_304_updates_check_only(self):
        with local_server(headers={"ETag": '"v1"', "Last-Modified": "Wed, 21 Oct 2026 00:00:00 GMT"}) as server:
            first = self.seed(age=100000, source_url=server["url"], headers=server["headers"])
            server.update(status=304, body=b"", headers={"ETag": '"v2"'})
            result = catalog.load_catalog(self.cache, source_url=server["url"])
            self.assertEqual(len(server["requests"]), 1)
            request = {key.lower(): value for key, value in server["requests"][0].items()}
            self.assertEqual(request["if-none-match"], '"v1"')
            self.assertIn("if-modified-since", request)
        self.assertEqual(first.metadata["fetched_at"], result.metadata["fetched_at"])
        self.assertNotEqual(first.metadata["checked_at"], result.metadata["checked_at"])
        self.assertEqual(result.metadata["pages"][0]["etag"], '"v2"')
        self.assertEqual(result.metadata["sha256"], first.metadata["sha256"])
        self.assertFalse(result.stale)

    def test_explicit_refresh_checks_fresh_cache_and_200_drops_old_validators(self):
        self.seed(headers={"ETag": '"old"'})
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload())) as get:
            result = catalog.load_catalog(self.cache, refresh=True)
        self.assertEqual(get.call_count, 1)
        self.assertNotIn("etag", result.metadata["pages"][0])

    def test_stale_failed_refresh_preserves_snapshot_and_warns(self):
        self.seed(age=100000)
        before = self.snapshot().read_bytes()
        with mock.patch.object(catalog, "_get", side_effect=OSError("offline test")) as get:
            result = catalog.load_catalog(self.cache)
        self.assertEqual(get.call_count, 1)
        self.assertTrue(result.stale)
        self.assertIn("stale", result.warning)
        self.assertIn("offline test", result.warning)
        self.assertEqual(self.snapshot().read_bytes(), before)

    def test_refresh_failure_warns_even_when_previous_cache_is_fresh(self):
        self.seed()
        with mock.patch.object(catalog, "_get", side_effect=OSError("failed")):
            result = catalog.load_catalog(self.cache, refresh=True)
        self.assertFalse(result.stale)
        self.assertIn("failed", result.warning)

    def test_offline_and_status_never_get_even_when_refresh_requested(self):
        for age in (0, 100000):
            with self.subTest(age=age):
                if self.snapshot().exists():
                    self.snapshot().unlink()
                self.seed(age=age)
                with mock.patch.object(catalog, "_get", side_effect=AssertionError("network")):
                    result = catalog.load_catalog(self.cache, offline=True, refresh=True)
                self.assertEqual(result.stale, age > catalog.MAX_AGE)
                self.assertEqual(bool(result.warning), result.stale)

    def test_missing_offline_fails_without_creating_cache(self):
        with mock.patch.object(catalog, "_get", side_effect=AssertionError("network")):
            with self.assertRaisesRegex(catalog.CatalogError, "Offline.*No usable catalog"):
                catalog.load_catalog(self.cache, offline=True)
        self.assertFalse(self.cache.exists())

    def test_missing_and_http_error_is_actionable(self):
        with local_server(status=503, body=b"unavailable") as server:
            with self.assertRaisesRegex(catalog.CatalogError, "no usable cache.*503"):
                catalog.load_catalog(self.cache, source_url=server["url"])
            self.assertEqual(len(server["requests"]), 1)
        self.assertFalse(self.snapshot().exists())

    def test_corruption_never_used_offline(self):
        mutations = {
            "hash": lambda s: s.update(sha256="bad"),
            "path": lambda s: s.update(catalog_file="../wrong.json"),
            "count": lambda s: s.update(count=200),
            "page_count": lambda s: s.update(page_count=200),
            "request_count": lambda s: s.update(request_count=False),
            "version": lambda s: s.update(cache_version=999),
            "schema": lambda s: s.update(schema_version=999),
            "boolean_version": lambda s: s.update(cache_version=True),
            "source": lambda s: s.update(source_url="https://other.invalid"),
            "timestamp": lambda s: s.update(checked_at="oops"),
            "future_fetch": lambda s: s.update(fetched_at="2999-01-01T00:00:00Z"),
            "validator": lambda s: s["pages"][0].update(etag="foo\r\nBad: 1"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                self.snapshot().unlink(missing_ok=True)
                self.seed()
                self.mutate(mutate)
                with self.assertRaises(catalog.CatalogError):
                    catalog.load_catalog(self.cache, offline=True)

    def test_corrupt_cache_refetched_without_validators(self):
        self.seed(headers={"ETag": '"old"'})
        self.mutate(lambda s: s.update(sha256="bad"))
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload())) as get:
            result = catalog.load_catalog(self.cache)
        self.assertEqual(len(result.plugins), 2)
        self.assertNotIn("If-None-Match", get.call_args.args[1])

    def test_raw_corruption_and_missing_content_are_rejected(self):
        self.seed()
        metadata = json.loads(self.snapshot().read_text())
        content = self.cache / metadata["catalog_file"]
        content.write_bytes(b"{}")
        with self.assertRaisesRegex(catalog.CatalogError, "SHA-256 mismatch"):
            catalog.read_cache(self.cache)
        content.unlink()
        with self.assertRaises(catalog.CatalogError):
            catalog.read_cache(self.cache)

    def test_record_crlf_and_non_ascii_text_are_preserved(self):
        items = [dict(ITEMS[0], description="Café\r\nline2")]
        body = payload(items).replace(b"\n", b"\r\n")
        with mock.patch.object(catalog, "_get", return_value=(200, {}, body)):
            result = catalog.load_catalog(self.cache)
        self.assertEqual((self.cache / result.metadata["catalog_file"]).read_bytes(), stored_payload(items))
        self.assertEqual(catalog.read_cache(self.cache).plugins, items)

    def test_interrupted_http_body_uses_last_known_good(self):
        self.seed(age=100000)
        with mock.patch.object(catalog, "_get", side_effect=IncompleteRead(b"partial", 500)):
            result = catalog.load_catalog(self.cache)
        self.assertIn("IncompleteRead", result.warning)
        self.assertEqual(result.plugins, ITEMS)

    def test_invalid_responses_do_not_replace_last_known_good(self):
        self.seed()
        before = self.snapshot().read_bytes()
        for body in (b"not json", b"{}", b"[]", b'[{"name":"only"}]', b"\xff",
                     payload([{"id": 3, "name": 42}]), payload([ITEMS[0], ITEMS[0]]),
                     payload([dict(ITEMS[0], unknown=float("nan"))]),
                     payload([dict(ITEMS[0], games=False)]), payload([dict(ITEMS[0], links=[])]),
                     page_payload(True, ITEMS, pages=1), page_payload(0, ITEMS, pages=True)):
            with self.subTest(body=body[:50]):
                with mock.patch.object(catalog, "_get", return_value=(200, {}, body)):
                    result = catalog.load_catalog(self.cache, refresh=True)
                self.assertIsNotNone(result.warning)
                self.assertEqual(self.snapshot().read_bytes(), before)

    def test_unsolicited_304_does_not_create_cache(self):
        with mock.patch.object(catalog, "_get", return_value=(304, {}, b"")):
            with self.assertRaisesRegex(catalog.CatalogError, "304"):
                catalog.load_catalog(self.cache)
        self.assertFalse(self.snapshot().exists())

    def test_paginated_partial_catalog_does_not_publish(self):
        data = {"items": ITEMS, "page": 0, "pages": 47, "total": 557}
        with mock.patch.object(catalog, "_get", return_value=(200, {}, json.dumps(data).encode())):
            with self.assertRaisesRegex(catalog.CatalogError, "expected page 1"):
                catalog.load_catalog(self.cache)
        self.assertFalse(self.snapshot().exists())

    def test_changed_catalog_keeps_prior_raw_snapshot(self):
        first = self.seed()
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload(ITEMS[:1]))):
            second = catalog.load_catalog(self.cache, refresh=True)
        self.assertNotEqual(first.metadata["catalog_file"], second.metadata["catalog_file"])
        self.assertEqual((self.cache / first.metadata["catalog_file"]).read_bytes(), stored_payload())
        self.assertEqual(catalog.read_cache(self.cache).plugins, ITEMS[:1])

    def test_full_pagination_aggregates_every_record_and_paces_requests(self):
        with local_server() as server, mock.patch.object(catalog, "PAGE_DELAY", 0):
            server["pages"] = {0: page_payload(0, ITEMS[:1]), 1: page_payload(1, ITEMS[1:])}
            result = catalog.load_catalog(self.cache, source_url=server["url"] + "?filterBroken=false")
            self.assertEqual(result.plugins, ITEMS)
            self.assertEqual(result.metadata["page_count"], 2)
            self.assertEqual(result.metadata["request_count"], 2)
            self.assertTrue(result.metadata["complete"])
            self.assertEqual(server["paths"], ["/plugins?filterBroken=false&page=0", "/plugins?filterBroken=false&page=1"])
            cached = catalog.load_catalog(self.cache, source_url=server["url"] + "?filterBroken=false")
            self.assertEqual(cached.plugins, result.plugins)
            self.assertEqual(len(server["requests"]), 2)
        with mock.patch.object(catalog, "_get", side_effect=[
                (200, {}, page_payload(0, ITEMS[:1])), (200, {}, page_payload(1, ITEMS[1:]))]), \
                mock.patch.object(catalog.time, "sleep") as sleep:
            catalog.load_catalog(self.cache, refresh=True)
        sleep.assert_called_once_with(0.5)

    def test_page_zero_304_does_not_validate_other_pages(self):
        initial = [(200, {"ETag": '"p0"'}, page_payload(0, ITEMS[:1])),
                   (200, {"ETag": '"p1"'}, page_payload(1, ITEMS[1:]))]
        with mock.patch.object(catalog, "_get", side_effect=initial), mock.patch.object(catalog, "PAGE_DELAY", 0):
            first = catalog.load_catalog(self.cache)
        changed = dict(ITEMS[1], description="New full description")
        with mock.patch.object(catalog, "_get", side_effect=[
                (304, {}, b""), (200, {}, page_payload(1, [changed]))]) as get, \
                mock.patch.object(catalog, "PAGE_DELAY", 0):
            result = catalog.load_catalog(self.cache, refresh=True)
        self.assertEqual(get.call_count, 2)
        self.assertEqual(get.call_args_list[0].args[1]["If-None-Match"], '"p0"')
        self.assertEqual(get.call_args_list[1].args[1]["If-None-Match"], '"p1"')
        self.assertEqual(result.plugins[1]["description"], "New full description")
        self.assertNotEqual(result.metadata["sha256"], first.metadata["sha256"])

    def test_invalid_later_pages_preserve_complete_cache(self):
        self.seed()
        before = self.snapshot().read_bytes()
        invalid = [page_payload(0, ITEMS[1:]), page_payload(1, ITEMS[:1]),
                   page_payload(1, ITEMS[1:], total=3), page_payload(1, ITEMS[1:], pages=3),
                   page_payload(1, []), b"<html>failure</html>"]
        for body in invalid:
            with self.subTest(body=body[:60]), mock.patch.object(catalog, "PAGE_DELAY", 0), \
                    mock.patch.object(catalog, "_get", side_effect=[
                        (200, {}, page_payload(0, ITEMS[:1])), (200, {}, body)]):
                result = catalog.load_catalog(self.cache, refresh=True)
                self.assertIsNotNone(result.warning)
                self.assertEqual(self.snapshot().read_bytes(), before)

    def test_page_and_total_size_guards(self):
        with mock.patch.object(catalog, "_get", return_value=(200, {}, page_payload(0, ITEMS[:1], pages=1001))):
            with self.assertRaisesRegex(catalog.CatalogError, "page count"):
                catalog.load_catalog(self.cache)
        with mock.patch.object(catalog, "MAX_CATALOG_BYTES", 1), \
                mock.patch.object(catalog, "_get", return_value=(200, {}, payload())):
            with self.assertRaisesRegex(catalog.CatalogError, "size limit"):
                catalog.load_catalog(self.cache, refresh=True)
        with local_server() as server, mock.patch.object(catalog, "MAX_RESPONSE_BYTES", 1):
            with self.assertRaisesRegex(catalog.CatalogError, "size limit"):
                catalog.load_catalog(self.cache, source_url=server["url"], refresh=True)

    def test_failure_cooldown_suppresses_requests_and_refresh_overrides_it(self):
        self.seed(age=100000)
        with mock.patch.object(catalog, "_get", side_effect=OSError("transient")) as get:
            first = catalog.load_catalog(self.cache)
            second = catalog.load_catalog(self.cache)
        self.assertEqual(get.call_count, 1)
        self.assertIn("transient", first.warning)
        self.assertIn("cooldown", second.warning)
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload())) as get:
            result = catalog.load_catalog(self.cache, refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(get.call_count, 1)
        self.assertFalse((self.cache / catalog.FAILURE_FILENAME).exists())

    def test_cold_failure_cooldown_is_actionable_and_no_network(self):
        with mock.patch.object(catalog, "_get", side_effect=OSError("transient")) as get:
            with self.assertRaises(catalog.CatalogError):
                catalog.load_catalog(self.cache)
            with self.assertRaisesRegex(catalog.CatalogError, "cooldown"):
                catalog.load_catalog(self.cache)
        self.assertEqual(get.call_count, 1)

    def test_retry_after_is_respected_and_invalid_values_do_not_hide_error(self):
        for value in ("3600", "inf", "not a date"):
            with self.subTest(value=value), HTTPError(
                    catalog.SOURCE_URL, 503, "test unavailable", {"Retry-After": value}, None) as error, \
                    mock.patch.object(catalog, "_get", side_effect=error):
                with self.assertRaisesRegex(catalog.CatalogError, "503"):
                    catalog.load_catalog(self.cache, refresh=True)
            failure = json.loads((self.cache / catalog.FAILURE_FILENAME).read_text())
            remaining = catalog._timestamp(failure["retry_at"]) - time.time()
            self.assertGreater(remaining, 3590 if value == "3600" else 890)

    def test_optional_null_fields_and_unsigned_broken_records_are_preserved(self):
        item = {**ITEMS[0], "identifier": None, "description": None, "shortdescription": None,
                "games": None, "authors": None, "url": None, "links": None,
                "signed": False, "broken": True, "deprecated": True, "screenshots": ["legacy.png"]}
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload([item]))):
            result = catalog.load_catalog(self.cache)
        self.assertEqual(result.plugins, [item])
        matches = catalog.search_plugins(result, ["café"])
        self.assertEqual(len(matches), 1)
        self.assertEqual(matches[0]["description"], "")
        self.assertIsNone(matches[0]["source_url"])

    def test_empty_complete_catalog_is_valid(self):
        for pages in (0, 1):
            with self.subTest(pages=pages), mock.patch.object(catalog, "_get", return_value=(
                    200, {}, page_payload(0, [], pages=pages, total=0))):
                result = catalog.load_catalog(self.cache, refresh=True)
            self.assertEqual(result.plugins, [])
            self.assertTrue(result.metadata["complete"])
            self.assertEqual(catalog.read_cache(self.cache).plugins, [])

    def test_atomic_replace_failure_preserves_pair_and_cleans_temporary_file(self):
        self.seed()
        before = self.snapshot().read_bytes()
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload(ITEMS[:1]))), \
                mock.patch.object(catalog.os, "replace", side_effect=OSError("simulated interruption")):
            result = catalog.load_catalog(self.cache, refresh=True)
        self.assertIn("interruption", result.warning)
        self.assertEqual(self.snapshot().read_bytes(), before)
        self.assertEqual(list(self.cache.glob("*.tmp")), [])
        self.assertEqual(catalog.read_cache(self.cache).metadata["count"], 2)

    def test_metadata_publish_failure_preserves_old_pointer_and_raw_file(self):
        old = self.seed()
        before = self.snapshot().read_bytes()
        replace = catalog.os.replace

        def fail_metadata(source, destination):
            if Path(destination).name == catalog.CACHE_FILENAME:
                raise OSError("interrupted before commit")
            replace(source, destination)

        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload(ITEMS[:1]))), \
                mock.patch.object(catalog.os, "replace", side_effect=fail_metadata):
            result = catalog.load_catalog(self.cache, refresh=True)
        self.assertIn("before commit", result.warning)
        self.assertEqual(self.snapshot().read_bytes(), before)
        self.assertTrue((self.cache / old.metadata["catalog_file"]).exists())
        self.assertEqual(catalog.read_cache(self.cache).plugins, old.plugins)
        self.assertEqual(len(list(self.cache.glob("catalog-*.json"))), 2)

    def test_numeric_arguments_are_finite_and_bounded(self):
        for options in ({"timeout": 0}, {"max_age": -1}, {"lock_timeout": -1},
                        {"timeout": float("nan")}, {"max_age": float("inf")}):
            with self.subTest(options=options), self.assertRaises(ValueError):
                catalog.load_catalog(self.cache, **options)

    def test_search_casefold_all_terms_real_fields_and_urls(self):
        result = self.seed()
        for terms in (["CAFÉ", "STRASSE"], ["checkpoint", "ghosts"], ["Maniaplanet"],
                      ["CafeTimer"], ["tester"], ["github.com/example/cafe"]):
            with self.subTest(terms=terms):
                matches = catalog.search_plugins(result, terms)
                self.assertEqual([p["id"] for p in matches], [1])
                self.assertEqual(matches[0]["site_url"], "https://openplanet.dev/plugin/cafe-timer")
                self.assertEqual(matches[0]["source_url"], "https://github.com/example/cafe")
                self.assertIn("Trackmania", matches[0]["tags"])
        self.assertEqual(catalog.search_plugins(result, ["nothing-matches"]), [])
        self.assertEqual(catalog.search_plugins(result, ["CafeTimer", "Turbo"]), [])
        self.assertEqual(catalog.search_plugins(result, ["GhostTools"])[0]["source_url"], None)

    def test_cross_platform_default_paths(self):
        for platform, env, expected in (
            ("win32", {"LOCALAPPDATA": "/local-data"}, "/local-data/openplanet/plugin-catalog"),
            ("win32", {}, "/user/AppData/Local/openplanet/plugin-catalog"),
            ("darwin", {"XDG_CACHE_HOME": "/ignored"}, "/user/Library/Caches/openplanet/plugin-catalog"),
            ("linux", {"XDG_CACHE_HOME": "/xdg"}, "/xdg/openplanet/plugin-catalog"),
            ("linux", {"XDG_CACHE_HOME": "relative"}, "/user/.cache/openplanet/plugin-catalog"),
            ("linux", {}, "/user/.cache/openplanet/plugin-catalog"),
        ):
            with self.subTest(platform=platform, env=env):
                self.assertEqual(catalog.default_cache_dir(platform=platform, environ=env, home="/user"), Path(expected))

    def run_cli(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), "--cache-dir", str(self.cache), *args],
                              capture_output=True, text=True, timeout=10)

    def test_cli_offline_search_json_status_missing_and_demo(self):
        self.assertEqual(self.run_cli("--offline", "search", "ghost").returncode, 1)
        self.seed()
        result = self.run_cli("--offline", "--json", "search", "CAFÉ", "ghosts")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([p["id"] for p in json.loads(result.stdout)], [1])
        result = self.run_cli("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["count"], 2)
        result = self.run_cli("--offline", "--full-refresh", "--json", "search", "ghost")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(json.loads(result.stdout)), 2)
        result = self.run_cli("demo")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("offline", result.stdout.lower())
        self.assertIn("Unchanged incremental check: 2 requests", result.stdout)
        self.assertIn("One changed older plugin: 3 requests", result.stdout)

    def test_cli_stale_warning_and_zero_matches_success(self):
        self.seed(age=100000)
        result = self.run_cli("--offline", "search", "does-not-exist")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("stale", result.stderr)
        self.assertIn("0 matching", result.stdout)

    def test_concurrent_cold_processes_share_one_complete_refresh(self):
        code = ("import importlib.util,sys; s=importlib.util.spec_from_file_location('pc',sys.argv[1]); "
                "m=importlib.util.module_from_spec(s); s.loader.exec_module(m); "
                "c=m.load_catalog(sys.argv[2],source_url=sys.argv[3]); print(c.metadata['count'])")
        processes = []
        with local_server(delay=0.25) as server:
            server["pages"] = {0: page_payload(0, ITEMS[:1]), 1: page_payload(1, ITEMS[1:])}
            try:
                for _ in range(5):
                    processes.append(subprocess.Popen([sys.executable, "-c", code, str(SCRIPT),
                                                       str(self.cache), server["url"]],
                                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True))
                for process in processes:
                    stdout, stderr = process.communicate(timeout=10)
                    self.assertEqual(process.returncode, 0, stderr)
                    self.assertEqual(stdout.strip(), "2")
                self.assertEqual(len(server["requests"]), 2)
            finally:
                for process in processes:
                    if process.poll() is None:
                        process.kill()
                    process.communicate()

    def test_lock_wait_is_finite_and_falls_back(self):
        self.seed(age=100000)
        with catalog._cache_lock(self.cache, 1), mock.patch.object(catalog, "_get") as get:
            started = time.monotonic()
            result = catalog.load_catalog(self.cache, lock_timeout=0.1)
            self.assertLess(time.monotonic() - started, 2)
        get.assert_not_called()
        self.assertIn("Timed out", result.warning)

    def test_terminated_process_releases_lock_without_manual_cleanup(self):
        code = ("import importlib.util,sys; from pathlib import Path\n"
                "s=importlib.util.spec_from_file_location('pc',sys.argv[1])\n"
                "m=importlib.util.module_from_spec(s); s.loader.exec_module(m)\n"
                "with m._cache_lock(Path(sys.argv[2]), 1):\n"
                " print('locked',flush=True)\n"
                " sys.stdin.read()\n")
        process = subprocess.Popen([sys.executable, "-c", code, str(SCRIPT), str(self.cache)],
                                   stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.assertEqual(process.stdout.readline().strip(), "locked")
            with self.assertRaisesRegex(catalog.CatalogError, "Timed out"):
                catalog.load_catalog(self.cache, lock_timeout=0.05)
        finally:
            process.kill()
            process.communicate(timeout=5)
        with mock.patch.object(catalog, "_get", return_value=(200, {}, payload())):
            result = catalog.load_catalog(self.cache, lock_timeout=0.1)
        self.assertEqual(result.plugins, ITEMS)


class FixtureAPI:
    """Synthetic known-ID versions and newest-first paginated full records."""

    def __init__(self, count=30, page_size=12):
        self.records = [{**ITEMS[0], "id": key, "name": f"Plugin {key}",
                         "identifier": f"Plugin{key}", "version": "1.0", "posttime": key,
                         "updatetime": key, "signed": key % 2 == 1, "broken": key == 3}
                        for key in range(1, count + 1)]
        self.page_size = page_size
        self.paths = []
        self.transform = lambda url, data: data

    def __call__(self, url, headers, timeout):
        self.paths.append(url)
        query = parse_qs(urlsplit(url).query)
        records = self.records
        if "ids" in query:
            ids = set(map(int, query["ids"][0].split(",")))
            records = [p for p in records if p["id"] in ids]
        if urlsplit(url).path == "/versions":
            data = [{key: p[key] for key in ("id", "identifier", "version")} for p in records]
        else:
            records = sorted(records, key=lambda p: p["posttime"], reverse=True)
            index = int(query.get("page", [0])[0])
            size = self.page_size
            data = {"items": records[index * size:(index + 1) * size], "page": index,
                    "pages": (len(records) + size - 1) // size, "total": len(records)}
        return 200, {}, json.dumps(self.transform(url, data)).encode()


class IncrementalTests(unittest.TestCase):
    source = "http://127.0.0.1:9999/plugins?filterBroken=false"
    versions = "http://127.0.0.1:9999/versions"

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.cache = Path(self.temp.name)
        self.api = FixtureAPI()
        for patcher in (mock.patch.object(catalog, "_get", side_effect=self.api),
                        mock.patch.object(catalog, "PAGE_DELAY", 0),
                        mock.patch.object(catalog, "urlopen", side_effect=AssertionError("no network"))):
            patcher.start()
            self.addCleanup(patcher.stop)

    def load(self, **kwargs):
        return catalog.load_catalog(self.cache, source_url=self.source, versions_url=self.versions, **kwargs)

    def seed(self, *, age=100000, legacy=False):
        stamp = (datetime.now(timezone.utc) - timedelta(seconds=age)).isoformat()
        with mock.patch.object(catalog, "_utcnow", return_value=stamp):
            result = self.load()
        if legacy:
            metadata = dict(result.metadata)
            metadata["cache_version"] = 1
            for key in ("full_checked_at", "delta_checked_at", "refresh_mode"):
                metadata.pop(key)
            (self.cache / catalog.CACHE_FILENAME).write_text(json.dumps(metadata))
            result = catalog.read_cache(self.cache, source_url=self.source)
        self.api.paths.clear()
        return result

    def pointer(self):
        return (self.cache / catalog.CACHE_FILENAME).read_bytes()

    def test_fresh_zero_stale_unchanged_two_requests_and_honest_dates(self):
        first = self.seed(age=0)
        self.assertEqual(self.load(), first)
        self.assertEqual(self.api.paths, [])
        checked = self.load(refresh=True)
        self.assertEqual(len(self.api.paths), 2)
        self.assertEqual(checked.metadata["request_count"], 2)
        self.assertEqual(checked.metadata["refresh_mode"], "incremental")
        self.assertEqual(checked.metadata["full_checked_at"], first.metadata["full_checked_at"])
        self.assertEqual(checked.metadata["fetched_at"], first.metadata["fetched_at"])
        self.assertEqual(checked.metadata["delta_checked_at"], checked.metadata["checked_at"])
        self.assertEqual(checked.metadata["pages"], [])
        self.assertEqual(checked.metadata["page_count"], 0)
        self.assertEqual(checked.plugins, first.plugins)
        self.assertEqual(catalog.read_cache(self.cache, source_url=self.source), checked)
        self.api.paths.clear()
        self.assertEqual(self.load(), checked)
        self.assertEqual(self.api.paths, [])

    def test_changed_old_record_three_requests_and_raw_fields_preserved(self):
        first = self.seed()
        self.api.records[0].update(version="0.9", future_field={"new": [1, 2]})
        result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["request_count"], 3)
        self.assertEqual(len(self.api.paths), 3)
        self.assertEqual(parse_qs(urlsplit(self.api.paths[-1]).query)["ids"], ["1"])
        row = next(p for p in result.plugins if p["id"] == 1)
        self.assertEqual(row["version"], "0.9")  # Rollbacks are changes too.
        self.assertEqual(row["future_field"], {"new": [1, 2]})
        self.assertTrue((self.cache / first.metadata["catalog_file"]).exists())

    def test_same_version_identifier_change_is_hydrated(self):
        self.seed()
        self.api.records[0]["identifier"] = "Renamed"
        result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["request_count"], 3)
        self.assertEqual(next(p for p in result.plugins if p["id"] == 1)["identifier"], "Renamed")

    def test_new_publication_with_older_build_found_without_updated_order(self):
        self.seed()
        self.api.records.append({**self.api.records[0], "id": 100, "identifier": "NewOldBuild",
                                 "posttime": 31, "updatetime": 0})
        result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["count"], 31)
        self.assertEqual(result.metadata["request_count"], 2)
        self.assertIn(100, [p["id"] for p in result.plugins])
        self.assertTrue(all("order=" not in path and "tags=" not in path for path in self.api.paths))
        self.assertTrue(all(parse_qs(urlsplit(path).query).get("filterBroken") == ["false"]
                            for path in self.api.paths if "/plugins?" in path))

    def test_new_timestamp_ties_continue_past_known_items_and_boundary(self):
        self.api = FixtureAPI(count=10, page_size=2)
        with mock.patch.object(catalog, "_get", side_effect=self.api):
            for row in self.api.records[6:]:
                row["posttime"] = 10
            self.seed()
            self.api.records.append({**self.api.records[0], "id": 99, "posttime": 10})
            result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["count"], 11)
        self.assertEqual(result.metadata["request_count"], 4)  # versions + three boundary pages

    def test_confirmed_absence_removed_for_signed_and_unsigned_records(self):
        for key in (1, 2):
            with self.subTest(key=key):
                if not (self.cache / catalog.CACHE_FILENAME).exists():
                    self.seed()
                else:
                    self.api.paths.clear()
                self.api.records = [p for p in self.api.records if p["id"] != key]
                result = self.load(refresh=True)
                self.assertIsNone(result.warning)
                self.assertEqual(result.metadata["request_count"], 3)
                self.assertNotIn(key, [p["id"] for p in result.plugins])
                self.assertEqual(parse_qs(urlsplit(self.api.paths[-1]).query)["ids"], [str(key)])

    def test_unsigned_broken_included_and_changed_flags_hydrated(self):
        self.seed()
        self.api.records[1].update(version="2.0", signed=True, broken=True)
        result = self.load()
        self.assertIsNone(result.warning)
        row = next(p for p in result.plugins if p["id"] == 2)
        self.assertTrue(row["signed"])
        self.assertTrue(row["broken"])
        self.assertIn(3, [p["id"] for p in result.plugins if p["broken"]])

    def test_metadata_only_edits_reconcile_on_weekly_clock_despite_daily_checks(self):
        initial = self.seed()
        self.api.records[0]["description"] = "Changed without a version or timestamp"
        delta = self.load()
        self.assertIsNone(delta.warning)
        self.assertNotEqual(next(p for p in delta.plugins if p["id"] == 1)["description"],
                            self.api.records[0]["description"])
        self.assertEqual(delta.metadata["full_checked_at"], initial.metadata["full_checked_at"])
        self.api.paths.clear()
        future = catalog._timestamp(initial.metadata["full_checked_at"]) + catalog.FULL_RECONCILE_AGE + 1
        with mock.patch.object(catalog.time, "time", return_value=future), \
                mock.patch.object(catalog, "_utcnow", return_value=datetime.fromtimestamp(
                    future, timezone.utc).isoformat()):
            reconciled = self.load(max_age=catalog.FULL_RECONCILE_AGE * 2)
        self.assertIsNone(reconciled.warning)
        self.assertEqual(reconciled.metadata["refresh_mode"], "full")
        self.assertEqual(reconciled.metadata["request_count"], 3)
        self.assertTrue(all("/versions" not in path for path in self.api.paths))
        self.assertEqual(next(p for p in reconciled.plugins if p["id"] == 1)["description"],
                         self.api.records[0]["description"])
        self.assertNotEqual(reconciled.metadata["full_checked_at"], initial.metadata["full_checked_at"])

    def test_v1_reused_offline_and_migrated_by_two_requests_without_recrawl(self):
        initial = self.seed(legacy=True)
        self.assertEqual(self.load(offline=True).metadata["cache_version"], 1)
        self.assertEqual(self.api.paths, [])
        result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["cache_version"], 2)
        self.assertEqual(result.metadata["full_checked_at"], initial.metadata["checked_at"])
        self.assertEqual(result.metadata["catalog_file"], initial.metadata["catalog_file"])
        self.assertEqual(result.metadata["request_count"], 2)

    def test_full_refresh_overrides_fresh_and_cooldown_but_offline_wins(self):
        self.seed(age=0)
        before = self.pointer()
        result = self.load(offline=True, full_refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(self.api.paths, [])
        self.assertEqual(self.pointer(), before)
        catalog._record_failure(self.cache, self.source, OSError("test failure"))
        result = self.load(full_refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["refresh_mode"], "full")
        self.assertEqual(result.metadata["request_count"], 3)
        self.assertTrue(all("/versions" not in path for path in self.api.paths))

    def test_malformed_partial_empty_versions_never_wipe_or_recrawl(self):
        self.seed()
        before = self.pointer()
        bad_values = [{"error": "bad"}, [], [False], [{"id": True}],
                      [{"id": 5000, "identifier": "x", "version": "1"}],
                      [{"id": 1, "identifier": None, "version": "1"}]]
        for bad in bad_values:
            with self.subTest(bad=bad):
                self.api.paths.clear()
                self.api.transform = lambda url, data: bad if "/versions?" in url else data
                result = self.load(refresh=True)
                self.assertIsNotNone(result.warning)
                self.assertEqual(len(self.api.paths), 1)
                self.assertEqual(self.pointer(), before)
        # Short successful arrays need confirmation; they cannot justify dropping
        # a still-public entry, regardless of signed or broken flags.
        for omitted in (1, 2, 3):
            self.api.paths.clear()
            self.api.transform = lambda url, data: (
                [p for p in data if p["id"] != omitted] if "/versions?" in url else data)
            result = self.load(refresh=True)
            self.assertIsNotNone(result.warning)
            self.assertLessEqual(len(self.api.paths), 3)
            self.assertEqual(self.pointer(), before)

    def test_duplicate_versions_and_inconsistent_changed_records_preserve_pointer(self):
        self.seed()
        before = self.pointer()
        self.api.transform = lambda url, data: data + data[:1] if "/versions?" in url else data
        self.assertIsNotNone(self.load(refresh=True).warning)
        self.assertEqual(self.pointer(), before)
        self.api.records[0]["version"] = "2.0"

        def race(url, data):
            if "/plugins?" in url and "ids=" in url:
                data["items"][0] = {**data["items"][0], "version": "3.0"}
            return data

        self.api.transform = race
        self.api.paths.clear()
        self.assertIn("disagree", self.load(refresh=True).warning)
        self.assertEqual(self.pointer(), before)
        self.assertEqual(len(self.api.paths), 3)

    def test_changed_record_missing_posttime_preserves_snapshot_and_incremental_retry(self):
        initial = self.seed(age=0)
        before = self.pointer()
        raw = (self.cache / initial.metadata["catalog_file"]).read_bytes()
        self.api.records[0]["version"] = "2.0"

        def missing_posttime(url, data):
            if "/plugins?" in url and "ids=" in url:
                data["items"] = [{k: v for k, v in row.items() if k != "posttime"}
                                 for row in data["items"]]
            return data

        self.api.transform = missing_posttime
        failed = self.load(refresh=True)
        self.assertIsNotNone(failed.warning)
        self.assertEqual(failed.metadata, initial.metadata)
        self.assertEqual(self.pointer(), before)
        self.assertEqual((self.cache / initial.metadata["catalog_file"]).read_bytes(), raw)
        self.assertEqual(len(self.api.paths), 3)
        self.api.paths.clear()
        self.assertEqual(self.load(), initial)  # Still fresh; no forced recrawl.
        self.assertEqual(self.api.paths, [])

        self.api.transform = lambda url, data: data
        result = self.load(refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(len(self.api.paths), 3)
        self.assertEqual(result.metadata["refresh_mode"], "incremental")
        self.assertEqual(result.metadata["full_checked_at"], initial.metadata["full_checked_at"])
        self.assertEqual(next(p for p in result.plugins if p["id"] == 1)["version"], "2.0")

    def test_new_record_missing_version_preserves_snapshot_and_incremental_retry(self):
        initial = self.seed(age=0)
        before = self.pointer()
        self.api.records.append({**self.api.records[0], "id": 31, "identifier": "New31",
                                 "posttime": 31})

        def missing_version(url, data):
            if "/plugins?" in url:
                data["items"] = [{k: v for k, v in row.items() if k != "version"}
                                 if row["id"] == 31 else row for row in data["items"]]
            return data

        self.api.transform = missing_version
        failed = self.load(refresh=True)
        self.assertIsNotNone(failed.warning)
        self.assertEqual(failed.metadata, initial.metadata)
        self.assertEqual(self.pointer(), before)
        self.assertEqual(len(self.api.paths), 2)
        self.api.paths.clear()
        self.assertEqual(self.load(), initial)
        self.assertEqual(self.api.paths, [])

        self.api.transform = lambda url, data: data
        result = self.load(refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(len(self.api.paths), 2)
        self.assertEqual(result.metadata["refresh_mode"], "incremental")
        self.assertEqual(result.metadata["full_checked_at"], initial.metadata["full_checked_at"])
        self.assertIn(31, [p["id"] for p in result.plugins])

    def test_minimal_record_contract_applies_to_all_incremental_record_sources(self):
        initial = self.seed(age=0)
        before = self.pointer()
        self.api.records[0]["version"] = "2.0"
        self.api.records.append({**self.api.records[0], "id": 31, "identifier": "New31",
                                 "posttime": 31})
        bad_fields = [("identifier", ""), ("identifier", "  "), ("version", ""),
                      ("version", "  "), ("version", None), ("posttime", None),
                      ("posttime", -1), ("posttime", True), ("posttime", 1.5),
                      ("signed", None), ("signed", 1), ("signed", "true")]
        for target, requests in ((30, 2), (31, 2), (1, 3)):
            for field, value in bad_fields:
                with self.subTest(target=target, field=field, value=value):
                    def malformed(url, data):
                        if "/plugins?" in url:
                            data["items"] = [{**row, field: value} if row["id"] == target else row
                                             for row in data["items"]]
                        return data

                    self.api.transform = malformed
                    self.api.paths.clear()
                    result = self.load(refresh=True)
                    self.assertIsNotNone(result.warning)
                    self.assertEqual(result.metadata, initial.metadata)
                    self.assertEqual(self.pointer(), before)
                    self.assertEqual(len(self.api.paths), requests)

    def test_incomplete_terminal_newest_page_preserves_cache_even_when_boundary_crossed(self):
        for pages in (1, 2):
            with self.subTest(pages=pages):
                # Twelve tied newest rows force the two-page case to continue;
                # the final page crosses the old watermark but omits old rows.
                for row in self.api.records[18:]:
                    row["posttime"] = 30
                initial = self.seed(age=0)
                before = self.pointer()

                def incomplete(url, data):
                    if "/plugins?" in url and "ids=" not in url:
                        data["pages"] = pages
                        if data["page"] == pages - 1:
                            data["items"] = [dict(self.api.records[0])]
                    return data

                self.api.transform = incomplete
                failed = self.load(refresh=True)
                self.assertIn("Incomplete newest listing", failed.warning)
                self.assertEqual(failed.metadata, initial.metadata)
                self.assertEqual(self.pointer(), before)
                self.assertEqual(len(self.api.paths), pages + 1)
                self.api.transform = lambda url, data: data
                self.api.paths.clear()

    def test_complete_terminal_newest_page_allows_boundary_and_timestamp_ties(self):
        self.api.records = self.api.records[:5]
        initial = self.seed(age=0)
        result = self.load(refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(result.plugins, initial.plugins)
        self.assertEqual(len(self.api.paths), 2)
        self.assertEqual(result.metadata["refresh_mode"], "incremental")
        self.assertEqual(result.metadata["full_checked_at"], initial.metadata["full_checked_at"])

        for row in self.api.records:
            row["posttime"] = 5
        self.api.paths.clear()
        self.load(full_refresh=True)
        self.api.paths.clear()
        tied = self.load(refresh=True)
        self.assertIsNone(tied.warning)
        self.assertEqual(len(self.api.paths), 2)
        self.assertEqual(tied.metadata["refresh_mode"], "incremental")

    def test_membership_churn_unexplained_count_and_deleted_all_fail_closed(self):
        self.seed()
        before = self.pointer()
        self.api.records.append({**self.api.records[0], "id": 200, "posttime": 0})
        result = self.load(refresh=True)
        self.assertIn("cannot reconcile", result.warning)
        self.assertEqual(self.pointer(), before)
        self.assertEqual(len(self.api.paths), 2)
        self.api.records.clear()
        self.api.paths.clear()
        self.assertIn("Empty version", self.load(refresh=True).warning)
        self.assertEqual(len(self.api.paths), 1)
        self.assertEqual(self.pointer(), before)

    def test_pacing_applies_between_versions_discovery_and_hydration(self):
        self.seed()
        self.api.records[0]["version"] = "2.0"
        with mock.patch.object(catalog, "PAGE_DELAY", 0.5), mock.patch.object(catalog.time, "sleep") as sleep:
            result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(sleep.call_args_list, [mock.call(0.5), mock.call(0.5)])

    def test_partial_racy_or_unordered_newest_pages_preserve_cache(self):
        self.api = FixtureAPI(count=10, page_size=2)
        with mock.patch.object(catalog, "_get", side_effect=self.api):
            for row in self.api.records[6:]:
                row["posttime"] = 10
            self.seed()
            before = self.pointer()

            def duplicate(url, data):
                if "/plugins?" in url and data["page"] == 1:
                    data["items"][0] = dict(self.api.records[6])
                return data

            def wrong_total(url, data):
                if "/plugins?" in url and data["page"] == 1:
                    data["total"] += 1
                return data

            def unordered(url, data):
                if "/plugins?" in url:
                    data["items"] = list(reversed(data["items"]))
                    if data["page"] == 1:
                        data["items"][0] = {**data["items"][0], "posttime": 20}
                return data

            def partial(url, data):
                if "/plugins?" in url:
                    data["pages"] = 1
                return data

            for transform in (duplicate, wrong_total, unordered, partial):
                with self.subTest(transform=transform.__name__):
                    self.api.transform = transform
                    self.api.paths.clear()
                    result = self.load(refresh=True)
                    self.assertIsNotNone(result.warning)
                    self.assertEqual(self.pointer(), before)
                    self.assertLessEqual(len(self.api.paths), 3)

    def test_partial_or_wrong_scope_hydration_pages_preserve_cache(self):
        self.seed()
        before = self.pointer()
        self.api.records[0]["version"] = "2.0"

        def empty(url, data):
            if "/plugins?" in url and "ids=" in url:
                data.update(items=[], total=0, pages=0)
            return data

        def wrong_id(url, data):
            if "/plugins?" in url and "ids=" in url:
                data["items"][0] = dict(self.api.records[1])
            return data

        def partial(url, data):
            if "/plugins?" in url and "ids=" in url:
                data["total"] += 1
            return data

        def bad_page(url, data):
            if "/plugins?" in url and "ids=" in url:
                data["page"] += 1
            return data

        for transform in (empty, wrong_id, partial, bad_page):
            with self.subTest(transform=transform.__name__):
                self.api.transform = transform
                self.api.paths.clear()
                self.assertIsNotNone(self.load(refresh=True).warning)
                self.assertEqual(self.pointer(), before)
                self.assertEqual(len(self.api.paths), 3)

    def test_delta_cooldown_suppresses_repeated_checks_and_refresh_overrides(self):
        self.seed()
        self.api.transform = lambda url, data: [] if "/versions?" in url else data
        first = self.load()
        self.assertIsNotNone(first.warning)
        self.api.paths.clear()
        second = self.load()
        self.assertIn("cooldown", second.warning)
        self.assertEqual(self.api.paths, [])
        self.api.transform = lambda url, data: data
        result = self.load(refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(len(self.api.paths), 2)

    def test_full_reconciliation_after_delta_has_no_stale_page_validators(self):
        self.seed()
        metadata = json.loads(self.pointer())
        for page in metadata["pages"]:
            page["etag"] = '"old-page"'
        (self.cache / catalog.CACHE_FILENAME).write_text(json.dumps(metadata))
        delta = self.load()
        self.assertEqual(delta.metadata["pages"], [])
        with mock.patch.object(catalog, "_get", side_effect=self.api) as transport:
            result = self.load(full_refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(transport.call_count, 3)
        self.assertTrue(all("If-None-Match" not in call.args[1] for call in transport.call_args_list))

    def test_concurrent_delta_cannot_satisfy_explicit_full_refresh(self):
        self.seed(age=0)

        @contextmanager
        def intervening_delta(cache_dir, timeout):
            cached = catalog.read_cache(cache_dir, source_url=self.source)
            raw, metadata = catalog._collect_incremental(self.source, self.versions, cached, 15)
            catalog._publish(cache_dir, raw, metadata)
            yield

        with mock.patch.object(catalog, "_cache_lock", side_effect=intervening_delta):
            result = self.load(full_refresh=True)
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["refresh_mode"], "full")
        self.assertEqual(result.metadata["request_count"], 3)
        self.assertEqual(len(self.api.paths), 5)  # concurrent delta 2 + required full 3

    def test_request_and_discovery_page_caps_fail_without_full_fallback(self):
        self.seed()
        before = self.pointer()
        for key in range(31, 55):
            self.api.records.append({**self.api.records[0], "id": key, "posttime": key})
        with mock.patch.object(catalog, "MAX_DELTA_PAGES", 1):
            result = self.load(refresh=True)
        self.assertIn("bounded page budget", result.warning)
        self.assertEqual(self.pointer(), before)
        self.api.paths.clear()
        with mock.patch.object(catalog, "MAX_DELTA_REQUESTS", 1):
            result = self.load(refresh=True)
        self.assertIn("request budget", result.warning)
        self.assertEqual(len(self.api.paths), 1)
        self.assertEqual(self.pointer(), before)

    def test_delta_publication_failure_keeps_old_pointer_raw_and_dates(self):
        initial = self.seed(legacy=True)
        before = self.pointer()
        self.api.records[0]["version"] = "2.0"
        replace = catalog.os.replace

        def interrupted(source, destination):
            if Path(destination).name == catalog.CACHE_FILENAME:
                raise OSError("interrupted delta commit")
            replace(source, destination)

        with mock.patch.object(catalog.os, "replace", side_effect=interrupted):
            result = self.load()
        self.assertIn("interrupted delta", result.warning)
        self.assertEqual(self.pointer(), before)
        self.assertTrue((self.cache / initial.metadata["catalog_file"]).exists())
        self.assertEqual(result.metadata, initial.metadata)

    def test_versions_url_chunking_is_bounded_and_includes_unsigned_broken(self):
        self.seed()
        with mock.patch.object(catalog, "ID_BATCH_SIZE", 10):
            result = self.load()
        self.assertIsNone(result.warning)
        self.assertEqual(result.metadata["request_count"], 4)
        ids = [int(key) for path in self.api.paths if "/versions?" in path
               for key in parse_qs(urlsplit(path).query)["ids"][0].split(",")]
        self.assertEqual(sorted(ids), list(range(1, 31)))
        huge = list(range(100000000, 100001000))
        self.assertTrue(all(len(",".join(map(str, batch))) <= 2400
                            for batch in catalog._id_batches(huge, catalog.ID_BATCH_SIZE)))

    def test_localhost_integration_and_concurrent_stale_refresh_share_one_delta(self):
        api = FixtureAPI(count=30)
        with local_server(delay=0.05) as server:
            server["route"] = api
            source = server["url"] + "?filterBroken=false"
            versions = server["url"].replace("/plugins", "/versions")
            # The mock setup only seeds a valid old cache; child processes use
            # real urllib over localhost, exercising cross-process locking.
            with mock.patch.object(catalog, "_get", side_effect=api), \
                    mock.patch.object(catalog, "_utcnow", return_value=(
                        datetime.now(timezone.utc) - timedelta(days=2)).isoformat()):
                catalog.load_catalog(self.cache, source_url=source)
            code = ("import importlib.util,sys; s=importlib.util.spec_from_file_location('pc',sys.argv[1]); "
                    "m=importlib.util.module_from_spec(s); s.loader.exec_module(m); "
                    "c=m.load_catalog(sys.argv[2],source_url=sys.argv[3],versions_url=sys.argv[4]); "
                    "assert c.warning is None,c.warning; print(c.metadata['request_count'])")
            children = [subprocess.Popen([sys.executable, "-c", code, str(SCRIPT), str(self.cache),
                                           source, versions], stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE, text=True) for _ in range(4)]
            try:
                for child in children:
                    stdout, stderr = child.communicate(timeout=10)
                    self.assertEqual(child.returncode, 0, stderr)
                    self.assertEqual(stdout.strip(), "2")
                self.assertEqual(len(server["requests"]), 2)
            finally:
                for child in children:
                    if child.poll() is None:
                        child.kill()
                    child.communicate()


if __name__ == "__main__":
    unittest.main(verbosity=2)
