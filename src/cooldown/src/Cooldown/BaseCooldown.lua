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
	local canDoTask = os.clock() - lastUsed > self.Length

	return canDoTask, lastUsed
end

function BaseCooldown:DoTask(key, callback)
	assert(typeof(callback) == "function", "Bad callback")

	local now = os.clock()
	local canDoTask, lastUsed = self:GetStatus(key)
	local timeLeft = lastUsed + self.Length - now

	if canDoTask then
		self.Data[key] = now
	end

	callback(canDoTask, timeLeft)
	self:Cleanup()
end

return BaseCooldown