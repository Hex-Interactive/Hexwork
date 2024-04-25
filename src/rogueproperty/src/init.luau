--[[
	Possible future features:
	- Support for RogueProperty-based bounds and base values
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

type Animatable = {
	duration: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
}

type ModifierInfo = {
	recompute: boolean?,
}

type ModifierCreationInfoAnimatable = ModifierCreationInfo & Animatable
type ModifierCreationInfo = ModifierInfo & {
	priority: number?,
}

type ModifierDestructionInfo = ModifierInfo & Animatable

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
		_modifiersNeedSorted: boolean,
		_min: number?,
		_max: number?,
		_binding: Binding<T>?,
		_processor: Map<T>?,
	},
	metatable
))

local function getPriority(info: ModifierCreationInfo?, fallback: number): number
	return if info then info.priority or fallback else fallback
end

local function getRecompute(info: ModifierInfo?): boolean
	if info then
		return info.recompute == true
	end

	return true
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
	self._modifiersNeedSorted = false
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

function RogueProperty._GetModifierIndexById<T>(self: Identity<T>, id: string): number?
	for index, modifier in self._modifiers do
		if modifier.id == id then
			return index
		end
	end

	return nil
end

function RogueProperty._Recompute<T>(self: Identity<T>)
	if self._modifiersNeedSorted then
		table.sort(self._modifiers, sortByPriority)
		self._modifiersNeedSorted = false
	end

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

function RogueProperty._AddModifier<T>(self: Identity<T>, id: string, priority: number, recompute: boolean, map: Map<T>)
	for _, modifier in self._modifiers do
		if modifier.id == id then
			error(`modifier id "{id}" already used`, 3)
		end
	end

	self._modifiersNeedSorted = true

	table.insert(self._modifiers, {
		id = id,
		priority = priority,
		map = map,
	})

	if recompute then
		self:_Recompute()
	end
end

function RogueProperty._RemoveModifierByIndex<T>(self: Identity<T>, index: number, id: string, recompute: boolean)
	self._modifiersNeedSorted = true

	self._animationAlphas[id] = nil
	table.remove(self._modifiers, index)

	if recompute then
		self:_Recompute()
	end
end

function RogueProperty._AnimateModifier<T>(
	self: Identity<T>,
	id: string,
	info: Animatable,
	alphaGoal: number,
	onFinished: ((canceled: boolean) -> ())?
)
	local duration = info.duration
	if not duration then
		error("nil duration passed when animating", 2)
		return
	end

	local easingStyle = info.easingStyle or Enum.EasingStyle.Linear
	local easingDirection = info.easingDirection or Enum.EasingDirection.Out
	local timeElapsed = 0

	self._animationAlphas[id] = math.abs(alphaGoal - 1)

	local conn: RBXScriptConnection? = nil
	local function finish(canceled: boolean)
		if conn then
			conn:Disconnect()
			conn = nil
		end

		if onFinished then
			onFinished(canceled)
		end
	end

	conn = RunService.Stepped:Connect(function(_, dt: number)
		if not self._animationAlphas[id] then
			finish(true)
			return
		end

		timeElapsed += dt

		if timeElapsed >= duration then
			self._animationAlphas[id] = alphaGoal
			self:_Recompute()
			finish(false)
			return
		end

		local timeAlpha = math.abs(timeElapsed / duration - alphaGoal)
		self._animationAlphas[id] = TweenService:GetValue(timeAlpha, easingStyle, easingDirection)
		self:_Recompute()
	end)
end

function RogueProperty._SetBounds<T>(self: Identity<T>, min: number?, max: number?)
	if self._type ~= "number" then
		error("bounds are only supported for number prop types", 3)
	end

	self._min = min
	self._max = max
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

	If the `duration` field is supplied into the `info` parameter, the creation of the modifier can be animated.
]]
function RogueProperty.AdditiveModifier<T>(self: Identity<T>, id: string, value: T, info: ModifierCreationInfoAnimatable?)
	if self._type == "CFrame" then
		error("additive modifiers are not supported with CFrame value types", 2)
	end

	local recompute = getRecompute(info)
	if not info or not info.duration then
		self:_AddModifier(id, getPriority(info, 10), recompute, function(current)
			return (current :: any) + value
		end)

		return
	end

	self:_AddModifier(id, getPriority(info, 10), recompute, function(current)
		return (current :: any) + (value :: any) * (self._animationAlphas[id] or 1)
	end)
	self:_AnimateModifier(id, info, 1)
end

--[[
	Creates a multiplier modifier with a default priority of `20`.

	If the `duration` field is supplied into the `info` parameter, the creation of the modifier can be animated.
]]
function RogueProperty.MultiplierModifier<T>(
	self: Identity<T>,
	id: string,
	value: T,
	info: ModifierCreationInfoAnimatable?
)
	local recompute = getRecompute(info)
	if not info or not info.duration then
		self:_AddModifier(id, getPriority(info, 20), recompute, function(current)
			return (current :: any) + value
		end)

		return
	end

	self:_AddModifier(id, getPriority(info, 20), recompute, function(current)
		return (current :: any) * (value :: any) * (self._animationAlphas[id] or 1)
	end)
	self:_AnimateModifier(id, info, 1)
end

--[[
	Creates an override modifier with a default priority of `30`.
]]
function RogueProperty.OverrideModifier<T>(self: Identity<T>, id: string, value: T, info: ModifierCreationInfo?)
	self:_AddModifier(id, getPriority(info, 30), getRecompute(info), function()
		return value
	end)
end

--[[
	Creates a custom modifier with a default priority of `40`.
]]
function RogueProperty.CustomModifier<T>(self: Identity<T>, id: string, map: Map<T>, info: ModifierCreationInfo?)
	self:_AddModifier(id, getPriority(info, 40), getRecompute(info), map)
end

--[[
	Removes a modifier by id.

	If the `duration` field is supplied into the `info` parameter, the destruction of the modifier can be animated.
	This only applies for additive and multiplier modifiers, others will not change during the animation time.
]]
function RogueProperty.RemoveModifier<T>(self: Identity<T>, id: string, info: ModifierDestructionInfo?)
	local index = self:_GetModifierIndexById(id)
	if not index then
		return
	end

	local recompute = getRecompute(info)

	if info and info.duration then
		self:_AnimateModifier(id, info, 0, function(canceled: boolean)
			if canceled then
				return
			end

			local updatedIndex = self:_GetModifierIndexById(id)
			if not updatedIndex then
				return
			end

			self:_RemoveModifierByIndex(updatedIndex, id, recompute)
		end)

		return
	end

	self:_RemoveModifierByIndex(index, id, recompute)
end

--[[
	Clears all the modifiers.
]]
function RogueProperty.ClearModifiers<T>(self: Identity<T>)
	self._modifiersNeedSorted = false
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
