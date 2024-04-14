local MAX = 9999999
local NONE = 0

type Index = any
type Entry = {
	start: number,
	dur: number?,
	yield: boolean?,
}

local Cooldown = {}
local metatable = { __index = Cooldown }
export type Identity = typeof(setmetatable(
	{} :: {
		_list: { [Index]: Entry },
	},
	metatable
))

local function constructor(): Identity
	local self = setmetatable({}, metatable)

	self._list = {}

	return self
end

function Cooldown.Add(self: Identity, index: Index, duration: number?)
	-- assert(self._list[index] == nil, `cooldown index "{index}" already exists`)

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

function Cooldown.Update(self: Identity, index: Index, duration: number?)
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

function Cooldown.CanContinue(self: Identity, index: Index): boolean
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

function Cooldown.GetTimeRemaining(self: Identity, index: Index): number
	local cooldown = self._list[index]

	if not cooldown then
		return NONE
	end

	if cooldown.dur then
		return math.max(cooldown.start + cooldown.dur - os.clock(), NONE)
	end

	return MAX
end

function Cooldown.Cleanup(self: Identity)
	for index in self._list do
		if self:CanContinue(index) then
			table.clear(self._list[index])
			self._list[index] = nil
		end
	end
end

function Cooldown.Clear(self: Identity)
	for index in self._list do
		table.clear(self._list[index])
		self._list[index] = nil
	end
end

return {
	new = constructor,
}
