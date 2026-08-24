# Player score on a map

Two official score-manager calls cover “what is this account’s time on that
UID.” Both need a yieldable context and a live
`MenuCustom_CurrentManiaApp`.

## Local player, one UID

```angelscript
uint PbMsOnMap(const string &in mapUid) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto mccma = app.MenuManager.MenuCustom_CurrentManiaApp;
    auto userId = mccma.UserMgr.Users[0].Id;
    return mccma.ScoreMgr.Map_GetRecord_v2(
        userId, mapUid, "PersonalBest", "", "TimeAttack", "");
}
```

`0` / sentinel means no record. This is the local user’s PB for that map
in Time Attack.

## Named account(s)

```angelscript
int RecordMsOnMap(const string &in mapUid, const string &in wsid) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto mccma = app.MenuManager.MenuCustom_CurrentManiaApp;
    auto userId = mccma.UserMgr.Users[0].Id;
    MwFastBuffer<wstring> ids;
    ids.Add(wsid);
    auto task = mccma.ScoreMgr.Map_GetPlayerListRecordList(
        userId, ids, mapUid, "PersonalBest", "", "TimeAttack", "");
    WaitAndClearTaskLater(task, mccma.ScoreMgr);
    if (task.HasFailed || !task.HasSucceeded) return -1;
    if (task.MapRecordList.Length == 0) return -1;
    return int(task.MapRecordList[0].Time); // copy now; do not keep the nod
}
```

`WaitAndClearTaskLater` is in [nadeo-tasks.md](nadeo-tasks.md). `wsid` is the
webservices account id (`NadeoServices::GetAccountID()` for the local user,
or `NadeoServices::LoginToAccountId`).

Live race scores (round points, team, current CP time) are
`MLFeed::GetRaceData_V4()` — see
[common-dependencies](../references/common-dependencies.md) — not `ScoreMgr`.

## Sources

- `Map_GetRecord_v2` / `Map_GetPlayerListRecordList` — [tm-better-totd](https://github.com/XertroV/tm-better-totd) `src/API/Core.as`
- Live scores — [tm-mlfeed-race-data](https://github.com/XertroV/tm-mlfeed-race-data)
