----// HUD Designer //----
-- Author: Exho
-- Version: 12/10/14

--[[ To Do:
* More shapes
* Recreate TTT's HUD in the editor
* Variable based width/height for rectangles
* Font creator
* Copy tool

In Progress:
* Textured rects - Make a texture selector in the Shape Options right click menu
* On-start pop up menu to choose a save
* In-game testing
]]

if SERVER then
	AddCSLuaFile("hud_designer/cl_base.lua")
	AddCSLuaFile("hud_designer/cl_util.lua")
	AddCSLuaFile("hud_designer/cl_assorted.lua")

	util.AddNetworkString("HD_OpenDesigner")
	resource.AddFile("resource/fonts/roboto_light.tff")
	for k, v in pairs(file.Find("materials/vgui/hud_designer/*", "GAME")) do
		resource.AddFile(v)
	end

	hook.Add("PlayerSay", "HUDDesignerOpener", function(ply, text)
		text = string.lower(text)

		if string.sub(text, 1) == "!hud" then
			net.Start("HD_OpenDesigner")
			net.Send(ply)
		end
	end)
else
	color_white = color_white or COLOR_WHITE or Color(255,255,255,255)
	color_black = color_black or COLOR_BLACK or Color(0,0,0,255)
	color_transparent = color_transparent or COLOR_TRANSPARENT or Color(0,0,0,0)

	HD = HD or {}

	include("hud_designer/cl_base.lua")
	include("hud_designer/cl_util.lua")
	include("hud_designer/cl_assorted.lua")
end