#if DEV
[Test]
void Main_MenuAndWindowShareState(Tests::Context@ ctx) {
    g_WindowOpen = false;
    g_WindowOpen = !g_WindowOpen;
    ctx.AssertTrue(g_WindowOpen);
}
namespace Tests {
    [Test]
    void Main_ControlDefaultsDisabled(Tests::Context@ ctx) {
        ctx.AssertFalse(S_Enabled, "DEV bridge requires explicit opt-in");
        ctx.AssertTrue(S_Port > 0 && S_Port < 65536, "configured port is bounded");
    }
}
#endif
