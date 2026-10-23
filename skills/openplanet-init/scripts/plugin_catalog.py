#!/usr/bin/env python3
"""Local-first Openplanet plugin discovery (Python 3.10+, standard library).

metadata.json is an atomically replaced pointer to an immutable full list of
original API records in catalog-<sha256>.json. Old catalogs are retained.
Only refreshes lock; the OS releases a crashed owner.
"""

from __future__ import annotations

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
import errno
import hashlib
from http.client import HTTPException
import json
import math
import os
from pathlib import Path
import sys
import tempfile
import time
from typing import NamedTuple
from urllib.error import HTTPError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


SOURCE_URL = "https://api.openplanet.dev/plugins?filterBroken=false"
CACHE_VERSION = 2
SCHEMA_VERSION = 1
CACHE_FILENAME = "metadata.json"
MAX_AGE = 24 * 60 * 60
FULL_RECONCILE_AGE = 7 * MAX_AGE
MAX_PAGES = 1000
MAX_RESPONSE_BYTES = 8 * 1024 * 1024
MAX_CATALOG_BYTES = 64 * 1024 * 1024
PAGE_DELAY = 0.5
FAILURE_COOLDOWN = 15 * 60
FAILURE_FILENAME = "refresh-failure.json"
VERSIONS_URL = "https://api.openplanet.dev/versions"
ID_BATCH_SIZE = 1000
RECORD_BATCH_SIZE = 96
MAX_DELTA_PAGES = 8
MAX_DELTA_REQUESTS = 20


class CatalogError(Exception):
    """The requested catalog could not be obtained or verified."""


class Catalog(NamedTuple):
    plugins: list[dict]
    metadata: dict
    stale: bool = False
    warning: str | None = None


def default_cache_dir(*, platform=None, environ=None, home=None) -> Path:
    """Return the shared per-user cache directory without creating it."""
    platform = sys.platform if platform is None else platform
    environ = os.environ if environ is None else environ
    home = Path.home() if home is None else Path(home)
    if platform == "win32":
        root = Path(environ["LOCALAPPDATA"]) if environ.get("LOCALAPPDATA") else home / "AppData" / "Local"
    elif platform == "darwin":
        root = home / "Library" / "Caches"
    else:
        xdg = environ.get("XDG_CACHE_HOME", "")
        root = Path(xdg) if xdg and Path(xdg).is_absolute() else home / ".cache"
    return root / "openplanet" / "plugin-catalog"


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")


def _timestamp(value) -> float:
    if not isinstance(value, str):
        raise ValueError("timestamp must be a UTC string")
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.utcoffset() is None or parsed.utcoffset().total_seconds() != 0:
        raise ValueError("timestamp must use UTC")
    return parsed.timestamp()


def _is_stale(metadata: dict, max_age: float) -> bool:
    age = time.time() - _timestamp(metadata["checked_at"])
    return age < 0 or age >= max_age


def _decode_json(raw: str):
    def invalid_constant(value):
        raise ValueError(f"Invalid JSON constant: {value}")

    return json.loads(raw, parse_constant=invalid_constant)


def _parse_catalog(raw: str) -> list[dict]:
    plugins = _decode_json(raw)
    if not isinstance(plugins, list):
        raise ValueError("expected a list of catalog records")
    ids = set()
    for plugin in plugins:
        if not isinstance(plugin, dict) or type(plugin.get("id")) is not int:
            raise ValueError("each plugin must have an integer id")
        if plugin["id"] in ids:
            raise ValueError("duplicate plugin id")
        ids.add(plugin["id"])
        if not isinstance(plugin.get("name"), str) or not plugin["name"].strip():
            raise ValueError("each plugin must have a nonempty name")
        for field in ("identifier", "description", "shortdescription", "url"):
            if plugin.get(field) is not None and not isinstance(plugin[field], str):
                raise ValueError(f"plugin {field} must be a string or null")
        games = plugin.get("games")
        if games is not None and (not isinstance(games, list) or any(not isinstance(g, str) for g in games)):
            raise ValueError("plugin games must be strings")
        if plugin.get("links") is not None and not isinstance(plugin["links"], dict):
            raise ValueError("plugin links must be an object")
        for key in ("source", "issues"):
            if (plugin.get("links") or {}).get(key) is not None and not isinstance(plugin["links"][key], str):
                raise ValueError(f"plugin {key} must be a URL string or null")
        authors = plugin.get("authors")
        if authors is not None and (not isinstance(authors, list) or any(not isinstance(a, dict) for a in authors)):
            raise ValueError("plugin authors must be objects")
    return plugins


