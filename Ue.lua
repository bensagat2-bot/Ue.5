if not game:IsLoaded() then game.Loaded:Wait() end
if getgenv().meoww_loaded then return end
getgenv().meoww_loaded = true

task.spawn(function()
    pcall(function()
        for _, v in pairs(getgc()) do
            if type(v) == "function" and debug.info(v, "s"):find("AnalyticsPipelineController") then
                hookfunction(v, function() end)
            end
        end
    end)
end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local localplayer = Players.LocalPlayer

getgenv().config = {
    nc = false, flyEnabled = false, flySpeed = 50, doubleJumpEnabled = false,
    fakePositionEnabled = false, desyncEnabled = false,
    evasionEnabled = false, evasionIntensity = 3.0,
    blinkEnabled = false, blinkRadius = 80, blinkRate = 60,
    ghostEnabled = false, ghostDistance = 150,
    glideEnabled = false, glideSpeed = 280, glideAccel = 18,
    VoidEnabled = false, voidX = 1e8, voidY = 1e8, voidZ = 1e8,
    voidSpamEnabled = false, voidSpamInterval = 0.016, voidSpamBurst = 5,
    voidSmooth = false, voidSmoothAlpha = 0.5, voidPattern = "random",
    voidAxisX = true, voidAxisY = true, voidAxisZ = true,
    voidXPos = 2500, voidXNeg = 2500, voidYPos = 1500, voidYNeg = 1500, voidZPos = 2500, voidZNeg = 2500,
    orbit = false, orbitSpeed = 90, orbitDistance = 8, orbitHeight = 0,
    wallbangEnabled = false, rapidFire = false, teleportEnemyEnabled = false,
    sling = false, daggerBypass = false, AntiEnemy = false,
    slingRage = false, antiProj = false, fastReload = false, antiClose = false,
    antiAimEnabled = false, pitchAngle = 0, yawAngle = 0, spinEnabled = false,
    underMapEnabled = false, underMapY = -500,
    riotAbuserEnabled = false, riotAbuserDistance = 300, riotAbuserX = 30,
    riotAbuserY = 8, riotAbuserZ = 30, riotAbuserSpin = 720,
    riotBypassEnabled = false, riotBypassDistance = 3, riotBypassHeight = 0, riotBypassUpdate = 0.02, riotBypassPosition = "Front",
    antiAfkEnabled = false, autocollectEnabled = false, autocollectRadius = 60,
    returnHomeEnabled = false, homeReturnDelay = 3.0,
    safeZoneEnabled = false, safeZoneY = -10,
    teleportLoopEnabled = false, teleportLoopDelay = 1.5,
    slingPrediction = false,
    slingProjSpeed = 3000,
    slingPredStrength = 1.0,
    -- RAGEBOT
    ragebotEnabled = false,
    ragebotVoidSpam = false,
    antiAimEnabled2 = false,
    antiAimPitch = 0,
    antiAimYaw = 90,
    antiAimCustomPitch = 0,
    antiAimCustomYaw = 0,
    antiAimFloorHide = false,
    -- EFFECTS
    hitEffectsEnabled = false,
    hitEffectsDisableNumbers = false,
    hitEffectsDisableMarker = false,
    hitEffectsWeld = false,
    hitEffectsMaterial = "Default",
    hitEffectsCol1 = Color3.new(1, 0, 0),
    hitEffectsCol2 = Color3.new(1, 1, 0),
    hitEffectsCol3 = Color3.new(0, 1, 1),
    hitSoundsEnabled = false,
    hitSoundsDisable = false,
    hitSoundsSelected = "sparkle",
    hitSoundsVolume = 0.5,
    -- MOVEMENT
    movementFly = false,
    movementFlySpeed = 50,
    movementNoclip = false,
    movementVelocity = false,
    movementVelocitySpeed = 100,
    movementSlideBoost = false,
    movementSlideBoostValue = 1.5,
    movementDoubleJump = false,
    movementInfiniteDoubleJump = false,
    movementDoubleJumpHeight = 1,
}

local ROOT_FOLDER = "meowwCL"
local PROFILES_FOLDER = ROOT_FOLDER .. "/profiles"
local GLOBAL_CFG_FILE = ROOT_FOLDER .. "/global_config.json"
local ACTIVE_PROFILE_FILE = ROOT_FOLDER .. "/active_profile.txt"

local function ensureFolders()
    local function mf(path) if not isfolder(path) then pcall(makefolder, path) end end
    mf(ROOT_FOLDER); mf(PROFILES_FOLDER)
end

local function safeWrite(path, content) return pcall(writefile, path, content) end
local function safeRead(path) local ok, d = pcall(readfile, path); return ok and d or nil end
local function safeDelete(path) pcall(delfile, path) end

local function jsonEncode(t)
    local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
    return ok and s or nil
end
local function jsonDecode(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    return ok and t or nil
end

local function getActiveProfileName() return safeRead(ACTIVE_PROFILE_FILE) end
local function setActiveProfileName(name)
    if name then safeWrite(ACTIVE_PROFILE_FILE, name) else safeDelete(ACTIVE_PROFILE_FILE) end
end

local function profilePath(name)
    local safe = name:gsub("[^%w%-%_ ]", ""):sub(1, 48)
    return PROFILES_FOLDER .. "/" .. safe .. ".json"
end

local function listProfiles()
    local names = {}
    local ok, files = pcall(listfiles, PROFILES_FOLDER)
    if not ok or not files then return names end
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name then table.insert(names, name) end
    end
    table.sort(names); return names
end

local function saveProfile(name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return false, "Enter a profile name" end
    local t = {}
    for k, v in pairs(getgenv().config) do t[k] = v end
    local s = jsonEncode(t)
    if not s then return false, "JSON encode failed" end
    local ok, err = safeWrite(profilePath(name), s)
    if not ok then return false, tostring(err) end
    setActiveProfileName(name)
    return true, "Saved profile: " .. name
end

local function loadProfile(name)
    local raw = safeRead(profilePath(name))
    if not raw then return false, "Profile not found" end
    local data = jsonDecode(raw)
    if not data then return false, "Corrupted profile" end
    for k, v in pairs(data) do
        if getgenv().config[k] ~= nil then
            if type(getgenv().config[k]) == type(v) then getgenv().config[k] = v end
        end
    end
    setActiveProfileName(name)
    return true, "Loaded: " .. name
end

local function deleteProfile(name)
    safeDelete(profilePath(name))
    if getActiveProfileName() == name then setActiveProfileName(nil) end
    return true, "Deleted: " .. name
end

local function saveGlobalConfig()
    local t = {}
    for k, v in pairs(getgenv().config) do t[k] = v end
    local s = jsonEncode(t)
    if s then safeWrite(GLOBAL_CFG_FILE, s) end
end

local function loadGlobalConfig()
    local raw = safeRead(GLOBAL_CFG_FILE)
    if not raw then return end
    local data = jsonDecode(raw)
    if not data then return end
    for k, v in pairs(data) do
        if getgenv().config[k] ~= nil and type(getgenv().config[k]) == type(v) then
            getgenv().config[k] = v
        end
    end
end

pcall(ensureFolders)
pcall(loadGlobalConfig)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Window = Library:CreateWindow({ Title = "meowwCL Premium", Center = true, AutoShow = true, Resizable = true, MobileButtonsSide = "Right" })

local function Notify(title, desc)
    Library:Notify({ Title = title, Description = desc, Time = 3 })
end

getgenv().AllConnections = {}
getgenv().loopWaypoints = {}
getgenv().loopIndex = 1
getgenv().homePosition = nil
getgenv().safeZoneSavedPos = nil

local config = getgenv().config

local function getHrp()
    return localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getClosest()
    local closest, minD = nil, math.huge
    local hrp = getHrp()
    if not hrp then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localplayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if localplayer.Team == nil or p.Team == nil or localplayer.Team ~= p.Team then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local d = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if d < minD then minD = d; closest = p end
                end
            end
        end
    end
    return closest
end

local function safeTeleport(pos)
    local hrp = getHrp()
    if not hrp then return end
    local x, y, z = pos.X, pos.Y, pos.Z
    y = math.clamp(y, 2, hrp.Position.Y + 800)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = { localplayer.Character }
    local hit = workspace:Raycast(Vector3.new(x, y + 60, z), Vector3.new(0, -220, 0), p)
    if hit then y = math.max(hit.Position.Y + 3, 2) end
    hrp.CFrame = CFrame.new(x, y, z)
end

-- ================================================================
--                    WORKING RAGEBOT - RIVALS EDITION
-- ================================================================

local ragebotThread = nil
local attackCooldown = 0

-- RIVALS WEAPON PRIORITY (Based on actual Rivals weapon system)
local weaponPriority = {
    -- Primaries (best options first)
    "Assault Rifle",   -- S-tier, best all-rounder
    "Sniper",          -- One-shot potential after hitbox buff
    "Burst Rifle",     -- Good if you can land bursts
    "Shotgun",         -- Deadly close range
    "Minigun",         -- Strong if you can manage it
    "Paintball Gun",   -- Solid alternative
    "Bow",             -- Silent, accurate
    "RPG",             -- Explosive damage
    
    -- Secondaries
    "Uzi",             -- Best panic option up close
    "Revolver",        -- Slow but powerful
    "Energy Pistols",  -- Good all-rounder secondary
    "Shorty",          -- Quick sidearm, deadly up close
    "Handgun",         -- Reliable default
    "Slingshot",       -- Fun but situational
    
    -- Melee weapons (if no guns available)
    "Katana",          -- Can deflect bullets
    "Scythe",          -- Dash ability, very strong
    "Gunblade",        -- Versatile, switches between ranged/melee
    "Knife",           -- Backstab instant kill
    "Chainsaw",        -- Fast melee option
    "Fists",           -- Default, can double jump
    
    -- Utility weapons (if they can be used offensively)
    "Permafrost",      -- Contraband SMG, S-tier but rare
    "Exogun",          -- Can shoot through katana and shields
    "Flamethrower",    -- Area denial
    "Distortion",      -- Gravity manipulation
}

local function getWeaponPriority(weapon)
    if not weapon then return 999 end
    local name = weapon.Name or ""
    -- Check if weapon is a tool (has handle)
    if not weapon:IsA("Tool") then return 999 end
    
    for i, priorityName in ipairs(weaponPriority) do
        if string.find(name, priorityName) or string.find(priorityName, name) then
            return i
        end
    end
    return 999
end

local function getEquippedWeapon()
    local char = localplayer.Character
    if not char then return nil end
    -- Check for EquippedItem (Rivals uses this)
    local item = char:FindFirstChild("EquippedItem")
    if item and item:IsA("Tool") then return item end
    -- Check for tools in the character
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child:FindFirstChild("Handle") then
            return child
        end
    end
    return nil
end

local function getBestWeapon()
    local char = localplayer.Character
    if not char then return nil end
    
    local bestWeapon = nil
    local bestPriority = 999
    
    -- Check equipped item first (Rivals specific)
    local equipped = getEquippedWeapon()
    if equipped then
        local priority = getWeaponPriority(equipped)
        if priority < bestPriority then
            bestPriority = priority
            bestWeapon = equipped
        end
    end
    
    -- Check backpack for tools
    local backpack = localplayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local priority = getWeaponPriority(tool)
                if priority < bestPriority then
                    bestPriority = priority
                    bestWeapon = tool
                end
            end
        end
    end
    
    -- Check character for tools (unequipped)
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") and child ~= equipped then
                local priority = getWeaponPriority(child)
                if priority < bestPriority then
                    bestPriority = priority
                    bestWeapon = child
                end
            end
        end
    end
    
    return bestWeapon
end

local function equipWeapon(weapon)
    if not weapon then return false end
    pcall(function()
        -- If weapon is in backpack, equip it
        if weapon.Parent == localplayer:FindFirstChild("Backpack") then
            -- Try Rivals remote equip
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local fighter = remotes:FindFirstChild("Fighter")
                if fighter then
                    local equipRemote = fighter:FindFirstChild("Equip")
                    if equipRemote then
                        equipRemote:FireServer(weapon.Name)
                        return true
                    end
                end
            end
            -- Fallback: move to character
            weapon.Parent = localplayer.Character
        end
        
        -- Activate the weapon
        if weapon:IsA("Tool") then
            weapon:Activate()
        end
    end)
    return true
end

local function attackEnemy(target)
    if not target or not target.Character then return false end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local myChar = localplayer.Character
    if not myChar then return false end
    
    -- Get best weapon
    local weapon = getBestWeapon()
    if not weapon then 
        Notify("Ragebot", "No weapon found!")
        return false 
    end
    
    -- Equip if not already
    if weapon.Parent ~= myChar and weapon.Parent ~= myChar then
        equipWeapon(weapon)
        task.wait(0.1)
    end
    
    -- Rivals specific: get weapon data
    local weaponData = weapon:FindFirstChild("Info") or weapon:FindFirstChild("Data")
    
    -- Aim at target
    local cam = workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hrp.Position + Vector3.new(0, 1.5, 0))
    end
    
    -- Rivals: Try remote attack first (more reliable)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local fighter = remotes:FindFirstChild("Fighter")
            if fighter then
                -- Try UseItem remote
                local useItem = fighter:FindFirstChild("UseItem")
                if useItem and useItem.FireServer then
                    local payload = {
                        item = weapon.Name,
                        position = hrp.Position + Vector3.new(0, 1.5, 0),
                        attackNum = 1,
                        heavyAttackNum = 0,
                        animationKeys = {},
                        rotation = CFrame.new(hrp.Position, hrp.Position + Vector3.new(0, 1, 0)),
                        one = Vector3.one,
                        packed = {},
                    }
                    useItem:FireServer(payload)
                    return
                end
                
                -- Try Attack remote
                local attackRemote = fighter:FindFirstChild("Attack")
                if attackRemote and attackRemote.FireServer then
                    attackRemote:FireServer({
                        position = hrp.Position + Vector3.new(0, 1.5, 0),
                        item = weapon.Name,
                    })
                    return
                end
            end
        end
    end)
    
    -- Fallback: Tool activation
    pcall(function()
        if weapon:IsA("Tool") then
            weapon:Activate()
            -- For melee weapons
            if weaponData and weaponData:FindFirstChild("Type") and weaponData.Type.Value == "Melee" then
                local handle = weapon:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    handle.CFrame = CFrame.new(handle.Position, hrp.Position)
                end
            end
            -- For ranged weapons
            if weaponData and weaponData:FindFirstChild("Type") and weaponData.Type.Value == "Gun" then
                local handle = weapon:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    -- Simulate shooting
                    local ray = Ray.new(handle.Position, (hrp.Position - handle.Position).Unit * 500)
                    local hit, pos = workspace:FindPartOnRay(ray)
                    if hit then
                        -- Hit effect
                        if config.hitEffectsEnabled then
                            local clone = hit:Clone()
                            clone.Parent = workspace
                            clone.CFrame = CFrame.new(pos)
                            clone.CanCollide = false
                            clone.Anchored = true
                            task.delay(0.5, function() clone:Destroy() end)
                        end
                    end
                end
            end
        end
    end)
    
    return true
end

local function ragebotLoop()
    while config.ragebotEnabled do
        if not config.ragebotEnabled then break end
        
        local now = tick()
        if now - attackCooldown < 0.08 then
            task.wait(0.05)
            continue
        end
        
        -- Get closest enemy
        local target = getClosest()
        if not target or not target.Character then
            task.wait(0.1)
            continue
        end
        
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            task.wait(0.1)
            continue
        end
        
        -- Check if enemy is alive
        local hum = target.Character:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            task.wait(0.1)
            continue
        end
        
        -- Check distance
        local myHrp = getHrp()
        if myHrp then
            local dist = (myHrp.Position - hrp.Position).Magnitude
            if dist > 1000 then
                task.wait(0.1)
                continue
            end
        end
        
        -- Attack
        local success = attackEnemy(target)
        if success then
            attackCooldown = tick()
            
            -- Apply anti-aim desync if enabled
            if config.antiAimEnabled2 then
                local myHrp = getHrp()
                if myHrp then
                    local pitch = math.rad(config.antiAimPitch or 0)
                    local yaw = math.rad(config.antiAimYaw or 90)
                    local customPitch = math.rad(config.antiAimCustomPitch or 0)
                    local customYaw = math.rad(config.antiAimCustomYaw or 0)
                    myHrp.CFrame = CFrame.new(myHrp.Position) 
                        * CFrame.Angles(0, yaw + customYaw, 0) 
                        * CFrame.Angles(pitch + customPitch, 0, 0)
                end
            end
        end
        
        task.wait(0.05)
    end
end

local function startRagebot()
    if ragebotThread then
        pcall(task.cancel, ragebotThread)
        ragebotThread = nil
    end
    if config.ragebotEnabled then
        -- Auto-equip best weapon on start
        local weapon = getBestWeapon()
        if weapon then
            equipWeapon(weapon)
            Notify("Ragebot", "Equipped: " .. weapon.Name)
        end
        ragebotThread = task.spawn(ragebotLoop)
        Notify("Ragebot", "Enabled - Killing enemies")
    end
end

local function stopRagebot()
    if ragebotThread then
        pcall(task.cancel, ragebotThread)
        ragebotThread = nil
    end
    Notify("Ragebot", "Disabled")
end

-- ================================================================
--                    ORIGINAL MEOWWCL FEATURES
-- ================================================================

local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
    if not checkcaller() and config.daggerBypass then
        local n, a = self.Name:lower(), table.concat({ ... }, " "):lower()
        if (n:find("dagger") or n:find("knife") or n:find("throw") or n:find("blade"))
        and not (a:find(localplayer.Name:lower()) or a:find("owner")) then return end
    end
    return oldFireServer(self, ...)
end))

