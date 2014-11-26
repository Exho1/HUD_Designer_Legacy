if CLIENT then
	-- Assorted stuff to remove clutter
	
	--// Shape settings
	function HD.OpenShapeSettings(id,mx,my)
		HD.CancelAlter() -- Make sure no shapes are altered while open
		HD.ShapeOptions = HD.ShapeOptions or {}
		local ShapeStuff = HD.GetShapeData(id)
		local Type = HD.GetShapeType(id)
		
			HD.ShapeOptions[id] = vgui.Create("DFrame", HD.Frame)
		HD.ShapeOptions[id]:SetSize(150, 120)
		HD.ShapeOptions[id]:SetPos(mx, my - 60)
		HD.ShapeOptions[id]:SetTitle("")
		HD.ShapeOptions[id]:SetDraggable(true)
		HD.ShapeOptions[id].btnMaxim:SetVisible( false )
		HD.ShapeOptions[id].btnMinim:SetVisible( false )
		HD.ShapeOptions[id].btnClose:SetVisible( true )
		HD.ShapeOptions[id].Paint = function()
			local self = HD.ShapeOptions[id]
			draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
		end
		HD.ShapeOptions[id].OnMousePressed = function()
			local self = HD.ShapeOptions[id]
			-- Make sure nothing moves
			HD.CurMovingData, HD.Moving, HD.CurSizeID, HD.Sizing = {}, false, nil, false
			
			-- Dragging code because I overrode the function
			self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
			self:MouseCapture( true )
			return
		end
		HD.ShapeOptions[id].btnClose.DoClick = function ( button ) 
			HD.CurMovingData, HD.Moving, HD.CurSizeID, HD.Sizing = {}, false, nil, false
			HD.ShapeOptions[id]:SetVisible(false) 
			HD.ShapeOptions[id] = nil
		end
		
			local NumLayer = vgui.Create( "DNumberWang", HD.ShapeOptions[id] )
		NumLayer:SetDecimals( 0 )
		NumLayer:SetMinMax( 1, HD.Layers+1 )
		NumLayer:SetValue( HD.CurLayer )
		NumLayer:SetPos(20, 30)
		NumLayer:SetSize(60, 25)
		NumLayer:SetTooltip("Change your shape's layer")
		NumLayer.OnValueChanged = function()
			local new = NumLayer:GetValue()
			if new == nil or new == 0 then return end
			
			if HD.Layers < new then
				HD.Layers = new
			end
			
			HD.EditShape(id, {layer=HD.CurLayer, newlayer=new}, "layer")
		end
		
		
		if Type == "draw.RoundedBox" then
				local NumCorner = vgui.Create( "DNumberWang", HD.ShapeOptions[id] )
			NumCorner:SetDecimals( 0 )
			NumCorner:SetMinMax( 0, 40 )
			NumCorner:SetValue( ShapeStuff.corner )
			NumCorner:SetPos(20, 80)
			NumCorner:SetSize(60, 25)
			NumCorner:SetTooltip("Change your shape's corner size")
			NumCorner.OnValueChanged = function()
				local new = NumCorner:GetValue()
				if new == nil or new == 0 then return end
				
				if new ~= ShapeStuff.corner then
					HD.EditShape(id, {corner=new}, "corner")
				end
			end
			-- Override click buttons to only move in increments of 2
			NumCorner.Up.DoClick = function( button, mcode ) NumCorner:SetValue( NumCorner:GetValue() + 2 ) end
			NumCorner.Down.DoClick = function( button, mcode ) NumCorner:SetValue( NumCorner:GetValue() - 2 ) end
		elseif Type == "draw.DrawText" then
				local Text = vgui.Create( "DTextEntry", HD.ShapeOptions[id] )	-- create the form as a child of frame
			Text:SetSize( 80, 25 )
			Text:SetPos( 20, 80 )
			Text:SetText( ShapeStuff.text )
			Text:SetFont("HD_Button")
			Text:SetTooltip("Enter your text here")
			Text.OnChange = function( self, val )
				HD.DrawnObjects[layer][Type][id].text = self:GetText() -- Set the new text
				
				local font = HD.DrawnObjects[layer][Type][id].font -- Adjust the size
				local width, height = HD.GetTextSize(self:GetText(), font)
				HD.DrawnObjects[layer][Type][id].width, HD.DrawnObjects[layer][Type][id].height = width, height
				
				local bound = HD.Boundaries[id] -- Gotta add new boundaries for the text
				HD.Boundaries[id].farx, HD.Boundaries[id].fary = bound.x + width, bound.y + height
			end
			
				local Font = vgui.Create( "DTextEntry", HD.ShapeOptions[id] )	-- create the form as a child of frame
			Font:SetSize( 80, 25 )
			Font:SetPos( 20, 130 )
			Font:SetText( ShapeStuff.font )
			Font:SetFont("HD_Button")
			Font:SetTooltip("Enter a valid font for your text")
			Font.OnEnter = function( self, val )
				HD.DrawnObjects[layer][Type][id].font = self:GetText() -- Set the new text
			end
			
				HD.ShapeOptions[id].Format = vgui.Create( "DTextEntry", HD.ShapeOptions[id] )	-- create the form as a child of frame
			HD.ShapeOptions[id].Format:SetSize( 80, 25 )
			HD.ShapeOptions[id].Format:SetPos( 20, 180 )
			HD.ShapeOptions[id].Format:SetText( HD.DrawnObjects[layer][Type][id].format or "Parameters" )
			HD.ShapeOptions[id].Format:SetFont("HD_Button")
			HD.ShapeOptions[id].Format:SetTooltip("string.format parameters")
			HD.ShapeOptions[id].Format.OnEnter = function( self )
				local val = string.Trim(self:GetText())

				if val ~= "Parameters" and val ~= "" then
					HD.DrawnObjects[layer][Type][id].text = Text:GetText()
					HD.DrawnObjects[layer][Type][id].format = val
					HD.ShapeOptions[id].Format:SetValue( val )
				end
			end
			
				local FormatHelp = vgui.Create( "DImageButton", HD.ShapeOptions[id] )
			FormatHelp:SetPos( 110, 185 )	
			FormatHelp:SetImage( "icon16/information.png" )	
			FormatHelp:SizeToContents()	
			FormatHelp:SetTooltip("Click me to go to Exho's help page")
			FormatHelp.DoClick = function()
				gui.OpenURL( "http://www.exho.comeze.com/huddesigner/help.html" )
			end
		end
		
			local Label1 = vgui.Create("DLabel", HD.ShapeOptions[id])
		Label1:SetPos(5, 10) 
		Label1:SetColor(Color(255,255,255)) 
		Label1:SetFont("HD_Smaller")
		Label1:SetText("Shape Layer:")
		Label1:SizeToContents() 
			local Label2 = vgui.Create("DLabel", HD.ShapeOptions[id])
		Label2:SetPos(5, 60) 
		Label2:SetColor(Color(255,255,255)) 
		Label2:SetFont("HD_Smaller")
		if Type == "draw.RoundedBox" then
			Label2:SetText("Corner Size:")
		elseif Type == "draw.DrawText" then
			Label2:SetText("Text:")
		end
		Label2:SizeToContents() 
			local Label3 = vgui.Create("DLabel", HD.ShapeOptions[id])
		Label3:SetPos(100, 60) 
		Label3:SetColor(Color(255,255,255)) 
		Label3:SetFont("HD_Smaller")
		Label3:SetText("ID: "..id)
		Label3:SizeToContents() 
		if Type == "draw.DrawText" then
				local Label4 = vgui.Create("DLabel", HD.ShapeOptions[id])
			Label4:SetPos(5, 110) 
			Label4:SetColor(Color(255,255,255)) 
			Label4:SetFont("HD_Smaller")
			Label4:SetText("Font: ")
			Label4:SizeToContents() 
			
			local Label4 = vgui.Create("DLabel", HD.ShapeOptions[id])
			Label4:SetPos(5, 160) 
			Label4:SetColor(Color(255,255,255)) 
			Label4:SetFont("HD_Smaller")
			Label4:SetText("Format: ")
			Label4:SizeToContents() 
			
			local w, h = HD.ShapeOptions[id]:GetSize()
			HD.ShapeOptions[id]:SetSize(w, h+100)
		end
	end
	
	--// Tutorial opener
	function HD.OpenTutorial()
			local Frame = vgui.Create("DFrame")
		Frame:SetSize(ScrW()-80,ScrH()-80)
		Frame:SetPos(40,40)
		Frame:SetTitle("")
		Frame:MakePopup()
		Frame:SetDraggable(false)
		Frame.btnMaxim:SetVisible( false )
		Frame.btnMinim:SetVisible( false )
		Frame.btnClose:SetVisible( true )
		Frame.Paint = function()
			draw.RoundedBox(0, 0, 0, Frame:GetWide(), Frame:GetTall(), Color(39, 174, 96))
			--draw.RoundedBox(0, Frame:GetWide()/2-10, 0, 20, Frame:GetTall(), Color(30, 30, 30))
		end
		
		surface.SetFont( "HD_Title" )

			local Title = vgui.Create("DLabel", Frame) 
		Title:SetSize(Frame:GetWide()/2, 0)
		Title:SetColor(Color(255,255,255)) 
		Title:SetFont("HD_Title")
		Title:SetText("Please choose a tutorial type to view") 
		Title:SizeToContents() 
		local w,h = surface.GetTextSize( Title:GetText() )
		Title:SetPos(ScrW()/2-w/1.5, ScrH()/2-120) 
		
			local Choice1 = vgui.Create( "DButton", Frame )
		Choice1:SetText( "Text" )
		Choice1:SetTextColor( Color(255,255,255,255) )
		Choice1:SetFont("HD_Title")
		Choice1:SetSize( 140, 60 ) 
		Choice1:SetPos( Frame:GetWide()/2-Choice1:GetWide()-10, Frame:GetTall()/2-Choice1:GetTall()/2 ) 
		Choice1.Paint = function()
			draw.RoundedBox( 0, 0, 0, Choice1:GetWide(), Choice1:GetTall(), Color(200, 79, 79,255) )
		end
		Choice1.DoClick = function()
			surface.PlaySound("buttons/button9.wav")
		end
		
			local Choice2 = vgui.Create( "DButton", Frame )
		Choice2:SetText( "Video" )
		Choice2:SetTextColor( Color(255,255,255,255) )
		Choice2:SetFont("HD_Title")
		Choice2:SetSize( 140, 60 ) 
		Choice2:SetPos( Frame:GetWide()/2+10, Frame:GetTall()/2-Choice2:GetTall()/2 ) 
		Choice2.Paint = function()
			draw.RoundedBox( 0, 0, 0, Choice2:GetWide(), Choice2:GetTall(), Color(200, 79, 79,255) )
		end
		Choice2.DoClick = function()
			Choice1:SetVisible(false)
			Choice2:SetVisible(false)
			Title:SetVisible(false)
			surface.PlaySound("buttons/button9.wav")
			
				local Video = vgui.Create( "HTML", Frame) 
			Video:SetSize( Frame:GetWide()-100, Frame:GetTall() - 100 )
			Video:SetPos(50, 50)
			Video:OpenURL("www.youtube.com/embed/JT6_r7Q-vxM") -- Set to the tutorial video later, get this url from embedd
			
				local Exit = vgui.Create( "DButton", Frame )
			Exit:SetText( "Exit" )
			Exit:SetTextColor( Color(255,255,255,255) )
			Exit:SetFont("HD_Title")
			Exit:SetSize( 80, 30 ) 
			Exit:SetPos( Frame:GetWide()/2+10, Frame:GetTall()-Exit:GetTall()-10 ) 
			Exit.Paint = function()
				draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
			end
			Exit.DoClick = function()
				Frame:Close()
				LocalPlayer():ConCommand( "hd_tutorial 0" )
				HD.OpenDesigner(true)
			end
			
				local Back = vgui.Create( "DButton", Frame )
			Back:SetText( "Back" )
			Back:SetTextColor( Color(255,255,255,255) )
			Back:SetFont("HD_Title")
			Back:SetSize( 80, 30 ) 
			Back:SetPos( Frame:GetWide()/2-Back:GetWide()-10, Frame:GetTall()-Back:GetTall()-10 ) 
			Back.Paint = function()
				draw.RoundedBox( 0, 0, 0, Back:GetWide(), Back:GetTall(), Color(66, 244, 123,255) )
			end
			Back.DoClick = function()
				Frame:Close()
				HD.OpenTutorial()
			end
			
		end
	end
	
	--// Tool functions 
	function HD.ToolFunctions(num)
		if num == HD.Tools.Create then -- Create shape
			local gs = HD.GridSize
			local width = HD.GridSize * 6
			local height = HD.GridSize * 8
			width, height = math.SnapTo(width,gs), math.SnapTo(height, gs)
			local x, y = HD.Canvas:GetWide()/2 - width/2, HD.Canvas:GetTall()/2 - height/2
			x, y = math.SnapTo(x, gs), math.SnapTo(y, gs)
			
			HD.AddShape(HD.ShapeID, x, y, width, height, HD.ChosenCol, 4, HD.CurLayer)
		elseif num == HD.Tools.Text then
			local gs = HD.GridSize
			local width = HD.GridSize * 6
			local height = HD.GridSize * 8
			width, height = math.SnapTo(width,gs), math.SnapTo(height, gs)
			local x, y = HD.Canvas:GetWide()/2 - width/2, HD.Canvas:GetTall()/2 - height/2
			x, y = math.SnapTo(x, gs), math.SnapTo(y, gs)
			
			local font = "Trebuchet24"
			local text = "Sample Text"
			
			HD.AddText(HD.ShapeID, x, y, text, font, HD.ChosenCol, HD.CurLayer)
		
		elseif num == HD.Tools.Color then -- Open color mixer panel
			HD.SetTool(HD.Tools.Color, "Color")
			
			if HD.ColMixerOpen then 
				HD.SetTool(nil)
				HD.ColMixer:SetVisible(false) HD.ColMixerOpen = false HD.ColMixer = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Color -- Parent related math
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
				HD.ColMixer = vgui.Create("DPanel", HD.Frame)
			HD.ColMixer:SetSize(260, 240)
			HD.ColMixer:SetPos(px-HD.ColMixer:GetWide()/4,40)
			HD.ColMixer.Paint = function()
				local self = HD.ColMixer
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				local Mixer = vgui.Create( "DColorMixer", HD.ColMixer )
			Mixer:SetSize(250, 230)
			Mixer:SetPos(5, 5)
			Mixer:SetPalette( false )
			Mixer:SetAlphaBar( true ) 	
			Mixer:SetWangs( true )
			Mixer:SetColor( HD.ChosenCol or HD.DefaultCol )
			Mixer.Think = function()
				HD.ChosenCol = Mixer:GetColor()
			end
			
			HD.ColMixerOpen = true
		elseif num == HD.Tools.Grid then -- Open grid changing panel
			if HD.GridOpen then 
				HD.SetTool(nil)
				HD.GridEditor:SetVisible(false) HD.GridOpen = false HD.GridEditor = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Grid
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
				HD.GridEditor = vgui.Create("DPanel", HD.Frame)
			HD.GridEditor:SetSize(80, 65)
			HD.GridEditor:SetPos(px-(HD.GridEditor:GetWide()/4), 40)
			HD.GridEditor.Paint = function()
				local self = HD.GridEditor
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				local GridEnabler = vgui.Create( "DCheckBoxLabel", HD.GridEditor )
			GridEnabler:SetPos( 5, 40 )
			GridEnabler:SetText( "Enabled" )
			GridEnabler:SetValue( HD.GridEnabled )	
			GridEnabler:SizeToContents()
			GridEnabler.OnChange = function( self, val )
				HD.GridEnabled = val
			end
			
				local Number = vgui.Create( "DNumberWang", HD.GridEditor )
			Number:SetDecimals( 0 )
			Number:SetMinMax( 2, 50 )
			Number:SetValue( HD.GridSize )
			Number:SetPos(5, 5)
			Number:SetSize(70, 25)
			Number.Think = function()
				if Number:GetValue() >= 2 and Number:GetValue() <= 50 then
					-- Gotta make sure that the grid can NEVER be too crazy otherwise your game crashes
					HD.GridSize = Number:GetValue()
				end
			end
			
			-- Custom button click functions cause control freak
			Number.Up.DoClick = function( button, mcode ) Number:SetValue( math.Clamp(Number:GetValue() + 2,2,50) ) end
			Number.Down.DoClick = function( button, mcode ) Number:SetValue( math.Clamp(Number:GetValue() - 2,2,50) ) end
			
			HD.GridOpen = true
		elseif num == HD.Tools.Layers then
			if HD.LayerOpen then 
				HD.SetTool(nil)
				HD.LayerSel:SetVisible(false) HD.LayerOpen = false HD.LayerView = false HD.LayerSel = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Layers
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
			local SizeAlter = 1
			if HD.Layers > 2 then SizeAlter = 2 end
			
				HD.LayerSel = vgui.Create("DScrollPanel", HD.Frame)
			HD.LayerSel:SetSize(180, 95*SizeAlter)
			HD.LayerSel:SetPos(px-(HD.LayerSel:GetWide()/4), 40)
			HD.LayerSel.Paint = function()
				local self = HD.LayerSel
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				local CurLay = vgui.Create("DLabel", HD.LayerSel)
			CurLay:SetPos(35, 5) 
			CurLay:SetColor(Color(255,255,255)) 
			CurLay:SetFont("HD_Smaller")
			CurLay:SetText("Current Layer: "..HD.CurLayer)
			CurLay:SizeToContents() 
			CurLay.Think = function()
				CurLay:SetText("Current Layer: "..HD.CurLayer)
			end
			
			local i = 1
			local YBuffer = 30
			local BarBuffer = 0
			if HD.Layers > 1 then BarBuffer = 15 end
			
			for i = 1, HD.Layers do		
				local Count 
					local Layer = vgui.Create("DButton", HD.LayerSel)
				Layer:SetPos(10, YBuffer)
				Layer:SetSize(HD.LayerSel:GetWide()-20-BarBuffer, 50)
				Layer:SetTextColor(Color(255,255,255))
				Layer:SetText("Layer: "..i.." Shapes: 0")
				Layer.Paint = function()
					local self = Layer
					local col = Color(90,90,90, 200)
					if Count == 0 then col.a = 100 end
					if HD.CurLayer == i then col.a = 255 else col.a = 200 end
					draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), col)
				end
				Layer.Think = function()
					for k, v in pairs(HD.DrawnObjects[i]) do
						Count = #v
					end
					Layer:SetText("Layer: "..i.." Shapes: "..Count)
				end
				Layer.DoClick = function()
					surface.PlaySound("buttons/button9.wav")
					HD.CurLayer = i
					HD.LayerView = true
				end
				
				YBuffer = YBuffer + Layer:GetTall() + 20
			end
			
			HD.LayerOpen = true
		elseif num == HD.Tools.Info then
			if HD.InfoOpen then
				HD.SetTool(nil)
				HD.InfoBar:SetVisible(false) HD.InfoOpen = false HD.InfoBar = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Info -- Parent related math
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
				HD.InfoBar = vgui.Create("DPanel", HD.Frame)
			HD.InfoBar:SetSize(120, 150)
			HD.InfoBar:SetPos(px-HD.InfoBar:GetWide()/4,40)
			HD.InfoBar.Paint = function()
				local self = HD.InfoBar
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
				draw.RoundedBox(0, 4, 4, self:GetWide()-8, self:GetTall()-8, Color(90, 90, 90))
			end
			
				local Title = vgui.Create("DLabel", HD.InfoBar)
			Title:SetPos(25, 5) 
			Title:SetColor(Color(255,255,255)) 
			Title:SetFont("HD_Smaller")
			Title:SetText("Information")
			Title:SizeToContents() 
			
				local L_CurLay = vgui.Create("DLabel", HD.InfoBar)
			L_CurLay:SetPos(10, 25) 
			L_CurLay:SetColor(Color(255,255,255)) 
			L_CurLay:SetFont("HD_Smaller")
			L_CurLay:SetText("Current Layer: "..HD.CurLayer)
			L_CurLay:SizeToContents() 
			L_CurLay.Think = function()
				L_CurLay:SetText("Current Layer: "..HD.CurLayer)
			end
			
				local L_LayCount = vgui.Create("DLabel", HD.InfoBar)
			L_LayCount:SetPos(10, 40) 
			L_LayCount:SetColor(Color(255,255,255)) 
			L_LayCount:SetFont("HD_Smaller")
			L_LayCount:SetText("Layer Count: "..HD.Layers)
			L_LayCount:SizeToContents() 
			L_LayCount.Think = function()
				L_LayCount:SetText("Layer Count: "..HD.Layers)
			end
			
				local L_ShaCount = vgui.Create("DLabel", HD.InfoBar)
			L_ShaCount:SetPos(10, 55) 
			L_ShaCount:SetColor(Color(255,255,255)) 
			L_ShaCount:SetFont("HD_Smaller")
			L_ShaCount:SetText("Shape Count: "..HD.ShapeCount-1)
			L_ShaCount:SizeToContents() 
			L_ShaCount.Think = function()
				L_ShaCount:SetText("Shape Count: "..HD.ShapeCount-1)
			end
			
				local L_GridSize = vgui.Create("DLabel", HD.InfoBar)
			L_GridSize:SetPos(10, 70) 
			L_GridSize:SetColor(Color(255,255,255)) 
			L_GridSize:SetFont("HD_Smaller")
			L_GridSize:SetText("Grid Size: "..HD.GridSize)
			L_GridSize:SizeToContents() 
			L_GridSize.Think = function()
				L_GridSize:SetText("Grid Size: "..HD.GridSize)
			end
			
				local L_GridOn = vgui.Create("DLabel", HD.InfoBar)
			L_GridOn:SetPos(10, 85) 
			L_GridOn:SetColor(Color(255,255,255)) 
			L_GridOn:SetFont("HD_Smaller")
			L_GridOn:SetText("Grid On: "..tostring(HD.GridEnabled))
			L_GridOn:SizeToContents() 
			L_GridOn.Think = function()
				L_GridOn:SetText("Grid On: "..tostring(HD.GridEnabled))
			end
			
			HD.InfoOpen = true
		elseif num == HD.Tools.Export then
			if HD.ExportOpen then 
				HD.SetTool(nil) 
				HD.Exporter:SetVisible(false) HD.ExportOpen = false HD.Exporter = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Export
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy

				HD.Exporter = vgui.Create("DPanel", HD.Frame)
			HD.Exporter:SetSize(150, 100)
			HD.Exporter:SetPos(px-(HD.Exporter:GetWide()/4), 40)
			HD.Exporter.Paint = function()
				local self = HD.Exporter
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
			local ExportData
				local CheckBox1 = vgui.Create( "DCheckBoxLabel", HD.Exporter )
			CheckBox1:SetPos( 10, 60 )
			CheckBox1:SetText( "Scale Size" )
			CheckBox1:SetValue( HD.ScaleSize )	
			CheckBox1:SizeToContents()
			CheckBox1.OnChange = function( self, val )
				-- Save the value and create the new code
				HD.ScaleSize = val
				ExportData = HD.CreateExportCode()
			end
			
				local CheckBox2 = vgui.Create( "DCheckBoxLabel", HD.Exporter )
			CheckBox2:SetPos( 10, 80 )
			CheckBox2:SetText( "Scale Position" )
			CheckBox2:SetValue( HD.ScalePos )	
			CheckBox2:SizeToContents()
			CheckBox2.OnChange = function( self, val )
				HD.ScalePos = val
				ExportData = HD.CreateExportCode()
			end
			
			-- Prepare the code for exporting
			local SaveLocation = nil
			ExportData = HD.CreateExportCode()
			
			-- Labels for user choice
				local LabelChoice = vgui.Create("DLabel", HD.Exporter)
			LabelChoice:SetPos(35, 5) 
			LabelChoice:SetColor(Color(255,255,255)) 
			LabelChoice:SetFont("HD_Smaller")
			LabelChoice:SetText("Save code to")
			LabelChoice:SizeToContents()
			
				local Console = vgui.Create( "DButton", HD.Exporter )
			Console:SetText( "Console" )
			Console:SetTextColor( Color(0,0,0) )
			Console:SetPos( 10, 25 ) 
			Console:SetSize( 60, 30 ) 
			Console.Paint = function()
				draw.RoundedBox( 0, 0, 0, Console:GetWide(), Console:GetTall(), Color(255, 255, 255 ))
			end
			Console.DoClick = function() -- Print HUD code to console
				surface.PlaySound("buttons/button9.wav")
				SaveLocation = "console"
				LabelChoice:SetText("Code Saved")
				LabelChoice:SizeToContents()
				LabelChoice:SetPos(40, 5) 
				
				print("")
				print("")
				print("")
				
				print("--// HUD Code exported by "..LocalPlayer():Nick().." using Exho's HUD Designer //--")
				print("--// Exported on "..os.date("%c").." //--")
				print("")
				print("local lp = LocalPlayer()")
				print("local wep = LocalPlayer():GetActiveWeapon()")
				print("")
				for layer, id in pairs(ExportData) do
					print("--Layer: "..layer)
					for k, v in pairs(id) do
						print(v)
					end
					print("")
				end
				print("")
				print("--// End HUD Code //--")
				print("")
				print("")
				print("")
			end
			
				local TxtFile = vgui.Create( "DButton", HD.Exporter )
			TxtFile:SetText( "Text File" )
			TxtFile:SetTextColor( Color(0,0,0) )
			TxtFile:SetPos( 80, 25 ) 
			TxtFile:SetSize( 60, 30 ) 
			TxtFile.Paint = function()
				draw.RoundedBox( 0, 0, 0, TxtFile:GetWide(), TxtFile:GetTall(), Color(255, 255, 255 ))
			end
			TxtFile.DoClick = function()-- Print HUD code to a txt document
				surface.PlaySound("buttons/button9.wav")
				print("Export text")
				
				SaveLocation = "text"
				LabelChoice:SetText("Code Saved")
				LabelChoice:SizeToContents()
				LabelChoice:SetPos(40, 5) 
				
				-- Get a file name going
				local Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
				local proj = HD.ProjectName
				for k, v in pairs(Banned) do -- Remove bad characters
					proj = string.gsub(proj, v, "-")
				end
				proj = string.gsub(proj, " ", "")
				local session = os.date("%H%M%S")
				session = string.gsub(session, ":", "")
				session = string.lower("export_"..proj.."_"..session)
	
				-- Create the code
				local Code = ""
				Code = Code.."--// HUD Code exported by "..LocalPlayer():Nick().." using Exho's HUD Designer //--\r\n"
				Code = Code.."--// Exported on "..os.date("%c").." //--\r\n\r\n"
				Code = Code.."local lp = LocalPlayer()\r\n"
				Code = Code.."local wep = LocalPlayer():GetActiveWeapon()\r\n\r\n"
					
				for layer, id in pairs(ExportData) do
					Code = Code.."--Layer: "..layer.."\r\n"
					for k, v in pairs(id) do
						Code = Code..v.."\r\n"
					end
					Code = Code.."\r\n"
				end
				Code = Code.."\r\n--// End HUD Code //--\r\n"
				
				-- Write to the directory
				file.CreateDir( "hud_designer" )
				file.Write( "hud_designer/"..session..".txt", Code)
			end
			
			HD.ExportOpen = true
		elseif num == HD.Tools.Save then -- Save current project in Json format
			HD.Save()
		elseif num == HD.Tools.Load then -- Load project from Json format
			-- Create a menu similar to the layer menu with all the available "save_" files
		
			HD.Load()
		end
	end
end

