--[[
    mainui — remote bootstrap
    ----------------------------------------------------------------
    Load this single line in your executor:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/thecoolersyn/mainui/refs/heads/main/main.lua"))()

    It fetches src.lua (the library) and test.lua (the demo UI) from the same
    GitHub repo and executes them in order.
]]

local BASE = "https://raw.githubusercontent.com/thecoolersyn/mainui/refs/heads/main/"

local function fetch(name)
    local ok, source = pcall(game.HttpGet, game, BASE .. name)
    if not ok or type(source) ~= "string" or #source == 0 then
        error(("[mainui] failed to fetch %s: %s"):format(name, tostring(source)))
    end
    return source
end

local ok, err = pcall(function()
    -- src.lua returns the Library table and publishes GG into getgenv().
    getgenv().MAINUI_LIBRARY = loadstring(fetch("src.lua"))()

    -- test.lua builds the demo UI using that library.
    loadstring(fetch("test.lua"))()
end)

if not ok then
    warn("[mainui] load failed:", err)
else
    print("[mainui] loaded from GitHub successfully")
end
