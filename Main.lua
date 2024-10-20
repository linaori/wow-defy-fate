local addOnName = ...

-- do not load if the player is not an evoker
if select(3, C_PlayerInfo.GetClass({unit = 'player'})) ~= 13 then
    return
end

local DefyFateId = 404195
local EmptyHourglassId = 404369

local Memory = {
--@debug@
    Debug = true,
--@end-debug@
    Loaded = false,
    PlayerName = nil,
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

local function GetRealUnitName(unit)
    local name, realm = UnitNameUnmodified(unit)
    if name == UNKNOWNOBJECT then return nil end

    if realm == nil then
        realm = GetNormalizedRealmName() or GetRealmName():gsub('[%s-]+', '')
    end

    return name .. '-' .. realm
end

local function getPlayerRecordings()
    if Memory.PlayerName == nil then
        Memory.PlayerName = GetRealUnitName('player')

        if Memory.PlayerName == nil then
            return nil
        end
    end

    if _G.DefyFateStorage.Recordings[Memory.PlayerName] == nil then
        _G.DefyFateStorage.Recordings[Memory.PlayerName] = {
            Count = 0,
            Junctures = {},
        }
    end

    return _G.DefyFateStorage.Recordings[Memory.PlayerName]
end

local function timelineDestroyed()
    if Memory.Loaded == false then return end

    local recordings = getPlayerRecordings()
    if recordings == nil then
        if (Memory.Debug) then
            print('Unable to get player recordings in timelineDestroyed()')
        end

        return
    end

    local juncture = time()
    recordings.Count = recordings.Count + 1
    recordings.Junctures[#recordings.Junctures + 1] = juncture

    local message = format('diverted their death to timeline %s. Alternate timelines destroyed: %d', createId(juncture), recordings.Count)

    SendChatMessage(message, 'EMOTE')
end

local function resetJunctures()
    if Memory.Loaded == false then return end

    local recordings = getPlayerRecordings()
    recordings.Count = 0
    recordings.Junctures = {}

    print('Causality detected, wiping incorrect juncture information.')
end

local function onUnitAura(unit, updateInfo)
    if unit ~= 'player' then return end
    if not updateInfo.addedAuras then return end

    for _, value in pairs(updateInfo.addedAuras) do
        if value.sourceUnit == 'player' and value.spellId == EmptyHourglassId then
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
            -- Store recordings separate from count in case the junctures get cleared.
            -- Tracking this information is fun, but shouldn't come at the cost of performance.
            -- Currently it's only tracked because I might do something with this in the future,
            -- which means that having past information is useful.
            -- ['Player-Realm'] = {
            --     Count = 0,
            --     Junctures = {},
            -- }
        },
    }
end

local function onSpellsChanged(frame)
    if IsPlayerSpell(DefyFateId) then
        frame:RegisterEvent('UNIT_AURA')
    else
        frame:UnregisterEvent('UNIT_AURA')
    end
end

do
    local frameEvent = function (self, event, ...)
        if (event == 'UNIT_AURA') then
            onUnitAura(...)
        elseif event == 'SPELLS_CHANGED' then
            onSpellsChanged(self)
        elseif event == 'ADDON_LOADED' then
            onAddonLoaded(...)
        end
    end

    local frame = CreateFrame('Frame')
    frame:SetScript('OnEvent', frameEvent)
    frame:RegisterEvent('ADDON_LOADED')
    frame:RegisterEvent('SPELLS_CHANGED')
end

if Memory.Debug then
    _G.DefyFake = timelineDestroyed
    _G.DefyReset = resetJunctures
end
