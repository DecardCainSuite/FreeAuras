-- Free Auras - ready-made aura packs for ForeverAuras, installed in one click.
-- The packs (import strings) are in Packs.lua; the pictures they use are in Media\.
-- Installing goes through ForeverAuras' own import window: the player reviews and clicks Import.
-- An installed pack is recognised by the uid of its group, its version by the group's "version".

local ADDON, ns = ...
ns.packs = ns.packs or {}

local PREFIX = "|cffff8a3dFree Auras|r: "
function ns.Print(msg) print(PREFIX .. msg) end

local db
function ns.GetDB() return db end

-- ------------------------------------------------------------ ForeverAuras
-- the aura engine (ForeverAuras keeps the WeakAuras name for addons)
function ns.Engine()
    local e = (type(WeakAuras) == "table" and WeakAuras) or (type(ForeverAuras) == "table" and ForeverAuras) or nil
    if e and type(e.Import) == "function" then return e end
    return nil
end
local function Displays()
    local s = (type(ForeverAurasSaved) == "table" and ForeverAurasSaved) or (type(WeakAurasSaved) == "table" and WeakAurasSaved) or nil
    return s and type(s.displays) == "table" and s.displays or nil
end
-- the installed group of a pack (found by uid, so a renamed group is still found)
function ns.Installed(pack)
    local displays = Displays()
    if not displays then return nil end
    for _, d in pairs(displays) do
        if type(d) == "table" and d.uid == pack.uid then return d end
    end
    return nil
end
-- "nofa" (ForeverAuras missing), "missing", "update", "ok"; plus the installed version text
function ns.Status(pack)
    if not ns.Engine() then return "nofa" end
    local d = ns.Installed(pack)
    if not d then return "missing" end
    local v = tonumber(d.version) or 0
    if v < (pack.vnum or 0) then return "update", d.semver or tostring(v) end
    return "ok", d.semver or pack.version
end

-- open ForeverAuras' import window with the pack (an update targets the installed group)
function ns.Install(pack)
    local engine = ns.Engine()
    if not engine then ns.Print("ForeverAuras is not loaded: install or enable it first.") return false end
    if InCombatLockdown and InCombatLockdown() then ns.Print("the import window opens after combat.") end
    local d = ns.Installed(pack)
    local ok, err = engine.Import(pack.data, d and d.uid or nil)
    if ok == false or (ok == nil and err) then
        ns.Print("ForeverAuras refused the pack (" .. tostring(err) .. ").")
        return false
    end
    if db then db.notified = db.notified or {}; db.notified[pack.key] = pack.vnum end
    return true
end

function ns.OpenEngine()
    local engine = ns.Engine()
    if engine and engine.OpenOptions then engine.OpenOptions() else ns.Print("ForeverAuras is not loaded.") end
end

function ns.PlayerClass()
    local _, class = UnitClass("player")
    return class
end

-- ------------------------------------------------------------ login: tell once about an update
local function NotifyUpdates()
    if not db or db.notify == false then return end
    db.notified = db.notified or {}
    for _, pack in ipairs(ns.packs) do
        local status, have = ns.Status(pack)
        if status == "update" and (db.notified[pack.key] or 0) < pack.vnum then
            ns.Print(string.format("an update of the %s pack is ready (%s to %s). Type /fauras to install it.", pack.title, have or "?", pack.version))
            db.notified[pack.key] = pack.vnum
        end
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        FreeAurasDB = type(FreeAurasDB) == "table" and FreeAurasDB or {}
        db = FreeAurasDB
        db.minimap = db.minimap or { hide = false }
        db.notified = db.notified or {}
        if db.notify == nil then db.notify = true end
        return
    end
    if event == "PLAYER_LOGIN" then
        if C_Timer and C_Timer.After then C_Timer.After(6, NotifyUpdates) else NotifyUpdates() end
        if ns.OnLogin then ns.OnLogin() end
    end
end)

-- ------------------------------------------------------------ slash
SLASH_FREEAURAS1 = "/fauras"
SLASH_FREEAURAS2 = "/freeauras"
SlashCmdList.FREEAURAS = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local key = msg:match("^install%s+(%S+)$")
    if key then
        for _, pack in ipairs(ns.packs) do
            if pack.key == key then ns.Install(pack) return end
        end
        ns.Print("no pack called \"" .. key .. "\". Packs: " .. ns.PackKeys())
        return
    end
    if msg == "help" or msg == "?" then
        ns.Print("/fauras = the packs window. /fauras install <pack> = open the import of a pack (" .. ns.PackKeys() .. ").")
        return
    end
    if ns.Toggle then ns.Toggle() end
end
function ns.PackKeys()
    local t = {}
    for _, p in ipairs(ns.packs) do t[#t + 1] = p.key end
    return table.concat(t, ", ")
end
function FreeAuras_Toggle() if ns.Toggle then ns.Toggle() end end
