local api = vim.api
local ts = vim.treesitter
local utils = require'ts_utils'
local ts_query = require'nvim-treesitter.query'

local high_ns = api.nvim_get_namespaces()['completion-treesitter']

local M = {}

local function node_range_to_vim(node)
  if node then
    local start_row, start_col, end_row, end_col = node:range()

    return {{start_row, start_col}, {end_row, end_col}}
  else
    return {{}, {}}
  end
end

function M.find_definition()
  if not utils.has_parser() then
    return node_range_to_vim()
  end

  local node = utils.expression_at_point()
  if node:type() == api.nvim_buf_get_var(0, 'completion_ident_type_name') then
    local tree = utils.tree_root()

    local def, _ = utils.get_definition(tree, node)

    return node_range_to_vim(def)
  else
    return node_range_to_vim()
  end
end

local function get_usages(tree, node)
  -- Get definition
  local _, scope = utils.get_definition(node, tree)
  local filetype = api.nvim_buf_get_option('filetype')
  local query = ts_query.get_query(filetype, 'locals')
  local node_text = node_api.get_node_text(node)
  local usages = {}

  for _, match in ts_query:iter_prepared_matches(query, scope, 0, row_start, row_end) do
    if match.reference and node_api.get_node_text(match.reference.node) == node_text then
      table.insert(usages, usage)
    end
  end
  return usages
end

function M.find_usages()
  if not utils.has_parser() then
    return {}
  end

  local node = utils.expression_at_point()
  if node:type() == api.nvim_buf_get_var(0, 'completion_ident_type_name') then
    local tree = utils.tree_root()
    local positions = {}

    for _, usage in ipairs(get_usages(tree, node)) do
      local start_row, start_col, _, end_col = usage:range()
      table.insert(positions, {start_row, start_col, end_col})
    end
    return positions
  else
    return {}
  end
end

return M
