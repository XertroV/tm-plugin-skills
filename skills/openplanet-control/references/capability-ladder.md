# Capability ladder

| Rung | Use | Do not assume |
| --- | --- | --- |
| Manual UI/log | Universal load/reload/unload and behavior fallback | Automation or machine-readable status |
| Minimal lifecycle bridge | Provider/library reload and restoration of previously loaded reverse dependents | General game control or arbitrary logs/actions |
| RemoteBuild | Simple leaf staging/reload and external log-tail support | Dependent restoration or socket-response compile truth |
| Project control | Semantic actions, state assertions, screenshots | Durable ownership of its own dependency lifecycle |

Lifecycle bridge snapshots only the currently loaded transitive reverse-dependent closure before mutation. A failed target load retains the old snapshot; retry must not overwrite it with the now-empty live closure. Restore only after fresh target health evidence, in dependency order. Never enable unrelated, disabled, or unloaded possible dependents.

Fallbacks: bridge failure → RemoteBuild only when closure is empty/safe, otherwise manual; RemoteBuild stuck → bounded retry/reload of RemoteBuild via a lower lifecycle rung, then manual; control disappearance after provider reload → restore/reload dependents, then reprobe; no readable log → lifecycle evidence is incomplete. Report concrete Scripts/Plugins UI steps and log path when manual action is needed.
