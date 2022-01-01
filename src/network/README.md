# Network
A module designed to implement custom replication from the server to a client. Useful for sending instances to only one client. A RemoteEvent named "NetworkReplicator" is assumed to be a descendant of ReplcatedStorage.

**Important:** Network was developed very quickly and the documentation is lackluster. A major refactor is in the works, but, for now, read the code comments to get a better idea of how the module works.

# Documentation

## Global Methods

```lua
Network:Connect()
```

**Description** <div>
Connects a client or the server to Network. This is required to send and receive packets. See the `Network:Connect()` code for more information.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| callbackData | any | | The packet received callback on the client or a table of events for the server. |

---

```lua
Network:ReplicateInstance()
```

**Description** <div>
Sends a copy of the given instance to the specified client. This function only runs on the server.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| player | Instance | | The player to replicate to. |
| instance | Instance | | The instance that should be copied and replicated to the client. |
| packetType | any | | An attribute by the name "PacketType" to be applied to the replicating packet. |