--Credit to Stefanuk12, works well so decided to push it to Anomic

if getgenv().ValiantAimHacks then return getgenv().ValiantAimHacks end

-- // Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

-- // Vars
local Heartbeat = RunService.Heartbeat
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // Silent Aim Vars
getgenv().ValiantAimHacks = {
    SilentAimEnabled = true,
    ShowFOV = true,
    VisibleCheck = true,
    TeamCheck = true,
    FOV = 60,
    HitChance = 100,
    Selected = LocalPlayer,
    TargetPart = "Head",
    BlacklistedTeams = {
        {
            Team = LocalPlayer.Team,
            TeamColor = LocalPlayer.TeamColor,
        },
    },
    BlacklistedPlayers = {LocalPlayer},
    WhitelistedPUIDs = {91318356},
}

-- // Show FOV
local circle = Drawing.new("Circle")
circle.Transparency = 1
circle.Thickness = 2
circle.Color = Color3.fromRGB(160,30,30)
circle.NumSides = 12
circle.Filled = false
function ValiantAimHacks.updateCircle()
    if (circle) then
        -- // Set Circle Properties
        circle.Visible = ValiantAimHacks.ShowFOV
        circle.Radius = (ValiantAimHacks.FOV * 3)
        circle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)

        -- // Return circle
        return circle
    end
end

