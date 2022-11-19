local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Player = game:GetService('Players').LocalPlayer

local espLib = loadstring(game:HttpGet(('https://www.tsuyuri.tk/load/tabbyware/esp.lua')))()
espLib:Load()

local loadstart = tick()

local espLibrary = {
    drawings = {},
    instances = {},
    espCache = {},
    chamsCache = {},
    objectCache = {},
    conns = {},
    whitelist = {}, -- insert string that is the player's name you want to whitelist (turns esp color to whitelistColor in options)
    blacklist = {}, -- insert string that is the player's name you want to blacklist (removes player from esp)
    options = {
        enabled = false,
        minScaleFactorX = 1,
        maxScaleFactorX = 10,
        minScaleFactorY = 1,
        maxScaleFactorY = 10,
        boundingBox = false, -- WARNING | Significant Performance Decrease when true
        boundingBoxDescending = true,
        font = 2,
        fontSize = 13,
        limitDistance = false,
        maxDistance = 1000,
        visibleOnly = false,
        AIM_TEAMCHECK = false,
        teamColor = false,
        fillColor = nil,
        whitelistColor = Color3.new(1, 0, 0),
        outOfViewArrows = false,
        outOfViewArrowsFilled = true,
        outOfViewArrowsSize = 25,
        outOfViewArrowsRadius = 100,
        outOfViewArrowsColor = Color3.new(1, 1, 1),
        outOfViewArrowsTransparency = 0.5,
        outOfViewArrowsOutline = true,
        outOfViewArrowsOutlineFilled = false,
        outOfViewArrowsOutlineColor = Color3.new(1, 1, 1),
        outOfViewArrowsOutlineTransparency = 1,
        names = false,
        nameTransparency = 1,
        nameColor = Color3.new(1, 1, 1),
        boxes = true,
        boxesTransparency = 1,
        boxesColor = Color3.new(1, 0, 0),
        boxFill = false,
        boxFillTransparency = 0.5,
        boxFillColor = Color3.new(1, 0, 0),
        healthBars = false,
        healthBarsSize = 1,
        healthBarsTransparency = 1,
        healthBarsColor = Color3.new(0, 1, 0),
        healthText = false,
        healthTextTransparency = 1,
        healthTextSuffix = "%",
        healthTextColor = Color3.new(1, 1, 1),
        distance = false,
        distanceTransparency = 1,
        distanceSuffix = " Studs",
        distanceColor = Color3.new(1, 1, 1),
        tracers = false,
        tracerTransparency = 1,
        tracerColor = Color3.new(1, 1, 1),
        tracerOrigin = "Bottom", -- Available [Mouse, Top, Bottom]
        chams = true,
        chamsFillColor = Color3.new(1, 0, 0),
        chamsFillTransparency = 0.5,
        chamsOutlineColor = Color3.new(),
        chamsOutlineTransparency = 0
    },
};

local SilentAimSettings = {
    Enabled = false,
    
    ClassName = "",
    ToggleKey = "RightAlt",
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- variables
getgenv().SilentAimSettings = Settings
local MainFileName = "perc"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible = true 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local fov_circle_outline = Drawing.new("Circle")
fov_circle_outline.Thickness = 1
fov_circle_outline.NumSides = 100
fov_circle_outline.Radius = 185
fov_circle_outline.Filled = false
fov_circle_outline.Visible = false
fov_circle_outline.ZIndex = 998
fov_circle_outline.Transparency = 1
fov_circle_outline.Color = Color3.fromRGB(0, 0, 0)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
end


--[[file handling]] do 
    if not isfolder(MainFileName) then 
        makefolder(MainFileName);
    end
    
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then 
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", "perc", tostring(game.PlaceId)))

-- functions
local function GetFiles() -- credits to the linoria lib for this function, listfiles returns the files full path and its annoying
	local out = {}
	for i = 1, #Files do
		local file = Files[i]
		if file:sub(-4) == '.lua' then
			-- i hate this but it has to be done ...

			local pos = file:find('.lua', 1, true)
			local start = pos

			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end

			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end
	
	return out
end

local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

loadstart = tick()

local Window = Library:CreateWindow({
    Title = 'perc - private | ' .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    Center = true, 
    AutoShow = true,
})

local Tabs = {
    Aim = Window:AddTab('Aim'),
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

--pasted from oreo.fun/lithium v2 
local MainBOX = Tabs.Aim:AddLeftGroupbox("Main") do
    MainBOX:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false});
    Options.aim_Enabled_KeyPicker:OnClick(function()
        SilentAimSettings.Enabled = not SilentAimSettings.Enabled
        
        Toggles.aim_Enabled.Value = SilentAimSettings.Enabled
        Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
        
        mouse_box.Visible = SilentAimSettings.Enabled
    end) 

    MainBOX:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
        SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
    end)
    MainBOX:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
        SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
    end)
    MainBOX:AddDropdown("TargetPart", {Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
        SilentAimSettings.TargetPart = Options.TargetPart.Value
    end)
    MainBOX:AddDropdown("Method", {Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
        "Raycast","FindPartOnRay",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRayWithIgnoreList",
        "Mouse.Hit/Target"
    }}):OnChanged(function() 
        SilentAimSettings.SilentAimMethod = Options.Method.Value 
    end)
    MainBOX:AddSlider('HitChance', {
        Text = 'Hit chance',
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 1,

        Compact = false,
    })
    Options.HitChance:OnChanged(function()
        SilentAimSettings.HitChance = Options.HitChance.Value
    end)
