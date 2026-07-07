local Library = {}

local clone_ref = cloneref or function(obj) return obj end
local Players = clone_ref(game:GetService("Players"))
local CoreGui = clone_ref(game:GetService("CoreGui"))
local UserInputService = clone_ref(game:GetService("UserInputService"))
local TweenService = clone_ref(game:GetService("TweenService"))
local GuiService = clone_ref(game:GetService("GuiService"))
local HttpService = clone_ref(game:GetService("HttpService"))
local TextService = clone_ref(game:GetService("TextService"))

Library.Accent = Color3.fromRGB(224, 94, 124)
Library.Flags = {}
Library.MainWindow = nil
Library.MenuOpen = true
Library.Connections = {}
Library.KeybindListFrame = nil
Library.KeybindListContainer = nil
Library.KeybindListEntries = {}
Library.KeybindListVisible = true
Library.WatermarkFrame = nil
Library.WatermarkLabel = nil
Library.WatermarkVisible = true
Library.WatermarkText = "<b>DeadCell</b>"
Library.ConfigFolder = "DeadcellConfigs"
Library.DefaultAccent = Library.Accent
Library.AccentRegistry = {}

if getgenv then 
    getgenv().flags = Library.Flags 
    getgenv().Library = Library
end

function Library:Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Library.Connections, conn)
    return conn
end

function Library:Unload()
    Library.Unloaded = true
    Library._cursorRunning = false
    if Library.KeybindListFrame then
        Library.KeybindListFrame:Destroy()
        Library.KeybindListFrame = nil
    end
    Library.KeybindListEntries = {}
    if Library.MainWindow then
        Library.MainWindow:Destroy()
        Library.MainWindow = nil
    end
    for _, conn in ipairs(Library.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    Library.Connections = {}
    Library.Flags = {}
    Library.AccentRegistry = {}

    if Library._cursorObjects then
        for _, obj in pairs(Library._cursorObjects) do
            obj.Visible = false
            obj:Remove()
        end
        Library._cursorObjects = nil
    end

    pcall(function()
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)

    if getgenv then 
        getgenv().flags = nil 
        getgenv().Library = nil
    end
end

function Library:Create(class, properties)
    local object = Instance.new(class)
    for property, value in pairs(properties) do
        if property ~= "Name" then
            object[property] = value
        end
    end
    object.Name = properties["Name"] or ""

    if class == "UIGradient" then
        if object.Name == "AccentGradient" or object.Name == "FillGradient" then
            Library:RegisterAccentObject(object, "AccentGradient")
        elseif object.Name == "AccentDarkGradient" then
            Library:RegisterAccentObject(object, "AccentDarkGradient")
        end
    elseif class == "Frame" and object.Name == "AccentLine" then
        Library:RegisterAccentObject(object, "AccentLine")
    end

    return object
end

function Library:GetDarkerColor(color, factor)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - (factor or 0.2), 0, 1))
end

function Library:StripRichText(text)
    text = tostring(text or "")
    return (text:gsub("<[^>]->", ""))
end

function Library:RegisterAccentObject(object, accentType)
    if not object then return end
    table.insert(Library.AccentRegistry, {
        Object = object,
        Type = accentType
    })
end

function Library:RebuildAccentRegistry()
    Library.AccentRegistry = {}
    local ScreenGui = Library:GetScreenGui()
    if not ScreenGui then return end

    for _, child in ipairs(ScreenGui:GetDescendants()) do
        if child:IsA("UIGradient") then
            if child.Name == "AccentGradient" or child.Name == "FillGradient" then
                Library:RegisterAccentObject(child, "AccentGradient")
            elseif child.Name == "AccentDarkGradient" then
                Library:RegisterAccentObject(child, "AccentDarkGradient")
            end
        elseif child:IsA("Frame") and child.Name == "AccentLine" then
            Library:RegisterAccentObject(child, "AccentLine")
        end
    end
end

function Library:ApplyAccentRegistry()
    for i = #Library.AccentRegistry, 1, -1 do
        local entry = Library.AccentRegistry[i]
        local obj = entry and entry.Object
        if not obj or not obj.Parent then
            table.remove(Library.AccentRegistry, i)
        else
            if entry.Type == "AccentGradient" and obj:IsA("UIGradient") then
                obj.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Library.Accent),
                    ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.15))
                })
            elseif entry.Type == "AccentDarkGradient" and obj:IsA("UIGradient") then
                obj.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.Accent, 0.2)),
                    ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.45))
                })
            elseif entry.Type == "AccentLine" and obj:IsA("Frame") then
                obj.BackgroundColor3 = Library.Accent
            end
        end
    end
end

Library._cursorRunning = false

function Library:_StartCursor()
    if Library._cursorRunning then return end
    Library._cursorRunning = true
    task.spawn(function()
        if not Drawing then
            Library._cursorRunning = false
            return
        end
        local RunService = game:GetService('RunService')

        local CursorOut = Drawing.new('Triangle')
        CursorOut.Thickness = 1
        CursorOut.Filled = true
        CursorOut.Visible = false

        local CursorBody = Drawing.new('Triangle')
        CursorBody.Thickness = 1
        CursorBody.Filled = true
        CursorBody.Visible = false

        local CursorNotch = Drawing.new('Triangle')
        CursorNotch.Thickness = 1
        CursorNotch.Filled = true
        CursorNotch.Color = Color3.fromRGB(15, 14, 19)
        CursorNotch.Visible = false

        Library._cursorObjects = {
            Out = CursorOut,
            Body = CursorBody,
            Notch = CursorNotch
        }

        while not Library.Unloaded do
            RunService.RenderStepped:Wait()
            if Library.Unloaded then break end

            local show = Library.MenuOpen

            if show then
                pcall(function()
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    UserInputService.MouseIconEnabled = false
                end)
            end

            if show then
                local mPos = UserInputService:GetMouseLocation()
                local scale = 0.75

                local ax, ay = mPos.X,      mPos.Y
                local bx, by = mPos.X,      mPos.Y + 13 * scale
                local cx, cy = mPos.X + 9 * scale, mPos.Y + 9 * scale
                local nx, ny = mPos.X + 3 * scale, mPos.Y + 10 * scale

                local accent = Library.Accent
                local darkAccent = Library:GetDarkerColor(accent, 0.35)

                CursorOut.Color  = darkAccent
                CursorOut.PointA = Vector2.new(ax - 1, ay - 1)
                CursorOut.PointB = Vector2.new(bx - 1, by + 1)
                CursorOut.PointC = Vector2.new(cx + 1, cy + 1)

                CursorBody.Color  = accent
                CursorBody.PointA = Vector2.new(ax, ay)
                CursorBody.PointB = Vector2.new(bx, by)
                CursorBody.PointC = Vector2.new(cx, cy)

                CursorNotch.Color  = Color3.fromRGB(15, 14, 19)
                CursorNotch.PointA = Vector2.new(nx, ny)
                CursorNotch.PointB = Vector2.new(bx, by)
                CursorNotch.PointC = Vector2.new(cx, cy)
            end

            CursorOut.Visible   = show
            CursorBody.Visible  = show
            CursorNotch.Visible = show
        end

        if CursorOut then CursorOut:Remove() end
        if CursorBody then CursorBody:Remove() end
        if CursorNotch then CursorNotch:Remove() end
        Library._cursorRunning = false
    end)
end

function Library:SetMenuVisible(options)
    local state = type(options) == "table" and options.value or options
    if state == nil then state = not Library.MenuOpen end
    if Library.MenuOpen == state then return end
    Library.MenuOpen = state
    
    local ScreenGui = Library:GetScreenGui()
    
    local MainFrame = ScreenGui and ScreenGui:FindFirstChild("MainFrame")
    if not MainFrame then return end
    
    if Library.ModalElement then
        Library.ModalElement.Modal = Library.MenuOpen
    end

    if Library.MenuOpen then
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.25), {GroupTransparency = 0}):Play()
        pcall(function()
            UserInputService.MouseIconEnabled = false
        end)
    else
        pcall(function()
            UserInputService.MouseIconEnabled = true
        end)
        
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.25), {GroupTransparency = 1})
        tw:Play()
        
        for _, child in ipairs(ScreenGui:GetChildren()) do
            if child.Name == "PickerFrame" or child.Name == "ListWrapper" or child.Name == "KeybindCtxMenu" or child.Name == "ColorCtxMenu" then
                child.Visible = false
            end
        end

        tw.Completed:Connect(function()
            if not Library.MenuOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

function Library:GetScreenGui()
    return CoreGui:FindFirstChild("ScreenGui")
end

function Library:Draggify(frame, dragHandle)
    local handles = {}
    if type(dragHandle) == "table" then
        handles = dragHandle
    else
        table.insert(handles, dragHandle or frame)
    end

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function bindHandle(handle)
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
    end

    for _, handle in ipairs(handles) do
        bindHandle(handle)
    end

    Library:Connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local screenGui = frame:FindFirstAncestorWhichIsA("ScreenGui")
            local screenRes = screenGui and screenGui.AbsoluteSize or Vector2.new(1920, 1080)
            local absX = (startPos.X.Scale * screenRes.X) + startPos.X.Offset + delta.X
            local absY = (startPos.Y.Scale * screenRes.Y) + startPos.Y.Offset + delta.Y
            absX = math.clamp(absX, 0, math.max(0, screenRes.X - frame.AbsoluteSize.X))
            absY = math.clamp(absY, 0, math.max(0, screenRes.Y - frame.AbsoluteSize.Y))
            frame.Position = UDim2.new(
                startPos.X.Scale, absX - (startPos.X.Scale * screenRes.X),
                startPos.Y.Scale, absY - (startPos.Y.Scale * screenRes.Y)
            )
        end
    end)
end

function Library:AddResizeHandle(frame, options)
    options = options or {}
    local resizeTarget = options.ResizeTarget or frame
    local minW = options.MinWidth or 160
    local minH = options.MinHeight or 60
    local getMinSize = options.GetMinSize
    local maxW = options.MaxWidth
    local maxH = options.MaxHeight
    local zIndex = options.ZIndex or 100

    local function resolveMinSize()
        if getMinSize then
            local dynamic = getMinSize()
            if dynamic then
                return dynamic.X, dynamic.Y
            end
        end
        return minW, minH
    end

    local handle = Library:Create("TextButton", {
        Name = "ResizeHandle",
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -15, 1, -15),
        Size = UDim2.new(0, 15, 0, 15),
        Text = "",
        ZIndex = zIndex
    })

    Library:Create("Frame", {
        Parent = handle,
        BackgroundColor3 = Color3.fromRGB(150, 150, 150),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 0, 2),
        Position = UDim2.new(1, -4, 1, -4),
        ZIndex = zIndex
    })
    Library:Create("Frame", {
        Parent = handle,
        BackgroundColor3 = Color3.fromRGB(150, 150, 150),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 0, 2),
        Position = UDim2.new(1, -8, 1, -4),
        ZIndex = zIndex
    })
    Library:Create("Frame", {
        Parent = handle,
        BackgroundColor3 = Color3.fromRGB(150, 150, 150),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 0, 2),
        Position = UDim2.new(1, -4, 1, -8),
        ZIndex = zIndex
    })

    local resizing = false
    local resizeStart
    local startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = resizeTarget.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    Library:Connect(UserInputService.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local curMinW, curMinH = resolveMinSize()
            local targetW = math.max(curMinW, startSize.X + delta.X)
            local targetH = math.max(curMinH, startSize.Y + delta.Y)

            if options.ClampToScreen then
                local screenGui = options.ScreenGui or resizeTarget:FindFirstAncestorWhichIsA("ScreenGui")
                if screenGui then
                    local screenRes = screenGui.AbsoluteSize
                    local pos = resizeTarget.AbsolutePosition
                    local maxScreenW = screenRes.X - pos.X
                    local maxScreenH = screenRes.Y - pos.Y
                    targetW = math.min(targetW, maxScreenW)
                    targetH = math.min(targetH, maxScreenH)
                end
            end

            if options.LockAxis then
                if math.abs(delta.X) > math.abs(delta.Y) then
                    targetH = startSize.Y
                elseif math.abs(delta.Y) > math.abs(delta.X) then
                    targetW = startSize.X
                end
            end

            if maxW then targetW = math.min(targetW, maxW) end
            if maxH then targetH = math.min(targetH, maxH) end
            resizeTarget.Size = UDim2.fromOffset(targetW, targetH)
            if options.OnResize then
                options.OnResize(targetW, targetH)
            end
        end
    end)

    return handle
end

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local time = options.Time or 3
    local notifyType = (options.Type or "Default")
    local hasText = options.Text ~= nil
    local text = hasText and tostring(options.Text) or ""
    local accent = options.Color or Library.Accent
    local spacing = 8
    local richText = options.RichText
    if richText == nil then
        richText = true
    end
    
    local ScreenGui = Library:GetScreenGui()
    if not ScreenGui then return end
    
    local guiInset = GuiService:GetGuiInset()
    local topOffset = ScreenGui.IgnoreGuiInset and guiInset.Y or 0

    local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
    if not NotifContainer then
        NotifContainer = Library:Create("Frame", {
            Name = "NotifContainer",
            Parent = ScreenGui,
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 1, -topOffset - 24),
            Position = UDim2.new(0, 10, 0, topOffset + 44),
            ZIndex = 300
        })
    else
        NotifContainer.BackgroundTransparency = 1
        NotifContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        NotifContainer.Size = UDim2.new(1, 0, 1, -topOffset - 24)
        NotifContainer.Position = UDim2.new(0, 10, 0, topOffset + 44)
    end

    Library._activeNotifs = Library._activeNotifs or {}

    local function updateNotifPositions()
        for index, entry in ipairs(Library._activeNotifs) do
            local targetY = (index - 1) * (entry.Height + spacing)
            TweenService:Create(entry.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, targetY)
            }):Play()
        end
    end

    local bodyText = hasText and ("  " .. text) or ""
    local displayText = tostring(title) .. bodyText
    local measureText = richText and Library:StripRichText(displayText) or displayText
    local textSize = TextService:GetTextSize(measureText, 11, Enum.Font.Code, Vector2.new(1000, 1000))
    local notifWidth = math.clamp(textSize.X + 30, 150, 360)
    local notifHeight = 24
    local isTextType = tostring(notifyType):lower() == "text"

    local NotifFrame = Library:Create("Frame", {
        Name = "Notification",
        Parent = NotifContainer,
        BackgroundColor3 = Color3.fromRGB(24, 24, 30),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, notifWidth, 0, notifHeight),
        Position = UDim2.new(0, -260, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 301
    })

    local Inline
    if isTextType then
        NotifFrame.BackgroundTransparency = 1
        Inline = Library:Create("Frame", {
            Parent = NotifFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            ZIndex = 302
        })
    else
        Library:Create("UIStroke", {
            Parent = NotifFrame,
            Color = Color3.fromRGB(58, 58, 70),
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })

        Inline = Library:Create("Frame", {
            Parent = NotifFrame,
            BackgroundColor3 = Color3.fromRGB(16, 16, 20),
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            ZIndex = 302
        })

        Library:Create("Frame", {
            Parent = Inline,
            BackgroundColor3 = accent,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BorderSizePixel = 0,
            ZIndex = 303
        })
    end

    local Label = Library:Create("TextLabel", {
        Parent = Inline,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, isTextType and 0 or 8, 0, 0),
        Size = UDim2.new(1, isTextType and 0 or -10, 1, -1),
        Font = Enum.Font.Code,
        Text = displayText,
        TextColor3 = isTextType and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(225, 225, 225),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = richText,
        ZIndex = 304
    })
    
    if isTextType then
        Library:Create("UIStroke", {
            Parent = Label,
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 1,
            Transparency = 0.45,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })
    end

    local ProgressBar = nil
    if not isTextType then
        ProgressBar = Library:Create("Frame", {
            Parent = Inline,
            BackgroundColor3 = accent,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
            ZIndex = 305
        })
        NotifFrame.BackgroundTransparency = 1
    else
        NotifFrame.BackgroundTransparency = 1
    end
    
    local notifData = {
        Frame = NotifFrame,
        Height = notifHeight,
        Closing = false
    }
    table.insert(Library._activeNotifs, 1, notifData)
    updateNotifPositions()

    TweenService:Create(NotifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = isTextType and 1 or 0
    }):Play()
    
    local elapsed = 0
    local connection
    connection = Library:Connect(game:GetService("RunService").Heartbeat, function(dt)
        if notifData.Closing then return end
        elapsed = elapsed + dt
        local progress = math.clamp(1 - (elapsed / time), 0, 1)
        if ProgressBar then
            ProgressBar.Size = UDim2.new(progress, 0, 0, 1)
        end
        
        if elapsed >= time then
            if connection and connection.Connected then
                connection:Disconnect()
            end

            notifData.Closing = true
            local tw = TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -(notifWidth + 20), 0, NotifFrame.Position.Y.Offset),
                BackgroundTransparency = 1
            })
            tw:Play()
            Library:Connect(tw.Completed, function()
                for i, entry in ipairs(Library._activeNotifs) do
                    if entry == notifData then
                        table.remove(Library._activeNotifs, i)
                        break
                    end
                end
                if NotifFrame.Parent then
                    NotifFrame:Destroy()
                end
                updateNotifPositions()
            end)
        end
    end)
    
    NotifFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if notifData.Closing then return end
            notifData.Closing = true
            if connection then
                connection:Disconnect()
            end
            
            local tw = TweenService:Create(NotifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -(notifWidth + 20), 0, NotifFrame.Position.Y.Offset),
                BackgroundTransparency = 1
            })
            tw:Play()
            Library:Connect(tw.Completed, function()
                for i, entry in ipairs(Library._activeNotifs) do
                    if entry == notifData then
                        table.remove(Library._activeNotifs, i)
                        break
                    end
                end
                if NotifFrame.Parent then
                    NotifFrame:Destroy()
                end
                updateNotifPositions()
            end)
        end
    end)
