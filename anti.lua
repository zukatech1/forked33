-- ╔══════════════════════════════════════════════════════╗
-- ║           ZexAddon v2.0 | Standalone Build           ║
-- ║      Main + Stealth merged, performance-optimized    ║
-- ╚══════════════════════════════════════════════════════╝

if getgenv().ZexAddon_Loaded then return end
getgenv().ZexAddon_Loaded = true

-- ─── Compatibility Layer ──────────────────────────────────────────────────────
local new_cc        = newcclosure        or function(f) return f end
local check_caller  = checkcaller        or function() return false end
local get_mt        = getrawmetatable
local set_ro        = setreadonly        or function() end
local hook_fn       = hookfunction       or function() end
local gc            = getgc              or get_gc_objects or function() return {} end
local get_ident     = getscriptidentity  or getidentity   or get_thread_identity or nil
local set_ident     = setscriptidentity  or setidentity   or set_thread_identity or nil

-- ─── Wait for Game ────────────────────────────────────────────────────────────
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
repeat task.wait(0.1) until Players and Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ─── State ────────────────────────────────────────────────────────────────────
local isUnloaded       = false
local cachedACTable    = nil
local HookedFunctions  = {}

local Stats = {
    KickAttempts        = 0,
    RemotesBlocked      = 0,
    DetectionsCaught    = 0,
    FunctionsHooked     = 0,
    ClientChecksBlocked = 0,
    RemotesFired        = 0,
}

-- ─── Pre-computed Lookup Tables ───────────────────────────────────────────────
-- Built once at load, never modified except via public API.
-- All string keys pre-lowercased so no :lower() at runtime in hot paths.

local INDEX_BLOCK = {
    exploitname          = true,
    ["_exploiting"]      = true,
    syn                  = true,
    fluxus               = true,
    krnl                 = true,
    solara               = true,
    hydrogen             = true,
    scriptidentity       = true,
    ["__namecallmethod"] = true,
}

local NEWINDEX_BLOCK = {
    ZexAddon        = true,
    ["_exploitflag"]= true,
}

-- Only methods we actually care about in __namecall.
-- Everything else fast-exits before getnamecallmethod() is even called.
-- IMPORTANT: never add Connect/ConnectParallel/Once here — the Animate script
-- and other core LocalScripts pass non-function values in edge cases and rely
-- on the real error propagating. Intercepting them causes "not a function" spam.
local NAMECALL_WATCH = {
    Kick                   = true,
    FireServer             = true,
    InvokeServer           = true,
    GetChildren            = true,
    GetDescendants         = true,
    FindFirstChild         = true,
    FindFirstChildOfClass  = true,
    FindFirstChildWhichIsA = true,
}

-- Methods that must ALWAYS bypass the hook entirely — touching these breaks
-- core Roblox scripts (Animate, default character scripts, etc.)
local NAMECALL_PASSTHROUGH = {
    Connect         = true,
    ConnectParallel = true,
    Once            = true,
    Wait            = true,
    Disconnect      = true,
}

-- Exact remote name blocklist — O(1) rawget in hook.
-- Pattern-matched remotes are promoted here by the DescendantAdded scanner.
local REMOTE_EXACT = {
    ClientCheck      = true,
    ProcessCommand   = true,
    ClientLoaded     = true,
    ActivateCommand  = true,
    Disconnect       = true,
    __FUNCTION       = true,
    _FUNCTION        = true,
}

local REMOTE_PATTERNS = {
    "anticheat", "anti_cheat", "kickplayer", "banplayer",
    "reportexploit", "detectclient", "cheatcheck",
}

-- AC detection keywords for kick messages (checked only on Kick calls — rare)
local KICK_KEYWORDS = {
    "adonis", "anti", "cheat", "exploit", "acli", "detected", "ban",
}

-- Injected object names hidden from GetChildren/FindFirstChild scans
local HIDDEN = {
    ZexAddonGui = true,
    ZexOverlay  = true,
}