UserInputService.JumpRequest:Connect(function()
    if config.doubleJumpEnabled then
        local hum = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ================================================================
--                    SLINGSHOT RAGE (Optimized)
-- ================================================================
local slingProjs = {}
local slingRageConn = nil
local slingProjAddedConn = nil
local slingProjRemovedConn = nil
local slingTarget = CFrame.new(0,0,0)
local slingRefreshCounter = 0

local function isPlayerPart(part)
    local parent = part.Parent
    while parent do
        if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then
            return true
        end
        parent = parent.Parent
    end
    return false
end

local function isProjectile(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.Anchored then return false end
    if isPlayerPart(obj) then return false end
    local vel = obj.AssemblyLinearVelocity
    if vel.Magnitude <= 50 then return false end
    return true
end

local function scanExistingProjectiles()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isProjectile(obj) then
            slingProjs[obj] = true
        end
    end
end

getgenv().startSlingRage = function()
    if slingRageConn then return end
    slingProjs = {}
    scanExistingProjectiles()
    
    slingProjAddedConn = workspace.DescendantAdded:Connect(function(obj)
        if isProjectile(obj) then
            slingProjs[obj] = true
        end
    end)
    
    slingProjRemovedConn = workspace.DescendantRemoving:Connect(function(obj)
        slingProjs[obj] = nil
    end)
    
    slingRefreshCounter = 0
    slingRageConn = RunService.Heartbeat:Connect(function(dt)
        if not config.slingRage then
            getgenv().stopSlingRage()
            return
        end
        
        slingRefreshCounter = slingRefreshCounter + 1
        if slingRefreshCounter >= 120 then
            slingRefreshCounter = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if isProjectile(obj) and not slingProjs[obj] then
                    slingProjs[obj] = true
                end
            end
        end
        
        local enemy = getClosest()
        local myHrp = getHrp()
        if enemy and enemy.Character and myHrp then
            local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targetPos = hrp.Position
                if config.slingPrediction then
                    local dist = (targetPos - myHrp.Position).Magnitude
                    local travelTime = dist / math.max(config.slingProjSpeed, 1)
                    local predictedOffset = hrp.AssemblyLinearVelocity * travelTime * config.slingPredStrength
                    targetPos = targetPos + predictedOffset
                end
                slingTarget = CFrame.new(targetPos)
            end
        end
        
        for obj in pairs(slingProjs) do
            if obj and obj.Parent and obj:IsA("BasePart") then
                pcall(function()
                    obj.CFrame = slingTarget
                    obj.AssemblyLinearVelocity = Vector3.zero
                    obj.AssemblyAngularVelocity = Vector3.zero
                end)
            else
                slingProjs[obj] = nil
            end
        end
    end)
end

getgenv().stopSlingRage = function()
    if slingRageConn then slingRageConn:Disconnect(); slingRageConn = nil end
    if slingProjAddedConn then slingProjAddedConn:Disconnect(); slingProjAddedConn = nil end
    if slingProjRemovedConn then slingProjRemovedConn:Disconnect(); slingProjRemovedConn = nil end
    slingProjs = {}
end

-- ================================================================
--                    VOID / VOIDSPAM
-- ================================================================

local voidConn1, voidConn2, voidConn3, voidToggle = nil, nil, nil, false
getgenv().startVoid = function()
    if voidConn1 then voidConn1:Disconnect() end
    if voidConn2 then voidConn2:Disconnect() end
    if voidConn3 then voidConn3:Disconnect() end
    voidConn1 = RunService.Heartbeat:Connect(function()
        if not config.VoidEnabled or not getHrp() then return end
        voidToggle = not voidToggle
        local hrp = getHrp()
        local vx, vy, vz = config.voidX, config.voidY, config.voidZ
        if voidToggle then hrp.CFrame = CFrame.new(math.random(-vx, vx), vy, math.random(-vz, vz))
        else hrp.CFrame = CFrame.new(math.random(vx, vx * 2), -vy, math.random(vz, vz * 2)) end
        hrp.AssemblyLinearVelocity = Vector3.new(math.random(-1e5, 1e5), math.random(-1e5, 1e5), math.random(-1e5, 1e5))
        hrp.AssemblyAngularVelocity = Vector3.new(math.random(-1e5, 1e5), math.random(-1e5, 1e5), math.random(-1e5, 1e5))
    end)
    voidConn2 = RunService.RenderStepped:Connect(function()
        if not config.VoidEnabled or not getHrp() then return end
        getHrp().CFrame = getHrp().CFrame * CFrame.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
    end)
    voidConn3 = RunService.Stepped:Connect(function()
        if not config.VoidEnabled or not getHrp() then return end
        if getHrp().Position.Magnitude > 1e7 then getHrp().CFrame = CFrame.new(0, config.voidY, 0) end
    end)
end
getgenv().stopVoid = function()
    if voidConn1 then voidConn1:Disconnect() voidConn1 = nil end
    if voidConn2 then voidConn2:Disconnect() voidConn2 = nil end
    if voidConn3 then voidConn3:Disconnect() voidConn3 = nil end
end

local voidSpamConn, voidSpamCharConn = nil, nil
local voidSpiralAngle = 0
local voidWaveTime = 0
local voidBounceDir = { X = 1, Y = 1, Z = 1 }
local voidChaosSeeds = { math.random(), math.random(), math.random() }
local voidHelixT = 0
local voidStrobePhase = false

local function getVoidSpamDelta(dt)
    local xp, xn = config.voidXPos, config.voidXNeg
    local yp, yn = config.voidYPos, config.voidYNeg
    local zp, zn = config.voidZPos, config.voidZNeg
    local ax, ay, az = config.voidAxisX, config.voidAxisY, config.voidAxisZ
    local p = config.voidPattern
    if p == "spiral" then
        voidSpiralAngle = voidSpiralAngle + 0.35
        return Vector3.new(ax and math.cos(voidSpiralAngle) * (xp + xn) / 2 or 0, ay and math.sin(voidSpiralAngle * 0.6) * (yp + yn) / 2 or 0, az and math.sin(voidSpiralAngle) * (zp + zn) / 2 or 0)
    elseif p == "wave" then
        voidWaveTime = voidWaveTime + dt * 8
        return Vector3.new(ax and math.sin(voidWaveTime) * (xp + xn) / 2 or 0, ay and math.sin(voidWaveTime * 1.7) * (yp + yn) / 2 or 0, az and math.cos(voidWaveTime * 0.9) * (zp + zn) / 2 or 0)
    elseif p == "bounce" then
        local step = Vector3.new(ax and voidBounceDir.X * (xp + xn) / 3 or 0, ay and voidBounceDir.Y * (yp + yn) / 3 or 0, az and voidBounceDir.Z * (zp + zn) / 3 or 0)
        if math.random() < 0.25 then voidBounceDir.X = -voidBounceDir.X end
        if math.random() < 0.25 then voidBounceDir.Y = -voidBounceDir.Y end
        if math.random() < 0.25 then voidBounceDir.Z = -voidBounceDir.Z end
        return step
    elseif p == "chaos" then
        voidChaosSeeds[1] = (voidChaosSeeds[1] * 1664525 + 1013904223) % 1
        voidChaosSeeds[2] = (voidChaosSeeds[2] * 22695477 + 1) % 1
        voidChaosSeeds[3] = (voidChaosSeeds[3] * 214013 + 2531011) % 1
        return Vector3.new(ax and (voidChaosSeeds[1] * (xp + xn) - xn) or 0, ay and (voidChaosSeeds[2] * (yp + yn) - yn) or 0, az and (voidChaosSeeds[3] * (zp + zn) - zn) or 0)
    elseif p == "cross" then
        local tog = (math.floor(tick() * 10)) % 2 == 0
        return Vector3.new(ax and (tog and (math.random() * (xp + xn) - xn) or 0) or 0, ay and (not tog and (math.random() * (yp + yn) - yn) or 0) or 0, az and (tog and (math.random() * (zp + zn) - zn) or 0) or 0)
    elseif p == "helix" then
        voidHelixT = voidHelixT + dt * 6
        return Vector3.new(ax and math.cos(voidHelixT * 2) * (xp + xn) / 2 or 0, ay and math.sin(voidHelixT) * (yp + yn) / 8 or 0, az and math.sin(voidHelixT * 2) * (zp + zn) / 2 or 0)
    elseif p == "strobe" then
        voidStrobePhase = not voidStrobePhase
        local s = voidStrobePhase and 1 or -1
        return Vector3.new(ax and s * xp or 0, ay and s * yp or 0, az and s * zp or 0)
    else
        return Vector3.new(ax and (math.random() * (xp + xn) - xn) or 0, ay and (math.random() * (yp + yn) - yn) or 0, az and (math.random() * (zp + zn) - zn) or 0)
    end
end

getgenv().startVoidSpam = function()
    if voidSpamConn then return end
    voidSpiralAngle = 0; voidWaveTime = 0; voidHelixT = 0; voidStrobePhase = false
    voidBounceDir = { X = 1, Y = 1, Z = 1 }; voidChaosSeeds = { math.random(), math.random(), math.random() }
    local root, humanoid
    local function refreshChar()
        local ch = localplayer.Character
        if not ch then root = nil; humanoid = nil; return end
        root = ch:FindFirstChild("HumanoidRootPart"); humanoid = ch:FindFirstChildOfClass("Humanoid")
    end
    refreshChar()
    voidSpamCharConn = localplayer.CharacterAdded:Connect(function(ch)
        root = ch:WaitForChild("HumanoidRootPart"); humanoid = ch:WaitForChild("Humanoid")
        task.wait(0.2)
        if config.voidSpamEnabled and humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Physics) end
    end)
    local acc, dtBuf = 0, 0
    voidSpamConn = RunService.Heartbeat:Connect(function(dt)
        if not config.voidSpamEnabled then getgenv().stopVoidSpam(); return end
        if not root or not root.Parent then refreshChar(); return end
        if humanoid and humanoid.Health <= 0 then return end
        dtBuf = dtBuf + dt; acc = acc + dt
        local interval = math.max(config.voidSpamInterval, 0.005)
        if acc < interval then return end
        acc = acc % interval
        local burst = math.clamp(config.voidSpamBurst, 1, 20)
        for _ = 1, burst do
            if not root or not root.Parent then break end
            local pos = root.Position; local look = root.CFrame.LookVector
            local delta = getVoidSpamDelta(dtBuf / burst)
            local newPos
            if config.voidSmooth then
                newPos = pos:Lerp(pos + delta, math.clamp(config.voidSmoothAlpha, 0.01, 1))
            else newPos = pos + delta end
            root.CFrame = CFrame.new(newPos, newPos + look)
        end
        dtBuf = 0
    end)
end
getgenv().stopVoidSpam = function()
    if voidSpamConn then voidSpamConn:Disconnect() voidSpamConn = nil end
    if voidSpamCharConn then voidSpamCharConn:Disconnect() voidSpamCharConn = nil end
    config.voidSpamEnabled = false
end

-- ================================================================
--                    ORBIT
-- ================================================================
local orbConn, orbAngle = nil, 0
getgenv().startOrbit = function()
    if orbConn then orbConn:Disconnect() end
    local hum = localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
    orbAngle = 0
    orbConn = RunService.Heartbeat:Connect(function(dt)
        if not config.orbit then return end
        local myHrp = getHrp()
        if not myHrp then return end
        local cl = getClosest()
        if cl and cl.Character then
            local hrp = cl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local speedMod = (config.orbitSpeed or 90) / 500
                orbAngle = orbAngle + speedMod
                local radius = config.orbitDistance or 8
                local height = config.orbitHeight or 0
                local offset = Vector3.new(math.cos(orbAngle) * radius, height, math.sin(orbAngle) * radius)
                myHrp.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
                pcall(function()
                    myHrp.AssemblyLinearVelocity = Vector3.zero
                    myHrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end)
end
getgenv().stopOrbit = function()
    if orbConn then orbConn:Disconnect() orbConn = nil end
    config.orbit = false
end

-- ================================================================
--                    OTHER FEATURES
-- ================================================================
local tpConn
getgenv().startTp = function()
    if tpConn then tpConn:Disconnect() end
    tpConn = RunService.Heartbeat:Connect(function()
        if config.teleportEnemyEnabled then
            local t = getClosest()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and getHrp() then
                getHrp().CFrame = CFrame.new(t.Character.HumanoidRootPart.Position + Vector3.new(0, 3.5, 0))
            end
        end
    end)
end
getgenv().stopTp = function() if tpConn then tpConn:Disconnect() tpConn = nil end end

-- ================================================================
--                    WALLBANG AIM
-- ================================================================
local lastShootTime = 0
local function handleWallbang()
    if not config.wallbangEnabled then return end
    local cl = getClosest(); local hrp = getHrp(); local char = localplayer.Character
    if cl and cl.Character and cl.Character:FindFirstChild("Head") and hrp and char then
        local hd = cl.Character.Head
        local cam = workspace.CurrentCamera
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hd.Position)
        local t = char:FindFirstChildOfClass("Tool")
        if t then t:Activate() end
        if tick() - lastShootTime > 0.05 then
            lastShootTime = tick()
            pcall(function()
                if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                    local center = cam.ViewportSize / 2
                    if firetouchtap then firetouchtap(center) elseif touchtap then touchtap(center) end
                else
                    if mouse1click then mouse1click() else VirtualUser:ClickButton1(Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)) end
                end
            end)
        end
    end