end

function Library:EnsureConfigFolder()
    local folder = Library.ConfigFolder
    if makefolder and not isfolder(folder) then
        pcall(makefolder, folder)
    end
    return folder
end

function Library:GetConfigNames()
    local folder = Library:EnsureConfigFolder()
    local names = {}
    if listfiles then
        local ok, files = pcall(listfiles, folder)
        if ok and files then
            for _, path in ipairs(files) do
                local name = path:match("([^\\/]+)%.json$")
                if name then
                    table.insert(names, name)
                end
            end
        end
    end
    table.sort(names)
    return names
end

function Library:SerializeFlags()
    local data = {}
    for flag, obj in pairs(Library.Flags) do
        if type(obj) == "table" then
            if obj.Value ~= nil and obj.Key == nil and obj.Color == nil then
                data[flag] = { t = "v", v = obj.Value }
            elseif obj.Color ~= nil then
                data[flag] = {
                    t = "c",
                    r = obj.Color.R, g = obj.Color.G, b = obj.Color.B,
                    a = obj.Alpha or 1
                }
            elseif obj.Key ~= nil then
                data[flag] = { t = "k", key = obj.Key, mode = obj.Mode or "Toggle" }
            end
        end
    end
    return HttpService:JSONEncode(data)
end

function Library:ApplyFlags(data)
    if type(data) ~= "table" then return end
    for flag, entry in pairs(data) do
        local obj = Library.Flags[flag]
        if obj and type(entry) == "table" then
            if entry.t == "v" and obj.SetValue then
                obj:SetValue(entry.v)
            elseif entry.t == "c" and obj.SetValue then
                obj:SetValue({
                    Color = Color3.new(entry.r, entry.g, entry.b),
                    Alpha = entry.a
                })
            elseif entry.t == "k" and obj.SetValue then
                local oldKey = obj.Key
                local oldMode = obj.Mode
                obj.Key = entry.key
                obj.Mode = entry.mode
                if entry.mode == "Always" then
                    obj.State = true
                else
                    obj.State = false
                end
                if Library.Flags[flag] then
                    Library.Flags[flag] = obj
                end
                Library:UpdateKeybindList()
            end
        end
    end
end

function Library:SaveConfig(name)
    if not name or name == "" then return false end
    if not writefile then return false end
    local folder = Library:EnsureConfigFolder()
    local path = folder .. "/" .. name .. ".json"
    local ok = pcall(writefile, path, Library:SerializeFlags())
    return ok
end

function Library:LoadConfig(name)
    if not name or name == "" then return false end
    if not readfile or not isfile then return false end
    local folder = Library:EnsureConfigFolder()
    local path = folder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok, raw = pcall(readfile, path)
    if not ok or not raw then return false end
    local decodedOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not decodedOk then return false end
    Library:ApplyFlags(data)
    return true
end

function Library:DeleteConfig(name)
    if not name or name == "" then return false end
    if not delfile or not isfile then return false end
    local folder = Library:EnsureConfigFolder()
    local path = folder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    return pcall(delfile, path)
end

function Library:GetKeybindListMinSize()
    local baseW = Library.KB_DEFAULT_W or 236
    local baseH = Library.KB_DEFAULT_H or 74
    local headerH = (Library.KB_HEADER_H or 40) + 10
    local chromeH = 36
    local entriesH = 28

    if Library.KeybindListLayout then
        entriesH = math.max(32, Library.KeybindListLayout.AbsoluteContentSize.Y + 8)
    elseif #Library.KeybindListEntries > 0 then
        local n = #Library.KeybindListEntries
        entriesH = 16 + n * 16 + math.max(0, n - 1) * 8
    end

    return Vector2.new(baseW, math.max(baseH, headerH + entriesH + chromeH))
end

function Library:EnforceKeybindListMinSize()
    if not Library.KeybindListFrame then return end
    local minSize = Library:GetKeybindListMinSize()
    local current = Library.KeybindListFrame.AbsoluteSize
    if current.X < minSize.X or current.Y < minSize.Y then
        Library.KeybindListFrame.Size = UDim2.fromOffset(
            math.max(current.X, minSize.X),
            math.max(current.Y, minSize.Y)
        )
    end
end

function Library:UpdateKeybindList()
    if not Library.KeybindListContainer then return end
    for _, child in ipairs(Library.KeybindListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local function formatKey(keyStr)
        local k = tostring(keyStr):lower()
        if k == "mousebutton1" or k == "mouse1" then return "MB1" end
        if k == "mousebutton2" or k == "mouse2" then return "MB2" end
        if k == "mousebutton3" or k == "mouse3" then return "MB3" end
        if k == "backspace" then return "BCK" end
        if k == "delete" then return "DEL" end
        if k == "insert" then return "INS" end
        if k == "leftcontrol" or k == "lcontrol" then return "LCtrl" end
        if k == "rightcontrol" or k == "rcontrol" then return "RCtrl" end
        if k == "leftalt" or k == "lalt" then return "LAlt" end
        if k == "rightalt" or k == "ralt" then return "RAlt" end
        if k == "leftshift" or k == "lshift" then return "LShift" end
        if k == "rightshift" or k == "rshift" then return "RShift" end
        if k == "unknown" or k == "none" then return "None" end
        return string.upper(keyStr)
    end

    for _, entry in ipairs(Library.KeybindListEntries) do
        local row = Library:Create("Frame", {
            Name = entry.Name,
            Parent = Library.KeybindListContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            BorderSizePixel = 0
        })

        Library:Create("TextLabel", {
            Parent = row,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.55, -4, 1, 0),
            Position = UDim2.new(0, 2, 0, 0),
            Font = Enum.Font.Code,
            Text = entry.Name,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center
        })

        local modeText = entry.Object.Mode == "Hold" and "[H]" or (entry.Object.Mode == "Always" and "[A]" or "")
        Library:Create("TextLabel", {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.55, 0, 0, 0),
            Size = UDim2.new(0.45, -6, 1, 0),
            Font = Enum.Font.Code,
            Text = formatKey(entry.Object.Key) .. " " .. modeText,
            TextColor3 = entry.Object.State and Library.Accent or Color3.fromRGB(140, 140, 140),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center
        })
    end

    Library:EnforceKeybindListMinSize()
    if Library.UpdateKeybindListScrollUI then
        Library.UpdateKeybindListScrollUI()
    end
end

function Library:RegisterKeybindList(name, kbObj)
    for i, entry in ipairs(Library.KeybindListEntries) do
        if entry.Object == kbObj then
            entry.Name = name
            Library:UpdateKeybindList()
            return
        end
    end
    table.insert(Library.KeybindListEntries, { Name = name, Object = kbObj, Mode = kbObj.Mode })
    Library:UpdateKeybindList()
end

function Library:CreateKeybindList()
    if Library.KeybindListFrame then return Library.KeybindListFrame end

    local ScreenGui = Library:GetScreenGui()
    if not ScreenGui then return nil end

    local KB_DEFAULT_W = 236
    local KB_DEFAULT_H = 74
    Library.KB_DEFAULT_W = KB_DEFAULT_W
    Library.KB_DEFAULT_H = KB_DEFAULT_H

    local screenRes = ScreenGui.AbsoluteSize
    local keybindlist = Library:Create("Frame", {
        Name = "KeybindList",
        Parent = ScreenGui,
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 12, 0, math.floor(screenRes.Y * 0.5 - KB_DEFAULT_H * 0.5)),
        Size = UDim2.new(0, KB_DEFAULT_W, 0, KB_DEFAULT_H),
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = false,
        ZIndex = 50
    })

    local Border1 = Library:Create("Frame", {
        Parent = keybindlist,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 51
    })

    local Border2 = Library:Create("Frame", {
        Parent = Border1,
        BackgroundColor3 = Color3.fromRGB(35, 33, 40),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 52
    })

    local Border3 = Library:Create("Frame", {
        Parent = Border2,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        BorderSizePixel = 0,
        ZIndex = 53
    })

    local MainBg = Library:Create("Frame", {
        Name = "MainBg",
        Parent = Border3,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 54
    })

    Library:Create("UIGradient", {
        Name = "MainBgGradient",
        Parent = MainBg,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 14, 19)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 24, 30))
        })
    })

    local KB_HEADER_H = 40

    local tab_holder = Library:Create("Frame", {
        Name = "Header",
        Parent = MainBg,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, KB_HEADER_H),
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 56
    })

    local headerBtn = Library:Create("TextButton", {
        Font = Enum.Font.Code,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "keybinds",
        Parent = tab_holder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 1),
        BorderSizePixel = 0,
        TextSize = 13,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextXAlignment = Enum.TextXAlignment.Center,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 57
    })

    local accent = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Parent = tab_holder,
        Position = UDim2.new(0, 0, 1, -4),
        Size = UDim2.new(1, 0, 0, 6),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 58
    })

    Library:Create("UIGradient", {
        Name = "AccentGradient",
        Parent = accent,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.Accent),
            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.15))
        })
    })

    local split = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Parent = accent,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 3),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 59
    })

    Library:Create("UIGradient", {
        Name = "AccentDarkGradient",
        Parent = split,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.Accent, 0.2)),
            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.45))
        })
    })

    Library.KeybindListHeader = tab_holder

    local listOuter = Library:Create("Frame", {
        Name = "ListOuter",
        Parent = MainBg,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 10, 0, KB_HEADER_H),
        Size = UDim2.new(1, -20, 1, -(KB_HEADER_H + 8)),
        BorderSizePixel = 0,
        ZIndex = 56
    })

    local listMiddle = Library:Create("Frame", {
        Parent = listOuter,
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 57
    })

    local listInner = Library:Create("Frame", {
        Parent = listMiddle,
        BackgroundColor3 = Color3.fromRGB(27, 27, 34),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 58
    })

    local listScroll = Library:Create("ScrollingFrame", {
        Name = "ListScroll",
        Parent = listInner,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ClipsDescendants = true,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 59
    })

    Library.KeybindListContainer = Library:Create("Frame", {
        Name = "Entries",
        Parent = listScroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ZIndex = 60
    })

    local listLayout = Library:Create("UIListLayout", {
        Parent = Library.KeybindListContainer,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Library.KeybindListLayout = listLayout

    Library:Create("UIPadding", {
        Parent = Library.KeybindListContainer,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })

    local KbTopGlow = Library:Create("ImageLabel", {
        Parent = listInner,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 1, 0, 0),
        Size = UDim2.new(1, -18, 0, 15),
        Image = "rbxassetid://15541064478",
        ImageColor3 = Color3.fromRGB(27, 27, 34),
        Rotation = 180,
        Visible = false,
        ZIndex = 62
    })

    local KbBottomGlow = Library:Create("ImageLabel", {
        Parent = listInner,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 1, 1, -15),
        Size = UDim2.new(1, -18, 0, 15),
        Image = "rbxassetid://15541064478",
        ImageColor3 = Color3.fromRGB(27, 27, 34),
        Rotation = 0,
        Visible = false,
        ZIndex = 62
    })

    local KbScrollUp = Library:Create("ImageButton", {
        Parent = listInner,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0, 4),
        Size = UDim2.new(0, 10, 0, 10),
        Image = "rbxassetid://252644715",
        Rotation = 180,
        ImageColor3 = Color3.fromRGB(150, 150, 150),
        Visible = false,
        ZIndex = 63
    })

    local KbScrollDown = Library:Create("ImageButton", {
        Parent = listInner,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 10, 0, 10),
        Image = "rbxassetid://252644715",
        Rotation = 0,
        ImageColor3 = Color3.fromRGB(150, 150, 150),
        Visible = false,
        ZIndex = 63
    })

    local function KbAddScrollEffects(btn)
        btn.MouseEnter:Connect(function() btn.ImageColor3 = Library.Accent end)
        btn.MouseLeave:Connect(function() btn.ImageColor3 = Color3.fromRGB(150, 150, 150) end)
    end
    KbAddScrollEffects(KbScrollUp)
    KbAddScrollEffects(KbScrollDown)

    local function UpdateKbScrollUI()
        local contentHeight = listLayout.AbsoluteContentSize.Y + 12
        listScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
        local isScrollable = contentHeight > listScroll.AbsoluteSize.Y
        if isScrollable then
            local maxScroll = math.max(0, listScroll.CanvasSize.Y.Offset - listScroll.AbsoluteSize.Y)
            local currentScroll = listScroll.CanvasPosition.Y
            KbScrollUp.Visible = currentScroll > 2
            KbScrollDown.Visible = currentScroll < (maxScroll - 2)
            KbTopGlow.Visible = currentScroll > 2
            KbBottomGlow.Visible = currentScroll < (maxScroll - 2)
        else
            KbScrollUp.Visible = false
            KbScrollDown.Visible = false
            KbTopGlow.Visible = false
            KbBottomGlow.Visible = false
        end
    end

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UpdateKbScrollUI()
    end)
    listScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateKbScrollUI)
    listScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateKbScrollUI)

    KbScrollUp.MouseButton1Click:Connect(function()
        local newPos = listScroll.CanvasPosition.Y - 40
        TweenService:Create(listScroll, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.max(0, newPos))}):Play()
    end)

    KbScrollDown.MouseButton1Click:Connect(function()
        local maxScroll = listScroll.CanvasSize.Y.Offset - listScroll.AbsoluteSize.Y
        local newPos = listScroll.CanvasPosition.Y + 40
        TweenService:Create(listScroll, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.min(maxScroll, newPos))}):Play()
    end)

    Library.KeybindListScroll = listScroll
    Library.KeybindListOuter = listOuter
    Library.UpdateKeybindListScrollUI = UpdateKbScrollUI
    Library:Draggify(keybindlist, { tab_holder, headerBtn })
    Library.KB_HEADER_H = KB_HEADER_H

    local ResizeHandle = Library:Create("TextButton", {
        Name = "ResizeHandle",
        Parent = keybindlist,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -15, 1, -15),
        Size = UDim2.new(0, 15, 0, 15),
        Text = "",
        ZIndex = 120
    })

    Library:Create("Frame", { Parent = ResizeHandle, BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 2), Position = UDim2.new(1, -4, 1, -4), ZIndex = 120 })
    Library:Create("Frame", { Parent = ResizeHandle, BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 2), Position = UDim2.new(1, -8, 1, -4), ZIndex = 120 })
    Library:Create("Frame", { Parent = ResizeHandle, BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 2), Position = UDim2.new(1, -4, 1, -8), ZIndex = 120 })

    local resizing = false
    local resizeStart
    local startSize

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = keybindlist.AbsoluteSize

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    Library:Connect(UserInputService.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local screenRes = ScreenGui.AbsoluteSize

            local maxW = screenRes.X - keybindlist.AbsolutePosition.X
            local maxH = screenRes.Y - keybindlist.AbsolutePosition.Y

            local contentMin = Library:GetKeybindListMinSize()
            local minW = KB_DEFAULT_W
            local minH = math.max(KB_DEFAULT_H, contentMin.Y)

            local targetW = math.max(minW, math.min(startSize.X + delta.X, maxW))
            local targetH = math.max(minH, math.min(startSize.Y + delta.Y, maxH))

            keybindlist.Size = UDim2.new(0, targetW, 0, targetH)
            UpdateKbScrollUI()
        end
    end)

    Library.KeybindListFrame = keybindlist
    keybindlist.Visible = Library.KeybindListVisible
    Library:UpdateKeybindList()
    return keybindlist
end

function Library:SetKeybindListVisible(state)
    Library.KeybindListVisible = state
    if Library.KeybindListFrame then
        Library.KeybindListFrame.Visible = state
    end
end

