local b1 = game:GetService("Players")
local b2 = game:GetService("RunService")
local b3 = game:GetService("UserInputService")
local b4 = game:GetService("ReplicatedStorage")
local b5 = game:GetService("GuiService")
local b6 = game:GetService("Stats")
local b7 = game:GetService("Workspace")
local b8 = game:GetService("CoreGui")

local b9 = b1.LocalPlayer
local b10 = b7.CurrentCamera
local b11 = b9:GetMouse()

local Config = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.Delete,
    GUIToggleKey = Enum.KeyCode.RightShift,
    FOV = {
        Enabled = true,
        Radius = 120,
        Visible = true,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
        Transparency = 1,
        Filled = false,
    },
    HitChance = 100,
    NearestPoint = true,
    Shooting = {
        AutoShoot = false,
        AutoShootDelay = 0.1,
        BurstMode = false,
        BurstCount = 3,
        BurstDelay = 0.05,
    },
    Notifications = {
        Enabled = true,
        ShowTargetName = true,
        ShowHitConfirm = true,
        ShowStats = true,
        Duration = 2,
    },
    Whitelist = {
        Enabled = false,
        Players = {},
    },
    TargetParts = {
        "Head",
        "UpperTorso",
        "LowerTorso",
        "LeftUpperArm",
        "LeftLowerArm",
        "LeftHand",
        "RightUpperArm",
        "RightLowerArm",
        "RightHand",
        "LeftUpperLeg",
        "LeftLowerLeg",
        "LeftFoot",
        "RightUpperLeg",
        "RightLowerLeg",
        "RightFoot",
        "HumanoidRootPart"
    },
    Prediction = {
        Enabled = true,
        AutoPing = true,
        BasePrediction = 0.133,
    },
    Resolver = true,
    AntiCurve = true,
    NoGroundShots = true,
    AntiAimViewer = true,
    DesyncVelocity = 86,
    GroundVelocityY = -20,
    UpVelocityY = -30,
    WallCheck = true,
    KnockedCheck = true,
    GrabbedCheck = true,
    CrewCheck = false,
    HealthCheck = true,
    HealthThreshold = 4,
    MaxDistance = 500,
    TeamCheck = false,
    GunFOV = {
        Enabled = true,
        ["Double-Barrel SG"] = 25,
        ["DoubleBarrel"] = 25,
        ["Revolver"] = 20,
        ["SMG"] = 18,
        ["Shotgun"] = 25,
        ["TacticalShotgun"] = 25,
        ["Silencer"] = 15,
    },
}

local b12 = {
    [2788229376] = {Name = "Da Hood", Argument = "UpdateMousePos", Remote = "MainEvent"},
    [9825515356] = {Name = "Hood Customs", Argument = "GetMousePos", Remote = "MainEvent"},
    [5602055394] = {Name = "Hood Modded", Argument = "MousePos", Remote = "Bullets"},
    [9183932460] = {Name = "Untitled Hood", Argument = "UpdateMousePos", Remote = ".gg/untitledhood"},
    [86385032689590] = {Name = "Da Uphill", Argument = "MOUSE", Remote = "MAINEVENT"},
    [74852365478794] = {Name = "Hood Bank", Argument = "MOUSE", Remote = "MAINEVENT"},
    [134531910435633] = {Name = "Da Strike", Argument = "MOUSE", Remote = "MAINEVENT"},
    [14487637618] = {Name = "Da Hood Bot Aim Trainer", Argument = "MOUSE", Remote = "MAINEVENT"},
    [11143225577] = {Name = "1v1 Hood Aim Trainer", Argument = "UpdateMousePos", Remote = "MainEvent"},
    [14413712255] = {Name = "Hood Aim", Argument = "MOUSE", Remote = "MAINEVENT"},
    [14472848239] = {Name = "Moon Hood", Argument = "MoonUpdateMousePos", Remote = "MainEvent"},
}

local CurrentGame = b12[game.PlaceId]

local State = {
    FOVCircle = nil,
    Target = nil,
    TargetPart = nil,
    CachedMousePos = Vector2.new(),
    LastMouseUpdate = 0,
    IsDesync = false,
    IsGroundShot = false,
    IsUpVelocity = false,
    CameraLookVector = nil,
    LastUpdateTime = 0,
    CurrentWeapon = nil,
    LastAutoShot = 0,
    BurstShotsLeft = 0,
    GUI = nil,
    GUIVisible = true,
    Connections = {},
    Stats = {
        Shots = 0,
        Hits = 0,
    }
}

