local M = {}

M.default = "tokyonight-moon"
M.state_file = vim.fn.stdpath("state") .. "/nvim-theme"

local function save(name)
  vim.fn.mkdir(vim.fn.fnamemodify(M.state_file, ":h"), "p")
  vim.fn.writefile({ name }, M.state_file)
end

function M.apply(name, persist)
  local ok = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify("Could not load theme " .. name, vim.log.levels.WARN)
    name = M.default
    vim.cmd.colorscheme(name)
  end

  if persist then
    save(name)
    vim.notify("Theme: " .. name)
  end
end

function M.setup()
  local saved
  if vim.uv.fs_stat(M.state_file) then
    saved = vim.fn.readfile(M.state_file)[1]
  end
  M.apply(saved or M.default, false)
end

function M.pick()
  Snacks.picker.colorschemes({
    confirm = function(picker, item)
      picker:close()
      if item then
        -- Prevent the previewer from restoring the previous theme on close.
        picker.preview.state.colorscheme = nil
        vim.schedule(function()
          M.apply(item.text, true)
        end)
      end
    end,
  })
end

return M
