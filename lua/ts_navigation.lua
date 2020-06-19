-- Code navigation using Treesitter

local api = vim.api
local ts = vim.treesitter
local utils = require'ts_utils'
local ts_locals = require'nvim-treesitter.locals'
local node_api = require'nvim-treesitter'.get_node_api()

local M = {}

function M.list_definitions(bufnr)
  local bufnr = bufnr or api.nvim_get_current_buf()
  local qf_list = {}

  for _, match in ipairs(ts_locals.get_definitions(bufnr)) do
    local def = utils.prepare_match(match)
    local lnum, col, _ = def.def:range()
    local text = node_api.get_node_text(def.def)

    table.insert(qf_list, {
      bufnr = bufnr,
      lnum = lnum + 1,
      col = col + 1,
      text = text,
      type = def.kind,
    })
  end

  vim.fn.setqflist(qf_list, 'r')
end

-- local folds_starts = api.nvim_create_namespace('completion-ts-folds-starts')
-- local folds_ends = api.nvim_create_namespace('completion-ts-folds-ends')
-- function M.update_folds(_, buf, changedtick, firstline, lastline, new_lastline, _)
--   local root = utils.tree_root(buf)
--   api.nvim_buf_clear_namespace(buf, folds_starts, 0, -1)
--   api.nvim_buf_clear_namespace(buf, folds_ends, 0, -1)

--   local function set_up_folds(node)
--     local start_r, start_c, stop_r, stop_c = node:range()
--     if start_r ~= stop_r and node ~= utils.tree_root(buf) then
--       api.nvim_buf_set_extmark(buf, folds_starts, 0, start_r, start_c, {})
--       api.nvim_buf_set_extmark(buf, folds_ends, 0, stop_r, stop_c - 1, {})
--     end

--     for index = 0,(node:named_child_count() -1) do
--       set_up_folds(node:named_child(index))
--     end
--   end

--   for index = 0,(root:named_child_count() -1) do
--     set_up_folds(root:named_child(index))
--   end
-- end

-- function M.get_folds(bufnr, start_line, end_line)
--   local starts = api.nvim_buf_get_extmarks(bufnr, folds_starts, start_line or 0, end_line or -1, {})
--   local starts_index = 1

--   local ends = api.nvim_buf_get_extmarks(bufnr, folds_ends, start_line or 0, end_line or -1, {})
--   local ends_index = 1

--   local folds = {}

--   local function min(mark1, mark2)
--     if mark1[2] ~= mark2[2] then
--       return (mark1[2] < mark2[2]) and mark1 or mark2
--     else
--       return (mark1[1] < mark2[1]) and mark1 or mark2
--     end
--   end

--   while starts_index <= #starts and ends_index <= #ends do
--     local start = starts[starts_index]
--     local end_ = ends[ends_index]

--     local min_mark = min(start, end_)

--     if min_mark == start then
--       table.insert(folds, {type="start", mark=start})
--       starts_index = starts_index+1
--     else
--       table.insert(folds, {type="end", mark=end_})
--       ends_index = ends_index + 1
--     end
--   end

--   for index = starts_index, #starts do
--     table.insert(folds, {type="start", mark=starts[index]})
--   end

--   for index = ends_index, #ends do
--     table.insert(folds, {type="end", mark=ends[index]})
--   end

--   return folds
-- end

return M
