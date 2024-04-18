-- author : BeerShigachi
-- date : 18 April 2024

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

local _player_chara
local function GetManualPlayer()
    if not _player_chara then
        local characterManager = GetCharacterManager()
        if characterManager then
            _player_chara = characterManager:get_ManualPlayer()
        end
    end
    return _player_chara
end

local _human
local function GetManualPlayerHuman()
    _human = _get_component(_human, GetCharacterManager, "get_ManualPlayerHuman")
    return _human
end

local _hit_controller
local function GetHitController()
    if not _hit_controller then
        local human = GetManualPlayerHuman()
        if human then
            _hit_controller = human:get_field("Hit")
        end
    end
    return _hit_controller
end

local _humanParam
local function GetHumanParam()
    _humanParam = _get_component(_humanParam, GetCharacterManager, "get_HumanParam()")
    return _humanParam
end

local _jobMagicUserActionContext
local function GetMagicUserActionContext()
    _jobMagicUserActionContext = _get_component(_jobMagicUserActionContext, GetManualPlayerHuman, "get_JobMagicUserActionContext()")
    return _jobMagicUserActionContext
end

local COMBO_ATTACK_RATE = 2.0
local COMBO_REACTION_RATE = 2.0
local POWER_ATTACK_RATE = 4.0
local POWER_REACTION_RATE = 20.0
local DEFAULT_VALUE = 1.0

local new_attack_rate = 1.0 -- default
local new_reaction_damage_rate = 1.0 --defalut

local is_requested = false
local function on_post_requestNormalAttack(args)
    _player_chara = GetManualPlayer()
    if _player_chara then
        local current_job = _player_chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
        if current_job == 6 or current_job == 3 then
            local obj_chara = sdk.to_managed_object(args[2]):get_field("Param"):get_field("Chara")
            if _player_chara == obj_chara then
                is_requested = true
                print("player attacked")
            else
                print("someone else attacked!")
            end
        else
            print("wrong vocations")
        end
    else
        print("player chara does not exist")
    end
end

local function on_post_release_action(rtval)
    if is_requested then
        local hit = GetHitController()
        if hit then
            local magic_user_action_context = GetMagicUserActionContext()
            if magic_user_action_context then
                if not magic_user_action_context:get_IsChargingShot() then
                    new_attack_rate = COMBO_ATTACK_RATE
                    new_reaction_damage_rate = COMBO_REACTION_RATE
                else
                    new_attack_rate = POWER_ATTACK_RATE
                    new_reaction_damage_rate = POWER_REACTION_RATE
                end
                hit:set_BaseAttackRate(new_attack_rate)
                hit:set_BaseReactionDamageRate(new_reaction_damage_rate)
                print("new attack rate ", hit:get_BaseAttackRate(), hit:get_BaseReactionDamageRate())
                is_requested = false
            end
        end
    end
    return rtval
end


local function on_pre_get_spell_action ()
    local hit = GetHitController()
    if hit then
        new_attack_rate = DEFAULT_VALUE
        new_reaction_damage_rate = DEFAULT_VALUE
        hit:set_BaseAttackRate(new_attack_rate)
        hit:set_BaseReactionDamageRate(new_reaction_damage_rate)
        print("custom skills ", hit:get_BaseAttackRate(), hit:get_BaseReactionDamageRate())
    end
end

local function on_pre_request_combo(args)
    _player_chara = GetManualPlayer()
    if _player_chara then
        local current_job = _player_chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
        if current_job == 6 or current_job == 3 then
            local obj_chara = sdk.to_managed_object(args[2]):get_field("Param"):get_field("Chara")
            if _player_chara == obj_chara then
                local hit = GetHitController()
                if hit then
                    new_attack_rate = COMBO_ATTACK_RATE
                    new_reaction_damage_rate = COMBO_REACTION_RATE
                    hit:set_BaseAttackRate(new_attack_rate)
                    hit:set_BaseReactionDamageRate(new_reaction_damage_rate)
                    print("combo attack rate ", hit:get_BaseAttackRate(), hit:get_BaseReactionDamageRate())
                end
            end
        end
    end
end

-- create the hook to update the base attack rate field to default when spell was used(pre hook) TRY POST HOOK FIRST!
-- app.JobMagicUserActionSelector.getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)
sdk.hook(sdk.find_type_definition("app.Job06ActionSelector"):get_method("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)"),
    on_pre_get_spell_action,
    function (rtval)
        return rtval
    end)

sdk.hook(sdk.find_type_definition("app.Job03ActionSelector"):get_method("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)"),
    on_pre_get_spell_action,
    function (rtval)
        return rtval
    end)

-- combo initialization.
sdk.hook(sdk.find_type_definition("app.HumanActionSelector"):get_method("requestComboAction(app.LocomotionSpeedTypeEnum)"),
    on_pre_request_combo,
    function (rtval)
        return rtval
    end)

-- JobMagicUserActionSelector.getReleaseAction does not work!
sdk.hook(sdk.find_type_definition("app.Job06ActionSelector"):get_method("getReleaseAction(System.UInt32)"),
    function () end,
    on_post_release_action)

sdk.hook(sdk.find_type_definition("app.Job03ActionSelector"):get_method("getReleaseAction(System.UInt32)"),
    function () end,
    on_post_release_action)

-- this should hook app.Job06(and03)ActionSelector.getNormalAttackAction(app.LocomotionSpeedTypeEnum, System.UInt32)
local _args_holder
sdk.hook(sdk.find_type_definition("app.HumanActionSelector"):get_method("requestNormalAttack(app.LocomotionSpeedTypeEnum)"),
    function (args)
        _args_holder = args
    end,
    function (rtval)
        on_post_requestNormalAttack(_args_holder)
        return rtval
    end)

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
    _player_chara = nil
    _hit_controller = nil
    _jobMagicUserActionContext = nil
    _human = nil
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

-- sdk.hook(
--     sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
--     function() end,
--     function()
--         resetScript()
--     end
-- )

re.on_frame(function ()
    -- hook_original_func()
end)
