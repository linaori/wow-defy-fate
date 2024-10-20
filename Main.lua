local addOnName = ...

local Memory = {
    Debug = true,
    Loaded = false,
}

local dictionary = {'A', 'B', 'C', 'D', 'E', 'F', 'Q', 'X', 'Y', 'Z'}

local function createId(timestamp)
    local p1, p2, p3, p4, p5 = tostring(timestamp):match('%d+(%d)(%d)(%d)(%d)(%d%d)')

    local major = dictionary[tonumber(p1) + 1]
    local minor = dictionary[tonumber(p2) + 1]

    -- 0 vs O, reference zero as null with N
    if p3 == '0' then p3 = 'N' end
    if p4 == '0' then p4 = 'N' end

    return major .. minor .. p3 .. p4 .. '-' .. p5
end

local function timelineDestroyed()
    if Memory.Loaded == false then return end

    local juncture = time()

    local recordings = _G.DefyFateStorage.Recordings
    -- Store recordings separate from count in case the junctures get cleared.
    -- Tracking this information is fun, but shouldn't come at the cost of performance.
    -- Currently it's only tracked because I might do something with this in the future,
    -- which means that having past information is useful.
    recordings.Count = recordings.Count + 1
    recordings.Junctures[#recordings.Junctures] = juncture

    local message = format('diverted their death to timeline %s. Alternate timelines destroyed: %d', createId(juncture), recordings.Count)

    if Memory.Debug then
        print(message)
    else
        SendChatMessage(message, 'EMOTE')
    end
end

local function onUnitAura(unit, updateInfo)
    if unit ~= 'player' then return end
    if not updateInfo.addedAuras then return end

    for _, value in pairs(updateInfo.addedAuras) do
        -- augmentation cheat death: Empty Hourglass
        if value.sourceUnit == 'player' and value.spellId == 404369 then
            timelineDestroyed()
            break
        end
    end
end

local function onAddonLoaded(addon)
    if addon ~= addOnName then return end

    Memory.Loaded = true

    if _G.DefyFateStorage ~= nil then return end

    _G.DefyFateStorage = {
        Recordings = {
            Count = 0,
            Junctures = {},
        },
    }
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('UNIT_AURA')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function (_, event, ...)
    if (event == 'UNIT_AURA') then
        onUnitAura(...)
    elseif event == 'ADDON_LOADED' then
        onAddonLoaded(...)
    end
end)

if Memory.Debug then
    _G.DefyFake = timelineDestroyed
end
