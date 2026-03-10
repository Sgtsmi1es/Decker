DeckerDB = DeckerDB or {}  --persistent saved variables table for selected layout names

local frame = CreateFrame("Frame")  --event frame used to run layout logic on login

local function GetDeviceType()

    local w = GetScreenWidth()  --current UI render width
    local h = GetScreenHeight()  --current UI render height

    if w == 1280 and h == 800 then
        return "deck"  --Steam Deck resolution match
    end

    return "desktop"  --this will fail if the res is lower or equal to the deck res, but shouldnt be an issue in most use cases
end

local function FindLayoutIndexByName(layoutName)

    if not layoutName then return nil end  --no configured layout to search for

    local layouts = C_EditMode.GetLayouts()  --fetch all Edit Mode layouts from WoW

    if not layouts or not layouts.layouts then return nil end  --Edit Mode data unavailable

    for i, layout in ipairs(layouts.layouts) do
        if layout.layoutName == layoutName then
            return layout.layoutIndex or i  --SetActiveLayout expects layoutIndex (not array position)
        end
    end

    return nil  --named layout was not found
end

local function ApplyLayout()

    local device = GetDeviceType()  --resolve whether this client is deck or desktop

    local targetLayout

    if device == "deck" then
        targetLayout = DeckerDB.deckLayoutName  --use saved deck layout name
    else
        targetLayout = DeckerDB.desktopLayoutName  --use saved desktop layout name
    end

    local index = FindLayoutIndexByName(targetLayout)  --convert layout name to active layout index

    if index then
        C_EditMode.SetActiveLayout(index)  --switch to selected Edit Mode layout
    end
end

frame:RegisterEvent("PLAYER_LOGIN")  --run once when character enters the world

frame:SetScript("OnEvent", function()

    ApplyLayout()  --apply the correct layout automatically at login

end)

Decker = {}  --optional public table for slash commands/other addons

Decker.ApplyLayout = ApplyLayout  --expose manual reapply helper
Decker.GetDeviceType = GetDeviceType  --expose device detection helper
