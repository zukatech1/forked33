--[[
 
   Loadstring Size Spoofer Source
  for obfuscating simple loadstrings.

]]



local function detectEnvironment()
    local env = {
        executor = identifyexecutor and identifyexecutor() or "Unknown",
        functions = {},
        level = 0
    }
    local testFunctions = {
        "getgenv", "getrenv", "getrawmetatable", "setreadonly",
        "hookmetamethod", "hookfunction", "newcclosure",
        "getnamecallmethod", "checkcaller", "getconnections",
        "firesignal", "Drawing", "WebSocket", "request",
        "http_request", "syn_request", "readfile", "writefile",
        "isfile", "isfolder", "makefolder", "delfile"
    }
    for _, funcName in ipairs(testFunctions) do
        local func = getfenv()[funcName]
        if func then
            env.functions[funcName] = type(func)
            env.level = env.level + 1
        end
    end
    env.rating = env.level >= 20 and "High" or env.level >= 10 and "Mid" or "Terrible"
    return env
end
local env = detectEnvironment()
print("Executor:", env.executor)
print("Tier:", env.rating)
print("Functions:", env.level)
local SETTINGS = {
    URL = "  ", --url would go here. https://raw.githubusercontent.com/example/
    RETRIES = 3,
    DELAY = 1,
    ENVIRONMENT_CHECK = true
}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local ExecutionStatus = false
local function SecureExecute(TargetUrl)
    local Success, Content = pcall(function()
        return game:HttpGet(TargetUrl)
    end)
    if Success and Content then
        local Loaded, Error = loadstring(Content)
        if Loaded then
            local RunSuccess, RunError = pcall(Loaded)
            if RunSuccess then
                return true
            end
        end
    end
    return false
end
local function Initialize()
    if getgenv()._EXECUTOR_ACTIVE then 
        return 
    end
    getgenv()._EXECUTOR_ACTIVE = true
    local Attempts = 0
    while Attempts < SETTINGS.RETRIES do
        local Result = SecureExecute(SETTINGS.URL)
        if Result then
            ExecutionStatus = true
            break
        end
        Attempts = Attempts + 1
        task.wait(SETTINGS.DELAY)
    end
end
local ProxyHandler = {}
ProxyHandler.__index = function(Self, Key)
    if Key == "Execute" then
        return Initialize
    end
end
local Bootstrapper = setmetatable({}, ProxyHandler)
task.spawn(function()
    Bootstrapper.Execute()
end)
