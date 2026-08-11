#if DEV
namespace SemanticControl {
    class RouteResult {
        bool Ok;
        string Code;
        bool Performed;
        bool Forced;

        RouteResult(bool ok, const string &in code = "") { Ok = ok; Code = code; }
    }

    RouteResult@ Route(const string &in route, const string &in component = "", const string &in action = "", uint generation = 0, bool force = false) {
        if (route == "ping") return RouteResult(true);
        if (route == "component.state") {
            Registration@ registration;
            return RouteResult(g_Registrations.Get(component, @registration), registration is null ? "unknown_component" : "");
        }
        if (route == "component.action") {
            string outcome = Invoke(component, generation, action, force);
            auto result = RouteResult(outcome == "performed" || outcome == "forced", outcome);
            result.Performed = outcome == "performed";
            result.Forced = outcome == "forced";
            return result;
        }
        return RouteResult(false, "unknown_route");
    }
}
#endif