local function b13(b14, b15)
    if not Config.Notifications.Enabled then
        return
    end
    
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Silent Aim",
            Text = b14,
            Duration = b15 or Config.Notifications.Duration
        })
    end)
end

local function b16(b17)
    if not Config.Whitelist.Enabled then
        return false
    end
    
    for _, b18 in ipairs(Config.Whitelist.Players) do
        if b17.Name:lower() == b18:lower() then
            return true
        end
    end
    return false
end

local function b19(b20)
    for _, b21 in ipairs(Config.Whitelist.Players) do
        if b21:lower() == b20:lower() then
            b13("⚠ " .. b20 .. " already whitelisted", 2)
            return
        end
    end
    
    table.insert(Config.Whitelist.Players, b20)
    b13("✓ Added " .. b20 .. " to whitelist", 2)
end

local function b22(b20)
    for i, b21 in ipairs(Config.Whitelist.Players) do
        if b21:lower() == b20:lower() then
            table.remove(Config.Whitelist.Players, i)
            b13("✓ Removed " .. b20 .. " from whitelist", 2)
            return
        end
    end
    
    b13("⚠ " .. b20 .. " not in whitelist", 2)
end

local function b23()
    local b24, b25 = pcall(function()
        local b26 = b6.Network.ServerStatsItem["Data Ping"]:GetValueString()
        local b27 = string.split(b26, "(")
        return tonumber(b27[1])
    end)
    return b24 and b25 or 50
end

local function b28()
    if not Config.Prediction.AutoPing then
        return Config.Prediction.BasePrediction
    end
    
    local b25 = b23()
    
    if b25 < 20 then return 0.110
    elseif b25 < 30 then return 0.119
    elseif b25 < 40 then return 0.123
    elseif b25 < 50 then return 0.125
    elseif b25 < 60 then return 0.129
    elseif b25 < 70 then return 0.130
    elseif b25 < 80 then return 0.1295
    elseif b25 < 90 then return 0.1295
    elseif b25 < 100 then return 0.130
    elseif b25 < 110 then return 0.1344
    elseif b25 < 120 then return 0.1344
    elseif b25 < 130 then return 0.141
    elseif b25 < 140 then return 0.1555
    elseif b25 < 150 then return 0.1555
    elseif b25 < 160 then return 0.1574
    elseif b25 < 170 then return 0.165
    elseif b25 < 180 then return 0.170
    else return 0.180
    end
end

local function b29()
    if Config.HitChance >= 100 then
        return true
    end
    
    local b30 = math.floor(Random.new():NextNumber(0, 1) * 100) / 100
    return b30 <= (Config.HitChance / 100)
end

