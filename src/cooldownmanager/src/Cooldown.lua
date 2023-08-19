local MAX = 9999
local NONE = 0

local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new()
	local self = setmetatable({}, Cooldown)
	self._list = {}
	return self
end

function Cooldown:Add(index: any, duration: number?)
	assert(self._list[index] == nil, `cooldown index "{index}" already exists`)

	local new = {
		Registered = os.clock(),
	}

	if duration then
		new.Duration = duration
	else
		new.Yielding = true
	end

	self._list[index] = new
end

function Cooldown:Update(index: any, duration: number?)
	local cooldown = self._list[index]
	if not cooldown then
		self:Add(index, duration)
		return
	end

	cooldown.Registered = os.clock()

	if duration then
		cooldown.Duration = duration
	else
		cooldown.Yielding = true
	end
end

function Cooldown:CanContinue(index: any): boolean
	local cooldown = self._list[index]

	if not cooldown then
		return true
	end

	if cooldown.Duration ~= nil then
		return cooldown.Registered + cooldown.Duration <= os.clock()
	elseif cooldown.Yielding ~= nil then
		return not cooldown.Yielding
	end

	return false
end

function Cooldown:GetTimeRemaining(index: any): number
	local cooldown = self._list[index]

	if not cooldown then
		return NONE
	end

	if cooldown.Duration then
		return math.max(cooldown.Registered + cooldown.Duration - os.clock(), NONE)
	end

	return MAX
end

function Cooldown:Cleanup()
	for index in self._list do
		if self:CanContinue(index) then
			table.clear(self._list[index])
			self._list[index] = nil
		end
	end
end

function Cooldown:Clear()
	for index in self._list do
		table.clear(self._list[index])
		self._list[index] = nil
	end
end

return Cooldown
