DeckerDB = DeckerDB or {}  --persistent saved variables table for selected layout names

local frame = CreateFrame("Frame")  --event frame used to run layout logic on login

local function Debug(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff98Decker:|r " .. tostring(message))
    end
end

local function GetDeviceType()

    local w = GetScreenWidth()  --current UI render width
    local h = GetScreenHeight()  --current UI render height

    if w == 1280 and h == 800 then
        return "deck"  --Steam Deck resolution match
    end

    return "desktop"  --this will fail if the res is lower or equal to the deck res, but shouldnt be an issue in most use cases
end

local function FindLayoutIndexByName(layoutName)

    if not layoutName then
        Debug("No target layout name configured; skipping apply.")
        return nil  --no configured layout to search for
    end

    local layouts = C_EditMode.GetLayouts()  --fetch all Edit Mode layouts from WoW

    if not layouts or not layouts.layouts then
        Debug("Edit Mode layouts are unavailable right now.")
        return nil  --Edit Mode data unavailable
    end

    for i, layout in ipairs(layouts.layouts) do
        if layout.layoutName == layoutName then
            local resolvedIndex = layout.layoutIndex or i
            Debug("Matched layout '" .. layoutName .. "' to layoutIndex=" .. tostring(layout.layoutIndex) .. " (arrayPosition=" .. tostring(i) .. ")")
            return resolvedIndex  --SetActiveLayout expects layoutIndex (not array position)
        end
    end

    Debug("Configured layout name not found: '" .. tostring(layoutName) .. "'.")
    return nil  --named layout was not found
end

local function ApplyLayout(trigger)

    local device = GetDeviceType()  --resolve whether this client is deck or desktop
    local source = trigger or "manual"

    local targetLayout

    if device == "deck" then
        targetLayout = DeckerDB.deckLayoutName  --use saved deck layout name
    else
        targetLayout = DeckerDB.desktopLayoutName  --use saved desktop layout name
    end

    Debug("ApplyLayout(" .. source .. "): device=" .. tostring(device) .. ", targetLayout=" .. tostring(targetLayout))

    local index = FindLayoutIndexByName(targetLayout)  --convert layout name to active layout index

    if index then
        Debug("Calling C_EditMode.SetActiveLayout(" .. tostring(index) .. ")")
        C_EditMode.SetActiveLayout(index)  --switch to selected Edit Mode layout
    else
        Debug("No layout index resolved; SetActiveLayout not called.")
    end
end

frame:RegisterEvent("PLAYER_LOGIN")  --run once when character enters the world

frame:SetScript("OnEvent", function(_, event)

    Debug("Event fired: " .. tostring(event))
    ApplyLayout("login")  --apply the correct layout automatically at login

end)

Decker = {}  --optional public table for slash commands/other addons

Decker.ApplyLayout = ApplyLayout  --expose manual reapply helper
Decker.GetDeviceType = GetDeviceType  --expose device detection helper
Decker.Debug = Debug  --expose debug helper for config panel logging
