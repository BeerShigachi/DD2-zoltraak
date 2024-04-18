-- author : BeerShigachi
-- date : 18 April 2024

-- CONFIG:
local POWER_ATTACK_CHARGE_PERIOD = 7.0 -- 1 as default. longer charging period results higher damage.
local QUICK_CHARGE_PERIOD = 0.5 -- 1 as default
local COMBO_INTERVAL = 0.1 -- default: 0.28

local COMBO_ATTACK_RATE = 1.5 -- defalut: 1.0
local COMBO_REACTION_RATE = 1.5 -- default: 1.0
local POWER_ATTACK_RATE = 1.5 -- CAUTION: set this value high result too OP! 
local POWER_REACTION_RATE = 3 -- CAUTION: set this value high result too OP!
local ALLIVIATE_STAMINA_COST = 100

-- DO NOT TOUCH UNDER THIS LINE
local re_ = re
local sdk_ = sdk
local _DEFAULT_VALUE = 1.0
local _is_requested_by_player = false
local _charge_deltatime = 1.0

local _characterManager
local function GetCharacterManager()
    if not _characterManager then
        _characterManager = sdk_.get_managed_singleton("app.CharacterManager")
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
        _rapidShotParameter:set_field("_ComboRapidShotTime", COMBO_INTERVAL)
    end
end

local function updateBurstShotParameter(value)
    _burstShotParameter = GetBurstShotParameter()
    if _burstShotParameter then
        _burstShotParameter:set_field("_PrepareTime", value)
    end
end

local function updateMageRapidShot()
    _mageRapidShotParameter = GetMageRapidShotParameter()
    if _mageRapidShotParameter then
        _mageRapidShotParameter:set_field("_ComboRapidShotTime", COMBO_INTERVAL)
    end
end

local function updatePowerShotParameter(value)
    _powerShotParameter = GetHeavyShotParameter()
    if _powerShotParameter then
        _powerShotParameter:set_field("_PrepareTime", value)
    end
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

local function on_post_requestNormalAttack(args)
    _player_chara = GetManualPlayer()
    if _player_chara then
        local current_job = _player_chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
        if current_job == 6 or current_job == 3 then
            local obj_chara = sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara")
            if _player_chara == obj_chara then
                _is_requested_by_player = true
                updateBurstShotParameter(POWER_ATTACK_CHARGE_PERIOD)
                updatePowerShotParameter(POWER_ATTACK_CHARGE_PERIOD)
                print("player attacked")
            else
                print("someone else attacked!")
            end
        else
            print("wrong vocations")
        end
    end
end

local function on_post_release_action(rtval)
    if _is_requested_by_player then
        local hit = GetHitController()
        if hit then
            local magic_user_action_context = GetMagicUserActionContext()
            if magic_user_action_context then
                if not magic_user_action_context:get_IsChargingShot() then
                    hit:set_BaseAttackRate(COMBO_ATTACK_RATE)
                    hit:set_BaseReactionDamageRate(COMBO_REACTION_RATE)
                else
                    hit:set_BaseAttackRate(POWER_ATTACK_RATE * _charge_deltatime)
                    hit:set_BaseReactionDamageRate(POWER_REACTION_RATE * _charge_deltatime)
                end
                print("new attack rate ", hit:get_BaseAttackRate(), hit:get_BaseReactionDamageRate())
                _is_requested_by_player = false
            end
        end
    end
    return rtval
end

local function on_pre_get_spell_action ()
    local hit = GetHitController()
    if hit then
        hit:set_BaseAttackRate(_DEFAULT_VALUE) -- TODO CHECK real DEFAULT_VALUE
        hit:set_BaseReactionDamageRate(_DEFAULT_VALUE)
        print("custom skills or job changed", hit:get_BaseAttackRate(), hit:get_BaseReactionDamageRate())
    end
end

