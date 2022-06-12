local source = require("copilot_cmp.source")

local M = {}

---Registered client and source mapping.
M.client_source_map = {}
M.registered = false

M.setup = function(completion_method)
  source.complete = completion_method or source.complete
  if vim.fn.has("nvim-0.7") > 0 then
    vim.api.nvim_create_autocmd({ "InsertEnter" }, { callback = M._on_insert_enter })
  else
    vim.api.nvim_command([[autocmd InsertEnter * lua require('copilot_cmp')._on_insert_enter()]])
  end
end
---Setup cmp-nvim-lsp source.
local if_nil = function(val, default)
  if val == nil then return default end
  return val
end

M.update_capabilities = function(capabilities, override)
  override = override or {}
  local completionItem = capabilities.textDocument.completion.completionItem
  completionItem.snippetSupport = if_nil(override.snippetSupport, true)
  completionItem.preselectSupport = if_nil(override.preselectSupport, true)
  completionItem.insertReplaceSupport = if_nil(override.insertReplaceSupport, true)
  completionItem.labelDetailsSupport = if_nil(override.labelDetailsSupport, true)
  completionItem.deprecatedSupport = if_nil(override.deprecatedSupport, true)
  completionItem.commitCharactersSupport = if_nil(override.commitCharactersSupport, true)
  completionItem.tagSupport = if_nil(override.tagSupport, { valueSet = { 1 } })
  completionItem.resolveSupport = if_nil(override.resolveSupport, {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  })

  return capabilities
end

local find_buf_client = function()
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == "copilot" then return client end
  end
end

M._on_insert_enter = function()
  local cmp = require("cmp")
  local copilot = find_buf_client()
  if copilot and not M.client_source_map[copilot.id] then
    local s = source.new(copilot)
    if s:is_available() then
      M.client_source_map[copilot.id] = cmp.register_source("copilot", s)
    end
  end
end

return M
