#if DEV
namespace Tests {
    [Test]
    void SemanticButton_CallbackChangesObservableComponentState(Tests::Context@ ctx) {
        uint before = SemanticControlFixture::ClickCount;
        SemanticControlFixture::ClickSave();
        ctx.AssertSame(SemanticControlFixture::ClickCount, before + 1, "semantic click increments visible state once");
    }
}
#endif
