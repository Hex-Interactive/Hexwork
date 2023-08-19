if game:GetService("RunService"):IsServer() then
	return require(script:WaitForChild("NetworkServer"))
else
	return require(script:WaitForChild("NetworkClient"))
end
