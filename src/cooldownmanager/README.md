# CooldownManager

Implements a cooldown system and a way to manage one or more of them. It uses a key based system for managing individual timeouts within a Cooldown object. Calculations to determine if a cooldown is active are only done when you actually need to check if a key is on a cooldown. Any sort of yielding is avoided to provide performant results.

## Installation

```
CooldownManager = "hex-interactive/cooldownmanager@1.0.0"
```