end

local FieldOfViewBOX = Tabs.Aim:AddLeftGroupbox("Field Of View") do
    FieldOfViewBOX:AddToggle("Visible", {Text = "Show FOV Circle"}):AddColorPicker("Color", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        fov_circle.Visible = Toggles.Visible.Value
        SilentAimSettings.FOVVisible = Toggles.Visible.Value
    end)
    FieldOfViewBOX:AddSlider("Radius", {Text = "FOV Circle Radius", Min = 0, Max = 360, Default = 130, Rounding = 0}):OnChanged(function()
        fov_circle.Radius = Options.Radius.Value
        SilentAimSettings.FOVRadius = Options.Radius.Value
    end)
    FieldOfViewBOX:AddToggle("MousePosition", {Text = "Show Silent Aim Target"}):AddColorPicker("MouseVisualizeColor", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        mouse_box.Visible = Toggles.MousePosition.Value 
        SilentAimSettings.ShowSilentAimTarget = Toggles.MousePosition.Value 
    end)
end

-- esp tab

local ESPTab = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPTab:AddToggle('ESP_MASTER', {
    Text = "Enabled",
    Default = false,
    Tooltip = "Toggles all ESP features"
})

ESPTab:AddToggle('ESP_OOVA', {
    Text = "Out Of View Arrows",
    Default = false,
    Tooltip = "Toggles out of view arrows"
}):AddColorPicker('ESP_OOVA_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Out Of View Arrows Color"
})

ESPTab:AddToggle('ESP_NAMES', {
    Text = "Names",
    Default = false,
    Tooltip = "Toggles names"
}):AddColorPicker('ESP_NAMES_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Names Color"
})

ESPTab:AddToggle('ESP_BOXES', {
    Text = "Boxes",
    Default = false,
    Tooltip = "Toggles boxes"
}):AddColorPicker('ESP_BOXES_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Boxes Color"
})

ESPTab:AddToggle('ESP_BOXFILL', {
    Text = "Box Fill",
    Default = false,
    Tooltip = "Toggles box fills"
}):AddColorPicker('ESP_BOXFILL_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Box Fill Color"
})

ESPTab:AddToggle('ESP_HEALTHBARS', {
    Text = "Healthbars",
    Default = false,
    Tooltip = "Toggles healthbars"
}):AddColorPicker('ESP_HEALTHBARS_COLOR', {
    Default = Color3.fromRGB(0, 255, 30),
    Title = "Healthbars Color"
})

ESPTab:AddToggle('ESP_HEALTHTEXT', {
    Text = "Health Text",
    Default = false,
    Tooltip = "Toggles health text"
}):AddColorPicker('ESP_HEALTHTEXT_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Health Text Color"
})

ESPTab:AddToggle('ESP_DISTANCE', {
    Text = "Distance",
    Default = false,
    Tooltip = "Toggles distance text"
}):AddColorPicker('ESP_DISTANCE_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Distance Text Color"
})

ESPTab:AddToggle('ESP_TRACERS', {
    Text = "Tracers",
    Default = false,
    Tooltip = "Toggles tracers"
}):AddColorPicker('ESP_TRACERS_COLOR', {
    Default = Color3.new(1, 1, 1),
    Title = "Tracers Color"
})

