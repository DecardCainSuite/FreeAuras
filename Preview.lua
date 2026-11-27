-- Free Auras - preview: shows a pack in its Demo mode, for any class, without installing it.
-- The pack's aura code is run here on a frame of ours (not in ForeverAuras), with its options at their defaults,
-- Demo ticked and the clickable bar off (no protected buttons). Only packs made of one drawn aura have a preview.

local ADDON, ns = ...

local regions = {}
local current

local function Decode(pack)
    if pack.decoded then return pack.decoded end
    local LD = LibStub and LibStub("LibDeflate", true)
    local LS = LibStub and LibStub("LibSerialize", true)
    if not (LD and LS) then return nil, "ForeverAuras' libraries (LibDeflate, LibSerialize) are not loaded" end
    local data = LD:DecodeForPrint(pack.data:sub(7))
    data = data and LD:DecompressDeflate(data)
    if not data then return nil, "the pack could not be read" end
    local ok, t = LS:Deserialize(data)
    if not ok or type(t) ~= "table" then return nil, "the pack could not be read" end
    pack.decoded = t
    return t
end

local function Copy(v)
    if type(v) ~= "table" then return v end
    local o = {}
    for k, x in pairs(v) do o[k] = Copy(x) end
    return o
end

-- the preview frame of a pack: the size of its aura, where the group would be, with a caption to close it
local function Region(pack, aura, group)
    local r = regions[pack.key]
    if not r then
        r = CreateFrame("Frame", "FreeAurasPreview_" .. pack.key, UIParent)
        r:SetFrameStrata("MEDIUM")
        r:SetMovable(true); r:SetClampedToScreen(true)
        local cap = CreateFrame("Button", nil, r)
        cap:SetHeight(18); cap:SetPoint("BOTTOMLEFT", r, "TOPLEFT", 0, 6); cap:SetPoint("BOTTOMRIGHT", r, "TOPRIGHT", 0, 6)
        cap.bg = cap:CreateTexture(nil, "BACKGROUND"); cap.bg:SetAllPoints(); cap.bg:SetColorTexture(0.07, 0.074, 0.085, 0.85)
        cap.text = cap:CreateFontString(nil, "OVERLAY"); cap.text:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE"); cap.text:SetPoint("CENTER")
        cap.text:SetText("|cffff8a3d" .. pack.title .. " pack|r  preview  ·  drag to move  ·  click to close")
        cap:RegisterForDrag("LeftButton")
        cap:SetScript("OnDragStart", function() r:StartMoving() end)
        cap:SetScript("OnDragStop", function() r:StopMovingOrSizing() end)
        cap:SetScript("OnClick", function() ns.StopPreview() end)
        regions[pack.key] = r
    end
    r:SetSize(aura.width or 200, aura.height or 200)
    if not r.placed then
        r:ClearAllPoints()
        r:SetPoint("CENTER", UIParent, "CENTER", (group.xOffset or 0) + (aura.xOffset or 0), (group.yOffset or 0) + (aura.yOffset or 0))
        r.placed = true
    end
    return r
end

function ns.CanPreview(pack)
    return pack.preview == true
end
function ns.PreviewKey() return current end

function ns.StopPreview()
    if current and regions[current] then regions[current]:Hide() end
    current = nil
    if ns.kit and ns.kit.frame then ns.kit:Refresh() end
end

