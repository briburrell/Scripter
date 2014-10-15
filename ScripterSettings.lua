ScripterSettings = ZO_Object:Subclass()

local LAM = LibStub("LibAddonMenu-2.0")

OPT_AFK = "afk"
OPT_AFK_ACTION = "afk_action"
OPT_AUTOACCEPT = "autoaccept"
OPT_AUTOBIND = "autobind"
OPT_DEBUG = "debug"
OPT_FADEOUT = "fadeout"
OPT_JUNKMODE = "junkmode"
OPT_LOG_MAX = "log_max"
OPT_NOTIFY = "notify"
OPT_NOTIFY_BOOK = "notify_book"
OPT_NOTIFY_MONEY = "notify_money"
OPT_NOTIFY_INVENTORY = "notify_inventory"
OPT_NOTIFY_COMBAT = "notify_combat"
OPT_NOTIFY_EFFECT = "notify_effect"
OPT_SYNC = "sync"
OPT_SYNC_ITEM = "sync_item"
OPT_SYNC_DELETE = "sync_delete"
OPT_SYNC_QUEST = "sync_quest"
OPT_SYNC_SKILL = "sync_skill"
OPT_SYNC_CRAFT = "sync_craft"

local settings = { }

local default_settings = {
    [OPT_AFK] = false,
    [OPT_AFK_ACTION] = "sit",
    [OPT_AUTOACCEPT] = true,
    [OPT_AUTOBIND] = true,
    [OPT_DEBUG] = false,
    [OPT_FADEOUT] = 15,
    [OPT_JUNKMODE] = true,
    [OPT_LOG_MAX] = 15,
    [OPT_NOTIFY] = true,
    [OPT_NOTIFY_BOOK] = true,
    [OPT_NOTIFY_MONEY] = true,
    [OPT_NOTIFY_INVENTORY] = true,
    [OPT_NOTIFY_COMBAT] = true,
    [OPT_NOTIFY_EFFECT] = true,
    [OPT_SYNC] = true,
    [OPT_SYNC_DELETE] = true,
    [OPT_SYNC_QUEST] = false,
    [OPT_SYNC_ITEM] = false,
    [OPT_SYNC_CRAFT] = true,
    [OPT_SYNC_SKILL] = true,
}

local settingsLabel = {
    [OPT_AFK_ACTION] = "Enable AFK character mode.",
    [OPT_AFK_ACTION] = "Set AFK command action.",
    [OPT_AUTOACCEPT] = "Automatically accept invitations from friends.",
    [OPT_AUTOBIND] = "Automatic character bindings",
    [OPT_DEBUG] = "Display ongoing game events.",
    [OPT_FADEOUT] = "Number of seconds before notification window fades out.",
    [OPT_JUNKMODE] = "Enable persistent junk management.",
    [OPT_LOG_MAX] = "Number of log lines to list.",
    [OPT_NOTIFY] = "Enable automatic text notification window.",
    [OPT_NOTIFY_BOOK] = "Enable automatic book notifications.",
    [OPT_NOTIFY_MONEY] = "Enable automatic monetary notifications.",
    [OPT_NOTIFY_INVENTORY] = "Enable automatic inventory notifications.",
    [OPT_NOTIFY_COMBAT] = "Enable automatic combat notifications.",
    [OPT_NOTIFY_EFFECT] = "Enable automatic effect notifications.",
    [OPT_SYNC] = "Enable automatic character attributes synchronization.",
    [OPT_SYNC_ITEM] = "Enable receiving of character item information.",
    [OPT_SYNC_CRAFT] = "Enable receiving of craft trait information.",
    [OPT_SYNC_DELETE] = "Delete synchronization mail notifications.",
    [OPT_SYNC_QUEST] = "Enable receiving of character quest information.",
    [OPT_SYNC_SKILL] = "Enable receiving of character skill information.",
}

function ScripterSettings:GetValue(name)
    return settings[name]
end

function ScripterSettings:SetValue(name, value)
    settings[name] = value
end

function ScripterSettings:GetOptions()
    return settings
end

