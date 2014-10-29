-- Scripter (ESO Add-On)
-- Copyright 2014 Neo Natura

--local LMP = LibStub:GetLibrary("LibMediaProvider-1.0")
local ScripterLG = ZO_Object:Subclass()

ScripterGui = {
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
			--isBackgroundHidden = false,
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
--		font = {
--			name = "EsoUI/Common/Fonts/univers57.otf", 
--			height = "14",
--			style = ""
--		},
		minAlpha = 0,
		maxAlpha = 0.4,
		fadeInDelay = 0,
		--fadeOutDelay = 15000,
		fadeDuration = 1500,
		lineFadeTime = 5,
		lineFadeDuration = 3,
		timestamp = true,
	},
	fadeOutCheckOnUpdate = nil
}

-- retained persistent dimensions
local savedVars_ScripterGui = {}

function ScripterGui.setBufferMax()
    ScripterGui.window.TEXTBUFFER:SetMaxHistoryLines(Settings:GetValue(OPT_NOTIFY_MAX))
end

function ScripterGui.setTextFont()
    ScripterGui.window.TEXTBUFFER:SetFont(Settings:GetFont(Settings:GetValue(OPT_NOTIFY_FONT)) .. "|" .. Settings:GetValue(OPT_NOTIFY_FONT_SIZE) .. "|")
end

function ScripterGui.CreateWindow( )
	if ScripterGui.window.ID == nil then
		ScripterGui.window.ID = WINDOW_MANAGER:CreateTopLevelWindow("ScripterLG_TLW")
		ScripterGui.window.ID:SetAlpha(savedVars_ScripterGui.maxAlpha)
		ScripterGui.window.ID:SetMouseEnabled(true)		
		ScripterGui.window.ID:SetMovable( savedVars_ScripterGui.general.isMovable )
		ScripterGui.window.ID:SetClampedToScreen(true)
		ScripterGui.window.ID:SetDimensions( savedVars_ScripterGui.dimensions.width, savedVars_ScripterGui.dimensions.height )
		--if savedVars_ScripterGui.general.isBackgroundHidden then
		if Settings:GetValue(OPT_NOTIFY_BG) == false then
			ScripterGui.window.ID:SetResizeHandleSize(0)
		else
			ScripterGui.window.ID:SetResizeHandleSize(8)
		end
		ScripterGui.window.ID:SetDrawLevel(DL_BELOW) -- Set the order where it is drawn, higher is more in background ???
		ScripterGui.window.ID:SetDrawLayer(DL_BACKGROUND)
		ScripterGui.window.ID:SetDrawTier(DT_LOW)
		ScripterGui.window.ID:SetAnchor(
			savedVars_ScripterGui.anchor.point, 
			savedVars_ScripterGui.anchor.relativeTo, 
			savedVars_ScripterGui.anchor.relativePoint, 
			savedVars_ScripterGui.anchor.xPos, 
			savedVars_ScripterGui.anchor.yPos )	

		ScripterGui.window.ID:SetHidden(savedVars_ScripterGui.general.isHidden)

		ScripterGui.window.ID.isResizing = false		
				
		ScripterGui.window.TEXTBUFFER = WINDOW_MANAGER:CreateControl(nil, ScripterGui.window.ID, CT_TEXTBUFFER)	
		ScripterGui.window.TEXTBUFFER:SetLinkEnabled(true)
		ScripterGui.window.TEXTBUFFER:SetMouseEnabled(true)

                ScripterGui.setTextFont()
