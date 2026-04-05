local HttpService = game:GetService("HttpService")

-- ====== 1️⃣ Make sure script key is set ======
local key = getgenv().script_key
if not key or key == "" then
    return warn("No script_key provided! Set getgenv().script_key before running the loader.")
end

-- ====== 2️⃣ Fetch keys.json from GitHub ======
local success, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json")
end)

if not success or not response then
    return warn("Failed to fetch keys.json. Check HTTP requests or URL.")
end

-- ====== 3️⃣ Decode JSON ======
local data
local ok, err = pcall(function()
    data = HttpService:JSONDecode(response)
end)
if not ok or not data then
    return warn("Failed to decode keys.json:", err)
end

-- ====== 4️⃣ Get keys table ======
local keys = data["keys"]
if type(keys) ~= "table" then
    return warn("JSON format invalid: 'keys' table missing")
end

-- ====== 5️⃣ Validate key ======
local keyData = keys[key]
if type(keyData) ~= "table" then
    return warn("Invalid key!")
end

-- ====== 6️⃣ Optional: check timed keys ======
if keyData["type"] == "timed" then
    -- created = time when key was issued, duration = seconds valid
    local created = keyData["created"] or 0
    local duration = keyData["duration"] or 0
    if os.time() > created + duration then
        return warn("Key expired!")
    end
end

print("Key valid! Loading main.lua...")

-- ====== 7️⃣ Fetch main.lua ======
local mainOk, mainCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua")
end)
if not mainOk or not mainCode then
    return warn("Failed to fetch main.lua")
end

-- ====== 8️⃣ Execute main.lua ======
local func, loadErr = loadstring(mainCode)
if not func then
    return warn("Failed to load main.lua:", loadErr)
end

func()