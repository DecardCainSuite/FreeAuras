-- Free Auras - window: the packs (install / update), and a few options.
-- One LibFreeUI window: free-standing (/fauras) or embedded in Free Hub.

local ADDON, ns = ...
local UI = LibStub("LibFreeUI-1.0")
local C = UI.C
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local WHITE = "Interface\\Buttons\\WHITE8x8"

local kit = UI:New({ name = "FreeAurasWindow", title = "Free Auras", sub = "Aura packs for ForeverAuras", addon = ADDON,
                     icon = MEDIA .. "icon", circle = MEDIA .. "circle", shadow = MEDIA .. "shadow", w = 760, h = 600,
                     tabs = { { "packs", "Packs" }, { "options", "Options" } } })
ns.kit = kit

local CLASS_ICONS = "Interface\\TargetingFrame\\UI-Classes-Circles"
local function ClassColor(class)
    local c = (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if c then return c.r, c.g, c.b end
    return C.text[1], C.text[2], C.text[3]
end

-- the classes, in a fixed order (tiles); the player's class is selected first
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local CLASS_NAMES = { WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
                      SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid" }
local function ClassIcon(tex, class)
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then tex:SetTexture(CLASS_ICONS); tex:SetTexCoord(unpack(coords)) else tex:SetTexture(MEDIA .. "icon"); tex:SetTexCoord(0, 1, 0, 1) end
end
local function PacksOf(class)
    local out = {}
    for _, p in ipairs(ns.packs) do if p.class == class then out[#out + 1] = p end end
    return out
end

-- one card per pack of the chosen class: name, version, state, summary, points and buttons
local function PackCard(parent)
    local card = CreateFrame("Frame", nil, parent)
    card.bg = kit:Fill(card, C.panel); card.bg:SetAllPoints()
    kit:Border(card, 0.06)
    card.strip = kit:Fill(card, C.accent, "ARTWORK"); card.strip:SetHeight(3); card.strip:SetPoint("TOPLEFT"); card.strip:SetPoint("TOPRIGHT")
    card.title = kit:Text(card, 16, C.text); card.title:SetPoint("TOPLEFT", 16, -14); card.title:SetWordWrap(false)
    card.sub = kit:Text(card, 11, C.muted); card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -3)
    card.state = kit:Text(card, 11, C.muted); card.state:SetPoint("TOPLEFT", card.sub, "BOTTOMLEFT", 0, -3)
    card.summary = kit:Text(card, 12, C.dim); card.summary:SetPoint("TOPLEFT", 16, -72); card.summary:SetPoint("RIGHT", -16, 0)
    card.points = {}
    for i = 1, 3 do
        local dot = card:CreateTexture(nil, "ARTWORK"); dot:SetTexture(MEDIA .. "circle"); dot:SetSize(6, 6); dot:SetVertexColor(unpack(C.accent))
        local fs = kit:Text(card, 11, C.text); fs:SetPoint("RIGHT", -16, 0)
        card.points[i] = { dot = dot, fs = fs }
    end
    card.main = kit:Button(card, "Install", 100, true, function() if card.pack then ns.Install(card.pack); kit:Refresh() end end)
    card.main:SetPoint("BOTTOMLEFT", 16, 14)
    card.again = kit:Button(card, "Reinstall", 86, false, function() if card.pack then ns.Install(card.pack); kit:Refresh() end end)
    card.again:SetPoint("LEFT", card.main, "RIGHT", 8, 0)
    card.again.tip = "Open the import again (to restore the pack, or after deleting some of its auras)."
    card.preview = kit:Button(card, "Preview", 104, false, function() if card.pack then ns.Preview(card.pack) end end)
    card.preview:SetPoint("BOTTOMRIGHT", -16, 14)
    card.preview.tip = "See the pack moving, whatever your class, without installing it. Click again, or on the bar over it, to close it."

    function card.Set(pack)
        card.pack = pack
        local r, g, b = ClassColor(pack.class)
        card.strip:SetVertexColor(r, g, b, 1)
        card.title:SetText(pack.title .. " pack"); card.title:SetTextColor(r, g, b, 1)
        card.summary:SetText(pack.summary or "")
        local prev = card.summary
        for i, p in ipairs(card.points) do
            local line = pack.points and pack.points[i]
            p.dot:SetShown(line ~= nil); p.fs:SetShown(line ~= nil)
            if line then
                p.fs:ClearAllPoints(); p.fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", i == 1 and 16 or 0, i == 1 and -10 or -6); p.fs:SetPoint("RIGHT", card, "RIGHT", -16, 0)
                p.dot:ClearAllPoints(); p.dot:SetPoint("TOPRIGHT", p.fs, "TOPLEFT", -6, -4)
                p.fs:SetText(line)
                prev = p.fs
            end
        end
        card.preview:SetShown(ns.CanPreview(pack))
        card.Update()
    end
    function card.Update()
        local pack = card.pack
        if not pack then return end
        local status, have = ns.Status(pack)
        card.sub:SetText("Version " .. pack.version .. "  ·  " .. (pack.count or 0) .. (pack.count == 1 and " aura" or " auras"))
        card.preview.label:SetText(ns.PreviewKey() == pack.key and "Stop preview" or "Preview")
        local st = card.state
        if status == "nofa" then
            st:SetText("ForeverAuras is not loaded"); st:SetTextColor(unpack(C.bad))
            card.main.label:SetText("Install"); card.main:SetEnabled(false); card.again:Hide()
        elseif status == "missing" then
            st:SetText("Not installed"); st:SetTextColor(unpack(C.muted))
            card.main.label:SetText("Install"); card.main:SetEnabled(true); card.again:Hide()
        elseif status == "update" then
            st:SetText("Update ready  ·  " .. (have or "?") .. " to " .. pack.version); st:SetTextColor(unpack(C.accent))
            card.main.label:SetText("Update"); card.main:SetEnabled(true); card.again:Hide()
        else
            st:SetText("Installed  ·  " .. (have or pack.version)); st:SetTextColor(unpack(C.good))
            card.main.label:SetText("Up to date"); card.main:SetEnabled(false); card.again:Show()
        end
    end
    return card
end

-- one tile per class: its icon and name; a dot when one of its packs is installed (green) or can be updated (orange)
local function ClassTile(parent, class, onClick)
    local t = CreateFrame("Button", nil, parent)
    t.bg = kit:Fill(t, C.panel); t.bg:SetAllPoints()
    kit:Border(t, 0.06)
    t.icon = t:CreateTexture(nil, "ARTWORK"); t.icon:SetSize(30, 30); t.icon:SetPoint("TOP", 0, -8)
    ClassIcon(t.icon, class)
    t.name = kit:Text(t, 11, C.dim); t.name:SetPoint("BOTTOM", 0, 7); t.name:SetJustifyH("CENTER"); t.name:SetText(CLASS_NAMES[class])
    t.dot = t:CreateTexture(nil, "OVERLAY"); t.dot:SetTexture(MEDIA .. "circle"); t.dot:SetSize(8, 8); t.dot:SetPoint("TOPRIGHT", -5, -5)
    t.under = kit:Fill(t, C.accent, "OVERLAY"); t.under:SetHeight(2); t.under:SetPoint("BOTTOMLEFT"); t.under:SetPoint("BOTTOMRIGHT")
    t:SetScript("OnClick", function() onClick(class) end)
    t:SetScript("OnEnter", function(s) if not s.selected then s.bg:SetVertexColor(unpack(C.hover)) end end)
    t:SetScript("OnLeave", function(s) s.bg:SetVertexColor(unpack(s.selected and C.control or C.panel)) end)
    function t.Update(selected)
        t.selected = selected
        local r, g, b = ClassColor(class)
        t.bg:SetVertexColor(unpack(selected and C.control or C.panel))
        t.under:SetShown(selected); t.under:SetVertexColor(r, g, b, 1)
        t.name:SetTextColor(unpack(selected and C.text or C.dim))
        local packs = PacksOf(class)
        t.icon:SetDesaturated(#packs == 0); t:SetAlpha(#packs == 0 and 0.45 or 1)
        local dot
        for _, p in ipairs(packs) do
            local st = ns.Status(p)
            if st == "update" then dot = C.accent elseif st == "ok" and dot == nil then dot = C.good end
        end
        t.dot:SetShown(dot ~= nil)
        if dot then t.dot:SetVertexColor(dot[1], dot[2], dot[3], 1) end
    end
    return t
end

local function DoBuild()
    if kit.frame then return end
    local pages, footer = kit:Build()
    local PAD = kit.PAD

    -- ---------------------------------------------------- packs: a tile per class, then the packs of the chosen class
    local page = pages.packs
    kit:Hint(page, "Pick a class, then Install (ForeverAuras' import window opens: check it and click Import) or Preview to see a pack moving.", PAD, -2, kit.W - 2 * PAD)
    local tiles, n = {}, #CLASSES
    local gap = 6
    local tw = (kit.W - 2 * PAD - (n - 1) * gap) / n
    local cards = { PackCard(page), PackCard(page) }
    local function Show(class)
        kit.faClass = class
        local packs = PacksOf(class)
        local w = kit.W - 2 * PAD
        for i, card in ipairs(cards) do
            local pack = packs[i]
            card:ClearAllPoints()
            if pack then
                local cw = (#packs > 1) and (w - 10) / 2 or w
                card:SetPoint("TOPLEFT", page, "TOPLEFT", PAD + (i - 1) * (cw + 10), -100)
                card:SetPoint("BOTTOM", page, "BOTTOM", 0, 4)
                card:SetWidth(cw)
                card.Set(pack); card:Show()
            else card:Hide() end
        end
        if not cards.none then cards.none = kit:Hint(page, "No pack for this class yet.", PAD, -104, 400) end
        cards.none:SetShown(#packs == 0)
        kit:Refresh()
    end
    for i, class in ipairs(CLASSES) do
        local t = ClassTile(page, class, Show)
        t:SetSize(tw, 60); t:SetPoint("TOPLEFT", PAD + (i - 1) * (tw + gap), -30)
        tiles[class] = t
    end
    kit:OnRefresh(function()
        for class, t in pairs(tiles) do t.Update(class == kit.faClass) end
        for _, c in ipairs(cards) do if c:IsShown() then c.Update() end end
    end)
    -- first time: your class (or the first class with a pack)
    local first = ns.PlayerClass()
    if #PacksOf(first or "") == 0 then for _, c in ipairs(CLASSES) do if #PacksOf(c) > 0 then first = c; break end end end
    Show(first)

    -- ---------------------------------------------------- options
    local o = pages.options
    kit:Caption(o, "Messages", kit.LX, kit:Y(1) + 8)
    kit:SwitchRow(o, "Tell me at login when a pack update is ready", kit.LX, kit:Y(2), kit.COLW,
        function() local db = ns.GetDB(); return not db or db.notify ~= false end,
        function(v) local db = ns.GetDB(); if db then db.notify = v end end)
    kit:Caption(o, "Button", kit.LX, kit:Y(3) + 8)
    kit:SwitchRow(o, "Minimap button", kit.LX, kit:Y(4), kit.COLW,
        function() return ns.IsMinimapShown == nil or ns.IsMinimapShown() end,
        function(v) if ns.SetMinimapShown then ns.SetMinimapShown(v) end end)
    kit:Hint(o, "With Free Hub installed, the Free addons share one minimap button.", kit.LX, kit:Y(5) + 6, kit.COLW)
    kit:Caption(o, "About", kit.RX, kit:Y(1) + 8)
    kit:Hint(o, "The packs are built for ForeverAuras (WoW: Forever). Their pictures come with this addon: keep it enabled while you use the packs. Settings of each aura: ForeverAuras options, Custom Options tab.", kit.RX, kit:Y(2), kit.COLW)

    -- ---------------------------------------------------- footer
    local open = kit:Button(footer, "Open ForeverAuras", 170, false, function() ns.OpenEngine() end)
    open:SetPoint("LEFT", PAD, 0)
    local close = kit:Button(footer, "Close", 120, true, function() kit.frame:Hide() end)
    close:SetPoint("RIGHT", -PAD, 0)
    kit:OnRefresh(function() close:SetShown(not kit.frame.fhEmbedded) end)
end
ns.Build = DoBuild

kit:RegisterHub("FreeAuras", DoBuild, function(show) if ns.ApplyMinimapVisibility then ns.ApplyMinimapVisibility(show) end end)

function ns.Toggle()
    kit:Toggle("FreeAuras", DoBuild)
end
