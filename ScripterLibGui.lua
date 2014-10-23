-- Scripter (ESO Add-On)
-- Copyright 2014 Neo Natura

--local LMP = LibStub:GetLibrary("LibMediaProvider-1.0")
local ScripterLG = ZO_Object:Subclass()

ScripterLibGui = { 
	window = {
		ID = nil,
		BACKDROP = nil,
		TEXTBUFFER = nil 
	},
	fontstyles = {
		" ",
		"soft-shadow-thick",
		"soft-shadow-thin"
	},
	defaults = {
		general = {
			isMovable = true,
			isHidden = false,
			isBackgroundHidden = false,
			hideInDialogs = false,
		},
		anchor = {
			point = TOPLEFT,
			relativeTo = GuiRoot,
			relativePoint = TOPLEFT,
			offsetX = 0,
			offsetY = 0
		},
		dimensions = {
			width = 540,
			height = 264
		},
		font = {
			name = "EsoUI/Common/Fonts/univers57.otf", 
		--	LMP:HashTable("font")["Univers 57"],
			height = "14",
			style = ""
		},
		minAlpha = 0,
		maxAlpha = 0.4,
		fadeInDelay = 0,
		fadeOutDelay = 15000,
		fadeDuration = 1500,
		lineFadeTime = 5,
		lineFadeDuration = 3,
		timestamp = true,
	},
	fadeOutCheckOnUpdate = nil
}

local savedVars_ScripterLibGui = {}