-- AC table field signatures with weights
local AC_SIGNATURES = {
    { "Detected",           true,  1   },
    { "RemovePlayer",       true,  1   },
    { "CheckAllClients",    true,  1   },
    { "KickedPlayers",      false, 1   },
    { "SpoofCheckCache",    false, 1   },
    { "ClientTimeoutLimit", false, 1   },
    { "CharacterCheck",     true,  0.5 },
    { "UserSpoofCheck",     true,  0.5 },
    { "AntiCheatEnabled",   false, 1   },
    { "GetPlayer",          true,  0.5 },
}
local AC_SCORE_THRESHOLD = 3

local SAFE_IDENTITY = 2  -- identity level a normal LocalScript runs at

-- ─── Safety Helpers ───────────────────────────────────────────────────────────
local function silent(fn, ...)
    local ok, r = pcall(fn, ...)
    if ok then return r end
end

-- Unlock → patch → relock atomically. Restores read-only even on failure.
local function atomicPatch(obj, fn)
    local mt = get_mt(obj)
    if not mt then return false end
    local ok = pcall(function()
        set_ro(mt, false)
        fn(mt)
        set_ro(mt, true)
    end)
    if not ok then pcall(set_ro, mt, true) end
    return ok
end

local function safeHook(original, replacement)
    if type(original) ~= "function" then return false end
    local ok = pcall(hook_fn, original, new_cc(replacement))
    if not ok then return false end
    table.insert(HookedFunctions, original)
    Stats.FunctionsHooked += 1
    return true
end

local function isHooked(fn)
    for _, h in ipairs(HookedFunctions) do
        if fn == h then return true end
    end
    return false
end

local function dismantle_readonly(target)
    if type(target) ~= "table" then return end
    pcall(function()
        set_ro(target, false)
        local mt = get_mt(target)
        if mt then pcall(set_ro, mt, false) end
    end)
end

-- ─── Environment Preparation ──────────────────────────────────────────────────
for _, fn in ipairs({ getgenv, getrenv, getreg }) do
    if type(fn) == "function" then
        local ok, env = pcall(fn)
        if ok and type(env) == "table" then dismantle_readonly(env) end
    end
end

-- ─── AC Table Detection & Patching ───────────────────────────────────────────
local function scoreTable(v)
    if type(v) ~= "table" then return 0 end
    local score = 0
    pcall(function()
        for _, sig in ipairs(AC_SIGNATURES) do
            local name, isFunc, weight = sig[1], sig[2], sig[3]
            local val = rawget(v, name)
            if val ~= nil then
                if isFunc then
                    if type(val) == "function" then score += weight end
                else
                    score += weight
                end
            end
        end
    end)
    return score
end

local function findACTable()
    local objs
    local ok = pcall(function() objs = gc(true) end)
    if not ok or not objs then return nil end
    for _, v in ipairs(objs) do
        local ok2, isT = pcall(function() return type(v) == "table" end)
        if ok2 and isT and scoreTable(v) >= AC_SCORE_THRESHOLD then
            return v
        end
    end
    return nil
end

local function hookACTable(tbl)
    if not tbl then return end

    if type(tbl.Detected) == "function" then
        safeHook(tbl.Detected, function(...)
            Stats.DetectionsCaught += 1
        end)
    end

    if type(tbl.RemovePlayer) == "function" then
        safeHook(tbl.RemovePlayer, function(...)
            Stats.KickAttempts += 1
        end)
    end

    if type(tbl.CheckAllClients) == "function" then
        safeHook(tbl.CheckAllClients, function(...)
            Stats.ClientChecksBlocked += 1
        end)
    end

    if type(tbl.UserSpoofCheck) == "function" then
        safeHook(tbl.UserSpoofCheck, function(...) return nil end)
    end

    if type(tbl.CharacterCheck) == "function" then
        safeHook(tbl.CharacterCheck, function(...) end)
    end

    if type(tbl.KickedPlayers) == "table" then
        local mt = getmetatable(tbl.KickedPlayers) or {}
        rawset(mt, "__index",   function() return false end)
        rawset(mt, "__newindex",function() end)
        rawset(mt, "__len",     function() return 0 end)
        pcall(setmetatable, tbl.KickedPlayers, mt)
    end

    if type(tbl.SpoofCheckCache) == "table" then
        local mt = {}
        rawset(mt, "__index", function(t, k)
            return {{ Id = k, Username = LocalPlayer.Name,
                      DisplayName = LocalPlayer.DisplayName,
                      UserId = LocalPlayer.UserId }}
        end)
        rawset(mt, "__newindex", function() end)
        pcall(setmetatable, tbl.SpoofCheckCache, mt)
    end

    if tbl.ClientTimeoutLimit ~= nil then
        pcall(function() tbl.ClientTimeoutLimit = math.huge end)
    end
    if tbl.AntiCheatEnabled ~= nil then
        pcall(function() tbl.AntiCheatEnabled = false end)
    end
