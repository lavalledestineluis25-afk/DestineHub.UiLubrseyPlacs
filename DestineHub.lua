   Usage: local Lib = loadstring(game:HttpGet("..."))() or require(script.FatalityLib)
--]]

local FatalityLib = {}
FatalityLib.__index = FatalityLib

-- ============================================================
-- SERVICES
-- ============================================================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    -- Backgrounds
    BG_DARK      = Color3.fromRGB(13, 13, 18),
    BG_PANEL     = Color3.fromRGB(18, 18, 26),
    BG_SECTION   = Color3.fromRGB(22, 22, 32),
    BG_ELEMENT   = Color3.fromRGB(28, 28, 40),
    BG_HOVER     = Color3.fromRGB(35, 35, 52),

    -- Accent (FATALITY pink-red)
    ACCENT       = Color3.fromRGB(220, 60, 100),
    ACCENT_DARK  = Color3.fromRGB(160, 30, 65),
    ACCENT_GLOW  = Color3.fromRGB(255, 80, 120),

    -- Text
    TEXT_PRIMARY = Color3.fromRGB(235, 235, 245),
    TEXT_SECONDARY = Color3.fromRGB(155, 155, 175),
    TEXT_MUTED   = Color3.fromRGB(90, 90, 115),
    TEXT_ACCENT  = Color3.fromRGB(220, 60, 100),

    -- Borders & Dividers
    BORDER       = Color3.fromRGB(45, 45, 65),
    BORDER_GLOW  = Color3.fromRGB(220, 60, 100),

    -- Slider fill
    SLIDER_FILL  = Color3.fromRGB(220, 60, 100),
    SLIDER_BG    = Color3.fromRGB(35, 35, 50),

    -- Toggle
    TOGGLE_ON    = Color3.fromRGB(220, 60, 100),
    TOGGLE_OFF   = Color3.fromRGB(45, 45, 65),

    -- Tab
    TAB_ACTIVE   = Color3.fromRGB(220, 60, 100),
    TAB_INACTIVE = Color3.fromRGB(55, 55, 75),
    TAB_TEXT_ON  = Color3.fromRGB(255, 255, 255),
    TAB_TEXT_OFF = Color3.fromRGB(140, 140, 165),
}

-- ============================================================
-- UTILITY
-- ============================================================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(inst, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ============================================================
-- PARTICLE SYSTEM (Title area floating sparkles)
-- ============================================================
local function SpawnParticles(parent, accentColor)
    -- We'll spawn small Frame "sparks" that float upward and fade
    local function spawnOne()
        local size = math.random(2, 5)
        local startX = math.random(5, parent.AbsoluteSize.X - 5)
        local p = Create("Frame", {
            Parent = parent,
            BackgroundColor3 = accentColor or Theme.ACCENT_GLOW,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.new(0, startX, 1, 0),
            ZIndex = 20,
            BackgroundTransparency = 0.2,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) })
        })
        -- Add a glow UIStroke
        local stroke = Create("UIStroke", {
            Parent = p,
            Color = accentColor or Theme.ACCENT_GLOW,
            Thickness = 1,
            Transparency = 0.3,
        })
        local endY = -(math.random(30, 80))
        local drift = math.random(-30, 30)
        Tween(p, {
            Position = UDim2.new(0, startX + drift, 0, endY),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(size * 0.5, size * 0.5),
        }, math.random(12, 25) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Tween(stroke, { Transparency = 1 }, math.random(12, 25) / 10)
        task.delay(2.5, function()
            if p and p.Parent then p:Destroy() end
        end)
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not parent or not parent.Parent then
            conn:Disconnect()
            return
        end
        if math.random(1, 4) == 1 then
            spawnOne()
        end
    end)
    return conn
end

-- ============================================================
-- GLOW EFFECT (UIStroke pulse)
-- ============================================================
local function PulseGlow(uistroke, color)
    task.spawn(function()
        local t = 0
        while uistroke and uistroke.Parent do
            t = t + 0.05
            local alpha = (math.sin(t * 2) + 1) / 2  -- 0..1
            local brightness = 0.3 + alpha * 0.5
            uistroke.Color = color:Lerp(Color3.new(1,1,1), brightness * 0.2)
            uistroke.Thickness = 1.5 + alpha * 1.5
            task.wait(0.03)
        end
    end)
end

