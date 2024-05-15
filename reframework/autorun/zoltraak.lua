-- author : BeerShigachi
-- date : 16 May 2024
-- version : 2.4.0

-- CONFIG: every values have to be float number. use float like 1.0 not 1.
local POWER_ATTACK_CHARGE_PERIOD = 3.0 -- 1.0 as default. longer charging period results higher damage.
local RAPID_CHARGE_PERIOD = 0.5 -- 1.0 as default
local COMBO_INTERVAL = 0.1 -- default: 0.28
local COMBO_ATTACK_RATE = 1.5 -- defalut: 1.0
local POWER_ATTACK_RATE = 2.0 -- defalut: 1.0: CAUTION: set this value too high result OP!
local BURST_BOLT_EXPLOSION_RATE = 1.0 -- defalut: 1.0: Burst bolt blob's exlosion. to avoid OP set around 0.9
local ALLIVIATE_STAMINA_COST = 100.0 -- higher value expend less stamina.
local DELAY_EXPLOSION = 0.1 -- default: 3.0 :set lower for insta explosion. require restart the game.

-- CONFIG: VFX_SIZE_SCALE
local NORMAL_SHOT_SCALE_X = 1.0
local NORMAL_SHOT_SCALE_Y = 1.0
local NORMAL_SHOT_SCALE_Z = 1.0
local RAPID_CHARGE_SHOT_SCALE_X = 1.0
local RAPID_CHARGE_SHOT_SCALE_Y = 1.0
local RAPID_CHARGE_SHOT_SCALE_Z = 1.0
local POWER_SHOT_SCALE_X = 2.0
local POWER_SHOT_SCALE_Y = 2.0
local POWER_SHOT_SCALE_Z = 2.0
local BURST_BLOB_SCALE_X = 1.0
local BURST_BLOB_SCALE_Y = 1.0
local BURST_BLOB_SCALE_Z = 1.0
local BURST_EXPLOSION_SCALE_X = 1.0
local BURST_EXPLOSION_SCALE_Y = 1.0
local BURST_EXPLOSION_SCALE_Z = 1.0



-- DO NOT TOUCH UNDER THIS LINE

if reframework.get_commit_count() < 1644 then
	re.msg("Ordinary Offensive Magic: Your REFramework is older version.\n If the mod does not work, Get version `REF Nightly 913` from\nhttps://github.com/praydog/REFramework-nightly/releases")
end

local sdk_ = sdk
local _charge_deltatime = 0.0
local cached_multiplier = {}
-- list of hash
local BURST_BOLT_HASH = 2550907203
local BURST_BOLT_HOLD_HASH = 1484381992
local FOCUSED_BOLT_HASH = 1425099050
local FOCUSED_BOLT_HOLD_HASH = 106531605
local MAGE_MAGIC_BOLT_HASH = 1126541769
local MAGE_MAGIC_BOLT_HOLD_HASH = 778730609
local SORCERER_MAGIC_BOLT_HASH = 144413685
local SORCERER_MAGIC_BOLT_HOLD_HASH = 1277318571
local BURST_BOLT_BLOB_HASH = 1430605661
local BURST_BOLT_EXPLOSION_HASH = 2270892601


local SIGNETURES = {
    NORMAL_SHOT_SIGNETURE = 0,
    POWER_SHOT_SIGNETURE = 1,
    BURST_BOLT_BLOG_SIGNETURE = 2,
    BURST_BOLT_EXPLSION_SIGNETURE = 3,
}


local SHELL_HASH_TABLE = {
    [BURST_BOLT_HASH] = SIGNETURES.POWER_SHOT_SIGNETURE,
    [BURST_BOLT_HOLD_HASH] = SIGNETURES.POWER_SHOT_SIGNETURE,
    [FOCUSED_BOLT_HASH] = SIGNETURES.POWER_SHOT_SIGNETURE,
    [FOCUSED_BOLT_HOLD_HASH] = SIGNETURES.POWER_SHOT_SIGNETURE,
    [MAGE_MAGIC_BOLT_HASH] = SIGNETURES.NORMAL_SHOT_SIGNETURE,
    [MAGE_MAGIC_BOLT_HOLD_HASH] = SIGNETURES.NORMAL_SHOT_SIGNETURE,
    [SORCERER_MAGIC_BOLT_HASH] = SIGNETURES.NORMAL_SHOT_SIGNETURE,
    [SORCERER_MAGIC_BOLT_HOLD_HASH] = SIGNETURES.NORMAL_SHOT_SIGNETURE,
    [BURST_BOLT_BLOB_HASH] = SIGNETURES.BURST_BOLT_BLOG_SIGNETURE,
    [BURST_BOLT_EXPLOSION_HASH] = SIGNETURES.BURST_BOLT_EXPLSION_SIGNETURE
}

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

