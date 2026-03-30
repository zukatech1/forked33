local SETTINGS = {
    URL = "  ",
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
