-- Scripter (ESO Add-On)
-- Copyright 2014 Neo Natura

if Scripter then return end
Scripter = {}
local Scripter = Scripter
local ScripterSL = ZO_Object:Subclass()
Settings = nil
scripterVersion = 2.0
local authorName = "@mahnki"

--local ScriptCommand = SLASH_COMMANDS["/script"]
local ChatLogCommand = SLASH_COMMANDS["/chatlog"]

-- Localize builtin functions we use 
local ipairs = ipairs
local next = next
local pairs = pairs
local tinsert = table.insert
local stat_stamp = {}
local stat_span = {}
local current_exp = 0
local current_vexp = 0
local victim = "unknown"
local scripterCraftEvent = false
local afk_index = 1
local NativeChannelEvent = nil

-- constant definitions
local S_NAME = "Name"
local S_CLASS = "Class"
local S_ALLIANCE = "Alliance"
local S_LEVEL = "Level"
local S_XP = "XP"

local ONE_HOUR = 3600

-- 30 days per moon cycle
local phaseLength = 30
local gamemonth = {"Morning Star","Sun's Dawn","First Seed","Rain's Hand","Second Seed","Midyear","Sun's Height","Last Seed","Hearthfire","Frostfall","Sun's Dusk","Evening Star"}
local gameweek = {"Sundas","Morndas","Tirdas","Middas","Turdas","Fredas","Loredas"}

-- Localize ESO API functions we use
local d = d
local strjoin = zo_strjoin
local GetNumActionLayers = GetNumActionLayers
local GetActionLayerInfo = GetActionLayerInfo
local GetActionLayerCategoryInfo = GetActionLayerCategoryInfo
local GetActionInfo = GetActionInfo
local GetActionIndicesFromName = GetActionIndicesFromName

VAL_USERDATA_FUNC = "userdata_func"

function SetScripterValue(token, value)
    Scripter.savedVariables[token] = value
end

function GetScripterValue(token)
    return Scripter.savedVariables[token]
end

function Scripter.InitChatSystem()
   local scrollbar = CHAT_SYSTEM["containers"][1]["scrollbar"]
   local buffer = CHAT_SYSTEM["containers"][1]["currentBuffer"]
   if (scrollbar ~= nil and scrollbar:IsHidden() == true) then
       scrollbar:SetHidden(false)
       scrollbar:SetEnabled(true)
--       buffer:SetClearBufferAfterFadeout(false)
   end
end

local function print(...)
    si_chat_print(...)
end

local default_help_desc = {
    ["/away"] = "Manage \"away from keyboard\" mode.",
    ["/alias"] = "Create and manage slash commands.",
    ["/clear"] = "Clear the chat window history.",
    ["/cmd"] = "Display slash commands.",
    ["/eq"] = "Character inventory.",
    ["/friend"] = "Display contacts information.",
    ["/func"] = "Manage in-game functions.",
    ["/junk"] = "Display the junk item list.",
    ["/keybind"] = "Setup key bindings.",
    ["/filter"] = "Manage chat filter.",
    ["/func"] = "Execute and edit functions.",
    ["/invite"] = "Perform group invite.",
    ["/leave"] = "Perform group leave",
    ["/loc"] = "Character location information.",
    ["/log"] = "Manage character activity log.",
    ["/mail"] = "Manage character's mail messages.",
    ["/min"] = "Minimize the chat window.",
    ["/quest"] = "Display character quest information.",
    ["/research"] = "Display researchable items.",
    ["/sguild"] = "Display guild character information.",
    ["/sgroup"] = "Manage the character's party group.",
    ["/rl"] = "Reload user intrface.",
    ["/scripter"] = "Scripter command usage.",
    ["/sconfig"] = "Scripter configuration settings.",
    ["/stat"] = "Character attributes information.",
    ["/scmd"] = "List all scripter commands",
    ["/feedback"] = "Submit a Scripter bug or enhancement.",
    ["/snap"] = "Take a screenshot.",
    ["/sync"] = "Synchronize character attributes.",
    ["/time"] = "Display current time.",
    ["/timer"] = "Manage timed events.",
    ["/ttime"] = "Display current Tamriel time.",
    ["/vendor"] = "Display item vendor information.",
    ["/who"] = "Display list of online friends.",
}

local default_alias_cmd = {
    ["invite"] = {"sgroup", "/invite"},
    ["leave"] = {"sgroup", "/leave"},
    ["rl"] = "reloadui",
    ["scmd"] = {"cmd","/scripter"},
    ["ttime"] = {"time","/game"},
    ["who"] = {"friend","/online"},
}

local default_functions = {
    ["hello"] = "s_print('Hello world.')",
    ["bluetext"] = "s_print(s_pr_clr(0,0,1) .. s_args)",
    ["bluehello"] = "s_call('bluetext', 'Hello world.')",
    ["realtime"] = "s_print('Earth Time: ' .. s_pr_date())",
}

Scripter.defaults = {
    ["bindings"] = {},
    ["autoSets"] = {},
    ["log"] = {},
    ["log_idx"] = 0,
    ["chat"] = {},
    ["chat_idx"] = 0,
    -- timed events
    ["usertime_afk"] = 0,
    ["usertime_mail"] = 0,
    ["usertime_timer"] = {},
    ["usertime_ptimer"] = {},
    ["usertime_ptimer_span"] = {},
    ["usertime_offset"] = 0,
    ["usertime_sync_item"] = 0,
    ["usertime_sync_quest"] = 0,
    ["usertime_sync_skill"] = 0,
    ["usertime_sync_trait"] = 0,
    -- dynamic internal variables
    ["buff"] = {},
    ["slot"] = {},
    ["usertemp_llogin"] = nil,
    ["usertemp_login_stamp"] = 0,
    ["usertemp_mail"] = {},
    ["usertemp_money"] = 0,
    -- persistent time saved information.
    ["lmoon"] = {
	start = 1407553200, -- Unix time of the start of the full moon phase in s
        full = 10, -- length of a full moon phase in real time in s -> TRY IN NIGHTS FOR DAYLENGTH OFFSET
        new = 5, -- length of a new moon phase in real time in s
        way = 85, -- length of the way between full moon and new moon in s
        name = "full",
    },
    ["gametime"] = {
--	start = 1398044126, -- exact unix time at the calculated game time start in s
--        daytime = 20955, -- length of one day in s (default 5.75h right now)
	-- start = 1396083600,
	start = 1396104332,
        daytime = 20976, 
        night = 7200, -- time of only the night ins (2h)
        name = "noon",
    },
    -- persistent help saved information.
    ["userhelp_desc"] = default_help_desc,
    -- persistent user saved information.
    ["userdata_alias_v3"] = default_alias_cmd,
    ["userdata_junk"] = {},
    ["userdata_filter"] = {},
    ["userdata_public"] = {},
    ["userdata_ability_rate"] = {},
    ["userdata_skill"] = {},
    ["userdata_quest"] = {},
    ["userdata_vendor"] = {},
    ["userdata_vendor_loc"] = {},
    ["userdata_zone"] = {},
    ["userdata_zone_loc"] = {},
    ["userdata_attr"] = {},
    ["userdata_item_worn"] = {},
    ["userdata_money"] = 0,
    ["userdata_skill_percent"] = {},
    ["userdata_sync"] = {},
    ["userdata_trait"] = {},
    ["userdata_func"] = default_functions,
    ["userdata_db"] = {},
    -- persistent character attribute information
    ["chardata_attr"] = {},
    ["chardata_item_worn"] = {},
    ["chardata_quest"] = {}, 
    ["chardata_rating"] = {}, 
    ["chardata_skill"] = {}, 
    ["chardata_sync"] = {}, 
    ["chardata_sync_read"] = {}, 
    ["chardata_sync_opt"] = {},
    ["chardata_trait"] = {},
}

function Scripter.GetFontNames()
    return Settings:GetFontNames()
end

function Scripter.GetFont(name)
    return Settings:GetFont(name)
end

local itemEquipType = {
    ["Costume"] = EQUIP_TYPE_COSTUME,
    ["Head"] = EQUIP_TYPE_HEAD,
    ["Neck"] = EQUIP_TYPE_NECK,
    ["Shoulders"] = EQUIP_TYPE_SHOULDERS,
    ["Hand"] = EQUIP_TYPE_HAND,
    ["Shield"] = EQUIP_TYPE_OFF_HAND,
    ["Two-Hand"] = EQUIP_TYPE_TWO_HAND,
    ["Ring"] = EQUIP_TYPE_RING,
    ["Chest"] = EQUIP_TYPE_CHEST,
    ["Waist"] = EQUIP_TYPE_WAIST,
    ["Legs"] = EQUIP_TYPE_LEGS,
    ["Feet"] = EQUIP_TYPE_FEET,
}

function Scripter.GetItemEquipLabel(val)
    for k, v in pairs(itemEquipType) do
        if val == v then
            return k
        end
    end
    return "unknown"
end

local itemArmorType = {
    ["None"] = ARMORTYPE_NONE,
    ["Light"] = ARMORTYPE_LIGHT,
    ["Medium"] = ARMORTYPE_MEDIUM,
    ["Heavy"] = ARMORTYPE_HEAVY,
}

function Scripter.GetItemArmorLabel(val)
    for k, v in pairs(itemArmorType) do
        if val == v then
            return k
        end
    end
    return "unknown"
end

local itemWeaponType = {
    ["Bow"] = WEAPONTYPE_BOW,
    ["Axe"] = WEAPONTYPE_AXE,
    ["Mace"] = WEAPONTYPE_HAMMER,
    ["Sword"] = WEAPONTYPE_SWORD,
    ["Two-Handed Axe"] = WEAPONTYPE_TWO_HANDED_AXE,
    ["Two-Handed Mace"] = WEAPONTYPE_TWO_HANDED_HAMMER,
    ["Two-Handed Sword"] = WEAPONTYPE_TWO_HANDED_SWORD,
    ["Dagger"] = WEAPONTYPE_DAGGER,
    ["Fire Staff"] = WEAPONTYPE_FIRE_STAFF,
    ["Frost Staff"] = WEAPONTYPE_FROST_STAFF,
    ["Lightning Staff"] = WEAPONTYPE_LIGHTNING_STAFF,
    ["Healing Staff"] = WEAPONTYPE_HEALING_STAFF,
}

function Scripter.GetItemWeaponLabel(val)
    for k, v in pairs(itemWeaponType) do
        if val == v then
            return k
        end
    end
    return "unknown"
end

local itemCategoryType = {
    ["Plug"] = ITEMTYPE_PLUG,
    ["Siege"] = ITEMTYPE_SIEGE,
    ["Trash"] = ITEMTYPE_TRASH,
    ["Trophy"] = ITEMTYPE_TROPHY,
    ["Tool"] = ITEMTYPE_TOOL,
    ["Tabard"] = ITEMTYPE_TABARD,
    ["Soul Gem"] = ITEMTYPE_SOUL_GEM,
    ["Recipe"] = ITEMTYPE_RECIPE,
    ["None"] = ITEMTYPE_NONE,
    ["LockPick"] = ITEMTYPE_LOCKPICK,
    ["Costume"] = ITEMTYPE_COSTUME,
    ["Container"] = ITEMTYPE_CONTAINER,
    ["Repair"] = ITEMTYPE_AVA_REPAIR,
    ["Ingredient"] = ITEMTYPE_INGREDIENT,
    ["Wood Raw Material"] = ITEMTYPE_WOODWORKING_RAW_MATERIAL,
    ["Wood Material"] = ITEMTYPE_WOODWORKING_MATERIAL,
    ["Wood Booster"] = ITEMTYPE_WOODWORKING_BOOSTER,
    ["Weapon Trait"] = ITEMTYPE_WEAPON_TRAIT,
    ["Weapon"] = ITEMTYPE_BOOSTER,
    ["Trophy"] = ITEMTYPE_TROPHY,
    ["Style Material"] = ITEMTYPE_STYLE_MATERIAL, 
    ["Spice"] = ITEMTYPE_SPICE,
    ["Reagent"] = ITEMTYPE_REAGENT,
    ["Potion"] = ITEMTYPE_POTION,
    ["Jewelry Glyph"] = ITEMTYPE_GLYPH_JEWELRY,
    ["Armor Glyph"] = ITEMTYPE_GLYPH_ARMOR,
    ["Weapon Glyph"] = ITEMTYPE_GLYPH_WEAPON,
    ["Flavoring"] = ITEMTYPE_FLAVORING,
    ["Enhchantment Booster"] = ITEMTYPE_ENHANCEMENT_BOOSTER,
    ["Echanting Rune"] = ITEMTYPE_ENCHANTING_RUNE,
    ["Drink"] = ITEMTYPE_DRINK,
    ["Disguise"] = ITEMTYPE_DISGUISE,
    ["Collectible"] = ITEMTYPE_COLLECTIBLE,
    ["Cloth Raw Material"] = ITEMTYPE_CLOTHIER_RAW_MATERIAL,
    ["Cloth Material"] = ITEMTYPE_CLOTHIER_MATERIAL,
    ["Cloth Booster"] = ITEMTYPE_CLOTHIER_BOOSTER,
    ["Weapon Raw Material"] = ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
    ["Weapon Material"] = ITEMTYPE_BLACKSMITHING_MATERIAL,
    ["Weapon Booster"] = ITEMTYPE_BLACKSMITHING_BOOSTER,
    ["Alchemy Base"] = ITEMTYPE_ALCHEMY_BASE,
    ["Additive"] = ITEMTYPE_ADDITIVE,
    ["Food"] = ITEMTYPE_FOOD,
    ["Armor Trait"] = ITEMTYPE_ARMOR_TRAIT,
    ["Armor Booster"] = ITEMTYPE_ARMOR_BOOSTER,
    ["Armor"] = ITEMTYPE_ARMOR,
    ["Lure"] = ITEMTYPE_LURE,
    ["Rune Aspect"] = ITEMTYPE_ENCHANTING_RUNE_ASPECT,
    ["Rune Potency"] = ITEMTYPE_ENCHANTING_RUNE_POTENCY,
    ["Rune Essence"] = ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
}

function Scripter.GetItemCategoryLabel(val)
    for k, v in pairs(itemCategoryType) do
        if val == v then
            return k
        end
    end
    return "unknown"
end

local itemQualityType = {
    ["Trash"] = ITEM_QUALITY_TRASH,
    ["Magic"] = ITEM_QUALITY_MAGIC,
    ["Arcane"] = ITEM_QUALITY_ARCANE,
    ["Artifact"] = ITEM_QUALITY_ARTIFACT,
    ["Legendary"] = ITEM_QUALITY_LEGENDARY,
    ["Normal"] = ITEM_QUALITY_NORMAL,
    ["Legendary"] = ITEM_QUALITY_LEGENDARY,
}

function Scripter.GetItemQualityLabel(val)
    for k, v in pairs(itemQualityType) do
        if val == v then
            return k
        end
    end
    return "unknown"
end

local itemCraftType = {
    ["Alchemy"] = CRAFTING_TYPE_ALCHEMY,
    ["Blacksmith"] = CRAFTING_TYPE_BLACKSMITHING,
    ["Clothier"] = CRAFTING_TYPE_CLOTHIER,
    ["Enchanting"] = CRAFTING_TYPE_ENCHANTING,
    ["Provisioning"] = CRAFTING_TYPE_PROVISIONING,
    ["Woodworker"] = CRAFTING_TYPE_WOODWORKING,
}

function Scripter.GetItemCraftTypeLabel(craftType)
    for k,v in pairs(itemCraftType) do
        if v == craftType then
            return k
        end
    end
    return ("Unknown")
end

local craftArmorTraitType = {
}
local craftJewleryTraitType = {
}
local craftTraitType = {
    [ITEM_TRAIT_TYPE_NONE] = "None",
    [ITEM_TRAIT_TYPE_ARMOR_DIVINES] = "Divines",
    [ITEM_TRAIT_TYPE_ARMOR_EXPLORATION] = "Exploration",
    [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = "Impenetrable",
    [ITEM_TRAIT_TYPE_ARMOR_INFUSED] = "Infused",
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE] = "Ornate",
    [ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = "Reinforced",
    [ITEM_TRAIT_TYPE_ARMOR_STURDY] = "Sturdy",
    [ITEM_TRAIT_TYPE_ARMOR_TRAINING] = "Training",
    [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = "Well-Fitted",
    [ITEM_TRAIT_TYPE_JEWELRY_ARCANE] = "Arcane",
    [ITEM_TRAIT_TYPE_JEWELRY_HEALTHY] = "Healthy",
    [ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = "Ornate",
    [ITEM_TRAIT_TYPE_JEWELRY_ROBUST] = "Robust",
    [ITEM_TRAIT_TYPE_WEAPON_CHARGED] = "Charged",
    [ITEM_TRAIT_TYPE_WEAPON_DEFENDING] = "Defending",
    [ITEM_TRAIT_TYPE_WEAPON_INFUSED] = "Infused",
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = "Intricate",
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE] = "Ornate",
    [ITEM_TRAIT_TYPE_WEAPON_POWERED] = "Powered",
    [ITEM_TRAIT_TYPE_WEAPON_PRECISE] = "Precise",
    [ITEM_TRAIT_TYPE_WEAPON_SHARPENED] = "Sharpened",
    [ITEM_TRAIT_TYPE_WEAPON_TRAINING] = "Training",
    [ITEM_TRAIT_TYPE_WEAPON_WEIGHTED] = "Weighted",
}

function Scripter.GetItemTraitLabel(traitType)
    local traitLabel = craftTraitType[traitType]
    if traitLabel == nil then traitLabel = "unknown" end
    return traitLabel
end

local charStatType = {
    ["Magicka Regen"] = STAT_MAGICKA_REGEN_IDLE,
    ["Health Regen"] = STAT_HEALTH_REGEN_IDLE,
    ["Stamina Regen"] = STAT_STAMINA_REGEN_COMBAT,
    ["Combat Critical"] = STAT_CRITICAL_STIKE,
    ["Magic Critical"] = STAT_SPELL_CRITICAL,
    ["Stamina Regen"] = STAT_STATMINA_REGEN_IDLE,
    ["Combat Damage"] = STAT_POWER,
    ["Magicka Damage"] = STAT_SPELL_POWER,
    ["Damage Resist"] = STAT_DAMAGE_RESIST_GENERI,
    ["Critical Resist"] = STAT_CRITICAL_RESISTANCE,
    ["Poison Resist"] = STAT_DAMAGE_RESIST_POISON,
    ["Shock Resist"] = STAT_DAMAGE_RESIST_SHOCK,
    ["Disease Resist"] = STAT_DAMAGE_RESIST_DISEASE,
    ["Fire Resist"] = STAT_DAMAGE_RESIST_FIRE,
    ["Cold Resist"] = STAT_DAMAGE_RESIST_COLD,
    ["Magicka Resist"] = STAT_SPELL_RESIST,
    ["Mana"] = STAT_MAGICKA_MAX,
    ["Health"] = STAT_HEALTH_MAX,
    ["Stamina"] = STAT_STAMINA_MAX,
}

function Scripter.GetCharStatLabel(val)
    for k, v in pairs(charStatType) do
        if val == v then
            return k
        end
    end
    return "unknown"
end

function Scripter.GetItemQuailtyColor(val)
    local r,g,b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, val);
    return string.format("|c%-2.2x%-2.2x%-2.2x", r, g, b)
end

function Scripter.NullCommand()
    -- all done
end

function Scripter.UnimplementedCommand(textarg)
    print("I'm sorry, Dave. I'm afraid I can't do that.")
end

function Scripter.HighlightText(text)
    return "|cff8f41" .. text .. "|cffffff"
end

function Scripter.PrintDebug(text)
    if text == nil then return end
    if Settings:GetValue(OPT_DEBUG) == false then return end
    print("[debug] " .. text)
end

-- returns whether an account name matches a friend or guild member
function Scripter.IsAccountValid(argtext)
    if (argtext == nil or argtext == "") then return false end

    if string.gmatch(argtext, "^@") == nil then
        argtext = "@" .. argtext;
    end

    for i = 1, GetNumFriends(), 1 do
        local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(i)
        if displayName == argtext then
          return (true)
        end
    end

    for i = 1, GetNumGuilds() do
       local guildId = GetGuildId(i)
       for memberId = 1, GetNumGuildMembers(guildId) do
           local accName = GetGuildMemberInfo(guildId, memberId);
	   if accName == argtext then
               return true
           end
        end
    end

    return false
end

-- returns whether a particular account is currently online
function Scripter.IsAccountOnline(argtext)
    if (argtext == nil or argtext == "") then return false end

    if string.gmatch(argtext, "^@") == nil then
        argtext = "@" .. argtext;
    end
    for i = 1, GetNumFriends(), 1 do
        local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(i)
        if (displayName == argtext and playerStatus == 1) then
          return (true)
        end
    end

    for i = 1, GetNumGuilds() do
       local guildId = GetGuildId(i)
       for memberId = 1, GetNumGuildMembers(guildId) do
           local accName,note,rank,stat,sec = GetGuildMemberInfo(guildId, memberId);
	   if (accName == argtext and stat == 1) then
               return true
           end
        end
    end

    return false
end

function Scripter.SetCharacterAttribute(characterName, name, text)
    if (characterName == nil or characterName == "") then return end
    if (name == nil or name == "") then return end

    -- retrieve stored data
    local data = Scripter.savedVariables.chardata_attr[characterName]
    if data == nil then
        data = {}
    end

    -- define new attribute value
    if (text == nil or text == "Unknown" or text == "") then
        data[name] = nil
    else
        data[name] = text
    end

    -- store data
    Scripter.savedVariables.chardata_attr[characterName] = data
end

function Scripter.GetCharacterAttribute(characterName, name)
    if (characterName == nil or characterName == "") then return "" end
    if (name == nil or name == "") then return "" end

    local data = Scripter.savedVariables.chardata_attr[characterName]
    if data == nil then
       return ""
    end

    if data[name] == nil then
       return ""
    end

    return data[name]
end

function Scripter.BuildActionTables()
    local actionHierarchy = {}
    local actionNames = {}
    local layers = GetNumActionLayers()
    for layerIndex=1, layers do
        local layerName, categories = GetActionLayerInfo(layerIndex)
        local layer = {}
        for categoryIndex=1, categories do
            local category = {}
            local categoryName, actions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
            for actionIndex=1, actions do
                local actionName, isRebindable, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)
                if isRebindable then
                    local action = {
                        ["name"] = actionName,
                        ["rebind"] = isRebindable,
                        ["hidden"] = isHidden,
                    }
                    category[actionIndex] = action
                    tinsert(actionNames, actionName)
                end
            end
            if next(category) ~= nil then
                category["name"] = categoryName
                layer[categoryIndex] = category
            end
        end
        if next(layer) ~= nil then
            layer["name"] = layerName
            actionHierarchy[layerIndex] = layer
        end
    end
    Scripter.actionHierarchy = actionHierarchy
    Scripter.actionNames = actionNames
end

function Scripter.BuildBindingsTable()
    if not Scripter.actionNames then Scripter.BuildActionTables() end
    local bindings = {}
    local bindCount = 0
    local maxBindings = GetMaxBindingsPerAction()
    for index, actionName in ipairs(Scripter.actionNames) do
        local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
        local actionBindings = {}
        for bindIndex=1, maxBindings do
            local keyCode, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindIndex)
            if keyCode ~= 0 then
                local bind = {
                    ["keyCode"] = keyCode,
                    ["mod1"] = mod1,
                    ["mod2"] = mod2,
                    ["mod3"] = mod3,
                    ["mod4"] = mod4,
                }
                tinsert(actionBindings, bind)
                bindCount = bindCount + 1
            end
        end
        bindings[actionName] = actionBindings
    end
    Scripter.bindings = bindings
    Scripter.bindCount = bindCount
