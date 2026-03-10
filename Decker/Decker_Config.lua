local panel = CreateFrame("Frame")  --settings panel frame shown in WoW options UI
panel.name = "Decker"  --category label in the addon settings list

-- Bounded width so descriptions wrap consistently on Deck (1280×800) and high-res; panel height from content
local DESC_WIDTH = 280

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Decker")  --header text for the settings panel

local function GetLayoutNames()

    local names = {}  --collect all available Edit Mode layout names

    local layouts = C_EditMode.GetLayouts()  --query current character's saved layouts
    local layoutList = layouts and (layouts.layouts or layouts)

    if type(layoutList) == "table" then
        for _, layout in pairs(layoutList) do
            if layout.layoutName then
                table.insert(names, layout.layoutName)  --store name for dropdown options
            end
        end
    end

    table.sort(names)  --stable alphabetical ordering for easier selection

    return names
end

local function CreateDropdown(anchor, offset)

    local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")  --classic Blizzard dropdown widget
    dropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -16, offset)

    UIDropDownMenu_SetWidth(dropdown, 220)  --consistent control width for both selectors

    return dropdown
end

local deckLabel = panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
deckLabel:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-20)
deckLabel:SetText("Steam Deck UI")

local deckDropdown = CreateDropdown(deckLabel,-6)  --dropdown storing DeckerDB.deckLayoutName

local deckDesc = panel:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
deckDesc:SetPoint("TOPLEFT",deckDropdown,"BOTTOMLEFT",0,-4)
deckDesc:SetWidth(DESC_WIDTH)
deckDesc:SetWordWrap(true)
deckDesc:SetText("Edit Mode layout used when playing on Steam Deck (1280×800).")

local desktopLabel = panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
desktopLabel:SetPoint("TOPLEFT",deckDesc,"BOTTOMLEFT",0,-16)
desktopLabel:SetText("Main Computer UI")

local desktopDropdown = CreateDropdown(desktopLabel,-6)  --dropdown storing DeckerDB.desktopLayoutName

local desktopDesc = panel:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
desktopDesc:SetPoint("TOPLEFT",desktopDropdown,"BOTTOMLEFT",0,-4)
desktopDesc:SetWidth(DESC_WIDTH)
desktopDesc:SetWordWrap(true)
desktopDesc:SetText("Edit Mode layout used on desktop or other resolutions.")

local function CreateActionButton(anchor, x, y, width, text, onClick)
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
    btn:SetSize(width, 22)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

local InitDropdown  --forward declaration so callbacks reference the local function, not a nil global

local reloadBtn = CreateActionButton(desktopDesc, 16, -16, 100, "Reload UI", function()
    ReloadUI()
end)

local reloadDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
reloadDesc:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 0, -4)
reloadDesc:SetWidth(DESC_WIDTH)
reloadDesc:SetWordWrap(true)
reloadDesc:SetText("Reload the game interface (same as /reload).")

InitDropdown = function(dropdown,key)

    UIDropDownMenu_Initialize(dropdown,function()  --rebuild menu each time the dropdown is opened

        local layouts = GetLayoutNames()  --fresh list so new layouts appear without reload

        for _,name in ipairs(layouts) do

            local info = UIDropDownMenu_CreateInfo()

            info.text = name
            info.func = function()

                DeckerDB[key] = name  --persist selected layout under the provided db key
                UIDropDownMenu_SetSelectedName(dropdown,name)  --immediately reflect current choice in UI

                if Decker and Decker.Debug then
                    Decker.Debug("Saved " .. key .. " = '" .. name .. "'.")
                end

            end

            info.checked = (DeckerDB[key] == name)  --mark active choice with check icon

            UIDropDownMenu_AddButton(info)

        end

    end)

    if DeckerDB[key] then
        UIDropDownMenu_SetSelectedName(dropdown,DeckerDB[key])
    else
        UIDropDownMenu_SetText(dropdown,"Select layout")  --placeholder when nothing is configured yet
    end
end

panel:SetScript("OnShow",function()

    DeckerDB = DeckerDB or {}  --guarantee saved vars exist before reading/writing keys

    InitDropdown(deckDropdown,"deckLayoutName")  --configure selector for Steam Deck layout
    InitDropdown(desktopDropdown,"desktopLayoutName")  --configure selector for desktop layout

end)

local category = Settings.RegisterCanvasLayoutCategory(panel,"Decker")  --register panel in WoW Settings UI
Settings.RegisterAddOnCategory(category)  --make category visible in addon list
