local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local key = getgenv().script_key
local webhook = "https://discord.com/api/webhooks/1488676937802055883/-hZc3klPkb_zQaRWjkgsvAB63kXSeLT3r6vYObSS9wmx2NZEd6tgTg8xcSQEBvVpQT6w"  -- replace with your webhook

if not key or key == "" then
    return warn("No script_key set!")
end

-- Generate pseudo HWID
local salt = "my_secret_salt_1234"
local hwid = HttpService:SHA256(tostring(player.UserId) .. salt)

-- Fetch keys.json
local ok, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json")
end)
if not ok or not response then
    return warn("Failed to fetch keys.json")
end

local data = HttpService:JSONDecode(response)
local keys = data["keys"]

local keyData = keys[key]
if not keyData then
    return warn("Invalid key!")
end

-- Check HWID
if keyData["hwid"] then
    if keyData["hwid"] ~= hwid then
        warn("HWID mismatch! Sending webhook...")
        -- Send Discord webhook
        local content = {
            ["content"] = string.format(
                "**Key Sharing Detected!**\nKey: %s\nPlayer: %s\nHWID: %s\nTime: %s",
                key, player.UserId, hwid, os.date("%c")
            )
        }
        pcall(function()
            HttpService:PostAsync(webhook, HttpService:JSONEncode(content), Enum.HttpContentType.ApplicationJson)
        end)
        return warn("This key is not valid for your device/player!")
    end
end

-- Check timed keys
if keyData["type"] == "timed" then
    local created = keyData["created"] or 0
    local duration = keyData["duration"] or 0
    if os.time() > created + duration then
        return warn("Key expired!")
    end
end

print("Key valid! Loading main.lua...")

-- Fetch and execute main.lua
local mainCode = game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua")
loadstring(mainCode)()