-- luajit tests/test_koth.lua (run from mod root): King of the Hill rules vs shared vectors
package.path = "tests/?.lua;" .. package.path
local json = require("dkjson")
local K = dofile("networking/koth_rules.lua")
local f = assert(io.open("tests/koth_vectors.json")); local V = json.decode(f:read("*a")); f:close()
local gt = function(a, b) return a > b end
local eq = function(a, b) return a == b end
local n = 0
for _, c in ipairs(V.cases) do
	local ids = {}
	for id in pairs(c.scores) do ids[#ids + 1] = id end
	table.sort(ids)
	local entries = {}
	for _, id in ipairs(ids) do entries[#entries + 1] = { id = id, name = "n" .. id, score = c.scores[id] } end
	-- the server's attrition rule: single lowest score loses a life
	local low, cnt = nil, 0
	for _, e in ipairs(entries) do
		if not low or e.score < low.score then low, cnt = e, 1 elseif e.score == low.score then cnt = cnt + 1 end
	end
	local loser = cnt == 1 and low.id or nil
	local st = { kingId = c.state.kingId ~= json.null and c.state.kingId or nil, streak = c.state.streak }
	local ev = K.resolve(st, entries, loser, gt, eq, K.config(c.options))
	local final_loser = (loser ~= ev.shieldedId) and loser or nil
	for k, want in pairs(c.expect) do
		local got
		if k == "loser" then got = final_loser else got = ev[k] end
		if want == json.null then want = nil end
		if k ~= "crowned" or want then
			assert(got == want, string.format("%s: %s = %s, want %s", c.name, k, tostring(got), tostring(want)))
		end
	end
	assert(st.kingId == ev.kingId and st.streak == ev.streak, c.name .. ": state mismatch")
	if ev.kingId then assert(ev.kingName == "n" .. ev.kingId, c.name .. ": kingName") end
	print("ok: " .. c.name); n = n + 1
end
local snap = K.snapshot({ kingId = "A", streak = 2 }, { A = "Alice" }, K.config({ koth_hold_target = "5" }))
assert(snap.kingName == "Alice" and snap.bounty == 2 and snap.holdTarget == 5 and snap.snapshot)
assert(K.config({ koth_hold_target = "99", starting_lives = "2" }).hold_target == 4 and K.config({ starting_lives = "2" }).starting_lives == 2)
print("PASS test_koth (" .. n .. " vectors)")
