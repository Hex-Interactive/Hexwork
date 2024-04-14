export type Value = number | CFrame | Vector3

type FunctionalBinding = (name: string, value: Value) -> ()
type Binding = FunctionalBinding | Instance
type Map = (value: Value) -> Value
type Modifier = {
	id: string,
	pri: number,
	map: Map,
}

local RogueProperty = {}
local metatable = { __index = RogueProperty }
export type Identity = typeof(setmetatable(
	{} :: {
		_name: string,
		_baseValue: Value,
		_computedValue: Value,
		_type: string,
		_modifiers: { Modifier },
		_min: number?,
		_max: number?,
		_binding: FunctionalBinding?,
	},
	metatable
))

local function constructor(name: string, baseValue: Value, binding: Binding?): Identity
	local valueType = typeof(baseValue)
	if valueType ~= "number" and valueType ~= "CFrame" and valueType ~= "Vector3" then
		error(`unsupported value type "{valueType}"`, 2)
	end

	local self = setmetatable({}, metatable)

	self._name = name
	self._baseValue = baseValue
	self._computedValue = baseValue
	self._type = valueType
	self._modifiers = {}
	self._min = nil
	self._max = nil

	if binding ~= nil then
		local bindingType = typeof(binding)

		if bindingType == "Instance" then
			local instance = binding :: any -- Cast to allow dynamic property assign
			self._binding = function(propName: string, propValue: Value)
				instance[propName] = propValue
			end
		elseif bindingType == "function" then
			self._binding = binding :: FunctionalBinding
		else
			error(`unsupported binding type "{bindingType}"`, 2)
		end
	end

	self:_Recompute()

	return self
end

function RogueProperty._Recompute(self: Identity)
	table.sort(self._modifiers, function(a, b)
		return a.pri < b.pri
	end)

	local value = self._baseValue
	for _, modifier in self._modifiers do
		value = modifier.map(value)
	end

	if self._min and self._max then
		value = math.clamp(value :: number, self._min, self._max)
	elseif self._min then
		value = math.max(value :: number, self._min)
	elseif self._max then
		value = math.min(value :: number, self._max)
	end

	self._computedValue = value

	if self._binding then
		self._binding(self._name, value)
	end
end

function RogueProperty._AddModifier(self: Identity, id: string, priority: number, map: (value: Value) -> Value)
	for _, modifier in self._modifiers do
		if modifier.id == id then
			error(`modifier id "{id}" already used`, 2)
		end
	end

	table.insert(self._modifiers, {
		id = id,
		pri = priority,
		map = map,
	})

	self:_Recompute()
end

function RogueProperty._RemoveModifier(self: Identity, id: string, recompute: boolean?)
	for index, modifier in self._modifiers do
		if modifier.id == id then
			table.remove(self._modifiers, index)

			if recompute then
				self:_Recompute()
			end

			return
		end
	end
end

function RogueProperty.Get(self: Identity): Value
	return self._computedValue
end

function RogueProperty.GetBaseValue(self: Identity): Value
	return self._baseValue
end

function RogueProperty.SetBaseValue(self: Identity, value: Value)
	self._baseValue = value
	self:_Recompute()
end

function RogueProperty.SetBounds(self: Identity, min: number?, max: number?)
	if self._type ~= "number" then
		error("bounds are only supported for number value types", 2)
	end

	self._min = min
	self._max = max
	self:_Recompute()
end

function RogueProperty.CreateAdditiveModifier(self: Identity, id: string, amount: Value, priority: number?)
	if self._type == "CFrame" then
		error("additive modifiers are not supported with CFrame value types", 2)
	end

	self:_AddModifier(id, priority or 10, function(value: Value)
		return value :: any + amount
	end)
end

function RogueProperty.CreateMultiplierModifier(self: Identity, id: string, amount: Value, priority: number?)
	self:_AddModifier(id, priority or 20, function(value: Value)
		return value :: any * amount
	end)
end

function RogueProperty.CreateOverrideModifier(self: Identity, id: string, value: Value, priority: number?)
	self:_AddModifier(id, priority or 30, function()
		return value
	end)
end

function RogueProperty.RemoveModifier(self: Identity, id: string, recompute: boolean?)
	self:_RemoveModifier(id, recompute)
end

function RogueProperty.ClearModifiers(self: Identity)
	table.clear(self._modifiers)
	self:_Recompute()
end

function RogueProperty.Destroy(self: Identity)
	table.clear(self._modifiers)
	self._binding = nil
end

return {
	new = constructor,
}
