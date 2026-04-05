local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ===== CONFIG =====
local key = getgenv().script_key
local webhook = "https://discord.com/api/webhooks/1477468087522427025/hsD3J0iDmB9oqwEhZhBL8QF4kPZIQlJlQl4dKCEJCt9IFAhvpdkjV4dSZ2NFjUl0TgPE”
local WEBHOOK_URL = "https://discord.com/api/webhooks/1488676937802055883/-hZc3klPkb_zQaRWjkgsvAB63kXSeLT3r6vYObSS9wmx2NZEd6tgTg8xcSQEBvVpQT6w"
local salt = "my_secret_salt_1234"
local MAX_ATTEMPTS = 2

if not key or key == "" then
    return warn("No script_key set")
end

-- ===== IDENTIFIERS =====
local hwid = tostring(player.UserId) .. "_" .. salt
local userid = player.UserId

-- ===== FETCH KEYS =====
local success, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json")
end)
if not success then return warn("Failed to fetch keys") end

local data = HttpService:JSONDecode(response)
local keyData = data.keys[key]

if not keyData then
    return warn("Invalid key")
end

-- ===== BANNED CHECK =====
if keyData.banned then
    return warn("Key revoked")
end

-- ===== ATTEMPT TRACKING =====
keyData.attempts = keyData.attempts or 0

local function logAndBlock(reason)
    keyData.attempts += 1

    local msg = {
        content = string.format(
            "**AUTO-BAN TRIGGERED**\nReason: %s\nKey: %s\nUserId: %s\nHWID: %s\nAttempts: %d/%d",
            reason, key, userid, hwid, keyData.attempts, MAX_ATTEMPTS
        )
    }

    pcall(function()
        HttpService:PostAsync(webhook, HttpService:JSONEncode(msg), Enum.HttpContentType.ApplicationJson)
    end)

    -- Smart threshold
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
    local msg = {
        content = string.format(
            "**FIRST USE**\nKey: %s\nUserId: %s\nHWID: %s\nAssign these to lock.",
            key, userid, hwid
        )
    }

    pcall(function()
        HttpService:PostAsync(webhook, HttpService:JSONEncode(msg), Enum.HttpContentType.ApplicationJson)
    end)
end

-- ===== USERID CHECK =====
if keyData.userid and keyData.userid ~= userid then
    return logAndBlock("UserId mismatch (key sharing)")
end

-- ===== HWID CHECK =====
if keyData.hwid and keyData.hwid ~= hwid then
    return logAndBlock("HWID mismatch (key sharing)")
end

-- ===== TIME CHECK =====
if keyData.type == "timed" then
    local created = keyData.created or 0
    local duration = keyData.duration or 0

    if os.time() > created + duration then
        return warn("Key expired")
    end
end

-- ===== AUTHORIZE =====
getgenv().authorized = true

print("Access granted. Loading script...")
-- ===== EXECUTION LOGGER (FIXED) =====

local function getHWID()
    local hwid = "Unknown"

    pcall(function()
        if gethwid then
            hwid = gethwid()
        elseif syn and syn.gethwid then
            hwid = syn.gethwid()
        elseif identifyexecutor then
            hwid = identifyexecutor()
        end
    end)

    return tostring(hwid)
end

local function sendLog()
    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "🚀 SinX Execution",
            ["color"] = 16753920,
            ["fields"] = {
                {
                    ["name"] = "User",
                    ["value"] = player.Name,
                    ["inline"] = true
                },
                {
                    ["name"] = "UserId",
                    ["value"] = tostring(userid),
                    ["inline"] = true
                },
                {
                    ["name"] = "Key",
                    ["value"] = tostring(key),
                    ["inline"] = false
                },
                {
                    ["name"] = "HWID / Executor",
                    ["value"] = getHWID(),
                    ["inline"] = false
                }
            }
        }}
    }

    pcall(function()
        if syn and syn.request then
            syn.request({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        elseif http_request then
            http_request({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        elseif request then
            request({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
end

task.spawn(sendLog)

-- ===== LOAD MAIN =====
local main = game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua")
loadstring(main)()