-- // === SERVICES (con cloneref) ===
get_service = function(service)
    return cloneref(game:GetService(service))
end

local players = get_service('Players')
local replicated_storage = get_service('ReplicatedStorage')
local http_service = get_service('HttpService')
local run_service = get_service('RunService')
local user_input_service = get_service('UserInputService')
local workspace = get_service('Workspace')

-- // REFERENCES
local local_player = players.LocalPlayer
local remote = replicated_storage.Packages.Net['RE/LaserGun_Fire']
local settings = require(replicated_storage.Shared.LaserGunsShared).Settings

-- // GUN MODS
settings.Radius.Value = 256
settings.MaxBounces.Value = 9999
settings.MaxAge.Value = 1e6
settings.StunDuration.Value = 60
settings.ImpulseForce.Value = 1e6
settings.Cooldown.Value = 0

-- // STATES
local lagger_enabled = false
local last_equipped = false

local selected_target = nil
local use_auto_target = true
local selected_target_label = 'Auto (Más cercano)'

-- “Frames” que quieres: como si el script estuviera iniciado muchas veces a la vez
local loops_por_frame = 1 -- se ajusta en la interfaz

-- // === GUI PRINCIPAL ===
local screen_gui = Instance.new('ScreenGui')
screen_gui.Name = 'Tokinu Hub'
screen_gui.Parent = local_player:WaitForChild('PlayerGui')

local frame = Instance.new('Frame')
frame.Size = UDim2.new(0, 260, 0, 270) -- más alto para que quepa todo
frame.Position = UDim2.new(0.5, -130, 0.5, -135) -- centrado aprox
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.05
frame.Active = true
frame.Parent = screen_gui

local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = frame

local stroke = Instance.new('UIStroke')
stroke.Color = Color3.fromRGB(120, 90, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = frame

-- LOGO
local logo = Instance.new('ImageLabel')
logo.Size = UDim2.new(0, 26, 0, 26)
logo.Position = UDim2.new(0, 10, 0, 8)
logo.BackgroundTransparency = 1
logo.Image = 'http://www.roblox.com/asset/?id=18347450507'
logo.Parent = frame

-- TITLE
local title = Instance.new('TextLabel')
title.Size = UDim2.new(1, -50, 0, 26)
title.Position = UDim2.new(0, 40, 0, 8)
title.BackgroundTransparency = 1
title.Text = 'FPS Killer - Made By Kayy'
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextColor3 = Color3.fromRGB(235, 235, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- BOTÓN CERRAR
local close_btn = Instance.new('TextButton')
close_btn.Size = UDim2.new(0, 22, 0, 22)
close_btn.Position = UDim2.new(1, -28, 0, 10)
close_btn.BackgroundColor3 = Color3.fromRGB(40, 10, 20)
close_btn.Text = '×'
close_btn.Font = Enum.Font.GothamBold
close_btn.TextSize = 16
close_btn.TextColor3 = Color3.fromRGB(255, 200, 210)
close_btn.Parent = frame

local close_corner = Instance.new('UICorner')
close_corner.CornerRadius = UDim.new(0, 11)
close_corner.Parent = close_btn

-- === BOTÓN PRINCIPAL (activar) ===
local button = Instance.new('TextButton')
button.Size = UDim2.new(1, -30, 0, 70)
button.Position = UDim2.new(0, 15, 0, 40)
button.Text = 'Pistola Láser\n[R] para activar'
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.FredokaOne
button.TextSize = 22
button.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
button.BackgroundTransparency = 0.1
button.AutoButtonColor = false
button.Parent = frame

local button_corner = Instance.new('UICorner')
button_corner.CornerRadius = UDim.new(0, 12)
button_corner.Parent = button

local button_gradient = Instance.new('UIGradient')
button_gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 110)),
})
button_gradient.Rotation = 90
button_gradient.Parent = button

-- === SELECTOR DE OBJETIVO ===
local target_frame = Instance.new('Frame')
target_frame.Size = UDim2.new(1, -30, 0, 26)
target_frame.Position = UDim2.new(0, 15, 0, 120)
target_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
target_frame.BorderSizePixel = 0
target_frame.Parent = frame

local target_corner = Instance.new('UICorner')
target_corner.CornerRadius = UDim.new(0, 10)
target_corner.Parent = target_frame

local target_label = Instance.new('TextLabel')
target_label.Size = UDim2.new(0, 80, 1, 0)
target_label.Position = UDim2.new(0, 8, 0, 0)
target_label.BackgroundTransparency = 1
target_label.Text = 'Objetivo:'
target_label.Font = Enum.Font.Gotham
target_label.TextSize = 14
target_label.TextColor3 = Color3.fromRGB(230, 230, 255)
target_label.TextXAlignment = Enum.TextXAlignment.Left
target_label.Parent = target_frame