end

function Scripter.RestoreBindingsFromTable()
    local bindCount = 0
    local attemptedBindCount = 0
    local skippedBindCount = 0
    local maxBindings = GetMaxBindingsPerAction()
    for actionName, actionBindings in pairs(Scripter.bindings) do
        local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
        if layerIndex and categoryIndex and actionIndex then
            CallSecureProtected("UnbindAllKeysFromAction", layerIndex, categoryIndex, actionIndex)
            for bindingIndex, bind in ipairs(actionBindings) do
                if bindingIndex <= maxBindings then
                    attemptedBindCount = attemptedBindCount + 1
                    CallSecureProtected("BindKeyToAction", layerIndex, categoryIndex, actionIndex, bindingIndex, bind["keyCode"], bind["mod1"], bind["mod2"], bind["mod3"], bind["mod4"])
                    bindCount = bindCount + 1
                else
                    skippedBindCount = skippedBindCount + 1
                end
            end
        else
            skippedBindCount = skippedBindCount + 1
        end
    end
end

function Scripter.SaveBindings(bindSetName, isSilent)
    if bindSetName == nil or bindSetName == "" then
        print("Usage: /keybind /set <name>")
        return
    end
    Scripter.BuildBindingsTable()
    
    -- Update any existing bind set as a set union, or create new
    local bindSet = Scripter.savedVariables.bindings[bindSetName] or {}
    for bindName, binding in pairs(Scripter.bindings) do
        bindSet[bindName] = binding
    end
    Scripter.savedVariables.bindings[bindSetName] = bindSet
    
    if not isSilent then
        print("Saved " .. Scripter.bindCount .. " bindings to bind set '" .. Scripter.HighlightText(bindSetName) .. "'.")
    end
    local character = GetUnitName("player")
    Scripter.savedVariables.autoSets[character] = bindSetName
end

function Scripter.LoadBindings(bindSetName, isSilent)
    if bindSetName == nil or bindSetName == "" then
        print("Usage: /keybind load <set name>")
        return
    end
    if Scripter.savedVariables.bindings[bindSetName] == nil then
        print("Bind set '" .. Scripter.HighlightText(bindSetName) .. "' does not exist.")
        return
    end
    if IsUnitInCombat("player") then
        print("Cannot load bind set - in combat. Please try again out of combat.")
        return
    end
    Scripter.bindings = Scripter.savedVariables.bindings[bindSetName]
    Scripter.RestoreBindingsFromTable()
    if not isSilent then
        print("Loaded ", Scripter.bindCount, " bindings from bind set '" .. Scripter.HighlightText(bindSetName) .. "'.")
    end
    local character = GetUnitName("player")
    Scripter.savedVariables.autoSets[character] = bindSetName
end

function Scripter.ListBindings()
    local sets = {}
    for setName in pairs(Scripter.savedVariables.bindings) do
        table.insert(sets, setName)
    end
    table.sort(sets)
    print("Keybinds:")
    for i,setName in ipairs(sets) do
        print("- ", setName)
    end
end

function Scripter.DeleteBindings(bindSetName)
    if bindSetName == nil or bindSetName == "" then
        print("Usage: /keybind /delete <name>")
        return
    end
    if Scripter.savedVariables.bindings[bindSetName] == nil then
        print("Scripter: Bind set '" .. Scripter.HighlightText(bindSetName) .. "' does not exist.")
        return
    end
    Scripter.savedVariables.bindings[bindSetName] = nil
    print("Scripter: Deleted bind set '" .. Scripter.HighlightText(bindSetName) .. "'.")
end

function Scripter.SaveAutomaticBindings(isSilent)
    -- No-op if automatic mode is disabled.
    if Settings:GetValue(OPT_AUTOBIND) == false then return end
    
    local character = GetUnitName("player")
    local setName = Scripter.savedVariables.autoSets[character]
    
    if setName == nil then
        setName = character:gsub(" ", "-") .. "-auto"
        Scripter.savedVariables.autoSets[character] = setName
    end
    
    Scripter.SaveBindings(setName, isSilent)
end

function Scripter.LoadAutomaticBindings(isSilent)
    if Settings:GetValue(OPT_AUTOBIND) == false then return end
    
    local character = GetUnitName("player")
    local setName = Scripter.savedVariables.autoSets[character]
    
    if setName ~= nil then
        Scripter.LoadBindings(setName, isSilent)
    else
        -- If there isn't a set to load, but automatic mode is on,
        -- create a new set.
        Scripter.SaveAutomaticBindings(isSilent)
    end
end

function Scripter.OnKeybindingSetOrCleared()
    -- Silently update active bind set
    Scripter.SaveAutomaticBindings(true)
end

function Scripter.OnKeybindingsLoaded()
    -- Silently load active bind set
    Scripter.LoadAutomaticBindings(true)
end

function Scripter.FormatTime(time)
	if time == nil then
	    return ""
	end
    local midnightSeconds = GetSecondsSinceMidnight()
    local utcSeconds = GetTimeStamp() % 86400
    local offset = midnightSeconds - utcSeconds
    if offset < -43200 then
    	offset = offset + 86400
    end

    local timeString = ZO_FormatTime((time + offset) % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
	return string.format("%s", timeString)
end

function Scripter.isPlayerAfk()
    if (GetPlayerStatus() == PLAYER_STATUS_AWAY or GetPlayerStatus() == PLAYER_STATUS_DO_NOT_DISTURB) then
        return true;
    end
    return false;
end

function Scripter.setPlayerAfk(status)
    SelectPlayerStatus(status)
end

function Scripter.ResetAfkMode()
    Scripter.setPlayerAfk(PLAYER_STATUS_ONLINE)
    Scripter.savedVariables.usertime_afk = 0
end

function Scripter.AFKWake()
    if Scripter.isPlayerAfk() == false then return end

    Scripter.ResetAfkMode()
    print("Scripter: Character AFK mode disabled.")
end

function Scripter.AFKSleep()
    if Scripter.isPlayerAfk() == false then return end

    Scripter.savedVariables.usertime_afk = Scripter.GetTimerOffset() + 60000
    Scripter.PrintDebug("AFKSleep " .. Scripter.FormatTime(GetTimeStamp() + 60))

    local cmd_base = Settings:GetValue(OPT_AFK_ACTION)
    if cmd_base == "<none>" then return end

    afk_index = afk_index + 1
    if afk_index > 6 then afk_index = 2 end
    local cmd_name = "/" .. cmd_base .. afk_index
    mcommand = SLASH_COMMANDS[cmd_name]
    if mcommand == nil then
        cmd_name = "/" .. cmd_base
        mcommand = SLASH_COMMANDS[cmd_name]
    end
    if mcommand ~= nil then
        mcommand("")
    end

end

function Scripter.PreEventCheck()
    if GetPlayerStatus() == PLAYER_STATUS_AWAY then
        Scripter.AFKWake()
    end
end

function Scripter.PreCommandCheck()
    if GetPlayerStatus() == PLAYER_STATUS_AWAY then
        Scripter.AFKWake()
    end

    
    -- disables lose focus after entering command
    if Settings:GetValue(OPT_CHAT_FOCUS) == true then 
        IgnoreMouseDownEditFocusLoss()
        CHAT_SYSTEM:StartTextEntry(nil, nil)
    end
end

function Scripter.ChannelFilter(eventType, messageType, fromName, text)
    if text == nil then return false end
    if type(text) ~= "string" then return false end

    for k,v in pairs(Scripter.savedVariables.userdata_filter) do
        if string.match(text, k) ~= nil then
            return true
        end
    end

    return false
end

function Scripter.AppendLog(ntext)
    if ntext == "" then return end

    if Scripter.savedVariables.log_idx == 1000 then
        Scripter.savedVariables.log_idx = 0
    end
    Scripter.savedVariables.log_idx = Scripter.savedVariables.log_idx + 1
	local tstr = Scripter.FormatTime(GetTimeStamp())
    Scripter.savedVariables.log[Scripter.savedVariables.log_idx] = "[" .. tstr .. "] " .. ntext
end

function Scripter.NotifyCharacterAction(notifyType, ntext)
    ntext = "|cFFFFFF" .. ntext
    Scripter.AppendLog(ntext)

    if Settings:GetValue(OPT_NOTIFY) == false then return end
    if Settings:GetValue(notifyType) == false then return end
    ScripterGui.addMessage(ntext)
end

function Scripter.ChatListCommand(argtext)
    print("Chat History:")

    local max = Settings:GetValue(OPT_CHAT_MAX)

    local cnt = 0
    for i = Scripter.savedVariables.chat_idx + 1, 1000, 1 do
        if Scripter.savedVariables.chat[i] ~= nil then
            if cnt > (1000 - max) then
                print(Scripter.savedVariables.chat[i])
            end
        end
        cnt = cnt + 1
    end

    for i = 1, Scripter.savedVariables.chat_idx, 1 do
        if Scripter.savedVariables.chat[i] ~= nil then
            if cnt > (1000 - max) then
                print(Scripter.savedVariables.chat[i])
            end
        end
        cnt = cnt + 1
    end
end

local channelType = {
    ["whisper sent"] = CHAT_CHANNEL_WHISPER_SENT,
    ["whisper"] = CHAT_CHANNEL_WHISPER,
    ["party"] = CHAT_CHANNEL_PARTY,
    ["monster"] = CHAT_CHANNEL_MONSTER_SAY,
    ["monster emote"] = CHAT_CHANNEL_MONSTER_EMOTE,
    ["monster whisper"] = CHAT_CHANNEL_MONSTER_WHISPER,
    ["emote"] = CHAT_CHANNEL_EMOTE,
    ["yell"] = CHAT_CHANNEL_YELL,
    ["say"] = CHAT_CHANNEL_SAY,
    ["guild1"] = CHAT_CHANNEL_GUILD_1,
    ["guild2"] = CHAT_CHANNEL_GUILD_2,
    ["guild3"] = CHAT_CHANNEL_GUILD_3,
    ["guild4"] = CHAT_CHANNEL_GUILD_4,
    ["guild5"] = CHAT_CHANNEL_GUILD_5,
    ["zone"] = CHAT_CHANNEL_ZONE,
    ["zone1"] = CHAT_CHANNEL_ZONE_LANGUAGE_1,
    ["zone2"] = CHAT_CHANNEL_ZONE_LANGUAGE_2,
    ["zone3"] = CHAT_CHANNEL_ZONE_LANGUAGE_3,
    ["officer1"] = CHAT_CHANNEL_OFFICER_1,
    ["officer2"] = CHAT_CHANNEL_OFFICER_2,
    ["officer3"] = CHAT_CHANNEL_OFFICER_3,
    ["sys"] = CHAT_CHANNEL_SYSTEM,
}

function Scripter.GetChannelType(messageType)
    for k,v in pairs(channelType) do
        if v == messageType then 
            return k
        end
    end

    return "unknown"
end

function Scripter.StoreChannelText(eventType, messageType, fromName, text)
    if (text == nil or type(text) ~= "string" or text == "") then return end
    if messageType == CHAT_CHANNEL_SYSTEM then return end 

    local cType = Scripter.GetChannelType(messageType)
    if cType == "unknown" then return end

    local selfName = GetUnitName('player')
    local dispName = GetDisplayName()
    fromName = Scripter.ResolveCharacterName(fromName)

    if Scripter.savedVariables.chat_idx == 1000 then
        Scripter.savedVariables.chat_idx = 0
    end

    Scripter.savedVariables.chat_idx = Scripter.savedVariables.chat_idx + 1
    local tstr = Scripter.FormatTime(GetTimeStamp())
    local cType = Scripter.GetChannelType(messageType)
    cType = "/" .. string.sub(cType, 0, 3)
    if messageType == CHAT_CHANNEL_WHISPER_SENT then
        cType = "->" .. cType
    end

    if (fromName == dispName or fromName == selfName) then
        Scripter.savedVariables.chat[Scripter.savedVariables.chat_idx] = "[" .. tstr .. cType .. "] " .. text
    else
        Scripter.savedVariables.chat[Scripter.savedVariables.chat_idx] = "[" .. tstr .. " " .. Scripter.HighlightText(fromName) .. cType .. "] " .. text
    end
end

function Scripter.ChannelFilterEvent(control, ...)
    if Scripter.ChannelFilter(...) then
        return
    end

    Scripter.StoreChannelText(...)

    if NativeChannelEvent == nil then
        return
    end

    if (GetPlayerStatus() ~= PLAYER_STATUS_DO_NOT_DISTURB or Settings:GetValue(OPT_CHAT_SUPPRESS) == false) then
        NativeChannelEvent(control, ...)
    end
end

function NewSyncChannelEvent(sender, message)
    local str_ar = si_strsplit(":", message)
    if str_ar ~= nil then
        Scripter.savedVariables.userdata_public[sender] = ""
        for k,w in pairs(str_ar) do
            local toks = si_strsplit(" ", w)
            local val = toks[1];
            local name = Scripter.extractstr(toks,2)
	    if name ~= "" then
                Scripter.savedVariables.userdata_public[sender] = Scripter.savedVariables.userdata_public[sender] .. name .. ": " .. val .. "  "
            end
	end
	Scripter.NotifyCharacterAction(OPT_NOTIFY_MISC, "Sync received from '" .. Scripter.HighlightText(sender) .. "'.")
    end
end

function Scripter.ResolveCharacterName(name)
    local resolvedCharacterName = name:match("([^^]+)^([^^]+)")
    if resolvedCharacterName == nil then return name end
    return resolvedCharacterName
end

function Scripter.FormatItemName(name)
    return Scripter.ResolveCharacterName(name)
--     if name == nil then
--         name = "unknown"
--     end
--     name = string.gsub(name, "(^Fx)", "")
--     name = string.gsub(name, "(^Mx)", "")
--     name = string.gsub(name, "(^p)", "")
--     name = string.gsub(name, "(^n)", "")
--     name = string.gsub(name, "(^m)", "")
--     name = string.gsub(name, "(^M)", "")
--     name = string.gsub(name, "(^f)", "")
--     return name
end

function Scripter.NewChannelEvent(eventCode, messageType, sender, message)
    if sender == GetRawUnitName("player") then
        Scripter.PreEventCheck()
    end
end

--function Scripter.GetZoneAndSubzone(alternative)
--   if alternative then
--      return select(3,(GetMapTileTexture()):lower():find("maps/([%w%-]+/[%w%-]+_[%w%-]+)"))
--   end
--
--   return select(3,(GetMapTileTexture()):lower():find("maps/([%w%-]+)/([%w%-]+_[%w%-]+)"))
--end

function Scripter.GetPlayerLocation()
    return si_char_location()
--    local zone, subzone = Scripter.GetZoneAndSubzone()
--    local x, y = GetMapPlayerPosition('player')
--    local subdesc = GetMapName()
--
--    loc = {}
--    loc.x = Scripter.FormatCordinate(x)
--    loc.y = Scripter.FormatCordinate(y)
--    loc.area = subdesc
--    loc.areaId = subzone
--    loc.zone = zone
--
--    return loc
end


function Scripter.GetPlayerSkillName(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_skill) do
        if si_strifind(k, name) then return k end
    end

    return nil
end

function Scripter.GetPlayerSkillData(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_skill) do
        if string.match(k, name) ~= nil then
            return v
        end
    end

    return nil
end

function Scripter.GetPlayerQuestName(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_quest) do
        if si_strifind(k, name) then return k end
    end

    return nil
end

function Scripter.GetPlayerQuestData(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_quest) do
        if string.match(k, name) ~= nil then
            return v
        end
    end

    return nil
end

function Scripter.GetPlayerCraftName(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_trait) do
        if si_strifind(k, name) then return k end
    end

    return nil
end

function Scripter.GetPlayerCraftData(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_trait) do
        if string.match(k, name) ~= nil then
            return v
        end
    end

    return nil
end

function Scripter.GetPlayerAttributeName(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_attr) do
        if si_strifind(k, name) then return k end
    end

    return nil
end
function Scripter.GetPlayerAttributeData(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_attr) do
        if string.match(k, name) ~= nil then
            v[S_NAME] = k
            return v
        end
    end

    return nil
end

function Scripter.GetPlayerItemName(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_item_worn) do
        if si_strifind(k, name) then return k end
    end

    return nil
end

function Scripter.GetPlayerItemData(name)
    if (name == nil or name == "") then return nil end

    for k,v in pairs(Scripter.savedVariables.chardata_item_worn) do
        if string.match(k, name) ~= nil then
            return v
        end
    end

    return nil
end

function Scripter.NewVendorEvent(Event, Unit)
    if not DoesUnitExist("interact") then return end
    Scripter.PrintDebug("NewVendorEvent")
    Scripter.PreEventCheck()

    local name = GetUnitName("interact")
    local zone, subzone = si_char_area()--Scripter.GetZoneAndSubzone()
    local subdesc = GetMapName()
    local reaction = GetUnitReaction("interact") 

    if name == nil then return end
    if subzone == nil then return end
    if reaction ~= UNIT_REACTION_INTERACT and reaction ~= UNIT_REACTION_NPC_ALLY then return end

    Scripter.savedVariables.userdata_vendor[name] = subdesc
    local x,y = GetMapPlayerPosition('player')
    local loc = {}
    loc.x = x
    loc.y = y
    Scripter.savedVariables.userdata_vendor_loc[name] = loc 
end

function Scripter.GetQuestInfo()
    local quests = {}
    for questIndex=1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(questIndex) == true then
            quests[questIndex] = {}
            local qi = quests[questIndex]
            qi.questIndex = questIndex
            qi.name, qi.bgText, qi.activeStepText, qi.activeStepType, qi.activeStepTrackerOvrdText, qi.isCompleted, qi.isTracked, qi.questLevel, qi.isPushed, qi.questType = GetJournalQuestInfo(questIndex)
            qi.zoneName, qi.objectiveName, qi.zoneIndex, qi.poiIndex = GetJournalQuestLocationInfo(questIndex)
            qi.conditions = {}
            for stepIndex=1, GetJournalQuestNumSteps(questIndex) do
                local stepText,_,_,trackerOvrdText,numConditions = GetJournalQuestStepInfo()
                if stepText == qi.activeStepText then
                    if trackerOvrdText ~= nil then 
                        local ci = {}
                        ci.conditionText = trackerOvrdText
                        table.insert(qi.conditions, ci)
                    else
                        for conditionIndex=1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                            local ci = {}
                            ci.conditionText, ci.current, ci.max, ci.isFailCondition, ci.isComplete, ci.isCreditShared = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)
                            table.insert(qi.conditions, ci)
                        end
                    end
                end
            end
        end    
    end
    return quests 
end

function Scripter.NewZoneEvent()
    Scripter.PrintDebug("NewZoneEvent")
    Scripter.PreEventCheck()

    -- generate table of zone <-> subzone association
    local zone, subzone = si_char_area()--Scripter.GetZoneAndSubzone()
    local subdesc = GetMapName()
    Scripter.savedVariables.userdata_zone[subdesc] = zone

    local plrX, plrY = GetMapPlayerPosition('player')
    local loc = {}
    loc.x = plrX
    loc.y = plrY
    Scripter.savedVariables.userdata_zone_loc[subdesc] = loc
end

function Scripter.SetSkillPercentage(name, value)
    local charName = GetUnitName('player')
    local data = Scripter.savedVariables.userdata_skill_percent[charName]
    if data == nil then data = {} end

    data[name] = value
    Scripter.savedVariables.userdata_skill_percent[charName] = data
end

function Scripter.GetSkillPercentage(name, value)
    local charName = GetUnitName('player')
    local data = Scripter.savedVariables.userdata_skill_percent[charName]
    if data == nil then return 0 end

    local value = data[name]
    if value == nil then return 0 end

    return value
end

function Scripter.SetAbilityRate(name, value)
    local charName = GetUnitName('player')
    local data = Scripter.savedVariables.userdata_ability_rate[charName]
    if data == nil then data = {} end

    data[name] = value
    Scripter.savedVariables.userdata_ability_rate[charName] = data
end

function Scripter.GetAbilityRate(name)
    local charName = GetUnitName('player')
    local data = Scripter.savedVariables.userdata_ability_rate[charName]
    if data == nil then return 0 end

    local value = data[name]
    if value == nil then return 0 end
    return value
end

function Scripter.GetAbilityRates()
    local charName = GetUnitName('player')
    local data = Scripter.savedVariables.userdata_ability_rate[charName]

    if data == nil then data = {} end
    return data
end
function Scripter.ClearAbilityRates()
    local charName = GetUnitName('player')
    Scripter.savedVariables.userdata_ability_rate[charName] = nil
end

function Scripter.AddAbilityRate(abilityName, hitValue)
    if Scripter.savedVariables == nil then return end
    if hitValue == 0 then return end
    if abilityName == "" then return end

    if stat_stamp[abilityName] == nil then
        -- initial action per login session
        stat_stamp[abilityName] = GetTimeStamp() - 60
        stat_span[abilityName] = hitValue
    else
        -- incrimental action per login session
        local tspan = (GetTimeStamp() - stat_stamp[abilityName])
        stat_span[abilityName] = stat_span[abilityName] + hitValue
        local avg = stat_span[abilityName] / (tspan / 60);
	local orig_value = Scripter.GetAbilityRate(abilityName, value)
        local value = (avg + orig_value) / 2
	Scripter.SetAbilityRate(abilityName, value)
    end
end

-- track money, gains and losses
function Scripter.NewMoneyEvent(eventId, newMoney, oldMoney, updateReason)
    Scripter.PrintDebug("NewMoneyEvent eventId:" .. eventId .. " newMoney:" .. newMoney .. " oldMoney:" .. oldMoney .. " updateReason:" .. updateReason)
    Scripter.PreEventCheck()

    Scripter.savedVariables.usertemp_money = newMoney - oldMoney
    Scripter.savedVariables.userdata_money = newMoney
end

function Scripter.AddItemEvent(eventId, bagId, slotId, itemSoundCategory, updateReason)
    Scripter.AddAbilityRate("Loot", 1)

    local link = GetItemLink(bagId, slotId)
    local name,col,typID,id,qual,levelreq,enchant,ench1,ench2,un1,un2,un3,un4,un5,un6,un7,un8,un9,style,un10,bound,charge,un11=ZO_LinkHandler_ParseLink(link)

    name = Scripter.FormatItemName(name)
    if levelreq ~= nil then
        Scripter.NotifyCharacterAction(OPT_NOTIFY_INVENTORY, "Obtained item '" .. Scripter.HighlightText(name) .. "' Lv " .. levelreq .. ".")
    end
end

function Scripter.GetItemCondition(bagId, slotId)
    local cond = -1
    local hasDurability = DoesItemHaveDurability(bagId, slotId)
    local hasCharges = IsItemChargeable(bagId, slotId)
    if hasDurability then
        cond = GetItemCondition(bagId, slotId)
    elseif hasCharges then
        local charges, maxCharges = GetChargeInfoForItem(bagId, slotId)
        cond = math.floor(charges  * 100 / maxCharges)
    end
    return cond
end

function Scripter.IsJunkItem(bagId, slotId)
    if bagId ~= BAG_BACKPACK then
        return
    end

    local itemName = GetItemName(bagId, slotId)
    if itemName == nil then
        return false
    end

    itemName = Scripter.FormatItemName(itemName)
    if Scripter.savedVariables.userdata_junk[itemName] == nil then
        return false
    end

    return true
