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
local savedVars_ScripterLibGui = {}

function ScripterLibGui.setBufferMax()
    ScripterLibGui.window.TEXTBUFFER:SetMaxHistoryLines(Settings:GetValue(OPT_NOTIFY_MAX))
end

function ScripterLibGui.setTextFont()
    ScripterLibGui.window.TEXTBUFFER:SetFont(Settings:GetFont(Settings:GetValue(OPT_NOTIFY_FONT)) .. "|" .. Settings:GetValue(OPT_NOTIFY_FONT_SIZE) .. "|")
end

function ScripterLibGui.CreateWindow( )
	if ScripterLibGui.window.ID == nil then
		ScripterLibGui.window.ID = WINDOW_MANAGER:CreateTopLevelWindow("ScripterLG_TLW")
		ScripterLibGui.window.ID:SetAlpha(savedVars_ScripterLibGui.maxAlpha)
		ScripterLibGui.window.ID:SetMouseEnabled(true)		
		ScripterLibGui.window.ID:SetMovable( savedVars_ScripterLibGui.general.isMovable )
		ScripterLibGui.window.ID:SetClampedToScreen(true)
		ScripterLibGui.window.ID:SetDimensions( savedVars_ScripterLibGui.dimensions.width, savedVars_ScripterLibGui.dimensions.height )
		--if savedVars_ScripterLibGui.general.isBackgroundHidden then
		if Settings:GetValue(OPT_NOTIFY_BG) == false then
			ScripterLibGui.window.ID:SetResizeHandleSize(0)
		else
			ScripterLibGui.window.ID:SetResizeHandleSize(8)
		end
		ScripterLibGui.window.ID:SetDrawLevel(DL_BELOW) -- Set the order where it is drawn, higher is more in background ???
		ScripterLibGui.window.ID:SetDrawLayer(DL_BACKGROUND)
		ScripterLibGui.window.ID:SetDrawTier(DT_LOW)
		ScripterLibGui.window.ID:SetAnchor(
			savedVars_ScripterLibGui.anchor.point, 
			savedVars_ScripterLibGui.anchor.relativeTo, 
			savedVars_ScripterLibGui.anchor.relativePoint, 
			savedVars_ScripterLibGui.anchor.xPos, 
			savedVars_ScripterLibGui.anchor.yPos )	

		ScripterLibGui.window.ID:SetHidden(savedVars_ScripterLibGui.general.isHidden)

		ScripterLibGui.window.ID.isResizing = false		
				
		ScripterLibGui.window.TEXTBUFFER = WINDOW_MANAGER:CreateControl(nil, ScripterLibGui.window.ID, CT_TEXTBUFFER)	
		ScripterLibGui.window.TEXTBUFFER:SetLinkEnabled(true)
		ScripterLibGui.window.TEXTBUFFER:SetMouseEnabled(true)

                ScripterLibGui.setTextFont()
