#if DEV
namespace SemanticControl {
    funcdef void SemanticAction();

    class Registration {
        string Id;
        uint Generation;
        uint LastDrawnEpoch = 0;
        dictionary Actions;

        Registration(const string &in id, uint generation) {
            Id = id;
            Generation = generation;
        }
    }

    dictionary g_Registrations;
    uint g_RenderEpoch = 0;
    uint g_SealedRenderEpoch = 0;

    uint BeginRenderEpoch() { return ++g_RenderEpoch; }

    void MarkDrawn(const string &in id) {
        Registration@ registration;
        if (g_Registrations.Get(id, @registration)) registration.LastDrawnEpoch = g_RenderEpoch;
    }

    void SealRenderEpoch() { g_SealedRenderEpoch = g_RenderEpoch; }

    bool Register(const string &in id, uint generation, const string &in action, SemanticAction@ callback) {
        if (id.Length == 0 || action.Length == 0 || callback is null || g_Registrations.Exists(id)) return false;
        auto registration = Registration(id, generation);
        registration.Actions.Set(action, @callback);
        g_Registrations.Set(id, @registration);
        return true;
    }

    void UnregisterGeneration(uint generation) {
        auto keys = g_Registrations.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            Registration@ registration;
            if (g_Registrations.Get(keys[i], @registration) && registration.Generation == generation)
                g_Registrations.Delete(keys[i]);
        }
    }

    string Invoke(const string &in id, uint generation, const string &in action, bool force) {
        Registration@ registration;
        if (!g_Registrations.Get(id, @registration)) return "unknown_component";
        if (registration.Generation != generation) return "stale_registration";
        SemanticAction@ callback;
        if (!registration.Actions.Get(action, @callback)) return "unknown_action";
        if (!force && (g_SealedRenderEpoch == 0 || registration.LastDrawnEpoch != g_SealedRenderEpoch)) return "not_drawn";
        callback();
        return force ? "forced" : "performed";
    }
}
#endif
