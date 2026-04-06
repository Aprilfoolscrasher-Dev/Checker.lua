local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 🔐 CONFIG
local WEBHOOK = "https://01kng0zz9p63z2ach5re524vav.hooks.webhookrelay.com"
local KEY_URL = "https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json"
local MAIN_URL = "https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua"

local AUTO_KILL = true
local FAKE_SUCCESS = true

local key = rawget(getgenv(), "script_key") or "NO_KEY"

-- 🧬 SESSION
local sessionId = HttpService:GenerateGUID(false)
local startTime = tick()

-- 🔒 SMART HWID (stable but useful)
local hwid = tostring(player.UserId) .. ":" .. tostring(game.PlaceId)

-- 🧠 EXECUTOR
local executor =
    identifyexecutor and identifyexecutor()
    or "Unknown"

-- 📡 LOGGER (SMART = minimal spam)
local function log(title, color, fields)
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
                        fields = fields,
                        footer = { text = os.date("%c") }
                    }}
                })
            })
        end)
    end)
end

-- 🔁 MULTI EXEC DETECT
if getgenv().__LOADED then
    log("⚠️ MULTI EXEC", 0xffff00, {
        {name="User", value=tostring(player.UserId)},
        {name="Key", value=key}
    })
else
    getgenv().__LOADED = true
end

-- 🌐 FETCH KEYS
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

-- 🚫 INVALID
if not keyData then
    log("🚫 INVALID KEY", 0xff0000, {
        {name="Key", value=key},
        {name="User", value=tostring(player.UserId)}
    })
    return
end

-- 🚫 BANNED
if keyData.banned then
    log("🚫 BANNED KEY USED", 0xff0000, {
        {name="Key", value=key}
    })
    return
end

-- 🆕 FIRST USE
if not keyData.hwid or keyData.hwid == "" then
    log("🆕 FIRST USE", 0xffff00, {
        {name="Key", value=key},
        {name="Assign HWID", value=hwid}
    })
end

-- 💀 SMART LEAK DETECT
local compromised = false

if keyData.hwid and keyData.hwid ~= hwid then
    compromised = true

    log("💀 KEY LEAK DETECTED", 0xff0000, {
        {name="Key", value=key},
        {name="Expected", value=keyData.hwid},
        {name="Got", value=hwid},
        {name="User", value=tostring(player.UserId)}
    })
end

-- ⚡ FAST RE-EXEC DETECT
if tick() - startTime < 2 then
    log("⚡ FAST EXECUTION", 0xffff00, {
        {name="Key", value=key}
    })
end

-- 💀 AUTO KILL
if compromised and AUTO_KILL then
    if FAKE_SUCCESS then
        log("🎭 FAKE LOAD", 0xffff00, {
            {name="Key", value=key}
        })

        print("Key valid! Loading...")
        while true do task.wait(10) end
    end

    return warn("Key invalid.")
end

-- ⛔ EXPIRE
if keyData.type == "timed" then
    if os.time() > (keyData.created + keyData.duration) then
        log("⛔ EXPIRED KEY", 0xff0000, {
            {name="Key", value=key}
        })
        return
    end
end

-- ✅ SUCCESS (only once)
log("✅ AUTHORIZED", 0x00ff00, {
    {name="User", value=tostring(player.UserId)},
    {name="Executor", value=executor},
    {name="Game", value=tostring(game.PlaceId)}
})

-- 🔐 ANTI DUMP
local _ENV = nil

-- 📦 LOAD MAIN
task.spawn(function()
    local ok, code = pcall(function()
        return game:HttpGet(MAIN_URL)
    end)

    if not ok then
        log("❌ MAIN FETCH FAIL", 0xff0000)
        return
    end

    local f = loadstring(code)
    if not f then
        log("❌ LOADSTRING FAIL", 0xff0000)
        return
    end

    local ran, err = pcall(f)

    if not ran then
        log("❌ RUNTIME ERROR", 0xff0000, {
            {name="Error", value=tostring(err)}
        })
    end
end)