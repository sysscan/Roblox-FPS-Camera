local UserInputService = game:GetService("UserInputService")

local SENSITIVITY_SCALE = 0.2
local PIXEL_TO_DEGREE = 0.5
local PITCH_LIMIT = math.rad(85)
local TELEPORT_THRESHOLD = 50
local DEFAULT_EYE_HEIGHT = 1.6
local GAMEPAD_SENSITIVITY = 3

export type Config = {
	getSensitivity?: () -> number,
	getInvertY?: () -> boolean,
	eyeHeight?: number,
	pitchLimit?: number,
	teleportThreshold?: number,
}

local config: Config = {}
local cameraYaw = 0
local cameraPitch = 0
local lastRootCFrame: CFrame? = nil
local pendingDeltaX = 0
local pendingDeltaY = 0
local connections: { RBXScriptConnection } = {}

local function getSensitivity(): number
	if config.getSensitivity then
		return (config.getSensitivity() or 1) * SENSITIVITY_SCALE
	end
	return SENSITIVITY_SCALE
end

local function getInvertY(): boolean
	return config.getInvertY and config.getInvertY() or false
end

local function syncFromCharacter(root: BasePart)
	if not root then return end
	local look = root.CFrame.LookVector
	local flatMag = Vector3.new(look.X, 0, look.Z).Magnitude
	if flatMag < 0.01 then return end
	cameraYaw = math.atan2(look.X, -look.Z)
	cameraPitch = math.asin(math.clamp(look.Y, -1, 1))
	lastRootCFrame = root.CFrame
end

local function startCapture()
	if #connections > 0 then return end
	table.insert(connections, UserInputService.InputChanged:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			pendingDeltaX += input.Delta.X
			pendingDeltaY += input.Delta.Y
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
		if input.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
		local stick = input.Position
		pendingDeltaX += stick.X * GAMEPAD_SENSITIVITY
		pendingDeltaY += -stick.Y * GAMEPAD_SENSITIVITY
	end))
end

local function stopCapture()
	for _, conn in connections do
		conn:Disconnect()
	end
	table.clear(connections)
	pendingDeltaX = 0
	pendingDeltaY = 0
end

local function update(root: BasePart?, crouchOffset: number?): CFrame?
	if not root then return nil end
	startCapture()

	local rootPos = root.Position
	local threshold = config.teleportThreshold or TELEPORT_THRESHOLD
	if not lastRootCFrame or (rootPos - lastRootCFrame.Position).Magnitude > threshold then
		syncFromCharacter(root)
	end
	lastRootCFrame = root.CFrame

	local dx = pendingDeltaX
	local dy = pendingDeltaY
	pendingDeltaX = 0
	pendingDeltaY = 0

	local sens = getSensitivity()
	local pitchSign = getInvertY() and 1 or -1
	local pitchLimit = config.pitchLimit or PITCH_LIMIT
	cameraYaw -= math.rad(dx * PIXEL_TO_DEGREE * sens)
	cameraPitch += pitchSign * math.rad(dy * PIXEL_TO_DEGREE * sens)
	cameraPitch = math.clamp(cameraPitch, -pitchLimit, pitchLimit)

	local eyeHeight = (config.eyeHeight or DEFAULT_EYE_HEIGHT) + (crouchOffset or 0)
	local pos = rootPos + Vector3.new(0, eyeHeight, 0)
	local rot = CFrame.Angles(0, cameraYaw, 0) * CFrame.Angles(cameraPitch, 0, 0)
	return CFrame.new(pos) * rot
end

local function reset()
	lastRootCFrame = nil
	stopCapture()
end

local function destroy()
	reset()
	cameraYaw = 0
	cameraPitch = 0
end

local function setConfig(cfg: Config)
	config = cfg or {}
end

return {
	update = update,
	syncFromCharacter = syncFromCharacter,
	reset = reset,
	destroy = destroy,
	setConfig = setConfig,
	getYawPitch = function()
		return cameraYaw, cameraPitch
	end,
}
