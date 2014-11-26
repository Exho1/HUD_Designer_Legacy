if CLIENT then
	-- Contains commands and functions
	
	-- Open panel commands
	net.Receive("HD_OpenDesigner", function( len, ply )
		HD.OpenDesigner()
	end)
	concommand.Add("hd_open", function(ply)
		HD.OpenDesigner()
	end)
	concommand.Add("hd_reset", function(ply) -- In case the script doesn't start up nicely
		HD = {} 
		include("autorun/cl_util.lua")
		include("autorun/cl_assorted.lua")
		include("autorun/cl_base.lua")
	end)
	
	function HD.GetShapeLayer(id) -- Retrieve the shape's layer
		if id == nil then print("Get shape layer, ID is nil") return end
		
		local i = 1
		for i = 1, HD.Layers do
			local type = HD.GetShapeType(id) or HD.CurType
			if HD.DrawnObjects[i][type] ~= nil then 
				if HD.DrawnObjects[i][type][id] then
					return i
				end
			end
		end
	end
	
	function HD.GetShapeType(id) -- Get the shape's type
		for k, v in pairs (HD.Types) do
			if HD.DrawnObjects[HD.CurLayer][v] ~= nil then
				if HD.DrawnObjects[HD.CurLayer][v][id] then
					return v 
				end
			end
		end
	end
	
	function HD.GetShapeData(id) -- Get a table of the shape's data
		if id == nil then return end
		
		local type = HD.GetShapeType(id)
		local layer = HD.GetShapeLayer(id)
		local Table = {}
		local dr, bo = nil
		
		local dr = HD.DrawnObjects[layer][type][id] 
		local bo = HD.Boundaries[id]
		
		for k, v in pairs(HD.DrawnObjects[layer][type][id]) do
			Table[k] = v
		end

		return Table
	end
	
	function HD.SetTool(num, name) -- Toolbar highlighting and stuff
		HD.CurTool = num -- HUD.Tools number
		HD.SelectedButton = name -- String name
	end
	
	function HD.GetTextSize(text, font)
		surface.SetFont(font)
		local width, height = surface.GetTextSize(text)
		return width, height
	end
	
	function HD.GetMousePos() -- Customised mouse position
		local offset = 15
		local self = HD.Canvas
		return self:ScreenToLocal(gui.MouseX())-offset, self:ScreenToLocal(gui.MouseY())-offset
	end
	
	function HD.CloseOpenInfoPanels() -- Close the open info panels
		if HD.GridOpen or HD.ColMixerOpen or HD.LayerOpen or HD.ExportOpen then	
			if HD.GridEditor then
				HD.GridEditor:SetVisible(false) HD.GridOpen = false HD.GridEditor = nil
			end
			if HD.ColMixer then
				HD.ColMixer:SetVisible(false) HD.ColMixerOpen = false HD.ColMixer = nil
			end
			if HD.LayerSel then
				HD.LayerSel:SetVisible(false) HD.LayerOpen = false HD.LayerView = false HD.LayerSel = nil
			end
			if HD.Exporter then
				HD.Exporter:SetVisible(false) HD.ExportOpen = false HD.Exporter = nil
			end
		end
	end
	
	function HD.InfoPanelOpen() -- If one of the special info panels is open
		if HD.GridOpen or HD.ColMixerOpen or HD.LayerOpen or HD.ExportOpen then
			return true
		end
		return false
	end
	
	function HD.CancelAlter() -- Cancels any moving or altering taking place
		HD.CurMovingData = {}
		HD.Moving = false
		HD.CurSizeID = nil
		HD.Sizing = false
	end
	
	function HD.AddShape(id, x, y, width, height, color, corner, layer) -- Create a new shape
		-- Fallbacks
		color = color or HD.DefaultCol
		layer = layer or HD.CurLayer
		corner = corner or HD.DefaultCorner
		HD.DrawnObjects[layer] = HD.DrawnObjects[HD.CurLayer] or {}
		HD.DrawnObjects[layer][HD.CurType] = HD.DrawnObjects[HD.CurLayer][HD.CurType] or {}
		
		-- Snap to grid
		x,y = math.SnapTo(x, HD.GridSize), math.SnapTo(y, HD.GridSize)
		
		HD.DrawnObjects[layer][HD.CurType][id] = {x=x, y=y, width=width, height=height, color=color, corner=corner}
		
		-- Boundaries somehow need to be altered in order for them to be accurate... Look into this
		x,y = x-HD.GridSize, y+HD.GridSize
		HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height, layer=layer}
		HD.ShapeID = HD.ShapeID + 1
		HD.ShapeCount = HD.ShapeCount + 1
		
		timer.Simple(0.5, function()
			HD.SetTool(HD.Tools.Select, "Select")
		end)
	end
	
	function HD.AddText(id, x, y, text, font, color, layer)
		layer = layer or HD.CurLayer
		color = color or Color(0,0,0)
		
		HD.DrawnObjects[layer]["draw.DrawText"][id] = {x=x, y=y, text=text, font=font, color=color}
		
		local width, height = HD.GetTextSize(text, font)
		
		x,y = x-HD.GridSize, y+HD.GridSize
		HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height, layer=layer}
		HD.ShapeID = HD.ShapeID + 1
		HD.ShapeCount = HD.ShapeCount + 1
		
		timer.Simple(0.5, function()
			HD.SetTool(HD.Tools.Select, "Select")
		end)
	end
	
	function HD.EditShape(id, tab, mode) -- All purpose shape editing function
		if id == nil then return end
		
		mode = string.lower(mode)
		
		local ShapeLay = HD.GetShapeLayer(id) or HD.CurLayer
		local Type = HD.GetShapeType(id) or HD.CurType
		HD.DrawnObjects[ShapeLay] = HD.DrawnObjects[ShapeLay] or {} -- Fallbacks
		HD.DrawnObjects[ShapeLay][Type] = HD.DrawnObjects[ShapeLay][Type] or {}
		local D = HD.DrawnObjects[ShapeLay][Type][id] -- Grab the data table
		if D == nil then return end
		
		local x, y width, height, text, font, color, layer, newlayer, corner, format = nil
		
		if Type == "draw.RoundedBox" then
			x, y = tab.x or D.x, tab.y or D.y
			width, height = tab.width or D.width, tab.height or D.height
			color, corner = tab.color or D.color, tab.corner or D.corner
			layer, newlayer = tab.layer or ShapeLay, tab.newlayer or ShapeLay
		elseif Type == "draw.DrawText" then
			x, y = tab.x or D.x, tab.y or D.y
			text, font = tab.text or D.text, tab.font or D.font
			width, height = HD.GetTextSize(text, font)
			color = tab.color or D.color
			format = tab.format or D.format
			layer, newlayer = tab.layer or ShapeLay, tab.newlayer or ShapeLay
		end
		
		if mode == "size" then -- Size shape
			if Type == "draw.DrawText" then return end
			
			width, height = math.SnapTo(width, HD.GridSize), math.SnapTo(height, HD.GridSize)
			width, height = math.Clamp(width, HD.GridSize, ScrW()), math.Clamp(height, HD.GridSize, ScrH())
				
			if Type == "draw.RoundedBox" then
				--HD.DrawnObjects[layer][Type][id] = {x=x, y=y, width=width, height=height, color=color, corner=corner}
				HD.DrawnObjects[layer][Type][id].width = width
				HD.DrawnObjects[layer][Type][id].height = height
			end
			
			x,y = x-HD.GridSize, y+HD.GridSize
			HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height}
		elseif mode == "move" then -- Move shape
			local cfarx, cfary = HD.Canvas:GetSize()
			local cx, cy = 0, 0
			
			x, y = math.Clamp(x, cx, cfarx-width), math.Clamp(y, cy, cfary-height)
			
			if Type == "draw.RoundedBox" then
				--HD.DrawnObjects[HD.CurLayer][Type][id] = {x=x, y=y, width=width, height=height, color=color, corner=corner}
				HD.DrawnObjects[layer][Type][id].x = x
				HD.DrawnObjects[layer][Type][id].y = y
			elseif Type == "draw.DrawText" then
				--HD.DrawnObjects[layer][Type][id] = {x=x, y=y, text=text, font=font, color=color}
				HD.DrawnObjects[layer][Type][id].x = x
				HD.DrawnObjects[layer][Type][id].y = y
			end

			x,y = x-HD.GridSize, y+HD.GridSize
			HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height}
		elseif mode == "layer" then -- Edit shape layers
			local CurLayer = layer
			local NewLayer = newlayer
			
			-- Fallbacks
			HD.DrawnObjects[NewLayer] = HD.DrawnObjects[NewLayer] or {}
			HD.DrawnObjects[NewLayer][Type] = HD.DrawnObjects[NewLayer][Type] or {}
			
			-- Destroy the current drawn shape
			local i = 1
			for i = 1, HD.Layers do
				-- Remove any copies of this shape in any layer
				for type, objects in pairs(HD.DrawnObjects[i]) do
					if objects[id] then
						objects[id] = nil
					end
				end	
			end
			HD.DrawnObjects[CurLayer][Type][id] = nil
			
			-- Modify existing data to use the new layer
			if Type == "draw.RoundedBox" then
				HD.DrawnObjects[NewLayer][Type][id] = {x=x, y=y, width=width, height=height, color=color, corner=corner}
			elseif Type == "draw.DrawText" then
				HD.DrawnObjects[NewLayer][Type][id] = {x=x, y=y, text=text, font=font, color=color, format=format}
			end
			HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height, layer=NewLayer}
			return
		elseif mode == "corner" then -- Edit shape corner
			if Type == "draw.DrawText" then return end
			
			--HD.DrawnObjects[ShapeLay][Type][id] = {x=x, y=y, width=width, height=height, color=color, corner=corner}
			HD.DrawnObjects[ShapeLay][Type][id].corner = corner
			x,y = x-HD.GridSize, y+HD.GridSize
			HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height}
		end
	end
	
	function HD.IsInCanvas(x, y) -- Check if the mouse cursor is in the canvas
		x,y = tonumber(x), tonumber(y)
		local cfarx, cfary = HD.Canvas:GetSize()
		local cx, cy = 0, HD.GridSize
		if HD.InfoPanelOpen() then return false end
		
		if x > cx and x < cfarx then
			if y > cy and y < cfary then
				return true
			end
		end
		return false
	end
	
	function HD.IsInSize(id, x, y) -- Mouse cursor inside the sizing box
		x,y = tonumber(x), tonumber(y)
		
		if HD.GetShapeType(id) == "draw.DrawText" then return end
		
		local gs = HD.GridSize * 1.5
		if HD.GridSize < 10 then gs = HD.GridSize * 5 end -- Just to make selecting easier on small grid sizes
		
		local b = HD.Boundaries[id]
		if b then
			local farx, fary = b.farx, b.fary
			local minx, miny = farx-gs, fary-gs
			
			if HD.InfoPanelOpen() then return false end
			
			if x > minx and x < farx then
				if y > miny and y < fary then
					return true
				end
			end
		end
		return false
	end
	
	function HD.IsInShape(x, y) -- Mouse cursor inside a shape
		x,y = tonumber(x), tonumber(y) 
		local difx, dify, id
		
		for ID, tab in pairs(HD.Boundaries) do
			if x > tab.x and x < tab.farx then
				if y > tab.y and y < tab.fary then
					-- Difference from Shape Pos to the Mouse Pos
					difx, dify = x - tab.x, y - tab.y
					id = ID
				end
			end
		end
		
		if id then
			local type = HD.GetShapeType(id) or HD.CurType
			if HD.DrawnObjects[HD.CurLayer][type] == nil then return end
			
			if HD.DrawnObjects[HD.CurLayer][type][id] then 
				-- This shape exists in the current layer
				return true, id, difx, dify
			end
		end
		return false
	end
	
	function HD.Load(file)
		if not IsValid(file) then return end
		
		print("Load", file)
		local file = file.Read( "hud_designer/"..file, "DATA" ) -- Read the spawns file
		local table = util.JSONToTable( file ) 
		
		PrintTable(table)
	end
	
	function HD.Save() -- Save shape data into JSON format
		print("Saving current project..")
		local json = util.TableToJSON( HD.ShapeData )
		
		if json ~= "[]" then
			local Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
			local proj = HD.ProjectName
			for k, v in pairs(Banned) do -- Remove bad characters
				proj = string.gsub(proj, v, "-")
			end
			proj = string.gsub(proj, " ", "")
			local session = os.date("%H%M%S")
			session = string.gsub(session, ":", "")
			session = string.lower("save_"..proj.."_"..session)
			
			-- Write to the directory
			file.CreateDir( "hud_designer" )
			file.Write( "hud_designer/"..session..".txt", json)
		end
	end
	
	function HD.Autosave() -- Autosave shape data
		print("Autosaving current project..")
		local json = util.TableToJSON( HD.ShapeData )
		
		if json ~= "[]" then
			local Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
			local proj = HD.ProjectName
			for k, v in pairs(Banned) do -- Remove bad characters
				proj = string.gsub(proj, v, "-")
			end
			proj = string.gsub(proj, " ", "")
			local session = os.date("%H%M%S")
			session = string.gsub(session, ":", "")
			session = string.lower("autosave_"..proj.."_"..session)
			
			-- Write to the directory
			file.CreateDir( "hud_designer" )
			file.Write( "hud_designer/"..session..".txt", json)
		end
	end
	
	function HD.CreateExportCode()
		local ExportData = {}
		local i = 1
		for i = 1, HD.Layers do
			ExportData[i] = {}
			for type, objects in pairs(HD.DrawnObjects[i]) do
				print(type)
				if type == "draw.RoundedBox" then -- Filter by type
					local c = 1
					for c = 1, #objects do -- Loop through by ID
						local tab = HD.DrawnObjects[i][type][c] -- Object data
						if tab ~= nil then
							-- Valid entry, lets declare variables
							local x,y,width,height,col,corner = tab.x,tab.y,tab.width,tab.height,tab.color,tab.corner
							
							-- Auto sizing for all of the vgui elements
							local modx, mody, modw, modh = nil
							if HD.ScaleSize then
								modw,modh = math.Round(ScrW()/width, 2), math.Round(ScrH()/height, 2)
								-- Extra precautions to prevent game crashes from bad math
								if modw == math.huge then width = 0 else width = "ScrW()/"..modw.."" end
								if modh == math.huge then height = 0 else height = "ScrH()/"..modh.."" end
							end	
							if HD.ScalePos then
								modx, mody = math.Round(ScrW()/x, 2), math.Round(ScrH()/y, 2)
								if modx == math.huge then x = 0 else x = "ScrW()/"..modx end
								if mody == math.huge then y = 0 elseif mody == 1.24 then y = "ScrH()-("..height..")" 
								else y = "ScrH()/"..mody end
							end
							
							-- Assemble the color
							col = "Color("..col.r..", "..col.g..", "..col.b..", "..col.a..")"
							-- Add a new table entry
							ExportData[i][c] = string.format("draw.RoundedBox(%i, %s, %s, %s, %s, "..col..")", corner, x, y, width, height)
						end
					end
				elseif type == "draw.DrawText" then
					local c = 1
					for c = 1, #objects do -- Loop through by ID
						local tab = HD.DrawnObjects[i][type][c] -- Object data
						if tab ~= nil then
							local x,y,width,height,col,corner = tab.x,tab.y,tab.width,tab.height,tab.color,tab.corner
							local x,y,text,font,col,format = tab.x,tab.y,tab.text,tab.font,tab.color,tab.format
							
							local modx, mody = nil
							if HD.ScalePos then
								modx, mody = math.Round(ScrW()/x, 2), math.Round(ScrH()/y, 2)
								if modx == math.huge then x = 0 else x = "ScrW()/"..modx end
								if mody == math.huge then y = 0 elseif mody == 1.24 then y = "ScrH()-("..height..")" 
								else y = "ScrH()/"..mody end
							end
							
							if format ~= nil then -- Set up string formatting
								print(format)
								text = 'string.format("'..text..'", '..format..')'
							else
								text = '"'..text..'"'
							end
							
							-- Assemble the color
							col = "Color("..col.r..", "..col.g..", "..col.b..", "..col.a..")"
							-- Add a new table entry
							ExportData[i][c] = string.format('draw.DrawText(%s, "%s", %s, %s, '..col..')', text, font, x, y, col)
						end
					end
				else
					-- New type
				end
			end
		end
		return ExportData or {}
	end

	-- Math functions from Luabee's poly editor, modified for my purposes
	function math.SnapTo(num, point)
		if HD.GridEnabled ~= true then return num end
		
		num = math.Round(num)
		local possible = {min=0, max=0}
		for i=1, point do
			if math.IsDivisible(num+i, point) then
				possible.max = num+i
			end
			if math.IsDivisible(num-i, point) then
				possible.min = num-i
			end
		end
		
		if possible.max - num <= num - possible.min then
			return possible.max
		else
			return possible.min
		end
	end

	function math.IsDivisible(divisor, dividend)
		return divisor%dividend == 0
	end

end
	

