local BaseCooldown = require(script:WaitForChild("BaseCooldown"))

local Cooldown = {}
local cooldowns = {}

function Cooldown:Add(name, ...)
	assert(typeof(name) == "string", "Bad name")
	assert(not cooldowns[name], "Duplicate name")
	cooldowns[name] = BaseCooldown.new(...)
	return cooldowns[name]
end

function Cooldown:Get(name)
	assert(cooldowns[name], "Bad name")
	return cooldowns[name]
end

return Cooldown