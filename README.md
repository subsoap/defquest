# DefQuest
Setup, track, and check real world time countdowns based on OS or server time for Defold

## Installation
You can use DefQuest in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

	https://github.com/subsoap/defquest/archive/master.zip
  
Once added, you must require the main Lua module in scripts via

```
local defquest = require("defquest.defquest")
```

DefQuest has DefSave as an optional dependency if you wish to use it.

## Usage

##