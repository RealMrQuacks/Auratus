local ESP = {
    Enabled = false,
    TeamColor = false,

    BoxShift = CFrame.new(0,-1.5,0),
    BoxSize = Vector3.new(4,6,0),
    Color = Color3.fromRGB(255, 170, 0),

    Objects = setmetatable({}, {__mode="kv"}),
}

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")

--Functions--
local function Draw(obj, props)
    local new = Drawing.new(obj)

    props = props or {}
    for i,v in pairs(props) do
        new[i] = v
    end
    return new
end

function ESP:GetColor(obj)
    local player = Players:GetPlayerFromCharacter(obj)
    return player and self.TeamColor and player.Team and player.Team.TeamColor.Color or self.Color
end

function ESP:Toggle(bool)
    self.Enabled = bool
    if not bool then
        for _,v in pairs(self.Objects) do
            if v.Type == "Box" then
                for _,v in pairs(v.Components) do
                    v.Visible = false
                end
            end
        end
    end
end

local boxBase = {}
boxBase.__index = boxBase

function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for i,v in pairs(self.Components) do
        v.Visible = false
        v:Remove()
        self.Components[i] = nil
    end
end

function boxBase:Update()
    if not self.PrimaryPart then
        return self:Remove()
    end

    local cf = self.PrimaryPart.CFrame
    local locs = {
        TagPos = cf * ESP.BoxShift * CFrame.new(0,self.Size.Y/2,0),
    }

    local TagPos, Vis5 = Camera:WorldToViewportPoint(locs.TagPos.Position)

    if Vis5 and self.Visible ~= false then
        local color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color

        local character = self.Object.Parent

        self.Components.Name.Visible = true
        self.Components.Name.Position = Vector2.new(TagPos.X, TagPos.Y)
        self.Components.Name.Text = self.Name
        self.Components.Name.Color = color

        if self.Humanoid then
            self.Components.Distance.Visible = true
            self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
            self.Components.Distance.Text = string.format("[%s][%s]", math.floor((Camera.CFrame.Position - cf.Position).Magnitude), math.floor(self.Humanoid.Health).."/"..math.floor(self.Humanoid.MaxHealth))
            self.Components.Distance.Color = color
        else
            self.Components.Distance.Visible = false
        end

    else
        self.Components.Name.Visible = false
        self.Components.Distance.Visible = false
    end
end


function ESP:Add(obj, options)
    if not obj.Parent then
        return warn(obj, "has no parent")
    end

    if self.Objects[obj] then
        self.Objects[obj]:Remove()
    end

    local box = setmetatable({
        Name = options.Name or obj.Name,
        Type = "Box",
        Visible = options.Visible,
        Color = options.Color --[[or self:GetColor(obj)]],
        Size = options.Size or self.BoxSize,
        Object = obj,
        PrimaryPart = options.PrimaryPart or obj.ClassName == "Model" and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
        Components = {},
        ColorDynamic = options.ColorDynamic,
        Humanoid = obj:FindFirstChildWhichIsA("Humanoid"),
    }, boxBase)

    box.Components["Name"] = Draw("Text", {
        Text = box.Name,
        Color = box.Color,
        Center = true,
        Outline = true,
        Size = 19,
        Visible = self.Enabled
    })

    box.Components["Distance"] = Draw("Text", {
        Color = box.Color,
        Center = true,
        Outline = true,
        Size = 19,
        Visible = self.Enabled
    })

    self.Objects[obj] = box

    obj.AncestryChanged:Connect(function(_, parent)
        if not parent then
            box:Remove()
        end
    end)

    local Humanoid = obj:FindFirstChild("Humanoid") or obj:FindFirstChildWhichIsA("Humanoid")
    if Humanoid then
        Humanoid.Died:Connect(function()
            box:Remove()
        end)
    end

    return box
end

game:GetService("RunService").RenderStepped:Connect(function()
    for _,v in (ESP.Enabled and pairs or ipairs)(ESP.Objects) do
        if v.Update then
            local s,e = pcall(v.Update, v)
            if not s then warn("[EU]", e, v.Object:GetFullName()) end
        end
    end
end)

return ESP