def _page_url(source_url: str, page: int) -> str:
    return f"{source_url}{'&' if '?' in source_url else '?'}page={page}"


def _parse_page(raw: str, expected_page: int) -> dict:
    data = _decode_json(raw)
    if not isinstance(data, dict) or not isinstance(data.get("items"), list):
        raise ValueError("expected an API object with items")
    for field in ("page", "pages", "total"):
        if type(data.get(field)) is not int or data[field] < 0:
            raise ValueError(f"invalid page metadata: {field}")
    if data["page"] != expected_page:
        raise ValueError(f"expected page {expected_page}, received {data['page']}")
    if data["pages"] > MAX_PAGES or (data["total"] > 0 and data["pages"] == 0):
        raise ValueError("invalid or excessive page count")
    if data["total"] > 0 and not data["items"]:
        raise ValueError("unexpected empty page")
    if data["total"] == 0 and (data["items"] or data["pages"] > 1):
        raise ValueError("inconsistent empty catalog")
    _parse_catalog(json.dumps(data["items"]))
    return data


def _validate_validators(entry: dict) -> None:
    for key in ("etag", "last_modified"):
        if key in entry and (not isinstance(entry[key], str) or "\r" in entry[key] or "\n" in entry[key]):
            raise ValueError(f"invalid {key}")


def read_cache(cache_dir=None, *, source_url=None, max_age=MAX_AGE) -> Catalog:
    """Read and integrity-check a local snapshot; never access the network."""
    source_url = SOURCE_URL if source_url is None else source_url
    path = Path(cache_dir) if cache_dir is not None else default_cache_dir()
    try:
        metadata = _decode_json((path / CACHE_FILENAME).read_text(encoding="utf-8"))
        if (type(metadata["cache_version"]) is not int or metadata["cache_version"] not in (1, CACHE_VERSION)
                or type(metadata["schema_version"]) is not int or metadata["schema_version"] != SCHEMA_VERSION):
            raise ValueError("unsupported cache/schema version")
        if metadata["source_url"] != source_url:
            raise ValueError("cache belongs to a different source URL")
        digest = metadata["sha256"]
        if not isinstance(digest, str) or len(digest) != 64 or any(c not in "0123456789abcdef" for c in digest):
            raise ValueError("invalid catalog SHA-256")
        if metadata["catalog_file"] != f"catalog-{digest}.json":
            raise ValueError("catalog filename does not match SHA-256")
        raw = (path / metadata["catalog_file"]).read_bytes().decode("utf-8")
        if hashlib.sha256(raw.encode("utf-8")).hexdigest() != metadata["sha256"]:
            raise ValueError("catalog SHA-256 mismatch")
        plugins = _parse_catalog(raw)
        if type(metadata["count"]) is not int or metadata["count"] != len(plugins):
            raise ValueError("catalog count mismatch")
        if metadata["complete"] is not True or type(metadata["total"]) is not int or metadata["total"] != len(plugins):
            raise ValueError("catalog is incomplete")
        pages = metadata["pages"]
        incremental = metadata["cache_version"] == 2 and metadata.get("refresh_mode") == "incremental"
        if not isinstance(pages, list) or len(pages) > MAX_PAGES or (not pages and not incremental):
            raise ValueError("invalid cached pages")
        page_count = pages[0]["pages"] if pages else 0
        if type(metadata["page_count"]) is not int or metadata["page_count"] != page_count:
            raise ValueError("page count metadata mismatch")
        if type(metadata["request_count"]) is not int or metadata["request_count"] < 0:
            raise ValueError("invalid request count metadata")
        if len(pages) != (0 if incremental else max(1, page_count)):
            raise ValueError("cached page count mismatch")
        offset = 0
        for index, page in enumerate(pages):
            if type(page["count"]) is not int or page["count"] < 0:
                raise ValueError("invalid cached page size")
            if page["url"] != _page_url(source_url, index) or page["pages"] != page_count or page["total"] != len(plugins):
                raise ValueError("cached page identity mismatch")
            _validate_validators(page)
            _parse_page(json.dumps({**page, "items": plugins[offset:offset + page["count"]]}), index)
            offset += page["count"]
        if not incremental and offset != len(plugins):
            raise ValueError("cached page sizes do not cover the catalog")
        if _timestamp(metadata["fetched_at"]) > _timestamp(metadata["checked_at"]):
            raise ValueError("fetch is newer than last check")
        if metadata["cache_version"] == 2:
            if metadata.get("refresh_mode") not in ("full", "incremental"):
                raise ValueError("invalid refresh mode")
            if _timestamp(metadata["full_checked_at"]) > _timestamp(metadata["checked_at"]):
                raise ValueError("full validation is newer than last check")
            delta_at = metadata.get("delta_checked_at")
            if delta_at is not None and _timestamp(delta_at) > _timestamp(metadata["checked_at"]):
                raise ValueError("delta validation is newer than last check")
            if incremental and delta_at != metadata["checked_at"]:
                raise ValueError("incremental snapshot has no matching delta check")
        return Catalog(plugins, metadata, _is_stale(metadata, max_age))
    except (OSError, ValueError, TypeError, KeyError, AttributeError, OverflowError) as exc:
        raise CatalogError(f"No usable catalog at {path / CACHE_FILENAME}: {exc}") from exc


