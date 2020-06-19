-- Treesitter utils

local api = vim.api
local ts = vim.treesitter
local ts_utils = require'nvim-treesitter.utils'
local ts_query = require'nvim-treesitter.query'
local node_api = require'nvim-treesitter'.get_node_api()

local M = {
}

M.match_kinds = {
  var = 'v',
  method = 'm',
  ['function'] = 'f'
}

local function read_query_file(fname)
  return table.concat(vim.fn.readfile(fname), '\n')
end

-- function M.get_query(ft, query_name)
--   local query_files = api.nvim_get_runtime_file(string.format('queries/%s/%s.scm', ft, query_name), false)
--   if #query_files > 0 then
--     return ts.parse_query(ft, read_query_file(query_files[1]))
--   end
-- end

function M.prepare_match(match)
  local object = {}

  if match.node then
    object.full = node
    object.def = node
  else
    for name, item in pairs(match) do
      object.kind = M.match_kinds[name]
      object.full = item.node
      object.def = item.node
    end
  end

  return object
end

function M.get_definition(node, tree)
  local node_text = node_api.get_node_text(node)
  local bufnr = api.nvim_get_current_buf()
  local filetype = api.nvim_buf_get_option('filetype')
  local query = ts_query.get_query(filetype, 'locals')
  local _, _, node_start = node:start()
  -- Get current context, and search upwards
  local current_context = node

  repeat
    current_context = node_api.previous_scope(current_context)
    for _, match in ts_utils.iter_prepared_matches(query, current_context, bufnr, row_start, row_end) do
      local prepared = M.prepare_match(match)
      local def = prepared.def
      local _, _, def_start = def:start()

      if def_start <= node_start then
        return def, current_context
      end
    end

    current_context = current_context:parent()
  until current_context == nil

  return node, tree
end

function M.prepare_def_query(ident_text)
  local def_query = api.nvim_buf_get_var(0, 'completion_def_query')
  local final_query = ""

  for _, subquery in ipairs(def_query) do
    final_query = final_query .. string.format("(%s %s)", subquery, ident_text)
  end

  return final_query
end

-- Copied from runtime treesitter.lua
function M.get_node_text(node, bufnr, line)
  local start_row, start_col, end_row, end_col = node:range()
  if start_row ~= end_row then
    local index
    if line ~= nil and line >= start_row then
      index = line - start_row + 1
    else
      index = 1
    end
    return api.nvim_buf_get_lines(bufnr, start_row, end_row, false)[line or 1]
  else
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row+1, true)[1]
    return string.sub(line, start_col+1, end_col)
  end
end

function M.tree_root(bufnr)
  return ts_utils.get_parser(bufnr):parse():root()
end

function M.has_parser(lang)
  local lang = lang or api.nvim_buf_get_option(0, 'filetype')
  return #api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) > 0
end

-- is dest in a parent of source
function M.is_parent(source, dest)
  local current = source
  while current ~= nil do
    if current == dest then
      return true
    end

    current = current:parent()
  end

  return false
end

function M.expression_at_point(tsroot)
  local tsroot = tsroot or M.tree_root()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_node = tsroot:named_descendant_for_range(cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2])
  return current_node
end

-- function M.smallestContext(tree, source)
--   -- Step 1 get current context
--   local contexts = api.nvim_buf_get_var(get_parser().bufnr, 'completion_context_query')
--   local current = source
--   while current ~= nil and not vim.tbl_contains(contexts, current:type()) do
--     current = current:parent()
--   end

--   return current or tree
-- end

function M.parse_query(query)
  return ts.parse_query(get_parser().lang, query)
end

return M
