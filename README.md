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

Beware of setting times based on "midnight" or "noon" in your local time zone, because the user can change their local device timezone and time at will and use that to time travel. It's better to set times based on amounts of time away from current time so that the future time is timezone agnostic.

Beware of using Defold's build in date/time functions as they by default work on local timezone.

##