def _atomic_write(path: Path, content: str) -> None:
    name = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="", dir=path.parent,
                                         prefix=".catalog-", suffix=".tmp", delete=False) as stream:
            name = stream.name
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if name is not None:
            Path(name).unlink(missing_ok=True)


def _publish(cache_dir: Path, raw: str, metadata: dict) -> None:
    """Publish immutable data first, then its atomic commit pointer.

    Old content files intentionally remain so lock-free readers of an older
    metadata generation can finish. A failed metadata write may leave an unused
    content file, but cannot replace the last-known-good pointer.
    """
    data_path = cache_dir / metadata["catalog_file"]
    if not data_path.exists() or data_path.read_bytes() != raw.encode("utf-8"):
        _atomic_write(data_path, raw)
    _atomic_write(cache_dir / CACHE_FILENAME, json.dumps(metadata, indent=2) + "\n")


@contextmanager
def _cache_lock(cache_dir: Path, timeout: float):
    """Bounded OS-backed lock; no stale lock ownership after a process crash."""
    cache_dir.mkdir(parents=True, exist_ok=True)
    with (cache_dir / "catalog.lock").open("a+b") as stream:
        if stream.tell() == 0:
            stream.write(b"\0")
            stream.flush()
        if sys.platform == "win32":
            import msvcrt

            def acquire():
                stream.seek(0)
                msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)

            def release():
                stream.seek(0)
                msvcrt.locking(stream.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            def acquire():
                fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)

            def release():
                fcntl.flock(stream.fileno(), fcntl.LOCK_UN)

        deadline = time.monotonic() + timeout
        while True:
            try:
                acquire()
                break
            except OSError as exc:
                if exc.errno not in (errno.EACCES, errno.EAGAIN, errno.EDEADLK):
                    raise
                if time.monotonic() >= deadline:
                    raise CatalogError(f"Timed out waiting for catalog lock after {timeout:g}s") from exc
                time.sleep(min(0.05, max(0, deadline - time.monotonic())))
        try:
            yield
        finally:
            release()


def _get(url: str, headers: dict, timeout: float) -> tuple[int, dict, bytes]:
    try:
        with urlopen(Request(url, headers=headers), timeout=timeout) as response:
            body = response.read(MAX_RESPONSE_BYTES + 1)
            if len(body) > MAX_RESPONSE_BYTES:
                raise CatalogError("API page exceeds response size limit")
            length = response.headers.get("Content-Length")
            if length is not None and int(length) != len(body):
                raise CatalogError("API response body is truncated")
            return response.status, dict(response.headers), body
    except HTTPError as exc:
        with exc:
            if exc.code != 304:
                raise
            return 304, dict(exc.headers), b""


class _Requests:
    """One refresh owns pacing and byte accounting across every API route."""

    def __init__(self, timeout, max_requests=None):
        self.timeout = timeout
        self.max_requests = max_requests
        self.count = 0
        self.received_bytes = 0

    def get(self, url, headers=None):
        if self.max_requests is not None and self.count >= self.max_requests:
            raise CatalogError("Delta exceeds request budget; use --full-refresh")
        if self.count:
            time.sleep(PAGE_DELAY)
        self.count += 1
        response = _get(url, headers or {"Accept": "application/json",
                                        "User-Agent": "openplanet-plugin-catalog/2"}, self.timeout)
        self.received_bytes += len(response[2])
        if self.received_bytes > MAX_CATALOG_BYTES:
            raise CatalogError("API catalog exceeds total response size limit")
        return response