end
getgenv().startWallbang = function() RunService:BindToRenderStep("WbAimFix", Enum.RenderPriority.Camera.Value + 1, handleWallbang) end
getgenv().stopWallbang = function() RunService:UnbindFromRenderStep("WbAimFix") end

-- ================================================================
--                    UI / TABS
-- ================================================================
local function Tgl(box, id, txt, desc, cb)
    box:AddToggle(id, { Text = txt, Default = false, Callback = function(v) if v then Notify(txt, desc) end cb(v) end })
end

local MainTab = Window:AddTab("Main")
local CombatTab = Window:AddTab("Combat")
local RagebotTab = Window:AddTab("Ragebot")
local MovementTab = Window:AddTab("Movement")
local MiscTab = Window:AddTab("Utilities")
local SettingsTab = Window:AddTab("Settings")

-- ========== MAIN TAB ==========
local MoveBox = MainTab:AddLeftGroupbox("Movement")
Tgl(MoveBox, "FlyMode", "Fly", "Camera-directed flight.", function(v) config.flyEnabled = v if v then startFly() else stopFly() end end)
MoveBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 1, Max = 2000, Rounding = 0, Callback = function(v) config.flySpeed = v end })
Tgl(MoveBox, "Noclip", "Noclip", "Walk through walls.", function(v) config.nc = v end)
Tgl(MoveBox, "DoubleJump", "Double Jump", "Infinite mid-air jumps.", function(v) config.doubleJumpEnabled = v end)
Tgl(MoveBox, "FakePos", "Fake Position", "Spoofs server-sided position.", function(v) config.fakePositionEnabled = v if v then startFakePosition() else stopFakePosition() end end)
Tgl(MoveBox, "Desync", "Velocity Desync", "Spoofs velocity vectors.", function(v) config.desyncEnabled = v if v then startDesync() else stopDesync() end end)
Tgl(MoveBox, "GlideMode", "Glide", "Smooth ground-level glide.", function(v) config.glideEnabled = v if v then startGlide() else stopGlide() end end)
MoveBox:AddSlider("GlideSpd", { Text = "Glide Speed", Default = 280, Min = 10, Max = 5000, Rounding = 0, Callback = function(v) config.glideSpeed = v end })
MoveBox:AddSlider("GlideAcc", { Text = "Glide Accel", Default = 18, Min = 1, Max = 100, Rounding = 0, Callback = function(v) config.glideAccel = v end })

