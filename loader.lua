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

-- 🔒 HWID
local hwid = table.concat({
    player.UserId,
    game.PlaceId,
    game.JobId
}, ":")

-- 🧠 EXECUTOR
local executor =
    identifyexecutor and identifyexecutor()
    or syn and "Synapse"
    or "Unknown"

-- 📡 LOGGER
local function log(title, color, extra)
    local fields = {
        {name="UserId", value=tostring(player.UserId)},
        {name="Key", value=key},
        {name="HWID", value=hwid},
        {name="Executor", value=executor},
        {name="PlaceId", value=tostring(game.PlaceId)},
        {name="JobId", value=game.JobId},
        {name="Session", value=sessionId}
    }

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
                            text = os.date("%c")
                        }
                    }}
                })
            })
        end)
    end)
end

-- 🚀 START
log("🚀 EXECUTION START", 0x0099ff)

-- 🔁 MULTI EXEC
if getgenv().__LOADED then
    log("🔁 MULTI EXECUTION", 0xffff00)
else
    getgenv().__LOADED = true
end

-- 🌐 FETCH KEYS
local success, response = pcall(function()
    return game:HttpGet(KEY_URL)
end)

if not success then
    log("❌ FETCH FAIL", 0xff0000)
    return
end

local data = HttpService:JSONDecode(response)
local keyData = data.keys and data.keys[key]

-- 🚫 INVALID
if not keyData then
    log("🚫 INVALID KEY", 0xff0000)
    return
end

-- 🚫 BANNED
if keyData.banned then
    log("🚫 BANNED KEY", 0xff0000)
    return
end

-- 🆕 FIRST USE
if not keyData.hwid or keyData.hwid == "" then
    log("🆕 FIRST USE", 0xffff00, {
        {name="Assign HWID", value=hwid}
    })
end

-- 💀 LEAK DETECT
local compromised = false

if keyData.hwid and keyData.hwid ~= hwid then
    compromised = true

    log("💀 KEY LEAKED", 0xff0000, {
        {name="Expected", value=keyData.hwid},
        {name="Got", value=hwid}
    })
end

-- 💀 AUTO KILL
if compromised and AUTO_KILL then
    getgenv().__KEY_KILLED = true

    if FAKE_SUCCESS then
        log("🎭 FAKE LOAD TRAP", 0xffff00)

        print("Key valid! Loading...")

        while true do
            task.wait(10)
        end
    end

    return warn("Key invalid.")
end

-- ⛔ EXPIRE
if keyData.type == "timed" then
    if os.time() > (keyData.created + keyData.duration) then
        log("⛔ EXPIRED", 0xff0000)
        return
    end
end

-- ✅ SUCCESS
local loadTime = math.floor((tick() - startTime)*1000)

log("✅ AUTHORIZED", 0x00ff00, {
    {name="LoadTime(ms)", value=tostring(loadTime)}
})

-- 💓 HEARTBEAT
task.spawn(function()
    while true do
        task.wait(60)

        log("💓 HEARTBEAT", 0x0099ff, {
            {name="Playtime", value=tostring(math.floor(tick() - startTime))},
            {name="Players", value=tostring(#Players:GetPlayers())}
        })
    end
end)

-- 🚀 TELEPORT DETECT
task.spawn(function()
    local root = player.Character and player.Character:WaitForChild("HumanoidRootPart")

    while task.wait(10) do
        if root then
            local old = root.Position
            task.wait(1)
            local new = root.Position

            if (new - old).Magnitude > 300 then
                log("🚀 TELEPORT DETECTED", 0xff0000)
            end
        end
    end
end)

-- 👋 SESSION END
game:BindToClose(function()
    log("👋 SESSION END", 0x0099ff, {
        {name="Time", value=tostring(math.floor(tick() - startTime))}
    })
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
    else
        log("📦 MAIN EXECUTED", 0x00ff00)
    end
end)