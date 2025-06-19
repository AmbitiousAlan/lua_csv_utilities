--[[
  Test file generated with help from ChatGPT (OpenAI) on June 18, 2025.
  Tests table <-> array2d conversion, covering references, nesting, and roundtrip integrity.
]]
package.path = "../?.lua;" .. package.path
local M = require("table_to_array2d") -- Replace with actual module name

local function assert_deep_equal(a, b, label)
    local function deep_cmp(x, y)
        if type(x) ~= type(y) then return false end
        if type(x) ~= "table" then return x == y end
        for k, v in pairs(x) do
            if not deep_cmp(v, y[k]) then return false end
        end
        for k, v in pairs(y) do
            if not deep_cmp(v, x[k]) then return false end
        end
        return true
    end
    if not deep_cmp(a, b) then
        error(label .. " failed")
    else
        print(label .. " passed")
    end
end

-- Sample structure
local shared_leaf = {x = 42}
local t = {
    config = {
        name = "Alan",
        nested = shared_leaf,
    },
    override = shared_leaf,
    flags = {true, false}
}

-- Optional branch filter: only recurse into tables that aren't arrays
local function branch_filter(node)
    local t = node.t
    local i = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" then return true end
        i = i + 1
    end
    return i == 0
end

-- Convert table → array2d
local array2d = M.table_to_array2d(t, branch_filter)

-- Convert back
local t2 = M.array2d_to_table(array2d, branch_filter)

-- Test structural match
assert_deep_equal(t2.config.name, "Alan", "Field preserved")
assert_deep_equal(t2.config.nested.x, 42, "Nested field preserved")
assert_deep_equal(t2.override.x, 42, "Shared table preserved")
assert_deep_equal(t2.config.nested, t2.override, "Shared ref structure preserved")

-- Test roundtrip
local array2d_round = M.table_to_array2d(t2, branch_filter)
assert_deep_equal(array2d_round, array2d, "Roundtrip array2d match")

print("All table <-> array2d tests passed.")