end

function Scripter.UnsetJunkItem(bagId, slotId)
    if bagId ~= BAG_BACKPACK then
        return
    end

    if scripterCraftEvent == true then
        return
    end

    local itemName = GetItemName(bagId, slotId)
    if itemName == nil then
        return
    end

    itemName = Scripter.FormatItemName(itemName)
    Scripter.PrintDebug("UnsetJunkItem bagId:" .. bagId .. " slotId:" .. slotId .. " itemName:" .. itemName)
    Scripter.savedVariables.userdata_junk[itemName] = nil
end

function Scripter.SetJunkItem(bagId, slotId)
    if bagId ~= BAG_BACKPACK then
        return
    end

    local itemName = GetItemName(bagId, slotId)
    if itemName == nil then
        return
    end

    itemName = Scripter.FormatItemName(itemName)
    Scripter.PrintDebug("SetJunkItem bagId:" .. bagId .. " slotId:" .. slotId .. " itemName:" .. itemName)
    if (Scripter.savedVariables.userdata_junk[itemName] ~= nil and Scripter.savedVariables.userdata_junk[itemName] == slotId) then
        -- redundant
        return
    end

    Scripter.savedVariables.userdata_junk[itemName] = slotId
    Scripter.NotifyCharacterAction(OPT_NOTIFY_INVENTORY, itemName .. " has been marked as junk.")
end

function Scripter.PerformJunkItem(bagId, slotId)
    if Settings:GetValue(OPT_JUNKMODE) == false then return end
    if bagId ~= BAG_BACKPACK then return end

    local icon, stackCount, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bagId, slotId)
    -- @see /sconfig junk
    if sellPrice > 0 then
        SetItemIsJunk(bagId, slotId, true)
        Scripter.PrintDebug("NewItemEvent: junked item " .. bagId .. ":" .. slotId)
    else -- not worth selling
        DestroyItem(bagId, slotId, true);
        Scripter.PrintDebug("NewItemEvent: destroy junk item " .. bagId .. ":" .. slotId)
    end
end

function Scripter.GetPlayerItemInfo(bagId, slotId)
    local item = {}
    local i_type = GetItemType(bagId, slotId)
    local i_icon, i_stack, i_price, i_use, i_lock, i_equip, i_style, i_qual = GetItemInfo(bagId, slotId)
    local i_name,col,typID,id,qual,i_level,enchant,ench1,ench2,un1,un2,un3,un4,un5,un6,un7,un8,un9,style,un10,bound,charge,un11=ZO_LinkHandler_ParseLink(GetItemLink(bagId, slotId))
    if (i_name == nil or i_name == "" or i_name == "unknown") then
        return nil
    end

    item['name'] = Scripter.FormatItemName(i_name)
    local eq_str = Scripter.GetItemEquipLabel(i_equip) 
    if eq_str ~= "unknown" then
        item['equip'] = eq_str
    end
    local type_str = Scripter.GetItemCategoryLabel(i_type)
    if type_str ~= "unknown" then
        item['type'] = type_str
    end
    local qual_str = Scripter.GetItemQualityLabel(i_qual)
    if (qual_str ~= "Normal" and qual_str ~= "unknown") then
        item['quality'] = qual_str
    end
    if i_price > 0 then
        item['price'] = i_price
    end
    if i_stack > 1 then
        item['x'] = i_stack 
    end
    if i_level ~= nil then
        item['level'] = i_level
    end
    if i_type == ITEMTYPE_ARMOR then
        local i_armor = GetItemArmorType(bagId, slotId)
        local armor_str = Scripter.GetItemArmorLabel(i_armor)
	if armor_str ~= "unknown" then
            item['armor'] = armor_str
        end
--         local i_trait = GetItemTrait(bagId, slotId)
--         local trait_str = Scripter.GetItemTraitLabel(i_trait, i_armor)
--         if trait_str ~= "unknown" then
--             item['trait'] = trait_str
--         end	
    elseif i_type == ITEMTYPE_WEAPON then
        --local i_wep = GetItemWeaponType(GetItemLink(bagId, slotId))
        local i_wep = GetItemWeaponType(bagId, slotId)
        item['weapon'] = Scripter.GetItemWeaponLabel(i_wep)
    end

    local i_link = GetItemLink(bagId, slotId)
    if IsItemLinkBound(i_link) == true then
        item['kind'] = "Bound" 
    elseif IsItemLinkConsumable(i_link) == true then
        item['kind'] = "Consumable"
    elseif IsItemLinkUnique(i_link) == true then
        item['kind'] = "Unique"
    elseif IsItemLinkVendorTrash(i_link) == true then
        item['kind'] = "Trash"
    elseif IsItemLinkCrafted(i_link) == true then
        item['kind'] = "Crafted"
    end

    return item
end

function Scripter.GetInventoryItemText(item, cond, showName)
    local text = ""

    if item == nil then
        return
    end

    if item['equip'] ~= nil then
        text = "(" .. item['equip'] .. ") " 
    end
    if (showName == nil or showName == true) then
        text = text .. Scripter.HighlightText(item['name'])
    end
    -- show non-numeric initially
    local attr_text = ""
    for k,v in pairs(item) do
        if (k ~= "name" and k ~= "equip") then
            if string.match(v, "[%d]+") == nil then
                attr_text = attr_text .. " " .. v
            end
        end
    end
    if attr_text ~= "" then
        text = text .. " (" .. attr_text .. " )"
    end
    -- show numeric with label
    for k,v in pairs(item) do
        if (k ~= "name" and k ~= "equip") then
            local label = string.sub(k, 0, 3)
            if string.match(v, "[%d]+") ~= nil then
                text = text .. " [" .. label .. " " .. v .. "]" 
            end
        end
    end
    -- show item condition last
    if (cond ~= nil and cond > 0 and cond < 99) then
        text = text .. " [con " .. cond .. "%]"
    end

    return text
end

function Scripter.NewItemEvent(eventId, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
    Scripter.PreEventCheck()
    Scripter.PrintDebug("NewItemEvent eventId:" .. eventId .. " bagId:" .. bagId .. " updateReason:" .. updateReason)

    if bagId == BAG_WORN then
        local item = Scripter.GetPlayerItemInfo(bagId, slotId)
        if item ~= nil then
            Scripter.StoreInventoryItem(item)
        end
    end

    if updateReason ~= INVENTORY_UPDATE_REASON_DURABILITY_CHANGE then
        if IsItemJunk(bagId, slotId) == false then
            if Scripter.IsJunkItem(bagId, slotId) then
                if isNewItem == true then
                    Scripter.PerformJunkItem(bagId, slotId)
                else
                    Scripter.UnsetJunkItem(bagId, slotId);
		    end
            end
        else
            Scripter.SetJunkItem(bagId, slotId);
        end
    end

    if isNewItem == true then
        Scripter.AddItemEvent(eventId, bagId, slotId, itemSoundCategory, updateReason)
    else
        local cond = Scripter.GetItemCondition(bagId, slotId)
	if Scripter.savedVariables.slot[slotId] == nil then 
	    Scripter.savedVariables.slot[slotId] = 0
        end
        if (cond > 0 and cond < 99) then
	    if Scripter.savedVariables.slot[slotId] ~= cond then
                local link = GetItemLink(bagId, slotId)
                local name,col,typID,id,qual,levelreq,enchant,ench1,ench2,un1,un2,un3,un4,un5,un6,un7,un8,un9,style,un10,bound,charge,un11=ZO_LinkHandler_ParseLink(link)
		name = Scripter.FormatItemName(name)
                Scripter.NotifyCharacterAction(OPT_NOTIFY_INVENTORY, "Item '" .. Scripter.HighlightText(name) .. "' durability is " .. cond .. "%.")
            end
        end
        Scripter.savedVariables.slot[slotId] = cond
    end
end

function Scripter.NewDeathEvent(event)
    Scripter.PreEventCheck()

    if (event == EVENT_PLAYER_DEAD) then -- player died
        Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, "You have died!")
        Scripter.AddAbilityRate("Death", 1)
    end
end

function Scripter.GetEffectLabel(name)
    -- todo add space before Cap letters via string:sub
    return name
end

function Scripter.AddEffectEvent(effectName, buffType, stackCount, abilityType)
    if effectName == "" then
        return
    end
    local btype = nil
    if buffType == ABILITY_TYPE_STUN then
        btype = "stun"
    elseif buffType == ABILITY_TYPE_STAGGER then
        btype = "stagger"
    elseif buffType == ABILITY_TYPE_BLOCK then
        btype = "block"
    elseif buffType == ABILITY_TYPE_OFFBALANCE then
        btype = "off-balance"
    elseif buffType == ABILITY_TYPE_BONUS then
        btype = "bonus"
    elseif (string.match(effectName, "^.-Potion" )) then
        btype = "potion"
    end

    local text = "A"
    if (abilityType == 0 or abilityType == 1 or abilityType == 10) then
        text = "A positive"
    end
    if btype ~= nil then
        text = text .. " " .. btype
    end
	effectName = Scripter.GetEffectLabel(effectName)
    text = text .. " '" .. Scripter.HighlightText(effectName) .. "' effect has occurred."
    if (stackCount ~= nil and stackCount ~= 0) then
        text = text .. " x" .. stackCount
    end
    Scripter.NotifyCharacterAction(OPT_NOTIFY_EFFECT, text)
end

function Scripter.RemoveEffectEvent(effectName, buffType, abilityType)
    local kind = "negative"
    if (abilityType == 0 or abilityType == 1 or abilityType == 10) then
        kind = "positive";
    end
    Scripter.NotifyCharacterAction(OPT_NOTIFY_EFFECT, "The " .. kind .. " '" .. Scripter.HighlightText(effectName) .. "' effect fades away.")
end

function Scripter.NewEffectEvent(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType)
    Scripter.PrintDebug("NewEffectEvent eventCode:" .. eventCode .. " changeType:" .. changeType .. " effectSlot:" .. effectSlot .. " effectName:" .. effectName .. " unitTag:" .. unitTag .. " buffType:" .. buffType .. " effectType:" .. effectType .. " abilityType:" .. abilityType .. " statusEffectType:" .. statusEffectType)
    if (unitTag == "player" and abilityType == 2) then
      return
    end
    if beginTime == 0 then
        return
    end
    if ( string.match( effectName , 'TargetingHit' ) or string.match( effectName , 'Hack' ) or string.match( effectName , 'dummy' ) or string.match( effectName , "Mount Up" ) or string.match( effectName , "Boon: " ) or string.match( effectName , "Force Siphon" ) or string.match( effectName , "Regeneration" )) then 
        return
    end
    if Scripter.savedVariables.buff[effectName] == nil then
        Scripter.savedVariables.buff[effectName] = 0
    end
    if Scripter.savedVariables.buff[effectName] == endTime then
        -- quash duplicates
        return
    end

    effectName = string.gsub(effectName, "%s+", "")
    if changeType == 2 then
        Scripter.RemoveEffectEvent(effectName, buffType, abilityType)
        Scripter.savedVariables.buff[effectName] = nil
    elseif (changeType == 1 or changeType == 3) then
        Scripter.AddEffectEvent(effectName, buffType, stackCount, abilityType)
        Scripter.savedVariables.buff[effectName] = endTime
    end
end

function Scripter.NewGroupInviteEvent()
    if Settings:GetValue(OPT_AUTOACCEPT) == false then return end
    local inviterDisplayName, secsSinceRequest = GetGroupInviteInfo()
    
    for i = 1, GetNumFriends(), 1 do
    	local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(i)
    	local hasCharacter, characterName, zoneName, classType, alliance, level, veteranRank = GetFriendCharacterInfo(i)
    	local regularCharacterName = characterName:match("([^^]+)^([^^]+)")
    	local uniqueCharacterName = GetUniqueNameForCharacter(characterName)
    	
    	if(inviterDisplayName == regularCharacterName) then
    		AcceptGroupInvite()
    		Scripter.NotifyCharacterAction(OPT_NOTIFY_MISC, "Accepted group invite from '" .. Scripter.HighlightText(uniqueCharacterName) .. "'.")
    		break
    	end
    end
end

function Scripter.StorePlayerStatInfo()
    local level = GetUnitLevel('player')
    local class = Scripter.GetClassNameByType(GetUnitClassId('player'))
   
    --local vet_level = GetUnitVeteranLevel('player')
    --if (vet_level ~= nil and vet_level ~= 0) then
    --    level = level .. " V" .. vet_level
    --end

    Scripter.savedVariables.userdata_attr = {}
    Scripter.savedVariables.userdata_attr[S_LEVEL] = level;
    Scripter.savedVariables.userdata_attr[S_CLASS] = class;

    for k,v in pairs(charStatType) do
        local val = GetPlayerStat(v, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
        if (val ~= nil and val ~= 0) then
            Scripter.savedVariables.userdata_attr[k] = val
	end
    end
end

function Scripter.GetPlayerStatusLabel(playerStatus)
    return GetString("SI_PLAYERSTATUS", playerStatus)
end

function Scripter.GetFriendText(id)
    local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(id)
    local hasCharacter, characterName, zoneName, classType, allianceType, level, veteranRank = GetFriendCharacterInfo(id)
    local alliance_str = Scripter.GetAllianceNameByType(allianceType)
    local class_str = Scripter.GetClassNameByType(classType)
    local level_str = level

    if (veteranRank ~= nil and veteranRank ~= 0) then
        level_str = level_str .. " V" .. veteranRank
    end

    characterName = Scripter.ResolveCharacterName(characterName)
    if playerStatus == 1 then	
        Scripter.SetCharacterAttribute(characterName, S_LEVEL, level_str)
        Scripter.SetCharacterAttribute(characterName, S_CLASS, class_str)
        Scripter.SetCharacterAttribute(characterName, S_ALLIANCE, alliance_str)
    end
    
    local timeSinceLogoff = nil
    if (playerStatus == PLAYER_STATUS_OFFLINE and secsSinceLogoff > 0) then
        timeSinceLogoff = Scripter.FormatSecondsToDDHHMMSS(secsSinceLogoff)
    end
    
    text = "Lv " .. level_str .. " " .. alliance_str .. " " .. class_str .. " " .. Scripter.HighlightText(characterName) .. displayName .. " in " .. zoneName
    if secsSinceLogoff > 0 then
        text = text .. " (Logoff: " .. timeSinceLogoff .. ")"
    else
        text = text .. " (" .. Scripter.GetPlayerStatusLabel(playerStatus) .. ")"
    end

    return text
end

function Scripter.RefreshFriendPlayerStatInfo()
    for i = 1, GetNumFriends(), 1 do
        local text = Scripter.GetFriendText(i)
    end
end

function Scripter.RefreshGuildPlayerStatInfo()
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        for memberId = 1, GetNumGuildMembers(guildId) do
            local text = Scripter.GetGuildMemberText(guildId, memberId)
        end
    end
end

function Scripter.RefreshCharacterTraitInfo()
    for k,v in pairs(itemCraftType) do
        Scripter.GetCharacterCraftInfo(v)
    end
end

function Scripter.NewStatEvent(eventId, unitTag)
    if unitTag ~= "player" then return end
    Scripter.PrintDebug("NewStatEvent eventId:" .. eventId .. " unitTag:" .. unitTag)
--    Scripter.PreEventCheck()

    Scripter.StorePlayerStatInfo()
end

function Scripter.NewCombatStateEvent(eventCode, inCombat)
--    Scripter.PreEventCheck()
    if inCombat == true then
        Scripter.PrintDebug("NewCombatStateEvent eventCode:" .. eventCode .. " inCombat:True")
    else
        Scripter.PrintDebug("NewCombatStateEvent eventCode:" .. eventCode .. " inCombat:False")
    end

end

function Scripter.MSync_ParseMailData(arguments)
    if arguments == nil then return nil end
    local data = {}
    for w in string.gmatch(arguments,"([^:]+)") do
        local toks = si_strsplit(" ", w)
        local val = toks[1];
        local name = Scripter.extractstr(toks,2)
        if (name ~= nil and name ~= "" and val ~= nil and val ~= "") then
            data[name] = val
        end
    end

    return data
end

function Scripter.MSync_ParseMailEvent(name, text)
    if (name == nil or text == nil) then return end
    local data

    for data in string.gmatch(text, "(\.\.[^\.]+)\.\.") do
       if string.match(data, "ATT:") ~= nil then
            attr_data = Scripter.MSync_ParseMailData(data)
            for k,v in pairs(attr_data) do
                Scripter.SetCharacterAttribute(name, k, v)
            end
        end
       if string.match(data, "QUE:") ~= nil then
            Scripter.savedVariables.chardata_quest[name] = Scripter.MSync_ParseMailData(data)
       end
       if string.match(data, "CRA:") ~= nil then
            Scripter.savedVariables.chardata_trait[name] = Scripter.MSync_ParseMailData(data)
       end
       if string.match(data, "SKI:") ~= nil then
            Scripter.savedVariables.chardata_skill[name] = Scripter.MSync_ParseMailData(data)
        end
        if string.match(data, "ITE:") ~= nil then
            Scripter.savedVariables.chardata_item_worn[name] = Scripter.MSync_ParseMailData(data)
        end
    end

    Scripter.savedVariables.chardata_sync[name] = GetTimeStamp()
end

-- ToggleShowIngameGui()
function Scripter.SendGameMail(accountName, subject, text)
--    RequestOpenMailbox()
    SendMail(accountName, subject, text)
--    ClearQueuedMail()
--    CloseMailbox()
end

function Scripter.ReadGameMail(mailId)
    local body

--    RequestOpenMailbox()
--    RequestReadMail(mailId)
    body = ReadMail(mailId)
--    CloseMailbox()

    return body
end

function Scripter.DeleteGameMail(mailId)
--    RequestOpenMailbox()
    local unread, returned, fromSystem, fromCustomerService = GetMailFlags(mailId)
    if (unread == true or returned == true or fromSystem == true or fromCustomerService == true) then return false end

    local body = ReadMail(mailId)
    if body == "" then return false end

--    Scripter.PrintDebug("DeleteGameMail " .. mailId)

    DeleteMail(mailId, false);
--		MAIL_INBOX:RefreshData()
--		PlaySound(SOUNDS.MAIL_ITEM_DELETED)
    
--    ClearQueuedMail()
--    CloseMailbox()
end

function Scripter.NewMailEvent(eventCode, mailId)
    local senderAccount, senderName, Subject, Icon, unread, fromSystem, fromCustomerService, isReturned, numAttachments, attachedMoney, codAmount, daysLeft, secs = GetMailItemInfo( mailId )
    if fromSystem == true then return end
    if fromCustomerService == true then return end
    if isReturned == true then return end
    if (numAttachments ~= nil and numAttachments > 0) then return end

    senderName = Scripter.ResolveCharacterName(senderName)
    Scripter.PrintDebug("NewMailEvent senderAccount:" .. senderAccount .. " senderName:" .. senderName .. " secs:" .. secs)

    local stamp = GetTimeStamp() - secs;
    local last_stamp = Scripter.savedVariables.chardata_sync_read[senderName]
    if last_stamp == nil then last_stamp = 0 end
    last_stamp = last_stamp - 5

    if Subject == "Scripter Automatic Synchronization" then
        if (stamp > last_stamp and Scripter.savedVariables.userdata_sync[senderAccount] ~= nil) then
            local body = ReadMail(mailId)
	    if (body == nil or body == "") then return end 

            Scripter.MSync_ParseMailEvent(senderName, body)

	    Scripter.NotifyCharacterAction(OPT_NOTIFY_MISC, "Received synchronization from '" .. Scripter.HighlightText(senderName) .. " (" .. senderAccount .. ")'.")
	    Scripter.savedVariables.chardata_sync_read[senderName] = GetTimeStamp()
        end

        if Settings:GetValue(OPT_SYNC_DELETE) == true then
            Scripter.DeleteGameMail(mailId)
--            ReadMail(mailId) -- mark as read
 --           DeleteMail(mailId, false)
        end
    end
end

-- cycles through all character's mail and checks for sync notifications
function Scripter.RefreshMailEvent()
    if Scripter.savedVariables.usertime_offset == 0 then return end
    if Scripter.GetTimerOffset() < Scripter.savedVariables.usertime_mail then return end

    local numMail = GetNumMailItems()
    local lastId = nil
    for m = 1, numMail, 1 do
        lastId = GetNextMailId( lastId )
        Scripter.NewMailEvent(0, lastId)
    end

    Scripter.savedVariables.usertime_mail = Scripter.GetTimerOffset() + 60000
end

function Scripter.NewQuestAddEvent(eventCode, questIndex, questName, objectiveName)
    if questName == nil then return end
    Scripter.PrintDebug("NewQuestAddEvent questIndex:" .. questIndex .. " questName:" .. questName)
    Scripter.PreEventCheck()

    local zoneName = GetJournalQuestLocationInfo(questIndex)
    if (zoneName == nil or zoneName == "") then zoneName = "Global" end
    Scripter.savedVariables.userdata_quest[questName] = zoneName
end

function Scripter.NewQuestCompleteEvent(eventCode, questName, level, prevXp, curXp, rank, prevPoints, curPoints)
    if questName == nil then return end
    Scripter.PrintDebug("NewQuestCompleteEvent questName:" .. questName .. " level:" .. level)
    Scripter.PreEventCheck()

    Scripter.AddAbilityRate("Quest", 1)
    Scripter.NotifyCharacterAction(OPT_NOTIFY_MISC, "You completed quest '" .. Scripter.HighlightText(questName) .. " [Lv " .. level .. "]'.")

    Scripter.savedVariables.userdata_quest[questName] = nil
end

function Scripter.NewMovementEvent(eventCode)
    Scripter.PrintDebug("NewMovementEvent eventCode:" .. eventCode)
    Scripter.PreEventCheck()
end

function Scripter.NewPlayerStatusEvent(eventCode, _, playerStatus)
    Scripter.PrintDebug("NewPlayerStatusEvent playerStatus:" .. playerStatus)
    Scripter.NotifyCharacterAction(OPT_NOTIFY_MISC, "Character mode transitioned to '" .. Scripter.HighlightText(Scripter.GetPlayerStatusLabel(playerStatus)) .. "'.")
end

function Scripter.NewTraitEvent(eventCode, itemName, itemTrait)
    if (itemName == nil or itemTrait == nil) then return end
    Scripter.PrintDebug("NewTraitEvent eventCode:" .. eventCode .. " itemName:" .. itemName .. " itemTrait:" .. itemTrait)
    Scripter.PreEventCheck()

    Scripter.NotifyCharacterAction(OPT_NOTIFY_MISC, "You learned the '" .. Scripter.HighlightText(itemTrait .. " " .. itemName) .. "' crafting trait.")
    Scripter.RefreshCharacterTraitInfo()
end

function Scripter.RegisterEvents()
    -- Book Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_LORE_BOOK_LEARNED, Scripter.NewLoreBookEvent)

    -- Chat Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_CHAT_MESSAGE_CHANNEL, Scripter.NewChannelEvent)

    -- Keybind Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_KEYBINDINGS_LOADED, Scripter.OnKeybindingsLoaded)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_KEYBINDING_SET, Scripter.OnKeybindingSetOrCleared)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_KEYBINDING_CLEARED, Scripter.OnKeybindingSetOrCleared)

    -- Location Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_LINKED_WORLD_POSITION_CHANGED, Scripter.NewZoneEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_ZONE_CHANGED, Scripter.NewZoneEvent)

    -- Money Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_MONEY_UPDATE, Scripter.NewMoneyEvent)

    -- Group Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_GROUP_INVITE_RECEIVED, Scripter.NewGroupInviteEvent)

    -- Item Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, Scripter.NewItemEvent)

    -- Craft Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_CRAFT_STARTED, function () scripterCraftEvent = true end);
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_CRAFT_COMPLETED, function () scripterCraftEvent = false end);

    -- Character Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_STATS_UPDATED, Scripter.NewStatEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_PLAYER_COMBAT_STATE, Scripter.NewCombatStateEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_EFFECT_CHANGED , Scripter.NewEffectEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_SKILL_XP_UPDATE , Scripter.NewSkillEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_PLAYER_DEAD , Scripter.NewDeathEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_COMBAT_EVENT , Scripter.NewCombatEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_EXPERIENCE_UPDATE , Scripter.NewExpEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_VETERAN_POINTS_UPDATE , Scripter.NewExpEvent)

    -- Trait Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_TRAIT_LEARNED, Scripter.NewTraitEvent)

    -- UI Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_NEW_MOVEMENT_IN_UI_MODE, Scripter.NewMovementEvent)
