#if DEV
namespace SemanticControlFixture {
    uint ClickCount = 0;
    uint Generation = 1;

    void ClickSave() { ClickCount++; }

    void RegisterComponents() {
        SemanticControl::Register("save", Generation, "click", SemanticControl::SemanticAction(ClickSave));
    }

    void RenderSaveButton() {
        if (UI::Button("Save###semantic-control-save")) ClickSave();
        SemanticControl::MarkDrawn("save");
    }

    void TeardownComponents() { SemanticControl::UnregisterGeneration(Generation); }
}
#endif
