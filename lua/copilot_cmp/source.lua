-- luacheck: ignore 212

local format = require("copilot_cmp.format")
local util = require("copilot.util")
local api = require("copilot.api")

local source = {
  client = nil,
  complete = nil,
  request_ids = {},
  timer = nil,
}

function source:get_keyword_pattern()
  return "."
end

function source:get_trigger_characters()
  return { "." }
end

function source:resolve(completion_item, callback)
  callback(completion_item)
end

function source:is_available()
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

function source:execute(completion_item, callback)
  callback(completion_item)
end

function source:complete(params, callback)
  local respond_callback = function(err, response)
    if err or not response or not response.completions then
      vim.schedule(callback)
    else
      local items = vim.tbl_map(function(item)
        return format.format_item(item, params.context, { fix_pairs = true })
      end, vim.tbl_values(response.completions))
      callback({
        isIncomplete = false,
        items = items,
      })
    end
  end
  api.get_completions_cycling(
    self.client,
    util.get_doc_params(),
    vim.schedule_wrap(respond_callback)
  )
end

function source.new(client)
  return setmetatable({
    timer = vim.loop.new_timer(),
    client = client,
    request_ids = {},
  }, { __index = source })
end

return source
