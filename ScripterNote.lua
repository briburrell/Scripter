
local ScripterNote		= { }
ScripterNote.default		= {
	anchor 		= { TOPLEFT, TOPLEFT, 0, 0},
	movable		= true,
	width			= 400,
	height		= 600,
	hideMainPanel 	= false,
	text			= "Drag and drop the bottom right corner to change the dimensions \n\n No mousewheel interaction, use page up and page down, sorry :( \n\n The text is saved when you click outside the window"
			}

NOTE_MODE_NONE = 0
NOTE_MODE_FUNCTION = 1

ScripterNote.movable = true
ScripterNote.moveCorner = false
--ScripterNote.width = 200
--ScripterNote.height = 400
ScripterNote.offsetX = 0
ScripterNote.offsetY = 2
ScripterNote.lastOffsetX = 0
ScripterNote.lastOffsetY = 2

function ScripterNote.HideNote()
	ScripterNotePanel:SetHidden(true)
--	ScripterNoteEditBox:SetEditEnabled(false)
end

function InitScripterNoteWindow()
	d("ScripterNote initialized.")
	
--	ScripterNote.SetHandler( "OnMouseUp", function()  ScripterNote.SaveAnchor() end )
		
	ScripterNote.vars = ZO_SavedVars:New("ScripterNote_SavedVariables",1,"ScripterNote",ScripterNote.default)
	
	-- Need to clear anchors, since SetAnchor() will just keep adding new ones.
--	ScripterNote.ClearAnchors()
--	ScripterNote.SetAnchor(ScripterNote.vars.anchor[1], ScripterNote.parent, ScripterNote.vars.anchor[2], ScripterNote.vars.anchor[3], ScripterNote.vars.anchor[4])
	
--	ScripterNote.movable = ScripterNote.vars.movable
		
	-- fix or movable
--	ScripterNote.UpdateMovable()
	
	-- init config panel
--	ScripterNote.InitConfigPanel()
	
	-- init corner
	ScripterNoteCorner:SetHandler("OnMouseDown", function() ScripterNote.MoveCorner(true) end)
	ScripterNoteCorner:SetHandler("OnMouseUp", function() ScripterNote.MoveCorner(false) end)
	
	-- init note panel
	ScripterNote.InitNotePanel()
	ScripterNote.HideNote()
	
	-- init edit box
	ScripterNoteEditBox:SetHandler("OnFocusLost", function() ScripterNote.SaveText() end)
	
	-- keybinding
--	ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_TINOTE", "Toggle ScripterNote")
	
	-- init main panel visibility
--	ScripterNote.UpdateMainVisibility()
	
end

--function ToggleScripterNote()
--	local isHidden = not ScripterNote.vars.hideMainPanel
--	ScripterNote.vars.hideMainPanel = isHidden
--	ScripterNote.SetHidden(isHidden)
--end

--function ScripterNote.UpdateMainVisibility()
----	ScripterNote.SetHidden(ScripterNote.vars.hideMainPanel)
--end

--function ScripterNote.OnReticleHidden(eventCode, hidden)
--	ScripterNoteEditBox:SetEditEnabled(hidden)
--end
--EVENT_MANAGER:RegisterForEvent("ScripterNote" , EVENT_RETICLE_HIDDEN_UPDATE, function(_event, _hidden) ScripterNote.OnReticleHidden(_event, _hidden) end)

function ScripterNoteUpdate()
	if not ScripterNote.moveCorner then
		return
	end
	
	ScripterNote.UpdateNoteDimension()
end

function ScripterNote.ShowNote()
	if ScripterNotePanel:IsHidden() == true then
		ScripterNotePanel:SetHidden(false)
	end
	--ScripterNoteEditBox:SetMouseEnabled(true)
	ScripterNoteEditBox:SetKeyboardEnabled(true)
	ScripterNoteEditBox:TakeFocus()
end
function ScripterNote.SetNoteText(text)
	ScripterNote.vars.text = text
	ScripterNoteEditBox:SetText(ScripterNote.vars.text)
end
function ScripterNoteShow(mode, title, text, callback)
	ScripterNote.title = title
	ScripterNote.note_mode = mode
	ScripterNote.callback = callback

--	ScripterNoteTitle:SetText(title)
	ScripterNote.SetNoteText(text)

	ScripterNote.ShowNote()
end

function ScripterNote.InitNotePanel()
	local xx = ScripterNote.vars.width
	local yy = ScripterNote.vars.height
	--ScripterNote.SetDimensions(xx,yy+20)
	ScripterNotePanel:SetDimensions(xx,yy)
	ScripterNoteBG:SetDimensions(xx,yy)
	ScripterNoteEditBox:SetDimensions(xx-10,yy-10)
		
	ScripterNoteEditBox:SetText(ScripterNote.vars.text)
	
	ScripterNoteCorner:ClearAnchors()
	ScripterNoteCorner:SetAnchor(BOTTOMRIGHT,ScripterNoteBG ,BOTTOMRIGHT, ScripterNote.offsetX, ScripterNote.offsetY)

	ScripterNoteEditBox:SetEditEnabled(true)
