local api = vim.api
local ts = vim.treesitter
local utils = require'ts_utils'
local ts_locals = require'nvim-treesitter.locals'
local node_api = require'nvim-treesitter'.get_node_api()

local M = {}

function M.getCompletionItems(prefix, score_func, bufnr)
  if utils.has_parser() then
    local at_point = utils.expression_at_point()
    local _, line_current, _, _, _ = unpack(vim.fn.getcurpos())

    local complete_items = {}

    for _, definition in ipairs(ts_locals.get_definitions(bufnr)) do
      local obj = utils.prepare_match(definition)
      local node = obj.node
      local node_scope = node_api.containing_scope(node)
      local start_line_node, _, _ = node:start()
      local node_text = node_api.get_node_text(node, bufnr)

      -- Only consider items in current scope, and not already met
      local score = score_func(prefix, node_text)

      if score < #prefix / 2
        and (node_api.is_parent(at_point, node_scope) or obj.kind == utils.match_kinds['function'])
        and (start_line_node <= line_current)
        then
          table.insert(complete_items, {
            word = node_text,
            kind = obj.kind,
            menu = full_text,
            score = score,
            icase = 1,
            dup = 0,
            empty = 1, })
      end
    end

    return complete_items
  else
    return {}
  end
end

    -- Step 2 find correct completions
    -- for pattern, match in tsquery:iter_matches(tstree, bufnr, row_start, row_end) do
    --   local obj = utils.prepare_match(tsquery, match)

    --   local node = obj.def
    --   local node_scope = utils.smallestContext(tstree, node)
    --   local start_line_node, _, _= node:start()

    --   local node_text = utils.get_node_text(node, bufnr, start_line_node)
    --   local full_text = utils.get_node_text(obj.declaration, bufnr)

    --   -- Only consider items in current scope, and not already met
    --   local score = score_func(prefix, node_text)
    --   if score < #prefix/2
    --     and (utils.is_parent(at_point, node_scope) or obj.kind == "f")
    --     and (start_line_node <= line_current)
    --     then
    --       table.insert(complete_items, {
    --         word = node_text,
    --         kind = obj.kind,
    --         menu = full_text,
    --         score = score,
    --         icase = 1,
    --         dup = 0,
    --         empty = 1, })
    --       end
    --     end

    --     return complete_items
    --   else
    --     return {}
    --   end
    -- end

M.complete_item = {
  item = M.getCompletionItems
}

if require'source' then
  require'source'.addCompleteItems('ts', M.complete_item)
end

return M