ESPTab:AddToggle('ESP_CHAMS', {
    Text = "Chams",
    Default = false,
    Tooltip = "Toggles chams"
}):AddColorPicker('ESP_CHAMS_FILLCOLOR', {
    Default = Color3.new(1, 0, 0),
    Title = "Chams Color"
}):AddColorPicker('ESP_CHAMS_OUTCOLOR', {
    Default = Color3.fromRGB(0, 0, 0),
    Title = "Chams Color"
})

Toggles.ESP_MASTER:OnChanged(function()
    espLib.options.enabled = Toggles.ESP_MASTER.Value
end)

Toggles.ESP_OOVA:OnChanged(function()
    espLib.options.outOfViewArrows = Toggles.ESP_OOVA.Value
end)

Toggles.ESP_NAMES:OnChanged(function()
    espLib.options.names = Toggles.ESP_NAMES.Value
end)

Toggles.ESP_BOXES:OnChanged(function()
    espLib.options.boxes = Toggles.ESP_BOXES.Value
end)

Toggles.ESP_BOXFILL:OnChanged(function()
    espLib.options.boxFill = Toggles.ESP_BOXFILL.Value
end)

Toggles.ESP_HEALTHBARS:OnChanged(function()
    espLib.options.healthBars = Toggles.ESP_HEALTHBARS.Value
end)

Toggles.ESP_HEALTHTEXT:OnChanged(function()
    espLib.options.healthText = Toggles.ESP_HEALTHTEXT.Value
end)

Toggles.ESP_DISTANCE:OnChanged(function()
    espLib.options.distance = Toggles.ESP_DISTANCE.Value
end)

Toggles.ESP_TRACERS:OnChanged(function()
    espLib.options.tracers = Toggles.ESP_TRACERS.Value
end)

Toggles.ESP_CHAMS:OnChanged(function()
    espLib.options.chams = Toggles.ESP_CHAMS.Value
end)

Options.ESP_OOVA_COLOR:OnChanged(function()
    espLib.options.outOfViewArrowsColor = Options.ESP_OOVA_COLOR.Value
end)

Options.ESP_NAMES_COLOR:OnChanged(function()
    espLib.options.nameColor = Options.ESP_NAMES_COLOR.Value
end)

Options.ESP_BOXES_COLOR:OnChanged(function()
    espLib.options.boxesColor = Options.ESP_BOXES_COLOR.Value
end)

Options.ESP_BOXFILL_COLOR:OnChanged(function()
    espLib.options.boxFillColor = Options.ESP_BOXFILL_COLOR.Value
end)

Options.ESP_HEALTHBARS_COLOR:OnChanged(function()
    espLib.options.healthBarsColor = Options.ESP_HEALTHBARS_COLOR.Value
end)

Options.ESP_HEALTHTEXT_COLOR:OnChanged(function()
    espLib.options.healthTextColor = Options.ESP_HEALTHTEXT_COLOR.Value
end)

Options.ESP_DISTANCE_COLOR:OnChanged(function()
    espLib.options.distanceColor = Options.ESP_DISTANCE_COLOR.Value
end)

Options.ESP_TRACERS_COLOR:OnChanged(function()
    espLib.options.tracerColor = Options.ESP_TRACERS_COLOR.Value
end)

Options.ESP_CHAMS_FILLCOLOR:OnChanged(function()
    espLib.options.chamsFillColor = Options.ESP_CHAMS_FILLCOLOR.Value
end)

Options.ESP_CHAMS_OUTCOLOR:OnChanged(function()
    espLib.options.chamsOutlineColor = Options.ESP_CHAMS_OUTCOLOR.Value
end)

local ESPExtras = Tabs.Visuals:AddRightGroupbox('Extras')

ESPExtras:AddToggle('ESP_OOVA_FILLED', {
    Text = "Arrows Filled",
    Default = false,
    Tooltip = "Makes the Out Of View Arrows filled"
})

ESPExtras:AddToggle('ESP_BOUNDING_BOX', {
    Text = "Bounding Box",
    Default = false,
    Tooltip = "Toggles bounding box for boxesp"
})

ESPExtras:AddToggle('ESP_TEAMCHECK', {
    Text = "Team Check",
    Default = false,
    Tooltip = "Toggles team check for esp"
})

Toggles.ESP_OOVA_FILLED:OnChanged(function()
    espLib.options.outOfViewArrowsFilled = Toggles.ESP_OOVA_FILLED.Value
end)

