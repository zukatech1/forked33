Modules.AdonisPanel = {
    State = {
        Visible         = false,
        Gui             = nil,
        TerminalLines   = {},
        CommandHistory  = {},
        HistoryIndex    = 0,
        MaxLines        = 1000,
        Dragging        = false,
        DragStart       = nil,
        StartPos        = nil,
        Macros          = {},
        Resizing        = false,
        ResizeStart     = nil,
        ResizeStartSize = nil,
        Snippets        = {},
        ActiveSnippet   = nil,
        ESPEnabled      = {},
        ESPConnection   = nil,
        ToastGui        = nil,
        ToastQueue      = {},
        ShowTimestamps  = false,
        _cmdPool        = {},
        _plrPool        = {},
        Pages           = {},
    },
    Config = {
        Theme = {
            Background    = Color3.fromRGB(31,  31,  31),
            BackgroundDim = Color3.fromRGB(22,  22,  22),
            TitleBar      = Color3.fromRGB(26,  26,  26),
            Accent        = Color3.fromRGB(195, 33,  35),
            Text          = Color3.fromRGB(255, 255, 255),
            SubText       = Color3.fromRGB(178, 178, 178),
            Border        = Color3.fromRGB(45,  45,  45),
            InputBg       = Color3.fromRGB(28,  28,  28),
            Green         = Color3.fromRGB(80,  200, 80),
            Yellow        = Color3.fromRGB(255, 200, 50),
            Red           = Color3.fromRGB(220, 60,  60),
            Purple        = Color3.fromRGB(120, 60,  200),
            Blue          = Color3.fromRGB(50,  100, 200),
        },
        Size        = Vector2.new(510, 283),
        Position    = UDim2.new(0.5, -732, 0.5, 97),
        ToggleKey   = Enum.KeyCode.Semicolon,
        FontSize    = 13,
        Opacity     = 0,
        MinSize     = Vector2.new(510, 280),
    }
}
local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end
local function corner(r, p)  return make("UICorner", {CornerRadius=UDim.new(0,r)}, p) end
local function stroke(t,c,p) return make("UIStroke",  {Thickness=t, Color=c or Color3.fromRGB(60,60,60), ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, p) end
local function scrollFrame(props, parent)
    local f = make("ScrollingFrame", {
        BackgroundColor3      = props.BackgroundColor3 or Color3.fromRGB(22,22,22),
        BorderSizePixel       = 0.5,
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = Color3.fromRGB(100,100,100),
        CanvasSize            = UDim2.new(0,0,0,0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        BottomImage = "http://roblox.com/asset?id=158348114",
        MidImage    = "http://roblox.com/asset?id=158348114",
        TopImage    = "http://roblox.com/asset?id=158348114",
        Size     = props.Size     or UDim2.new(1,-10,1,-10),
        Position = props.Position or UDim2.new(0,5,0,5),
    }, parent)
    if props.Corner then corner(props.Corner, f) end
    make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0, props.Padding or 1)}, f)
    make("UIPadding",    {PaddingLeft=UDim.new(0,4), PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4)}, f)
    return f
end
local function lineColor(text, T)
    local lo = text:lower()
    if lo:find("^error") or lo:find("^%[error%]") then
        return T.Red,    Color3.fromRGB(50,20,20)
    elseif lo:find("^warn") or lo:find("^%[warn%]") then
        return T.Yellow, Color3.fromRGB(50,45,20)
    elseif lo:find("^>") then
        return T.Accent, nil
    elseif lo:find("^  macro") then
        return T.SubText, nil
    end
    return nil, nil