local function b31()
    local b32 = Instance.new("ScreenGui")
    b32.Name = "SilentAimGUI"
    b32.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    b32.ResetOnSpawn = false
    
    local b33 = Instance.new("Frame")
    b33.Name = "MainFrame"
    b33.Parent = b32
    b33.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b33.BorderSizePixel = 0
    b33.Position = UDim2.new(0.5, -200, 0.5, -250)
    b33.Size = UDim2.new(0, 400, 0, 500)
    b33.Active = true
    b33.Draggable = true
    
    local b34 = Instance.new("UICorner")
    b34.CornerRadius = UDim.new(0, 10)
    b34.Parent = b33
    
    local b35 = Instance.new("TextLabel")
    b35.Name = "Title"
    b35.Parent = b33
    b35.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    b35.BorderSizePixel = 0
    b35.Size = UDim2.new(1, 0, 0, 40)
    b35.Font = Enum.Font.GothamBold
    b35.Text = "Silent Aim | RightShift to Toggle"
    b35.TextColor3 = Color3.fromRGB(255, 255, 255)
    b35.TextSize = 16
    
    local b36 = Instance.new("UICorner")
    b36.CornerRadius = UDim.new(0, 10)
    b36.Parent = b35
    
    local b37 = Instance.new("ScrollingFrame")
    b37.Name = "ScrollFrame"
    b37.Parent = b33
    b37.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b37.BorderSizePixel = 0
    b37.Position = UDim2.new(0, 10, 0, 50)
    b37.Size = UDim2.new(1, -20, 1, -60)
    b37.CanvasSize = UDim2.new(0, 0, 0, 1200)
    b37.ScrollBarThickness = 4
    
    local b38 = Instance.new("UIListLayout")
    b38.Parent = b37
    b38.SortOrder = Enum.SortOrder.LayoutOrder
    b38.Padding = UDim.new(0, 8)
    
    local function b39(b21, b40, b41)
        local b42 = Instance.new("Frame")
        b42.Name = b21
        b42.Parent = b37
        b42.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        b42.BorderSizePixel = 0
        b42.Size = UDim2.new(1, 0, 0, 35)
        
        local b43 = Instance.new("UICorner")
        b43.CornerRadius = UDim.new(0, 6)
        b43.Parent = b42
        
        local b44 = Instance.new("TextLabel")
        b44.Parent = b42
        b44.BackgroundTransparency = 1
        b44.Position = UDim2.new(0, 10, 0, 0)
        b44.Size = UDim2.new(1, -60, 1, 0)
        b44.Font = Enum.Font.Gotham
        b44.Text = b21
        b44.TextColor3 = Color3.fromRGB(255, 255, 255)
        b44.TextSize = 13
        b44.TextXAlignment = Enum.TextXAlignment.Left
        
        local b45 = Instance.new("TextButton")
        b45.Parent = b42
        b45.BackgroundColor3 = b40 and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        b45.BorderSizePixel = 0
        b45.Position = UDim2.new(1, -45, 0.5, -12)
        b45.Size = UDim2.new(0, 35, 0, 24)
        b45.Font = Enum.Font.GothamBold
        b45.Text = b40 and "ON" or "OFF"
        b45.TextColor3 = Color3.fromRGB(255, 255, 255)
        b45.TextSize = 11
        
        local b46 = Instance.new("UICorner")
        b46.CornerRadius = UDim.new(0, 4)
        b46.Parent = b45
        
        local b47 = b40
        
        b45.MouseButton1Click:Connect(function()
            b47 = not b47
            b45.BackgroundColor3 = b47 and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
            b45.Text = b47 and "ON" or "OFF"
            b41(b47)
        end)
        
        return b42
    end
    
    local function b48(b21, b49, b50, b40, b41)
        local b51 = Instance.new("Frame")
        b51.Name = b21
        b51.Parent = b37
        b51.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        b51.BorderSizePixel = 0
        b51.Size = UDim2.new(1, 0, 0, 50)
        
        local b52 = Instance.new("UICorner")
        b52.CornerRadius = UDim.new(0, 6)
        b52.Parent = b51
        
        local b44 = Instance.new("TextLabel")
        b44.Parent = b51
        b44.BackgroundTransparency = 1
        b44.Position = UDim2.new(0, 10, 0, 5)
        b44.Size = UDim2.new(1, -20, 0, 20)
        b44.Font = Enum.Font.Gotham
        b44.Text = b21 .. ": " .. b40
        b44.TextColor3 = Color3.fromRGB(255, 255, 255)
        b44.TextSize = 13
        b44.TextXAlignment = Enum.TextXAlignment.Left
        
        local b53 = Instance.new("Frame")
        b53.Parent = b51
        b53.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b53.BorderSizePixel = 0
        b53.Position = UDim2.new(0, 10, 0, 30)
        b53.Size = UDim2.new(1, -20, 0, 8)
        
        local b54 = Instance.new("UICorner")
        b54.CornerRadius = UDim.new(0, 4)
        b54.Parent = b53
        
        local b55 = Instance.new("Frame")
        b55.Parent = b53
        b55.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        b55.BorderSizePixel = 0
        b55.Size = UDim2.new((b40 - b49) / (b50 - b49), 0, 1, 0)
        
        local b56 = Instance.new("UICorner")
        b56.CornerRadius = UDim.new(0, 4)
        b56.Parent = b55
        
        local b57 = false
        
        b53.InputBegan:Connect(function(b58)
            if b58.UserInputType == Enum.UserInputType.MouseButton1 then
                b57 = true
            end
        end)
        
        b53.InputEnded:Connect(function(b58)
            if b58.UserInputType == Enum.UserInputType.MouseButton1 then
                b57 = false
            end
        end)
        
        b3.InputChanged:Connect(function(b58)
            if b57 and b58.UserInputType == Enum.UserInputType.MouseMovement then
                local b59 = math.clamp((b58.Position.X - b53.AbsolutePosition.X) / b53.AbsoluteSize.X, 0, 1)
                b55.Size = UDim2.new(b59, 0, 1, 0)
                local b60 = math.floor(b49 + (b50 - b49) * b59)
                b44.Text = b21 .. ": " .. b60
                b41(b60)
            end
        end)
        
        return b51
    end
    
    local function b61(b21, b62, b41)
        local b63 = Instance.new("Frame")
        b63.Name = b21
        b63.Parent = b37
        b63.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        b63.BorderSizePixel = 0
        b63.Size = UDim2.new(1, 0, 0, 60)
        
        local b64 = Instance.new("UICorner")
        b64.CornerRadius = UDim.new(0, 6)
        b64.Parent = b63
        
        local b44 = Instance.new("TextLabel")
        b44.Parent = b63
        b44.BackgroundTransparency = 1
        b44.Position = UDim2.new(0, 10, 0, 5)
        b44.Size = UDim2.new(1, -20, 0, 20)
        b44.Font = Enum.Font.Gotham
        b44.Text = b21
        b44.TextColor3 = Color3.fromRGB(255, 255, 255)
        b44.TextSize = 13
        b44.TextXAlignment = Enum.TextXAlignment.Left
        
        local b65 = Instance.new("TextBox")
        b65.Parent = b63
        b65.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b65.BorderSizePixel = 0
        b65.Position = UDim2.new(0, 10, 0, 30)
        b65.Size = UDim2.new(1, -20, 0, 25)
        b65.Font = Enum.Font.Gotham
        b65.PlaceholderText = b62
        b65.Text = ""
        b65.TextColor3 = Color3.fromRGB(255, 255, 255)
        b65.TextSize = 12
        b65.ClearTextOnFocus = false
        
        local b66 = Instance.new("UICorner")
        b66.CornerRadius = UDim.new(0, 4)
        b66.Parent = b65
        
        b65.FocusLost:Connect(function(b67)
            if b67 and b65.Text ~= "" then
                b41(b65.Text)
                b65.Text = ""
            end
        end)
        
        return b63
    end
    
    local function b68(b21, b41)
        local b45 = Instance.new("TextButton")
        b45.Name = b21
        b45.Parent = b37
        b45.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        b45.BorderSizePixel = 0
        b45.Size = UDim2.new(1, 0, 0, 35)
        b45.Font = Enum.Font.GothamBold
        b45.Text = b21
        b45.TextColor3 = Color3.fromRGB(255, 255, 255)
        b45.TextSize = 14
        
        local b69 = Instance.new("UICorner")
        b69.CornerRadius = UDim.new(0, 6)
        b69.Parent = b45
        
        b45.MouseButton1Click:Connect(b41)
        
        return b45
    end
    
    b39("Silent Aim Enabled", Config.Enabled, function(b70) Config.Enabled = b70 end)
    b39("Show FOV Circle", Config.FOV.Visible, function(b70) Config.FOV.Visible = b70 end)
    b48("FOV Radius", 1, 300, Config.FOV.Radius, function(b70) Config.FOV.Radius = b70 end)
    b48("Hit Chance", 0, 100, Config.HitChance, function(b70) Config.HitChance = b70 end)
    
    b39("Auto Shoot", Config.Shooting.AutoShoot, function(b70) Config.Shooting.AutoShoot = b70 end)
    b39("Burst Mode", Config.Shooting.BurstMode, function(b70) Config.Shooting.BurstMode = b70 end)
    b48("Burst Count", 2, 10, Config.Shooting.BurstCount, function(b70) Config.Shooting.BurstCount = b70 end)
    
    b39("Prediction", Config.Prediction.Enabled, function(b70) Config.Prediction.Enabled = b70 end)
    b39("Auto Ping Prediction", Config.Prediction.AutoPing, function(b70) Config.Prediction.AutoPing = b70 end)
    b39("Resolver", Config.Resolver, function(b70) Config.Resolver = b70 end)
    b39("Anti Curve", Config.AntiCurve, function(b70) Config.AntiCurve = b70 end)
    b39("No Ground Shots", Config.NoGroundShots, function(b70) Config.NoGroundShots = b70 end)
    b39("Anti Aim Viewer", Config.AntiAimViewer, function(b70) Config.AntiAimViewer = b70 end)
    
    b39("Wall Check", Config.WallCheck, function(b70) Config.WallCheck = b70 end)
    b39("Knocked Check", Config.KnockedCheck, function(b70) Config.KnockedCheck = b70 end)
    b39("Grabbed Check", Config.GrabbedCheck, function(b70) Config.GrabbedCheck = b70 end)
    b39("Crew Check", Config.CrewCheck, function(b70) Config.CrewCheck = b70 end)
    
    b39("Notifications", Config.Notifications.Enabled, function(b70) Config.Notifications.Enabled = b70 end)
    b39("Show Target Name", Config.Notifications.ShowTargetName, function(b70) Config.Notifications.ShowTargetName = b70 end)
    b39("Show Hit Confirm", Config.Notifications.ShowHitConfirm, function(b70) Config.Notifications.ShowHitConfirm = b70 end)
    
    b39("Whitelist System", Config.Whitelist.Enabled, function(b70) Config.Whitelist.Enabled = b70 end)
    b61("Add to Whitelist", "Enter username", function(b14) b19(b14) end)
    b61("Remove from Whitelist", "Enter username", function(b14) b22(b14) end)
    
    b68("Show Stats", function()
        if State.Stats.Shots > 0 then
            local b71 = math.floor((State.Stats.Hits / State.Stats.Shots) * 100)
            b13("📊 Accuracy: " .. b71 .. "% (" .. State.Stats.Hits .. "/" .. State.Stats.Shots .. ")", 4)
        else
            b13("📊 No shots fired yet", 2)
        end
    end)
    
    b68("Reset Stats", function()
        State.Stats.Shots = 0
        State.Stats.Hits = 0
        b13("✓ Stats reset", 2)
    end)
    
    if gethui then
        b32.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(b32)
        b32.Parent = b8
    else
        b32.Parent = b8
    end
    
    State.GUI = b32
    return b32