--		ScripterGui.window.TEXTBUFFER:SetFont(savedVars_ScripterGui.font.name.."|"..savedVars_ScripterGui.font.height.."|"..savedVars_ScripterGui.font.style)

		ScripterGui.window.TEXTBUFFER:SetClearBufferAfterFadeout(false)
		--ScripterGui.window.TEXTBUFFER:SetLineFade(savedVars_ScripterGui.lineFadeTime, savedVars_ScripterGui.lineFadeDuration)
		ScripterGui.window.TEXTBUFFER:SetLineFade(Settings:GetValue(OPT_NOTIFY_FADE_DELAY), savedVars_ScripterGui.lineFadeDuration)
		ScripterGui.setBufferMax()
		ScripterGui.window.TEXTBUFFER:SetDimensions(savedVars_ScripterGui.dimensions.width-64, savedVars_ScripterGui.dimensions.height-64)
		ScripterGui.window.TEXTBUFFER:SetAnchor(TOPLEFT,ScripterGui.window.ID,TOPLEFT,32,32)
	
		ScripterGui.window.BACKDROP = WINDOW_MANAGER:CreateControl(nil, ScripterGui.window.ID, CT_BACKDROP)
		ScripterGui.window.BACKDROP:SetCenterTexture([[/esoui/art/chatwindow/chat_bg_center.dds]], 16, 1)
		ScripterGui.window.BACKDROP:SetEdgeTexture([[/esoui/art/chatwindow/chat_bg_edge.dds]], 32, 32, 32, 0)
		ScripterGui.window.BACKDROP:SetInsets(32,32,-32,-32)	
		ScripterGui.window.BACKDROP:SetAnchorFill(ScripterGui.window.ID)
		--ScripterGui.window.BACKDROP:SetHidden(savedVars_ScripterGui.general.isBackgroundHidden)
		if Settings:GetValue(OPT_NOTIFY_BG) == true then
		    ScripterGui.window.BACKDROP:SetHidden(false)
                else
		    ScripterGui.window.BACKDROP:SetHidden(true)
                end
	
		if not savedVars_ScripterGui.general.isMovable then
			ScripterGui.FadeOut()
		end

		ScripterGui.window.TEXTBUFFER:SetHandler( "OnLinkMouseUp", function(self, _, link, button, ...)
			return ZO_LinkHandler_OnLinkMouseUp(link, button, self) 
		end) 
	

		ScripterGui.window.TEXTBUFFER:SetHandler( "OnMouseEnter", function(self, ...) 
			ScripterGui.FadeIn()

    		ScripterGui.window.TEXTBUFFER:ShowFadedLines()

    		ScripterGui.MonitorForMouseExit()
		end )

		ScripterGui.window.ID:SetHandler( "OnMouseExit" , function(self, ...) 
			ScripterGui.MonitorForMouseExit()
		end )

		ScripterGui.window.ID:SetHandler( "OnResizeStart" , function(self, ...) 
			self.isResizing = true
		end )

		ScripterGui.window.ID:SetHandler( "OnResizeStop" , function(self, ...) 
			savedVars_ScripterGui.dimensions.width, savedVars_ScripterGui.dimensions.height = self:GetDimensions()
			ScripterGui.window.TEXTBUFFER:SetDimensions(savedVars_ScripterGui.dimensions.width-64, savedVars_ScripterGui.dimensions.height-64)
			self.isResizing = false
		end )

		ScripterGui.window.ID:SetHandler( "OnMoveStop" , function(self, ...) 
			local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ScripterGui.window.ID:GetAnchor()
			if isValidAnchor then
				savedVars_ScripterGui.anchor.point = point
				savedVars_ScripterGui.anchor.relativeTo = relativeTo
				savedVars_ScripterGui.anchor.relativePoint = relativePoint
				savedVars_ScripterGui.anchor.xPos = offsetX
				savedVars_ScripterGui.anchor.yPos = offsetY
				ScripterGui.window.ID:ClearAnchors()
				ScripterGui.window.ID:SetAnchor(
					savedVars_ScripterGui.anchor.point, 
					savedVars_ScripterGui.anchor.relativeTo, 
					savedVars_ScripterGui.anchor.relativePoint, 
					savedVars_ScripterGui.anchor.xPos, 
					savedVars_ScripterGui.anchor.yPos )
			end
		end )
		
		ScripterGui.window.ID:SetHandler( "OnMouseWheel", function(self, ...)  
			ScripterGui.window.TEXTBUFFER:MoveScrollPosition(...) 
		end )
		--
		-- If the loot window is hidden do not add it to the scene manager (it would pop up back otherwise)
		-- If we dont want to hide in dialogs, dont add it to the scene manager
		--
		--local fragment = ZO_FadeSceneFragment:New( ScripterGui.window.ID )
		local fragment = ZO_SimpleSceneFragment:New( ScripterGui.window.ID )

		if not savedVars_ScripterGui.general.isHidden and savedVars_ScripterGui.general.hideInDialogs then
			SCENE_MANAGER:GetScene('hud'):AddFragment( fragment )	
			SCENE_MANAGER:GetScene('hudui'):AddFragment( fragment )
		end
	end
end

function ScripterGui.FadeOut()
	if Settings:GetValue(OPT_NOTIFY_BG) then
		if not ScripterGui.window.BACKDROP.fadeAnim then
			ScripterGui.window.BACKDROP.fadeAnim = ZO_AlphaAnimation:New(ScripterGui.window.BACKDROP)
		end
		ScripterGui.window.BACKDROP.fadeAnim:SetMinMaxAlpha(savedVars_ScripterGui.minAlpha, savedVars_ScripterGui.maxAlpha)
		--ScripterGui.window.BACKDROP.fadeAnim:FadeOut(savedVars_ScripterGui.fadeOutDelay, savedVars_ScripterGui.fadeDuration)
		ScripterGui.window.BACKDROP.fadeAnim:FadeOut(Settings:GetValue(OPT_NOTIFY_FADE_DELAY), savedVars_ScripterGui.fadeDuration)
	end
