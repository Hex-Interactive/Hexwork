local Players = game:GetService("Players")

local NetworkClient = {}
local replicatorRemote

local function handlePacket(instance, callback)
	-- Check if the instance is a packet
	if string.sub(instance.Name, 1, 13) == "NetworkPacket" then
		-- The callback is capable of yielding to allow a delayed activation of the NetworkReplicator confirmation
		-- Firing the server will confirm that the packet should have been fully processed and is no longer needed

		callback(instance, instance:GetChildren()[1]) -- Supplies the packet and the first child of the packet (the root instance being replicated)
		replicatorRemote:FireServer()
	end
end

function NetworkClient:Connect(callback)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	replicatorRemote = script.Parent:WaitForChild("NetworkReplicator")

	-- Connect replications of new packets
	playerGui.ChildAdded:Connect(function(packet)
		handlePacket(packet, callback)
	end)

	-- Find packets that have been replicated already
	for _, instance in ipairs(playerGui:GetChildren()) do
		handlePacket(instance, callback)
	end
end

return NetworkClient
