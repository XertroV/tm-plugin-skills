#!/usr/bin/env python3
"""Deterministically assemble and validate the issue-12 throwaway gallery proof."""

from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError as exc:  # pragma: no cover - explicit environment failure
    raise SystemExit("FAIL: python package 'jsonschema' is required") from exc

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "generated" / "VisualRecipeGallery"
LIB_OUT = ROOT / "generated" / "SkillpackDemoLib"
MANIFEST_PATH = ROOT / "manifest.json"
SCHEMA_PATH = ROOT / "recipe.schema.json"
MATRIX_PATH = ROOT / "screenshot-matrix.json"
TIERS = ("default-imgui", "nvg", "advanced")
FORBIDDEN_TEXT = (
    "tm-agent/src",
    "tm-bosslike/src",
    "reviewer page",
    "reviewer route",
    "bypass review",
    "evade review",
    "paid-feature bypass",
)
BINARY_SUFFIXES = {".ttf", ".otf", ".png", ".jpg", ".jpeg", ".webp", ".gif", ".mp3", ".wav", ".ogg"}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fail(message: str) -> None:
    raise AssertionError(message)


def validate_model(manifest: dict, matrix: dict) -> None:
    jsonschema.Draft202012Validator.check_schema(load_json(SCHEMA_PATH))
    jsonschema.validate(manifest, load_json(SCHEMA_PATH))

    recipes = manifest["recipes"]
    for field in ("id", "source", "namespace"):
        values = [recipe[field] for recipe in recipes]
        if len(values) != len(set(values)):
            fail(f"duplicate recipe {field}: {values}")

    for recipe in recipes:
        source = ROOT / recipe["source"]
        if not source.is_file():
            fail(f"missing canonical recipe: {recipe['source']}")
        provenance = recipe.get("provenance")
        if provenance is not None and provenance["file"] != f"prototypes/issue-12-gallery/{recipe['source']}":
            fail(f"present provenance file does not identify canonical source: {recipe['id']}")

    curations = [recipe["curation"] for recipe in recipes]
    if "featured" not in curations or "boring" not in curations:
        fail("gallery must contain both featured and boring recipes")

    axes = matrix["axes"]
    ids = {recipe["id"] for recipe in recipes}
    seen_cases: set[str] = set()
    covered_frames: set[tuple[str, int]] = set()
    for case in matrix["required_cases"]:
        if case["id"] in seen_cases:
            fail(f"duplicate screenshot case: {case['id']}")
        seen_cases.add(case["id"])
        if case["recipe"] not in ids:
            fail(f"unknown screenshot recipe: {case['recipe']}")
        for axis in ("theme", "viewport", "ui_scale", "game_state"):
            if case[axis] not in axes[axis]:
                fail(f"screenshot case {case['id']} has undeclared {axis}: {case[axis]}")
        covered_frames.add((case["recipe"], case["frame"]))

    for recipe in recipes:
        for frame in recipe["state_contract"]["capture_frames"]:
            if (recipe["id"], frame) not in covered_frames:
                fail(f"missing screenshot case for {recipe['id']} frame {frame}")

    default_text = "\n".join((ROOT / r["source"]).read_text() for r in recipes if r["tier"] == "default-imgui")
    if "PushStyleColor" in default_text or "PushStyleVar" in default_text:
        fail("default ImGui tier overrides style/color")

    for recipe in recipes:
        text = (ROOT / recipe["source"]).read_text()
        instrumentation = recipe["state_contract"]["instrumentation"]
        if "clip-depth" in instrumentation and not ("clipDepth++" in text and "clipDepth--" in text and "PopClipRect" in text):
            fail(f"clip instrumentation is not mechanically balanced: {recipe['id']}")
        if "scissor-depth" in instrumentation and not ("scissorDepth++" in text and "scissorDepth--" in text and "ResetScissor" in text):
            fail(f"scissor instrumentation is not mechanically balanced: {recipe['id']}")
        if "style-depth" in instrumentation and "styleDepth" not in text:
            fail(f"style instrumentation missing: {recipe['id']}")
        if "animation-state" in instrumentation and "captureFrame" not in text:
            fail(f"deterministic animation state missing: {recipe['id']}")
        if "stable-id" in instrumentation and "###" not in text:
            fail(f"stable widget identity missing: {recipe['id']}")
        if "render-ownership" in instrumentation and "SubmissionCount" not in text:
            fail(f"render ownership seam missing: {recipe['id']}")
        if "visibility-state" in instrumentation and "InvokeAction" not in text:
            fail(f"visibility-safe action seam missing: {recipe['id']}")