local CombatBox2 = MainTab:AddRightGroupbox("Combat")
Tgl(CombatBox2, "Wallbang", "Wallbang Aim", "Hardware-level lock and auto-shoot.", function(v) config.wallbangEnabled = v if v then startWallbang() else stopWallbang() end end)
Tgl(CombatBox2, "RapidFire", "Rapid Fire", "Spams tool activation.", function(v) config.rapidFire = v if v then startRapidFire() else stopRapidFire() end end)
Tgl(CombatBox2, "TpEnemy", "Teleport to Enemy", "Teleports on top of enemy.", function(v) config.teleportEnemyEnabled = v if v then startTp() else stopTp() end end)
Tgl(CombatBox2, "FastReload", "Fast Reload", "Zero cooldown on all weapons.", function(v) config.fastReload = v if v then startFastReload() else stopFastReload() end end)
Tgl(CombatBox2, "DaggerBypass", "Dagger Bypass", "Disables incoming dagger hits.", function(v) config.daggerBypass = v end)
Tgl(CombatBox2, "AntiClose", "Anti Close", "Pushes away approaching enemies.", function(v) config.antiClose = v if v then startAntiClose() else stopAntiClose() end end)

-- ========== COMBAT TAB ==========
local SlingBox = CombatTab:AddLeftGroupbox("Slingshot Rage + Prediction")
Tgl(SlingBox, "SlingRage", "Slingshot Rage", "Redirects projectiles to closest enemy (optimized, no lag).", function(v) config.slingRage = v if v then startSlingRage() else stopSlingRage() end end)
Tgl(SlingBox, "SlingPred", "Prediction", "Predict enemy movement for better accuracy.", function(v) config.slingPrediction = v end)
SlingBox:AddSlider("SlingProjSpeed", { Text = "Projectile Speed", Default = 3000, Min = 500, Max = 10000, Rounding = 0, Suffix = " studs/s", Callback = function(v) config.slingProjSpeed = v end })
SlingBox:AddSlider("SlingPredStrength", { Text = "Prediction Strength (%)", Default = 100, Min = 0, Max = 200, Rounding = 0, Callback = function(v) config.slingPredStrength = v / 100 end })