-- // Custom Functions
calcChance = function(percentage)
    percentage = math.floor(percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= percentage/100
end

-- // Customisable Checking Functions: Is a part visible
function ValiantAimHacks.isPartVisible(Part, PartDescendant)
    -- // Vars
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Origin = CurrentCamera.CFrame.Position
    local _, OnScreen = CurrentCamera:WorldToViewportPoint(Part.Position)

    -- // If Part is on the screen
    if (OnScreen) then
        -- // Vars: Calculating if is visible
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {Character, CurrentCamera}

        local Result = Workspace:Raycast(Origin, Part.Position - Origin, raycastParams)
        if not Result then return false end
        local PartHit = Result.Instance
        local Visible = (not PartHit or PartHit:IsDescendantOf(PartDescendant))

        -- // Return
        return Visible
    end

    -- // Return
    return false
end

-- // Check teams
function ValiantAimHacks.checkTeam(targetPlayerA, targetPlayerB)
    -- // If player is not on your team
    if (targetPlayerA.Team ~= targetPlayerB.Team) then

        -- // Check if team is blacklisted
        for i = 1, #ValiantAimHacks.BlacklistedTeams do
            local v = ValiantAimHacks.BlacklistedTeams

            if (targetPlayerA.Team ~= v.Team and targetPlayerA.TeamColor ~= v.TeamColor) then
                return true
            end
        end
    end

    -- // Return
    return false
end

-- // Check if player is blacklisted
function ValiantAimHacks.checkPlayer(targetPlayer)
    for i = 1, #ValiantAimHacks.BlacklistedPlayers do
        local v = ValiantAimHacks.BlacklistedPlayers[i]

        if (v ~= targetPlayer) then
            return true
        end
    end

    -- // Return
    return false
end

-- // Check if player is whitelisted
function ValiantAimHacks.checkWhitelisted(targetPlayer)
    for i = 1, #ValiantAimHacks.WhitelistedPUIDs do
        local v = ValiantAimHacks.WhitelistedPUIDs[i]

        if (targetPlayer.UserId == v) then
            return true
        end
    end

    -- // Return
    return false
end

-- // Get the Direction, Normal and Material
function ValiantAimHacks.findDirectionNormalMaterial(Origin, Destination, UnitMultiplier)
    if (typeof(Origin) == "Vector3" and typeof(Destination) == "Vector3") then
        -- // Handling
        if (not UnitMultiplier) then UnitMultiplier = 1 end

        -- // Vars
        local Direction = (Destination - Origin).Unit * UnitMultiplier
        local RaycastResult = Workspace:Raycast(Origin, Direction)

        if (RaycastResult ~= nil) then
            local Normal = RaycastResult.Normal
            local Material = RaycastResult.Material

            return Direction, Normal, Material
        end
    end

    -- // Return
    return nil
end

-- // Get Character
function ValiantAimHacks.getCharacter(Player)
    return Player.Character
end

-- // Check Health
function ValiantAimHacks.checkHealth(Player)
    local Character = ValiantAimHacks.getCharacter(Player)
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

    local Health = (Humanoid and Humanoid.Health or 0)
    return Health > 0
end

-- // Check if silent aim can used
function ValiantAimHacks.checkSilentAim()
    return (ValiantAimHacks.SilentAimEnabled == true and ValiantAimHacks.Selected ~= LocalPlayer)
end

-- // Silent Aim Function
function ValiantAimHacks.getClosestPlayerToCursor()
    -- // Vars
    local ClosestPlayer = nil
    local Chance = calcChance(ValiantAimHacks.HitChance)
    local ShortestDistance = 1/0

    -- // Chance
    if (not Chance) then
        ValiantAimHacks.Selected = (Chance and LocalPlayer or LocalPlayer)

        return (Chance and LocalPlayer or LocalPlayer)
    end

    -- // Loop through all players
    local AllPlayers = Players:GetPlayers()
    for i = 1, #AllPlayers do
        local Player = AllPlayers[i]
        local Character = ValiantAimHacks.getCharacter(Player)

        if (not ValiantAimHacks.checkWhitelisted(Player) and ValiantAimHacks.checkPlayer(Player) and Character and Character:FindFirstChild(ValiantAimHacks.TargetPart) and ValiantAimHacks.checkHealth(Player)) then
            -- // Team Check
            if (ValiantAimHacks.TeamCheck and not ValiantAimHacks.checkTeam(Player, LocalPlayer)) then continue end

            -- // Vars
            local TargetPart = Character[ValiantAimHacks.TargetPart]
            local PartPos, _ = CurrentCamera:WorldToViewportPoint(TargetPart.Position)
            local Magnitude = (Vector2.new(PartPos.X, PartPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

            -- // Check if is in FOV
            if (circle.Radius > Magnitude and Magnitude < ShortestDistance) then
                -- // Check if Visible
                if (ValiantAimHacks.VisibleCheck and not ValiantAimHacks.isPartVisible(TargetPart, Character)) then continue end

                -- //
                ClosestPlayer = Player
                ShortestDistance = Magnitude
            end
        end
    end

    -- // End
    ValiantAimHacks.Selected = (Chance and ClosestPlayer or LocalPlayer)
end

-- // Heartbeat Function
Heartbeat:Connect(function()
    ValiantAimHacks.updateCircle()
    ValiantAimHacks.getClosestPlayerToCursor()
end)

local mt = getrawmetatable(game)
local backupnamecall = mt.__namecall
local backupindex = mt.__index
ValiantAimHacks["TeamCheck"] = false
ValiantAimHacks["SilentAimEnabled"] = false
ValiantAimHacks["ShowFOV"] = false
setreadonly(mt, false)

--silent aim
if not checkcaller then checkcaller = function() return false end end
local itemlist
local s,e = pcall(function()
    itemlist = loadstring(decompile(game:GetService("ReplicatedStorage"):WaitForChild("Client"):WaitForChild("ItemList")))()
end)
if not s then 
    itemlist = loadstring(game:HttpGet("https://raw.githubusercontent.com/BonfireDevelopment/Roblox/main/Anomic/Support%20Code/itemlist.lua"))()
end

mt.__namecall = newcclosure(function(r,...)
    local args = {...}

    if tostring(getnamecallmethod()) == "SetPrimaryPartCFrame" and not checkcaller() and getcallingscript() == game.Players.LocalPlayer.PlayerGui["_L.Handler"]:WaitForChild("GunHandlerLocal") and args[1] == workspace then
        wait(4e4)
        return
    elseif tostring(getnamecallmethod()) == "FireServer" and tostring(r) == "Validate" then
        wait(4e4)
        return
    elseif tostring(getnamecallmethod()) == "FireServer" and tostring(r) == "WeaponServer" and args[1] == "Player" then
        args[5] = itemlist[args[3]].Accuracy   
        return backupnamecall(r,unpack(args))
    end
    if tostring(getnamecallmethod()) == "Kick" then
        wait(4e4)
        return
    end
    return backupnamecall(r, ...)
end)
mt.__index = newcclosure(function(t, k)
    if t:IsA("Mouse") and (k == "Hit" or k == "Target") then
        if ValiantAimHacks.checkSilentAim() then
            local CPlayer = rawget(ValiantAimHacks, "Selected")
            if CPlayer and CPlayer.Character and CPlayer.Character.FindFirstChild(CPlayer.Character, "Head") then
                return (k == "Hit" and CPlayer.Character.Head.CFrame or CPlayer.Character.Head)
            end
        end
    end
    return backupindex(t, k)
end)
setreadonly(mt, true)

return ValiantAimHacks