--    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_GAME_CAMERA_UI_MODE_CHANGED, Scripter.NewMovementEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_PLAYER_STATUS_CHANGED, Scripter.NewPlayerStatusEvent)

    -- Vendor Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_OPEN_STORE, Scripter.NewVendorEvent)

    -- Quest Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_QUEST_COMPLETE, Scripter.NewQuestCompleteEvent)
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_QUEST_ADDED, Scripter.NewQuestAddEvent)

    -- Mail Events
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_MAIL_READABLE, Scripter.NewMailEvent)
end

function Scripter.KeybindSlashCommandHelp()
    print("- /keybind <name>  |cff8f41  Apply a keybind set.")
    print("- /keybind /set <name>  |cff8f41  Create new keybind set.")
    print("- /keybind /list  |cff8f41  List available keybind sets.")
    print("- /keybind /delete <name>  |cff8f41  Delete a keybind set.")
end

function Scripter.PartySlashCommandHelp()
    print("- /sgroup  |cff8f41  List members of active party group.")
    print("- /sgroup /leave  |cff8f41  Leave the active party group.")
    print("- /sgroup /invite <name>  |cff8f41  Invite someone into the group.")
end
function Scripter.GuildSlashCommandHelp()
    print("- /sguild  |cff8f41  List all of character's active guilds.")
    print("- /sguild <guild>  |cff8f41  List all characters in guild.")
end
function Scripter.ResearchSlashCommandHelp()
    print("- /research  |cff8f41  List all researchable items in the backpack.")
--    print("- /research <item>  |cff8f41  Research a item in the backpack.")
end
function Scripter.AFKSlashCommandHelp()
    print("- /away  |cff8f41  Toggle character's \"Away From Keyboard\" mode.")
    print("- /away /action <cmd>  |cff8f41  Set the action to perform while in AFK mode.")
    print("- /away /quiet  |cff8f41  Toggle character's \"Do Not Disturb\" mode.")
    print("  note: The \"Do Not Disturb\" mode suppresses all incoming chat message.")
end

function Scripter.FormatDate(time)
	if time == nil then
	    return ""
	end
    local midnightSeconds = GetSecondsSinceMidnight()
    local utcSeconds = GetTimeStamp() % 86400
    local offset = midnightSeconds - utcSeconds
    if offset < -43200 then
    	offset = offset + 86400
    end

    local dateString = GetDateStringFromTimestamp(time)
    local timeString = ZO_FormatTime((time + offset) % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
	return string.format("%s %s", dateString, timeString)
end

function Scripter.GetAllianceNameByType(atype)
    local allianceName = "Unknown"
    if atype == 1 then
    	allianceName = "Aldmeri"
    elseif atype == 2 then
    	allianceName = "Ebonhart"
    elseif atype == 3 then
    	allianceName = "Daggerfall"
    end
    return allianceName
end
function Scripter.GetClassNameByType(ctype)
    local className = "Unknown"
    if ctype == 1 then
    	className = "Dragonknight"
    elseif ctype == 2 then
    	className = "Sorcerer"
    elseif ctype == 3 then
    	className = "Nightblade"
    elseif ctype == 6 then
    	className = "Templar"
    end
    return className
end

function Scripter.FormatSecondsToDDHHMMSS(secsSinceLogoff)
    local days = math.floor(secsSinceLogoff / 86400)
    local hours = math.floor((secsSinceLogoff / 3600) - (days * 24))
    local minutes = math.floor((secsSinceLogoff / 60) - (days * 1440) - (hours * 60))
    local seconds = secsSinceLogoff % 60
    return string.format("%4d Days: %2d Hours: %2d Minutes: %2d Seconds", days, hours, minutes, seconds)
end

function Scripter.AFKToggleCommand(argtext)
    if Scripter.isPlayerAfk() == false then
        Scripter.setPlayerAfk(PLAYER_STATUS_AWAY)
	print("Scripter: Character AFK mode enabled.")
	Scripter.AFKSleep()
    else
        Scripter.setPlayerAfk(PLAYER_STATUS_ONLINE)
	print("Scripter: Character AFK mode disabled.")
	Scripter.AFKWake()
    end
end

function Scripter.AFKActionCommand(argtext)
    if argtext == nil then argtext = "" end
    argtext = string.gsub(argtext, "(/)", "")

    if (argtext ~= "" and argtext ~= "<none>") then 
        if (SLASH_COMMANDS["/"..argtext] == nil and SLASH_COMMANDS["/"..argtext.."2"] == nil) then
            print("Scripter: Unknown command '/" .. Scripter.HighlightText(argtext) .. "' specified.")
            return
        end
        print("Scripter: Set character AFK action to '/" .. Scripter.HighlightText(argtext) .. "'.")
    else
        print("Scripter: Unset character AFK action.")
    end

    Settings:SetValue(OPT_AFK_ACTION, argtext)
end

function Scripter.OnlineFriendCommand()
    print("Friends (online):")
    for i = 1, GetNumFriends(), 1 do
        local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(i)
	local text = Scripter.GetFriendText(i)
        if (playerStatus == 1) then 
            print(text)
        end
    end
end

function Scripter.FriendSlashCommandHelp()
    print("- /friend  |cff8f41  Display character's friend information.")
    print("- /friend <name>  |cff8f41  Display specific friend information.")
    print("- /friend /online  |cff8f41  Display online friends.")
end

function Scripter.AliasSlashCommandHelp()
    print("- /alias  |cff8f41  List all aliases.")
    print("- /alias <alias> <cmd> <args>  |cff8f41  Add an alias.")
    print("- /alias /delete <alias>  |cff8f41  Delete an alias.")
    print("- /alias /clear  |cff8f41  Clear all saved aliases.")
    print("Example aliases:")
    print("- /alias lo logout  |cff8f41  Convience command for character logout.")
    print("- /alias help scripter  |cff8f41  Use scripter help via /help command.")
    print("- /alias note log note:  |cff8f41  Add a note to character log with /note <text>.")
    print("- /alias skill stat /skill  |cff8f41  List skill attribute with /skill.") 
    print("- /alias abil stat /action  |cff8f41  Show character's action rates with /abil.")
end

Scripter.keybindCommands = {
    ["/set"] = Scripter.SaveBindings,
    ["/list"] = Scripter.ListBindings,
    ["/delete"] = Scripter.DeleteBindings,
}

Scripter.friendCommands = {
    ["/online"] = Scripter.OnlineFriendCommand,
}

function Scripter.LogSlashCommandHelp()
    print("- /log  |cff8f41  Show recent character log messages.")
    print("- /log <msg>  |cff8f41  Add a message to the log.")
    print("- /log /chat  |cff8f41  Show recent chat history.")
    print("- /log /clear  |cff8f41  Clear log contents.")
    print("- /log /filter <kwd>  |cff8f41  Show messages matching keyword.")
    print("- /log /full  |cff8f41  Show last 1000 log messages.")
    print("- /log /print <msg>  |cff8f41  Log and print a message.")
end

function Scripter.ScoreSlashCommandHelp()
    print("- /stat [<user>]  |cff8f41  Show summary of player's attributes.")
    print("- /stat /action  |cff8f41  Show recent character actions.")
    print("- /stat /all [<user>]  |cff8f41  Show all of a character's information.")
    print("- /stat /buff  |cff8f41  Show current character effects.")
    print("- /stat /clear  |cff8f41  Reset action statistics.")
    print("- /stat /craft [<user>]  |cff8f41  Display character crafting traits.")
    print("- /stat /skill [<user>]  |cff8f41  Display character skill attributes.")
    print("- /stat /userlist  |cff8f41  List all users with stored info.")
end

function Scripter.ConfigSlashCommandHelp()
     print("- /sconfig  |cff8f41  Open Scripter configuration dialog.")

--     print("- /sconfig  |cff8f41  List all configuration values.")
--     print("- /sconfig afk  |cff8f41  Enable \"away from keyboard\" mode.")
--     print("- /sconfig afk_action  |cff8f41  Set \"away from keyboard\" action.")
--     print("- /sconfig autoaccept  |cff8f41  Automatic invitation accept from friends.")
--     print("- /sconfig book  |cff8f41  Automatic book notifications.")
--     print("- /sconfig combat  |cff8f41  Automatic combat notifications.")
--     print("- /sconfig debug  |cff8f41  Verbose event information.")
--     print("- /sconfig effect  |cff8f41  Automatic effect notifications.")
--     print("- /sconfig inventory  |cff8f41  Automatic inventory notifications.")
--     print("- /sconfig junk  |cff8f41  Persistent junk item management.")
--     print("- /sconfig keybind  |cff8f41  Automatic character keybinding.")
--     print("- /sconfig log <lines>  |cff8f41  Number of log lines to list.")
--     print("- /sconfig money  |cff8f41  Automatic money notifications.")
--     print("- /sconfig quiet  |cff8f41  Manage automatic notification window.")
--     print("- /sconfig sync  |cff8f41  Enable or diable automatic synchronization.")
--     print("- /sconfig sync_mail  |cff8f41  Set whether to retain sync mails.")
end

function Scripter.TimeSlashCommandHelp()
    print("- /time  |cff8f41  Show game and real time.")
    print("- /time /game  |cff8f41  Show the current game time.")
    print("- /time /real  |cff8f41  Show the current real time.")
end

function Scripter.TimerSlashCommandHelp()
    print("- /timer  |cff8f41  List active timer events.")
    print("- /timer <time> <cmd> <args>  |cff8f41  Perform /<cmd> after <time> seconds.")
    print("- /timer /clear  |cff8f41  Clear all timer events.")
    print("- /timer /delete <id>  |cff8f41  Delete a timer by id.")
    print("- /timer /repeat <time> <cmd>  |cff8f41  Continually perform a command.")
end

function Scripter.SyncSlashCommandHelp()
    print("- /sync  |cff8f41  List all users synchronizing.")
    print("- /sync <user>  |cff8f41  Synchronize with <user>.")
    print("- /sync /clear  |cff8f41  Clear synchronization user list.")
    print("- /sync /delete <user>  |cff8f41  Stop synchronizing with <user>.")
    print("- /sync /list  |cff8f41  Display recent synchronization history.")
    print("- /sync /list <user>  |cff8f41  Display synchronization info for <user>.")
    print("- /sync /scan  |cff8f41  Scan mail for synchronization notifications.")
end

function Scripter.VendorSlashCommandHelp()
    print("- /vendor  |cff8f41  List all vendors in zone.")
    print("- /vendor <kwd>  |cff8f41  List all vendors matching <kwd>.")
    print("- /vendor /clear  |cff8f41  Clear all vendor information.")
    print("- /vendor /list  |cff8f41  List all known vendors.")
end

function Scripter.ZoneSlashCommandHelp()
    print("- /loc  |cff8f41  Show current location.")
    print("- /loc <kwd>  |cff8f41  List all locations matching <kwd>.")
    print("- /loc /area  |cff8f41  List points of interest in map zone.")
    print("- /loc /clear  |cff8f41  Clear all known locations.")
    print("- /loc /list  |cff8f41  List all known locations.")
end

function Scripter.QuestSlashCommandHelp()
    print("- /quest  |cff8f41  Display active quests in local area.")
    print("- /quest [<user>]  |cff8f41  Display a character's active quests.")
    print("- /quest /list  |cff8f41  Display all character's active quests.")
end

function Scripter.InventorySlashCommandHelp()
    print("- /eq [<user>]  |cff8f41  Display character's worn items.")
    print("- /eq /all  |cff8f41  Display all character's items.")
    print("- /eq /bank  |cff8f41  Display character's bank items.")
    print("- /eq /pack  |cff8f41  Display character's backpack items.")
end

function Scripter.JunkSlashCommandHelp()
    print("- /junk  |cff8f41  List all items marked as junk.")
end

function Scripter.CommandSlashCommandHelp()
    print("- /cmd  |cff8f41  Display all slash commands.")
    print("- /cmd <kwd>  |cff8f41  Display all commands matching keyword.")
    print("- /cmd /clear  |cff8f41  Clear all saved command descriptions.")
    print("- /cmd /desc <cmd> <desc>  |cff8f41  Set a command's description.")
    print("- /cmd /emote  |cff8f41  Display all chat emote commands.")
    print("- /cmd /scripter  |cff8f41  Display all Scripter commands.")
end

function Scripter.GetCommandDesc(cmd)
    if Scripter.savedVariables.userhelp_desc == nil then
        return ""
    end
    -- todo add "/" if not prefixed
    if Scripter.savedVariables.userhelp_desc[cmd] == nil then
        return ""
    end
    return Scripter.savedVariables.userhelp_desc[cmd]
end
function Scripter.SubmitSlashCommandHelp()
    print("- /feedback <msg>  |cff8f41  " .. Scripter.savedVariables.userhelp_desc["/feedback"])
end

function Scripter.MailSlashCommandHelp()
    print("- /mail  |cff8f41  Print a summary of all mail messages.")
    print("- /mail <user> <msg>  |cff8f41  Send a message to <user>.")
    print("- /mail /delete <id>  |cff8f41  Delete a mail message.")
    print("- /mail /read <id>  |cff8f41  Read the full contents of a mail message.")
    print("- /mail /purge  |cff8f41  Purge all mail without attachments.")
end

function Scripter.MinimizeSlashCommandHelp()
    print("- /min  |cff8f41  " .. Scripter.savedVariables.userhelp_desc["/min"])
end
function Scripter.ClearSlashCommandHelp()
    print("- /clear  |cff8f41  " .. Scripter.savedVariables.userhelp_desc["/clear"])
end

function Scripter.FilterSlashCommandHelp()
    print("- /filter  |cff8f41  Print all current chat filters.")
    print("- /filter <text>  |cff8f41  Add a new chat filter keyword.");
    print("- /filter /clear  |cff8f41  Clear all filter keywords.")
    print("- /filter /delete <text>  |cff8f41  Delete a chat filter keyword.");
end

function Scripter.ScreenshotSlashCommandHelp()
    print("- /snap  |cff8f41  " .. Scripter.savedVariables.userhelp_desc["/snap"])
end

function Scripter.FunctionSlashCommandHelp()
    print("- /func  |cff8f41  List all defined functions.")
    print("- /func <func> [<args>]  |cff8f41  Execute a function.")
    print("- /func /edit <func>  |cff8f41  Edit a function's source code.")
    print("API Library:")
    print("- s_args  |cff8f41  A string of all the user arguments.")
    print("- s_arg  |cff8f41  A string array of user arguments.")
    print("- s_db_get(<name>)  |cff8f41  Obtain a stored value from the databank.")
    print("- s_db_set(<name>, <value>)  |cff8f41  Set a value to be stored in the databank.")
    print("- s_call(<func>[, <args>])  |cff8f41  Call another Scripter function with optional arguments.")
    print("- s_loc()  |cff8f41  The current location of the character.")
    print("- s_time()  |cff8f41  The current date and time.")
    print("- s_print(<text>)  |cff8f41  Print text to the chat window.")
    print("- s_pr_clr(<text>)  |cff8f41  Set the text color.")
    print("- s_pr_cord([<loc>])  |cff8f41  Print the grid X and Y coordinates in meters.")
    print("- s_pr_date([<time>])  |cff8f41  Print the date and time of a timestamp.")
    print("- s_pr_loc([<loc>])  |cff8f41  Print information about the zone, sub-zone, and coordinates.")
    print("- s_pr_time([<time>])  |cff8f41  Print the time of a timestamp.")
end

Scripter.helpCommands = {
    ["away"] = Scripter.AFKSlashCommandHelp,
    ["alias"] = Scripter.AliasSlashCommandHelp,
    ["clear"] = Scripter.ClearSlashCommandHelp,
    ["cmd"] = Scripter.CommandSlashCommandHelp,
    ["eq"] = Scripter.InventorySlashCommandHelp,
    ["friend"] = Scripter.FriendSlashCommandHelp,
    ["keybind"] = Scripter.KeybindSlashCommandHelp,
    ["filter"] = Scripter.FilterSlashCommandHelp,
    ["func"] = Scripter.FunctionSlashCommandHelp,
    ["junk"] = Scripter.JunkSlashCommandHelp,
    ["loc"] = Scripter.ZoneSlashCommandHelp,
    ["log"] = Scripter.LogSlashCommandHelp,
    ["mail"] = Scripter.MailSlashCommandHelp,
    ["min"] = Scripter.MinimizeSlashCommandHelp,
    ["research"] = Scripter.ResearchSlashCommandHelp,
    ["sguild"] = Scripter.GuildSlashCommandHelp,
    ["sgroup"] = Scripter.PartySlashCommandHelp,
    ["quest"] = Scripter.QuestSlashCommandHelp,
    ["stat"] = Scripter.ScoreSlashCommandHelp,
    ["sconfig"] = Scripter.ConfigSlashCommandHelp,
    ["feedback"] = Scripter.SubmitSlashCommandHelp,
    ["snap"] = Scripter.ScreenshotSlashCommandHelp,
    ["sync"] = Scripter.SyncSlashCommandHelp,
    ["time"] = Scripter.TimeSlashCommandHelp,
    ["timer"] = Scripter.TimerSlashCommandHelp,
    ["vendor"] = Scripter.VendorSlashCommandHelp,
}

Scripter.damageTypes = {
    [0] = nil,
    [1] = nil,
    [2] = "physical",
    [3] = "fire",
    [4] = "shock",
    [5] = "obvlivion",
    [6] = "cold",
    [7] = "earth",
    [8] = "magicka",
    [9] = "drown",
    [10] = "disease",
    [11] = "poison",
}

function Scripter.extractstr(args, index)
	if args == nil then
	    return nil
	end
    return table.concat(args, " ", index)
end

function Scripter.SlashCommandHelp()
    print("Scripter help topics:")
    for k,v in pairs(Scripter.helpCommands) do
        local help_desc = Scripter.savedVariables.userhelp_desc["/"..k]
        if help_desc == nil then help_desc = "" end
        print("- /scripter " .. k .. "  |cff8f41  " .. help_desc)
    end
end

function Scripter.HelpCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.SlashCommandHelp()
        return
    end

    local hcommand = Scripter.helpCommands[args[1]]
    if not hcommand then
        print("No help topic '" .. Scripter.HighlightText(args[1]) .. "' found.")
--        Scripter.SlashCommandHelp()
        return
    end

    print("Scripter '" .. Scripter.HighlightText(args[1]) .. "' usage:")
    hcommand()
end

function Scripter.KeybindCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.KeybindSlashCommandHelp()
        return
    end

    local command = Scripter.keybindCommands[args[1]]
    if not command then
       print("Scripter: Loading keybind '" .. Scripter.HighlightText(args[1]) .. "'.")
       Scripter.LoadBindings(args[1]);
       return
    end

    -- Call the selected function with everything except the original command
    command(Scripter.extractstr(args,2))
end

function Scripter.ListFriendCommand(argtext)
    if argtext == nil then
        print("Friends:")
    else
        print("Friends (" .. argtext .. "):")
    end
    for i = 1, GetNumFriends(), 1 do
        local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(i)
        local hasCharacter, characterName = GetFriendCharacterInfo(i)
        local text = Scripter.GetFriendText(i)
        if (argtext == nil or si_strifind(displayName, argtext) or si_strifind(characterName, argtext)) then
            print(text)
        end
    end
end

function Scripter.FriendCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.ListFriendCommand()
        return
    end

    local command = Scripter.friendCommands[args[1]]
    if not command then
        Scripter.ListFriendCommand(argtext)
        return
    end

    -- Call the selected function with everything except the original command
    command()
end

function Scripter.ListFilterCommand()
    print("Filters:")
    for k,v in pairs(Scripter.savedVariables.userdata_filter) do
        print("- " .. k)
    end
end

function Scripter.FilterClearCommand(argtext)
    Scripter.savedVariables.userdata_filter = {}
    print("Scripter: Cleared all filter keywords.")
end

function Scripter.FilterDeleteCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.FilterSlashCommandHelp()
        return
    end

    if Scripter.savedVariables.userdata_filter[argtext] == nil then
        print("Scripter: Filter keyword '" .. Scripter.HighlightText(argtext) .. "' does not exist.")
        return
    end

    Scripter.savedVariables.userdata_filter[argtext] = nil
    print("Scripter: Filter '" .. Scripter.HighlightText(argtext) .. "' deleted.")
end

Scripter.filterCommands = {
    ["/clear"] = Scripter.FilterClearCommand,
    ["/delete"] = Scripter.FilterDeleteCommand,
}

function Scripter.FilterCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.ListFilterCommand()
        return
    end

    local args = si_strsplit(" ", argtext)
    local fcommand = Scripter.filterCommands[args[1]]
    if not fcommand then
        Scripter.savedVariables.userdata_filter[argtext] = ""
        print("Scripter: Filter '" .. Scripter.HighlightText(argtext) .. "' added.")
        return
    end

    fcommand(Scripter.extractstr(args,2));
end

function Scripter.Alias_DoCommandInClosure(alias, cmd)
	local args = nil
	if type(cmd) == "table" then
		args = cmd[2]
		cmd = cmd[1]
	end
		
	SLASH_COMMANDS["/"..alias] = function(userArgs)
		if SLASH_COMMANDS["/"..cmd] ~= nil and type(SLASH_COMMANDS["/"..cmd]) == "function" then
			if args then
				if #userArgs > 0 then
					SLASH_COMMANDS["/"..cmd](args.." "..userArgs)
				else
					SLASH_COMMANDS["/"..cmd](args)
				end
			else
				SLASH_COMMANDS["/"..cmd](userArgs)
			end
		else
			print("Command /"..cmd.." doesn't exist.")
		end
	end
end

function Scripter.Alias_ListAliases(...)
	print("Defined aliases:")
	for k,v in pairs(Scripter.savedVariables.userdata_alias_v3) do
		if type(v) == "table" then
			print(k.." -> "..v[1].."("..table.concat(v, ", ", 2)..")")
		else
			print(k.." -> "..v)
		end
	end
end

function Scripter.Alias_AddAlias(arguments)
	local args = {}
	local i = 1
	for w in string.gmatch(arguments,"[%w/:_%-]+") do
		args[i] = w
		i = i + 1
	end
	
	if args[1] == nil or args[2] == nil then
		Scripter.AliasSlashCommandHelp()
		return
	end
	
	local alias = args[1]
	local cmd = args[2]

	-- strip "/" prefix, if specified
	alias = string.gsub(alias, "(/)", "")

	-- strip "/" prefix, if specified
	cmd = string.gsub(cmd, "(/)", "")

	if SLASH_COMMANDS["/"..alias] ~= nil then
	    print("Command /"..alias.." already exists.")
	    return
	end
	
	if cmd == alias then
	    print("Alias name and command cannot be the same.")
	    return
	end
	
	local aliasArgs = table.concat(args, " ", 3)
	
	Scripter.savedVariables.userdata_alias_v3[alias] = {cmd, aliasArgs}
	Scripter.Alias_DoCommandInClosure(alias, Scripter.savedVariables.userdata_alias_v3[alias])
	print("Scripter: Alias /"..alias.." added.")
end

function Scripter.AliasDeleteCommand(arguments)
    local args = {}
    local i = 1
    for w in string.gmatch(arguments,"[%w_%-]+") do
    	args[i] = w
    	i = i + 1
    end
    
    if args[1] == nil then
    	print("Usage: /alias /delete <alias>")
    	return
    end
    
    -- strip "/" prefix, if specified
    args[1] = string.gsub(args[1], "(/)", "")
    
    if Scripter.savedVariables.userdata_alias_v3[args[1]] == nil then
    	print("Alias /"..args[1].." does not exist.")
    	return
    end
    
    SLASH_COMMANDS["/"..args[1]] = nil
    Scripter.savedVariables.userdata_alias_v3[args[1]] = nil
    print("Scripter: Alias /"..args[1].." deleted.")
end

function Scripter.AliasClearCommand(arguments)
    -- purge previous aliases
    for k,v in pairs(Scripter.savedVariables.userdata_alias_v3) do
        local cmd = v
        if type(v) == "table" then
            cmd = v[1]
        end

        Scripter.AliasDeleteCommand(cmd)
    end
    
    -- set default aliases
    Scripter.savedVariables.userdata_alias_v3 = default_alias_cmd 
    for k,v in pairs(Scripter.savedVariables.userdata_alias_v3) do
	Scripter.Alias_DoCommandInClosure(k,v)
    end
 
    print("Scripter: Aliases have been reset to default.")
end

Scripter.aliasCommands = {
    ["/delete"] = Scripter.AliasDeleteCommand,
    ["/clear"] = Scripter.AliasClearCommand,
}

function Scripter.AliasCommand(argtext)
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.Alias_ListAliases()
        return
    end

    local acommand = Scripter.aliasCommands[args[1]]
    if not acommand then
        Scripter.Alias_AddAlias(argtext)
        return
    end

    -- Call the selected function with everything except the original command
    acommand(Scripter.extractstr(args,2));
end

function Scripter.LogResetCommand(argtext)
    Scripter.savedVariables.log = {}
    Scripter.savedVariables.log_idx = 0
	print("Scripter: The character's log has been cleared.")
end

function Scripter.LogFullListCommand(argtext)
	print("History:")
    for i = Scripter.savedVariables.log_idx + 1, 1000, 1 do
	    if Scripter.savedVariables.log[i] ~= nil then
		    print(Scripter.savedVariables.log[i])
		end
	end
    for i = 1, Scripter.savedVariables.log_idx, 1 do
	    if Scripter.savedVariables.log[i] ~= nil then
		    print(Scripter.savedVariables.log[i])
		end
	end
end

function Scripter.LogPrintCommand(argtext)
    print(argtext)
    Scripter.AppendLog(argtext)
end

function Scripter.LogFilterListCommand(argtext)
    print("History (" .. argtext .. "):")
    for i = Scripter.savedVariables.log_idx + 1, 1000, 1 do
	    if Scripter.savedVariables.log[i] ~= nil then
		    if si_strifind(Scripter.savedVariables.log[i], argtext) then
		        print(Scripter.savedVariables.log[i])
                    end
            end
    end
    for i = 1, Scripter.savedVariables.log_idx, 1 do
	    if Scripter.savedVariables.log[i] ~= nil then
		    if string.match(Scripter.savedVariables.log[i], argtext) ~= nil then
		        print(Scripter.savedVariables.log[i])
		    end
		end
	end
end

Scripter.logCommands = {
    ["/chat"] = Scripter.ChatListCommand,
    ["/clear"] = Scripter.LogResetCommand,
    ["/filter"] = Scripter.LogFilterListCommand,
    ["/full"] = Scripter.LogFullListCommand,
    ["/print"] = Scripter.LogPrintCommand,
}

function Scripter.LogListCommand(argtext)
    print("Log History:")

    local max = Settings:GetValue(OPT_LOG_MAX)

    local cnt = 0
    for i = Scripter.savedVariables.log_idx + 1, 1000, 1 do
        if Scripter.savedVariables.log[i] ~= nil then
            if cnt > (1000 - max) then
                print(Scripter.savedVariables.log[i])
            end
        end
        cnt = cnt + 1
    end

    for i = 1, Scripter.savedVariables.log_idx, 1 do
        if Scripter.savedVariables.log[i] ~= nil then
            if cnt > (1000 - max) then
                print(Scripter.savedVariables.log[i])
            end
        end
        cnt = cnt + 1
    end
end

function Scripter.LogAddCommand(argtext)
    Scripter.AppendLog(argtext)
	print("Scripter: Logged '" .. Scripter.HighlightText(argtext) .. "'.")
end

function Scripter.LogCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.LogListCommand("")
        return
    end

    local lcommand = Scripter.logCommands[args[1]]
    if not lcommand then
        Scripter.LogAddCommand(argtext)
        return
    end

    -- Call the selected function with everything except the original command
    lcommand(Scripter.extractstr(args,2));
end

function Scripter.GetPlayerStatCapPercent(stat)
    local cap = GetStatSoftCap(stat)
    if cap == nil then
        return 0
    end

    local per = 100 / cap * GetPlayerStat(stat, 0, 0)
    return per
end

function Scripter.PrintPlayerStatInfo(data, unitTag)
    if data == nil then return end

    for k,v in pairs(data) do
        local idx = charStatType[k]
        local cap = nil
	local text = ""

        text = "|cFFFFFF" .. k .. ": " .. v
	if (unitTag == 'player' and idx ~= nil) then
            text = text .. " " .. string.format("%7.2f", Scripter.GetPlayerStatCapPercent(idx)) .. "%" 
        end
	print(text)
    end
end

function Scripter.ScoreListStatCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.StorePlayerStatInfo()
        Scripter.PrintPlayerStatInfo(Scripter.savedVariables.userdata_attr, 'player')
    else
        local charName = Scripter.GetPlayerAttributeName(argtext)
        if charName == nil then
            print("Scripter: No character attribute info available for user '" .. argtext .. "'.")
            return
        end

        local text
        local data = Scripter.GetPlayerAttributeData(charName)
        if (data[S_LEVEL] ~= nil and data[S_CLASS] ~= nil) then
            text = "Lv " .. data[S_LEVEL] .. " " .. " " .. data[S_CLASS] .. " '" .. Scripter.HighlightText(charName) .. "'"
        else
            text = "'" .. Scripter.HighlightText(charName) .. "'"
        end 
        print(text)
        
        for k,v in pairs(data) do
            if (k ~= S_LEVEL and k ~= S_CLASS and k ~= S_NAME) then
                print(k .. ": " .. v)
	    end
        end
    end
end

function Scripter.ScoreListActionCommand(argtext)
    print("Actions:")
    local abil = Scripter.GetAbilityRates()
    for k,v in pairs(abil) do
	    if v ~= nil then
			    if v ~= 0 then
      			if stat_span[k] == nil then
                          print(k .. " - " .. string.format("%7.2f", v) .. "/min")
      				else
                          print(k .. " - " .. string.format("%7.2f", v) .. "/min (" .. stat_span[k] ..  " since " .. Scripter.FormatTime(stat_stamp[k]) .. ")")
      				end
            end
        end
    end
end

function Scripter.ScoreListActionSummary()
	local text = "Actions: "
	local abil = Scripter.GetAbilityRates()
	for k,v in pairs(abil) do
	    if (v ~= nil and v ~= 0) then
	        text = text .. k .. " (" .. string.format("%7.2f", v) .. "/min)  "
	    end
	end
	print(text)
end

function Scripter.ScoreExpCommand(argtext)
    if (argtext ~= nil and argtext ~= "") then return end

    local vxp = GetUnitVeteranPoints('player')
    local xp = GetUnitXP('player')
    local per = 100 / GetUnitXPMax('player') * xp
    local class = Scripter.GetClassNameByType(GetUnitClassId('player'))
    local name = GetUnitName('player')
    local level = GetUnitLevel('player')
    local text = ""
    
    text = "|cFFFFFFLevel " .. level .. " " .. " " .. class .. " '" .. Scripter.HighlightText(name) .. "', " .. xp .. " XP Points"
    if GetUnitXPMax('player') > xp then
        text = text .. " " .. string.format("%7.2f", per) .. "%"
    end
    if vxp > 0 then
        local vper = 100 / GetUnitVeteranPointsMax('player') * vxp
        text = text .. "  VXP: " .. vxp .. " Points " .. string.format("%7.2f", vper) .. "%"
    end

    print(text)
end

function Scripter.ScoreListBuffSummary(argtext)
    if (argtext ~= nil and argtext ~= "") then return end

    local numBuffs = GetNumBuffs(unit)
		if numBuffs == 0 then
      return
    end
    text = "Buffs: "
    for i = 1, numBuffs do
       local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType = GetUnitBuffInfo(unit, i)
       local diff = timeEnding - GetTimeStamp()

       if diff > 0 then
           text = text .. buffName .. "(" .. diff .. "s)  "
       end
    end
    print(text)
end

function Scripter.ScoreSummaryCommand(argtext)
--    print("Level " .. GetUnitLevel('player') .. " " .. GetUnitName('player'))
    Scripter.ScoreExpCommand(argtext)
    Scripter.ScoreListBuffSummary(argtext)
    Scripter.ScoreListStatCommand(argtext)
end

function Scripter.ScoreResetCommand(argtext)
    Scripter.ClearAbilityRates()
    Scripter.savedVariables.chardata_attr = {}
    Scripter.savedVariables.chardata_skill = {}
    stat_span = {}
    stat_stamp = {}
    print("Scripter: Score statistics have been cleared.")
end

function Scripter.ScoreListFullCommand(argtext)
    if (argtext == nil or argtext == "") then
        argtext = ""
        Scripter.ScoreExpCommand(argtext)
        Scripter.ScoreListStatCommand(argtext)
        Scripter.ScoreListActionCommand(argtext)
        Scripter.ScoreListBuffCommand(argtext)
        Scripter.SkillCommand(argtext)
    else
        Scripter.ScoreListStatCommand(argtext)
        Scripter.SkillCommand(argtext)
        Scripter.ScoreListCraftCommand(argtext)
    end
end

function Scripter.ScoreListBuffCommand(argtext)
    local numBuffs = GetNumBuffs(unit)
		if numBuffs == 0 then
        print("No current character effects.")
        return
    end	
    print("Buffs:")
    for i = 1, numBuffs do
       local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType = GetUnitBuffInfo(unit, i)
       local diff = timeEnding - GetTimeStamp()
       local btype = nil
       if buffType == ABILITY_TYPE_STUN then
           btype = "stun"
       elseif buffType == ABILITY_TYPE_STAGGER then
           btype = "stagger"
       elseif buffType == ABILITY_TYPE_BLOCK then
           btype = "block"
       elseif buffType == ABILITY_TYPE_OFFBALANCE then
           btype = "off-balance"
       elseif buffType == ABILITY_TYPE_BONUS then
           btype = "bonus"
       elseif (string.match(buffName, "^.-Potion" )) then
           btype = "potion"
       end

       if diff > 0 then
           if btype ~= nil then
               print(buffName .. " (" .. btype .. ") .. " .. diff .. "s left") 
           else
               print(buffName .. " .. " .. diff .. "s left") 
           end
       end
    end
end

function Scripter.GetPlayerSkills()
    skills = {
        ["Alchemy"] = GetSkillLineXPInfo(8,1),
        ["Blacksmithing"] = GetSkillLineXPInfo(8,2),
        ["Clothing"] = GetSkillLineXPInfo(8,3),
        ["Enchanting"] = GetSkillLineXPInfo(8,4),
        ["Provisioning"] = GetSkillLineXPInfo(8,5),
        ["Woodworking"] = GetSkillLineXPInfo(8,6),
        ["Assault"] = GetSkillLineXPInfo(6,1),
        ["Support"] = GetSkillLineXPInfo(6,2),
        ["Emperor"] = GetSkillLineXPInfo(6,3),
        ["Fighters Guild"] = GetSkillLineXPInfo(5,1),
        ["Mages Guild"] = GetSkillLineXPInfo(5,2),
        ["Undaunted Guild"] = GetSkillLineXPInfo(5,3),
        ["Light Armor"] = GetSkillLineXPInfo(3,1),
        ["Medium Armor"] = GetSkillLineXPInfo(3,2),
        ["Heavy Armor"] = GetSkillLineXPInfo(3,3),
        ["Two Handed"] = GetSkillLineXPInfo(2,1),
        ["One Hand and Shield"] = GetSkillLineXPInfo(2,2),
        ["Dual Wield"] = GetSkillLineXPInfo(2,3),
        ["Bow"] = GetSkillLineXPInfo(2,4),
        ["Destruction Staff"] = GetSkillLineXPInfo(2,5),
        ["Restoration Staff"] = GetSkillLineXPInfo(2,6),
    }
    if GetUnitClass('player') == "Sorcerer" then
        skills["Dark Magic"] = GetSkillLineXPInfo(1,1)
        skills["Daedric Summoning"] = GetSkillLineXPInfo(1,2)
        skills["Storm Calling"] = GetSkillLineXPInfo(1,3)
    else
        skills["Class Tree 1"] = GetSkillLineXPInfo(1,1)
        skills["Class Tree 2"] = GetSkillLineXPInfo(1,2)
        skills["Class Tree 3"] = GetSkillLineXPInfo(1,3)
    end

    Scripter.savedVariables.userdata_skill = {}
    for k,v in pairs(skills) do
        if v ~= 0 then
            Scripter.savedVariables.userdata_skill[k] = v
        end
    end

    return skills
end

function Scripter.SkillCommand(argtext)
    if (argtext == nil or argtext == "") then 
        local skills = Scripter.GetPlayerSkills()
        print("Skills:")
        for k,v in pairs(skills) do
            if v ~= nil then
                if v > 0 then
                    local text = k .. ": " .. v .. " Points"
                    local per = Scripter.GetSkillPercentage(k)
                    local rate = Scripter.GetAbilityRate(k)
                    if per ~= 0 then
                        text = text .. " " .. string.format("%7.2f", per) .. "%"
                    end
                    if rate ~= 0 then
                        text = text .. " (" .. string.format("%7.2f", rate) .. "/min)"
                    end
                    print(text)
                end
            end
        end
    else
        local charName = Scripter.GetPlayerSkillName(argtext)
        if charName == nil then
            print("Scripter: No skill info available for user '" .. Scripter.HighlightText(argtext) .. "'.")
            return
        end

	print("Skills (" .. charName .. "):")
        local data = Scripter.GetPlayerSkillData(charName)
        for k,v in pairs(data) do
            print(k .. ": " .. v .. " Points")
        end
    end
end

function Scripter.ScoreUserListCommand(argtext)
    if next(Scripter.savedVariables.chardata_attr) == nil then
        print("Scripter: No external character attribute information.")
        return
    end

    print("Characters:")
    for k,v in pairs(Scripter.savedVariables.chardata_attr) do
        print("- " .. k)
    end
end

function Scripter.GetCharacterCraftInfo(craftType)
    local i,maxLines
    local data = {}
    local text = ""

    maxLines = GetNumSmithingResearchLines(craftType)
    for i = 1, maxLines do
        local unkCount = 0
        local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftType, i)
	for traitId = 1, numTraits do
            local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftType, traitId, i)
	    local traitLabel = Scripter.GetItemTraitLabel(traitType)
	    if known == true then
                local craftLabel = Scripter.GetItemCraftTypeLabel(craftType)

                if text ~= "" then text = text .. "\n|cFFFFFF" end
                text = text .. "(" .. craftLabel .. ") " .. Scripter.HighlightText(traitLabel) .. " " .. name .. "\n|cFFFFFF" .. "- " .. traitDescription

		local dname = traitLabel .. " " .. name
		data[dname] = craftLabel 
             elseif (traitDescription ~= "" and unkCount == 0) then
                if text ~= "" then text = text .. "\n|cFFFFFF" end
                text = text .. "(" .. Scripter.GetItemCraftTypeLabel(craftType) .. ") " .. Scripter.HighlightText(traitLabel) .. " " .. name .. " [" .. Scripter.HighlightText("unlearned") .. "]" .. "\n|cFFFFFF" .. "- " .. traitDescription

		unkCount = unkCount + 1
            end
        end
    end

    Scripter.savedVariables.userdata_trait = data
    return text
