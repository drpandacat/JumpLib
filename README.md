# Jump Library (1.2.1)
JumpLib is a library for Isaac Repentance mods that allows for easy and customizable functionality around moving the entities through the air, avoiding mod conflicts when used across multiple mods
### Features
- 13 functions (including `GetData`, `Jump`, `SetHeight`, `IsFalling`, + more)
- 21 callbacks with various return types and optional parameters
- 22 jump flags to modify default jump behavior (familiar, laser, and knife follow behavior, collision controls, bomb behavior, + more)
- Custom bomb behavior, allowing bombs to be dropped while in the air that explode upon landing (configurable through jump flags)
- Pitfall mechanics with Fiend Folio Lily Pad support
- "Tag" system to keep track of sources of jumps, and run code for only specific jumps
### Notes
- [REPENTOGON](https://github.com/TeamREPENTOGON/REPENTOGON) is not required, but allows for extra functionality
- JumpLib is a work in progress and anyone is free to contribute in any way. Bug reports and feature requests are much appreciated
- Theres no need to credit me if you want to use this in any of your projects, the only time I ask is if the majority of the mod revolves around jumping mechanics

## Setup
Download the library and include or require it inside of your mod, and call the `Init` function from the returned table
```lua
require("scripts.lib.jumplib").Init()
```
You are now able to access anything from the `JumpLib` global!
