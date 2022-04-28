if not INIT then
  -- Initialization
  INIT = true

  -- We'll use that to time our loading
  tStart = 0
  tEnd = nil
end

-- Loads the "Input", this will autimatically run any required stuff to fetch data automatically. This MUST BE OUTSIDE of any init checks and run EVERY FRAME
local Input = require('@wolfe-labs/ScreenBuffer:Data')

-- Creates our layer
local layer = createLayer()

-- Our main font
local font = loadFont('Play', 32)

-- The "offline" image
local imgOffline = loadImage('assets.prod.novaquark.com/113304/5e4ef0af-681b-4d3e-915f-fa4cd05b7351.png')

-- The "loading" image
local imgLoading = loadImage('assets.prod.novaquark.com/113304/d5ba22a0-c1f6-4e85-a10f-44dca9e9a77d.png')

-- The "loaded" image
local imgLoaded = loadImage('assets.prod.novaquark.com/113304/480266b1-f409-4681-8245-d59a768d9b5f.png')

-- Gets screen resolution
local W, H = getResolution()

-- Formats bytes
local function formatBytes (bytes)
  local suffix = 'B'
  if bytes > 1024 then
    suffix = 'kB'
    bytes = bytes / 1024
  end
  return string.format('%.3f %s', bytes, suffix)
end

-- Do we have any data to render?
if (Input.dataAvailable) then
  -- End time
  if not tEnd then
    tEnd = getTime()
  end

  -- Total bytes, duration and byte rate
  local byteTotal = Input.dataRaw:len()
  local duration = tEnd - tStart
  local byteRate = byteTotal / duration

  -- Renders loaded background
  addImage(layer, imgLoaded, 0, 0, W, H)

  -- Shows stats
  
  setNextFillColor(layer, 0.015, 0.003, 0.063, 1)
  setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
  addText(layer, font, string.format('Loaded %s of data in %.2f seconds', formatBytes(byteTotal), duration), W * 0.5, H * 0.75)

  setNextFillColor(layer, 0.015, 0.003, 0.063, 1)
  setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
  addText(layer, font, string.format('Byte rate: %s/s', formatBytes(byteRate)), W * 0.5, H * 0.85)
else
  -- Are we loading?
  if Input.loading then
    -- Gets loading status
    local loadingStatus = Input.loadingProgress

    -- Starts timing load time
    if loadingStatus[1] == 1 then
      tStart = getTime()
      tEnd = nil
    end

    -- How much have we loaded
    local progress = loadingStatus[1] / loadingStatus[2]

    -- Calculates our bar width, height, radius and location
    local barW = W / 3
    local barH = 20
    local barR = barH / 4
    local barX = W * 0.5 - barW * 0.5
    local barY = H * 0.85

    -- Renders loading background
    addImage(layer, imgLoading, 0, 0, W, H)

    -- Draws progress bar background
    setNextFillColor(layer, 0.015, 0.003, 0.063, 1)
    addBoxRounded(layer, barX, barY, barW, barH, 5)

    -- Draws progress bar foreground
    setNextFillColor(layer, 0.341, 0.929, 0.615, 1)
    addBoxRounded(layer, barX, barY, barW * progress, barH, 5)
  else
    -- Offline
    addImage(layer, imgOffline, 0, 0, W, H)
  end
end