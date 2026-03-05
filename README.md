# Roblox FPS Camera

First-person camera controller with mouse and gamepad support. Handles sensitivity, pitch limits, and teleport detection.

## Installation

Copy `CameraController.luau` into your project.

## Usage

```lua
local CameraController = require(path.to.CameraController)

CameraController.setConfig({
    getSensitivity = function() return 1 end,
    getInvertY = function() return false end,
    eyeHeight = 1.6,
    pitchLimit = math.rad(85),
    teleportThreshold = 50,
})

RunService.RenderStepped:Connect(function()
    local root = character:FindFirstChild("HumanoidRootPart")
    local cf = CameraController.update(root, crouchOffset)
    if cf then
        camera.CFrame = cf
    end
end)
```

### On Character Spawn

```lua
CameraController.syncFromCharacter(root)
```

### On Death / Respawn

```lua
CameraController.reset()
```

## Config

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| getSensitivity | () -> number | 1 | Sensitivity multiplier |
| getInvertY | () -> boolean | false | Invert Y axis |
| eyeHeight | number | 1.6 | Camera height above root |
| pitchLimit | number | rad(85) | Max pitch angle |
| teleportThreshold | number | 50 | Distance to trigger re-sync |

## License

MIT
