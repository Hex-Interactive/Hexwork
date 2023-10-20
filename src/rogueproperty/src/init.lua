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
	self._min = nil
	self._max = nil

	if binding ~= nil then
		local bindingType = typeof(binding)

		if bindingType == "Instance" then
			self._binding = function(propName: string, propValue: Value)
				binding[propName] = propValue
			end
		elseif bindingType == "function" then
			self._binding = binding
		else
			error("unsupported binding type")
		end
	end

	self:_recompute()
	self.IsValid = true

	return self
end

function RogueProperty:SetBounds(min: number?, max: number?)
	if self._type ~= "number" then
		error("bounds are only supported for numbers")
	end

	self._min = min
	self._max = max
	self:_recompute()
end

function RogueProperty:_recompute()
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
	self._binding(self._name, value)
end

function RogueProperty:_addModifier(id: string, priority: number, map: (value: Value) -> Value)
	for _, modifier in self._modifiers do
		if modifier[1] == id then
			error(`modifier id "{id}" already used`)
		end
	end

	table.insert(self._modifiers, { id, priority, map })
	self:_recompute()
end

function RogueProperty:SetBaseValue(value: Value)
	self._baseValue = value
	self:_recompute()
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
			self:_recompute()
			return
		end
	end
end

function RogueProperty:ClearModifiers()
	for _, modifier in self._modifiers do
		table.clear(modifier)
	end
	table.clear(self._modifiers)
	self:_recompute()
end

function RogueProperty:Destroy()
	self:ClearModifiers()
	table.clear(self)
	setmetatable(self, nil)
end

return RogueProperty