end

function Scripter.PrintCharacterCraftInfo(craftType)
    local text = Scripter.GetCharacterCraftInfo(craftType)
    if text ~= "" then print(text) end
end

function Scripter.ScoreListCraftCommand(argtext)
    if (argtext == nil or argtext == "") then
        print("Crafting traits:")
        for k,v in pairs(itemCraftType) do
            Scripter.PrintCharacterCraftInfo(v)
        end
    else
        local charName = Scripter.GetPlayerCraftName(argtext)
        if data == nil then
            print("Scripter: No craft info available for user '" .. Scripter.HighlightText(argtext) .. "'.")
            return
        end

        print("Craft traits (" .. charName .. "):")
        local data = Scripter.GetPlayerCraftData(charName)
        for k,v in pairs(data) do
	    print("(" .. k .. ") " .. v)
        end
    end
end

Scripter.statCommands = {
    ["/action"] = Scripter.ScoreListActionCommand,
    ["/all"] = Scripter.ScoreListFullCommand,
    ["/craft"] = Scripter.ScoreListCraftCommand,
    ["/buff"] = Scripter.ScoreListBuffCommand,
    ["/clear"] = Scripter.ScoreResetCommand,
    ["/skill"] = Scripter.SkillCommand,
    ["/userlist"] = Scripter.ScoreUserListCommand,
}

function Scripter.ScoreCommand(argtext)
    Scripter.PreCommandCheck()

    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.ScoreSummaryCommand()
        return
    end

    local scommand = Scripter.statCommands[args[1]]
    if not scommand then
        Scripter.ScoreSummaryCommand(argtext)
        return
    end

    -- Call the selected function with everything except the original command
    scommand(Scripter.extractstr(args,2));
end

function Scripter.CommandResetCommand(argtext)
    Scripter.savedVariables.userhelp_desc = default_help_desc
    print("Scripter: Set command descriptions to default.")
end

function Scripter.TimerResetCommand(argtext)
    Scripter.savedVariables.usertime_timer = {}
    Scripter.savedVariables.usertime_ptimer = {}
    Scripter.savedVariables.usertime_ptimer_span = {}
    print("Scripter: Cleared all timer events.")
end

function Scripter.SyncResetCommand(argtext)
    Scripter.savedVariables.userdata_sync = {}
    Scripter.savedVariables.chardata_sync = {}
    print("Scripter: Cleared synchronization user list.")
end

function Scripter.ResetVendorCommand(argtext)
    Scripter.savedVariables.userdata_vendor = {}
    Scripter.savedVariables.userdata_vendor_loc = {}
    print("Scripter: Vendor information has been cleared.")
end

function Scripter.ZoneResetCommand()
    Scripter.savedVariables.userdata_zone = {}
    Scripter.savedVariables.userdata_zone_loc = {}
    print("Scripter: Cleared stored location information.")
end

function Scripter.TimeCommand(argtext)
    Scripter.PreCommandCheck()
    if (argtext == "/game") then 
        print(Scripter.GetGameTime(GetTimeStamp()) .. " (" .. Scripter.GetMoonPhase(GetTimeStamp()) .. " moon)")
	elseif (argtext == "/real") then 
        print(Scripter.FormatDate(GetTimeStamp()))
    else
        print("Local time is " .. Scripter.GetGameTime(GetTimeStamp()) .. " (" .. Scripter.GetMoonPhase(GetTimeStamp()) .. " moon).")
        print("Earth time is " .. Scripter.FormatDate(GetTimeStamp()) .. ".")
    end
    local diff = GetTimeStamp() - Scripter.savedVariables.usertemp_login_stamp
    if diff < 60 then
        print("You have been playing for " .. diff .. " seconds.")
    elseif diff < 3600 then
        diff = string.format("%.2f", diff / 60)
        print("You have been playing for " .. diff .. " minutes.")
    elseif diff < 86400 then
        diff = string.format("%.2f", diff / 3600)
        print("You have been playing for " .. diff .. " hours.")
    else
        diff = string.format("%.2f", diff / 86400)
        print("You have been playing for " .. diff .. " days.")
    end
end

function Scripter.GetTimerOffset()
    return GetGameTimeMilliseconds() - Scripter.savedVariables.usertime_offset
end

function Scripter.FireTimer(cmd, args)
	local tcmd = "/" .. cmd
	if SLASH_COMMANDS[tcmd] == nil then
		-- silent error
	    return
	end
	SLASH_COMMANDS["/"..cmd](args)
end

function Scripter.FireTimers()
    if Scripter.savedVariables.usertime_offset == 0 then return end
    local now = Scripter.GetTimerOffset()

    for k,v in pairs(Scripter.savedVariables.usertime_timer) do
        if now > k then
            Scripter.savedVariables.usertime_timer[k] = nil

            local args = si_strsplit(" ", v)
            local cmd = args[1]
            Scripter.FireTimer(cmd, Scripter.extractstr(args,2))
        end
    end

    for k,v in pairs(Scripter.savedVariables.usertime_ptimer) do
        if now > k then
            local time = Scripter.savedVariables.usertime_ptimer_span[k]
            Scripter.savedVariables.usertime_ptimer[k] = nil
            Scripter.savedVariables.usertime_ptimer_span[k] = nil

            local args = si_strsplit(" ", v)
            local cmd = args[1]
            Scripter.FireTimer(cmd, Scripter.extractstr(args,2))

            local stamp = now + (time * 1000)
            Scripter.savedVariables.usertime_ptimer[stamp] = v
            Scripter.savedVariables.usertime_ptimer_span[stamp] = time
        end
    end

    if (Scripter.isPlayerAfk() == true and Scripter.savedVariables.usertime_afk ~= 0) then
        if now > Scripter.savedVariables.usertime_afk then
            Scripter.AFKSleep()
        end
    end
end

function Scripter.AddPtimer(time, cmd)
    local args = si_strsplit(" ", cmd)
    if args[1] == nil then
        print("Scripter: You must specify a command.")
        return false
    end

    if SLASH_COMMANDS["/"..args[1]] == nil then
        print("Scripter: Unknown command '/" .. args[1] .. "'.")
        return false
    end

    local stamp = Scripter.GetTimerOffset() + (time * 1000)
    Scripter.savedVariables.usertime_ptimer[stamp] = cmd
    Scripter.savedVariables.usertime_ptimer_span[stamp] = time
    return true
end

function Scripter.TimerRepeatCommand(argtext)
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.TimerSlashCommandHelp()
        return
    end

    local time = args[1]
    local cmd = Scripter.extractstr(args,2)
    if (time == 0 or cmd == nil) then
        Scripter.TimerSlashCommandHelp()
        return
    end

    cmd = string.gsub(cmd, "^(/)", "")
    if Scripter.AddPtimer(time, cmd) == true then
        print("Scripter: Added persistent timer for '/" .. cmd .. "'.")
    end
end