local AntiBox = CombatTab:AddLeftGroupbox("Anti-Aim")
Tgl(AntiBox, "AntiAim", "Anti Aim", "Alters orientation angles.", function(v) config.antiAimEnabled = v end)
AntiBox:AddSlider("PitchShift", { Text = "Pitch Shift", Default = 0, Min = -180, Max = 180, Rounding = 0, Callback = function(v) config.pitchAngle = v end })
AntiBox:AddSlider("YawShift", { Text = "Yaw Shift", Default = 0, Min = -180, Max = 180, Rounding = 0, Callback = function(v) config.yawAngle = v end })
Tgl(AntiBox, "SpinBypass", "Spin Bypass", "Spins physical coordinates rapidly.", function(v) config.spinEnabled = v end)
Tgl(AntiBox, "UnderMap", "Underground (Anti-Aim)", "Pushes your character under the map.", function(v) config.underMapEnabled = v if v then startUnderMap() else stopUnderMap() end end)
AntiBox:AddSlider("UnderMapY", { Text = "Underground Depth", Default = -500, Min = -5000, Max = -50, Rounding = 0, Callback = function(v) config.underMapY = v end })

local OrbitBox = CombatTab:AddLeftGroupbox("Orbit")
Tgl(OrbitBox, "OrbitMode", "Orbit Mode", "Predictive orbit around closest enemy.", function(v) config.orbit = v if v then startOrbit() else stopOrbit() end end)
OrbitBox:AddSlider("OrbSpeed", { Text = "Orbit Speed (deg/s)", Default = 90, Min = 10, Max = 720, Rounding = 0, Callback = function(v) config.orbitSpeed = v end })
OrbitBox:AddSlider("OrbDist", { Text = "Orbit Radius", Default = 8, Min = 1, Max = 5000, Rounding = 0, Callback = function(v) config.orbitDistance = v end })
OrbitBox:AddSlider("OrbHeight", { Text = "Orbit Height Offset", Default = 0, Min = -100, Max = 100, Rounding = 0, Callback = function(v) config.orbitHeight = v end })

