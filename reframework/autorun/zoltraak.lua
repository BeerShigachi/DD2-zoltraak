-- author : BeerShigachi
-- date : 20 April 2024

-- CONFIG: every values have to be float number. use float like 1.0 not 1.
local POWER_ATTACK_CHARGE_PERIOD = 3.0 -- 1.0 as default. longer charging period results higher damage.
local RAPID_CHARGE_PERIOD = 0.5 -- 1.0 as default
local COMBO_INTERVAL = 0.1 -- default: 0.28
local COMBO_ATTACK_RATE = 2.0 -- defalut: 1.0
local POWER_ATTACK_RATE = 3.5 -- CAUTION: set this value too high result OP! 
local ALLIVIATE_STAMINA_COST = 100.0 -- higher value expend less stamina.

-- DO NOT TOUCH UNDER THIS LINE
local re_ = re
local sdk_ = sdk
local _DEFAULT_VALUE = 1.0
local _is_requested_by_player = false
local _charge_deltatime = 0.0
local elapsed_time = 0.0
local _is_spell = false

local _character_manager
local function GetCharacterManager()
    if not _character_manager then
        _character_manager = sdk_.get_managed_singleton("app.CharacterManager")
    end
	return _character_manager
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

local _human_param
local function GetHumanParam()
    _human_param = _get_component(_human_param, GetCharacterManager, "get_HumanParam()")
    return _human_param
end

local _magic_user_action_context
local function GetMagicUserActionContext()
    _magic_user_action_context = _get_component(_magic_user_action_context, GetManualPlayerHuman, "get_JobMagicUserActionContext()")
    return _magic_user_action_context
end

local _job_param
local function GetJobParam()
    _job_param = _get_component(_job_param, GetHumanParam, "get_Job()")
    return _job_param
end

local _mage_param
local function GetMageParam()
    _mage_param = _get_component(_mage_param, GetJobParam, "get_Job03Param()")
    return _mage_param
end

local _sorcerer_param
local function GetSorcererParameter ()
    _sorcerer_param = _get_component(_sorcerer_param, GetJobParam, "get_Job06Param()")
    return _sorcerer_param
end

local _burst_shot_param
local function GetBurstShotParameter()
    _burst_shot_param = _get_component(_burst_shot_param, GetSorcererParameter, "get_BurstShotParam")
    return _burst_shot_param
end

local _rapid_shot_param
local function GetSorcererRapidShotParameter()
    _rapid_shot_param = _get_component(_rapid_shot_param, GetSorcererParameter, "get_RapidShotParam")
    return _rapid_shot_param
end

local _mage_rapid_shot_param
local function GetMageRapidShotParameter()
    _mage_rapid_shot_param = _get_component(_mage_rapid_shot_param, GetMageParam, "get_RapidShotParamProp")
    return _mage_rapid_shot_param
end

local _power_shot_param
local function GetHeavyShotParameter()
    _power_shot_param = _get_component(_power_shot_param, GetMageParam, "get_PowerShotParamProp")
    return _power_shot_param
end

local function updateSorcererRapidShot()
    _rapid_shot_param = GetSorcererRapidShotParameter()
    if _rapid_shot_param then
        _rapid_shot_param:set_field("_ComboRapidShotTime", COMBO_INTERVAL)
    end
end

local function updateBurstShotParameter(value)
    _burst_shot_param = GetBurstShotParameter()
    if _burst_shot_param then
        _burst_shot_param:set_field("_PrepareTime", value)
    end
end

local function updateMageRapidShot()
    _mage_rapid_shot_param = GetMageRapidShotParameter()
    if _mage_rapid_shot_param then
        _mage_rapid_shot_param:set_field("_ComboRapidShotTime", COMBO_INTERVAL)
    end
end

local function updatePowerShotParameter(value)
    _power_shot_param = GetHeavyShotParameter()
    if _power_shot_param then
        _power_shot_param:set_field("_PrepareTime", value)
    end
end

local _stamina_manager
local function GetStaminaManager()
    if not _stamina_manager then
        local manualPlayer = GetManualPlayer()
        if manualPlayer then
            _stamina_manager = manualPlayer:get_StaminaManager()
        end
    end
    return _stamina_manager
end

local function on_post_requestNormalAttack()
    local current_job = _player_chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
    if current_job == 6 or current_job == 3 then
        _is_spell = false
        _is_requested_by_player = true
        updateBurstShotParameter(POWER_ATTACK_CHARGE_PERIOD)
        updatePowerShotParameter(POWER_ATTACK_CHARGE_PERIOD)
        print("player attacked")
    end
end

local function on_post_release_action()
    if _is_spell then return end
    _hit_controller = GetHitController()
    if _hit_controller then
        _magic_user_action_context = GetMagicUserActionContext()
        if _magic_user_action_context then
            if not _magic_user_action_context:get_IsChargingShot() then
                _hit_controller:set_BaseAttackRate(COMBO_ATTACK_RATE)
            else
                if _charge_deltatime < 1.0 then
                    _hit_controller:set_BaseAttackRate(POWER_ATTACK_RATE)
                else
                    _hit_controller:set_BaseAttackRate(POWER_ATTACK_RATE * _charge_deltatime)
                    _charge_deltatime = 0.0
                end
            end
            print("new attack rate ", _hit_controller:get_BaseAttackRate())
            _is_requested_by_player = false
        end
    end
end

