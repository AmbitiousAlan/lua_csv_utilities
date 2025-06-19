--[[
  Test file generated with help from ChatGPT (OpenAI) on June 18, 2025.
  Includes round-trip tests for CSV <-> array2d transformations.
  Covers quoting, escaping, newlines, and structural edge cases.
]]

package.path = "../?.lua;" .. package.path
local csv_utils = require("csv_to_array2d") 

local function assert_equal(a, b, label)
    local function serialize(v)
        if type(v) == "table" then
            local out = {}
            for i = 1, #v do
                out[i] = serialize(v[i])
            end
            return "{" .. table.concat(out, ", ") .. "}"
        else
            return tostring(v)
        end
    end

    local ok = true
    if type(a) == "table" and type(b) == "table" then
        if #a ~= #b then
            ok = false
        else
            for i = 1, #a do
                if type(a[i]) == "table" and type(b[i]) == "table" then
                    for j = 1, #a[i] do
                        if a[i][j] ~= b[i][j] then ok = false break end
                    end
                elseif a[i] ~= b[i] then
                    ok = false
                end
            end
        end
    else
        ok = a == b
    end

    if not ok then
        error(label .. " failed.\nExpected: " .. serialize(b) .. "\nGot     : " .. serialize(a))
    else
        print(label .. " passed.")
    end
end

-- Test 1: Basic CSV parsing
local csv = [[
a,b,c
1,2,3
x,y,z
]]
local expected = {
    {"a","b","c"},
    {"1","2","3"},
    {"x","y","z"}
}

local parsed = csv_utils.csv_to_array2d(csv)
assert_equal(parsed, expected, "Basic CSV parsing")

-- Test 2: Round-trip
local roundtrip = csv_utils.array2d_to_csv(parsed)
local reparsed = csv_utils.csv_to_array2d(roundtrip)
assert_equal(reparsed, expected, "Round-trip parse and serialize")

-- Test 3: Quoted values and commas
local csv2 = [["a,1","b""2","c
newline"]]
local expected2 = {
    {"a,1", 'b"2', "c\nnewline"}
}
local parsed2 = csv_utils.csv_to_array2d(csv2)
assert_equal(parsed2, expected2, "Quoted values with commas and newlines")

-- Test 4: Empty cells and lines
local csv3 = [[
a,b,,
1,,3,
,,
]]
local expected3 = {
    {"a", "b", "", ""},
    {"1", "", "3", ""},
    {"", "", "", ""}
}
local parsed3 = csv_utils.csv_to_array2d(csv3)
assert_equal(parsed3, expected3, "Empty cells and lines")

print("All tests passed.")


-- Part 2: Start with array2d and generate CSV

local function normalize_newlines(s)
    return s:gsub("\r\n", "\n"):gsub("\r", "\n") -- For cross-platform consistency
end

local function assert_csv_equal(actual_csv, expected_csv, label)
    if normalize_newlines(actual_csv) ~= normalize_newlines(expected_csv) then
        error(label .. " failed.\nExpected:\n" .. expected_csv .. "\nGot:\n" .. actual_csv)
    else
        print(label .. " passed.")
    end
end

-- Test 1: Basic quoted values
local array1 = {
    {"a", "b", "c"},
    {"1", "2", "3"},
    {"x", "y", "z"}
}
local expected_csv1 = [["a","b","c"
"1","2","3"
"x","y","z"]]
local csv1 = csv_utils.array2d_to_csv(array1)
assert_csv_equal(csv1, expected_csv1, "CSV generation (basic)")

-- Test 2: Escaping quotes and commas
local array2 = {
    {'"quoted"', 'with,comma', 'normal'}
}
local expected_csv2 = [["""quoted""","with,comma","normal"]]
local csv2 = csv_utils.array2d_to_csv(array2)
assert_csv_equal(csv2, expected_csv2, "CSV generation (escaping)")

-- Test 3: Roundtrip check again
local parsed_back = csv_utils.csv_to_array2d(csv2)
assert_equal(parsed_back, array2, "CSV roundtrip from array2d")

-- Test 4: Empty strings and whitespace
local array3 = {
    {"", " ", "  text  "}
}
local expected_csv3 = [[""," ","  text  "]]
local csv3 = csv_utils.array2d_to_csv(array3)
assert_csv_equal(csv3, expected_csv3, "CSV generation (empty/whitespace)")

-- Test 5: Newlines inside values
local array4 = {
    {"multi\nline", "ok"}
}
local expected_csv4 = [["multi
line","ok"]]
local csv4 = csv_utils.array2d_to_csv(array4)
assert_csv_equal(csv4, expected_csv4, "CSV generation (newlines)")

print("All Part 2 tests passed.")