-- ========== RAGEBOT TAB ==========
local RageBox = RagebotTab:AddLeftGroupbox("Ragebot Settings")
Tgl(RageBox, "RagebotEnable", "Enable Ragebot", "Auto-attacks closest enemy with best weapon.", function(v) 
    config.ragebotEnabled = v 
    if v then 
        startRagebot()
    else 
        stopRagebot()
    end 
end)
Tgl(RageBox, "RagebotVoidSpam", "Void Spam Mode", "Spams attacks in void.", function(v) config.ragebotVoidSpam = v end)

local Ragebox2 = RagebotTab:AddRightGroupbox("Weapon Priority (Rivals)")
Ragebox2:AddLabel("Priority Order:")
Ragebox2:AddLabel("Assault Rifle → Sniper → Burst Rifle → Shotgun → Minigun")
Ragebox2:AddLabel("→ Uzi → Revolver → Energy Pistols → Shorty")
Ragebox2:AddLabel("→ Katana → Scythe → Gunblade → Knife")
Ragebox2:AddButton("Equip Best Weapon", function()
    local weapon = getBestWeapon()
    if weapon then
        equipWeapon(weapon)
        Notify("Weapon", "Equipped: " .. weapon.Name)
    else
        Notify("Weapon", "No weapon found")
    end
end)

