local clone_ref = cloneref or function(obj) return obj end

local TweenService = clone_ref(game:GetService("TweenService"))
local UserInputService = clone_ref(game:GetService("UserInputService"))
local HttpService = clone_ref(game:GetService("HttpService"))
local Players = clone_ref(game:GetService("Players"))
local CoreGui = clone_ref(game:GetService("CoreGui").RobloxGui)

local Library = {
    IsOpen = true,
    Unloaded = false,
    Flags = {},
    Signals = {},
    ActiveDropdownClose = nil,
    ActiveColorpickerClose = nil,
    NotificationPosition = "right",
    Theme = {
        MainBackground = Color3.fromRGB(23, 21, 19),
        SidebarBackground = Color3.fromRGB(16, 13, 14),
        CardBackground = Color3.fromRGB(16, 13, 14),
        ElementBackground = Color3.fromRGB(18, 16, 16),
        ElementHover = Color3.fromRGB(24, 21, 21),
        PopupBackground = Color3.fromRGB(16, 13, 14),
        OuterBorder = Color3.fromRGB(36, 34, 32),
        
        Accent = Color3.fromRGB(255, 168, 160),
        AccentDark = Color3.fromRGB(20, 20, 22),
        
        Text = Color3.fromRGB(235, 235, 238),
        TextDim = Color3.fromRGB(125, 125, 133),
        
        FontBold = Enum.Font.GothamBold,
        FontMedium = Enum.Font.GothamMedium,
        FontRegular = Enum.Font.Gotham,
        FontSemiBold = Font.new(Font.fromEnum(Enum.Font.Gotham).Family, Enum.FontWeight.SemiBold),
    }
}

if getgenv then 
    getgenv().flags = Library.Flags 
    getgenv().Library = Library
end

function Library:SetTheme(theme)
    if typeof(theme) == "table" then
        for k, v in pairs(theme) do
            Library.Theme[k] = v
        end
    end
end

function Library:GiveSignal(signal)
    table.insert(Library.Signals, signal)
    return signal
end

function Library:Unload()
    if Library.Unloaded then return end
    Library.Unloaded = true

    for i = #Library.Signals, 1, -1 do
        local conn = table.remove(Library.Signals, i)
        if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end
    if Library.OnUnloadCallback then
        pcall(Library.OnUnloadCallback)
    end
    if Library.ScreenGui then
        Library.ScreenGui:Destroy()
    end
    if Library.KeybindFrame and Library.KeybindFrame.Parent then
        Library.KeybindFrame:Destroy()
    end
    table.clear(Library.Flags)
end

function Library:OnUnload(fn)
    Library.OnUnloadCallback = fn
end

local SaveManager = {
    Parser = {
        Toggle = {
            Save = function(idx, obj)
                return { type = 'Toggle', idx = idx, value = obj.Value }
            end,
            Load = function(idx, data)
                if Library.Flags[idx] then
                    Library.Flags[idx]:SetValue(data.value)
                end
            end
        },
        Slider = {
            Save = function(idx, obj)
                return { type = 'Slider', idx = idx, value = tostring(obj.Value) }
            end,
            Load = function(idx, data)
                if Library.Flags[idx] then
                    Library.Flags[idx]:SetValue(data.value)
                end
            end
        },
        Dropdown = {
            Save = function(idx, obj)
                return { type = 'Dropdown', idx = idx, value = obj.Value, multi = obj.Multi }
            end,
            Load = function(idx, data)
                if Library.Flags[idx] then
                    Library.Flags[idx]:SetValue(data.value)
                end
            end
        },
        List = {
            Save = function(idx, obj)
                return { type = 'List', idx = idx, value = obj.Value, multi = obj.Multi }
            end,
            Load = function(idx, data)
                if Library.Flags[idx] then
                    Library.Flags[idx]:SetValue(data.value)
                end
            end
        },
        ColorPicker = {
            Save = function(idx, obj)
                local col = obj.Value
                local hex = typeof(col) == "Color3" and col:ToHex() or col
                return { type = 'ColorPicker', idx = idx, value = hex, transparency = obj.Transparency or (1 - (obj.Alpha or 1)) }
            end,
            Load = function(idx, data)
                if Library.Flags[idx] then
                    local col = (typeof(data.value) == "string" and (data.value:sub(1,1) == "#" or #data.value == 6)) and Color3.fromHex(data.value) or data.value
                    Library.Flags[idx]:SetValue(col, 1 - (data.transparency or 0))
                end
            end
        },
        KeyPicker = {
            Save = function(idx, obj)
                local val = obj.Value
                local keyName = "None"
                if val then
                    if val == Enum.UserInputType.MouseButton1 or val == "MB1" or val == "MouseButton1" then
                        keyName = "MB1"
                    elseif val == Enum.UserInputType.MouseButton2 or val == "MB2" or val == "MouseButton2" then
                        keyName = "MB2"
                    elseif val == Enum.UserInputType.MouseButton3 or val == "MB3" or val == "MouseButton3" then
                        keyName = "MB3"
                    elseif typeof(val) == "EnumItem" then
                        keyName = val.Name
                    else
                        keyName = tostring(val)
                    end
                end
                return { type = 'KeyPicker', idx = idx, key = keyName, mode = obj.Mode }
            end,
            Load = function(idx, data)
                local obj = Library.Flags[idx]
                if obj then
                    obj:SetValue({ data.key, data.mode })
                    if data.mode == "Always" then
                        obj:SetState(true)
                    else
                        obj.Held = false
                        obj.Toggled = false
                        obj:SetState(false)
                    end
                end
            end
        },
        Input = {
            Save = function(idx, obj)
                return { type = 'Input', idx = idx, text = obj.Value }
            end,
            Load = function(idx, data)
                if Library.Flags[idx] and typeof(data.text) == "string" then
                    Library.Flags[idx]:SetValue(data.text)
                end
            end
        }
    }
}

function Library:Create(class, properties)
    local object = Instance.new(class)
    local parent = properties["Parent"]
    for property, value in pairs(properties) do
        if property ~= "Name" and property ~= "Parent" then
            object[property] = value
        end
    end
    object.Name = properties["Name"] or ""
    if parent then
        object.Parent = parent
    end

    return object
end

function Library:GetDarkerColor(color, factor)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - (factor or 0.2), 0, 1))
end

local function FormatIcon(icon)
    if not icon then return "" end
    icon = tostring(icon)
    if tonumber(icon) then
        return "rbxassetid://" .. icon
    end
    return icon
end

local function Tween(instance, properties, duration)
    local tweenInfo = TweenInfo.new(
        duration or 0.18,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Library:Notify(notifyConfig)
    if typeof(notifyConfig) == "string" then
        notifyConfig = { Text = notifyConfig }
    end
    notifyConfig = notifyConfig or {}

    if not Library.ScreenGui then
        return nil
    end

    local pos = tostring(notifyConfig.Position or Library.NotificationPosition or "Right"):lower()
    local anchor, placement, align

    if pos == "left" then
        anchor = Vector2.new(0, 0)
        placement = UDim2.new(0, 16, 0, 16)
        align = Enum.HorizontalAlignment.Left
    elseif pos == "center" then
        anchor = Vector2.new(0.5, 0)
        placement = UDim2.new(0.5, 0, 0, 16)
        align = Enum.HorizontalAlignment.Center
    else
        anchor = Vector2.new(1, 0)
        placement = UDim2.new(1, -16, 0, 16)
        align = Enum.HorizontalAlignment.Right
    end

    local container = Library.NotifyContainer
    if not container or container.Parent ~= Library.ScreenGui then
        container = Library:Create("Frame", {
            Name = "Notifications",
            AnchorPoint = anchor,
            Position = placement,
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 200,
            Parent = Library.ScreenGui
        })

        Library:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = align,
            Padding = UDim.new(0, 8),
            Parent = container
        })

        Library.NotifyContainer = container
    else
        container.AnchorPoint = anchor
        container.Position = placement
        local layout = container:FindFirstChildOfClass("UIListLayout")
        if layout then
            layout.HorizontalAlignment = align
        end
    end

    local rawDescription = notifyConfig.Description or notifyConfig.Desc or notifyConfig.description or notifyConfig.desc
    local hasDescription = rawDescription ~= nil and tostring(rawDescription) ~= ""
    local duration = notifyConfig.Duration or 4
    local accent = notifyConfig.Color or Library.Theme.Accent

    local Card
    local CardStroke
    local CardCorner

    if hasDescription then
        local title = notifyConfig.Title or notifyConfig.Name or notifyConfig.Text or "Notification"
        local description = tostring(rawDescription)

        Card = Library:Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(0, notifyConfig.Width or 270, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme.CardBackground,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 201,
            Parent = container
        })

        CardCorner = Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = Card
        })

        CardStroke = Library:Create("UIStroke", {
            Color = Library.Theme.OuterBorder,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Transparency = 1,
            Parent = Card
        })

        Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = Card
        })

        Library:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
            Parent = Card
        })

        Library:Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = tostring(title),
            TextColor3 = accent,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            RichText = true,
            TextTransparency = 1,
            Parent = Card
        })

        Library:Create("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = Library.Theme.TextDim,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            RichText = true,
            TextTransparency = 1,
            Parent = Card
        })
    else
        local mainText = notifyConfig.Text or notifyConfig.Title or notifyConfig.Name or ""

        Card = Library:Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Library.Theme.CardBackground,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 201,
            Parent = container
        })

        CardCorner = Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 5),
            Parent = Card
        })

        CardStroke = Library:Create("UIStroke", {
            Color = Library.Theme.OuterBorder,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Transparency = 1,
            Parent = Card
        })

        Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 0),
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = Card
        })

        Library:Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = tostring(mainText),
            TextColor3 = notifyConfig.Color or Library.Theme.Text,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            RichText = true,
            TextTransparency = 1,
            Parent = Card
        })
    end

    local function FadeElements(transparency)
        Tween(Card, { BackgroundTransparency = transparency }, 0.2)
        Tween(CardStroke, { Transparency = transparency }, 0.2)
        for _, child in ipairs(Card:GetChildren()) do
            if child:IsA("TextLabel") then
                Tween(child, { TextTransparency = transparency }, 0.2)
            end
        end
    end

    FadeElements(0)

    local dismissed = false

    local function Dismiss()
        if dismissed then return end
        dismissed = true
        FadeElements(1)
        task.delay(0.22, function()
            if Card then
                Card:Destroy()
            end
        end)
    end

    Card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dismiss()
        end
    end)

    if duration > 0 then
        task.delay(duration, Dismiss)
    end

    return {
        Frame = Card,
        Dismiss = Dismiss
    }
end

local function EnableDragging(dragHandle, targetFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))

    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

function Library:InitKeybindList(config)
    if self.KeybindFrame and self.KeybindFrame.Parent then
        return self.KeybindList
    end
    if not self.ScreenGui then return nil end

    config = config or {}
    local visible = (config.Visible == true)
    local position = config.Position or UDim2.new(0, 24, 0.45, 0)

    local Container = Library:Create("Frame", {
        Name = "KeybindList",
        Position = position,
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 50,
        Parent = self.ScreenGui
    })

    self.KeybindFrame = Container

    Library:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        Parent = Container
    })

    local Header = Library:Create("Frame", {
        Name = "Header",
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Library.Theme.PopupBackground or Library.Theme.CardBackground or Color3.fromRGB(16, 14, 15),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        ZIndex = 51,
        Parent = Container
    })

    Library:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Header
    })

    Library:Create("UIStroke", {
        Color = Library.Theme.OuterBorder,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Header
    })

    Library:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        Parent = Header
    })

    Library:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = Header
    })

    local IconLabel = Library:Create("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10709790537",
        ImageColor3 = Library.Theme.Accent,
        ZIndex = 52,
        Parent = Header
    })

    local TitleLabel = Library:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = "Hotkeys",
        TextColor3 = Color3.fromRGB(240, 240, 245),
        Font = Library.Theme.FontBold,
        TextSize = 11,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 52,
        Parent = Header
    })

    EnableDragging(Header, Container)

    local ItemsHolder = Library:Create("Frame", {
        Name = "Items",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 51,
        Parent = Container
    })

    Library:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        Parent = ItemsHolder
    })

    local activeRows = {}

    local listAPI = {
        Container = Container,
        Header = Header,
        ItemsHolder = ItemsHolder,
        Rows = activeRows,
        SetVisible = function(self_api, isVis)
            Container.Visible = (isVis == true)
        end,
        UpdateKeybind = function(self_api, id, name, isActive)
            local row = activeRows[id]
            if isActive then
                if not row then
                    local RowFrame = Library:Create("Frame", {
                        Name = "Item_" .. tostring(id),
                        Size = UDim2.new(0, 0, 0, 18),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 51,
                        Parent = ItemsHolder
                    })

                    Library:Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 4),
                        Parent = RowFrame
                    })

                    local SwitchPill = Library:Create("Frame", {
                        Name = "Switch",
                        Size = UDim2.new(0, 22, 0, 14),
                        BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(20, 18, 19),
                        BackgroundTransparency = 0.4,
                        BorderSizePixel = 0,
                        ZIndex = 52,
                        Parent = RowFrame
                    })

                    Library:Create("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                        Parent = SwitchPill
                    })

                    Library:Create("UIStroke", {
                        Color = Library.Theme.OuterBorder,
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Parent = SwitchPill
                    })

                    local Knob = Library:Create("Frame", {
                        Name = "Knob",
                        Size = UDim2.new(0, 8, 0, 8),
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -3, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        ZIndex = 53,
                        Parent = SwitchPill
                    })

                    Library:Create("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                        Parent = Knob
                    })

                    local NamePill = Library:Create("Frame", {
                        Name = "NamePill",
                        Size = UDim2.new(0, 0, 0, 18),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(20, 18, 19),
                        BackgroundTransparency = 0.4,
                        BorderSizePixel = 0,
                        ZIndex = 52,
                        Parent = RowFrame
                    })

                    Library:Create("UICorner", {
                        CornerRadius = UDim.new(0, 5),
                        Parent = NamePill
                    })

                    Library:Create("UIStroke", {
                        Color = Library.Theme.OuterBorder,
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Parent = NamePill
                    })

                    Library:Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                        Parent = NamePill
                    })

                    local NameLabel = Library:Create("TextLabel", {
                        Name = "Label",
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Color3.fromRGB(235, 235, 240),
                        FontFace = Library.Theme.FontSemiBold,
                        TextSize = 11,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 53,
                        Parent = NamePill
                    })

                    activeRows[id] = { Frame = RowFrame, Label = NameLabel, Switch = SwitchPill, Knob = Knob }
                else
                    row.Label.Text = name
                    row.Frame.Visible = true
                end
            else
                if row then
                    row.Frame:Destroy()
                    activeRows[id] = nil
                end
            end
        end
    }

    Library.KeybindList = listAPI

    if Library.ActiveHotkeys then
        for id, info in pairs(Library.ActiveHotkeys) do
            listAPI:UpdateKeybind(id, info.Name, info.Active)
        end
    end

    return listAPI
end

function Library:SetKeybindListVisible(vis)
    if not self.KeybindList then
        self:InitKeybindList()
    end
    if self.KeybindList then
        self.KeybindList:SetVisible(vis)
    end
end

function Library:UpdateKeybindList(id, name, isActive)
    self.ActiveHotkeys = self.ActiveHotkeys or {}
    if isActive then
        self.ActiveHotkeys[id] = { Name = name, Active = true }
    else
        self.ActiveHotkeys[id] = nil
    end

    if not self.KeybindList then
        self:InitKeybindList()
    end
    if self.KeybindList then
        self.KeybindList:UpdateKeybind(id, name, isActive)
    end
end