def as_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def generate_catalog(manifest: dict) -> str:
    recipes = manifest["recipes"]
    lines = [
        "// GENERATED by prototype.py from manifest.json; do not edit.",
        "enum GalleryTier { DefaultImgui, Nvg, Advanced }",
        "",
        "class RecipeMeta {",
        "    string Id; string Title; GalleryTier Tier; bool IsFeatured; string Maturity; string Expected; string Provenance; int[] CaptureFrames;",
        "    RecipeMeta(const string &in id, const string &in title, GalleryTier tier, bool isFeatured, const string &in maturity, const string &in expected, const string &in provenance, int[] frames) {",
        "        Id = id; Title = title; Tier = tier; IsFeatured = isFeatured; Maturity = maturity; Expected = expected; Provenance = provenance; CaptureFrames = frames;",
        "    }",
        "}",
        "",
        "RecipeMeta@[] g_recipes = {",
    ]
    tier_expr = {"default-imgui": "GalleryTier::DefaultImgui", "nvg": "GalleryTier::Nvg", "advanced": "GalleryTier::Advanced"}
    for recipe in recipes:
        p = recipe.get("provenance")
        provenance = "" if p is None else f"{p['repository']} · {p['file']} · {p['kind']}"
        frames = ", ".join(str(frame) for frame in recipe["state_contract"]["capture_frames"])
        lines.append(
            f"    RecipeMeta({as_string(recipe['id'])}, {as_string(recipe['title'])}, {tier_expr[recipe['tier']]}, {str(recipe['curation'] == 'featured').lower()}, "
            f"{as_string(recipe['maturity'])}, {as_string(recipe['expected'])}, {as_string(provenance)}, {{{frames}}}),"
        )
    lines.extend(["};", "", "void DrawRecipeByIndex(int index, int captureFrame) {"])
    for index, recipe in enumerate(recipes):
        call = f"{recipe['namespace']}::{recipe['entrypoint']}(captureFrame);"
        lines.append(f"    {'if' if index == 0 else 'else if'} (index == {index}) {call}")
    lines.extend(["}", ""])
    return "\n".join(lines)