local _human_param
local function GetHumanParam()
    _human_param = _get_component(_human_param, GetCharacterManager, "get_HumanParam()")
    return _human_param
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

local function on_post_requestNormalAttack(chara)
    local job = chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
    if job == 6 or job == 3 or job == 10 then
        updateBurstShotParameter(POWER_ATTACK_CHARGE_PERIOD)
        updatePowerShotParameter(POWER_ATTACK_CHARGE_PERIOD)
    end
end

local function on_pre_set_rapid_charge_shot(chara)
    local job = chara:get_field("<Human>k__BackingField"):get_JobContext():get_field("CurrentJob")
    if job == 6 or job == 3 or job == 10 then
        updateBurstShotParameter(RAPID_CHARGE_PERIOD)
        updatePowerShotParameter(RAPID_CHARGE_PERIOD)
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
    _stamina_manager = nil
    _charge_deltatime = 0.0
    _player_chara = GetManualPlayer()
    _burst_shot_param = GetBurstShotParameter()
    _power_shot_param = GetHeavyShotParameter()
    cached_multiplier = {}
end

initialize_()

-- could use sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType")
sdk_.hook(sdk_.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
    function () end,
    function (...)
        initialize_()
        updateSorcererRapidShot()
        updateBurstShotParameter(RAPID_CHARGE_PERIOD)
        updateMageRapidShot()
        updatePowerShotParameter(RAPID_CHARGE_PERIOD)
        print("player character: zoltraak", _player_chara)
        return ...
    end)

