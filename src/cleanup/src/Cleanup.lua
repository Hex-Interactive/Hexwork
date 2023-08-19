local RunService = game:GetService("RunService")

local Cleanup = {}

local cleanupConnection
local debris = {}

local function checkDebris()
	local now = os.clock()

	for instance, timeout in pairs(debris) do
		if now > timeout then
			-- Remove the instance
			if instance and instance.Parent then
				instance:Destroy()
			end

			debris[instance] = nil

			-- Cleanup connection if no debris
			if next(debris) == nil then
				cleanupConnection:Disconnect()
				cleanupConnection = nil
			end
		end
	end
end

function Cleanup:ScheduleInstance(instance, timeout)
	assert(typeof(instance) == "Instance", "Bad instance")
	assert(typeof(timeout) == "number", "Bad timeout")

	-- Setup connection if not already
	if not cleanupConnection then
		cleanupConnection = RunService.Stepped:Connect(checkDebris)
	end

	-- Add instance
	debris[instance] = os.clock() + timeout
end

function Cleanup:DestroyTable(targetTable)
	for index in pairs(targetTable) do
		targetTable[index] = nil
	end
end

return Cleanup