def generate_main(manifest: dict) -> str:
    initial_recipe = next(i for i, recipe in enumerate(manifest["recipes"]) if recipe["curation"] == "featured")
    return """// GENERATED prototype shell; do not edit. Canonical implementations live in recipes/*.as.
bool g_windowOpen = true;
int g_selectedRecipe = __INITIAL_RECIPE__;
int g_captureFrame = 0;

void RenderMenu() {
    if (UI::BeginMenu("Skillpack Demos")) {
        if (UI::MenuItem("Visual Recipe Gallery PROTOTYPE", "", g_windowOpen)) g_windowOpen = !g_windowOpen;
        UI::EndMenu();
    }
}

void RenderInterface() {
    DrawGalleryWindow();
}

void Render() {
    // RenderInterface owns the normal Openplanet-overlay path. Only use Render for the
    // optional HUD-like path while the overlay is hidden; otherwise the same ImGui window
    // ID is submitted twice and its interior can appear duplicated.
    if (UI::IsOverlayShown()) return;
    DrawGalleryWindow();
}

void DrawGalleryWindow() {
    if (!g_windowOpen) return;
    UI::SetNextWindowSize(780, 560, UI::Cond::FirstUseEver);
    if (UI::Begin("Visual Recipe Gallery PROTOTYPE###skillpack-demo-gallery", g_windowOpen)) DrawGallery();
    UI::End();
}

void DrawGallery() {
    UI::TextWrapped("THROWAWAY / STATIC-ONLY: no recipe shown here is stable until live screenshot gates pass.");
    UI::Separator();
    if (UI::BeginTable("gallery-layout", 2, UI::TableFlags::SizingStretchProp | UI::TableFlags::BordersInnerV)) {
        UI::TableSetupColumn("Navigation", UI::TableColumnFlags::WidthFixed, 230);
        UI::TableSetupColumn("Recipe", UI::TableColumnFlags::WidthStretch);
        UI::TableNextRow();
        UI::TableNextColumn(); DrawNavigation();
        UI::TableNextColumn(); DrawSelectedRecipe();
        UI::EndTable();
    }
}

void DrawNavigation() {
    UI::BeginTabBar("gallery-curation-tabs");
        if (UI::BeginTabItem("Featured")) {
            DrawNavigationForCuration(true);
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Boring")) {
            DrawNavigationForCuration(false);
            UI::EndTabItem();
        }
    UI::EndTabBar();
}

void DrawNavigationForCuration(bool featured) {
    EnsureSelectionMatchesCuration(featured);
    GalleryTier lastTier = GalleryTier::Advanced;
    bool first = true;
    for (uint i = 0; i < g_recipes.Length; i++) {
        auto recipe = g_recipes[i];
        if (recipe.IsFeatured != featured) continue;
        if (first || recipe.Tier != lastTier) {
            UI::SeparatorText(TierName(recipe.Tier));
            lastTier = recipe.Tier; first = false;
        }
        if (UI::Selectable(recipe.Title + "###recipe-" + recipe.Id, int(i) == g_selectedRecipe)) g_selectedRecipe = int(i);
    }
}

void EnsureSelectionMatchesCuration(bool featured) {
    if (g_selectedRecipe >= 0 && g_selectedRecipe < int(g_recipes.Length)
            && g_recipes[g_selectedRecipe].IsFeatured == featured) return;
    for (uint i = 0; i < g_recipes.Length; i++) {
        if (g_recipes[i].IsFeatured == featured) {
            g_selectedRecipe = int(i);
            g_captureFrame = g_recipes[i].CaptureFrames[0];
            return;
        }
    }
}

void DrawSelectedRecipe() {
    auto recipe = g_recipes[g_selectedRecipe];
    UI::Text(recipe.Title);
    UI::TextDisabled(recipe.Id + " · " + recipe.Maturity);
    UI::TextWrapped("Expected: " + recipe.Expected);
    UI::TextWrapped("Provenance: " + recipe.Provenance);
    UI::SetNextItemWidth(260);
    g_captureFrame = UI::SliderInt("Deterministic capture frame", g_captureFrame, 0, 120);
    UI::Text("Matrix frames:"); UI::SameLine();
    for (uint i = 0; i < recipe.CaptureFrames.Length; i++) {
        if (i > 0) UI::SameLine();
        int frame = recipe.CaptureFrames[i];
        if (UI::Button(tostring(frame) + "###capture-frame-" + recipe.Id + "-" + i)) g_captureFrame = frame;
    }
    UI::SameLine();
    if (UI::Button("Reset state###reset-state-" + recipe.Id)) g_captureFrame = recipe.CaptureFrames[0];
    UI::Separator();
    DrawRecipeByIndex(g_selectedRecipe, g_captureFrame);
}

string TierName(GalleryTier tier) {
    if (tier == GalleryTier::DefaultImgui) return "1 · Theme-respecting default ImGui";
    if (tier == GalleryTier::Nvg) return "2 · NVG recipes";
    return "3 · Advanced composition (opt-in)";
}
""".replace("__INITIAL_RECIPE__", str(initial_recipe))