def _collect(source_url: str, cached: Catalog | None, timeout: float,
             requests=None) -> tuple[str, dict]:
    """Collect all pages once; a 304 validates only its own cached page."""
    plugins, page_metadata = [], []
    total, pages, offset = None, 1, 0
    requests = requests or _Requests(timeout)
    fetched = False
    index = 0
    while index < max(1, pages):
        url = _page_url(source_url, index)
        prior = None
        headers = {"Accept": "application/json", "User-Agent": "openplanet-plugin-catalog/1"}
        if cached is not None and index < len(cached.metadata["pages"]):
            prior = cached.metadata["pages"][index]
            for key, header in (("etag", "If-None-Match"), ("last_modified", "If-Modified-Since")):
                if prior.get(key):
                    headers[header] = prior[key]
        status, response_headers, body = requests.get(url, headers)
        response_headers = {key.lower(): value for key, value in response_headers.items()}
        if status == 304:
            if prior is None or not any(key in headers for key in ("If-None-Match", "If-Modified-Since")):
                raise CatalogError("API returned 304 without a validated cached page")
            data = {**prior, "items": cached.plugins[offset:offset + prior["count"]]}
            entry = dict(prior)
        elif status == 200:
            data = _parse_page(body.decode("utf-8"), index)
            entry = {"url": url, "page": index, "pages": data["pages"], "total": data["total"],
                     "count": len(data["items"])}
            fetched = True
        else:
            raise CatalogError(f"Unexpected API HTTP status {status}")
        if index == 0:
            pages, total = data["pages"], data["total"]
        if data["pages"] != pages or data["total"] != total:
            raise CatalogError("Catalog pagination changed during refresh; incomplete result discarded")
        for key, header in (("etag", "etag"), ("last_modified", "last-modified")):
            if header in response_headers:
                entry[key] = response_headers[header]
        _validate_validators(entry)
        plugins.extend(data["items"])
        if prior is not None:
            offset += prior["count"]
        page_metadata.append(entry)
        index += 1
    if len(plugins) != total:
        raise CatalogError(f"Incomplete catalog: expected {total} records, received {len(plugins)}")
    raw = json.dumps(plugins, ensure_ascii=False, separators=(",", ":")) + "\n"
    _parse_catalog(raw)  # Includes duplicate IDs across pages.
    checked_at = _utcnow()
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    metadata = {"cache_version": CACHE_VERSION, "schema_version": SCHEMA_VERSION,
                "source_url": source_url, "scope": "public catalog; broken filtering disabled; all games",
                "fetched_at": checked_at if fetched else cached.metadata["fetched_at"],
                "checked_at": checked_at, "count": len(plugins), "total": total, "complete": True,
                "full_checked_at": checked_at, "delta_checked_at": None, "refresh_mode": "full",
                "page_count": pages, "request_count": requests.count, "pages": page_metadata,
                "sha256": digest, "catalog_file": f"catalog-{digest}.json"}
    return raw, metadata


def _with_query(url, query):
    return f"{url}{'&' if '?' in url else '?'}{query}"


def _full_due(cached):
    # Version-1 checks validated every page, so its checked_at is an honest
    # starting point. Migration never downloads the catalog just to change format.
    checked = cached.metadata.get("full_checked_at", cached.metadata["checked_at"])
    age = time.time() - _timestamp(checked)
    return age < 0 or age >= FULL_RECONCILE_AGE


def _has_delta_fields(record):
    return (type(record.get("posttime")) is int and record["posttime"] >= 0
            and type(record.get("signed")) is bool
            and all(isinstance(record.get(key), str) and record[key].strip()
                    for key in ("identifier", "version")))


def _supports_delta(cached):
    return bool(cached.plugins) and all(_has_delta_fields(p) for p in cached.plugins)


def _parse_delta_page(raw, index):
    data = _parse_page(raw, index)
    # Apply the same eligibility contract to every fetched record, including
    # unknown IDs and hydrated old records, before either can replace good data.
    for record in data["items"]:
        if not _has_delta_fields(record):
            raise ValueError(f"Plugin {record['id']} requires nonempty identifier/version, "
                             "nonnegative posttime, and boolean signed for incremental refresh")
    return data


