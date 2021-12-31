local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new(length: number)
	return setmetatable({
		Length = length or 1,
		Data = {}
	}, Cooldown)
end

function Cooldown:Cleanup()
	for index: any in pairs(self.Data) do
		if not self:GetStatus(index) then
			self.Data[index] = nil
		end
	end
end

function Cooldown:GetStatus(key: any): (boolean, number)
	local lastUsed: number = self.Data[key] or 0
	local onCooldown: boolean = os.clock() - lastUsed <= self.Length

	return onCooldown, lastUsed
end

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