function ScripterLibGui.CreateWindow( )
	if ScripterLibGui.window.ID == nil then
		ScripterLibGui.window.ID = WINDOW_MANAGER:CreateTopLevelWindow("ScripterLG_TLW")
		ScripterLibGui.window.ID:SetAlpha(savedVars_ScripterlibGui.maxAlpha)
		ScripterLibGui.window.ID:SetMouseEnabled(true)		
		ScripterLibGui.window.ID:SetMovable( savedVars_ScripterlibGui.general.isMovable )
		ScripterLibGui.window.ID:SetClampedToScreen(true)
		ScripterLibGui.window.ID:SetDimensions( savedVars_ScripterlibGui.dimensions.width, savedVars_ScripterlibGui.dimensions.height )
		if savedVars_ScripterlibGui.general.isBackgroundHidden then
			ScripterLibGui.window.ID:SetResizeHandleSize(0)
		else
			ScripterLibGui.window.ID:SetResizeHandleSize(8)
		end
		ScripterLibGui.window.ID:SetDrawLevel(DL_BELOW) -- Set the order where it is drawn, higher is more in background ???
		ScripterLibGui.window.ID:SetDrawLayer(DL_BACKGROUND)
		ScripterLibGui.window.ID:SetDrawTier(DT_LOW)
		ScripterLibGui.window.ID:SetAnchor(
			savedVars_ScripterlibGui.anchor.point, 
			savedVars_ScripterlibGui.anchor.relativeTo, 
			savedVars_ScripterlibGui.anchor.relativePoint, 
			savedVars_ScripterlibGui.anchor.xPos, 
			savedVars_ScripterlibGui.anchor.yPos )	

		ScripterLibGui.window.ID:SetHidden(savedVars_ScripterlibGui.general.isHidden)

		ScripterLibGui.window.ID.isResizing = false		
				
		ScripterLibGui.window.TEXTBUFFER = WINDOW_MANAGER:CreateControl(nil, ScripterLibGui.window.ID, CT_TEXTBUFFER)	
		ScripterLibGui.window.TEXTBUFFER:SetLinkEnabled(true)
		ScripterLibGui.window.TEXTBUFFER:SetMouseEnabled(true)
		ScripterLibGui.window.TEXTBUFFER:SetFont(savedVars_ScripterlibGui.font.name.."|"..savedVars_ScripterlibGui.font.height.."|"..savedVars_ScripterlibGui.font.style)
		ScripterLibGui.window.TEXTBUFFER:SetClearBufferAfterFadeout(false)
		ScripterLibGui.window.TEXTBUFFER:SetLineFade(savedVars_ScripterlibGui.lineFadeTime, savedVars_ScripterlibGui.lineFadeDuration)
		ScripterLibGui.window.TEXTBUFFER:SetMaxHistoryLines(100)
		ScripterLibGui.window.TEXTBUFFER:SetDimensions(savedVars_ScripterlibGui.dimensions.width-64, savedVars_ScripterlibGui.dimensions.height-64)
		ScripterLibGui.window.TEXTBUFFER:SetAnchor(TOPLEFT,ScripterLibGui.window.ID,TOPLEFT,32,32)
	
		ScripterLibGui.window.BACKDROP = WINDOW_MANAGER:CreateControl(nil, ScripterLibGui.window.ID, CT_BACKDROP)
		ScripterLibGui.window.BACKDROP:SetCenterTexture([[/esoui/art/chatwindow/chat_bg_center.dds]], 16, 1)
		ScripterLibGui.window.BACKDROP:SetEdgeTexture([[/esoui/art/chatwindow/chat_bg_edge.dds]], 32, 32, 32, 0)
		ScripterLibGui.window.BACKDROP:SetInsets(32,32,-32,-32)	
		ScripterLibGui.window.BACKDROP:SetAnchorFill(ScripterLibGui.window.ID)
		ScripterLibGui.window.BACKDROP:SetHidden(savedVars_ScripterlibGui.general.isBackgroundHidden)
	
		if not savedVars_ScripterlibGui.general.isMovable then
			ScripterLibGui.FadeOut()
		end

		ScripterLibGui.window.TEXTBUFFER:SetHandler( "OnLinkMouseUp", function(self, _, link, button, ...)
			return ZO_LinkHandler_OnLinkMouseUp(link, button, self) 
		end) 
	

		ScripterLibGui.window.TEXTBUFFER:SetHandler( "OnMouseEnter", function(self, ...) 
			ScripterLibGui.FadeIn()

    		ScripterLibGui.window.TEXTBUFFER:ShowFadedLines()

    		ScripterLibGui.MonitorForMouseExit()
		end )

		ScripterLibGui.window.ID:SetHandler( "OnMouseExit" , function(self, ...) 
			ScripterLibGui.MonitorForMouseExit()
		end )

		ScripterLibGui.window.ID:SetHandler( "OnResizeStart" , function(self, ...) 
			self.isResizing = true
		end )

		ScripterLibGui.window.ID:SetHandler( "OnResizeStop" , function(self, ...) 
			savedVars_ScripterlibGui.dimensions.width, savedVars_ScripterlibGui.dimensions.height = self:GetDimensions()
			ScripterLibGui.window.TEXTBUFFER:SetDimensions(savedVars_ScripterlibGui.dimensions.width-64, savedVars_ScripterlibGui.dimensions.height-64)
			self.isResizing = false
		end )

		ScripterLibGui.window.ID:SetHandler( "OnMoveStop" , function(self, ...) 
			local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ScripterLibGui.window.ID:GetAnchor()
			if isValidAnchor then
				savedVars_ScripterlibGui.anchor.point = point
				savedVars_ScripterlibGui.anchor.relativeTo = relativeTo
				savedVars_ScripterlibGui.anchor.relativePoint = relativePoint
				savedVars_ScripterlibGui.anchor.xPos = offsetX
				savedVars_ScripterlibGui.anchor.yPos = offsetY
				ScripterLibGui.window.ID:ClearAnchors()
				ScripterLibGui.window.ID:SetAnchor(
					savedVars_ScripterlibGui.anchor.point, 
					savedVars_ScripterlibGui.anchor.relativeTo, 
					savedVars_ScripterlibGui.anchor.relativePoint, 
					savedVars_ScripterlibGui.anchor.xPos, 
					savedVars_ScripterlibGui.anchor.yPos )
			end
		end )
		
		ScripterLibGui.window.ID:SetHandler( "OnMouseWheel", function(self, ...)  
			ScripterLibGui.window.TEXTBUFFER:MoveScrollPosition(...) 
		end )
		--
		-- If the loot window is hidden do not add it to the scene manager (it would pop up back otherwise)
		-- If we dont want to hide in dialogs, dont add it to the scene manager
		--
		--local fragment = ZO_FadeSceneFragment:New( ScripterLibGui.window.ID )
		local fragment = ZO_SimpleSceneFragment:New( ScripterLibGui.window.ID )

		if not savedVars_ScripterlibGui.general.isHidden and savedVars_ScripterlibGui.general.hideInDialogs then
			SCENE_MANAGER:GetScene('hud'):AddFragment( fragment )	
			SCENE_MANAGER:GetScene('hudui'):AddFragment( fragment )
		end
	end
end

function ScripterLibGui.FadeOut()
	if not savedVars_ScripterlibGui.general.isBackgroundHidden then
		if not ScripterLibGui.window.BACKDROP.fadeAnim then
			ScripterLibGui.window.BACKDROP.fadeAnim = ZO_AlphaAnimation:New(ScripterLibGui.window.BACKDROP)
		end
		ScripterLibGui.window.BACKDROP.fadeAnim:SetMinMaxAlpha(savedVars_ScripterlibGui.minAlpha, savedVars_ScripterlibGui.maxAlpha)
		ScripterLibGui.window.BACKDROP.fadeAnim:FadeOut(savedVars_ScripterlibGui.fadeOutDelay, savedVars_ScripterlibGui.fadeDuration)
	end
end

function ScripterLibGui.FadeIn()
	if not savedVars_ScripterlibGui.general.isBackgroundHidden then
       	if not ScripterLibGui.window.BACKDROP.fadeAnim then
       		ScripterLibGui.window.BACKDROP.fadeAnim = ZO_AlphaAnimation:New(ScripterLibGui.window.BACKDROP)
       	end
		ScripterLibGui.window.BACKDROP.fadeAnim:SetMinMaxAlpha(savedVars_ScripterlibGui.minAlpha, savedVars_ScripterlibGui.maxAlpha)
    	ScripterLibGui.window.BACKDROP.fadeAnim:FadeIn(savedVars_ScripterlibGui.fadeInDelay, savedVars_ScripterlibGui.fadeDuration)
    end
