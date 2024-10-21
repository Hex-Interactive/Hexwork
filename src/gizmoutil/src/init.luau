local Workspace = game:GetService("Workspace")

type Gizmo = Part

local CYLINDER_ROTATION = CFrame.Angles(0, math.rad(90), 0)
local CONTAINER_NAME = "_GizmoContainer"
local LINE_DIAMETER = 0.2
local RAY_LENGTH = 800

local container: Folder? = nil
local active: { Gizmo } = {}
local pool: { Gizmo } = {}

local material: Enum.Material? = nil
local transparency: number? = nil
local color: BrickColor? = nil

local GizmoUtil = {}

local function gizmoContainer(): Folder
	if container then
		return container
	end

	local folder = Instance.new("Folder")
	folder.Name = CONTAINER_NAME
	folder.Parent = Workspace

	container = folder
	return folder
end

local function newGizmo(shape: Enum.PartType): Gizmo
	local poolIndex = #pool

	local gizmo
	if poolIndex == 0 then
		local instance = Instance.new("Part")
		instance.CastShadow = false
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
		instance.Anchored = true
		gizmo = instance
	else
		gizmo = pool[poolIndex]
		table.remove(pool, poolIndex)
	end

	gizmo.Name = shape.Name
	gizmo.Shape = shape
	gizmo.Transparency = transparency or 0.3
	gizmo.Material = material or Enum.Material.SmoothPlastic
	gizmo.BrickColor = color or BrickColor.random()

	gizmo.Parent = gizmoContainer()
	table.insert(active, gizmo)

	return gizmo
end

function GizmoUtil.SetColor(new: BrickColor?)
	color = new
end

function GizmoUtil.SetMaterial(new: Enum.Material?)
	material = new
end

function GizmoUtil.SetTransparency(new: number?)
	transparency = new
end

function GizmoUtil.Point(position: Vector3, diameter: number?)
	local gizmo = newGizmo(Enum.PartType.Ball)
	gizmo.Position = position
	gizmo.Size = Vector3.one * (diameter or 1)
end

function GizmoUtil.Line(from: Vector3, to: Vector3, diameter: number?)
	local finalDiameter = diameter or LINE_DIAMETER
	local direction = to - from
	local distance = direction.Magnitude

	local gizmo = newGizmo(Enum.PartType.Cylinder)
	gizmo.Size = Vector3.new(distance, finalDiameter, finalDiameter)
	gizmo.CFrame = CFrame.lookAlong(from, direction) * CFrame.new(0, 0, distance * -0.5) * CYLINDER_ROTATION
end

function GizmoUtil.Ray(from: Vector3, direction: Vector3, diameter: number?)
	local finalDiameter = diameter or LINE_DIAMETER

	local gizmo = newGizmo(Enum.PartType.Cylinder)
	gizmo.Size = Vector3.new(RAY_LENGTH, finalDiameter, finalDiameter)
	gizmo.CFrame = CFrame.lookAlong(from, direction) * CFrame.new(0, 0, RAY_LENGTH * -0.5) * CYLINDER_ROTATION
end

function GizmoUtil.RayCFrame(location: CFrame, diameter: number?)
	local finalDiameter = diameter or LINE_DIAMETER

	local gizmo = newGizmo(Enum.PartType.Cylinder)
	gizmo.Size = Vector3.new(RAY_LENGTH, finalDiameter, finalDiameter)
	gizmo.CFrame = CFrame.lookAlong(location.Position, location.LookVector)
		* CFrame.new(0, 0, RAY_LENGTH * -0.5)
		* CYLINDER_ROTATION
end

function GizmoUtil.ClearAll()
	for i = #active, 1, -1 do
		local gizmo = active[i]
		gizmo.Parent = nil

		table.insert(pool, gizmo)
		table.remove(active, i)
	end
end

function GizmoUtil.DestroyAll()
	GizmoUtil.ClearAll()

	for i = #pool, 1, -1 do
		pool[i]:Destroy()
		table.remove(pool, i)
	end
end

return GizmoUtil