end

local function b72()
    local b73 = b9.Character
    if not b73 then return nil end
    
    local b74 = b73:FindFirstChildOfClass("Tool")
    if not b74 then return nil end
    
    local b21 = b74.Name
    if string.find(b21, "%[") and string.find(b21, "%]") then
        local b27 = string.split(string.split(b21, "[")[2], "]")
        return b27[1]
    end
    
    return b21
end

local function b75()
    if not Config.GunFOV.Enabled then
        return Config.FOV.Radius
    end
    
    local b76 = b72()
    if b76 and Config.GunFOV[b76] then
        return Config.GunFOV[b76]
    end
    
    return Config.FOV.Radius
end

local function b77()
    if not Config.AntiAimViewer then
        State.CameraLookVector = nil
        return
    end
    
    local b78 = tick()
    if b78 - State.LastUpdateTime < 0.1 then
        return
    end
    
    State.LastUpdateTime = b78
    State.CameraLookVector = b10.CFrame.LookVector
end

local function b79(b80)
    if not Config.AntiAimViewer or not State.CameraLookVector then
        return false
    end
    
    local b81 = b10.CFrame.Position
    local b82 = (b80 - b81).Unit
    local b83 = State.CameraLookVector:Dot(b82)
    
    return b83 < 0.5
end