local target_button = Instance.new('TextButton')
target_button.Size = UDim2.new(1, -100, 1, -6)
target_button.Position = UDim2.new(0, 90, 0, 3)
target_button.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
target_button.TextColor3 = Color3.fromRGB(240, 240, 255)
target_button.Font = Enum.Font.Gotham
target_button.TextSize = 14
target_button.TextXAlignment = Enum.TextXAlignment.Left
target_button.Text = selected_target_label .. '  ▼'
target_button.AutoButtonColor = true
target_button.Parent = target_frame

local target_btn_corner = Instance.new('UICorner')
target_btn_corner.CornerRadius = UDim.new(0, 9)
target_btn_corner.Parent = target_button

-- === SELECTOR DE FRAMES/LOOPS (TEXTBOX LIBRE) ===
local frames_frame = Instance.new('Frame')
frames_frame.Size = UDim2.new(1, -30, 0, 26)
frames_frame.Position = UDim2.new(0, 15, 0, 150)
frames_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frames_frame.BorderSizePixel = 0
frames_frame.Parent = frame

local frames_corner = Instance.new('UICorner')
frames_corner.CornerRadius = UDim.new(0, 10)
frames_corner.Parent = frames_frame

local frames_label = Instance.new('TextLabel')
frames_label.Size = UDim2.new(0, 110, 1, 0)
frames_label.Position = UDim2.new(0, 8, 0, 0)
frames_label.BackgroundTransparency = 1
frames_label.Text = 'Frames por tick:'
frames_label.Font = Enum.Font.Gotham
frames_label.TextSize = 14
frames_label.TextColor3 = Color3.fromRGB(230, 230, 255)
frames_label.TextXAlignment = Enum.TextXAlignment.Left
frames_label.Parent = frames_frame

local frames_input = Instance.new('TextBox')
frames_input.Size = UDim2.new(0, 70, 1, -6)
frames_input.Position = UDim2.new(1, -78, 0, 3)
frames_input.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
frames_input.TextColor3 = Color3.fromRGB(255, 200, 220)
frames_input.Font = Enum.Font.GothamBold
frames_input.TextSize = 14
frames_input.Text = tostring(loops_por_frame)
frames_input.ClearTextOnFocus = false
frames_input.TextXAlignment = Enum.TextXAlignment.Center
frames_input.Parent = frames_frame

local frames_input_corner = Instance.new('UICorner')
frames_input_corner.CornerRadius = UDim.new(0, 9)
frames_input_corner.Parent = frames_input

frames_input.FocusLost:Connect(function(enterPressed)
    local txt = frames_input.Text:gsub('%D', '')
    local num = tonumber(txt)

    if not num or num <= 0 then
        num = 1
    end
    if num > 1000 then
        num = 1000
    end

    loops_por_frame = num
    frames_input.Text = tostring(loops_por_frame)
end)

-- === DROPDOWN DE JUGADORES ===
local dropdown = Instance.new('ScrollingFrame')
dropdown.Size = UDim2.new(1, -30, 0, 70)
dropdown.Position = UDim2.new(0, 15, 0, 180)
dropdown.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
dropdown.BackgroundTransparency = 0.1
dropdown.ScrollBarThickness = 4
dropdown.BorderSizePixel = 0
dropdown.Visible = false
dropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropdown.Parent = frame

local dropdown_corner = Instance.new('UICorner')
dropdown_corner.CornerRadius = UDim.new(0, 10)
dropdown_corner.Parent = dropdown

local list_layout = Instance.new('UIListLayout')
list_layout.Parent = dropdown
list_layout.Padding = UDim.new(0, 3)

local function create_dropdown_button(text, player_or_nil, is_auto)
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(1, -8, 0, 22)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    btn.TextColor3 = Color3.fromRGB(240, 240, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = text
    btn.AutoButtonColor = true
    btn.Parent = dropdown

    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if is_auto then
            use_auto_target = true
            selected_target = nil
            selected_target_label = 'Auto (Más cercano)'
        else
            use_auto_target = false
            selected_target = player_or_nil
            selected_target_label = player_or_nil and player_or_nil.Name
                or 'Nadie'
        end
        target_button.Text = selected_target_label .. '  ▼'
        dropdown.Visible = false
    end)
end

local function rebuild_dropdown()
    dropdown.Visible = false
    for _, child in ipairs(dropdown:GetChildren()) do
        if child:IsA('TextButton') then
            child:Destroy()
        end
    end

    create_dropdown_button('Auto (Más cercano)', nil, true)

    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= local_player then
            create_dropdown_button(plr.Name, plr, false)
        end
    end
end

rebuild_dropdown()

players.PlayerAdded:Connect(rebuild_dropdown)
players.PlayerRemoving:Connect(function(plr)
    if selected_target == plr then
        selected_target = nil
        use_auto_target = true
        selected_target_label = 'Auto (Más cercano)'
        target_button.Text = selected_target_label .. '  ▼'
    end
    rebuild_dropdown()
end)

target_button.MouseButton1Click:Connect(function()
    dropdown.Visible = not dropdown.Visible
end)