Toggles.ESP_BOUNDING_BOX:OnChanged(function()
    espLib.options.boundingBox = Toggles.ESP_BOUNDING_BOX.Value
end)

Toggles.ESP_TEAMCHECK:OnChanged(function()
    espLib.options.teamCheck = Toggles.ESP_TEAMCHECK.Value
end)


local SpamBox = Tabs.Misc:AddLeftGroupbox('Spam')
local ChatReq = game:GetService('ReplicatedStorage').DefaultChatSystemChatEvents.SayMessageRequest

local SpamType = nil
local SpamDelay = 2

SpamBox:AddToggle('SPAM_TOGGLE', {
    Text = "Enabled",
    Default = false,
    Tooltip = "Enables chat spam"
})

Toggles.SPAM_TOGGLE:OnChanged(function(v)
    _G.spam = v
    while true do   
        if not _G.spam and game.PlaceId ~= 286090429 then return end
        wait(SpamDelay)
        if SpamType == 'Drain Gang' then
            ChatReq:FireServer('Jraine gangg ⛓️🩸⛓️🩸 Jraine gangg ⛓️🩸⛓️🩸 Jraine gangg ⛓️🩸⛓️🩸 Jraine gangg ⛓️🩸⛓️🩸 Jraine gangg ⛓️🩸⛓️🩸 Jraine gangg ⛓️🩸⛓️🩸', 'All')
        elseif SpamType == 'Depot' then
            ChatReq:FireServer('If its a depot got a bite it🥶🥶🥶 If its a depot got a bite it🥶🥶🥶 If its a depot got a bite it🥶🥶🥶 If its a depot got a bite it🥶🥶🥶 If its a depot got a bite it🥶🥶🥶', 'All')
        elseif SpamType == 'Ambatukum' then
            ChatReq:FireServer('Amba tu k um 😭😭😭😭😭😭 Amba tu k um 😭😭😭😭😭😭 Amba tu k um 😭😭😭😭😭😭 Amba tu k um 😭😭😭😭😭😭 Amba tu k um 😭😭😭😭😭😭 Amba tu k um 😭😭😭😭😭😭 Amba tu k um 😭😭😭😭😭😭', 'All')
        elseif SpamType == 'Zaxbys' then
            ChatReq:FireServer('Theres free zax byys on the zax xbyys app rn. 😮😮😮😮😮Just make an account and check rewards. 🤑🤑🤑🤑If its not there then just reload the app. 😳😳😳😳 Theres free zax byys on the zax xbyys app rn. 😮😮😮😮😮', 'All')
        elseif SpamType == 'Private Application' then
            ChatReq:FireServer('plesae accept my scrip application... 🥺🥺🥺🥺🥺 plesae accept my scrip application... 🥺🥺🥺🥺🥺 plesae accept my scrip application... 🥺🥺🥺🥺🥺 plesae accept my scrip application... 🥺🥺🥺🥺🥺', 'All')
        elseif SpamType == 'Caprisun' then
            ChatReq:FireServer('caprisunhook on top real!!!! 😱😱😱😱😱 caprisunhook on top real!!!! 😱😱😱😱😱 caprisunhook on top real!!!! 😱😱😱😱😱 caprisunhook on top real!!!! 😱😱😱😱😱 caprisunhook on top real!!!! 😱😱😱😱😱', 'All')
        elseif SpamType == 'Gamesneeze Slander' then
            ChatReq:FireServer('CAPRISUN > GAMESNEEZE🤑 💸GAME "SNEEZE" BECAUSE SNEEZE WHEN SEE IT💸 BECAUSE ITS TRASH AND IM ALLERGIC TO TRASH🤑💸', 'All')
        end
    end
end)

SpamBox:AddDivider()

SpamBox:AddDropdown('SPAM_TYPE', {
    Values = { 'Drain Gang', 'Depot', 'Ambatukum', 'Zaxbys', 'Private Application', 'Caprisun', 'Gamesneeze Slander' },
    Default = 1, 
    Multi = false,
    Text = 'Spam Type',
    Tooltip = 'What the chatspam spams'
})

SpamBox:AddSlider('SPAM_DELAY', {
    Text = 'Spam Delay',
    Default = 2,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Tooltip = 'How fast the chatspam spams'
})

Options.SPAM_TYPE:OnChanged(function()
    SpamType = Options.SPAM_TYPE.Value
end)