def _json_response(requests, url):
    status, _, body = requests.get(url)
    if status != 200:
        raise CatalogError(f"Unexpected incremental API HTTP status {status}")
    return body.decode("utf-8")


def _id_batches(ids, limit, max_chars=2400):
    batch, length = [], 0
    for key in sorted(ids):
        size = len(str(key)) + 1
        if batch and (len(batch) >= limit or length + size > max_chars):
            yield batch
            batch, length = [], 0
        batch.append(key)
        length += size
    if batch:
        yield batch


def _versions(requests, url, ids):
    """/versions is a filtered version probe, NEVER a global inventory."""
    result = {}
    for values in _id_batches(ids, ID_BATCH_SIZE):
        batch = set(values)
        data = _decode_json(_json_response(requests, _with_query(
            url, "ids=" + ",".join(map(str, sorted(batch))))))
        if not isinstance(data, list):
            raise ValueError("version check must return an array")
        for row in data:
            if (not isinstance(row, dict) or type(row.get("id")) is not int
                    or row["id"] not in batch or row["id"] in result
                    or any(not isinstance(row.get(key), str) or not row[key]
                           for key in ("identifier", "version"))):
                raise ValueError("malformed, duplicate, or unexpected version record")
            result[row["id"]] = (row["identifier"], row["version"])
    return result


def _record_version(record):
    return record.get("identifier"), record.get("version")


def _delta_records(requests, source_url, ids):
    """Fetch only selected records, verifying pagination and requested scope."""
    result = {}
    for values in _id_batches(ids, RECORD_BATCH_SIZE):
        batch = set(values)
        url = _with_query(source_url, "ids=" + ",".join(map(str, sorted(batch))))
        first = None
        index = 0
        records = []
        while first is None or index < max(1, first["pages"]):
            if index >= MAX_DELTA_PAGES:
                raise CatalogError("Delta exceeds bounded page budget; use --full-refresh")
            data = _parse_delta_page(_json_response(requests, _page_url(url, index)), index)
            first = first or data
            if (data["pages"], data["total"]) != (first["pages"], first["total"]):
                raise CatalogError("Delta pagination changed during refresh")
            records.extend(data["items"])
            index += 1
        if len(records) != first["total"]:
            raise CatalogError("Incomplete delta record batch")
        for record in records:
            if record["id"] not in batch or record["id"] in result:
                raise CatalogError("Unexpected or duplicate delta record")
            result[record["id"]] = record
    return result


def _collect_incremental(source_url, versions_url, cached, timeout):
    """Combine known-ID versions, a bounded newest prefix, and selected records.

    Versions miss metadata-only edits. The creation-ordered head catches new
    publications (even when their build is older), not an authoritative
    global inventory. Counts must reconcile; ambiguous scope changes fail closed
    with no automatic full crawl. Weekly full validation covers hidden edits.
    """
    requests = _Requests(timeout, MAX_DELTA_REQUESTS)
    prior = {p["id"]: p for p in cached.plugins}
    versions = _versions(requests, versions_url, prior)
    if not versions:
        raise CatalogError("Empty version check cannot validate a catalog; use --full-refresh")
    watermark = max(p["posttime"] for p in cached.plugins)
    recent = {}
    head = None
    previous_time = None
    for index in range(MAX_DELTA_PAGES):
        data = _parse_delta_page(_json_response(requests, _page_url(source_url, index)), index)
        head = head or data
        if (data["pages"], data["total"]) != (head["pages"], head["total"]):
            raise CatalogError("Newest listing pagination changed during refresh")
        older = False
        for record in data["items"]:
            stamp = record.get("posttime")
            if (type(stamp) is not int or stamp < 0
                    or (previous_time is not None and stamp > previous_time)):
                raise CatalogError("Newest listing is not ordered by valid creation timestamps")
            previous_time = stamp
            if record["id"] in recent:
                raise CatalogError("Duplicate record in newest listing")
            recent[record["id"]] = record
            older = older or stamp < watermark
        end = index + 1 >= max(1, data["pages"])
        if end and len(recent) != head["total"]:
            raise CatalogError("Incomplete newest listing")
        if older or end:
            break
    else:
        raise CatalogError("Newest listing exceeds bounded page budget; use --full-refresh")
    changed = {key for key, version in versions.items() if version != _record_version(prior[key])}
    missing = prior.keys() - versions.keys()
    records = _delta_records(requests, source_url, (changed | missing) - recent.keys())
    records.update(recent)
    if changed - records.keys():
        raise CatalogError("Changed version has no full record")
    for key, record in records.items():
        if key in versions and _record_version(record) != versions[key]:
            raise CatalogError("Version and full record disagree during refresh")
        # Live versions checks include unsigned and broken entries too. An
        # omission followed by a public record is partial/inconsistent evidence.
        if key in missing:
            raise CatalogError("Incomplete version check omitted a public record")
    merged = dict(prior)
    for key in missing - records.keys():
        del merged[key]
    merged.update(records)
    if len(merged) != head["total"]:
        raise CatalogError("Incremental count cannot reconcile additions/deletions; use --full-refresh")
    plugins = list(merged.values())
    raw = json.dumps(plugins, ensure_ascii=False, separators=(",", ":")) + "\n"
    _parse_catalog(raw)
    checked = _utcnow()
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    metadata = {**cached.metadata, "cache_version": CACHE_VERSION,
                "checked_at": checked, "delta_checked_at": checked,
                "full_checked_at": cached.metadata.get("full_checked_at", cached.metadata["checked_at"]),
                "fetched_at": checked if plugins != cached.plugins else cached.metadata["fetched_at"],
                "refresh_mode": "incremental", "version_check_url": versions_url,
                "pages": [], "page_count": 0, "request_count": requests.count,
                "count": len(plugins), "total": len(plugins),
                "sha256": digest, "catalog_file": f"catalog-{digest}.json"}
    return raw, metadata