end
-- ── Syntax highlighter ───────────────────────────────────────────────────
local Syntax = {
    Text          = Color3.fromRGB(204,204,204),
    Operator      = Color3.fromRGB(204,204,204),
    Number        = Color3.fromRGB(255,198,0),
    String        = Color3.fromRGB(173,241,149),
    Comment       = Color3.fromRGB(102,102,102),
    Keyword       = Color3.fromRGB(248,109,124),
    BuiltIn       = Color3.fromRGB(132,214,247),
    LocalMethod   = Color3.fromRGB(253,251,172),
    LocalProperty = Color3.fromRGB(97,161,241),
    Nil           = Color3.fromRGB(255,198,0),
    Bool          = Color3.fromRGB(255,198,0),
    Function      = Color3.fromRGB(248,109,124),
    Local         = Color3.fromRGB(248,109,124),
    Self          = Color3.fromRGB(248,109,124),
    FunctionName  = Color3.fromRGB(253,251,172),
    Bracket       = Color3.fromRGB(204,204,204),
}
local HL_KEYWORDS = {
    ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
    ["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,
    ["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,
    ["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,
    ["until"]=true,["while"]=true,
}
local HL_BUILTINS = {
    ["game"]=true,["Players"]=true,["TweenService"]=true,["ScreenGui"]=true,
    ["Instance"]=true,["UDim2"]=true,["Vector2"]=true,["Vector3"]=true,
    ["Color3"]=true,["Enum"]=true,["loadstring"]=true,["warn"]=true,
    ["pcall"]=true,["print"]=true,["UDim"]=true,["delay"]=true,
    ["require"]=true,["spawn"]=true,["tick"]=true,["getfenv"]=true,
    ["workspace"]=true,["setfenv"]=true,["getgenv"]=true,["script"]=true,
    ["string"]=true,["pairs"]=true,["type"]=true,["math"]=true,
    ["tonumber"]=true,["tostring"]=true,["CFrame"]=true,["BrickColor"]=true,
    ["table"]=true,["Random"]=true,["Ray"]=true,["xpcall"]=true,
    ["coroutine"]=true,["_G"]=true,["_VERSION"]=true,["debug"]=true,
    ["Axes"]=true,["assert"]=true,["error"]=true,["ipairs"]=true,
    ["rawequal"]=true,["rawget"]=true,["rawset"]=true,["select"]=true,
    ["bit32"]=true,["buffer"]=true,["task"]=true,["os"]=true,
}
local HL_METHODS = {
    ["WaitForChild"]=true,["FindFirstChild"]=true,["GetService"]=true,
    ["Destroy"]=true,["Clone"]=true,["IsA"]=true,["ClearAllChildren"]=true,
    ["GetChildren"]=true,["GetDescendants"]=true,["Connect"]=true,
    ["Disconnect"]=true,["Fire"]=true,["Invoke"]=true,["rgb"]=true,
    ["FireServer"]=true,["request"]=true,["call"]=true,
}
local function _hlColorHex(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end
local function _hlTokenize(line)
    local tokens, i = {}, 1
    while i <= #line do
        local c = line:sub(i,i)
        if c == "-" and line:sub(i,i+1) == "--" then
            table.insert(tokens, {line:sub(i), "Comment"}); break
        elseif c == "[" and line:sub(i,i+1):match("%[=*%[") then
            local eqCount = 0
            local k = i+1
            while line:sub(k,k) == "=" do eqCount += 1; k += 1 end
            if line:sub(k,k) == "[" then
                local close = "]"..string.rep("=",eqCount).."]"
                local endIdx = line:find(close, k+1, true)
                local j = endIdx and (endIdx + #close - 1) or #line
                table.insert(tokens, {line:sub(i,j), "String"}); i = j
            else
                table.insert(tokens, {c, "Operator"})
            end
        elseif c == '"' or c == "'" then
            local q, j = c, i+1
            while j <= #line do
                if line:sub(j,j) == q and line:sub(j-1,j-1) ~= "\\" then break end
                j += 1
            end
            table.insert(tokens, {line:sub(i,j), "String"}); i = j
        elseif c:match("%d") then
            local j = i
            while j <= #line and line:sub(j,j):match("[%d%.]") do j += 1 end
            table.insert(tokens, {line:sub(i,j-1), "Number"}); i = j-1
        elseif c:match("[%a_]") then
            local j = i
            while j <= #line and line:sub(j,j):match("[%w_]") do j += 1 end
            table.insert(tokens, {line:sub(i,j-1), "Word"}); i = j-1
        else
            table.insert(tokens, {c, "Operator"})
        end
        i += 1
    end
    return tokens
end
local function _hlDetect(tokens, idx)
    local val, typ = tokens[idx][1], tokens[idx][2]
    if typ ~= "Word" then return typ end
    if HL_KEYWORDS[val]  then return "Keyword"  end
    if HL_BUILTINS[val]  then return "BuiltIn"  end
    if HL_METHODS[val]   then return "LocalMethod" end
    if idx > 1 and tokens[idx-1][1] == "." then return "LocalProperty" end
    if idx > 1 and tokens[idx-1][1] == ":" then return "LocalMethod" end
    if val == "self"  then return "Self" end
    if val == "true" or val == "false" then return "Bool" end
    if val == "nil"   then return "Nil"  end
    if idx > 1 and tokens[idx-1][1] == "function" then return "FunctionName" end
    return "Text"
end
local function hlLine(line)
    local tokens = _hlTokenize(line)
    local out = ""
    for i, tok in ipairs(tokens) do
        local col = Syntax[_hlDetect(tokens, i)] or Syntax.Text
        local safe = tok[1]:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
        out ..= string.format('<font color="%s">%s</font>', _hlColorHex(col), safe)
    end
    return out
end
-- ─────────────────────────────────────────────────────────────────────────
function Modules.AdonisPanel:_initToast()
    if self.State.ToastGui then return end
    local tg = make("ScreenGui", {
        Name="ZukaToasts", DisplayOrder=997, ResetOnSpawn=false, IgnoreGuiInset=true,
    }, game:GetService("CoreGui"))
    self.State.ToastGui = tg
end
function Modules.AdonisPanel:_toast(msg, color)
    self:_initToast()
    local T = self.Config.Theme
    color = color or T.Yellow
    local frame = make("Frame", {
        Size=UDim2.new(0,280,0,34), Position=UDim2.new(1,-290,1,-50),
        BackgroundColor3=Color3.fromRGB(28,28,28), BackgroundTransparency=0.15,
        BorderSizePixel=0, ZIndex=10,
    }, self.State.ToastGui)
    stroke(1, color, frame)
    make("Frame", {
        Size=UDim2.fromOffset(3,34), BackgroundColor3=color, BorderSizePixel=0, ZIndex=11,
    }, frame)
    make("TextLabel", {
        Size=UDim2.new(1,-10,1,0), Position=UDim2.fromOffset(8,0),
        BackgroundTransparency=1, Text=msg, TextColor3=T.Text,
        Font=Enum.Font.SourceSans, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=11,
    }, frame)
    local toasts = self.State.ToastQueue
    for _, f in ipairs(toasts) do
        TweenService:Create(f, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = UDim2.new(f.Position.X.Scale, f.Position.X.Offset,
                                 f.Position.Y.Scale, f.Position.Y.Offset - 40)
        }):Play()
    end
    table.insert(toasts, frame)
    frame.Position = UDim2.new(1,-290+300, 1,-50)
    TweenService:Create(frame, TweenInfo.new(0.25,Enum.EasingStyle.Quad), {
        Position=UDim2.new(1,-290,1,-50)
    }):Play()
    task.delay(4, function()
        TweenService:Create(frame, TweenInfo.new(0.25,Enum.EasingStyle.Quad), {
            Position=UDim2.new(1,-290+300,1,-50), BackgroundTransparency=1
        }):Play()
        task.wait(0.3)
        frame:Destroy()
        for i, f in ipairs(toasts) do
            if f == frame then table.remove(toasts,i) break end
        end
    end)
end
function Modules.AdonisPanel:_espUpdate()
    local Players = game:GetService("Players")
    if self.State.ESPConnection then
        self.State.ESPConnection:Disconnect()
        self.State.ESPConnection = nil
    end
    for uid, data in pairs(self.State.ESPEnabled) do
        if data.Drawings then
            for _, d in pairs(data.Drawings) do
                pcall(function() d:Remove() end)
            end
            data.Drawings = {}
        end
    end
    local anyEnabled = false
    for _, data in pairs(self.State.ESPEnabled) do
        if data.Enabled then anyEnabled = true break end
    end
    if not anyEnabled then return end
    self.State.ESPConnection = game:GetService("RunService").RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local data = self.State.ESPEnabled[plr.UserId]
            if not data or not data.Enabled then
                if data and data.Drawings then
                    for _, d in pairs(data.Drawings) do pcall(function() d.Visible=false end) end
                end
                continue
            end
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not root then
                if data.Drawings then
                    for _, d in pairs(data.Drawings) do pcall(function() d.Visible=false end) end
                end
                continue
            end
            if not data.Drawings then data.Drawings = {} end
            local dr = data.Drawings
            if not dr.Box then
                dr.Box       = Drawing.new("Square")
                dr.Box.Thickness = 1
                dr.Box.Filled = false
            end
            if not dr.Name then
                dr.Name      = Drawing.new("Text")
                dr.Name.Size = 14
                dr.Name.Center = true
                dr.Name.Outline = true
            end
            if not dr.Dist then
                dr.Dist      = Drawing.new("Text")
                dr.Dist.Size = 12
                dr.Dist.Center = true
                dr.Dist.Outline = true
            end
            if not dr.HealthBg then
                dr.HealthBg  = Drawing.new("Square")
                dr.HealthBg.Thickness = 1
                dr.HealthBg.Filled = true
                dr.HealthBg.Color  = Color3.fromRGB(20,20,20)
            end
            if not dr.HealthBar then
                dr.HealthBar = Drawing.new("Square")
                dr.HealthBar.Thickness = 1
                dr.HealthBar.Filled = true
            end
            local col = data.Color or Color3.fromRGB(255,50,50)
            local head = char:FindFirstChild("Head")
            local topPos   = (head and head.Position + Vector3.new(0,0.6,0)) or root.Position + Vector3.new(0,2.6,0)
            local botPos   = root.Position - Vector3.new(0,3,0)
            local topScreen, topVis = camera:WorldToViewportPoint(topPos)
            local botScreen, _      = camera:WorldToViewportPoint(botPos)
            if not topVis then
                for _, d in pairs(dr) do pcall(function() d.Visible=false end) end
                continue
            end
            local h = math.abs(topScreen.Y - botScreen.Y)
            local w = h * 0.5
            local cx = topScreen.X
            dr.Box.Visible  = true
            dr.Box.Color    = col
            dr.Box.Size     = Vector2.new(w, h)
            dr.Box.Position = Vector2.new(cx - w/2, topScreen.Y)
            dr.Name.Visible   = true
            dr.Name.Color     = col
            dr.Name.Text      = plr.DisplayName
            dr.Name.Position  = Vector2.new(cx, topScreen.Y - 16)
            local dist = (camera.CFrame.Position - root.Position).Magnitude
            dr.Dist.Visible   = true
            dr.Dist.Color     = Color3.fromRGB(200,200,200)
            dr.Dist.Text      = string.format("[%.0fm]", dist)
            dr.Dist.Position  = Vector2.new(cx, botScreen.Y + 2)
            local hp    = hum and math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1) or 1
            local barH  = h * hp
            local barX  = cx - w/2 - 6
            dr.HealthBg.Visible  = true
            dr.HealthBg.Size     = Vector2.new(4, h)
            dr.HealthBg.Position = Vector2.new(barX, topScreen.Y)
            dr.HealthBar.Visible  = true
            dr.HealthBar.Color    = Color3.fromRGB(80*2*(1-hp), 200*hp, 40)
            dr.HealthBar.Size     = Vector2.new(4, barH)
            dr.HealthBar.Position = Vector2.new(barX, topScreen.Y + (h - barH))
        end
    end)
end
function Modules.AdonisPanel:_build()
    local T   = self.Config.Theme
    local UIS = game:GetService("UserInputService")
    local gui = make("ScreenGui", {
        Name="ZukaAdonisPanel", DisplayOrder=999,
        ResetOnSpawn=false, IgnoreGuiInset=true,
    }, game:GetService("CoreGui"))
    self.State.Gui = gui
    local UIS_clickConn
    UIS_clickConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not (self.State.InputBox and self.State.InputBox:IsFocused()) then return end
        local mp = game:GetService("UserInputService"):GetMouseLocation()
        local wp = win.AbsolutePosition
        local ws = win.AbsoluteSize
        local inside = mp.X >= wp.X and mp.X <= wp.X + ws.X
                    and mp.Y >= wp.Y and mp.Y <= wp.Y + ws.Y
        if not inside then
            self.State.InputBox:ReleaseFocus(false)
        end
    end)
    gui.Destroying:Connect(function() UIS_clickConn:Disconnect() end)
    local win = make("Frame", {
        Name="Window",
        Size=UDim2.fromOffset(self.Config.Size.X, self.Config.Size.Y),
        Position=self.Config.Position,
        BackgroundColor3=T.Background, BackgroundTransparency=self.Config.Opacity,
        BorderSizePixel=0, ClipsDescendants=true, ZIndex=2,
    }, gui)
    corner(6, win)
    stroke(1, T.Border, win)
    local titleBar = make("Frame", {
        Size=UDim2.new(1,0,0,26), BackgroundColor3=T.TitleBar, BorderSizePixel=1, ZIndex=3,
    }, win)
    corner(6, titleBar)
    make("Frame", {
        Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,1,-6),
        BackgroundColor3=T.TitleBar, BorderSizePixel=0, ZIndex=3,
    }, titleBar)
    local titleLabel = make("TextLabel", {
        Size=UDim2.new(1,-120,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text="Adonis ~ //  Terminal",
        TextColor3=T.Text, Font=Enum.Font.SourceSansLight, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
    }, titleBar)
    local keyHintLabel = make("TextLabel", {
        Size=UDim2.fromOffset(50,20), Position=UDim2.new(1,-120,0,3),
        BackgroundTransparency=1,
        Text="["..self.Config.ToggleKey.Name.."]",
        TextColor3=T.SubText, Font=Enum.Font.SourceSans, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=4,
    }, titleBar)
    local closeBtn = make("TextButton", {
        Size=UDim2.fromOffset(30,20), Position=UDim2.new(1,-35,0,3),
        BackgroundColor3=T.Accent, BackgroundTransparency=0.25, BorderSizePixel=0,
        Text="×", TextColor3=Color3.fromRGB(220,220,220),
        Font=Enum.Font.SourceSansBold, TextSize=18, ZIndex=5,
    }, titleBar)
    corner(0, closeBtn)
    local minBtn = make("TextButton", {
        Size=UDim2.fromOffset(30,20), Position=UDim2.new(1,-70,0,3),
        BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.5, BorderSizePixel=0,
        Text="-", TextColor3=T.Text, Font=Enum.Font.ArialBold, TextSize=14, ZIndex=5,
    }, titleBar)
    corner(0, minBtn)
    local tabRow = make("Frame", {
        Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,26),
        BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0, ZIndex=3,
    }, win)
    make("UIListLayout", {
        FillDirection=Enum.FillDirection.Horizontal,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,2),
    }, tabRow)
    make("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingTop=UDim.new(0,3)}, tabRow)
    local content = make("Frame", {
        Size=UDim2.new(1,0,1,-66), Position=UDim2.new(0,0,0,52),
        BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true, ZIndex=2,
    }, win)
    -- Status bar
    local statusBar = make("Frame", {
        Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
        BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0, ZIndex=9,
    }, win)
    make("Frame", {
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(45,45,45), BorderSizePixel=0, ZIndex=9,
    }, statusBar)
    local statusLeft = make("TextLabel", {
        Size=UDim2.new(0.6,0,1,0), Position=UDim2.fromOffset(6,0),
        BackgroundTransparency=1,
        Text="● " .. (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or "—"),
        TextColor3=Color3.fromRGB(100,100,100), Font=Enum.Font.SourceSans, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=10,
    }, statusBar)
    local statusRight = make("TextLabel", {
        Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0.6,0,0,0),
        BackgroundTransparency=1,
        Text=tostring(game.PlaceId),
        TextColor3=Color3.fromRGB(70,70,70), Font=Enum.Font.SourceSans, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=10,
    }, statusBar)
    make("UIPadding", {PaddingRight=UDim.new(0,6)}, statusRight)
    -- Update status ping periodically
    task.spawn(function()
        while task.wait(2) do
            if not statusBar.Parent then break end
            local rs = game:GetService("Stats")
            local ping = rs and rs.Network and rs.Network.ServerStatsItem and
                pcall(function() return rs.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
            statusLeft.Text = "● " .. (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or "—")
        end
    end)
    local resizeHandle = make("TextButton", {
        Size=UDim2.fromOffset(14,14),
        Position=UDim2.new(1,-14,1,-14),
        BackgroundColor3=Color3.fromRGB(80,80,80),
        BackgroundTransparency=0.6, BorderSizePixel=0, Text="◢",
        TextColor3=Color3.fromRGB(120,120,120), Font=Enum.Font.SourceSansBold, TextSize=12,
        ZIndex=10,
    }, win)
    corner(3, resizeHandle)
    local termPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=true, ZIndex=2,
    }, content)
    local outputScroll = scrollFrame({
        Size=UDim2.new(1,-10,1,-68), Position=UDim2.new(0,5,0,5), Corner=4,
    }, termPage)
    local hintLabel = make("TextLabel", {
        Size=UDim2.new(1,-10,0,16), Position=UDim2.new(0,5,1,-61),
        BackgroundTransparency=1, Text="",
        TextColor3=T.SubText, Font=Enum.Font.SourceSansItalic,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
    }, termPage)
    local inputBar = make("Frame", {
        Size=UDim2.new(1,-10,0,28), Position=UDim2.new(0,5,1,-38),
        BackgroundColor3=T.InputBg, BorderSizePixel=0, ZIndex=3,
    }, termPage)
    corner(0, inputBar)
    stroke(1, Color3.fromRGB(50,50,50), inputBar)
    make("TextLabel", {
        Size=UDim2.fromOffset(20,28), BackgroundTransparency=1,
        Text=">", TextColor3=T.Accent,
        Font=Enum.Font.SourceSansBold, TextSize=16, ZIndex=4,
    }, inputBar)
    local inputBox = make("TextBox", {
        Size=UDim2.new(1,-25,1,0), Position=UDim2.new(0,20,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText="Send command.", PlaceholderColor3=T.SubText,
        TextColor3=T.Text, Font=Enum.Font.SourceSans,
        TextSize=self.Config.FontSize, TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false, ZIndex=4,
    }, inputBar)
    make("UIPadding", {PaddingRight=UDim.new(0,5)}, inputBox)
    local cmdPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)
    local searchBox = make("TextBox", {
        Size=UDim2.new(1,-10,0,24), Position=UDim2.new(0,5,0,5),
        BackgroundColor3=T.InputBg, BorderSizePixel=0, Text="",
        PlaceholderText="Search commands...", PlaceholderColor3=T.SubText,
        TextColor3=T.Text, Font=Enum.Font.SourceSans,
        TextSize=14, ClearTextOnFocus=false, ZIndex=3,
    }, cmdPage)
    corner(0, searchBox)
    make("UIPadding", {PaddingLeft=UDim.new(0,6)}, searchBox)
    local cmdScroll = scrollFrame({
        Size=UDim2.new(1,-10,1,-38), Position=UDim2.new(0,5,0,33), Corner=4,
    }, cmdPage)
    local plrPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)
    local plrScroll = scrollFrame({
        Size=UDim2.new(1,-10,1,-10), Position=UDim2.new(0,5,0,5), Corner=4, Padding=2,
    }, plrPage)
    local logsPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)
    local logSearch = make("TextBox", {
        Size=UDim2.new(1,-112,0,24), Position=UDim2.new(0,5,0,5),
        BackgroundColor3=T.InputBg, BorderSizePixel=0, Text="",
        PlaceholderText="Search logs...", PlaceholderColor3=T.SubText,
        TextColor3=T.Text, Font=Enum.Font.SourceSans, TextSize=14, ClearTextOnFocus=false, ZIndex=3,
    }, logsPage)
    corner(0, logSearch)
    make("UIPadding", {PaddingLeft=UDim.new(0,6)}, logSearch)
    local logClearBtn = make("TextButton", {
        Size=UDim2.fromOffset(55,24), Position=UDim2.new(1,-60,0,5),
        BackgroundColor3=T.Red, BackgroundTransparency=0.4, BorderSizePixel=0,
        Text="Clear", TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=12, ZIndex=3,
    }, logsPage)
    corner(0, logClearBtn)
    local tsBtn = make("TextButton", {
        Size=UDim2.fromOffset(52,24), Position=UDim2.new(1,-118,0,5),
        BackgroundColor3=Color3.fromRGB(50,50,50), BackgroundTransparency=0.4, BorderSizePixel=0,
        Text="[ts off]", TextColor3=T.SubText, Font=Enum.Font.SourceSans, TextSize=11, ZIndex=3,
    }, logsPage)
    corner(0, tsBtn)
    tsBtn.MouseButton1Click:Connect(function()
        self.State.ShowTimestamps = not self.State.ShowTimestamps
        tsBtn.Text = self.State.ShowTimestamps and "[ts on]" or "[ts off]"
        tsBtn.TextColor3 = self.State.ShowTimestamps and T.Green or T.SubText
        self:_populateLogs(logSearch.Text)
    end)
    local logScroll = scrollFrame({
        Size=UDim2.new(1,-10,1,-38), Position=UDim2.new(0,5,0,33), Corner=4,
    }, logsPage)
    local macroPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)
    local macroScroll = scrollFrame({
        Size=UDim2.new(1,-10,1,-42), Position=UDim2.new(0,5,0,5), Corner=4, Padding=3,
    }, macroPage)
    local macroAddBar = make("Frame", {
        Size=UDim2.new(1,-10,0,32), Position=UDim2.new(0,5,1,-37),
        BackgroundColor3=T.InputBg, BorderSizePixel=0, ZIndex=3,
    }, macroPage)
    corner(0, macroAddBar)
    stroke(1, Color3.fromRGB(50,50,50), macroAddBar)
    local aliasInput = make("TextBox", {
        Size=UDim2.new(0.25,0,1,0), BackgroundTransparency=1,
        Text="", PlaceholderText="alias", PlaceholderColor3=T.SubText,
        TextColor3=T.Accent, Font=Enum.Font.SourceSansBold, TextSize=13, ClearTextOnFocus=false, ZIndex=4,
    }, macroAddBar)
    make("UIPadding", {PaddingLeft=UDim.new(0,6)}, aliasInput)
    make("TextLabel", {
        Size=UDim2.fromOffset(12,32), Position=UDim2.new(0.25,0,0,0),
        BackgroundTransparency=1, Text=">", TextColor3=T.SubText,
        Font=Enum.Font.SourceSansBold, TextSize=14, ZIndex=4,
    }, macroAddBar)
    local cmdInput2 = make("TextBox", {
        Size=UDim2.new(0.6,-8,1,0), Position=UDim2.new(0.25,14,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText="command (no prefix)", PlaceholderColor3=T.SubText,
        TextColor3=T.Text, Font=Enum.Font.SourceSans, TextSize=13, ClearTextOnFocus=false, ZIndex=4,
    }, macroAddBar)
    local macroAddBtn = make("TextButton", {
        Size=UDim2.new(0.15,-4,1,-8), Position=UDim2.new(0.85,0,0,4),
        BackgroundColor3=T.Green, BackgroundTransparency=0.3, BorderSizePixel=0,
        Text="+", TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=18, ZIndex=4,
    }, macroAddBar)
    corner(0, macroAddBtn)
    -- ── SCRIPT PAGE ──────────────────────────────────────────────────────
    local EDITOR_FONT     = Enum.Font.Code
    local EDITOR_FONTSIZE = 14
    local LINE_H          = 17  -- px per line, must match font size render height

    local scriptPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)

    -- Top toolbar
    local scriptBar = make("Frame", {
        Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0, ZIndex=3,
    }, scriptPage)
    -- 1px separator under toolbar
    make("Frame", {
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=Color3.fromRGB(45,45,45), BorderSizePixel=0, ZIndex=4,
    }, scriptBar)

    local newBtn = make("TextButton", {
        Size=UDim2.fromOffset(46,22), Position=UDim2.fromOffset(4,4),
        BackgroundColor3=Color3.fromRGB(45,45,45), BackgroundTransparency=0.2, BorderSizePixel=0,
        Text="New", TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=12, ZIndex=4,
    }, scriptBar)
    local saveBtn = make("TextButton", {
        Size=UDim2.fromOffset(46,22), Position=UDim2.fromOffset(54,4),
        BackgroundColor3=T.Blue, BackgroundTransparency=0.35, BorderSizePixel=0,
        Text="Save", TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=12, ZIndex=4,
    }, scriptBar)
    local runBtn = make("TextButton", {
        Size=UDim2.fromOffset(46,22), Position=UDim2.fromOffset(104,4),
        BackgroundColor3=T.Green, BackgroundTransparency=0.3, BorderSizePixel=0,
        Text="▶  Run", TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=12, ZIndex=4,
    }, scriptBar)
    local clearScriptBtn = make("TextButton", {
        Size=UDim2.fromOffset(46,22), Position=UDim2.fromOffset(154,4),
        BackgroundColor3=T.Red, BackgroundTransparency=0.45, BorderSizePixel=0,
        Text="Clear", TextColor3=T.Text, Font=Enum.Font.SourceSans, TextSize=12, ZIndex=4,
    }, scriptBar)
    -- Copy button on the right
    local copyScriptBtn = make("TextButton", {
        Size=UDim2.fromOffset(46,22), Position=UDim2.new(1,-50,0,4),
        BackgroundColor3=Color3.fromRGB(50,50,50), BackgroundTransparency=0.3, BorderSizePixel=0,
        Text="Copy", TextColor3=T.SubText, Font=Enum.Font.SourceSans, TextSize=12, ZIndex=4,
    }, scriptBar)
    -- Active snippet label (center of toolbar)
    local activeSnipLabel = make("TextLabel", {
        Size=UDim2.new(1,-310,1,0), Position=UDim2.fromOffset(206,0),
        BackgroundTransparency=1, Text="untitled",
        TextColor3=T.SubText, Font=Enum.Font.SourceSansItalic, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
    }, scriptBar)

    -- Left snippet sidebar (wider, cleaner)
    local SIDEBAR_W = 120
    local snippetPanel = make("ScrollingFrame", {
        Size=UDim2.new(0,SIDEBAR_W,1,-30), Position=UDim2.fromOffset(0,30),
        BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=Color3.fromRGB(80,80,80),
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ZIndex=3,
    }, scriptPage)
    make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,1)}, snippetPanel)
    -- Right border on sidebar
    make("Frame", {
        Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
        BackgroundColor3=Color3.fromRGB(45,45,45), BorderSizePixel=0, ZIndex=4,
    }, snippetPanel)

    -- Editor area
    local editorHolder = make("Frame", {
        Size=UDim2.new(1,-SIDEBAR_W,1,-30), Position=UDim2.fromOffset(SIDEBAR_W,30),
        BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0,
        ClipsDescendants=true, ZIndex=3,
    }, scriptPage)

    -- Line number gutter
    local LINE_GUTTER = 36
    local lineNumHolder = make("Frame", {
        Size=UDim2.new(0,LINE_GUTTER,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(24,24,24), BorderSizePixel=0, ClipsDescendants=true, ZIndex=4,
    }, editorHolder)
    -- Separator between gutter and code
    make("Frame", {
        Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
        BackgroundColor3=Color3.fromRGB(38,38,38), BorderSizePixel=0, ZIndex=5,
    }, lineNumHolder)

    -- Single scrolling code frame (input + highlight overlay share one scroll)
    local codeScroll = make("ScrollingFrame", {
        Size=UDim2.new(1,-LINE_GUTTER,1,0), Position=UDim2.fromOffset(LINE_GUTTER,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=Color3.fromRGB(90,90,90),
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.None,
        ScrollingDirection=Enum.ScrollingDirection.XY,
        ZIndex=4,
    }, editorHolder)

    -- Syntax highlight overlay (rendered behind the input)
    local hlOverlay = make("TextLabel", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="", RichText=true,
        TextColor3=T.Text, Font=EDITOR_FONT, TextSize=EDITOR_FONTSIZE,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=false, ZIndex=4,
    }, codeScroll)
    make("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingTop=UDim.new(0,3)}, hlOverlay)

    -- Actual input box (transparent text so only highlight shows)
    local codeInput = make("TextBox", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="-- write your script here\n",
        TextColor3=Color3.fromRGB(1,1,1,0), -- fully transparent text
        PlaceholderText="", PlaceholderColor3=Color3.fromRGB(0,0,0),
        Font=EDITOR_FONT, TextSize=EDITOR_FONTSIZE,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,
        MultiLine=true, ClearTextOnFocus=false,
        ZIndex=6,
    }, codeScroll)
    make("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingTop=UDim.new(0,3)}, codeInput)
    -- make caret visible by giving text a near-black color that blends with bg
    codeInput.TextColor3 = Color3.fromRGB(22,22,22)

    -- Rebuild line numbers to match current line count
    local _lineLabels = {}
    local function rebuildLineNums(count)
        -- remove excess
        for i = count+1, #_lineLabels do
            if _lineLabels[i] then _lineLabels[i]:Destroy() end
            _lineLabels[i] = nil
        end
        -- add missing
        for i = #_lineLabels+1, count do
            local lbl = make("TextLabel", {
                Size=UDim2.new(1,-2,0,LINE_H), BackgroundTransparency=1,
                Text=tostring(i), TextColor3=Color3.fromRGB(80,80,80),
                Font=EDITOR_FONT, TextSize=EDITOR_FONTSIZE,
                TextXAlignment=Enum.TextXAlignment.Right,
                Position=UDim2.fromOffset(0,(i-1)*LINE_H),
                ZIndex=5,
            }, lineNumHolder)
            _lineLabels[i] = lbl
        end
        lineNumHolder.Size = UDim2.new(0,LINE_GUTTER, 0, math.max(count*LINE_H, editorHolder.AbsoluteSize.Y))
    end

    -- Sync line number scroll offset to code scroll
    local function syncLineNums()
        local yOff = codeScroll.CanvasPosition.Y
        -- shift lineNumHolder up by scroll amount
        lineNumHolder.Position = UDim2.fromOffset(0, -yOff)
    end

    -- Rebuild syntax highlight and resize canvas
    local _highlightPending = false
    local function updateHighlight(code)
        if _highlightPending then return end
        _highlightPending = true
        task.defer(function()
            _highlightPending = false
            local lines = code:split("\n")
            local richLines = {}
            for _, line in ipairs(lines) do
                table.insert(richLines, hlLine(line))
            end
            hlOverlay.Text = table.concat(richLines, "\n")
            -- Resize canvas so scroll works correctly
            local lineCount = #lines
            local canvasH = math.max(lineCount * LINE_H + 20, editorHolder.AbsoluteSize.Y)
            codeScroll.CanvasSize = UDim2.new(0, 2000, 0, canvasH)
            hlOverlay.Size = UDim2.new(0, 2000, 0, canvasH)
            codeInput.Size  = UDim2.new(0, 2000, 0, canvasH)
            rebuildLineNums(lineCount)
            syncLineNums()
        end)
    end

    codeInput:GetPropertyChangedSignal("Text"):Connect(function()
        updateHighlight(codeInput.Text)
    end)
    codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        syncLineNums()
    end)
    updateHighlight(codeInput.Text)

    -- ── Snippet sidebar logic ─────────────────────────────────────────────
    local function getSnipDisplayName(sn) return sn.name or "untitled" end

    local function refreshSnippetList()
        for _, c in ipairs(snippetPanel:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        for i, sn in ipairs(self.State.Snippets) do
            local isActive = (i == self.State.ActiveSnippet)
            local row = make("Frame", {
                Size=UDim2.new(1,0,0,28),
                BackgroundColor3= isActive and Color3.fromRGB(38,38,38) or Color3.fromRGB(24,24,24),
                BackgroundTransparency=0, BorderSizePixel=0,
                LayoutOrder=i, ZIndex=4,
            }, snippetPanel)
            -- Active accent left bar
            if isActive then
                make("Frame", {
                    Size=UDim2.new(0,2,1,0), BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=5,
                }, row)
            end
            local nameBtn = make("TextButton", {
                Size=UDim2.new(1,-22,1,0), Position=UDim2.fromOffset(isActive and 6 or 4, 0),
                BackgroundTransparency=1, Text=getSnipDisplayName(sn),
                TextColor3= isActive and T.Text or T.SubText,
                Font= isActive and Enum.Font.SourceSansBold or Enum.Font.SourceSans,
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=5,
            }, row)
            make("UIPadding", {PaddingLeft=UDim.new(0,4)}, nameBtn)
            -- Delete button (X)
            local delBtn = make("TextButton", {
                Size=UDim2.fromOffset(18,18), Position=UDim2.new(1,-20,0,5),
                BackgroundColor3=Color3.fromRGB(60,30,30), BackgroundTransparency=0.3, BorderSizePixel=0,
                Text="×", TextColor3=Color3.fromRGB(180,80,80),
                Font=Enum.Font.SourceSansBold, TextSize=14, ZIndex=6,
            }, row)
            nameBtn.MouseButton1Click:Connect(function()
                -- Save current before switching
                if self.State.ActiveSnippet and self.State.Snippets[self.State.ActiveSnippet] then
                    self.State.Snippets[self.State.ActiveSnippet].code = codeInput.Text
                end
                self.State.ActiveSnippet = i
                codeInput.Text = sn.code or ""
                activeSnipLabel.Text = getSnipDisplayName(sn)
                refreshSnippetList()
            end)
            delBtn.MouseButton1Click:Connect(function()
                table.remove(self.State.Snippets, i)
                if self.State.ActiveSnippet == i then
                    self.State.ActiveSnippet = nil
                    codeInput.Text = ""
                    activeSnipLabel.Text = "untitled"
                elseif self.State.ActiveSnippet and self.State.ActiveSnippet > i then
                    self.State.ActiveSnippet = self.State.ActiveSnippet - 1
                end
                refreshSnippetList()
                self:Print("Snippet deleted.", T.SubText)
            end)
        end
    end
    self.State.RefreshSnippets = refreshSnippetList

    -- New script
    newBtn.MouseButton1Click:Connect(function()
        -- auto-save current
        if self.State.ActiveSnippet and self.State.Snippets[self.State.ActiveSnippet] then
            self.State.Snippets[self.State.ActiveSnippet].code = codeInput.Text
        end
        local newName = "Script " .. tostring(#self.State.Snippets + 1)
        table.insert(self.State.Snippets, {name=newName, code="-- "..newName.."\n"})
        self.State.ActiveSnippet = #self.State.Snippets
        codeInput.Text = self.State.Snippets[self.State.ActiveSnippet].code
        activeSnipLabel.Text = newName
        refreshSnippetList()
        self:Print("New snippet: "..newName, T.SubText)
    end)

    -- Save current snippet
    saveBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if self.State.ActiveSnippet and self.State.Snippets[self.State.ActiveSnippet] then
            self.State.Snippets[self.State.ActiveSnippet].code = code
            local name = self.State.Snippets[self.State.ActiveSnippet].name
            refreshSnippetList()
            self:Print("Saved: "..name, T.Green)
            self:_toast("Saved: "..name, T.Green)
        else
            -- No active snippet — create one
            local newName = "Script " .. tostring(#self.State.Snippets + 1)
            table.insert(self.State.Snippets, {name=newName, code=code})
            self.State.ActiveSnippet = #self.State.Snippets
            activeSnipLabel.Text = newName
            refreshSnippetList()
            self:Print("Saved as: "..newName, T.Green)
            self:_toast("Saved as: "..newName, T.Green)
        end
    end)

    -- Clear editor
    clearScriptBtn.MouseButton1Click:Connect(function()
        codeInput.Text = ""
    end)

    -- Copy to clipboard
    copyScriptBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if code:match("^%s*$") then return end
        if setclipboard then
            pcall(setclipboard, code)
            self:_toast("Script copied to clipboard", T.Blue)
        else
            self:Print("setclipboard not available on this executor.", T.Red)
        end
    end)

    -- Execute
    runBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if code:match("^%s*$") then return end
        -- Auto-save before run
        if self.State.ActiveSnippet and self.State.Snippets[self.State.ActiveSnippet] then
            self.State.Snippets[self.State.ActiveSnippet].code = code
        end
        runBtn.Text = "..."
        runBtn.BackgroundTransparency = 0.6
        task.defer(function()
            self:Print("▶ Executing script...", T.Green)
            local fn, compErr = loadstring(code)
            if not fn then
                self:Print("Syntax error: "..tostring(compErr), T.Red)
                self:_toast("Syntax error — check terminal", T.Red)
            else
                local ok, runErr = pcall(fn)
                if not ok then
                    self:Print("Runtime error: "..tostring(runErr), T.Red)
                    self:_toast("Runtime error — check terminal", T.Red)
                else
                    self:Print("Script executed OK.", T.Green)
                    self:_toast("Script executed OK", T.Green)
                end
            end
            runBtn.Text = "▶  Run"
            runBtn.BackgroundTransparency = 0.3
        end)
    end)
    local settingsPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)
    local settingsScroll = scrollFrame({
        Size=UDim2.new(1,-10,1,-10), Position=UDim2.new(0,5,0,5), Corner=4, Padding=6,
    }, settingsPage)
    local function settingRow(label)
        local row = make("Frame", {
            Size=UDim2.new(1,-5,0,36),
            BackgroundColor3=Color3.fromRGB(28,28,28), BackgroundTransparency=0.25,
            BorderSizePixel=0, ZIndex=3,
        }, settingsScroll)
        corner(0, row)
        make("TextLabel", {
            Size=UDim2.new(0.5,0,1,0), Position=UDim2.fromOffset(8,0),
            BackgroundTransparency=1, Text=label, TextColor3=T.Text,
            Font=Enum.Font.SourceSans, TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
        }, row)
        return row
    end
    local accentRow = settingRow("Accent Color")
    local accentColors = {
        Color3.fromRGB(195,33,35),
        Color3.fromRGB(50,150,255),
        Color3.fromRGB(80,200,80),
        Color3.fromRGB(200,120,50),
        Color3.fromRGB(180,50,220),
        Color3.fromRGB(255,200,50),
    }
    for i, col in ipairs(accentColors) do
        local dot = make("TextButton", {
            Size=UDim2.fromOffset(20,20),
            Position=UDim2.new(0.5, (i-1)*24, 0, 8),
            BackgroundColor3=col, BorderSizePixel=0, Text="", ZIndex=5,
        }, accentRow)
        corner(10, dot)
        dot.MouseButton1Click:Connect(function()
            T.Accent = col
            closeBtn.BackgroundColor3 = col
            self:Print("Accent changed.", col)
            for _, tab in ipairs(self._tabDefs or {}) do
                if tab.Btn and tab.Page and tab.Page.Visible then
                    tab.Btn.BackgroundColor3 = col
                end
            end
        end)
    end
    local keyRow = settingRow("Toggle Key")
    local keyBox = make("TextBox", {
        Size=UDim2.new(0.45,0,1,-8), Position=UDim2.new(0.52,0,0,4),
        BackgroundColor3=T.InputBg, BorderSizePixel=0,
        Text=self.Config.ToggleKey.Name,
        TextColor3=T.Accent, Font=Enum.Font.SourceSansBold,
        TextSize=13, ClearTextOnFocus=false, ZIndex=5,
    }, keyRow)
    corner(0, keyBox)
    keyBox.FocusLost:Connect(function()
        local key = Enum.KeyCode[keyBox.Text]
        if key then
            self.Config.ToggleKey = key
            keyHintLabel.Text = "["..keyBox.Text.."]"
            self:Print("Toggle key → "..keyBox.Text, T.SubText)
        else
            keyBox.Text = self.Config.ToggleKey.Name
        end
    end)
    local fsRow = settingRow("Font Size  ("..self.Config.FontSize..")")
    local fsSizes = {12,13,14,15,16,18}
    for i, sz in ipairs(fsSizes) do
        local btn = make("TextButton", {
            Size=UDim2.fromOffset(28,22), Position=UDim2.new(0.5,(i-1)*32,0,7),
            BackgroundColor3=sz==self.Config.FontSize and T.Accent or Color3.fromRGB(45,45,45),
            BackgroundTransparency=0.3, BorderSizePixel=0,
            Text=tostring(sz), TextColor3=T.Text,
            Font=Enum.Font.SourceSansBold, TextSize=12, ZIndex=5,
        }, fsRow)
        corner(3, btn)
        btn.MouseButton1Click:Connect(function()
            self.Config.FontSize = sz
            inputBox.TextSize = sz
            fsRow:FindFirstChild("TextLabel").Text = "Font Size  ("..sz..")"
            for _, c in ipairs(fsRow:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = (tonumber(c.Text)==sz) and T.Accent or Color3.fromRGB(45,45,45)
                end
            end
        end)
    end
    local mlRow = settingRow("Max Lines  ("..self.State.MaxLines..")")
    local mlOptions = {100, 250, 500, 1000}
    for i, ml in ipairs(mlOptions) do
        local btn = make("TextButton", {
            Size=UDim2.fromOffset(40,22), Position=UDim2.new(0.5,(i-1)*44,0,7),
            BackgroundColor3=ml==self.State.MaxLines and T.Accent or Color3.fromRGB(45,45,45),
            BackgroundTransparency=0.3, BorderSizePixel=0,
            Text=tostring(ml), TextColor3=T.Text,
            Font=Enum.Font.SourceSans, TextSize=12, ZIndex=5,
        }, mlRow)
        corner(3, btn)
        btn.MouseButton1Click:Connect(function()
            self.State.MaxLines = ml
            mlRow:FindFirstChild("TextLabel").Text = "Max Lines  ("..ml..")"
            for _, c in ipairs(mlRow:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = (tonumber(c.Text)==ml) and T.Accent or Color3.fromRGB(45,45,45)
                end
            end
        end)
    end
    local opRow = settingRow("Window Opacity")
    local opSteps = {0, 0.08, 0.2, 0.4, 0.6}
    local opLabels = {"0%","8%","20%","40%","60%"}
    for i, op in ipairs(opSteps) do
        local btn = make("TextButton", {
            Size=UDim2.fromOffset(34,22), Position=UDim2.new(0.5,(i-1)*38,0,7),
            BackgroundColor3=op==self.Config.Opacity and T.Accent or Color3.fromRGB(45,45,45),
            BackgroundTransparency=0.3, BorderSizePixel=0,
            Text=opLabels[i], TextColor3=T.Text,
            Font=Enum.Font.SourceSans, TextSize=11, ZIndex=5,
        }, opRow)
        corner(3, btn)
        btn.MouseButton1Click:Connect(function()
            self.Config.Opacity = op
            win.BackgroundTransparency = op
            for _, c in ipairs(opRow:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = (c.Text==opLabels[opSteps[i] and 1 or 1]) and T.Accent or Color3.fromRGB(45,45,45)
                end
            end
            for j, o in ipairs(opSteps) do
                if o == op then
                    for _, c in ipairs(opRow:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.BackgroundColor3 = (c.Text==opLabels[j]) and T.Accent or Color3.fromRGB(45,45,45)
                        end
                    end
                    break
                end
            end
        end)
    end
    local decompPage = make("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Visible=false, ZIndex=2,
    }, content)
    local decompBar = make("Frame", {
        Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0, ZIndex=3,
    }, decompPage)
    local decompTargetBox = make("TextBox", {
        Size=UDim2.new(1,-200,1,-6), Position=UDim2.fromOffset(5,3),
        BackgroundColor3=T.InputBg, BorderSizePixel=0,
        Text="", PlaceholderText="script path  e.g. game.Workspace.MyScript",
        PlaceholderColor3=T.SubText, TextColor3=T.Text,
        Font=Enum.Font.SourceSans, TextSize=13, ClearTextOnFocus=false, ZIndex=4,
    }, decompBar)
    corner(0, decompTargetBox)
    make("UIPadding", {PaddingLeft=UDim.new(0,6)}, decompTargetBox)
    local decompRunBtn = make("TextButton", {
        Size=UDim2.fromOffset(80,24), Position=UDim2.new(1,-193,0,3),
        BackgroundColor3=T.Green, BackgroundTransparency=0.3, BorderSizePixel=0.4,
        Text="Build", TextColor3=T.Text,
        Font=Enum.Font.SourceSansBold, TextSize=10, ZIndex=4,
    }, decompBar)
    corner(0, decompRunBtn)
    local decompCopyBtn = make("TextButton", {
        Size=UDim2.fromOffset(52,24), Position=UDim2.new(1,-108,0,3),
        BackgroundColor3=T.Blue, BackgroundTransparency=0.3, BorderSizePixel=0,
        Text="Copy", TextColor3=T.Text,
        Font=Enum.Font.SourceSansBold, TextSize=12, ZIndex=4,
    }, decompBar)
    corner(0, decompCopyBtn)
    local decompClearBtn = make("TextButton", {
        Size=UDim2.fromOffset(52,24), Position=UDim2.new(1,-52,0,3),
        BackgroundColor3=T.Red, BackgroundTransparency=0.4, BorderSizePixel=0,
        Text="Clear", TextColor3=T.Text,
        Font=Enum.Font.SourceSans, TextSize=12, ZIndex=4,
    }, decompBar)
    corner(0, decompClearBtn)
    local decompModeRow = make("Frame", {
        Size=UDim2.new(1,0,0,22), Position=UDim2.fromOffset(0,30),
        BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0, ZIndex=3,
    }, decompPage)
    make("UIListLayout", {
        FillDirection=Enum.FillDirection.Horizontal,
        SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,3),
    }, decompModeRow)
    make("UIPadding", {PaddingLeft=UDim.new(0,5), PaddingTop=UDim.new(0,2)}, decompModeRow)
    local decompModes = {"disasm", "pretty", "clean"}
    local decompModeLabels = {"Disasm", "Pretty", "Clean"}
    local decompCurrentMode = "disasm"
    local decompModeBtns = {}
    for mi, mode in ipairs(decompModes) do
        local mb = make("TextButton", {
            Size=UDim2.fromOffset(56,18),
            BackgroundColor3=mode=="disasm" and T.Accent or Color3.fromRGB(40,40,40),
            BackgroundTransparency=mode=="disasm" and 0.2 or 0.6,
            BorderSizePixel=0, Text=decompModeLabels[mi], TextColor3=T.Text,
            Font=Enum.Font.SourceSans, TextSize=11, LayoutOrder=mi, ZIndex=4,
        }, decompModeRow)
        corner(3, mb)
        decompModeBtns[mode] = mb
        mb.MouseButton1Click:Connect(function()
            decompCurrentMode = mode
            for m2, b2 in pairs(decompModeBtns) do
                b2.BackgroundColor3 = (m2==mode) and T.Accent or Color3.fromRGB(40,40,40)
                b2.BackgroundTransparency = (m2==mode) and 0.2 or 0.6
            end
        end)
    end
    local decompOutputHolder = make("Frame", {
        Size=UDim2.new(1,0,1,-52), Position=UDim2.fromOffset(0,52),
        BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0, ClipsDescendants=true, ZIndex=3,
    }, decompPage)
    local decompScroll = make("ScrollingFrame", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=Color3.fromRGB(80,80,80),
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        ZIndex=4,
    }, decompOutputHolder)
    local decompOutput = make("TextLabel", {
        Size=UDim2.new(1,-8,0,0), Position=UDim2.fromOffset(4,4),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,
        Text="-- Decompiler ready.\n-- Enter Path.",
        RichText=false, TextColor3=T.SubText,
        Font=Enum.Font.Code, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=false, ZIndex=5,
    }, decompScroll)
    make("UIPadding", {PaddingLeft=UDim.new(0,2), PaddingTop=UDim.new(0,2)}, decompOutput)
    self.State.DecompLastText = ""
    local function decompSetOutput(text, isErr)
        decompOutput.Text = text
        decompOutput.TextColor3 = isErr and T.Red or T.Text
        self.State.DecompLastText = text
    end
    local function resolveScript(path)
    path = path:gsub('game:GetService%("([^"]+)"%)', function(svc)
        return svc
    end)
    path = path:gsub("game:GetService%('([^']+)'%)", function(svc)
        return svc
    end)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    local serviceAliases = {
        players        = "Players",
        workspace      = "Workspace",
        lighting       = "Lighting",
        replicatedstorage = "ReplicatedStorage",
        replicatedfirst   = "ReplicatedFirst",
        serverstorage     = "ServerStorage",
        serverscriptservice = "ServerScriptService",
        startergui     = "StarterGui",
        starterpack    = "StarterPack",
        starterplayer  = "StarterPlayer",
        soundservice   = "SoundService",
        chat           = "Chat",
        teams          = "Teams",
    }
    local cur = game
    for i, part in ipairs(parts) do
        if i == 1 then
            local lo = part:lower()
            if lo == "game" then
                cur = game
            elseif lo == "workspace" then
                cur = workspace
            else
                local realName = serviceAliases[lo] or part
                local ok, svc = pcall(function() return game:GetService(realName) end)
                if ok and svc then
                    cur = svc
                else
                    cur = game:FindFirstChild(part)
                end
            end
        elseif part == "LocalPlayer" then
            local ok, lp = pcall(function()
                return game:GetService("Players").LocalPlayer
            end)
            cur = (ok and lp) or nil
        else
            if not cur then return nil end
            cur = cur:FindFirstChild(part)
        end
    end
    return cur
end
    decompRunBtn.MouseButton1Click:Connect(function()
        local path = decompTargetBox.Text:match("^%s*(.-)%s*$")
        if path == "" then
            decompSetOutput("-- No path entered.", true)
            self:Print("Decompiler: no path entered.", T.Red)
            return
        end
        local dFn  = getgenv and getgenv()._ZUK_DECOMPILE
        local ppFn = getgenv and getgenv()._ZUK_PRETTYPRINT
        local coFn = getgenv and getgenv()._ZUK_CLEANOUTPUT
        if not dFn then
            decompSetOutput("-- ZukDecompile core not loaded yet.\n-- Wait a moment and try again.", true)
            self:Print("Decompiler: core not ready yet.", T.Yellow)
            return
        end
        local obj = resolveScript(path)
        if not obj then
            decompSetOutput("-- Could not find: " .. path, true)
            self:Print("Decompiler: path not found — " .. path, T.Red)
            return
        end
        if not obj:IsA("LuaSourceContainer") then
            decompSetOutput("-- Object is not a script: " .. obj.ClassName, true)
            self:Print("Decompiler: not a script — " .. obj.ClassName, T.Red)
            return
        end
        decompSetOutput("-- Decompiling " .. path .. "...", false)
        self:Print("Decompiler: compiling " .. path, T.SubText)
        task.spawn(function()
            local ok, bc = pcall(luau_compile or function() return nil end, "")
            local bytecode
            local compFn = getgenv and getgenv().luau_compile
            if compFn then
                local s, res = pcall(compFn, game:GetService("ScriptContext"))
            end
            local result
            local execDecomp = getgenv and (
                getgenv().decompile or
                getgenv().decompilestring or
                getgenv().decompile_script
            )
            if execDecomp then
                local s2, r2 = pcall(execDecomp, obj)
                if s2 and r2 and r2 ~= "" then
                    result = r2
                end
            end
            if not result then
                local getbc = getgenv and (getgenv().getscriptbytecode or getgenv().get_script_bytecode)
                if getbc then
                    local s3, bc3 = pcall(getbc, obj)
                    if s3 and bc3 then
                        local opts = {
                            DecompilerMode       = "disasm",
                            ReaderFloatPrecision = 7,
                            DecompilerTimeout    = 10,
                            ShowDebugInformation = true,
                            ShowInstructionLines = false,
                            ShowOperationIndex   = false,
                            ShowOperationNames   = false,
                            ShowTrivialOperations= true,
                            UseTypeInfo          = true,
                            ListUsedGlobals      = true,
                            CleanMode            = true,
                            EnabledRemarks       = {ColdRemark=false, InlineRemark=true},
                        }
                        local s4, r4 = pcall(dFn, bc3, opts)
                        result = s4 and r4 or ("-- ZukDecompile error: " .. tostring(r4))
                        if s4 and r4 then
                            if decompCurrentMode == "pretty" and ppFn then
                                local s5, r5 = pcall(ppFn, r4)
                                result = s5 and r5 or result
                            elseif decompCurrentMode == "clean" and coFn then
                                local s5, r5 = pcall(ppFn, r4)
                                if s5 and r5 then
                                    local s6, r6 = pcall(coFn, r5)
                                    result = s6 and r6 or result
                                end
                            end
                        end
                    end
                end
            end
            if not result then
                result = "-- No bytecode API available on this executor.\n-- Try: getscriptbytecode / decompile"
            end
            decompSetOutput(result, result:sub(1,2) == "--" and result:find("error", 1, true) ~= nil)
            self:Print("Decompiler: done — " .. path, T.Green)
        end)
    end)
    decompCopyBtn.MouseButton1Click:Connect(function()
        if self.State.DecompLastText ~= "" then
            if setclipboard then
                pcall(setclipboard, self.State.DecompLastText)
                self:_toast("Decompile output copied", T.Blue)
                self:Print("Decompiler: output copied to clipboard.", T.Blue)
            else
                self:Print("Decompiler: setclipboard not available.", T.Red)
            end
        end
    end)
    decompClearBtn.MouseButton1Click:Connect(function()
        decompSetOutput("-- Cleared.", false)
        self.State.DecompLastText = ""
    end)
    local tabDefs = {
        {Name="Terminal",   Page=termPage},
        {Name="Commands",   Page=cmdPage},
        {Name="Players",    Page=plrPage},
        {Name="Logs",       Page=logsPage},
        {Name="Macros",     Page=macroPage},
        {Name="Scripts",    Page=scriptPage},
        {Name="Decompiler", Page=decompPage},
        {Name="Settings",   Page=settingsPage},
    }
    self._tabDefs = tabDefs
    local function setTab(tab)
        for _, t in ipairs(tabDefs) do
            t.Page.Visible = (t == tab)
            if t.Btn then
                t.Btn.BackgroundColor3 = (t==tab) and T.Accent or Color3.fromRGB(40,40,40)
                t.Btn.BackgroundTransparency = (t==tab) and 0.2 or 0.6
                -- Active tab underline indicator
                local ind = t.Btn:FindFirstChild("_ActiveInd")
                if t == tab then
                    if not ind then
                        ind = make("Frame", {
                            Name="_ActiveInd",
                            Size=UDim2.new(1,0,0,2),
                            Position=UDim2.new(0,0,1,-2),
                            BackgroundColor3=T.Accent,
                            BorderSizePixel=0, ZIndex=6,
                        }, t.Btn)
                    end
                    ind.Visible = true
                else
                    if ind then ind.Visible = false end
                end
            end
        end
        titleLabel.Text = "Adonis ~ //  "..tab.Name
        if tab.Name == "Commands" then self:_populateCommands() end
        if tab.Name == "Players"  then self:_populatePlayers()  end
        if tab.Name == "Logs"     then self:_populateLogs()     end
        if tab.Name == "Macros"   then self:_populateMacros()   end
        if tab.Name == "Scripts"  then refreshSnippetList()     end
    end
    for i, tab in ipairs(tabDefs) do
        local btn = make("TextButton", {
            Name=tab.Name.."Tab",
            Size=UDim2.fromOffset(58,20),
            BackgroundColor3=i==1 and T.Accent or Color3.fromRGB(40,40,40),
            BackgroundTransparency=i==1 and 0.2 or 0.6,
            BorderSizePixel=0, Text=tab.Name, TextColor3=T.Text,
            Font=Enum.Font.SourceSansBold, TextSize=11,
            LayoutOrder=i, ZIndex=4,
        }, tabRow)
        corner(0, btn)
        tab.Btn = btn
        btn.MouseButton1Click:Connect(function() setTab(tab) end)
    end
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self.State.Dragging  = true
            self.State.DragStart = input.Position
            self.State.StartPos  = win.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if self.State.Dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - self.State.DragStart
            win.Position = UDim2.new(
                self.State.StartPos.X.Scale, self.State.StartPos.X.Offset + d.X,
                self.State.StartPos.Y.Scale, self.State.StartPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self.State.Dragging  = false
            self.State.Resizing  = false
        end
    end)
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.State.Resizing       = true
            self.State.ResizeStart    = input.Position
            self.State.ResizeStartSize = Vector2.new(win.AbsoluteSize.X, win.AbsoluteSize.Y)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if self.State.Resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - self.State.ResizeStart
            local newW = math.max(self.Config.MinSize.X, self.State.ResizeStartSize.X + d.X)
            local newH = math.max(self.Config.MinSize.Y, self.State.ResizeStartSize.Y + d.Y)
            win.Size = UDim2.fromOffset(newW, newH)
        end
    end)
    closeBtn.MouseButton1Click:Connect(function() self:Hide() end)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(win, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = minimized
                and UDim2.fromOffset(self.Config.Size.X, 26)
                or  UDim2.fromOffset(win.AbsoluteSize.X, math.max(win.AbsoluteSize.Y, self.Config.Size.Y))
        }):Play()
        content.Visible = not minimized
        tabRow.Visible  = not minimized
        minBtn.Text     = minimized and "+" or "-"
    end)
    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = inputBox.Text:lower()
        if txt == "" then hintLabel.Text = "" return end
        local firstWord = txt:match("^(%S+)")
        if not firstWord then hintLabel.Text = "" return end
        local matches = {}
        for name in pairs(Commands) do
            if name:lower():sub(1,#firstWord) == firstWord then
                table.insert(matches, name)
            end
        end
        table.sort(matches)
        if #matches == 0 then
            hintLabel.Text = ""
        elseif #matches <= 4 then
            hintLabel.Text = "→ "..table.concat(matches, "  |  ")
        else
            hintLabel.Text = "→ "..table.concat({table.unpack(matches,1,4)}, "  |  ").."  +"..tostring(#matches-4).." more"
        end
    end)
    inputBox.FocusLost:Connect(function(entered)
        if entered and inputBox.Text ~= "" then
            local cmd = inputBox.Text
            inputBox.Text = ""
            hintLabel.Text = ""
            table.insert(self.State.CommandHistory, 1, cmd)
            if #self.State.CommandHistory > 50 then table.remove(self.State.CommandHistory) end
            self.State.HistoryIndex = 0
            self:Print("> "..cmd, T.Accent)
            local firstWord = cmd:lower():match("^(%S+)")
            if firstWord and self.State.Macros[firstWord] then
                local rest = cmd:match("^%S+%s*(.*)")
                cmd = self.State.Macros[firstWord]..(rest~="" and " "..rest or "")
                self:Print("  macro → "..cmd, T.SubText)
            end
            local ok, err = pcall(function()
                processCommand(Prefix..cmd:gsub("^"..Prefix,""))
            end)
            if not ok then self:Print("Error: "..tostring(err), T.Red) end
        end
    end)
    UIS.InputBegan:Connect(function(input)
        if not self.State.Visible or not inputBox:IsFocused() then return end
        if input.KeyCode == Enum.KeyCode.Up then
            self.State.HistoryIndex = math.min(self.State.HistoryIndex+1, #self.State.CommandHistory)
            local e = self.State.CommandHistory[self.State.HistoryIndex]
            if e then inputBox.Text = e end
        elseif input.KeyCode == Enum.KeyCode.Down then
            self.State.HistoryIndex = math.max(self.State.HistoryIndex-1, 0)
            inputBox.Text = self.State.HistoryIndex==0 and "" or (self.State.CommandHistory[self.State.HistoryIndex] or "")
        elseif input.KeyCode == Enum.KeyCode.Tab then
            local txt = inputBox.Text:lower():match("^(%S+)") or ""
            for name in pairs(Commands) do
                if name:lower():sub(1,#txt) == txt and name:lower() ~= txt then
                    inputBox.Text = name.." "
                    break
                end
            end
        end
    end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:_populateCommands(searchBox.Text)
    end)
    logSearch:GetPropertyChangedSignal("Text"):Connect(function()
        self:_populateLogs(logSearch.Text)
    end)
    logClearBtn.MouseButton1Click:Connect(function()
        self.State.TerminalLines = {}
        for _, c in ipairs(outputScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        self:_populateLogs()
        self:Print("Logs cleared.", T.SubText)
    end)
    macroAddBtn.MouseButton1Click:Connect(function()
        local alias   = aliasInput.Text:lower():match("^(%S+)")
        local command = cmdInput2.Text:match("^(.-)%s*$")
        if alias and alias~="" and command and command~="" then
            self.State.Macros[alias] = command
            aliasInput.Text = ""
            cmdInput2.Text  = ""
            self:_populateMacros()
            self:Print("Macro added: "..alias.." → "..command, T.Green)
            RegisterCommand({Name=alias, Aliases={}, Description="Macro: "..command}, function(args)
                local full = command
                if args and #args>0 then full = full.." "..table.concat(args," ") end
                processCommand(Prefix..full)
            end)
        else
            self:Print("Need both alias and command.", T.Red)
        end
    end)
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.Config.ToggleKey then self:Toggle() end
    end)
    self.State.Win          = win
    self.State.OutputScroll = outputScroll
    self.State.InputBox     = inputBox
    self.State.CmdScroll    = cmdScroll
    self.State.SearchBox    = searchBox
    self.State.PlrScroll    = plrScroll
    self.State.LogScroll    = logScroll
    self.State.LogSearch    = logSearch
    self.State.MacroScroll  = macroScroll
    self.State.AliasInput   = aliasInput
    self.State.CmdInput     = cmdInput2
    self.State.Pages        = {
        Terminal    = termPage,    Commands = cmdPage, Players  = plrPage,
        Logs        = logsPage,    Macros   = macroPage,
        Scripts     = scriptPage,  Settings = settingsPage,
        Decompiler  = decompPage,
}
    win.Visible = false
    self:Print("Adonis has been loaded.", T.Accent)
    self:Print("Toggle: "..self.Config.ToggleKey.Name.."  |  Prefix: "..Prefix, T.SubText)
    self:Print(string.rep("─", 52), Color3.fromRGB(55,55,55))
end
function Modules.AdonisPanel:Print(text, color)
    local T = self.Config.Theme
    local autoColor, rowBg = lineColor(text, T)
    color = color or autoColor or T.Text
    table.insert(self.State.TerminalLines, {Text=text, Color=color, RowBg=rowBg, Time=os.time()})
    if #self.State.TerminalLines > self.State.MaxLines then
        table.remove(self.State.TerminalLines, 1)
    end
    if not self.State.OutputScroll then return end
    local lbl = make("TextLabel", {
        Size=UDim2.new(1,-5,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=rowBg and 0.35 or 1,
        BackgroundColor3=rowBg or Color3.fromRGB(0,0,0),
        Text=text, TextColor3=color,
        Font=Enum.Font.Code, TextSize=self.Config.FontSize,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        LayoutOrder=#self.State.TerminalLines, ZIndex=2,
    }, self.State.OutputScroll)
    -- Left severity gutter bar
    local gutterColor = nil
    if rowBg then
        gutterColor = color
    elseif text:sub(1,1) == ">" then
        gutterColor = T.Accent
    end
    if gutterColor then
        make("Frame", {
            Size=UDim2.new(0,2,1,0), Position=UDim2.new(0,0,0,0),
            BackgroundColor3=gutterColor, BorderSizePixel=0, ZIndex=3,
        }, lbl)
        make("UIPadding", {PaddingLeft=UDim.new(0,6)}, lbl)
    else
        make("UIPadding", {PaddingLeft=UDim.new(0,4)}, lbl)
    end
    if rowBg then corner(3, lbl) end
    lbl.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if setclipboard then
                pcall(setclipboard, text)
                self:_toast("Copied to clipboard", T.SubText)
            end
        end
    end)
    task.defer(function()
        if self.State.OutputScroll then
            self.State.OutputScroll.CanvasPosition = Vector2.new(0, math.huge)
        end
    end)
    local count = 0
    for _, c in ipairs(self.State.OutputScroll:GetChildren()) do
        if c:IsA("TextLabel") then count += 1 end
    end
    if count > self.State.MaxLines then
        for _, c in ipairs(self.State.OutputScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() break end
        end
    end
end
function Modules.AdonisPanel:_populateCommands(filter)
    if not self.State.CmdScroll then return end
    filter = filter and filter:lower() or ""
    local T = self.Config.Theme
    for _, c in ipairs(self.State.CmdScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then
            c:Destroy()
        end
    end
    self.State._cmdPool = {}
    local names = {}
    for name in pairs(Commands) do
        if filter == "" or name:lower():find(filter, 1, true) then
            table.insert(names, name)
        end
    end
    table.sort(names)
    for i, name in ipairs(names) do
        local row = make("TextButton", {
            Size        = UDim2.new(1,-5,0,22),
            BackgroundColor3 = i%2==0 and Color3.fromRGB(28,28,28) or Color3.fromRGB(34,34,34),
            BackgroundTransparency = 0.2, BorderSizePixel = 0,
            Text        = " "..Prefix..name,
            TextColor3  = T.Text,
            Font        = Enum.Font.SourceSans, TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i, ZIndex = 2,
        }, self.State.CmdScroll)
        corner(3, row)
        row:SetAttribute("CmdName", name)
        self.State._cmdPool[i] = row
        row.MouseButton1Click:Connect(function()
            self.State.InputBox.Text = row:GetAttribute("CmdName").." "
            self.State.InputBox:CaptureFocus()
            for _, p in pairs(self.State.Pages) do p.Visible = false end
            self.State.Pages.Terminal.Visible = true
        end)
    end
    if #names == 0 then
        make("TextLabel", {
            Size = UDim2.new(1,-5,0,22), BackgroundTransparency = 1,
            Text = " No commands found", TextColor3 = T.SubText,
            Font = Enum.Font.SourceSans, TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
        }, self.State.CmdScroll)
    end
end
function Modules.AdonisPanel:_populatePlayers()
    if not self.State.PlrScroll then return end
    for _, c in ipairs(self.State.PlrScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local T = self.Config.Theme
    local Players = game:GetService("Players")
    for i, plr in ipairs(Players:GetPlayers()) do
        local isLocal = plr == LocalPlayer
        local uid     = plr.UserId
        if not self.State.ESPEnabled[uid] then
            self.State.ESPEnabled[uid] = {Enabled=false, Color=Color3.fromRGB(255,50,50), Drawings={}}
        end
        local espData = self.State.ESPEnabled[uid]
        local row = make("Frame", {
            Size=UDim2.new(1,-5,0,56),
            BackgroundColor3=isLocal and Color3.fromRGB(30,40,30) or Color3.fromRGB(30,30,30),
            BackgroundTransparency=0.3, BorderSizePixel=0, LayoutOrder=i, ZIndex=2,
        }, self.State.PlrScroll)
        corner(0, row)
        local thumb = make("ImageLabel", {
            Size=UDim2.fromOffset(42,42), Position=UDim2.fromOffset(4,7),
            BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0,
            Image=("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png"):format(uid),
            ZIndex=3,
        }, row)
        corner(21, thumb)
        make("TextLabel", {
            Size=UDim2.new(1,-160,0,18), Position=UDim2.fromOffset(52,6),
            BackgroundTransparency=1,
            Text=plr.DisplayName..(isLocal and "  (you)" or ""),
            TextColor3=isLocal and T.Green or T.Text,
            Font=Enum.Font.SourceSansBold, TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
        }, row)
        make("TextLabel", {
            Size=UDim2.new(1,-160,0,14), Position=UDim2.fromOffset(52,24),
            BackgroundTransparency=1,
            Text="@"..plr.Name.."  |  "..tostring(uid),
            TextColor3=T.SubText, Font=Enum.Font.SourceSans, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
        }, row)
        if not isLocal then
            local espCheck = make("TextButton", {
                Size=UDim2.fromOffset(42,18), Position=UDim2.fromOffset(52,38),
                BackgroundColor3=espData.Enabled and T.Green or Color3.fromRGB(50,50,50),
                BackgroundTransparency=0.3, BorderSizePixel=0,
                Text=espData.Enabled and "ESP ON" or "ESP OFF",
                TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=10, ZIndex=4,
            }, row)
            corner(3, espCheck)
            espCheck.MouseButton1Click:Connect(function()
                espData.Enabled = not espData.Enabled
                espCheck.Text = espData.Enabled and "ESP ON" or "ESP OFF"
                espCheck.BackgroundColor3 = espData.Enabled and T.Green or Color3.fromRGB(50,50,50)
                self:_espUpdate()
            end)
            local espCols = {
                Color3.fromRGB(255,50,50),
                Color3.fromRGB(50,200,255),
                Color3.fromRGB(255,200,50),
                Color3.fromRGB(80,255,80),
            }
            for ci, col in ipairs(espCols) do
                local dot = make("TextButton", {
                    Size=UDim2.fromOffset(14,14),
                    Position=UDim2.fromOffset(98+(ci-1)*18, 40),
                    BackgroundColor3=col, BorderSizePixel=0, Text="", ZIndex=4,
                }, row)
                corner(7, dot)
                dot.MouseButton1Click:Connect(function()
                    espData.Color = col
                    if espData.Drawings and espData.Drawings.Box then
                        espData.Drawings.Box.Color = col
                    end
                end)
            end
        end
        local function quickBtn(label, xOff, clr, cmd)
            local b = make("TextButton", {
                Size=UDim2.fromOffset(30,22), Position=UDim2.new(1,xOff,0,10),
                BackgroundColor3=clr, BackgroundTransparency=0.3, BorderSizePixel=0,
                Text=label, TextColor3=T.Text,
                Font=Enum.Font.SourceSansBold, TextSize=11, ZIndex=4,
            }, row)
            corner(3, b)
            b.MouseButton1Click:Connect(function()
                self:Print("> "..cmd.." "..plr.Name, T.Accent)
                processCommand(Prefix..cmd.." "..plr.Name)
            end)
        end
        quickBtn("TP",  -34, T.Blue, "tp me")
    end
end
function Modules.AdonisPanel:_populateLogs(filter)
    if not self.State.LogScroll then return end
    filter = filter and filter:lower() or ""
    for _, c in ipairs(self.State.LogScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local T = self.Config.Theme
    local lines = self.State.TerminalLines
    local results = {}
    if filter == "" then
        results = lines
    else
        local p1, p2 = {}, {}
        for _, line in ipairs(lines) do
            local t = line.Text:lower()
            if t == filter then table.insert(p1, line)
            elseif t:find(filter,1,true) then table.insert(p2, line) end
        end
        for _, v in ipairs(p1) do table.insert(results, v) end
        for _, v in ipairs(p2) do table.insert(results, v) end
    end
    for i, line in ipairs(results) do
        local timeStr = ""
        if self.State.ShowTimestamps and line.Time then
            timeStr = string.format("[%02d:%02d:%02d] ",
                math.floor(line.Time/3600)%24,
                math.floor(line.Time/60)%60,
                line.Time%60)
        end
        make("TextLabel", {
            Size=UDim2.new(1,-5,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=i%2==0 and 0.75 or 1,
            BackgroundColor3=Color3.fromRGB(35,35,35),
            Text=timeStr..line.Text, TextColor3=line.Color or T.Text,
            Font=Enum.Font.SourceSans, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
            LayoutOrder=i, ZIndex=2,
        }, self.State.LogScroll)
    end
    if #results == 0 then
        make("TextLabel", {
            Size=UDim2.new(1,-5,0,22), BackgroundTransparency=1,
            Text=filter~="" and " No matching logs" or " No logs yet",
            TextColor3=T.SubText, Font=Enum.Font.SourceSans,
            TextSize=14, TextXAlignment=Enum.TextXAlignment.Left,
        }, self.State.LogScroll)
    end
end
function Modules.AdonisPanel:_populateMacros()
    if not self.State.MacroScroll then return end
    for _, c in ipairs(self.State.MacroScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local T = self.Config.Theme
    local i = 0
    if not next(self.State.Macros) then
        make("TextLabel", {
            Size=UDim2.new(1,-5,0,22), BackgroundTransparency=1,
            Text=" No macros yet. Type alias → command below and hit +",
            TextColor3=T.SubText, Font=Enum.Font.SourceSans,
            TextSize=14, TextXAlignment=Enum.TextXAlignment.Left,
        }, self.State.MacroScroll)
        return
    end
    for alias, command in pairs(self.State.Macros) do
        i += 1
        local row = make("Frame", {
            Size=UDim2.new(1,-5,0,34),
            BackgroundColor3=i%2==0 and Color3.fromRGB(28,28,28) or Color3.fromRGB(34,34,34),
            BackgroundTransparency=0.2, BorderSizePixel=0, LayoutOrder=i, ZIndex=2,
        }, self.State.MacroScroll)
        corner(0, row)
        make("TextLabel", {
            Size=UDim2.new(0.28,0,1,0), Position=UDim2.fromOffset(8,0),
            BackgroundTransparency=1, Text=Prefix..alias, TextColor3=T.Accent,
            Font=Enum.Font.SourceSansBold, TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
        }, row)
        make("TextLabel", {
            Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0.28,12,0,0),
            BackgroundTransparency=1, Text="→ "..Prefix..command, TextColor3=T.SubText,
            Font=Enum.Font.SourceSans, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
        }, row)
        local delBtn = make("TextButton", {
            Size=UDim2.fromOffset(24,20), Position=UDim2.new(1,-30,0,7),
            BackgroundColor3=T.Red, BackgroundTransparency=0.4, BorderSizePixel=0,
            Text="✕", TextColor3=T.Text, Font=Enum.Font.SourceSansBold, TextSize=13, ZIndex=4,
        }, row)
        corner(3, delBtn)
        local capturedAlias = alias
        delBtn.MouseButton1Click:Connect(function()
            self.State.Macros[capturedAlias] = nil
            Commands[capturedAlias] = nil
            self:Print("Macro removed: "..capturedAlias, T.SubText)
            self:_populateMacros()
        end)
    end
end
function Modules.AdonisPanel:Show()
    if not self.State.Gui then self:_build() end
    self.State.Win.Visible = true
    self.State.Visible = true
    task.defer(function()
        if self.State.InputBox then self.State.InputBox:CaptureFocus() end
    end)
end
function Modules.AdonisPanel:Hide()
    if self.State.Win then self.State.Win.Visible = false end
    self.State.Visible = false
end
function Modules.AdonisPanel:Toggle()
    if self.State.Visible then self:Hide() else self:Show() end
end
local _origDoNotif = DoNotif
DoNotif = function(msg, duration, color)
    _origDoNotif(msg, duration, color)
    Modules.AdonisPanel:_toast(msg, Modules.AdonisPanel.Config.Theme.Yellow)
    if Modules.AdonisPanel.State.Gui then
        Modules.AdonisPanel:Print(msg, Modules.AdonisPanel.Config.Theme.Yellow)
    end
end
RegisterCommand({Name="apanel", Aliases={"adonis","console"}, Description="Toggle Adonis-style panel"}, function()
    Modules.AdonisPanel:Toggle()
end)
RegisterCommand({Name="panelclear", Aliases={"cls"}, Description="Clear panel terminal"}, function()
    if Modules.AdonisPanel.State.OutputScroll then
        for _, c in ipairs(Modules.AdonisPanel.State.OutputScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        Modules.AdonisPanel.State.TerminalLines = {}
        Modules.AdonisPanel:Print("Cleared.", Modules.AdonisPanel.Config.Theme.SubText)
    end
end)
RegisterCommand({Name="espoff", Aliases={}, Description="Disable all ESP"}, function()
    for uid, data in pairs(Modules.AdonisPanel.State.ESPEnabled) do
        data.Enabled = false
    end
    Modules.AdonisPanel:_espUpdate()
    Modules.AdonisPanel:Print("All ESP disabled.", Modules.AdonisPanel.Config.Theme.SubText)
end)
function Modules.AdonisPanel:_watchPlayer(plr)
    local T = self.Config.Theme
    local function onCharAdded(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        local function getKiller()
            local tag = hum:FindFirstChild("creator")
            if tag then
                local killer = tag.Value
                if killer and killer ~= "" then
                    if typeof(killer) == "Instance" and killer:IsA("Player") then
                        return killer.DisplayName.." (@"..killer.Name..")"
                    else
                        return tostring(killer)
                    end
                end
            end
            local weaponTag = hum:FindFirstChild("weapon")
            if weaponTag then return "weapon: "..tostring(weaponTag.Value) end
            return "unknown"
        end
        hum.Died:Connect(function()
            local killer = getKiller()
            local isLocal = plr == LocalPlayer
            local nameStr = isLocal
                and ("You ("..plr.DisplayName..")")
                or  (plr.DisplayName.." (@"..plr.Name..")")
            local msg = "☠ "..nameStr.." died  —  killer: "..killer
            local col = isLocal and T.Red or T.Yellow
            self:Print(msg, col)
            self:_toast(msg, col)
        end)
    end
    if plr.Character then onCharAdded(plr.Character) end
    plr.CharacterAdded:Connect(onCharAdded)
end
function Modules.AdonisPanel:_initDeathLogger()
    local Players = game:GetService("Players")
    for _, plr in ipairs(Players:GetPlayers()) do
        self:_watchPlayer(plr)
    end
    Players.PlayerAdded:Connect(function(plr)
        self:_watchPlayer(plr)
    end)
end
function Modules.AdonisPanel:Initialize()
    task.spawn(function()
        task.wait(1)
        self:_build()
        self:_initDeathLogger()
        task.spawn(function()
            local ok, err = pcall(function()
local function main()
	local ZukDecompile
	local prettyPrint
	local cleanOutput
	task.defer(function()
	local FLOAT_PRECISION = 7
	local Reader = {}
	function Reader.new(bytecode)
		local stream = buffer.fromstring(bytecode)
		local cursor = 0
		local blen   = buffer.len(stream)
		local self   = {}
		local function guard(n)
			if cursor + n > blen then
				error(string.format("Reader OOB: need %d byte(s) at offset %d (buf len %d)", n, cursor, blen), 2)
			end
		end
		function self:len()       return blen end
		function self:nextByte()
			guard(1); local r = buffer.readu8(stream, cursor); cursor += 1; return r
		end
		function self:nextSignedByte()
			guard(1); local r = buffer.readi8(stream, cursor); cursor += 1; return r
		end
		function self:nextBytes(count)
			local t = {}
			for i = 1, count do t[i] = self:nextByte() end
			return t
		end
		function self:nextChar()     return string.char(self:nextByte()) end
		function self:nextUInt32()
			guard(4); local r = buffer.readu32(stream, cursor); cursor += 4; return r
		end
		function self:nextInt32()
			guard(4); local r = buffer.readi32(stream, cursor); cursor += 4; return r
		end
		function self:nextFloat()
			guard(4); local r = buffer.readf32(stream, cursor); cursor += 4
			return tonumber(string.format("%0."..FLOAT_PRECISION.."f", r))
		end
		function self:nextVarInt()
			local result = 0
			for i = 0, 4 do
				local b = self:nextByte()
				result = bit32.bor(result, bit32.lshift(bit32.band(b, 0x7F), i * 7))
				if not bit32.btest(b, 0x80) then break end
			end
			return result
		end
		function self:nextString(slen)
			slen = slen or self:nextVarInt()
			if slen == 0 then return "" end
			guard(slen)
			local r = buffer.readstring(stream, cursor, slen); cursor += slen; return r
		end
		function self:nextDouble()
			guard(8); local r = buffer.readf64(stream, cursor); cursor += 8; return r
		end
		return self
	end
	function Reader:Set(fp) FLOAT_PRECISION = fp end
	local Strings = {
		SUCCESS              = "%s",
		TIMEOUT              = "-- DECOMPILER TIMEOUT",
		COMPILATION_FAILURE  = "-- SCRIPT FAILED TO COMPILE, ERROR:\n%s",
		UNSUPPORTED_LBC_VERSION = "-- PASSED BYTECODE IS TOO OLD AND IS NOT SUPPORTED",
		USED_GLOBALS         = "-- USED GLOBALS: %s.\n",
		DECOMPILER_REMARK    = "-- DECOMPILER REMARK: %s\n",
	}
	local CASE_MULTIPLIER = 227
	local Luau = {
		OpCode = {
			{name="NOP",type="none"},{name="BREAK",type="none"},
			{name="LOADNIL",type="A"},{name="LOADB",type="ABC"},
			{name="LOADN",type="AsD"},{name="LOADK",type="AD"},
			{name="MOVE",type="AB"},
			{name="GETGLOBAL",type="AC",aux=true},{name="SETGLOBAL",type="AC",aux=true},
			{name="GETUPVAL",type="AB"},{name="SETUPVAL",type="AB"},
			{name="CLOSEUPVALS",type="A"},
			{name="GETIMPORT",type="AD",aux=true},
			{name="GETTABLE",type="ABC"},{name="SETTABLE",type="ABC"},
			{name="GETTABLEKS",type="ABC",aux=true},{name="SETTABLEKS",type="ABC",aux=true},
			{name="GETTABLEN",type="ABC"},{name="SETTABLEN",type="ABC"},
			{name="NEWCLOSURE",type="AD"},{name="NAMECALL",type="ABC",aux=true},
			{name="CALL",type="ABC"},{name="RETURN",type="AB"},
			{name="JUMP",type="sD"},{name="JUMPBACK",type="sD"},
			{name="JUMPIF",type="AsD"},{name="JUMPIFNOT",type="AsD"},
			{name="JUMPIFEQ",type="AsD",aux=true},{name="JUMPIFLE",type="AsD",aux=true},
			{name="JUMPIFLT",type="AsD",aux=true},{name="JUMPIFNOTEQ",type="AsD",aux=true},
			{name="JUMPIFNOTLE",type="AsD",aux=true},{name="JUMPIFNOTLT",type="AsD",aux=true},
			{name="ADD",type="ABC"},{name="SUB",type="ABC"},{name="MUL",type="ABC"},
			{name="DIV",type="ABC"},{name="MOD",type="ABC"},{name="POW",type="ABC"},
			{name="ADDK",type="ABC"},{name="SUBK",type="ABC"},{name="MULK",type="ABC"},
			{name="DIVK",type="ABC"},{name="MODK",type="ABC"},{name="POWK",type="ABC"},
			{name="AND",type="ABC"},{name="OR",type="ABC"},
			{name="ANDK",type="ABC"},{name="ORK",type="ABC"},
			{name="CONCAT",type="ABC"},
			{name="NOT",type="AB"},{name="MINUS",type="AB"},{name="LENGTH",type="AB"},
			{name="NEWTABLE",type="AB",aux=true},{name="DUPTABLE",type="AD"},
			{name="SETLIST",type="ABC",aux=true},
			{name="FORNPREP",type="AsD"},{name="FORNLOOP",type="AsD"},
			{name="FORGLOOP",type="AsD",aux=true},
			{name="FORGPREP_INEXT",type="A"},
			{name="FASTCALL3",type="ABC",aux=true},
			{name="FORGPREP_NEXT",type="A"},{name="NATIVECALL",type="none"},
			{name="GETVARARGS",type="AB"},{name="DUPCLOSURE",type="AD"},
			{name="PREPVARARGS",type="A"},{name="LOADKX",type="A",aux=true},
			{name="JUMPX",type="E"},{name="FASTCALL",type="AC"},
			{name="COVERAGE",type="E"},{name="CAPTURE",type="AB"},
			{name="SUBRK",type="ABC"},{name="DIVRK",type="ABC"},
			{name="FASTCALL1",type="ABC"},
			{name="FASTCALL2",type="ABC",aux=true},{name="FASTCALL2K",type="ABC",aux=true},
			{name="FORGPREP",type="AsD"},
			{name="JUMPXEQKNIL",type="AsD",aux=true},{name="JUMPXEQKB",type="AsD",aux=true},
			{name="JUMPXEQKN",type="AsD",aux=true},{name="JUMPXEQKS",type="AsD",aux=true},
			{name="IDIV",type="ABC"},{name="IDIVK",type="ABC"},
			{name="_COUNT",type="none"},
		},
		BytecodeTag = {
			LBC_VERSION_MIN=3, LBC_VERSION_MAX=6,
			LBC_TYPE_VERSION_MIN=1, LBC_TYPE_VERSION_MAX=3,
			LBC_CONSTANT_NIL=0, LBC_CONSTANT_BOOLEAN=1, LBC_CONSTANT_NUMBER=2,
			LBC_CONSTANT_STRING=3, LBC_CONSTANT_IMPORT=4, LBC_CONSTANT_TABLE=5,
			LBC_CONSTANT_CLOSURE=6, LBC_CONSTANT_VECTOR=7,
		},
		BytecodeType = {
			LBC_TYPE_NIL=0,LBC_TYPE_BOOLEAN=1,LBC_TYPE_NUMBER=2,LBC_TYPE_STRING=3,
			LBC_TYPE_TABLE=4,LBC_TYPE_FUNCTION=5,LBC_TYPE_THREAD=6,LBC_TYPE_USERDATA=7,
			LBC_TYPE_VECTOR=8,LBC_TYPE_BUFFER=9,LBC_TYPE_ANY=15,
			LBC_TYPE_TAGGED_USERDATA_BASE=64,LBC_TYPE_TAGGED_USERDATA_END=64+32,
			LBC_TYPE_OPTIONAL_BIT=bit32.lshift(1,7),LBC_TYPE_INVALID=256,
		},
		CaptureType  = {LCT_VAL=0,LCT_REF=1,LCT_UPVAL=2},
		BuiltinFunction = {
			LBF_NONE=0,LBF_ASSERT=1,LBF_MATH_ABS=2,LBF_MATH_ACOS=3,LBF_MATH_ASIN=4,
			LBF_MATH_ATAN2=5,LBF_MATH_ATAN=6,LBF_MATH_CEIL=7,LBF_MATH_COSH=8,
			LBF_MATH_COS=9,LBF_MATH_DEG=10,LBF_MATH_EXP=11,LBF_MATH_FLOOR=12,
			LBF_MATH_FMOD=13,LBF_MATH_FREXP=14,LBF_MATH_LDEXP=15,LBF_MATH_LOG10=16,
			LBF_MATH_LOG=17,LBF_MATH_MAX=18,LBF_MATH_MIN=19,LBF_MATH_MODF=20,
			LBF_MATH_POW=21,LBF_MATH_RAD=22,LBF_MATH_SINH=23,LBF_MATH_SIN=24,
			LBF_MATH_SQRT=25,LBF_MATH_TANH=26,LBF_MATH_TAN=27,
			LBF_BIT32_ARSHIFT=28,LBF_BIT32_BAND=29,LBF_BIT32_BNOT=30,LBF_BIT32_BOR=31,
			LBF_BIT32_BXOR=32,LBF_BIT32_BTEST=33,LBF_BIT32_EXTRACT=34,
			LBF_BIT32_LROTATE=35,LBF_BIT32_LSHIFT=36,LBF_BIT32_REPLACE=37,
			LBF_BIT32_RROTATE=38,LBF_BIT32_RSHIFT=39,LBF_TYPE=40,
			LBF_STRING_BYTE=41,LBF_STRING_CHAR=42,LBF_STRING_LEN=43,LBF_TYPEOF=44,
			LBF_STRING_SUB=45,LBF_MATH_CLAMP=46,LBF_MATH_SIGN=47,LBF_MATH_ROUND=48,
			LBF_RAWSET=49,LBF_RAWGET=50,LBF_RAWEQUAL=51,LBF_TABLE_INSERT=52,
			LBF_TABLE_UNPACK=53,LBF_VECTOR=54,LBF_BIT32_COUNTLZ=55,LBF_BIT32_COUNTRZ=56,
			LBF_SELECT_VARARG=57,LBF_RAWLEN=58,LBF_BIT32_EXTRACTK=59,
			LBF_GETMETATABLE=60,LBF_SETMETATABLE=61,LBF_TONUMBER=62,LBF_TOSTRING=63,
			LBF_BIT32_BYTESWAP=64,
			LBF_BUFFER_READI8=65,LBF_BUFFER_READU8=66,LBF_BUFFER_WRITEU8=67,
			LBF_BUFFER_READI16=68,LBF_BUFFER_READU16=69,LBF_BUFFER_WRITEU16=70,
			LBF_BUFFER_READI32=71,LBF_BUFFER_READU32=72,LBF_BUFFER_WRITEU32=73,
			LBF_BUFFER_READF32=74,LBF_BUFFER_WRITEF32=75,LBF_BUFFER_READF64=76,
			LBF_BUFFER_WRITEF64=77,
			LBF_VECTOR_MAGNITUDE=78,LBF_VECTOR_NORMALIZE=79,LBF_VECTOR_CROSS=80,
			LBF_VECTOR_DOT=81,LBF_VECTOR_FLOOR=82,LBF_VECTOR_CEIL=83,
			LBF_VECTOR_ABS=84,LBF_VECTOR_SIGN=85,LBF_VECTOR_CLAMP=86,
			LBF_VECTOR_MIN=87,LBF_VECTOR_MAX=88,
		},
		ProtoFlag = {
			LPF_NATIVE_MODULE  = bit32.lshift(1,0),
			LPF_NATIVE_COLD    = bit32.lshift(1,1),
			LPF_NATIVE_FUNCTION= bit32.lshift(1,2),
		},
	}
	function Luau:INSN_OP(i)  return bit32.band(i,0xFF) end
	function Luau:INSN_A(i)   return bit32.band(bit32.rshift(i,8),0xFF) end
	function Luau:INSN_B(i)   return bit32.band(bit32.rshift(i,16),0xFF) end
	function Luau:INSN_C(i)   return bit32.band(bit32.rshift(i,24),0xFF) end
	function Luau:INSN_D(i)   return bit32.rshift(i,16) end
	function Luau:INSN_sD(i)
		local D=self:INSN_D(i); return (D>0x7FFF and D<=0xFFFF) and (-(0xFFFF-D)-1) or D
	end
	function Luau:INSN_E(i)   return bit32.rshift(i,8) end
	function Luau:GetBaseTypeString(t, checkOpt)
		local BT=self.BytecodeType
		local tag=bit32.band(t,bit32.bnot(BT.LBC_TYPE_OPTIONAL_BIT))
		local names={[BT.LBC_TYPE_NIL]="nil",[BT.LBC_TYPE_BOOLEAN]="boolean",
			[BT.LBC_TYPE_NUMBER]="number",[BT.LBC_TYPE_STRING]="string",
			[BT.LBC_TYPE_TABLE]="table",[BT.LBC_TYPE_FUNCTION]="function",
			[BT.LBC_TYPE_THREAD]="thread",[BT.LBC_TYPE_USERDATA]="userdata",
			[BT.LBC_TYPE_VECTOR]="Vector3",[BT.LBC_TYPE_BUFFER]="buffer",
			[BT.LBC_TYPE_ANY]="any"}
		local r=names[tag] or "unknown"
		if checkOpt then
			r ..= (bit32.band(t,BT.LBC_TYPE_OPTIONAL_BIT)==0) and "" or "?"
		end
		return r
	end
	function Luau:GetBuiltinInfo(bfid)
		local BF=self.BuiltinFunction
		local map={
			[BF.LBF_NONE]="none",[BF.LBF_ASSERT]="assert",
			[BF.LBF_TYPE]="type",[BF.LBF_TYPEOF]="typeof",
			[BF.LBF_RAWSET]="rawset",[BF.LBF_RAWGET]="rawget",
			[BF.LBF_RAWEQUAL]="rawequal",[BF.LBF_RAWLEN]="rawlen",
			[BF.LBF_TABLE_UNPACK]="unpack",[BF.LBF_SELECT_VARARG]="select",
			[BF.LBF_GETMETATABLE]="getmetatable",[BF.LBF_SETMETATABLE]="setmetatable",
			[BF.LBF_TONUMBER]="tonumber",[BF.LBF_TOSTRING]="tostring",
			[BF.LBF_MATH_ABS]="math.abs",[BF.LBF_MATH_ACOS]="math.acos",
			[BF.LBF_MATH_ASIN]="math.asin",[BF.LBF_MATH_ATAN2]="math.atan2",
			[BF.LBF_MATH_ATAN]="math.atan",[BF.LBF_MATH_CEIL]="math.ceil",
			[BF.LBF_MATH_COSH]="math.cosh",[BF.LBF_MATH_COS]="math.cos",
			[BF.LBF_MATH_DEG]="math.deg",[BF.LBF_MATH_EXP]="math.exp",
			[BF.LBF_MATH_FLOOR]="math.floor",[BF.LBF_MATH_FMOD]="math.fmod",
			[BF.LBF_MATH_FREXP]="math.frexp",[BF.LBF_MATH_LDEXP]="math.ldexp",
			[BF.LBF_MATH_LOG10]="math.log10",[BF.LBF_MATH_LOG]="math.log",
			[BF.LBF_MATH_MAX]="math.max",[BF.LBF_MATH_MIN]="math.min",
			[BF.LBF_MATH_MODF]="math.modf",[BF.LBF_MATH_POW]="math.pow",
			[BF.LBF_MATH_RAD]="math.rad",[BF.LBF_MATH_SINH]="math.sinh",
			[BF.LBF_MATH_SIN]="math.sin",[BF.LBF_MATH_SQRT]="math.sqrt",
			[BF.LBF_MATH_TANH]="math.tanh",[BF.LBF_MATH_TAN]="math.tan",
			[BF.LBF_MATH_CLAMP]="math.clamp",[BF.LBF_MATH_SIGN]="math.sign",
			[BF.LBF_MATH_ROUND]="math.round",
			[BF.LBF_BIT32_ARSHIFT]="bit32.arshift",[BF.LBF_BIT32_BAND]="bit32.band",
			[BF.LBF_BIT32_BNOT]="bit32.bnot",[BF.LBF_BIT32_BOR]="bit32.bor",
			[BF.LBF_BIT32_BXOR]="bit32.bxor",[BF.LBF_BIT32_BTEST]="bit32.btest",
			[BF.LBF_BIT32_EXTRACT]="bit32.extract",[BF.LBF_BIT32_EXTRACTK]="bit32.extract",
			[BF.LBF_BIT32_LROTATE]="bit32.lrotate",[BF.LBF_BIT32_LSHIFT]="bit32.lshift",
			[BF.LBF_BIT32_REPLACE]="bit32.replace",[BF.LBF_BIT32_RROTATE]="bit32.rrotate",
			[BF.LBF_BIT32_RSHIFT]="bit32.rshift",[BF.LBF_BIT32_COUNTLZ]="bit32.countlz",
			[BF.LBF_BIT32_COUNTRZ]="bit32.countrz",[BF.LBF_BIT32_BYTESWAP]="bit32.byteswap",
			[BF.LBF_STRING_BYTE]="string.byte",[BF.LBF_STRING_CHAR]="string.char",
			[BF.LBF_STRING_LEN]="string.len",[BF.LBF_STRING_SUB]="string.sub",
			[BF.LBF_TABLE_INSERT]="table.insert",[BF.LBF_VECTOR]="Vector3.new",
			[BF.LBF_BUFFER_READI8]="buffer.readi8",[BF.LBF_BUFFER_READU8]="buffer.readu8",
			[BF.LBF_BUFFER_WRITEU8]="buffer.writeu8",[BF.LBF_BUFFER_READI16]="buffer.readi16",
			[BF.LBF_BUFFER_READU16]="buffer.readu16",[BF.LBF_BUFFER_WRITEU16]="buffer.writeu16",
			[BF.LBF_BUFFER_READI32]="buffer.readi32",[BF.LBF_BUFFER_READU32]="buffer.readu32",
			[BF.LBF_BUFFER_WRITEU32]="buffer.writeu32",[BF.LBF_BUFFER_READF32]="buffer.readf32",
			[BF.LBF_BUFFER_WRITEF32]="buffer.writef32",[BF.LBF_BUFFER_READF64]="buffer.readf64",
			[BF.LBF_BUFFER_WRITEF64]="buffer.writef64",
			[BF.LBF_VECTOR_MAGNITUDE]="vector.magnitude",[BF.LBF_VECTOR_NORMALIZE]="vector.normalize",
			[BF.LBF_VECTOR_CROSS]="vector.cross",[BF.LBF_VECTOR_DOT]="vector.dot",
			[BF.LBF_VECTOR_FLOOR]="vector.floor",[BF.LBF_VECTOR_CEIL]="vector.ceil",
			[BF.LBF_VECTOR_ABS]="vector.abs",[BF.LBF_VECTOR_SIGN]="vector.sign",
			[BF.LBF_VECTOR_CLAMP]="vector.clamp",[BF.LBF_VECTOR_MIN]="vector.min",
			[BF.LBF_VECTOR_MAX]="vector.max",
		}
		return map[bfid] or ("builtin#"..tostring(bfid))
	end
	do
		local raw = Luau.OpCode
		local encoded = {}
		for i, v in raw do
			local case = bit32.band((i-1)*CASE_MULTIPLIER, 0xFF)
			encoded[case] = v
		end
		Luau.OpCode = encoded
	end
	local DEFAULT_OPTIONS = {
		EnabledRemarks       = {ColdRemark=false, InlineRemark=true},
		DecompilerTimeout    = 10,
		DecompilerMode       = "disasm",
		ReaderFloatPrecision = 7,
		ShowDebugInformation = false,
		ShowInstructionLines = false,
		ShowOperationIndex   = false,
		ShowOperationNames   = false,
		ShowTrivialOperations= false,
		UseTypeInfo          = true,
		ListUsedGlobals      = true,
		ReturnElapsedTime    = false,
		CleanMode            = true,
	}
	local LuauCompileUserdataInfo = true
	pcall(function()
		local ok, r = pcall(function() return game:GetFastFlag("LuauCompileUserdataInfo") end)
		if ok then LuauCompileUserdataInfo = r end
	end)
	local LuauOpCode        = Luau.OpCode
	local LuauBytecodeTag   = Luau.BytecodeTag
	local LuauBytecodeType  = Luau.BytecodeType
	local LuauCaptureType   = Luau.CaptureType
	local LuauProtoFlag     = Luau.ProtoFlag
	local function toBoolean(v)      return v ~= 0 end
	local function toEscapedString(v)
		if type(v) == "string" then
			return string.format("%q", v)
		end
		return tostring(v)
	end
	local function formatIndexString(key)
		if type(key) == "string" and key:match("^[%a_][%w_]*$") then
			return "." .. key
		end
		return "[" .. toEscapedString(key) .. "]"
	end
	local function padLeft(v, ch, n)
		local s = tostring(v); return string.rep(ch, math.max(0, n-#s)) .. s
	end
	local function padRight(v, ch, n)
		local s = tostring(v); return s .. string.rep(ch, math.max(0, n-#s))
	end
	local ROBLOX_GLOBALS = {
		"game","workspace","script","plugin","settings","shared","UserSettings",
		"print","warn","error","assert","pcall","xpcall","require","select",
		"pairs","ipairs","next","unpack","type","typeof","tostring","tonumber",
		"setmetatable","getmetatable","rawset","rawget","rawequal","rawlen",
		"math","table","string","bit32","coroutine","os","utf8","task","buffer",
		"Instance","Enum","Vector3","Vector2","CFrame","Color3","BrickColor",
		"UDim","UDim2","Ray","Axes","Faces","NumberRange","NumberSequence",
		"ColorSequence","TweenInfo","RaycastParams","OverlapParams",
		"tick","time","wait","delay","spawn","_G","_VERSION",
	}
	local function isGlobal(key)
		for _, v in ipairs(ROBLOX_GLOBALS) do if v == key then return true end end
		return false
	end
	local function Decompile(bytecode, options)
		local bytecodeVersion, typeEncodingVersion
		Reader:Set(options.ReaderFloatPrecision)
		local reader = Reader.new(bytecode)
		local function disassemble()
			if bytecodeVersion >= 4 then
				typeEncodingVersion = reader:nextByte()
			end
			local stringTable = {}
			local function readStringTable()
				local n = reader:nextVarInt()
				for i = 1, n do stringTable[i] = reader:nextString() end
			end
			local userdataTypes = {}
			local function readUserdataTypes()
				if LuauCompileUserdataInfo then
					while true do
						local idx = reader:nextByte()
						if idx == 0 then break end
						userdataTypes[idx] = reader:nextVarInt()
					end
				end
			end
			local protoTable = {}
			local function readProtoTable()
				local n = reader:nextVarInt()
				for i = 1, n do
					local protoId = i - 1
					local proto = {
						id=protoId, instructions={}, constants={},
						captures={}, innerProtos={}, instructionLineInfo={},
					}
					protoTable[protoId] = proto
					proto.maxStackSize  = reader:nextByte()
					proto.numParams     = reader:nextByte()
					proto.numUpvalues   = reader:nextByte()
					proto.isVarArg      = toBoolean(reader:nextByte())
					if bytecodeVersion >= 4 then
						proto.flags = reader:nextByte()
						local resultTypedParams, resultTypedUpvalues, resultTypedLocals = {}, {}, {}
						local allTypeInfoSize = reader:nextVarInt()
						local hasTypeInfo = allTypeInfoSize > 0
						proto.hasTypeInfo = hasTypeInfo
						if hasTypeInfo then
							local totalTypedParams   = allTypeInfoSize
							local totalTypedUpvalues = 0
							local totalTypedLocals   = 0
							if typeEncodingVersion and typeEncodingVersion > 1 then
								totalTypedParams   = reader:nextVarInt()
								totalTypedUpvalues = reader:nextVarInt()
								totalTypedLocals   = reader:nextVarInt()
							end
							if totalTypedParams > 0 then
								resultTypedParams = reader:nextBytes(totalTypedParams)
								table.remove(resultTypedParams, 1)
								table.remove(resultTypedParams, 1)
							end
							for j = 1, totalTypedUpvalues do
								resultTypedUpvalues[j] = {type=reader:nextByte()}
							end
							for j = 1, totalTypedLocals do
								local lt  = reader:nextByte()
								local lr  = reader:nextByte()
								local lsp = reader:nextVarInt() + 1
								local lep = reader:nextVarInt() + lsp - 1
								resultTypedLocals[j] = {type=lt, register=lr, startPC=lsp}
							end
						end
						proto.typedParams   = resultTypedParams
						proto.typedUpvalues = resultTypedUpvalues
						proto.typedLocals   = resultTypedLocals
					end
					proto.sizeInstructions = reader:nextVarInt()
					for j = 1, proto.sizeInstructions do
						proto.instructions[j] = reader:nextUInt32()
					end
					proto.sizeConstants = reader:nextVarInt()
					for j = 1, proto.sizeConstants do
						local constType  = reader:nextByte()
						local constValue
						local BT = LuauBytecodeTag
						if constType == BT.LBC_CONSTANT_BOOLEAN then
							constValue = toBoolean(reader:nextByte())
						elseif constType == BT.LBC_CONSTANT_NUMBER then
							constValue = reader:nextDouble()
						elseif constType == BT.LBC_CONSTANT_STRING then
							constValue = stringTable[reader:nextVarInt()]
						elseif constType == BT.LBC_CONSTANT_IMPORT then
							local id = reader:nextUInt32()
							local idxCount = bit32.rshift(id, 30)
							local ci1 = bit32.band(bit32.rshift(id,20), 0x3FF)
							local ci2 = bit32.band(bit32.rshift(id,10), 0x3FF)
							local ci3 = bit32.band(id, 0x3FF)
							local tag = ""
							local function kv(idx) return proto.constants[idx+1] end
							if     idxCount == 1 then tag = tostring(kv(ci1) and kv(ci1).value or "")
							elseif idxCount == 2 then tag = tostring(kv(ci1) and kv(ci1).value or "")
								.."."..tostring(kv(ci2) and kv(ci2).value or "")
							elseif idxCount == 3 then tag = tostring(kv(ci1) and kv(ci1).value or "")
								.."."..tostring(kv(ci2) and kv(ci2).value or "")
								.."."..tostring(kv(ci3) and kv(ci3).value or "")
							end
							constValue = tag
						elseif constType == BT.LBC_CONSTANT_TABLE then
							local sz = reader:nextVarInt()
							local keys = {}
							for k = 1, sz do keys[k] = reader:nextVarInt()+1 end
							constValue = {size=sz, keys=keys}
						elseif constType == BT.LBC_CONSTANT_CLOSURE then
							constValue = reader:nextVarInt() + 1
						elseif constType == BT.LBC_CONSTANT_VECTOR then
							local x,y,z,w = reader:nextFloat(),reader:nextFloat(),reader:nextFloat(),reader:nextFloat()
							constValue = w == 0 and ("Vector3.new("..x..","..y..","..z..")")
								or ("vector.create("..x..","..y..","..z..","..w..")")
						end
						proto.constants[j] = {type=constType, value=constValue}
					end
					proto.sizeInnerProtos = reader:nextVarInt()
					for j = 1, proto.sizeInnerProtos do
						proto.innerProtos[j] = protoTable[reader:nextVarInt()]
					end
					proto.lineDefined = reader:nextVarInt()
					local nameId = reader:nextVarInt()
					proto.name = stringTable[nameId]
					local hasLineInfo = toBoolean(reader:nextByte())
					proto.hasLineInfo = hasLineInfo
					if hasLineInfo then
						local lgap = reader:nextByte()
						local baselineSize = bit32.rshift(proto.sizeInstructions-1, lgap)+1
						local smallLineInfo, absLineInfo = {}, {}
						local lastOffset, lastLine = 0, 0
						for j = 1, proto.sizeInstructions do
							local b = reader:nextSignedByte()
							lastOffset += b
							smallLineInfo[j] = lastOffset
						end
						for j = 1, baselineSize do
							local lc = lastLine + reader:nextInt32()
							absLineInfo[j-1] = lc
							lastLine = lc
						end
						local resultLineInfo = {}
						for j, line in ipairs(smallLineInfo) do
							local absIdx = bit32.rshift(j-1, lgap)
							local absLine = absLineInfo[absIdx]
							local rl = line + absLine
							if lgap <= 1 and (-line == absLine) then
								rl += absLineInfo[absIdx+1] or 0
							end
							if rl <= 0 then rl += 0x100 end
							resultLineInfo[j] = rl
						end
						proto.lineInfoSize = lgap
						proto.instructionLineInfo = resultLineInfo
					end
					local hasDebugInfo = toBoolean(reader:nextByte())
					proto.hasDebugInfo = hasDebugInfo
					if hasDebugInfo then
						local totalLocals = reader:nextVarInt()
						local debugLocals = {}
						for j = 1, totalLocals do
							debugLocals[j] = {
								name     = stringTable[reader:nextVarInt()],
								startPC  = reader:nextVarInt(),
								endPC    = reader:nextVarInt(),
								register = reader:nextByte(),
							}
						end
						proto.debugLocals = debugLocals
						local totalUpvals = reader:nextVarInt()
						local debugUpvalues = {}
						for j = 1, totalUpvals do
							debugUpvalues[j] = {name=stringTable[reader:nextVarInt()]}
						end
						proto.debugUpvalues = debugUpvalues
					end
				end
			end
			readStringTable()
			if bytecodeVersion and bytecodeVersion > 5 then readUserdataTypes() end
			readProtoTable()
			local mainProtoId = reader:nextVarInt()
			return mainProtoId, protoTable
		end
		local function organize()
			local mainProtoId, protoTable = disassemble()
			local mainProto = protoTable[mainProtoId]
			mainProto.main = true
			local registerActions = {}
			local function baseProto(proto)
				local protoRegisterActions = {}
				registerActions[proto.id] = {proto=proto, actions=protoRegisterActions}
				local instructions = proto.instructions
				local innerProtos  = proto.innerProtos
				local constants    = proto.constants
				local captures     = proto.captures
				local flags        = proto.flags
				local function collectCaptures(baseIdx, p)
					local nup = p.numUpvalues
					if nup > 0 then
						local _c = p.captures
						for j = 1, nup do
							local cap = instructions[baseIdx + j]
							local ctype = Luau:INSN_A(cap)
							local sreg  = Luau:INSN_B(cap)
							if ctype == LuauCaptureType.LCT_VAL or ctype == LuauCaptureType.LCT_REF then
								_c[j-1] = sreg
							elseif ctype == LuauCaptureType.LCT_UPVAL then
								_c[j-1] = captures[sreg]
							end
						end
					end
				end
				local function writeFlags()
					if type(flags) == "table" then return end
					local rawFlags = type(flags) == "number" and flags or 0
					local df = {}
					if proto.main then
						df.native = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_MODULE))
					else
						df.native = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_FUNCTION))
						df.cold   = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_COLD))
					end
					flags = df; proto.flags = df
				end
				local function writeInstructions()
					local auxSkip = false
					local function reg(act, regs, extra, hide)
						table.insert(protoRegisterActions, {
							usedRegisters=regs or {}, extraData=extra,
							opCode=act, hide=hide
						})
					end
					for idx, instruction in ipairs(instructions) do
						if auxSkip then auxSkip=false; continue end
						local oci = LuauOpCode[Luau:INSN_OP(instruction)]
						if not oci then continue end
						local opn  = oci.name
						local opt  = oci.type
						local isAux= oci.aux == true
						local A,B,C,sD,D,E,aux
						if     opt=="A"   then A=Luau:INSN_A(instruction)
						elseif opt=="E"   then E=Luau:INSN_E(instruction)
						elseif opt=="AB"  then A=Luau:INSN_A(instruction); B=Luau:INSN_B(instruction)
						elseif opt=="AC"  then A=Luau:INSN_A(instruction); C=Luau:INSN_C(instruction)
						elseif opt=="ABC" then A=Luau:INSN_A(instruction); B=Luau:INSN_B(instruction); C=Luau:INSN_C(instruction)
						elseif opt=="AD"  then A=Luau:INSN_A(instruction); D=Luau:INSN_D(instruction)
						elseif opt=="AsD" then A=Luau:INSN_A(instruction); sD=Luau:INSN_sD(instruction)
						elseif opt=="sD"  then sD=Luau:INSN_sD(instruction)
						end
						if isAux then
							auxSkip=true; reg(oci,nil,nil,true)
							aux=instructions[idx+1]
						end
						local st = not options.ShowTrivialOperations
						if opn=="NOP" or opn=="BREAK" or opn=="NATIVECALL" then reg(oci,nil,nil,st)
						elseif opn=="LOADNIL" then reg(oci,{A})
						elseif opn=="LOADB"   then reg(oci,{A},{B,C})
						elseif opn=="LOADN"   then reg(oci,{A},{sD})
						elseif opn=="LOADK"   then reg(oci,{A},{D})
						elseif opn=="MOVE"    then reg(oci,{A,B})
						elseif opn=="GETGLOBAL" or opn=="SETGLOBAL" then reg(oci,{A},{aux})
						elseif opn=="GETUPVAL" or opn=="SETUPVAL"  then reg(oci,{A},{B})
						elseif opn=="CLOSEUPVALS" then reg(oci,{A},nil,st)
						elseif opn=="GETIMPORT" then reg(oci,{A},{D,aux})
						elseif opn=="GETTABLE" or opn=="SETTABLE" then reg(oci,{A,B,C})
						elseif opn=="GETTABLEKS" or opn=="SETTABLEKS" then reg(oci,{A,B},{C,aux})
						elseif opn=="GETTABLEN" or opn=="SETTABLEN" then reg(oci,{A,B},{C})
						elseif opn=="NEWCLOSURE" then
							reg(oci,{A},{D})
							local p2=innerProtos[D+1]
							if p2 then collectCaptures(idx,p2); baseProto(p2) end
						elseif opn=="DUPCLOSURE" then
							reg(oci,{A},{D})
							local c=constants[D+1]
							if c then local p2=protoTable[c.value-1]; if p2 then collectCaptures(idx,p2); baseProto(p2) end end
						elseif opn=="NAMECALL"  then reg(oci,{A,B},{C,aux},st)
						elseif opn=="CALL"      then reg(oci,{A},{B,C})
						elseif opn=="RETURN"    then reg(oci,{A},{B})
						elseif opn=="JUMP" or opn=="JUMPBACK" then reg(oci,{},{sD})
						elseif opn=="JUMPIF" or opn=="JUMPIFNOT" then reg(oci,{A},{sD})
						elseif opn=="JUMPIFEQ" or opn=="JUMPIFLE" or opn=="JUMPIFLT"
						    or opn=="JUMPIFNOTEQ" or opn=="JUMPIFNOTLE" or opn=="JUMPIFNOTLT" then
							reg(oci,{A,aux},{sD})
						elseif opn=="ADD" or opn=="SUB" or opn=="MUL" or opn=="DIV"
						    or opn=="MOD" or opn=="POW" then reg(oci,{A,B,C})
						elseif opn=="ADDK" or opn=="SUBK" or opn=="MULK" or opn=="DIVK"
						    or opn=="MODK" or opn=="POWK" then reg(oci,{A,B},{C})
						elseif opn=="AND" or opn=="OR" then reg(oci,{A,B,C})
						elseif opn=="ANDK" or opn=="ORK" then reg(oci,{A,B},{C})
						elseif opn=="CONCAT" then
							local regs={A}
							for r=B,C do table.insert(regs,r) end
							reg(oci,regs)
						elseif opn=="NOT" or opn=="MINUS" or opn=="LENGTH" then reg(oci,{A,B})
						elseif opn=="NEWTABLE" then reg(oci,{A},{B,aux})
						elseif opn=="DUPTABLE" then reg(oci,{A},{D})
						elseif opn=="SETLIST"  then
							if C~=0 then
								local regs={A,B}
								for k=1,C-2 do table.insert(regs,A+k) end
								reg(oci,regs,{aux,C})
							else reg(oci,{A,B},{aux,C}) end
						elseif opn=="FORNPREP" then reg(oci,{A,A+1,A+2},{sD})
						elseif opn=="FORNLOOP" then reg(oci,{A},{sD})
						elseif opn=="FORGLOOP" then
							local nv=bit32.band(aux or 0,0xFF)
							local regs={}
							for k=1,nv do table.insert(regs,A+k) end
							reg(oci,regs,{sD,aux})
						elseif opn=="FORGPREP_INEXT" or opn=="FORGPREP_NEXT" then reg(oci,{A,A+1})
						elseif opn=="FORGPREP"  then reg(oci,{A},{sD})
						elseif opn=="GETVARARGS" then
							if B~=0 then
								local regs={A}
								for k=0,B-1 do table.insert(regs,A+k) end
								reg(oci,regs,{B})
							else reg(oci,{A},{B}) end
						elseif opn=="PREPVARARGS" then reg(oci,{},{A},st)
						elseif opn=="LOADKX"  then reg(oci,{A},{aux})
						elseif opn=="JUMPX"   then reg(oci,{},{E})
						elseif opn=="COVERAGE" then reg(oci,{},{E},st)
						elseif opn=="JUMPXEQKNIL" or opn=="JUMPXEQKB"
						    or opn=="JUMPXEQKN"   or opn=="JUMPXEQKS" then
							reg(oci,{A},{sD,aux})
						elseif opn=="CAPTURE" then reg(oci,nil,nil,st)
						elseif opn=="SUBRK" or opn=="DIVRK" then reg(oci,{A,C},{B})
						elseif opn=="IDIV"  then reg(oci,{A,B,C})
						elseif opn=="IDIVK" then reg(oci,{A,B},{C})
						elseif opn=="FASTCALL"  then reg(oci,{},{A,C},st)
						elseif opn=="FASTCALL1" then reg(oci,{B},{A,C},st)
						elseif opn=="FASTCALL2" then
							local r2=bit32.band(aux or 0,0xFF)
							reg(oci,{B,r2},{A,C},st)
						elseif opn=="FASTCALL2K" then reg(oci,{B},{A,C,aux},st)
						elseif opn=="FASTCALL3" then
							local r2=bit32.band(aux or 0,0xFF)
							local r3=bit32.rshift(r2,8)
							reg(oci,{B,r2,r3},{A,C},st)
						end
					end
				end
				writeFlags()
				writeInstructions()
			end
			baseProto(mainProto)
			return mainProtoId, registerActions, protoTable
		end
		local function finalize(mainProtoId, registerActions, protoTable)
			local finalResult = ""
			local totalParameters = 0
			local usedGlobals    = {}
			local usedGlobalsSet = {}
			local function isValidGlobal(key)
				if usedGlobalsSet[key] then return false end
				return not isGlobal(key)
			end
			local function processResult(res)
				local embed = ""
				if options.ListUsedGlobals and #usedGlobals > 0 then
					embed = string.format(Strings.USED_GLOBALS, table.concat(usedGlobals, ", "))
				end
				return embed .. res
			end
			if options.DecompilerMode == "disasm" then
				local resultParts = {}
				local function emit(s) resultParts[#resultParts + 1] = s end
				local function writeActions(protoActions)
					local actions  = protoActions.actions
					local proto    = protoActions.proto
					local lineInfo = proto.instructionLineInfo
					local inner    = proto.innerProtos
					local consts   = proto.constants
					local caps     = proto.captures
					local pflags   = proto.flags
					local numParams= proto.numParams
					local jumpMarkers = {}
					local function makeJump(idx) idx-=1; jumpMarkers[idx]=(jumpMarkers[idx] or 0)+1 end
					totalParameters += numParams
					if proto.main and pflags and pflags.native then emit("--!native\n") end
					local function buildRegNames(instrIdx)
						local names = {}
						if proto.debugLocals then
							for _, dl in ipairs(proto.debugLocals) do
								if instrIdx >= dl.startPC and instrIdx <= dl.endPC then
									names[dl.register] = dl.name
								end
							end
						end
						return names
					end
					local function fmtUpv(r)
						if r == nil then return "upv_unknown" end
						local du = proto.debugUpvalues
						if du then
							local entry = du[r + 1]
							if entry and entry.name and entry.name ~= "" then
								return entry.name
							end
						end
						local capturedReg = caps[r]
						if capturedReg ~= nil and proto.debugLocals then
							for _, dl in ipairs(proto.debugLocals) do
								if dl.register == capturedReg and dl.name and dl.name ~= "" then
									return dl.name
								end
							end
						end
						return "upv_" .. tostring(r)
					end
					local regNameCache = {}
					local function fmtReg(r, instrIdx)
						if instrIdx and proto.debugLocals then
							local cached = regNameCache[instrIdx]
							if not cached then
								cached = buildRegNames(instrIdx)
								regNameCache[instrIdx] = cached
							end
							if cached[r] and cached[r] ~= "" then
								return cached[r]
							end
						end
						local pr = r+1
						if pr < numParams+1 then
							return "p"..((totalParameters-numParams)+pr)
						end
						return "v"..(r-numParams)
					end
					local function paramName(j)
						if proto.debugLocals then
							for _, dl in ipairs(proto.debugLocals) do
								if dl.startPC == 0 and dl.register == j-1 then
									return dl.name
								end
							end
						end
						return "p"..(totalParameters+j)
					end
					local function fmtConst(k)
						if not k then return "nil" end
						if k.type == LuauBytecodeTag.LBC_CONSTANT_VECTOR then
							return tostring(k.value)
						end
						if type(tonumber(k.value))=="number" then
							return tostring(tonumber(string.format("%0."..options.ReaderFloatPrecision.."f", k.value)))
						end
						local s = toEscapedString(k.value)
						if k.type == LuauBytecodeTag.LBC_CONSTANT_IMPORT then
							s = s:gsub("%.%.+", ".")
							s = s:gsub("^%.", "")
							s = s:gsub("%.$", "")
						end
						return s
					end
					local function fmtProto(p)
						local body=""
						if p.flags and p.flags.native then
							if p.flags.cold and options.EnabledRemarks.ColdRemark then
								body ..= string.format(Strings.DECOMPILER_REMARK,
									"This function is marked cold and is not compiled natively")
							end
							body ..= "@native "
						end
						if p.name then body="local function "..p.name
						else body="function" end
						body ..= "("
						for j=1,p.numParams do
							local pb=paramName(j)
							if p.hasTypeInfo and options.UseTypeInfo and p.typedParams and p.typedParams[j] then
								pb ..= ": "..Luau:GetBaseTypeString(p.typedParams[j],true)
							end
							if j~=p.numParams then pb ..= ", " end
							body ..= pb
						end
						if p.isVarArg then
							body ..= (p.numParams>0) and ", ..." or "..."
						end
						body ..= ")\n"
						if options.ShowDebugInformation then
							body ..= "-- proto pool id: "..p.id.."\n"
							body ..= "-- num upvalues: "..p.numUpvalues.."\n"
							body ..= "-- num inner protos: "..(p.sizeInnerProtos or 0).."\n"
							body ..= "-- size instructions: "..(p.sizeInstructions or 0).."\n"
							body ..= "-- size constants: "..(p.sizeConstants or 0).."\n"
							body ..= "-- lineinfo gap: "..(p.lineInfoSize or "n/a").."\n"
							body ..= "-- max stack size: "..p.maxStackSize.."\n"
							body ..= "-- is typed: "..tostring(p.hasTypeInfo).."\n"
						end
						return body
					end
					local function writeProto(reg, p)
						local body=fmtProto(p)
						if p.name then
							emit("\n"..body)
							writeActions(registerActions[p.id])
							if not options.CleanMode then
								emit("end\n"..fmtReg(reg).." = "..p.name)
							else
								emit("end")
							end
						else
							emit(fmtReg(reg).." = "..body)
							writeActions(registerActions[p.id])
							emit("end")
						end
					end
					local CLEAN_SUPPRESS = {
						CLOSEUPVALS=true, PREPVARARGS=true, COVERAGE=true,
						CAPTURE=true, FASTCALL=true, FASTCALL1=true,
						FASTCALL2=true, FASTCALL2K=true, FASTCALL3=true,
						JUMPX=true, NOP=true, JUMPBACK=true,
					}
					for i, action in ipairs(actions) do
						if action.hide then continue end
						local ur  = action.usedRegisters
						local ed  = action.extraData
						local oci = action.opCode
						if not oci then continue end
						local opn = oci.name
						if options.CleanMode and CLEAN_SUPPRESS[opn] then continue end
						if options.CleanMode and opn == "RETURN" then
							local b = ed and ed[1] or 0
							if b == 1 then continue end
						end
						if options.CleanMode and opn == "MOVE" and
						   i > 1 and actions[i-1] and
						   (actions[i-1].opCode.name == "NEWCLOSURE" or
						    actions[i-1].opCode.name == "DUPCLOSURE") then
							continue
						end
						local function R(r) return fmtReg(r, i) end
						local function handleJumps()
							local n = jumpMarkers[i]
							if n then
								jumpMarkers[i]=nil
							for _=1,n do emit("end\n") end
							end
						end
						if not options.CleanMode then
							if options.ShowOperationIndex then
								emit("["..padLeft(i,"0",3).."] ")
							end
							if options.ShowInstructionLines and lineInfo and lineInfo[i] then
								emit(":"..padLeft(lineInfo[i],"0",3)..":")
							end
							if options.ShowOperationNames then
								emit(padRight(opn," ",15))
							end
						end
						if opn=="LOADNIL" then emit(R(ur[1]).." = nil")
						elseif opn=="LOADB" then
							emit(R(ur[1]).." = "..toEscapedString(toBoolean(ed[1])))
							if ed[2]~=0 then emit(" +"..ed[2]) end
						elseif opn=="LOADN" then emit(R(ur[1]).." = "..ed[1])
						elseif opn=="LOADK" then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]))
						elseif opn=="MOVE"  then emit(R(ur[1]).." = "..R(ur[2]))
						elseif opn=="GETGLOBAL" then
							local gk=tostring(consts[ed[1]+1] and consts[ed[1]+1].value or "")
							if options.ListUsedGlobals and isValidGlobal(gk) then
								table.insert(usedGlobals,gk); usedGlobalsSet[gk]=true
							end
							emit(R(ur[1]).." = "..gk)
						elseif opn=="SETGLOBAL" then
							local gk=tostring(consts[ed[1]+1] and consts[ed[1]+1].value or "")
							if options.ListUsedGlobals and isValidGlobal(gk) then
								table.insert(usedGlobals,gk); usedGlobalsSet[gk]=true
							end
							emit(gk.." = "..R(ur[1]))
						elseif opn=="GETUPVAL" then
							local slot = ed[1]
							local resolvedCap = caps[slot]
							emit(R(ur[1]).." = "..fmtUpv(resolvedCap))
						elseif opn=="SETUPVAL" then
							local slot = ed[1]
							local resolvedCap = caps[slot]
							emit(fmtUpv(resolvedCap).." = "..R(ur[1]))
						elseif opn=="CLOSEUPVALS" then emit("-- clear captures from back until: "..ur[1])
						elseif opn=="GETIMPORT" then
							local imp=tostring(consts[ed[1]+1] and consts[ed[1]+1].value or "")
							imp = imp:gsub("%.%.+", "."):gsub("^%.", ""):gsub("%.$", "")
							local totalIdx = bit32.rshift(ed[2] or 0, 30)
							if totalIdx==1 and options.ListUsedGlobals and isValidGlobal(imp) then
								table.insert(usedGlobals,imp); usedGlobalsSet[imp]=true
							end
							emit(R(ur[1]).." = "..imp)
						elseif opn=="GETTABLE" then
							emit(R(ur[1]).." = "..R(ur[2]).."["..R(ur[3]).."]")
						elseif opn=="SETTABLE" then
							emit(R(ur[2]).."["..R(ur[3]).."] = "..R(ur[1]))
						elseif opn=="GETTABLEKS" then
							local key = consts[ed[2]+1] and consts[ed[2]+1].value
							emit(R(ur[1]).." = "..R(ur[2])..formatIndexString(key))
						elseif opn=="SETTABLEKS" then
							local key = consts[ed[2]+1] and consts[ed[2]+1].value
							emit(R(ur[2])..formatIndexString(key).." = "..R(ur[1]))
						elseif opn=="GETTABLEN" then
							emit(R(ur[1]).." = "..R(ur[2]).."["..(ed[1]+1).."]")
						elseif opn=="SETTABLEN" then
							emit(R(ur[2]).."["..(ed[1]+1).."] = "..R(ur[1]))
						elseif opn=="NEWCLOSURE" then
							local p2=inner[ed[1]+1]; if p2 then writeProto(ur[1],p2) end
						elseif opn=="DUPCLOSURE" then
							local c=consts[ed[1]+1]
							if c then
								local p2=protoTable[c.value-1]; if p2 then writeProto(ur[1],p2) end
							end
						elseif opn=="NAMECALL" then
							local method=tostring(consts[ed[2]+1] and consts[ed[2]+1].value or "")
							emit("-- :"..method)
						elseif opn=="CALL" then
							local baseR=ur[1]
							local nArgs=ed[1]-1; local nRes=ed[2]-1
							local nmMethod=""; local argOff=0
							local prev=actions[i-1]
							if prev and prev.opCode and prev.opCode.name=="NAMECALL" then
								nmMethod=":"..tostring(consts[prev.extraData[2]+1] and consts[prev.extraData[2]+1].value or "")
								nArgs-=1; argOff+=1
							end
							local callBody=""
							if nRes==-1 then callBody="... = "
							elseif nRes>0 then
								local rb=""
								for k=1,nRes do
									rb..=R(baseR+k-1)
									if k~=nRes then rb..=", " end
								end
								callBody=rb.." = "
							end
							callBody ..= R(baseR)..nmMethod.."("
							if nArgs==-1 then callBody..="..."
							elseif nArgs>0 then
								local ab=""
								for k=1,nArgs do
									ab..=R(baseR+k+argOff)
									if k~=nArgs then ab..=", " end
								end
								callBody..=ab
							end
							callBody..=")"
							emit(callBody)
						elseif opn=="RETURN" then
							local baseR=ur[1]; local tot=ed[1]-2
							local rb=""
							if tot==-2 then rb=" "..R(baseR)..", ..."
							elseif tot>-1 then
								rb=" "
								for k=0,tot do
									rb..=R(baseR+k)
									if k~=tot then rb..=", " end
								end
							end
							emit("return"..rb)
						elseif opn=="JUMP" then emit("-- jump to #"..(i+ed[1]))
						elseif opn=="JUMPBACK" then emit("-- jump back to #"..(i+ed[1]+1))
						elseif opn=="JUMPIF" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if not "..R(ur[1]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOT" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." then -- goto #"..ei)
						elseif opn=="JUMPIFEQ" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." == "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFLE" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." >= "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFLT" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." > "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOTEQ" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." ~= "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOTLE" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." <= "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOTLT" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." < "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="ADD"  then emit(R(ur[1]).." = "..R(ur[2]).." + "..R(ur[3]))
						elseif opn=="SUB"  then emit(R(ur[1]).." = "..R(ur[2]).." - "..R(ur[3]))
						elseif opn=="MUL"  then emit(R(ur[1]).." = "..R(ur[2]).." * "..R(ur[3]))
						elseif opn=="DIV"  then emit(R(ur[1]).." = "..R(ur[2]).." / "..R(ur[3]))
						elseif opn=="MOD"  then emit(R(ur[1]).." = "..R(ur[2]).." % "..R(ur[3]))
						elseif opn=="POW"  then emit(R(ur[1]).." = "..R(ur[2]).." ^ "..R(ur[3]))
						elseif opn=="ADDK" then emit(R(ur[1]).." = "..R(ur[2]).." + "..fmtConst(consts[ed[1]+1]))
						elseif opn=="SUBK" then emit(R(ur[1]).." = "..R(ur[2]).." - "..fmtConst(consts[ed[1]+1]))
						elseif opn=="MULK" then emit(R(ur[1]).." = "..R(ur[2]).." * "..fmtConst(consts[ed[1]+1]))
						elseif opn=="DIVK" then emit(R(ur[1]).." = "..R(ur[2]).." / "..fmtConst(consts[ed[1]+1]))
						elseif opn=="MODK" then emit(R(ur[1]).." = "..R(ur[2]).." % "..fmtConst(consts[ed[1]+1]))
						elseif opn=="POWK" then emit(R(ur[1]).." = "..R(ur[2]).." ^ "..fmtConst(consts[ed[1]+1]))
						elseif opn=="AND"  then emit(R(ur[1]).." = "..R(ur[2]).." and "..R(ur[3]))
						elseif opn=="OR"   then emit(R(ur[1]).." = "..R(ur[2]).." or "..R(ur[3]))
						elseif opn=="ANDK" then emit(R(ur[1]).." = "..R(ur[2]).." and "..fmtConst(consts[ed[1]+1]))
						elseif opn=="ORK"  then emit(R(ur[1]).." = "..R(ur[2]).." or "..fmtConst(consts[ed[1]+1]))
						elseif opn=="CONCAT" then
							local tgt=table.remove(ur,1)
							local cb=""
							for k,r in ipairs(ur) do
								cb..=fmtReg(r); if k~=#ur then cb..=" .. " end
							end
							emit(R(tgt).." = "..cb)
						elseif opn=="NOT"    then emit(R(ur[1]).." = not "..R(ur[2]))
						elseif opn=="MINUS"  then emit(R(ur[1]).." = -"..R(ur[2]))
						elseif opn=="LENGTH" then emit(R(ur[1]).." = #"..R(ur[2]))
						elseif opn=="NEWTABLE" then
							emit(R(ur[1]).." = {}")
							if options.ShowDebugInformation and ed[2] and ed[2]>0 then
								emit(" ")
							end
						elseif opn=="DUPTABLE" then
							local cv=consts[ed[1]+1]
							if cv and type(cv.value)=="table" then
								local tb="{"
								for k=1,cv.value.size do
									tb..=fmtConst(consts[cv.value.keys[k]])
									if k~=cv.value.size then tb..=", " end
								end
								emit(R(ur[1]).." = {} -- "..tb.."}")
							else emit(R(ur[1]).." = {}") end
						elseif opn=="SETLIST" then
							local tgt=ur[1]; local src=ur[2]
							local si=ed[1]; local vc=ed[2]
							if vc==0 then
								emit(R(tgt).."["..si.."] = [...]")
							else
								local tot2=#ur-1; local cb=""
								for k=1,tot2 do
									cb..=R(ur[k]).."["..(si+k-1).."] = "..R(src+k-1)
									if k~=tot2 then cb..="\n" end
								end
								emit(cb)
							end
						elseif opn=="FORNPREP" then
							emit("for "..R(ur[3]).." = "..R(ur[3])..", "..R(ur[1])..", "..R(ur[2]).." do -- end at #"..(i+ed[1]))
						elseif opn=="FORNLOOP" then
							emit("end -- iterate + jump to #"..(i+ed[1]))
						elseif opn=="FORGLOOP" then
							emit("end -- iterate + jump to #"..(i+ed[1]))
						elseif opn=="FORGPREP_INEXT" then
							local tr=ur[1]+1
							emit("for "..R(tr+2)..", "..R(tr+3).." in ipairs("..R(tr)..") do")
						elseif opn=="FORGPREP_NEXT" then
							local tr=ur[1]+1
							emit("for "..R(tr+2)..", "..R(tr+3).." in pairs("..R(tr)..") do")
						elseif opn=="FORGPREP" then
							local ei=i+ed[1]+2
							local ea=actions[ei]
							local vb=""
							if ea and ea.usedRegisters and #ea.usedRegisters > 0 then
								for k,r in ipairs(ea.usedRegisters) do
									vb..=fmtReg(r, ei); if k~=#ea.usedRegisters then vb..=", " end
								end
							else
								local baseReg = ur[1]
								local nVars = 2
								if ea and ea.extraData and ea.extraData[2] then
									nVars = math.max(1, bit32.band(ea.extraData[2], 0xFF))
								end
								local parts = {}
								for k = 1, nVars do
									parts[k] = fmtReg(baseReg + 2 + (k - 1), i)
								end
								vb = table.concat(parts, ", ")
							end
							emit("for "..vb.." in "..R(ur[1]).." do -- end at #"..ei)
						elseif opn=="GETVARARGS" then
							local vc2=ed[1]-1
							local rb=""
							if vc2==-1 then rb=R(ur[1])
							else
								for k=1,vc2 do
									rb..=R(ur[k]); if k~=vc2 then rb..=", " end
								end
							end
							emit(rb.." = ...")
						elseif opn=="PREPVARARGS" then emit("-- ... ; number of fixed args: "..ed[1])
						elseif opn=="LOADKX" then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]))
						elseif opn=="JUMPX"    then emit("-- jump to #"..(i+ed[1]))
						elseif opn=="COVERAGE" then emit("-- coverage ("..ed[1]..")")
						elseif opn=="JUMPXEQKNIL" then
							local rev=bit32.rshift(ed[2] or 0,0x1F)~=1
							local sign=rev and "~=" or "=="
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." "..sign.." nil then -- goto #"..ei)
						elseif opn=="JUMPXEQKB" then
							local val=tostring(toBoolean(bit32.band(ed[2] or 0,1)))
							local rev=bit32.rshift(ed[2] or 0,0x1F)~=1
							local sign=rev and "~=" or "=="
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." "..sign.." "..val.." then -- goto #"..ei)
						elseif opn=="JUMPXEQKN" or opn=="JUMPXEQKS" then
							local cidx=bit32.band(ed[2] or 0,0xFFFFFF)
							local val=fmtConst(consts[cidx+1])
							local rev=bit32.rshift(ed[2] or 0,0x1F)~=1
							local sign=rev and "~=" or "=="
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." "..sign.." "..val.." then -- goto #"..ei)
						elseif opn=="CAPTURE"  then emit("-- upvalue capture")
						elseif opn=="SUBRK"    then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]).." - "..R(ur[2]))
						elseif opn=="DIVRK"    then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]).." / "..R(ur[2]))
						elseif opn=="IDIV"     then emit(R(ur[1]).." = "..R(ur[2]).." // "..R(ur[3]))
						elseif opn=="IDIVK"    then emit(R(ur[1]).." = "..R(ur[2]).." // "..fmtConst(consts[ed[1]+1]))
						elseif opn=="FASTCALL" then emit("-- FASTCALL; "..Luau:GetBuiltinInfo(ed[1]).."()")
						elseif opn=="FASTCALL1" then emit("-- FASTCALL1; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..")")
						elseif opn=="FASTCALL2" then emit("-- FASTCALL2; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..", "..R(ur[2])..")")
						elseif opn=="FASTCALL2K" then
							emit("-- FASTCALL2K; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..", "..fmtConst(consts[(ed[3] or 0)+1])..")")
						elseif opn=="FASTCALL3" then
							emit("-- FASTCALL3; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..", "..R(ur[2])..", "..R(ur[3])..")")
						end
						emit("\n")
						handleJumps()
					end
				end
				writeActions(registerActions[mainProtoId])
				finalResult = processResult(table.concat(resultParts))
			else
				finalResult = processResult("-- one day..")
			end
			return finalResult
		end
		local function manager(proceed, issue)
			if proceed then
				local startTime = os.clock()
				local result
				local ok, res = pcall(function() return finalize(organize()) end)
				result = ok and res or ("-- RUNTIME ERROR:\n-- " .. tostring(res))
				if (os.clock() - startTime) >= options.DecompilerTimeout then
					return Strings.TIMEOUT
				end
				return string.format(Strings.SUCCESS, result)
			else
				if issue == "COMPILATION_FAILURE" then
					local len = reader:len()-1
					return string.format(Strings.COMPILATION_FAILURE, reader:nextString(len))
				elseif issue == "UNSUPPORTED_LBC_VERSION" then
					return Strings.UNSUPPORTED_LBC_VERSION
				end
			end
		end
		bytecodeVersion = reader:nextByte()
		if bytecodeVersion == 0 then
			return manager(false, "COMPILATION_FAILURE")
		elseif bytecodeVersion >= LuauBytecodeTag.LBC_VERSION_MIN
		   and bytecodeVersion <= LuauBytecodeTag.LBC_VERSION_MAX then
			return manager(true)
		else
			return manager(false, "UNSUPPORTED_LBC_VERSION")
		end
	end
	local CONST_TYPE = {
		[0]="nil",[1]="boolean",[2]="number(f64)",[3]="string",
		[4]="import",[5]="table",[6]="closure",[7]="number(f32)",[8]="number(i16)"
	}
	local function parseProto(p, stringTable, depth)
		local result = {
			depth=depth or 0, maxStack=p:nextByte(), numParams=p:nextByte(),
			numUpvals=p:nextByte(), isVararg=p:nextByte()~=0, flags=p:nextByte(),
			constants={}, protos={}, upvalues={}, debugName="", strings={}, imports={},
		}
		local typeSize = p:nextVarInt()
		if typeSize>0 then for _=1,typeSize do p:nextByte() end end
		local instrCount = p:nextVarInt()
		for _=1,instrCount do p:nextUInt32() end
		local constCount = p:nextVarInt()
		for i=1,constCount do
			local kind=p:nextByte()
			local name=CONST_TYPE[kind] or ("unknown("..kind..")")
			local value
			if     kind==0 then value="nil"
			elseif kind==1 then value=p:nextByte()~=0 and "true" or "false"
			elseif kind==2 then value=tostring(p:nextDouble())
			elseif kind==7 then value=tostring(p:nextFloat())
			elseif kind==8 then
				local lo,hi=p:nextByte(),p:nextByte()
				local n=lo+hi*256; if n>=32768 then n=n-65536 end; value=tostring(n)
			elseif kind==3 then
				local idx=p:nextVarInt()
				value=stringTable[idx] or ("<string #"..idx..">")
				table.insert(result.strings,value)
			elseif kind==4 then
				local id=p:nextUInt32()
				local k0=bit32.band(bit32.rshift(id,20),0x3FF)
				local k1=bit32.band(bit32.rshift(id,10),0x3FF)
				local k2=bit32.band(id,0x3FF)
				local parts={}
				for _,k in ipairs({k0,k1,k2}) do
					if stringTable[k] then table.insert(parts,stringTable[k]) end
				end
				value=table.concat(parts,"."); table.insert(result.imports,value)
			elseif kind==5 then
				local keys,ks=p:nextVarInt(),{}
				for _=1,keys do
					local kidx=p:nextVarInt(); table.insert(ks,stringTable[kidx] or "?")
				end
				value="{"..table.concat(ks,", ").."}"
			elseif kind==6 then value="<proto #"..p:nextVarInt()..">"
			else value="?" end
			table.insert(result.constants,{kind=name,value=value,index=i-1})
		end
		local protoCount=p:nextVarInt()
		for i=1,protoCount do
			local ok,inner=pcall(parseProto,p,stringTable,depth+1)
			table.insert(result.protos,ok and inner or {error=tostring(inner),depth=depth+1})
		end
		local hasLines=p:nextByte()
		if hasLines~=0 then
			local lgap=p:nextByte()
			local intervalCount=bit32.rshift(instrCount-1,lgap)+1
			for _=1,intervalCount do p:nextByte() end
			for _=1,instrCount do p:nextByte() end
		end
		local hasDebug=p:nextByte()
		if hasDebug~=0 then
			local nameIdx=p:nextVarInt()
			result.debugName=stringTable[nameIdx] or ""
			local lc=p:nextVarInt()
			for _=1,lc do p:nextVarInt();p:nextVarInt();p:nextVarInt();p:nextByte() end
			local uc=p:nextVarInt()
			for j=1,uc do
				local ui=p:nextVarInt()
				table.insert(result.upvalues,stringTable[ui] or ("upval_"..j))
			end
		end
		return result
	end
	local function parseBytecode(bytes)
		local reader2=Reader.new(bytes)
		local ver=reader2:nextByte()
		if ver==0 then return nil,"Compile error: "..reader2:nextString(reader2:len()-1) end
		local typesVer=reader2:nextByte()
		local stringCount=reader2:nextVarInt()
		local stringTable={}
		for i=1,stringCount do
			local len=reader2:nextVarInt(); stringTable[i]=reader2:nextString(len)
		end
		local protoCount=reader2:nextVarInt()
		local protos={}
		for i=1,protoCount do
			local ok,proto=pcall(parseProto,reader2,stringTable,0)
			table.insert(protos,ok and proto or {error=tostring(proto),depth=0})
		end
		local entryProto=reader2:nextVarInt()
		return {version=ver,typesVersion=typesVer,
			stringTable=stringTable,protos=protos,entryProto=entryProto}
	end
	local function buildReport(parsed, scriptName)
		local lines={}
		local function w(s) table.insert(lines,s or "") end
		w("_zukatechzukatech_zukatechzukatechhzukatech_")
		w("  code reconstructor — "..(scriptName or "unknown"))
		w("_zukatechzukatech_zukatechzukatechhzukatech_")
		w("  Luau version : "..parsed.version)
		w("  Types version: "..parsed.typesVersion)
		w("  Proto count  : "..#parsed.protos)
		w("  Entry proto  : #"..parsed.entryProto)
		w("  Strings total: "..#parsed.stringTable)
		w("")
		w("── STRING TABLE ─────────────────────────────────────")
		for i,s in ipairs(parsed.stringTable) do w(string.format("  [%3d] %q",i,s)) end
		w("")
		local function walkProto(proto,idx)
			if proto.error then w("  [Proto #"..idx.."] PARSE ERROR: "..proto.error); return end
			local ind=string.rep("  ",proto.depth+1)
			local dn=proto.debugName~="" and (" '"..proto.debugName.."'") or ""
			w(string.format("%s── Proto #%d%s",ind,idx,dn))
			w(string.format("%s   params=%d  upvals=%d  maxStack=%d  vararg=%s",
				ind,proto.numParams,proto.numUpvals,proto.maxStack,tostring(proto.isVararg)))
			if #proto.upvalues>0 then w(ind.."   Upvalues: "..table.concat(proto.upvalues,", ")) end
			if #proto.imports>0  then
				w(ind.."   Imports:")
				for _,imp in ipairs(proto.imports) do w(ind.."     "..imp) end
			end
			if #proto.strings>0  then
				w(ind.."   String literals:")
				for _,s in ipairs(proto.strings) do w(ind..'     "'..s..'"') end
			end
			if #proto.constants>0 then
				w(ind.."   All constants:")
				for _,c in ipairs(proto.constants) do
					w(string.format("%s     [%2d] %-14s %s",ind,c.index,c.kind,tostring(c.value)))
				end
			end
			w("")
			for i2,inner in ipairs(proto.protos) do walkProto(inner,i2) end
		end
		w("── PROTO TREE ───────────────────────────────────────")
		for i,proto in ipairs(parsed.protos) do walkProto(proto,i) end
		return table.concat(lines,"\n")
	end
	local function _ppImpl(text)
		local result = {}
		local depth  = 0
		local DEDENT_BEFORE      = { ["end"]=true, ["until"]=true }
		local INDENT_AFTER       = { ["then"]=true, ["do"]=true, ["repeat"]=true }
		local DEDENT_THEN_INDENT = { ["else"]=true, ["elseif"]=true }
		local function stripStrings(s)
			s = s:gsub('"[^"\\]*(?:\\.[^"\\]*)*"', '""')
			s = s:gsub("'[^'\\]*(?:\\.[^'\\]*)*'", "''")
			s = s:gsub("%-%-.*$", "")
			return s
		end
		local function firstWord(s)
			return (stripStrings(s):match("^%s*([%a_][%w_]*)")) or ""
		end
		local function containsOpener(s)
			local clean = stripStrings(s)
			local fw = clean:match("^%s*([%a_][%w_]*)")
			if fw == "elseif" or fw == "else" then return false end
			for w in clean:gmatch("[%a_][%w_]*") do
				if INDENT_AFTER[w] then return true end
				if w == "function" then return true end
			end
			return false
		end
		for line in (text .. "\n"):gmatch("[^\n]*\n") do
			local bare = line:gsub("\n$", "")
			if bare == "" then
				result[#result + 1] = "\n"; continue
			end
			local expr = bare:match("^%[%d+%]%s*:?%d*:?%s*%u[%u_]*%s+(.*)") or bare
			local kw = firstWord(expr)
			if DEDENT_THEN_INDENT[kw] then
				depth = math.max(0, depth - 1)
				result[#result + 1] = string.rep("    ", depth) .. bare .. "\n"
				depth += 1
			elseif DEDENT_BEFORE[kw] then
				depth = math.max(0, depth - 1)
				result[#result + 1] = string.rep("    ", depth) .. bare .. "\n"
			else
				result[#result + 1] = string.rep("    ", depth) .. bare .. "\n"
				if containsOpener(expr) then depth += 1 end
			end
		end
		return table.concat(result)
	end
	local function _coImpl(text)
		local rawLines = {}
		for line in (text .. "\n"):gmatch("[^\n]*\n") do
			rawLines[#rawLines + 1] = line:gsub("\n$", "")
		end
		local function escpat(s)
			return s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
		end
		local function nextNonBlank(start)
			local j = start
			while j <= #rawLines and (rawLines[j] == nil or rawLines[j]:match("^%s*$")) do
				j += 1
			end
			return j
		end
		local function tryCollapse(i)
			local line = rawLines[i]
			if line == nil then return false end
			local reg, lit = line:match('^%s*(v%d+) = (".-")%s*$')
			if not reg then reg, lit = line:match('^%s*(v%d+) = (%-?%d+%.?%d*)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = (true)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = (false)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = (nil)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = ([%a_][%w_%.]+)%s*$') end
			if not reg then return false end
			local j = nextNonBlank(i + 1)
			if j > #rawLines or rawLines[j] == nil then return false end
			local nextLine = rawLines[j]
			local ep = escpat(reg)
			local count = 0
			for _ in nextLine:gmatch(ep) do count += 1 end
			if count ~= 1 then return false end
			if nextLine:match("^%s*" .. ep .. "%s*=") then return false end
			for k = i + 1, j - 1 do
				local midLine = rawLines[k]
				if midLine and midLine:match("^%s*" .. ep .. "%s*=") then return false end
			end
			rawLines[j] = nextLine:gsub(ep, lit, 1)
			rawLines[i] = nil
			return true
		end
		for _ = 1, 8 do
			for i = 1, #rawLines do tryCollapse(i) end
		end
		local function tryFoldField(i)
			local line = rawLines[i]
			if not line then return false end
			local lreg, src, field = line:match('^%s*(v%d+) = (v%d+)%.([%a_][%w_]*)%s*$')
			if not lreg then
				lreg, src, field = line:match('^%s*(v%d+) = (v%d+)%[(.-)%]%s*$')
				if lreg then field = "[" .. field .. "]" else return false end
			else
				field = "." .. field
			end
			local j = nextNonBlank(i + 1)
			if j > #rawLines then return false end
			local nextLine = rawLines[j]
			local epSrc = escpat(src)
			local epReg = escpat(lreg)
			local count = 0
			for _ in nextLine:gmatch(epReg) do count += 1 end
			if count ~= 1 then return false end
			if nextLine:match("^%s*" .. epReg .. "%s*=") then return false end
			for k = i + 1, j - 1 do
				local midLine = rawLines[k]
				if midLine and midLine:match("^%s*" .. epSrc .. "%s*=") then return false end
			end
			if src:match("^upv_") then return false end
			rawLines[j] = nextLine:gsub(epReg, src .. field, 1)
			rawLines[i] = nil
			return true
		end
		for _ = 1, 6 do
			for i = 1, #rawLines do tryFoldField(i) end
		end
		local pass2 = {}
		for idx = 1, #rawLines do
			local line = rawLines[idx]
			if line == nil then continue end
			local stripped = line:match("^%s*(.-)%s*$")
			if stripped:match("^%-%- goto #%d+$") then continue end
			if stripped:match("^%-%- jump") then continue end
			line = line:gsub("%s*%-%- goto #%d+$", "")
			line = line:gsub("%s*%-%- end at #%d+$", "")
			line = line:gsub("%s*%-%- iterate %+ jump to #%d+$", "")
			pass2[#pass2 + 1] = line
		end
		local pass3 = {}
		local i = 1
		while i <= #pass2 do
			local line = pass2[i]
			local nxt  = pass2[i + 1]
			local s    = line and line:match("^%s*(.-)%s*$") or ""
			local isNilInit = s:match("^v%d+ = nil") ~= nil
			local nextIsFor = nxt and nxt:match("^%s*for%s+v%d+") ~= nil
			if isNilInit and nextIsFor then
				i += 1
			else
				pass3[#pass3 + 1] = line
				i += 1
			end
		end
		local seen = {}
		local pass4 = {}
		for _, line in ipairs(pass3) do
			local reg = line:match("^%s*(v%d+)%s*=")
			if reg and not seen[reg] then
				seen[reg] = true
				line = line:gsub("^(%s*)(v%d+%s*=)", "%1local %2", 1)
			end
			pass4[#pass4 + 1] = line
		end
		local final = {}
		local lastBlank = false
		for _, line in ipairs(pass4) do
			local isBlank = line:match("^%s*$") ~= nil
			if isBlank and lastBlank then continue end
			lastBlank = isBlank
			final[#final + 1] = line
		end
		return table.concat(final, "\n")
	end
		ZukDecompile = Decompile
		prettyPrint  = _ppImpl
		cleanOutput  = _coImpl
		getgenv()._ZUK_DECOMPILE    = Decompile
		getgenv()._ZUK_PRETTYPRINT  = _ppImpl
		getgenv()._ZUK_CLEANOUTPUT  = _coImpl
	end)
end
main()
end)
if ok then
Modules.AdonisPanel:Print("ZukDecompile core loaded.", Modules.AdonisPanel.Config.Theme.Green)
else
Modules.AdonisPanel:Print("ZukDecompile load error: "..tostring(err), Modules.AdonisPanel.Config.Theme.Red)
end
end)
warn("[AdonisPanel] v2 Ready — "..self.Config.ToggleKey.Name.." or ;apanel")
end)
end
