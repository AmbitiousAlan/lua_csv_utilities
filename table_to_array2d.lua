local deepcopy = (require("lua_users_utilities")).deepcopy


local function insert_cell_value(v, v_list, ref)
    if type(v)=="table" then
        table.insert(v_list, "@"..tostring(ref))
    elseif type(v)=="number" then
        table.insert(v_list, tostring(v))
    elseif type(v)=="string" then
        table.insert(v_list, tostring(v))
    else
        error("Type "..type(v).." not supported", 3)
    end
end

local function read_cell_value(nodes, cell_value, ref_divider)
    if "@"==cell_value:sub(1, 1) then
        local ref = tonumber(cell_value:sub(2))
        if type(ref)~="number" then error("There is a reference "..cell_value.." where the reference cannot be evaluated to a number") end
        ref = math.floor(ref/ref_divider)+1
        return nodes[ref].t
    end
    return tonumber(cell_value) or cell_value
end

local function get_sorted_keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

local function get_keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

local function new_node(t, edge_to_parent, initial_path_to_t)
    return {t=t, edge_to_parent=edge_to_parent, initial_path_to_t=initial_path_to_t}
end

local function is_node(maybe_node)
    return type(maybe_node)~="table" or type(maybe_node.t) ~="table" or type(maybe_node.edge_to_parent) ~="table" or type(maybe_node.initial_path_to_t) ~="table"
end

local function table_to_nodes(t, branch_filter)
    local nodes = {}
    local ref_to_node = {}
    
    local todo = {new_node(t, {}, {})}
    local done = {}
    
    while todo[1] ~= nil do
        local current_node = table.remove(todo)
        done[current_node.t] = current_node
        
        if branch_filter==nil or branch_filter(current_node) then
        
            table.insert(nodes, current_node)
            ref_to_node[current_node.t] = current_node
            current_node.i = #nodes
            
            --we don't need get_sorted_keys if we are okay with the order being random/non-deterministic
            local keys = get_sorted_keys(current_node.t)
            
            for i = 1, #keys do
                local k = keys[i]
                local v = current_node.t[k]
                if type(v)=="table" then
                    if not done[v] then
                        local initial_path_to_t = deepcopy(current_node.initial_path_to_t)
                        table.insert(initial_path_to_t, k)
                        table.insert(todo, new_node(v, {[k]=current_node.t}, initial_path_to_t))
                    else
                        done[v].edge_to_parent[k] = current_node
                    end
                end
            end 
        end
    end
    
    return nodes, ref_to_node
end

local function table_to_array2d(t, branch_filter, kv_filter)
    if (not (branch_filter==nil or type(branch_filter)=="function")) then error("branch filter is not nil or a function", 2) end
    
    local nodes, ref_to_node = table_to_nodes(t, branch_filter)
    
    
    local array2d = {}
    
    for i = 0, #nodes-1 do
        array2d[1+4*i] = {}
        array2d[1+4*i+1] = {}
        array2d[1+4*i+2] = {}
        array2d[1+4*i+3] = {}
        
        local e_list = array2d[1+4*i]
        local p_list = array2d[1+4*i+1]
        local k_list = array2d[1+4*i+2]
        local v_list = array2d[1+4*i+3]
        
        table.insert(e_list, "e")
        table.insert(p_list, "p")
        table.insert(k_list, "k")
        table.insert(v_list, "v")
        
        local current_node = nodes[1+i]
        
        --we don't need get_sorted_keys if we are okay with the order being random/non-deterministic
        local keys = get_sorted_keys(current_node.edge_to_parent)
        
        for i = 1, #keys do
            local e = keys[i]
            local p = current_node.edge_to_parent[e]
            insert_cell_value(e, e_list, ref_to_node[e] and ref_to_node[e].i*4-3)
            insert_cell_value(p, p_list, ref_to_node[p] and ref_to_node[p].i*4-3)
        end
        
        --we don't need get_sorted_keys if we are okay with the order being random/non-deterministic
        local keys = get_sorted_keys(current_node.t)
        
        for i = 1, #keys do
            local k = keys[i]
            local v = current_node.t[k]
            if kv_filter==nil or kv_filter(current_node, k, v) then
                insert_cell_value(k, k_list, ref_to_node[k] and ref_to_node[k].i*4-3)     
                insert_cell_value(v, v_list, ref_to_node[v] and ref_to_node[v].i*4-3)
            end
        end
    end
    
    return array2d
end

local function max_index(t)
    local ret = 0
    for k, v in pairs(t) do
        if type(k)=="number" and ret < k then
            ret = k
        end
    end
    return ret
end

--never remove a node
local function array2d_to_table(array2d, branch_filter, out_table)
    out_table = out_table or {}
    local nodes = table_to_nodes(out_table, branch_filter)

    --lets not assume that there aren't empty rows
    local last_line = max_index(array2d)
    
    local order = {}
    
    --capture the pattern used
    for i = 1, last_line do
        local line_type = array2d[i][1]
        if order[line_type]==nil then
            table.insert(order, line_type)
            order[line_type] = true
        else
            break
        end
    end

    local i = 1
    
    --add new tables
    local last_index = math.floor(last_line/#order)
    for j= #nodes+1, last_index do
        nodes[j] = new_node({}, {}, {})
    end
    
    while i<last_line do
        local properties = {}
        for j = 1, #order do
            assert(array2d[i+j-1][1]==order[j])
            properties[array2d[i+j-1][1]] = array2d[i+j-1]
        end
        
        local index = math.floor(i/#order)+1
        
        if order['k'] and order['v'] then
            local node = nodes[index]
            local properties_length = max_index(properties['k'])
            for p = 1, properties_length do
                local k = properties['k'][1+p] and read_cell_value(nodes, properties['k'][1+p], #order)
                local v = properties['v'][1+p] and read_cell_value(nodes, properties['v'][1+p], #order)
                if k == "" then k = nil end
                if v == "" then v = nil end
                if k then
                    node.t[k] = v
                end
            end
            
        end
        
        i=i+#order
    end
    
    for j = 1, #nodes do
        local node = nodes[i]
        if node ~= nil then
            local keys = get_keys(node.t)
            for l = 1, #keys do
                local k = keys[i]
                local v = node.t[k]
                node.t[k] = nil
                node.t[read_cell_value(nodes, k)] = read_cell_value(nodes, v)
            end
        end
    end
    
    return out_table
end

return {array2d_to_table=array2d_to_table, table_to_array2d=table_to_array2d, table_to_array2d=table_to_array2d}