def _cooldown(cache_dir: Path, source_url: str) -> str | None:
    try:
        failure = _decode_json((cache_dir / FAILURE_FILENAME).read_text(encoding="utf-8"))
        if failure["source_url"] == source_url and _timestamp(failure["retry_at"]) > time.time():
            return f"Refresh cooldown until {failure['retry_at']}: {failure['error']} (use --refresh to retry)"
    except (OSError, ValueError, KeyError, TypeError, OverflowError):
        pass
    return None


def _record_failure(cache_dir: Path, source_url: str, error: Exception) -> None:
    retry_at = time.time() + FAILURE_COOLDOWN
    if isinstance(error, HTTPError):
        value = error.headers.get("Retry-After") if error.headers else None
        if value:
            try:
                try:
                    candidate = time.time() + float(value)
                except ValueError:
                    candidate = parsedate_to_datetime(value).timestamp()
                if math.isfinite(candidate):
                    datetime.fromtimestamp(candidate, timezone.utc)  # Reject unrepresentable dates.
                    retry_at = max(retry_at, candidate)
            except (TypeError, ValueError, OverflowError, OSError):
                pass
    failure = {"source_url": source_url, "failed_at": _utcnow(), "error": str(error),
               "retry_at": datetime.fromtimestamp(retry_at, timezone.utc).isoformat()}
    try:
        _atomic_write(cache_dir / FAILURE_FILENAME, json.dumps(failure) + "\n")
    except OSError:
        pass  # A read-only/full disk must not hide the original refresh error.


