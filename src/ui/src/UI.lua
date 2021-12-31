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
	if not loaded then
		self:Init()
	end

	return guis[name]
end

function UI:Init()
	local starterGui = ReplicatedStorage:WaitForChild("StarterGui")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	loaded = true

	-- Load all the UIs
	for i, instance in ipairs(starterGui:GetChildren()) do
		guis[instance.Name] = instance

		instance.ResetOnSpawn = false
		instance.Parent = playerGui
	end

	starterGui:Destroy()

	-- Handle callbacks
	for i, callback in ipairs(callbacks) do
		task.spawn(callback)
	end

	for index in ipairs(callbacks) do
		callbacks[index] = nil
	end
end

return UI