function Library:CreateWatermark()
    if Library.WatermarkFrame then return Library.WatermarkFrame end

    local ScreenGui = Library:GetScreenGui()
    if not ScreenGui then return nil end

    local cleanText = Library:StripRichText(Library.WatermarkText)
    local textBounds = TextService:GetTextSize(cleanText, 12, Enum.Font.Code, Vector2.new(1000, 1000))
    local width = math.max(140, textBounds.X + 26)

    local watermark = Library:Create("Frame", {
        Name = "Watermark",
        Parent = ScreenGui,
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 12),
        Size = UDim2.new(0, width, 0, 24),
        BorderSizePixel = 0,
        Visible = Library.WatermarkVisible,
        ZIndex = 60
    })

    local border1 = Library:Create("Frame", {
        Parent = watermark,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 61
    })

    local border2 = Library:Create("Frame", {
        Parent = border1,
        BackgroundColor3 = Color3.fromRGB(35, 33, 40),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 62
    })

    local mainBg = Library:Create("Frame", {
        Parent = border2,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 63
    })

    Library:Create("UIGradient", {
        Name = "MainBgGradient",
        Parent = mainBg,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 14, 19)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 24, 30))
        })
    })

    Library:Create("Frame", {
        Name = "AccentLine",
        Parent = mainBg,
        BackgroundColor3 = Library.Accent,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        ZIndex = 64
    })

    local label = Library:Create("TextLabel", {
        Name = "Text",
        Parent = mainBg,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 1),
        Size = UDim2.new(1, -16, 1, -2),
        Font = Enum.Font.Code,
        Text = Library.WatermarkText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true,
        ZIndex = 65
    })

    Library:Create("UIStroke", {
        Name = "TextStroke",
        Parent = label,
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    })

    Library.WatermarkFrame = watermark
    Library.WatermarkLabel = label
    Library:Draggify(watermark)
    Library:SetWatermarkText(Library.WatermarkText)
    Library:SetWatermarkVisible(Library.WatermarkVisible)

    return watermark
end

function Library:SetWatermarkVisible(state)
    Library.WatermarkVisible = state
    if Library.WatermarkFrame then
        Library.WatermarkFrame.Visible = state
    end
end

function Library:SetWatermarkText(text)
    Library.WatermarkText = tostring(text or "")
    if Library.WatermarkLabel and Library.WatermarkFrame then
        Library.WatermarkLabel.Text = Library.WatermarkText
        local cleanText = Library:StripRichText(Library.WatermarkText)
        local textBounds = TextService:GetTextSize(cleanText, 12, Enum.Font.Code, Vector2.new(1000, 1000))
        Library.WatermarkFrame.Size = UDim2.new(0, math.max(140, textBounds.X + 26), 0, 24)
    end
end

function Library:ChangeAccent(newColor)
    if Library.Flags and Library.Flags["CustomAccentToggle"] and not Library.Flags["CustomAccentToggle"].Value then
        newColor = Library.DefaultAccent or Library.Accent
    end
    Library.Accent = typeof(newColor) == "table" and newColor.value or newColor
    Library:ApplyAccentRegistry()
end

