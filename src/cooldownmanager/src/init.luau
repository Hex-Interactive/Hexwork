local Cooldown = require(script:WaitForChild("Cooldown"))

local cache = {}

local CooldownManager = {}

function CooldownManager.Add(name: string): Cooldown.Identity
	assert(cache[name] == nil, `cooldown "{name}" already exists`)
	local new = Cooldown.new()
	cache[name] = new
	return new
end

function CooldownManager.Get(name: string): Cooldown.Identity
	assert(cache[name], `unknown "{name}" cooldown`)
	return cache[name]
end

function CooldownManager.Cleanup()
	for _, cooldown in cache do
		cooldown:Cleanup()
	end
end

function CooldownManager.Clear()
	for _, cooldown in cache do
		cooldown:Clear()
	end
end

return CooldownManager