function Scripter.TimerDeleteCommand(argtext)
    local number = argtext
    if type(number) == "string" then
        number = tonumber(number)
    end

    local cmd = Scripter.savedVariables.usertime_timer[number]
    if cmd ~= nil then
        Scripter.savedVariables.usertime_timer[number] = nil
        print("Scripter: Timer '" .. Scripter.HighlightText(cmd) .. "' has been removed.")
        return
    end

    local cmd = Scripter.savedVariables.usertime_ptimer[number]
    if cmd ~= nil then
        Scripter.savedVariables.usertime_ptimer[number] = nil
        print("Scripter: Persistent timer '" .. Scripter.HighlightText(cmd) .. "' has been removed.")
        return
    end

    print("Scripter: Timer id '" .. Scripter.HighlightText(number) .. "' not found.")
end

Scripter.timerCommands = {
    ["/delete"] = Scripter.TimerDeleteCommand,
    ["/repeat"] = Scripter.TimerRepeatCommand,
    ["/clear"] = Scripter.TimerResetCommand,
}

function Scripter.AddTimer(time, cmd)
    if (time == nil or cmd == nil) then return end

    local args = si_strsplit(" ", cmd)
    if (args[1] == nil or SLASH_COMMANDS["/"..args[1]] == nil) then
        print("Scripter: Unknown command '/" .. args[1] .. "'.")
        return false
    end

    local stamp = Scripter.GetTimerOffset() + (time * 1000)
    Scripter.savedVariables.usertime_timer[stamp] = cmd
    return true
end

function Scripter.TimerSlashListCommand()
    print("Timers:")
    for k,v in pairs(Scripter.savedVariables.usertime_timer) do
        print("[" .. Scripter.FormatTime(k) .. "] " .. v .. " (id: " .. k .. ")")
    end

    print("Repeated Timers:")
    for k,v in pairs(Scripter.savedVariables.usertime_ptimer) do
        print("[" .. Scripter.FormatTime(k) .. " (every " .. Scripter.savedVariables.usertime_ptimer_span[k] .. "s)] " .. v .. " (id: " .. k .. ")")
    end
end	

function Scripter.TimerCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.TimerSlashListCommand()
        return
    end

    local tcommand = Scripter.timerCommands[args[1]]
    if not tcommand then
    	local time = args[1]
    	local cmd = Scripter.extractstr(args,2)
    	if (time == 0 or cmd == nil) then
            Scripter.TimerSlashCommandHelp()
			return
    	end

        cmd = string.gsub(cmd, "^(/)", "")
	if Scripter.AddTimer(time, cmd) == true then
            print("Scripter: Added timer for '/" .. cmd .. "'.")
        end
        return
    end

    tcommand(Scripter.extractstr(args,2))
end

-- list users configured to sync with
function Scripter.SyncListCommand()
    print("Sync accounts:");
    for k,v in pairs(Scripter.savedVariables.userdata_sync) do
        if Settings:GetValue(OPT_SYNC) == false then
            print("- " .. k)
        elseif v ~= 0 then
            print("- " .. k .. " (" .. Scripter.FormatTime(v) .. ")")
        else
            print("- " .. k .. " (pending)")
        end
    end
end

function Scripter.MSync_GetSyncTextInfo(prefix, data)
    if data == nil then return end

    local cnt = 0
    local text = ""
    for k,v in pairs(data) do
        if (k ~= nil and v ~= nil) then
            if cnt == 0 then
                text = ".." .. prefix
            end

            text = text .. ":" .. v .. " " .. k

            cnt = cnt + 1
	    if cnt >= 5 then
		text = text .. "..\n"
                cnt = 0
            end
        end
    end
    text = text .. "..\n"

    return text
end

function Scripter.GetCharacterSyncOption(displayName, name)
    local opts = Scripter.savedVariables.chardata_sync_opt[displayName]
    if (opts == nil or opts[name] == nil) then return Settings:GetValue(name) end

    return opts[name]
end

function Scripter.SetCharacterSyncOption(displayName, name, value)
    local opts = Scripter.savedVariables.chardata_sync_opt[displayName]
    if opts == nil then opts = {} end

    opts[name] = value
    Scripter.savedVariables.chardata_sync_opt[displayName] = opts
end

function Scripter.MSync_SendEvent(displayName, isManual)
    if displayName == nil then return end
    local stamp = GetTimeStamp()

    -- todo: parse options
--     text = "..OPT:"
--     for k,v in pairs(Scripter.savedVariables.chardata_sync_opt) do
--         if v == true then
-- 	    text = text .. "1 " .. k 
--         else
-- 	    text = text .. "0 " .. k 
-- 	end
--     end
--     text = text .. "..\n"

    local skip = false
    if (Scripter.GetCharacterSyncOption(displayName, OPT_SYNC_QUEST) and Scripter.savedVariables.usertime_sync_quest < stamp) then
        local text = "Automatically generated by Scripter.\n\n"
        text = text .. Scripter.MSync_GetSyncTextInfo("QUE", Scripter.savedVariables.userdata_quest)
	Scripter.savedVariables.usertime_sync_quest = stamp + (ONE_HOUR * 4)
	if isManual == false then skip = true end
        Scripter.SendGameMail(displayName, "Scripter Automatic Synchronization", text)
--        SendMail(displayName, "Scripter Automatic Synchronization", text)
        Scripter.PrintDebug("MSync_SendEvent[QUE] displayName:" .. displayName .. " nextTime:" .. Scripter.FormatTime(GetTimeStamp() + 1200))
    end

    if (skip == false and Scripter.GetCharacterSyncOption(displayName, OPT_SYNC_SKILL) and Scripter.savedVariables.usertime_sync_skill < stamp) then
        local skills = Scripter.GetPlayerSkills() -- refresh vars 
        local text = "Automatically generated by Scripter.\n\n"
        text = text .. Scripter.MSync_GetSyncTextInfo("SKI", Scripter.savedVariables.userdata_skill)
	Scripter.savedVariables.usertime_sync_skill = stamp + (ONE_HOUR * 3)
	if isManual == false then skip = true end
        Scripter.SendGameMail(displayName, "Scripter Automatic Synchronization", text)
--        SendMail(displayName, "Scripter Automatic Synchronization", text)
        Scripter.PrintDebug("MSync_SendEvent[SKI] displayName:" .. displayName .. " nextTime:" .. Scripter.FormatTime(GetTimeStamp() + 1200))
    end

    if (skip == false and Scripter.GetCharacterSyncOption(displayName, OPT_SYNC_ITEM) and Scripter.savedVariables.usertime_sync_item < stamp) then
        local text = "Automatically generated by Scripter.\n\n"
        text = text .. Scripter.MSync_GetSyncTextInfo("ITE", Scripter.savedVariables.userdata_item_worn)
	Scripter.savedVariables.usertime_sync_item = stamp + (ONE_HOUR * 2)
	if isManual == false then skip = true end
        Scripter.SendGameMail(displayName, "Scripter Automatic Synchronization", text)
--        SendMail(displayName, "Scripter Automatic Synchronization", text)
        Scripter.PrintDebug("MSync_SendEvent[ITE] displayName:" .. displayName .. " nextTime:" .. Scripter.FormatTime(GetTimeStamp() + 1200))
    end

    if (skip == false and Scripter.GetCharacterSyncOption(displayName, OPT_SYNC_CRAFT) and Scripter.savedVariables.usertime_sync_trait < stamp) then
        local text = "Automatically generated by Scripter.\n\n"
        text = text .. Scripter.MSync_GetSyncTextInfo("CRA", Scripter.savedVariables.userdata_trait)
	Scripter.savedVariables.usertime_sync_trait = stamp + ONE_HOUR
	if isManual == false then skip = true end
        Scripter.SendGameMail(displayName, "Scripter Automatic Synchronization", text)
--        SendMail(displayName, "Scripter Automatic Synchronization", text)
        Scripter.PrintDebug("MSync_SendEvent[CRA] displayName:" .. displayName .. " nextTime:" .. Scripter.FormatTime(GetTimeStamp() + 1200))
    end

    if skip == false then
        local text = "Automatically generated by Scripter.\n\n"
        text = text .. Scripter.MSync_GetSyncTextInfo("ATT", Scripter.savedVariables.userdata_attr)
        Scripter.SendGameMail(displayName, "Scripter Automatic Synchronization", text)
--        SendMail(displayName, "Scripter Automatic Synchronization", text)
        Scripter.PrintDebug("MSync_SendEvent[ATT] displayName:" .. displayName .. " nextTime:" .. Scripter.FormatTime(GetTimeStamp() + 1200))
    end
end

function Scripter.MSync_UpdateEvent()
    local now = GetTimeStamp()
    for k,v in pairs(Scripter.savedVariables.userdata_sync) do
        if now > v then
           if Scripter.IsAccountOnline(k) == true then
               Scripter.MSync_SendEvent(k, false)
           end
           Scripter.savedVariables.userdata_sync[k] = now + 1200
        end
    end
end

function Scripter.MSync_AddUser(displayName)
    if displayName == nil then return end

    if string.gmatch(displayName, "^@") == nil then
        displayName = "@" .. displayName
    end
    Scripter.savedVariables.userdata_sync[displayName] = 0
end

function Scripter.SyncAddUserCommand(argtext)
    for i = 1, GetNumFriends(), 1 do
        local displayName, note, playerStatus, secsSinceLogoff = GetFriendInfo(i)
        if string.match(displayName, argtext) ~= nil then
	    Scripter.MSync_AddUser(displayName)
            if Settings:GetValue(OPT_SYNC) == true then
                print("Scripter: Added user '" .. Scripter.HighlightText(displayName) .. " for synchronization.")
            else
                Scripter.MSync_SendEvent(displayName, true)
                print("Scripter: Sent synchronization to user '" .. Scripter.HighlightText(displayName) .. ".")
            end

            local timeSinceLogoff = nil
            if secsSinceLogoff > 0 then
                timeSinceLogoff = Scripter.FormatSecondsToDDHHMMSS(secsSinceLogoff)
            end
            if timeSinceLogoff ~= nil then
                print("Info: User has been logged off for " .. timeSinceLogoff)
            end
            return
        end
    end
    print("Scripter: User '" .. Scripter.HighlightText(argtext) .. "' not found.")
end

function Scripter.MSync_RemoveUser(displayName)
    Scripter.savedVariables.userdata_sync[displayName] = nil
end

function Scripter.SyncDeleteUserCommand(displayName)
    if string.match(displayName, "^@") == nil then
        displayName = "@" .. displayName
    end
    if Scripter.savedVariables.userdata_sync[displayName] == nil then
        print("Scripter: Sync user '" .. displayName .. "' not found.")
        return
    end

    Scripter.MSync_RemoveUser(displayName)
    print("You are no longer synchronizing with user '" .. displayName .. "'.")
end

function Scripter.SyncListInfoCommand(argtext)
    if (argtext == nil or argtext == "") then
        print("Sync character history:")
        for k,v in pairs(Scripter.savedVariables.chardata_sync) do
            print("- " .. k .. " (" .. Scripter.FormatDate(v) .. ")")
        end
    else
        Scripter.ScoreListStatCommand(argtext)
        Scripter.SkillCommand(argtext)
        Scripter.ScoreListCraftCommand(argtext)
        Scripter.InventorySummaryListCommand(argtext)
        Scripter.QuestCommand(argtext)
    end
end

function Scripter.SyncScanCommand(argtext)
    print("Scripter: Scanning mail for sync notifications.")

    local mailId = nil
    local numMail = GetNumMailItems()
    for m = 1, numMail, 1 do
        mailId = GetNextMailId( mailId )

        local senderAccount, senderName, Subject = GetMailItemInfo(mailId)
        if Subject == "Scripter Automatic Synchronization" then
            local data = Scripter.ReadGameMail(mailId)
--            local data = ReadMail(mailId)
	    Scripter.MSync_ParseMailEvent(senderName, data)
        end
    end
end

Scripter.syncCommands = {
    ["/clear"] = Scripter.SyncResetCommand,
    ["/delete"] = Scripter.SyncDeleteUserCommand,
    ["/list"] = Scripter.SyncListInfoCommand,
    ["/scan"] = Scripter.SyncScanCommand,
}

function Scripter.SyncCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.SyncListCommand()
        return
    end

    local scommand = Scripter.syncCommands[args[1]]
    if not scommand then
        Scripter.SyncAddUserCommand(argtext)
	return
    end

    scommand(Scripter.extractstr(args, 2))
end

function Scripter.ListVendorCommand(argtext)
    local zone, subzone = si_char_area()--Scripter.GetZoneAndSubzone()
    local subdesc = GetMapName()
    local found = false

    print("Vendors:")
    for k,v in pairs(Scripter.savedVariables.userdata_vendor) do
        if v == subdesc then
            local loc = Scripter.savedVariables.userdata_vendor_loc[k]
            local text = Scripter.HighlightText(k) .. " in " .. v
	    if loc ~= nil then 
                text = text .. " " .. Scripter.GetDistanceText(loc.x, loc.y)
            end
            text = text .. "."
            print(text)
	    found = true
	end
    end
    if found == false then
        print("Scripter: No vendors have been visited in this area.")
    end
end

function Scripter.FilterVendorCommand(argtext)
    print("Vendor (" .. argtext .. "):")
    for k,v in pairs(Scripter.savedVariables.userdata_vendor) do
        if (si_strifind(k, argtext) or si_strifind(v, argtext)) then
            print(k .. " [" .. v .. "]")
	end
    end
end

function Scripter.ListAllVendorCommand(argtext)
    print("Vendors:")
    for k,v in pairs(Scripter.savedVariables.userdata_vendor) do
        print(k .. " [" .. v .. "]")
    end
end

Scripter.vendorCommands = {
    ["/clear"] = Scripter.ResetVendorCommand,
    ["/list"] = Scripter.ListAllVendorCommand,
} 

function Scripter.VendorCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.ListVendorCommand()
        return
    end

    local vcommand = Scripter.vendorCommands[args[1]]
    if not vcommand then
        Scripter.FilterVendorCommand(argtext)
        return
    end

    vcommand(Scripter.extractstr(args,2))
end

function Scripter.JoinGroupCommand(argtext)
    if argtext == "" then
        print("Scripter: You must specify a username.")
        return
    end
    GroupInviteByName(argtext)
end

function Scripter.LeaveGroupCommand(argtext)
    GroupDisband()
    GroupLeave() -- incase user is group leader
--    print("You disband from the group.")
end

--function Scripter.FormatCordinate(cord)
--   return zo_round(cord * 10000) / 10000
--end

function Scripter.CordinateToMeters(cord)
    return si_formatmeter(cord)
--    return zo_round(300 * cord)
end

function Scripter.CordinateDistance(x, y)
    local plrX, plrY = GetMapPlayerPosition('player')
--    local locX = Scripter.FormatCordinate(plrX)
--    local locY = Scripter.FormatCordinate(plrY)
    local locX = si_formatcord(plrX)
    local locY = si_formatcord(plrY)

    local distX = zo_abs(Scripter.CordinateToMeters(x - plrX)) 
    local distY = zo_abs(Scripter.CordinateToMeters(y - plrY)) 
    return (distX + distY) / 2
end

function Scripter.CordinateDirection(x, y)
    local plrX, plrY = GetMapPlayerPosition('player')
    if (plrX == nil or plrY == nil) then return "" end
    local locX = Scripter.CordinateToMeters(plrX)
    local locY = Scripter.CordinateToMeters(plrY)

    x = Scripter.CordinateToMeters(x)
    y = Scripter.CordinateToMeters(y)

    local east = false
    local north = false
    local west = false
    local south = false
    if locX < x then east = true end
    if locY > y then north = true end
    if locX > x then west = true end
    if locY < y then south = true end

    if (north == true and east == true) then 
        return "NE"
    elseif (north == true and west == true) then
        return "NW"
    elseif (south == true and east == true) then
        return "SE"
    elseif (south == true and west == true) then
        return "SW"
    elseif north == true then
        return "N"
    elseif south == true then
        return "S"
    elseif east == true then
        return "E"
    elseif west == true then
        return "W"
    end

    return ""
end

function Scripter.GetCordinateText(x, y)
    return si_cord(x, y)
--    return Scripter.CordinateToMeters(x) .. ":" .. Scripter.CordinateToMeters(y)
end

function Scripter.GetDistanceText(x, y)
    if (x == nil or y == nil) then return "n/a" end

    local dist = Scripter.CordinateDistance(x,y)
    if dist == 0 then return "" end

    local text = dist .. "m " .. Scripter.CordinateDirection(x,y)
    text = text .. " " .. Scripter.GetCordinateText(x,y)
    text = " (" .. text .. ")" 
    return text
end

function Scripter.ZoneInfoCommand()
--    local x, y = GetMapPlayerPosition('player')
--    local zone, subzone = Scripter.GetZoneAndSubzone()
--    local subdesc = GetMapName()
--    print("Location: " .. Scripter.HighlightText(subdesc) .. " of " .. zone .. " (" .. Scripter.GetCordinateText(x,y) .. ")")

    local loc = Scripter.GetPlayerLocation()
    print("Location: " .. Scripter.HighlightText(loc.area) .. " of " .. loc.zone .. " (" .. Scripter.GetCordinateText(loc.x, loc.y) .. ")")
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    if (zoneIndex ~= nil and poiIndex ~= nil) then
        local text = Scripter.GetPOIText(zoneIndex, i, false)
        if text ~= "" then print("- " .. text) end
    end
end

function Scripter.ZoneFilterCommand(argtext)
    print("Zones (" .. argtext .. "):")
    for k,v in pairs(Scripter.savedVariables.userdata_zone) do
        if (si_strifind(k, argtext) or si_strifind(v, argtext)) then
            print("Location: " .. k .. " of " .. v .. ".")
        end
    end
end

function Scripter.ZoneListAllCommand(argtext)
    print("Zones:")
    for k,v in pairs(Scripter.savedVariables.userdata_zone) do
        local text = "Location: " .. Scripter.HighlightText(k) .. " of " .. v .. "."
        print(text)
    end
end

function Scripter.GetPOIText(zoneIndex, poiIndex, showLocation)
    local x,y = GetPOIMapInfo(zoneIndex, poiIndex)
    local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
    if (x == nil or y == nil or objectiveName == "") then return "" end
    local dungeon = false
    local wayshrine = false
    local text

    if (IsPOIPublicDungeon(zoneIndex, poiIndex) == true or IsPOIGroupDungeon(zoneIndex, poiIndex)) then dungeon = true end
    if IsPOIWayshrine(zoneIndex, poiIndex) then wayshrine = true end

    text = Scripter.HighlightText(objectiveName)
    if objectiveLevel ~= 0 then 
        text = text .. " Lv " .. objectiveLevel
    end
    if startDescription ~= "" then 
       text = text .. " - " .. startDescription
    end
    if dungeon == true then text = text .. " [dungeon]" end
    if wayshrine == true then text = text .. " [wayshrine]" end
    if (showLocation == nil or showLocation == true) then
       text = text .. " " .. Scripter.GetDistanceText(x, y) 
       --text = text .. " [" .. Scripter.GetDistanceText(x, y) .. " " .. Scripter.GetCordinateText(x, y) .. "]"
    end

    return text
end

function Scripter.ZoneListPOICommand(argtext)
    local loc = Scripter.GetPlayerLocation()
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    local loc_max = GetNumPOIs(zoneIndex)

    print("Locations (" .. loc.zone .. "):")
    if zoneIndex == nil then return end

    for i = 1, loc_max, 1 do
        local text = Scripter.GetPOIText(zoneIndex, i, false)
        if text ~= "" then print(text) end
    end
end

Scripter.zoneCommands = {
    ["/area"] = Scripter.ZoneListPOICommand,
    ["/clear"] = Scripter.ZoneResetCommand,
    ["/list"] = Scripter.ZoneListAllCommand,
}

function Scripter.ZoneCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.ZoneInfoCommand()
        return
    end

    local zcommand = Scripter.zoneCommands[args[1]]
    if not zcommand then
        Scripter.ZoneFilterCommand(argtext)
        return
    end

    zcommand(Scripter.extractstr(args,2))
end

-- GetJournalQuestType
function Scripter.QuestListAreaCommand(argtext)
    local loc = Scripter.GetPlayerLocation()
    print("Quests (" .. Scripter.HighlightText(loc.area) .. " of " .. loc.zone .. "):")
    local quests = Scripter.GetQuestInfo()
	local s_quest = {}
    for k,v in pairs(quests) do
        local isArea = IsJournalQuestInCurrentMapZone(v.questIndex)
        if (v.isCompleted == false and isArea) then
           local text = v.name
	       if v.zoneName ~= "" then
               text = text .. " (Lv " .. v.questLevel .. ")"
           else
               text = text .. " [" .. v.zoneName .. " (Lv " .. v.questLevel .. ")]"
           end
           print(text)
           print("- " .. v.bgText)

           if (v.zoneIndex ~= nil and v.poiIndex ~= nil) then
              text = Scripter.GetPOIText(v.zoneIndex, v.poiIndex, true)
              if text ~= "" then print("- " .. text) end
           end

	       -- quest key:name val:zone
	       local zoneName = v.zoneName
	       if zoneName == "" then
               zoneName = "Global"
	       end
           s_quest[v.name] = zoneName
        end
    end
end

function Scripter.QuestListAllCommand(argtext)
    print("Quests:")
    local quests = Scripter.GetQuestInfo()
	local s_quest = {}
    for k,v in pairs(quests) do
        if v.isCompleted == false then
           local text = v.name
	       if v.zoneName ~= "" then
               text = text .. " (Lv " .. v.questLevel .. ")"
           else
               text = text .. " [" .. v.zoneName .. " (Lv " .. v.questLevel .. ")]"
           end
           print(text)
           print("- " .. v.bgText)

           if (v.zoneIndex ~= nil and v.poiIndex ~= nil) then
              local isArea = IsJournalQuestInCurrentMapZone(v.questIndex)
              text = Scripter.GetPOIText(v.zoneIndex, v.poiIndex, isArea)
              if text ~= "" then print("- " .. text) end
           end

           -- quest key:name val:zone
           local zoneName = v.zoneName
           if zoneName == "" then
               zoneName = "Global"
           end
           s_quest[v.name] = zoneName
        end
    end
    Scripter.savedVariables.userdata_quest = s_quest
end

Scripter.questCommands = {
    ["/list"] = Scripter.QuestListAllCommand,
}
function Scripter.QuestCommand(argtext)
    Scripter.PreCommandCheck()

    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.QuestListAreaCommand()
        return
    end

    local qcommand = Scripter.questCommands[args[1]]
    if not qcommand then
        Scripter.QuestListCharacterCommand(argtext)
        return
    end

    qcommand(Scripter.extractstr(args, 2))
end

function Scripter.QuestListCharacterCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.QuestSlashCommandHelp()
    end

    local charName = Scripter.GetPlayerQuestName(argtext)
    if charName == nil then
        print("Scripter: No quest info available for user '" .. Scripter.HighlightText(argtext) .. "'.")
        return
    end

    print("Quests (" .. charName .. "):")
    local data = Scripter.GetPlayerQuestData(charName)
    for k,v in pairs(data) do
        if v == "" then v = "Global" end
	    print(k .. " [" .. v .. "]") 
    end
end

function Scripter.GetItemData(data, slotId)
    for k,v in pairs(data) do
        if v == slotId then
           return k
        end
    end
end

function Scripter.StoreInventoryItem(item)
    local text = Scripter.GetInventoryItemText(item)
    if text == nil then return end

    Scripter.savedVariables.userdata_item_worn[text] = 1
end