--		ScripterLibGui.window.TEXTBUFFER:SetFont(savedVars_ScripterLibGui.font.name.."|"..savedVars_ScripterLibGui.font.height.."|"..savedVars_ScripterLibGui.font.style)

		ScripterLibGui.window.TEXTBUFFER:SetClearBufferAfterFadeout(false)
		--ScripterLibGui.window.TEXTBUFFER:SetLineFade(savedVars_ScripterLibGui.lineFadeTime, savedVars_ScripterLibGui.lineFadeDuration)
		ScripterLibGui.window.TEXTBUFFER:SetLineFade(Settings:GetValue(OPT_NOTIFY_FADE_DELAY), savedVars_ScripterLibGui.lineFadeDuration)
		ScripterLibGui.setBufferMax()
		ScripterLibGui.window.TEXTBUFFER:SetDimensions(savedVars_ScripterLibGui.dimensions.width-64, savedVars_ScripterLibGui.dimensions.height-64)
		ScripterLibGui.window.TEXTBUFFER:SetAnchor(TOPLEFT,ScripterLibGui.window.ID,TOPLEFT,32,32)
	
		ScripterLibGui.window.BACKDROP = WINDOW_MANAGER:CreateControl(nil, ScripterLibGui.window.ID, CT_BACKDROP)
		ScripterLibGui.window.BACKDROP:SetCenterTexture([[/esoui/art/chatwindow/chat_bg_center.dds]], 16, 1)
		ScripterLibGui.window.BACKDROP:SetEdgeTexture([[/esoui/art/chatwindow/chat_bg_edge.dds]], 32, 32, 32, 0)
		ScripterLibGui.window.BACKDROP:SetInsets(32,32,-32,-32)	
		ScripterLibGui.window.BACKDROP:SetAnchorFill(ScripterLibGui.window.ID)
		--ScripterLibGui.window.BACKDROP:SetHidden(savedVars_ScripterLibGui.general.isBackgroundHidden)
		if Settings:GetValue(OPT_NOTIFY_BG) == true then
		    ScripterLibGui.window.BACKDROP:SetHidden(false)
                else
		    ScripterLibGui.window.BACKDROP:SetHidden(true)
                end
	
		if not savedVars_ScripterLibGui.general.isMovable then
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
			savedVars_ScripterLibGui.dimensions.width, savedVars_ScripterLibGui.dimensions.height = self:GetDimensions()
			ScripterLibGui.window.TEXTBUFFER:SetDimensions(savedVars_ScripterLibGui.dimensions.width-64, savedVars_ScripterLibGui.dimensions.height-64)
			self.isResizing = false
		end )

		ScripterLibGui.window.ID:SetHandler( "OnMoveStop" , function(self, ...) 
			local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ScripterLibGui.window.ID:GetAnchor()
			if isValidAnchor then
				savedVars_ScripterLibGui.anchor.point = point
				savedVars_ScripterLibGui.anchor.relativeTo = relativeTo
				savedVars_ScripterLibGui.anchor.relativePoint = relativePoint
				savedVars_ScripterLibGui.anchor.xPos = offsetX
				savedVars_ScripterLibGui.anchor.yPos = offsetY
				ScripterLibGui.window.ID:ClearAnchors()
				ScripterLibGui.window.ID:SetAnchor(
					savedVars_ScripterLibGui.anchor.point, 
					savedVars_ScripterLibGui.anchor.relativeTo, 
					savedVars_ScripterLibGui.anchor.relativePoint, 
					savedVars_ScripterLibGui.anchor.xPos, 
					savedVars_ScripterLibGui.anchor.yPos )
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

		if not savedVars_ScripterLibGui.general.isHidden and savedVars_ScripterLibGui.general.hideInDialogs then
			SCENE_MANAGER:GetScene('hud'):AddFragment( fragment )	
			SCENE_MANAGER:GetScene('hudui'):AddFragment( fragment )
		end
	end
end

function ScripterLibGui.FadeOut()
	if Settings:GetValue(OPT_NOTIFY_BG) then
		if not ScripterLibGui.window.BACKDROP.fadeAnim then
			ScripterLibGui.window.BACKDROP.fadeAnim = ZO_AlphaAnimation:New(ScripterLibGui.window.BACKDROP)
		end
		ScripterLibGui.window.BACKDROP.fadeAnim:SetMinMaxAlpha(savedVars_ScripterLibGui.minAlpha, savedVars_ScripterLibGui.maxAlpha)
		--ScripterLibGui.window.BACKDROP.fadeAnim:FadeOut(savedVars_ScripterLibGui.fadeOutDelay, savedVars_ScripterLibGui.fadeDuration)
		ScripterLibGui.window.BACKDROP.fadeAnim:FadeOut(Settings:GetValue(OPT_NOTIFY_FADE_DELAY), savedVars_ScripterLibGui.fadeDuration)
	end
end

function ScripterLibGui.FadeIn()
    if Settings:GetValue(OPT_NOTIFY_BG) == true then
       	if not ScripterLibGui.window.BACKDROP.fadeAnim then
       		ScripterLibGui.window.BACKDROP.fadeAnim = ZO_AlphaAnimation:New(ScripterLibGui.window.BACKDROP)
       	end
		ScripterLibGui.window.BACKDROP.fadeAnim:SetMinMaxAlpha(savedVars_ScripterLibGui.minAlpha, savedVars_ScripterLibGui.maxAlpha)
    	ScripterLibGui.window.BACKDROP.fadeAnim:FadeIn(savedVars_ScripterLibGui.fadeInDelay * 1000, savedVars_ScripterLibGui.fadeDuration)
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
	savedVars_ScripterLibGui.general.isMovable = value
	ScripterLibGui.window.ID:SetMovable(value)
end

function ScripterLibGui.getTimeTillLineFade()
	return savedVars_ScripterLibGui.lineFadeTime
end

function ScripterLibGui.setTimeTillLineFade(value)
	savedVars_ScripterLibGui.lineFadeTime = value
	ScripterLibGui.window.TEXTBUFFER:SetLineFade(savedVars_ScripterLibGui.lineFadeTime, savedVars_ScripterLibGui.lineFadeDuration)
end

function ScripterLibGui.setBackgroundHidden(value)
--	savedVars_ScripterLibGui.general.isBackgroundHidden = value
	ScripterLibGui.window.BACKDROP:SetHidden(value)
	--if savedVars_ScripterLibGui.general.isBackgroundHidden then
	if Settings:GetValue(OPT_NOTIFY_BG) == false then
		ScripterLibGui.window.ID:SetResizeHandleSize(0)
	else
		ScripterLibGui.window.ID:SetResizeHandleSize(8)
	end
end

function ScripterLibGui.setFadeDelay(value)
--    ScripterLibGui.window.BACKDROP.fadeAnim:FadeOut(value, 1500)
    ScripterLibGui.window.TEXTBUFFER:SetLineFade(value, 3)
end

--function ScripterLibGui.isBackgroundHidden()
--	return savedVars_ScripterLibGui.general.isBackgroundHidden
--end

function ScripterLibGui.isMovable()
	return savedVars_ScripterLibGui.general.isMovable
end


function ScripterLibGui.HideInDialogs(value)
	savedVars_ScripterLibGui.general.hideInDialogs = value
end

function ScripterLibGui.isHiddenInDialogs()
    return savedVars_ScripterLibGui.general.hideInDialogs
end

function ScripterLibGui.setHidden(value)
    savedVars_ScripterLibGui.general.isHidden = value
    ScripterLibGui.window.ID:SetHidden(value)
end

function ScripterLibGui.Hide()
    if savedVars_ScripterLibGui.general.isHidden == false then
        ScripterLibGui.setHidden(true)
    end
end

function ScripterLibGui.Show()
    if savedVars_ScripterLibGui.general.isHidden == true then
        ScripterLibGui.setHidden(false)
    end
end

function ScripterLibGui.isHidden()
    return savedVars_ScripterLibGui.general.isHidden
end

function ScripterLibGui.isTimestampEnabled()
	return savedVars_ScripterLibGui.timestamp
end

function ScripterLibGui.setTimestampEnabled(value)
	savedVars_ScripterLibGui.timestamp = value
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
	savedVars_ScripterLibGui = ZO_SavedVars:New("ScripterLibGui_SavedVariables", 1, nil, ScripterLibGui.defaults)
end
