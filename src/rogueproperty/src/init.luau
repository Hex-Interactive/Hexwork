export type Value = number | CFrame | Vector3

type FunctionalBinding = (name: string, value: Value) -> ()
type Binding = FunctionalBinding | Instance
type Map = (value: Value) -> Value
type Modifier = {
	id: string,
	pri: number,
	map: Map
}

type RogueProperty = {
	__index: RogueProperty,
	new: (name: string, baseValue: Value, binding: Binding?) -> RogueProperty,
	Destroy: (self: RogueProperty) -> (),

	_name: string,
	_baseValue: Value,
	_computedValue: Value,
	_type: string,
	_modifiers: { Modifier },
	_min: number?,
	_max: number?,
	_binding: FunctionalBinding?,
	IsValid: boolean,

	_Recompute: (self: RogueProperty) -> (),
	_AddModifier: (self: RogueProperty, id: string, priority: number, map: (value: Value) -> Value) -> (),
	_RemoveModifier: (self: RogueProperty, id: string, callback: (() -> ())?) -> (),
	Get: (self: RogueProperty) -> Value,
	GetBaseValue: (self: RogueProperty) -> Value,
	SetBaseValue: (self: RogueProperty, value: Value) -> (),
	SetBounds: (self: RogueProperty, min: number?, max: number?) -> (),
	CreateAdditiveModifier: (self: RogueProperty,id: string, amount: Value, priority: number?) -> (),
	CreateMultiplierModifier: (self: RogueProperty,id: string, amount: Value, priority: number?) -> (),
	CreateOverrideModifier: (self: RogueProperty,id: string, value: Value, priority: number?) -> (),
	RemoveModifier: (self: RogueProperty,id: string) -> (),
	RemoveModifierClean: (self: RogueProperty,id: string) -> (),
	ClearModifiers: (self: RogueProperty) -> (),
}

local RogueProperty = {} :: RogueProperty
RogueProperty.__index = RogueProperty

function RogueProperty.new(name: string, baseValue: Value, binding: Binding?): RogueProperty
	local self = (setmetatable({}, RogueProperty) :: any) :: RogueProperty

	local valueType = typeof(baseValue)
	if valueType ~= "number" and valueType ~= "CFrame" and valueType ~= "Vector3" then
		error(`unsupported RogueProperty type "{valueType}"`)
	end

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
			error("unsupported binding type")
		end
	else
		self._binding = nil
	end

	self:_Recompute()
	self.IsValid = true

	return self
end

function RogueProperty:_Recompute()
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

function RogueProperty:_AddModifier(id: string, priority: number, map: (value: Value) -> Value)
	for _, modifier in self._modifiers do
		if modifier.id == id then
			error(`modifier id "{id}" already used`)
		end
	end

	table.insert(self._modifiers, {
		id = id,
		pri = priority,
		map = map
	})

	self:_Recompute()
end

function RogueProperty:_RemoveModifier(id: string, callback: (() -> ())?)
	for index, modifier in self._modifiers do
		if modifier.id == id then
			table.remove(self._modifiers, index)
			if callback then
				callback()
			end
			return
		end
	end
end

function RogueProperty:Get(): Value
	return self._computedValue
end

function RogueProperty:GetBaseValue(): Value
	return self._baseValue
end

function RogueProperty:SetBaseValue(value: Value)
	self._baseValue = value
	self:_Recompute()
end

function RogueProperty:SetBounds(min: number?, max: number?)
	if self._type ~= "number" then
		error("bounds are only supported for numbers")
	end

	self._min = min
	self._max = max
	self:_Recompute()
end

function RogueProperty:CreateAdditiveModifier(id: string, amount: Value, priority: number?)
	if self._type == "CFrame" then
		error("additive modifiers are not supported with CFrames")
	end

	self:_AddModifier(id, priority or 10, function(value: Value)
		return value :: any + amount
	end)
end

function RogueProperty:CreateMultiplierModifier(id: string, amount: Value, priority: number?)
	self:_AddModifier(id, priority or 20, function(value: Value)
		return value :: any * amount
	end)
end

function RogueProperty:CreateOverrideModifier(id: string, value: Value, priority: number?)
	self:_AddModifier(id, priority or 30, function()
		return value
	end)
end

function RogueProperty:RemoveModifier(id: string)
	self:_RemoveModifier(id, function()
		self:_Recompute()
	end)
end

function RogueProperty:RemoveModifierClean(id: string)
	self:_RemoveModifier(id)
end

function RogueProperty:ClearModifiers()
	table.clear(self._modifiers)
	self:_Recompute()
end

function RogueProperty:Destroy()
	self:ClearModifiers()
	table.clear(self)
	setmetatable(self, nil)
end

return RogueProperty