function Scripter.GetInventoryItem(bagId, slotId)
    local item = Scripter.GetPlayerItemInfo(bagId, slotId)
    if bagId == BAG_WORN then
        Scripter.StoreInventoryItem(item)
    end
    return item
end

function Scripter.ListPackInventoryCommand()
    print("Inventory:")
    local max = GetBagSize(BAG_BACKPACK)
    for slotId = 0, max do
        local link = GetItemLink(BAG_BACKPACK, slotId)
        local cond = Scripter.GetItemCondition(BAG_BACKPACK, slotId)
        local item = Scripter.GetInventoryItem(BAG_BACKPACK, slotId)
        local text = Scripter.GetInventoryItemText(item, cond, false)
        if text ~= nil then
            print(link .. text)
        end
    end
    local max = GetBagSize(BAG_WORN)
    for slotId = 0, max do
        local link = GetItemLink(BAG_WORN, slotId)
        local cond = Scripter.GetItemCondition(BAG_WORN, slotId)
        local item = Scripter.GetInventoryItem(BAG_WORK, slotId)
        if (item ~= nil and item['equip'] == nil) then
            local text = Scripter.GetInventoryItemText(item, cond, false)
            if text ~= nil then
                print(link .. text)
            end
        end
    end
end

function Scripter.ListWornInventoryCommand(argtext)
   if (argtext == nil or argtext == "") then
       Scripter.savedVariables.userdata_item_worn = {}
       print("Worn:")
       local max = GetBagSize(BAG_WORN)
       for slotId = 0, max do
           local link = GetItemLink(bagId, slotId)
           local cond = Scripter.GetItemCondition(BAG_WORN, slotId)
           local item = Scripter.GetInventoryItem(BAG_WORN, slotId)
           if (item ~= nil and item['equip'] ~= nil) then
               local text = Scripter.GetInventoryItemText(item, cond, true)
               if text ~= nil then
                   print(link .. text)
               end
           end
       end
    else
        local charName = Scripter.GetPlayerItemName(argtext)
        if charName == nil then
            print("Scripter: No equipment info available for user '" .. Scripter.HighlightText(argtext) .. "'.")
            return
        end

        print("Worn (" .. charName .. "):")
        local data = Scripter.GetPlayerItemData(charName)
        for k,v in pairs(data) do
	    local item = {}
	    item['name'] = k
            print(Scripter.GetInventoryItemText(item))
        end
    end
end
function Scripter.ListBankInventoryCommand(argtext)
    print("Bank:")
    local max = GetBagSize(BAG_BANK)
    for slotId = 0, max do
       local item = Scripter.GetInventoryItem(BAG_BANK, slotId)
       if item ~= nil then
           local cond = Scripter.GetItemCondition(BAG_BANK, slotId)
           local text = Scripter.GetInventoryItemText(item, cond)
           if text ~= nil then
               local link = GetItemLink(bagId, slotId)
               print(link .. text)
           end
       end 
    end
end

function Scripter.InventorySummaryListCommand(argtext)
    Scripter.ListWornInventoryCommand(argtext)
end

function Scripter.ListAllInventoryCommand(argtext)
    Scripter.ListBankInventoryCommand(argtext)
    Scripter.ListWornInventoryCommand(argtext)
    Scripter.ListPackInventoryCommand(argtext)
end

Scripter.inventoryCommands = {
    ["/all"] = Scripter.ListAllInventoryCommand,
    ["/bank"] = Scripter.ListBankInventoryCommand,
    ["/pack"] = Scripter.ListPackInventoryCommand,
}

function Scripter.InventoryCommand(argtext)
    Scripter.PreCommandCheck()

    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.InventorySummaryListCommand()
        return
    end

    local icommand = Scripter.inventoryCommands[args[1]]
    if not icommand then
        Scripter.InventorySummaryListCommand(argtext)	
        return
    end

    icommand(Scripter.extractstr(args, 2))
end

function Scripter.JunkListCommand(textarg)
    if next(Scripter.savedVariables.userdata_junk) == nil then
        print("Scripter: There are no junk items marked.")
        return
    end

    print("Junk Items:")
    for k,v in pairs(Scripter.savedVariables.userdata_junk) do
        print(k)
    end
end

function Scripter.JunkCommand(textarg)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.JunkListCommand()
        return
    end

    Scripter.JunkSlashCommandHelp()
end

function Scripter.CommandListCommand(textarg)
    if textarg == nil then
        print("Commands:")
    else
        print("Commands (" .. textarg .. "):")
    end

    local cnt = 0
    local text = ""
    for k,v in pairs(SLASH_COMMANDS) do
        if (textarg == nil or string.match(k, textarg) ~= nil) then 
            local help_desc = Scripter.savedVariables.userhelp_desc[k]
            if help_desc == nil then 
	        text = text .. k .. "  "
                cnt = cnt + 1

                if (cnt > 12) then
                    print(text)	
                    text = ""
                    cnt = 0
                end
            end
        end 
    end
    print(text);

    for k,v in pairs(SLASH_COMMANDS) do
        if (textarg == nil or string.match(k, textarg) ~= nil) then 
            local help_desc = Scripter.savedVariables.userhelp_desc[k]
            if help_desc ~= nil then 
	        print("- " .. k .. "  |cff8f41  " .. help_desc)
            end
        end 
    end
end

function Scripter.AFKQuietCommand()
    if Scripter.isPlayerAfk() == false then
        Scripter.setPlayerAfk(PLAYER_STATUS_DO_NOT_DISTURB)
	print("Scripter: Character AFK (Quiet) mode enabled.")
	Scripter.AFKSleep()
    else
        Scripter.setPlayerAfk(PLAYER_STATUS_ONLINE)
	print("Scripter: Character AFK mode disabled.")
	Scripter.AFKWake()
    end
end

Scripter.afkCommands = {
    ["/action"] = Scripter.AFKActionCommand,
    ["/quiet"] = Scripter.AFKQuietCommand,
}

function Scripter.ScripterCommandsCommand(argtext)
    print("Scripter commands:")
    for k,v in pairs(Scripter.helpCommands) do
        local help_desc = Scripter.savedVariables.userhelp_desc["/"..k]
        if help_desc == nil then help_desc = "" end
        print("- /" .. k .. "  |cff8f41  " .. help_desc)
    end
    print("Scripter aliases:")
    for k,v in pairs(Scripter.savedVariables.userdata_alias_v3) do
        local help_desc = Scripter.savedVariables.userhelp_desc["/"..k]
        if help_desc == nil then help_desc = "" end
        print("- /" .. k .. "  |cff8f41  " .. help_desc)
    end
end

function Scripter.EmoteCommandsCommand(argtext)
    print("Emote Commands:")
    local emoteCount = GetNumEmotes()
    for j = 1, emoteCount, 1 do
        local cmd = GetEmoteSlashName(j)
        local help_desc = Scripter.savedVariables.userhelp_desc[cmd]
        if help_desc == nil then help_desc = "" end
        print("- " .. GetEmoteSlashName(j) .. "  |cff8f41  " .. help_desc)
    end
end

function Scripter.CommandDescCommand(argtext)
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.CommandSlashCommandHelp()
        return
    end

    local cmd = string.gsub(args[1], "(/)", "")
    if SLASH_COMMANDS["/" .. cmd] == nil then
        print("Scripter: Unknown command '/" .. cmd .. "'.")
        return
    end

    local text = Scripter.extractstr(args,2)
    if (text == nil or text == "") then
        Scripter.CommandSlashCommandHelp()
	return
    end

    Scripter.savedVariables.userhelp_desc["/"..cmd] = text
    print("Scripter: Set command '/" .. Scripter.HighlightText(cmd) .. "' description to '" .. Scripter.HighlightText(text) .. "'.")
end

Scripter.commandCommands = {
    ["/clear"] = Scripter.CommandResetCommand,
    ["/desc"] = Scripter.CommandDescCommand,
    ["/emote"] = Scripter.EmoteCommandsCommand,
    ["/scripter"] = Scripter.ScripterCommandsCommand,
}

function Scripter.CommandCommand(argtext)
    Scripter.PreCommandCheck()
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.CommandListCommand()
        return
    end

    local ccommand = Scripter.commandCommands[args[1]]
    if not ccommand then
        Scripter.CommandListCommand(argtext)
        return
    end

    ccommand(Scripter.extractstr(args,2));
end

function Scripter.PartyListCommand()
    print("Party members:")
    for i = 1, GetGroupSize(), 1 do
        print("- " .. Scripter.FormatItemName(GetGroupUnitTagByIndex(i)))
    end
end

Scripter.partyCommands = {
    ["/leave"] = Scripter.LeaveGroupCommand,
    ["/invite"] = Scripter.JoinGroupCommand,
}

function Scripter.PartyCommand(argtext)
    Scripter.PreCommandCheck()

    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.PartyListCommand()
        return
    end

    local pcommand = Scripter.partyCommands[args[1]]
    if not pcommand then
        Scripter.PartySlashCommandHelp()
        return
    end

    pcommand(Scripter.extractstr(args,2));
end

function Scripter.NewCombatEvent( eventCode , result , isError , abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log )
    if sourceName == "" then return end
    Scripter.PrintDebug("NewCombatEvent sourceName:" .. sourceName)
    Scripter.PreEventCheck()

    if sourceName == targetName then
			if ( result == ACTION_RESULT_HEAL or result == ACTION_RESULT_CRITICAL_HEAL or result == ACTION_RESULT_HOT_TICK or result == ACTION_RESULT_HOT_TICK_CRITICAL ) then
          if hitValue ~= 0 and abilityName ~= "" then
    			    Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, "+" .. hitValue .. " " .. abilityName .. " (Heal)")
          end
    elseif ( result == ACTION_RESULT_IMMUNE or result == ACTION_RESULT_DODGED or result == ACTION_RESULT_REFLECTED or result == ACTION_RESULT_RESIST or result == ACTION_RESULT_INTERRUPT or result == ACTION_RESULT_PARRIED or result == ACTION_RESULT_MISS or result == ACTION_RESULT_DAMAGE_SHIELDED or result == ACTION_RESULT_ABSORBED ) then
          if hitValue ~= 0 and abilityName ~= "" then
			        Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, "+" .. hitValue .. " " .. abilityName .. " (Immune)")
          end
		    end
	else
		sourceName = "You"
	    local dmg_type = Scripter.damageTypes[damageType]
	    if dmg_type == nil then
				return
        end

--        if result == ACTION_RESULT_KILLING_BLOW then
--	        Scripter.NotifyCharacterAction(sourceName .. " incapacitate " .. targetName " with " .. hitValue .. " points of '" .. abilityName .. "' " .. dmg_type .. " damage.")
--	        Scripter.AddAbilityRate("Kills", hitValue)
--        end

      targetName = Scripter.FormatItemName(targetName)

			local action = "does"
			if ( result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_BLOCKED_DAMAGE or result == ACTION_RESULT_FALL_DAMAGE ) then
			    action = "inflict"
				victim = targetName
            elseif ( result == ACTION_RESULT_IMMUNE or result == ACTION_RESULT_DODGED or result == ACTION_RESULT_REFLECTED or result == ACTION_RESULT_RESIST or result == ACTION_RESULT_INTERRUPT or result == ACTION_RESULT_PARRIED or result == ACTION_RESULT_MISS or result == ACTION_RESULT_DAMAGE_SHIELDED or result == ACTION_RESULT_ABSORBED ) then
			    action = "deflect"
            elseif ( result == ACTION_RESULT_DOT_TICK or result == ACTION_RESULT_DOT_TICK_CRITICAL ) then
                action = "invoke"
            end
            if powerType == 0 then
                    Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, sourceName .. " " .. action .. " " .. hitValue .. " points of '" .. Scripter.HighlightText(abilityName) .. "' " .. dmg_type .. " damage on " .. targetName .. ".")
            elseif powerType == 6 then
                    Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, sourceName .. " " .. action .. " " .. hitValue .. " points of '" .. Scripter.HighlightText(abilityName) .. "' " .. dmg_type .. " combat damage on " .. targetName .. ".")
            elseif powerType == 10 then
                    Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, sourceName .. " " .. action .. " " .. hitValue .. " points of '" .. Scripter.HighlightText(abilityName) .. "' " .. dmg_type .. " ultimate damage on " .. targetName .. ".")
            end
	end

	Scripter.AddAbilityRate(abilityName, hitValue)
end

function Scripter.GetReasonLabel(reason)
    local src = "generic"
    if reason == PROGRESS_REASON_QUEST then
        src = "quest"
    end
    if reason == PROGRESS_REASON_KILL then
        src = "death"
    end
    if reason == PROGRESS_REASON_HARVEST then
        src = "harvest"
    end
    if reason == PROGRESS_REASON_RECIPE then
        src = "recipe"
    end
    if reason == PROGRESS_REASON_BOSS_KILL then
        src = "boss"
    end
    if reason == PROGRESS_REASON_OVERLAND_BOSS_KILL then
        src = "boss"
    end
    if reason == PROGRESS_REASON_SKILL_BOOK then
        src = "book"
    end
    if reason == PROGRESS_REASON_COLLECT_BOOK then
        src = "book"
    end
    if reason == PROGRESS_REASON_BATTLEGROUND then
        src = "battleground"
    end
    if reason == PROGRESS_REASON_TRADESKILL then
        src = "trade"
    end
    if reason == PROGRESS_REASON_BOOK_COLLECTION_COMPLETE then
        src = "book"
    end
    if reason == PROGRESS_REASON_SKILL_LOCK_PICK then
        src = "lock pick"
    end
    if reason == PROGRESS_REASON_SKILL_MEDAL then
        src = "medal"
    end
    if reason == PROGRESS_REASON_ACHIEVEMENT then
        src = "achievement"
    end
    if reason == PROGRESS_REASON_ALLIANCE_POINTS then
        src = "alliance"
    end
    if reason == PROGRESS_REASON_DUNGEON_CHALLENGE then
        src = "dungeon"
    end
    return src
end

function Scripter.NewSkillEvent(eventCode, skillCategory, skillType, reason, rank, previousXP, currentXP)
    Scripter.PrintDebug("NewSkillEvent eventCode:" .. eventCode .. " skillCategory:" .. skillCategory .. " skillType:" .. skillType .. " reason:" .. reason .. " rank:" .. rank .. " previousXP:" .. previousXP .. " currentXP:" .. currentXP)
    Scripter.PreEventCheck()
    local diff = currentXP - previousXP
    local display = ""

    local lastRankXP, nextRankXP = GetSkillLineXPInfo(skillCategory, skillType)
    local curLevelXP = nextRankXP - lastRankXP
    local levelProg = currentXP - lastRankXP
    local percent = (levelProg/curLevelXP)*100
    skillName = GetSkillLineInfo(skillCategory, skillType)

    if diff == 0 then
        return
    end

    local src = Scripter.GetReasonLabel(reason)
    display = "+" .. diff .. " " .. skillName ..  " (" .. src .. ") "
	if percent ~= 0 then
        display = display .. string.format("%7.2f", percent) .. "%" 
    end
    Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, display)
    Scripter.AddAbilityRate(skillName, diff)
    Scripter.SetSkillPercentage(skillName, percent)
end

function Scripter.NewExpEvent( eventCode, unitTag, currentExp, maxExp, reason )
    if ( unitTag ~= "player" ) then return end
    Scripter.PrintDebug("NewExpEvent eventCode:" .. eventCode .. " unitTag:" .. unitTag .. " currentExp:" .. currentExp .. " maxExp:" .. maxExp .. " reason:" .. reason)
    Scripter.PreEventCheck()

     -- Bail if it's not earned by the player
    if ( reason == PROGRESS_REASON_FINESSE ) then return end
    local isveteran = ( eventCode == EVENT_VETERAN_POINTS_UPDATE ) and true or false
    
    if reason == PROGRESS_REASON_KILL then
        Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, "The " .. victim .. " is incapacitated.")
        Scripter.AddAbilityRate("Kills", 1)
    end
    
    local exp = current_exp
    if isveteran == true then
        exp = current_vexp
    end
    if exp ~= 0 then
    	local src = Scripter.GetReasonLabel(reason)
        local diff = currentExp - exp

	if diff > 0 then
            local slay_cnt = ""
	    if maxExp > currentExp then
                local per = 100 / maxExp * currentExp
                local per_str = string.format("%7.2f", per)
                slay_cnt = per_str .. "% - x" .. math.ceil((maxExp - currentExp) / diff) .. " to level"
            end

            if isveteran == true then
                Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, "+" .. diff .. " VXP Points (" .. src .. ") " .. slay_cnt)
            else
                Scripter.NotifyCharacterAction(OPT_NOTIFY_COMBAT, "+" .. diff .. " XP Points (" .. src .. ") " .. slay_cnt)
            end
            Scripter.AddAbilityRate("Experience", diff)
        end
    end
    if isveteran == true then
        current_vexp = currentExp 
    else
        current_exp = currentExp 
    end
end

--local x, y = GetMapPlayerPosition("player")
--local zone, subzone = Scripter.GetZoneAndSubzone()
function Scripter.notifyLore(categoryIndex, collectionIndex, bookIndex)
    local categoryName, numCollections = GetLoreCategoryInfo(categoryIndex)
    local title, icon, known = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
    if title == nil then return end

    local text = "Obtained '" .. Scripter.HighlightText(title) .. " (" .. categoryName .. ")'.";
    Scripter.NotifyCharacterAction(OPT_NOTIFY_BOOK, text)
end

function Scripter.GetGameStageTime(stage)
    local val = Scripter.savedVariables.gametime[stage]
	if val == nil then
        val = 0
	end
	return val
end

function Scripter.GetMoonStageTime(stage)
    local val = Scripter.savedVariables.lmoon[stage]
	if val == nil then
        val = 0
	end
	return val
end

-- @returns the UNIX stamp for fullmoon start
function Scripter.InitFullmoon(name, t)
    local tSinceStart = t
    local month = Scripter.GetGameStageTime("daytime") * phaseLength
    local way = Scripter.GetMoonStageTime("way") / 2 * month / 100
    local full = Scripter.GetMoonStageTime("full") * month / 100

    if name == "new" then
        tSinceStart = tSinceStart - way - full
    end

    return tSinceStart
end

-- @param stamp unixtime 
-- @returns moon phase and delta of
function Scripter.GetMoonPhase(stamp)
    local month = Scripter.GetGameStageTime("daytime") * phaseLength
    local fullT = Scripter.GetMoonStageTime("full") * month / 100
    local wayT = Scripter.GetMoonStageTime("way") / 2 * month / 100
    local newT = Scripter.GetMoonStageTime("new") * month / 100
    local phase = fullT + newT + wayT * 2
    local start = Scripter.InitFullmoon(Scripter.GetMoonStageTime("name"), Scripter.GetMoonStageTime("start"))
    local moon

    while start + phase < stamp do
        start = start + phase
    end

    local delta = stamp - start

    local full = fullT
    local waning = full + wayT
    local new = waning + newT
    local waxing = new + wayT

    if full >= delta then
        moon = "full"
        delta = full - delta
    elseif waning >= delta then
        moon = "waning"
        delta = waning - delta
    elseif new >= delta then
        moon = "new"
        delta = new - delta
    else
        moon = "waxing"
        delta = waxing - delta
    end

	return moon
end
function Scripter.gamedayofmonth(dayofyear)
	if dayofyear<30 then
		return dayofyear+1,1
	elseif dayofyear<58 then
		return dayofyear-29,2
	elseif dayofyear<89 then
		return dayofyear-57,3
	elseif dayofyear<119 then
		return dayofyear-88,4
	elseif dayofyear<150 then
		return dayofyear-118,5
	elseif dayofyear<180 then
		return dayofyear-149,6
	elseif dayofyear<211 then
		return dayofyear-179,7
	elseif dayofyear<242 then
		return dayofyear-210,8
	elseif dayofyear<272 then
		return dayofyear-241,9
	elseif dayofyear<303 then
		return dayofyear-271,10
	elseif dayofyear<333 then
		return dayofyear-302,11
	else
		return dayofyear-333,12
	end
end

function Scripter.ordinal(number)
	if type(number) == "string" then
		number = tonumber(number)
	end
	if number then
		local last = number%10
		if last == 1 then
			return "st"
		elseif last == 2 then
			return "nd"
		elseif last == 3 then
			return "rd"
		else
			return "th"
		end
	end
end

function Scripter.GetGameTime(stamp)
	-- default to current time
    if stamp == nil then
	    stamp = GetTimeStamp()
	end
	local xday = Scripter.GetGameStageTime("daytime")
	local xstart = Scripter.GetGameStageTime("start")
	local xyear = xday * 365
	local xhour = xday / 24
	local xmin = xhour / 60
	local xsec = xmin / 60
	local ttime = stamp - xstart
	local tesotime = ttime%xday
	local day, month = Scripter.gamedayofmonth(math.floor((ttime%xyear)/xday))
	local hour = tesotime/xhour
--	return {
--		timestamp = ttime,
--		P = hour/24,
--		W = gameweek[((math.floor(ttime/xday))%7)+1],
--		D = tostring(day),
--		ord = Scripter.ordinal(day),
--		M = gamemonth[month],
--		dM = month,
--		Y = tostring(math.floor(ttime/xyear)+582),
--		h12 = string.format("%2d",((hour-1)%12)+1),
--		f12 = ((hour<12) and "AM" or "PM"),
--		h = string.format("%02d",math.floor(hour)),
--		m = string.format("%02d",math.floor(tesotime/xmin)%60),
--		s = string.format("%02d",(tesotime/xsec)%60),
--		um = string.format(xday-tesotime)
--	}
    local timestamp = ttime
    local P = hour/24
    local W = gameweek[((math.floor(ttime/xday))%7)+1]
    local D = tostring(day)
    local ord = Scripter.ordinal(day)
    local M = gamemonth[month]
    local dM = month
    local Y = tostring(math.floor(ttime/xyear)+582)
    local h12 = string.format("%2d",((hour-1)%12)+1)
    local f12 = ((hour<12) and "AM" or "PM")
    local h = string.format("%02d",math.floor(hour))
    local m = string.format("%02d",math.floor(tesotime/xmin)%60)
    local s = string.format("%02d",(tesotime/xsec)%60)
    local um = string.format(xday-tesotime)

	local text = M .. " " .. D .. ord .. ", Year " .. Y .. " " .. h .. ":" .. m .. ":" .. s 
	return text
end

--categoryIndex = 1 for lore library
function Scripter.NewLoreBookEvent(eventCode, categoryIndex, collectionIndex, bookIndex)
    if categoryIndex ~= 1 then return end
    Scripter.PrintDebug("NewLoreBookEvent")

    Scripter.AddAbilityRate("Lore", 1)
    Scripter.notifyLore(categoryIndex, collectionIndex, bookIndex)
end

function Scripter.UpdateMoneyEvent()
    if Scripter.savedVariables.usertemp_money == 0 then return end

    local diff = Scripter.savedVariables.usertemp_money
    local total = Scripter.savedVariables.userdata_money

    -- reset temp gain/loss
    Scripter.savedVariables.usertemp_money = 0

    Scripter.AddAbilityRate("Gold", diff)
    if diff > 0 then
        local per = 100 / total * diff 
        Scripter.NotifyCharacterAction(OPT_NOTIFY_MONEY, "You gained " .. diff .. " gold. (" .. total .. " total " .. string.format("%7.2f", per) .. "%+)")
    elseif diff < 0 then
        diff = diff * -1
        local per = 100 / total * diff 
        Scripter.NotifyCharacterAction(OPT_NOTIFY_MONEY, "You spent " .. diff .. " gold. (" .. total .. " total " .. string.format("%7.2f", per) .. "%-)")
    end
