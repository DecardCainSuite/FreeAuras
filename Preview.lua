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

function ns.Preview(pack)
    if current == pack.key then ns.StopPreview() return end
    ns.StopPreview()
    local t, err = Decode(pack)
    if not t then ns.Print("no preview: " .. err .. ".") return end
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