function ScripterSettings:CreateOptionsMenu()
    local panel = {
        type = "panel",
        name = "Scripter",
        author = "Neo Natura",
        version = "1.91",
        slashCommand = "/sconfig",
        registerForRefresh = true
    }

    local optionsData = {
        [1] = {
            type = "header",
            name = "Scripter Settings",
        },
        [2] = {
            type = "checkbox",
            name = "Automatic Synchronization",
            tooltip = settingsLabel[OPT_SYNC],
            getFunc = function() 
	    	return self:GetValue(OPT_SYNC)
            end,
            setFunc = function(value)
                self:SetValue(OPT_SYNC, value)
            end
        },
        [3] = {
            type = "checkbox",
            name = "Delete Synchronization Notifications",
            tooltip = settingsLabel[OPT_SYNC_DELETE],
            getFunc = function() 
	    	return self:GetValue(OPT_SYNC_DELETE)
            end,
            setFunc = function(value)
                self:SetValue(OPT_SYNC_DELETE, value)
            end
        },
        [4] = {
            type = "checkbox",
            name = "Synchronize Skills",
            tooltip = settingsLabel[OPT_SYNC_SKILL],
            getFunc = function() 
	    	return self:GetValue(OPT_SYNC_SKILL)
            end,
            setFunc = function(value)
                self:SetValue(OPT_SYNC_SKILL, value)
            end
        },
        [5] = {
            type = "checkbox",
            name = "Synchronize Quests",
            tooltip = settingsLabel[OPT_SYNC_QUEST],
            getFunc = function() 
	    	return self:GetValue(OPT_SYNC_QUEST)
            end,
            setFunc = function(value)
                self:SetValue(OPT_SYNC_QUEST, value)
            end
        },
        [6] = {
            type = "checkbox",
            name = "Synchronize Items",
            tooltip = settingsLabel[OPT_SYNC_ITEM],
            getFunc = function() 
	    	return self:GetValue(OPT_SYNC_ITEM)
            end,
            setFunc = function(value)
                self:SetValue(OPT_SYNC_ITEM, value)
            end
        },
        [7] = {
            type = "checkbox",
            name = "Synchronize Traits",
            tooltip = settingsLabel[OPT_SYNC_CRAFT],
            getFunc = function() 
	    	return self:GetValue(OPT_SYNC_CRAFT)
            end,
            setFunc = function(value)
                self:SetValue(OPT_SYNC_CRAFT, value)
            end
        },
        [8] = {
            type = "checkbox",
            name = "Notification Window",
            tooltip = settingsLabel[OPT_NOTIFY],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY, value)
            end
        },
        [9] = {
            type = "checkbox",
            name = "Book Notifications",
            tooltip = settingsLabel[OPT_NOTIFY_BOOK],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_BOOK)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_BOOK, value)
            end
        },
        [10] = {
            type = "checkbox",
            name = "Money Notifications",
            tooltip = settingsLabel[OPT_NOTIFY_MONEY],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_MONEY)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_MONEY, value)
            end
        },
        [11] = {
            type = "checkbox",
            name = "Inventory Notifications",
            tooltip = settingsLabel[OPT_NOTIFY_INVENTORY],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_INVENTORY)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_INVENTORY, value)
            end
        },
        [12] = {
            type = "checkbox",
            name = "Combat Notifications",
            tooltip = settingsLabel[OPT_NOTIFY_COMBAT],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_COMBAT)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_COMBAT, value)
            end
        },
        [13] = {
            type = "checkbox",
            name = "Effect Notifications",
            tooltip = settingsLabel[OPT_NOTIFY_EFFECT],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_EFFECT)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_EFFECT, value)
            end
        },
        [14] = {
            type = "checkbox",
            name = "Auto Accept Invite",
            tooltip = settingsLabel[OPT_AUTOACCEPT],
            getFunc = function() 
	    	return self:GetValue(OPT_AUTOACCEPT)
            end,
            setFunc = function(value)
                self:SetValue(OPT_AUTOACCEPT, value)
            end
        },
        [15] = {
            type = "checkbox",
            name = "Automatic Keybindings",
            tooltip = settingsLabel[OPT_AUTOBIND],
            getFunc = function() 
	    	return self:GetValue(OPT_AUTOBIND)
            end,
            setFunc = function(value)
                self:SetValue(OPT_AUTOBIND, value)
            end
        },
        [16] = {
            type = "checkbox",
            name = "Remember Junk Items",
            tooltip = settingsLabel[OPT_JUNKMODE],
            getFunc = function() 
	    	return self:GetValue(OPT_JUNKMODE)
            end,
            setFunc = function(value)
                self:SetValue(OPT_JUNKMODE, value)
            end
        },
        [17] = {
            type = "slider",
            name = "Log Lines",
	    min = 1,
            max = 999,
            tooltip = settingsLabel[OPT_LOG_MAX],
            getFunc = function() 
	    	return self:GetValue(OPT_LOG_MAX)
            end,
            setFunc = function(value)
                self:SetValue(OPT_LOG_MAX, value)
            end
        },
        [18] = {
            type = "checkbox",
            name = "Debug Mode",
            tooltip = settingsLabel[OPT_DEBUG],
            getFunc = function() 
	    	return self:GetValue(OPT_DEBUG)
            end,
            setFunc = function(value)
                self:SetValue(OPT_DEBUG, value)
            end
        },
    }

    LAM:RegisterAddonPanel("ScripterSettingsPanel", panel)
    LAM:RegisterOptionControls("ScripterSettingsPanel", optionsData)

end
function ScripterSettings:New()
	local obj = ZO_Object.New(self)
	obj:Initialize()
	return obj
end

function ScripterSettings:Initialize()
    settings = ZO_SavedVars:NewAccountWide("ScripterSettings_SavedVariables", 1, "default", default_settings)
    self:CreateOptionsMenu()
end


