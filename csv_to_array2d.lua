local function next_token(csv, cursor, delimiter)
    local len = #csv
    local p = cursor

    -- Skip whitespace (optional)
    while p <= len and (csv:sub(p,p) == ' ' or csv:sub(p,p) == '\t') do
        p = p + 1
    end

    local start = p

    if p > len then
        return { type = "end", start = p, end_ = p }, p
    end

    local char = csv:sub(p, p)
    if char == delimiter then
        return { type = "comma", start = p, end_ = p + 1 }, p + 1
    elseif char == '\r' or char == '\n' then
        local next_char = csv:sub(p + 1, p + 1)
        local newline_len = (char == '\r' and next_char == '\n') and 2 or 1
        return { type = "newline", start = p, end_ = p + newline_len }, p + newline_len
    else
        if char == '"' then
            -- Quoted value
            p = p + 1
            start = p
            local value = {}
            while p <= len do
                local c = csv:sub(p, p)
                if c == '"' then
                    local next_c = csv:sub(p + 1, p + 1)
                    if next_c == '"' then
                        table.insert(value, '"')
                        p = p + 2
                    else
                        break
                    end
                else
                    table.insert(value, c)
                    p = p + 1
                end
            end
            p = p + 1 -- skip closing quote
            return { type = "value", text = table.concat(value), start = start, end_ = p }, p
        else
            -- Unquoted value
            while p <= len do
                local c = csv:sub(p, p)
                if c == delimiter or c == '\r' or c == '\n' then break end
                p = p + 1
            end
            return { type = "value", text = csv:sub(start, p - 1), start = start, end_ = p }, p
        end
    end
end

local function csv_to_array2d(csv, delimiter)
    delimiter = delimiter or ','
    local result = {}
    local row = {}
    local row_index = 1
    local col_index = 1
    local cursor = 1

    while true do
        local token
        token, cursor = next_token(csv, cursor, delimiter)

        if token.type == "end" then
            if #row > 0 then
                result[row_index] = row
            end
            break
        elseif token.type == "value" then
            row[col_index] = token.text
        elseif token.type == "comma" then
            col_index = col_index + 1
        elseif token.type == "newline" then
            result[row_index] = row
            row_index = row_index + 1
            row = {}
            col_index = 1
        else
            error("Unknown token type: " .. tostring(token.type))
        end
    end

    return result
end

local function array2d_to_csv(array2d)
    assert(type(array2d)=="table")
    local lines = {}
    
    for i = 1, #array2d do
        assert(type(array2d[i])=="table", type(array2d[i]))
        local line = {}
        for j=1, #array2d[i] do
            table.insert(line, '"'..array2d[i][j]:gsub('"', '""')..'"')
        end
        table.insert(lines, table.concat(line, ","))
    end
    return table.concat(lines, "\n")
end

return {csv_to_array2d=csv_to_array2d, array2d_to_csv=array2d_to_csv}

