# Cooldown: a simple solution
Cooldown is my personal way of managing cooldowns of any type. It avoids using wait or any sort of yielding to provide performant results. On top of that, it uses a key based system for managing individual cooldowns under the main Cooldown class.

# Example

This is an example of how to utilize Cooldown:
```lua
local Players = game:GetService("Players")
local cooldown = Cooldown.new(5) -- Create a new cooldown of 5 seconds

part.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end
	
	cooldown:DoTask(player, function(onCooldown, timeLeft)
		if onCooldown then
			timeLeft = math.floor(timeLeft * 10) / 10 -- Format the time
			print("There are", timeLeft, "second(s) left!")
		else
			print("Activated!")
		end
	end)
end)
```
This will print "Activated!" whenever you touch "part" only every 5 seconds.

# Documentation

This is the detailed code documentation for Cooldown.

## Global Methods

```lua
Cooldown.new()
```

**Description** <div>
Creates and returns a new Cooldown object.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| length | number | 1 | The length in seconds for this Cooldown object. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| Cooldown | table | A new Cooldown object. |

---

## Cooldown Object

```lua
Cooldown:DoTask()
```

**Description** <div>
Completes a task based off a cooldown.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| key | any | | The key to use when managing a certain cooldown. |
| callback | function | | The function called, also known as the task. See the below for the arguments of the callback. |

**Callback Arguments**

| Name | Type | Description |
| --- | --- | --- |
| onCooldown | bool | A boolean representing if the specified key is on cooldown or not. |
| timeLeft | number | The amount of time in seconds the cooldown key has remaining. |

---

```lua
Cooldown:GetStatus()
```

**Description** <div>
Gets cooldown information about a certain key.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| key | any | | The key to retrieve cooldown information about. |

**Returns**

| Name | Type | Description |
| --- | --- | --- |
| onCooldown | bool | A boolean representing if the specified key is on cooldown or not. |
| lastUsed | number | The tick when the cooldown was last successful. |

---

```lua
Cooldown:Cleanup()
```

**Description** <div>
Cleans up any completed cooldowns. This is mostly useful for garbage collecting cooldowns where an instance would act as the key.