local function b84(b17)
    return b17 
        and b17.Character 
        and b17.Character:FindFirstChild("Humanoid")
        and b17.Character.Humanoid.Health > 0
        and b17.Character:FindFirstChild("HumanoidRootPart")
        and b17.Character:FindFirstChild("Head")
end

local function b85(b17)
    if not b17 or b17 == b9 then
        return false
    end
    
    if not b84(b17) then
        return false
    end
    
    if b16(b17) then
        return false
    end
    
    if Config.TeamCheck and b17.Team == b9.Team then
        return false
    end
    
    local b86 = b17.Character
    local b87 = b86:FindFirstChild("Humanoid")
    local b88 = b86:FindFirstChild("HumanoidRootPart")
    local b89 = b86:FindFirstChild("Head")
    
    if Config.HealthCheck and b87.Health < Config.HealthThreshold then
        return false
    end
    
    if Config.WallCheck and b89 and b89.Transparency == 1 then
        return false
    end
    
    if Config.KnockedCheck then
        local b90 = b86:FindFirstChild("BodyEffects")
        if b90 then
            local b91 = b90:FindFirstChild("K.O")
            if b91 and b91.Value == true then
                return false
            end
        end
    end
    
    if Config.GrabbedCheck then
        if b86:FindFirstChild("GRABBING_CONSTRAINT") then
            return false
        end
        if b87:FindFirstChild("Grabbed") and b87.Grabbed.Value then
            return false
        end
    end
    
    if Config.CrewCheck then
        local b92 = b17:FindFirstChild("DataFolder")
        local b93 = b9:FindFirstChild("DataFolder")
        
        if b92 and b93 then
            b92 = b92:FindFirstChild("Information") and b92.Information:FindFirstChild("Crew")
            b93 = b93:FindFirstChild("Information") and b93.Information:FindFirstChild("Crew")
            
            if b92 and b93 then
                if b92.Value ~= "" and b93.Value ~= "" and b92.Value == b93.Value then
                    return false
                end
            end
        end
    end
    
    return true