function Library:CreateWindow(options)
    options = options or {}
    if typeof(options.Theme) == "table" then
        for k, v in pairs(options.Theme) do
            Library.Theme[k] = v
        end
    end
    local Title = options.Title or "luxe$ware"
    local Size = options.Size or UDim2.new(0, 780, 0, 520)
    local ToggleKey = options.ToggleKey or Enum.KeyCode.Insert
    local UserDisplay = options.User or "noname"

    if options.NotificationPosition or options.NotifyPosition then
        Library.NotificationPosition = options.NotificationPosition or options.NotifyPosition
    end

    local ScreenGui = Library:Create("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = CoreGui
    })
    Library.ScreenGui = ScreenGui

    ScreenGui.Destroying:Connect(function()
        Library:Unload()
    end)

    if options.KeybindList ~= false then
        Library:InitKeybindList(typeof(options.KeybindList) == "table" and options.KeybindList or nil)
    end

    local MainFrame = Library:Create("Frame", {
        Name = "MainFrame",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        BackgroundColor3 = Library.Theme.MainBackground,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = ScreenGui
    })

    local MainCorner = Library:Create("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = MainFrame
    })

    local MainStroke = Library:Create("UIStroke", {
        Color = Library.Theme.OuterBorder,
        Thickness = 1.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = MainFrame
    })

    local TopDrag = Library:Create("Frame", {
        Name = "TopDrag",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })
    EnableDragging(TopDrag, MainFrame)

    local Sidebar = Library:Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 180, 1, 0),
        BackgroundColor3 = Library.Theme.SidebarBackground,
        BorderSizePixel = 0,
        Parent = MainFrame
    })

    local SidebarCorner = Library:Create("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = Sidebar
    })

    local SidebarSquare = Library:Create("Frame", {
        Name = "SidebarSquare",
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -16, 0, 0),
        BackgroundColor3 = Library.Theme.SidebarBackground,
        BorderSizePixel = 0,
        Parent = Sidebar
    })

    local SidebarLine = Library:Create("Frame", {
        Name = "SidebarLine",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Library.Theme.OuterBorder,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Sidebar
    })

    EnableDragging(Sidebar, MainFrame)

    local LogoLabel = Library:Create("TextLabel", {
        Name = "Logo",
        Size = UDim2.new(1, 0, 0, 48),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        RichText = true,
        Text = Title,
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Sidebar
    })

    local TabsContainer = Library:Create("ScrollingFrame", {
        Name = "TabsContainer",
        Size = UDim2.new(1, -16, 1, -125),
        Position = UDim2.new(0, 8, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar
    })

    local TabsLayout = Library:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = TabsContainer
    })

    local UserProfile = Library:Create("Frame", {
        Name = "UserProfile",
        Size = UDim2.new(1, -24, 0, 40),
        Position = UDim2.new(0, 10, 1, -50),
        BackgroundTransparency = 1,
        Parent = Sidebar
    })

    local AvatarCircle = Library:Create("Frame", {
        Name = "Avatar",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 6, 0.5, -15),
        BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(30, 27, 28),
        BorderSizePixel = 0,
        Parent = UserProfile
    })

    local AvatarCorner = Library:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = AvatarCircle
    })

    local AvatarLetter = Library:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = string.sub(UserDisplay, 1, 1):lower(),
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 13,
        Parent = AvatarCircle
    })

    local UserName = Library:Create("TextLabel", {
        Name = "Username",
        Size = UDim2.new(1, -48, 1, 0),
        Position = UDim2.new(0, 44, 0, 0),
        BackgroundTransparency = 1,
        Text = UserDisplay,
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = UserProfile
    })

    local ContentArea = Library:Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -196, 1, -20),
        Position = UDim2.new(0, 188, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainFrame
    })

    local function MatchesToggleKey(input)
        local key = ToggleKey
        if typeof(key) == "string" then
            if key == "MB1" or key == "MouseButton1" then
                return input.UserInputType == Enum.UserInputType.MouseButton1
            elseif key == "MB2" or key == "MouseButton2" then
                return input.UserInputType == Enum.UserInputType.MouseButton2
            elseif key == "MB3" or key == "MouseButton3" then
                return input.UserInputType == Enum.UserInputType.MouseButton3
            elseif Enum.KeyCode[key] then
                return input.KeyCode == Enum.KeyCode[key]
            elseif Enum.UserInputType[key] then
                return input.UserInputType == Enum.UserInputType[key]
            end
        elseif typeof(key) == "EnumItem" then
            if key.EnumType == Enum.KeyCode then
                return input.KeyCode == key
            elseif key.EnumType == Enum.UserInputType then
                return input.UserInputType == key
            end
        end
        return false
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and MatchesToggleKey(input) then
            Library.IsOpen = not Library.IsOpen
            MainFrame.Visible = Library.IsOpen
        end
    end))

    local PopupsHolder = Library:Create("Frame", {
        Name = "PopupsHolder",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = MainFrame
    })

    local function CreateColumnsContainer(parentContainer)
        local LeftWrapper = Library:Create("Frame", {
            Name = "LeftWrapper",
            Size = UDim2.new(0.5, -6, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = parentContainer
        })

        local LeftColumn = Library:Create("ScrollingFrame", {
            Name = "LeftColumn",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ClipsDescendants = false,
            Parent = LeftWrapper
        })

        local LeftPad = Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            Parent = LeftColumn
        })

        local LeftLayout = Library:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = LeftColumn
        })

        local LeftTopFade = Library:Create("ImageLabel", {
            Name = "TopFade",
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, 0),
            Rotation = 180,
            BackgroundTransparency = 1,
            Image = "rbxassetid://15541064478",
            ImageColor3 = Library.Theme.MainBackground,
            Visible = false,
            ZIndex = 25,
            Active = false,
            Parent = LeftWrapper
        })

        local LeftBottomFade = Library:Create("ImageLabel", {
            Name = "BottomFade",
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 1, -24),
            Rotation = 0,
            BackgroundTransparency = 1,
            Image = "rbxassetid://15541064478",
            ImageColor3 = Library.Theme.MainBackground,
            Visible = false,
            ZIndex = 25,
            Active = false,
            Parent = LeftWrapper
        })

        local RightWrapper = Library:Create("Frame", {
            Name = "RightWrapper",
            Size = UDim2.new(0.5, -6, 1, 0),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = parentContainer
        })

        local RightColumn = Library:Create("ScrollingFrame", {
            Name = "RightColumn",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ClipsDescendants = false,
            Parent = RightWrapper
        })

        local RightPad = Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            Parent = RightColumn
        })

        local RightLayout = Library:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = RightColumn
        })

        local RightTopFade = Library:Create("ImageLabel", {
            Name = "TopFade",
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, 0),
            Rotation = 180,
            BackgroundTransparency = 1,
            Image = "rbxassetid://15541064478",
            ImageColor3 = Library.Theme.MainBackground,
            Visible = false,
            ZIndex = 25,
            Active = false,
            Parent = RightWrapper
        })

        local RightBottomFade = Library:Create("ImageLabel", {
            Name = "BottomFade",
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 1, -24),
            Rotation = 0,
            BackgroundTransparency = 1,
            Image = "rbxassetid://15541064478",
            ImageColor3 = Library.Theme.MainBackground,
            Visible = false,
            ZIndex = 25,
            Active = false,
            Parent = RightWrapper
        })

        local function SetupScrollFade(col, topFade, bottomFade)
            local function CheckFades()
                local canY = col.CanvasPosition.Y
                local absCanvasY = col.AbsoluteCanvasSize.Y
                local absWinY = col.AbsoluteWindowSize.Y
                local maxScroll = absCanvasY - absWinY

                if maxScroll > 2 then
                    topFade.Visible = (canY > 2)
                    bottomFade.Visible = (canY < maxScroll - 2)
                else
                    topFade.Visible = false
                    bottomFade.Visible = false
                end
            end

            col:GetPropertyChangedSignal("CanvasPosition"):Connect(CheckFades)
            col:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(CheckFades)
            col:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(CheckFades)
            task.defer(CheckFades)
        end

        SetupScrollFade(LeftColumn, LeftTopFade, LeftBottomFade)
        SetupScrollFade(RightColumn, RightTopFade, RightBottomFade)

        return LeftColumn, RightColumn
    end

    local GetOrCreateAddons
    local CreateColorpickerWidget
    local CreateSubmenuWidget
    local CreateKeybindWidget

    local function RegisterWidgetMethods(host, elementsContainer)
        function host:AddButton(btnConfig)
            if typeof(btnConfig) == "string" then
                btnConfig = { Name = btnConfig }
            end
            btnConfig = btnConfig or {}

            local Row = Library:Create("Frame", {
                Name = "ButtonRow",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = elementsContainer
            })

            local RowLayout = Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = Row
            })

            local rowButtons = {}

            local function RecalculateSizes()
                local count = #rowButtons
                local widthScale = 1 / count
                local marginOffset = math.floor((count - 1) * 6 / count)

                for idx, btnData in ipairs(rowButtons) do
                    btnData.Button.LayoutOrder = idx
                    btnData.Button.Size = UDim2.new(widthScale, -marginOffset, 1, 0)
                end
            end

            local function CreateButtonWidget(cfg)
                local name = cfg.Name or cfg.Text or "Button"
                local cb = cfg.Callback or function() end

                local Btn = Library:Create("TextButton", {
                    Name = "Btn_" .. name,
                    BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    Parent = Row
                })

                local BtnCorner = Library:Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = Btn
                })

                local BtnStroke = Library:Create("UIStroke", {
                    Color = Library.Theme.OuterBorder,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = Btn
                })

                local BtnLabel = Library:Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Library.Theme.Text,
                    FontFace = Library.Theme.FontSemiBold,
                    TextSize = 11,
                    Parent = Btn
                })

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(26, 23, 23) }, 0.15)
                    Tween(BtnLabel, { TextColor3 = Library.Theme.Text }, 0.15)
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16) }, 0.15)
                    Tween(BtnLabel, { TextColor3 = Library.Theme.Text }, 0.15)
                end)
                Btn.MouseButton1Down:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Library.Theme.SidebarBackground or Library.Theme.MainBackground or Color3.fromRGB(14, 12, 12) }, 0.08)
                end)
                Btn.MouseButton1Up:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(26, 23, 23) }, 0.08)
                end)
                Btn.MouseButton1Click:Connect(function()
                    cb()
                end)

                local btnData = {
                    Button = Btn,
                    Label = BtnLabel,
                    Row = Row
                }

                function btnData:AddButton(subConfig)
                    if typeof(subConfig) == "string" then
                        subConfig = { Name = subConfig }
                    end
                    subConfig = subConfig or {}

                    local isRight = (subConfig.Side and string.lower(tostring(subConfig.Side)) == "right")
                    local newBtnData = CreateButtonWidget(subConfig)

                    if isRight then
                        table.insert(rowButtons, newBtnData)
                    else
                        table.insert(rowButtons, 1, newBtnData)
                    end

                    RecalculateSizes()
                    return newBtnData
                end

                return btnData
            end

            local firstBtn = CreateButtonWidget(btnConfig)
            table.insert(rowButtons, firstBtn)
            RecalculateSizes()

            return firstBtn
        end

        function host:AddLabel(labelConfig)
            if typeof(labelConfig) == "string" then
                labelConfig = { Name = labelConfig }
            end
            labelConfig = labelConfig or {}

            local name = labelConfig.Name or labelConfig.Text or "Label"

            local Row = Library:Create("Frame", {
                Name = "LabelRow_" .. name,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = elementsContainer
            })

            local Label = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = name:lower(),
                TextColor3 = Library.Theme.TextDim,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row
            })

            local labelAPI = {
                Row = Row,
                Label = Label
            }

            function labelAPI:Set(newText)
                Label.Text = tostring(newText):lower()
            end

            function labelAPI:AddColorpicker(cpOptions)
                return CreateColorpickerWidget(Row, cpOptions, false)
            end

            function labelAPI:AddKeybind(kbConfig)
                return CreateKeybindWidget(Row, kbConfig, nil)
            end
            labelAPI.AddBind = labelAPI.AddKeybind

            function labelAPI:AddSubmenu(configOptions)
                return CreateSubmenuWidget(Row, configOptions, false)
            end
            labelAPI.AddSub = labelAPI.AddSubmenu
            labelAPI.AddSettings = labelAPI.AddSubmenu
            labelAPI.AddGear = labelAPI.AddSubmenu

            return labelAPI
        end

        function host:AddToggle(toggleConfig)
            if typeof(toggleConfig) == "string" then
                toggleConfig = { Name = toggleConfig }
            end
            toggleConfig = toggleConfig or {}

            local name = toggleConfig.Name or toggleConfig.Title or "Toggle"
            local flag = toggleConfig.Flag or toggleConfig.Name or name
            local existingObj = flag and Library.Flags[flag]
            local state = (existingObj and existingObj.Value ~= nil) and existingObj.Value or (toggleConfig.Default or false)
            local callback = toggleConfig.Callback or function() end

            local ToggleRow = Library:Create("TextButton", {
                Name = "Toggle_" .. name,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                Parent = elementsContainer
            })
            ToggleRow:SetAttribute("ToggleState", state)

            local ToggleLabel = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -38, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = name:lower(),
                TextColor3 = state and Library.Theme.Text or Library.Theme.TextDim,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ToggleRow
            })

            local Track = Library:Create("Frame", {
                Name = "Track",
                Size = UDim2.new(0, 28, 0, 14),
                Position = UDim2.new(1, -28, 0.5, -7),
                BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(22, 19, 20),
                BorderSizePixel = 0,
                Parent = ToggleRow
            })

            local TrackCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Track
            })

            local TrackStroke = Library:Create("UIStroke", {
                Color = state and Library.Theme.Accent or Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Track
            })

            local Knob = Library:Create("Frame", {
                Name = "Knob",
                Size = UDim2.new(0, 10, 0, 10),
                Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5),
                BackgroundColor3 = state and Library.Theme.AccentDark or Library.Theme.TextDim,
                BorderSizePixel = 0,
                Parent = Track
            })

            local KnobCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Knob
            })

            local Toggle = {
                Type = 'Toggle',
                Value = state,
                Default = toggleConfig.Default or false,
                Callback = callback,
                Changed = nil,
                Row = ToggleRow
            }

            function Toggle:Display()
                if Toggle.Value then
                    Tween(Track, { BackgroundColor3 = Library.Theme.Accent }, 0.15)
                    Tween(TrackStroke, { Color = Library.Theme.Accent }, 0.15)
                    Tween(Knob, { Position = UDim2.new(1, -12, 0.5, -5), BackgroundColor3 = Library.Theme.AccentDark }, 0.15)
                    Tween(ToggleLabel, { TextColor3 = Library.Theme.Text }, 0.15)
                else
                    Tween(Track, { BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(22, 19, 20) }, 0.15)
                    Tween(TrackStroke, { Color = Library.Theme.OuterBorder }, 0.15)
                    Tween(Knob, { Position = UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Library.Theme.TextDim }, 0.15)
                    Tween(ToggleLabel, { TextColor3 = Library.Theme.TextDim }, 0.15)
                end
                ToggleRow:SetAttribute("ToggleState", Toggle.Value)
            end

            function Toggle:SetValue(bool)
                if typeof(bool) == "table" and rawget(bool, "Value") ~= nil then bool = bool.Value end
                bool = (bool == true)
                Toggle.Value = bool
                Toggle:Display()
                if Toggle.Callback then pcall(Toggle.Callback, Toggle.Value) end
                if Toggle.Changed then pcall(Toggle.Changed, Toggle.Value) end
            end

            function Toggle:OnChanged(func)
                Toggle.Changed = func
                if typeof(func) == "function" then
                    pcall(func, Toggle.Value)
                end
            end

            function Toggle:Get() return Toggle.Value end
            function Toggle:GetValue() return Toggle.Value end
            Toggle.Set = Toggle.SetValue

            ToggleRow.MouseEnter:Connect(function()
                if not Toggle.Value then
                    Tween(ToggleLabel, { TextColor3 = Library.Theme.Text }, 0.15)
                    Tween(Knob, { BackgroundColor3 = Library.Theme.Text }, 0.15)
                end
            end)

            ToggleRow.MouseLeave:Connect(function()
                if not Toggle.Value then
                    Tween(ToggleLabel, { TextColor3 = Library.Theme.TextDim }, 0.15)
                    Tween(Knob, { BackgroundColor3 = Library.Theme.TextDim }, 0.15)
                end
            end)

            ToggleRow.MouseButton1Click:Connect(function()
                Toggle:SetValue(not Toggle.Value)
            end)

            if flag then
                Library.Flags[flag] = Toggle
            end

            function Toggle:AddColorpicker(cpOptions)
                return CreateColorpickerWidget(ToggleRow, cpOptions, true)
            end

            function Toggle:AddKeybind(kbConfig)
                return CreateKeybindWidget(ToggleRow, kbConfig, Toggle)
            end
            Toggle.AddBind = Toggle.AddKeybind

            function Toggle:AddSubmenu(configOptions)
                return CreateSubmenuWidget(ToggleRow, configOptions, true)
            end
            Toggle.AddSub = Toggle.AddSubmenu
            Toggle.AddSettings = Toggle.AddSubmenu
            Toggle.AddGear = Toggle.AddSubmenu

            return Toggle
        end

        function host:AddDropdown(dropdownConfig)
            if typeof(dropdownConfig) == "string" then
                dropdownConfig = { Name = dropdownConfig }
            end
            dropdownConfig = dropdownConfig or {}

            local Dropdown
            local name = dropdownConfig.Name or dropdownConfig.Title or "Dropdown"
            local flag = dropdownConfig.Flag or dropdownConfig.Name or name
            local items = dropdownConfig.Items or dropdownConfig.Values or {}
            local isMulti = dropdownConfig.Multi or false
            local callback = dropdownConfig.Callback or function() end
            local itemActiveColor = Library:GetDarkerColor(Library.Theme.Accent, 0.63)

            local existingObj = flag and Library.Flags[flag]
            local selected = {}
            if isMulti then
                local def = (existingObj and existingObj.Value ~= nil) and existingObj.Value or dropdownConfig.Default
                if typeof(def) == "table" then
                    for k, v in pairs(def) do
                        if typeof(k) == "number" then
                            selected[v] = true
                        elseif v == true then
                            selected[k] = true
                        end
                    end
                elseif def then
                    selected[def] = true
                end
            else
                selected = (existingObj and existingObj.Value ~= nil) and existingObj.Value or (dropdownConfig.Default or (items[1] or ""))
            end

            local function GetDisplayText()
                if isMulti then
                    local list = {}
                    for _, item in ipairs(items) do
                        if selected[item] then
                            table.insert(list, item)
                        end
                    end
                    if #list == 0 then
                        return "none"
                    else
                        return table.concat(list, ", ")
                    end
                else
                    return tostring(selected)
                end
            end

            local Row = Library:Create("Frame", {
                Name = "DropdownRow_" .. name,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent = elementsContainer
            })

            local Label = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -120, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = name:lower(),
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row
            })

            local DropBtn = Library:Create("TextButton", {
                Name = "DropBtn",
                Size = UDim2.new(0, 114, 0, 22),
                Position = UDim2.new(1, -114, 0.5, -11),
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = Row
            })

            local DropCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 5),
                Parent = DropBtn
            })

            local DropStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = DropBtn
            })

            local ValueLabel = Library:Create("TextLabel", {
                Name = "ValueLabel",
                Size = UDim2.new(1, -26, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = GetDisplayText(),
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = DropBtn
            })

            local Chevron = Library:Create("ImageLabel", {
                Name = "Chevron",
                Size = UDim2.new(0, 11, 0, 11),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://80852254608142",
                ImageColor3 = Library.Theme.TextDim,
                Parent = DropBtn
            })

            local isOpen = false
            local PopupList = nil
            local closeConnection = nil

            local function ClosePopup()
                if not isOpen then return end
                isOpen = false

                if closeConnection then
                    closeConnection:Disconnect()
                    closeConnection = nil
                end

                if PopupList then
                    PopupList:Destroy()
                    PopupList = nil
                end
            end

            local function OpenPopup()
                if isOpen then
                    ClosePopup()
                    return
                end

                if Library.ActiveDropdownClose then
                    Library.ActiveDropdownClose()
                end

                isOpen = true
                Library.ActiveDropdownClose = ClosePopup

                local maxVisible = 6
                local count = #items
                local visibleSlots = math.clamp(count, 1, maxVisible)
                local itemHeight = 22
                local gap = 3
                local verticalPadding = 8

                local popupHeight = verticalPadding + (visibleSlots * itemHeight) + math.max(0, (visibleSlots - 1) * gap)
                local totalContentHeight = verticalPadding + (count * itemHeight) + math.max(0, (count - 1) * gap)

                local mainPos = MainFrame.AbsolutePosition
                local btnPos = DropBtn.AbsolutePosition
                local popX = btnPos.X - mainPos.X
                local popY = btnPos.Y - mainPos.Y + DropBtn.AbsoluteSize.Y + 4

                PopupList = Library:Create("ScrollingFrame", {
                    Name = "DropdownPopup_" .. name,
                    Size = UDim2.new(0, DropBtn.AbsoluteSize.X, 0, popupHeight),
                    Position = UDim2.new(0, popX, 0, popY),
                    BackgroundColor3 = Library.Theme.PopupBackground or Library.Theme.CardBackground or Color3.fromRGB(16, 13, 14),
                    BorderSizePixel = 0,
                    ZIndex = 120,
                    ClipsDescendants = true,
                    Parent = PopupsHolder
                })

                local PopCorner = Library:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = PopupList
                })

                local PopStroke = Library:Create("UIStroke", {
                    Color = Library.Theme.OuterBorder,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = PopupList
                })

                local PopPadding = Library:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    Parent = PopupList
                })

                local PopLayout = Library:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, gap),
                    Parent = PopupList
                })

                if count > maxVisible then
                    PopupList.ScrollingEnabled = true
                    PopupList.ScrollBarThickness = 2
                    PopupList.ScrollBarImageColor3 = Library.Theme.Accent
                    PopupList.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight)
                else
                    PopupList.ScrollingEnabled = false
                    PopupList.ScrollBarThickness = 0
                    PopupList.CanvasSize = UDim2.new(0, 0, 0, 0)
                end

                for idx, item in ipairs(items) do
                    local isItemActive = isMulti and (selected[item] == true) or (selected == item)

                    local ItemBtn = Library:Create("TextButton", {
                        Name = "Item_" .. item,
                        Size = UDim2.new(1, 0, 0, itemHeight),
                        BackgroundColor3 = itemActiveColor,
                        BackgroundTransparency = isItemActive and 0.6 or 1,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 121,
                        LayoutOrder = idx,
                        Parent = PopupList
                    })

                    local ItemCorner = Library:Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ItemBtn
                    })

                    local ItemLabel = Library:Create("TextLabel", {
                        Name = "Label",
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        BackgroundTransparency = 1,
                        Text = item,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        FontFace = Library.Theme.FontSemiBold,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 122,
                        Parent = ItemBtn
                    })

                    ItemBtn.MouseEnter:Connect(function()
                        Tween(ItemBtn, { BackgroundColor3 = itemActiveColor, BackgroundTransparency = 0.6 }, 0.12)
                    end)

                    ItemBtn.MouseLeave:Connect(function()
                        local currentlyActive = isMulti and (selected[item] == true) or (selected == item)
                        if currentlyActive then
                            Tween(ItemBtn, { BackgroundColor3 = itemActiveColor, BackgroundTransparency = 0.6 }, 0.12)
                        else
                            Tween(ItemBtn, { BackgroundTransparency = 1 }, 0.12)
                        end
                    end)

                    ItemBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            selected[item] = not selected[item]
                            local nowActive = selected[item]
                            Tween(ItemBtn, { BackgroundColor3 = itemActiveColor, BackgroundTransparency = nowActive and 0.6 or 1 }, 0.1)
                            ValueLabel.Text = GetDisplayText()
                            if Dropdown then
                                Dropdown.Value = selected
                                if Dropdown.Changed then pcall(Dropdown.Changed, Dropdown.Value) end
                            end
                            callback(selected)
                        else
                            selected = item
                            ValueLabel.Text = GetDisplayText()
                            ClosePopup()
                            if Dropdown then
                                Dropdown.Value = selected
                                if Dropdown.Changed then pcall(Dropdown.Changed, Dropdown.Value) end
                            end
                            callback(selected)
                        end
                    end)
                end

                closeConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if not PopupList then return end
                        local mPos = input.Position
                        local bPos = DropBtn.AbsolutePosition
                        local bSize = DropBtn.AbsoluteSize
                        local pPos = PopupList.AbsolutePosition
                        local pSize = PopupList.AbsoluteSize

                        local inBtn = (mPos.X >= bPos.X and mPos.X <= bPos.X + bSize.X and mPos.Y >= bPos.Y and mPos.Y <= bPos.Y + bSize.Y)
                        local inPop = (mPos.X >= pPos.X and mPos.X <= pPos.X + pSize.X and mPos.Y >= pPos.Y and mPos.Y <= pPos.Y + pSize.Y)

                        if not inBtn and not inPop then
                            ClosePopup()
                        end
                    end
                end)
            end

            DropBtn.MouseButton1Click:Connect(OpenPopup)

            DropBtn.MouseEnter:Connect(function()
                Tween(DropBtn, { BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 21) }, 0.15)
            end)
            DropBtn.MouseLeave:Connect(function()
                Tween(DropBtn, { BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16) }, 0.15)
            end)

            Dropdown = {
                Type = 'Dropdown',
                Values = items,
                Value = selected,
                Multi = isMulti,
                Callback = callback,
                Changed = nil,
                Row = Row,
                Close = ClosePopup
            }

            function Dropdown:Display()
                ValueLabel.Text = GetDisplayText()
            end

            function Dropdown:SetValue(val)
                if typeof(val) == "table" and rawget(val, "Value") ~= nil then val = val.Value end
                if Dropdown.Multi then
                    Dropdown.Value = {}
                    if typeof(val) == "table" then
                        for k, v in pairs(val) do
                            if typeof(k) == "number" then
                                Dropdown.Value[v] = true
                            elseif v == true then
                                Dropdown.Value[k] = true
                            end
                        end
                    elseif val then
                        Dropdown.Value[val] = true
                    end
                else
                    Dropdown.Value = val
                end
                selected = Dropdown.Value
                Dropdown:Display()
                if Dropdown.Callback then pcall(Dropdown.Callback, Dropdown.Value) end
                if Dropdown.Changed then pcall(Dropdown.Changed, Dropdown.Value) end
            end

            function Dropdown:SetValues(newItems)
                if typeof(newItems) == "table" then
                    items = newItems
                    Dropdown.Values = newItems
                    if isMulti then
                        local valid = {}
                        for _, itm in ipairs(newItems) do valid[itm] = true end
                        for k, _ in pairs(selected) do
                            if not valid[k] then
                                selected[k] = nil
                            end
                        end
                    else
                        local found = false
                        for _, itm in ipairs(newItems) do
                            if itm == selected then
                                found = true
                                break
                            end
                        end
                        if not found then
                            selected = newItems[1] or ""
                        end
                    end
                    Dropdown.Value = selected
                    Dropdown:Display()
                    if isOpen then
                        ClosePopup()
                        OpenPopup()
                    end
                end
            end
            Dropdown.Refresh = Dropdown.SetValues

            function Dropdown:OnChanged(func)
                Dropdown.Changed = func
                if typeof(func) == "function" then
                    pcall(func, Dropdown.Value)
                end
            end

            function Dropdown:Get() return Dropdown.Value end
            function Dropdown:GetValue() return Dropdown.Value end
            Dropdown.Set = Dropdown.SetValue

            if flag then
                Library.Flags[flag] = Dropdown
            end

            return Dropdown
        end

        function host:AddSlider(sliderConfig)
            if typeof(sliderConfig) == "string" then
                sliderConfig = { Name = sliderConfig }
            end
            sliderConfig = sliderConfig or {}

            local name = sliderConfig.Name or sliderConfig.Title or "Slider"
            local flag = sliderConfig.Flag or sliderConfig.Name or name
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local step = sliderConfig.Round or sliderConfig.Step or 1
            local suffix = sliderConfig.Suffix or ""
            local existingObj = flag and Library.Flags[flag]
            local currentVal = (existingObj and existingObj.Value ~= nil) and existingObj.Value or (sliderConfig.Default or min)
            local callback = sliderConfig.Callback or function() end

            currentVal = math.clamp(currentVal, min, max)

            local function GetDecimals(num)
                local str = tostring(num)
                local dot = string.find(str, "%.")
                if dot then
                    return #str - dot
                end
                return 0
            end

            local decimals = GetDecimals(step)

            local function SnapValue(val)
                local snapped = math.floor((val - min) / step + 0.5) * step + min
                snapped = math.clamp(snapped, min, max)
                return tonumber(string.format("%." .. decimals .. "f", snapped))
            end

            currentVal = SnapValue(currentVal)

            local Row = Library:Create("Frame", {
                Name = "SliderRow_" .. name,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent = elementsContainer
            })

            local Label = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -120, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = name:lower(),
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row
            })

            local SliderBox = Library:Create("TextButton", {
                Name = "SliderBox",
                Size = UDim2.new(0, 114, 0, 22),
                Position = UDim2.new(1, -114, 0.5, -11),
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = Row
            })

            local SliderCorner = Library:Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = SliderBox })
            local SliderStroke = Library:Create("UIStroke", { Color = Library.Theme.OuterBorder, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = SliderBox })

            local ValueLabel = Library:Create("TextLabel", {
                Name = "ValueLabel",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = string.format("%." .. decimals .. "f", currentVal) .. suffix,
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 2,
                Parent = SliderBox
            })

            local InputBox = Library:Create("TextBox", {
                Name = "InputBox",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(currentVal),
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClearTextOnFocus = false,
                Visible = false,
                ZIndex = 4,
                Parent = SliderBox
            })

            local knobWidth = 8
            local pad = 3
            local trackWidth = 114 - knobWidth - (pad * 2)

            local Knob = Library:Create("Frame", {
                Name = "Knob",
                Size = UDim2.new(0, knobWidth, 0, 16),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 3,
                Parent = SliderBox
            })

            Library:Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Knob })

            local Slider = {
                Type = 'Slider',
                Value = currentVal,
                Min = min,
                Max = max,
                Rounding = decimals,
                Suffix = suffix,
                Callback = callback,
                Changed = nil,
                Row = Row
            }

            function Slider:Display()
                local percent = math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
                local knobX = pad + math.floor(percent * trackWidth)
                Knob.Position = UDim2.new(0, knobX, 0.5, -8)
                ValueLabel.Text = string.format("%." .. Slider.Rounding .. "f", Slider.Value) .. Slider.Suffix
            end

            function Slider:SetValue(val)
                if typeof(val) == "table" and rawget(val, "Value") ~= nil then val = val.Value end
                local num = tonumber(val)
                if not num then return end
                num = math.clamp(num, Slider.Min, Slider.Max)
                num = SnapValue(num)
                Slider.Value = num
                currentVal = num
                Slider:Display()
                if Slider.Callback then pcall(Slider.Callback, Slider.Value) end
                if Slider.Changed then pcall(Slider.Changed, Slider.Value) end
            end

            function Slider:OnChanged(func)
                Slider.Changed = func
                if typeof(func) == "function" then
                    pcall(func, Slider.Value)
                end
            end

            function Slider:Get() return Slider.Value end
            function Slider:GetValue() return Slider.Value end
            Slider.Set = Slider.SetValue

            Slider:Display()

            local isDragging = false

            local function CalculateFromMouse(inputX)
                local boxX = SliderBox.AbsolutePosition.X + pad
                local relX = math.clamp(inputX - boxX, 0, trackWidth)
                local percent = relX / trackWidth
                local rawVal = min + percent * (max - min)
                Slider:SetValue(rawVal)
            end

            SliderBox.InputBegan:Connect(function(input)
                if InputBox.Visible then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    CalculateFromMouse(input.Position.X)
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    InputBox.Text = tostring(Slider.Value)
                    ValueLabel.Visible = false
                    InputBox.Visible = true
                    task.defer(function()
                        InputBox:CaptureFocus()
                    end)
                end
            end)

            InputBox.FocusLost:Connect(function(enterPressed)
                local rawText = string.gsub(InputBox.Text, ",", ".")
                local num = tonumber(rawText)
                if num then
                    Slider:SetValue(num)
                else
                    Slider:Display()
                end
                task.defer(function()
                    InputBox.Visible = false
                    ValueLabel.Visible = true
                end)
            end)

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                if isDragging and not InputBox.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    CalculateFromMouse(input.Position.X)
                end
            end))

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end))

            SliderBox.MouseEnter:Connect(function()
                Tween(SliderBox, { BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 21) }, 0.15)
            end)
            SliderBox.MouseLeave:Connect(function()
                Tween(SliderBox, { BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16) }, 0.15)
            end)

            if flag then
                Library.Flags[flag] = Slider
            end

            return Slider
        end

        function host:AddList(listConfig)
            if typeof(listConfig) == "string" then
                listConfig = { Name = listConfig }
            end
            listConfig = listConfig or {}

            local name = listConfig.Name or listConfig.Title or "List"
            local flag = listConfig.Flag or listConfig.Name or name
            local items = listConfig.Items or {}
            local multi = listConfig.Multi ~= false
            local callback = listConfig.Callback or function() end
            local itemHeight = 24
            local gap = 4
            local padding = 6
            local fiveItemsHeight = (padding * 2) + (5 * itemHeight) + (4 * gap)
            local maxHeight = listConfig.MaxHeight or listConfig.Height or fiveItemsHeight
            local itemActiveColor = Library:GetDarkerColor(Library.Theme.Accent, 0.63)

            local List
            local selected = {}
            local default = listConfig.Default
            if multi then
                if typeof(default) == "table" then
                    for _, v in ipairs(default) do
                        selected[v] = true
                    end
                elseif default then
                    selected[default] = true
                end
            else
                selected = default or (items[1] or "")
            end

            local contentHeight = (padding * 2) + (#items * itemHeight) + math.max(0, (#items - 1) * gap)

            local Box = Library:Create("ScrollingFrame", {
                Name = "ListBox_" .. name,
                Size = UDim2.new(1, 0, 0, fiveItemsHeight),
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                BorderSizePixel = 0,
                ScrollBarThickness = contentHeight > fiveItemsHeight and 2 or 0,
                ScrollBarImageColor3 = Library.Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, contentHeight),
                ClipsDescendants = true,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = elementsContainer
            })

            local BoxCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Box
            })

            local BoxStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Box
            })

            Library:Create("UIPadding", {
                PaddingTop = UDim.new(0, padding),
                PaddingBottom = UDim.new(0, padding),
                PaddingLeft = UDim.new(0, padding),
                PaddingRight = UDim.new(0, padding),
                Parent = Box
            })

            Library:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, gap),
                Parent = Box
            })

            local itemRows = {}

            local function IsSelected(item)
                if multi then
                    return selected[item] == true
                end
                return selected == item
            end

            local function UpdateItem(item)
                local row = itemRows[item]
                if not row then return end
                local active = IsSelected(item)
                Tween(row.Button, {
                    BackgroundColor3 = itemActiveColor,
                    BackgroundTransparency = active and 0.6 or 1
                }, 0.12)
                Tween(row.Label, {
                    TextColor3 = active and Library.Theme.Accent or Library.Theme.Text
                }, 0.12)
            end

            local function CreateItemRow(item, idx)
                local ItemBtn = Library:Create("TextButton", {
                    Name = "Item_" .. tostring(item),
                    Size = UDim2.new(1, 0, 0, itemHeight),
                    BackgroundColor3 = itemActiveColor,
                    BackgroundTransparency = IsSelected(item) and 0.6 or 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    LayoutOrder = idx,
                    Parent = Box
                })

                Library:Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ItemBtn
                })

                local ItemLabel = Library:Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(item),
                    TextColor3 = IsSelected(item) and Library.Theme.Accent or Library.Theme.Text,
                    FontFace = Library.Theme.FontSemiBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = ItemBtn
                })

                itemRows[item] = { Button = ItemBtn, Label = ItemLabel }

                ItemBtn.MouseEnter:Connect(function()
                    if not IsSelected(item) then
                        Tween(ItemBtn, { BackgroundColor3 = itemActiveColor, BackgroundTransparency = 0.85 }, 0.12)
                    end
                end)

                ItemBtn.MouseLeave:Connect(function()
                    if not IsSelected(item) then
                        Tween(ItemBtn, { BackgroundTransparency = 1 }, 0.12)
                    end
                end)

                ItemBtn.MouseButton1Click:Connect(function()
                    if multi then
                        selected[item] = not selected[item]
                    else
                        selected = item
                    end

                    for _, other in ipairs(items) do
                        UpdateItem(other)
                    end

                    List.Value = selected
                    if List.Callback then pcall(List.Callback, List.Value) end
                    if List.Changed then pcall(List.Changed, List.Value) end
                end)
            end

            for idx, item in ipairs(items) do
                CreateItemRow(item, idx)
            end

            List = {
                Type = 'List',
                Value = selected,
                Multi = multi,
                Values = items,
                Box = Box,
                Row = Box,
                Callback = callback,
                Changed = nil
            }

            function List:Display()
                for _, other in ipairs(items) do
                    UpdateItem(other)
                end
            end

            function List:Get()
                return List.Value
            end
            List.GetValue = List.Get

            function List:SetValue(value)
                if multi then
                    selected = {}
                    if typeof(value) == "table" then
                        for k, v in pairs(value) do
                            if typeof(k) == "string" and v == true then
                                selected[k] = true
                            else
                                selected[v] = true
                            end
                        end
                    elseif value then
                        selected[value] = true
                    end
                else
                    selected = value
                end

                List.Value = selected
                List:Display()

                if List.Callback then pcall(List.Callback, List.Value) end
                if List.Changed then pcall(List.Changed, List.Value) end
            end
            List.Set = List.SetValue

            function List:OnChanged(func)
                List.Changed = func
                if typeof(func) == "function" then
                    pcall(func, List.Value)
                end
            end

            function List:Refresh(newItems)
                if newItems then
                    items = newItems
                    List.Values = items
                end
                for _, row in pairs(itemRows) do
                    if row.Button then
                        row.Button:Destroy()
                    end
                end
                table.clear(itemRows)

                local newContentHeight = (padding * 2) + (#items * itemHeight) + math.max(0, (#items - 1) * gap)

                Box.Size = UDim2.new(1, 0, 0, fiveItemsHeight)
                Box.CanvasSize = UDim2.new(0, 0, 0, newContentHeight)
                Box.ScrollBarThickness = newContentHeight > fiveItemsHeight and 2 or 0

                for idx, item in ipairs(items) do
                    CreateItemRow(item, idx)
                end
            end
            List.SetItems = List.Refresh
            List.SetValues = List.Refresh

            if flag then
                Library.Flags[flag] = List
            end

            return List
        end

        function host:AddTextbox(textboxConfig)
            if typeof(textboxConfig) == "string" then
                textboxConfig = { Name = textboxConfig }
            end
            textboxConfig = textboxConfig or {}

            local api
            local name = textboxConfig.Name or "Textbox"
            local flag = textboxConfig.Flag or textboxConfig.Name
            local existingObj = flag and Library.Flags[flag]
            local placeholder = textboxConfig.Placeholder or textboxConfig.PlaceHolder or textboxConfig.Name or "config name..."
            local defaultText = (existingObj and existingObj.Value ~= nil) and existingObj.Value or (textboxConfig.Default or textboxConfig.Text or "")
            local callback = textboxConfig.Callback or function() end

            local Row = Library:Create("Frame", {
                Name = "TextboxRow_" .. name,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = elementsContainer
            })

            local Box = Library:Create("TextBox", {
                Name = "Input",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                BorderSizePixel = 0,
                Text = defaultText,
                PlaceholderText = placeholder,
                PlaceholderColor3 = Library.Theme.TextDim,
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Parent = Row
            })

            local BoxCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = Box
            })

            local BoxStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Box
            })

            Library:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box
            })

            local lastValue = defaultText

            Box.Focused:Connect(function()
                Tween(BoxStroke, { Color = Library.Theme.Accent }, 0.15)
            end)

            Box.FocusLost:Connect(function(enterPressed)
                Tween(BoxStroke, { Color = Library.Theme.OuterBorder }, 0.15)
                local value = Box.Text
                if value ~= lastValue then
                    lastValue = value
                    if api then
                        api.Value = value
                        if api.Changed then pcall(api.Changed, value) end
                    end
                    callback(value, enterPressed)
                end
            end)

            api = {
                Type = 'Input',
                Value = defaultText,
                Callback = callback,
                Changed = nil,
                Box = Box,
                Row = Row
            }

            function api:Get()
                return api.Value
            end

            function api:GetValue()
                return api.Value
            end

            function api:SetValue(text)
                if typeof(text) == "table" and rawget(text, "Value") ~= nil then text = text.Value end
                text = tostring(text or "")
                api.Value = text
                Box.Text = text
                lastValue = text
                if api.Callback then pcall(api.Callback, text, false) end
                if api.Changed then pcall(api.Changed, text) end
            end
            api.Set = api.SetValue

            function api:OnChanged(func)
                api.Changed = func
                if typeof(func) == "function" then
                    pcall(func, api.Value)
                end
            end

            function api:Focus()
                Box:CaptureFocus()
            end

            function api:AddButton(buttonConfig)
                if typeof(buttonConfig) == "string" then
                    buttonConfig = { Text = buttonConfig }
                end
                buttonConfig = buttonConfig or {}

                local btnText = tostring(buttonConfig.Text or buttonConfig.Name or "button")
                local buttonHeight = buttonConfig.Height or 16
                local buttonWidth = buttonConfig.Width or math.clamp(#btnText * 6 + 18, 44, 60)

                Box.Size = UDim2.new(1, -(buttonWidth + 5), 1, 0)

                local Btn = Library:Create("TextButton", {
                    Name = "TextboxButton",
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    Parent = Row
                })

                local BtnCorner = Library:Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = Btn
                })

                local BtnStroke = Library:Create("UIStroke", {
                    Color = Library.Theme.OuterBorder,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = Btn
                })

                Library:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    Parent = Btn
                })

                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 4),
                    Parent = Btn
                })

                local icon = FormatIcon(buttonConfig.Icon)
                if icon ~= "" then
                    Library:Create("ImageLabel", {
                        Name = "Icon",
                        Size = UDim2.new(0, 10, 0, 10),
                        BackgroundTransparency = 1,
                        Image = icon,
                        ImageColor3 = Library.Theme.Text,
                        Parent = Btn
                    })
                end

                local BtnLabel = Library:Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Text = btnText,
                    TextColor3 = Library.Theme.Text,
                    FontFace = Library.Theme.FontSemiBold,
                    TextSize = 10,
                    Parent = Btn
                })

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 21) }, 0.15)
                end)

                Btn.MouseLeave:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16) }, 0.15)
                end)

                Btn.MouseButton1Click:Connect(function()
                    if buttonConfig.Callback then
                        buttonConfig.Callback(Box.Text, api)
                    end
                end)

                return {
                    Button = Btn,
                    Label = BtnLabel,
                    Row = Row
                }
            end

            api.SetValue = api.Set
            api.GetValue = api.Get

            if flag then
                Library.Flags[flag] = api
            end

            if textboxConfig.Button then
                api:AddButton(textboxConfig.Button)
            end

            return api
        end

        function host:AddKeybind(kbConfig)
            local label = host:AddLabel({ Name = (typeof(kbConfig) == "table" and (kbConfig.Name or kbConfig.Title)) or "Keybind" })
            return label:AddKeybind(kbConfig)
        end
        host.AddBind = host.AddKeybind
        host.AddKeyPicker = host.AddKeybind

        host.AddInput = host.AddTextbox
        host.AddTextBox = host.AddTextbox
    end


        local Keys = {
            [Enum.KeyCode.LeftShift] = "LS",
            [Enum.KeyCode.RightShift] = "RS",
            [Enum.KeyCode.LeftControl] = "LC",
            [Enum.KeyCode.RightControl] = "RC",
            [Enum.KeyCode.Insert] = "INS",
            [Enum.KeyCode.Backspace] = "BS",
            [Enum.KeyCode.Return] = "Ent",
            [Enum.KeyCode.LeftAlt] = "LA",
            [Enum.KeyCode.RightAlt] = "RA",
            [Enum.KeyCode.CapsLock] = "CAPS",
            [Enum.KeyCode.One] = "1",
            [Enum.KeyCode.Two] = "2",
            [Enum.KeyCode.Three] = "3",
            [Enum.KeyCode.Four] = "4",
            [Enum.KeyCode.Five] = "5",
            [Enum.KeyCode.Six] = "6",
            [Enum.KeyCode.Seven] = "7",
            [Enum.KeyCode.Eight] = "8",
            [Enum.KeyCode.Nine] = "9",
            [Enum.KeyCode.Zero] = "0",
            [Enum.KeyCode.KeypadOne] = "Num1",
            [Enum.KeyCode.KeypadTwo] = "Num2",
            [Enum.KeyCode.KeypadThree] = "Num3",
            [Enum.KeyCode.KeypadFour] = "Num4",
            [Enum.KeyCode.KeypadFive] = "Num5",
            [Enum.KeyCode.KeypadSix] = "Num6",
            [Enum.KeyCode.KeypadSeven] = "Num7",
            [Enum.KeyCode.KeypadEight] = "Num8",
            [Enum.KeyCode.KeypadNine] = "Num9",
            [Enum.KeyCode.KeypadZero] = "Num0",
            [Enum.KeyCode.Minus] = "-",
            [Enum.KeyCode.Equals] = "=",
            [Enum.KeyCode.Tilde] = "~",
            [Enum.KeyCode.LeftBracket] = "[",
            [Enum.KeyCode.RightBracket] = "]",
            [Enum.KeyCode.RightParenthesis] = ")",
            [Enum.KeyCode.LeftParenthesis] = "(",
            [Enum.KeyCode.Semicolon] = ",",
            [Enum.KeyCode.Quote] = "'",
            [Enum.KeyCode.BackSlash] = "\\",
            [Enum.KeyCode.Comma] = ",",
            [Enum.KeyCode.Period] = ".",
            [Enum.KeyCode.Slash] = "/",
            [Enum.KeyCode.Asterisk] = "*",
            [Enum.KeyCode.Plus] = "+",
            [Enum.KeyCode.Backquote] = "`",
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
            [Enum.KeyCode.Escape] = "ESC",
            [Enum.KeyCode.Space] = "SPC",
        }

        local function FormatKey(key)
            if not key then return "None" end
            if key == "MouseButton1" or key == "MB1" or key == Enum.UserInputType.MouseButton1 then return "MB1" end
            if key == "MouseButton2" or key == "MB2" or key == Enum.UserInputType.MouseButton2 then return "MB2" end
            if key == "MouseButton3" or key == "MB3" or key == Enum.UserInputType.MouseButton3 then return "MB3" end
            if Keys[key] then return Keys[key] end
            if typeof(key) == "EnumItem" then return key.Name end
            return tostring(key)
        end

        function GetOrCreateAddons(parentWidget, isToggle)
            local container = parentWidget:FindFirstChild("AddonsContainer")
            if not container then
                container = Library:Create("Frame", {
                    Name = "AddonsContainer",
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = isToggle and UDim2.new(1, -34, 0.5, 0) or UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    Parent = parentWidget
                })

                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                    Parent = container
                })

                local label = parentWidget:FindFirstChild("Label")
                if label and label:IsA("TextLabel") then
                    local function UpdateLabelBounds()
                        local rightSpace = (isToggle and 34 or 0) + container.AbsoluteSize.X + 8
                        label.Size = UDim2.new(1, -rightSpace, 1, 0)
                    end
                    container:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateLabelBounds)
                    task.defer(UpdateLabelBounds)
                end
            end
            return container
        end

        function CreateColorpickerWidget(parentWidget, cpConfig, isToggle)
            if typeof(cpConfig) == "function" then
                cpConfig = { Callback = cpConfig }
            end
            cpConfig = cpConfig or {}

            local cpAPI
            local defaultColor = cpConfig.Default or cpConfig.default or Color3.fromRGB(255, 255, 255)
            local defaultAlpha = cpConfig.Alpha or cpConfig.alpha or 1
            local flag = cpConfig.Flag or cpConfig.flag
            local existingObj = flag and Library.Flags[flag]
            if existingObj and existingObj.Value ~= nil then
                if typeof(existingObj.Value) == "Color3" then
                    defaultColor = existingObj.Value
                elseif typeof(existingObj.Value) == "table" then
                    defaultColor = existingObj.Value.Color or defaultColor
                    defaultAlpha = existingObj.Value.Alpha or defaultAlpha
                end
            end
            local callback = cpConfig.Callback or cpConfig.callback or function() end

            local h, s, v = defaultColor:ToHSV()
            local colorValue = defaultColor
            local alphaValue = defaultAlpha

            local addons = GetOrCreateAddons(parentWidget, isToggle)
            local colorBoxCount = 0
            for _, child in ipairs(addons:GetChildren()) do
                if child.Name:sub(1, 8) == "ColorBox" then
                    colorBoxCount = colorBoxCount + 1
                end
            end

            local ColorBox = Library:Create("TextButton", {
                Name = "ColorBox_" .. tostring(colorBoxCount + 1),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = true,
                LayoutOrder = 10 + colorBoxCount,
                ZIndex = 5,
                Parent = addons
            })

            local BoxCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = ColorBox
            })

            local BoxStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = ColorBox
            })

            local Checker = Library:Create("ImageLabel", {
                Name = "Checker",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://18274452449",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 15, 0, 15),
                ZIndex = 5,
                Parent = ColorBox
            })

            local CheckerCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = Checker
            })

            local Fill = Library:Create("Frame", {
                Name = "Fill",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = defaultColor,
                BackgroundTransparency = 1 - defaultAlpha,
                BorderSizePixel = 0,
                ZIndex = 6,
                Parent = ColorBox
            })

            local FillCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = Fill
            })

            local Popup = Library:Create("Frame", {
                Name = "ColorpickerPopup",
                Size = UDim2.new(0, 182, 0, 132),
                BackgroundColor3 = Library.Theme.PopupBackground or Library.Theme.CardBackground or Color3.fromRGB(16, 13, 14),
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 80,
                Parent = PopupsHolder
            })

            local PopCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Popup
            })

            local PopStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Popup
            })

            local SVMap = Library:Create("TextButton", {
                Name = "SVMap",
                Size = UDim2.new(0, 130, 0, 120),
                Position = UDim2.new(0, 6, 0, 6),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = true,
                ZIndex = 81,
                Parent = Popup
            })

            local SVCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = SVMap
            })

            local SVImage = Library:Create("ImageLabel", {
                Name = "SVImage",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://97638161873819",
                ZIndex = 82,
                Parent = SVMap
            })

            local SVCursor = Library:Create("Frame", {
                Name = "Cursor",
                Size = UDim2.new(0, 10, 0, 10),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(s, 0, 1 - v, 0),
                BackgroundColor3 = colorValue,
                BorderSizePixel = 0,
                ZIndex = 85,
                Parent = SVMap
            })

            local SVCursorCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = SVCursor
            })

            local SVCursorStroke = Library:Create("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 1.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = SVCursor
            })

            local HueBar = Library:Create("TextButton", {
                Name = "HueBar",
                Size = UDim2.new(0, 14, 0, 120),
                Position = UDim2.new(0, 142, 0, 6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = false,
                ZIndex = 81,
                Parent = Popup
            })

            local HueCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = HueBar
            })

            local HueGradient = Library:Create("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }),
                Parent = HueBar
            })

            local HueIndicator = Library:Create("Frame", {
                Name = "Indicator",
                Size = UDim2.new(1, 2, 0, 3),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, h, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 86,
                Parent = HueBar
            })

            Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 1),
                Parent = HueIndicator
            })

            Library:Create("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = HueIndicator
            })

            local AlphaBar = Library:Create("TextButton", {
                Name = "AlphaBar",
                Size = UDim2.new(0, 14, 0, 120),
                Position = UDim2.new(0, 162, 0, 6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = false,
                ZIndex = 81,
                Parent = Popup
            })

            local AlphaCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = AlphaBar
            })

            local AlphaChecker = Library:Create("ImageLabel", {
                Name = "Checker",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://18274452449",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 7, 0, 7),
                ZIndex = 81,
                Parent = AlphaBar
            })

            local AlphaCheckerCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = AlphaChecker
            })

            local AlphaFillFrame = Library:Create("Frame", {
                Name = "FillFrame",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 82,
                Parent = AlphaBar
            })

            local AlphaFillCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = AlphaFillFrame
            })

            local AlphaGradient = Library:Create("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, colorValue),
                    ColorSequenceKeypoint.new(1, colorValue)
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Parent = AlphaFillFrame
            })

            local AlphaIndicator = Library:Create("Frame", {
                Name = "Indicator",
                Size = UDim2.new(1, 2, 0, 3),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 1 - alphaValue, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 86,
                Parent = AlphaBar
            })

            Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 1),
                Parent = AlphaIndicator
            })

            Library:Create("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = AlphaIndicator
            })

            local function UpdateColor()
                colorValue = Color3.fromHSV(h, s, v)
                Fill.BackgroundColor3 = colorValue
                Fill.BackgroundTransparency = 1 - alphaValue
                SVCursor.BackgroundColor3 = colorValue
                SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                AlphaGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, colorValue),
                    ColorSequenceKeypoint.new(1, colorValue)
                })
                if cpAPI then
                    cpAPI.Value = colorValue
                    cpAPI.Alpha = alphaValue
                    cpAPI.Transparency = 1 - alphaValue
                    if cpAPI.Changed then pcall(cpAPI.Changed, colorValue, alphaValue) end
                end
                callback(colorValue, alphaValue)
            end

            local isDraggingSV = false
            local isDraggingHue = false
            local isDraggingAlpha = false

            local function UpdateSVFromMouse(inputPos)
                local sizeX, sizeY = SVMap.AbsoluteSize.X, SVMap.AbsoluteSize.Y
                local posX, posY = SVMap.AbsolutePosition.X, SVMap.AbsolutePosition.Y
                s = math.clamp((inputPos.X - posX) / sizeX, 0, 1)
                v = 1 - math.clamp((inputPos.Y - posY) / sizeY, 0, 1)
                SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                UpdateColor()
            end

            local function UpdateHueFromMouse(inputPos)
                local sizeY = HueBar.AbsoluteSize.Y
                local posY = HueBar.AbsolutePosition.Y
                h = math.clamp((inputPos.Y - posY) / sizeY, 0, 1)
                HueIndicator.Position = UDim2.new(0.5, 0, h, 0)
                SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                UpdateColor()
            end

            local function UpdateAlphaFromMouse(inputPos)
                local sizeY = AlphaBar.AbsoluteSize.Y
                local posY = AlphaBar.AbsolutePosition.Y
                alphaValue = 1 - math.clamp((inputPos.Y - posY) / sizeY, 0, 1)
                AlphaIndicator.Position = UDim2.new(0.5, 0, 1 - alphaValue, 0)
                UpdateColor()
            end

            SVMap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingSV = true
                    UpdateSVFromMouse(input.Position)
                end
            end)

            HueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingHue = true
                    UpdateHueFromMouse(input.Position)
                end
            end)

            AlphaBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingAlpha = true
                    UpdateAlphaFromMouse(input.Position)
                end
            end)

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if isDraggingSV then UpdateSVFromMouse(input.Position) end
                    if isDraggingHue then UpdateHueFromMouse(input.Position) end
                    if isDraggingAlpha then UpdateAlphaFromMouse(input.Position) end
                end
            end))

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingSV = false
                    isDraggingHue = false
                    isDraggingAlpha = false
                end
            end))

            local closeConn = nil
            local function ClosePopup()
                if not Popup.Visible then return end
                Popup.Visible = false
                if closeConn then
                    closeConn:Disconnect()
                    closeConn = nil
                end
            end

            local function OpenPopup()
                if Popup.Visible then
                    ClosePopup()
                    return
                end

                if Library.ActiveColorpickerClose then
                    Library.ActiveColorpickerClose()
                end
                if Library.ActiveDropdownClose then
                    Library.ActiveDropdownClose()
                end

                Popup.Visible = true
                Library.ActiveColorpickerClose = ClosePopup

                local mainPos = MainFrame.AbsolutePosition
                local btnPos = ColorBox.AbsolutePosition
                local popX = btnPos.X - mainPos.X - Popup.AbsoluteSize.X + ColorBox.AbsoluteSize.X
                local popY = btnPos.Y - mainPos.Y + ColorBox.AbsoluteSize.Y + 4

                popX = math.clamp(popX, 4, MainFrame.AbsoluteSize.X - Popup.AbsoluteSize.X - 4)
                popY = math.clamp(popY, 4, MainFrame.AbsoluteSize.Y - Popup.AbsoluteSize.Y - 4)

                Popup.Position = UDim2.new(0, popX, 0, popY)

                closeConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mx, my = input.Position.X, input.Position.Y
                        local px, py = Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
                        local sx, sy = Popup.AbsoluteSize.X, Popup.AbsoluteSize.Y
                        local cx, cy = ColorBox.AbsolutePosition.X, ColorBox.AbsolutePosition.Y
                        local csx, csy = ColorBox.AbsoluteSize.X, ColorBox.AbsoluteSize.Y

                        local inPop = (mx >= px and mx <= px + sx and my >= py and my <= py + sy)
                        local inBtn = (mx >= cx and mx <= cx + csx and my >= cy and my <= cy + csy)

                        if not inPop and not inBtn then
                            ClosePopup()
                        end
                    end
                end)
            end

            ColorBox.MouseButton1Click:Connect(OpenPopup)

            cpAPI = {
                Type = 'ColorPicker',
                Value = colorValue,
                Alpha = alphaValue,
                Transparency = 1 - alphaValue,
                Callback = callback,
                Changed = nil,
                Box = ColorBox,
                Close = ClosePopup
            }

            function cpAPI:Display()
                UpdateColor()
            end

            function cpAPI:SetValue(newColor, newAlpha)
                if typeof(newColor) == "table" then
                    if newColor.Color then
                        newAlpha = newColor.Alpha or newAlpha
                        newColor = newColor.Color
                    elseif newColor.R ~= nil and newColor.G ~= nil and newColor.B ~= nil then
                        newColor = Color3.new(newColor.R, newColor.G, newColor.B)
                    end
                elseif typeof(newColor) == "string" and (newColor:sub(1, 1) == "#" or #newColor == 6) then
                    pcall(function() newColor = Color3.fromHex(newColor) end)
                end
                if newColor and typeof(newColor) == "Color3" then
                    colorValue = newColor
                    local nh, ns, nv = colorValue:ToHSV()
                    h, s, v = nh, ns, nv
                    SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    HueIndicator.Position = UDim2.new(0.5, 0, h, 0)
                end
                if newAlpha and typeof(newAlpha) == "number" then
                    alphaValue = math.clamp(newAlpha, 0, 1)
                    AlphaIndicator.Position = UDim2.new(0.5, 0, 1 - alphaValue, 0)
                end
                cpAPI.Value = colorValue
                cpAPI.Alpha = alphaValue
                cpAPI.Transparency = 1 - alphaValue
                cpAPI:Display()
                if cpAPI.Callback then pcall(cpAPI.Callback, cpAPI.Value, cpAPI.Alpha) end
                if cpAPI.Changed then pcall(cpAPI.Changed, cpAPI.Value, cpAPI.Alpha) end
            end
            cpAPI.Set = cpAPI.SetValue
            cpAPI.SetColor = cpAPI.SetValue
            cpAPI.SetValueRGB = cpAPI.SetValue

            function cpAPI:OnChanged(func)
                cpAPI.Changed = func
                if typeof(func) == "function" then
                    pcall(func, cpAPI.Value, cpAPI.Alpha)
                end
            end

            function cpAPI:Get()
                return cpAPI.Value
            end

            function cpAPI:GetValue()
                return cpAPI.Value
            end

            function cpAPI:GetColor()
                return cpAPI.Value, cpAPI.Alpha
            end

            if flag then
                Library.Flags[flag] = cpAPI
            end

            return cpAPI
        end

        function CreateSubmenuWidget(parentWidget, configOptions, isToggle)
            if typeof(configOptions) == "string" then
                configOptions = { Name = configOptions }
            end
            configOptions = configOptions or {}
            local name = configOptions.Name or configOptions.Title or "Settings"

            local addons = GetOrCreateAddons(parentWidget, isToggle)

            local GearBtn = Library:Create("ImageButton", {
                Name = "GearBtn",
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundTransparency = 1,
                Image = "rbxassetid://102264797208719",
                ImageColor3 = Library.Theme.TextDim,
                LayoutOrder = 1,
                ZIndex = 5,
                Parent = addons
            })

            local popupWidth = (configOptions.Size and configOptions.Size.X.Offset) or 310
            local headerHeight = 34
            local maxContentHeight = configOptions.MaxHeight or 360
            local widgetScrollLimit = configOptions.ScrollAfter or 7
            local contentPadding = 20

            local Popup = Library:Create("Frame", {
                Name = "SubWindow_" .. name,
                Size = UDim2.new(0, popupWidth, 0, headerHeight),
                BackgroundColor3 = Library.Theme.CardBackground,
                BorderSizePixel = 0,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 80,
                Parent = PopupsHolder
            })

            local PopCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = Popup
            })

            local PopStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1.2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Popup
            })

            local HeaderBG = Library:Create("Frame", {
                Name = "HeaderBG",
                Size = UDim2.new(1, -2, 0, headerHeight),
                Position = UDim2.new(0, 1, 0, 1),
                BackgroundColor3 = Library.Theme.CardBackground,
                BorderSizePixel = 0,
                ZIndex = 89,
                Parent = Popup
            })

            local Header = Library:Create("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                ZIndex = 90,
                Parent = Popup
            })

            local TitleLabel = Library:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = name:lower(),
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.FontBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 91,
                Parent = Header
            })

            local CloseBtn = Library:Create("TextButton", {
                Name = "Close",
                Size = UDim2.new(0, 24, 0, 24),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                BackgroundTransparency = 1,
                Text = "x",
                TextColor3 = Library.Theme.TextDim,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                ZIndex = 91,
                Parent = Header
            })

            CloseBtn.MouseEnter:Connect(function()
                Tween(CloseBtn, { TextColor3 = Color3.fromRGB(255, 120, 120) }, 0.15)
            end)
            CloseBtn.MouseLeave:Connect(function()
                Tween(CloseBtn, { TextColor3 = Library.Theme.TextDim }, 0.15)
            end)

            local HeaderLine = Library:Create("Frame", {
                Name = "HeaderLine",
                Size = UDim2.new(1, -24, 0, 1),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundColor3 = Library.Theme.OuterBorder,
                BorderSizePixel = 0,
                ZIndex = 91,
                Parent = Header
            })

            local MainScroll = Library:Create("ScrollingFrame", {
                Name = "Elements",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, headerHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 0,
                TopImage = "",
                BottomImage = "",
                MidImage = "",
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollingEnabled = true,
                ClipsDescendants = true,
                ZIndex = 82,
                Parent = Popup
            })

            local ScrollLayout = Library:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = MainScroll
            })

            local ScrollPadding = Library:Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = MainScroll
            })

            local TopFade = Library:Create("ImageLabel", {
                Name = "TopFade",
                Size = UDim2.new(1, -10, 0, 18),
                Position = UDim2.new(0, 0, 0, headerHeight + 1),
                Rotation = 180,
                BackgroundTransparency = 1,
                Image = "rbxassetid://15541064478",
                ImageColor3 = Library.Theme.CardBackground,
                Visible = false,
                ZIndex = 85,
                Active = false,
                Parent = Popup
            })

            local BottomFade = Library:Create("ImageLabel", {
                Name = "BottomFade",
                Size = UDim2.new(1, -10, 0, 18),
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Rotation = 0,
                BackgroundTransparency = 1,
                Image = "rbxassetid://15541064478",
                ImageColor3 = Library.Theme.CardBackground,
                Visible = false,
                ZIndex = 85,
                Active = false,
                Parent = Popup
            })

            local ScrollTrack = Library:Create("Frame", {
                Name = "ScrollTrack",
                Size = UDim2.new(0, 3, 0, 0),
                Position = UDim2.new(1, -7, 0, headerHeight + 8),
                BackgroundColor3 = Library.Theme.OuterBorder,
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 88,
                Parent = Popup
            })

            Library:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = ScrollTrack
            })

            local ScrollThumb = Library:Create("Frame", {
                Name = "ScrollThumb",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                Visible = false,
                Active = true,
                ZIndex = 89,
                Parent = ScrollTrack
            })

            Library:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = ScrollThumb
            })

            local function UpdateScrollbar()
                local viewH = MainScroll.AbsoluteSize.Y
                local canvasH = MainScroll.CanvasSize.Y.Offset
                local maxScroll = math.max(0, canvasH - viewH)

                if maxScroll <= 2 or viewH <= 0 then
                    ScrollTrack.Visible = false
                    ScrollThumb.Visible = false
                    return
                end

                local trackH = math.max(0, viewH - 16)
                ScrollTrack.Visible = true
                ScrollThumb.Visible = true
                ScrollTrack.Size = UDim2.new(0, 3, 0, trackH)

                local thumbH = math.clamp(trackH * math.clamp(viewH / canvasH, 0, 1), 14, trackH)
                ScrollThumb.Size = UDim2.new(1, 0, 0, thumbH)

                local scrollRatio = math.clamp(MainScroll.CanvasPosition.Y / maxScroll, 0, 1)
                ScrollThumb.Position = UDim2.new(0, 0, 0, (trackH - thumbH) * scrollRatio)
            end

            local draggingThumb = false

            ScrollThumb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingThumb = true
                end
            end)

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingThumb = false
                end
            end))

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                if not draggingThumb then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

                local trackH = ScrollTrack.AbsoluteSize.Y
                local thumbH = ScrollThumb.AbsoluteSize.Y
                if trackH <= thumbH then return end

                local rel = math.clamp(input.Position.Y - ScrollTrack.AbsolutePosition.Y - (thumbH / 2), 0, trackH - thumbH)
                local maxScroll = math.max(0, MainScroll.CanvasSize.Y.Offset - MainScroll.AbsoluteSize.Y)
                MainScroll.CanvasPosition = Vector2.new(0, (rel / (trackH - thumbH)) * maxScroll)
            end))

            local function UpdateFades()
                local maxScroll = math.max(0, MainScroll.CanvasSize.Y.Offset - MainScroll.AbsoluteSize.Y)
                if maxScroll > 2 then
                    TopFade.Visible = MainScroll.CanvasPosition.Y > 2
                    BottomFade.Visible = MainScroll.CanvasPosition.Y < (maxScroll - 2)
                else
                    TopFade.Visible = false
                    BottomFade.Visible = false
                end
                UpdateScrollbar()
            end

            local function GetWidgetBottoms()
                local bottoms = {}
                for _, child in ipairs(MainScroll:GetChildren()) do
                    if child:IsA("GuiObject") then
                        local top = child.AbsolutePosition.Y - MainScroll.AbsolutePosition.Y + MainScroll.CanvasPosition.Y
                        table.insert(bottoms, top + child.AbsoluteSize.Y)
                    end
                end
                table.sort(bottoms)
                return bottoms
            end

            local function ResizeContents()
                local contentHeight = ScrollLayout.AbsoluteContentSize.Y + contentPadding
                local bottoms = GetWidgetBottoms()
                local visibleHeight = math.min(contentHeight, maxContentHeight)

                if #bottoms > widgetScrollLimit and bottoms[widgetScrollLimit] then
                    visibleHeight = math.min(visibleHeight, math.ceil(bottoms[widgetScrollLimit]) + 12)
                end

                MainScroll.Size = UDim2.new(1, 0, 0, visibleHeight)
                MainScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                Popup.Size = UDim2.new(0, popupWidth, 0, headerHeight + visibleHeight)

                UpdateFades()
                task.defer(UpdateFades)
            end

            ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeContents)
            MainScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateFades)
            MainScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(UpdateFades)
            task.defer(ResizeContents)

            local popupOpen = false
            local closeConn = nil

            local function ClosePopup()
                if not popupOpen then return end
                popupOpen = false
                Popup.Visible = false
                if closeConn then
                    closeConn:Disconnect()
                    closeConn = nil
                end
                Tween(GearBtn, { ImageColor3 = Library.Theme.TextDim }, 0.15)
            end

            local function PositionPopup()
                local mainPos = MainFrame.AbsolutePosition
                local btnPos = GearBtn.AbsolutePosition
                local popX = btnPos.X - mainPos.X + 24
                local popY = btnPos.Y - mainPos.Y

                popX = math.max(10, math.min(popX, MainFrame.AbsoluteSize.X - Popup.AbsoluteSize.X - 10))
                popY = math.max(10, math.min(popY, MainFrame.AbsoluteSize.Y - Popup.AbsoluteSize.Y - 10))

                Popup.Position = UDim2.new(0, popX, 0, popY)
            end

            local function OpenPopup()
                if popupOpen then
                    ClosePopup()
                    return
                end

                popupOpen = true
                Popup.Visible = true
                Tween(GearBtn, { ImageColor3 = Library.Theme.Accent }, 0.15)

                PositionPopup()
                task.defer(function()
                    if popupOpen then
                        PositionPopup()
                    end
                end)

                closeConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mx, my = input.Position.X, input.Position.Y
                        local px, py = Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
                        local sx, sy = Popup.AbsoluteSize.X, Popup.AbsoluteSize.Y
                        local gx, gy = GearBtn.AbsolutePosition.X, GearBtn.AbsolutePosition.Y
                        local gsx, gsy = GearBtn.AbsoluteSize.X, GearBtn.AbsoluteSize.Y

                        local inPop = (mx >= px and mx <= px + sx and my >= py and my <= py + sy)
                        local inBtn = (mx >= gx and mx <= gx + gsx and my >= gy and my <= gy + gsy)

                        if not inPop and not inBtn then
                            ClosePopup()
                        end
                    end
                end)
            end

            GearBtn.MouseEnter:Connect(function()
                if not popupOpen then
                    Tween(GearBtn, { ImageColor3 = Library.Theme.Text }, 0.15)
                end
            end)
            GearBtn.MouseLeave:Connect(function()
                if not popupOpen then
                    Tween(GearBtn, { ImageColor3 = Library.Theme.TextDim }, 0.15)
                end
            end)
            GearBtn.MouseButton1Click:Connect(OpenPopup)
            CloseBtn.MouseButton1Click:Connect(ClosePopup)

            local subAPI = {
                Popup = Popup,
                Container = MainScroll,
                Open = OpenPopup,
                Close = ClosePopup
            }

            RegisterWidgetMethods(subAPI, MainScroll)

            local tabGroupCreated = false
            local tabButtons = {}
            local TabsHolder, TabBar, TabContentArea

            local function EnsureTabGroup()
                if tabGroupCreated then return end
                tabGroupCreated = true

                TabsHolder = Library:Create("Frame", {
                    Name = "TabsHolder",
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    LayoutOrder = 999,
                    Parent = MainScroll
                })

                local TabsHolderLayout = Library:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 8),
                    Parent = TabsHolder
                })

                TabBar = Library:Create("Frame", {
                    Name = "TabBar",
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabsHolder
                })

                local TabBarLayout = Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = TabBar
                })

                TabContentArea = Library:Create("Frame", {
                    Name = "TabContentArea",
                    Size = UDim2.new(1, 0, 0, configOptions.TabHeight or 210),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                    Parent = TabsHolder
                })
            end

            function subAPI:CreateTab(tabName)
                EnsureTabGroup()
                tabName = tostring(tabName)

                local TabBtn = Library:Create("TextButton", {
                    Name = "TabBtn_" .. tabName,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(36, 32, 34),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = tabName:lower(),
                    TextColor3 = Library.Theme.TextDim,
                    FontFace = Library.Theme.FontSemiBold,
                    TextSize = 11,
                    Parent = TabBar
                })

                local TabBtnCorner = Library:Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = TabBtn
                })

                local TabBtnPadding = Library:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    Parent = TabBtn
                })

                local TabScroll = Library:Create("ScrollingFrame", {
                    Name = "TabScroll_" .. tabName,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Library.Theme.Accent,
                    TopImage = "",
                    BottomImage = "",
                    MidImage = "",
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    Visible = false,
                    ClipsDescendants = true,
                    Parent = TabContentArea
                })

                local TabScrollLayout = Library:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = TabScroll
                })

                local TabScrollPadding = Library:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 0),
                    PaddingRight = UDim.new(0, 4),
                    Parent = TabScroll
                })

                local tabEntry = {
                    Button = TabBtn,
                    Scroll = TabScroll
                }
                table.insert(tabButtons, tabEntry)

                local function SwitchTo()
                    for _, entry in ipairs(tabButtons) do
                        local isActive = (entry == tabEntry)
                        entry.Scroll.Visible = isActive
                        if isActive then
                            entry.Button.BackgroundTransparency = 0
                            entry.Button.TextColor3 = Library.Theme.Text
                        else
                            entry.Button.BackgroundTransparency = 1
                            entry.Button.TextColor3 = Library.Theme.TextDim
                        end
                    end
                end

                TabBtn.MouseButton1Click:Connect(SwitchTo)

                if #tabButtons == 1 then
                    SwitchTo()
                end

                local tabAPI = {
                    Frame = TabScroll,
                    Container = TabScroll
                }
                RegisterWidgetMethods(tabAPI, TabScroll)

                return tabAPI
            end

            subAPI.AddTab = subAPI.CreateTab

            function subAPI:CreateTabs(tabList)
                local tabsMap = {}
                for _, tName in ipairs(tabList) do
                    local tAPI = subAPI:CreateTab(tName)
                    tabsMap[tName] = tAPI
                    tabsMap[tName:lower()] = tAPI
                end
                return tabsMap
            end
            subAPI.AddTabs = subAPI.CreateTabs

            return subAPI
        end

        function CreateKeybindWidget(parentWidget, kbConfig, isToggle)
            if typeof(kbConfig) == "string" then
                kbConfig = { Name = kbConfig }
            end
            kbConfig = kbConfig or {}

            local name = kbConfig.Name or "Keybind"
            local flag = kbConfig.Flag or kbConfig.flag
            local currentKey = kbConfig.Default or kbConfig.Key or kbConfig.default
            if typeof(currentKey) == "string" then
                if currentKey == "None" or currentKey == "NONE" then
                    currentKey = nil
                elseif currentKey == "MB1" or currentKey == "MouseButton1" then
                    currentKey = Enum.UserInputType.MouseButton1
                elseif currentKey == "MB2" or currentKey == "MouseButton2" then
                    currentKey = Enum.UserInputType.MouseButton2
                elseif currentKey == "MB3" or currentKey == "MouseButton3" then
                    currentKey = Enum.UserInputType.MouseButton3
                else
                    currentKey = Enum.KeyCode[currentKey] or currentKey
                end
            end

            local currentMode = kbConfig.Mode or kbConfig.DefaultMode or "Toggle"
            if currentMode ~= "Hold" and currentMode ~= "Toggle" and currentMode ~= "Always" then
                currentMode = "Toggle"
            end

            local lockMode = (kbConfig.LockMode == true or kbConfig.lockMode == true)
            local callback = kbConfig.Callback or kbConfig.callback or function() end
            local isToggleRow = (isToggle == true or typeof(isToggle) == "table")
            local parentToggle = (typeof(isToggle) == "table" and isToggle.Type == "Toggle") and isToggle or nil

            local isActive = (currentMode == "Always")
            if kbConfig.State ~= nil then
                isActive = (kbConfig.State == true)
            elseif kbConfig.Value ~= nil then
                isActive = (kbConfig.Value == true)
            elseif kbConfig.DefaultState ~= nil then
                isActive = (kbConfig.DefaultState == true)
            elseif kbConfig.Active ~= nil then
                isActive = (kbConfig.Active == true)
            elseif parentToggle and currentMode == "Toggle" and parentToggle.Value == true then
                isActive = true
            end

            local addons = GetOrCreateAddons(parentWidget, isToggleRow)

            local KeybindBtn = Library:Create("TextButton", {
                Name = "KeybindBtn",
                Size = UDim2.new(0, 0, 0, 16),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 16),
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = 30,
                ZIndex = 5,
                Parent = addons
            })

            local KbCorner = Library:Create("UICorner", {
                CornerRadius = UDim.new(0, 3),
                Parent = KeybindBtn
            })

            local KbStroke = Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = KeybindBtn
            })

            Library:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                Parent = KeybindBtn
            })

            local KbLabel = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = FormatKey(currentKey),
                TextColor3 = Library.Theme.TextDim,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 6,
                Parent = KeybindBtn
            })

            local displayName = kbConfig.Title or kbConfig.Text or kbConfig.Name or "Keybind"

            local function FormatTitle(str)
                str = tostring(str or "Keybind")
                return str:gsub("(%a)([%w_']*)", function(first, rest)
                    return first:upper() .. rest:lower()
                end)
            end
            local formattedName = FormatTitle(displayName)
            local keybindCounter = (Library._keybindCounter or 0) + 1
            Library._keybindCounter = keybindCounter
            local keybindId = "kb_" .. tostring(keybindCounter)

            local KeyPicker = {
                Type = 'KeyPicker',
                Value = currentKey,
                Mode = currentMode,
                Toggled = isActive,
                Held = false,
                Callback = callback,
                Changed = kbConfig.Changed,
                ChangedCallback = kbConfig.ChangedCallback,
                SyncToggleState = (isToggleRow == true or typeof(isToggle) == "table") and (kbConfig.SyncToggleState ~= false),
                Title = displayName,
                Button = KeybindBtn,
                Flag = flag,
            }

            local isBinding = false

            function KeyPicker:GetState()
                if self.Mode == 'Always' then
                    return true
                elseif self.Mode == 'Hold' then
                    if not self.Value or self.Value == 'None' then
                        return false
                    end
                    local key = self.Value
                    if key == 'MB1' or key == 'MouseButton1' or key == Enum.UserInputType.MouseButton1 then
                        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                    elseif key == 'MB2' or key == 'MouseButton2' or key == Enum.UserInputType.MouseButton2 then
                        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                    elseif key == 'MB3' or key == 'MouseButton3' or key == Enum.UserInputType.MouseButton3 then
                        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
                    else
                        local kc = typeof(key) == "EnumItem" and key or Enum.KeyCode[key]
                        if kc then
                            return UserInputService:IsKeyDown(kc) or (self.Held == true)
                        end
                        return self.Held == true
                    end
                else
                    return self.Toggled == true
                end
            end

            function KeyPicker:Get()
                return self:GetState()
            end

            function KeyPicker:GetValue()
                return self:GetState()
            end

            function KeyPicker:Update()
                local state = self:GetState()
                if isBinding then
                    KbLabel.Text = "..."
                    KbLabel.TextColor3 = Library.Theme.Accent
                else
                    KbLabel.Text = FormatKey(self.Value)
                    KbLabel.TextColor3 = state and Library.Theme.Accent or Library.Theme.TextDim
                end
                Library:UpdateKeybindList(keybindId, formattedName, state and self.Value ~= nil and self.Value ~= "None")
            end

            function KeyPicker:DoClick()
                if parentToggle and self.SyncToggleState then
                    parentToggle:SetValue(not parentToggle.Value)
                end
                local st = self:GetState()
                if self.Callback then
                    task.spawn(self.Callback, st, self.Value, self.Mode)
                end
                if self.Clicked then
                    task.spawn(self.Clicked, st)
                end
            end

            function KeyPicker:SetKey(newKey)
                if typeof(newKey) == "string" then
                    if newKey == "None" or newKey == "NONE" then
                        self.Value = nil
                    elseif newKey == "MB1" or newKey == "MouseButton1" then
                        self.Value = Enum.UserInputType.MouseButton1
                    elseif newKey == "MB2" or newKey == "MouseButton2" then
                        self.Value = Enum.UserInputType.MouseButton2
                    elseif newKey == "MB3" or newKey == "MouseButton3" then
                        self.Value = Enum.UserInputType.MouseButton3
                    else
                        self.Value = Enum.KeyCode[newKey] or newKey
                    end
                else
                    self.Value = newKey
                end
                self:Update()
                if self.ChangedCallback then
                    task.spawn(self.ChangedCallback, self.Value)
                end
                if self.Changed then
                    task.spawn(self.Changed, self.Value)
                end
            end

            local Popup = nil
            local closeConn = nil
            local modeButtons = {}
            local itemActiveColor = Library:GetDarkerColor(Library.Theme.Accent, 0.63)

            local function ClosePopup()
                if Popup then
                    Popup.Visible = false
                end
                if closeConn then
                    closeConn:Disconnect()
                    closeConn = nil
                end
                if Library.ActiveKeybindClose == ClosePopup then
                    Library.ActiveKeybindClose = nil
                end
            end

            function KeyPicker:SetMode(newMode)
                if newMode == "Hold" or newMode == "Toggle" or newMode == "Always" then
                    self.Mode = newMode
                    if self.Mode == "Always" then
                        self.Toggled = true
                    elseif self.Mode == "Hold" then
                        self.Held = false
                    end
                    for m, row in pairs(modeButtons) do
                        local isCur = (m == self.Mode)
                        if row.Button and row.Label then
                            row.Button.BackgroundColor3 = itemActiveColor
                            row.Button.BackgroundTransparency = isCur and 0.6 or 1
                            row.Label.TextColor3 = isCur and Library.Theme.Accent or Library.Theme.Text
                        end
                    end
                    self:Update()
                    if self.Callback then
                        task.spawn(self.Callback, self:GetState(), self.Value, self.Mode)
                    end
                end
            end

            function KeyPicker:SetState(state)
                if self.Mode == "Always" then
                    self.Toggled = true
                else
                    self.Toggled = (state == true)
                    if not state then
                        self.Held = false
                    end
                end
                self:Update()
                if self.Callback then
                    task.spawn(self.Callback, self:GetState(), self.Value, self.Mode)
                end
            end

            function KeyPicker:SetValue(data)
                if typeof(data) == "table" and (data[1] ~= nil or data.key ~= nil or data.Key ~= nil) then
                    local k = data[1] or data.key or data.Key
                    local m = data[2] or data.mode or data.Mode
                    self:SetKey(k)
                    if m then
                        self:SetMode(m)
                    end
                elseif typeof(data) == "boolean" then
                    self:SetState(data)
                elseif typeof(data) == "string" or typeof(data) == "EnumItem" then
                    self:SetKey(data)
                end
                self:Update()
            end
            KeyPicker.Set = KeyPicker.SetValue

            function KeyPicker:OnChanged(fn)
                self.Changed = fn
                if typeof(fn) == "function" then
                    task.spawn(fn, self.Value)
                end
                return {
                    Disconnect = function()
                        if self.Changed == fn then
                            self.Changed = nil
                        end
                    end
                }
            end

            function KeyPicker:OnClick(fn)
                self.Clicked = fn
            end

            if parentToggle and KeyPicker.SyncToggleState then
                parentToggle:OnChanged(function(val)
                    if KeyPicker.Mode == "Toggle" then
                        KeyPicker.Toggled = (val == true)
                        KeyPicker:Update()
                    end
                end)
            end

            local function OpenContextMenu()
                if lockMode then return end
                if isBinding then return end

                if Library.ActiveDropdownClose then
                    Library.ActiveDropdownClose()
                end
                if Library.ActiveColorpickerClose then
                    Library.ActiveColorpickerClose()
                end
                if Library.ActiveKeybindClose then
                    Library.ActiveKeybindClose()
                end

                if not Popup then
                    Popup = Library:Create("Frame", {
                        Name = "KeybindPopup",
                        Size = UDim2.new(0, 80, 0, 78),
                        BackgroundColor3 = Library.Theme.PopupBackground or Library.Theme.CardBackground or Color3.fromRGB(16, 13, 14),
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 90,
                        Parent = PopupsHolder
                    })

                    Library:Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = Popup
                    })

                    Library:Create("UIStroke", {
                        Color = Library.Theme.OuterBorder,
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Parent = Popup
                    })

                    Library:Create("UIPadding", {
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                        Parent = Popup
                    })

                    Library:Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 2),
                        Parent = Popup
                    })

                    local modes = { "Hold", "Toggle", "Always" }

                    for idx, modeName in ipairs(modes) do
                        local isModeActive = (KeyPicker.Mode == modeName)
                        local ModeBtn = Library:Create("TextButton", {
                            Name = "Mode_" .. modeName,
                            Size = UDim2.new(1, 0, 0, 22),
                            BackgroundColor3 = itemActiveColor,
                            BackgroundTransparency = isModeActive and 0.6 or 1,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Text = "",
                            LayoutOrder = idx,
                            ZIndex = 91,
                            Parent = Popup
                        })

                        Library:Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                            Parent = ModeBtn
                        })

                        local ModeLabel = Library:Create("TextLabel", {
                            Name = "Label",
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 6, 0, 0),
                            BackgroundTransparency = 1,
                            Text = modeName,
                            TextColor3 = isModeActive and Library.Theme.Accent or Library.Theme.Text,
                            FontFace = Library.Theme.FontSemiBold,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 92,
                            Parent = ModeBtn
                        })

                        modeButtons[modeName] = { Button = ModeBtn, Label = ModeLabel }

                        ModeBtn.MouseEnter:Connect(function()
                            if KeyPicker.Mode ~= modeName then
                                Tween(ModeBtn, { BackgroundColor3 = itemActiveColor, BackgroundTransparency = 0.85 }, 0.12)
                            end
                        end)

                        ModeBtn.MouseLeave:Connect(function()
                            if KeyPicker.Mode ~= modeName then
                                Tween(ModeBtn, { BackgroundTransparency = 1 }, 0.12)
                            end
                        end)

                        ModeBtn.MouseButton1Click:Connect(function()
                            KeyPicker:SetMode(modeName)
                            ClosePopup()
                        end)
                    end
                end

                for m, row in pairs(modeButtons) do
                    local isCur = (m == KeyPicker.Mode)
                    row.Button.BackgroundColor3 = itemActiveColor
                    row.Button.BackgroundTransparency = isCur and 0.6 or 1
                    row.Label.TextColor3 = isCur and Library.Theme.Accent or Library.Theme.Text
                end

                Popup.Visible = true
                Library.ActiveKeybindClose = ClosePopup

                local mainPos = MainFrame.AbsolutePosition
                local btnPos = KeybindBtn.AbsolutePosition
                local popX = btnPos.X - mainPos.X - Popup.AbsoluteSize.X + KeybindBtn.AbsoluteSize.X
                local popY = btnPos.Y - mainPos.Y + KeybindBtn.AbsoluteSize.Y + 4

                popX = math.clamp(popX, 4, MainFrame.AbsoluteSize.X - Popup.AbsoluteSize.X - 4)
                popY = math.clamp(popY, 4, MainFrame.AbsoluteSize.Y - Popup.AbsoluteSize.Y - 4)

                Popup.Position = UDim2.new(0, popX, 0, popY)

                closeConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
                        local mx, my = input.Position.X, input.Position.Y
                        local px, py = Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
                        local sx, sy = Popup.AbsoluteSize.X, Popup.AbsoluteSize.Y
                        local bx, by = KeybindBtn.AbsolutePosition.X, KeybindBtn.AbsolutePosition.Y
                        local bsx, bsy = KeybindBtn.AbsoluteSize.X, KeybindBtn.AbsoluteSize.Y

                        local inPop = (mx >= px and mx <= px + sx and my >= py and my <= py + sy)
                        local inBtn = (mx >= bx and mx <= bx + bsx and my >= by and my <= by + bsy)

                        if not inPop and not inBtn then
                            ClosePopup()
                        end
                    end
                end)
            end

            local bindConn = nil

            local function StartBinding()
                if isBinding then return end
                isBinding = true
                KeyPicker:Update()

                task.defer(function()
                    if bindConn then
                        bindConn:Disconnect()
                        bindConn = nil
                    end

                    bindConn = UserInputService.InputBegan:Connect(function(input)
                        if not isBinding then return end

                        local chosen = nil
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Backspace then
                                chosen = "NONE"
                            else
                                chosen = input.KeyCode
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.MouseButton2
                            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            chosen = input.UserInputType
                        end

                        if chosen ~= nil then
                            isBinding = false
                            if bindConn then
                                bindConn:Disconnect()
                                bindConn = nil
                            end

                            if chosen == "NONE" then
                                KeyPicker:SetKey(nil)
                                KeyPicker.Toggled = false
                                KeyPicker.Held = false
                            else
                                KeyPicker:SetKey(chosen)
                            end

                            KeyPicker:Update()
                            if KeyPicker.Callback then
                                task.spawn(KeyPicker.Callback, KeyPicker:GetState(), KeyPicker.Value, KeyPicker.Mode)
                            end
                        end
                    end)
                end)
            end

            KeybindBtn.MouseButton1Click:Connect(function()
                if not isBinding then
                    StartBinding()
                end
            end)

            KeybindBtn.MouseButton2Click:Connect(function()
                OpenContextMenu()
            end)

            local function MatchesKey(input)
                if not KeyPicker.Value then return false end
                local val = KeyPicker.Value
                if typeof(val) == "string" then
                    if val == "MB1" or val == "MouseButton1" then
                        return input.UserInputType == Enum.UserInputType.MouseButton1
                    elseif val == "MB2" or val == "MouseButton2" then
                        return input.UserInputType == Enum.UserInputType.MouseButton2
                    elseif val == "MB3" or val == "MouseButton3" then
                        return input.UserInputType == Enum.UserInputType.MouseButton3
                    else
                        val = Enum.KeyCode[val]
                    end
                end
                if typeof(val) == "EnumItem" then
                    if val.EnumType == Enum.KeyCode then
                        return input.KeyCode == val
                    elseif val.EnumType == Enum.UserInputType then
                        return input.UserInputType == val
                    end
                end
                return false
            end

            Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if isBinding then return end
                if not KeyPicker.Value then return end
                if UserInputService:GetFocusedTextBox() then return end

                if MatchesKey(input) then
                    if KeyPicker.Mode == "Toggle" then
                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                        KeyPicker:Update()
                    elseif KeyPicker.Mode == "Hold" then
                        KeyPicker.Held = true
                        KeyPicker:Update()
                        if KeyPicker.Callback then
                            task.spawn(KeyPicker.Callback, true, KeyPicker.Value, KeyPicker.Mode)
                        end
                    elseif KeyPicker.Mode == "Always" then
                        KeyPicker.Toggled = true
                        KeyPicker:Update()
                        if KeyPicker.Callback then
                            task.spawn(KeyPicker.Callback, true, KeyPicker.Value, KeyPicker.Mode)
                        end
                    end
                end
            end))

            Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                if isBinding then return end
                if not KeyPicker.Value then return end
                if KeyPicker.Mode == "Hold" and MatchesKey(input) then
                    KeyPicker.Held = false
                    KeyPicker:Update()
                    if KeyPicker.Callback then
                        task.spawn(KeyPicker.Callback, false, KeyPicker.Value, KeyPicker.Mode)
                    end
                end
            end))

            KeybindBtn.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    Library:UpdateKeybindList(keybindId, formattedName, false)
                end
            end)

            if flag then
                Library.Flags[flag] = KeyPicker
            end

            KeyPicker:Update()

            return KeyPicker
        end

    local function CreateSectorInstance(columns, sectorOptions)
        if typeof(sectorOptions) == "string" then
            sectorOptions = { Name = sectorOptions }
        end
        sectorOptions = sectorOptions or {}

        local column = columns and columns.Left or nil
        if columns and string.lower(tostring(sectorOptions.Side or "left")) == "right" then
            column = columns.Right
        end

        local sectorName = sectorOptions.Name or sectorOptions.Title or "sector"
        local icon = FormatIcon(sectorOptions.Icon)
        local headerHeight = 28

        local SectorFrame = Library:Create("Frame", {
            Name = "Sector_" .. tostring(sectorName),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme.CardBackground,
            BorderSizePixel = 0,
            Parent = column
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = SectorFrame
        })

        Library:Create("UIStroke", {
            Color = Library.Theme.OuterBorder,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = SectorFrame
        })

        local SectorHeader = Library:Create("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, headerHeight),
            BackgroundTransparency = 1,
            Parent = SectorFrame
        })

        if icon ~= "" then
            Library:Create("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, -9),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = Library.Theme.Accent,
                Parent = SectorHeader
            })
        end

        Library:Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, (icon ~= "" and -46 or -20), 1, 0),
            Position = UDim2.new(0, (icon ~= "" and 38 or 12), 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(sectorName):lower(),
            TextColor3 = Library.Theme.Text,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = SectorHeader
        })

        Library:Create("Frame", {
            Name = "HeaderLine",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = Library.Theme.OuterBorder,
            BorderSizePixel = 0,
            Parent = SectorHeader
        })

        local ElementsList = Library:Create("Frame", {
            Name = "Elements",
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 10, 0, headerHeight + 10),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = SectorFrame
        })

        Library:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = ElementsList
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            Parent = ElementsList
        })

        local Sector = {}

        RegisterWidgetMethods(Sector, ElementsList)

        Sector.Frame = SectorFrame
        Sector.Content = ElementsList

        return Sector
    end

    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        PopupsHolder = PopupsHolder,
        ContentArea = ContentArea,
        Tabs = {}
    }

    function Window:CreateTab(tabConfig)
        if typeof(tabConfig) == "string" then
            tabConfig = { Name = tabConfig }
        end
        tabConfig = tabConfig or {}

        local tabName = tabConfig.Name or "Tab"
        local iconAsset = FormatIcon(tabConfig.Icon)

        local Tab = {
            Name = tabName,
            Active = false,
            SubTabs = {},
            CurrentSubTab = nil
        }

        local TabButton = Library:Create("TextButton", {
            Name = "Tab_" .. tabName,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Library.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = TabsContainer
        })

        local TabCorner = Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = TabButton
        })

        local TabIcon = Library:Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 12, 0.5, -10),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = Library.Theme.TextDim,
            Parent = TabButton
        })

        local TabLabel = Library:Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -48, 1, 0),
            Position = UDim2.new(0, 42, 0, 0),
            BackgroundTransparency = 1,
            Text = tabName:lower(),
            TextColor3 = Library.Theme.TextDim,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton
        })

        local Page = Library:Create("Frame", {
            Name = "Page_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = ContentArea
        })

        local SubTabsBar = Library:Create("CanvasGroup", {
            Name = "SubTabsBar",
            Size = UDim2.new(0, 0, 0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            Position = UDim2.new(0, 9, 0, 6),
            BackgroundColor3 = Library.Theme.SidebarBackground,
            BorderSizePixel = 0,
            GroupTransparency = 0,
            Visible = false,
            Parent = Page
        })

        local BarCorner = Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = SubTabsBar
        })

        local BarStroke = Library:Create("UIStroke", {
            Color = Library.Theme.OuterBorder,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = SubTabsBar
        })

        local SubTabsLayout = Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),
            Parent = SubTabsBar
        })

        local DirectContent = Library:Create("Frame", {
            Name = "DirectContent",
            Size = UDim2.new(1, -12, 1, -16),
            Position = UDim2.new(0, 6, 0, 8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Page
        })

        local DirectLeft, DirectRight = CreateColumnsContainer(DirectContent)
        local DirectColumns = { Left = DirectLeft, Right = DirectRight }

        local function SetActive(state)
            Tab.Active = state
            Page.Visible = state

            if state then
                Page.Position = UDim2.new(0, 0, 0, 14)
                Tween(Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
                Tween(TabButton, { BackgroundTransparency = 0 })
                Tween(TabLabel, { TextColor3 = Library.Theme.AccentDark })
                Tween(TabIcon, { ImageColor3 = Library.Theme.AccentDark })
            else
                Tween(TabButton, { BackgroundTransparency = 1 })
                Tween(TabLabel, { TextColor3 = Library.Theme.TextDim })
                Tween(TabIcon, { ImageColor3 = Library.Theme.TextDim })
            end
        end

        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                Tween(TabButton, { BackgroundTransparency = 0.92 })
                Tween(TabLabel, { TextColor3 = Library.Theme.Text })
                Tween(TabIcon, { ImageColor3 = Library.Theme.Text })
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                Tween(TabButton, { BackgroundTransparency = 1 })
                Tween(TabLabel, { TextColor3 = Library.Theme.TextDim })
                Tween(TabIcon, { ImageColor3 = Library.Theme.TextDim })
            end
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, otherTab in ipairs(Window.Tabs) do
                otherTab.SetActive(false)
            end
            SetActive(true)
        end)

        Tab.SetActive = SetActive
        Tab.Page = Page

        function Tab:CreateSubTab(subConfig)
            if typeof(subConfig) == "string" then
                subConfig = { Name = subConfig }
            end
            subConfig = subConfig or {}

            local subName = subConfig.Name or "SubTab"

            SubTabsBar.Visible = true

            DirectContent.Visible = false

            local SubTab = {
                Name = subName,
                Active = false
            }

            local btnWidth = math.max(68, #subName * 9 + 28)

            local SubBtn = Library:Create("TextButton", {
                Name = "SubBtn_" .. subName,
                Size = UDim2.new(0, btnWidth, 1, 0),
                BackgroundColor3 = Library.Theme.SidebarBackground,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = SubTabsBar
            })

            local SubLabel = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = subName:lower(),
                TextColor3 = Library.Theme.TextDim,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 12,
                ZIndex = 2,
                Parent = SubBtn
            })

            local Divider = Library:Create("Frame", {
                Name = "Divider",
                Size = UDim2.new(0, 1, 1, 0),
                Position = UDim2.new(1, -1, 0, 0),
                BackgroundColor3 = Library.Theme.OuterBorder,
                BorderSizePixel = 0,
                ZIndex = 3,
                Parent = SubBtn
            })

            local SubPage = Library:Create("Frame", {
                Name = "SubPage_" .. subName,
                Size = UDim2.new(1, -12, 1, -48),
                Position = UDim2.new(0, 6, 0, 40),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = false,
                Parent = Page
            })

            local SubLeft, SubRight = CreateColumnsContainer(SubPage)
            local SubColumns = { Left = SubLeft, Right = SubRight }

            local function SetSubActive(state)
                SubTab.Active = state
                SubPage.Visible = state

                if state then
                    SubPage.Position = UDim2.new(0, 6, 0, 48)
                    Tween(SubPage, { Position = UDim2.new(0, 6, 0, 40) }, 0.2)
                    Tween(SubBtn, { BackgroundColor3 = Library.Theme.Accent }, 0.15)
                    Tween(SubLabel, { TextColor3 = Library.Theme.AccentDark }, 0.15)
                else
                    Tween(SubBtn, { BackgroundColor3 = Library.Theme.SidebarBackground }, 0.15)
                    Tween(SubLabel, { TextColor3 = Library.Theme.TextDim }, 0.15)
                end
            end

            SubBtn.MouseEnter:Connect(function()
                if not SubTab.Active then
                    Tween(SubLabel, { TextColor3 = Library.Theme.Text }, 0.15)
                end
            end)

            SubBtn.MouseLeave:Connect(function()
                if not SubTab.Active then
                    Tween(SubLabel, { TextColor3 = Library.Theme.TextDim }, 0.15)
                end
            end)

            SubBtn.MouseButton1Click:Connect(function()
                for _, other in ipairs(Tab.SubTabs) do
                    other.SetSubActive(false)
                end
                SetSubActive(true)
            end)

            SubTab.Button = SubBtn
            SubTab.Label = SubLabel
            SubTab.Divider = Divider
            SubTab.SetSubActive = SetSubActive
            SubTab.Page = SubPage
            SubTab.Columns = SubColumns

            function SubTab:CreateSector(sectorOptions)
                return CreateSectorInstance(SubColumns, sectorOptions)
            end

            table.insert(Tab.SubTabs, SubTab)

            for i, st in ipairs(Tab.SubTabs) do
                st.Divider.Visible = (i < #Tab.SubTabs)
            end

            if #Tab.SubTabs == 1 then
                SetSubActive(true)
            end

            return SubTab
        end

        function Tab:CreateSector(sectorOptions)
            return CreateSectorInstance(DirectColumns, sectorOptions)
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    function Window:CreateConfig(configOptions)
        if typeof(configOptions) == "string" then
            configOptions = { ConfigFolder = configOptions }
        end
        configOptions = configOptions or {}

        local folderName = configOptions.ConfigFolder or configOptions.Folder or "LuxeWare"
        local tabName = configOptions.Name or configOptions.Title or configOptions.TabName or "configs"
        local iconAsset = FormatIcon(configOptions.Icon or "rbxassetid://10723345518")

        local Tab = {
            Name = tabName,
            Active = false,
            SubTabs = {},
            CurrentSubTab = nil
        }

        local TabButton = Library:Create("TextButton", {
            Name = "Tab_" .. tabName,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Library.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = TabsContainer
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = TabButton
        })

        local TabIcon = Library:Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 12, 0.5, -10),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = Library.Theme.TextDim,
            Parent = TabButton
        })

        local TabLabel = Library:Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -48, 1, 0),
            Position = UDim2.new(0, 42, 0, 0),
            BackgroundTransparency = 1,
            Text = tabName:lower(),
            TextColor3 = Library.Theme.TextDim,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton
        })

        local Page = Library:Create("Frame", {
            Name = "Page_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = ContentArea
        })

        local function SetActive(state)
            Tab.Active = state
            Page.Visible = state

            if state then
                Page.Position = UDim2.new(0, 0, 0, 14)
                Tween(Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
                Tween(TabButton, { BackgroundTransparency = 0 })
                Tween(TabLabel, { TextColor3 = Library.Theme.AccentDark })
                Tween(TabIcon, { ImageColor3 = Library.Theme.AccentDark })
            else
                Tween(TabButton, { BackgroundTransparency = 1 })
                Tween(TabLabel, { TextColor3 = Library.Theme.TextDim })
                Tween(TabIcon, { ImageColor3 = Library.Theme.TextDim })
            end
        end

        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                Tween(TabButton, { BackgroundTransparency = 0.92 })
                Tween(TabLabel, { TextColor3 = Library.Theme.Text })
                Tween(TabIcon, { ImageColor3 = Library.Theme.Text })
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                Tween(TabButton, { BackgroundTransparency = 1 })
                Tween(TabLabel, { TextColor3 = Library.Theme.TextDim })
                Tween(TabIcon, { ImageColor3 = Library.Theme.TextDim })
            end
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, otherTab in ipairs(Window.Tabs) do
                otherTab.SetActive(false)
            end
            SetActive(true)
        end)

        Tab.SetActive = SetActive
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)

        local ConfigContent = Library:Create("Frame", {
            Name = "ConfigContent",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Page
        })

        local TopBar = Library:Create("Frame", {
            Name = "TopBar",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = ConfigContent
        })

        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = TopBar
        })

        local SearchBox = Library:Create("Frame", {
            Name = "SearchBox",
            Size = UDim2.new(0, 180, 0, 30),
            BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 17),
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Parent = TopBar
        })

        Library:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SearchBox })
        Library:Create("UIStroke", {
            Color = Library.Theme.OuterBorder,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = SearchBox
        })

        Library:Create("ImageLabel", {
            Name = "SearchIcon",
            Size = UDim2.new(0, 13, 0, 13),
            Position = UDim2.new(0, 9, 0.5, -6),
            BackgroundTransparency = 1,
            Image = "rbxassetid://122936689907429",
            ImageColor3 = Library.Theme.TextDim,
            Parent = SearchBox
        })

        local SearchInput = Library:Create("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 26, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Search config...",
            PlaceholderColor3 = Library.Theme.TextDim,
            TextColor3 = Library.Theme.Text,
            FontFace = Library.Theme.FontSemiBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = SearchBox
        })

        local function CreateTopButton(btnName, text, iconAsset, layoutOrder)
            local btn = Library:Create("TextButton", {
                Name = btnName,
                Size = UDim2.new(0, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 22),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = layoutOrder,
                Parent = TopBar
            })

            Library:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
            Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = btn
            })
            Library:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 12),
                Parent = btn
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = btn
            })

            local icon = Library:Create("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 13, 0, 13),
                BackgroundTransparency = 1,
                Image = iconAsset,
                ImageColor3 = Library.Theme.Text,
                LayoutOrder = 1,
                Parent = btn
            })

            local lbl = Library:Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                LayoutOrder = 2,
                Parent = btn
            })

            btn.MouseEnter:Connect(function()
                Tween(btn, { BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.MainBackground or Color3.fromRGB(32, 28, 29) }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, { BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 22) }, 0.12)
            end)

            return btn
        end

        local NewConfigBtn = CreateTopButton("NewConfigBtn", "New Config", "rbxassetid://96644180483078", 2)
        local ImportCodeBtn = CreateTopButton("ImportCodeBtn", "Import Code", "rbxassetid://128134385303747", 3)

        local ConfigsScroll = Library:Create("ScrollingFrame", {
            Name = "ConfigsScroll",
            Size = UDim2.new(1, 0, 1, -40),
            Position = UDim2.new(0, 0, 0, 40),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = ConfigContent
        })

        Library:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
            Parent = ConfigsScroll
        })

        Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 6),
            Parent = ConfigsScroll
        })

        local SessionConfigs = {}
        local currentLoadedConfig = nil
        local configCards = {}

        local function HasFileSystem()
            return (typeof(writefile) == "function" and typeof(readfile) == "function")
        end

        local function EnsureFolder()
            if typeof(makefolder) == "function" then
                if typeof(isfolder) == "function" then
                    if not isfolder(folderName) then
                        pcall(makefolder, folderName)
                    end
                else
                    pcall(makefolder, folderName)
                end
            end
        end

        local function GetFilePath(name)
            return folderName .. "/" .. name .. ".json"
        end

        local function GatherCurrentFlags()
            local objectsList = {}
            local flagsDict = {}
            for idx, obj in pairs(Library.Flags) do
                if typeof(obj) == "table" and obj.Type and SaveManager.Parser[obj.Type] then
                    local parsed = SaveManager.Parser[obj.Type].Save(idx, obj)
                    table.insert(objectsList, parsed)
                    flagsDict[idx] = parsed.value or parsed.text or parsed.key
                end
            end
            return objectsList, flagsDict
        end

        local function LoadFlagsFromData(data)
            if typeof(data) ~= "table" then return end

            -- 1. Reset ALL toggles in Library.Flags to false first
            for idx, obj in pairs(Library.Flags) do
                if typeof(obj) == "table" and obj.Type == "Toggle" then
                    obj:SetValue(false)
                end
            end

            -- 2. Reset ALL keybinds to false, UNLESS mode is "Always"
            for idx, obj in pairs(Library.Flags) do
                if typeof(obj) == "table" and obj.Type == "KeyPicker" then
                    if obj.Mode == "Always" then
                        obj:SetState(true)
                    else
                        obj.Held = false
                        obj.Toggled = false
                        obj:SetState(false)
                    end
                end
            end

            -- 3. Apply loaded config objects (Linoria format)
            if data.objects and typeof(data.objects) == "table" then
                for _, opt in ipairs(data.objects) do
                    if opt and opt.type and SaveManager.Parser[opt.type] then
                        task.spawn(function()
                            SaveManager.Parser[opt.type].Load(opt.idx, opt)
                        end)
                    end
                end
            -- 4. Fallback for legacy format with data.Flags or direct dictionary
            else
                local flagsToLoad = data.Flags or data
                for flag, val in pairs(flagsToLoad) do
                    if flag ~= "Name" and flag ~= "Author" and flag ~= "Modified" and flag ~= "objects" then
                        local obj = Library.Flags[flag]
                        if obj and typeof(obj) == "table" and obj.SetValue then
                            local processedVal = val
                            if typeof(val) == "table" then
                                if val.R ~= nil and val.G ~= nil and val.B ~= nil and val.Color == nil then
                                    processedVal = Color3.new(val.R, val.G, val.B)
                                elseif val.Color and typeof(val.Color) == "table" and val.Color.R ~= nil then
                                    processedVal = {
                                        Color = Color3.new(val.Color.R, val.Color.G, val.Color.B),
                                        Alpha = val.Alpha or 1
                                    }
                                end
                            end
                            task.spawn(function()
                                obj:SetValue(processedVal)
                            end)
                        end
                    end
                end
            end
        end

        local function ReadConfigFromFile(cfgName)
            if HasFileSystem() then
                local path = GetFilePath(cfgName)
                local success, content = pcall(readfile, path)
                if success and content then
                    local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                    if ok and decoded then
                        return decoded
                    end
                end
            end
            return SessionConfigs[cfgName]
        end

        local function SaveConfigToFile(cfgName)
            local objectsList, flagsDict = GatherCurrentFlags()
            local data = {
                Name = cfgName,
                Author = UserDisplay or "User",
                Modified = os.date("%d-%m-%Y %H:%M"),
                objects = objectsList,
                Flags = flagsDict
            }
            SessionConfigs[cfgName] = data
            local json = HttpService:JSONEncode(data)
            if HasFileSystem() then
                EnsureFolder()
                pcall(writefile, GetFilePath(cfgName), json)
            end
            return data
        end

        local function DeleteConfigFile(cfgName)
            SessionConfigs[cfgName] = nil
            if HasFileSystem() and typeof(delfile) == "function" then
                pcall(delfile, GetFilePath(cfgName))
            end
            if currentLoadedConfig == cfgName then
                currentLoadedConfig = nil
            end
        end

        local function ListAllConfigs()
            local configs = {}
            local seen = {}
            if HasFileSystem() and typeof(listfiles) == "function" then
                EnsureFolder()
                local success, files = pcall(listfiles, folderName)
                if success and typeof(files) == "table" then
                    for _, file in ipairs(files) do
                        local fileName = file:match("([^/\\]+)%.json$")
                        if fileName then
                            local data = ReadConfigFromFile(fileName)
                            if data then
                                table.insert(configs, data)
                                seen[fileName] = true
                            end
                        end
                    end
                end
            end

            for name, data in pairs(SessionConfigs) do
                if not seen[name] then
                    table.insert(configs, data)
                end
            end

            return configs
        end

        local PromptModal = nil

        local function ShowModal(title, placeholder, confirmText, onConfirm, isImport)
            if PromptModal then
                PromptModal:Destroy()
                PromptModal = nil
            end

            PromptModal = Library:Create("TextButton", {
                Name = "ConfigModal",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.55,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 120,
                Parent = PopupsHolder
            })

            local Dialog = Library:Create("Frame", {
                Name = "Dialog",
                Size = UDim2.new(0, 280, 0, 118),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundColor3 = Library.Theme.CardBackground or Color3.fromRGB(16, 13, 14),
                BorderSizePixel = 0,
                ZIndex = 121,
                Parent = PromptModal
            })

            Library:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Dialog })
            Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Dialog
            })

            Library:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -24, 0, 22),
                Position = UDim2.new(0, 12, 0, 10),
                BackgroundTransparency = 1,
                Text = title:lower(),
                TextColor3 = Library.Theme.Text,
                Font = Library.Theme.FontBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 122,
                Parent = Dialog
            })

            local InputBox = Library:Create("TextBox", {
                Name = "Input",
                Size = UDim2.new(1, -24, 0, 28),
                Position = UDim2.new(0, 12, 0, 38),
                BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(22, 19, 20),
                BorderSizePixel = 0,
                Text = "",
                PlaceholderText = placeholder,
                PlaceholderColor3 = Library.Theme.TextDim,
                TextColor3 = Library.Theme.Text,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                MultiLine = isImport and true or false,
                ZIndex = 122,
                Parent = Dialog
            })

            Library:Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = InputBox })
            Library:Create("UIStroke", {
                Color = Library.Theme.OuterBorder,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = InputBox
            })
            Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = InputBox })

            local BtnRow = Library:Create("Frame", {
                Name = "Buttons",
                Size = UDim2.new(1, -24, 0, 24),
                Position = UDim2.new(0, 12, 1, -34),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 122,
                Parent = Dialog
            })

            local ConfirmBtn = Library:Create("TextButton", {
                Name = "Confirm",
                Size = UDim2.new(0, 68, 1, 0),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = confirmText,
                TextColor3 = Library.Theme.AccentDark,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                ZIndex = 123,
                Parent = BtnRow
            })
            Library:Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ConfirmBtn })

            local CancelBtn = Library:Create("TextButton", {
                Name = "Cancel",
                Size = UDim2.new(0, 60, 1, 0),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -74, 0, 0),
                BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 22),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "cancel",
                TextColor3 = Library.Theme.TextDim,
                FontFace = Library.Theme.FontSemiBold,
                TextSize = 11,
                ZIndex = 123,
                Parent = BtnRow
            })
            Library:Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = CancelBtn })

            if isImport and typeof(getclipboard) == "function" then
                local PasteBtn = Library:Create("TextButton", {
                    Name = "Paste",
                    Size = UDim2.new(0, 50, 1, 0),
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Library.Theme.ElementHover or Library.Theme.CardBackground or Color3.fromRGB(24, 21, 22),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "paste",
                    TextColor3 = Color3.fromRGB(220, 220, 225),
                    FontFace = Library.Theme.FontSemiBold,
                    TextSize = 11,
                    ZIndex = 123,
                    Parent = BtnRow
                })
                Library:Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = PasteBtn })
                PasteBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        local clip = getclipboard()
                        if clip and typeof(clip) == "string" and clip ~= "" then
                            InputBox.Text = clip
                        end
                    end)
                end)

                pcall(function()
                    local clip = getclipboard()
                    if clip and typeof(clip) == "string" and (clip:match("^%s*%{") or clip:match("^%s*%[")) then
                        InputBox.Text = clip
                    end
                end)
            end

            local function Close()
                if PromptModal then
                    PromptModal:Destroy()
                    PromptModal = nil
                end
            end

            CancelBtn.MouseButton1Click:Connect(Close)
            PromptModal.MouseButton1Click:Connect(Close)

            ConfirmBtn.MouseButton1Click:Connect(function()
                local val = InputBox.Text
                if val and val:gsub("%s+", "") ~= "" then
                    Close()
                    onConfirm(val)
                end
            end)

            task.defer(function()
                InputBox:CaptureFocus()
            end)
        end

        local function RefreshCards()
            for _, cardObj in pairs(configCards) do
                if cardObj.Frame then
                    cardObj.Frame:Destroy()
                end
            end
            table.clear(configCards)

            local configs = ListAllConfigs()

            for idx, cfgData in ipairs(configs) do
                local cfgName = cfgData.Name or ("Config_" .. tostring(idx))
                local modDate = cfgData.Modified or os.date("%d-%m-%Y %H:%M")
                local isLoaded = (currentLoadedConfig == cfgName)

                local Card = Library:Create("Frame", {
                    Name = "Card_" .. cfgName,
                    Size = UDim2.new(1, -4, 0, 56),
                    BackgroundColor3 = Library.Theme.ElementBackground or Library.Theme.CardBackground or Color3.fromRGB(18, 16, 17),
                    BorderSizePixel = 0,
                    LayoutOrder = idx,
                    Parent = ConfigsScroll
                })

                Library:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Card })

                local CardStroke = Library:Create("UIStroke", {
                    Color = isLoaded and Library.Theme.Accent or Library.Theme.OuterBorder,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = Card
                })

                local NameLabel = Library:Create("TextLabel", {
                    Name = "NameLabel",
                    Size = UDim2.new(0, 0, 0, 16),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Position = UDim2.new(0, 16, 0, 10),
                    BackgroundTransparency = 1,
                    Text = cfgName,
                    Font = Library.Theme.FontBold,
                    TextSize = 13,
                    TextColor3 = Color3.fromRGB(245, 245, 250),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Card
                })

                local ModLabel = Library:Create("TextLabel", {
                    Name = "ModLabel",
                    Size = UDim2.new(0, 0, 0, 14),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Position = UDim2.new(0, 16, 0, 31),
                    BackgroundTransparency = 1,
                    RichText = true,
                    Text = '<b>Modification:</b> ' .. modDate,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    FontFace = Library.Theme.FontSemiBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Card
                })

                local Actions = Library:Create("Frame", {
                    Name = "Actions",
                    Size = UDim2.new(0, 0, 0, 42),
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = Card
                })

                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 10),
                    Parent = Actions
                })

                local function CreateActionButton(btnActName, iconAssetId, labelText, order, isPrimary)
                    local btn = Library:Create("TextButton", {
                        Name = btnActName,
                        Size = UDim2.new(0, 36, 0, 40),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        LayoutOrder = order,
                        Parent = Actions
                    })

                    local icon = Library:Create("ImageLabel", {
                        Name = "Icon",
                        Size = UDim2.new(0, 14, 0, 14),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5, 0, 0, 4),
                        BackgroundTransparency = 1,
                        Image = iconAssetId,
                        ImageColor3 = isPrimary and Library.Theme.Accent or Library.Theme.TextDim,
                        Parent = btn
                    })

                    local lbl = Library:Create("TextLabel", {
                        Name = "Label",
                        Size = UDim2.new(1, 0, 0, 14),
                        AnchorPoint = Vector2.new(0.5, 1),
                        Position = UDim2.new(0.5, 0, 1, -2),
                        BackgroundTransparency = 1,
                        Text = labelText,
                        TextColor3 = isPrimary and Library.Theme.Accent or Library.Theme.TextDim,
                        FontFace = Library.Theme.FontSemiBold,
                        TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Parent = btn
                    })

                    btn.MouseEnter:Connect(function()
                        if not isPrimary then
                            Tween(icon, { ImageColor3 = Color3.fromRGB(240, 240, 245) }, 0.12)
                            Tween(lbl, { TextColor3 = Color3.fromRGB(240, 240, 245) }, 0.12)
                        end
                    end)
                    btn.MouseLeave:Connect(function()
                        if not isPrimary then
                            Tween(icon, { ImageColor3 = Library.Theme.TextDim }, 0.12)
                            Tween(lbl, { TextColor3 = Library.Theme.TextDim }, 0.12)
                        end
                    end)

                    return btn, icon, lbl
                end

                local loadIcon = isLoaded and "rbxassetid://123741252324994" or "rbxassetid://100109138749883"
                local loadText = isLoaded and "Loaded" or "Load"
                local LoadBtn = CreateActionButton("LoadBtn", loadIcon, loadText, 1, isLoaded)
                local SaveBtn = CreateActionButton("SaveBtn", "rbxassetid://103946434167533", "Save", 2, false)
                local ShareBtn = CreateActionButton("ShareBtn", "rbxassetid://136757423752893", "Share", 3, false)
                local DeleteBtn = CreateActionButton("DeleteBtn", "rbxassetid://116124263605294", "Delete", 4, false)

                LoadBtn.MouseButton1Click:Connect(function()
                    local data = ReadConfigFromFile(cfgName) or cfgData
                    LoadFlagsFromData(data)
                    currentLoadedConfig = cfgName
                    RefreshCards()
                    Library:Notify({
                        Title = "configs",
                        Description = 'loaded "' .. cfgName .. '" successfully',
                        Duration = 3
                    })
                end)

                SaveBtn.MouseButton1Click:Connect(function()
                    local savedData = SaveConfigToFile(cfgName)
                    modDate = savedData.Modified
                    ModLabel.Text = '<b>Modification:</b> ' .. modDate
                    RefreshCards()
                    Library:Notify({
                        Title = "configs",
                        Description = 'saved "' .. cfgName .. '" successfully',
                        Duration = 3
                    })
                end)

                ShareBtn.MouseButton1Click:Connect(function()
                    local data = ReadConfigFromFile(cfgName) or cfgData
                    local json = HttpService:JSONEncode(data)
                    if typeof(setclipboard) == "function" then
                        setclipboard(json)
                    elseif typeof(toclipboard) == "function" then
                        toclipboard(json)
                    end
                    Library:Notify({
                        Title = "configs",
                        Description = 'copied code for "' .. cfgName .. '" to clipboard',
                        Duration = 3
                    })
                end)

                DeleteBtn.MouseButton1Click:Connect(function()
                    DeleteConfigFile(cfgName)
                    RefreshCards()
                    Library:Notify({
                        Title = "configs",
                        Description = 'deleted "' .. cfgName .. '"',
                        Duration = 3
                    })
                end)

                configCards[cfgName] = {
                    Frame = Card,
                    Name = cfgName,
                    ModLabel = ModLabel,
                    Stroke = CardStroke
                }
            end

            local filter = SearchInput.Text:lower():gsub("%s+", "")
            if filter ~= "" then
                for cName, cObj in pairs(configCards) do
                    cObj.Frame.Visible = (cName:lower():gsub("%s+", ""):find(filter, 1, true) ~= nil)
                end
            end
        end

        SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
            local filter = SearchInput.Text:lower():gsub("%s+", "")
            for cName, cObj in pairs(configCards) do
                cObj.Frame.Visible = (filter == "" or cName:lower():gsub("%s+", ""):find(filter, 1, true) ~= nil)
            end
        end)

        NewConfigBtn.MouseButton1Click:Connect(function()
            ShowModal("new config", "config name...", "create", function(name)
                SaveConfigToFile(name)
                SearchInput.Text = ""
                RefreshCards()
                Library:Notify({
                    Title = "configs",
                    Description = 'created config "' .. name .. '"',
                    Duration = 3
                })
            end, false)
        end)

        ImportCodeBtn.MouseButton1Click:Connect(function()
            ShowModal("import code", "paste json/config code here...", "import", function(code)
                code = code:match("^%s*(.-)%s*$") or code
                local ok, data = pcall(function() return HttpService:JSONDecode(code) end)
                if (not ok or typeof(data) ~= "table") and typeof(crypt) == "table" and typeof(crypt.base64decode) == "function" then
                    local b64ok, decoded = pcall(crypt.base64decode, code)
                    if b64ok and decoded then
                        ok, data = pcall(function() return HttpService:JSONDecode(decoded) end)
                    end
                end

                if ok and typeof(data) == "table" then
                    local name = nil
                    if typeof(data.Name) == "string" and data.Name:gsub("%s+", "") ~= "" then
                        name = data.Name
                    else
                        name = "Imported_" .. os.date("%d%m%Y_%H%M%S")
                    end

                    if not data.Flags and not data.Modified then
                        data = {
                            Name = name,
                            Author = "Imported",
                            Modified = os.date("%d-%m-%Y %H:%M"),
                            Flags = data
                        }
                    else
                        data.Name = name
                        data.Modified = data.Modified or os.date("%d-%m-%Y %H:%M")
                        data.Author = data.Author or "Imported"
                    end

                    SessionConfigs[name] = data
                    if HasFileSystem() then
                        EnsureFolder()
                        local jsonOut = HttpService:JSONEncode(data)
                        pcall(writefile, GetFilePath(name), jsonOut)
                    end
                    SearchInput.Text = ""
                    RefreshCards()
                    Library:Notify({
                        Title = "configs",
                        Description = 'imported config "' .. name .. '"',
                        Duration = 3
                    })
                else
                    Library:Notify({
                        Title = "configs",
                        Description = "invalid config code",
                        Duration = 3
                    })
                end
            end, true)
        end)

        RefreshCards()

        local configTabAPI = {
            Tab = Tab,
            Button = TabButton,
            Page = Page,
            Refresh = RefreshCards,
            Create = function(self_api, name)
                SaveConfigToFile(name)
                RefreshCards()
            end,
            Load = function(self_api, name)
                local data = ReadConfigFromFile(name)
                if data then
                    LoadFlagsFromData(data)
                    currentLoadedConfig = name
                    RefreshCards()
                end
            end,
            Save = function(self_api, name)
                SaveConfigToFile(name)
                RefreshCards()
            end,
            Delete = function(self_api, name)
                DeleteConfigFile(name)
                RefreshCards()
            end
        }

        return configTabAPI
    end
    Window.CreateConfigs = Window.CreateConfig


    function Window:Notify(notifyConfig)
        return Library:Notify(notifyConfig)
    end

    function Window:SetKeybindListVisible(vis)
        return Library:SetKeybindListVisible(vis)
    end
    Window.KeybindList = Library.KeybindList
    Window.KeybindFrame = Library.KeybindFrame
    Window.Unload = function() Library:Unload() end

    return Window
end
return Library
