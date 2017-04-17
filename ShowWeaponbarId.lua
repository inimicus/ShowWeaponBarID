-- http://wiki.esoui.com/Main_Page
-- http://wiki.esoui.com/Writing_your_first_addon
-- http://wiki.esoui.com/API
-- http://wiki.esoui.com/Events
-- http://wiki.esoui.com/Fonts
-- http://wiki.esoui.com/Controls

-- working with textures
-- http://www.esoui.com/downloads/info33-zTextureTest.html
-- http://www.esoui.com/forums/showthread.php?t=1266 
-- http://www.esoui.com/forums/showthread.php?p=3054

-- helpful
-- http://wiki.esoui.com/Circonians_Menu_Settings_Tutorial

-- First, we create a namespace for our addon by declaring a top-level table that will hold everything else.
ShowWeaponbarId = {}
 
-- This isn't strictly necessary, but we'll use this string later when registering events.
-- Better to define it in a single place rather than retyping the same string.
ShowWeaponbarId.name = "ShowWeaponbarId"

-- Localize builtin functions we use 
local ipairs = ipairs
local next = next
local pairs = pairs
local tinsert = table.insert

-- Localize ESO API functions we use
local d = d
local strjoin = zo_strjoin
local strsplit = zo_strsplit
local GetNumActionLayers = GetNumActionLayers
local GetActionLayerInfo = GetActionLayerInfo
local GetActionLayerCategoryInfo = GetActionLayerCategoryInfo
local GetActionInfo = GetActionInfo
local GetActionIndicesFromName = GetActionIndicesFromName

local function print(...)
    d(strjoin("", ...))
end

local function hex2rgb(hex)
	hex = hex:gsub("#","")
	local t = {}
	t[1] = tonumber("0x"..hex:sub(1,2))
	t[2] = tonumber("0x"..hex:sub(3,4))
	t[3] = tonumber("0x"..hex:sub(5,6))
	t[4] = 1
	return t
end 

-- RGBA colors (RGB + Alpha), Alpha: 0 until 1 (e.g 0.5 = half alpha)
ShowWeaponbarId.colors = {
	["black"] = {0,0,0,1}, -- #000000
	["red"] = {255,0,0,1}, -- #ff0000
	["yellow"] = {255,255,0,1}, -- #ffff00
	["pink"] = {255,0,255,1}, -- #ff00ff
	["cyan"] = {0,255,255,1}, -- #00ffff
	["green"] = {0,255,0,1}, -- #00ff00
	["blue"] = {0,0,255,1}, -- #0000ff
	["white"] = {255,255,255,1}, -- #ffffff
}

-- ESO Fonts: http://wiki.esoui.com/Fonts
ShowWeaponbarId.fonts = {
	[1] = "BOLD_FONT",
	[2] = "MEDIUM_FONT",
	[3] = "CHAT_FONT",
	[4] = "ANTIQUE_FONT",
	[5] = "HANDWRITTEN_FONT",
	[6] = "STONE_TABLET_FONT",
	[7] = "GAMEPAD_MEDIUM_FONT",
	[8] = "GAMEPAD_BOLD_FONT",
}
 
-- Next we create a function that will initialize our addon
function ShowWeaponbarId:Initialize()
	-- Init Label-Text (get current weaponbarId)
	ShowWeaponbarIdIndicatorLabel:SetText(GetActiveWeaponPairInfo())

    ShowWeaponbarId.MainLoop()
	
	-- EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MOUNTED_STATE_CHANGED, self.OnMount)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTIVE_WEAPON_PAIR_CHANGED, self.OnWeaponSwap)
	
	-- create savedVariables
	self.savedVariables = ZO_SavedVars:NewAccountWide("ShowWeaponbarIdSavedVariables", 1, nil, {})
	
	-- Restore saved position of Indicator from savedVariables
	self:RestorePosition()
	
	-- Restore saved font from savedVariables
	self:RestoreFont()
	
	-- Restore saved font size from savedVariables
	--self:RestoreFontSize()
	
	-- Restore saved color from savedVariables
	self:RestoreColor()
end

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function ShowWeaponbarId.OnAddOnLoaded(event, addonName)
  -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
  if addonName == ShowWeaponbarId.name then
    ShowWeaponbarId:Initialize()
  end
end

-- EventHandler for "OnMoveStop"-Gui-event
-- save new position in savedVariables
function ShowWeaponbarId.OnIndicatorMoveStop()
  ShowWeaponbarId.savedVariables.left = ShowWeaponbarIdIndicator:GetLeft()
  ShowWeaponbarId.savedVariables.top = ShowWeaponbarIdIndicator:GetTop()
end

-- Restore saved position of Indicator from savedVariables
function ShowWeaponbarId:RestorePosition()
	local left = self.savedVariables.left
	local top = self.savedVariables.top
	
	ShowWeaponbarIdIndicator:ClearAnchors()
	ShowWeaponbarIdIndicator:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

-- Restore saved font from savedVariables
function ShowWeaponbarId:RestoreFont()
	if self.savedVariables.font then
		font = self.savedVariables.font
	else 
		font = "BOLD_FONT"
	end
	
	if self.savedVariables.fontSize then
		fontSize = self.savedVariables.fontSize
	else 
		fontSize = 60
	end
	
	if self.savedVariables.font then
		ShowWeaponbarIdIndicatorLabel:SetFont("$("..font..")|"..fontSize.."|soft-shadow-thick")
	end
end

-- Restore saved font size from savedVariables
-- function ShowWeaponbarId:RestoreFontSize()
	-- if self.savedVariables.fontSize then
		-- ShowWeaponbarIdIndicatorLabel:SetFont("$(BOLD_FONT)|"..self.savedVariables.fontSize.."|soft-shadow-thick")
	-- end
