ScripterSettings = ZO_Object:Subclass()

local LAM = LibStub("LibAddonMenu-2.0")

OPT_AFK_ACTION = "afk_action"
OPT_AUTOACCEPT = "autoaccept"
OPT_AUTOBIND = "autobind"
OPT_DEBUG = "debug"
OPT_FADEOUT = "fadeout"
OPT_JUNKMODE = "junkmode"
OPT_LOG_MAX = "log_line_max"
OPT_CHAT_FOCUS = "chat_focus"
OPT_CHAT_MAX = "chat_max"
OPT_AUTOAFK = "autoafk"
OPT_CHAT_SUPPRESS = "chat_suppress"
OPT_NOTIFY_WIN = "notify_win"
OPT_NOTIFY_BOOK = "notify_book"
OPT_NOTIFY_MONEY = "notify_money"
OPT_NOTIFY_INVENTORY = "notify_inventory"
OPT_NOTIFY_COMBAT = "notify_combat"
OPT_NOTIFY_EFFECT = "notify_effect"
OPT_NOTIFY_MISC = "notify_misc"
OPT_NOTIFY_FADE_DELAY = "notify_fade_delay"
OPT_NOTIFY_BG = "notify_bg"
OPT_NOTIFY_MAX = "notify_max"
OPT_NOTIFY_FONT = "notify_font"
OPT_NOTIFY_FONT_SIZE = "notify_font_size"
OPT_SYNC = "sync"
OPT_SYNC_ITEM = "sync_item"
OPT_SYNC_DELETE = "sync_delete"
OPT_SYNC_QUEST = "sync_quest"
OPT_SYNC_SKILL = "sync_skill"
OPT_SYNC_CRAFT = "sync_craft"
OPT_CHAT_FONT = "chat_font_name"
OPT_CHAT_FONT_SIZE = "chat_font_size"
OPT_CMD_FEEDBACK = "cmd_feedback"
OPT_CMD_AFK = "cmd_afk"

local settings = { }

local default_settings = {
    [OPT_AFK_ACTION] = "<none>",
    [OPT_AUTOACCEPT] = true,
    [OPT_AUTOBIND] = true,
    [OPT_CHAT_FONT] = "Univers 57",
    [OPT_CHAT_FONT_SIZE] = 14.5,
    [OPT_DEBUG] = false,
    [OPT_FADEOUT] = 15,
    [OPT_JUNKMODE] = true,
    [OPT_LOG_MAX] = 40,
    [OPT_CHAT_FOCUS] = true,
    [OPT_CHAT_MAX] = 50,
    [OPT_AUTOAFK] = false,
    [OPT_CHAT_SUPPRESS] = false,
    [OPT_NOTIFY_WIN] = true,
    [OPT_NOTIFY_BOOK] = true,
    [OPT_NOTIFY_MONEY] = true,
    [OPT_NOTIFY_INVENTORY] = true,
    [OPT_NOTIFY_COMBAT] = true,
    [OPT_NOTIFY_EFFECT] = true,
    [OPT_NOTIFY_MISC] = true,
    [OPT_NOTIFY_FADE_DELAY] = 15,
    [OPT_NOTIFY_BG] = true,
    [OPT_NOTIFY_MAX] = 64,
    [OPT_NOTIFY_FONT] = "Univers 57",
    [OPT_NOTIFY_FONT_SIZE] = 14,
    [OPT_SYNC] = true,
    [OPT_SYNC_DELETE] = true,
    [OPT_SYNC_QUEST] = false,
    [OPT_SYNC_ITEM] = false,
    [OPT_SYNC_CRAFT] = true,
    [OPT_SYNC_SKILL] = true,
    [OPT_CMD_FEEDBACK] = "sfeedback",
    [OPT_CMD_AFK] = "away",
}