-- ------------------------------------------------------------ packs of several auras (Rogue): a fake game
-- The pack's real auras (init code and triggers) run in a sandbox: global reads go first to a table of fake
-- game answers (combo points, energy, buffs, cooldowns, poisons...), then to the real game. "In combat" is
-- answered yes, so no aura places a protected button (nothing can be cast from the preview).
local FAKE = {}
local function Cycle(t, period, on, offset) return ((t + (offset or 0)) % period) < on end
FAKE.rogue = function()
    local function Now() return GetTime() end
    local function Hash(id) return (id * 7919) % 97 end
    -- your buffs and your bleeds on the target, on loops
    local function PlayerBuff(id)
        local t = Now()
        local function A(period, on, off) local p = (t + (off or 0)) % period; if p < on then return { spellId = id, expirationTime = t + on - p, duration = on, applications = 0 } end end
        if id == 6774 or id == 5171 then return A(24, 21) end
        if id == 13877 then return A(40, 15, 8) end
        if id == 13750 then return A(60, 15, 30) end
        if id == 5277 or id == 11305 or id == 1857 then return A(45, 10, Hash(id)) end
        return nil
    end
    local TARGET = { { 1943, 16, 12, 0 }, { 703, 20, 18, 6 } }
    local function TargetDebuff(i)
        local t, n = Now(), 0
        for _, d in ipairs(TARGET) do
            local p = (t + d[4]) % d[2]
            if p < d[3] then n = n + 1; if n == i then return { spellId = d[1], expirationTime = t + d[3] - p, duration = d[3], applications = 0 } end end
        end
    end
    local function CD(id)
        local h = Hash(id)
        local period = 14 + h % 24
        local p = (Now() + h) % period
        local dur = period * 0.5
        if p < dur then return Now() - p, dur end
        return 0, 0
    end
    local ENERGY, COMBO = 3, 4
    local function Combo() return math.min(5, math.floor((Now() % 9) / 1.5)) end
    local over = {
        IsPlayerSpell = function() return true end,
        IsSpellKnown = function() return true end,
        InCombatLockdown = function() return true end,
        UnitAffectingCombat = function() return true end,
        UnitExists = function(u) if u == "target" then return true end return UnitExists(u) end,
        UnitGUID = function(u) if u == "target" then return "Creature-0-0-0-0-0-preview" end return UnitGUID(u) end,
        UnitCanAttack = function(_, u) if u == "target" then return true end return UnitCanAttack("player", u) end,
        GetComboPoints = function() return Combo() end,
        UnitPower = function(u, pt)
            if pt == ENERGY then return math.floor(25 + 75 * ((Now() % 6) / 6)) end
            if pt == COMBO then return Combo() end
            return UnitPower(u, pt)
        end,
        UnitPowerMax = function(u, pt) if pt == ENERGY then return 100 elseif pt == COMBO then return 5 end return UnitPowerMax(u, pt) end,
        GetSpellCooldown = function(id) local s, d = CD(id); return s, d, 1 end,
        IsUsableSpell = function(id) if id == 14251 then return Cycle(Now(), 10, 3) end return true end,
        GetWeaponEnchantInfo = function() return true, 1500000, 40, 0, true, 900000, 8, 0 end,
        C_Secrets = { ShouldAurasBeSecret = function() return false end },
        C_Spell = setmetatable({
            GetSpellCooldown = function(id) local s, d = CD(id); return { startTime = s, duration = d, isActive = d > 0, isEnabled = true } end,
            IsSpellUsable = function(id) if id == 14251 then return Cycle(Now(), 10, 3) end return true end,
        }, { __index = C_Spell }),
        C_UnitAuras = setmetatable({
            GetPlayerAuraBySpellID = PlayerBuff,
            GetUnitAuraBySpellID = function(_, id) return PlayerBuff(id) end,
            GetAuraDataByIndex = function(unit, i, filter)
                if unit == "target" and (filter or ""):find("HARMFUL") then return TargetDebuff(i) end
                if unit == "player" then
                    local list = {}
                    for _, id in ipairs({ 6774, 13877, 13750 }) do local a = PlayerBuff(id); if a then list[#list + 1] = a end end
                    return list[i]
                end
            end,
        }, { __index = C_UnitAuras }),
        C_TooltipInfo = setmetatable({
            GetInventoryItem = function(unit, slot)
                if slot == 16 then return { lines = { { leftText = "Instant Poison VI (25 min)" } } } end
                if slot == 17 then return { lines = { { leftText = "Deadly Poison V (14 min)" } } } end
                return C_TooltipInfo.GetInventoryItem(unit, slot)
            end,
        }, { __index = C_TooltipInfo }),
    }
    return over
end

-- the bar of an "aurabar" aura (Energy): drawn here, as ForeverAuras would, fed by the fake game
local function AuraBar(region, aura, sb)
    local bar = region.fsBar
    if not bar then
        bar = CreateFrame("StatusBar", nil, region)
        bar:SetAllPoints(region)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar.bg = bar:CreateTexture(nil, "BACKGROUND"); bar.bg:SetAllPoints(); bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar.edge = bar:CreateTexture(nil, "BACKGROUND", nil, -1); bar.edge:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar.edge:SetPoint("TOPLEFT", -1, 1); bar.edge:SetPoint("BOTTOMRIGHT", 1, -1); bar.edge:SetVertexColor(0, 0, 0, 1)
        local holder = CreateFrame("Frame", nil, region)
        holder:SetAllPoints(region)
        holder.type = "subtext"
        bar.text = holder:CreateFontString(nil, "OVERLAY")
        bar.text:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
        bar.text:SetPoint("RIGHT", region, "RIGHT", -3, 0)
        bar.holder = holder
        region.fsBar = bar
    end
    local c, c2, bg = aura.barColor or { 1, 0.75, 0.2, 1 }, aura.barColor2, aura.backgroundColor or { 0.1, 0.1, 0.1, 0.8 }
    bar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
    local tex = bar:GetStatusBarTexture()
    if aura.enableGradient and c2 and tex and tex.SetGradient and CreateColor then
        local dir = (aura.gradientOrientation == "VERTICAL") and "VERTICAL" or "HORIZONTAL"
        tex:SetGradient(dir, CreateColor(c[1], c[2], c[3], c[4] or 1), CreateColor(c2[1], c2[2], c2[3], c2[4] or 1))
    end
    bar.bg:SetVertexColor(bg[1], bg[2], bg[3], bg[4] or 1)
    region.subRegions = { bar.holder }
    bar:SetScript("OnUpdate", function(self)
        local v, m = sb.UnitPower("player", 3), sb.UnitPowerMax("player", 3)
        self:SetMinMaxValues(0, m); self:SetValue(v); self.text:SetText(v)
    end)
end

local function Sandbox(over, env)
    return setmetatable({ aura_env = env }, {
        __index = function(_, k) local v = over[k]; if v ~= nil then return v end return _G[k] end,
        __newindex = function(_, k, v) _G[k] = v end,
    })
end

local function PreviewMany(pack, t)
    local root = regions[pack.key]
    local group = t.d or {}
    local top, bottom = 0, 0
    for _, c in ipairs(t.c) do
        top = math.max(top, (c.yOffset or 0) + (c.height or 0) / 2)
        bottom = math.min(bottom, (c.yOffset or 0) - (c.height or 0) / 2)
    end
    if not root then
        root = Region(pack, { width = 200, height = top - bottom, yOffset = (top + bottom) / 2 }, group)
        local over = FAKE[pack.fake]()
        local list = {}
        local WA = setmetatable({ IsOptionsOpen = function() return false end }, { __index = WeakAuras })
        over.WeakAuras = WA
        function WA.ScanEvents(event, ...)
            for _, a in ipairs(list) do if a.events[event] then a.Fire(event, ...) end end
        end
        for _, c in ipairs(t.c) do
            local r = CreateFrame("Frame", nil, root)
            r:SetSize(c.width or 200, c.height or 20)
            r:SetPoint("CENTER", root, "CENTER", c.xOffset or 0, (c.yOffset or 0) - (top + bottom) / 2)
            local cfg = Copy(c.config or {})
            local env = { id = c.id, cloneId = "", config = cfg, region = r, state = {}, states = {} }
            local sb = Sandbox(over, env)
            if c.regionType == "aurabar" then AuraBar(r, c, sb) end
            local a = { env = env, events = {}, states = {} }
            local init = c.actions and c.actions.init and c.actions.init.custom
            if init then
                local f = loadstring(init, "Free Auras preview: " .. c.id)
                if f then setfenv(f, sb); local ok, err = pcall(f); if not ok then ns.Print("preview: " .. c.id .. ": " .. tostring(err)) end end
            end
            local tr = c.triggers and c.triggers[1] and c.triggers[1].trigger
            if tr and tr.type == "custom" and tr.custom then
                local mk = loadstring("return " .. tr.custom, "Free Auras preview trigger: " .. c.id)
                local fn = mk and setfenv(mk, sb)()
                if fn then setfenv(fn, sb) end
                for ev in tostring(tr.events or ""):gmatch("[%w_]+") do a.events[ev] = true end
                a.Fire = function(event, ...)
                    if not fn then return end
                    local ok, err
                    if tr.custom_type == "status" then ok, err = pcall(fn, event, ...)
                    else ok, err = pcall(fn, a.states, event, ...) end
                    if not ok and not a.warned then a.warned = true; ns.Print("preview: " .. c.id .. ": " .. tostring(err)) end
                end
            else
                a.Fire = function() end
            end
            list[#list + 1] = a
        end
        -- the game's events, every few tenths of a second, so the triggers keep drawing
        local ARGS = { UNIT_POWER_FREQUENT = "player", UNIT_POWER_UPDATE = "player", UNIT_MAXPOWER = "player", UNIT_AURA = "player", UNIT_INVENTORY_CHANGED = "player" }
        for _, a in ipairs(list) do a.Fire("OPTIONS"); a.Fire("PLAYER_ENTERING_WORLD") end
        local acc, n = 0, 0
        root:SetScript("OnUpdate", function(_, el)
            acc = acc + el
            if acc < 0.25 then return end
            acc = 0; n = n + 1
            for _, a in ipairs(list) do
                for ev in pairs(a.events) do
                    if ev ~= "UNIT_SPELLCAST_SUCCEEDED" and ev ~= "PLAYER_DEAD" and (ev ~= "PLAYER_TARGET_CHANGED" or n % 12 == 0) then a.Fire(ev, ARGS[ev]) end
                end
            end
        end)
        root.fsEnv = list
    end
    root:Show()
    current = pack.key
    if ns.kit and ns.kit.frame then ns.kit:Refresh() end
end

function ns.Preview(pack)
    if current == pack.key then ns.StopPreview() return end
    ns.StopPreview()
    local t, err = Decode(pack)
    if not t then ns.Print("no preview: " .. err .. ".") return end
    if pack.fake and FAKE[pack.fake] then return PreviewMany(pack, t) end
    local aura
    for _, c in ipairs(t.c or {}) do
        if c.actions and c.actions.init and type(c.actions.init.custom) == "string" then aura = c end
    end
    if not aura or #(t.c or {}) ~= 1 then ns.Print("this pack has no preview.") return end
    local region = Region(pack, aura, t.d or {})
    region:Show()
    current = pack.key
    -- first time: run the aura's code on our frame, Demo on (the code keeps its drawing on the frame)
    if not region.fsEnv then
        local cfg = Copy(aura.config or {})
        cfg.demo = true
        cfg.clickable = false
        local env = { id = "Free Auras preview", cloneId = "", config = cfg, region = region, state = {}, states = {} }
        local code, cerr = loadstring(aura.actions.init.custom, "Free Auras preview: " .. pack.title)
        if not code then ns.Print("no preview: " .. tostring(cerr)) region:Hide(); current = nil; return end
        local saved = aura_env
        aura_env = env
        local ok, rerr = pcall(code)
        aura_env = saved
        if not ok then ns.Print("the preview stopped: " .. tostring(rerr)) region:Hide(); current = nil; return end
        if env.Layout then pcall(env.Layout) end
        region.fsEnv = env
    end
    if ns.kit and ns.kit.frame then ns.kit:Refresh() end
end
