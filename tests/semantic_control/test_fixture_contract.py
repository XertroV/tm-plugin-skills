from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
PLUGIN = ROOT / "prototypes" / "semantic-control-reference" / "SemanticControlFixture"


class FixtureContractTests(unittest.TestCase):
    def test_every_feature_has_neighboring_test(self):
        sources = [path for path in (PLUGIN / "src").glob("*.as") if not path.stem.endswith("_Test")]
        self.assertTrue(sources)
        for source in sources:
            self.assertTrue(source.with_name(source.stem + "_Test.as").is_file(), source.name)

    def test_fixture_is_dev_only_disabled_and_loopback_only(self):
        info = (PLUGIN / "info.toml").read_text()
        main = (PLUGIN / "src" / "Main.as").read_text()
        self.assertIn("defines = [\"DEV\"]", info)
        self.assertIn("#if DEV", main)
        self.assertIn("bool S_Enabled = false", main)
        self.assertIn('"127.0.0.1"', main)
        self.assertNotIn("Listen(S_Port)", main)

    def test_router_has_only_fixed_semantic_routes(self):
        router = (PLUGIN / "src" / "ControlRouter.as").read_text()
        self.assertIn('route == "ping"', router)
        self.assertIn('route == "component.state"', router)
        self.assertIn('route == "component.action"', router)
        for forbidden in ("eval", "ExecuteString", "startnew(request", "IO::", "File"):
            self.assertNotIn(forbidden, router)

    def test_registry_encodes_render_epoch_and_generation_rules(self):
        registry = (PLUGIN / "src" / "ComponentRegistry.as").read_text()
        for phrase in ("BeginRenderEpoch", "MarkDrawn", "SealRenderEpoch", "LastDrawnEpoch", "Generation", "not_drawn", "stale_registration", "force"):
            self.assertIn(phrase, registry)

    def test_transport_contract_documents_unfrozen_byte_order(self):
        transport = (PLUGIN / "TRANSPORT.md").read_text()
        self.assertIn("MUST live-probe", transport)
        self.assertIn("big-endian", transport)
        self.assertIn("64 KiB", transport)
        self.assertIn("one request/reply per connection", transport)


if __name__ == "__main__":
    unittest.main()
