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

local set_copilot_client = function()
  if source.client then
    return source.client
  else
    for _, client in ipairs(vim.lsp.get_active_clients()) do
      if client.name == "copilot" then
        source.client = client
        return client
      end
    end
  end
end

function source:get_keyword_pattern()
  return "."
end

function source:get_trigger_characters()
  return { "." }
end

function source:resolve(completion_item, callback)
  callback(completion_item)
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
  if self.client then
    api.get_completions_cycling(
      self.client,
      util.get_doc_params(),
      vim.schedule_wrap(respond_callback)
    )
  else
    vim.schedule(set_copilot_client)
    vim.schedule(callback)
  end
end

function source.new()
  return setmetatable({
    timer = vim.loop.new_timer(),
    client = set_copilot_client(),
    request_ids = {},
  }, { __index = source })
end

return source
