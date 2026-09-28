local map = vim.keymap.set

-- Reuse one shell even if the editor's working directory changes.
local terminal_cwd = vim.fn.getcwd()
local function toggle_terminal()
  Snacks.terminal.toggle(nil, { cwd = terminal_cwd, count = 1 })
end
map({ "n", "t" }, "<C-\\>", toggle_terminal, { desc = "Toggle terminal" })
map("n", "<leader>tt", toggle_terminal, { desc = "Toggle terminal" })

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
-- Keep native [d / ]d diagnostics and gcc / gc commenting mappings.
for key, picker in pairs({
  ff = "files", fg = "grep", fb = "buffers", fh = "help",
  fr = "recent", fs = "lsp_symbols", gs = "git_status",
}) do
  map("n", "<leader>" .. key, function()
    Snacks.picker[picker]()
  end, { desc = "Pick " .. picker:gsub("_", " ") })
end
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>uC", function()
  require("theme").pick()
end, { desc = "Pick color theme" })