def generate_info(manifest: dict) -> str:
    gallery = manifest["gallery"]
    return f'''[meta]\nname = {json.dumps(gallery["name"])}\nauthor = "tm-plugin-skills prototype"\ncategory = "Skillpack Demos"\nversion = {json.dumps(gallery["version"])}\nsiteid = 0\n\n[script]\ndependencies = ["SkillpackDemoLib"]\nexport_dependencies = ["SkillpackDemoLib"]\n'''


def generate_library_info() -> str:
    return '''[meta]\nname = "Skillpack Demo Library PROTOTYPE"\nauthor = "tm-plugin-skills prototype"\ncategory = "Skillpack Demos"\nversion = "0.0.0"\nsiteid = 0\n\n[script]\nmodule = "SkillpackDemoLib"\nexports = ["Exports.as"]\n'''


def generate_library_exports() -> str:
    return '''namespace SkillpackDemoLib {\n    float ClampUnit(float value) { return Math::Clamp(value, 0.0f, 1.0f); }\n    float PhaseFromFrame(int frame, int maxFrame) {\n        if (maxFrame <= 0) return 0.0f;\n        return ClampUnit(float(frame) / float(maxFrame));\n    }\n}\n'''


def expected_outputs(manifest: dict) -> dict[Path, bytes]:
    outputs: dict[Path, bytes] = {
        LIB_OUT / "info.toml": generate_library_info().encode(),
        LIB_OUT / "Exports.as": generate_library_exports().encode(),

        OUT / "info.toml": generate_info(manifest).encode(),
        OUT / "src" / "Main.as": generate_main(manifest).encode(),
        OUT / "src" / "GeneratedCatalog.as": generate_catalog(manifest).encode(),
    }
    for recipe in manifest["recipes"]:
        source = ROOT / recipe["source"]
        banner = f"// GENERATED COPY sha256={sha256(source.read_bytes())} source={recipe['source']}\n".encode()
        outputs[OUT / "src" / "recipes" / source.name] = banner + source.read_bytes()
        test_source = source.with_name(source.stem + "_Test.as")
        if not test_source.is_file():
            fail(
                f"recipe {recipe['id']} is missing neighboring test companion "
                f"{test_source.name}"
            )
        relative_test = test_source.relative_to(ROOT)
        test_banner = f"// GENERATED COPY sha256={sha256(test_source.read_bytes())} source={relative_test}\n".encode()
        outputs[OUT / "src" / "recipes" / test_source.name] = test_banner + test_source.read_bytes()
    return outputs


def write_outputs(outputs: dict[Path, bytes]) -> None:
    for root in (LIB_OUT, OUT):
        if root.exists():
            shutil.rmtree(root)
    for path, data in sorted(outputs.items(), key=lambda item: str(item[0])):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)


def validate_outputs(outputs: dict[Path, bytes], manifest: dict) -> None:
    actual = {path for root in (LIB_OUT, OUT) for path in root.rglob("*") if path.is_file()}
    if actual != set(outputs):
        fail(f"generated file set drift: expected {sorted(map(str, outputs))}, actual {sorted(map(str, actual))}")
    for path, expected in outputs.items():
        if path.read_bytes() != expected:
            fail(f"generated output drift: {path.relative_to(ROOT)}")
    catalog = (OUT / "src" / "GeneratedCatalog.as").read_text()
    positions = [catalog.index(as_string(recipe["id"])) for recipe in manifest["recipes"]]
    if positions != sorted(positions):
        fail("generated navigation order differs from manifest order")
    if catalog.count("RecipeMeta(") != len(manifest["recipes"]) + 1:  # constructor + records
        fail("not every manifest recipe generated exactly once")


