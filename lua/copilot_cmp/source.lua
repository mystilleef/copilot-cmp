local source = {
  timer = nil,
  executions = {},
  client = nil,
  request_ids = {},
  complete = nil,
}

function source.get_keyword_pattern()
  return "."
end

source.get_trigger_characters = function()
  return { "." }
end

-- executes before selection
function source:resolve(completion_item, callback)
  for _, fn in ipairs(self.executions) do
    completion_item = fn(completion_item)
  end
  callback(completion_item)
end

source.is_available = function(self)
  -- client is stopped.
  if self.client.is_stopped() then
    return false
  end
  -- client is not attached to current buffer.
  local active_clients =
    vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf() })
  local active_copilot_client = vim.tbl_filter(function(client)
    return client.id == self.client.id
  end, active_clients)
  if next(active_copilot_client) == nil then
    return false
  end
  if self.client.name ~= "copilot" then
    return false
  end
  return true
end

source.execute = function(_, completion_item, callback)
  callback(completion_item)
end

function source.new(client, opts)
  local completion_functions = require("copilot_cmp.completion_functions")
  return setmetatable({
    timer = vim.loop.new_timer(),
    client = client,
    executions = {},
    request_ids = {},
    complete = completion_functions.init("getCompletionsCycling", opts),
  }, { __index = source })
end

return source
