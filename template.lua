--[[
    Private Loader
    Handshake-gated payload executor with Discord logging.
]]

local SETTINGS = {
    PAYLOAD_URL       = "", -- your private repo raw URL
    WEBHOOK_URL       = "", -- your discord webhook URL
    RETRIES           = 3,
    DELAY             = 1.5,
    ENVIRONMENT_CHECK = true,
    MIN_ENV_LEVEL     = 5
}

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer       = Players.LocalPlayer

local function DetectEnvironment()
    local env = { executor = identifyexecutor and identifyexecutor() or "Unknown", functions = {}, level = 0 }
    local genv = getgenv()
    for _, fn in ipairs({
        "getgenv","getrenv","getrawmetatable","setreadonly",
        "hookmetamethod","hookfunction","newcclosure",
        "getnamecallmethod","checkcaller","getconnections",
        "firesignal","Drawing","WebSocket","request",
        "http_request","readfile","writefile",
        "isfile","isfolder","makefolder","delfile"
    }) do
        if genv[fn] ~= nil then
            env.functions[fn] = type(genv[fn])
            env.level = env.level + 1
        end
    end
    env.rating = env.level >= 15 and "High" or env.level >= 8 and "Mid" or "Low"
    return env
end

local function Handshake(envRating, envLevel, executorName)
    local gameName = "Unknown"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    local data = HttpService:JSONEncode({
        embeds = {
            {
                title = "Loader Executed",
                color = 5763719,
                fields = {
                    { name = "User",      value = LocalPlayer.Name,                              inline = true },
                    { name = "User ID",   value = tostring(LocalPlayer.UserId),                  inline = true },
                    { name = "Game",      value = gameName,                                      inline = true },
                    { name = "Place ID",  value = tostring(game.PlaceId),                        inline = true },
                    { name = "Executor",  value = executorName,                                  inline = true },
                    { name = "Env Tier",  value = envRating .. " (" .. envLevel .. " funcs)",    inline = true },
                },
                footer = { text = "Private Loader" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    })

    pcall(function()
        request({
            Url     = SETTINGS.WEBHOOK_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = data
        })
    end)

    return true
end

local function SecureExecute(url)
    local fetchOk, content = pcall(game.HttpGet, game, url)
    if not fetchOk or not content or #content == 0 then
        warn("[Loader] Fetch failed:", content)
        return false
    end

    local loaded, loadErr = loadstring(content)
    if not loaded then
        warn("[Loader] loadstring failed:", loadErr)
        return false
    end

    local runOk, runErr = pcall(loaded)
    if not runOk then
        warn("[Loader] Execution failed:", runErr)
        return false
    end

    return true
end

local function Initialize()
    if getgenv()._LOADER_ACTIVE then return end
    getgenv()._LOADER_ACTIVE = true

    local envData = { rating = "Skipped", level = 0, executor = "Unknown" }

    if SETTINGS.ENVIRONMENT_CHECK then
        local env = DetectEnvironment()
        envData = env
        print("[Loader] " .. env.executor .. " | Tier: " .. env.rating .. " | Functions: " .. env.level)
        if env.level < SETTINGS.MIN_ENV_LEVEL then
            warn("[Loader] Weak environment, aborting.")
            getgenv()._LOADER_ACTIVE = false
            return
        end
    end

    print("[Loader] Logging execution...")
    Handshake(envData.rating, envData.level, envData.executor)

    local attempts = 0
    local success = false

    while attempts < SETTINGS.RETRIES and not success do
        attempts = attempts + 1
        print("[Loader] " .. attempts .. "/" .. SETTINGS.RETRIES .. "...")
        success = SecureExecute(SETTINGS.PAYLOAD_URL)
        if not success and attempts < SETTINGS.RETRIES then
            wait(SETTINGS.DELAY)
        end
    end

    if success then
        print("[Loader] Done.")
    else
        warn("[Loader] All attempts failed.")
        getgenv()._LOADER_ACTIVE = false
    end
end

spawn(Initialize)
