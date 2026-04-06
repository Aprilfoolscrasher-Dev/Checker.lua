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

-- ✅ FIX: request fallback
local req = request or http_request or (syn and syn.request)

-- 🧬 SESSION
local sessionId = HttpService:GenerateGUID(false)
local startTime = tick()

-- 🔒 HWID
local hwid = player.UserId .. ":" .. game.PlaceId .. ":" .. game.JobId

-- 🧠 EXECUTOR
local executor =
    identifyexecutor and identifyexecutor()
    or (syn and "Synapse")
    or "Unknown"

-- 📡 LOGGER
local function log(title, color, extra)
    if not req then return end -- prevent crash

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
            req({
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

if not success or not response then
    log("❌ FETCH FAIL", 0xff0000)
    return
end

-- ✅ FIX: safe decode
local ok, data = pcall(function()
    return HttpService:JSONDecode(response)
end)

if not ok or not data then
    log("❌ JSON FAIL", 0xff0000)
    return
end

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
        while true do task.wait(10) end
    end

    return warn("Key invalid.")
end

-- ⛔ EXPIRE
if keyData.type == "timed" then
    if os.time() > ((keyData.created or 0) + (keyData.duration or 0)) then
        log("⛔ EXPIRED", 0xff0000)
        return
    end
end

-- ✅ SUCCESS
log("✅ AUTHORIZED", 0x00ff00)

-- 💓 HEARTBEAT
task.spawn(function()
    while task.wait(60) do
        log("💓 HEARTBEAT", 0x0099ff)
    end
end)

-- 🚀 TELEPORT DETECT (FIXED SAFE)
task.spawn(function()
    while task.wait(10) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")

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
    log("👋 SESSION END", 0x0099ff)
end)

-- 📦 LOAD MAIN
task.spawn(function()
    local ok, code = pcall(function()
        return game:HttpGet(MAIN_URL)
    end)

    if not ok or not code then
        log("❌ MAIN FETCH FAIL", 0xff0000)
        return
    end

    local f, err = loadstring(code)
    if not f then
        log("❌ LOADSTRING FAIL", 0xff0000, {
            {name="Error", value=tostring(err)}
        })
        return
    end

    local ran, err2 = pcall(f)

    if not ran then
        log("❌ RUNTIME ERROR", 0xff0000, {
            {name="Error", value=tostring(err2)}
        })
    else
        log("📦 MAIN EXECUTED", 0x00ff00)
    end
end)