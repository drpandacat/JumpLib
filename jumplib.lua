---@diagnostic disable: undefined-global
--[[
    Jump library by kerkel
    Version 1.0.3
    Direct issues and requests to the dedicated resources post in https://discord.gg/modding-of-isaac-962027940131008653
    GitHub repo https://github.com/drpandacat/JumpLib/
]]

---@class JumpData
---@field Jumping boolean
---@field Tags table
---@field Height number
---@field StaticHeightIncrease number
---@field StaticJumpSpeed number
---@field Fallspeed number
---@field StoredEntityColl EntityCollisionClass
---@field StoredGridColl GridCollisionClass
---@field Flags integer

---@class JumpConfig
---@field Height number
---@field Speed number | nil
---@field Flags integer | nil
---@field Tags string | string[] | nil

---@class InternalJumpData
---@field UpdateFrame integer
---@field Jumping boolean
---@field Tags table
---@field PrevTags table
---@field Height number
---@field StaticHeightIncrease number
---@field StaticJumpSpeed number
---@field Fallspeed number
---@field StoredEntityColl EntityCollisionClass
---@field StoredGridColl GridCollisionClass
---@field ChildStoredEntityColl EntityCollisionClass
---@field ChildStoredGridColl GridCollisionClass
---@field StoredSpriteScale Vector
---@field Flags integer
---@field LaserOffset Vector
---@field Pitfall boolean
---@field PitPos Vector
---@field Config JumpConfig
---@field SetInitialLaserHeight boolean
---@field GridCollToSet GridCollisionClass
---@field EntCollToSet EntityCollisionClass

local LOCAL_JUMPLIB = {}

