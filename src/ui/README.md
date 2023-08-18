# UI
Handles initialization and storage of prebuilt GUIs. **GUIs should be parented to a folder named "StarterGui" in ReplicatedStorage.** It is a best practice to spread your GUIs throughout multiple ScreenGuis and use the `UI.Get()` function to retrieve them throughout your UI code, which this module assumes is centralized.

## Example

This is the most basic example of how to utilize UI assuming the GUIs have been setup correctly:
```lua
-- Client script
local UI = require(path.to.UI)

UI.Init()

local mainGuis = UI.Get("Main")
mainGuis.TextLabel.Text = "Hello, world!"
mainGuis.TextLabel.Visible = true
```
Note that you don't need any `WaitForChild` calls on any of the GUI children.

# Documentation

## Global Methods

```lua
UI.Get()
```

**Description** <div>
Returns a loaded ScreenGui by the given name. Will error if no loaded GUI by the given name is found.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| name | string | | The name of the GUI to retrieve. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| GUI | ScreenGui | The GUI by the given name. |

---

```lua
UI.Init()
```

**Description** <div>
Initializes and loads all of the GUIs in the "StarterGui" folder in ReplicatedStorage. The StarterGui folder is emptied and deleted after initialization. Will error if there is a duplicate name in the StarterGui folder. The `ResetOnSpawn` property is set to `false` when a GUI is loaded.