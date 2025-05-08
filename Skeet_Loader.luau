local Loaderlibrary = {}
function Loaderlibrary:CreateWindow(arg)
	local InsideLibrary = {}
	local Settings = {
		Label1 = arg.Text1,
		Label2 = arg.Text2,
		Label3 = arg.Text3
	}

	local LoaderNever = Instance.new("ScreenGui",game.CoreGui)
	LoaderNever.Name = "LoaderNever"
	
	local BackMain = Instance.new("ImageLabel",LoaderNever)
	BackMain.Name = "BackMain"
	BackMain.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
	BackMain.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BackMain.BorderSizePixel = 2
	BackMain.Position = UDim2.new(0.340702921, 0, 0.273284316, 0)
	BackMain.Size = UDim2.new(0.318005174, 0, 0.453431368, 0)
	BackMain.ZIndex = 0
	BackMain.Image = "rbxassetid://8547666218"
	BackMain.ImageColor3 = Color3.fromRGB(12, 12, 12)
	BackMain.ScaleType = Enum.ScaleType.Tile
	BackMain.TileSize = UDim2.new(0, 8, 0, 8)
	
	local UserInputService = game:GetService("UserInputService")
	local dragging
	local dragInput
	local dragStart
	local startPos
	local function update(input)
		local delta = input.Position - dragStart
		BackMain.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	BackMain.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = BackMain.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	BackMain.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
	
	
	local BackMainUIStroker = Instance.new("UIStroke",BackMain)		
	BackMainUIStroker.Color = Color3.fromRGB(48, 45, 49)
	BackMainUIStroker.ApplyStrokeMode = "Border"

	
	
	local Gradient = Instance.new("ImageLabel")
	local GamesList = Instance.new("ImageLabel",BackMain)
	GamesList.Name = "GamesList"
	GamesList.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
	GamesList.BorderColor3 = Color3.fromRGB(0, 0, 0)
	GamesList.BorderSizePixel = 2
	GamesList.Position = UDim2.new(0.0168740451, 0, 0.0516627952, 0)
	GamesList.Size = UDim2.new(0.649694502, 0, 0.470270276, 0)
	GamesList.ZIndex = 0
	GamesList.Image = "rbxassetid://8547666218"
	GamesList.ImageColor3 = Color3.fromRGB(12, 12, 12)
	GamesList.ScaleType = Enum.ScaleType.Tile
	GamesList.TileSize = UDim2.new(0, 8, 0, 8)
	
	local GamesListUIStroker = Instance.new("UIStroke",GamesList)		
	GamesListUIStroker.Color = Color3.fromRGB(48, 45, 49)
	GamesListUIStroker.ApplyStrokeMode = "Border"
	
	
	
	
	local TextLabel = Instance.new("TextLabel")
	local ScrollingFrame = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	
	local MiscTab = Instance.new("ImageLabel")
	MiscTab.Name = "MiscTab"
	MiscTab.Parent = BackMain
	MiscTab.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
	MiscTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MiscTab.BorderSizePixel = 2
	MiscTab.Position = UDim2.new(0.0168740451, 0, 0.551662803, 0)
	MiscTab.Size = UDim2.new(0.965376794, 0, 0.413513511, 0)
	MiscTab.ZIndex = 0
	MiscTab.Image = "rbxassetid://8547666218"
	MiscTab.ImageColor3 = Color3.fromRGB(12, 12, 12)
	MiscTab.ScaleType = Enum.ScaleType.Tile
	MiscTab.TileSize = UDim2.new(0, 8, 0, 8)

	local MiscTabUIStroker = Instance.new("UIStroke",MiscTab)		
	MiscTabUIStroker.Color = Color3.fromRGB(48, 45, 49)
	MiscTabUIStroker.ApplyStrokeMode = "Border"

	
	
	local MiscLabel = Instance.new("TextLabel")
	
	local OptionsTab = Instance.new("ImageLabel",BackMain)
	OptionsTab.Name = "OptionsTab"
	OptionsTab.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
	OptionsTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
	OptionsTab.BorderSizePixel = 2
	OptionsTab.Position = UDim2.new(0.682861805, 0, 0.0516627952, 0)
	OptionsTab.Size = UDim2.new(0.299389005, 0, 0.470270276, 0)
	OptionsTab.ZIndex = 0
	OptionsTab.Image = "rbxassetid://8547666218"
	OptionsTab.ImageColor3 = Color3.fromRGB(12, 12, 12)
	OptionsTab.ScaleType = Enum.ScaleType.Tile
	OptionsTab.TileSize = UDim2.new(0, 8, 0, 8)
	local OptionsTabUIStroker = Instance.new("UIStroke",OptionsTab)		
	OptionsTabUIStroker.Color = Color3.fromRGB(48, 45, 49)
	OptionsTabUIStroker.ApplyStrokeMode = "Border"
	
	local OptionsLabel = Instance.new("TextLabel")
	local UnHookButton = Instance.new("TextButton")
	UnHookButton.Name = "UnHookButton"
	UnHookButton.Parent = OptionsTab
	UnHookButton.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
	UnHookButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UnHookButton.BorderSizePixel = 2
	UnHookButton.Position = UDim2.new(0.0612244904, 0, 0.75287354, 0)
	UnHookButton.Size = UDim2.new(0.877551019, 0, 0.201149419, 0)
	UnHookButton.Font = Enum.Font.Gotham
	UnHookButton.Text = "UnHook"
	UnHookButton.TextColor3 = Color3.fromRGB(189, 189, 189)
	UnHookButton.TextSize = 14.000
	UnHookButton.TextStrokeTransparency = 0.000
	UnHookButton.MouseButton1Click:Connect(function()
		LoaderNever:Remove()
	end)
	local UnHookButtonStroker = Instance.new("UIStroke",UnHookButton)		
	UnHookButtonStroker.Color = Color3.fromRGB(48, 45, 49)
	UnHookButtonStroker.ApplyStrokeMode = "Border"
	
	local Label1 = Instance.new("TextLabel")
	local VerionBetaLabel = Instance.new("TextLabel")
	local HwidcopiedLabel = Instance.new("TextLabel")

	Gradient.Name = "Gradient"
	Gradient.Parent = BackMain
	Gradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Gradient.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Gradient.BorderSizePixel = 0
	Gradient.Size = UDim2.new(1, 0, 0.00270270277, 0)
	Gradient.Image = "rbxassetid://8508019876"



	TextLabel.Parent = GamesList
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.BackgroundTransparency = 1.000
	TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.BorderSizePixel = 0
	TextLabel.Position = UDim2.new(0, 0, -0.068965517, 0)
	TextLabel.Size = UDim2.new(0, 83, 0, 22)
	TextLabel.Font = Enum.Font.Gotham
	TextLabel.Text = "Games List"
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.TextSize = 14.000
	TextLabel.TextStrokeTransparency = 0.000

	ScrollingFrame.Parent = GamesList
	ScrollingFrame.Active = true
	ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ScrollingFrame.BackgroundTransparency = 1.000
	ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScrollingFrame.BorderSizePixel = 0
	ScrollingFrame.Position = UDim2.new(0, 0, 0.0574712642, 0)
	ScrollingFrame.Size = UDim2.new(1, 0, 0.942528725, 0)
	ScrollingFrame.BottomImage = ""
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.ScrollBarThickness = 1
	ScrollingFrame.TopImage = ""

	UIListLayout.Parent = ScrollingFrame
	UIListLayout.Padding = UDim.new(0, 2);
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder


	MiscLabel.Name = "MiscLabel"
	MiscLabel.Parent = MiscTab
	MiscLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiscLabel.BackgroundTransparency = 1.000
	MiscLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MiscLabel.BorderSizePixel = 0
	MiscLabel.Position = UDim2.new(0, 0, -0.0689655393, 0)
	MiscLabel.Size = UDim2.new(0.124472573, 0, 0.143790856, 0)
	MiscLabel.Font = Enum.Font.Gotham
	MiscLabel.Text = "Misc"
	MiscLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	MiscLabel.TextSize = 14.000
	MiscLabel.TextStrokeTransparency = 0.000

	OptionsLabel.Name = "OptionsLabel"
	OptionsLabel.Parent = OptionsTab
	OptionsLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	OptionsLabel.BackgroundTransparency = 1.000
	OptionsLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	OptionsLabel.BorderSizePixel = 0
	OptionsLabel.Position = UDim2.new(0, 0, -0.068965517, 0)
	OptionsLabel.Size = UDim2.new(0.564625859, 0, 0.126436785, 0)
	OptionsLabel.Font = Enum.Font.Gotham
	OptionsLabel.Text = "Options"
	OptionsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	OptionsLabel.TextSize = 14.000
	OptionsLabel.TextStrokeTransparency = 0.000

	Label1.Name = ""
	Label1.Parent = OptionsTab
	Label1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Label1.BackgroundTransparency = 1.000
	Label1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Label1.BorderSizePixel = 0
	Label1.Position = UDim2.new(0.0612244904, 0, 0.0919540226, 0)
	Label1.Size = UDim2.new(0.877551019, 0, 0.0977011472, 0)
	Label1.Font = Enum.Font.Gotham
	Label1.Text = Settings.Label1
	Label1.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label1.TextSize = 14.000
	Label1.TextStrokeTransparency = 0.000
	Label1.TextXAlignment = Enum.TextXAlignment.Left

	VerionBetaLabel.Name = ""
	VerionBetaLabel.Parent = OptionsTab
	VerionBetaLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	VerionBetaLabel.BackgroundTransparency = 1.000
	VerionBetaLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	VerionBetaLabel.BorderSizePixel = 0
	VerionBetaLabel.Position = UDim2.new(0.0612244904, 0, 0.18965517, 0)
	VerionBetaLabel.Size = UDim2.new(0.877551019, 0, 0.0977011472, 0)
	VerionBetaLabel.Font = Enum.Font.Gotham
	VerionBetaLabel.Text = Settings.Label2
	VerionBetaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	VerionBetaLabel.TextSize = 14.000
	VerionBetaLabel.TextStrokeTransparency = 0.000
	VerionBetaLabel.TextXAlignment = Enum.TextXAlignment.Left

	HwidcopiedLabel.Name = ""
	HwidcopiedLabel.Parent = OptionsTab
	HwidcopiedLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HwidcopiedLabel.BackgroundTransparency = 1.000
	HwidcopiedLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HwidcopiedLabel.BorderSizePixel = 0
	HwidcopiedLabel.Position = UDim2.new(0.0612244904, 0, 0.287356317, 0)
	HwidcopiedLabel.Size = UDim2.new(0.877551019, 0, 0.0977011472, 0)
	HwidcopiedLabel.Font = Enum.Font.Gotham
	HwidcopiedLabel.Text = Settings.Label3
	HwidcopiedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	HwidcopiedLabel.TextSize = 14.000
	HwidcopiedLabel.TextStrokeTransparency = 0.000
	HwidcopiedLabel.TextXAlignment = Enum.TextXAlignment.Left

	local Tabs = Instance.new("Folder",BackMain)
	Tabs.Name = "Tabs"

	function InsideLibrary:CreateGame(Image,Name,Version)
		local TabTypes = {}

		local TridentTaber = Instance.new("Frame",Tabs)

		local TridentSurvivalButton = Instance.new("TextButton",ScrollingFrame)
		local TSIcon = Instance.new("ImageLabel",TridentSurvivalButton)
		local TSName = Instance.new("TextLabel",TridentSurvivalButton)
		local TSVersion = Instance.new("TextLabel",TridentSurvivalButton)

		TridentSurvivalButton.Name = "TridentSurvivalButton"
		TridentSurvivalButton.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		TridentSurvivalButton.BackgroundTransparency = 1--0.750
		TridentSurvivalButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TridentSurvivalButton.BorderSizePixel = 0
		TridentSurvivalButton.Size = UDim2.new(1, 0, 0.23, 0)
		TridentSurvivalButton.Font = Enum.Font.SourceSans
		TridentSurvivalButton.Text = ""
		TridentSurvivalButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		TridentSurvivalButton.TextSize = 14.000
		TridentSurvivalButton.MouseButton1Click:Connect(function()
			for i,v in next,Tabs:GetChildren() do
				v.Visible = false
			end
			for y,u in next,ScrollingFrame:GetChildren() do
				if u.ClassName ~= "UIListLayout" and u.ClassName ~= "UIPadding" then
					u.BackgroundTransparency = 1
					u.TSName.TextColor3 = Color3.fromRGB(111, 112, 111)
				end
			end	
			TridentTaber.Visible = true
			TridentSurvivalButton.BackgroundTransparency = 0.750
			TSName.TextColor3 = Color3.fromRGB(181, 207, 49)
		end)

		TSIcon.Name = "TSIcon"
		TSIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TSIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TSIcon.BorderSizePixel = 0
		TSIcon.Position = UDim2.new(0.0250783693, 0, 0, 0)
		TSIcon.Size = UDim2.new(0.125391856, 0, 1, 0)
		TSIcon.Image = Image

		TSName.Name = "TSName"
		TSName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TSName.BackgroundTransparency = 1.000
		TSName.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TSName.BorderSizePixel = 0
		TSName.Position = UDim2.new(0.184952974, 0, 0, 0)
		TSName.Size = UDim2.new(0.626959264, 0, 0.425000012, 0)
		TSName.Font = Enum.Font.Gotham
		TSName.Text = Name --"Trident Survival V4"
		TSName.TextColor3 = Color3.fromRGB(111, 112, 111)--Color3.fromRGB(181, 207, 49)
		TSName.TextSize = 14.000
		TSName.TextStrokeTransparency = 0.000
		TSName.TextXAlignment = Enum.TextXAlignment.Left

		TSVersion.Name = "TSVersion"
		TSVersion.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TSVersion.BackgroundTransparency = 1.000
		TSVersion.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TSVersion.BorderSizePixel = 0
		TSVersion.Position = UDim2.new(0.184952974, 0, 0.425000012, 0)
		TSVersion.Size = UDim2.new(0.626959264, 0, 0.425000012, 0)
		TSVersion.Font = Enum.Font.Gotham
		TSVersion.Text = Version --"Beta [ 0.3 ]"
		TSVersion.TextColor3 = Color3.fromRGB(143, 143, 143)
		TSVersion.TextSize = 14.000
		TSVersion.TextStrokeTransparency = 0.000
		TSVersion.TextXAlignment = Enum.TextXAlignment.Left
		
		function TabTypes:CreateGameVersion(Name)	
			local Versions = {}
			TridentTaber.Name = "TridentTaber"
			TridentTaber.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TridentTaber.BackgroundTransparency = 1.000
			TridentTaber.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TridentTaber.BorderSizePixel = 0
			TridentTaber.Position = UDim2.new(0.0162932798, 0, 0.551351368, 0)
			TridentTaber.Size = UDim2.new(0.965376794, 0, 0.413513511, 0)
			TridentTaber.Visible = false

			local TSVersions = Instance.new("ImageLabel",TridentTaber)
			TSVersions.Name = "TSVersions"
			TSVersions.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
			TSVersions.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TSVersions.BorderSizePixel = 2
			TSVersions.Position = UDim2.new(0.0168740321, 0, 0.120290317, 0)
			TSVersions.Size = UDim2.new(0.964135051, 0, 0.83006537, 0)
			TSVersions.ZIndex = 0
			TSVersions.Image = "rbxassetid://8547666218"
			TSVersions.ImageColor3 = Color3.fromRGB(12, 12, 12)
			TSVersions.ScaleType = Enum.ScaleType.Tile
			TSVersions.TileSize = UDim2.new(0, 8, 0, 8)

			local TSVersionsUIStroker = Instance.new("UIStroke",TSVersions)		
			TSVersionsUIStroker.Color = Color3.fromRGB(48, 45, 49)
			TSVersionsUIStroker.ApplyStrokeMode = "Border"

			local TsVersionFrame = Instance.new("ScrollingFrame",TSVersions)
			TsVersionFrame.Name = "TsVersionFrame"
			TsVersionFrame.Active = true
			TsVersionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TsVersionFrame.BackgroundTransparency = 1.000
			TsVersionFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TsVersionFrame.BorderSizePixel = 0
			TsVersionFrame.Size = UDim2.new(1, 0, 0.763779521, 0)
			TsVersionFrame.ScrollBarThickness = 1
			local UIListLayout_2 = Instance.new("UIListLayout",TsVersionFrame)
			UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
			
				
			function Versions:CreateGameVersions(Name,callback)
				local LoadButton = Instance.new("TextButton",OptionsTab)
				LoadButton.Name = "LoadButton"
				LoadButton.Visible = false
				LoadButton.BackgroundColor3 = Color3.fromRGB(17, 16, 17)
				LoadButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LoadButton.BorderSizePixel = 2
				LoadButton.Position = UDim2.new(0.0612244904, 0, 0.494252861, 0)
				LoadButton.Size = UDim2.new(0.877551019, 0, 0.201149419, 0)
				LoadButton.Font = Enum.Font.Gotham
				LoadButton.Text = "Load"
				LoadButton.TextColor3 = Color3.fromRGB(189, 189, 189)
				LoadButton.TextSize = 14.000
				LoadButton.TextStrokeTransparency = 0.000
				LoadButton.MouseButton1Click:Connect(function()
					LoaderNever:Remove()
					callback()
				end)
				local LoadButtonStroker = Instance.new("UIStroke",LoadButton)		
				LoadButtonStroker.Color = Color3.fromRGB(48, 45, 49)
				LoadButtonStroker.ApplyStrokeMode = "Border"

				local Beta3Button = Instance.new("TextButton", TsVersionFrame)
				Beta3Button.Name = "Beta3Button"
				Beta3Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Beta3Button.BackgroundTransparency = 1.000
				Beta3Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Beta3Button.BorderSizePixel = 0
				Beta3Button.Position = UDim2.new(0.00062771386, 0, 0, 0)
				Beta3Button.Size = UDim2.new(0, 456, 0, 23)
				Beta3Button.Font = Enum.Font.Gotham
				Beta3Button.Text = Name
				Beta3Button.TextColor3 = Color3.fromRGB(139, 139, 139)
				Beta3Button.TextSize = 14.000
				Beta3Button.TextStrokeTransparency = 0.000
				Beta3Button.TextXAlignment = Enum.TextXAlignment.Left
				Beta3Button.MouseButton1Click:Connect(function()
					for y,u in next,TsVersionFrame:GetChildren() do
						if u.ClassName == "TextButton" then
							u.TextColor3 = Color3.fromRGB(139, 139, 139)
						end
					end
					for y,u in next,OptionsTab:GetChildren() do
						if u.Name == "LoadButton" then
							u.Visible = false
						end
					end
					for y,u in Tabs:GetDescendants() do
						if u.ClassName == "TextButton" then
							u.TextColor3 = Color3.fromRGB(139, 139, 139)
						end
					end
					LoadButton.Visible = true
					Beta3Button.TextColor3 = Color3.fromRGB(181, 207, 49)
				end)
				local Beta3ButtonUIPadding = Instance.new("UIPadding",Beta3Button)
				Beta3ButtonUIPadding.PaddingLeft = UDim.new(0, 10)					
			end	
			return Versions
		end
		return TabTypes
	end	
	return InsideLibrary
end
return Loaderlibrary
