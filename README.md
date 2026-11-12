# Roblox x9 Training Panel

A legitimate training GUI for a Roblox experience you own or are authorized to edit. It creates a draggable panel with an ON/OFF button. Training awards 9 `TrainingPower` per second while enabled; the server owns the timer and award logic.

## Install in Roblox Studio

1. Put `ServerScriptService/TrainingServer.server.lua` in **ServerScriptService**.
2. Put `StarterPlayer/StarterPlayerScripts/TrainingGui.client.lua` in **StarterPlayer > StarterPlayerScripts**.
3. Press **Play**. The example server script creates `leaderstats.TrainingPower` if it does not already exist.

If your game already creates a `TrainingPower` `IntValue` or `NumberValue` under `leaderstats`, the example stat-creation block at the bottom of the server script can be removed. To tune the award, edit `BASE_RATE` and `TRAINING_MULTIPLIER` in the server script.

This is for your own Roblox Studio game; it is not an executor/universal exploit script and cannot control training in other people's experiences.
