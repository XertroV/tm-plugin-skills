# Nadeo tasks

Script APIs that talk to Nadeo (`DataFileMgr`, `ScoreMgr`, `UserMgr`, …)
return a `CWebServicesTaskResult@`. Wait until it is done, read the payload
**before the next yield**, then release the task on its owner.

## Wait, read, release later

```angelscript
class ClearTask {
    CWebServicesTaskResult@ task;
    CMwNod@ nod;

    ClearTask(CWebServicesTaskResult@ task, CMwNod@ owner) {
        @this.task = task;
        @nod = owner;
    }

    void Release() {
        auto userMgr = cast<CGameUserManagerScript>(nod);
        auto dfm = cast<CGameDataFileManagerScript>(nod);
        auto scoreMgr = cast<CGameScoreAndLeaderBoardManagerScript>(nod);
        if (userMgr !is null) userMgr.TaskResult_Release(task.Id);
        else if (dfm !is null) dfm.TaskResult_Release(task.Id);
        else if (scoreMgr !is null) scoreMgr.TaskResult_Release(task.Id);
        else throw("unknown task owner: " + Reflection::TypeOf(nod).Name);
    }
}

ClearTask@[] tasksToClear;

void WaitAndClearTaskLater(CWebServicesTaskResult@ task, CMwNod@ owner) {
    while (task.IsProcessing) yield();
    tasksToClear.InsertLast(ClearTask(task, owner));
}

void ClearTaskCoro() {
    while (true) {
        yield(5);
        if (tasksToClear.Length == 0) continue;
        uint toClear = tasksToClear.Length;
        yield(7);
        for (uint i = 0; i < toClear; i++) tasksToClear[i].Release();
        tasksToClear.RemoveRange(0, toClear);
    }
}
```

Start `ClearTaskCoro` from `Main`. The extra yields give you a few frames
to finish reading.

## Use

```angelscript
auto mccma = cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp;
auto userId = mccma.UserMgr.Users[0].Id;
auto task = mccma.DataFileMgr.Map_NadeoServices_GetFromUid(userId, uid);
WaitAndClearTaskLater(task, mccma.DataFileMgr);
if (task.HasFailed || !task.HasSucceeded) {
    warn(task.ErrorCode + " " + task.ErrorDescription);
    return;
}
string url = task.Map.FileUrl; // copy fields now
```

Do not keep the result nod (`task.Map`, `task.Ghost`, `MapRecordList[i]`)
across a later yield. Copy what you need immediately after
`WaitAndClearTaskLater` returns.

Release via the **same** manager that created the task. A leftover unreleased
task is a leak; releasing the wrong owner or twice is a crash.

## Sources

- `WaitAndClearTaskLater` / `TaskResult_Release` — [tm-play-map](https://github.com/XertroV/tm-play-map) `src/ClearTasks.as` (same pattern in bosslike, BRM, better-totd)
