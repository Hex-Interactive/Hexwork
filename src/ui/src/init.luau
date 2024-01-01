local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local guis = {}

local UI = {}

function UI.Get(name: string): ScreenGui
	assert(guis[name], `GUI "{name}" not initialized`)
	return guis[name]
end

function UI.Init()
	local starterGui = ReplicatedStorage:WaitForChild("StarterGui")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	for _, instance in starterGui:GetChildren() do
		if instance:IsA("ScreenGui") then
			local name = instance.Name
			assert(guis[name] == nil, `GUI "{name}" already initialized`)

			guis[name] = instance
			instance.ResetOnSpawn = false
			instance.Parent = playerGui
		end
	end

	starterGui:Destroy()
end

return UI
