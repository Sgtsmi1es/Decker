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
    local layoutList = layouts and (layouts.layouts or layouts)

    if type(layoutList) ~= "table" then
        Debug("Edit Mode layouts are unavailable right now.")
        return nil  --Edit Mode data unavailable
    end

    for key, layout in pairs(layoutList) do
        if layout.layoutName == layoutName then
            local explicitIndex = tonumber(layout.layoutIndex) or tonumber(layout.layoutID) or tonumber(layout.id)

            if type(explicitIndex) == "number" then
                return explicitIndex  --prefer an explicit layout identifier returned by the API
            end

            if type(key) == "number" then
                return key  --some client builds expose the layout index as the table key only
            end

            Debug("Matched layout name but no explicit index was present; probing indices via C_EditMode.GetLayoutInfo.")
            break
        end
    end

    -- Some clients return names from GetLayouts without a usable numeric index.
    -- Probe the known index space and match by layout name using GetLayoutInfo(index).
    if type(C_EditMode.GetLayoutInfo) == "function" then
        local missesInARow = 0

        for probeIndex = 0, 200 do
            local info = C_EditMode.GetLayoutInfo(probeIndex)

            if info and info.layoutName then
                missesInARow = 0

                if info.layoutName == layoutName then
                    return probeIndex
                end
            else
                missesInARow = missesInARow + 1

                if missesInARow >= 20 then
                    break  --stop once we've seen a long run of empty slots
                end
            end
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
Decker.Debug = Debug  --expose debug output helper for config/actions