end

function ScripterNote.SaveNotePanel()
	local xx, yy = ScripterNotePanel:GetDimensions()
	ScripterNote.vars.width = xx
	ScripterNote.vars.height = yy
end

function ScripterNote.SaveText()
	ScripterNote.vars.text = ScripterNoteEditBox:GetText()
	ScripterNote.HideNote()

	if ScripterNote.callback then 
		ScripterNote.callback(ScripterNote.note_mode, ScripterNote.title, ScripterNote.vars.text)
	end
	ScripterNote.callback = nil
end

function ScripterNote.SaveAnchor()
	
	-- Get the new position
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ScripterNote.GetAnchor()
	
	-- Save the anchors
	if ( isValidAnchor ) then
	
	ScripterNote.vars.anchor = { point, relativePoint, offsetX, offsetY }
	
	else
	
	d("ScripterNote - anchor not valid")
	
	end
end

function ScripterNote.UpdateMovable()
--	ScripterNote.SetMovable(ScripterNote.movable)
end

function ScripterNote.ToggleMovable()
	ScripterNote.movable = not ScripterNote.movable
--	ScripterNote.UpdateMovable()
	ScripterNote.vars.movable = ScripterNote.movable
	return ScripterNote.movable
end


function ScripterNote.InitConfigPanel()
	
	local cPanelId="ScripterNoteConfigPanel"
	local panelId = _G[cPanelId]
	
	if not panelId then
		ZO_OptionsWindow_AddUserPanel(cPanelId, "ScripterNote")
		panelId = _G[cPanelId]
	end
	
	-- movable
	local checkbox = CreateControlFromVirtual("ScripterNoteMovableCheckbox", ZO_OptionsWindowSettingsScrollChild, "ZO_Options_Checkbox")
	checkbox:SetAnchor(TOPLEFT, checkbox.parent, TOPLEFT, 0, 20)
	checkbox.controlType = OPTIONS_CHECKBOX
	checkbox.panel = panelId
	checkbox.system = SETTING_TYPE_UI
	checkbox.settingId = _G["SETTING_ScripterNoteMovableCheckbox"]
	checkbox.text = "Movable"
	
	local checkboxButton = checkbox:GetNamedChild("Checkbox")
	
	
	ZO_PreHookHandler(checkbox, "OnShow", function()
			checkboxButton:SetState(ScripterNote.movable and 1 or 0)
			checkboxButton:toggleFunction(ScripterNote.movable)
		end)
		
	ZO_PreHookHandler(checkboxButton, "OnClicked", function()  
					ScripterNote.ToggleMovable()
				end)
	
	ZO_OptionsWindow_InitializeControl(checkbox)
	
end

function ScripterNote.MoveCorner(bmove)
	--d(bmove)
	ScripterNote.moveCorner = bmove
	
	if not bmove then
		ScripterNoteCorner:ClearAnchors()
		ScripterNoteCorner:SetAnchor(BOTTOMRIGHT,ScripterNoteBG ,BOTTOMRIGHT, ScripterNote.offsetX, ScripterNote.offsetY)
		ScripterNoteCorner:SetAlpha(1)
		ScripterNote.lastOffsetX = ScripterNote.offsetX
		ScripterNote.lastOffsetY = ScripterNote.offsetY
		ScripterNote.SaveNotePanel()
	else
		ScripterNoteCorner:SetAlpha(0)
	end
end

function ScripterNote.UpdateNoteDimension()

	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ScripterNoteCorner:GetAnchor()
	
	if ( isValidAnchor ) then
	
	--d(tostring(offsetX).." , "..tostring(offsetY))
	local x, y = ScripterNotePanel:GetDimensions()
	local xx = x
	local yy = y
	
	local xdiff = offsetX-ScripterNote.lastOffsetX
	if xdiff ~= 0 then
		xx = xx + xdiff
		if xx < 100 then -- limit min width
			xx = xx - xdiff
		else
			ScripterNote.lastOffsetX = offsetX
		end
	end
	
	local ydiff = offsetY - ScripterNote.lastOffsetY
	if ydiff ~= 0 then
		yy = yy + ydiff
		if yy < 30 then -- limit min height
			yy = yy - ydiff 
		else
			ScripterNote.lastOffsetY = offsetY
		end
	end
	
	--ScripterNote.SetDimensions(xx,yy+20)
	ScripterNotePanel:SetDimensions(xx,yy)
	ScripterNoteBG:SetDimensions(xx,yy)
	ScripterNoteEditBox:SetDimensions(xx-10,yy-10)
	--ScripterNoteCorner:ClearAnchors()
	--ScripterNoteCorner:SetAnchor(point,relativeTo ,relativePoint, 0, 2)
	
	else
	
	d("ScripterNote - corner anchor not valid")
	
	end

end