function LOCAL_JUMPLIB.Init()
    local LOCAL_VERSION = 1.3

    if JumpLib then
        if JumpLib.Version > LOCAL_VERSION then
            return
        end
        JumpLib.Internal:RemoveCallbacks()
    end

    local game = Game()

    JumpLib = RegisterMod("JumpLib", 1)
    JumpLib.Version = LOCAL_VERSION

    ---@enum JumpCallback
    ---All jump callbacks shared optional parameter table:
    ---
    ---* `type = EntityType`
    ---* `variant = integer`
    ---* `subtype = integer`
    ---* `tag = string`
    ---
    ---Additional params for player callbacks:
    ---
    ---* `collectible = CollectibleType`
    ---* `trinket = TrinketType`
    ---* `effect = CollectibleType`
    ---* `player = PlayerType`
    ---* `weapon = WeaponType`
    JumpLib.Callbacks = {
        ---Called before a player jumps
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* config - `JumpConfig`
        ---
        ---Returns:
        ---* Return `true` to cancel jump
        ---* Return `JumpConfig` object to override config
        PRE_PLAYER_JUMP = "JUMPLIB_PRE_PLAYER_JUMP",
        ---Called after a player jumps
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* config - `JumpConfig`
        POST_PLAYER_JUMP = "JUMPLIB_POST_PLAYER_JUMP",
        ---Called after a player lands
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* data - `JumpData`
        ---* pitfall - `boolean`
        PLAYER_LAND = "JUMPLIB_PLAYER_LAND",
        ---Called before an entity jumps
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* config - `JumpConfig`
        ---
        ---Returns:
        ---* Return `true` to cancel jump
        ---* Return `JumpConfig` object to override config
        PRE_ENTITY_JUMP = "JUMPLIB_PRE_ENTITY_JUMP",
        ---Called after an entity jumps
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* config - `JumpConfig`
        POST_ENTITY_JUMP = "JUMPLIB_POST_ENTITY_JUMP",
        ---Called after an entity lands
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* data - `JumpData`
        ENTITY_LAND = "JUMPLIB_ENTITY_LAND",
        ---Called before a player falls into a pit after jumping
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* data - `JumpData`
        ---
        ---Returns:
        ---* Return `true` to cancel
        ---* Return `false` to fall into the pit but take no damage
        ---* Return `integer` to override damage
        PRE_PITFALL = "JUMPLIB_PRE_PITFALL",
        ---Called before a player takes damage after falling into a pit
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* data - `JumpData`
        ---* damage - `integer`
        ---
        ---Returns:
        ---* Return `true` to cancel
        ---* Return `integer` to override damage
        PRE_PITFALL_HURT = "JUMPLIB_PRE_PITFALL_HURT",
        ---Called after a player exits a pit
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* data - `JumpData`
        PITFALL_EXIT = "JUMPLIB_PITFALL_EXIT",
        ---Called before setting a player's fallspeed
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* speed - `number`
        ---* data - `JumpData`
        ---Returns:
        ---* Return `true` to cancel
        ---* Return `number` to multiply provided speed by
        PRE_PLAYER_SET_FALLSPEED = "JUMPLIB_PRE_PLAYER_SET_FALLSPEED",
        ---Called after setting a player's fallspeed
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* speed - `number`
        ---* data - `JumpData`
        POST_PLAYER_SET_FALLSPEED = "JUMPLIB_POST_PLAYER_SET_FALLSPEED",
        ---Called before setting an entity's fallspeed
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* speed - `number`
        ---* data - `JumpData`
        ---Returns:
        ---* Return `true` to cancel
        ---* Return `number` to multiply provided speed by
        PRE_ENTITY_SET_FALLSPEED = "JUMPLIB_PRE_ENTITY_SET_FALLSPEED",
        ---Called after setting an entity's fallspeed
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* speed - `number`
        ---* data - `JumpData`
        POST_ENTITY_SET_FALLSPEED = "JUMPLIB_POST_ENTITY_SET_FALLSPEED",
        ---Called when checking if a laser should follow its parent
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* laser - `EntityLaser`
        ---
        ---Returns:
        ---* Return `true` to allow follow
        ---* Return `false` to disallow follow
        GET_LASER_CAN_FOLLOW_ENTITY = "JUMPLIB_GET_LASER_CAN_FOLLOW_ENTITY",
        ---Called when checking if a laser should follow its parent
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* laser - `EntityLaser`
        ---
        ---Returns:
        ---* Return `true` to allow follow
        ---* Return `false` to disallow follow
        GET_LASER_CAN_FOLLOW_PLAYER = "JUMPLIB_GET_LASER_CAN_FOLLOW_PLAYER",
        ---Runs 30 times per second for every player in the air
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* data - `JumpData`
        PLAYER_UPDATE_30 = "JUMPLIB_PLAYER_UPDATE_30",
        ---Runs 60 times per second for every player in the air
        ---
        ---Parameters:
        ---* player - `EntityPlayer`
        ---* data - `JumpData`
        PLAYER_UPDATE_60 = "JUMPLIB_PLAYER_UPDATE_60",
        ---Runs 30 times per second for every entity in the air
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* data - `JumpData`
        ENTITY_UPDATE_30 = "JUMPLIB_ENTITY_UPDATE_30",
        ---Runs 60 times per second for every entity in the air
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* data - `JumpData`
        ENTITY_UPDATE_60 = "JUMPLIB_ENTITY_UPDATE_60",
    }

    JumpLib.Flags = {
        ---Player will not fall into pits on landing
        NO_PITFALL = 1 << 0,
        ---Player will not take damage from pitfall
        NO_HURT_PITFALL = 1 << 1,
        ---Player will fall into pits regardless of flight
        IGNORE_FLIGHT = 1 << 2,
        ---Entity will collide with grid entities
        COLLISION_GRID = 1 << 3,
        ---Entity will collide with other entities
        COLLISION_ENTITY = 1 << 4,
        ---`CanJump()` will return `true`
        OVERWRITABLE = 1 << 5,
        ---Knives that follow parent jump will not collide with entities
        KNIFE_DISABLE_ENTCOLL = 1 << 6,
        ---Knives will not follow parent jump
        KNIFE_FOLLOW_CUSTOM = 1 << 7,
        ---Unaffected by PRE_SET_FALLSPEED returns
        IGNORE_FALLSPEED_MODIFIERS = 1 << 8,
        ---Unaffected by `PRE_JUMP` `JumpConfig` returns
        IGNORE_CONFIG_OVERRIDE = 1 << 9,
        ---Lasers will not follow parent
        DISABLE_LASER_FOLLOW = 1 << 10,
        ---Only orbital familiars will follow the player
        FAMILIAR_FOLLOW_ORBITALS_ONLY =  1 << 11,
        ---Only tear-copying familiars will follow the player
        FAMILIAR_FOLLOW_TEARCOPYING_ONLY = 1 << 12,
        ---Familiars will not use default jumping behaviors when following player
        FAMILIAR_FOLLOW_CUSTOM = 1 << 13,
        ---Lasers will not use default jumping behaviors
        LASER_FOLLOW_CUSTOM = 1 << 14,
        ---Bombs drop as if you were not jumping
        DISABLE_COOL_BOMBS = 1 << 15,
        ---Bombs are unable to be dropped
        DISABLE_BOMB_INPUT = 1 << 16,
        ---Player is unable to shoot
        DISABLE_SHOOTING_INPUT = 1 << 17,
        ---Disables tears and projectiles being spawned at spawner height
        DISABLE_TEARHEIGHT = 1 << 18,
        ---Entity will not collide with walls
        GRIDCOLL_NO_WALLS = 1 << 19,
        ---Damage is not prevented while in the air
        DAMAGE_CUSTOM = 1 << 20,
    }

    ---Combination of:
    ---* `COLLISION_GRID`
    ---* `COLLISION_ENTITY`
    ---* `OVERWRITABLE`
    ---* `DISABLE_COOL_BOMBS`
    ---* `IGNORE_CONFIG_OVERRIDE`
    ---* `FAMILIAR_FOLLOW_ORBITALS_ONLY`
    ---* `DAMAGE_CUSTOM`
    ---
    ---Useful for small, frequent jumps. Combine with desired familiar flag
    JumpLib.Flags.WALK_PRESET = JumpLib.Flags.COLLISION_GRID
    | JumpLib.Flags.COLLISION_ENTITY
    | JumpLib.Flags.OVERWRITABLE
    | JumpLib.Flags.DISABLE_COOL_BOMBS
    | JumpLib.Flags.IGNORE_CONFIG_OVERRIDE
    | JumpLib.Flags.DAMAGE_CUSTOM

    JumpLib.Constants = {
        PITFRAME_START = 15,
        PITFRAME_DAMAGE = 20,
        PITFRAME_END = 30,
        HEIGHT_TO_LASER_OFFSET = 1.5525,
        CONFIG_HEIGHT_MULT = 2,
        CONFIG_SPEED_MULT = 0.2,
        FALLSPEED_INCR = 0.2,
    }

    JumpLib.Internal = {
        EntityData = {},
        CallbackEntries = {},

        TEAR_COPYING_FAMILIARS = {
            [FamiliarVariant.INCUBUS] = true,
            [FamiliarVariant.TWISTED_BABY] = true,
            [FamiliarVariant.UMBILICAL_BABY] = true,
            [FamiliarVariant.BLOOD_BABY] = true,
        },

        HOOK_TO_CANCEL = {
            [InputHook.GET_ACTION_VALUE] = 0,
            [InputHook.IS_ACTION_PRESSED] = false,
            [InputHook.IS_ACTION_TRIGGERED] = false,
        },

        SHOOT_ACTIONS = {
            [ButtonAction.ACTION_SHOOTLEFT] = true,
            [ButtonAction.ACTION_SHOOTRIGHT] = true,
            [ButtonAction.ACTION_SHOOTUP] = true,
            [ButtonAction.ACTION_SHOOTDOWN] = true,
        },

        SchedulerEntries = {},
    }

    ---@param callback ModCallbacks | JumpCallback
    ---@param fn function
    ---@param param any
    local function AddCallback(callback, fn, param)
        JumpLib.Internal.CallbackEntries[#JumpLib.Internal.CallbackEntries + 1] = {
            Callback = callback,
            Function = fn,
            Param = param,
        }
    end

    ---@param fn function
    ---@param delay integer
    ---@param persistent boolean | nil
    function JumpLib.Internal:ScheduleFunction(fn, delay, persistent)
        table.insert(JumpLib.Internal.SchedulerEntries, {
            Frame = game:GetFrameCount(),
            Function = fn,
            Delay = delay,
            Persistent = persistent
        })
    end

    local function ClearScheduled()
        JumpLib.Internal.SchedulerEntries = {}
    end
    AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ClearScheduled)

    -- ---@param entity Entity
    -- local function ClearEntityDataOnRemove(_, entity)
    --     JumpLib.Internal:ScheduleFunction(function ()
    --         JumpLib.Internal.EntityData[GetPtrHash(entity)] = nil
    --     end, 1, true)
    -- end
    -- AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, ClearEntityDataOnRemove)

    -- local function ClearDataOnExit()
    --     JumpLib.Internal.EntityData = {}
    -- end
    -- AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ClearDataOnExit)

    local function Scheduler()
        local frame = game:GetFrameCount()

        for i = #JumpLib.Internal.SchedulerEntries, 1, -1 do
            local v = JumpLib.Internal.SchedulerEntries[i]
            if v.Frame + v.Delay <= frame then
                v.Function()
                table.remove(JumpLib.Internal.SchedulerEntries, i)
            end
        end
    end
    AddCallback(ModCallbacks.MC_POST_UPDATE, Scheduler)

    local function RemoveNonPersistentFunctions()
        for i, v in ipairs(JumpLib.Internal.SchedulerEntries) do
            if not v.Persistent then
                table.remove(JumpLib.Internal.SchedulerEntries, i)
            end
        end
    end
    AddCallback(ModCallbacks.MC_POST_NEW_ROOM, RemoveNonPersistentFunctions)

    ---@param entity Entity
    ---@return InternalJumpData
    function JumpLib.Internal:GetData(entity)
        -- local hash = GetPtrHash(entity)

        -- if not JumpLib.Internal.EntityData[hash] then
        --     JumpLib.Internal.EntityData[hash] = {}
        -- end

        -- return JumpLib.Internal.EntityData[hash]

        local data = entity:GetData()
        data.__JUMPLIB = data.__JUMPLIB or {}
        return data.__JUMPLIB
    end

    ---@param entity Entity
    function JumpLib.Internal:LaserBehaviorsFromEntity(entity)
        local entityData = JumpLib.Internal:GetData(entity)
        local hash = GetPtrHash(entity)
        local player = entity:ToPlayer()

        for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_LASER)) do
            if v.SpawnerEntity and GetPtrHash(v.SpawnerEntity) == hash
            or v.Parent and GetPtrHash(v.Parent) == hash then
                local laser = v:ToLaser() ---@cast laser EntityLaser

                if JumpLib:GetData(entity).Flags & JumpLib.Flags.DISABLE_LASER_FOLLOW == 0 then
                    local returns = {}

                    if player then
                        returns = JumpLib:RunCallbackWithParam(JumpLib.Callbacks.GET_LASER_CAN_FOLLOW_PLAYER, player, laser)
                    end

                    for _, v in ipairs(JumpLib:RunCallbackWithParam(JumpLib.Callbacks.GET_LASER_CAN_FOLLOW_ENTITY, entity, laser)) do
                        returns[#returns + 1] = v
                    end

                    local follow

                    for _, v in ipairs(returns) do
                        if v == true then
                            follow = true
                        elseif v == false then
                            follow = false
                        end
                    end

                    if follow and JumpLib:GetData(entity).Flags & JumpLib.Flags.LASER_FOLLOW_CUSTOM == 0 then
                        local laserData = JumpLib.Internal:GetData(laser)

                        if not (laser.DisableFollowParent or (laser:IsCircleLaser())) or not laserData.SetInitialLaserHeight then
                            local config = entityData.Config; config.Speed = 0

                            if laser:IsCircleLaser() then
                                JumpLib:SetHeight(laser, entityData.Height, {Height = 0, Speed = 0.8})
                            else
                                JumpLib:SetHeight(laser, entityData.Height, config)

                                laserData.StaticHeightIncrease = 0
                                laserData.StaticJumpSpeed = 0
                            end

                            laserData.SetInitialLaserHeight = true
                        end
                    end

                    laser.PositionOffset = JumpLib:GetOffset(laser)
                end
            end
        end
    end

    function JumpLib.Internal:RemoveCallbacks()
        for _, v in ipairs(JumpLib.Internal.CallbackEntries) do
            JumpLib:RemoveCallback(v.Callback, v.Function)
        end
    end

    ---@param callback JumpCallback | string
    ---@param entity Entity
    ---@return any[]
    function JumpLib:RunCallbackWithParam(callback, entity, ...)
        local player = entity:ToPlayer()
        local familiar = entity:ToFamiliar()
        local data = JumpLib.Internal:GetData(entity)
        local returns = {}

        for _, v in ipairs(Isaac.GetCallbacks(callback)) do
            ---@diagnostic disable-next-line: cast-type-mismatch
            local param = v.Param ---@cast param table
            local tbl = type(param) == "table"
            local tags = data.PrevTags or data.Tags

            local isType = not tbl or not param.type or param.type == entity.Type
            local isVariant = not tbl or not param.variant or param.variant == entity.Variant
            local isSubType = not tbl or not param.subtype or param.subtype == entity.SubType
            local hasCollectible = not tbl or not param.collectible or not player or player:HasCollectible(param.collectible)
            local hasTrinket = not tbl or not param.trinket or not player or player:HasTrinket(param.collectible)
            local hasEffect = not tbl or not param.effect or not player or player:GetEffects():HasCollectibleEffect(param.effect)
            local hasTag = not tbl or not param.tag or tags and tags[param.tag]
            local isPlayer = not tbl or not param.player or not player or player:GetPlayerType() == param.player
            local hasWeapon = not tbl or not param.weapon

            if not hasWeapon then
                if player then
                    for i = 0, 4 do
                        local weapon = player:GetWeapon(i)
                        if weapon and weapon:GetWeaponType() == param.weapon then
                            hasWeapon = true
                            break
                        end
                    end
                elseif familiar then
                    local weapon = familiar:GetWeapon()
                    if weapon and weapon:GetWeaponType() == param.weapon then
                        hasWeapon = true
                    end
                end
            end

            if isType
            and isVariant
            and isSubType
            and hasCollectible
            and hasTrinket
            and hasEffect
            and hasTag
            and isPlayer
            and hasWeapon then
                returns[#returns + 1] = v.Function(v.Mod, entity, ...)
            end
        end

        return returns
    end

    ---@param entity Entity
    function JumpLib:CanJump(entity)
        local jumpData = JumpLib:GetData(entity)

        if jumpData.Flags & JumpLib.Flags.OVERWRITABLE ~= 0 then
            return true
        end

        return not jumpData.Jumping
    end

    ---@param entity Entity
    ---@param config JumpConfig
    ---@param force boolean | nil
    ---@return boolean
    function JumpLib:Jump(entity, config, force)
        config = {
            Height = config.Height,
            Speed = config.Speed or 1,
            Flags = config.Flags or 0,
            Tags = config.Tags or {},
        }

        if type(config.Tags) == "string" then
            ---@diagnostic disable-next-line: assign-type-mismatch
            config.Tags = {config.Tags}
        end

        local player = entity:ToPlayer()
        local returns = JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PRE_ENTITY_JUMP, entity, config)

        if player then
            for _, v in ipairs(JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PRE_PLAYER_JUMP, player, config)) do
                returns[#returns + 1] = v
            end
        end

        if not force then
            for _, v in ipairs(returns) do
                if type(v) == "table" then
                    config = v
                    break
                elseif v == true then
                    return false
                end
            end
        end

        local data = JumpLib.Internal:GetData(entity)
        local hash = GetPtrHash(entity)

        data.Flags = config.Flags
        data.Jumping = true
        data.Height = data.Height or 0
        data.StaticHeightIncrease = config.Height * JumpLib.Constants.CONFIG_HEIGHT_MULT * config.Speed * JumpLib.Constants.CONFIG_SPEED_MULT
        data.StaticJumpSpeed = config.Speed
        data.Fallspeed = 0
        data.Tags = data.Tags or {}
        data.Config = config

        ---@diagnostic disable-next-line: param-type-mismatch
        for _, v in ipairs(config.Tags) do
            ---@diagnostic disable-next-line: assign-type-mismatch
            data.Tags[v] = true
        end

        if not data.StoredEntityColl and data.Flags & JumpLib.Flags.COLLISION_ENTITY == 0 then
            data.StoredEntityColl = entity.EntityCollisionClass

            if player and data.Flags & JumpLib.Flags.DISABLE_SHOOTING_INPUT == 0 then
                data.EntCollToSet = EntityCollisionClass.ENTCOLL_PLAYERONLY
            else
                data.EntCollToSet = EntityCollisionClass.ENTCOLL_NONE
            end
        end

        if entity.Type ~= EntityType.ENTITY_KNIFE then
            if not data.StoredGridColl and data.Flags & JumpLib.Flags.COLLISION_GRID == 0 then
                data.StoredGridColl = entity.GridCollisionClass
                data.GridCollToSet = data.Flags & JumpLib.Flags.GRIDCOLL_NO_WALLS == 0 and EntityGridCollisionClass.GRIDCOLL_WALLS or EntityGridCollisionClass.GRIDCOLL_NONE
            end

            for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_KNIFE)) do
                if GetPtrHash(v.Parent) == hash and data.Flags & JumpLib.Flags.KNIFE_FOLLOW_CUSTOM == 0 then
                    local konfig = config; konfig.Flags = (konfig.Flags | JumpLib.Flags.GRIDCOLL_NO_WALLS) ~ JumpLib.Flags.COLLISION_GRID

                    if data.Flags & JumpLib.Flags.KNIFE_DISABLE_ENTCOLL ~= 0 then
                        konfig.Flags = konfig.Flags | JumpLib.Flags.COLLISION_ENTITY
                    end

                    JumpLib:Jump(v, konfig)
                end
            end
        end

        JumpLib:RunCallbackWithParam(JumpLib.Callbacks.POST_ENTITY_JUMP, entity, config)

        if player then
            JumpLib:RunCallbackWithParam(JumpLib.Callbacks.POST_PLAYER_JUMP, entity, config)

            if data.Flags & JumpLib.Flags.FAMILIAR_FOLLOW_CUSTOM == 0 then
                for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR)) do
                    local familiar = v:ToFamiliar() ---@cast familiar EntityFamiliar
                    if familiar.Player and GetPtrHash(familiar.Player) == hash then
                        local orbital = data.Flags & JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS_ONLY ~= 0
                        local tearCopying = data.Flags & JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING_ONLY ~= 0
                        local isOrbital = familiar.OrbitLayer ~= -1
                        local isTearCopying = JumpLib.Internal.TEAR_COPYING_FAMILIARS[v.Variant]

                        if (orbital and isOrbital) or (tearCopying and isTearCopying) or not (orbital or tearCopying) then
                            local config2 = config; if isOrbital then config2.Flags = config2.Flags | JumpLib.Flags.GRIDCOLL_NO_WALLS end
                            JumpLib:Jump(v, config2)
                        end
                    end
                end
            end
        end

        return true
    end

    ---Jumps if `CanJump()` returns `true`
    ---
    ---Returns `true` if successful, `false` otherwise
    ---@param entity Entity
    ---@param config JumpConfig
    ---@return boolean
    function JumpLib:TryJump(entity, config)
        local canJump = JumpLib:CanJump(entity)

        if canJump then
            return JumpLib:Jump(entity, config)
        end

        return canJump
    end

    ---Stops the current jump
    ---
    ---Returns `true` if successful, `false` otherwise
    ---@param entity Entity
    ---@return boolean
    function JumpLib:QuitJump(entity)
        local entityData = JumpLib.Internal:GetData(entity)
        local jumpData = JumpLib:GetData(entity)

        if not jumpData.Jumping then
            return false
        end

        entityData.EntCollToSet = nil
        entityData.GridCollToSet = nil
        entityData.Jumping = false

        if jumpData.Flags & JumpLib.Flags.COLLISION_ENTITY == 0 then
            entity.EntityCollisionClass = entityData.StoredEntityColl or entity.EntityCollisionClass
        end

        if jumpData.Flags & JumpLib.Flags.COLLISION_GRID == 0 then
            entity.GridCollisionClass = entityData.StoredGridColl or entity.GridCollisionClass
        end

        entityData.Flags = 0
        entityData.Fallspeed = 0

        ---@diagnostic disable-next-line: param-type-mismatch
        if not JumpLib:IsPitfalling(entity) then
            entityData.StoredEntityColl = nil
            entityData.StoredGridColl = nil
        end

        entityData.LaserOffset = nil

        entityData.Tags = nil

        return true
    end

    ---Begins player pitfall sequence
    ---@param player EntityPlayer
    ---@param position Vector
    ---@param damage integer | nil
    ---@return boolean
    function JumpLib:Pitfall(player, position, damage)
        if player.Type ~= EntityType.ENTITY_PLAYER or JumpLib:IsPitfalling(player) or player:IsCoopGhost() then return false end
        damage  = damage or 1

        player:PlayExtraAnimation("FallIn")

        local data = JumpLib.Internal:GetData(player)

        data.Pitfall = true
        data.PitPos = position

        data.StoredEntityColl = player.EntityCollisionClass
        data.StoredGridColl = player.GridCollisionClass

        JumpLib.Internal:ScheduleFunction(function ()
            for _, v in ipairs(JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PRE_PITFALL_HURT, player, JumpLib:GetData(player), damage)) do
                damage = type(v) == "number" and v or damage
                if v == true then
                    return
                end
            end

            player:TakeDamage(damage, DamageFlag.DAMAGE_PITFALL, EntityRef(player), 30)
        end, JumpLib.Constants.PITFRAME_START, true)

        JumpLib.Internal:ScheduleFunction(function ()
            player:AnimatePitfallOut()
            player.SpriteScale = data.StoredSpriteScale

            data.StoredSpriteScale = nil
            data.PitPos = game:GetRoom():FindFreePickupSpawnPosition(player.Position, 40)
        end, JumpLib.Constants.PITFRAME_DAMAGE, true)

        JumpLib.Internal:ScheduleFunction(function ()
            data.Pitfall = false
            data.PitPos = nil

            player.ControlsEnabled = true
            player.GridCollisionClass = data.StoredGridColl
            player.EntityCollisionClass = data.StoredEntityColl

            data.StoredGridColl = nil
            data.StoredEntityColl = nil

            JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PITFALL_EXIT, player, JumpLib:GetData(player))
        end, JumpLib.Constants.PITFRAME_END, true)

        return true
    end

    ---Returns if player is currently pitfalling
    ---@param player EntityPlayer
    ---@return boolean
    function JumpLib:IsPitfalling(player)
        return not not JumpLib.Internal:GetData(player).Pitfall
    end

    ---Returns non-writable `JumpData` of provided entity
    ---@param entity Entity
    ---@return JumpData
    function JumpLib:GetData(entity)
        local data = JumpLib.Internal:GetData(entity)

        return  {
            Jumping = data.Jumping or false,
            Tags = data.Tags or {},
            Height = data.Height or 0,
            StaticHeightIncrease = data.StaticHeightIncrease or 0,
            StaticJumpSpeed = data.StaticJumpSpeed or 0,
            Fallspeed = data.Fallspeed or 0,
            Flags = data.Flags or 0,
        }
    end

    ---Sets height of entity if jumping
    ---
    ---If `config` is provided, entity jumps and height is automatically set
    ---
    ---Returns `true` if successful, `false` otherwise
    ---@param entity Entity
    ---@param height number
    ---@param config JumpConfig | nil
    ---@return boolean
    function JumpLib:SetHeight(entity, height, config)
        if not JumpLib:GetData(entity).Jumping then
            if config then
                JumpLib:Jump(entity, config)
            else
                return false
            end
        end

        JumpLib.Internal:GetData(entity).Height = height

        return true
    end

    ---Removes a tag from the current jump
    ---@param entity Entity
    ---@param tag string
    function JumpLib:ClearTag(entity, tag)
        local data = JumpLib.Internal:GetData(entity) if not data.Tags then return end
        data.Tags[tag] = nil
    end

    ---Sets speed of current jump
    ---
    ---Returns `true` if successful, `false` otherwise
    ---@param entity Entity
    ---@param speed number
    ---@return boolean
    function JumpLib:SetSpeed(entity, speed)
        local data = JumpLib:GetData(entity)
        if not data.Jumping then
            return false
        end

        local player = entity:ToPlayer()

        if data.Flags & JumpLib.Flags.IGNORE_FALLSPEED_MODIFIERS == 0 then
            local returns = {}

            if player then
                returns = JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PRE_PLAYER_SET_FALLSPEED, player, speed, JumpLib:GetData(player))
            end

            for _, v in ipairs(JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PRE_ENTITY_SET_FALLSPEED, entity, speed, JumpLib:GetData(entity))) do
                returns[#returns + 1] = v
            end

            for _, v in ipairs(returns) do
                if type(v) == "number" then
                    speed = speed * v
                elseif v == true then
                    return false
                end
            end
        end

        JumpLib.Internal:GetData(entity).Fallspeed = speed

        if player then
            JumpLib:RunCallbackWithParam(JumpLib.Callbacks.POST_PLAYER_SET_FALLSPEED, player, speed, JumpLib:GetData(player))
        end

        JumpLib:RunCallbackWithParam(JumpLib.Callbacks.POST_ENTITY_SET_FALLSPEED, entity, speed, JumpLib:GetData(entity))

        return true
    end

    ---@param entity Entity
    ---@param yOffset number | nil
    ---@return Vector
    function JumpLib:GetOffset(entity, yOffset)
        local data = JumpLib:GetData(entity)

        if entity.Type == EntityType.ENTITY_LASER then
            local laser = entity:ToLaser() ---@cast laser EntityLaser

            if not data.Jumping then
                return laser.PositionOffset
            end

            local laserData = JumpLib.Internal:GetData(entity)

            if not laserData.LaserOffset then
                laserData.LaserOffset = Vector(laser.PositionOffset.X, laser.PositionOffset.Y)
            end

           return Vector(laserData.LaserOffset.X, -data.Height * JumpLib.Constants.HEIGHT_TO_LASER_OFFSET + laserData.LaserOffset.Y)
        end

        if not data.Jumping then
            return Vector.Zero
        end

        local renderOffset = Vector(0, -data.Height + (yOffset or 0))

        if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then
            renderOffset = -renderOffset
        end

        return renderOffset
    end

    local function RunUpdate()
        if game:IsPaused() then return end

        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            local entityData = JumpLib.Internal:GetData(entity)
            local jumpData = JumpLib:GetData(entity)
            local player = entity:ToPlayer()

            entityData.UpdateFrame = (entityData.UpdateFrame or 1) + 1

            if jumpData.Jumping then
                JumpLib:RunCallbackWithParam(JumpLib.Callbacks.ENTITY_UPDATE_60, entity, jumpData)

                if player then
                    JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PLAYER_UPDATE_60, player, jumpData)
                end

                if entityData.UpdateFrame % 2 == 0 then
                    JumpLib:RunCallbackWithParam(JumpLib.Callbacks.ENTITY_UPDATE_30, entity, jumpData)

                    if player then
                        JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PLAYER_UPDATE_30, player, jumpData)
                    end
                end
            end
        end
    end
    AddCallback(ModCallbacks.MC_POST_RENDER, RunUpdate)

    ---@param entity Entity
    ---@param jumpData JumpData
    local function OnUpdate(_, entity, jumpData)
        local entityData = JumpLib.Internal:GetData(entity)
        local player = entity:ToPlayer()

        entityData.Fallspeed = entityData.Fallspeed + JumpLib.Constants.FALLSPEED_INCR * entityData.StaticJumpSpeed

        entityData.Height = math.max(0,
            entityData.Height + entityData.StaticHeightIncrease - entityData.Fallspeed * entityData.StaticJumpSpeed
        )

        JumpLib.Internal:LaserBehaviorsFromEntity(entity)

        entity.GridCollisionClass = entityData.GridCollToSet or entity.GridCollisionClass
        entity.EntityCollisionClass = entityData.EntCollToSet or entity.EntityCollisionClass

        if entityData.Height == 0 then
            entityData.PrevTags = entityData.Tags
            JumpLib:RunCallbackWithParam(JumpLib.Callbacks.ENTITY_LAND, entity, jumpData)
            JumpLib:QuitJump(entity)

            if player then
                local fell

                if jumpData.Flags & JumpLib.Flags.NO_PITFALL == 0 then
                    if jumpData.Flags & JumpLib.Flags.COLLISION_GRID == 0 then

                        local pitFound
                        local room = game:GetRoom()

                        local grid = room:GetGridEntityFromPos(player.Position)
                        local pit

                        if grid then
                            pit = grid:ToPit()
                        end

                        if pit then
                            if pit.State == 0 and not pit.HasLadder then
                                pitFound = true

                                if FiendFolio and StageAPI then
                                    for _, customGrid in ipairs(StageAPI.GetCustomGrids(room:GetGridIndex(player.Position), FiendFolio.LilyPadGrid.Name)) do
                                        if customGrid.PersistentData.State == "Idle" then
                                            pitFound = false
                                            break
                                        end
                                    end
                                end
                            end
                        end

                        if pitFound then
                            local canFly = player.CanFly
                            local hurt = jumpData.Flags & JumpLib.Flags.NO_HURT_PITFALL == 0 and 1 or 0

                            if jumpData.Flags & JumpLib.Flags.IGNORE_FLIGHT ~= 0 then
                                canFly = false
                            end

                            local fall = true and not canFly

                            if fall then
                                for _, v in ipairs(JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PRE_PITFALL, player, jumpData)) do
                                    if v == true then
                                        fall = false
                                        break
                                    elseif v == false then
                                        hurt = 0
                                    elseif type(v) == "number" then
                                        hurt = v
                                    end
                                end

                                fell = true
                                JumpLib:Pitfall(player, grid.Position, hurt)
                            end
                        end
                    end
                end

                JumpLib:RunCallbackWithParam(JumpLib.Callbacks.PLAYER_LAND, player, jumpData, fell)
            end

            entityData.PrevTags = nil
        end
    end
    AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, OnUpdate)

    ---@param player EntityPlayer
    local function PitfallVelocity(_, player)
        local data = JumpLib.Internal:GetData(player) if not data.Pitfall then return end

        player.ControlsEnabled = false

        player.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        player.Velocity = (data.PitPos - player.Position) * 0.1

        if player:GetSprite():IsFinished("FallIn") and player.SpriteScale ~= Vector.Zero then
            data.StoredSpriteScale = player.SpriteScale
            player.SpriteScale = Vector.Zero
        end
    end
    AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, PitfallVelocity)

    ---@param laser EntityLaser
    local function LaserUpdate(_, laser)
        if laser.Variant == LaserVariant.TRACTOR_BEAM then return end
        local spawner = laser.SpawnerEntity or laser.Parent

        if spawner and JumpLib:GetData(spawner).Jumping then
            JumpLib.Internal:LaserBehaviorsFromEntity(spawner)
        end

        if not JumpLib:GetData(laser) then return end

        laser.PositionOffset = JumpLib:GetOffset(laser)
    end
    AddCallback(ModCallbacks.MC_PRE_LASER_UPDATE, LaserUpdate)

    ---@param entity Entity
    local function PreRender(_, entity)
        local jumpData = JumpLib:GetData(entity)

        if jumpData.Jumping then
            return JumpLib:GetOffset(entity)
        end
    end

    -- ModCallbacks.MC_PRE_EFFECT_RENDER
    -- ModCallbacks.MC_PRE_FAMILIAR_RENDER
    -- ModCallbacks.MC_PRE_KNIFE_RENDER
    -- ModCallbacks.MC_PRE_NPC_RENDER
    -- ModCallbacks.MC_PRE_PICKUP_RENDER
    -- ModCallbacks.MC_PRE_PLAYER_RENDER
    -- ModCallbacks.MC_PRE_PROJECTILE_RENDER
    -- ModCallbacks.MC_PRE_TEAR_RENDER
    for i = ModCallbacks.MC_PRE_FAMILIAR_RENDER, ModCallbacks.MC_PRE_BOMB_RENDER do
        AddCallback(i, PreRender)
    end

    ---@param bomb EntityBomb
    local function OnBombDrop(_, bomb)
        local spawner = bomb.SpawnerEntity if not spawner then return end
        local data = JumpLib:GetData(spawner) if not data.Jumping or data.Flags & JumpLib.Flags.DISABLE_COOL_BOMBS ~= 0 then return end

        JumpLib:SetHeight(bomb, data.Height, {
            Height = 0,
            Speed = 1.25,
            Tags = "JUMPLIB_BOMB"
        })
    end
    AddCallback(ModCallbacks.MC_POST_BOMB_INIT, OnBombDrop)

    ---@param entity Entity
    local function BombLand(_, entity)
        local bomb = entity:ToBomb() ---@cast bomb EntityBomb
        if bomb.IsFetus then return end

        bomb:SetExplosionCountdown(0)
        -- bomb:Update()
    end
    AddCallback(JumpLib.Callbacks.ENTITY_LAND, BombLand, {
        type = EntityType.ENTITY_BOMB,
        tag = "JUMPLIB_BOMB"
    })

    ---@param entity Entity
    ---@param flags DamageFlag
    ---@param source EntityRef
    local function PreventDamage(_, entity, _, flags, source)
        if flags & DamageFlag.DAMAGE_RED_HEARTS ~= 0 then return end
        local data = JumpLib:GetData(entity) if not data.Jumping then return end
        if data.Flags & JumpLib.Flags.DAMAGE_CUSTOM ~= 0 then return end
        return false
    end
    AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PreventDamage)

    ---wip
    ---@param tear EntityTear | EntityProjectile
    local function TearInit(_, tear)
        if tear.FrameCount ~= 0 then return end
        local spawner = tear.SpawnerEntity or tear.Parent if not spawner then return end
        local data = JumpLib:GetData(spawner) if not data.Jumping or data.Flags & JumpLib.Flags.DISABLE_TEARHEIGHT ~= 0 then return end

        tear.Height = tear.Height - data.Height * 3.33
    end
    AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, TearInit)
    AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, TearInit)

    ---@param entity Entity
    local function EnableLaserFollow(_, entity)
        if JumpLib:GetData(entity).Flags & JumpLib.Flags.LASER_FOLLOW_CUSTOM == 0 then
            return true
        end
    end
    AddCallback(JumpLib.Callbacks.GET_LASER_CAN_FOLLOW_ENTITY, EnableLaserFollow)

    ---@param entity Entity
    ---@param hook InputHook
    ---@param action ButtonAction
    local function InputAction(_, entity, hook, action)
        local player = entity and entity:ToPlayer() if not player then return end
        local data = JumpLib:GetData(player) if not data.Jumping then return end

        if data.Flags & JumpLib.Flags.DISABLE_BOMB_INPUT ~= 0 then
            if action == ButtonAction.ACTION_BOMB then
                return JumpLib.Internal.HOOK_TO_CANCEL[hook]
            end
        elseif data.Flags & JumpLib.Flags.DISABLE_SHOOTING_INPUT ~= 0 then
            if JumpLib.Internal.SHOOT_ACTIONS[action] then
                return JumpLib.Internal.HOOK_TO_CANCEL[hook]
            end
        end
    end
    AddCallback(ModCallbacks.MC_INPUT_ACTION, InputAction)

    ---@param grid GridEntityPressurePlate
    local function ButtonUpdate(_, grid)
        for _, v in ipairs(Isaac.FindInRadius(grid.Position, 80, EntityPartition.PLAYER)) do
            local data = JumpLib:GetData(v) if data.Jumping and data.Flags & JumpLib.Flags.COLLISION_GRID == 0 then
                return true
            end
        end
    end
    AddCallback(ModCallbacks.MC_PRE_GRID_ENTITY_PRESSUREPLATE_UPDATE, ButtonUpdate)

    ---@param grid GridEntity
    local function LockUpdate(_, grid)
        for _, v in ipairs(Isaac.FindInRadius(grid.Position, 80, EntityPartition.PLAYER)) do
            local data = JumpLib:GetData(v) if data.Jumping and data.Flags & JumpLib.Flags.COLLISION_GRID == 0 then
                return true
            end
        end
    end
    AddCallback(ModCallbacks.MC_PRE_GRID_ENTITY_LOCK_UPDATE, LockUpdate)

    ---@param entity Entity
    ---@param grid GridEntity?
    local function GridCollision(_, entity, _, grid)
        local lock = grid and grid:ToLock() if not lock then return end
        local data = JumpLib:GetData(entity) if data.Jumping and data.Flags & JumpLib.Flags.COLLISION_GRID == 0 then
            return true
        end
    end for _, v in ipairs({
        ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION,
        ModCallbacks.MC_PRE_TEAR_GRID_COLLISION,
        ModCallbacks.MC_PRE_FAMILIAR_GRID_COLLISION,
        ModCallbacks.MC_PRE_BOMB_GRID_COLLISION,
        ModCallbacks.MC_PRE_PICKUP_GRID_COLLISION,
        ModCallbacks.MC_PRE_PROJECTILE_GRID_COLLISION,
        ModCallbacks.MC_PRE_NPC_GRID_COLLISION,
    }) do
        AddCallback(v, GridCollision)
    end

    for _, v in ipairs(JumpLib.Internal.CallbackEntries) do
        JumpLib:AddCallback(v.Callback, v.Function, v.Param)
    end
end

return LOCAL_JUMPLIB

-- Special thanks to Thicco Catto!!
