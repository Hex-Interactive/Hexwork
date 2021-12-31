# UI
A module responsible for handling initialization of prebuilt GUIs. GUIs should be parented to a folder named "StarterGui" in ReplicatedStorage. It is a best practice to spread your GUIs throughout multiple screen guis and use the `UI:GetUI()` function to retrieve them throughout your centralized UI code. The `ResetOnSpawn` property is set to `false` when a GUI is loaded.

# Documentation

## Global Methods

```lua
UI:OnLoad()
```

**Description** <div>
Connects the given callback to be called when the GUIs are loaded.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| callback | function | | The function to call on loaded. |

---

```lua
UI:GetGUI()
```

**Description** <div>
Returns a loaded ScreenGui by the given name.

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
UI:Init()
```

**Description** <div>
Initializes and loads all of the GUIs in the "StarterGui" folder in ReplicatedStorage. Also fires and cleans up OnLoad connections.