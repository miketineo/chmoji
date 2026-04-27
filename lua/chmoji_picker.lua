-- chmoji picker bridges for Neovim-native Lua pickers.
-- Vimscript dispatch lives in autoload/chmoji/picker.vim; this module is
-- only loaded when the user has at least one of fzf-lua / snacks / telescope.
--
-- Each entry takes (items, query) where items is a list of "<glyph>\t:<name>:"
-- lines. On selection we call vim.fn['chmoji#picker#commit'](line).

local M = {}

local function commit(line)
  if line and line ~= "" then
    vim.fn["chmoji#picker#commit"](line)
    vim.schedule(function() vim.cmd("startinsert!") end)
  end
end

-- fzf-lua: ibhagwan/fzf-lua
function M.fzf_lua(items, query)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return vim.notify("chmoji: fzf-lua not available", vim.log.levels.WARN)
  end
  fzf.fzf_exec(items, {
    prompt = "emoji> ",
    winopts = { relative = "cursor", row = 1, col = 0, height = 0.35, width = 0.5 },
    fzf_opts = {
      ["--query"] = query or "",
      ["--delimiter"] = "\t",
      ["--with-nth"] = "1,2",
      ["--reverse"] = "",
    },
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          commit(selected[1])
        end
      end,
    },
  })
end

-- snacks.nvim: folke/snacks.nvim
function M.snacks(items, query)
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then
    return vim.notify("chmoji: snacks.picker not available", vim.log.levels.WARN)
  end
  local entries = {}
  for _, line in ipairs(items) do
    table.insert(entries, { text = line, value = line })
  end
  snacks.picker.pick({
    source = "chmoji",
    items = entries,
    title = "emoji",
    pattern = query or "",
    format = "text",
    layout = { preset = "cursor" },
    confirm = function(picker, item)
      picker:close()
      if item and item.value then
        commit(item.value)
      end
    end,
  })
end

-- telescope.nvim: nvim-telescope/telescope.nvim
function M.telescope(items, query)
  local ok_p, pickers = pcall(require, "telescope.pickers")
  local ok_f, finders = pcall(require, "telescope.finders")
  local ok_c, conf = pcall(require, "telescope.config")
  local ok_a, actions = pcall(require, "telescope.actions")
  local ok_s, action_state = pcall(require, "telescope.actions.state")
  if not (ok_p and ok_f and ok_c and ok_a and ok_s) then
    return vim.notify("chmoji: telescope not available", vim.log.levels.WARN)
  end

  pickers.new({}, {
    prompt_title = "emoji",
    default_text = query or "",
    finder = finders.new_table({ results = items }),
    sorter = conf.values.generic_sorter({}),
    layout_strategy = "cursor",
    layout_config = { width = 0.5, height = 12 },
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then
          commit(sel[1] or sel.value)
        end
      end)
      return true
    end,
  }):find()
end

return M
