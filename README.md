# DX-UI

The DX-SR interface library for Roblox. One window, sidebar groups, tabs, sections and 14 animated elements, Lucide icons, themes, config saving, background images, glass mode that blurs the game behind the window, a privacy-blurred user card, custom cursor and mobile auto scale. The API follows WindUI.

Docs: https://hamaddddds.github.io/DX-UI/

## Loader

```lua
local DX = loadstring(game:HttpGet("https://raw.githubusercontent.com/hamaddddds/DX-UI/main/DX-UI.luau"))()
```

## Example

```lua
local Window = DX:CreateWindow({
    Title = "Example Hub",
    Author = "by you",
    Folder = "ExampleHub",
    Size = UDim2.fromOffset(700, 480),
    Background = "rbxassetid://136921327637425",
    Glass = true,
})

local Main = Window:Section({Title = "Main", Icon = "house"})
local Farm = Main:Tab({Title = "Farming", Icon = "sprout"})
Farm:Section({Title = "Auto Farm"})

Farm:Toggle({
    Title = "Auto Farm",
    Flag = "AutoFarm",
    Callback = function(state)
        print(state)
    end,
})

DX:Notify({Title = "DX-UI", Content = "Loaded.", Type = "Success"})
```
