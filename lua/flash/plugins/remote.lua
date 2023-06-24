-- Original code by @max397574
-- https://github.com/folke/flash.nvim/discussions/24

local Config = require("flash.config")

---@class Flash.Remote
---@field opfunc? string
---@field operator? string
---@field register? string
---@field win? window
---@field view? any
local M = {}

function M.op()
  vim.api.nvim_win_set_cursor(0, vim.api.nvim_buf_get_mark(0, "["))
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, vim.api.nvim_buf_get_mark(0, "]"))
  vim.go.operatorfunc = M.opfunc
  vim.api.nvim_input('"' .. M.register .. M.operator)
  M.restore()
end

function M.restore()
  local win = vim.api.nvim_get_current_win()
  local view = vim.fn.winsaveview()

  local function restore()
    -- HACK: also restore the remote window.
    -- A bug causes the window to get the cursor position of the
    -- previous window. I don't think this is cacused by flash. Need to
    -- further investigate.
    if win ~= M.win then
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview(view)
      end)
    end
    vim.api.nvim_set_current_win(M.win)
    vim.fn.winrestview(M.view)
  end
  restore = vim.schedule_wrap(restore)

  if M.operator == "c" then
    vim.api.nvim_create_autocmd("InsertLeave", {
      once = true,
      callback = restore,
    })
  elseif M.operator == "y" then -- need to check for some opt to paste after yank
    vim.api.nvim_create_autocmd("TextYankPost", {
      once = true,
      callback = restore,
    })
  else
    restore()
  end
end

function M.save()
  M.operator = vim.v.operator
  M.register = vim.v.register
  M.view = vim.fn.winsaveview()
  M.win = vim.api.nvim_get_current_win()
  M.opfunc = vim.go.operatorfunc
end

---@param opts? Flash.State.Config
function M.jump(opts)
  M.save()

  opts = Config.get(opts, { mode = "remote" }, {
    action = function(match)
      vim.api.nvim_set_current_win(match.win)
      vim.api.nvim_win_set_cursor(match.win, match.pos)
      vim.go.operatorfunc = "v:lua.require'flash.plugins.remote'.op"
      vim.api.nvim_feedkeys("g@", "n", false)
    end,
  })

  vim.api.nvim_input("<esc>")
  vim.schedule(function()
    require("flash").jump(opts)
  end)
end

return M