local function on_pre_set_default ()
    _hit_controller = GetHitController()
    if _hit_controller then
        _hit_controller:set_BaseAttackRate(_DEFAULT_VALUE)
        _is_spell = true
        print("custom skills or job changed", _hit_controller:get_BaseAttackRate())
    end
end

local function on_pre_set_rapid_charge_shot()
    if _is_spell then return end
    local current_job = _player_chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
    if current_job == 6 or current_job == 3 then
        updateBurstShotParameter(RAPID_CHARGE_PERIOD)
        updatePowerShotParameter(RAPID_CHARGE_PERIOD)
        _hit_controller = GetHitController()
        if _hit_controller then
            _hit_controller:set_BaseAttackRate(COMBO_ATTACK_RATE)
            print("combo attack rate ", _hit_controller:get_BaseAttackRate())
        end
    end
end

local function initialize_()
    _character_manager = nil
    _human_param = nil
    _job_param = nil
    _sorcerer_param = nil
    _mage_param = nil
    _rapid_shot_param = nil
    _burst_shot_param = nil
    _mage_rapid_shot_param = nil
    _power_shot_param = nil
    _player_chara = nil
    _hit_controller = nil
    _magic_user_action_context = nil
    _human = nil
    _stamina_manager = nil
    _is_requested_by_player = false
    _is_spell = false
    _charge_deltatime = 0.0
    _player_chara = GetManualPlayer()
end

initialize_()

-- could use sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType")
sdk_.hook(sdk_.find_type_definition("app.Player"):get_method(".ctor"),
    function () end,
    function (...)
        initialize_()
        updateSorcererRapidShot()
        updateBurstShotParameter(RAPID_CHARGE_PERIOD)
        updateMageRapidShot()
        updatePowerShotParameter(RAPID_CHARGE_PERIOD)
        return ...
    end)

sdk.hook(
    sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
    function() end,
    function(rtval)
        _player_chara = GetManualPlayer()
        print("player character", _player_chara)
        return rtval
    end
)

-- need to find methods to hook for HumanSkillID 62 salamander and 64 minevolt.
sdk_.hook(sdk_.find_type_definition("app.Job06ActionSelector"):get_method("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)"),
    function (args)
        if _player_chara == sdk_.to_managed_object(args[2]):get_field("<Chara>k__BackingField") then
            on_pre_set_default()
        end
    end,
    function (rtval)
        return rtval
    end)

sdk_.hook(sdk_.find_type_definition("app.Job03ActionSelector"):get_method("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)"),
    function (args)
        if _player_chara == sdk_.to_managed_object(args[2]):get_field("<Chara>k__BackingField") then
            on_pre_set_default()
        end
    end,
    function (rtval)
        return rtval
    end)

-- combo initialization.
sdk_.hook(sdk_.find_type_definition("app.HumanActionSelector"):get_method("requestComboAction(app.LocomotionSpeedTypeEnum)"),
    function (args)
        if _player_chara == sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara") then
            on_pre_set_rapid_charge_shot()
        end
    end,
    function (rtval)
        return rtval
    end)

-- JobMagicUserActionSelector.getReleaseAction does not work!
local caller_sorcerer
sdk_.hook(sdk_.find_type_definition("app.Job06ActionSelector"):get_method("getReleaseAction(System.UInt32)"),
    function (args) caller_sorcerer = sdk_.to_managed_object(args[2]):get_field("<Chara>k__BackingField") end,
    function (rtval)
        if _player_chara and _player_chara == caller_sorcerer then
            on_post_release_action()
        end
        return rtval
    end)

local caller_mage
sdk_.hook(sdk_.find_type_definition("app.Job03ActionSelector"):get_method("getReleaseAction(System.UInt32)"),
    function (args) caller_mage = sdk_.to_managed_object(args[2]):get_field("<Chara>k__BackingField") end,
    function (rtval)
        if _player_chara == caller_mage then
            on_post_release_action()
        end
        return rtval
    end)

local caller_human
sdk_.hook(sdk_.find_type_definition("app.HumanActionSelector"):get_method("requestNormalAttack(app.LocomotionSpeedTypeEnum)"),
    function (args)
        caller_human = sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara")
    end,
    function (rtval)
        if _player_chara == caller_human then
            on_post_requestNormalAttack()
        end
        return rtval
    end)

sdk_.hook(sdk_.find_type_definition("app.JobContext"):get_method("setJobChanged(app.Character.JobEnum)"),
    on_pre_set_default,
    function (rtval)
        return rtval
    end)

local last_frame = os.clock()
re_.on_frame(function ()
    local current_frame = os.clock()
    local deltatime = current_frame - last_frame
    last_frame = current_frame
    if _is_requested_by_player then
        _magic_user_action_context = GetMagicUserActionContext()
        if _magic_user_action_context:get_IsChargingShot() then
            elapsed_time = elapsed_time + deltatime
            if elapsed_time < POWER_ATTACK_CHARGE_PERIOD then
                _charge_deltatime = elapsed_time
                _stamina_manager = GetStaminaManager()
                local cost = _stamina_manager:get_MaxValue() * 0.1 * -1.0
                _stamina_manager:add(cost / ALLIVIATE_STAMINA_COST, false)
            else
                _charge_deltatime = POWER_ATTACK_CHARGE_PERIOD
            end
        else
            _charge_deltatime = 0.0
            elapsed_time = 0.0
        end
    end
end)