local function on_pre_request_combo(args)
    _player_chara = GetManualPlayer()
    if _player_chara then
        local current_job = _player_chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
        if current_job == 6 or current_job == 3 then
            local obj_chara = sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara")
            if _player_chara == obj_chara then
                updateBurstShotParameter(QUICK_CHARGE_PERIOD)
                updatePowerShotParameter(QUICK_CHARGE_PERIOD)
                local hit = GetHitController()
                if hit then
                    hit:set_BaseAttackRate(COMBO_ATTACK_RATE)
                    hit:set_BaseReactionDamageRate(COMBO_REACTION_RATE)
                    print("combo attack rate ", hit:get_BaseAttackRate(), hit:get_BaseReactionDamageRate())
                end
            end
        end
    end
end

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
    _staminaManager = nil
    _is_requested_by_player = false
    _charge_deltatime = 0.0
end

-- could use sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType")
sdk_.hook(sdk_.find_type_definition("app.Player"):get_method(".ctor"),
    function () end,
    function (...)
        resetScript()
        updateSorcererRapidShot()
        updateBurstShotParameter(QUICK_CHARGE_PERIOD)
        updateMageRapidShot()
        updatePowerShotParameter(QUICK_CHARGE_PERIOD)
        return ...
    end)

-- create the hook to update the base attack rate field to default when spell was used(pre hook) TRY POST HOOK FIRST!
-- app.JobMagicUserActionSelector.getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)
sdk_.hook(sdk_.find_type_definition("app.Job06ActionSelector"):get_method("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)"),
    on_pre_get_spell_action,
    function (rtval)
        return rtval
    end)

sdk_.hook(sdk_.find_type_definition("app.Job03ActionSelector"):get_method("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)"),
    on_pre_get_spell_action,
    function (rtval)
        return rtval
    end)

-- combo initialization.
sdk_.hook(sdk_.find_type_definition("app.HumanActionSelector"):get_method("requestComboAction(app.LocomotionSpeedTypeEnum)"),
    on_pre_request_combo,
    function (rtval)
        return rtval
    end)

-- JobMagicUserActionSelector.getReleaseAction does not work!
sdk_.hook(sdk_.find_type_definition("app.Job06ActionSelector"):get_method("getReleaseAction(System.UInt32)"),
    function () end,
    on_post_release_action)

sdk_.hook(sdk_.find_type_definition("app.Job03ActionSelector"):get_method("getReleaseAction(System.UInt32)"),
    function () end,
    on_post_release_action)

-- this should hook app.Job06(and03)ActionSelector.getNormalAttackAction(app.LocomotionSpeedTypeEnum, System.UInt32)
local _args_holder
sdk_.hook(sdk_.find_type_definition("app.HumanActionSelector"):get_method("requestNormalAttack(app.LocomotionSpeedTypeEnum)"),
    function (args)
        _args_holder = args
    end,
    function (rtval)
        on_post_requestNormalAttack(_args_holder)
        return rtval
    end)

-- app.JobContext.setJobChanged(app.Character.JobEnum)
sdk_.hook(sdk_.find_type_definition("app.JobContext"):get_method("setJobChanged(app.Character.JobEnum)"),
    on_pre_get_spell_action,
    function (rtval)
        _is_requested_by_player = false -- test if this works.
        return rtval
    end)

local applicatioin = sdk_.get_native_singleton("via.Application")
local application_type = sdk_.find_type_definition("via.Application")



re_.on_frame(function ()
    _human = GetManualPlayerHuman()
    print(sdk_.call_native_func(applicatioin, application_type, "get_DeltaTime"))
    if _is_requested_by_player then
        local magic_user_action_context = GetMagicUserActionContext()
        if magic_user_action_context:get_IsChargingShot() then
            if _charge_deltatime < POWER_ATTACK_CHARGE_PERIOD then
                _charge_deltatime = _charge_deltatime + sdk_.call_native_func(applicatioin, application_type, "get_DeltaTime")
                print(_charge_deltatime)
            end
            local staminaManager = GetStaminaManager()
            local max_stamina = staminaManager:get_MaxValue()
            local cost = max_stamina * 0.1 * -1.0
            staminaManager:add(cost / ALLIVIATE_STAMINA_COST, false)
        else
            _charge_deltatime = 0.0
        end
    end
end)