end

-- ─── Remote Client Heartbeat ──────────────────────────────────────────────────
local function findAndPatchRemoteClients()
    local userId = tostring(LocalPlayer.UserId)
    local objs
    local ok = pcall(function() objs = gc(true) end)
    if not ok or not objs then return end

    for _, v in ipairs(objs) do
        local ok2, isT = pcall(function() return type(v) == "table" end)
        if not (ok2 and isT) then continue end

        local ok3, client, hasMaxLen = pcall(function()
            return rawget(v, userId), rawget(v, "MaxLen")
        end)
        if not (ok3 and type(client) == "table") then continue end

        local ok4, hasLastUpdate = pcall(function()
            return rawget(client, "LastUpdate") ~= nil
        end)
        if ok4 and hasLastUpdate and hasMaxLen ~= nil then
            task.spawn(function()
                while not isUnloaded do
                    task.wait(8)
                    pcall(function()
                        local c = v[userId]
                        if c then
                            c.LastUpdate   = os.time()
                            c.PlayerLoaded = true
                        end
                    end)
                end
            end)
        end
    end
end

-- ─── Optimized __namecall Hook ────────────────────────────────────────────────
-- getnamecallmethod() only called when NAMECALL_WATCH hits.
-- ~95% of namecalls (physics, render, input) skip all logic entirely.
local function installNamecall()
    local gcnm = getnamecallmethod

    atomicPatch(game, function(mt)
        local prev = mt.__namecall

        mt.__namecall = new_cc(function(self, ...)
            if check_caller() then return prev(self, ...) end

            local m = gcnm()

            -- Hard passthrough: these must NEVER be intercepted.
            -- Signal methods (Connect, Once, Wait) are called by core Roblox
            -- scripts like Animate with values we must not touch.
            if rawget(NAMECALL_PASSTHROUGH, m) then
                return prev(self, ...)
            end

            if not rawget(NAMECALL_WATCH, m) then
                return prev(self, ...)
            end

            -- Kick ────────────────────────────────────────────────────────────
            if m == "Kick" and self == LocalPlayer then
                local msg = tostring((...) or ""):lower()
                for i = 1, #KICK_KEYWORDS do
                    if msg:find(KICK_KEYWORDS[i], 1, true) then
                        Stats.KickAttempts += 1
                        return nil
                    end
                end
            end

            -- FireServer / InvokeServer ────────────────────────────────────────
            if m == "FireServer" or m == "InvokeServer" then
                local name
                local ok = pcall(function() name = self.Name end)
                if ok and rawget(REMOTE_EXACT, name) then
                    Stats.RemotesBlocked += 1
                    if m == "InvokeServer" then return "Pong" end
                    return nil
                end
                Stats.RemotesFired += 1
            end

            -- GetChildren / GetDescendants ─────────────────────────────────────
            if m == "GetChildren" or m == "GetDescendants" then
                local result = prev(self, ...)
                if type(result) ~= "table" then return result end
                local hasHidden = false
                for i = 1, #result do
                    local ok, n = pcall(function() return result[i].Name end)
                    if ok and rawget(HIDDEN, n) then hasHidden = true; break end
                end
                if not hasHidden then return result end
                local out, j = {}, 0
                for i = 1, #result do
                    local ok, n = pcall(function() return result[i].Name end)
                    if not (ok and rawget(HIDDEN, n)) then
                        j = j + 1; out[j] = result[i]
                    end
                end
                return out
            end

            -- FindFirstChild family ────────────────────────────────────────────
            if m == "FindFirstChild" or m == "FindFirstChildOfClass"
               or m == "FindFirstChildWhichIsA" then
                if rawget(HIDDEN, tostring((...) or "")) then return nil end
            end

            return prev(self, ...)
        end)
    end)
end