local settingsLabel = {
    [OPT_AFK_ACTION] = "Set AFK command action.",
    [OPT_AUTOACCEPT] = "Automatically accept invitations from friends.",
    [OPT_AUTOBIND] = "Automatic character bindings",
    [OPT_DEBUG] = "Display ongoing game events.",
    [OPT_FADEOUT] = "Number of seconds before notification window fades out.",
    [OPT_JUNKMODE] = "Enable persistent junk management.",
    [OPT_LOG_MAX] = "Number of character log lines to list.",
    [OPT_CHAT_FONT] = "The font to render text in the chat window.",
    [OPT_CHAT_FONT_SIZE] = "The font size to display text in the chat window.",
    [OPT_CHAT_FOCUS] = "Retain focus after a command is performed.",
    [OPT_CHAT_MAX] = "Number of chat log lines to list.",
    [OPT_AUTOAFK] = "Transition to 'Online' character mode when active.",
    [OPT_CHAT_SUPPRESS] = "Disable incoming chat when in 'Do Not Disturb' mode.",
    [OPT_NOTIFY_WIN] = "Enable automatic text notification window.",
    [OPT_NOTIFY_BOOK] = "Enable automatic book notifications.",
    [OPT_NOTIFY_MONEY] = "Enable automatic monetary notifications.",
    [OPT_NOTIFY_INVENTORY] = "Enable automatic inventory notifications.",
    [OPT_NOTIFY_COMBAT] = "Enable automatic combat notifications.",
    [OPT_NOTIFY_EFFECT] = "Enable automatic effect notifications.",
    [OPT_NOTIFY_MISC] = "Enable automatic miscellaneous notifications.",
    [OPT_NOTIFY_FADE_DELAY] = "Seconds before notification window fades out.",
    [OPT_NOTIFY_BG] = "Enable a black background behind the notification text.",
    [OPT_NOTIFY_MAX] = "Set the number of scroll lines.",
    [OPT_NOTIFY_FONT] = "The font to render text in the notification window.",
    [OPT_NOTIFY_FONT_SIZE] = "The font size to display text in the notification window.",
    [OPT_SYNC] = "Enable automatic character attributes synchronization.",
    [OPT_SYNC_ITEM] = "Enable receiving of character item information.",
    [OPT_SYNC_CRAFT] = "Enable receiving of craft trait information.",
    [OPT_SYNC_DELETE] = "Delete synchronization mail notifications.",
    [OPT_SYNC_QUEST] = "Enable receiving of character quest information.",
    [OPT_SYNC_SKILL] = "Enable receiving of character skill information.",
    [OPT_CMD_FEEDBACK] = "Set the feedback slash command name.",
    [OPT_CMD_AFK] = "Set the 'Away from Keyboard' slash command name.",
}

local fontFilePath = {
    ["Consolas"] = "EsoUI/Common/Fonts/consola.ttf",
    ["Futura Condensed"] = "EsoUI/Common/Fonts/futurastd-condensed.otf",
    ["Futura Light"] = "EsoUI/Common/Fonts/futurastd-condensedlight.otf",
    ["ProseAntique"] = "EsoUI/Common/Fonts/ProseAntiquePSMT.otf",
    ["Skyrim Handwritten"] = "EsoUI/Common/Fonts/Handwritten_Bold.otf",
    ["Trajan Pro"] = "EsoUI/Common/Fonts/trajanpro-regular.otf",
    ["Univers 55"] = "EsoUI/Common/Fonts/univers55.otf",
    ["Univers 57"] = "EsoUI/Common/Fonts/univers57.otf",
    ["Univers 67"] = "EsoUI/Common/Fonts/univers67.otf",
}

function ScripterSettings:GetFontNames()
    local names = {}
    for k, v in pairs(fontFilePath) do
        table.insert(names, k)
    end
    return names
end

function ScripterSettings:GetFont(name)
    return fontFilePath[name]
end

function ScripterSettings:GetValue(name)
    return settings[name]
end

function ScripterSettings:SetValue(name, value)
    settings[name] = value
end

function ScripterSettings:GetOptions()
    return settings
end

