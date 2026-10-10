# DX-UI

The DX-SR interface library for Roblox. One window, sidebar groups, tabs, sections and 14 animated elements, Lucide icons, themes, config saving, glass mode and mobile auto scale.

## Loader

```lua
local DX = loadstring(game:HttpGet("https://raw.githubusercontent.com/hamaddddds/DX-UI/main/DX-UI.luau"))()
```

## Example

```lua
local Window = DX:CreateWindow({
    Title = "DX-SR Hub",
    Author = "Professional Hub",
    Folder = "DX-SR",
    Size = UDim2.fromOffset(700, 480),
})

local Main = Window:Section({Title = "Main", Icon = "house"})
local Farm = Main:Tab({Title = "Farming", Icon = "tractor"})
local Auto = Farm:Section({Title = "Auto Farm", Icon = "zap"})

Auto:Toggle({
    Title = "Auto Farm",
    Flag = "AutoFarm",
    Callback = function(state)
        print(state)
    end,
})

DX:Notify({Title = "DX-UI", Content = "Loaded.", Type = "Success"})
```
