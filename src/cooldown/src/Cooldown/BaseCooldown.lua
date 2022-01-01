local BaseCooldown = {}
BaseCooldown.__index = BaseCooldown

function BaseCooldown.new(length)
	assert(typeof(length) == "number", "Bad length")

	return setmetatable({
		Length = length,
		Data = {}
	}, BaseCooldown)
end

function BaseCooldown:Cleanup()
	for index in pairs(self.Data) do
		if self:GetStatus(index) then
			self.Data[index] = nil
		end
	end
end

function BaseCooldown:GetStatus(key)
	assert(key ~= nil, "Bad key")

	local lastUsed = self.Data[key] or 0
	local canActivate = os.clock() - lastUsed > self.Length

	return canActivate, lastUsed
end

function BaseCooldown:DoTask(key, callback)
	assert(typeof(callback) == "function", "Bad callback")

	local now = os.clock()
	local canActivate, lastUsed = self:GetStatus(key)
	local timeLeft = lastUsed + self.Length - now

	if canActivate then
		self.Data[key] = now
	end

	callback(canActivate, timeLeft)
	self:Cleanup()
end

return BaseCooldown