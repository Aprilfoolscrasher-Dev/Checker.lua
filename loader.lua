local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 🔐 CONFIG
local WEBHOOK = "https://01kng0zz9p63z2ach5re524vav.hooks.webhookrelay.com"
local KEY_URL = "https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json"
local MAIN_URL = "https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua"

local key = rawget(getgenv(), "script_key") or "NO_KEY"

-- 🧬 UNIQUE SESSION ID
local sessionId = HttpService:GenerateGUID(false)

-- ⏱ TIMERS
local startTime = tick()
local lastHeartbeat = 0
local heartbeatInterval = 60 -- every 60s

-- 🔒 HWID (enhanced)
local hwid = table.concat({
    player.UserId,
    game.PlaceId,
    game.JobId
}, ":")

-- 🧠 EXECUTOR DETECTION
local executor =
    identifyexecutor and identifyexecutor()
    or syn and "Synapse"
    or "Unknown"

-- 📊 BASE INFO
local function baseFields()
    return {
        {name="UserId", value=tostring(player.UserId)},
        {name="Key", value=key},
        {name="HWID", value=hwid},
        {name="Executor", value=executor},
        {name="PlaceId", value=tostring(game.PlaceId)},
        {name="JobId", value=game.JobId},
        {name="Session", value=sessionId}
    }
end

-- 📡 LOGGER
local function log(title, color, extra)
    local fields = baseFields()

    if extra then
        for _,v in ipairs(extra) do
            table.insert(fields, v)
        end
    end

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
                        footer = {
                            text = "Time: "..os.date("%c")
                        }
                    }}
                })
            })
        end)
    end)
end

-- 🚀 START LOG
log("🚀 SESSION START", 0x0099ff)

-- 🚨 ENV CHECK
if not request then
    log("⚠️ REQUEST BLOCKED", 0xffff00)
end

-- 🌐 FETCH KEYS
local success, response = pcall(function()
    return game:HttpGet(KEY_URL)
end)

if not success then
    log("❌ KEY FETCH FAIL", 0xff0000)
    return
end

local decoded = HttpService:JSONDecode(response)
local keyData = decoded.keys and decoded.keys[key]

-- 🚫 INVALID
if not keyData then
    log("🚫 INVALID KEY", 0xff0000)
    return
end

-- 🚫 BANNED
if keyData.banned then
    log("🚫 BANNED KEY USED", 0xff0000)
    return
end

-- 🆕 FIRST USE
if not keyData.hwid or keyData.hwid == "" then
    log("🆕 FIRST USE", 0xffff00)
end

-- 🚨 SHARE DETECT
if keyData.hwid and keyData.hwid ~= hwid then
    log("🚨 KEY SHARING DETECTED", 0xff0000, {
        {name="Expected", value=keyData.hwid},
        {name="Got", value=hwid}
    })
    return
end

-- ⛔ EXPIRE
if keyData.type == "timed" then
    if os.time() > (keyData.created + keyData.duration) then
        log("⛔ KEY EXPIRED", 0xff0000)
        return
    end
end

-- ⏱ LOAD TIME
local loadTime = math.floor((tick() - startTime)*1000)

log("✅ AUTHORIZED", 0x00ff00, {
    {name="LoadTime(ms)", value=tostring(loadTime)}
})

-- 🕵️ BEHAVIOR TRACKING
local joinTime = tick()
local suspiciousFlags = 0

task.spawn(function()
    while true do
        task.wait(heartbeatInterval)

        local playtime = math.floor(tick() - joinTime)

        -- 🚨 suspicious patterns
        local flags = {}

        if playtime < 10 then
            table.insert(flags, "Left quickly")
            suspiciousFlags += 1
        end

        if #Players:GetPlayers() < 2 then
            table.insert(flags, "Empty server")
        end

        log("💓 HEARTBEAT", 0x0099ff, {
            {name="Playtime(s)", value=tostring(playtime)},
            {name="Players", value=tostring(#Players:GetPlayers())},
            {name="Flags", value=table.concat(flags, ", ") ~= "" and table.concat(flags, ", ") or "None"}
        })
    end
end)

-- 🕵️ REJOIN DETECT
task.spawn(function()
    task.wait(5)

    if tick() - startTime < 6 then
        log("🔁 FAST REJOIN", 0xffff00)
    end
end)

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