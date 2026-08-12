namespace SkillpackDemoLib {
    import float ClampUnit(float value) from "SkillpackDemoLib";
    import float PhaseFromFrame(int frame, int maxFrame) from "SkillpackDemoLib";
    import void RegisterMenuItem(const string &in id, const string &in label, MenuIsOpen@ isOpen, MenuToggle@ toggle) from "SkillpackDemoLib";
    import void UnregisterMenuItem(const string &in id) from "SkillpackDemoLib";
}
