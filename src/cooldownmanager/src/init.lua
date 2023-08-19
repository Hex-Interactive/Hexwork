local Cooldown = require(script:WaitForChild("Cooldown"))

local cooldowns = {}

local CooldownManager = {}

function CooldownManager.Add(name: string): any
	assert(cooldowns[name] == nil, `cooldown "{name}" already exists`)

	local new = Cooldown.new()
	cooldowns[name] = new
	return new
end

function CooldownManager.Get(name: string): any
	assert(cooldowns[name], `unknown "{name}" cooldown`)
	return cooldowns[name]
end

function CooldownManager.Cleanup()
	for _, cooldown in cooldowns do
		cooldown:Cleanup()
	end
end

function CooldownManager.Clear()
	for _, cooldown in cooldowns do
		cooldown:Clear()
	end
end

return CooldownManager