end

local function b94(b95)
    local b96, b97 = b10:WorldToViewportPoint(b95)
    return Vector2.new(b96.X, b96.Y), b97
end

local function b98(b95)
    local b99, b97 = b94(b95)
    if not b97 then
        return math.huge
    end
    
    return (b99 - State.CachedMousePos).Magnitude
end

local function b100(b95)
    if not Config.FOV.Enabled then
        return true
    end
    
    local b101 = b75()
    local b102 = b98(b95)
    return b102 <= (b101 * 3)
end

local function b103(b104)
    if not Config.WallCheck then
        return true
    end
    
    local b105 = b10.CFrame.Position
    local b106 = (b104.Position - b105)
    
    local b107 = RaycastParams.new()
    b107.FilterType = Enum.RaycastFilterType.Exclude
    b107.FilterDescendantsInstances = {b9.Character, b10}
    b107.IgnoreWater = true
    
    local b108 = b7:Raycast(b105, b106, b107)
    
    if b108 then
        return b108.Instance:IsDescendantOf(b104.Parent)
    end
    
    return true
end

local function b109()
    if State.FOVCircle then
        State.FOVCircle:Remove()
    end
    
    State.FOVCircle = Drawing.new("Circle")
    State.FOVCircle.Color = Config.FOV.Color
    State.FOVCircle.Thickness = Config.FOV.Thickness
    State.FOVCircle.Transparency = Config.FOV.Transparency
    State.FOVCircle.Filled = Config.FOV.Filled
    State.FOVCircle.Visible = Config.FOV.Visible and Config.Enabled
    State.FOVCircle.NumSides = 64
    State.FOVCircle.ZIndex = 9999
end

local function b110()
    if not State.FOVCircle then
        return
    end
    
    local b111 = Vector2.new(b11.X, b11.Y + b5:GetGuiInset().Y)
    local b101 = b75()
    State.CachedMousePos = Vector2.new(b11.X, b11.Y + b5:GetGuiInset().Y)

    State.FOVCircle.Position = b111
    State.FOVCircle.Radius = b101 * 3
    State.FOVCircle.Visible = Config.FOV.Visible and Config.Enabled
end

local function b112(b104)
    if not b104 or not b104:IsA("BasePart") then
        return false
    end
    if string.find(b104.Name, "Gun") then
        return false
    end
    return true
end

local function b113(b86)
    local b114 = nil
    local b115 = math.huge
    
    for _, b116 in ipairs(Config.TargetParts) do
        local b104 = b86:FindFirstChild(b116)
        
        if b104 and b112(b104) then
            if b103(b104) and b100(b104.Position) then
                local b102 = b98(b104.Position)
                
                if b102 < b115 then
                    b115 = b102
                    b114 = b104
                end
            end
        end
    end
    
    return b114
end

