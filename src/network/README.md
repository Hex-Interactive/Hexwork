# Network
Implements custom replication of instances from the server to a single client. Network needs to be initialized on the server and connected on the client for it to function. When required on the server, Network has a different interface then on the client and vice versa.

Network takes advantage of the fact that server created instances parented to a given player's PlayerGui only replicate to that specific player. Using this "hack" with Roblox instance replication, decent custom replication behavior can be simulated. Ideally, new API would remove the need for this module.

## Example

TODO

# Documentation

## Server Methods

```lua
Network:Init()
```

**Description**

Initializes the Network server with the given config. Table contents must match the index of the default config to be applied. This is required to be executed in order for Network to run.

Default config:
- PacketTimeout (default `10`): The amount of time in seconds before packets are automatically marked confirmed while waiting for confirmation from the client

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| initConfig | table | | The config table to apply. |

---

```lua
Network:Connect()
```

**Description**

Connects the given function(s) to their matching event name. Names have to match a valid event name to be connected correctly.

Events:
- `OnPacketSend(player, instance)`: Fires when a packet is sent to a client; passes the player and the instance replicated
- `OnPacketConfirmed(player)`: Fires when a packet is confirmed by the client (or timed out); passes the player

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| connections | table | | The table of functions to connect. |

---

```lua
Network:ReplicateInstance()
```

**Description**

Replicates a copy of the given instance to the specified client.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| player | Instance | | The player to replicate to. |
| instance | Instance | | The instance that should be copied and replicated to the client. |
| packetType | any | | An attribute by the name "PacketType" to be applied to the replicating packet. |

## Client Methods

```lua
Network:Connect()
```

**Description**

Connects the callback to be fired when a packet is received. This is required to be executed in order for Network to run.

**Parameters**

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| callback | function | | The callback to connect. |

**Callback Arguments**

| Name | Type | Description |
| --- | --- | --- |
| packet | Instance | The instance used to hold the instance when replicating it to the client. |
| instance | Instance | The instance replicated to the client. |