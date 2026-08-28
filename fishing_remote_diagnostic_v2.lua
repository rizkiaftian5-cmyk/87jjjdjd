-- Fishing Remote Diagnostic v2
-- Delta-ready diagnostic for a game you control.
-- Finds client-visible RemoteEvents/RemoteFunctions related to fishing
-- and records their names/paths. It does NOT invoke unknown remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LOG = "fishing_remote_diagnostic_v2.txt"

local keywords = {
    "fish", "fishing", "cast", "catch", "reel", "rod",
    "hook", "bite", "mini", "cleanup", "giver", "replication"
}

local function log(text)
    print("[FishingDiagV2] " .. text)
    if type(appendfile) == "function" then
        pcall(function()
            appendfile(LOG, os.date("[%H:%M:%S] ") .. text .. "\n")
        end)
    elseif type(writefile) == "function" then
        local old = ""
        if type(isfile) == "function" and isfile(LOG)
            and type(readfile) == "function" then
            pcall(function() old = readfile(LOG) end)
        end
        pcall(function()
            writefile(LOG, old .. os.date("[%H:%M:%S] ") .. text .. "\n")
        end)
    end
end

local function matches(name)
    local n = string.lower(name)
    for _, k in ipairs(keywords) do
        if n:find(k, 1, true) then
            return true
        end
    end
    return false
end

local function describe(obj)
    local class = obj.ClassName

    if class == "RemoteEvent" then
        return "RemoteEvent"
    elseif class == "RemoteFunction" then
        return "RemoteFunction"
    elseif class == "BindableEvent" then
        return "BindableEvent"
    elseif class == "BindableFunction" then
        return "BindableFunction"
    end

    return nil
end

log("=== FISHING REMOTE DIAGNOSTIC V2 ===")
log("Player: " .. player.Name)
log("Started: " .. os.date("%Y-%m-%d %H:%M:%S"))
log("Scanning ReplicatedStorage...")

local found = 0
local list = {}

for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    local class = describe(obj)

    if class and matches(obj.Name) then
        found += 1

        local line = string.format(
            "%02d | %s | %s",
            found,
            class,
            obj:GetFullName()
        )

        list[#list + 1] = line
        log(line)
    end
end

-- Always report the remotes already known from the previous diagnostic.
local remotes = ReplicatedStorage:FindFirstChild("Remotess")
if remotes then
    log("Known folder found: " .. remotes:GetFullName())

    for _, name in ipairs({"MiniGame", "NotifyClient"}) do
        local obj = remotes:FindFirstChild(name)
        if obj then
            log("KNOWN | " .. obj.ClassName .. " | " .. obj:GetFullName())
        else
            log("KNOWN | MISSING | Remotess." .. name)
        end
    end
else
    log("WARNING | ReplicatedStorage.Remotess not found")
end

log("Total matching remotes: " .. tostring(found))
log("IMPORTANT: No unknown RemoteEvent/RemoteFunction was invoked.")
log("")

if found == 0 then
    log("No additional fishing-related remotes were found.")
    log("If the game creates remotes dynamically, run this while fishing.")
end

-- Small draggable status panel.
local gui = Instance.new("ScreenGui")
gui.Name = "FishingRemoteDiagnosticV2"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 310, 0, 130)
frame.Position = UDim2.new(0.5, -155, 0.25, 0)
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Fishing Diagnostic V2"
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 55)
status.Position = UDim2.new(0, 10, 0, 45)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextSize = 15
status.Text = "Found: " .. found .. "\nLog: " .. LOG
status.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 32, 0, 32)
close.Position = UDim2.new(1, -38, 0, 6)
close.Text = "×"
close.TextSize = 22
close.Parent = frame

-- Mobile drag support.
local UIS = game:GetService("UserInputService")
local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and
        (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

close.Activated:Connect(function()
    gui:Destroy()
end)

getgenv().StopFishingRemoteDiagnosticV2 = function()
    pcall(function()
        gui:Destroy()
    end)
end

print("========================================")
print(" Fishing Remote Diagnostic V2 ACTIVE")
print(" Matching remotes: " .. tostring(found))
print(" Log: " .. LOG)
print(" Lakukan 2-3x fishing setelah ini aktif.")
print(" Kirim isi file log ke saya.")
print("========================================")
