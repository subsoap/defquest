# DefQuest
Setup, track, and check real world time countdowns based on OS or server time for Defold

DefQuest can be used for Hearthstone style quests, time locked crates / events (to encourage users to return to the game), or energy regeneration times for games with an energy/heart system.

## Installation
You can use DefQuest in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

	https://github.com/subsoap/defquest/archive/master.zip
  
Once added, you must require the main Lua module in scripts via

```
local defquest = require("defquest.defquest")
```

DefQuest has DefSave and DefWindow as optional dependencies but they are highly recommended you use them. If you use the Defold API Window callbacks then if you should use DefWindow to set your Window callback function instead of using Defold's Window API directly.

In your update make sure to include

defquest.update(dt)

And in your final make sure to include (before defsave.final())

defquest.final()

## Usage

If you are using DefSave then you need to make sure you setup the appname and init DefSave before doing anything with DefQuest (see the example).

defquest.add(id, time, data)

You can set the id til nil to generate a random id. When the random id is generated DefQuest will check to make sure an ID with the random ID it generates is not the same as any other IDs.

If you set an ID when adding a quest it will overwrite any existing quest with that ID.

Time is a table with all values optional but you should set at least one of the values unless you want the quest to complete instantly for some reason. The table values are: seconds, minutes, hours, days, years. 

defquest.add(nil, {hours = 1}, {prize = 25})

If you want a reset time based on midnight or noon then you can set time.midnight or time.noon to true. This will set the next reset to the follow midnight / next day's noon (or today's noon if it's not yet noon). This time is NOT based on local time but on UTC +0. (I honestly don't know with certainty if these time related things are accurate so hopefully someone who knows about it better can sanity check it...)

## Information

DefQuest is meant for games which have frequent or always on Internet connections. You can use DefQuest offline, but it defeats its purpose.

By default, DefQuest saves its data (using DefSave) to a "defquest" file. You can set the defquest.defsave_filename string to another file, such as your user profile/game data so that users cannot simply swap their defquest files to cheese quest completion over and over.


Beware of using Defold's build in date/time functions as they by default work on local timezone.