--[[
	Possible future features:
	- Support for RogueProperty based base values and bounds
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

type Binding<T> = (value: T) -> ()
type Map<T> = (value: T) -> T

type Modifier<T> = {
	id: string,
	priority: number,
	map: Map<T>,
}

type ModifierInfo = {
	priority: number?,
}

type ModifierInfoAnimatable = ModifierInfo & {
	duration: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
}

type Config<T> = {
	binding: Binding<T>?,
	processor: Map<T>?,
	min: number?,
	max: number?,
}

local SUPPORTED_TYPES = {
	number = true,
	CFrame = true,
	Vector3 = true,
}

local RogueProperty = {}
local metatable = { __index = RogueProperty }
export type Identity<T> = typeof(setmetatable(
	{} :: {
		_baseValue: T,
		_computedValue: T,
		_type: string,
		_modifiers: { Modifier<T> },
		_animationAlphas: { [string]: number },
		_min: number?,
		_max: number?,
		_binding: Binding<T>?,
		_processor: Map<T>?,
	},
	metatable
))

local function getPriority(info: (ModifierInfo | ModifierInfoAnimatable)?, fallback: number): number
	return if info then info.priority or fallback else fallback
end

local function sortByPriority<T>(a: Modifier<T>, b: Modifier<T>)
	return a.priority < b.priority
end

local function constructor<T>(initialBase: T, config: Config<T>?): Identity<T>
	local propType = typeof(initialBase)
	if not SUPPORTED_TYPES[propType] then
		error(`unsupported prop type "{propType}"`, 2)
	end

	local self = setmetatable({}, metatable)

	self._baseValue = initialBase
	self._computedValue = initialBase
	self._type = propType
	self._modifiers = {}
	self._animationAlphas = {}
	self._min = nil
	self._max = nil

	if config then
		self._binding = config.binding
		self._processor = config.processor

		if config.min or config.max then
			self:_SetBounds(config.min, config.max)
		end
	end

	self:_Recompute()
	return self
end

function RogueProperty._Recompute<T>(self: Identity<T>)
	table.sort(self._modifiers, sortByPriority)

	local value = self._baseValue
	for _, modifier in self._modifiers do
		value = modifier.map(value)
	end

	if self._processor then
		value = self._processor(value)
	end

	if self._min and self._max then
		value = math.clamp(value :: any, self._min, self._max) :: any
	elseif self._min then
		value = math.max(value :: any, self._min) :: any
	elseif self._max then
		value = math.min(value :: any, self._max) :: any
	end

	self._computedValue = value

	if self._binding then
		self._binding(value)
	end
end

function RogueProperty._AddModifier<T>(self: Identity<T>, id: string, priority: number, map: Map<T>)
	for _, modifier in self._modifiers do
		if modifier.id == id then
			error(`modifier id "{id}" already used`, 3)
		end
	end

	table.insert(self._modifiers, {
		id = id,
		priority = priority,
		map = map,
	})

	self:_Recompute()
end

function RogueProperty._SetBounds<T>(self: Identity<T>, min: number?, max: number?)
	if self._type ~= "number" then
		error("bounds are only supported for number prop types", 3)
	end

	self._min = min
	self._max = max
end

function RogueProperty._Animate<T>(self: Identity<T>, id: string, info: ModifierInfoAnimatable)
	local duration = info.duration :: number
	local easingStyle = info.easingStyle or Enum.EasingStyle.Quad
	local easingDirection = info.easingDirection or Enum.EasingDirection.Out
	local timeElapsed = 0

	self._animationAlphas[id] = 0

	local conn: RBXScriptConnection? = nil
	local function cleanup()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end

	conn = RunService.Stepped:Connect(function(_, dt: number)
		if not self._animationAlphas[id] then
			cleanup()
			return
		end

		timeElapsed += dt

		if timeElapsed >= duration then
			self._animationAlphas[id] = 1
			self:_Recompute()
			cleanup()
			return
		end

		self._animationAlphas[id] = TweenService:GetValue(timeElapsed / duration, easingStyle, easingDirection)
		self:_Recompute()
	end)
end

--[[
	Returns the computed value.
]]
function RogueProperty.Get<T>(self: Identity<T>): T
	return self._computedValue
end

--[[
	Returns the base value.
]]
function RogueProperty.GetBase<T>(self: Identity<T>): T
	return self._baseValue
end

--[[
	Sets the base value.
]]
function RogueProperty.SetBase<T>(self: Identity<T>, value: T)
	self._baseValue = value
	self:_Recompute()
end

--[[
	Changes the bounds of the computed value. Will error if the RogueProperty is *not* the `number` type.
]]
function RogueProperty.ChangeBounds<T>(self: Identity<T>, min: number?, max: number?)
	self:_SetBounds(min, max)
	self:_Recompute()
end

--[[
	Creates an additive modifier with a default priority of `10`. Will error if the RogueProperty is the `CFrame` type.

	If a the `duration` field is supplied into the `info` parameter, the creation of the modifier can be animated.
]]
function RogueProperty.AdditiveModifier<T>(self: Identity<T>, id: string, value: T, info: ModifierInfoAnimatable?)
	if self._type == "CFrame" then
		error("additive modifiers are not supported with CFrame value types", 2)
	end

	if not info or not info.duration then
		self:_AddModifier(id, getPriority(info, 10), function(current)
			return (current :: any) + value
		end)

		return
	end

	self:_Animate(id, info)
	self:_AddModifier(id, getPriority(info, 10), function(current)
		return (current :: any) + (value :: any) * (self._animationAlphas[id] or 1)
	end)
end

--[[
	Creates a multiplier modifier with a default priority of `20`.

	If a the `duration` field is supplied into the `info` parameter, the creation of the modifier can be animated.
]]
function RogueProperty.MultiplierModifier<T>(self: Identity<T>, id: string, value: T, info: ModifierInfoAnimatable?)
	if not info or not info.duration then
		self:_AddModifier(id, getPriority(info, 20), function(current)
			return (current :: any) + value
		end)

		return
	end

	self:_Animate(id, info)
	self:_AddModifier(id, getPriority(info, 20), function(current)
		return (current :: any) * (value :: any) * (self._animationAlphas[id] or 1)
	end)
end

--[[
	Creates an override modifier with a default priority of `30`.
]]
function RogueProperty.OverrideModifier<T>(self: Identity<T>, id: string, value: T, info: ModifierInfo?)
	self:_AddModifier(id, getPriority(info, 30), function()
		return value
	end)
end

--[[
	Creates a custom modifier with a default priority of `40`.
]]
function RogueProperty.CustomModifier<T>(self: Identity<T>, id: string, map: Map<T>, info: ModifierInfo?)
	self:_AddModifier(id, getPriority(info, 40), map)
end

--[[
	Removes a modifier by id with an optional recompute, defaulting to `true`.
]]
function RogueProperty.RemoveModifier<T>(self: Identity<T>, id: string, recompute: boolean?)
	for index, modifier in self._modifiers do
		if modifier.id == id then
			self._animationAlphas[id] = nil
			table.remove(self._modifiers, index)

			if recompute == true then
				self:_Recompute()
			end

			return
		end
	end
end

--[[
	Clears all the modifiers.
]]
function RogueProperty.ClearModifiers<T>(self: Identity<T>)
	table.clear(self._animationAlphas)
	table.clear(self._modifiers)
	self:_Recompute()
end

--[[
	Permanently clears the configured binding. Primarily useful for "destroying" the RogueProperty, although it can be GC'd regardless.
]]
function RogueProperty.ClearBinding<T>(self: Identity<T>)
	self._binding = nil
end

return {
	new = constructor,
}