-- ============================================================
-- SCROLLING FRAME HELPER
-- ============================================================
local function MakeScrollFrame(parent, size, position)
    local sf = Create("ScrollingFrame", {
        Parent = parent,
        Size = size,
        Position = position or UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.ACCENT,
        ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
    })
    Create("UIPadding", {
        Parent = sf,
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    })
    Create("UIListLayout", {
        Parent = sf,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })
    return sf
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotifContainer
local function EnsureNotifContainer()
    if NotifContainer and NotifContainer.Parent then return end
    local sg = Create("ScreenGui", {
        Name = "FatalityNotifs",
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    NotifContainer = Create("Frame", {
        Parent = sg,
        Size = UDim2.fromOffset(300, 0),
        Position = UDim2.new(1, -310, 1, -10),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 6),
        })
    })
end

function FatalityLib:Notify(opts)
    opts = opts or {}
    EnsureNotifContainer()
    local title    = opts.Title or "FatalityLib"
    local text     = opts.Text or ""
    local duration = opts.Duration or 3
    local color    = opts.Color or Theme.ACCENT

    local card = Create("Frame", {
        Parent = NotifContainer,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Theme.BG_PANEL,
        BorderSizePixel = 0,
        BackgroundTransparency = 0,
        ClipsDescendants = true,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", {
            Color = color,
            Thickness = 1,
            Transparency = 0.4,
        }),
        -- Accent bar left
        Create("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        }, { Create("UICorner", { CornerRadius = UDim.new(0,3) }) }),
        Create("TextLabel", {
            Text = title,
            Position = UDim2.new(0, 12, 0, 6),
            Size = UDim2.new(1, -16, 0, 20),
            BackgroundTransparency = 1,
            TextColor3 = color,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Create("TextLabel", {
            Text = text,
            Position = UDim2.new(0, 12, 0, 28),
            Size = UDim2.new(1, -16, 0, 26),
            BackgroundTransparency = 1,
            TextColor3 = Theme.TEXT_SECONDARY,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        }),
    })

    -- Slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back)

    task.delay(duration, function()
        Tween(card, { Position = UDim2.new(1, 10, 0, 0), BackgroundTransparency = 1 }, 0.3)
        task.delay(0.35, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

-- ============================================================
-- WINDOW
-- ============================================================
function FatalityLib:CreateWindow(opts)
    opts = opts or {}
    local winTitle  = opts.Title or "FatalityLib"
    local winSize   = opts.Size or UDim2.fromOffset(720, 440)
    local showLoader = opts.Loader ~= false
    local accentColor = opts.AccentColor or Theme.ACCENT

    -- Root ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "FatalityUI_" .. winTitle,
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    -- Main Window Frame
    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        Name = "MainFrame",
        Size = winSize,
        Position = UDim2.new(0.5, -winSize.X.Offset/2, 0.5, -winSize.Y.Offset/2),
        BackgroundColor3 = Theme.BG_DARK,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    })

    -- Outer glow (drop shadow simulation)
    local OuterGlow = Create("ImageLabel", {
        Parent = MainFrame,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",  -- standard radial gradient
        ImageColor3 = accentColor,
        ImageTransparency = 0.75,
        ZIndex = -1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
    })

    -- Window border stroke
    local WinStroke = Create("UIStroke", {
        Parent = MainFrame,
        Color = Theme.BORDER,
        Thickness = 1,
        Transparency = 0.2,
    })

    -- -------------------------------------------------------
    -- TITLEBAR
    -- -------------------------------------------------------
    local TitleBar = Create("Frame", {
        Parent = MainFrame,
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.BG_PANEL,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        -- Bottom crop fix
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 1, -8),
            BackgroundColor3 = Theme.BG_PANEL,
            BorderSizePixel = 0,
            ZIndex = 10,
        }),
    })

    -- Bottom border line under titlebar
    Create("Frame", {
        Parent = TitleBar,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.BORDER,
        BorderSizePixel = 0,
        ZIndex = 11,
    })

    -- Title glow line
    local TitleGlowLine = Create("Frame", {
        Parent = TitleBar,
        Size = UDim2.new(0.4, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    -- Animate the glow line
    task.spawn(function()
        while TitleGlowLine and TitleGlowLine.Parent do
            Tween(TitleGlowLine, { Size = UDim2.new(0.7, 0, 0, 2), BackgroundTransparency = 0 }, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
            Tween(TitleGlowLine, { Size = UDim2.new(0.2, 0, 0, 2), BackgroundTransparency = 0.4 }, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
        end
    end)

    -- Title Text (BIG + GLOW)
    local TitleLabel = Create("TextLabel", {
        Parent = TitleBar,
        Text = winTitle:upper(),
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    })

    -- Title UIStroke glow pulse
    local TitleStroke = Create("UIStroke", {
        Parent = TitleLabel,
        Color = accentColor,
        Thickness = 0.5,
        Transparency = 0.3,
    })
    PulseGlow(TitleStroke, accentColor)

    -- Spawn particles in titlebar
    SpawnParticles(TitleBar, accentColor)

    -- Accent dot before title
    Create("Frame", {
        Parent = TitleBar,
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(0, 6, 0.5, -3),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 15,
    }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    -- Close Button
    local CloseBtn = Create("TextButton", {
        Parent = TitleBar,
        Text = "×",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -36, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(180, 40, 70),
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, { Create("UICorner", { CornerRadius = UDim.new(0,5) }) })
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.fromOffset(winSize.X.Offset, 0), BackgroundTransparency = 1 }, 0.2)
        task.delay(0.25, function() ScreenGui:Destroy() end)
    end)

    -- Minimize Button
    local MinBtn = Create("TextButton", {
        Parent = TitleBar,
        Text = "─",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -68, 0.5, -14),
        BackgroundColor3 = Theme.BG_ELEMENT,
        TextColor3 = Theme.TEXT_SECONDARY,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, { Create("UICorner", { CornerRadius = UDim.new(0,5) }) })

    local minimized = false
    local ContentFrameRef -- will be set later
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, { Size = UDim2.fromOffset(winSize.X.Offset, 52) }, 0.2)
        else
            Tween(MainFrame, { Size = winSize }, 0.2)
        end
    end)

    -- Make draggable
    MakeDraggable(MainFrame, TitleBar)

    -- -------------------------------------------------------
    -- TAB BAR
    -- -------------------------------------------------------
    local TabBar = Create("Frame", {
        Parent = MainFrame,
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundColor3 = Theme.BG_PANEL,
        BorderSizePixel = 0,
        ZIndex = 9,
        ClipsDescendants = true,
    })
    Create("Frame", {
        Parent = TabBar,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.BORDER,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    local TabBarLayout = Create("UIListLayout", {
        Parent = TabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    })
    Create("UIPadding", {
        Parent = TabBar,
        PaddingLeft = UDim.new(0, 8),
    })

    -- -------------------------------------------------------
    -- CONTENT AREA
    -- -------------------------------------------------------
    local ContentArea = Create("Frame", {
        Parent = MainFrame,
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -88),
        Position = UDim2.new(0, 0, 0, 88),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 5,
    })
    ContentFrameRef = ContentArea

    -- Loader animation
    if showLoader then
        MainFrame.Size = UDim2.fromOffset(winSize.X.Offset, 0)
        Tween(MainFrame, { Size = winSize }, 0.4, Enum.EasingStyle.Back)
    end

    -- -------------------------------------------------------
    -- WINDOW OBJECT
    -- -------------------------------------------------------
    local Window = {}
    Window._tabs = {}
    Window._activeTab = nil
    Window._screenGui = ScreenGui
    Window._mainFrame = MainFrame
    Window._tabBar = TabBar
    Window._contentArea = ContentArea
    Window._accentColor = accentColor

    function Window:Toggle()
        MainFrame.Enabled = not MainFrame.Enabled
    end

    function Window:Destroy()
        ScreenGui:Destroy()
    end

    -- -------------------------------------------------------
    -- CREATE TAB
    -- -------------------------------------------------------
    function Window:CreateTab(name, tabOpts)
        tabOpts = tabOpts or {}
        local icon = tabOpts.Icon or ""

        -- Tab button
        local tabBtn = Create("TextButton", {
            Parent = TabBar,
            Name = "Tab_" .. name,
            Text = (icon ~= "" and icon .. "  " or "") .. name:upper(),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            TextColor3 = Theme.TAB_TEXT_OFF,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            BorderSizePixel = 0,
            ZIndex = 10,
        })
        Create("UIPadding", {
            Parent = tabBtn,
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
        })

        -- Active underline
        local Underline = Create("Frame", {
            Parent = tabBtn,
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 11,
        })

        -- Tab content frame (two-column layout)
        local TabContent = Create("Frame", {
            Parent = ContentArea,
            Name = "Content_" .. name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 5,
        })

        -- Left column
        local LeftColumn = Create("Frame", {
            Parent = TabContent,
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
        })
        local LeftScroll = MakeScrollFrame(LeftColumn, UDim2.new(1, 0, 1, 0))

        -- Right column
        local RightColumn = Create("Frame", {
            Parent = TabContent,
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
        })
        local RightScroll = MakeScrollFrame(RightColumn, UDim2.new(1, 0, 1, 0))

        local Tab = {}
        Tab._btn = tabBtn
        Tab._content = TabContent
        Tab._underline = Underline
        Tab._leftScroll = LeftScroll
        Tab._rightScroll = RightScroll
        Tab._sections = {}
        Tab._accentColor = accentColor

        -- Tab click
        tabBtn.MouseButton1Click:Connect(function()
            -- Deactivate all
            for _, t in pairs(Window._tabs) do
                t._content.Visible = false
                Tween(t._underline, { BackgroundTransparency = 1 }, 0.15)
                Tween(t._btn, { TextColor3 = Theme.TAB_TEXT_OFF }, 0.15)
            end
            -- Activate this
            TabContent.Visible = true
            Tween(Underline, { BackgroundTransparency = 0 }, 0.15)
            Tween(tabBtn, { TextColor3 = Theme.TAB_TEXT_ON }, 0.15)
            Window._activeTab = Tab
        end)

        -- Hover effect
        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(tabBtn, { TextColor3 = Theme.TEXT_PRIMARY }, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(tabBtn, { TextColor3 = Theme.TAB_TEXT_OFF }, 0.1)
            end
        end)

        table.insert(Window._tabs, Tab)

        -- Auto-activate first tab
        if #Window._tabs == 1 then
            TabContent.Visible = true
            Underline.BackgroundTransparency = 0
            tabBtn.TextColor3 = Theme.TAB_TEXT_ON
            Window._activeTab = Tab
        end

        -- =====================================================
        -- CREATE SECTION
        -- =====================================================
        function Tab:CreateSection(sectionName, sOpts)
            sOpts = sOpts or {}
            local side = sOpts.Side or "left"
            local defaultOpen = sOpts.DefaultOpen ~= false
            local parentScroll = side == "right" and RightScroll or LeftScroll

            -- Section container
            local Section = Create("Frame", {
                Parent = parentScroll,
                Name = "Section_" .. sectionName,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Theme.BG_SECTION,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Create("UIStroke", {
                    Color = Theme.BORDER,
                    Thickness = 1,
                    Transparency = 0.3,
                }),
            })

            -- Section header
            local Header = Create("TextButton", {
                Parent = Section,
                Text = "",
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                ZIndex = 6,
            })

            -- Accent left border
            Create("Frame", {
                Parent = Header,
                Size = UDim2.fromOffset(3, 18),
                Position = UDim2.new(0, 6, 0.5, -9),
                BackgroundColor3 = accentColor,
                BorderSizePixel = 0,
            }, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

            Create("TextLabel", {
                Parent = Header,
                Text = sectionName:upper(),
                Position = UDim2.new(0, 18, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.TEXT_ACCENT,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
            })

            -- Collapse arrow
            local Arrow = Create("TextLabel", {
                Parent = Header,
                Text = defaultOpen and "▾" or "▸",
                Position = UDim2.new(1, -22, 0, 0),
                Size = UDim2.fromOffset(20, 30),
                BackgroundTransparency = 1,
                TextColor3 = Theme.TEXT_MUTED,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                ZIndex = 6,
            })

            -- Content holder
            local ContentHolder = Create("Frame", {
                Parent = Section,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true,
                Visible = defaultOpen,
            }, {
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                }),
                Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 6),
                }),
            })

            -- Collapse toggle
            local isOpen = defaultOpen
            Header.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                ContentHolder.Visible = isOpen
                Arrow.Text = isOpen and "▾" or "▸"
            end)

            local SectionObj = {}
            SectionObj._content = ContentHolder
            SectionObj._accentColor = accentColor

            -- Helper: create row frame
            local function MakeRow(height)
                return Create("Frame", {
                    Parent = ContentHolder,
                    Size = UDim2.new(1, 0, 0, height or 30),
                    BackgroundColor3 = Theme.BG_ELEMENT,
                    BorderSizePixel = 0,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                })
            end

            -- =================================================
            -- BUTTON
            -- =================================================
            function SectionObj:CreateButton(bOpts)
                bOpts = bOpts or {}
                local row = MakeRow(28)
                local btn = Create("TextButton", {
                    Parent = row,
                    Text = bOpts.Name or "Button",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    ZIndex = 6,
                })
                -- Hover / click
                btn.MouseEnter:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_HOVER }, 0.1)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_ELEMENT }, 0.1)
                end)
                btn.MouseButton1Down:Connect(function()
                    Tween(row, { BackgroundColor3 = accentColor:Lerp(Theme.BG_ELEMENT, 0.7) }, 0.05)
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_HOVER }, 0.1)
                    if bOpts.Callback then bOpts.Callback() end
                end)

                -- Accent left indicator
                local bar = Create("Frame", {
                    Parent = row,
                    Size = UDim2.fromOffset(2, 14),
                    Position = UDim2.new(0, 3, 0.5, -7),
                    BackgroundColor3 = accentColor,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                }, { Create("UICorner", { CornerRadius = UDim.new(0,2) }) })

                btn.MouseEnter:Connect(function()
                    Tween(bar, { BackgroundTransparency = 0 }, 0.1)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(bar, { BackgroundTransparency = 0.5 }, 0.1)
                end)
            end

            -- =================================================
            -- TOGGLE
            -- =================================================
            function SectionObj:CreateToggle(tOpts)
                tOpts = tOpts or {}
                local state = tOpts.Default or false
                local row = MakeRow(28)

                Create("TextLabel", {
                    Parent = row,
                    Text = tOpts.Name or "Toggle",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                -- Track
                local track = Create("Frame", {
                    Parent = row,
                    Size = UDim2.fromOffset(32, 16),
                    Position = UDim2.new(1, -38, 0.5, -8),
                    BackgroundColor3 = state and Theme.TOGGLE_ON or Theme.TOGGLE_OFF,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                -- Knob
                local knob = Create("Frame", {
                    Parent = track,
                    Size = UDim2.fromOffset(12, 12),
                    Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0,
                    ZIndex = 8,
                }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                -- Glow on knob when active
                local knobStroke = Create("UIStroke", {
                    Parent = knob,
                    Color = accentColor,
                    Thickness = 1,
                    Transparency = state and 0.3 or 1,
                })

                local clickArea = Create("TextButton", {
                    Parent = row,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 9,
                })

                clickArea.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(track, { BackgroundColor3 = state and Theme.TOGGLE_ON or Theme.TOGGLE_OFF }, 0.15)
                    Tween(knob, { Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }, 0.15)
                    Tween(knobStroke, { Transparency = state and 0.3 or 1 }, 0.15)
                    if tOpts.Callback then tOpts.Callback(state) end
                end)

                row.MouseEnter:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_HOVER }, 0.1)
                end)
                row.MouseLeave:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_ELEMENT }, 0.1)
                end)

                return {
                    Set = function(_, v)
                        state = v
                        Tween(track, { BackgroundColor3 = state and Theme.TOGGLE_ON or Theme.TOGGLE_OFF }, 0.15)
                        Tween(knob, { Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }, 0.15)
                        if tOpts.Callback then tOpts.Callback(state) end
                    end,
                    Get = function() return state end,
                }
            end

            -- =================================================
            -- SLIDER
            -- =================================================
            function SectionObj:CreateSlider(slOpts)
                slOpts = slOpts or {}
                local min     = slOpts.Min or 0
                local max     = slOpts.Max or 100
                local default = slOpts.Default or min
                local value   = default
                local suffix  = slOpts.Suffix or ""

                local row = MakeRow(42)

                -- Top row: name + value
                local nameLabel = Create("TextLabel", {
                    Parent = row,
                    Text = slOpts.Name or "Slider",
                    Position = UDim2.new(0, 10, 0, 3),
                    Size = UDim2.new(0.6, 0, 0, 16),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                local valLabel = Create("TextLabel", {
                    Parent = row,
                    Text = tostring(value) .. suffix,
                    Position = UDim2.new(0.6, 0, 0, 3),
                    Size = UDim2.new(0.35, 0, 0, 16),
                    BackgroundTransparency = 1,
                    TextColor3 = accentColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 6,
                })

                -- Track BG
                local trackBG = Create("Frame", {
                    Parent = row,
                    Size = UDim2.new(1, -20, 0, 5),
                    Position = UDim2.new(0, 10, 0, 28),
                    BackgroundColor3 = Theme.SLIDER_BG,
                    BorderSizePixel = 0,
                    ZIndex = 6,
                }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

                -- Fill
                local fillPercent = (value - min) / (max - min)
                local trackFill = Create("Frame", {
                    Parent = trackBG,
                    Size = UDim2.new(fillPercent, 0, 1, 0),
                    BackgroundColor3 = accentColor,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

                -- Knob
                local sKnob = Create("Frame", {
                    Parent = trackBG,
                    Size = UDim2.fromOffset(11, 11),
                    Position = UDim2.new(fillPercent, -5, 0.5, -5),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0,
                    ZIndex = 8,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1,0) }),
                    Create("UIStroke", { Color = accentColor, Thickness = 1.5, Transparency = 0.2 }),
                })

                -- Click area
                local sliderBtn = Create("TextButton", {
                    Parent = row,
                    Size = UDim2.new(1, -20, 0, 20),
                    Position = UDim2.new(0, 10, 0, 22),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 9,
                })

                local dragging = false

                local function update(input)
                    local relX = input.Position.X - trackBG.AbsolutePosition.X
                    local pct = math.clamp(relX / trackBG.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + pct * (max - min) + 0.5)
                    valLabel.Text = tostring(value) .. suffix
                    Tween(trackFill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.05)
                    Tween(sKnob, { Position = UDim2.new(pct, -5, 0.5, -5) }, 0.05)
                    if slOpts.Callback then slOpts.Callback(value) end
                end

                sliderBtn.MouseButton1Down:Connect(function()
                    dragging = true
                    update(UserInputService:GetMouseLocation() and { Position = UserInputService:GetMouseLocation() } or
                    { Position = Vector2.new(Mouse.X, Mouse.Y) })
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        update(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                row.MouseEnter:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_HOVER }, 0.1)
                end)
                row.MouseLeave:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_ELEMENT }, 0.1)
                end)

                return {
                    Set = function(_, v)
                        value = math.clamp(v, min, max)
                        local pct = (value - min) / (max - min)
                        valLabel.Text = tostring(value) .. suffix
                        trackFill.Size = UDim2.new(pct, 0, 1, 0)
                        sKnob.Position = UDim2.new(pct, -5, 0.5, -5)
                        if slOpts.Callback then slOpts.Callback(value) end
                    end,
                    Get = function() return value end,
                }
            end

            -- =================================================
            -- DROPDOWN
            -- =================================================
            function SectionObj:CreateDropdown(dOpts)
                dOpts = dOpts or {}
                local options = dOpts.Options or {}
                local selected = dOpts.Default or (options[1] or "")
                local isOpen = false

                local row = MakeRow(28)
                row.ClipsDescendants = false

                Create("TextLabel", {
                    Parent = row,
                    Text = dOpts.Name or "Dropdown",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                local selLabel = Create("TextLabel", {
                    Parent = row,
                    Text = selected,
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(0.45, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = accentColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 6,
                })

                local arrowLbl = Create("TextLabel", {
                    Parent = row,
                    Text = "▾",
                    Position = UDim2.new(1, -18, 0, 0),
                    Size = UDim2.fromOffset(16, 28),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_MUTED,
                    Font = Enum.Font.GothamBold,
                    TextSize = 9,
                    ZIndex = 6,
                })

                -- Dropdown list
                local listFrame = Create("Frame", {
                    Parent = row,
                    Size = UDim2.new(1, 0, 0, #options * 22 + 4),
                    Position = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3 = Theme.BG_PANEL,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 20,
                    ClipsDescendants = true,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    Create("UIStroke", { Color = Theme.BORDER, Thickness = 1, Transparency = 0.2 }),
                    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }),
                    Create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }),
                })

                for _, opt in ipairs(options) do
                    local optBtn = Create("TextButton", {
                        Parent = listFrame,
                        Text = opt,
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundTransparency = 1,
                        TextColor3 = opt == selected and accentColor or Theme.TEXT_SECONDARY,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        ZIndex = 21,
                    })
                    optBtn.MouseEnter:Connect(function()
                        Tween(optBtn, { TextColor3 = Theme.TEXT_PRIMARY }, 0.1)
                        Tween(optBtn, { BackgroundTransparency = 0.85 }, 0.1)
                        optBtn.BackgroundColor3 = accentColor
                    end)
                    optBtn.MouseLeave:Connect(function()
                        Tween(optBtn, { TextColor3 = opt == selected and accentColor or Theme.TEXT_SECONDARY }, 0.1)
                        Tween(optBtn, { BackgroundTransparency = 1 }, 0.1)
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        selLabel.Text = opt
                        isOpen = false
                        listFrame.Visible = false
                        arrowLbl.Text = "▾"
                        if dOpts.Callback then dOpts.Callback(opt) end
                        -- Refresh colors
                        for _, c in ipairs(listFrame:GetChildren()) do
                            if c:IsA("TextButton") then
                                c.TextColor3 = c.Text == selected and accentColor or Theme.TEXT_SECONDARY
                            end
                        end
                    end)
                end

                local toggleBtn = Create("TextButton", {
                    Parent = row,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 8,
                })
                toggleBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    listFrame.Visible = isOpen
                    arrowLbl.Text = isOpen and "▴" or "▾"
                end)

                row.MouseEnter:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_HOVER }, 0.1)
                end)
                row.MouseLeave:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.BG_ELEMENT }, 0.1)
                end)

                return {
                    Set = function(_, v)
                        selected = v
                        selLabel.Text = v
                        if dOpts.Callback then dOpts.Callback(v) end
                    end,
                    Get = function() return selected end,
                }
            end

            -- =================================================
            -- TEXTBOX
            -- =================================================
            function SectionObj:CreateTextbox(txOpts)
                txOpts = txOpts or {}
                local row = MakeRow(28)

                Create("TextLabel", {
                    Parent = row,
                    Text = txOpts.Name or "Input",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.4, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                local inputBox = Create("TextBox", {
                    Parent = row,
                    Text = txOpts.Default or "",
                    PlaceholderText = txOpts.Placeholder or "...",
                    PlaceholderColor3 = Theme.TEXT_MUTED,
                    Position = UDim2.new(0.42, 0, 0.15, 0),
                    Size = UDim2.new(0.54, 0, 0.7, 0),
                    BackgroundColor3 = Theme.BG_DARK,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                    ClearTextOnFocus = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    Create("UIStroke", { Color = Theme.BORDER, Thickness = 1, Transparency = 0.3 }),
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
                })

                inputBox.Focused:Connect(function()
                    Tween(inputBox:FindFirstChildOfClass("UIStroke"), { Color = accentColor, Transparency = 0 }, 0.15)
                end)
                inputBox.FocusLost:Connect(function(enter)
                    Tween(inputBox:FindFirstChildOfClass("UIStroke"), { Color = Theme.BORDER, Transparency = 0.3 }, 0.15)
                    if txOpts.Callback then txOpts.Callback(inputBox.Text, enter) end
                end)
            end

            -- =================================================
            -- KEYBIND
            -- =================================================
            function SectionObj:CreateKeybind(kOpts)
                kOpts = kOpts or {}
                local currentKey = kOpts.Default or Enum.KeyCode.RightShift
                local listening = false

                local row = MakeRow(28)

                Create("TextLabel", {
                    Parent = row,
                    Text = kOpts.Name or "Keybind",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.55, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                local keyLabel = Create("TextButton", {
                    Parent = row,
                    Text = "[" .. currentKey.Name .. "]",
                    Position = UDim2.new(0.58, 0, 0.15, 0),
                    Size = UDim2.new(0.38, 0, 0.7, 0),
                    BackgroundColor3 = Theme.BG_DARK,
                    TextColor3 = accentColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    Create("UIStroke", { Color = Theme.BORDER, Thickness = 1, Transparency = 0.3 }),
                })

                keyLabel.MouseButton1Click:Connect(function()
                    listening = true
                    keyLabel.Text = "[...]"
                    Tween(keyLabel:FindFirstChildOfClass("UIStroke"), { Color = accentColor, Transparency = 0 }, 0.1)
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if listening and not gp and input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        listening = false
                        keyLabel.Text = "[" .. currentKey.Name .. "]"
                        Tween(keyLabel:FindFirstChildOfClass("UIStroke"), { Color = Theme.BORDER, Transparency = 0.3 }, 0.1)
                    elseif not listening and input.KeyCode == currentKey then
                        if kOpts.Callback then kOpts.Callback() end
                    end
                end)
            end

            -- =================================================
            -- COLOR PICKER
            -- =================================================
            function SectionObj:CreateColorPicker(cpOpts)
                cpOpts = cpOpts or {}
                local currentColor = cpOpts.Default or Color3.fromRGB(255, 0, 0)

                local row = MakeRow(28)
                row.ClipsDescendants = false

                Create("TextLabel", {
                    Parent = row,
                    Text = cpOpts.Name or "Color",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                local swatch = Create("TextButton", {
                    Parent = row,
                    Text = "",
                    Size = UDim2.fromOffset(40, 18),
                    Position = UDim2.new(1, -46, 0.5, -9),
                    BackgroundColor3 = currentColor,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    Create("UIStroke", { Color = Theme.BORDER, Thickness = 1 }),
                })

                -- Simple HSV picker popup
                local pickerOpen = false
                local picker = Create("Frame", {
                    Parent = row,
                    Size = UDim2.fromOffset(160, 110),
                    Position = UDim2.new(1, -165, 1, 4),
                    BackgroundColor3 = Theme.BG_PANEL,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 30,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Create("UIStroke", { Color = accentColor, Thickness = 1, Transparency = 0.3 }),
                })

                -- R/G/B sliders in picker (simplified)
                local channels = { {name="R", key="r"}, {name="G", key="g"}, {name="B", key="b"} }
                local rgb = { r = math.floor(currentColor.R * 255), g = math.floor(currentColor.G * 255), b = math.floor(currentColor.B * 255) }

                local pickerLayout = Create("UIListLayout", { Parent = picker, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
                Create("UIPadding", { Parent = picker, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) })

                local function rebuildColor()
                    currentColor = Color3.fromRGB(rgb.r, rgb.g, rgb.b)
                    swatch.BackgroundColor3 = currentColor
                    if cpOpts.Callback then cpOpts.Callback(currentColor) end
                end

                for _, ch in ipairs(channels) do
                    local chRow = Create("Frame", { Parent = picker, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
                    Create("TextLabel", { Parent = chRow, Text = ch.name, Position = UDim2.new(0,0,0,0), Size = UDim2.fromOffset(12, 24), BackgroundTransparency = 1, TextColor3 = Theme.TEXT_SECONDARY, Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 31 })
                    local chBG = Create("Frame", { Parent = chRow, Size = UDim2.new(1, -36, 0, 5), Position = UDim2.new(0, 16, 0.5, -2), BackgroundColor3 = Theme.SLIDER_BG, BorderSizePixel = 0, ZIndex = 31 }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
                    local pct = rgb[ch.key] / 255
                    local chFill = Create("Frame", { Parent = chBG, Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = accentColor, BorderSizePixel = 0, ZIndex = 32 }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
                    local chVal = Create("TextLabel", { Parent = chRow, Text = tostring(rgb[ch.key]), Position = UDim2.new(1, -18, 0, 0), Size = UDim2.fromOffset(18, 24), BackgroundTransparency = 1, TextColor3 = Theme.TEXT_SECONDARY, Font = Enum.Font.GothamBold, TextSize = 9, ZIndex = 31 })
                    local chBtn = Create("TextButton", { Parent = chRow, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1, Text = "", ZIndex = 33 })
                    local chDrag = false
                    chBtn.MouseButton1Down:Connect(function() chDrag = true end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if chDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                            local p = math.clamp((inp.Position.X - chBG.AbsolutePosition.X) / chBG.AbsoluteSize.X, 0, 1)
                            rgb[ch.key] = math.floor(p * 255)
                            chFill.Size = UDim2.new(p, 0, 1, 0)
                            chVal.Text = tostring(rgb[ch.key])
                            rebuildColor()
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then chDrag = false end
                    end)
                end

                swatch.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    picker.Visible = pickerOpen
                end)
            end

            -- =================================================
            -- LABEL
            -- =================================================
            function SectionObj:CreateLabel(lOpts)
                lOpts = lOpts or {}
                local row = MakeRow(22)
                row.BackgroundTransparency = 1
                Create("TextLabel", {
                    Parent = row,
                    Text = lOpts.Text or "",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -10, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = lOpts.Color or Theme.TEXT_MUTED,
                    Font = lOpts.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
                    TextSize = lOpts.Size or 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })
            end

            -- =================================================
            -- SEPARATOR
            -- =================================================
            function SectionObj:CreateSeparator()
                local sep = Create("Frame", {
                    Parent = ContentHolder,
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Theme.BORDER,
                    BorderSizePixel = 0,
                })
            end

            -- =================================================
            -- IMAGE BUTTON (image support)
            -- =================================================
            function SectionObj:CreateImageButton(imgOpts)
                imgOpts = imgOpts or {}
                local row = MakeRow(42)

                -- Image preview
                if imgOpts.Image then
                    Create("ImageLabel", {
                        Parent = row,
                        Image = imgOpts.Image,
                        Size = UDim2.fromOffset(32, 32),
                        Position = UDim2.new(0, 5, 0.5, -16),
                        BackgroundTransparency = 1,
                        ZIndex = 6,
                    }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                end

                local xOff = imgOpts.Image and 44 or 10
                Create("TextLabel", {
                    Parent = row,
                    Text = imgOpts.Name or "Image Button",
                    Position = UDim2.new(0, xOff, 0, 5),
                    Size = UDim2.new(1, -(xOff + 10), 0, 18),
                    BackgroundTransparency = 1,
                    TextColor3 = Theme.TEXT_PRIMARY,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })

                if imgOpts.Description then
                    Create("TextLabel", {
                        Parent = row,
                        Text = imgOpts.Description,
                        Position = UDim2.new(0, xOff, 0, 24),
                        Size = UDim2.new(1, -(xOff + 10), 0, 14),
                        BackgroundTransparency = 1,
                        TextColor3 = Theme.TEXT_MUTED,
                        Font = Enum.Font.Gotham,
                        TextSize = 9,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 6,
                    })
                end

                local btn = Create("TextButton", {
                    Parent = row,
                    Text = "",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 8,
                })
                btn.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.BG_HOVER }, 0.1) end)
                btn.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.BG_ELEMENT }, 0.1) end)
                btn.MouseButton1Click:Connect(function()
                    if imgOpts.Callback then imgOpts.Callback() end
                end)
            end

            return SectionObj
        end -- end CreateSection

        return Tab
    end -- end CreateTab

    return Window
end -- end CreateWindow

-- ============================================================
-- EXPOSE THEME FOR CUSTOMISATION
-- ============================================================
FatalityLib.Theme = Theme

return FatalityLib