function Library:CreateWindow(options)
    options = options or {}
    Library.Unloaded = false
    local WindowSize = options.Size or UDim2.new(0, 580, 0, 550)
    
    local ScreenGui = self:Create("ScreenGui", {
        Name = "ScreenGui",
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })

    local ModalElement = self:Create("TextButton", {
        Name = "ModalElement",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = true,
        Text = "",
        Modal = Library.MenuOpen,
        Parent = ScreenGui
    })
    Library.ModalElement = ModalElement
    Library:CreateWatermark()

    Library:_StartCursor()

    if Library.MenuOpen then
        pcall(function()
            UserInputService.MouseIconEnabled = false
        end)
    end

    local MainFrame = self:Create("CanvasGroup", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        Position = UDim2.new(0.5, -WindowSize.X.Offset / 2, 0.5, -WindowSize.Y.Offset / 2),
        Size = WindowSize,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Active = true
    })

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local relativeY = input.Position.Y - MainFrame.AbsolutePosition.Y
            
            if relativeY >= 0 and relativeY <= 50 then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    Library:Connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local screenRes = ScreenGui.AbsoluteSize
            
            local currentAbsX = (startPos.X.Scale * screenRes.X) + startPos.X.Offset + delta.X
            local currentAbsY = (startPos.Y.Scale * screenRes.Y) + startPos.Y.Offset + delta.Y
            
            local clampedAbsX = math.clamp(currentAbsX, 0, math.max(0, screenRes.X - MainFrame.AbsoluteSize.X))
            local clampedAbsY = math.clamp(currentAbsY, 0, math.max(0, screenRes.Y - MainFrame.AbsoluteSize.Y))
            
            local finalOffsetX = clampedAbsX - (startPos.X.Scale * screenRes.X)
            local finalOffsetY = clampedAbsY - (startPos.Y.Scale * screenRes.Y)
            
            MainFrame.Position = UDim2.new(startPos.X.Scale, finalOffsetX, startPos.Y.Scale, finalOffsetY)
        end
    end)

    local ResizeHandle = self:Create("TextButton", {
        Name = "ResizeHandle",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -15, 1, -15),
        Size = UDim2.new(0, 15, 0, 15),
        Text = "",
        ZIndex = 100
    })

    self:Create("Frame", { Parent = ResizeHandle, BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 2), Position = UDim2.new(1, -4, 1, -4), ZIndex = 100 })
    self:Create("Frame", { Parent = ResizeHandle, BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 2), Position = UDim2.new(1, -8, 1, -4), ZIndex = 100 })
    self:Create("Frame", { Parent = ResizeHandle, BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 2), Position = UDim2.new(1, -4, 1, -8), ZIndex = 100 })

    local resizing = false
    local resizeStart
    local startSize

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.AbsoluteSize
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    Library:Connect(UserInputService.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local screenRes = ScreenGui.AbsoluteSize
            
            local maxW = screenRes.X - MainFrame.AbsolutePosition.X
            local maxH = screenRes.Y - MainFrame.AbsolutePosition.Y
            
            local targetW = math.max(WindowSize.X.Offset, math.min(startSize.X + delta.X, maxW))
            local targetH = math.max(350, math.min(startSize.Y + delta.Y, maxH))
            
            MainFrame.Size = UDim2.new(0, targetW, 0, targetH)
        end
    end)

    local Border1 = self:Create("Frame", {
        Name = "Border1",
        Parent = MainFrame,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0
    })

    local Border2 = self:Create("Frame", {
        Name = "Border2",
        Parent = Border1,
        BackgroundColor3 = Color3.fromRGB(35, 33, 40),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0
    })

    local Border3 = self:Create("Frame", {
        Name = "Border3",
        Parent = Border2,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        BorderSizePixel = 0
    })

    local MainBackground = self:Create("Frame", {
        Name = "MainBackground",
        Parent = Border3,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0
    })

    self:Create("UIGradient", {
        Name = "MainBgGradient",
        Parent = MainBackground,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 14, 19)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 24, 30))  
        })
    })

    local TopAccent = self:Create("Frame", {
        Name = "TopAccent",
        Parent = MainBackground,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 3
    })

    self:Create("UIGradient", {
        Name = "AccentGradient",
        Parent = TopAccent,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.Accent), 
            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.15)) 
        })
    })

    local TabBarBorder = self:Create("Frame", {
        Name = "TabBarBorder",
        Parent = MainBackground,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 10, 0, 15),
        Size = UDim2.new(1, -20, 0, 35),
        BorderSizePixel = 0,
        ZIndex = 2
    })

    local TabBarMain = self:Create("Frame", {
        Name = "TabBarMain",
        Parent = TabBarBorder,
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 2
    })

    local TabBar = self:Create("Frame", {
        Name = "TabBar",
        Parent = TabBarMain,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 2
    })

    self:Create("UIListLayout", {
        Name = "TabBarLayout",
        Parent = TabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0)
    })

    local TabContainerBorder = self:Create("Frame", {
        Name = "TabContainerBorder",
        Parent = MainBackground,
        BackgroundColor3 = Color3.fromRGB(55, 53, 62),
        Position = UDim2.new(0, 10, 0, 49),
        Size = UDim2.new(1, -20, 1, -59),
        BorderSizePixel = 0,
        ZIndex = 1
    })

    local TabContainerMain = self:Create("Frame", {
        Name = "TabContainerMain",
        Parent = TabContainerBorder,
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 1
    })

    local TabContainer = self:Create("Frame", {
        Name = "TabContainer",
        Parent = TabContainerMain,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1
    })

    local Window = {
        Tabs = {},
        CurrentTab = nil
    }

    function Window:ShowDialog(options)
        if MainFrame:FindFirstChild("DialogOverlay") then
            return
        end

        local text = options.Text or "Are you sure?"
        local callback = options.Callback or function() end

        local Overlay = Library:Create("Frame", {
            Name = "DialogOverlay",
            Parent = MainFrame,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            Active = true,
            ZIndex = 200
        })

        local DialogFrame = Library:Create("Frame", {
            Name = "DialogFrame",
            Parent = Overlay,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Size = UDim2.new(0, 320, 0, 120),
            Position = UDim2.new(0.5, -160, 0.5, -60),
            BorderSizePixel = 0,
            ZIndex = 201
        })

        local DBorder1 = Library:Create("Frame", {
            Parent = DialogFrame,
            BackgroundColor3 = Color3.fromRGB(55, 53, 62),
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            ZIndex = 202
        })

        local DBorder2 = Library:Create("Frame", {
            Parent = DBorder1,
            BackgroundColor3 = Color3.fromRGB(35, 33, 40),
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            ZIndex = 203
        })

        local DBorder3 = Library:Create("Frame", {
            Parent = DBorder2,
            BackgroundColor3 = Color3.fromRGB(55, 53, 62),
            Position = UDim2.new(0, 5, 0, 5),
            Size = UDim2.new(1, -10, 1, -10),
            BorderSizePixel = 0,
            ZIndex = 204
        })

        local DMainBackground = Library:Create("Frame", {
            Parent = DBorder3,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            ZIndex = 205
        })

        Library:Create("UIGradient", {
            Parent = DMainBackground,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 14, 19)), 
                ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 24, 30))  
            })
        })

        local DTopAccent = Library:Create("Frame", {
            Parent = DMainBackground,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 0, 2),
            BorderSizePixel = 0,
            ZIndex = 206
        })

        Library:Create("UIGradient", {
            Parent = DTopAccent,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library.Accent), 
                ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.15)) 
            })
        })

        Library:Create("TextLabel", {
            Parent = DMainBackground,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 20, 0, 15),
            Size = UDim2.new(1, -40, 0, 40),
            Font = Enum.Font.Code,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 207
        })

        local function CreateDialogButton(name, xOffset, onClick)
            local Btn = Library:Create("TextButton", {
                Parent = DMainBackground,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(1, xOffset, 1, -35),
                Size = UDim2.new(0, 70, 0, 22),
                AutoButtonColor = false,
                Text = "",
                BorderSizePixel = 0,
                ZIndex = 207
            })

            Library:Create("UIGradient", {
                Parent = Btn,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(41, 41, 48)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 43))
                })
            })

            Library:Create("UIStroke", {
                Parent = Btn,
                Color = Color3.fromRGB(12, 12, 12),
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            local BtnText = Library:Create("TextLabel", {
                Parent = Btn,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Code,
                Text = name,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 11,
                ZIndex = 208
            })

            Btn.MouseButton1Down:Connect(function() BtnText.TextColor3 = Color3.fromRGB(150, 150, 150) end)
            Btn.MouseButton1Up:Connect(function() BtnText.TextColor3 = Color3.fromRGB(255, 255, 255) end)
            Btn.MouseButton1Click:Connect(onClick)
        end

        local function Close() Overlay:Destroy() end

        CreateDialogButton("Yes", -155, function() Close() callback() end)
        CreateDialogButton("No", -75, Close)
    end
    
    function Window:CreateTab(tabOptions)
        tabOptions = typeof(tabOptions) == "table" and tabOptions or { Title = tabOptions }
        local name = tabOptions.Title or "Tab"
        
        local Tab = {
            Name = name,
            Active = false,
            Sectors = {}
        }

        local TabButton = Library:Create("TextButton", {
            Name = name .. "TabButton",
            Parent = TabBar,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 3
        })
        
        Tab.Button = TabButton

        Library:Create("UIStroke", {
            Name = "ButtonStroke",
            Parent = TabButton,
            Color = Color3.fromRGB(55, 53, 62),
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })

        local TabGradient = Library:Create("UIGradient", {
            Name = "TabGradient",
            Parent = TabButton,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 46, 55)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 14, 19))
            })
        })

        local TabTitle = Library:Create("TextLabel", {
            Name = "Title",
            Parent = TabButton,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.Code,
            Text = name,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            ZIndex = 4
        })

        Library:Create("UIStroke", {
            Name = "TextStroke",
            Parent = TabTitle,
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 1,
            Transparency = 0.6,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        })

        local TabAccentLine = Library:Create("Frame", {
            Name = "AccentLine",
            Parent = TabButton,
            BackgroundColor3 = Library.Accent,
            Position = UDim2.new(0, 1, 1, -1),
            Size = UDim2.new(1, -2, 0, 1),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 5
        })

        local ContentFrame = Library:Create("Frame", {
            Name = name .. "Content",
            Parent = TabContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        })

        local SideContainer = Library:Create("Frame", {
            Name = "SideContainer",
            Parent = ContentFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0)
        })

        Library:Create("UIListLayout", {
            Name = "SideLayout",
            Parent = SideContainer,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })

        Library:Create("UIPadding", {
            Name = "SidePadding",
            Parent = SideContainer,
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })

        local function CreateSide(sideName, parentContainer)
            local targetParent = parentContainer or SideContainer

            local SideFrame = Library:Create("Frame", {
                Name = sideName,
                Parent = targetParent,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -2, 1, 0)
            })

            local SideList = Library:Create("Frame", {
                Name = "List",
                Parent = SideFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ClipsDescendants = true
            })

            local Layout = Library:Create("UIListLayout", {
                Name = "Layout",
                Parent = SideList,
                Padding = UDim.new(0, 15),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left
            })

            Library:Create("UIPadding", {
                Name = "Padding",
                Parent = SideList,
                PaddingTop = UDim.new(0, 15),
                PaddingBottom = UDim.new(0, 15),
                PaddingLeft = UDim.new(0, 8)
            })

            local SideObject = {
                Sectors = {}
            }

            local function UpdateSectorSizes()
                local sectorCount = #SideObject.Sectors
                if sectorCount == 0 then return end
                local layoutOffset = 15 * (sectorCount - 1)
                for _, sector in ipairs(SideObject.Sectors) do
                    sector.Main.Size = UDim2.new(0.98, 0, 1 / sectorCount, -layoutOffset / sectorCount)
                end
            end

            function SideObject:CreateSector(sectorOptions)
                sectorOptions = typeof(sectorOptions) == "table" and sectorOptions or { Title = sectorOptions }
                local sectorTitle = sectorOptions.Title or "Sector"

                local SectorOuter = Library:Create("Frame", {
                    Name = sectorTitle .. "Sector",
                    Parent = SideList,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Size = UDim2.new(0.98, 0, 0, 0),
                    BorderSizePixel = 0
                })

                local SectorMiddle = Library:Create("Frame", {
                    Name = "MiddleBorder",
                    Parent = SectorOuter,
                    BackgroundColor3 = Color3.fromRGB(55, 53, 62),
                    Position = UDim2.new(0, 1, 0, 1),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0
                })

                local SectorInner = Library:Create("Frame", {
                    Name = "InnerBorder",
                    Parent = SectorMiddle,
                    BackgroundColor3 = Color3.fromRGB(27, 27, 34),
                    Position = UDim2.new(0, 1, 0, 1),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    ClipsDescendants = true
                })

                local TitleMask = Library:Create("Frame", {
                    Name = "TitleMask",
                    Parent = SectorOuter,
                    BackgroundColor3 = Color3.fromRGB(32, 32, 38),
                    Position = UDim2.new(0, 10, 0, -7),
                    Size = UDim2.new(0, 0, 0, 14),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BorderSizePixel = 0,
                    ZIndex = 15
                })

                local TitleLabel = Library:Create("TextLabel", {
                    Name = "Title",
                    Parent = TitleMask,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Code,
                    Text = "<b>" .. sectorTitle .. "</b>",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 13,
                    ZIndex = 16,
                    RichText = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center
                })

                Library:Create("UIStroke", {
                    Name = "TextStroke",
                    Parent = TitleLabel,
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 1,
                    Transparency = 0.6,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                })

                Library:Create("UIPadding", {
                    Name = "TitlePadding",
                    Parent = TitleLabel,
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4)
                })

                local ScrollFrame = Library:Create("ScrollingFrame", {
                    Name = "ScrollFrame",
                    Parent = SectorInner,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 10),
                    Size = UDim2.new(1, 0, 1, -10),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 0,
                    ClipsDescendants = true,
                    ElasticBehavior = Enum.ElasticBehavior.Never,
                    ZIndex = 5
                })

                local ContentLayout = Library:Create("UIListLayout", {
                    Name = "ContentLayout",
                    Parent = ScrollFrame,
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left
                })

                Library:Create("UIPadding", {
                    Name = "ContentPadding",
                    Parent = ScrollFrame,
                    PaddingTop = UDim.new(0, 8),
                    PaddingBottom = UDim.new(0, 12),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10)
                })

                local TopGlow = Library:Create("ImageLabel", {
                    Name = "TopGlow",
                    Parent = SectorInner,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 1, 0, 10),
                    Size = UDim2.new(1, -2, 0, 20),
                    Image = "rbxassetid://15541064478",
                    ImageColor3 = Color3.fromRGB(27, 27, 34),
                    Rotation = 180,
                    Visible = false,
                    ZIndex = 10
                })

                local BottomGlow = Library:Create("ImageLabel", {
                    Name = "BottomGlow",
                    Parent = SectorInner,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 1, 1, -20),
                    Size = UDim2.new(1, -2, 0, 20),
                    Image = "rbxassetid://15541064478",
                    ImageColor3 = Color3.fromRGB(27, 27, 34),
                    Rotation = 0,
                    Visible = false,
                    ZIndex = 10
                })

                local ScrollUp = Library:Create("ImageButton", {
                    Name = "ScrollUp",
                    Parent = SectorInner,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -18, 0, 12),
                    Size = UDim2.new(0, 10, 0, 10),
                    Image = "rbxassetid://252644715",
                    Rotation = 180,
                    ImageColor3 = Color3.fromRGB(150, 150, 150),
                    Visible = false,
                    ZIndex = 25
                })

                local ScrollDown = Library:Create("ImageButton", {
                    Name = "ScrollDown",
                    Parent = SectorInner,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -18, 1, -18),
                    Size = UDim2.new(0, 10, 0, 10),
                    Image = "rbxassetid://252644715",
                    Rotation = 0,
                    ImageColor3 = Color3.fromRGB(150, 150, 150),
                    Visible = false,
                    ZIndex = 25
                })

                ScrollUp.MouseEnter:Connect(function() ScrollUp.ImageColor3 = Library.Accent end)
                ScrollUp.MouseLeave:Connect(function() ScrollUp.ImageColor3 = Color3.fromRGB(150, 150, 150) end)
                ScrollDown.MouseEnter:Connect(function() ScrollDown.ImageColor3 = Library.Accent end)
                ScrollDown.MouseLeave:Connect(function() ScrollDown.ImageColor3 = Color3.fromRGB(150, 150, 150) end)

                local function UpdateScrollUI()
                    local contentHeight = ContentLayout.AbsoluteContentSize.Y + 20
                    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                    local isScrollable = contentHeight > ScrollFrame.AbsoluteSize.Y
                    if isScrollable then
                        local maxScroll = math.max(0, ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y)
                        local currentScroll = ScrollFrame.CanvasPosition.Y
                        ScrollUp.Visible = currentScroll > 2
                        ScrollDown.Visible = currentScroll < (maxScroll - 2)
                        TopGlow.Visible = currentScroll > 2
                        BottomGlow.Visible = currentScroll < (maxScroll - 2)
                    else
                        ScrollUp.Visible = false
                        ScrollDown.Visible = false
                        TopGlow.Visible = false
                        BottomGlow.Visible = false
                    end
                end

                ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateScrollUI)
                ScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateScrollUI)
                ScrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateScrollUI)

                ScrollUp.MouseButton1Click:Connect(function()
                    local newPos = ScrollFrame.CanvasPosition.Y - 40
                    TweenService:Create(ScrollFrame, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.max(0, newPos))}):Play()
                end)

                ScrollDown.MouseButton1Click:Connect(function()
                    local maxScroll = ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y
                    local newPos = ScrollFrame.CanvasPosition.Y + 40
                    TweenService:Create(ScrollFrame, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.min(maxScroll, newPos))}):Play()
                end)

                local Sector = {
                    Main = SectorOuter,
                    Content = ScrollFrame
                }
                table.insert(SideObject.Sectors, Sector)
                UpdateSectorSizes()

                local SectorMethods = {}

            local function CreateColorpickerAddon(parentContainer, scrollFrameObj, options, currentOffset)
                options = typeof(options) == "table" and options or {}
                local defaultColor = options.Default or Color3.fromRGB(255, 255, 255)
                local defaultAlpha = options.DefaultAlpha
                if defaultAlpha == nil then defaultAlpha = 0 end
                defaultAlpha = math.clamp(defaultAlpha, 0, 1)
                local flag = options.Flag or ("Colorpicker_" .. tostring(math.random(100000)))
                local callback = options.Callback or function() end
                local pickerTitle = tostring(options.Title or options.Tittle or "Color Picker")

                local cpObj = {
                    Color = defaultColor,
                    Alpha = defaultAlpha,
                    Transparency = defaultAlpha,
                    Opacity = 1 - defaultAlpha,
                    Callbacks = {}
                }
                
                function cpObj:OnChanged(cb)
                    table.insert(self.Callbacks, cb)
                end
                
                local function FireCallbacks(...)
                    for _, cb in ipairs(cpObj.Callbacks) do
                        task.spawn(cb, ...)
                    end
                end

                local h, s, v = defaultColor:ToHSV()
                local a = 1 - defaultAlpha
                local colorMode = "HEX" 

                local rightGap = 6
                local btnWidth = 18
                local btnHeight = 8

                local ColorBtnBg = Library:Create("Frame", {
                    Name = "ColorBtnBg",
                    Parent = parentContainer,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Size = UDim2.new(0, btnWidth, 0, btnHeight),
                    Position = UDim2.new(1, -rightGap - currentOffset, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 7
                })

                Library:Create("UIStroke", {
                    Parent = ColorBtnBg,
                    Color = Color3.fromRGB(12, 12, 12),
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Library:Create("Frame", {
                    Parent = ColorBtnBg, Size = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, ZIndex = 8
                })
                Library:Create("Frame", {
                    Parent = ColorBtnBg, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150), BorderSizePixel = 0, ZIndex = 8
                })

                local ColorBtnDisplay = Library:Create("TextButton", {
                    Name = "Display",
                    Parent = ColorBtnBg,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = defaultAlpha,
                    AutoButtonColor = false,
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 9
                })
                
                local ColorBtnGradient = Library:Create("UIGradient", {
                    Parent = ColorBtnDisplay,
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, defaultColor),
                        ColorSequenceKeypoint.new(1, Library:GetDarkerColor(defaultColor, 0.3))
                    })
                })

                local PickerFrame = Library:Create("Frame", {
                    Name = "PickerFrame",
                    Parent = ScreenGui,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                    Size = UDim2.new(0, 185, 0, 188),
                    Visible = false,
                    ZIndex = 150
                })

                Library:Create("UIStroke", {
                    Parent = PickerFrame,
                    Color = Color3.fromRGB(12, 12, 12),
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Library:Create("TextLabel", {
                    Name = "Title",
                    Parent = PickerFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 6),
                    Size = UDim2.new(1, -20, 0, 14),
                    Font = Enum.Font.Code,
                    Text = pickerTitle,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 151
                })

                local SVMap = Library:Create("TextButton", {
                    Name = "SVMap", Parent = PickerFrame,
                    Position = UDim2.new(0, 10, 0, 28), Size = UDim2.new(0, 145, 0, 100),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    AutoButtonColor = false, Text = "", ZIndex = 151
                })
                local SatGrad = Library:Create("Frame", {
                    Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 152
                })
                Library:Create("UIGradient", {
                    Parent = SatGrad, Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}
                })
                local ValGrad = Library:Create("Frame", {
                    Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 153
                })
                Library:Create("UIGradient", {
                    Parent = ValGrad, Rotation = 90, Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}
                })
                local SVCursor = Library:Create("Frame", {
                    Parent = SVMap, Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(s, -2, 1 - v, -2),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 155
                })

                local HueSlider = Library:Create("TextButton", {
                    Name = "HueSlider", Parent = PickerFrame,
                    Position = UDim2.new(0, 165, 0, 28), Size = UDim2.new(0, 10, 0, 100),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255), AutoButtonColor = false, Text = "", ZIndex = 151
                })
                Library:Create("UIGradient", {
                    Parent = HueSlider, Rotation = 90,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    }
                })
                local HueCursor = Library:Create("Frame", {
                    Parent = HueSlider, Size = UDim2.new(1, 2, 0, 2), Position = UDim2.new(0, -1, h, -1),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 155
                })

                local AlphaSlider = Library:Create("TextButton", {
                    Name = "AlphaSlider", Parent = PickerFrame,
                    Position = UDim2.new(0, 10, 0, 138), Size = UDim2.new(0, 165, 0, 15),
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150), AutoButtonColor = false, Text = "", ZIndex = 151, ClipsDescendants = false
                })

                for y = 0, 2 do
                    for x = 0, 32 do
                        if (x + y) % 2 == 0 then
                            Library:Create("Frame", {
                                Parent = AlphaSlider, Position = UDim2.new(0, x * 5, 0, y * 5),
                                Size = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                BorderSizePixel = 0, ZIndex = 152
                            })
                        end
                    end
                end

                local AlphaColorOverlay = Library:Create("Frame", {
                    Parent = AlphaSlider, Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = defaultColor, ZIndex = 153
                })
                Library:Create("UIGradient", {
                    Parent = AlphaColorOverlay,
                    Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}
                })

                local AlphaCursor = Library:Create("Frame", {
                    Parent = AlphaSlider, Size = UDim2.new(0, 4, 1, 4), Position = UDim2.new(a, -2, 0, -2),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 155
                })

                local ModeBtnBg = Library:Create("Frame", {
                    Parent = PickerFrame, BackgroundColor3 = Color3.fromRGB(46, 46, 55),
                    Position = UDim2.new(0, 10, 0, 163), Size = UDim2.new(0, 35, 0, 15),
                    BorderSizePixel = 0, ZIndex = 151
                })
                Library:Create("UIStroke", { Parent = ModeBtnBg, Color = Color3.fromRGB(12, 12, 12), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
                local ModeBtn = Library:Create("TextButton", {
                    Parent = ModeBtnBg, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Code, Text = colorMode, TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 10, ZIndex = 152
                })

                local ValBg = Library:Create("Frame", {
                    Parent = PickerFrame, BackgroundColor3 = Color3.fromRGB(46, 46, 55),
                    Position = UDim2.new(0, 50, 0, 163), Size = UDim2.new(0, 125, 0, 15),
                    BorderSizePixel = 0, ZIndex = 151
                })
                Library:Create("UIStroke", { Parent = ValBg, Color = Color3.fromRGB(12, 12, 12), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
                local ValBox = Library:Create("TextBox", {
                    Parent = ValBg, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Code, Text = "", TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 10, ClearTextOnFocus = false, ZIndex = 152
                })

                local ColorCtxMenu = Library:Create("Frame", {
                    Name = "ColorCtxMenu",
                    Parent = ScreenGui,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                    Size = UDim2.new(0, 84, 0, 54),
                    Visible = false,
                    ZIndex = 150
                })

                Library:Create("UIStroke", {
                    Parent = ColorCtxMenu,
                    Color = Color3.fromRGB(12, 12, 12),
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Library:Create("UIListLayout", {
                    Parent = ColorCtxMenu,
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                local function UpdateTextBox()
                    if colorMode == "HEX" then
                        ValBox.Text = string.format("#%02X%02X%02X", cpObj.Color.R * 255, cpObj.Color.G * 255, cpObj.Color.B * 255)
                    else
                        ValBox.Text = string.format("%d, %d, %d", cpObj.Color.R * 255, cpObj.Color.G * 255, cpObj.Color.B * 255)
                    end
                end

                ModeBtn.MouseButton1Click:Connect(function()
                    colorMode = colorMode == "HEX" and "RGB" or "HEX"
                    ModeBtn.Text = colorMode
                    UpdateTextBox()
                end)

                local function UpdateColor()
                    cpObj.Color = Color3.fromHSV(h, s, v)
                    cpObj.Alpha = 1 - a
                    cpObj.Transparency = cpObj.Alpha
                    cpObj.Opacity = a
                    Library.Flags[flag] = cpObj
                    
                    ColorBtnGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, cpObj.Color),
                        ColorSequenceKeypoint.new(1, Library:GetDarkerColor(cpObj.Color, 0.3))
                    })
                    ColorBtnDisplay.BackgroundTransparency = cpObj.Alpha
                    
                    SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    AlphaColorOverlay.BackgroundColor3 = cpObj.Color
                    
                    SVCursor.Position = UDim2.new(s, -2, 1 - v, -2)
                    HueCursor.Position = UDim2.new(0, -1, h, -1)
                    AlphaCursor.Position = UDim2.new(a, -2, 0, -2)
                    
                    UpdateTextBox()
                    callback(cpObj.Color, cpObj.Alpha)
                    FireCallbacks(cpObj.Color, cpObj.Alpha)
                end

                ValBox.FocusLost:Connect(function()
                    local txt = ValBox.Text
                    local success = pcall(function()
                        if colorMode == "HEX" then
                            txt = txt:gsub("#", "")
                            if #txt == 6 then
                                local r = tonumber(txt:sub(1,2), 16) / 255
                                local g = tonumber(txt:sub(3,4), 16) / 255
                                local b = tonumber(txt:sub(5,6), 16) / 255
                                h, s, v = Color3.new(r, g, b):ToHSV()
                            end
                        else
                            local r, g, b = txt:match("(%d+)[%D]+(%d+)[%D]+(%d+)")
                            if r and g and b then
                                h, s, v = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)):ToHSV()
                            end
                        end
                    end)
                    UpdateColor()
                end)

                local function HandleInput(btn, typeStr)
                    local isDragging = false
                    btn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            isDragging = true
                            local function update(inp)
                                local pos = inp.Position
                                local absPos = btn.AbsolutePosition
                                local absSize = btn.AbsoluteSize
                                
                                if typeStr == "SV" then
                                    s = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
                                    v = 1 - math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
                                elseif typeStr == "Hue" then
                                    h = math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
                                elseif typeStr == "Alpha" then
                                    a = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
                                end
                                UpdateColor()
                            end
                            update(input)
                            
                            local moveConn, endConn
                            moveConn = UserInputService.InputChanged:Connect(function(inp)
                                if inp.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
                                    update(inp)
                                end
                            end)
                            endConn = UserInputService.InputEnded:Connect(function(inp)
                                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                                    isDragging = false
                                    moveConn:Disconnect()
                                    endConn:Disconnect()
                                end
                            end)
                        end
                    end)
                end

                HandleInput(SVMap, "SV")
                HandleInput(HueSlider, "Hue")
                HandleInput(AlphaSlider, "Alpha")
                UpdateColor()

                local open = false
                local inputConnection = nil
                local menuOpen = false
                local menuInputConnection = nil

                local function closePicker()
                    if open then
                        open = false
                        PickerFrame.Visible = false
                        if inputConnection then
                            inputConnection:Disconnect()
                            inputConnection = nil
                        end
                    end
                end

                local function closeCtxMenu()
                    if menuOpen then
                        menuOpen = false
                        ColorCtxMenu.Visible = false
                        if menuInputConnection then
                            menuInputConnection:Disconnect()
                            menuInputConnection = nil
                        end
                    end
                end

                local function createCtxButton(name, onClick)
                    local btn = Library:Create("TextButton", {
                        Name = name,
                        Parent = ColorCtxMenu,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Font = Enum.Font.Code,
                        Text = " " .. name,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 151
                    })
                    btn.MouseEnter:Connect(function() btn.TextColor3 = Library.Accent end)
                    btn.MouseLeave:Connect(function() btn.TextColor3 = Color3.fromRGB(200, 200, 200) end)
                    btn.MouseButton1Click:Connect(function()
                        closeCtxMenu()
                        onClick()
                    end)
                end

                createCtxButton("Copy", function()
                    Library._ColorClipboard = {
                        Color = cpObj.Color,
                        Alpha = cpObj.Alpha
                    }
                end)

                createCtxButton("Paste", function()
                    local data = Library._ColorClipboard
                    if data and data.Color then
                        cpObj:SetValue({
                            Color = data.Color,
                            Alpha = data.Alpha
                        })
                    end
                end)

                createCtxButton("Reset", function()
                    cpObj:SetValue({
                        Color = defaultColor,
                        Alpha = defaultAlpha
                    })
                end)

                ColorBtnDisplay.MouseButton1Click:Connect(function()
                    closeCtxMenu()
                    if open then
                        closePicker()
                    else
                        open = true
                        local inset = GuiService:GetGuiInset()
                        local offsetY = ScreenGui.IgnoreGuiInset and inset.Y or 0
                        
                        PickerFrame.Position = UDim2.new(0, ColorBtnBg.AbsolutePosition.X, 0, ColorBtnBg.AbsolutePosition.Y + btnHeight + 4 + offsetY)
                        PickerFrame.Visible = true

                        if inputConnection then inputConnection:Disconnect() end
                        inputConnection = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                                local pos = input.Position
                                local pPos = PickerFrame.AbsolutePosition
                                local pSize = PickerFrame.AbsoluteSize
                                local inPicker = pos.X >= pPos.X and pos.X <= pPos.X + pSize.X and pos.Y >= pPos.Y and pos.Y <= pPos.Y + pSize.Y
                                
                                local bPos = ColorBtnBg.AbsolutePosition
                                local bSize = ColorBtnBg.AbsoluteSize
                                local inBtn = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y

                                if not inPicker and not inBtn then
                                    closePicker()
                                end
                            end
                        end)
                    end
                end)

                ColorBtnDisplay.MouseButton2Click:Connect(function()
                    closePicker()
                    if menuOpen then
                        closeCtxMenu()
                    else
                        menuOpen = true
                        local inset = GuiService:GetGuiInset()
                        local offsetY = ScreenGui.IgnoreGuiInset and inset.Y or 0

                        ColorCtxMenu.Position = UDim2.new(0, ColorBtnBg.AbsolutePosition.X, 0, ColorBtnBg.AbsolutePosition.Y + btnHeight + 4 + offsetY)
                        ColorCtxMenu.Visible = true

                        if menuInputConnection then menuInputConnection:Disconnect() end
                        task.wait()
                        menuInputConnection = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                                local pos = input.Position
                                local cPos = ColorCtxMenu.AbsolutePosition
                                local cSize = ColorCtxMenu.AbsoluteSize
                                local inMenu = pos.X >= cPos.X and pos.X <= cPos.X + cSize.X and pos.Y >= cPos.Y and pos.Y <= cPos.Y + cSize.Y

                                local bPos = ColorBtnBg.AbsolutePosition
                                local bSize = ColorBtnBg.AbsoluteSize
                                local inBtn = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y

                                if not inMenu and not inBtn then
                                    closeCtxMenu()
                                end
                            end
                        end)
                    end
                end)

                if scrollFrameObj and typeof(scrollFrameObj) == "Instance" and scrollFrameObj:IsA("ScrollingFrame") then
                    scrollFrameObj:GetPropertyChangedSignal("CanvasPosition"):Connect(closePicker)
                    scrollFrameObj:GetPropertyChangedSignal("CanvasPosition"):Connect(closeCtxMenu)
                end
                MainFrame:GetPropertyChangedSignal("Position"):Connect(closePicker)
                MainFrame:GetPropertyChangedSignal("Position"):Connect(closeCtxMenu)

                function cpObj:SetValue(newValues)
                    if type(newValues) == "table" then
                        if newValues.Color ~= nil then cpObj.Color = newValues.Color end
                        if newValues.value ~= nil then cpObj.Color = newValues.value end
                        if newValues.Alpha ~= nil then cpObj.Alpha = newValues.Alpha end
                        if newValues.Transparency ~= nil then cpObj.Alpha = newValues.Transparency end
                        if newValues.Opacity ~= nil then cpObj.Alpha = 1 - newValues.Opacity end
                    elseif typeof(newValues) == "Color3" then
                        cpObj.Color = newValues
                    end

                    cpObj.Alpha = math.clamp(cpObj.Alpha or 0, 0, 1)
                    cpObj.Transparency = cpObj.Alpha
                    cpObj.Opacity = 1 - cpObj.Alpha
                    h, s, v = cpObj.Color:ToHSV()
                    a = cpObj.Opacity
                    UpdateColor()
                end
                cpObj.Set = cpObj.SetValue

                Library.Flags[flag] = cpObj
                return cpObj
            end

            local function CreateKeybindAddon(parentContainer, scrollFrameObj, options, currentOffset)
                options = typeof(options) == "table" and options or {}
                local defaultKey = options.Default or "None"
                local defaultMode = options.Mode or "Toggle"
                local flag = options.Flag or ("Keybind_" .. tostring(math.random(100000)))
                local canChangeMode = options.CanChangeMode
                if canChangeMode == nil then canChangeMode = true end
                local showInList = options.ShowInList
                if showInList == nil then showInList = options.ShowBind end
                if showInList == nil then showInList = true end
                local listName = options.ListName or options.Title or options.Tittle
                local callback = options.Callback or function() end

                local function onKeybindChanged(...)
                    callback(...)
                    Library:UpdateKeybindList()
                end

                local function formatKey(keyStr)
                    local k = tostring(keyStr):lower()
                    if k == "mousebutton1" or k == "mouse1" then return "MB1" end
                    if k == "mousebutton2" or k == "mouse2" then return "MB2" end
                    if k == "mousebutton3" or k == "mouse3" then return "MB3" end
                    if k == "backspace" then return "BCK" end
                    if k == "delete" then return "DEL" end
                    if k == "insert" then return "INS" end
                    if k == "leftcontrol" or k == "lcontrol" then return "LCtrl" end
                    if k == "rightcontrol" or k == "rcontrol" then return "RCtrl" end
                    if k == "leftalt" or k == "lalt" then return "LAlt" end
                    if k == "rightalt" or k == "ralt" then return "RAlt" end
                    if k == "leftshift" or k == "lshift" then return "LShift" end
                    if k == "rightshift" or k == "rshift" then return "RShift" end
                    if k == "unknown" or k == "none" then return "None" end
                    return string.upper(keyStr)
                end

                local kbObj = {
                    Key = defaultKey,
                    Mode = defaultMode,
                    State = false,
                    Callbacks = {}
                }
                
                function kbObj:OnChanged(cb)
                    table.insert(self.Callbacks, cb)
                end
                
                local function FireCallbacks(...)
                    for _, cb in ipairs(kbObj.Callbacks) do
                        task.spawn(cb, ...)
                    end
                end

                local rightGap = 6
                local btnWidth = 25
                local btnHeight = 8

                local KeybindBtn = Library:Create("TextButton", {
                    Name = "KeybindBtn",
                    Parent = parentContainer,
                    BackgroundColor3 = Color3.fromRGB(27, 27, 34),
                    Size = UDim2.new(0, btnWidth, 0, btnHeight),
                    Position = UDim2.new(1, -rightGap - currentOffset, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Text = formatKey(defaultKey),
                    Font = Enum.Font.Code,
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 8,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 7
                    })

                Library:Create("UIStroke", {
                    Parent = KeybindBtn,
                    Color = Color3.fromRGB(12, 12, 12),
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                local CtxMenu = Library:Create("Frame", {
                    Name = "KeybindCtxMenu",
                    Parent = ScreenGui,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                    Size = UDim2.new(0, 60, 0, 54),
                    Visible = false,
                    ZIndex = 150
                })
                
                Library:Create("UIStroke", {
                    Parent = CtxMenu,
                    Color = Color3.fromRGB(12, 12, 12),
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                local Layout = Library:Create("UIListLayout", {
                    Parent = CtxMenu,
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                local modes = {"Hold", "Toggle", "Always"}
                local modeBtns = {}

                for _, mode in ipairs(modes) do
                    local btn = Library:Create("TextButton", {
                        Parent = CtxMenu,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Font = Enum.Font.Code,
                        Text = " " .. mode,
                        TextColor3 = (mode == kbObj.Mode) and Library.Accent or Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 151
                    })
                    
                    btn.MouseEnter:Connect(function() btn.TextColor3 = Library.Accent end)
                    btn.MouseLeave:Connect(function() btn.TextColor3 = (mode == kbObj.Mode) and Library.Accent or Color3.fromRGB(200, 200, 200) end)
                    
                    btn.MouseButton1Click:Connect(function()
                        kbObj.Mode = mode
                        CtxMenu.Visible = false
                        Library.Flags[flag] = kbObj
                        for _, mb in ipairs(modeBtns) do
                            mb.TextColor3 = (mb.Name == mode) and Library.Accent or Color3.fromRGB(200, 200, 200)
                        end
                        if mode == "Always" then
                            kbObj.State = true
                            onKeybindChanged(kbObj.State)
                            FireCallbacks(kbObj.State)
                        else
                            kbObj.State = false
                            onKeybindChanged(kbObj.State)
                            FireCallbacks(kbObj.State)
                        end
                        Library:UpdateKeybindList()
                    end)
                    btn.Name = mode
                    table.insert(modeBtns, btn)
                end

                local binding = false
                local open = false
                local inputConnection = nil

                local function closeMenu()
                    if open then
                        open = false
                        CtxMenu.Visible = false
                        if inputConnection then
                            inputConnection:Disconnect()
                            inputConnection = nil
                        end
                    end
                end

                KeybindBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if not binding then
                            KeybindBtn.Text = "..."
                            binding = true
                            task.wait() 
                        end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        if not canChangeMode then return end
                        if open then
                            closeMenu()
                        else
                            open = true
                            local inset = GuiService:GetGuiInset()
                            local offsetY = ScreenGui.IgnoreGuiInset and inset.Y or 0
                            
                            CtxMenu.Position = UDim2.new(0, KeybindBtn.AbsolutePosition.X, 0, KeybindBtn.AbsolutePosition.Y + btnHeight + 4 + offsetY)
                            CtxMenu.Visible = true

                            if inputConnection then inputConnection:Disconnect() end
                            task.wait()
                            inputConnection = UserInputService.InputBegan:Connect(function(inp)
                                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
                                    local pos = inp.Position
                                    local cPos = CtxMenu.AbsolutePosition
                                    local cSize = CtxMenu.AbsoluteSize
                                    if not (pos.X >= cPos.X and pos.X <= cPos.X + cSize.X and pos.Y >= cPos.Y and pos.Y <= cPos.Y + cSize.Y) then
                                        closeMenu()
                                    end
                                end
                            end)
                        end
                    end
                end)

                Library:Connect(UserInputService.InputBegan, function(input)
                    if binding then
                        local key = "None"
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            key = input.UserInputType.Name
                        end
                        
                        if key ~= "None" then
                            if key == "Backspace" then
                                key = "None"
                            end
                            kbObj.Key = key
                            KeybindBtn.Text = formatKey(key)
                            binding = false
                            Library.Flags[flag] = kbObj
                            Library:UpdateKeybindList()
                        end
                    elseif not binding then
                        local keyStr = ""
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            keyStr = input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            keyStr = input.UserInputType.Name
                        end

                        if keyStr == kbObj.Key then
                            if kbObj.Mode == "Toggle" then
                                kbObj.State = not kbObj.State
                                onKeybindChanged(kbObj.State)
                                FireCallbacks(kbObj.State)
                            elseif kbObj.Mode == "Hold" then
                                kbObj.State = true
                                onKeybindChanged(kbObj.State)
                                FireCallbacks(kbObj.State)
                            end
                        end
                    end
                end)

                Library:Connect(UserInputService.InputEnded, function(input)
                    if not binding and kbObj.Mode == "Hold" then
                        local keyStr = ""
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            keyStr = input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            keyStr = input.UserInputType.Name
                        end

                        if keyStr == kbObj.Key then
                            kbObj.State = false
                            onKeybindChanged(kbObj.State)
                            FireCallbacks(kbObj.State)
                        end
                    end
                end)

                if scrollFrameObj and typeof(scrollFrameObj) == "Instance" and scrollFrameObj:IsA("ScrollingFrame") then
                    scrollFrameObj:GetPropertyChangedSignal("CanvasPosition"):Connect(closeMenu)
                end
                MainFrame:GetPropertyChangedSignal("Position"):Connect(closeMenu)

                function kbObj:SetValue(newVal)
                    if type(newVal) == "table" then
                        if newVal.Key then kbObj.Key = newVal.Key end
                        if newVal.Mode then kbObj.Mode = newVal.Mode end
                    elseif type(newVal) == "string" then
                        kbObj.Key = newVal
                    end
                    KeybindBtn.Text = formatKey(kbObj.Key)
                    Library.Flags[flag] = kbObj
                    for _, mb in ipairs(modeBtns) do
                        mb.TextColor3 = (mb.Name == kbObj.Mode) and Library.Accent or Color3.fromRGB(200, 200, 200)
                    end
                    if kbObj.Mode == "Always" then
                        kbObj.State = true
                    else
                        kbObj.State = false
                    end
                    onKeybindChanged(kbObj.State)
                    FireCallbacks(kbObj.State)
                    Library:UpdateKeybindList()
                end
                kbObj.Set = kbObj.SetValue

                Library.Flags[flag] = kbObj
                if showInList and listName then
                    Library:RegisterKeybindList(listName, kbObj)
                end
                if kbObj.Mode == "Always" then
                    kbObj.State = true
                    onKeybindChanged(kbObj.State)
                    FireCallbacks(kbObj.State)
                end
                return kbObj
            end


                function SectorMethods:AddLabel(options)
                    local text, flag
                    if type(options) == "table" then
                        text = options.Text or "Label"
                        flag = options.Flag
                    else
                        text = tostring(options)
                    end

                    local LabelObj = { AddonOffset = 0, Callbacks = {} }
                    
                    function LabelObj:OnChanged(cb)
                        table.insert(self.Callbacks, cb)
                    end
                    
                    local function FireCallbacks(...)
                        for _, cb in ipairs(LabelObj.Callbacks) do
                            task.spawn(cb, ...)
                        end
                    end

                    local LabelContainer = Library:Create("Frame", {
                        Name = "LabelContainer",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        ZIndex = 6
                    })

                    LabelObj.Main = LabelContainer
                    function LabelObj:SetVisible(state)
                        if self.Main then self.Main.Visible = state end
                    end

                    local Label = Library:Create("TextLabel", {
                        Parent = LabelContainer,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 218, 1, 0),
                        Position = UDim2.new(0, 24, 0, 0),
                        Font = Enum.Font.Code,
                        Text = text,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7
                    })
                    
                    function LabelObj:SetValue(newText)
                        if type(newText) == "table" and newText.value ~= nil then
                            newText = newText.value
                        end
                        Label.Text = tostring(newText)
                        FireCallbacks(tostring(newText))
                    end
                    LabelObj.Set = LabelObj.SetValue

                    function LabelObj:SetText(newText)
                        if type(newText) == "table" and newText.value ~= nil then
                            newText = newText.value
                        end
                        Label.Text = tostring(newText)
                        FireCallbacks(tostring(newText))
                    end

                    function LabelObj:AddColorpicker(cpOptions)
                        cpOptions = cpOptions or {}
                        if not cpOptions.Title and not cpOptions.Tittle then
                            cpOptions.Tittle = text
                        end
                        local cp = CreateColorpickerAddon(LabelContainer, ScrollFrame, cpOptions, self.AddonOffset)
                        self.AddonOffset = self.AddonOffset + 18 + 4
                        return self
                    end

                    function LabelObj:AddKeybind(kbOptions)
                        kbOptions = kbOptions or {}
                        if not kbOptions.ListName then
                            kbOptions.ListName = kbOptions.Title or kbOptions.Tittle or text
                        end
                        local kb = CreateKeybindAddon(LabelContainer, ScrollFrame, kbOptions, self.AddonOffset)
                        self.AddonOffset = self.AddonOffset + 25 + 4
                        return self
                    end

                    if flag then
                        Library.Flags[flag] = LabelObj
                    end
                    
                    return LabelObj
                end

                function SectorMethods:AddToggle(options)
                    options = typeof(options) == "table" and options or { Text = options }
                    local text = options.Text or "Toggle"
                    local default = options.Default or false
                    local flag = options.Flag or text
                    local callback = options.Callback or function() end

                    local ToggleObj = {
                        Value = default,
                        AddonOffset = 0,
                        Callbacks = {},
                        _isVisible = true,
                        _visibilityLinks = {}
                    }

                    function ToggleObj:OnChanged(cb)
                        table.insert(self.Callbacks, cb)
                    end
                    
                    local function FireCallbacks(...)
                        for _, cb in ipairs(ToggleObj.Callbacks) do
                            task.spawn(cb, ...)
                        end
                    end

                    local ToggleContainer = Library:Create("TextButton", {
                        Name = text .. "Toggle",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 6
                    })

                    ToggleObj.Main = ToggleContainer
                    function ToggleObj:SetVisible(state)
                        self.Main.Visible = state
                        self._isVisible = state
                        if self._updateConnectedVisibility then
                            self:_updateConnectedVisibility()
                        end
                    end

                    function ToggleObj:Connect(widgets, value)
                        if value == nil then value = true end
                        local targetWidgets = (type(widgets) == "table" and not widgets.Main) and widgets or {widgets}
                        table.insert(self._visibilityLinks, {
                            Widgets = targetWidgets,
                            Value = value
                        })
                        if self._updateConnectedVisibility then
                            self:_updateConnectedVisibility()
                        end
                    end

                    function ToggleObj:_updateConnectedVisibility()
                        for _, link in ipairs(self._visibilityLinks) do
                            local shouldShow = self._isVisible and (self.Value == link.Value)
                            for _, w in ipairs(link.Widgets) do
                                if w.SetVisible then
                                    w:SetVisible(shouldShow)
                                end
                            end
                        end
                    end

                    local ToggleBox = Library:Create("Frame", {
                        Name = "ToggleBox",
                        Parent = ToggleContainer,
                        BackgroundColor3 = Color3.fromRGB(46, 46, 55),
                        Size = UDim2.new(0, 6, 0, 6),
                        Position = UDim2.new(0, 6, 0.5, -3),
                        BorderSizePixel = 0,
                        ZIndex = 7
                    })

                    Library:Create("UIStroke", {
                        Name = "BoxStroke",
                        Parent = ToggleBox,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local ToggleFill = Library:Create("Frame", {
                        Name = "ToggleFill",
                        Parent = ToggleBox,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        Visible = ToggleObj.Value,
                        ZIndex = 8
                    })

                    Library:Create("UIGradient", {
                        Name = "FillGradient",
                        Parent = ToggleFill,
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Library.Accent), 
                            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.15)) 
                        })
                    })

                    local ToggleLabel = Library:Create("TextLabel", {
                        Name = "ToggleLabel",
                        Parent = ToggleContainer,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 218, 1, 0),
                        Position = UDim2.new(0, 24, 0, 0),
                        Font = Enum.Font.Code,
                        Text = text,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7
                    })

                    local function SetState(newState)
                        ToggleObj.Value = newState
                        ToggleFill.Visible = ToggleObj.Value
                        ToggleObj:_updateConnectedVisibility()
                        callback(ToggleObj.Value)
                        FireCallbacks(ToggleObj.Value)
                    end

                    ToggleContainer.MouseButton1Click:Connect(function()
                        SetState(not ToggleObj.Value)
                    end)

                    function ToggleObj:SetValue(newState)
                        if type(newState) == "table" and newState.value ~= nil then
                            newState = newState.value
                        end
                        SetState(newState)
                    end
                    ToggleObj.Set = ToggleObj.SetValue

                    function ToggleObj:AddToggle(opt)
                        local widget = SectorMethods:AddToggle(opt)
                        self:Connect(widget)
                        return widget
                    end
                    function ToggleObj:AddSlider(opt)
                        local widget = SectorMethods:AddSlider(opt)
                        self:Connect(widget)
                        return widget
                    end
                    function ToggleObj:AddDropdown(opt)
                        local widget = SectorMethods:AddDropdown(opt)
                        self:Connect(widget)
                        return widget
                    end
                    function ToggleObj:AddList(opt)
                        local widget = SectorMethods:AddList(opt)
                        self:Connect(widget)
                        return widget
                    end
                    function ToggleObj:AddTextbox(opt)
                        local widget = SectorMethods:AddTextbox(opt)
                        self:Connect(widget)
                        return widget
                    end
                    function ToggleObj:AddButton(opt)
                        local widget = SectorMethods:AddButton(opt)
                        self:Connect(widget)
                        return widget
                    end
                    function ToggleObj:AddLabel(opt)
                        local widget = SectorMethods:AddLabel(opt)
                        self:Connect(widget)
                        return widget
                    end

                    function ToggleObj:AddColorpicker(cpOptions)
                        cpOptions = cpOptions or {}
                        if not cpOptions.Title and not cpOptions.Tittle then
                            cpOptions.Tittle = text
                        end
                        local cp = CreateColorpickerAddon(ToggleContainer, ScrollFrame, cpOptions, self.AddonOffset)
                        self.AddonOffset = self.AddonOffset + 18 + 4
                        return self
                    end

                    function ToggleObj:AddKeybind(kbOptions)
                        kbOptions = kbOptions or {}
                        if not kbOptions.ListName then
                            kbOptions.ListName = kbOptions.Title or kbOptions.Tittle or text
                        end
                        local kb = CreateKeybindAddon(ToggleContainer, ScrollFrame, kbOptions, self.AddonOffset)
                        self.AddonOffset = self.AddonOffset + 25 + 4
                        return self
                    end

                    Library.Flags[flag] = ToggleObj
                    return ToggleObj
                end

                function SectorMethods:AddSlider(options)
                    options = typeof(options) == "table" and options or { Text = options }
                    local text = options.Text or "Slider"
                    local min = options.Min or 0
                    local max = options.Max or 100
                    local step = options.Step or 1
                    if type(step) ~= "number" or step <= 0 then
                        step = 1
                    end
                    local default = options.Default or min
                    local flag = options.Flag or text
                    local callback = options.Callback or function() end
                    local stepDecimals = 0
                    do
                        local stepStr = tostring(step)
                        local dec = stepStr:match("%.(%d+)")
                        if dec then
                            stepDecimals = #dec
                        end
                    end

                    local SliderObj = {
                        Value = default,
                        Callbacks = {}
                    }

                    function SliderObj:OnChanged(cb)
                        table.insert(self.Callbacks, cb)
                    end
                    
                    local function FireCallbacks(...)
                        for _, cb in ipairs(SliderObj.Callbacks) do
                            task.spawn(cb, ...)
                        end
                    end

                    local SliderContainer = Library:Create("Frame", {
                        Name = text .. "Slider",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 32),
                        ZIndex = 6
                    })

                    SliderObj.Main = SliderContainer
                    function SliderObj:SetVisible(state)
                        self.Main.Visible = state
                    end

                    local SliderLabel = Library:Create("TextLabel", {
                        Name = "Label",
                        Parent = SliderContainer,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 218, 0, 14),
                        Position = UDim2.new(0, 24, 0, 0),
                        Font = Enum.Font.Code,
                        Text = text,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7
                    })

                    local SliderBg = Library:Create("Frame", {
                        Name = "Background",
                        Parent = SliderContainer,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 170, 0, 6),
                        Position = UDim2.new(0, 24, 1, -8),
                        AnchorPoint = Vector2.new(0, 1),
                        BorderSizePixel = 0,
                        ZIndex = 7
                    })

                    Library:Create("UIGradient", {
                        Name = "BgGradient",
                        Parent = SliderBg,
                        Rotation = -90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 53, 62)),
                            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Color3.fromRGB(55, 53, 62), 0.1))
                        })
                    })

                    Library:Create("UIStroke", {
                        Name = "BgStroke",
                        Parent = SliderBg,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local SliderFill = Library:Create("Frame", {
                        Name = "Fill",
                        Parent = SliderBg,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 0, 1, 0),
                        BorderSizePixel = 0,
                        ZIndex = 8
                    })

                    Library:Create("UIGradient", {
                        Name = "FillGradient",
                        Parent = SliderFill,
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Library.Accent), 
                            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Library.Accent, 0.15)) 
                        })
                    })

                    local ValueBox = Library:Create("TextBox", {
                        Name = "Value",
                        Parent = SliderBg,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 30, 0, 14),
                        Position = UDim2.new(0, 0, 0.5, 3),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Font = Enum.Font.GothamBold,
                        Text = tostring(SliderObj.Value),
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 9,
                        ClearTextOnFocus = false
                    })

                    Library:Create("UIStroke", {
                        Name = "TextStroke",
                        Parent = ValueBox,
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 1,
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                    })
                    
                    local Hitbox = Library:Create("TextButton", {
                        Name = "Hitbox",
                        Parent = SliderBg,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 10),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Text = "",
                        ZIndex = 10
                    })

                    local dragging = false

                    local function snapValue(raw)
                        local clamped = math.clamp(raw, min, max)
                        local snapped = min + (math.floor(((clamped - min) / step) + 0.5) * step)
                        return math.clamp(snapped, min, max)
                    end

                    local function formatValue(v)
                        if stepDecimals > 0 then
                            local rounded = tonumber(string.format("%." .. stepDecimals .. "f", v)) or v
                            if math.abs(rounded - math.floor(rounded + 0.5)) < 1e-9 then
                                return tostring(math.floor(rounded + 0.5))
                            end
                            return tostring(rounded)
                        end
                        return tostring(v)
                    end

                    local function UpdateSlider(input)
                        local sizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                        local value = snapValue(min + ((max - min) * sizeX))
                        sizeX = (value - min) / (max - min)
                        
                        SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                        ValueBox.Position = UDim2.new(sizeX, 0, 0.5, 3)
                        ValueBox.Text = formatValue(value)
                        
                        SliderObj.Value = value
                        callback(value)
                        FireCallbacks(value)
                    end

                    Hitbox.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            UpdateSlider(input)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            ValueBox:CaptureFocus()
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)

                    Library:Connect(UserInputService.InputChanged, function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            UpdateSlider(input)
                        end
                    end)

                    ValueBox.FocusLost:Connect(function()
                        local num = tonumber(ValueBox.Text)
                        if num then
                            local val = snapValue(num)
                            local pct = (val - min) / (max - min)
                            SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                            ValueBox.Position = UDim2.new(pct, 0, 0.5, 3)
                            ValueBox.Text = formatValue(val)
                            SliderObj.Value = val
                            callback(val)
                            FireCallbacks(val)
                        else
                            ValueBox.Text = formatValue(SliderObj.Value)
                        end
                    end)

                    function SliderObj:SetValue(value)
                        if type(value) == "table" and value.value ~= nil then
                            value = value.value
                        end
                        local val = snapValue(value)
                        local pct = (val - min) / (max - min)
                        SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                        ValueBox.Position = UDim2.new(pct, 0, 0.5, 3)
                        ValueBox.Text = formatValue(val)
                        SliderObj.Value = val
                        callback(val)
                        FireCallbacks(val)
                    end
                    SliderObj.Set = SliderObj.SetValue

                    SliderObj.Value = snapValue(SliderObj.Value)
                    local startPct = math.clamp((SliderObj.Value - min) / (max - min), 0, 1)
                    SliderFill.Size = UDim2.new(startPct, 0, 1, 0)
                    ValueBox.Position = UDim2.new(startPct, 0, 0.5, 3)
                    ValueBox.Text = formatValue(SliderObj.Value)

                    Library.Flags[flag] = SliderObj
                    return SliderObj
                end

                function SectorMethods:AddDropdown(options)
                    options = typeof(options) == "table" and options or { Text = options }
                    local text = options.Text or "Dropdown"
                    local list = options.List or {}
                    local multi = options.Multi or false
                    local default = options.Default or (multi and {} or list[1] or "")
                    local flag = options.Flag or text
                    local callback = options.Callback or function() end

                    local DropdownObj = {
                        Value = default,
                        Callbacks = {},
                        _isVisible = true,
                        _visibilityLinks = {}
                    }
                    
                    function DropdownObj:OnChanged(cb)
                        table.insert(self.Callbacks, cb)
                    end
                    
                    local function FireCallbacks(...)
                        for _, cb in ipairs(DropdownObj.Callbacks) do
                            task.spawn(cb, ...)
                        end
                    end

                    local totalHeight = 0

                    local function getSelectedText()
                        if multi then
                            local selected = DropdownObj.Value
                            if type(selected) == "table" and #selected > 0 then
                                return table.concat(selected, ", ")
                            end
                            return "None"
                        else
                            return tostring(DropdownObj.Value)
                        end
                    end

                    local DropdownContainer = Library:Create("Frame", {
                        Name = text .. "Dropdown",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 38), 
                        ZIndex = 6
                    })

                    DropdownObj.Main = DropdownContainer
                    function DropdownObj:SetVisible(state)
                        if self.Main then
                            self.Main.Visible = state
                        end
                        self._isVisible = state
                        if self._updateConnectedVisibility then
                            self:_updateConnectedVisibility()
                        end
                    end

                    function DropdownObj:Connect(widgets, value)
                        if multi then return end
                        if value == nil then return end
                        local targetWidgets = (type(widgets) == "table" and not widgets.Main) and widgets or {widgets}
                        table.insert(self._visibilityLinks, {
                            Widgets = targetWidgets,
                            Value = value
                        })
                        if self._updateConnectedVisibility then
                            self:_updateConnectedVisibility()
                        end
                    end

                    function DropdownObj:_updateConnectedVisibility()
                        if multi then return end
                        for _, link in ipairs(self._visibilityLinks) do
                            local shouldShow = self._isVisible and (self.Value == link.Value)
                            for _, w in ipairs(link.Widgets) do
                                if w.SetVisible then
                                    w:SetVisible(shouldShow)
                                end
                            end
                        end
                    end

                    local DropdownLabel = Library:Create("TextLabel", {
                        Name = "Label",
                        Parent = DropdownContainer,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 218, 0, 14),
                        Position = UDim2.new(0, 24, 0, 0),
                        Font = Enum.Font.Code,
                        Text = text,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11, 
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7
                    })

                    local DropdownBg = Library:Create("TextButton", {
                        Name = "Background",
                        Parent = DropdownContainer,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 170, 0, 20),
                        Position = UDim2.new(0, 24, 0, 16),
                        AutoButtonColor = false,
                        Text = "",
                        BorderSizePixel = 0,
                        ZIndex = 7
                    })

                    Library:Create("UIGradient", {
                        Name = "BgGradient",
                        Parent = DropdownBg,
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 53, 62)),
                            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Color3.fromRGB(55, 53, 62), 0.1))
                        })
                    })

                    Library:Create("UIStroke", {
                        Name = "BgStroke",
                        Parent = DropdownBg,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local TextClipFrame = Library:Create("Frame", {
                        Name = "TextClipFrame",
                        Parent = DropdownBg,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -24, 1, 0),
                        Position = UDim2.new(0, 6, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 8
                    })

                    local SelectedText = Library:Create("TextLabel", {
                        Name = "SelectedText",
                        Parent = TextClipFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Font = Enum.Font.Code,
                        Text = getSelectedText(),
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 8
                    })

                    local Arrow = Library:Create("ImageLabel", {
                        Name = "Arrow",
                        Parent = DropdownBg,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 8, 0, 8),
                        Position = UDim2.new(1, -14, 0.5, -4),
                        Image = "rbxassetid://252644715",
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        Rotation = 0,
                        ZIndex = 8
                    })

                    local ListWrapper = Library:Create("Frame", {
                        Name = "ListWrapper",
                        Parent = ScreenGui,
                        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                        Size = UDim2.new(0, DropdownBg.AbsoluteSize.X, 0, 0),
                        Position = UDim2.new(0, 0, 0, 0), 
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        Visible = false,
                        ZIndex = 100
                    })

                    Library:Create("UIStroke", {
                        Name = "ListStroke",
                        Parent = ListWrapper,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local ListContainer = Library:Create("ScrollingFrame", {
                        Name = "ListContainer",
                        Parent = ListWrapper,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        ScrollBarThickness = 0,
                        ClipsDescendants = true,
                        ZIndex = 101
                    })

                    local ListLayout = Library:Create("UIListLayout", {
                        Parent = ListContainer,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 0)
                    })

                    local TopGlow = Library:Create("ImageLabel", {
                        Name = "TopGlow",
                        Parent = ListWrapper,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 1, 0, 0), 
                        Size = UDim2.new(1, -2, 0, 15),
                        Image = "rbxassetid://15541064478",
                        ImageColor3 = Color3.fromRGB(27, 27, 34), 
                        Rotation = 180,
                        Visible = false,
                        ZIndex = 105
                    })

                    local BottomGlow = Library:Create("ImageLabel", {
                        Name = "BottomGlow",
                        Parent = ListWrapper,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 1, 1, -15),
                        Size = UDim2.new(1, -2, 0, 15),
                        Image = "rbxassetid://15541064478",
                        ImageColor3 = Color3.fromRGB(27, 27, 34), 
                        Rotation = 0,
                        Visible = false,
                        ZIndex = 105
                    })

                    local ScrollUp = Library:Create("ImageButton", {
                        Name = "ScrollUp",
                        Parent = ListWrapper,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -14, 0, 4), 
                        Size = UDim2.new(0, 10, 0, 10),
                        Image = "rbxassetid://252644715",
                        Rotation = 180,
                        ImageColor3 = Color3.fromRGB(150, 150, 150),
                        Visible = false,
                        ZIndex = 106
                    })

                    local ScrollDown = Library:Create("ImageButton", {
                        Name = "ScrollDown",
                        Parent = ListWrapper,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -14, 1, -14),
                        Size = UDim2.new(0, 10, 0, 10),
                        Image = "rbxassetid://252644715",
                        Rotation = 0,
                        ImageColor3 = Color3.fromRGB(150, 150, 150),
                        Visible = false,
                        ZIndex = 106
                    })

                    ScrollUp.MouseEnter:Connect(function() ScrollUp.ImageColor3 = Library.Accent end)
                    ScrollUp.MouseLeave:Connect(function() ScrollUp.ImageColor3 = Color3.fromRGB(150, 150, 150) end)
                    ScrollDown.MouseEnter:Connect(function() ScrollDown.ImageColor3 = Library.Accent end)
                    ScrollDown.MouseLeave:Connect(function() ScrollDown.ImageColor3 = Color3.fromRGB(150, 150, 150) end)

                    local open = false
                    local buttons = {}
                    local inputConnection = nil
                    
                    local function UpdateListScrollUI()
                        local contentHeight = ListLayout.AbsoluteContentSize.Y
                        ListContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                        
                        local isScrollable = contentHeight > ListWrapper.AbsoluteSize.Y
                        
                        if isScrollable then
                            local maxScroll = math.max(0, ListContainer.CanvasSize.Y.Offset - ListWrapper.AbsoluteSize.Y)
                            local currentScroll = ListContainer.CanvasPosition.Y
                            
                            ScrollUp.Visible = currentScroll > 2
                            ScrollDown.Visible = currentScroll < (maxScroll - 2)
                            TopGlow.Visible = currentScroll > 2
                            BottomGlow.Visible = currentScroll < (maxScroll - 2)
                        else
                            ScrollUp.Visible = false
                            ScrollDown.Visible = false
                            TopGlow.Visible = false
                            BottomGlow.Visible = false
                        end
                    end

                    ListContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateListScrollUI)
                    ListWrapper:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateListScrollUI)

                    ScrollUp.MouseButton1Click:Connect(function()
                        local newPos = ListContainer.CanvasPosition.Y - 36
                        TweenService:Create(ListContainer, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.max(0, newPos))}):Play()
                    end)

                    ScrollDown.MouseButton1Click:Connect(function()
                        local maxScroll = ListContainer.CanvasSize.Y.Offset - ListWrapper.AbsoluteSize.Y
                        local newPos = ListContainer.CanvasPosition.Y + 36
                        TweenService:Create(ListContainer, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.min(maxScroll, newPos))}):Play()
                    end)

                    local function updatePosition()
                        if open then
                            local inset = GuiService:GetGuiInset()
                            local offsetY = ScreenGui.IgnoreGuiInset and inset.Y or 0
                            
                            local visibleItems = math.min(#list, 7)
                            local visibleHeight = visibleItems * 18
                            
                            ListWrapper.Size = UDim2.new(0, DropdownBg.AbsoluteSize.X, 0, visibleHeight)
                            ListWrapper.Position = UDim2.new(0, DropdownBg.AbsolutePosition.X, 0, DropdownBg.AbsolutePosition.Y + DropdownBg.AbsoluteSize.Y + 4 + offsetY)
                            UpdateListScrollUI()
                        end
                    end

                    local function closeDropdown()
                        if open then
                            open = false
                            TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                            ListWrapper.Visible = false
                            if inputConnection then
                                inputConnection:Disconnect()
                                inputConnection = nil
                            end
                        end
                    end

                    local function updateList()
                        for _, btn in pairs(buttons) do btn:Destroy() end
                        buttons = {}
                        totalHeight = 0

                        for _, item in ipairs(list) do
                            local isSelected = false
                            if multi then
                                isSelected = table.find(DropdownObj.Value, item) ~= nil
                            else
                                isSelected = item == DropdownObj.Value
                            end

                            local itemBtn = Library:Create("TextButton", {
                                Name = item,
                                Parent = ListContainer,
                                BackgroundTransparency = 1,
                                BackgroundColor3 = Color3.fromRGB(54, 54, 64),
                                Size = UDim2.new(1, 0, 0, 18), 
                                Font = Enum.Font.Code,
                                Text = "  " .. tostring(item),
                                TextColor3 = isSelected and Library.Accent or Color3.fromRGB(200, 200, 200),
                                TextSize = 11,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                BorderSizePixel = 0,
                                AutoButtonColor = false,
                                ZIndex = 7
                                })
                            itemBtn.MouseButton1Click:Connect(function()
                                if multi then
                                    local selected = DropdownObj.Value
                                    local idx = table.find(selected, item)
                                    if idx then
                                        table.remove(selected, idx)
                                    else
                                        table.insert(selected, item)
                                    end
                                    DropdownObj.Value = selected
                                    SelectedText.Text = getSelectedText()
                                    callback(selected)
                                    FireCallbacks(selected)
                                    DropdownObj:_updateConnectedVisibility()
                                    
                                    itemBtn.TextColor3 = table.find(selected, item) and Library.Accent or Color3.fromRGB(200, 200, 200)
                                else
                                    DropdownObj.Value = item
                                    SelectedText.Text = getSelectedText()
                                    callback(item)
                                    FireCallbacks(item)
                                    DropdownObj:_updateConnectedVisibility()
                                    
                                    for _, b in pairs(buttons) do
                                        b.BackgroundTransparency = 1
                                        b.TextColor3 = (b.Name == tostring(item)) and Library.Accent or Color3.fromRGB(200, 200, 200)
                                    end
                                    
                                    closeDropdown()
                                end
                            end)

                            itemBtn.MouseEnter:Connect(function()
                                itemBtn.BackgroundTransparency = 0
                                itemBtn.TextColor3 = Library.Accent
                            end)
                            
                            itemBtn.MouseLeave:Connect(function()
                                itemBtn.BackgroundTransparency = 1
                                local currentlySelected = multi and table.find(DropdownObj.Value, item) or (DropdownObj.Value == item)
                                itemBtn.TextColor3 = currentlySelected and Library.Accent or Color3.fromRGB(200, 200, 200)
                            end)

                            table.insert(buttons, itemBtn)
                            totalHeight = totalHeight + 18
                        end
                        ListContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
                        updatePosition()
                    end
                    
                    updateList()

                    DropdownBg.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if open then
                                closeDropdown()
                            else
                                open = true
                                TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 180}):Play()
                                updatePosition()
                                ListWrapper.Visible = true
                                
                                if inputConnection then inputConnection:Disconnect() end
                                task.wait()
                                inputConnection = UserInputService.InputBegan:Connect(function(inp)
                                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
                                        local pos = inp.Position
                                        local bgPos = DropdownBg.AbsolutePosition
                                        local bgSize = DropdownBg.AbsoluteSize
                                        local inBg = pos.X >= bgPos.X and pos.X <= bgPos.X + bgSize.X and pos.Y >= bgPos.Y and pos.Y <= bgPos.Y + bgSize.Y
                                        
                                        local listPos = ListWrapper.AbsolutePosition
                                        local listSize = ListWrapper.AbsoluteSize
                                        local inList = ListWrapper.Visible and pos.X >= listPos.X and pos.X <= listPos.X + listSize.X and pos.Y >= listPos.Y and pos.Y <= listPos.Y + listSize.Y
                                        
                                        if not inBg and not inList then
                                            closeDropdown()
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                    
                    ScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(closeDropdown)
                    MainFrame:GetPropertyChangedSignal("Position"):Connect(closeDropdown)
                    
                    MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        if open then
                            updatePosition()
                        end
                    end)

                    function DropdownObj:SetValue(value)
                        if type(value) == "table" and value.value ~= nil then
                            value = value.value
                        end
                        if multi then
                            if type(value) == "table" then
                                DropdownObj.Value = value
                                SelectedText.Text = getSelectedText()
                                callback(value)
                                FireCallbacks(value)
                                updateList()
                                DropdownObj:_updateConnectedVisibility()
                            end
                        else
                            if table.find(list, value) then
                                DropdownObj.Value = value
                                SelectedText.Text = getSelectedText()
                                callback(value)
                                FireCallbacks(value)
                                updateList()
                                DropdownObj:_updateConnectedVisibility()
                            end
                        end
                    end
                    
                    function DropdownObj:Refresh(newList)
                        list = newList
                        updateList()
                    end

                    function DropdownObj:Connect(widgets, value)
                        if multi or value == nil then return end
                        local targetWidgets = (type(widgets) == "table" and not widgets.Main) and widgets or {widgets}
                        table.insert(self._visibilityLinks, {
                            Widgets = targetWidgets,
                            Value = value
                        })
                        self:_updateConnectedVisibility()
                    end

                    function DropdownObj:AddToggle(opt)
                        local widget = SectorMethods:AddToggle(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    function DropdownObj:AddSlider(opt)
                        local widget = SectorMethods:AddSlider(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    function DropdownObj:AddDropdown(opt)
                        local widget = SectorMethods:AddDropdown(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    function DropdownObj:AddList(opt)
                        local widget = SectorMethods:AddList(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    function DropdownObj:AddTextbox(opt)
                        local widget = SectorMethods:AddTextbox(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    function DropdownObj:AddButton(opt)
                        local widget = SectorMethods:AddButton(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    function DropdownObj:AddLabel(opt)
                        local widget = SectorMethods:AddLabel(opt)
                        self:Connect(widget, opt.ConnectValue)
                        return widget
                    end
                    
                    DropdownObj.Set = DropdownObj.SetValue
                    Library.Flags[flag] = DropdownObj
                    return DropdownObj
                end

                function SectorMethods:AddTextbox(options)
                    options = typeof(options) == "table" and options or { Text = options }
                    local text = options.Text or "Textbox"
                    local default = options.Default or ""
                    local flag = options.Flag or text
                    local clearOnFocus = options.ClearTextOnFocus
                    if clearOnFocus == nil then clearOnFocus = false end
                    local callback = options.Callback or function() end

                    local TextboxObj = {
                        Value = default,
                        Callbacks = {}
                    }
                    
                    function TextboxObj:OnChanged(cb)
                        table.insert(self.Callbacks, cb)
                    end
                    
                    local function FireCallbacks(...)
                        for _, cb in ipairs(TextboxObj.Callbacks) do
                            task.spawn(cb, ...)
                        end
                    end

                    local TextboxContainer = Library:Create("Frame", {
                        Name = text .. "Textbox",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 38),
                        ZIndex = 6
                    })

                    TextboxObj.Main = TextboxContainer
                    function TextboxObj:SetVisible(state)
                        self.Main.Visible = state
                    end

                    local TextboxLabel = Library:Create("TextLabel", {
                        Name = "Label",
                        Parent = TextboxContainer,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 218, 0, 14),
                        Position = UDim2.new(0, 24, 0, 0),
                        Font = Enum.Font.Code,
                        Text = text,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7
                    })

                    local TextboxBg = Library:Create("Frame", {
                        Name = "Background",
                        Parent = TextboxContainer,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 170, 0, 20),
                        Position = UDim2.new(0, 24, 0, 16),
                        BorderSizePixel = 0,
                        ZIndex = 7
                    })

                    Library:Create("UIGradient", {
                        Name = "BgGradient",
                        Parent = TextboxBg,
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 53, 62)),
                            ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Color3.fromRGB(55, 53, 62), 0.1))
                        })
                    })

                    local BgStroke = Library:Create("UIStroke", {
                        Name = "BgStroke",
                        Parent = TextboxBg,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local InputClip = Library:Create("Frame", {
                        Name = "InputClip",
                        Parent = TextboxBg,
                        BackgroundTransparency = 1,
                        ClipsDescendants = true,
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 6, 0, 0),
                        ZIndex = 8
                    })

                    local InputBox = Library:Create("TextBox", {
                        Name = "Input",
                        Parent = InputClip,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Font = Enum.Font.Code,
                        Text = tostring(default),
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ClearTextOnFocus = clearOnFocus,
                        ZIndex = 8
                    })

                    local function getCursorIndex()
                        local cursorPos = InputBox.CursorPosition
                        if cursorPos == nil or cursorPos < 0 then
                            return #InputBox.Text
                        end
                        return math.clamp(cursorPos - 1, 0, #InputBox.Text)
                    end

                    local function updateTextboxScroll()
                        local currentText = tostring(InputBox.Text or "")
                        local clipWidth = math.max(InputClip.AbsoluteSize.X, 1)
                        local totalWidth = TextService:GetTextSize(currentText, 11, Enum.Font.Code, Vector2.new(10000, 20)).X
                        local contentWidth = math.max(clipWidth, totalWidth + 4)
                        InputBox.Size = UDim2.new(0, contentWidth, 1, 0)

                        local beforeCursor = currentText:sub(1, getCursorIndex())
                        local cursorWidth = TextService:GetTextSize(beforeCursor, 11, Enum.Font.Code, Vector2.new(10000, 20)).X
                        local maxOffset = math.max(0, contentWidth - clipWidth)
                        local targetOffset = 0

                        if contentWidth > clipWidth then
                            targetOffset = math.clamp(cursorWidth - clipWidth + 10, 0, maxOffset)
                        end

                        InputBox.Position = UDim2.new(0, -targetOffset, 0, 0)
                    end

                    InputBox:GetPropertyChangedSignal("Text"):Connect(updateTextboxScroll)
                    InputBox:GetPropertyChangedSignal("CursorPosition"):Connect(updateTextboxScroll)
                    InputClip:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTextboxScroll)
                    InputBox.Focused:Connect(updateTextboxScroll)

                    InputBox.FocusLost:Connect(function()
                        TextboxObj.Value = InputBox.Text
                        Library.Flags[flag] = TextboxObj
                        callback(InputBox.Text)
                        FireCallbacks(InputBox.Text)
                        updateTextboxScroll()
                    end)

                    function TextboxObj:SetValue(value)
                        if type(value) == "table" and value.value ~= nil then
                            value = value.value
                        end
                        InputBox.Text = tostring(value)
                        TextboxObj.Value = tostring(value)
                        Library.Flags[flag] = TextboxObj
                        callback(tostring(value))
                        FireCallbacks(tostring(value))
                        updateTextboxScroll()
                    end
                    TextboxObj.Set = TextboxObj.SetValue

                    updateTextboxScroll()
                    Library.Flags[flag] = TextboxObj
                    return TextboxObj
                end

                function SectorMethods:AddList(options)
                    options = typeof(options) == "table" and options or { Text = options }
                    local text = options.Text or "List"
                    local list = options.List or {}
                    local multi = options.Multi or false
                    local default = options.Default or (multi and {} or list[1] or "")
                    local flag = options.Flag or text
                    local showTitle = options.ShowTitle
                    if showTitle == nil then showTitle = true end
                    local noGaps = options.NoGaps or false
                    local fullSize = options.FullSize or false
                    local callback = options.Callback or function() end
                    
                    local ListObj = {
                        Value = default,
                        Callbacks = {}
                    }
                    
                    function ListObj:OnChanged(cb)
                        table.insert(self.Callbacks, cb)
                    end
                    
                    local function FireCallbacks(...)
                        for _, cb in ipairs(ListObj.Callbacks) do
                            task.spawn(cb, ...)
                        end
                    end
                    
                    local xOffset = noGaps and 0 or 24
                    local widthOffset = noGaps and 0 or 48
                    local labelHeight = 0

                    local ListMain = Library:Create("Frame", {
                        Name = text .. "ListMain",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        ZIndex = 6
                    })
                    
                    ListObj.Main = ListMain
                    function ListObj:SetVisible(state)
                        if self.Main then
                            self.Main.Visible = state
                        end
                    end

                    if showTitle then
                        labelHeight = 18
                        Library:Create("TextLabel", {
                            Name = "Label",
                            Parent = ListMain,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, -xOffset, 0, 14),
                            Position = UDim2.new(0, xOffset, 0, 0),
                            Font = Enum.Font.Code,
                            Text = text,
                            TextColor3 = Color3.fromRGB(200, 200, 200),
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 7
                        })
                    end
                    
                    local ListShell = Library:Create("Frame", {
                        Name = "ListShell",
                        Parent = ListMain,
                        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                        Position = UDim2.new(0, xOffset, 0, labelHeight),
                        Size = UDim2.new(1, -widthOffset, 0, 0),
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        ZIndex = 7
                    })

                    Library:Create("UIStroke", {
                        Parent = ListShell,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local ListContainer = Library:Create("ScrollingFrame", {
                        Name = "ListContainer",
                        Parent = ListShell,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        ScrollBarThickness = 0,
                        ClipsDescendants = true,
                        ZIndex = 8
                    })
                    
                    local ListLayout = Library:Create("UIListLayout", {
                        Parent = ListContainer,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 0)
                    })

                    local ListTopGlow = Library:Create("ImageLabel", {
                        Name = "TopGlow",
                        Parent = ListShell,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 1),
                        Size = UDim2.new(1, 0, 0, 15),
                        Image = "rbxassetid://15541064478",
                        ImageColor3 = Color3.fromRGB(27, 27, 34),
                        Rotation = 180,
                        Visible = false,
                        ZIndex = 12
                    })

                    local ListBottomGlow = Library:Create("ImageLabel", {
                        Name = "BottomGlow",
                        Parent = ListShell,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 1, 1, -15),
                        Size = UDim2.new(1, 0, 0, 15),
                        Image = "rbxassetid://15541064478",
                        ImageColor3 = Color3.fromRGB(27, 27, 34),
                        Rotation = 0,
                        Visible = false,
                        ZIndex = 12
                    })

                    local ListScrollUp = Library:Create("ImageButton", {
                        Name = "ScrollUp",
                        Parent = ListShell,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -14, 0, 4),
                        Size = UDim2.new(0, 10, 0, 10),
                        Image = "rbxassetid://252644715",
                        Rotation = 180,
                        ImageColor3 = Color3.fromRGB(150, 150, 150),
                        Visible = false,
                        ZIndex = 13
                    })

                    local ListScrollDown = Library:Create("ImageButton", {
                        Name = "ScrollDown",
                        Parent = ListShell,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -14, 1, -14),
                        Size = UDim2.new(0, 10, 0, 10),
                        Image = "rbxassetid://252644715",
                        Rotation = 0,
                        ImageColor3 = Color3.fromRGB(150, 150, 150),
                        Visible = false,
                        ZIndex = 13
                    })

                    local function ListAddScrollEffects(btn)
                        btn.MouseEnter:Connect(function() btn.ImageColor3 = Library.Accent end)
                        btn.MouseLeave:Connect(function() btn.ImageColor3 = Color3.fromRGB(150, 150, 150) end)
                    end
                    ListAddScrollEffects(ListScrollUp)
                    ListAddScrollEffects(ListScrollDown)

                    local function UpdateListScrollUI()
                        local contentHeight = ListLayout.AbsoluteContentSize.Y
                        ListContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                        local isScrollable = contentHeight > ListContainer.AbsoluteSize.Y
                        if isScrollable then
                            local maxScroll = math.max(0, ListContainer.CanvasSize.Y.Offset - ListContainer.AbsoluteSize.Y)
                            local currentScroll = ListContainer.CanvasPosition.Y
                            ListScrollUp.Visible = currentScroll > 2
                            ListScrollDown.Visible = currentScroll < (maxScroll - 2)
                            ListTopGlow.Visible = currentScroll > 2
                            ListBottomGlow.Visible = currentScroll < (maxScroll - 2)
                        else
                            ListScrollUp.Visible = false
                            ListScrollDown.Visible = false
                            ListTopGlow.Visible = false
                            ListBottomGlow.Visible = false
                        end
                    end

                    ListContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateListScrollUI)
                    ListShell:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateListScrollUI)
                    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateListScrollUI)

                    ListScrollUp.MouseButton1Click:Connect(function()
                        local newPos = ListContainer.CanvasPosition.Y - 36
                        TweenService:Create(ListContainer, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.max(0, newPos))}):Play()
                    end)

                    ListScrollDown.MouseButton1Click:Connect(function()
                        local maxScroll = ListContainer.CanvasSize.Y.Offset - ListContainer.AbsoluteSize.Y
                        local newPos = ListContainer.CanvasPosition.Y + 36
                        TweenService:Create(ListContainer, TweenInfo.new(0.2), {CanvasPosition = Vector2.new(0, math.min(maxScroll, newPos))}):Play()
                    end)
                    
                    local buttons = {}
                    
                    local function updateList()
                        for _, btn in pairs(buttons) do btn:Destroy() end
                        buttons = {}
                        local totalHeight = 0
                        
                        for _, item in ipairs(list) do
                            local isSelected = false
                            if multi then
                                isSelected = table.find(ListObj.Value, item) ~= nil
                            else
                                isSelected = item == ListObj.Value
                            end
                            
                            local itemBtn = Library:Create("TextButton", {
                                Name = item,
                                Parent = ListContainer,
                                BackgroundTransparency = isSelected and 0 or 1,
                                BackgroundColor3 = Color3.fromRGB(54, 54, 64),
                                Size = UDim2.new(1, 0, 0, 18),
                                Font = Enum.Font.Code,
                                Text = "  " .. tostring(item),
                                TextColor3 = isSelected and Library.Accent or Color3.fromRGB(200, 200, 200),
                                TextSize = 11,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                BorderSizePixel = 0,
                                AutoButtonColor = false,
                                ZIndex = 7
                                })
                            itemBtn.MouseButton1Click:Connect(function()
                                if multi then
                                    local selected = ListObj.Value
                                    local idx = table.find(selected, item)
                                    if idx then
                                        table.remove(selected, idx)
                                    else
                                        table.insert(selected, item)
                                    end
                                    ListObj.Value = selected
                                    callback(selected)
                                    FireCallbacks(selected)
                                    
                                    itemBtn.BackgroundTransparency = table.find(selected, item) and 0 or 1
                                    itemBtn.TextColor3 = table.find(selected, item) and Library.Accent or Color3.fromRGB(200, 200, 200)
                                else
                                    ListObj.Value = item
                                    callback(item)
                                    FireCallbacks(item)
                                    
                                    for _, b in pairs(buttons) do
                                        b.BackgroundTransparency = 1
                                        b.TextColor3 = (b.Name == tostring(item)) and Library.Accent or Color3.fromRGB(200, 200, 200)
                                    end
                                    
                                    itemBtn.BackgroundTransparency = 0
                                    itemBtn.TextColor3 = Library.Accent
                                end
                            end)
                            
                            itemBtn.MouseEnter:Connect(function()
                                itemBtn.TextColor3 = Library.Accent
                            end)
                            
                            itemBtn.MouseLeave:Connect(function()
                                local currentlySelected = multi and table.find(ListObj.Value, item) or (ListObj.Value == item)
                                itemBtn.TextColor3 = currentlySelected and Library.Accent or Color3.fromRGB(200, 200, 200)
                            end)
                            
                            table.insert(buttons, itemBtn)
                            totalHeight = totalHeight + 18
                        end
                        
                        local listHeight = 0
                        if fullSize then
                            listHeight = math.max(18, ScrollFrame.AbsoluteSize.Y - labelHeight - 20)
                        else
                            local visibleItems = math.min(#list, 7)
                            listHeight = visibleItems * 18
                        end
                        
                        if fullSize then
                            ListShell.Size = UDim2.new(1, -widthOffset, 0, listHeight)
                        else
                            ListShell.Size = UDim2.new(0, 170, 0, listHeight)
                        end
                        ListContainer.Size = UDim2.new(1, 0, 1, 0)
                        ListMain.Size = UDim2.new(1, 0, 0, listHeight + labelHeight)
                        UpdateListScrollUI()
                    end
                    
                    updateList()
                    
                    if fullSize then
                        ScrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            local listHeight = math.max(18, ScrollFrame.AbsoluteSize.Y - labelHeight - 20)
                            ListShell.Size = UDim2.new(1, -widthOffset, 0, listHeight)
                            ListContainer.Size = UDim2.new(1, 0, 1, 0)
                            ListMain.Size = UDim2.new(1, 0, 0, listHeight + labelHeight)
                            UpdateListScrollUI()
                        end)
                    end
                    
                    function ListObj:SetValue(value)
                        if type(value) == "table" and value.value ~= nil then
                            value = value.value
                        end
                        if multi then
                            if type(value) == "table" then
                                ListObj.Value = value
                                callback(value)
                                FireCallbacks(value)
                                updateList()
                            end
                        else
                            if table.find(list, value) then
                                ListObj.Value = value
                                callback(value)
                                FireCallbacks(value)
                                updateList()
                            end
                        end
                    end
                    
                    function ListObj:Refresh(newList)
                        list = newList
                        updateList()
                    end
                    
                    ListObj.Set = ListObj.SetValue
                    Library.Flags[flag] = ListObj
                    return ListObj
                end

                function SectorMethods:AddButton(options)
                    options = typeof(options) == "table" and options or { Text = options }
                    local text = options.Text or "Button"
                    local callback = options.Callback or function() end

                    local ButtonContainer = Library:Create("Frame", {
                        Name = text .. "ButtonContainer",
                        Parent = ScrollFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 24),
                        ZIndex = 6
                    })

                    local ButtonBg = Library:Create("TextButton", {
                        Name = "ButtonBg",
                        Parent = ButtonContainer,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 170, 1, -4),
                        Position = UDim2.new(0, 24, 0, 2),
                        AutoButtonColor = false,
                        Text = "",
                        BorderSizePixel = 0,
                        ZIndex = 7
                    })

                    Library:Create("UIGradient", {
                        Name = "BgGradient",
                        Parent = ButtonBg,
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(41, 41, 48)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 43))
                        })
                    })

                    Library:Create("UIStroke", {
                        Name = "BgStroke",
                        Parent = ButtonBg,
                        Color = Color3.fromRGB(12, 12, 12),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    })

                    local ButtonText = Library:Create("TextLabel", {
                        Name = "Text",
                        Parent = ButtonBg,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = Enum.Font.Code,
                        Text = text,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 11,
                        ZIndex = 8
                    })

                    local confirmOptions = nil

                    ButtonBg.MouseButton1Click:Connect(function()
                        if confirmOptions then
                            Window:ShowDialog({
                                Text = confirmOptions.Text or "Are you sure?",
                                Callback = function()
                                    callback()
                                    if confirmOptions.Callback then
                                        confirmOptions.Callback()
                                    end
                                end
                            })
                        else
                            callback()
                        end
                    end)

                    local ButtonObj = { Main = ButtonContainer }
                    function ButtonObj:SetVisible(state)
                        if self.Main then
                            self.Main.Visible = state
                        end
                    end
                    
                    function ButtonObj:Confirm(confOptions)
                        confirmOptions = typeof(confOptions) == "table" and confOptions or { Text = confOptions }
                        return self
                    end
                    
                    return ButtonObj
                end

                return SectorMethods
            end
            
            return SideObject
        end

        local LeftSide = CreateSide("Left")
        local RightSide = CreateSide("Right")

        LeftSide._Tab = Tab
        LeftSide._ContentFrame = ContentFrame
        LeftSide._SideContainer = SideContainer

        function LeftSide:CreateSubTabs(options)
            options = typeof(options) == "table" and options or {}
            local subHeight = options.Height or 24

            SideContainer.Visible = false

            local SubTabsBar = Library:Create("Frame", {
                Name = "SubTabsBar",
                Parent = ContentFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, subHeight),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 5
            })

            Library:Create("UIPadding", {
                Parent = SubTabsBar,
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 16)
            })

            local SubTabsLayout = Library:Create("UIListLayout", {
                Parent = SubTabsBar,
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 16)
            })

            local subtabs = {}
            local currentSubTab = nil

            local function activateSubTab(subObj)
                if currentSubTab == subObj then return end
                currentSubTab = subObj
                SideContainer.Visible = false
                for _, s in ipairs(subtabs) do
                    local active = (s == subObj)
                    s.Active = active
                    s.Label.TextColor3 = active and Library.Accent or Color3.fromRGB(150, 150, 150)
                    if s.Wrapper then
                        s.Wrapper.Visible = active
                    end
                end
            end

            local SubTabsApi = {}

            function SubTabsApi:CreateTab(tabOptions)
                tabOptions = typeof(tabOptions) == "table" and tabOptions or { Title = tabOptions }
                local tabName = tabOptions.Title or "SubTab"

                local SubTabLabel = Library:Create("TextButton", {
                    Name = tabName .. "SubTabBtn",
                    Parent = SubTabsBar,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    AutoButtonColor = false,
                    Font = Enum.Font.Code,
                    Text = tabName,
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = 12,
                    ZIndex = 6
                })

                local subContentFrame = Library:Create("Frame", {
                    Name = tabName .. "SubContent",
                    Parent = ContentFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, -subHeight),
                    Position = UDim2.new(0, 0, 0, subHeight),
                    Visible = false,
                    ZIndex = 1
                })

                local subSideContainer = Library:Create("Frame", {
                    Name = "SubSideContainer",
                    Parent = subContentFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0)
                })

                Library:Create("UIListLayout", {
                    Parent = subSideContainer,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4)
                })

                Library:Create("UIPadding", {
                    Parent = subSideContainer,
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8)
                })

                local subLeft, subRight = CreateSide("SubLeft", subSideContainer), CreateSide("SubRight", subSideContainer)

                local subObj = {
                    Active = false,
                    Label = SubTabLabel,
                    Wrapper = subContentFrame,
                    LeftSide = subLeft,
                    RightSide = subRight
                }

                SubTabLabel.MouseButton1Click:Connect(function()
                    activateSubTab(subObj)
                end)

                table.insert(subtabs, subObj)

                if #subtabs == 1 then
                    activateSubTab(subObj)
                else
                    activateSubTab(currentSubTab or subtabs[1])
                end

                return subLeft, subRight
            end

            return SubTabsApi
        end

        function Tab:Activate()
            if Window.CurrentTab then
                Window.CurrentTab:Deactivate()
            end
            
            Window.CurrentTab = Tab
            Tab.Active = true
            
            TabGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 53, 62)),
                ColorSequenceKeypoint.new(1, Library:GetDarkerColor(Color3.fromRGB(55, 53, 62), 0.1))
            })
            TabAccentLine.Visible = true
            ContentFrame.Visible = true
        end

        function Tab:Deactivate()
            Tab.Active = false
            
            TabGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 46, 55)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 14, 19))
            })
            TabAccentLine.Visible = false
            ContentFrame.Visible = false
        end

        TabButton.MouseButton1Click:Connect(function()
            Tab:Activate()
        end)

        local function UpdateTabSizes()
            local tabCount = #Window.Tabs
            if tabCount > 0 then
                local sizeScale = 1 / tabCount
                for _, t in ipairs(Window.Tabs) do
                    t.Button.Size = UDim2.new(sizeScale, 0, 1, 0)
                end
            end
        end

        table.insert(Window.Tabs, Tab)
        UpdateTabSizes()

        Tab:Deactivate()
        if #Window.Tabs == 1 then
            Tab:Activate()
        end

        return LeftSide, RightSide
    end
    
    function Window:CreateConfiguration(options)
        options = options or {}
        Library.ConfigFolder = options.FolderName or "DeadcellConfigs"
        Library:EnsureConfigFolder()

        local ConfigTabL, ConfigTabR = self:CreateTab({ Title = "Configuration" })
        local ProfilesSector = ConfigTabL:CreateSector({ Title = "Profiles" })
        local SettingsSector = ConfigTabR:CreateSector({ Title = "Settings" })

        local configsList = Library:GetConfigNames()
        local ConfigListObj = ProfilesSector:AddList({
            Text = "Configs",
            List = configsList,
            Multi = false,
            ShowTitle = false,
            NoGaps = true,
            FullSize = true,
            Flag = "ConfigList"
        })

        SettingsSector:AddLabel({ Text = "Menu Bind" }):AddKeybind({
            Default = "Insert",
            Mode = "Toggle",
            CanChangeMode = false,
            ShowInList = false,
            Flag = "MenuBind",
            Callback = function(state)
                Library:SetMenuVisible(nil)
            end
        })

        local defaultAccent = Library.DefaultAccent or Library.Accent
        SettingsSector:AddToggle({
            Text = "Custom Accent Color",
            Default = false,
            Flag = "CustomAccentToggle",
            Callback = function(v)
                if v then
                    if Library.Flags["MenuAccentColor"] then
                        Library:ChangeAccent(Library.Flags["MenuAccentColor"].Color)
                    end
                else
                    Library:ChangeAccent(defaultAccent)
                end
            end
        }):AddColorpicker({
            Default = defaultAccent,
            Flag = "MenuAccentColor",
            Callback = function(color)
                if Library.Flags["CustomAccentToggle"] and Library.Flags["CustomAccentToggle"].Value then
                    Library:ChangeAccent(color)
                end
            end
        })

        SettingsSector:AddToggle({
            Text = "Keybind List",
            Default = true,
            Flag = "KeybindListToggle",
            Callback = function(v)
                Library:SetKeybindListVisible(v)
            end
        })
        Library:SetKeybindListVisible(true)

        SettingsSector:AddToggle({
            Text = "Watermark",
            Default = true,
            Flag = "WatermarkToggle",
            Callback = function(v)
                Library:SetWatermarkVisible(v)
            end
        })
        Library:SetWatermarkVisible(true)

        SettingsSector:AddButton({
            Text = "Unhook",
            Callback = function()
                Library:Unload()
            end
        }):Confirm({ Text = "This will completely unload the library. Are you sure?" })

        SettingsSector:AddTextbox({
            Text = "Config Name",
            Default = "",
            Flag = "ConfigNameInput"
        })

        SettingsSector:AddButton({
            Text = "Create",
            Callback = function()
                local name = Library.Flags["ConfigNameInput"] and Library.Flags["ConfigNameInput"].Value
                if name and name ~= "" and not table.find(configsList, name) then
                    table.insert(configsList, name)
                    ConfigListObj:Refresh(configsList)
                    ConfigListObj:SetValue(name)
                    Library:SaveConfig(name)
                    Library:Notify({ Title = "Config", Text = "Created: " .. name, Time = 2 })
                end
            end
        })

        SettingsSector:AddButton({
            Text = "Save",
            Callback = function()
                local sel = Library.Flags["ConfigList"] and Library.Flags["ConfigList"].Value
                if sel and sel ~= "" then
                    if Library:SaveConfig(sel) then
                        Library:Notify({ Title = "Config", Text = "Saved: " .. sel, Time = 2 })
                    end
                end
            end
        })

        SettingsSector:AddButton({
            Text = "Load",
            Callback = function()
                local sel = Library.Flags["ConfigList"] and Library.Flags["ConfigList"].Value
                if sel and sel ~= "" then
                    if Library:LoadConfig(sel) then
                        Library:Notify({ Title = "Config", Text = "Loaded: " .. sel, Time = 2 })
                    end
                end
            end
        })

        SettingsSector:AddButton({
            Text = "Delete",
            Callback = function()
                local sel = Library.Flags["ConfigList"] and Library.Flags["ConfigList"].Value
                local idx = table.find(configsList, sel)
                if idx then
                    Library:DeleteConfig(sel)
                    table.remove(configsList, idx)
                    ConfigListObj:Refresh(configsList)
                    local nextSel = configsList[1] or ""
                    ConfigListObj:SetValue(nextSel)
                    Library:Notify({ Title = "Config", Text = "Deleted: " .. sel, Time = 2 })
                end
            end
        }):Confirm({ Text = "Delete this config?" })

        if configsList[1] then
            ConfigListObj:SetValue(configsList[1])
        end

        return ProfilesSector, SettingsSector
    end
    
    function Window:Destroy()
        ScreenGui:Destroy()
    end

    Library:CreateKeybindList()

    Library.MainWindow = Window
    return Window
end

function Library:CreateConfiguration(options)
    if Library.MainWindow then
        return Library.MainWindow:CreateConfiguration(options)
    end
end

return Library
