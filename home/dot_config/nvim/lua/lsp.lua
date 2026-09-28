-- System clangd keeps the container toolchain explicit; no Mason downloads.
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
})
vim.lsp.enable("clangd")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end
    local function map(key, action, desc)
      vim.keymap.set("n", key, action, { buffer = event.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    -- K, grr, gri and <C-s> use Neovim's native LSP mappings.
  end,
})
