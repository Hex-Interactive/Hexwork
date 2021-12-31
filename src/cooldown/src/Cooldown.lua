local Cooldown = {}
Cooldown.__index = Cooldown

-- Create a new Cooldown object
function Cooldown.new(length: number)
	return setmetatable({
		Length = length or 1,
		Data = {}
	}, Cooldown)
end

-- Used to clean up any completed cooldowns
function Cooldown:Cleanup()
	for index: any in pairs(self.Data) do
		if not self:GetStatus(index) then
			self.Data[index] = nil
		end
	end
end

-- Used to get information about a certain key
function Cooldown:GetStatus(key: any): (boolean, number)
	local lastUsed: number = self.Data[key] or 0
	local onCooldown: boolean = os.clock() - lastUsed <= self.Length
	
	return onCooldown, lastUsed
end

-- Used to complete a task based off a cooldown
function Cooldown:DoTask(key: any, callback: (boolean?, number?) -> any)
	local now: number = os.clock()
	local onCooldown: boolean, lastUsed: number = self:GetStatus(key)
	local timeLeft: number = lastUsed + self.Length - now
	
	if not onCooldown then
		self.Data[key] = now
	end
	
	callback(onCooldown, timeLeft)
	self:Cleanup()
end

return Cooldown