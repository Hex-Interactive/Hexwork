# Cleanup
A module to manage cleaning up data, such as instances. This is a good replacement for the [Debris](https://developer.roblox.com/en-us/api-reference/class/Debris) service.

# Documentation

## Global Methods

```lua
Cleanup:Schedule()
```

**Description** <div>
Schedules the descruction of an instance after a given time interval.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| instance | Instance | | The instance to clean up. |
| timeout | number | | The duration in seconds before cleaning up the instance. |