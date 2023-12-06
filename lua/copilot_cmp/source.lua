-- luacheck: ignore 212

local format = require("copilot_cmp.format")
local util = require("copilot.util")
local api = require("copilot.api")

local source = {
  client = nil,
  timer = nil,
}

local function get_copilot_client()
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == "copilot" then
      return client
    end
  end
  return nil
end

local function update_copilot_client()
  if source.client then
    return source.client
  else
    source.client = get_copilot_client()
    return source.client
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

function source:new()
  return setmetatable({
    timer = vim.loop.new_timer(),
    client = update_copilot_client(),
  }, { __index = source })
end

function source:complete(params, callback)
  local update_client = function()
    vim.schedule(update_copilot_client)
    vim.schedule(callback)
  end
  local get_completions = function(response)
    return vim.tbl_map(function(item)
      return format.format_item(item, params.context, { fix_pairs = true })
    end, vim.tbl_values(response.completions))
  end
  local respond_callback = function(err, response)
    if err or not response or not response.completions then
      vim.schedule(callback)
    else
      callback({ isIncomplete = false, items = get_completions(response) })
    end
  end
  if self.client then
    api.get_completions_cycling(
      self.client,
      util.get_doc_params(),
      vim.schedule_wrap(respond_callback)
    )
  else
    vim.schedule(update_client)
  end
end

return source
