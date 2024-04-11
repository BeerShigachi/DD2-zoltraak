-- author : BeerShigachi
-- date : 10 April 2024

local re = re
local sdk = sdk

-- CONFIG:

local _characterManager
local function GetCharacterManager()
    if not _characterManager then 
        _characterManager = sdk.get_managed_singleton("app.CharacterManager") 
    end
	return _characterManager
end

local function _get_component(value, func, name)
    if not value then
        local _parent_component = func()
        if _parent_component then
            value = _parent_component:call(name)
        end
    end
    return value
end

local _humanParam
local function GetHumanParam()
    -- if not _humanParam then
    --     local characterManager = GetCharacterManager()
    --     if characterManager then
    --         _humanParam = characterManager:get_HumanParam()
    --     end
    -- end
    -- return _humanParam
    _humanParam = _get_component(_humanParam, GetCharacterManager, "get_HumanParam()")
    return _humanParam
end

local _jobParam
local function GetJobParam()
    if not _jobParam then
        local humanParam = GetHumanParam()
        if humanParam then
            _jobParam = humanParam:get_Job()
        end
    end
    return _jobParam
    -- _jobParam_ = _get_component(_jobParam, GetHumanParam, "get_Job()")
    -- return _jobParam
end

local _sorcererParam
local function GetSorcererParam()
    if not _sorcererParam then
        local jobParam = GetJobParam()
        if jobParam then
            _sorcererParam = jobParam:get_Job06Param()
        end
    end
    return _sorcererParam
    -- _sorcererParam = _get_component(_sorcererParam, GetJobParam, "get_Job06Param()")
    -- return _sorcererParam
end

local _manualPlayerHuman
local function GetManualPlayerHuman()
    if not _manualPlayerHuman then
        local characterManager = GetCharacterManager()
        if characterManager then
            _manualPlayerHuman = characterManager:get_ManualPlayerHuman()
        end
    end
    return _manualPlayerHuman
end

local _manualPlayer
local function GetManualPlayer()
    if not _manualPlayer then
        local characterManager = GetCharacterManager()
        if characterManager then
            _manualPlayer = characterManager:get_ManualPlayer()
        end
    end
    return _manualPlayer
end

local _staminaManager
local function GetStaminaManager()
    if not _staminaManager then
        local manualPlayer = GetManualPlayer()
        if manualPlayer then
            _staminaManager = manualPlayer:get_StaminaManager()
        end
    end
    return _staminaManager
end

local _humanCommonActionCtrl
local function GetHumanCommonActionCtrl()
    local manualPlayerHuman = GetManualPlayerHuman()
    if manualPlayerHuman then
        if _humanCommonActionCtrl == nil then 
            _humanCommonActionCtrl = manualPlayerHuman:get_HumanCommonActionCtrl()
        end
    end
    return _humanCommonActionCtrl
end

local function resetScript()
    _characterManager = nil
    _humanParam = nil
    _manualPlayerHuman = nil
    _humanCommonActionCtrl = nil
    _manualPlayerHuman = nil
    _staminaManager = nil
end

local function processDeath(characterManager)
    if not characterManager then return end
    if not characterManager:get_IsManualPlayerDead() then return end
    resetScript()
end

local function initScript(sorcererParam)
    if not sorcererParam then return end
    local common = sorcererParam:get_CommonParam()
    if common then
        local walking_rate = common:get_AddRateForPreparingSpellWhileWalking()
        local v = walking_rate + 1
        print(v)
    end
end

re.on_frame(function ()
    local humanCommonActionCtrl = GetHumanCommonActionCtrl()
    local characterManager = GetCharacterManager()
    local manualPlayerHuman = GetManualPlayerHuman()
    local staminaManager = GetStaminaManager()
    local sorcererParam = GetSorcererParam()
    initScript(sorcererParam)
    processDeath(characterManager)
end)