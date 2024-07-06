type Vector = Vector2 | Vector3
type VectorI16 = Vector2int16 | Vector3int16
type Numerical = number | Vector | VectorI16 | CFrame

local MathUtil = {}

function MathUtil.IsNaN(value: Numerical): boolean
	return value ~= value
end

function MathUtil.IsReal(value: number): boolean
	return value * 0 == 0
end

function MathUtil.IsFinite(value: number): boolean
	return value > -math.huge and value < math.huge
end

function MathUtil.IsValid(value: number): boolean
	return MathUtil.IsReal(value) and MathUtil.IsFinite(value) and not MathUtil.IsNaN(value)
end

function MathUtil.OnIntOpen(value: number, min: number, max: number): boolean
	return value > min and value < max
end

function MathUtil.OnIntClosed(value: number, min: number, max: number): boolean
	return value >= min and value <= max
end

function MathUtil.Flatten(value: number, min: number, max: number): number
	return math.clamp(math.floor(value), min, max)
end

function MathUtil.UnitVec<T>(vector: T & Vector): T
	return if vector.Magnitude > 0 then vector.Unit else vector :: any
end

function MathUtil.Lerp(start: number, goal: number, alpha: number): number
	return start + (goal - start) * alpha
end

function MathUtil.Logerp(start: number, goal: number, alpha: number): number
	return start * math.pow(goal / start, alpha)
end

function MathUtil.Map(value: number, min0: number, max0: number, min1: number, max1: number): number
	assert(max0 ~= min0, "max0 and min0 cannot match")
	return (value - min0) * (max1 - min1) / (max0 - min0) + min1
end

--- In degrees
function MathUtil.AngleBetween<T>(vectorA: T & Vector, vectorB: T & Vector): number
	return math.deg(math.acos(MathUtil.UnitVec(vectorA :: any):Dot(vectorB)))
end

return MathUtil
