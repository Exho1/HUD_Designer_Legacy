if CLIENT then
	-- Contains commands and functions
	
	HD = HD or {}
	
	-- Open panel commands
	net.Receive("HD_OpenDesigner", function( len, ply )
		HD.OpenDesigner()
	end)
	concommand.Add("hd_open", function(ply)
		HD.OpenDesigner()
	end)
	concommand.Add("hd_reset", function(ply) -- In case the script doesn't start up nicely
		if HD.Frame then
			HD.Frame:SetVisible(false)
		end
		HD = {} 
		include("autorun/cl_util.lua")
		include("autorun/cl_assorted.lua")
		include("autorun/cl_base.lua")
	end)
	
	function HD.AddShape(id, x, y, width, height, color, special, layer) -- Create a new shape
		-- Fallbacks
		color = color or HD.DefaultCol
		layer = layer or HD.CurLayer
		HD.DrawnObjects[layer] = HD.DrawnObjects[HD.CurLayer] or {}
		HD.DrawnObjects[layer][HD.CurType] = HD.DrawnObjects[HD.CurLayer][HD.CurType] or {}
		
		-- Snap to grid
		x,y = math.SnapTo(x, HD.GridSize), math.SnapTo(y, HD.GridSize)
		
		if HD.CurType == "draw.RoundedBox" then
			HD.DrawnObjects[layer][HD.CurType][id] = {x=x, y=y, width=width, height=height, color=color, corner=special}
		elseif HD.CurType == "surface.DrawTexturedRect" then
			HD.DrawnObjects[layer][HD.CurType][id] = {x=x, y=y, width=width, height=height, color=color, texture=special}
		else
		
		end

		-- Boundaries somehow need to be altered in order for them to be accurate... Look into this
		HD.SetBoundaries(id, x, y, width, height, layer)
		
		-- Advance shape count
		HD.ShapeID = HD.ShapeID + 1
		HD.ShapeCount = HD.ShapeCount + 1
		
		timer.Simple(0.5, function()
			HD.SetTool(HD.Tools.Select, "Select")
		end)
	end

	function HD.AddText(id, x, y, text, font, color, layer)
		-- Fallbacks
		layer = layer or HD.CurLayer
		color = color or Color(0,0,0)
		HD.DrawnObjects[layer] = HD.DrawnObjects[layer] or{}
		HD.DrawnObjects[layer]["draw.DrawText"] = HD.DrawnObjects[layer]["draw.DrawText"] or {}
		
		if color == HD.DefaultCol then color = Color(0,0,0) end -- Text should not be blue by default :/
		
		x,y = math.SnapTo(x, HD.GridSize), math.SnapTo(y, HD.GridSize)
		
		-- Tell the designer to draw this shape
		HD.DrawnObjects[layer]["draw.DrawText"][id] = {x=x, y=y, text=text, font=font, color=color}
		
		-- Create boundaries
		local width, height = HD.GetTextSize(text, font)
		--x,y = x-HD.GridSize, y+HD.GridSize
		--HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height, layer=layer}
		HD.SetBoundaries(id, x, y, width, height, layer)
		
		-- Advance shape count
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
		
		-- Make sure the tables exist
		HD.DrawnObjects[ShapeLay] = HD.DrawnObjects[ShapeLay] or {}
		HD.DrawnObjects[ShapeLay][Type] = HD.DrawnObjects[ShapeLay][Type] or {}
		
		local D = HD.DrawnObjects[ShapeLay][Type][id] -- Grab the data table
		if D == nil then return end
		
		-- Localize some variables
		local x, y width, height, text, font, color, layer, newlayer, corner, format, special = nil
		
		-- Declare the basics with fallbacks
		x, y = tab.x or D.x, tab.y or D.y
		layer, newlayer = tab.layer or ShapeLay, tab.newlayer or ShapeLay
		color = tab.color or D.color
		
		-- Declare specifics
		if Type == "draw.RoundedBox" then
			width, height = tab.width or D.width, tab.height or D.height
			corner =  tab.corner or D.corner
		elseif Type == "surface.DrawTexturedRect" then
			width, height = tab.width or D.width, tab.height or D.height
			special = tab.special 
		elseif Type == "draw.DrawText" then
			text, font = tab.text or D.text, tab.font or D.font
			width, height = HD.GetTextSize(text, font)
			format = tab.format or D.format
		end
		
		if mode == "size" then -- Size shape
			if Type == "draw.DrawText" then return end
			
			width, height = math.SnapTo(width, HD.GridSize), math.SnapTo(height, HD.GridSize)
			width, height = math.Clamp(width, HD.GridSize, ScrW()), math.Clamp(height, HD.GridSize, ScrH())
				
			if Type == "draw.RoundedBox" then
				HD.DrawnObjects[layer][Type][id].width = width
				HD.DrawnObjects[layer][Type][id].height = height
			elseif Type == "surface.DrawTexturedRect" then
				HD.DrawnObjects[layer][Type][id].width = width
				HD.DrawnObjects[layer][Type][id].height = height
			end
			
			HD.SetBoundaries(id, x, y, width, height, layer)
		elseif mode == "move" then -- Move shape
			local cfarx, cfary = HD.Canvas:GetSize()
			local cx, cy = 0, 0
			
			x, y = math.Clamp(x, cx, cfarx-width), math.Clamp(y, cy, cfary-height)
			
			if Type == "draw.RoundedBox" then
				HD.DrawnObjects[layer][Type][id].x = x
				HD.DrawnObjects[layer][Type][id].y = y
			elseif Type == "surface.DrawTexturedRect" then
				HD.DrawnObjects[layer][Type][id].x = x
				HD.DrawnObjects[layer][Type][id].y = y
			elseif Type == "draw.DrawText" then
				HD.DrawnObjects[layer][Type][id].x = x
				HD.DrawnObjects[layer][Type][id].y = y
			end

			--x,y = x-HD.GridSize, y+HD.GridSize
			HD.SetBoundaries(id, x, y, width, height, layer)
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
			
			HD.SetBoundaries(id, x, y, width, height, NewLayer)
			return
		elseif mode == "corner" then -- Edit shape corner
			if Type == "draw.DrawText" then return end
			
			HD.DrawnObjects[ShapeLay][Type][id].corner = corner
			HD.SetBoundaries(id, x, y, width, height, layer)
		end
	end
	
	function HD.GetShapeLayer(id) -- Retrieve the shape's layer
		if id == nil then return end
		
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
		if HD.GridOpen then
			HD.GridEditor:SetVisible(false) HD.GridOpen = false HD.GridEditor = nil
		end
		if HD.ColMixerOpen then
			HD.ColMixer:SetVisible(false) HD.ColMixerOpen = false HD.ColMixer = nil
		end
		if HD.LayerOpen then
			HD.LayerSel:SetVisible(false) HD.LayerOpen = false HD.LayerView = false HD.LayerSel = nil
		end
		if HD.ExportOpen then
			HD.Exporter:SetVisible(false) HD.ExportOpen = false HD.Exporter = nil
		end
		if HD.LoadOpen then
			HD.LoadSel:SetVisible(false) HD.LoadOpen = false HD.LoadSel = nil
		end
		if HD.CreateOpen then
			HD.CreatePanel:SetVisible(false) HD.CreateOpen = false HD.CreatePanel = nil
		end
		HD.SetTool()
	end
	
	function HD.SetTool( num, name ) -- Toolbar highlighting and stuff
		HD.CurTool = num -- HUD.Tools number
		HD.SelectedButton = name -- String name
	end
	
	function HD.SetType( name )
		for k, v in pairs(HD.Types) do
			if string.lower(v) == string.lower(name) then
				HD.CurType = HD.Types[k]
				return true
			end
		end
	end
	
	function HD.SetBoundaries(id, x, y, width, height, layer)
		layer = layer or HD.CurLayer
		
		-- I have to change the X and Y to line the bounds up with the drawn shape. Why?
		x,y = x-HD.GridSize, y+HD.GridSize
		
		HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height, layer=layer}
	end
	
	function HD.InfoPanelOpen() -- If one of the special info panels is open
		if HD.GridOpen or HD.ColMixerOpen or HD.LayerOpen or HD.ExportOpen or HD.CreateOpen or HD.LoadOpen then
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
		
		local gs = HD.GridSize 
		if HD.GridSize < 10 then
			gs = 10 * 1.5
		else
			gs = gs * 1.5
		end
		
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
		
		for shapeID, tab in pairs(HD.Boundaries) do
			if x > tab.x and x < tab.farx then
				if y > tab.y and y < tab.fary then
					if tab.layer == HD.CurLayer then
						-- Difference from Shape Pos to the Mouse Pos
						difx, dify = x - tab.x, y - tab.y
						id = shapeID
						return true, id, difx, dify
					end	
				end
			end
		end
		return false
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
	
	function HD.Load( txt )
		HD.CancelAlter()
		local json = file.Read( "hud_designer/"..txt, "DATA" )
		local tab = util.JSONToTable( json ) 
		
		HD.ProjectName = tab.ProjectName or HD.ProjectName
		HD.ProjectText:SetText(HD.ProjectName)
		
		local i = 1
		local size = table.Count(tab)
		if size > 1 then size = size - 1 end -- Tables are weird
		
		for i = 1, size do
			HD.DrawnObjects[i] = HD.DrawnObjects[i] or {} -- Layer fallback
			for type, objects in pairs(tab[i]) do
				HD.DrawnObjects[i][type] = HD.DrawnObjects[i][type] or {} -- Type fallback
				for id, data in pairs(objects) do
					HD.DrawnObjects[i][type][HD.ShapeID] = {}
					
					-- Merge the table
					table.Merge( HD.DrawnObjects[i][type][HD.ShapeID], data )
					
					-- Fix up broken colors
					local col = HD.DrawnObjects[i][type][HD.ShapeID].color or HD.DefaultCol
					HD.DrawnObjects[i][type][HD.ShapeID].color = Color(col.r, col.g, col.b, col.a)
					
					-- Create the boundaries
					local width, height = nil
					if type == "draw.DrawText" then
						width, height = HD.GetTextSize(data.text, data.font)
					else
						width, height = data.width, data.height
					end
					HD.SetBoundaries(HD.ShapeID, data.x, data.y, width, height, i)
					
					-- Acknowledge the shape exists
					HD.ShapeID = HD.ShapeID + 1
					HD.ShapeCount = HD.ShapeCount + 1
				end
			end
		end
		print("Loaded HUD from "..txt)
	end
	
	function HD.Save( name ) -- Save shape data into JSON format
		if HD.ShapeCount < 2 then print("Not enough shapes ("..HD.ShapeCount..") to save!") return end
		print("Saving current project..")
		
		local tojson = table.Copy(HD.DrawnObjects)
		local i = 1
		for i = 1, HD.Layers do
			for type, objects in pairs(tojson[i]) do
				for id, data in pairs(objects) do
					-- Json isn't a big fan of the color tables, so we will make sure it recognizes them
					local col = data.color or HD.DefaultCol
					data.color = {r=col.r, g=col.g, b=col.b, a=col.a}
				end
			end
		end
		tojson.ProjectName = tojson.ProjectName or HD.ProjectName
		
		local json = util.TableToJSON( tojson )
		
		if json ~= "[]" then
			local Banned, proj, session = nil
			-- Create a file name
			Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
			proj = name or HD.ProjectName
			for k, v in pairs(Banned) do -- Remove bad characters
				proj = string.gsub(proj, v, "-")
			end
			proj = string.gsub(proj, " ", "")
			session = os.date("%H%M%S")
			session = string.gsub(session, ":", "")
			session = string.lower("save_"..proj.."_"..session)
			
			-- Write to the directory
			file.CreateDir( "hud_designer" )
			file.Write( "hud_designer/"..session..".txt", json)
		end
		
		timer.Simple(0.5, function()
			HD.SetTool(HD.Tools.Select, "Select")
		end)
	end
	
	function HD.Autosave() -- Autosave shape data
		print("Autosaving current project..")
		local json = util.TableToJSON( HD.DrawnObjects )
		
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
		HD.CancelAlter()
		local ExportData = {}
		local i = 1
		for i = 1, HD.Layers do
			ExportData[i] = {}
			for type, objects in pairs(HD.DrawnObjects[i]) do
				if type == "draw.RoundedBox" then -- Filter by type
					local c = 1
					for c = 1, HD.ShapeCount do -- Loop through by ID
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
							y = y + 230 -- Fix for the Canvas not being screen size, find a way to make this resolution dependent
							if HD.ScalePos then
								modx, mody = math.Round(ScrW()/x, 2), math.Round(ScrH()/y, 2)
								if modx == math.huge then x = 0 else x = "ScrW()/"..modx end
								if mody == math.huge then y = 0 elseif mody == 1.24 then y = "ScrH()-("..height..")" 
								else y = "ScrH()/"..mody end
							else -- Going to slightly scale the position anyways
								if x > ScrW()/2 then
									modx = ScrW() - x
									x = "ScrW()-"..modx
								end
								if y > ScrH()/2 then
									mody = ScrH() - y
									y = "ScrH()-"..mody
								end
							end
							
							-- Assemble the color
							col = "Color("..col.r..", "..col.g..", "..col.b..", "..col.a..")"
							-- Add a new table entry
							ExportData[i][c] = string.format("draw.RoundedBox(%i, %s, %s, %s, %s, "..col..")", corner, x, y, width, height)
						end
					end
				elseif type == "draw.DrawText" then
					local c = 1
					for c = 1, HD.ShapeCount do -- Loop through by ID
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
								local tab, param = nil
								for k, v in pairs(HD.FormatTypes) do
									if v.code == format then
										tab = k -- Grab the FormatType key
									end
								end
								tab = HD.FormatTypes[tab] -- Plug it back into the table
								
								text = tab.type[1]
								param = tab.code
								
								text = 'string.format("'..text..'", '..param..')'
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

end
	