Library:SetWatermarkVisibility(true)
Library:SetWatermark('perc | welcome, ' .. Player.Name .. ' | ' .. os.date("%x %X", os.time()))
Library.KeybindFrame.Visible = true;

function unloadAim()
    Toggles.aim_Enabled.Value = false
    fov_circle.Visible = false
    mouse_box.Visible = false
end

Library:OnUnload(function()
    Library.Unloaded = true
    unloadAim()
    espLib:Unload()
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
local MiscGroup = Tabs['UI Settings']:AddRightGroupbox('Misc')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' }) 
MenuGroup:AddToggle('MENU_KEYBIND_LIST', { Text = "Keybind List", Default = true, Tooltip = "Toggles the built-in keybind list" })
MenuGroup:AddToggle('MENU_WATERMARK', { Text = "Watermark", Default = true, Tooltip = "Toggles the built-in watermark" })
MenuGroup:AddToggle('MENU_RAINBOW', { Text = "Rainbow", Default = false, Tooltip = "Toggles rainbow ui color" })

--MiscGroup:AddToggle('MENU_')

-- written by kal fully

task.spawn(
    function()
        while game:GetService("RunService").RenderStepped:Wait() do
            if Toggles.MENU_RAINBOW.Value == true then
                local Registry = Window.Holder.Visible and Library.Registry or Library.HudRegistry

                for Idx, Object in next, Registry do
                    for Property, ColorIdx in next, Object.Properties do
                        if ColorIdx == "AccentColor" or ColorIdx == "AccentColorDark" then
                            local Instance = Object.Instance
                            local yPos = Instance.AbsolutePosition.Y

                            local Mapped = Library:MapValue(yPos, 0, 1080, 0, 0.3) / 0.45
                            local Color = Color3.fromHSV((Library.CurrentRainbowHue - Mapped) % 1, 0.59, 1)

                            if ColorIdx == "AccentColorDark" then
                                Color = Library:GetDarkerColor(Color)
                            end

                            Instance[Property] = Color
                        end
                    end
                end
            end
        end
    end
)

Toggles.MENU_KEYBIND_LIST:OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.MENU_KEYBIND_LIST.Value
end)

Toggles.MENU_WATERMARK:OnChanged(function(v)
    Library:SetWatermarkVisibility(v)
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:SetFolder('caprisun')
SaveManager:SetFolder('caprisun/uni')

SaveManager:BuildConfigSection(Tabs['UI Settings']) 

ThemeManager:ApplyToTab(Tabs['UI Settings'])

Toggles.MENU_RAINBOW:OnChanged(function()
    if not Toggles.MENU_RAINBOW.Value == true then
        ThemeManager.Library.FontColor = Options.FontColor.Value
		ThemeManager.Library.MainColor = Options.MainColor.Value
		ThemeManager.Library.AccentColor = Options.AccentColor.Value
		ThemeManager.Library.BackgroundColor = Options.BackgroundColor.Value
		ThemeManager.Library.OutlineColor = Options.OutlineColor.Value

		ThemeManager.Library.AccentColorDark = ThemeManager.Library:GetDarkerColor(ThemeManager.Library.AccentColor);
		ThemeManager.Library:UpdateColorsUsingRegistry()
    end
end)

local menu_time = math.floor((tick() - loadstart) * 1000)

Library:Notify('done loading the thug shaker cheat! (' .. menu_time .. 'ms)')
Library:Notify('rshift to toggle')

resume(create(function()
    RenderStepped:Connect(function()
        if Toggles.MousePosition.Value and Toggles.aim_Enabled.Value then
            if getClosestPlayer() then 
                local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
                -- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)
                
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
            else 
                mouse_box.Visible = false 
                mouse_box.Position = Vector2.new()
            end
        end
        
        if Toggles.Visible.Value then 
            fov_circle.Visible = Toggles.Visible.Value
            fov_circle.Color = Options.Color.Value
            fov_circle.Position = getMousePosition()
        end
    end)
end))

-- hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
        local HitPart = getClosestPlayer()
         
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return ((Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not Toggles.Prediction.Value and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then 
            return self.X 
        elseif Index == "Y" or Index == "y" then 
            return self.Y 
        elseif Index == "UnitRay" then 
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end
    end

    return oldIndex(self, Index)
end))

task.spawn(function()
    while task.wait(0.9) do
        Library:SetWatermark('caprisun | welcome, ' .. Player.Name .. ' | ' .. os.date("%x %X", os.time()))
    end
end)
