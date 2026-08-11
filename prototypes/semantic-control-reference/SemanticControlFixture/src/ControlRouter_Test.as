#if DEV
namespace Tests {
    [Test]
    void ControlRouter_OnlyKnownRoutesResolve(Tests::Context@ ctx) {
        ctx.AssertTrue(SemanticControl::Route("ping").Ok, "ping is fixed and known");
        auto unknown = SemanticControl::Route("eval");
        ctx.AssertFalse(unknown.Ok, "arbitrary route is rejected");
        ctx.AssertSame(unknown.Code, "unknown_route", "rejection is concise");
    }

    [Test]
    void ControlRouter_UnknownComponentIsTruthful(Tests::Context@ ctx) {
        auto result = SemanticControl::Route("component.action", "absent", "click", 1, false);
        ctx.AssertFalse(result.Ok, "unknown component fails");
        ctx.AssertSame(result.Code, "unknown_component", "error identifies immediate cause");
        ctx.AssertFalse(result.Performed, "failure never claims mutation");
        ctx.AssertFalse(result.Forced, "failure never claims force");
    }
}
#endif