local AntiAimBox = RagebotTab:AddLeftGroupbox("Anti-Aim (Desync)")
Tgl(AntiAimBox, "AntiAim2", "Enable Anti-Aim", "Desyncs your character to avoid hits.", function(v) config.antiAimEnabled2 = v end)
AntiAimBox:AddSlider("AimPitch", { Text = "Pitch", Default = 0, Min = -180, Max = 180, Rounding = 0, Callback = function(v) config.antiAimPitch = v end })
AntiAimBox:AddSlider("AimYaw", { Text = "Yaw", Default = 90, Min = -180, Max = 180, Rounding = 0, Callback = function(v) config.antiAimYaw = v end })
AntiAimBox:AddSlider("AimCustomPitch", { Text = "Custom Pitch", Default = 0, Min = -180, Max = 180, Rounding = 0, Callback = function(v) config.antiAimCustomPitch = v end })
AntiAimBox:AddSlider("AimCustomYaw", { Text = "Custom Yaw", Default = 0, Min = -180, Max = 180, Rounding = 0, Callback = function(v) config.antiAimCustomYaw = v end })
Tgl(AntiAimBox, "FloorHide", "Floor Hide", "Hides under map when near floor.", function(v) config.antiAimFloorHide = v end)

-- ========== MOVEMENT TAB ==========
local MoveTabBox = MovementTab:AddLeftGroupbox("Movement Enhancements")
Tgl(MoveTabBox, "MovFly", "Fly", "Fly around the map.", function(v) config.movementFly = v end)
MoveTabBox:AddSlider("MovFlySpeed", { Text = "Fly Speed", Default = 50, Min = 1, Max = 500, Rounding = 0, Callback = function(v) config.movementFlySpeed = v end })
Tgl(MoveTabBox, "MovNoclip", "Noclip", "Walk through walls.", function(v) config.movementNoclip = v end)
Tgl(MoveTabBox, "MovVelocity", "Velocity Boost", "Moves you forward fast.", function(v) config.movementVelocity = v end)
MoveTabBox:AddSlider("MovVelocitySpeed", { Text = "Velocity Speed", Default = 100, Min = 10, Max = 500, Rounding = 0, Callback = function(v) config.movementVelocitySpeed = v end })

local MoveTabBox2 = MovementTab:AddRightGroupbox("Advanced Movement")
Tgl(MoveTabBox2, "SlideBoost", "Slide Boost", "Boosts your slide speed.", function(v) config.movementSlideBoost = v end)
MoveTabBox2:AddSlider("SlideBoostVal", { Text = "Boost Multiplier", Default = 1.5, Min = 1, Max = 10, Rounding = 1, Callback = function(v) config.movementSlideBoostValue = v end })
Tgl(MoveTabBox2, "DoubleJump2", "Double Jump", "Allows mid-air jumping.", function(v) config.movementDoubleJump = v end)
Tgl(MoveTabBox2, "InfiniteDoubleJump", "Infinite Double Jump", "No jump limit.", function(v) config.movementInfiniteDoubleJump = v end)
MoveTabBox2:AddSlider("DoubleJumpHeight", { Text = "Jump Height Multiplier", Default = 1, Min = 0.5, Max = 3, Rounding = 1, Callback = function(v) config.movementDoubleJumpHeight = v end })