local function b117(b104)
    if not b104 or not Config.NearestPoint then
        return b104.Position
    end
    
    local b118 = b11.Hit.Position
    local b119 = b104.Size * 0.5
    local b120 = b104.CFrame:PointToObjectSpace(b118)
    
    local b121 = math.clamp(b120.X, -b119.X, b119.X)
    local b122 = math.clamp(b120.Y, -b119.Y, b119.Y)
    local b123 = math.clamp(b120.Z, -b119.Z, b119.Z)
    
    local b124 = b104.CFrame * Vector3.new(b121, b122, b123)
    
    return b124
end

local function b125()
    
    local b126 = nil
    local b127 = nil
    local b128 = math.huge
    local b129 = 100
    
    for _, b17 in ipairs(b1:GetPlayers()) do
        if b85(b17) then
            local b86 = b17.Character
            local b88 = b86:FindFirstChild("HumanoidRootPart")
            
            if b88 then
                local b130 = (b10.CFrame.Position - b88.Position).Magnitude
                if b130 <= Config.MaxDistance then
                    
                    local b131 = b113(b86)
                    
                    if b131 then
                        local b102 = b98(b131.Position) * 0.6
                        local b101 = b75()
                        
                        if b102 < b128 and (b101 * 3) > b102 and b102 < b129 then
                            b128 = b102
                            b126 = b17
                            b127 = b131
                        end
                    end
                end
            end
        end
    end
    
    if b126 and Config.Notifications.ShowTargetName and b126 ~= State.Target then
        b13("🎯 Targeting: " .. b126.Name, 1)
    end
    
    return b126, b127
end

local function b132(b17)
    local b86 = b17.Character
    if not b86 then
        return
    end
    
    local b88 = b86:FindFirstChild("HumanoidRootPart")
    local b87 = b86:FindFirstChild("Humanoid")
    
    if not b88 or not b87 then
        return
    end
    
    local b133 = b88.AssemblyLinearVelocity
    local b134 = b87.MoveDirection
    local b135 = b133.Magnitude
    local b136 = b134.Magnitude
    
    if Config.Resolver then
        State.IsDesync = false
        
        if b135 > Config.DesyncVelocity then
            State.IsDesync = true
        elseif b135 < 1 and b136 > 0.01 then
            State.IsDesync = true
        elseif b135 > 5 and b136 < 0.01 then
            State.IsDesync = true
        end
    else
        State.IsDesync = false
    end
    
    if Config.NoGroundShots then
        State.IsGroundShot = b133.Y < Config.GroundVelocityY
    else
        State.IsGroundShot = false
    end
    
    State.IsUpVelocity = b133.Y < Config.UpVelocityY
end

local function b137(b17, b138)
    local b86 = b17.Character
    if not b86 then
        return nil
    end
    
    local b88 = b86:FindFirstChild("HumanoidRootPart")
    local b87 = b86:FindFirstChild("Humanoid")
    
    if not b88 or not b138 then
        return nil
    end
    
    b132(b17)
    
    local b133 = b88.AssemblyLinearVelocity
    local b134 = b87.MoveDirection
    
    local b95 = b117(b138)
    
    local b139 = b28()
    local b140
    
    if State.IsDesync then
        b140 = b95 + (b134 * b139 * 16)
        
    elseif State.IsUpVelocity then
        b140 = b95 + (Vector3.new(b133.X, 0, b133.Z) * b139)
        
    elseif State.IsGroundShot then
        b140 = b95 + (Vector3.new(b133.X, b133.Y * 0.5, b133.Z) * b139)
        
    elseif Config.Prediction.Enabled then
        b140 = b95 + (b133 * b139)
        
    else
        b140 = b95
    end
    
    return b140
end

local function b141(b142, b140)
    if not Config.AntiCurve then
        return true
    end
    
    local b143, b144 = b10:WorldToViewportPoint(b142)
    local b145, b146 = b10:WorldToViewportPoint(b140)
    
    if not (b144 and b146) then
        return false
    end
    
    local b111 = Vector2.new(b11.X, b11.Y + b5:GetGuiInset().Y)
    
    local b147 = (Vector2.new(b143.X, b143.Y) - b111).Magnitude
    local b148 = (Vector2.new(b145.X, b145.Y) - b111).Magnitude
    
    local b149 = 5
    if b148 > b147 + b149 then
        return false
    end
    
    return true
