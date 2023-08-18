# Cooldown
Manages singular or groups of cooldowns. It uses a key based system for managing individual cooldowns under a given BaseCooldown object. Calculations to determine if a cooldown is active are only done when you actually need to check if a key is on a cooldown. Using `wait()` or yielding is avoided to provide performant results.

**Important:** If you plan to only use one cooldown (a single BaseCooldown object), then there is no need to require the Cooldown module, only the BaseCooldown child module to directly use instead. However, it's still possible to use the main Cooldown module with only one BaseCooldown ever used. See the example code for this.

## Refactor Notice

This module is in need of refactoring and updates. At the moment, it is not recommended for new work.

## Example

This is an example of how to utilize Cooldown:
```lua
local Players = game:GetService("Players")
local Cooldown = require(path.to.Cooldown)

local partCooldown = Cooldown:Add("PartCooldown", 5) -- Create a new cooldown of 5 seconds

part.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end
	
	partCooldown:DoTask(player, function(canActivate, timeLeft)
		if canActivate then
			print("Activated!")
		else
			timeLeft = math.floor(timeLeft * 10) / 10 -- Format the time
			print("There are", timeLeft, "second(s) left!")
		end
	end)
end)
```
This will print "Activated!" whenever you touch "part" only every 5 seconds.

# Documentation

## Global Methods

```lua
Cooldown:Add()
```

**Description**

Creates a new BaseCooldown object to add to this Cooldown and returns it. Will error in the case of duplicate names.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| name | string | | The name for this BaseCooldown object in this Cooldown object. |
| length | number | | The length in seconds for the BaseCooldown object. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| BaseCooldown | table | The BaseCooldown object created. |

---

```lua
Cooldown:Get()
```

**Description**

Returns a stored BaseCooldown object by name. Will error if no BaseCooldown by the given name exists.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| name | string | | The name for the requested BaseCooldown object. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| BaseCooldown | table | The BaseCooldown object requested. |

## BaseCooldown Methods

```lua
BaseCooldown.new()
```

**Description**

Creates and returns a new BaseCooldown object.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| length | number | | The length in seconds for this BaseCooldown object. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| BaseCooldown | table | A new BaseCooldown object. |

---

```lua
BaseCooldown:DoTask()
```

**Description**

Completes a task based off a cooldown.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| key | any | | The key to use. |
| callback | function | | The task to complete. See the below for the arguments of the callback. |

**Callback Arguments**

| Name | Type | Description |
| --- | --- | --- |
| canActivate | bool | States whether the key is not on a cooldown. |
| timeLeft | number | The amount of time in seconds the cooldown key has remaining. |

---

```lua
BaseCooldown:GetStatus()
```

**Description**

Gets cooldown information about a certain key.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| key | any | | The key to retrieve cooldown information about. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| canActivate | bool | States whether the key is not on a cooldown. |
| lastUsed | number | The tick when the cooldown was last successful. |

---

```lua
BaseCooldown:Cleanup()
```

**Description**

Cleans up any completed cooldowns. This is mostly useful for garbage collecting cooldowns where an instance would act as the key. This is called internally at the end of a `BaseCooldown:DoTask()` call.