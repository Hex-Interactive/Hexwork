export type Value = number | CFrame | Vector3

local RogueProperty = {}
RogueProperty.__index = RogueProperty

function RogueProperty.new(name: string, baseValue: Value, binding: ((name: string, value: Value) -> () | Instance)?)
	local self = setmetatable({}, RogueProperty)

	self._name = name
	self._baseValue = baseValue
	self._computedValue = baseValue
	self._type = typeof(baseValue)
	self._modifiers = {}
	self._fuzzIndex = 0
	self._min = nil
	self._max = nil

	local bindingType = typeof(binding)
	if bindingType == "Instance" then
		self._instance = binding
		self:Recompute()
	elseif bindingType == "function" then
		self._onChange = binding
		self:Recompute()
	end

	self.IsValid = true

	return self
end

function RogueProperty:SetBounds(min: number?, max: number?)
	if self._type ~= "number" then
		error("bounds are only supported for numbers")
	end

	self._min = min
	self._max = max
	self:Recompute()
end

function RogueProperty:Recompute()
	table.sort(self._modifiers, function(a, b)
		return a[2] < b[2]
	end)

	local value = self._baseValue
	for _, modifier in self._modifiers do
		value = modifier[3](value)
	end

	if self._min and self._max then
		value = math.clamp(value, self._min, self._max)
	elseif self._min then
		value = math.max(value, self._min)
	elseif self._max then
		value = math.min(value, self._max)
	end

	self._computedValue = value

	if self._instance then
		self._instance[self._name] = value
	elseif self._onChange then
		self._onChange(self._name, value)
	end
end

function RogueProperty:_addModifier(id: string, priority: number, map: (value: Value) -> Value)
	for _, modifier in self._modifiers do
		if modifier[1] == id then
			error(`modifier id "{id}" already used`)
		end
	end

	table.insert(self._modifiers, { id, priority, map })
	self:Recompute()
end

function RogueProperty:SetBaseValue(value: Value)
	self._baseValue = value
	self:Recompute()
end

function RogueProperty:GetBaseValue(): Value
	return self._baseValue
end

function RogueProperty:Get(): Value
	return self._computedValue
end

function RogueProperty:CreateAdditiveModifier(id: string, amount: Value, priority: number?)
	if self._type == "CFrame" then
		error("additive modifiers are not supported with CFrames")
	end

	self:_addModifier(id, priority or 10, function(value: Value)
		return value + amount
	end)
end

function RogueProperty:CreateMultiplierModifier(id: string, amount: Value, priority: number?)
	self:_addModifier(id, priority or 20, function(value: Value)
		return value * amount
	end)
end

function RogueProperty:CreateOverrideModifier(id: string, value: Value, priority: number?)
	self:_addModifier(id, priority or 30, function()
		return value
	end)
end

function RogueProperty:RemoveModifier(id: string)
	for index, modifier in self._modifiers do
		if modifier[1] == id then
			table.remove(self._modifiers, index)
			self:Recompute()
			return
		end
	end
end

function RogueProperty:ClearModifiers()
	for _, modifier in self._modifiers do
		table.clear(modifier)
	end
	table.clear(self._modifiers)

	self:Recompute()
end

function RogueProperty:Destroy()
	self:ClearModifiers()
	table.clear(self)

	setmetatable(self, nil)
end

return RogueProperty