function ScripterSettings:InitializeChatWindowFont()
    -- set the default CHAT window font size. 
    local font_type = self:GetValue(OPT_CHAT_FONT)
    local font_size = self:GetValue(OPT_CHAT_FONT_SIZE)
    -- chat history list
    CHAT_SYSTEM:SetFontSize(tonumber(font_size))
    -- entry textfield
    font_size = font_size - 0.25
    ZO_ChatWindowTextEntryEditBox:SetFont(string.format( "%s|%d|%s", 
        self:GetFont(font_type), font_size, "soft-shadow-thin")); 
    font_size = font_size - 0.25
    ZO_ChatWindowTextEntryLabel:SetFont(string.format( "%s|%d|%s",
        self:GetFont(font_type), font_size, "soft-shadow-thin")); 
end

function ScripterSettings:CreateOptionsMenu()
    local panel = {
        type = "panel",
        name = "Scripter",
        author = "Neo Natura",
        version = scripterVersion,
        slashCommand = "/sconfig",
        registerForRefresh = true
    }

    local optionsData = {
        [1] = {
            type = "header",
            name = "Synchronization",
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
            type = "header",
            name = "Notifications",
        },
        [9] = {
            type = "checkbox",
            name = "Notification Window",
            tooltip = settingsLabel[OPT_NOTIFY_WIN],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_WIN)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_WIN, value)
		if value == false then
		    self:SetValue(OPT_NOTIFY_BG, false)
                    ScripterGui.setBackgroundHidden(true)
                end
            end
        },
        [10] = {
            type = "checkbox",
            name = "Window Background",
            tooltip = settingsLabel[OPT_NOTIFY_BG],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_BG)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_BG, value)
                if value == true then
                    ScripterGui.setBackgroundHidden(false)
                else
                    ScripterGui.setBackgroundHidden(true)
                end
            end
        },
        [11] = {
            type = "slider",
            name = "Fade Out Time (seconds)",
	    min = 1,
            max = 60,
            tooltip = settingsLabel[OPT_NOTIFY_FADE_DELAY],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_FADE_DELAY)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_FADE_DELAY, value)
		ScripterGui.setFadeDelay(value)
            end
        },
        [12] = {
            type = "slider",
            name = "Notification History (lines)",
	    min = 10,
            max = 1000,
            tooltip = settingsLabel[OPT_NOTIFY_MAX],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_MAX)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_MAX, value)
		ScripterGui.setBufferMax()
            end
        },
        [13] = {
            type = "dropdown",
            name = "Notification Window Text Font",
            tooltip = settingsLabel[OPT_NOTIFY_FONT],
	    choices = self:GetFontNames(),
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_FONT)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_FONT, value)
                ScripterGui.setTextFont()
            end
        },
        [14] = {
            type = "slider",
            name = "Notification Window Font Size",
	    min = 6,
            max = 24,
            tooltip = settingsLabel[OPT_NOTIFY_FONT_SIZE],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_FONT_SIZE)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_FONT_SIZE, value)
                ScripterGui.setTextFont()
            end
        },
        [15] = {
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
        [16] = {
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
        [17] = {
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
        [18] = {
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
        [19] = {
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
        [20] = {
            type = "checkbox",
            name = "Miscellaneous Notifications",
            tooltip = settingsLabel[OPT_NOTIFY_MISC],
            getFunc = function() 
	    	return self:GetValue(OPT_NOTIFY_MISC)
            end,
            setFunc = function(value)
                self:SetValue(OPT_NOTIFY_MISC, value)
            end
        },
        [21] = {
            type = "header",
            name = "Triggers",
        },
        [22] = {
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
        [23] = {
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
        [24] = {
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
        [25] = {
            type = "dropdown",
            name = "AFK Action Command",
	    choices = { "<none>", "bored", "dance", "faint", "goaway", "juggleflame", "kick", "laugh", "leanbackcoin", "phew", "playdead", "sigh", "sit", "spit", "surprised", "tilt", "yawn", "wave", },
            tooltip = settingsLabel[OPT_AFK_ACTION],
            getFunc = function() 
	    	return self:GetValue(OPT_AFK_ACTION)
            end,
            setFunc = function(value)
                self:SetValue(OPT_AFK_ACTION, value)
            end
        },
        [26] = {
            type = "header",
            name = "Character Log",
        },
        [27] = {
            type = "slider",
            name = "Log History Lines",
	    min = 1,
            max = 500,
            tooltip = settingsLabel[OPT_LOG_MAX],
            getFunc = function() 
	    	return self:GetValue(OPT_LOG_MAX)
            end,
            setFunc = function(value)
                self:SetValue(OPT_LOG_MAX, value)
            end
        },
        [28] = {
            type = "header",
            name = "Chat Window",
        },
        [29] = {
            type = "checkbox",
            name = "Retain Command Focus",
            tooltip = settingsLabel[OPT_CHAT_FOCUS],
            getFunc = function() 
	    	return self:GetValue(OPT_CHAT_FOCUS)
            end,
            setFunc = function(value)
                self:SetValue(OPT_CHAT_FOCUS, value)
            end
        },
        [30] = {
            type = "slider",
            name = "Chat History Lines",
	    min = 1,
            max = 500,
            tooltip = settingsLabel[OPT_CHAT_MAX],
            getFunc = function() 
	    	return self:GetValue(OPT_CHAT_MAX)
            end,
            setFunc = function(value)
                self:SetValue(OPT_CHAT_MAX, value)
            end
        },
        [31] = {
            type = "checkbox",
            name = "AFK: Auto go 'Online' when active.",
            tooltip = settingsLabel[OPT_AUTOAFK],
            getFunc = function() 
	    	return self:GetValue(OPT_AUTOAFK)
            end,
            setFunc = function(value)
                self:SetValue(OPT_AUTOAFK, value)
            end
        },
        [32] = {
            type = "checkbox",
            name = "Disable chat in 'Do not disturb' mode.",
            tooltip = settingsLabel[OPT_CHAT_SUPPRESS],
            getFunc = function() 
	    	return self:GetValue(OPT_CHAT_SUPPRESS)
            end,
            setFunc = function(value)
                self:SetValue(OPT_CHAT_SUPPRESS, value)
            end
        },
        [33] = {
            type = "slider",
            name = "Chat Window Font Size",
	    min = 6,
            max = 24,
            tooltip = settingsLabel[OPT_CHAT_FONT_SIZE],
            getFunc = function() 
	    	return self:GetValue(OPT_CHAT_FONT_SIZE)
            end,
            setFunc = function(value)
                self:SetValue(OPT_CHAT_FONT_SIZE, value)
                self:InitializeChatWindowFont()
            end
        },
        [34] = {
            type = "header",
            name = "Commands",
        },
        [35] = {
            type = "dropdown",
            name = "Feedback Command",
	    choices = { "sfeedback", "submit" },
            tooltip = settingsLabel[OPT_CMD_FEEDBACK],
            getFunc = function() 
	    	return self:GetValue(OPT_CMD_FEEDBACK)
            end,
            setFunc = function(value)
	    	local cmd_name = self:GetValue(OPT_CMD_FEEDBACK)
                self:SetValue(OPT_CMD_FEEDBACK, value)
		InitializeScripterFeedbackCommand(cmd_name)
            end
        },
        [36] = {
            type = "dropdown",
            name = "AFK Command",
	    choices = { "afk", "away", "busy" },
            tooltip = settingsLabel[OPT_CMD_AFK],
            getFunc = function() 
	    	return self:GetValue(OPT_CMD_AFK)
            end,
            setFunc = function(value)
		local cmd_name = self:GetValue(OPT_CMD_AFK)
                self:SetValue(OPT_CMD_AFK, value)
		InitializeScripterAFKCommand(cmd_name)
            end
        },
        [37] = {
            type = "header",
            name = "Diagnostics",
        },
        [38] = {
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


