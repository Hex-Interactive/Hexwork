local MAX = 9999
local NONE = 0

type Index = any
type Entry = {
	start: number,
	dur: number?,
	yield: boolean?
}

export type Cooldown = {
	__index: Cooldown,
	new: () -> Cooldown,

	_list: {[Index]: Entry},

	Add: (self: Cooldown, index: Index, duration: number?) -> (),
	Update: (self: Cooldown, index: Index, duration: number?) -> (),
	CanContinue: (self: Cooldown, index: Index) -> boolean,
	GetTimeRemaining: (self: Cooldown, index: Index) -> number,
	Cleanup: (self: Cooldown) -> (),
	Clear: (self: Cooldown) -> (),
}

local Cooldown = {} :: Cooldown
Cooldown.__index = Cooldown

function Cooldown.new(): Cooldown
	local self = (setmetatable({}, Cooldown) :: any) :: Cooldown
	self._list = {}
	return self
end

function Cooldown:Add(index: Index, duration: number?)
	assert(self._list[index] == nil, `cooldown index "{index}" already exists`)

	local new = {
		start = os.clock(),
	}

	if duration then
		new.dur = duration
	else
		new.yield = true
	end

	self._list[index] = new
end

function Cooldown:Update(index: Index, duration: number?)
	local cooldown = self._list[index]
	if not cooldown then
		self:Add(index, duration)
		return
	end

	cooldown.start = os.clock()

	if duration then
		cooldown.dur = duration
	else
		cooldown.yield = true
	end
end

function Cooldown:CanContinue(index: Index): boolean
	local cooldown = self._list[index]

	if not cooldown then
		return true
	end

	if cooldown.dur ~= nil then
		return cooldown.start + cooldown.dur <= os.clock()
	elseif cooldown.yield ~= nil then
		return not cooldown.yield
	end

	return false
end

function Cooldown:GetTimeRemaining(index: Index): number
	local cooldown = self._list[index]

	if not cooldown then
		return NONE
	end

	if cooldown.dur then
		return math.max(cooldown.start + cooldown.dur - os.clock(), NONE)
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