def validate_live_install_identity(manifest: dict) -> None:
    plugins_dir = Path.home() / "OpenplanetNext" / "Plugins"
    if not plugins_dir.is_dir():
        return
    gallery_name = manifest["gallery"]["name"]
    owners = []
    for info in plugins_dir.glob("*/info.toml"):
        text = info.read_text(errors="replace")
        if f'name = "{gallery_name}"' in text:
            owners.append(info.parent.name)
    if len(owners) > 1:
        fail(
            f"duplicate live gallery installations own {gallery_name!r}: {owners}; "
            "unload/remove stale plugin folders so one authoritative gallery remains"
        )


def validate_exclusions() -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() in BINARY_SUFFIXES:
            fail(f"binary/asset excluded from prototype: {path.relative_to(ROOT)}")
        if "generated" in path.parts:
            continue
        if path.suffix.lower() not in {".md", ".json", ".as", ".py"}:
            continue
        lowered = path.read_text(errors="replace").lower()
        for forbidden in FORBIDDEN_TEXT:
            if forbidden.lower() in lowered and path.name not in {"README.md", "VALIDATION-CONTRACT.md", "QUESTIONS-RESOLVED.md", "prototype.py"}:
                fail(f"forbidden source/policy phrase in {path.relative_to(ROOT)}: {forbidden}")


def tree_digest() -> str:
    digest = hashlib.sha256()
    for root in (LIB_OUT, OUT):
        for path in sorted(p for p in root.rglob("*") if p.is_file()):
            digest.update(root.name.encode() + b"/" + str(path.relative_to(root)).encode() + b"\0" + path.read_bytes() + b"\0")
    return digest.hexdigest()


def run_lsp() -> str:
    executable = shutil.which("openplanet-lsp")
    if executable is None:
        return "SKIP (openplanet-lsp unavailable; live compile still mandatory)"
    summaries = []
    for root in (LIB_OUT, OUT):
        command = [executable, "check"]
        if root == OUT:
            command.extend(["--plugins-dir", str(LIB_OUT.parent)])
        command.append(str(root))
        result = subprocess.run(command, text=True, capture_output=True)
        combined = (result.stdout + result.stderr).strip()
        if result.returncode != 0:
            print(combined, file=sys.stderr)
            fail(f"openplanet-lsp check failed for {root.name} with exit {result.returncode}")
        diagnostic_match = re.search(r"(\d+)\s+diagnostic", combined, re.IGNORECASE)
        if diagnostic_match and int(diagnostic_match.group(1)) != 0:
            fail(f"openplanet-lsp reported diagnostics for {root.name}: {combined}")
        summaries.append(f"{root.name}: {combined or 'PASS (exit 0)'}")
    return "; ".join(summaries)


def main() -> int:
    try:
        manifest = load_json(MANIFEST_PATH)
        matrix = load_json(MATRIX_PATH)
        validate_model(manifest, matrix)
        validate_exclusions()
        outputs = expected_outputs(manifest)
        write_outputs(outputs)
        validate_outputs(outputs, manifest)
        validate_live_install_identity(manifest)
        first_digest = tree_digest()
        write_outputs(outputs)
        validate_outputs(outputs, manifest)
        second_digest = tree_digest()
        if first_digest != second_digest:
            fail("second assembly changed generated tree digest")
        lsp_result = run_lsp()
    except (AssertionError, json.JSONDecodeError, jsonschema.ValidationError, jsonschema.SchemaError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    print("PASS schema: manifest validates against recipe.schema.json")
    print(f"PASS model: {len(manifest['recipes'])} unique canonical recipes across {len(TIERS)} tiers")
    print(f"PASS matrix: {len(matrix['required_cases'])} required deterministic screenshot cases cover all recipe frames")
    print("PASS contracts: provenance, theme default, instrumentation, exclusions, and navigation")
    print(f"PASS deterministic assembly: {len(outputs)} files; tree sha256={second_digest}")
    print(f"PASS openplanet-lsp: {lsp_result}")
    print("LIVE-PENDING: no runtime load, behavior smoke, or screenshots were performed; maturity remains candidate-static-only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
