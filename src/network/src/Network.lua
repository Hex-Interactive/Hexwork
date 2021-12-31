local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NetworkReplicator = ReplicatedStorage:FindFirstChild("NetworkReplicator", true)
assert(NetworkReplicator, "NetworkReplicator was not found as a descendant of ReplicatedStorage")

local Network = {
	PacketTimeout = 15,
	PacketSendCooldown = 0,
	OnSendConnection = nil,
	OnConfirmedConnection = nil,

	Replicating = {},
	Cooldowns = {}
}

-- Utility Functions --

local function replicationError(instanceName, playerName)
	return "[Network]: Unable to replicate instance \"" .. instanceName .. "\" to player \"" .. playerName .. "\""
end

local function isPacket(packet)
	return string.sub(packet.Name, 1, 13) == "NetworkPacket"
end

local function handleClientPackets(packets, callback)
	-- Handle packets passed in
	for i, packet in ipairs(packets) do
		if isPacket(packet) then
			callback(packet, packet:GetChildren()[1]) -- Callback can yield to allow a delayed activation of the NetworkReplicator
			NetworkReplicator:FireServer() -- Tell server that the replication finished
		end
	end
end

local function confirmPacket(player, packetToClear)
	-- If the player doesn't have anything replicating, cancel
	if not Network.Replicating[player.UserId] then
		return
	end

	-- Fire confirmed event
	if Network.OnConfirmedConnection then
		task.spawn(Network.OnConfirmedConnection, player)
	end

	-- If the packet to clear isn't what the user currently has replicating then cancel
	if packetToClear then
		if Network.Replicating[player.UserId] ~= packetToClear then
			return
		end
	end

	-- Destroy the packet and clear the reference
	Network.Replicating[player.UserId]:Destroy()
	Network.Replicating[player.UserId] = nil
end

-- Module Functions --

function Network:Connect(callbackData)
	if RunService:IsClient() then
		local player = Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")

		-- Connect replications of new packets
		playerGui.ChildAdded:Connect(function(packet)
			handleClientPackets({packet}, callbackData)
		end)

		-- Find packets that have been replicated already
		handleClientPackets(playerGui:GetChildren(), callbackData)
	else
		-- Connect events
		if type(callbackData) == "table" then
			self.OnSendConnection = callbackData.OnPacketSend
			self.OnConfirmedConnection = callbackData.OnPacketConfirmed
		end

		-- Allow clients to confirm successful replication
		NetworkReplicator.OnServerEvent:Connect(function(player)
			confirmPacket(player) -- Don't use other arguments sent in through OnServerEvent in confirmPacket
		end)
	end
end

function Network:ReplicateInstance(player, instance, packetType)
	if RunService:IsClient() then
		return
	end

	-- Run in protected mode to prevent weird errors regarding the server dealing with players
	local success, message = pcall(function()
		local playerGui = player:WaitForChild("PlayerGui", 5)

		if playerGui then
			-- Player shouldn't have more than one thing being replicated
			-- Prevent clients requesting more packets before their last packet has even been cloned
			if self.Replicating[player.UserId] or self.Cooldowns[player.UserId] then
				return
			end
			self.Cooldowns[player.UserId] = true

			-- Replicate the instance
			local packet = Instance.new("ScreenGui")
			packet.Name = "NetworkPacket_" .. os.time()

			if packetType then
				packet:SetAttribute("PacketType", packetType)
			end

			local instanceClone = instance:Clone()
			instanceClone.Parent = packet
			packet:SetAttribute("LoadCount", #instanceClone:GetDescendants())

			self.Replicating[player.UserId] = packet
			packet.Parent = playerGui

			if self.OnSendConnection then
				task.spawn(self.OnSendConnection, player, instance)
			end

			-- Manage the player's cooldown and setup a packet timeout
			task.delay(self.PacketSendCooldown, function()
				self.Cooldowns[player.UserId] = nil
			end)

			task.delay(self.PacketTimeout, function()
				confirmPacket(player, packet)
			end)
		else
			warn(replicationError(instance.Name, player.Name))
		end
	end)

	-- Handle errors
	if not success then
		warn(replicationError(instance.Name, player.Name), "-", message)
	end
end

return Network