end

local function b150(b95)
    if not CurrentGame then
        return false
    end
    
    local b151 = b4:FindFirstChild(CurrentGame.Remote)
    if not b151 then
        return false
    end
    
    local b24 = pcall(function()
        b151:FireServer(CurrentGame.Argument, b95)
    end)
    
    return b24
end

local function b152()
    if not Config.Enabled then
        return
    end
    
    local b153 = State.Target
    local b138 = State.TargetPart
    
    if not b153 or not b138 then
        return
    end
    
    if not b29() then
        return
    end
    
    local b140 = b137(b153, b138)
    
    if not b140 then
        return
    end
    
    if b79(b140) then
        return
    end
    
    local b24 = b150(b140)
    
    State.Stats.Shots = State.Stats.Shots + 1
    if b24 then
        State.Stats.Hits = State.Stats.Hits + 1
        
        if Config.Notifications.ShowHitConfirm then
            b13("✓ Hit " .. b153.Name, 1)
        end
    end
end

local function b154()
    if Config.Shooting.BurstMode then
        State.BurstShotsLeft = Config.Shooting.BurstCount
        
        for i = 1, Config.Shooting.BurstCount do
            task.wait(Config.Shooting.BurstDelay)
            b152()
        end
    else
        b152()
    end
end

local function b155(b74)
    if b74:IsA("Tool") then
        if State.Connections.Tool then
            State.Connections.Tool:Disconnect()
        end
        State.Connections.Tool = b74.Activated:Connect(b154)
    end
end

local function b156(b86)
    for _, b74 in ipairs(b86:GetChildren()) do
        if b74:IsA("Tool") then
            b155(b74)
        end
    end
    
    State.Connections.ChildAdded = b86.ChildAdded:Connect(function(b157)
        if b157:IsA("Tool") then
            b155(b157)
        end
    end)
end

local function b158()
    Config.Enabled = not Config.Enabled
    
    if Config.Enabled then
        b13("✓ ENABLED", 2)
    else
        b13("✗ DISABLED", 2)
        State.Target = nil
        State.TargetPart = nil
    end
    
    b110()
end

local function b159()
    if State.GUI then
        State.GUIVisible = not State.GUIVisible
        State.GUI.Enabled = State.GUIVisible
    end
end

local function b160()
    State.Connections.Input = b3.InputBegan:Connect(function(b58, b161)
        if b161 then return end
        
        if b58.KeyCode == Config.ToggleKey then
            b158()
        elseif b58.KeyCode == Config.GUIToggleKey then
            b159()
        end
    end)
end

local function b162()
    State.Connections.Heartbeat = b2.Heartbeat:Connect(function()
    b110()
    b77()
    
    if Config.Enabled then
        local b153, b138 = b125()
        State.Target = b153
        State.TargetPart = b138
        
        if b153 then
            b132(b153)
        end
    end
        
        if Config.Shooting.AutoShoot and Config.Enabled then
            local b78 = tick()
            if b78 - State.LastAutoShot >= Config.Shooting.AutoShootDelay then
                local b153, b138 = b125()
                
                if b153 and b138 and b100(b138.Position) then
                    State.LastAutoShot = b78
                    b152()
                end
            end
        end
    end)
end

local function b163()
    for _, b164 in pairs(State.Connections) do
        if typeof(b164) == "RBXScriptConnection" then
            b164:Disconnect()
        end
    end
    
    if State.FOVCircle then
        State.FOVCircle:Remove()
    end
    
    if State.GUI then
        State.GUI:Destroy()
    end
    
    State.Target = nil
    State.TargetPart = nil
    State.Connections = {}
    
    b13("Unloaded", 2)
end

local function b165()
    if not CurrentGame then
        b13("⚠ Game not supported", 3)
        return
    end
    
    b31()
    b109()
    
    if b9.Character then
        b156(b9.Character)
    end
    
    State.Connections.CharacterAdded = b9.CharacterAdded:Connect(b156)
    
    b160()
    b162()
    
    b13("✓ Loaded Successfully", 3)
    task.wait(0.5)
    b13("Press RightShift to open GUI", 2)
end

if _G.SilentAimCleanup then
    pcall(_G.SilentAimCleanup)
end
_G.SilentAimCleanup = b163

b165()
