local json = require('dkjson')

function BufferedScreen (screen)
  -- Sanity check
  if not (screen.getScriptOutput and screen.setScriptInput) then
    error('Invalid screen object!')
  end

  -- Max bytes per chunk (imagine this as the "bitrate")
  local maxSize = 999

  -- Our rate of updates, will aim to send X updates per second
  local rate = 30
  local nextTick = 0

  -- This is our buffer
  local buffer = {}
  local current = nil

  -- Sets message size
  local function setByteSize (size)
    maxSize = size
  end

  -- Sets message rate
  local function setByteRate (interval)
    rate = interval
  end

  -- Resets output of the screen
  local function reset ()
    screen.setScriptInput('0,0,0:')
  end

  -- Sets input of the screen
  local function update (data)
    -- Resets data
    buffer = {}
    current = nil
    
    -- Converts data to JSON
    data = json.encode(data)

    -- Only chunks stuff if required
    if #data <= maxSize then
      table.insert(buffer, data)
    else
      -- Breaks down input into multiple chunks
      while #data > 0 do
        if #data > maxSize then
          table.insert(buffer, data:sub(1, maxSize))
          data = data:sub(1 + maxSize)
        else
          table.insert(buffer, data)
          data = ''
        end
      end

      -- Starts streaming the chunks
      screen.setScriptInput(data)
    end
  end
  
  -- Creates instance with event support
  local self = {
    baseScreen = screen,
    reset = reset,
    update = update,
    setByteRate = setByteRate,
    setByteSize = setByteSize,
  }
  library.addEventHandlers(self)

  -- Hooks into the main 'update' event
  system:onEvent('update', function ()
    -- Can we process next chunk of data yet?
    if rate > 0 and system.getUtcTime() < nextTick then
      -- Skips
      return
    else
      -- Sets next tick time
      nextTick = system.getUtcTime() + (1 / rate)
    end

    -- Handles screen output, 'lc' is the last acked chunk number
    local output = screen.getScriptOutput()
    if output and output:len() > 0 then
      output = json.decode(output) or { lc = 0 }

      -- Handles any upstream events
      if output.e and #output.e > 0 then
        -- Pushes all events
        self:triggerEvent('hasEvents', output.e)

        -- Pushes individual events
        for iEvent, event in ipairs(output.e) do
          self:triggerEvent(table.unpack(event))
        end
      end

      -- Handles data loading
      if 'number' == type(output.lc) and buffer then
        local cmd = 0x01 -- Append data
        local completed = false -- Completed status

        -- If current chunk is nil we had a reset
        if output.lc == 0 or (not current) then
          cmd = 0x00
          current = 1
        elseif output.lc == #buffer then
          -- We're done!
          completed = true
        else 
          -- Increments current chunk
          current = output.lc + 1
        end

        -- Sends the chunk upstream
        if not completed then
          screen.setScriptInput(string.format('%d,%d,%d:%s', cmd, current, #buffer, buffer[current]))
          self:triggerEvent('loadProgress', current, #buffer)
        else
          -- If no more chunks are present, just stop sending data and emit a notification to our main script
          screen.setScriptInput('')
          self:triggerEvent('loadComplete')
        end
      end

      -- Clears output to prevent double executions
      screen.clearScriptOutput()
    end
  end)

  -- Resets screen
  self.reset()

  -- Returns public API
  return self
end

-- Exposes API
return BufferedScreen