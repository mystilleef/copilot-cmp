local source = require("copilot_cmp.source")
local capabilities = require("copilot_cmp.capabilities")

---Registered client and source mapping.
local M = {
  default_capabilities = capabilities.default_capabilities,
  update_capabilities = capabilities.update_capabilities,
}

local function register()
  require("cmp").register_source("copilot", source:new())
end

M.setup = function()
  vim.schedule(register)
end

return M
