local HttpService = game:GetService("HttpService")

-- Make sure your script_key is set
local key = getgenv().script_key
if not key or key == "" then
    return warn("No script_key provided! Set getgenv().script_key before running the loader.")
end

-- Fetch keys.json
local ok, response = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/keys.json")
end)

if not ok or not response then
    return warn("Failed to fetch keys.json. Check the URL or your HTTP Requests setting.")
end

-- Decode JSON
local data
local decodeOk, decodeErr = pcall(function()
    data = HttpService:JSONDecode(response)
end)

if not decodeOk or not data then
    return warn("Failed to decode keys.json:", decodeErr)
end

-- Get nested keys table
local keys = data["keys"]
if type(keys) ~= "table" then
    return warn("JSON format invalid: 'keys' table missing")
end

-- Check if the provided key exists
local keyData = keys[key]
if type(keyData) ~= "table" then
    return warn("Invalid key!")
end

print("Key valid! Loading main.lua...")

-- Fetch main.lua
local mainOk, mainCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Aprilfoolscrasher-Dev/Checker.lua/main/main.lua")
end)

if not mainOk or not mainCode then
    return warn("Failed to fetch main.lua. Check that main.lua exists in your repo.")
end

-- Execute main.lua
local func, loadErr = loadstring(mainCode)
if not func then
    return warn("Failed to load main.lua:", loadErr)
end

func()