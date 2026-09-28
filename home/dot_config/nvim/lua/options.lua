require "nvchad.options"

-- "unnamedplus" makes y/delete share the system clipboard register.
vim.opt.clipboard = "unnamedplus"

-- Without a display (e.g. Docker), use the terminal's clipboard via OSC 52.
-- The built-in OSC 52 provider requires Neovim 0.10 or newer.
if not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok then
    vim.g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy "+",
        ["*"] = osc52.copy "*",
      },
      paste = {
        ["+"] = osc52.paste "+",
        ["*"] = osc52.paste "*",
      },
    }
  end
end

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
