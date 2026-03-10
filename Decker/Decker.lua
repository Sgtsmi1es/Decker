DeckerDB = DeckerDB or {}
DeckerDB.layoutList = DeckerDB.layoutList or {}

local frame = CreateFrame("Frame")  --event frame used to run layout logic on login

local function Debug(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff98Decker:|r " .. tostring(message))
    end
end

local function GetDeviceType()

    local h = GetScreenHeight()  --current UI render height

    if h == 800 then
        return "deck"  --Steam Deck resolution match
    end

    return "desktop"  --this will fail if the res is lower or equal to the deck res, but shouldnt be an issue in most use cases
end

local function RefreshLayoutList()
    local layouts = C_EditMode.GetLayouts()
    local layoutList = layouts and (layouts.layouts or layouts)
    if type(layoutList) ~= "table" then return end
    local newList = {}
    for key, layout in pairs(layoutList) do
        if layout and layout.layoutName then
            -- Use key as id: Blizzard may key layouts by SetActiveLayout index (e.g. 3,4,5 for custom after defaults)
            local id = (type(key) == "number" and key) or tonumber(layout.layoutIndex) or tonumber(layout.layoutID) or tonumber(layout.id)
            if id then
                table.insert(newList, { name = layout.layoutName, id = id })
            end
        end
    end
    if #newList > 0 then
        DeckerDB.layoutList = newList
    end
end

local function FindLayoutIndexByName(layoutName)
    if not layoutName then return nil end
    RefreshLayoutList()
    for _, entry in ipairs(DeckerDB.layoutList) do
        if entry.name == layoutName then
            return entry.id
        end
    end
    return nil
end

local function ApplyLayout(trigger, retryCount)

    local device = GetDeviceType()  --resolve whether this client is deck or desktop
    local source = trigger or "manual"
    retryCount = retryCount or 0

    local targetLayout

    if device == "deck" then
        targetLayout = DeckerDB.deckLayoutName  --use saved deck layout name
    else
        targetLayout = DeckerDB.desktopLayoutName  --use saved desktop layout name
    end

    RefreshLayoutList()
    if targetLayout and #DeckerDB.layoutList == 0 and source == "login" and retryCount < 3 then
        C_Timer.After((retryCount + 1) * 2, function() ApplyLayout("login", retryCount + 1) end)
        return
    end

    local index = FindLayoutIndexByName(targetLayout)
    if index then
        C_EditMode.SetActiveLayout(index + 2)  -- presets 1=Modern, 2=Classic; custom layouts start at 3
        Debug("Applied layout: " .. tostring(targetLayout))
    end
end

frame:RegisterEvent("PLAYER_LOGIN")  --run once when character enters the world

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2, function() ApplyLayout("login") end)
    end
end)

Decker = {}  --optional public table for slash commands/other addons

Decker.ApplyLayout = ApplyLayout  --expose manual reapply helper
Decker.GetDeviceType = GetDeviceType  --expose device detection helper
Decker.Debug = Debug  --expose debug output helper for config/actions
