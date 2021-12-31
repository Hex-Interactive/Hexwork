local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UI = {}

local loaded = false
local callbacks = {}
local guis = {}

function UI:OnLoad(callback)
	if loaded then
		callback()
	else
		table.insert(callbacks, callback)
	end
end

function UI:GetGUI(name)
	assert(guis[name], "Bad GUI name or not initialized")
	return guis[name]
end

function UI:Init()
	local starterGui = ReplicatedStorage:WaitForChild("StarterGui")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Load all the UIs
	for i, instance in ipairs(starterGui:GetChildren()) do
		if instance:IsA("ScreenGui") then
			assert(guis[instance.Name] == nil, "Duplicate GUI name")

			guis[instance.Name] = instance
			instance.ResetOnSpawn = false
			instance.Parent = playerGui
		end
	end

	starterGui:Destroy()

	-- Handle callbacks
	loaded = true

	for i = #callbacks, 1, -1 do
		task.spawn(callbacks[i])
		table.remove(callbacks, i)
	end
end

return UI