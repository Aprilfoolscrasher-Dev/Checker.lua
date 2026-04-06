local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 🔐 CONFIG
local WEBHOOK = "https://01kng0zz9p63z2ach5re524vav.hooks.webhookrelay.com"
local KEY_URL = "https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json"
local MAIN_URL = "https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua"

-- 🔑 KEY
local key = rawget(getgenv(), "script_key")

if not key then
    return
end

-- 🧠 Fake delay (anti skid copy)
task.wait(math.random(2,5))

-- 🔒 HWID (harder to spoof)
local hwid = tostring(player.UserId)
    ..":"..tostring(game.PlaceId)
    ..":"..tostring(game.JobId)

-- 🚨 Stealth logger
local function log(title, color, data)
    task.spawn(function()
        pcall(function()
            request({
                Url = WEBHOOK,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = title,
                        color = color,
                        fields = data,
                        footer = {
                            text = os.date("%c")
                        }
                    }}
                })
            })
        end)
    end)
end

-- 🔍 Tamper check
if not request or not HttpService then
    log("⚠️ ENV TAMPER", 0xffff00, {
        {name="User", value=tostring(player.UserId)}
    })
    return
end

-- 🌐 Fetch keys
local success, response = pcall(function()
    return game:HttpGet(KEY_URL)
end)

if not success then
    log("❌ FETCH FAIL", 0xff0000, {
        {name="User", value=tostring(player.UserId)}
    })
    return
end

local data = HttpService:JSONDecode(response)
local keyData = data.keys and data.keys[key]

-- 🚫 Invalid key
if not keyData then
    log("🚫 INVALID", 0xff0000, {
        {name="Key", value=key},
        {name="User", value=tostring(player.UserId)}
    })
    return
end

-- 🚫 Banned
if keyData.banned then
    log("🚫 BANNED", 0xff0000, {
        {name="Key", value=key}
    })
    return
end

-- 🆕 First use
if not keyData.hwid or keyData.hwid == "" then
    log("🆕 FIRST USE", 0xffff00, {
        {name="Key", value=key},
        {name="HWID", value=hwid}
    })
end

-- 🚨 HWID mismatch
if keyData.hwid and keyData.hwid ~= hwid then
    log("🚨 SHARE DETECTED", 0xff0000, {
        {name="Expected", value=keyData.hwid},
        {name="Got", value=hwid}
    })
    return
end

-- ⛔ Expired
if keyData.type == "timed" then
    local created = keyData.created or 0
    local duration = keyData.duration or 0

    if os.time() > created + duration then
        log("⛔ EXPIRED", 0xff0000, {
            {name="Key", value=key}
        })
        return
    end
end

-- ✅ SUCCESS (silent + visible)
log("✅ AUTHORIZED", 0x00ff00, {
    {name="User", value=tostring(player.UserId)},
    {name="Game", value=tostring(game.PlaceId)}
})

-- 🕵️ Anti dump trick
local _ENV = nil

-- 📦 Load main (protected)
task.spawn(function()
    local ok, code = pcall(function()
        return game:HttpGet(MAIN_URL)
    end)

    if ok and code then
        local f = loadstring(code)
        if f then
            pcall(f)
        end
    else
        log("❌ MAIN FAIL", 0xff0000, {})
    end
end)