-- end

function ShowWeaponbarId:RestoreColor()
	if self.savedVariables.color then
		ShowWeaponbarIdIndicatorLabel:SetColor(unpack(ShowWeaponbarId.savedVariables.color))
	end
end

-- EventHandler for "EVENT_ACTIVE_WEAPON_PAIR_CHANGED" event
function ShowWeaponbarId.OnWeaponSwap(event, activeWeaponPair, locked)
	ShowWeaponbarIdIndicatorLabel:SetText(activeWeaponPair)
end

-- EventHandler for "EVENT_MOUNTED_STATE_CHANGED" event
function ShowWeaponbarId.OnMount(event, mounted)
	d("----")
	d(123)
	d(mounted)
	d(GetUnitName("player"))
end

function ShowWeaponbarId.MainLoop()
    local inMenu = ZO_Compass:IsHidden()
    if inMenu then
        ShowWeaponbarIdIndicator:SetHidden(true)
    else
        ShowWeaponbarIdIndicator:SetHidden(false)
    end
    
    -- make this function a loop
    zo_callLater(function() ShowWeaponbarId.MainLoop() end, 1000)
end

-------------------------------------------------------------------------------------------------
-------------- COMMANDS -------------------------------------------------------------------------

function ShowWeaponbarId.SlashCommandHelp()
    print("ShowWeaponbarId usage:")
	print("- /swi --font <fontNumber> (set fontNumber 1-8)")
    print("- /swi --fontsize <size> (set font size between 1 and 70)")
	print("- /swi --color <color> (black,red,yellow,pink,cyan,green,blue,white)")
	print("- /swi --help (show help screen)")
end

-- setFont
function ShowWeaponbarId.setFont(fontNumber)
	
	-- convert string to number
	local fontNumber = tonumber(fontNumber)
	
	-- size nil or not a number
	if not fontNumber then
		print("ShowWeaponbarId: invalid value for font! must be a number")
        -- ShowWeaponbarId.SlashCommandHelp()
        return
	end
	
	-- size not between 1 and 8
	if fontNumber < 1 or fontNumber > 8 then
		print("fontNumber must be between 1 and 8")
		return
	end
	
	-- save the font in savedVariables
	ShowWeaponbarId.savedVariables.font = ShowWeaponbarId.fonts[fontNumber]
	
	-- get fontSize
	local fontSize = 60
	if ShowWeaponbarId.savedVariables.fontSize then
		fontSize = ShowWeaponbarId.savedVariables.fontSize
	end

	
	-- set the fontSize
	ShowWeaponbarIdIndicatorLabel:SetFont("$("..ShowWeaponbarId.savedVariables.font..")|"..fontSize.."|soft-shadow-thick")
end

-- setFontSize
function ShowWeaponbarId.setFontSize(size)
	
	-- convert string to number
	local size = tonumber(size)
	
	-- size nil or not a number
	if not size then
		print("ShowWeaponbarId: invalid value for fontsize! must be a number")
        -- ShowWeaponbarId.SlashCommandHelp()
        return
	end
	
	-- size not between 1 and 70
	if size < 1 or size > 80 then
		print("fontsize must be between 1 and 80")
		return
	end
	
	-- save the size in savedVariables
	ShowWeaponbarId.savedVariables.fontSize = size
	
	-- get font
	local font = "BOLD_FONT"
	if ShowWeaponbarId.savedVariables.font then
		font = ShowWeaponbarId.savedVariables.font
	end

	-- set the fontSize
	ShowWeaponbarIdIndicatorLabel:SetFont("$("..font..")|"..ShowWeaponbarId.savedVariables.fontSize.."|soft-shadow-thick")
end

-- setColor
function ShowWeaponbarId.setColor(color)
	
	-- if color not in table (ShowWeaponbarId.colors)
	if ShowWeaponbarId.colors[color] == nil then
		print("ShowWeaponbarId: invalid value for color! (valid: black,red,yellow,pink,cyan,green,blue,white)")
		-- ShowWeaponbarId.SlashCommandHelp()
		return
	end

	-- get rgba table (=dictionary) from ShowWeaponbarId.colors by given color
	rgba = ShowWeaponbarId.colors[color]

	-- save the color in savedVariables
	ShowWeaponbarId.savedVariables.color = rgba
	
	-- set the color
	ShowWeaponbarIdIndicatorLabel:SetColor(unpack(ShowWeaponbarId.savedVariables.color))
end

ShowWeaponbarId.commands = {
	["--font"] = ShowWeaponbarId.setFont,
	["--fontsize"] = ShowWeaponbarId.setFontSize,
	["--color"] = ShowWeaponbarId.setColor,
	["--help"] = ShowWeaponbarId.SlashCommandHelp,
}

-- command handler
function ShowWeaponbarId.SlashCommand(argtext)
	local args = {strsplit(" ", argtext)}

	-- no args
    if next(args) == nil then
        ShowWeaponbarId.SlashCommandHelp()
        return
    end

	-- unkonwn command
    local command = ShowWeaponbarId.commands[args[1]]
    if not command then
        print("ShowWeaponbarId: unknown command '", args[1], "'.")
        ShowWeaponbarId.SlashCommandHelp()
        return
    end
    
    -- call function
    command(unpack(args, 2))
end
-------------------------------------------------------------------------------------------------
 
-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(ShowWeaponbarId.name, EVENT_ADD_ON_LOADED, ShowWeaponbarId.OnAddOnLoaded)

-- Command entry point
SLASH_COMMANDS["/swi"] = ShowWeaponbarId.SlashCommand

 
