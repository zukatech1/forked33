lua = {
"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
"local", "return", "function", "export"
},
rbx = {
"game", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
"error", "warn", "tick", "assert", "shared", "loadstring", "tonumber", "tostring", "type",
"typeof", "unpack", "print", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo",
"collectgarbage", "not", "utf8", "pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs"
},
executor = {
"hookmetamethod", "hookfunction", "getgc", "filtergc", "Drawing", "getgenv", "getsenv", "getrenv", "getfenv", "setfenv",
"decompile", "saveinstance", "getrawmetatable", "setrawmetatable", "checkcaller", "cloneref", "clonefunction",
"iscclosure", "islclosure", "isexecutorclosure", "newcclosure", "getfunctionhash", "crypt", "writefile", "appendfile", "loadfile", "readfile", "listfiles",
"makefolder", "isfolder", "isfile", "delfile", "delfolder", "getcustomasset", "fireclickdetector", "firetouchinterest", "fireproximityprompt"
},
operators = {
"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">", ",", ".", "(", ")", "{", "}", "[", "]", ";", ":"
}
}
local colors = {
numbers = Color3.fromRGB(255, 198, 0),
boolean = Color3.fromRGB(255, 198, 0),
operator = Color3.fromRGB(204, 204, 204),
lua = Color3.fromRGB(132, 214, 247),
exploit = Color3.fromRGB(171, 84, 247),
rbx = Color3.fromRGB(248, 109, 124),
str = Color3.fromRGB(173, 241, 132),
comment = Color3.fromRGB(102, 102, 102),
null = Color3.fromRGB(255, 198, 0),
call = Color3.fromRGB(253, 251, 172),
self_call = Color3.fromRGB(253, 251, 172),
local_color = Color3.fromRGB(248, 109, 115),
function_color = Color3.fromRGB(248, 109, 115),
self_color = Color3.fromRGB(248, 109, 115),
local_property = Color3.fromRGB(97, 161, 241),
}
local function createKeywordSet(keywords)
    local keywordSet = {}
    for _, keyword in ipairs(keywords) do
        keywordSet[keyword] = true
    end
    return keywordSet
end
local luaSet = createKeywordSet(keywords.lua)
local exploitSet = createKeywordSet(keywords.exploit)
local rbxSet = createKeywordSet(keywords.rbx)
local operatorsSet = createKeywordSet(keywords.operators)
local function getHighlight(tokens, index)
    local token = tokens[index]
    if colors[token .. "_color"] then
        return colors[token .. "_color"]
    end
    if tonumber(token) then
        return colors.numbers
    elseif token == "nil" then
        return colors.null
    elseif token:sub(1, 2) == "--" then
        return colors.comment
    elseif operatorsSet[token] then
        return colors.operator
    elseif luaSet[token] then
        return colors.rbx
    elseif rbxSet[token] then
        return colors.lua
    elseif exploitSet[token] then
        return colors.exploit
    elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
        return colors.str
    elseif token == "true" or token == "false" then
        return colors.boolean
    end
    if tokens[index + 1] == "(" then
        if tokens[index - 1] == ":" then
            return colors.self_call
        end
        return colors.call
    end
    if tokens[index - 1] == "." then
        if tokens[index - 2] == "Enum" then
            return colors.rbx
        end
        return colors.local_property
    end
end
function highlighter.run(source)
    local tokens = {}
    local currentToken = ""
    local inString = false
    local inComment = false
    local commentPersist = false
    for i = 1, #source do
        local character = source:sub(i, i)
        if inComment then
            if character == "\n" and not commentPersist then
                table.insert(tokens, currentToken)
                table.insert(tokens, character)
                currentToken = ""
                inComment = false
            elseif source:sub(i - 1, i) == "]]" and commentPersist then
                currentToken .. = "]"
                table.insert(tokens, currentToken)
                currentToken = ""
                inComment = false
                commentPersist = false
            else
                currentToken = currentToken .. character
            end
        elseif inString then
            if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
                currentToken = currentToken .. character
                inString = false
            else
                currentToken = currentToken .. character
            end
        else
            if source:sub(i, i + 1) == "--" then
                table.insert(tokens, currentToken)
                currentToken = "-"
                inComment = true
                commentPersist = source:sub(i + 2, i + 3) == "[["
                elseif character == "\"" or character == "\'" then
                table.insert(tokens, currentToken)
                currentToken = character
                inString = character
                elseif operatorsSet[character] then
                table.insert(tokens, currentToken)
                table.insert(tokens, character)
                currentToken = ""
                elseif character:match("[%w_]") then
                currentToken = currentToken .. character
                else
                table.insert(tokens, currentToken)
                table.insert(tokens, character)
                currentToken = ""
                end
                end
                end
                table.insert(tokens, currentToken)
                local highlighted = {}
                for i, token in ipairs(tokens) do
                local highlight = getHighlight(tokens, i)
                if highlight then
                local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))
                table.insert(highlighted, syntax)
                else
                table.insert(highlighted, token)
                end
                end
                return table.concat(highlighted)
                end
              return highlighter
        end;
    };

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
local function colorToHex(c)
	return string.format("#%02x%02x%02x",
		math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end
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
local function hlTokenize(line)
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
local function hlDetect(tokens, idx)
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
	local tokens = hlTokenize(line)
	local out = ""
	for i, tok in ipairs(tokens) do
		local col = Syntax[hlDetect(tokens, i)] or Syntax.Text
		local safe = tok[1]:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
		out ..= string.format('<font color="%s">%s</font>', colorToHex(col), safe)
	end
	return out
end
