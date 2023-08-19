local NetworkServer = {}

local config = {
	PacketTimeout = 10,
}

local replicatorRemote
local replicating = {}
local events = {}

local function replErr(instanceName, playerName)
	return '[Network]: Unable to replicate instance "' .. instanceName .. '" to player "' .. playerName .. '"'
end

local function fireEvent(name, ...)
	if events[name] then
		task.spawn(events[name], ...)
	end
end

local function confirmPacket(player, packetToDestroy)
	-- If the player doesn't have anything replicating, cancel
	if not replicating[player.UserId] then
		return
	end

	-- Fire confirmed event
	fireEvent("OnPacketConfirmed", player)

	-- If the packet to be destroyed isn't what the user currently has replicating then cancel
	if packetToDestroy then
		if replicating[player.UserId] ~= packetToDestroy then
			return
		end
	end

	-- Destroy the packet and clear the reference
	replicating[player.UserId]:Destroy()
	replicating[player.UserId] = nil
end

function NetworkServer:ReplicateInstance(player, instance, packetType)
	-- Run in protected mode to prevent weird errors regarding the server dealing with players
	local success, message = pcall(function()
		assert(player:IsA("Player"), "Bad player")
		assert(typeof(instance) == "Instance", "Bad instance")

		local playerGui = player:WaitForChild("PlayerGui", 5)

		if playerGui then
			-- Player shouldn't have more than one thing being replicated
			-- Prevent clients requesting more packets before their last packet has even been cloned
			if replicating[player.UserId] then
				return
			end

			-- Replicate the instance
			local packet = Instance.new("ScreenGui")
			packet.Name = "NetworkPacket_" .. os.time()

			if packetType then
				packet:SetAttribute("PacketType", packetType)
			end

			local instanceClone = instance:Clone()
			instanceClone.Parent = packet
			packet:SetAttribute("DescendantCount", #instanceClone:GetDescendants())

			replicating[player.UserId] = packet
			packet.Parent = playerGui

			fireEvent("OnPacketSend", player, instanceClone)

			-- Manage timeouts
			task.delay(config.PacketTimeout, function()
				confirmPacket(player, packet)
			end)
		else
			warn(replErr(instance.Name, player.Name))
		end
	end)

	-- Handle errors
	if not success then
		warn(replErr(instance.Name, player.Name), "-", message)

		-- Clean up just in case
		if replicating[player.UserId] then
			replicating[player.UserId]:Destroy()
		end

		replicating[player.UserId] = nil
	end
end

function NetworkServer:Init(initConfig)
	assert(typeof(initConfig) == "table", "Bad config")

	-- Apply config
	for index, value in pairs(initConfig) do
		if config[index] ~= nil then
			config[index] = value
		else
			warn('[Network]: Config "' .. index .. '" unknown')
		end
	end

	-- Setup NetworkReplicator
	replicatorRemote = Instance.new("RemoteEvent")
	replicatorRemote.Name = "NetworkReplicator"
	replicatorRemote.Parent = script.Parent

	-- Allow clients to confirm successful replication
	replicatorRemote.OnServerEvent:Connect(function(player)
		confirmPacket(player) -- Don't use other arguments sent in through OnServerEvent in confirmPacket
	end)
end

function NetworkServer:Connect(connections)
	assert(typeof(connections) == "table", "Bad connections")

	events.OnPacketSend = connections.OnPacketSend
	events.OnPacketConfirmed = connections.OnPacketConfirmed
end

return NetworkServer