-- combo initialization.
sdk_.hook(sdk_.find_type_definition("app.HumanActionSelector"):get_method("requestComboAction(app.LocomotionSpeedTypeEnum)"),
    function (args)
        if _player_chara == sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara") then
            on_pre_set_rapid_charge_shot(sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara"))
        end
    end,
    function (rtval)
        return rtval
    end)

local caller_human
sdk_.hook(sdk_.find_type_definition("app.HumanActionSelector"):get_method("requestNormalAttack(app.LocomotionSpeedTypeEnum)"),
    function (args)
        caller_human = sdk_.to_managed_object(args[2]):get_field("Param"):get_field("Chara")
    end,
    function (rtval)
        if _player_chara == caller_human then
            on_post_requestNormalAttack(caller_human)
        end
        return rtval
    end)

local function get_new_vector3(x, y, z)
    local new_vector3 = ValueType.new(sdk_.find_type_definition("via.vec3"))
    local function fixed_size(val)
        if val < 0.1 then
            return 0.1
        end
        return val
    end
    new_vector3.x = fixed_size(x)
    new_vector3.y = fixed_size(y)
    new_vector3.z = fixed_size(z)
    return new_vector3
end

sdk_.hook(sdk_.find_type_definition("app.ShellManager"):get_method("registShell(app.Shell)"),
    function (args)
        local app_shell = sdk_.to_managed_object(args[3])
        local caller_chara= app_shell:get_OwnerCharacter()
        if caller_chara ~= _player_chara then return end
        local shell_param = app_shell:get_ShellParameter()
        local shell_base_param = shell_param:get_field("ShellBaseParam")
        local shell_hash = app_shell:get_ShellParamId()
        if SHELL_HASH_TABLE[shell_hash] == SIGNETURES.NORMAL_SHOT_SIGNETURE then
            shell_base_param["Scale"] = get_new_vector3(NORMAL_SHOT_SCALE_X, NORMAL_SHOT_SCALE_Y, NORMAL_SHOT_SCALE_Z)
        -- cache request id and deltatime
        elseif SHELL_HASH_TABLE[shell_hash] == SIGNETURES.POWER_SHOT_SIGNETURE then
            if _charge_deltatime < 1.0 then
                -- rapid charge
                _charge_deltatime = 1.0
                shell_base_param["Scale"] = get_new_vector3(RAPID_CHARGE_SHOT_SCALE_X, RAPID_CHARGE_SHOT_SCALE_Y, RAPID_CHARGE_SHOT_SCALE_Z)
            else
                -- power shot
                shell_base_param["Scale"] = get_new_vector3(POWER_SHOT_SCALE_X, POWER_SHOT_SCALE_Y, POWER_SHOT_SCALE_Z)
            end
            cached_multiplier[app_shell["<RequestId>k__BackingField"]] = _charge_deltatime
            _charge_deltatime = 0.0
        -- Blob lifetime is used for Burst bolt explosion delay
        elseif SHELL_HASH_TABLE[shell_hash] == SIGNETURES.BURST_BOLT_BLOG_SIGNETURE then
            shell_base_param:set_field("LifeTime", DELAY_EXPLOSION)
            shell_base_param["Scale"] = get_new_vector3(BURST_BLOB_SCALE_X, BURST_BLOB_SCALE_Y, BURST_BLOB_SCALE_Z)
        elseif SHELL_HASH_TABLE[shell_hash] == SIGNETURES.BURST_BOLT_EXPLSION_SIGNETURE then
            shell_base_param["Scale"] = get_new_vector3(BURST_EXPLOSION_SCALE_X, BURST_EXPLOSION_SCALE_Y, BURST_EXPLOSION_SCALE_Z)
        else
            return
        end
        shell_base_param["UseScale"] = true
    end,
    function (rtval)
        return rtval
    end)

sdk_.hook(sdk_.find_type_definition("app.JobContext"):get_method("setJobChanged(app.Character.JobEnum)"),
    function ()
        -- specify chara  here.
        cached_multiplier = {}
    end,
    function (rtval)
        return rtval
    end)

sdk_.hook(sdk_.find_type_definition("app.HitController"):get_method("calcDamageValue(app.HitController.DamageInfo)"),
function (args)
    local damage_info = sdk_.to_managed_object(args[3])
    -- perhaps better to use _player_chara:get_GameObject()
    local attacker_hit_controller = damage_info:get_field("<AttackOwnerHitController>k__BackingField")
    if attacker_hit_controller ~= nil then
        local attacker_chara = attacker_hit_controller:get_CachedCharacter()
        if attacker_chara == _player_chara and damage_info:get_field("<AttackHitController>k__BackingField") ~= nil then
            local attacker_shell_cache = damage_info:get_field("<AttackHitController>k__BackingField"):get_CachedShell()
            if attacker_shell_cache ~= nil then
                local id_attacked_by = attacker_shell_cache:get_ShellParamId()
                local attack_user_data = damage_info:get_field("<AttackUserData>k__BackingField")
                local new_rate = attack_user_data:get_field("ActionRate")
                if SHELL_HASH_TABLE[id_attacked_by] == SIGNETURES.NORMAL_SHOT_SIGNETURE then
                    new_rate = new_rate * COMBO_ATTACK_RATE
                elseif SHELL_HASH_TABLE[id_attacked_by] == SIGNETURES.POWER_SHOT_SIGNETURE then
                    -- get charge_delta and id for quick charge and power shot
                    local request_id = attacker_shell_cache["<RequestId>k__BackingField"]
                    new_rate = new_rate * POWER_ATTACK_RATE * cached_multiplier[request_id]
                elseif SHELL_HASH_TABLE[id_attacked_by] == SIGNETURES.BURST_BOLT_EXPLSION_SIGNETURE then
                    new_rate = new_rate * BURST_BOLT_EXPLOSION_RATE
                end
                attack_user_data:set_field("ActionRate", new_rate)
                damage_info:set_field("<AttackUserData>k__BackingField", attack_user_data)
            end
        end
    end
end,
function (rtval)
    return rtval
end)

sdk_.hook(sdk_.find_type_definition("app.ShellManager"):get_method("requestDestroyShell(System.Int32)"),
function (args)
    local request_id = sdk_.to_int64(args[3])
    if cached_multiplier[request_id] ~= nil then
        cached_multiplier[request_id] = nil
    end
end,
function (rtval)
    return rtval
end)

local timer = os.clock()
local elapsed_time_ = 0.0
sdk_.hook(sdk_.find_type_definition("app.Job06ActionController"):get_method("update()"),
function (args)
    local this = sdk_.to_managed_object(args[2])
    local caller = this:get_field("Chara")
    if _player_chara ~= caller then return end
    local magic_user_context = this:get_field("<JobMagicUserActionContext>k__BackingField")
    local current_frame = os.clock()
    local deltatime = current_frame - timer
    timer = current_frame
    if magic_user_context == nil then return end
    if _burst_shot_param["_PrepareTime"] == POWER_ATTACK_CHARGE_PERIOD or _power_shot_param["_PrepareTime"] == POWER_ATTACK_CHARGE_PERIOD then
        if magic_user_context:get_IsChargingShot() then
            elapsed_time_ = elapsed_time_ + deltatime
            -- print(elapsed_time_)
            if elapsed_time_ < POWER_ATTACK_CHARGE_PERIOD then
                _charge_deltatime = elapsed_time_
                _stamina_manager = GetStaminaManager()
                local cost = _stamina_manager:get_MaxValue() * 0.1 * -1.0
                _stamina_manager:add(cost / ALLIVIATE_STAMINA_COST, false)
            else
                _charge_deltatime = POWER_ATTACK_CHARGE_PERIOD
            end
        else
            elapsed_time_ = 0.0
        end
    end
end,
function ()
end)