-- ─── Optimized __index / __newindex ──────────────────────────────────────────
-- No :lower() at runtime — keys pre-lowercased in INDEX_BLOCK.
-- pcall only wraps the actual engine call, not the guard logic.
local function installIndexHooks()
    atomicPatch(game, function(mt)
        local prevIndex    = mt.__index
        local prevNewIndex = mt.__newindex

        mt.__index = new_cc(function(self, key, ...)
            if check_caller() then return prevIndex(self, key, ...) end
            if type(key) == "string" and rawget(INDEX_BLOCK, key) then
                return nil
            end
            -- Do NOT swallow errors here — returning nil on failure corrupts
            -- reads that legitimate scripts depend on (e.g. Animate, CharacterScripts).
            -- Let the error propagate naturally so the caller can handle it.
            return prevIndex(self, key, ...)
        end)

        mt.__newindex = new_cc(function(self, key, value, ...)
            if check_caller() then
                if prevNewIndex then return prevNewIndex(self, key, value, ...) end
                return rawset(self, key, value)
            end
            if rawget(NEWINDEX_BLOCK, key) then return end
            if prevNewIndex then
                pcall(prevNewIndex, self, key, value, ...)
            else
                pcall(rawset, self, key, value)
            end
        end)
    end)

    -- Workspace mt dedup: only patch if it's a separate metatable
    local ws = silent(function() return game:GetService("Workspace") end)
    if ws and get_mt(ws) ~= get_mt(game) then
        atomicPatch(ws, function(mt)
            local prevIndex = mt.__index
            mt.__index = new_cc(function(self, key, ...)
                if check_caller() then return prevIndex(self, key, ...) end
                if type(key) == "string" and rawget(INDEX_BLOCK, key) then return nil end
                return prevIndex(self, key, ...)
            end)
        end)
    end
end

-- ─── Script Identity Spoofing ─────────────────────────────────────────────────
local function installIdentityHooks()
    if not get_ident then return end

    pcall(hook_fn, get_ident, new_cc(function(...)
        if check_caller() then return get_ident(...) end
        return SAFE_IDENTITY
    end))

    if set_ident then
        pcall(hook_fn, set_ident, new_cc(function(level, ...)
            if check_caller() then return set_ident(level, ...) end
        end))
    end

    for _, name in ipairs({ "getidentity", "get_thread_identity", "getscriptidentity" }) do
        local fn = rawget(getgenv(), name) or rawget(getrenv(), name)
        if fn and fn ~= get_ident and type(fn) == "function" then
            pcall(hook_fn, fn, new_cc(function(...)
                if check_caller() then return fn(...) end
                return SAFE_IDENTITY
            end))
        end
    end
end

-- ─── Debug Hook Hardening ─────────────────────────────────────────────────────
local function installDebugHooks()
    local function wrapDebugFn(fn, fallback)
        if type(fn) ~= "function" then return end
        pcall(hook_fn, fn, new_cc(function(target, ...)
            if isHooked(target) then return fallback end
            return fn(target, ...)
        end))
    end
    wrapDebugFn(debug.info or debug.getinfo, nil)
    wrapDebugFn(debug.getupvalues,  {})
    wrapDebugFn(debug.getlocals,    {})
    wrapDebugFn(debug.getconstants, {})
end

-- ─── Kick Guard ───────────────────────────────────────────────────────────────
local function protectKick()
    local origKick = LocalPlayer.Kick
    safeHook(origKick, function(self, reason, ...)
        if check_caller() then return origKick(self, reason, ...) end
        if self == LocalPlayer then
            local msg = tostring(reason or ""):lower()
            for _, kw in ipairs(KICK_KEYWORDS) do
                if msg:find(kw, 1, true) then
                    Stats.KickAttempts += 1
                    return nil
                end
            end
        end
        return origKick(self, reason, ...)
    end)
end

-- ─── Require Hook ────────────────────────────────────────────────────────────
local oldRequire
oldRequire = hook_fn(getrenv().require, new_cc(function(module)
    if check_caller() then return oldRequire(module) end
    if typeof(module) == "Instance" then
        local name = module.Name:lower()
        if name:find("topbar", 1, true) or name:find("icon", 1, true)
        or name:find("adonis", 1, true) then
            return setmetatable({}, {
                __index    = function() return function() end end,
                __newindex = function() end,
                __call     = function() return {} end,
            })
        end
    end
    return oldRequire(module)
end))

