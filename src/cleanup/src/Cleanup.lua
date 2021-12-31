local RunService = game:GetService("RunService")

local Cleanup = {}
local debris = {}

RunService.Stepped:Connect(function()
	local now = os.clock()

	for instance, timeout in pairs(debris) do
		if now > timeout then
			pcall(function()
				instance:Destroy()
			end)

			debris[instance] = nil
		end
	end
end)

function Cleanup:Schedule(instance, timeout)
	debris[instance] = os.clock() + timeout
end

return Cleanup