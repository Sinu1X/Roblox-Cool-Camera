local UIS = game:GetService("UserInputService")
local cam = workspace.CurrentCamera
local RS = game:GetService("RunService")
local pl = game.Players.LocalPlayer
local mouse = pl:GetMouse()
local module = require(game.ReplicatedStorage:WaitForChild("config"))
local gun1 = nil

local guic = pl:WaitForChild("PlayerGui")
local circle = guic:WaitForChild("Cursor"):WaitForChild("Circle")

local ciralpha = 0.5
local activealpha = 1

local retspd = 10
local vy, vx = 0, 0
local precision = 0.2
local friction = 10
local sens = 4

local deadz = 0.1
local cx = 0
local cy = 0

local bodyx = 0
local bodyDZ = 15

local lean = 0
local maxlean = 7
local leanspd = 0.1

local shakex = 0
local shakey = 0
local shakel = 0.15

local last = 0
local updateInterval = 0.1

cam.CameraType = Enum.CameraType.Scriptable

pl.CameraMaxZoomDistance = 0.5
pl.CameraMinZoomDistance = 0.5

UIS.MouseBehavior = Enum.MouseBehavior.Default
UIS.MouseIconEnabled = false

mouse.Button1Down:Connect(function()
	if gun1 then
		local ammo = gun1:GetAttribute("CurrentAmmo")
		if ammo <= 0 then return end
		
		task.wait(0.01)
		
		local fireMode = gun1:GetAttribute("FireMode") or "single"
		
		if fireMode == "burst" then
			for i = 1, 3 do
				if not gun1:GetAttribute("IsShooting") then break end
				local up, side = module.recoil(gun1)
				cy = math.clamp(cy + up, -75, 75)
				cx = cx + side
				shakey = shakey - (up * math.random(2,11))
				shakex = shakex - (up * math.random(2,11))
				task.wait(0.07)
			end
			task.wait(0.4)
		elseif fireMode == "single" then
			local up, side = module.recoil(gun1)
			cy = math.clamp(cy + up, -75, 75)
			cx = cx + side
			
			shakey = shakey - (up * math.random(2,11))
			shakex = shakex - (up * math.random(2,11))
		elseif fireMode == "auto" then

			while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and gun1:GetAttribute("IsShooting") and gun1:GetAttribute("CurrentAmmo") > 0 and gun1.Parent:IsA("Model") do
				local up, side = module.recoil(gun1)
				cy = math.clamp(cy + up, -75, 75)
				cx = cx + side
				shakey = shakey - (up * math.random(2,11))
				shakex = shakex - (up * math.random(2,11))
				task.wait(module.TIMEOUT[gun1])
			end
		end
	end
end)

RS.RenderStepped:Connect(function(dt)
	
	local char = pl.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	local delta = UIS:GetMouseDelta()
	
	vx += delta.X * sens * precision
	vy += delta.Y * sens * precision
	
	vx = math.clamp(vx, -180, 180)
	vy = math.clamp(vy, -180, 180)
	
	local rotspd = 1
	cx -= vx * dt * rotspd
	cy = math.clamp(cy - (vy * dt * rotspd), -75, 75)
	
	
	local move = 5
	local px,py=0,0
	
	if math.abs(vx) > move then
		px = (math.abs(vx) - move) * math.sign(vx)
	end
	if math.abs(vy) > move then
		py = (math.abs(vy) - move) * math.sign(vy)
	end
	
	local sensfac = 1
	cx -= (px*dt*sensfac)
	cy = cy - (py*dt*sensfac)
	cy = math.clamp(cy, -75,75)
	
	if delta.Magnitude < 0.1 then
		vx *= (1 - (friction * dt))
		vy *= (1 - (friction * dt))
	else
		vx = vx * (1 - (2 * dt))
		vy = vy * (1 - (2 * dt))
	end
	local dist = math.sqrt(vx^2 + vy^2)
	if dist > 5 then
		circle.ImageTransparency = circle.ImageTransparency + (0 - circle.ImageTransparency) * 0.2
	else
		circle.ImageTransparency = circle.ImageTransparency + (0.7 - circle.ImageTransparency) * 0.1
	end
	
	local targetlean = math.clamp(-vx / 20, -maxlean, maxlean)
	lean = lean + (targetlean - lean) * leanspd
	gun1 = module.findGun(pl.Character)
	
	
	local mpos = UIS:GetMouseLocation()
	local scrs = cam.ViewportSize
	local center = Vector2.new(scrs.X / 2, scrs.Y / 2)
	
	shakex = shakex * (1 - shakel)
	shakey = shakey * (1 - shakel)
	
	circle.Position = UDim2.fromOffset(center.X + vx + shakex, center.Y + vy + shakey)
	local rot = CFrame.Angles(0,math.rad(cx), 0) *
		CFrame.Angles(0,0, math.rad(lean)) *
		CFrame.Angles(math.rad(cy), 0, 0)
	cam.CFrame = CFrame.new(head.Position) * rot
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.LocalTransparencyModifier = 1
			end
		end
	end
	
	if tick() - last > 0.03 then
		last = tick()
		game.ReplicatedStorage.RotateEvent:FireServer(cx, cy)
	end
end)