-- ─── Deferred Remote Scanner ─────────────────────────────────────────────────
-- Pattern matching done outside the namecall hook via DescendantAdded.
-- Matches are promoted to REMOTE_EXACT for O(1) lookup inside the hook.
local function startRemoteScanner()
    local function checkRemote(obj)
        if typeof(obj) ~= "RemoteEvent" and typeof(obj) ~= "RemoteFunction" then return end
        local ok, name = pcall(function() return obj.Name end)
        if not ok then return end
        local lower = name:lower()
        for _, pat in ipairs(REMOTE_PATTERNS) do
            if lower:find(pat, 1, true) then
                rawset(REMOTE_EXACT, name, true)
                break
            end
        end
    end

    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do checkRemote(obj) end
    end)
    pcall(function()
        game.DescendantAdded:Connect(function(obj)
            task.defer(checkRemote, obj)
        end)
    end)
end

-- ─── Rescan Loop ─────────────────────────────────────────────────────────────
local function rescan()
    local tbl = findACTable()
    if tbl and tbl ~= cachedACTable then
        cachedACTable = tbl
        hookACTable(tbl)
        warn("[ZexAddon] New AC table found during rescan.")
    end
    findAndPatchRemoteClients()
end

-- ─── Initialize ──────────────────────────────────────────────────────────────
local function initialize()
    -- Order matters: namecall + index before anything that might trigger them
    installNamecall()
    installIndexHooks()
    installIdentityHooks()
    installDebugHooks()
    protectKick()
    startRemoteScanner()

    cachedACTable = findACTable()
    if cachedACTable then
        hookACTable(cachedACTable)
        warn("[ZexAddon] v2.0 loaded — AC table hooked.")
    else
        warn("[ZexAddon] v2.0 loaded — no AC table yet, will rescan.")
    end

    findAndPatchRemoteClients()

    -- Rescan loop — picks up AC tables that load after us
    task.spawn(function()
        while not isUnloaded do
            task.wait(15)
            rescan()
        end
    end)

    -- Heartbeat stats log
    task.spawn(function()
        while not isUnloaded do
            task.wait(60)
            warn(string.format(
                "[ZexAddon] Kicks: %d | Remotes blocked: %d | Detections: %d | Checks: %d | Hooks: %d | Fired: %d",
                Stats.KickAttempts, Stats.RemotesBlocked, Stats.DetectionsCaught,
                Stats.ClientChecksBlocked, Stats.FunctionsHooked, Stats.RemotesFired
            ))
        end
    end)
end

-- ─── Public API ──────────────────────────────────────────────────────────────
getgenv().ZexAddon = {
    Version = "2.0",

    GetStats = function()
        return {
            KickAttempts        = Stats.KickAttempts,
            RemotesBlocked      = Stats.RemotesBlocked,
            DetectionsCaught    = Stats.DetectionsCaught,
            ClientChecksBlocked = Stats.ClientChecksBlocked,
            FunctionsHooked     = Stats.FunctionsHooked,
            RemotesFired        = Stats.RemotesFired,
        }
    end,

    PrintStats = function()
        for k, v in pairs(Stats) do
            print(string.format("  %s: %d", k, v))
        end
    end,

    Rescan = function()
        rescan()
        warn("[ZexAddon] Manual rescan complete.")
    end,

    Unload = function()
        isUnloaded = true
        getgenv().ZexAddon_Loaded = nil
        warn("[ZexAddon] Unloaded.")
    end,

    -- Runtime table manipulation
    BlockRemote = function(name)
        rawset(REMOTE_EXACT, name, true)
        warn("[ZexAddon] Blocking remote: " .. tostring(name))
    end,
    UnblockRemote = function(name)
        rawset(REMOTE_EXACT, name, nil)
    end,
    HideObject = function(name)
        rawset(HIDDEN, name, true)
    end,
    SpoofIndex = function(key, value)
        rawset(INDEX_BLOCK, key:lower(), value or true)
    end,
}

initialize()
print("[ZexAddon] v2.0 standalone ready.")