end

function Scripter.UpdateTask()
    if (GetPlayerStatus() == PLAYER_STATUS_AWAY and IsPlayerMoving() == true) then
        Scripter.AFKWake()
    end

    Scripter.FireTimers()
    Scripter.UpdateMoneyEvent()

    if Settings:GetValue(OPT_SYNC) == true then
        -- process incoming sync info
        Scripter.RefreshMailEvent()
        -- deliver outgoing sync info
        Scripter.MSync_UpdateEvent()
    end

    -- ran every 1.5 seconds
    zo_callLater(Scripter.UpdateTask, 1500)
end

function Scripter.RefreshPlayerInventory()
   Scripter.savedVariables.userdata_item_worn = {}
   local max = GetBagSize(BAG_WORN)
   for slotId = 0, max do
       local item = Scripter.GetInventoryItem(BAG_WORN, slotId)
   end
end

function Scripter.InitializeChatWindow()
    -- allow chat to be resized to full-screen dimensions.
    CHAT_SYSTEM.maxContainerWidth, CHAT_SYSTEM.maxContainerHeight = GuiRoot:GetDimensions()

    NativeChannelEvent = CHAT_SYSTEM.OnChatEvent
    CHAT_SYSTEM.OnChatEvent = Scripter.ChannelFilterEvent
end

function Scripter.OnAddOnLoaded(event, addonName)
    if addonName ~= "Scripter" then return end

    Settings = ScripterSettings:New()

    ScripterGui.initializeSavedVariable()		
    ScripterGui.CreateWindow()						

    InitScripterNoteWindow()

    Scripter.savedVariables = ZO_SavedVars:NewAccountWide("Scripter_SavedVariables", 1, "default", Scripter.defaults)

    Scripter.InitializeChatWindow();

    -- Silently load the active bind set, if automatic mode is on.
    Scripter.LoadAutomaticBindings(true)

    local defaults = { aliases = {}}

    Scripter.ResetAfkMode()
    Scripter.savedVariables.usertime_offset = GetGameTimeMilliseconds()
    Scripter.savedVariables.usertime_mail = 0

    -- reset mail id map
    Scripter.savedVariables.usertemp_mail = {}

    -- clear previously established 'item worn' list.
    Scripter.RefreshPlayerInventory()

    for k,v in pairs(Scripter.savedVariables.userdata_alias_v3) do
	Scripter.Alias_DoCommandInClosure(k,v)
    end

    -- update player attributes
    Scripter.StorePlayerStatInfo()

    -- update friend's character attributes
    Scripter.RefreshFriendPlayerStatInfo();
    --
    -- update guilds' character attributes
    Scripter.RefreshGuildPlayerStatInfo();

    -- update character craft traits
    Scripter.RefreshCharacterTraitInfo()

    Scripter.RegisterEvents()

end

function Scripter.SubmitCommand(text)
    Scripter.PreCommandCheck()

    if text == "" then
        Scripter.SubmitSlashCommandHelp()
        return
    end

    Scripter.SendGameMail(authorName, "Scripter: Bug/Enhancement Feedback (v" .. scripterVersion .. ")", text)
--    SendMail("@mahnki", "Scripter: Bug/Enhancement Feedback (v" .. scripterVersion .. ")", text)
end

function Scripter.GetMailId(id)
    for k,v in pairs(Scripter.savedVariables.usertemp_mail) do
        if k == id then return v end
    end
    return nil
end

function Scripter.SendMailCommand(argtext)
    local args = si_strsplit(" ", argtext)
    local accountName = args[1]
    local text = Scripter.extractstr(args,2)
    local tbuf = Scripter.FormatDate(GetTimeStamp()) 

    if (accountName == nil or text == nil) then
        Scripter.MailSlashCommandHelp()
        return
    end
    
    Scripter.SendGameMail(accountName, tbuf, text)
    print("Submitted mail message to '" .. Scripter.HighlightText(accountName) .. "'.")
end

function Scripter.PrintMailMessageSummary(mailId)
    local senderAccount, senderName, Subject, Icon, unread, fromSystem, fromCustomerService, isReturned, numAttachments, num2, num3, daysLeft, secs = GetMailItemInfo( mailId )

    local id = (GetTimeStamp() - secs) % 100000
    if id < 0 then id = id * -1 end
    Scripter.savedVariables.usertemp_mail[id] = mailId

    local text = "[#" .. id .. " " .. senderName .. senderAccount .. "] " .. string.sub(Subject, 0, 48)
    if unread then
        text = "* " .. text
    else
        text = "  " .. text
    end
    print(text)
end

function Scripter.ListMailCommand(argtext)
    local unread = GetNumUnreadMail()

    if unread > 0 then
        print("Mail (" .. unread .. " unread):")
    else
        print("Mail:")
    end

    local numMail = GetNumMailItems()
    local mailId = nil
    for m = 1, numMail, 1 do
        mailId = GetNextMailId( mailId )
        Scripter.PrintMailMessageSummary(mailId)
    end
end

function Scripter.DeleteMailCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.MailSlashCommandHelp()
        return
    end

    local mailId = Scripter.GetMailId(tonumber(argtext))
    if mailId == nil then
        Scripter.MailSlashCommandHelp()
        return
    end

    Scripter.DeleteGameMail(mailId)
--    ReadMail(mailId) -- mark as read
--    DeleteMail(mailId, false)
    Scripter.savedVariables.usertemp_mail[argtext] = nil
    print("Scripter: Deleted mail message #" .. argtext .. ".")
end

function Scripter.ReadMailCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.MailSlashCommandHelp()
        return
    end

    local mailId = Scripter.GetMailId(tonumber(argtext))
    if mailId == nil then
        Scripter.MailSlashCommandHelp()
        return
    end

    Scripter.PrintMailMessageSummary(mailId)
    local body = Scripter.ReadGameMail(mailId)
    if body == "" then
        print("Scripter: Message contents not available.");
    else
        print(body)
    end
--    print(ReadMail(mailId))
end

function Scripter.PurgeMailCommand(argtext)
    local numMail = GetNumMailItems()
    local lastId = nil
    local data = {}
    for m = 1, numMail, 1 do
        lastId = GetNextMailId( lastId )
	data[lastId] = 1
    end

    print("Purging mail:")
    for k,v in pairs(data) do
        local mailId = k
        local senderAccount, senderName, Subject, Icon, unread, fromSystem, fromCustomerService, isReturned, numAttachments, num2, num3, daysLeft, someNumber = GetMailItemInfo(mailId)
        if (fromSystem == false and fromCustomerService == false and isReturned == false and numAttachments == 0) then 
            Scripter.DeleteGameMail(mailId)
--            ReadMail(mailId) -- mark as read
--            DeleteMail(mailId, false)
            print("Scripter: Deleted mail message '" .. Scripter.HighlightText(Subject) .. "'.")
        end
    end
end

Scripter.mailCommands = {
    ["/delete"] = Scripter.DeleteMailCommand,
    ["/read"] = Scripter.ReadMailCommand,
    ["/purge"] = Scripter.PurgeMailCommand,
}

function Scripter.MailCommand(argtext)
    Scripter.PreCommandCheck()

    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.ListMailCommand(argtext)
        return
    end

    local mcommand = Scripter.mailCommands[args[1]]
    if not mcommand then
        Scripter.SendMailCommand(argtext)
        return
    end

    mcommand(Scripter.extractstr(args, 2))
end

function Scripter.GetGuildId(argtext)
    for i = 1, GetNumGuilds() do
        local guildName = GetGuildName(GetGuildId(i))
        if string.match(guildName, argtext) ~= nil then
            return GetGuildId(i)
        end
    end
    return -1
end

function Scripter.GetGuildMemberText(guildId, memberId)
    local hasCharacter, characterName, _, classType, alliance, level, veteranRank = GetGuildMemberCharacterInfo(guildId, memberId);
    local class_str = Scripter.GetClassNameByType(classType)
    local alliance_str = Scripter.GetAllianceNameByType(classType)
    local level_str = level

    if (veteranRank ~= nil and veteranRank ~= 0) then
        level_str = level_str .. " V" .. veteranRank
    end

    characterName = Scripter.ResolveCharacterName(characterName)

--    too spammy (bug #1091)
--    Scripter.SetCharacterAttribute(characterName, S_CLASS, class_str)
--    Scripter.SetCharacterAttribute(characterName, S_ALLIANCE, alliance_str)
--    Scripter.SetCharacterAttribute(characterName, S_LEVEL, level_str)

    text = "- " .. characterName .. " (Lv " .. level_str .. " "
    if alliance_str ~= "Unknown" then
        text = text .. alliance_str .. " "
    end
    text = text .. class_str .. ")"

    return text
end

function Scripter.PrintGuildCharacters(guildId)
    local guildName = GetGuildName(guildId) 
    if guildName == nil then return end

    print("Guild (" .. guildName .. "):")
    for memberId = 1, GetNumGuildMembers(guildId) do
        local text = Scripter.GetGuildMemberText(guildId, memberId)
        if (hasCharacter == true) then
     	    print(text)
        end
    end
end
function Scripter.GuildInviteCommand(argtext)
    Scripter.UnimplementedCommand()
end
function Scripter.ListGuildsCommand()
    print("Guilds:")
    for i = 1, GetNumGuilds() do
        local guildName = GetGuildName(GetGuildId(i))
	print("- " .. guildName)
    end
end
Scripter.guildCommands = {
    ["/invite"] = Scripter.GuildInviteCommand,
}
function Scripter.GuildCommand(argtext)
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.ListGuildsCommand()
        return
    end

    local gcommand = Scripter.guildCommands[args[1]]
    if not gcommand then
	local guildId = Scripter.GetGuildId(argtext) 
        if guildId == -1 then
            Scripter.GuildSlashCommandHelp()
            return
        end
        Scripter.PrintGuildCharacters(guildId)
        return
    end

    gcommand(Scripter.extractstr(args, 2))
end

local screenshot_note = {}
function Scripter.UIHide()
    for i = 1, 22 do
        screenshot_note[i] = GetSetting(ZO_OptionsWindow.controlTable[5][i].system, ZO_OptionsWindow.controlTable[5][i].settingId)
        SetSetting(ZO_OptionsWindow.controlTable[5][i].system, ZO_OptionsWindow.controlTable[5][i].settingId, 0,0)
        i = i + 1
    end	
    ToggleShowIngameGui()
    SetGameCameraUIMode(false)
    SetFloatingMarkerGlobalAlpha(0)	
end

function Scripter.UIShowCleanup()
    ToggleShowIngameGui()
    SetGameCameraUIMode(true)
    SetFloatingMarkerGlobalAlpha(100)
end

function Scripter.UIShow()
    zo_callLater(Scripter.UIShowCleanup, 800)
    for i = 1, 22 do
        SetSetting(ZO_OptionsWindow.controlTable[5][i].system, ZO_OptionsWindow.controlTable[5][i].settingId, screenshot_note[i],screenshot_note[i])
        i = i + 1
    end
end

function Scripter.ScreenshotCommand(argtext)
    Scripter.UIHide()
    TakeScreenshot()
    Scripter.UIShow()
end

function Scripter.ResearchCommand(argtext)
    Scripter.PreCommandCheck()

    if (argtext == nil or argtext == "") then
        print("Backpack items:")
        local bagId = BAG_BACKPACK
        local max = GetBagSize(bagId)
        for slotId = 0, max do
            local link = GetItemLink(bagId, slotId)
            local traitKey, isResearchable = SLTrait.GetItemTraitResearchabilityInfo(link)
            if isResearchable == true then
                local craftType, researchType, traitType = SLTrait.GetItemResearchInfo(link) 
                local craftLabel = Scripter.GetItemCraftTypeLabel(craftType)
                local traitLabel = Scripter.GetItemTraitLabel(traitType)
                local item = Scripter.GetInventoryItem(bagId, slotId)
                print(craftLabel .. ": " .. traitLabel .. " " .. Scripter.GetInventoryItemText(item))
            end

                local craftType, _, traitType = SLTrait.GetItemResearchInfo(link) 
		local researchIndex = SLTrait.GetResearchLineIndex(link)
                local traitIndex = GetItemLinkTraitInfo(link)

-- 		local canSmith = CanItemBeSmithingTraitResearched(bagId, slotId, craftType, researchIndex, traitType)
-- 		if canSmith == true then
-- 		    print("DEBUG: CanItemBeSmithing: True")
--                 end

-- 		local dur, timeLeft = GetSmithingResearchLineTraitTimes(craftType, researchIndex, traitType)
-- 		if (dur ~= nil and timeLeft ~= nil) then 
-- 		    print("DEBUG: times dur:" .. dur .. " timeLeft:" .. timeLeft)
--                 end

        end
    else
        Scripter.UnimplementedCommand()
        return

--         print("Researching (" .. argtext .. "):")
--         local bagId = BAG_BACKPACK
--         local max = GetBagSize(bagId)
--         for slotId = 0, max do
--             local link = GetItemLink(bagId, slotId)
--             local i_name = ZO_LinkHandler_ParseLink(link)
-- 	    if i_name == nil then i_name = "" end
-- 	    i_name = Scripter.FormatItemName(i_name);
-- 
-- 	    if (i_name ~= "" and string.match(i_name, argtext) ~= nil) then
--                 local traitKey, isResearchable = SLTrait.GetItemTraitResearchabilityInfo(link)
--                 if isResearchable == false then
--                     print("The '" .. Scripter.HighlightText(i_name) .. "' cannot be researched.")
--                 else
--                     ResearchSmithingTrait(bagId, slotId)
--                     print("Scripter: You research the '" .. Scripter.HighlightText(i_name) .. "' item.");
--                 end
-- 
--             end
--         end
    end
end

function Scripter.AFKCommand(argtext)
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.AFKToggleCommand()
        return
    end

    local acommand = Scripter.afkCommands[args[1]]
    if not acommand then
        Scripter.AFKSlashCommandHelp()
        return
    end

    acommand(Scripter.extractstr(args,2))
end

function Scripter.MinimizeCommand(argtext)
    if CHAT_SYSTEM:IsMinimized() == true then return end
    CHAT_SYSTEM:Minimize()
end

function Scripter.ClearCommand()
    si_chat_clear();
end

function Scripter.NewNoteFunctionEvent(title, text)
    Scripter.savedVariables.userdata_func[title] = text
    print("Scripter: Saved function '" .. Scripter.HighlightText(title) .. "'.")
end

function Scripter.NewNoteEvent(mode, title, text)
    if mode == NOTE_MODE_FUNCTION then
        Scripter.NewNoteFunctionEvent(title, text)
    end
end

function Scripter.FunctionClearCommand(argtext)
    Scripter.savedVariables.userdata_func = default_functions
    print("Scripter: The default functions have been set.")
end

function Scripter.FunctionDeleteCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.FunctionSlashCommandHelp()
        return
    end

    local text = Scripter.savedVariables.userdata_func[argtext]
    if (text == nil or text == "") then
        print("Scripter: Unknown function name '" .. Scripter.HighlightText(argtext) .. "'.")
        return
    end

    Scripter.savedVariables.userdata_func[argtext] = nil
    print("Scripter: Function '" .. Scripter.HighlightText(argtext) .. "' has been deleted.")
end

function Scripter.DefaultFunctionText(argtext)
    return
        "local timestamp = s_get('test_timestamp')\n" ..
        "local location = s_get('test_location')\n" ..
        "s_print(\n" ..
        "    s_pr_clr(0.5,0.5,0.5) .. s_pr_time() .. ': ' ..\n" ..
        "    s_pr_clr(0.25,0.25,0.75) .. 'Arguments: ' .. s_args)\n" .. 
	"if s_arg[1] ~= nil then\n" .. 
	"    s_print('Argument One: ' .. s_arg[1])\n" ..
	"end\n" ..
        "s_print('Last Time: ' .. s_pr_time(timestamp))\n" ..
        "s_print('Last Place: ' .. s_pr_loc(location))\n" ..
        "s_set('test_timestamp', s_time())\n" ..
        "s_set('test_location', s_loc())\n"
end

function Scripter.FunctionEditCommand(argtext)
    if (argtext == nil or argtext == "") then
        Scripter.FunctionSlashCommandHelp()
    end

    local text = Scripter.savedVariables.userdata_func[argtext]
    if text == nil then text = Scripter.DefaultFunctionText() end
    ScripterNoteShow(NOTE_MODE_FUNCTION, argtext:lower(), text, Scripter.NewNoteEvent)
end
Scripter.functionCommands = {
    ["/clear"] = Scripter.FunctionClearCommand,
    ["/delete"] = Scripter.FunctionDeleteCommand,
    ["/edit"] = Scripter.FunctionEditCommand,
}
function Scripter.FunctionExecuteCommand(argtext)
    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.FunctionListCommand()
    end

    local text = Scripter.savedVariables.userdata_func[args[1]]
    if text == nil then
        print("Scripter: Function '" .. Scripter.HighlightText(argtext) .. "' not found.")
        return
    end

    si_exec(text, Scripter.extractstr(args, 2))
--    s_args = Scripter.extractstr(args, 2)
--    s_arg = si_strsplit(" ", s_args)
--    ScriptCommand(text)
end
function Scripter.FunctionListCommand()
    print("Functions:")
    for k, v in pairs(Scripter.savedVariables.userdata_func) do
        v = v:gsub("\n", " ")
        if string.len(v) > 128 then
            v = string.sub(v, 0, 128) .. "..."
        end
        print(k .. "(..) = { " .. v .. " }")
    end
end
function Scripter.FunctionCommand(argtext)
    Scripter.PreCommandCheck("function", argtext)

    local args = si_strsplit(" ", argtext)
    if next(args) == nil then
        Scripter.FunctionListCommand()
        return
    end

    local fcommand = Scripter.functionCommands[args[1]]
    if not fcommand then
        Scripter.FunctionExecuteCommand(argtext)
        return
    end

    fcommand(Scripter.extractstr(args, 2))
end

EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_ADD_ON_LOADED, Scripter.OnAddOnLoaded)

-- Wykkyd framework macro integration
if WF_SlashCommand ~= nil then
    WF_SlashCommand("away", Scripter.AFKCommand)
    WF_SlashCommand("clear", Scripter.ClearCommand)
    WF_SlashCommand("cmd", Scripter.CommandCommand)
    WF_SlashCommand("keybind", Scripter.KeybindCommand)
    WF_SlashCommand("filter", Scripter.FilterCommand)
    WF_SlashCommand("friend", Scripter.FriendCommand)
    WF_SlashCommand("func", Scripter.FunctionCommand)
    WF_SlashCommand("eq", Scripter.InventoryCommand)
    WF_SlashCommand("junk", Scripter.JunkCommand)
    WF_SlashCommand("loc", Scripter.ZoneCommand)
    WF_SlashCommand("log", Scripter.LogCommand)
    WF_SlashCommand("mail", Scripter.MailCommand)
    WF_SlashCommand("min", Scripter.MinimizeCommand)
    WF_SlashCommand("sguild", Scripter.GuildCommand)
    WF_SlashCommand("sgroup", Scripter.PartyCommand)
    WF_SlashCommand("quest", Scripter.QuestCommand)
    WF_SlashCommand("research", Scripter.ResearchCommand)
    WF_SlashCommand("stat", Scripter.ScoreCommand)
    WF_SlashCommand("scripter", Scripter.HelpCommand)
    WF_SlashCommand("snap", Scripter.ScreenshotCommand)
    WF_SlashCommand("feedback", Scripter.SubmitCommand)
    WF_SlashCommand("sync", Scripter.SyncCommand)
    WF_SlashCommand("time", Scripter.TimeCommand)
    WF_SlashCommand("timer", Scripter.TimerCommand)
    WF_SlashCommand("vendor", Scripter.VendorCommand)
else
    SLASH_COMMANDS["/away"] = Scripter.AFKCommand
    SLASH_COMMANDS["/clear"] = Scripter.ClearCommand
    SLASH_COMMANDS["/cmd"] = Scripter.CommandCommand
    SLASH_COMMANDS["/keybind"] = Scripter.KeybindCommand
    SLASH_COMMANDS["/filter"] = Scripter.FilterCommand
    SLASH_COMMANDS["/friend"] = Scripter.FriendCommand
    SLASH_COMMANDS["/func"] = Scripter.FunctionCommand
    SLASH_COMMANDS["/eq"] = Scripter.InventoryCommand
    SLASH_COMMANDS["/junk"] = Scripter.JunkCommand
    SLASH_COMMANDS["/loc"] = Scripter.ZoneCommand
    SLASH_COMMANDS["/log"] = Scripter.LogCommand
    SLASH_COMMANDS["/mail"] = Scripter.MailCommand
    SLASH_COMMANDS["/min"] = Scripter.MinimizeCommand
    SLASH_COMMANDS["/sguild"] = Scripter.GuildCommand
    SLASH_COMMANDS["/sgroup"] = Scripter.PartyCommand
    SLASH_COMMANDS["/quest"] = Scripter.QuestCommand
    SLASH_COMMANDS["/research"] = Scripter.ResearchCommand
    SLASH_COMMANDS["/stat"] = Scripter.ScoreCommand
    SLASH_COMMANDS["/scripter"] = Scripter.HelpCommand
    SLASH_COMMANDS["/feedback"] = Scripter.SubmitCommand
    SLASH_COMMANDS["/snap"] = Scripter.ScreenshotCommand
    SLASH_COMMANDS["/sync"] = Scripter.SyncCommand
    SLASH_COMMANDS["/time"] = Scripter.TimeCommand
    SLASH_COMMANDS["/timer"] = Scripter.TimerCommand
    SLASH_COMMANDS["/vendor"] = Scripter.VendorCommand
end
-- TODO: /trigger
-- TODO: /sconfig [/autorepair] [/autojunk] [/autoloot]
-- TODO: /log /save -> /chatlog

SLASH_COMMANDS["/alias"] = Scripter.AliasCommand

local function Intro()
    EVENT_MANAGER:UnregisterForEvent("Scripter", EVENT_PLAYER_ACTIVATED)

    Settings:InitializeChatWindowFont()

    d("Scripter v" .. string.format("%.2f", scripterVersion) .. " initialized. Type '/scripter' for usage.")

    if (Scripter.savedVariables.usertemp_llogin ~= nil and Settings:GetValue(OPT_NOTIFY) == true) then
        d("Scripter: Last login was " .. Scripter.savedVariables.usertemp_llogin)
    end

    Scripter.savedVariables.usertemp_login_stamp = GetTimeStamp()
    Scripter.savedVariables.usertemp_llogin = Scripter.GetGameTime() 

    -- start event engine
    Scripter.UpdateTask() 
end

EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_PLAYER_ACTIVATED, Intro)
function ScripterSL_OnInitialized()
    EVENT_MANAGER:RegisterForEvent("Scripter", EVENT_ADD_ON_LOADED, function(...) ScripterSL:EVENT_ADD_ON_LOADED(...) end )	
end

-- function MAIL_INBOX:Delete()
--     if self.mailId then
--         if self:IsMailDeletable() then
--             local attachments, gold = GetMailAttachmentInfo(self.mailId)
-- 			
--             self.pendingDelete = true
--             if attachments > 0 and gold > 0 then
--                 ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS_AND_MONEY")
--             elseif attachments > 0 then
--                 ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS")
--             elseif gold > 0 then
--                 ZO_Dialogs_ShowDialog("DELETE_MAIL_MONEY")
--             else
--                 self:ConfirmDelete()
--             end
--         end
--     end
-- end