end

function ScripterLibGui.IsMouseInside()
	if  MouseIsOver(ScripterLibGui.window.ID) or MouseIsOver(ScripterLibGui.window.TEXTBUFFER) or  MouseIsOver(ScripterLibGui.window.BACKDROP) then
        return true
    end
    
    return false
end

function ScripterLibGui.fadeOutCheckOnUpdate()
	if not ScripterLibGui.IsMouseInside() and not ScripterLibGui.window.ID.isResizing then 
		ScripterLibGui.FadeOut()
	end 
end
--
-- For some reason this OnUpdate is not working properly, forced to call this function
-- on Mouse exit of the main container ...
--
function ScripterLibGui.MonitorForMouseExit()
	ScripterLibGui.fadeOutCheckOnUpdate()
	--ScripterLibGui.window.ID:SetHandler("OnUpdate", ScripterLibGui.fadeOutCheckOnUpdate() )
end

function ScripterLibGui.setMovable(value)
	savedVars_ScripterlibGui.general.isMovable = value
	ScripterLibGui.window.ID:SetMovable(value)
end

function ScripterLibGui.getTimeTillLineFade()
	return savedVars_ScripterlibGui.lineFadeTime
end

function ScripterLibGui.setTimeTillLineFade(value)
	savedVars_ScripterlibGui.lineFadeTime = value
	ScripterLibGui.window.TEXTBUFFER:SetLineFade(savedVars_ScripterlibGui.lineFadeTime, savedVars_ScripterlibGui.lineFadeDuration)
end

function ScripterLibGui.setBackgroundHidden(value)
	savedVars_ScripterlibGui.general.isBackgroundHidden = value
	ScripterLibGui.window.BACKDROP:SetHidden(value)
	if savedVars_ScripterlibGui.general.isBackgroundHidden then
		ScripterLibGui.window.ID:SetResizeHandleSize(0)
	else
		ScripterLibGui.window.ID:SetResizeHandleSize(8)
	end
end

function ScripterLibGui.isBackgroundHidden()
	return savedVars_ScripterlibGui.general.isBackgroundHidden
end

function ScripterLibGui.isMovable()
	return savedVars_ScripterlibGui.general.isMovable
end


function ScripterLibGui.HideInDialogs(value)
	savedVars_ScripterlibGui.general.hideInDialogs = value
end

function ScripterLibGui.isHiddenInDialogs()
    return savedVars_ScripterlibGui.general.hideInDialogs
end

function ScripterLibGui.setHidden(value)
    savedVars_ScripterlibGui.general.isHidden = value
    ScripterLibGui.window.ID:SetHidden(value)
end

function ScripterLibGui.Hide()
    if savedVars_ScripterlibGui.general.isHidden == false then
        ScripterLibGui.setHidden(true)
    end
end

function ScripterLibGui.Show()
    if savedVars_ScripterlibGui.general.isHidden == true then
        ScripterLibGui.setHidden(false)
    end
end

function ScripterLibGui.isHidden()
    return savedVars_ScripterlibGui.general.isHidden
end

-- function ScripterLibGui.getDefaultFont()
-- 	for i,v in pairs(LMP:HashTable("font")) do
-- 		if v == savedVars_ScripterlibGui.font.name then
-- 			return i
-- 		end
-- 	end
-- end
-- 
-- function ScripterLibGui.setDefaultFont(value)
-- 	savedVars_ScripterlibGui.font.name = LMP:HashTable("font")[value]
-- end

function ScripterLibGui.setFontSize(value)
	savedVars_ScripterlibGui.font.height = value
end

function ScripterLibGui.getFontSize()
	return savedVars_ScripterlibGui.font.height
end

function ScripterLibGui.getFontStyles()
	return ScripterLibGui.fontstyles
end

function ScripterLibGui.getFontStyle()
	return savedVars_ScripterlibGui.font.style
end

function ScripterLibGui.setFontStyle(value)
	savedVars_ScripterlibGui.font.style = value
end

function ScripterLibGui.isTimestampEnabled()
	return savedVars_ScripterlibGui.timestamp
end

function ScripterLibGui.setTimestampEnabled(value)
	savedVars_ScripterlibGui.timestamp = value
end

function ScripterLibGui.addMessage(message)
	if ScripterLibGui.window.TEXTBUFFER ~= nil then	
		if ScripterLibGui.isTimestampEnabled() then
			ScripterLibGui.window.TEXTBUFFER:AddMessage("|caaaaaa[" .. GetTimeString() .. "]|r " .. message)
		else
			ScripterLibGui.window.TEXTBUFFER:AddMessage(message)
		end
	end
end

function ScripterLibGui.initializeSavedVariable()
	savedVars_ScripterlibGui = ZO_SavedVars:New("ScripterLibGui_SavedVariables", 1, nil, ScripterLibGui.defaults)
end
