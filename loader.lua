local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local key = getgenv().script_key or "NO_KEY"
local webhook = "https://discord.com/api/webhooks/1488676937802055883/-hZc3klPkb_zQaRWjkgsvAB63kXSeLT3r6vYObSS9wmx2NZEd6tgTg8xcSQEBvVpQT6w"
local salt = "my_secret_salt_1234"
local MAX_ATTEMPTS = 2

if not key or key == "" then
    warn("No script_key set")
    return
end

-- ===== SESSION TRACKING =====
getgenv().execCount = (getgenv().execCount or 0) + 1

-- ===== GAME INFO =====
local gameName = "Unknown"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

local timeNow = os.date("%Y-%m-%d %H:%M:%S")

-- ===== LOGGER =====
local function sendLog(status, extra)
    local msg = {
        content = string.format(
            "**SCRIPT LOG**\nUser: %s (%s)\nKey: %s\nGame: %s\nPlaceId: %s\nExec Count: %d\nStatus: %s\nTime: %s\n%s",
            player.Name,
            player.UserId,
            key,
            gameName,
            game.PlaceId,
            getgenv().execCount,
            status,
            timeNow,
            extra or ""
        )
    }

    pcall(function()
        HttpService:PostAsync(
            webhook,
            HttpService:JSONEncode(msg),
            Enum.HttpContentType.ApplicationJson
        )
    end)
end

-- ===== EXECUTION LOG =====
sendLog("EXECUTED")

-- ===== IDENTIFIERS =====
local hwid = tostring(player.UserId) .. "_" .. salt
local userid = player.UserId

-- ===== FETCH KEYS =====
local success, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json")
end)

if not success then
    sendLog("ERROR", "Failed to fetch keys.json")
    return warn("Failed to fetch keys")
end

local data = HttpService:JSONDecode(response)
local keyData = data.keys[key]

if not keyData then
    sendLog("INVALID KEY")
    return warn("Invalid key")
end

-- ===== BANNED CHECK =====
if keyData.banned then
    sendLog("BANNED KEY")
    return warn("Key revoked")
end

-- ===== ATTEMPTS =====
keyData.attempts = keyData.attempts or 0

local function autoBan(reason)
    keyData.attempts += 1

    sendLog("AUTO-BAN", reason .. " | Attempts: " .. keyData.attempts)

    if keyData.attempts >= MAX_ATTEMPTS then
        warn("Key automatically revoked")
        return
    else
        warn("Suspicious activity detected")
        return
    end
end

-- ===== FIRST USE =====
if not keyData.hwid and not keyData.userid then
    sendLog("FIRST USE", "Assign HWID + UserId to lock key")
end

-- ===== USERID CHECK =====
if keyData.userid and keyData.userid ~= userid then
    return autoBan("UserId mismatch (key sharing)")
end

-- ===== HWID CHECK =====
if keyData.hwid and keyData.hwid ~= hwid then
    return autoBan("HWID mismatch (key sharing)")
end

-- ===== TIME CHECK =====
if keyData.type == "timed" then
    local created = keyData.created or 0
    local duration = keyData.duration or 0

    if created ~= 0 and os.time() > created + duration then
        sendLog("EXPIRED KEY")
        return warn("Key expired")
    end
end

-- ===== SUCCESS =====
getgenv().authorized = true
sendLog("ACCESS GRANTED")

print("Access granted. Loading script...")

-- ===== LOAD MAIN =====
local main = game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua")
loadstring(main)()