-- === INFO TEXT ABAJO ===
local info_text = Instance.new('TextLabel')
info_text.Size = UDim2.new(1, -30, 0, 18)
info_text.Position = UDim2.new(0, 15, 1, -24)
info_text.BackgroundTransparency = 1
info_text.Text = 'Objetivo: '
    .. selected_target_label
    .. ' | Frames: '
    .. loops_por_frame
info_text.Font = Enum.Font.Gotham
info_text.TextSize = 13
info_text.TextColor3 = Color3.fromRGB(220, 220, 245)
info_text.TextXAlignment = Enum.TextXAlignment.Left
info_text.Parent = frame

local function update_info()
    info_text.Text = 'Objetivo: '
        .. selected_target_label
        .. ' | Frames: '
        .. loops_por_frame
end

-- === DRAG DE LA INTERFAZ (MISMO SISTEMA QUE TU PRIMER SCRIPT) ===
local dragging = false
local drag_input
local drag_start
local start_pos
local drag_threshold = 6

update_ = function(input)
    local delta = input.Position - drag_start
    frame.Position = UDim2.new(
        start_pos.X.Scale,
        start_pos.X.Offset + delta.X,
        start_pos.Y.Scale,
        start_pos.Y.Offset + delta.Y
    )
end

attach_ = function(handle)
    handle.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            drag_start = input.Position
            start_pos = frame.Position
            drag_input = nil

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            drag_input = input
        end
    end)
end

attach_(frame)
attach_(button)

local supp = false

user_input_service.InputChanged:Connect(function(input)
    if dragging and input == drag_input then
        if (input.Position - drag_start).Magnitude > drag_threshold then
            supp = true
        end
        update_(input)
    end
end)

-- === EQUIPAR AUTOMÁTICAMENTE LA LASER GUN CUANDO SE ACTIVA ===
local function equip_laser_gun()
    local char = local_player.Character
    if not char then
        return
    end

    local humanoid = char:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    -- buscar en el personaje o en la mochila
    local tool = char:FindFirstChild('Laser Gun')
        or local_player:FindFirstChildOfClass('Backpack')
            and local_player.Backpack:FindFirstChild('Laser Gun')

    if tool then
        humanoid:EquipTool(tool)
    end
end

-- === TOGGLE LAGGER ===
local function toggle_lagger()
    lagger_enabled = not lagger_enabled

    if lagger_enabled then
        button.Text = 'Pistola Láser\nACTIVA'
        button_gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 40, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 60, 100)),
        })

        -- ⭐ AQUÍ EQUIPAMOS EL ARMA AUTOMÁTICAMENTE ⭐
        equip_laser_gun()
    else
        button.Text = 'Pistola Láser\n[R] para activar'
        button_gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 110)),
        })
    end
end

button.MouseButton1Click:Connect(function()
    if supp then
        supp = false
        return
    end
    toggle_lagger()
end)

user_input_service.InputBegan:Connect(function(input, gp)
    if gp then
        return
    end
    if input.KeyCode == Enum.KeyCode.R then
        toggle_lagger()
    end
end)

close_btn.MouseButton1Click:Connect(function()
    lagger_enabled = false
    screen_gui:Destroy()
end)

-- === LÓGICA DE TARGET ===
local function get_nearest()
    local char = local_player.Character
    if not char or not char.PrimaryPart then
        return nil
    end

    local origin = char.PrimaryPart.Position
    local closest, dist = nil, math.huge

    for _, plr in ipairs(players:GetPlayers()) do
        if
            plr ~= local_player
            and plr.Character
            and plr.Character.PrimaryPart
        then
            local d = (origin - plr.Character.PrimaryPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = plr
            end
        end
    end

    return closest
end

local function get_target()
    if use_auto_target then
        return get_nearest()
    else
        if selected_target and players:FindFirstChild(selected_target.Name) then
            return selected_target
        else
            use_auto_target = true
            selected_target = nil
            selected_target_label = 'Auto (Más cercano)'
            target_button.Text = selected_target_label .. '  ▼'
            return get_nearest()
        end
    end
end

-- === LOOP PRINCIPAL ===
run_service.RenderStepped:Connect(function()
    local char = local_player.Character
    if not char then
        return
    end

    local tool = char:FindFirstChildOfClass('Tool')
    local equipped = tool and tool.Name == 'Laser Gun'

    if equipped ~= last_equipped then
        last_equipped = equipped
    end

    if not (lagger_enabled and equipped) then
        return
    end

    update_info()

    local target = get_target()
    if
        not target
        or not target.Character
        or not target.Character.PrimaryPart
    then
        return
    end

    local pos1 = char.PrimaryPart.Position
    local pos2 = target.Character.PrimaryPart.Position
    local dir = (pos2 - pos1).Unit

    for i = 1, loops_por_frame do
        local id = http_service:GenerateGUID(false):lower():gsub('%-', '')
        remote:FireServer(id, pos1, dir, workspace:GetServerTimeNow())
    end
end)
