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
        local this_ = func()
        if this_ then
            value = this_:call(name)
        end
    end
    return value
end

local _humanParam
local function GetHumanParam()
    _humanParam = _get_component(_humanParam, GetCharacterManager, "get_HumanParam()")
    return _humanParam
end

local _jobParam
local function GetJobParam()
    _jobParam = _get_component(_jobParam, GetHumanParam, "get_Job()")
    return _jobParam
end

local _mageParam
local function GetMageParam()
    _mageParam = _get_component(_mageParam, GetJobParam, "get_Job03Param()")
    return _mageParam
end

local _sorcererParam
local function GetSorcererParameter ()
    _sorcererParam = _get_component(_sorcererParam, GetJobParam, "get_Job06Param()")
    return _sorcererParam
end

local _burstShotParameter
local function GetBurstShotParameter()
    _burstShotParameter = _get_component(_burstShotParameter, GetSorcererParameter, "get_BurstShotParam")
    return _burstShotParameter
end

local _rapidShotParameter
local function GetSorcererRapidShotParameter()
    _rapidShotParameter = _get_component(_rapidShotParameter, GetSorcererParameter, "get_RapidShotParam")
    return _rapidShotParameter
end

local _mageRapidShotParameter
local function GetMageRapidShotParameter()
    _mageRapidShotParameter = _get_component(_mageRapidShotParameter, GetMageParam, "get_RapidShotParamProp")
    return _mageRapidShotParameter
end

local _powerShotParameter
local function GetHeavyShotParameter()
    _powerShotParameter = _get_component(_powerShotParameter, GetMageParam, "get_BurstShotParamProp")
    return _powerShotParameter
end

local function updateSorcererRapidShot()
    _rapidShotParameter = GetSorcererRapidShotParameter()
    if _rapidShotParameter then
        _rapidShotParameter:set_field("_ComboRapidShotTime", 0.1) -- 0.28 as default
    end
end

local function updateBurstShotParameter()
    _burstShotParameter = GetBurstShotParameter()
    if _burstShotParameter then
        _burstShotParameter:set_field("_PrepareTime", 0.5) -- 1 as default
    end
end

local function updateMageRapidShot()
    _mageRapidShotParameter = GetMageRapidShotParameter()
    if _mageRapidShotParameter then
        _mageRapidShotParameter:set_field("_ComboRapidShotTime", 0.1)
    end
end

local function updatePowerShotParameter()
    _powerShotParameter = GetHeavyShotParameter()
    if _powerShotParameter then
        _powerShotParameter:set_field("_PrepareTime", 0.5)
    end
end

-- local _manualPlayerHuman
-- local function GetManualPlayerHuman()
--     if not _manualPlayerHuman then
--         local characterManager = GetCharacterManager()
--         if characterManager then
--             _manualPlayerHuman = characterManager:get_ManualPlayerHuman()
--         end
--     end
--     return _manualPlayerHuman
-- end

-- local _manualPlayer
-- local function GetManualPlayer()
--     if not _manualPlayer then
--         local characterManager = GetCharacterManager()
--         if characterManager then
--             _manualPlayer = characterManager:get_ManualPlayer()
--         end
--     end
--     return _manualPlayer
-- end

-- local _staminaManager
-- local function GetStaminaManager()
--     if not _staminaManager then
--         local manualPlayer = GetManualPlayer()
--         if manualPlayer then
--             _staminaManager = manualPlayer:get_StaminaManager()
--         end
--     end
--     return _staminaManager
-- end

-- local _humanCommonActionCtrl
-- local function GetHumanCommonActionCtrl()
--     local manualPlayerHuman = GetManualPlayerHuman()
--     if manualPlayerHuman then
--         if _humanCommonActionCtrl == nil then 
--             _humanCommonActionCtrl = manualPlayerHuman:get_HumanCommonActionCtrl()
--         end
--     end
--     return _humanCommonActionCtrl
-- end

local function resetScript()
    _characterManager = nil
    _humanParam = nil
    _jobParam = nil
    _sorcererParam = nil
    _mageParam = nil
    _rapidShotParameter = nil
    _burstShotParameter = nil
    _mageRapidShotParameter = nil
    _powerShotParameter = nil
end

sdk.hook(sdk.find_type_definition("app.Player"):get_method(".ctor"),
    function () end,
    function (...)
        resetScript()
        updateSorcererRapidShot()
        updateBurstShotParameter()
        updateMageRapidShot()
        updatePowerShotParameter()
        return ...
    end
)
