# Cleanup

Handle cleaning up data of all sorts. This is a good replacement for the [Debris](https://developer.roblox.com/en-us/api-reference/class/Debris) service with additional features.

## ⚠️ DO NOT USE THIS FOR NEW WORK

This is an old package that is not recommended for new work. It is not available via Wally.

## Example

This is an example of how to utilize Cleanup:
```lua
local Cleanup = require(path.to.Cleanup)

local messyTable = {Junk = 3, Garbage = "abcd", Stuff = true}
print("Before:", messyTable) --> Before: {["Garbage"] = "abcd", ["Junk"] = 3, ["Stuff"] = true}
Cleanup:DestroyTable(messyTable)
print("After:", messyTable) --> After: {}

local tempPart = Instance.new("Part")
tempPart.Parent = workspace
Cleanup:ScheduleInstance(tempPart, 5)

```
Along with the output, you will see the created Part be destroyed after the time interval.

# Documentation

## Global Methods

```lua
Cleanup:ScheduleInstance()
```

**Description**

Schedules the destruction of an instance after a given time interval.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| instance | Instance | | The instance to clean up. |
| timeout | number | | The duration in seconds before cleaning up the instance. |

---

```lua
Cleanup:DestroyTable()
```

**Description**

Sets every index of the table to `nil` iterating with the `pairs()` iterator function. **IMPORTANT: Only use this if you have no intention of using the table again.** Otherwise, it is more efficent to call `table.clear()` with the table.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| targetTable | table | | The table to destroy. |