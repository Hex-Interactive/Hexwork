local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local guis = {}

local UI = {}

function UI.Get(name: string): ScreenGui
	assert(guis[name], "bad GUI name or not initialized")
	return guis[name]
end

function UI.Init()
	local starterGui = ReplicatedStorage:WaitForChild("StarterGui")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	for _, instance in starterGui:GetChildren() do
		if instance:IsA("ScreenGui") then
			assert(guis[instance.Name] == nil, "duplicate initialized GUI name")

			guis[instance.Name] = instance
			instance.ResetOnSpawn = false
			instance.Parent = playerGui
		end
	end

	starterGui:Destroy()
end

return UI
