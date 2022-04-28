-- This is the data currently being loaded, we'll handle chunked loading here to get around the 1024 character limit
if not __data_buffer then
  __data_buffer = {}
end

-- This is what data was already *completely* loaded, the front buffer
if not __data then
  __data = ''
end

-- This is the size of backbuffer
local __size_buffer = 0

-- This is the current input
-- The data coming here will be in the format 0,1,4:json_data where 0 is indicating wether we should reset the current data, 1 is the current chunk, 4 is total chunks and json_data is the data being transferred
local raw = getInput()
if raw and #raw > 0 then
  -- Parses the current command
  local cmd, chunk, total, data = raw:match('([0-9]+),([0-9]+),([0-9]+):(.*)')

  -- Validity check
  if cmd and chunk and total and data then
    -- Converts variables
    cmd = tonumber(cmd)
    chunk = tonumber(chunk)
    total = tonumber(total)

    -- Updates backbuffer size
    __size_buffer = total

    -- Clear/reset command
    if 0x00 == cmd then
      __data_buffer = {}
    end

    -- Append data
    if #__data_buffer == chunk - 1 then
      table.insert(__data_buffer, data)

      -- Finished loading, send data to front buffer
      if __size_buffer > 0 and #__data_buffer == __size_buffer then
        __data = table.concat(__data_buffer, '')
      end
    elseif __size_buffer == 0 and chunk == 0 then
      -- Special clear case
      __data = ''
      __data_buffer = {}
      __size_buffer = 0
    else
      -- Something is wrong, reset everything and load again
      __data_buffer = {}
      __size_buffer = 0
    end
  end
end

-- Processes data
local result = require('dkjson').decode(__data) or {}

-- Loading status, returns null if not loading or { current chunk, total chunks }
local loadingProgress = nil
if __size_buffer > 0 then
  loadingProgress = { #__data_buffer, __size_buffer }
end

-- Initial screen output
local output = {
  e = {}, -- Events
  lc = #__data_buffer, -- Last chunk loaded
}

-- Sets output
local function callback ()
  setOutput(require('dkjson').encode(output))
end

-- Emits events to Control Unit
local function emit (...)
  table.insert(output.e, {...})
  callback()
end

-- Sets initial output
callback()

-- Exposes processed data
return {
  data = result,
  dataRaw = __data,
  dataAvailable = (result and __data and #__data > 0),
  loading = (loadingProgress ~= nil),
  loadingProgress = loadingProgress,
  emit = emit,
}
