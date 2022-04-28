-- Generates a big data set
local largeDataSet = {}
for i = 1, 2048 do
  table.insert(largeDataSet, 'the quick brown fox jumped over the lazy dog #' .. i)
end

-- Loads the API to communicate with our Render Script
local ScreenBuffer = require('@wolfe-labs/ScreenBuffer:API')

-- Gets a list of all screens linked
local screens = library.getLinksByClass('ScreenUnit')

-- Configures every linked screen
for i, screen in pairs(screens) do
  -- Converts to a Luna screen object
  screen = ScreenBuffer(screen)

  -- "Overclocks" our communication speed to maximum possible rate. Note that this might cause desync if other nearby clients can't keep up, as the rate will be bound to your fps count
  -- You can change this line to something more reasonable such as 60 for 60 updates per second, for example. Zero will make it run at max performance. Default is 30.
  screen.setByteRate(0)

  -- Sends data
  screen.update(largeDataSet)

  -- Saves screen
  screens[i] = screen
end

-- When the board turns off, clear data from screens
unit:onEvent('stop', function (unit)
  for i, screen in pairs(screens) do
    screen.reset()
  end
end)