def load_catalog(cache_dir=None, *, offline=False, refresh=False, max_age=MAX_AGE,
                 timeout=15.0, lock_timeout=120.0, source_url=None,
                 full_refresh=False, versions_url=None) -> Catalog:
    """Use local data, incremental checks, or periodic full reconciliation.

    Offline always forbids networking, including with refresh=True. Failures
    return a verified last-known-good snapshot with a warning when possible.
    """
    for label, number, allow_zero in (("max_age", max_age, True), ("timeout", timeout, False),
                                       ("lock_timeout", lock_timeout, True)):
        if not math.isfinite(number) or number < 0 or (not allow_zero and number == 0):
            raise ValueError(f"{label} must be finite and {'nonnegative' if allow_zero else 'positive'}")
    source_url = SOURCE_URL if source_url is None else source_url
    refresh = refresh or full_refresh
    # Custom fixture/mirror sources retain the original full-page contract
    # unless their caller explicitly supplies the compatible versions route.
    versions_url = versions_url or (VERSIONS_URL if source_url == SOURCE_URL else None)
    cache_dir = Path(cache_dir) if cache_dir is not None else default_cache_dir()

    def local():
        return read_cache(cache_dir, source_url=source_url, max_age=max_age)

    try:
        cached = local()
    except CatalogError as exc:
        cached, cache_error = None, str(exc)
    if offline:
        if cached is None:
            raise CatalogError(f"Offline: {cache_error}")
        return cached._replace(warning="Offline: using stale cached catalog" if cached.stale else None)
    if cached is not None and not cached.stale and not refresh and not _full_due(cached):
        return cached
    try:
        cooldown = None if refresh else _cooldown(cache_dir, source_url)
        if cooldown:
            raise CatalogError(cooldown)
        with _cache_lock(cache_dir, lock_timeout):
            try:
                latest = local()
            except CatalogError:
                latest = None
            # A concurrent refresher's newly published check also satisfies an
            # explicit refresh which began before that check completed.
            if latest is not None:
                changed = cached is None or latest.metadata != cached.metadata
                cached = latest
                concurrent_full = latest.metadata.get("refresh_mode", "full") == "full"
                if ((changed and not _full_due(latest) and (not full_refresh or concurrent_full))
                        or (not latest.stale and not refresh and not _full_due(latest))):
                    return latest
            cooldown = None if refresh else _cooldown(cache_dir, source_url)
            if cooldown:
                raise CatalogError(cooldown)
            try:
                if (cached is not None and versions_url is not None and not full_refresh
                        and not _full_due(cached) and _supports_delta(cached)):
                    raw, metadata = _collect_incremental(source_url, versions_url, cached, timeout)
                else:
                    raw, metadata = _collect(source_url, cached, timeout)
                _publish(cache_dir, raw, metadata)
            except (OSError, ValueError, HTTPException, CatalogError) as exc:
                _record_failure(cache_dir, source_url, exc)
                raise
            (cache_dir / FAILURE_FILENAME).unlink(missing_ok=True)
            return Catalog(_parse_catalog(raw), metadata, _is_stale(metadata, max_age))
    except (OSError, ValueError, HTTPException, CatalogError) as exc:
        if cached is not None:
            stale = _is_stale(cached.metadata, max_age)
            label = "stale " if stale else ""
            return cached._replace(stale=stale, warning=f"Catalog refresh failed ({exc}); using {label}cached catalog")
        raise CatalogError(f"Catalog refresh failed and no usable cache exists: {exc}") from exc


