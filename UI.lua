-- Free Auras - window: the packs (install / update), and a few options.
-- One LibFreeUI window: free-standing (/fauras) or embedded in Free Hub.

local ADDON, ns = ...
local UI = LibStub("LibFreeUI-1.0")
local C = UI.C
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local WHITE = "Interface\\Buttons\\WHITE8x8"

local kit = UI:New({ name = "FreeAurasWindow", title = "Free Auras", sub = "Aura packs for ForeverAuras", addon = ADDON,
                     icon = MEDIA .. "icon", circle = MEDIA .. "circle", shadow = MEDIA .. "shadow", w = 760, h = 560,
                     tabs = { { "packs", "Packs" }, { "options", "Options" } } })
ns.kit = kit

local CLASS_ICONS = "Interface\\TargetingFrame\\UI-Classes-Circles"
local function ClassColor(class)
    local c = (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if c then return c.r, c.g, c.b end
    return C.text[1], C.text[2], C.text[3]
end

-- one card per pack: class icon, name, version, summary, points, state and buttons
local CARD_H = 176
local function PackCard(parent, pack)
    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(CARD_H)
    card.bg = kit:Fill(card, C.panel); card.bg:SetAllPoints()
    kit:Border(card, 0.06)
    local r, g, b = ClassColor(pack.class)
    local strip = kit:Fill(card, { r, g, b, 1 }, "ARTWORK"); strip:SetWidth(3); strip:SetPoint("TOPLEFT"); strip:SetPoint("BOTTOMLEFT")

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40); icon:SetPoint("TOPLEFT", 18, -16)
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[pack.class]
    if coords then icon:SetTexture(CLASS_ICONS); icon:SetTexCoord(unpack(coords)) else icon:SetTexture(MEDIA .. "icon") end

    local title = kit:Text(card, 17, { r, g, b, 1 }); title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1); title:SetText(pack.title .. " pack")
    local sub = kit:Text(card, 11, C.muted); sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    card.sub = sub
    local tag = kit:Text(card, 11, C.accent); tag:SetPoint("LEFT", title, "RIGHT", 10, -1); tag:SetText("YOUR CLASS")
    card.tag = tag

    local summary = kit:Text(card, 12, C.dim); summary:SetPoint("TOPLEFT", 18, -66); summary:SetPoint("RIGHT", -190, 0)
    summary:SetText(pack.summary or "")
    local y = -66 - 34
    for i, line in ipairs(pack.points or {}) do
        if i > 3 then break end
        local dot = card:CreateTexture(nil, "ARTWORK"); dot:SetTexture(MEDIA .. "circle"); dot:SetSize(6, 6)
        dot:SetVertexColor(unpack(C.accent)); dot:SetPoint("TOPLEFT", 22, y - 5)
        local fs = kit:Text(card, 12, C.text); fs:SetPoint("TOPLEFT", 34, y); fs:SetPoint("RIGHT", -190, 0); fs:SetWordWrap(false)
        fs:SetText(line)
        y = y - 18
    end

    local state = kit:Text(card, 12, C.muted); state:SetPoint("TOPRIGHT", -18, -20); state:SetJustifyH("RIGHT"); state:SetWidth(170)
    card.state = state
    card.main = kit:Button(card, "Install", 150, true, function() ns.Install(pack); kit:Refresh() end)
    card.main:SetPoint("TOPRIGHT", -18, -66)
    card.again = kit:Button(card, "Reinstall", 150, false, function() ns.Install(pack); kit:Refresh() end)
    card.again:SetPoint("TOPRIGHT", -18, -100)
    card.again.tip = "Open the import again (to restore the pack, or after deleting some of its auras)."
    -- preview: the pack in Demo mode, for any class, without installing it
    card.preview = kit:Button(card, "Preview", 150, false, function() ns.Preview(pack) end)
    card.preview:SetPoint("TOPRIGHT", -18, -134)
    card.preview.tip = "See the pack moving (Demo mode), whatever your class. Click again, or on the bar over it, to close it."
    card.preview:SetShown(ns.CanPreview(pack))

    function card.Update()
        local status, have = ns.Status(pack)
        if card.preview:IsShown() then card.preview.label:SetText(ns.PreviewKey() == pack.key and "Stop preview" or "Preview") end
        sub:SetText("Version " .. pack.version .. "  ·  " .. (pack.count or 0) .. " auras  ·  for " .. (pack.classLabel or pack.title))
        tag:SetShown(ns.PlayerClass() == pack.class)
        if status == "nofa" then
            state:SetText("ForeverAuras is not loaded"); state:SetTextColor(unpack(C.bad))
            card.main.label:SetText("Install"); card.main:SetEnabled(false); card.again:Hide()
        elseif status == "missing" then
            state:SetText("Not installed"); state:SetTextColor(unpack(C.muted))
            card.main.label:SetText("Install"); card.main:SetEnabled(true); card.again:Hide()
        elseif status == "update" then
            state:SetText("Update ready  ·  " .. (have or "?") .. " to " .. pack.version); state:SetTextColor(unpack(C.accent))
            card.main.label:SetText("Update"); card.main:SetEnabled(true); card.again:Hide()
        else
            state:SetText("Installed  ·  " .. (have or pack.version)); state:SetTextColor(unpack(C.good))
            card.main.label:SetText("Up to date"); card.main:SetEnabled(false); card.again:Show()
        end
    end
    return card
end

local function DoBuild()
    if kit.frame then return end
    local pages, footer = kit:Build()
    local PAD = kit.PAD

    -- ---------------------------------------------------- packs (scrolls when there are many)
    local page = pages.packs
    local hint = kit:Hint(page, "Each pack opens in ForeverAuras' own import window: check it and click Import. Preview shows a pack moving, whatever your class.", PAD, -2, kit.W - 2 * PAD)
    local scroll = CreateFrame("ScrollFrame", nil, page)
    scroll:SetPoint("TOPLEFT", PAD, -34); scroll:SetPoint("BOTTOMRIGHT", -PAD, 4)
    local list = CreateFrame("Frame", nil, scroll)
    list:SetSize(kit.W - 2 * PAD, 10)
    scroll:SetScrollChild(list)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(s, delta)
        local max = math.max(0, list:GetHeight() - s:GetHeight())
        s:SetVerticalScroll(math.min(max, math.max(0, s:GetVerticalScroll() - delta * 40)))
    end)
    scroll:SetScript("OnSizeChanged", function(s, w) list:SetWidth(w) end)
    local cards = {}
    -- the player's class first
    local order = {}
    for _, p in ipairs(ns.packs) do order[#order + 1] = p end
    table.sort(order, function(a, b)
        local me = ns.PlayerClass()
        if (a.class == me) ~= (b.class == me) then return a.class == me end
        return a.title < b.title
    end)
    for i, pack in ipairs(order) do
        local card = PackCard(list, pack)
        card:SetPoint("TOPLEFT", 0, -(i - 1) * (CARD_H + 10)); card:SetPoint("RIGHT")
        cards[#cards + 1] = card
    end
    list:SetHeight(math.max(10, #order * (CARD_H + 10)))
    if #order == 0 then kit:Hint(list, "No pack in this version.", 0, 0, 400) end
    kit:OnRefresh(function() for _, c in ipairs(cards) do c.Update() end end)

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