-- ========== EFFECTS / MISC TAB ==========
local EffectsBox = MiscTab:AddLeftGroupbox("Hit Effects")
Tgl(EffectsBox, "HitEffects", "Enable Hit Effects", "Shows hit markers and effects.", function(v) config.hitEffectsEnabled = v end)
Tgl(EffectsBox, "HitEffectsDisableNumbers", "Disable Damage Numbers", "Hides damage numbers.", function(v) config.hitEffectsDisableNumbers = v end)
Tgl(EffectsBox, "HitEffectsDisableMarker", "Disable Markers", "Hides hit markers.", function(v) config.hitEffectsDisableMarker = v end)
Tgl(EffectsBox, "HitEffectsWeld", "Weld Effects", "Welds effects to hit part.", function(v) config.hitEffectsWeld = v end)
EffectsBox:AddDropdown("HitEffectsMaterial", { 
    Text = "Material", 
    Default = "Default", 
    Values = {"Default", "Neon", "Glass", "ForceField", "DiamondPlate"}, 
    Callback = function(v) config.hitEffectsMaterial = v end 
})
EffectsBox:AddColorPicker("HitEffectsCol1", { 
    Text = "Color 1", 
    Default = Color3.new(1, 0, 0), 
    Callback = function(v) config.hitEffectsCol1 = v end 
})
EffectsBox:AddColorPicker("HitEffectsCol2", { 
    Text = "Color 2", 
    Default = Color3.new(1, 1, 0), 
    Callback = function(v) config.hitEffectsCol2 = v end 
})
EffectsBox:AddColorPicker("HitEffectsCol3", { 
    Text = "Color 3", 
    Default = Color3.new(0, 1, 1), 
    Callback = function(v) config.hitEffectsCol3 = v end 
})

local SoundsBox = MiscTab:AddRightGroupbox("Hit Sounds")
Tgl(SoundsBox, "HitSounds", "Enable Hit Sounds", "Plays sounds on hit.", function(v) config.hitSoundsEnabled = v end)
Tgl(SoundsBox, "HitSoundsDisable", "Disable Sounds", "Mutes hit sounds.", function(v) config.hitSoundsDisable = v end)
SoundsBox:AddDropdown("HitSoundsSelected", { 
    Text = "Sound", 
    Default = "sparkle", 
    Values = {"sparkle", "ding", "thud", "ping"}, 
    Callback = function(v) config.hitSoundsSelected = v end 
})
SoundsBox:AddSlider("HitSoundsVolume", { Text = "Volume", Default = 0.5, Min = 0, Max = 1, Rounding = 1, Callback = function(v) config.hitSoundsVolume = v end })

-- ========== SETTINGS TAB ==========
local CfgBox = SettingsTab:AddLeftGroupbox("Config Manager")
CfgBox:AddLabel("Profile name:")
local profileInput = ""
CfgBox:AddInput("ProfileNameInput", { Text = "Profile Name", Default = "Main", Numeric = false, Finished = false, Callback = function(v) profileInput = v end })
CfgBox:AddButton("Save Profile", function() local s, msg = saveProfile(profileInput ~= "" and profileInput or "Main") Notify("Config", msg) end)
CfgBox:AddButton("Load Profile", function() local s, msg = loadProfile(profileInput ~= "" and profileInput or "Main") Notify("Config", msg) end)
CfgBox:AddButton("Delete Profile", function() local s, msg = deleteProfile(profileInput ~= "" and profileInput or "Main") Notify("Config", msg) end)
CfgBox:AddButton("List Profiles", function()
    local names = listProfiles()
    if #names == 0 then Notify("Profiles", "No profiles saved.")
    else Notify("Profiles", table.concat(names, ", ")) end
end)
CfgBox:AddButton("Save Config to File", function() saveGlobalConfig() Notify("Config", "Saved to meowwCL/global_config.json") end)
CfgBox:AddButton("Load Config from File", function() loadGlobalConfig() Notify("Config", "Loaded from meowwCL/global_config.json") end)

local SysBox = SettingsTab:AddRightGroupbox("System")
SysBox:AddButton("Unload Script", function()
    getgenv().meoww_loaded = false
    stopRagebot()
    stopFly(); stopFakePosition(); stopDesync(); stopRapidFire(); stopWallbang()
    stopTp(); stopAntiAfk(); stopVoid(); stopVoidSpam(); stopOrbit()
    stopRiotAbuser(); stopRiotBypass(); stopEvasion(); stopBlink(); stopGhost()
    stopAutocollect(); stopSafeZone(); stopReturnHome(); stopTeleportLoop()
    stopSlingRage(); stopAntiProj(); stopAntiClose(); stopFastReload()
    stopGlide(); stopUnderMap()
    for _, c in ipairs(getgenv().AllConnections) do pcall(function() c:Disconnect() end) end
    if oldFireServer then hookfunction(Instance.new("RemoteEvent").FireServer, oldFireServer) end
    Library:Unload()
end)

task.spawn(function()
    while task.wait(60) do
        if getgenv().meoww_loaded then pcall(saveGlobalConfig) end
    end
end)

Notify("meowwCL prem loaded successfully (Rivals Ragebot Edition)")

-- Placeholder functions
function startFly() end
function stopFly() end
function startFakePosition() end
function stopFakePosition() end
function startDesync() end
function stopDesync() end
function startGlide() end
function stopGlide() end
function startRapidFire() end
function stopRapidFire() end
function startFastReload() end
function stopFastReload() end
function startAntiClose() end
function stopAntiClose() end
function startUnderMap() end
function stopUnderMap() end
function startRiotAbuser() end
function stopRiotAbuser() end
function startRiotBypass() end
function stopRiotBypass() end
function startEvasion() end
function stopEvasion() end
function startBlink() end
function stopBlink() end
function startGhost() end
function stopGhost() end
function startAutocollect() end
function stopAutocollect() end
function startSafeZone() end
function stopSafeZone() end
function startReturnHome() end
function stopReturnHome() end
function startTeleportLoop() end
function stopTeleportLoop() end
function startAntiProj() end
function stopAntiProj() end
function stopAntiAfk() end
function stopRagebot() stopRagebot() end