end

function ScripterGui.FadeIn()
    if Settings:GetValue(OPT_NOTIFY_BG) == true then
       	if not ScripterGui.window.BACKDROP.fadeAnim then
       		ScripterGui.window.BACKDROP.fadeAnim = ZO_AlphaAnimation:New(ScripterGui.window.BACKDROP)
       	end
		ScripterGui.window.BACKDROP.fadeAnim:SetMinMaxAlpha(savedVars_ScripterGui.minAlpha, savedVars_ScripterGui.maxAlpha)
    	ScripterGui.window.BACKDROP.fadeAnim:FadeIn(savedVars_ScripterGui.fadeInDelay * 1000, savedVars_ScripterGui.fadeDuration)
    end
end

function ScripterGui.IsMouseInside()
	if  MouseIsOver(ScripterGui.window.ID) or MouseIsOver(ScripterGui.window.TEXTBUFFER) or  MouseIsOver(ScripterGui.window.BACKDROP) then
        return true
    end
    
    return false
end

function ScripterGui.fadeOutCheckOnUpdate()
	if not ScripterGui.IsMouseInside() and not ScripterGui.window.ID.isResizing then 
		ScripterGui.FadeOut()
	end 
end
--
-- For some reason this OnUpdate is not working properly, forced to call this function
-- on Mouse exit of the main container ...
--
function ScripterGui.MonitorForMouseExit()
	ScripterGui.fadeOutCheckOnUpdate()
	--ScripterGui.window.ID:SetHandler("OnUpdate", ScripterGui.fadeOutCheckOnUpdate() )
end

function ScripterGui.setMovable(value)
	savedVars_ScripterGui.general.isMovable = value
	ScripterGui.window.ID:SetMovable(value)
end

function ScripterGui.getTimeTillLineFade()
	return savedVars_ScripterGui.lineFadeTime
end

function ScripterGui.setTimeTillLineFade(value)
	savedVars_ScripterGui.lineFadeTime = value
	ScripterGui.window.TEXTBUFFER:SetLineFade(savedVars_ScripterGui.lineFadeTime, savedVars_ScripterGui.lineFadeDuration)
end

function ScripterGui.setBackgroundHidden(value)
--	savedVars_ScripterGui.general.isBackgroundHidden = value
	ScripterGui.window.BACKDROP:SetHidden(value)
	--if savedVars_ScripterGui.general.isBackgroundHidden then
	if Settings:GetValue(OPT_NOTIFY_BG) == false then
		ScripterGui.window.ID:SetResizeHandleSize(0)
	else
		ScripterGui.window.ID:SetResizeHandleSize(8)
	end
end

function ScripterGui.setFadeDelay(value)
--    ScripterGui.window.BACKDROP.fadeAnim:FadeOut(value, 1500)
    ScripterGui.window.TEXTBUFFER:SetLineFade(value, 3)
end

--function ScripterGui.isBackgroundHidden()
--	return savedVars_ScripterGui.general.isBackgroundHidden
--end

function ScripterGui.isMovable()
	return savedVars_ScripterGui.general.isMovable
end


function ScripterGui.HideInDialogs(value)
	savedVars_ScripterGui.general.hideInDialogs = value
end

function ScripterGui.isHiddenInDialogs()
    return savedVars_ScripterGui.general.hideInDialogs
end

function ScripterGui.setHidden(value)
    savedVars_ScripterGui.general.isHidden = value
    ScripterGui.window.ID:SetHidden(value)
end

function ScripterGui.Hide()
    if savedVars_ScripterGui.general.isHidden == false then
        ScripterGui.setHidden(true)
    end
end

function ScripterGui.Show()
    if savedVars_ScripterGui.general.isHidden == true then
        ScripterGui.setHidden(false)
    end
end

function ScripterGui.isHidden()
    return savedVars_ScripterGui.general.isHidden
end

function ScripterGui.isTimestampEnabled()
	return savedVars_ScripterGui.timestamp
end

function ScripterGui.setTimestampEnabled(value)
	savedVars_ScripterGui.timestamp = value
end

function ScripterGui.addMessage(message)
	if ScripterGui.window.TEXTBUFFER ~= nil then	
		if ScripterGui.isTimestampEnabled() then
			ScripterGui.window.TEXTBUFFER:AddMessage("|caaaaaa[" .. GetTimeString() .. "]|r " .. message)
		else
			ScripterGui.window.TEXTBUFFER:AddMessage(message)
		end
	end
end

function ScripterGui.initializeSavedVariable()
	savedVars_ScripterGui = ZO_SavedVars:New("ScripterGui_SavedVariables", 1, nil, ScripterGui.defaults)
end