def search_plugins(catalog: Catalog, terms) -> list[dict]:
    """Return normalized matches; every case-folded term must match a field."""
    if isinstance(terms, str):
        terms = [terms]
    terms = [term.casefold() for term in terms if term.strip()]
    matches = []
    for plugin in catalog.plugins:
        source = (plugin.get("links") or {}).get("source") or None
        site = urljoin("https://openplanet.dev/", plugin.get("url") or "")
        # The public API's request tags select games; preserve that field
        # and expose the same values as `tags` for discovery callers.
        result = {**plugin, "description": plugin.get("description") or plugin.get("shortdescription") or "",
                  "tags": list(plugin.get("games") or []), "site_url": site, "source_url": source}
        fields = [str(plugin["id"]), plugin["name"], plugin.get("identifier") or "",
                  plugin.get("shortdescription") or "", result["description"], site, source or "",
                  (plugin.get("links") or {}).get("issues") or "",
                  *result["tags"]]
        for author in plugin.get("authors") or []:
            fields.extend(str(author.get(key) or "") for key in ("displayname", "username"))
        searchable = "\n".join(fields).casefold()
        if all(term in searchable for term in terms):
            matches.append(result)
    return sorted(matches, key=lambda p: (p["name"].casefold(), p["id"]))


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache-dir", type=Path, help="override the shared user cache directory")
    parser.add_argument("--offline", action="store_true", help="never access the network")
    parser.add_argument("--refresh", action="store_true", help="check even a fresh cache (conditional GET when possible)")
    parser.add_argument("--full-refresh", action="store_true", help="reconcile every metadata page, even with a fresh cache")
    parser.add_argument("--max-age", type=float, default=MAX_AGE, metavar="SECONDS", help="freshness window (default: 86400)")
    parser.add_argument("--timeout", type=float, default=15, metavar="SECONDS", help="HTTP timeout (default: 15)")
    parser.add_argument("--lock-timeout", type=float, default=120, metavar="SECONDS", help="lock wait (default: 120)")
    parser.add_argument("--json", action="store_true", help="machine-readable results")
    commands = parser.add_subparsers(dest="command", required=True)
    search = commands.add_parser("search", help="search all supplied terms across catalog fields")
    search.add_argument("terms", nargs="+")
    commands.add_parser("refresh", help="check and cache the complete catalog")
    commands.add_parser("status", help="inspect the local cache without network access")
    commands.add_parser("demo", help="run an isolated offline discovery demo without changing the user cache")
    args = parser.parse_args(argv)
    try:
        if args.command == "demo":
            return _demo()
        catalog = load_catalog(args.cache_dir, offline=args.offline or args.command == "status",
                               refresh=args.refresh or args.command == "refresh", max_age=args.max_age,
                               timeout=args.timeout, lock_timeout=args.lock_timeout, full_refresh=args.full_refresh)
        if catalog.warning:
            print(f"WARNING: {catalog.warning}", file=sys.stderr)
        if args.command == "search":
            matches = search_plugins(catalog, args.terms)
            if args.json:
                print(json.dumps(matches, ensure_ascii=False, indent=2))
            else:
                for plugin in matches:
                    print(f"{plugin['name']} [{plugin['id']}]\n  {plugin['description']}")
                    print(f"  Games: {', '.join(plugin['tags'])}\n  Site: {plugin['site_url']}")
                    if plugin["source_url"]:
                        print(f"  Source: {plugin['source_url']}")
                print(f"{len(matches)} matching plugin(s)")
        else:
            result = {"cache_path": str((args.cache_dir or default_cache_dir()) / CACHE_FILENAME),
                      **catalog.metadata, "stale": catalog.stale, "warning": catalog.warning}
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (CatalogError, ValueError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


def _demo() -> int:
    from unittest.mock import patch
    from urllib.parse import parse_qs, urlsplit

    print("Synthetic mock transport and isolated cache; no network is used.")
    items = [{"id": key, "name": f"Synthetic plugin {key}", "identifier": f"Demo{key}",
              "version": "1.0", "signed": True, "broken": False, "posttime": key,
              "updatetime": key, "games": ["Trackmania"]} for key in range(1, 61)]
    items[0].update(name="Example Lap Timer", description="Synthetic reusable lap timing.")
    calls = []

    def transport(url, headers, timeout):
        calls.append(url)
        query = parse_qs(urlsplit(url).query)
        selected = items
        if "ids" in query:
            ids = set(map(int, query["ids"][0].split(",")))
            selected = [p for p in items if p["id"] in ids]
        if urlsplit(url).path == "/versions":
            data = [{key: p[key] for key in ("id", "identifier", "version")} for p in selected]
        else:
            selected = sorted(selected, key=lambda p: p["posttime"], reverse=True)
            page = int(query.get("page", [0])[0])
            data = {"items": selected[page * 12:(page + 1) * 12], "page": page,
                    "pages": (len(selected) + 11) // 12, "total": len(selected)}
        return 200, {}, json.dumps(data).encode("utf-8")

    with tempfile.TemporaryDirectory(prefix="openplanet-catalog-demo-") as directory, \
            patch(__name__ + "._get", side_effect=transport), patch(__name__ + ".PAGE_DELAY", 0):
        cold = load_catalog(directory)
        print(f"Cold full reconciliation: {cold.metadata['request_count']} mock requests / 60 records.")
        calls.clear()
        load_catalog(directory)
        assert not calls
        print("Fresh cache: 0 requests.")
        same = load_catalog(directory, refresh=True)
        assert same.metadata["request_count"] == 2
        print("Unchanged incremental check: 2 requests (versions + newest page).")
        items[0]["version"] = "1.1"
        changed = load_catalog(directory, refresh=True)
        assert changed.metadata["request_count"] == 3
        print("One changed older plugin: 3 requests, including one selected-record batch.")
        calls.clear()
        load_catalog(directory, offline=True, full_refresh=True)
        assert not calls
        print("Offline + full-refresh: 0 requests.")
        full = load_catalog(directory, full_refresh=True)
        print(f"Explicit full-refresh: {full.metadata['request_count']} requests; full validation date advanced.")
        print("Search offline for both 'timer' and 'Trackmania':")
        return main(["--cache-dir", directory, "--offline", "search", "timer", "Trackmania"])


if __name__ == "__main__":
    raise SystemExit(main())
