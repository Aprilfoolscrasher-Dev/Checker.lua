local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ====== 1️⃣ Your key and Discord webhook ======
local key = getgenv().script_key
local webhook = "https://discord.com/api/webhooks/1488676937802055883/-hZc3klPkb_zQaRWjkgsvAB63kXSeLT3r6vYObSS9wmx2NZEd6tgTg8xcSQEBvVpQT6w"

if not key or key == "" then
    return warn("No script_key set! Set getgenv().script_key before running the loader.")
end

-- ====== 2️⃣ Generate Roblox-compatible pseudo-HWID ======
local salt = "my_secret_salt_1234" -- keep secret
local hwid = tostring(player.UserId) .. "_" .. salt -- deterministic unique string per player

-- ====== 3️⃣ Fetch keys.json ======
local success, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json")
end)
if not success or not response then
    return warn("Failed to fetch keys.json")
end

local ok, data = pcall(function()
    return HttpService:JSONDecode(response)
end)
if not ok or not data then
    return warn("Failed to decode keys.json")
end

local keys = data["keys"]
if type(keys) ~= "table" then
    return warn("JSON format invalid: 'keys' table missing")
end

local keyData = keys[key]
if type(keyData) ~= "table" then
    return warn("Invalid key!")
end

-- ====== 4️⃣ Dynamic HWID assignment ======
if not keyData["hwid"] or keyData["hwid"] == "" or keyData["hwid"] == nil then
    warn("Key has no HWID yet. Sending webhook to assign HWID...")

    local content = {
        ["content"] = string.format(
            "**Key First-Time Use Detected!**\nKey: %s\nPlayer: %s\nGenerated HWID: %s\nTime: %s\nAssign this HWID to lock the key.",
            key, player.UserId, hwid, os.date("%c")
        )
    }

    pcall(function()
        HttpService:PostAsync(webhook, HttpService:JSONEncode(content), Enum.HttpContentType.ApplicationJson)
    end)
end

-- ====== 5️⃣ Check HWID match ======
if keyData["hwid"] and keyData["hwid"] ~= hwid then
    warn("HWID mismatch! Sending Discord webhook...")

    local content = {
        ["content"] = string.format(
            "**Key Sharing Detected!**\nKey: %s\nPlayer: %s\nHWID Attempt: %s\nTime: %s",
            key, player.UserId, hwid, os.date("%c")
        )
    }

    pcall(function()
        HttpService:PostAsync(webhook, HttpService:JSONEncode(content), Enum.HttpContentType.ApplicationJson)
    end)

    return warn("This key is not valid for your device/player!")
end

-- ====== 6️⃣ Check timed keys ======
if keyData["type"] == "timed" then
    local created = keyData["created"] or 0
    local duration = keyData["duration"] or 0
    if os.time() > created + duration then
        return warn("Key expired!")
    end
end

print("Key valid! Loading main.lua...")

-- ====== 7️⃣ Fetch and run main.lua ======
local mainOk, mainCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua")
end)
if not mainOk or not mainCode then
    return warn("Failed to fetch main.lua")
end

local func, loadErr = loadstring(mainCode)
if not func then
    return warn("Failed to load main.lua:", loadErr)
end

func()