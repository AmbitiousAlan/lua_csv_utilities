package.path = "../?.lua;" .. package.path
local csvluaruntime = require("csvluaruntime")

local state = csvluaruntime.init({"luacsvruntime_test.csv"})
csvluaruntime.load_standard_lib(state)
while csvluaruntime.step(state) do
    print("step")
end

--right now, we expect a bunch to not be processed
for i = 1, #state.corners do
    print("Corner "..csvluaruntime.tostring_corner(state, state.corners[i]).." not processed")
end



