type Vector = Vector2 | Vector3
type VectorI16 = Vector2int16 | Vector3int16
type Numerical = number | Vector | VectorI16 | CFrame

local RNG = Random.new()

local MathUtil = {
	tau = math.pi * 2,
}

function MathUtil.IsNaN(value: Numerical): boolean
	return value ~= value
end

function MathUtil.IsFinite(value: number): boolean
	return MathUtil.FitsIntervalOpen(value, -math.huge, math.huge)
end

function MathUtil.FitsIntervalOpen(value: number, min: number, max: number): boolean
	return value > min and value < max
end

function MathUtil.FitsIntervalClosed(value: number, min: number, max: number): boolean
	return value >= min and value <= max
end

function MathUtil.Flatten(value: number, min: number, max: number): number
	return math.clamp(math.floor(value), min, max)
end

function MathUtil.UnitVectorSafe(vector: Vector): Vector
	return if vector.Magnitude > 0 then vector.Unit else vector
end

function MathUtil.Jitter(average: number, spread: number, randomValue: number?): number
	return average - 0.5 * spread + (randomValue or RNG:NextNumber()) * spread
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

return MathUtil