--!nonstrict
--!nolint
-- ============================================================================
-- ENVLOG9MS - DIRECT CONCAT 400KB+ - รวมโค้ดจริงทั้งหมดในไฟล์เดียว
-- เอา combined.lua (303KB) + ultimate (49KB) + allinone (52KB) = 404KB+
-- นี่คือไฟล์ที่ใหญ่สุด ทรงพลังสุด รวมทุกระบบจริงๆ
-- ============================================================================

-- ==================== COMBINED BASE (303KB) ====================
--!nonstrict
--!nolint
-- ============================================================================
-- COMBINED ENVLOGGER v1.0
-- รวม 2 ไฟล์: main.lua (AST + Lune Logger) + envlogger.lua (Larry Proxy Dumper)
-- วันที่รวม: 2026-09-26
-- วิธีทำงาน:
--  1. ลองใช้ hookOp ก่อน (ถ้ามี)
--  2. ลอง EnvLog แบบ AST (ของ main)
--  3. ถ้า output น้อยเกิน (<3 meaningful statements) -> ลอง .r (raw) -> .r2 (aspect)
--  4. [ใหม่] -> .r3 (Larry Proxy Dumper) เป็น fallback สุดท้าย
--  5. บันทึกไฟล์ตาม Settings.out
-- ============================================================================


local DONT_DELETE_FILES = false
local DONE_PROCESSING = false
local NON_ENGLISH = "[\0-\31\189-\255{}]"
local WHILE_LIMIT = 50_000_000
local MAIN_THREAD = coroutine.running()

local TypesLib = require("./mods/types")
local AstLib = require("./mods/ast")
local IsGarbageString, SetGarbageData = unpack(require("./mods/garbage"))

local IsLowerCase = function(byte : number) return byte >= 97 and byte <= 122 end
local IsUpperCase = function(byte : number) return byte >= 65 and byte <= 90 end
local IsBetween = function(n : number, min: number, max : number) return n >= min and n <= max end

--! helper funcs ^^

type AstExpression = TypesLib.AstExpression
type AstBlock = TypesLib.AstBlock
type Spied = TypesLib.Spied
type Variable = string
type func = (...any) -> ...any
type dict = { [any]: any }
type array = { any }
type tbl = dict | array
type VariableData = {
    var: string,
    self: Spied
}
type Internal = {
    [Variable]: { any }
}
type Variables = {
    [any]: Variable
}
type Environment = {
    [string]: (any) -> any | { [string]: any }
}
type P = Instance
type FunctionHooks = {
    [func]: func
}

local Ast = AstLib.Ast

local fenv = getfenv();
local lune_luau = require("@lune/luau")
local loadstring = lune_luau.load
local compile = lune_luau.compile

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = table.clone(require("@lune/roblox"))
local task = require("@lune/task")
local stdio = require("@lune/stdio")

local TIME_TO_WAIT = task.wait();
local LURAPH_COMPRESSED;
local PRINT = print;
local MAX_OPS_MUL = 1;

local Instance = roblox.Instance

-- lune's @lune/roblox does not ship RaycastParams/OverlapParams/PhysicalProperties
-- datatype libs; shim minimal stand-ins so `RaycastParams.new()` etc. keep working.
if not roblox.RaycastParams then
    roblox.RaycastParams = {
        new = function() return { FilterType = "1", RespectCanCollide = true } end,
    }
    roblox.OverlapParams = {
        new = function() return { FilterType = "1", RespectCanCollide = true } end,
    }
end
if not roblox.PhysicalProperties then
    roblox.PhysicalProperties = {
        new = function(...) return {} end,
    }
end

local ExecutorEnvironment = require("./env/exec")
local RandomLib = require("./env/random")
local DateTime = require("./env/datetime")
local InstanceLib, InstanceFuncs = unpack(require("./env/instances"))
local ExploitLib = require("./env/genv")
local RobloxCompat = require("./env/roblox_compat")
local GetTerrainMaterialColor = require("./env/terrain")


-- ==================== LARRY DUMPER (from envlogger.lua) ====================
-- Wrapped as local module to avoid polluting globals
local LarryDumper = (function()
local a = debug
local b = debug.sethook
local c = debug.getinfo
local d = debug.traceback
local e = load
local f = loadstring or load
local g = pcall
local h = xpcall
local i = error
local j = type
local k = getmetatable
local l = rawequal
local m = tostring
local n = tonumber
local o = io
local p = os
local q = {}
q.__index = q
local r = {
    MAX_DEPTH = 15,
    MAX_TABLE_ITEMS = 150,
    OUTPUT_FILE = "dumped_output.lua",
    VERBOSE = false,
    TRACE_CALLBACKS = true,
    TIMEOUT_SECONDS = 6.7,
    MAX_REPEATED_LINES = 6,
    MIN_DEOBF_LENGTH = 150,
    MAX_OUTPUT_SIZE = 6 * 1024 * 1024,
    CONSTANT_COLLECTION = true,
    INSTRUMENT_LOGIC = true
}
local s = arg and arg[3]
if s then
    print("[Dumper] Auto-Input Key Detected: " .. tostring(s))
end
local t = {
    output = {},
    indent = 0,
    registry = {},
    reverse_registry = {},
    names_used = {},
    parent_map = {},
    property_store = {},
    call_graph = {},
    variable_types = {},
    string_refs = {},
    proxy_id = 0,
    callback_depth = 0,
    pending_iterator = false,
    last_http_url = nil,
    last_emitted_line = nil,
    repetition_count = 0,
    current_size = 0,
    lar_counter = 0
}
local s = arg[3] or "NoKey"
local u = tonumber(arg[4]) or tonumber(arg[3]) or 123456789
local v = {}
local function w(x)
    if j(x) ~= "table" then
        return false
    end
    local y, z =
        pcall(
        function()
            return rawget(x, v) == true
        end
    )
    return y and z
end
local function A(x)
    if j(x) == "number" then
        return x
    end
    if w(x) then
        return rawget(x, "__value") or 0
    end
    return 0
end
local e = loadstring or load
local B = print
local C = warn or function()
    end
local D = pairs
local E = ipairs
local j = type
local m = tostring
local F = {}
local function G(x)
    if j(x) ~= "table" then
        return false
    end
    local y, z =
        pcall(
        function()
            return rawget(x, F) == true
        end
    )
    return y and z
end
local function H(x)
    if not G(x) then
        return nil
    end
    return rawget(x, "__proxy_id")
end
local function I(J)
    if j(J) ~= "string" then
        return '"'
    end
    local K = {}
    local L, M = 1, #J
    local function N(O)
        return O:gsub(
            "\\\\(.)",
            function(P)
                if P:match('[abfnrtv\\\\%\'%\\"%[%]0-9xu]') then
                    return "" .. P
                end
                return P
            end
        )
    end
    local function Q(R)
        if not R or R == '"' then
            return ""
        end
        R =
            R:gsub(
            "0[bB]([01_]+)",
            function(S)
                local T = S:gsub("_", "")
                local U = n(T, 2)
                return U and m(U) or "0"
            end
        )
        R =
            R:gsub(
            "0[xX]([%x_]+)",
            function(S)
                local T = S:gsub("_", '"')
                return "0x" .. T
            end
        )
        while R:match("%d_+%d") do
            R = R:gsub("(%d)_+(%d)", "%1%2")
        end
        local V = {{"+=", "+"}, {"-=", "-"}, {"*=", "*"}, {"/=", "/"}, {"%%=", "%%"}, {"%^=", "^"}, {"%.%.=", ".."}}
        for W, X in ipairs(V) do
            local Y, Z = X[1], X[2]
            R =
                R:gsub(
                "([%a_][%w_]*)%s*" .. Y,
                function(_)
                    return _ .. " = " .. _ .. " " .. Z .. " "
                end
            )
            R =
                R:gsub(
                "([%a_][%w_]*%.[%a_][%w_%.]+)%s*" .. Y,
                function(_)
                    return _ .. " = " .. _ .. " " .. Z .. " "
                end
            )
            R =
                R:gsub(
                "([%a_][%w_]*%b[])%s*" .. Y,
                function(_)
                    return _ .. " = " .. _ .. " " .. Z .. " "
                end
            )
        end
        R = R:gsub("([^%w_])continue([^%w_])", "%1_G.LuraphContinue()%2")
        R = R:gsub("^continue([^%w_])", "_G.LuraphContinue()%1")
        R = R:gsub("([^%w_])continue$", "%1_G.LuraphContinue()")
        return R
    end
    local function a0(a1)
        local a2 = 0
        while a1 <= M and J:byte(a1) == 61 do
            a2 = a2 + 1
            a1 = a1 + 1
        end
        return a2, a1
    end
    local function a3(a4, a5)
        local a6 = "]" .. string.rep("=", a5) .. "]"
        local a7, a8 = J:find(a6, a4, true)
        return a8 or M
    end
    local a9 = 1
    while L <= M do
        local aa = J:byte(L)
        if aa == 91 then
            local a5, ab = a0(L + 1)
            if ab <= M and J:byte(ab) == 91 then
                table.insert(K, Q(J:sub(a9, L - 1)))
                local ac = L
                local ad = a3(ab + 1, a5)
                table.insert(K, J:sub(ac, ad))
                L = ad
                a9 = L + 1
            end
        elseif aa == 45 and L + 1 <= M and J:byte(L + 1) == 45 then
            table.insert(K, Q(J:sub(a9, L - 1)))
            local ae = L
            if L + 2 <= M and J:byte(L + 2) == 91 then
                local a5, ab = a0(L + 3)
                if ab <= M and J:byte(ab) == 91 then
                    local ad = a3(ab + 1, a5)
                    table.insert(K, J:sub(ae, ad))
                    L = ad
                    a9 = L + 1
                    L = L + 1
                end
            end
            local af = J:find("\n", L + 2, true)
            if af then
                L = af
            else
                L = M
            end
            table.insert(K, J:sub(ae, L))
            a9 = L + 1
        elseif aa == 34 or aa == 39 or aa == 96 then
            table.insert(K, Q(J:sub(a9, L - 1)))
            local ag = aa
            local ac = L
            L = L + 1
            while L <= M do
                local ah = J:byte(L)
                if ah == 92 then
                    L = L + 1
                elseif ah == ag then
                    break
                end
                L = L + 1
            end
            local ai = J:sub(ac + 1, L - 1)
            ai = N(ai)
            if ag == 96 then
                table.insert(K, '"' .. ai:gsub('"', '\\\\"') .. '"')
            else
                local aj = string.char(ag)
                table.insert(K, aj .. ai .. aj)
            end
            a9 = L + 1
        end
        L = L + 1
    end
    table.insert(K, Q(J:sub(a9)))
    return table.concat(K)
end
local function ak(al, am)
    local R, an = e(al, am)
    if R then
        return R
    end
    B("\n[CRITICAL ERROR] Failed to load script!")
    B("[LUA_LOAD_FAIL] " .. m(an))
    local ao = tonumber(an:match(":(%d+):"))
    local ap = an:match("near '([^']+)'")
    if ap then
        local a1 = al:find(ap, 1, true)
        if a1 then
            local aq = math.max(1, a1 - 50)
            local ar = math.min(#al, a1 + 50)
            B("Context around error:")
            B("..." .. al:sub(aq, ar) .. "...")
        end
    end
    local as = o.open("DEBUG_FAILED_TRANSPILE.lua", "w")
    if as then
        as:write(al)
        as:close()
        B("[*] Saved to 'DEBUG_FAILED_TRANSPILE.lua' for inspection")
    end
    return nil, an
end
local function at(O, au)
    if t.limit_reached then
        return
    end
    if O == nil then
        return
    end
    local av = au and "" or string.rep("    ", t.indent)
    local aw = av .. m(O)
    local ax = #aw + 1
    if t.current_size + ax > r.MAX_OUTPUT_SIZE then
        t.limit_reached = true
        local ay = "-- [CRITICAL] Dump stopped: File size exceeded 6MB limit."
        table.insert(t.output, ay)
        t.current_size = t.current_size + #ay
        error("DUMP_LIMIT_EXCEEDED")
    end
    if aw == t.last_emitted_line then
        t.repetition_count = t.repetition_count + 1
        if t.repetition_count <= r.MAX_REPEATED_LINES then
            table.insert(t.output, aw)
            t.current_size = t.current_size + ax
        elseif t.repetition_count == r.MAX_REPEATED_LINES + 1 then
            local ay = av .. "-- [Repeated lines suppressed...]"
            table.insert(t.output, ay)
            t.current_size = t.current_size + #ay
        end
    else
        t.last_emitted_line = aw
        t.repetition_count = 0
        table.insert(t.output, aw)
        t.current_size = t.current_size + ax
    end
    if r.VERBOSE and t.repetition_count <= 1 then
        B(aw)
    end
end
local function az(O)
    at("-- " .. m(O or ""))
end
local function aA()
    t.last_emitted_line = nil
    table.insert(t.output, "")
end
local function aB()
    return table.concat(t.output, "\n")
end
local function aC(aD)
    local as = o.open(aD or r.OUTPUT_FILE, "w")
    if as then
        as:write(aB())
        as:close()
        return true
    end
    return false
end
local function aE(aF)
    if aF == nil then
        return "nil"
    end
    if j(aF) == "string" then
        return aF
    end
    if j(aF) == "number" or j(aF) == "boolean" then
        return m(aF)
    end
    if j(aF) == "table" then
        if t.registry[aF] then
            return t.registry[aF]
        end
        if G(aF) then
            local aG = H(aF)
            return aG and "proxy_" .. aG or "proxy"
        end
    end
    local y, O = pcall(m, aF)
    return y and O or "unknown"
end
local function aH(aF)
    local O = aE(aF)
    local aI =
        O:gsub("\\\\", "\\\\\\\\"):gsub('"', '\\\\"'):gsub("\n", "\n"):gsub("\\r", "\\\\r"):gsub("\\t", "\\\\t")
    return '"' .. aI .. '"'
end
local aJ = {
    Players = "Players",
    Workspace = "Workspace",
    ReplicatedStorage = "ReplicatedStorage",
    ServerStorage = "ServerStorage",
    ServerScriptService = "ServerScriptService",
    StarterGui = "StarterGui",
    StarterPack = "StarterPack",
    StarterPlayer = "StarterPlayer",
    Lighting = "Lighting",
    SoundService = "SoundService",
    Chat = "Chat",
    RunService = "RunService",
    UserInputService = "UserInputService",
    TweenService = "TweenService",
    HttpService = "HttpService",
    MarketplaceService = "MarketplaceService",
    TeleportService = "TeleportService",
    PathfindingService = "PathfindingService",
    CollectionService = "CollectionService",
    PhysicsService = "PhysicsService",
    ProximityPromptService = "ProximityPromptService",
    ContextActionService = "ContextActionService",
    GuiService = "GuiService",
    HapticService = "HapticService",
    VRService = "VRService",
    CoreGui = "CoreGui",
    Teams = "Teams",
    InsertService = "InsertService",
    DataStoreService = "DataStoreService",
    MessagingService = "MessagingService",
    TextService = "TextService",
    TextChatService = "TextChatService",
    ContentProvider = "ContentProvider",
    Debris = "Debris"
}
local aK = {
    Players = "Players",
    UserInputService = "UIS",
    RunService = "RunService",
    ReplicatedStorage = "ReplicatedStorage",
    TweenService = "TweenService",
    Workspace = "Workspace",
    Lighting = "Lighting",
    StarterGui = "StarterGui",
    CoreGui = "CoreGui",
    HttpService = "HttpService",
    MarketplaceService = "MarketplaceService",
    DataStoreService = "DataStoreService",
    TeleportService = "TeleportService",
    SoundService = "SoundService",
    Chat = "Chat",
    Teams = "Teams",
    ProximityPromptService = "ProximityPromptService",
    ContextActionService = "ContextActionService",
    CollectionService = "CollectionService",
    PathfindingService = "PathfindingService",
    Debris = "Debris"
}
local aL = {
    {pattern = "window", prefix = "Window", counter = "window"},
    {pattern = "tab", prefix = "Tab", counter = "tab"},
    {pattern = "section", prefix = "Section", counter = "section"},
    {pattern = "button", prefix = "Button", counter = "button"},
    {pattern = "toggle", prefix = "Toggle", counter = "toggle"},
    {pattern = "slider", prefix = "Slider", counter = "slider"},
    {pattern = "dropdown", prefix = "Dropdown", counter = "dropdown"},
    {pattern = "textbox", prefix = "Textbox", counter = "textbox"},
    {pattern = "input", prefix = "Input", counter = "input"},
    {pattern = "label", prefix = "Label", counter = "label"},
    {pattern = "keybind", prefix = "Keybind", counter = "keybind"},
    {pattern = "colorpicker", prefix = "ColorPicker", counter = "colorpicker"},
    {pattern = "paragraph", prefix = "Paragraph", counter = "paragraph"},
    {pattern = "notification", prefix = "Notification", counter = "notification"},
    {pattern = "divider", prefix = "Divider", counter = "divider"},
    {pattern = "bind", prefix = "Bind", counter = "bind"},
    {pattern = "picker", prefix = "Picker", counter = "picker"}
}
local aM = {}
local function aN(aO)
    aM[aO] = (aM[aO] or 0) + 1
    return aM[aO]
end
local function aP(aQ, aR, aS)
    if not aQ then
        aQ = "var"
    end
    local aT = aE(aQ)
    if aK[aT] then
        return aK[aT]
    end
    if aS then
        local aU = aS:lower()
        for W, aV in ipairs(aL) do
            if aU:find(aV.pattern) then
                local a2 = aN(aV.counter)
                return a2 == 1 and aV.prefix or aV.prefix .. a2
            end
        end
    end
    if aT == "LocalPlayer" then
        return "LocalPlayer"
    end
    if aT == "Character" then
        return "Character"
    end
    if aT == "Humanoid" then
        return "Humanoid"
    end
    if aT == "HumanoidRootPart" then
        return "HumanoidRootPart"
    end
    if aT == "Camera" then
        return "Camera"
    end
    if aT:match("^Enum%.") then
        return aT
    end
    local T = aT:gsub("[^%w_]", '"'):gsub("^%d+", '"')
    if T == '"' or T == "Object" or T == "Value" or T == "result" then
        T = "var"
    end
    return T
end
local function aW(x, aQ, aX, aS)
    local aY = t.registry[x]
    if aY and aY:match("^lar%d+$") then
        return aY
    end
    t.lar_counter = (t.lar_counter or 0) + 1
    local am = "lar" .. t.lar_counter
    t.names_used[am] = true
    t.registry[x] = am
    t.reverse_registry[am] = x
    t.variable_types[am] = aX or j(x)
    return am
end
local function aZ(aF, a_, b0, b1)
    a_ = a_ or 0
    b0 = b0 or {}
    if a_ > r.MAX_DEPTH then
        return "{ --[[max depth]] }"
    end
    local b2 = j(aF)
    if w(aF) then
        local b3 = rawget(aF, "__value")
        return m(b3 or 0)
    end
    if b2 == "table" and t.registry[aF] then
        return t.registry[aF]
    end
    if b2 == "nil" then
        return "nil"
    elseif b2 == "string" then
        if #aF > 100 and aF:match("^[A-Za-z0-9+/=]+$") then
            table.insert(t.string_refs, {value = aF:sub(1, 50) .. "...", hint = "base64", full_length = #aF})
        elseif aF:match("https?://") then
            table.insert(t.string_refs, {value = aF, hint = "URL"})
        elseif aF:match("rbxasset://") or aF:match("rbxassetid://") then
            table.insert(t.string_refs, {value = aF, hint = "Asset"})
        end
        return aH(aF)
    elseif b2 == "number" then
        if aF ~= aF then
            return "0/0"
        end
        if aF == math.huge then
            return "math.huge"
        end
        if aF == -math.huge then
            return "-math.huge"
        end
        if aF == math.floor(aF) then
            return m(math.floor(aF))
        end
        return string.format("%.6g", aF)
    elseif b2 == "boolean" then
        return m(aF)
    elseif b2 == "function" then
        if t.registry[aF] then
            return t.registry[aF]
        end
        return "function() end"
    elseif b2 == "table" then
        if G(aF) then
            return t.registry[aF] or "proxy"
        end
        if b0[aF] then
            return "{ --[[circular]] }"
        end
        b0[aF] = true
        local a2 = 0
        for b4, b5 in D(aF) do
            if b4 ~= F and b4 ~= "__proxy_id" then
                a2 = a2 + 1
            end
        end
        if a2 == 0 then
            return "{}"
        end
        local b6 = true
        local b7 = 0
        for b4, b5 in D(aF) do
            if b4 ~= F and b4 ~= "__proxy_id" then
                if j(b4) ~= "number" or b4 < 1 or b4 ~= math.floor(b4) then
                    b6 = false
                    break
                else
                    b7 = math.max(b7, b4)
                end
            end
        end
        b6 = b6 and b7 == a2
        if b6 and a2 <= 5 and b1 ~= false then
            local b8 = {}
            for L = 1, a2 do
                local b5 = aF[L]
                if j(b5) ~= "table" or G(b5) then
                    table.insert(b8, aZ(b5, a_ + 1, b0, true))
                else
                    b6 = false
                    break
                end
            end
            if b6 and #b8 == a2 then
                return "{" .. table.concat(b8, ", ") .. "}"
            end
        end
        local b9 = {}
        local ba = 0
        local bb = string.rep("    ", t.indent + a_ + 1)
        local bc = string.rep("    ", t.indent + a_)
        for b4, b5 in D(aF) do
            if b4 ~= F and b4 ~= "__proxy_id" then
                ba = ba + 1
                if ba > r.MAX_TABLE_ITEMS then
                    table.insert(b9, bb .. "-- ..." .. a2 - ba + 1 .. " more")
                    break
                end
                local bd
                if b6 then
                    bd = nil
                elseif j(b4) == "string" and b4:match("^[%a_][%w_]*$") then
                    bd = b4
                else
                    bd = "[" .. aZ(b4, a_ + 1, b0) .. "]"
                end
                local be = aZ(b5, a_ + 1, b0)
                if bd then
                    table.insert(b9, bb .. bd .. " = " .. be)
                else
                    table.insert(b9, bb .. be)
                end
            end
        end
        if #b9 == 0 then
            return "{}"
        end
        return "{\n" .. table.concat(b9, ",\n") .. "\n" .. bc .. "}"
    elseif b2 == "userdata" then
        if t.registry[aF] then
            return t.registry[aF]
        end
        local y, O = pcall(m, aF)
        return y and O or "userdata"
    elseif b2 == "thread" then
        return "coroutine.create(function() end)"
    else
        local y, O = pcall(m, aF)
        return y and O or "nil"
    end
end
local bf = {}
setmetatable(bf, {__mode = "k"})
local function bg()
    local bh = {}
    bf[bh] = true
    local bi = {}
    setmetatable(bh, bi)
    return bh, bi
end
local function G(x)
    return bf[x] == true
end
local bj
local bk
local function bl(bm)
    local bh, bi = bg()
    rawset(bh, v, true)
    rawset(bh, "__value", bm)
    t.registry[bh] = tostring(bm)
    bi.__tostring = function()
        return tostring(bm)
    end
    bi.__index = function(b2, b4)
        if b4 == F or b4 == "__proxy_id" or b4 == v or b4 == "__value" then
            return rawget(b2, b4)
        end
        return bl(0)
    end
    bi.__newindex = function()
    end
    bi.__call = function()
        return bm
    end
    local function bn(X)
        return function(bo, aa)
            local bp = type(bo) == "table" and rawget(bo, "__value") or bo or 0
            local bq = type(aa) == "table" and rawget(aa, "__value") or aa or 0
            local z
            if X == "+" then
                z = bp + bq
            elseif X == "-" then
                z = bp - bq
            elseif X == "*" then
                z = bp * bq
            elseif X == "/" then
                z = bq ~= 0 and bp / bq or 0
            elseif X == "%" then
                z = bq ~= 0 and bp % bq or 0
            elseif X == "^" then
                z = bp ^ bq
            else
                z = 0
            end
            return bl(z)
        end
    end
    bi.__add = bn("+")
    bi.__sub = bn("-")
    bi.__mul = bn("*")
    bi.__div = bn("/")
    bi.__mod = bn("%")
    bi.__pow = bn("^")
    bi.__unm = function(bo)
        return bl(-(rawget(bo, "__value") or 0))
    end
    bi.__eq = function(bo, aa)
        local bp = type(bo) == "table" and rawget(bo, "__value") or bo
        local bq = type(aa) == "table" and rawget(aa, "__value") or aa
        return bp == bq
    end
    bi.__lt = function(bo, aa)
        local bp = type(bo) == "table" and rawget(bo, "__value") or bo
        local bq = type(aa) == "table" and rawget(aa, "__value") or aa
        return bp < bq
    end
    bi.__le = function(bo, aa)
        local bp = type(bo) == "table" and rawget(bo, "__value") or bo
        local bq = type(aa) == "table" and rawget(aa, "__value") or aa
        return bp <= bq
    end
    bi.__len = function()
        return 0
    end
    return bh
end
local function br(bs, bt)
    if j(bs) ~= "function" then
        return {}
    end
    local a4 = #t.output
    local bu = t.pending_iterator
    t.pending_iterator = false
    xpcall(
        function()
            bs(table.unpack(bt or {}))
        end,
        function()
        end
    )
    while t.pending_iterator do
        t.indent = t.indent - 1
        at("end")
        t.pending_iterator = false
    end
    t.pending_iterator = bu
    local bv = {}
    for L = a4 + 1, #t.output do
        table.insert(bv, t.output[L])
    end
    for L = #t.output, a4 + 1, -1 do
        table.remove(t.output, L)
    end
    return bv
end
bk = function(aS, bw)
    local bh, bi = bg()
    local bx = t.registry[bw] or "object"
    local by = aE(aS)
    t.registry[bh] = bx .. "." .. by
    bi.__call = function(self, bz, ...)
        local bA
        if bz == bh or bz == bw or G(bz) then
            bA = {...}
        else
            bA = {bz, ...}
        end
        local aU = by:lower()
        local bB = nil
        local bC = true
        for W, aV in ipairs(aL) do
            if aU:find(aV.pattern) then
                bB = aV.prefix
                break
            end
        end
        local bD = nil
        local bE = nil
        local bF = nil
        for L, b5 in ipairs(bA) do
            if j(b5) == "function" then
                bD = b5
                break
            elseif j(b5) == "table" and not G(b5) then
                for bG, aF in D(b5) do
                    local bH = m(bG):lower()
                    if bH == "callback" and j(aF) == "function" then
                        bD = aF
                        bE = bG
                        bF = L
                        break
                    end
                end
            end
        end
        local bI = "value"
        local bt = {}
        if bD then
            if aU:match("toggle") then
                bI = "enabled"
                bt = {true}
            elseif aU:match("slider") then
                bI = "value"
                bt = {50}
            elseif aU:match("dropdown") then
                bI = "selected"
                bt = {"Option"}
            elseif aU:match("textbox") or aU:match("input") then
                bI = "text"
                bt = {s or "input"}
            elseif aU:match("keybind") or aU:match("bind") then
                bI = "key"
                bt = {bj("Enum.KeyCode.E", false)}
            elseif aU:match("color") then
                bI = "color"
                bt = {Color3.fromRGB(255, 255, 255)}
            elseif aU:match("button") then
                bI = "\\"
                bt = {}
            end
        end
        local bJ = {}
        if bD then
            bJ = br(bD, bt)
        end
        local z = bj(bB or by, false, bw)
        local _ = aW(z, bB or by, nil, by)
        local bK = {}
        for L, b5 in ipairs(bA) do
            if j(b5) == "table" and not G(b5) and L == bF then
                local b8 = {}
                for bG, aF in D(b5) do
                    local bd
                    if j(bG) == "string" and bG:match("^[%a_][%w_]*$") then
                        bd = bG
                    else
                        bd = "[" .. aZ(bG) .. "]"
                    end
                    if bG == bE and #bJ > 0 then
                        local bL = bI ~= '"' and "function(" .. "bI" .. ")" or "function()"
                        local bb = string.rep("    ", t.indent + 2)
                        local bM = {}
                        for W, aw in ipairs(bJ) do
                            table.insert(bM, bb .. (aw:match("^%s*(.*)$") or aw))
                        end
                        local bc = string.rep("    ", t.indent + 1)
                        table.insert(b8, bd .. " = " .. bL .. "\n" .. table.concat(bM, "\n") .. "\n" .. bc .. "end")
                    elseif bG == bE then
                        local bN = bI ~= "\\" and "function(" .. bI .. ") end" or "function() end"
                        table.insert(b8, bd .. " = " .. bN)
                    else
                        table.insert(b8, bd .. " = " .. aZ(aF))
                    end
                end
                table.insert(
                    bK,
                    "{\n" ..
                        string.rep("    ", t.indent + 1) ..
                            table.concat(b8, ",\n" .. string.rep("    ", t.indent + 1)) ..
                                "\n" .. string.rep("    ", t.indent) .. "}"
                )
            elseif j(b5) == "function" then
                if #bJ > 0 then
                    local bL = bI ~= '"' and "function(" .. bI .. ")" or "function()"
                    local bb = string.rep("    ", t.indent + 1)
                    local bM = {}
                    for W, aw in ipairs(bJ) do
                        table.insert(bM, bb .. (aw:match("^%s*(.*)$") or aw))
                    end
                    table.insert(
                        bK,
                        bL .. "\n" .. table.concat(bM, "\n") .. "\n" .. string.rep("    ", t.indent) .. "end"
                    )
                else
                    local bN = bI ~= '"' and "function(" .. bI .. ") end" or "function() end"
                    table.insert(bK, bN)
                end
            else
                table.insert(bK, aZ(b5))
            end
        end
        at(string.format("local %s = %s:%s(%s)", _, bx, by, table.concat(bK, ", ")))
        return z
    end
    bi.__index = function(b2, b4)
        if b4 == F or b4 == "__proxy_id" then
            return rawget(b2, b4)
        end
        return bk(b4, bh)
    end
    bi.__tostring = function()
        return bx .. ":" .. by
    end
    return bh
end
bj = function(aQ, bO, bw)
    local bh, bi = bg()
    local aT = aE(aQ)
    t.property_store[bh] = {}
    if bO then
        t.registry[bh] = aT
        t.names_used[aT] = true
    elseif bw then
        t.parent_map[bh] = bw
        rawset(bh, "__temp_path", (t.registry[bw] or "object") .. "." .. aT)
    end
    local bP = {}
    bP.GetService = function(self, bQ)
        local bR = aE(bQ)
        local x = bj(bR, false, bh)
        local _ = aW(x, bR)
        local bS = t.registry[bh] or "game"
        at(string.format("local %s = %s:GetService(%s)", _, bS, aH(bR)))
        return x
    end
    bP.WaitForChild = function(self, bT, bU)
        local bV = aE(bT)
        local x = bj(bV, false, bh)
        local _ = aW(x, bV)
        local bS = t.registry[bh] or "object"
        if bU then
            at(string.format("local %s = %s:WaitForChild(%s, %s)", _, bS, aH(bV), aZ(bU)))
        else
            at(string.format("local %s = %s:WaitForChild(%s)", _, bS, aH(bV)))
        end
        return x
    end
    bP.FindFirstChild = function(self, bT, bW)
        local bV = aE(bT)
        local x = bj(bV, false, bh)
        local _ = aW(x, bV)
        local bS = t.registry[bh] or "object"
        if bW then
            at(string.format("local %s = %s:FindFirstChild(%s, true)", _, bS, aH(bV)))
        else
            at(string.format("local %s = %s:FindFirstChild(%s)", _, bS, aH(bV)))
        end
        return x
    end
    bP.FindFirstChildOfClass = function(self, bX)
        local bY = aE(bX)
        local x = bj(bY, false, bh)
        local _ = aW(x, bY)
        local bS = t.registry[bh] or "object"
        at(string.format("local %s = %s:FindFirstChildOfClass(%s)", _, bS, aH(bY)))
        return x
    end
    bP.FindFirstChildWhichIsA = function(self, bX)
        local bY = aE(bX)
        local x = bj(bY, false, bh)
        local _ = aW(x, bY)
        local bS = t.registry[bh] or "object"
        at(string.format("local %s = %s:FindFirstChildWhichIsA(%s)", _, bS, aH(bY)))
        return x
    end
    bP.FindFirstAncestor = function(self, am)
        local bZ = aE(am)
        local x = bj(bZ, false, bh)
        local _ = aW(x, bZ)
        local bS = t.registry[bh] or "object"
        at(string.format("local %s = %s:FindFirstAncestor(%s)", _, bS, aH(bZ)))
        return x
    end
    bP.FindFirstAncestorOfClass = function(self, bX)
        local bY = aE(bX)
        local x = bj(bY, false, bh)
        local _ = aW(x, bY)
        local bS = t.registry[bh] or "object"
        at(string.format("local %s = %s:FindFirstAncestorOfClass(%s)", _, bS, aH(bY)))
        return x
    end
    bP.FindFirstAncestorWhichIsA = function(self, bX)
        local bY = aE(bX)
        local x = bj(bY, false, bh)
        local _ = aW(x, bY)
        local bS = t.registry[bh] or "object"
        at(string.format("local %s = %s:FindFirstAncestorWhichIsA(%s)", _, bS, aH(bY)))
        return x
    end
    bP.GetChildren = function(self)
        local bS = t.registry[bh] or "object"
        at(string.format("for _, child in %s:GetChildren() do", bS))
        t.indent = t.indent + 1
        t.pending_iterator = true
        return {}
    end
    bP.GetDescendants = function(self)
        local bS = t.registry[bh] or "object"
        at(string.format("for _, obj in %s:GetDescendants() do", bS))
        t.indent = t.indent + 1
        local b_ = bj("obj", false)
        t.registry[b_] = "obj"
        t.property_store[b_] = {Name = "Ball", ClassName = "Part", Size = Vector3.new(1, 1, 1)}
        local c0 = false
        return function()
            if not c0 then
                c0 = true
                return 1, b_
            else
                t.indent = t.indent - 1
                at("end")
                return nil
            end
        end, nil, 0
    end
    bP.Clone = function(self)
        local bS = t.registry[bh] or "object"
        local x = bj((aT or "object") .. "Clone", false)
        local _ = aW(x, (aT or "object") .. "Clone")
        at(string.format("local %s = %s:Clone()", _, bS))
        return x
    end
    bP.Destroy = function(self)
        local bS = t.registry[bh] or "object"
        at(string.format("%s:Destroy()", bS))
    end
    bP.ClearAllChildren = function(self)
        local bS = t.registry[bh] or "object"
        at(string.format("%s:ClearAllChildren()", bS))
    end
    bP.Connect = function(self, bs)
        local bS = t.registry[bh] or "signal"
        local c1 = bj("connection", false)
        local c2 = aW(c1, "conn")
        local c3 = bS:match("%.([^%.]+)$") or bS
        local c4 = {"..."}
        if c3:match("InputBegan") or c3:match("InputEnded") or c3:match("InputChanged") then
            c4 = {"input", "gameProcessed"}
        elseif c3:match("CharacterAdded") or c3:match("CharacterRemoving") then
            c4 = {"character"}
        elseif c3:match("PlayerAdded") or c3:match("PlayerRemoving") then
            c4 = {"player"}
        elseif c3:match("Touched") then
            c4 = {"hit"}
        elseif c3:match("Heartbeat") or c3:match("RenderStepped") then
            c4 = {"deltaTime"}
        elseif c3:match("Stepped") then
            c4 = {"time", "deltaTime"}
        elseif c3:match("Changed") then
            c4 = {"property"}
        elseif c3:match("ChildAdded") or c3:match("ChildRemoved") then
            c4 = {"child"}
        elseif c3:match("DescendantAdded") or c3:match("DescendantRemoving") then
            c4 = {"descendant"}
        elseif c3:match("Died") or c3:match("MouseButton") or c3:match("Activated") then
            c4 = {}
        elseif c3:match("FocusLost") then
            c4 = {"enterPressed", "inputObject"}
        end
        at(string.format("local %s = %s:Connect(function(%s)", c2, bS, table.concat(c4, ", ")))
        t.indent = t.indent + 1
        if j(bs) == "function" then
            xpcall(
                function()
                    bs()
                end,
                function()
                end
            )
        end
        while t.pending_iterator do
            t.indent = t.indent - 1
            at("end")
            t.pending_iterator = false
        end
        t.indent = t.indent - 1
        at("end)")
        return c1
    end
    bP.Once = function(self, bs)
        local bS = t.registry[bh] or "signal"
        local c1 = bj("connection", false)
        local c2 = aW(c1, "conn")
        at(string.format("local %s = %s:Once(function(...)", c2, bS))
        t.indent = t.indent + 1
        if j(bs) == "function" then
            xpcall(
                function()
                    bs()
                end,
                function()
                end
            )
        end
        t.indent = t.indent - 1
        at("end)")
        return c1
    end
    bP.Wait = function(self)
        local bS = t.registry[bh] or "signal"
        local z = bj("waitResult", false)
        local _ = aW(z, "waitResult")
        at(string.format("local %s = %s:Wait()", _, bS))
        return z
    end
    bP.Disconnect = function(self)
        local bS = t.registry[bh] or "connection"
        at(string.format("%s:Disconnect()", bS))
    end
    bP.FireServer = function(self, ...)
        local bS = t.registry[bh] or "remote"
        local bA = {...}
        local c5 = {}
        for W, b5 in ipairs(bA) do
            table.insert(c5, aZ(b5))
        end
        at(string.format("%s:FireServer(%s)", bS, table.concat(c5, ", ")))
        table.insert(t.call_graph, {type = "RemoteEvent", name = bS, args = bA})
    end
    bP.InvokeServer = function(self, ...)
        local bS = t.registry[bh] or "remote"
        local bA = {...}
        local c5 = {}
        for W, b5 in ipairs(bA) do
            table.insert(c5, aZ(b5))
        end
        local z = bj("invokeResult", false)
        local _ = aW(z, "result")
        at(string.format("local %s = %s:InvokeServer(%s)", _, bS, table.concat(c5, ", ")))
        table.insert(t.call_graph, {type = "RemoteFunction", name = bS, args = bA})
        return z
    end
    bP.Create = function(self, x, c6, c7)
        local bS = t.registry[bh] or "TweenService"
        local c8 = bj("tween", false)
        local _ = aW(c8, "tween")
        at(string.format("local %s = %s:Create(%s, %s, %s)", _, bS, aZ(x), aZ(c6), aZ(c7)))
        return c8
    end
    bP.Play = function(self)
        local bS = t.registry[bh] or "tween"
        at(string.format("%s:Play()", bS))
    end
    bP.Pause = function(self)
        local bS = t.registry[bh] or "tween"
        at(string.format("%s:Pause()", bS))
    end
    bP.Cancel = function(self)
        local bS = t.registry[bh] or "tween"
        at(string.format("%s:Cancel()", bS))
    end
    bP.Stop = function(self)
        local bS = t.registry[bh] or "tween"
        at(string.format("%s:Stop()", bS))
    end
    bP.Raycast = function(self, c9, ca, cb)
        local bS = t.registry[bh] or "workspace"
        local z = bj("raycastResult", false)
        local _ = aW(z, "rayResult")
        if cb then
            at(string.format("local %s = %s:Raycast(%s, %s, %s)", _, bS, aZ(c9), aZ(ca), aZ(cb)))
        else
            at(string.format("local %s = %s:Raycast(%s, %s)", _, bS, aZ(c9), aZ(ca)))
        end
        return z
    end
    bP.GetMouse = function(self)
        local bS = t.registry[bh] or "player"
        local cc = bj("mouse", false)
        local _ = aW(cc, "mouse")
        at(string.format("local %s = %s:GetMouse()", _, bS))
        return cc
    end
    bP.Kick = function(self, cd)
        local bS = t.registry[bh] or "player"
        if cd then
            at(string.format("%s:Kick(%s)", bS, aZ(cd)))
        else
            at(string.format("%s:Kick()", bS))
        end
    end
    bP.GetPropertyChangedSignal = function(self, ce)
        local cf = aE(ce)
        local bS = t.registry[bh] or "instance"
        local cg = bj(cf .. "Changed", false)
        t.registry[cg] = bS .. ":GetPropertyChangedSignal(" .. aH(cf) .. ")"
        return cg
    end
    bP.IsA = function(self, bX)
        return true
    end
    bP.IsDescendantOf = function(self, ch)
        return true
    end
    bP.IsAncestorOf = function(self, ci)
        return true
    end
    bP.GetAttribute = function(self, cj)
        return nil
    end
    bP.SetAttribute = function(self, cj, bm)
        local bS = t.registry[bh] or "instance"
        at(string.format("%s:SetAttribute(%s, %s)", bS, aH(cj), aZ(bm)))
    end
    bP.GetAttributes = function(self)
        return {}
    end
    bP.GetPlayers = function(self)
        return {}
    end
    bP.GetPlayerFromCharacter = function(self, ck)
        local bS = t.registry[bh] or "Players"
        local cl = bj("player", false)
        local _ = aW(cl, "player")
        at(string.format("local %s = %s:GetPlayerFromCharacter(%s)", _, bS, aZ(ck)))
        return cl
    end
    bP.GetPlayerByUserId = function(self, cm)
        local bS = t.registry[bh] or "Players"
        local cl = bj("player", false)
        local _ = aW(cl, "player")
        at(string.format("local %s = %s:GetPlayerByUserId(%s)", _, bS, aZ(cm)))
        return cl
    end
    bP.SetCore = function(self, am, bm)
        local bS = t.registry[bh] or "StarterGui"
        at(string.format("%s:SetCore(%s, %s)", bS, aH(am), aZ(bm)))
    end
    bP.GetCore = function(self, am)
        return nil
    end
    bP.SetCoreGuiEnabled = function(self, cn, co)
        local bS = t.registry[bh] or "StarterGui"
        at(string.format("%s:SetCoreGuiEnabled(%s, %s)", bS, aZ(cn), aZ(co)))
    end
    bP.BindToRenderStep = function(self, am, cp, bs)
        local bS = t.registry[bh] or "RunService"
        at(string.format("%s:BindToRenderStep(%s, %s, function(deltaTime)", bS, aH(am), aZ(cp)))
        t.indent = t.indent + 1
        if j(bs) == "function" then
            xpcall(
                function()
                    bs(0.016)
                end,
                function()
                end
            )
        end
        t.indent = t.indent - 1
        at("end)")
    end
    bP.UnbindFromRenderStep = function(self, am)
        local bS = t.registry[bh] or "RunService"
        at(string.format("%s:UnbindFromRenderStep(%s)", bS, aH(am)))
    end
    bP.GetFullName = function(self)
        return t.registry[bh] or "Instance"
    end
    bP.GetDebugId = function(self)
        return "DEBUG_" .. (H(bh) or "0")
    end
    bP.MoveTo = function(self, cq, cr)
        local bS = t.registry[bh] or "humanoid"
        if cr then
            at(string.format("%s:MoveTo(%s, %s)", bS, aZ(cq), aZ(cr)))
        else
            at(string.format("%s:MoveTo(%s)", bS, aZ(cq)))
        end
    end
    bP.Move = function(self, ca, cs)
        local bS = t.registry[bh] or "humanoid"
        at(string.format("%s:Move(%s, %s)", bS, aZ(ca), aZ(cs or false)))
    end
    bP.EquipTool = function(self, ct)
        local bS = t.registry[bh] or "humanoid"
        at(string.format("%s:EquipTool(%s)", bS, aZ(ct)))
    end
    bP.UnequipTools = function(self)
        local bS = t.registry[bh] or "humanoid"
        at(string.format("%s:UnequipTools()", bS))
    end
    bP.TakeDamage = function(self, cu)
        local bS = t.registry[bh] or "humanoid"
        at(string.format("%s:TakeDamage(%s)", bS, aZ(cu)))
    end
    bP.ChangeState = function(self, cv)
        local bS = t.registry[bh] or "humanoid"
        at(string.format("%s:ChangeState(%s)", bS, aZ(cv)))
    end
    bP.GetState = function(self)
        return bj("Enum.HumanoidStateType.Running", false)
    end
    bP.SetPrimaryPartCFrame = function(self, cw)
        local bS = t.registry[bh] or "model"
        at(string.format("%s:SetPrimaryPartCFrame(%s)", bS, aZ(cw)))
    end
    bP.GetPrimaryPartCFrame = function(self)
        return CFrame.new(0, 0, 0)
    end
    bP.PivotTo = function(self, cw)
        local bS = t.registry[bh] or "model"
        at(string.format("%s:PivotTo(%s)", bS, aZ(cw)))
    end
    bP.GetPivot = function(self)
        return CFrame.new(0, 0, 0)
    end
    bP.GetBoundingBox = function(self)
        return CFrame.new(0, 0, 0), Vector3.new(1, 1, 1)
    end
    bP.GetExtentsSize = function(self)
        return Vector3.new(1, 1, 1)
    end
    bP.TranslateBy = function(self, cx)
        local bS = t.registry[bh] or "model"
        at(string.format("%s:TranslateBy(%s)", bS, aZ(cx)))
    end
    bP.LoadAnimation = function(self, cy)
        local bS = t.registry[bh] or "animator"
        local cz = bj("animTrack", false)
        local _ = aW(cz, "animTrack")
        at(string.format("local %s = %s:LoadAnimation(%s)", _, bS, aZ(cy)))
        return cz
    end
    bP.GetPlayingAnimationTracks = function(self)
        return {}
    end
    bP.AdjustSpeed = function(self, cA)
        local bS = t.registry[bh] or "animTrack"
        at(string.format("%s:AdjustSpeed(%s)", bS, aZ(cA)))
    end
    bP.AdjustWeight = function(self, cB, cC)
        local bS = t.registry[bh] or "animTrack"
        if cC then
            at(string.format("%s:AdjustWeight(%s, %s)", bS, aZ(cB), aZ(cC)))
        else
            at(string.format("%s:AdjustWeight(%s)", bS, aZ(cB)))
        end
    end
    bP.Teleport = function(self, cD, cl, cE, cF)
        local bS = t.registry[bh] or "TeleportService"
        at(
            string.format(
                "%s:Teleport(%s, %s%s%s)",
                bS,
                aZ(cD),
                aZ(cl),
                cE and ", " .. aZ(cE) or '"',
                cF and ", " .. aZ(cF) or '"'
            )
        )
    end
    bP.TeleportToPlaceInstance = function(self, cD, cG, cl)
        local bS = t.registry[bh] or "TeleportService"
        at(string.format("%s:TeleportToPlaceInstance(%s, %s, %s)", bS, aZ(cD), aZ(cG), aZ(cl)))
    end
    bP.PlayLocalSound = function(self, cH)
        local bS = t.registry[bh] or "SoundService"
        at(string.format("%s:PlayLocalSound(%s)", bS, aZ(cH)))
    end
    bP.GetAsync = function(self, cI)
        return "{}"
    end
    bP.PostAsync = function(self, cI, cJ)
        return "{}"
    end
    bP.JSONEncode = function(self, cJ)
        return "{}"
    end
    bP.JSONDecode = function(self, O)
        return {}
    end
    bP.GenerateGUID = function(self, cK)
        return "00000000-0000-0000-0000-000000000000"
    end
    bP.HttpGet = function(self, cI)
        local cL = aE(cI)
        table.insert(t.string_refs, {value = cL, hint = "HTTP URL"})
        t.last_http_url = cL
        return cL
    end
    bP.HttpPost = function(self, cI, cJ, cM)
        local cL = aE(cI)
        table.insert(t.string_refs, {value = cL, hint = "HTTP POST URL"})
        local x = bj("HttpResponse", false)
        local _ = aW(x, "httpResponse")
        local bS = t.registry[bh] or "HttpService"
        at(string.format("local %s = %s:HttpPost(%s, %s, %s)", _, bS, aZ(cI), aZ(cJ), aZ(cM)))
        t.property_store[x] = {Body = "{}", StatusCode = 200, Success = true}
        return x
    end
    bP.AddItem = function(self, cN, cO)
        local bS = t.registry[bh] or "Debris"
        at(string.format("%s:AddItem(%s, %s)", bS, aZ(cN), aZ(cO or 10)))
    end
    bi.__index = function(b2, b4)
        if b4 == F or b4 == "__proxy_id" then
            return rawget(b2, b4)
        end
        if b4 == "PlaceId" or b4 == "GameId" or b4 == "placeId" or b4 == "gameId" then
            return u
        end
        local bS = t.registry[bh] or aT or "object"
        local cP = aE(b4)
        if t.property_store[bh] and t.property_store[bh][b4] ~= nil then
            return t.property_store[bh][b4]
        end
        if bP[cP] then
            local cQ, cR = bg()
            t.registry[cQ] = bS .. "." .. cP
            cR.__call = function(W, ...)
                local bA = {...}
                if bA[1] == bh or G(bA[1]) and bA[1] ~= cQ then
                    table.remove(bA, 1)
                end
                return bP[cP](bh, table.unpack(bA))
            end
            cR.__index = function(W, cS)
                if cS == F or cS == "__proxy_id" then
                    return rawget(cQ, cS)
                end
                return bj(cS, false, cQ)
            end
            cR.__tostring = function()
                return bS .. ":" .. cP
            end
            return cQ
        end
        if bS == "fenv" or bS == "getgenv" or bS == "_G" then
            if b4 == "game" then
                return game
            end
            if b4 == "workspace" then
                return workspace
            end
            if b4 == "script" then
                return script
            end
            if b4 == "Enum" then
                return Enum
            end
            if _G[b4] ~= nil then
                return _G[b4]
            end
            return nil
        end
        if b4 == "Parent" then
            return t.parent_map[bh] or bj("Parent", false)
        end
        if b4 == "Name" then
            return aT or "Object"
        end
        if b4 == "ClassName" then
            return aT or "Instance"
        end
        if b4 == "LocalPlayer" then
            local cT = bj("LocalPlayer", false, bh)
            local _ = aW(cT, "LocalPlayer")
            at(string.format("local %s = %s.LocalPlayer", _, bS))
            return cT
        end
        if b4 == "PlayerGui" then
            return bj("PlayerGui", false, bh)
        end
        if b4 == "Backpack" then
            return bj("Backpack", false, bh)
        end
        if b4 == "PlayerScripts" then
            return bj("PlayerScripts", false, bh)
        end
        if b4 == "UserId" then
            return 1
        end
        if b4 == "DisplayName" then
            return "Player"
        end
        if b4 == "AccountAge" then
            return 1000
        end
        if b4 == "Team" then
            return bj("Team", false, bh)
        end
        if b4 == "TeamColor" then
            return BrickColor.new("White")
        end
        if b4 == "Character" then
            return bj("Character", false, bh)
        end
        if b4 == "Humanoid" then
            local cU = bj("Humanoid", false, bh)
            t.property_store[cU] = {Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2}
            return cU
        end
        if b4 == "HumanoidRootPart" or b4 == "PrimaryPart" or b4 == "RootPart" then
            local cV = bj("HumanoidRootPart", false, bh)
            t.property_store[cV] = {Position = Vector3.new(0, 5, 0), CFrame = CFrame.new(0, 5, 0)}
            return cV
        end
        local cW = {
            "Head",
            "Torso",
            "UpperTorso",
            "LowerTorso",
            "RightArm",
            "LeftArm",
            "RightLeg",
            "LeftLeg",
            "RightHand",
            "LeftHand",
            "RightFoot",
            "LeftFoot"
        }
        for W, cr in ipairs(cW) do
            if b4 == cr then
                return bj(b4, false, bh)
            end
        end
        if b4 == "Animator" then
            return bj("Animator", false, bh)
        end
        if b4 == "CurrentCamera" or b4 == "Camera" then
            local cX = bj("Camera", false, bh)
            t.property_store[cX] = {
                CFrame = CFrame.new(0, 10, 0),
                FieldOfView = 70,
                ViewportSize = Vector2.new(1920, 1080)
            }
            return cX
        end
        if b4 == "CameraType" then
            return bj("Enum.CameraType.Custom", false)
        end
        if b4 == "CameraSubject" then
            return bj("Humanoid", false, bh)
        end
        local cY = {
            Health = 100,
            MaxHealth = 100,
            WalkSpeed = 16,
            JumpPower = 50,
            JumpHeight = 7.2,
            HipHeight = 2,
            Transparency = 0,
            Mass = 1,
            Value = 0,
            TimePosition = 0,
            TimeLength = 1,
            Volume = 0.5,
            PlaybackSpeed = 1,
            Brightness = 1,
            Range = 60,
            Angle = 90,
            FieldOfView = 70,
            Size = 1,
            Thickness = 1,
            ZIndex = 1,
            LayoutOrder = 0
        }
        if cY[b4] then
            return bl(cY[b4])
        end
        local cZ = {
            Visible = true,
            Enabled = true,
            Anchored = false,
            CanCollide = true,
            Locked = false,
            Active = true,
            Draggable = false,
            Modal = false,
            Playing = false,
            Looped = false,
            IsPlaying = false,
            AutoPlay = false,
            Archivable = true,
            ClipsDescendants = false,
            RichText = false,
            TextWrapped = false,
            TextScaled = false,
            PlatformStand = false,
            AutoRotate = true,
            Sit = false
        }
        if cZ[b4] ~= nil then
            return cZ[b4]
        end
        if b4 == "AbsoluteSize" or b4 == "ViewportSize" then
            return Vector2.new(1920, 1080)
        end
        if b4 == "AbsolutePosition" then
            return Vector2.new(0, 0)
        end
        if b4 == "Position" then
            if aT and (aT:match("Part") or aT:match("Model") or aT:match("Character") or aT:match("Root")) then
                return Vector3.new(0, 5, 0)
            end
            return UDim2.new(0, 0, 0, 0)
        end
        if b4 == "Size" then
            if aT and aT:match("Part") then
                return Vector3.new(4, 1, 2)
            end
            return UDim2.new(1, 0, 1, 0)
        end
        if b4 == "CFrame" then
            return CFrame.new(0, 5, 0)
        end
        if b4 == "Velocity" or b4 == "AssemblyLinearVelocity" then
            return Vector3.new(0, 0, 0)
        end
        if b4 == "RotVelocity" or b4 == "AssemblyAngularVelocity" then
            return Vector3.new(0, 0, 0)
        end
        if b4 == "Orientation" or b4 == "Rotation" then
            return Vector3.new(0, 0, 0)
        end
        if b4 == "LookVector" then
            return Vector3.new(0, 0, -1)
        end
        if b4 == "RightVector" then
            return Vector3.new(1, 0, 0)
        end
        if b4 == "UpVector" then
            return Vector3.new(0, 1, 0)
        end
        if
            b4 == "Color" or b4 == "Color3" or b4 == "BackgroundColor3" or b4 == "BorderColor3" or b4 == "TextColor3" or
                b4 == "PlaceholderColor3" or
                b4 == "ImageColor3"
         then
            return Color3.new(1, 1, 1)
        end
        if b4 == "BrickColor" then
            return BrickColor.new("Medium stone grey")
        end
        if b4 == "Material" then
            return bj("Enum.Material.Plastic", false)
        end
        if b4 == "Hit" then
            return CFrame.new(0, 0, -10)
        end
        if b4 == "Origin" then
            return CFrame.new(0, 5, 0)
        end
        if b4 == "Target" then
            return bj("Target", false, bh)
        end
        if b4 == "X" or b4 == "Y" then
            return 0
        end
        if b4 == "UnitRay" then
            return Ray.new(Vector3.new(0, 5, 0), Vector3.new(0, 0, -1))
        end
        if b4 == "ViewSizeX" then
            return 1920
        end
        if b4 == "ViewSizeY" then
            return 1080
        end
        if b4 == "Text" or b4 == "PlaceholderText" or b4 == "ContentText" or b4 == "Value" then
            if s then
                return s
            end
            if b4 == "Value" then
                return "input"
            end
            return '"'
        end
        if b4 == "TextBounds" then
            return Vector2.new(0, 0)
        end
        if b4 == "Font" then
            return bj("Enum.Font.SourceSans", false)
        end
        if b4 == "TextSize" then
            return 14
        end
        if b4 == "Image" or b4 == "ImageContent" then
            return '"'
        end
        local c_ = {
            "Changed",
            "ChildAdded",
            "ChildRemoved",
            "DescendantAdded",
            "DescendantRemoving",
            "Touched",
            "TouchEnded",
            "InputBegan",
            "InputEnded",
            "InputChanged",
            "MouseButton1Click",
            "MouseButton1Down",
            "MouseButton1Up",
            "MouseButton2Click",
            "MouseButton2Down",
            "MouseButton2Up",
            "MouseEnter",
            "MouseLeave",
            "MouseMoved",
            "MouseWheelForward",
            "MouseWheelBackward",
            "Activated",
            "Deactivated",
            "FocusLost",
            "FocusGained",
            "Focused",
            "Heartbeat",
            "RenderStepped",
            "Stepped",
            "CharacterAdded",
            "CharacterRemoving",
            "CharacterAppearanceLoaded",
            "PlayerAdded",
            "PlayerRemoving",
            "AncestryChanged",
            "AttributeChanged",
            "Died",
            "FreeFalling",
            "GettingUp",
            "Jumping",
            "Running",
            "Seated",
            "Swimming",
            "StateChanged",
            "HealthChanged",
            "MoveToFinished",
            "OnClientEvent",
            "OnServerEvent",
            "OnClientInvoke",
            "OnServerInvoke",
            "Completed",
            "DidLoop",
            "Stopped",
            "Button1Down",
            "Button1Up",
            "Button2Down",
            "Button2Up",
            "Idle",
            "Move",
            "TextChanged",
            "ReturnPressedFromOnScreenKeyboard",
            "Triggered",
            "TriggerEnded"
        }
        for W, d0 in ipairs(c_) do
            if b4 == d0 then
                local cg = bj(bS .. "." .. b4, false, bh)
                t.registry[cg] = bS .. "." .. b4
                return cg
            end
        end
        if bS:match("^Enum") then
            local d1 = bS .. "." .. cP
            local d2 = bj(d1, false)
            t.registry[d2] = d1
            return d2
        end
        return bk(cP, bh)
    end
    bi.__newindex = function(b2, b4, b5)
        if b4 == F or b4 == "__proxy_id" then
            rawset(b2, b4, b5)
            return
        end
        local bS = t.registry[bh] or aT or "object"
        local cP = aE(b4)
        t.property_store[bh] = t.property_store[bh] or {}
        t.property_store[bh][b4] = b5
        if b4 == "Parent" and G(b5) then
            t.parent_map[bh] = b5
        end
        at(string.format("%s.%s = %s", bS, cP, aZ(b5)))
    end
    bi.__call = function(b2, ...)
        local bS = t.registry[bh] or aT or "func"
        if bS == "fenv" or bS == "getgenv" or bS:match("env") then
            return bh
        end
        local bA = {...}
        local c5 = {}
        for W, b5 in ipairs(bA) do
            table.insert(c5, aZ(b5))
        end
        local z = bj("result", false)
        local _ = aW(z, "result")
        at(string.format("local %s = %s(%s)", _, bS, table.concat(c5, ", ")))
        return z
    end
    local function d3(d4)
        local function d5(bo, aa)
            local bh, bi = bg()
            local d6 = "0"
            if bo ~= nil then
                d6 = t.registry[bo] or aZ(bo)
            end
            local d7 = "0"
            if aa ~= nil then
                d7 = t.registry[aa] or aZ(aa)
            end
            local d8 = "(" .. d6 .. " " .. d4 .. " " .. d7 .. ")"
            t.registry[bh] = d8
            bi.__tostring = function()
                return d8
            end
            bi.__call = function()
                return bh
            end
            bi.__index = function(W, b4)
                if b4 == F or b4 == "__proxy_id" then
                    return rawget(bh, b4)
                end
                return bj(d8 .. "." .. aE(b4), false)
            end
            bi.__add = d3("+")
            bi.__sub = d3("-")
            bi.__mul = d3("*")
            bi.__div = d3("/")
            bi.__mod = d3("%")
            bi.__pow = d3("^")
            bi.__concat = d3("..")
            bi.__eq = function()
                return false
            end
            bi.__lt = function()
                return false
            end
            bi.__le = function()
                return false
            end
            return bh
        end
        return d5
    end
    bi.__add = d3("+")
    bi.__sub = d3("-")
    bi.__mul = d3("*")
    bi.__div = d3("/")
    bi.__mod = d3("%")
    bi.__pow = d3("^")
    bi.__concat = d3("..")
    bi.__eq = function()
        return false
    end
    bi.__lt = function()
        return false
    end
    bi.__le = function()
        return false
    end
    bi.__unm = function(bo)
        local z, d9 = bg()
        t.registry[z] = "(-" .. (t.registry[bo] or aZ(bo)) .. ")"
        d9.__tostring = function()
            return t.registry[z]
        end
        return z
    end
    bi.__len = function()
        return 0
    end
    bi.__tostring = function()
        return t.registry[bh] or aT or "Object"
    end
    bi.__pairs = function()
        return function()
            return nil
        end, bh, nil
    end
    bi.__ipairs = bi.__pairs
    return bh
end
local function da(am, db)
    local dc = {}
    local dd = {}
    dd.__index = function(b2, b4)
        if b4 == "new" or db and db[b4] then
            return function(...)
                local bA = {...}
                local c5 = {}
                for W, b5 in ipairs(bA) do
                    table.insert(c5, aZ(b5))
                end
                local d8 = am .. "." .. b4 .. "(" .. table.concat(c5, ", ") .. ")"
                local bh, de = bg()
                t.registry[bh] = d8
                de.__tostring = function()
                    return d8
                end
                de.__index = function(W, bG)
                    if bG == F or bG == "__proxy_id" then
                        return rawget(bh, bG)
                    end
                    if bG == "X" or bG == "Y" or bG == "Z" or bG == "W" then
                        return 0
                    end
                    if bG == "Magnitude" then
                        return 0
                    end
                    if bG == "Unit" then
                        return bh
                    end
                    if bG == "Position" then
                        return bh
                    end
                    if bG == "CFrame" then
                        return bh
                    end
                    if bG == "LookVector" or bG == "RightVector" or bG == "UpVector" then
                        return bh
                    end
                    if bG == "Rotation" then
                        return bh
                    end
                    if bG == "R" or bG == "G" or bG == "B" then
                        return 1
                    end
                    if bG == "Width" or bG == "Height" then
                        return UDim.new(0, 0)
                    end
                    if bG == "Min" or bG == "Max" then
                        return 0
                    end
                    if bG == "Scale" or bG == "Offset" then
                        return 0
                    end
                    if bG == "p" then
                        return bh
                    end
                    return 0
                end
                local function df(Z)
                    return function(bo, aa)
                        local dg, dh = bg()
                        local O =
                            "(" .. (t.registry[bo] or aZ(bo)) .. " " .. Z .. " " .. (t.registry[aa] or aZ(aa)) .. ")"
                        t.registry[dg] = O
                        dh.__tostring = function()
                            return O
                        end
                        dh.__index = de.__index
                        dh.__add = df("+")
                        dh.__sub = df("-")
                        dh.__mul = df("*")
                        dh.__div = df("/")
                        return dg
                    end
                end
                de.__add = df("+")
                de.__sub = df("-")
                de.__mul = df("*")
                de.__div = df("/")
                de.__unm = function(bo)
                    local dg, dh = bg()
                    t.registry[dg] = "(-" .. (t.registry[bo] or aZ(bo)) .. ")"
                    dh.__tostring = function()
                        return t.registry[dg]
                    end
                    return dg
                end
                de.__eq = function()
                    return false
                end
                return bh
            end
        end
        return nil
    end
    dd.__call = function(b2, ...)
        return b2.new(...)
    end
    return setmetatable(dc, dd)
end
Vector3 = da("Vector3", {new = true, zero = true, one = true})
Vector2 = da("Vector2", {new = true, zero = true, one = true})
UDim = da("UDim", {new = true})
UDim2 = da("UDim2", {new = true, fromScale = true, fromOffset = true})
CFrame =
    da(
    "CFrame",
    {
        new = true,
        Angles = true,
        lookAt = true,
        fromEulerAnglesXYZ = true,
        fromEulerAnglesYXZ = true,
        fromAxisAngle = true,
        fromMatrix = true,
        fromOrientation = true,
        identity = true
    }
)
Color3 = da("Color3", {new = true, fromRGB = true, fromHSV = true, fromHex = true})
BrickColor =
    da(
    "BrickColor",
    {
        new = true,
        random = true,
        White = true,
        Black = true,
        Red = true,
        Blue = true,
        Green = true,
        Yellow = true,
        palette = true
    }
)
TweenInfo = da("TweenInfo", {new = true})
Rect = da("Rect", {new = true})
Region3 = da("Region3", {new = true})
Region3int16 = da("Region3int16", {new = true})
Ray = da("Ray", {new = true})
NumberRange = da("NumberRange", {new = true})
NumberSequence = da("NumberSequence", {new = true})
NumberSequenceKeypoint = da("NumberSequenceKeypoint", {new = true})
ColorSequence = da("ColorSequence", {new = true})
ColorSequenceKeypoint = da("ColorSequenceKeypoint", {new = true})
PhysicalProperties = da("PhysicalProperties", {new = true})
Font = da("Font", {new = true, fromEnum = true, fromName = true, fromId = true})
RaycastParams = da("RaycastParams", {new = true})
OverlapParams = da("OverlapParams", {new = true})
PathWaypoint = da("PathWaypoint", {new = true})
Axes = da("Axes", {new = true})
Faces = da("Faces", {new = true})
Vector3int16 = da("Vector3int16", {new = true})
Vector2int16 = da("Vector2int16", {new = true})
CatalogSearchParams = da("CatalogSearchParams", {new = true})
DateTime = da("DateTime", {now = true, fromUnixTimestamp = true, fromUnixTimestampMillis = true, fromIsoDate = true})
Random = {new = function(di)
        local x = {}
        function x:NextNumber(dj, dk)
            return (dj or 0) + 0.5 * ((dk or 1) - (dj or 0))
        end
        function x:NextInteger(dj, dk)
            return math.floor((dj or 1) + 0.5 * ((dk or 100) - (dj or 1)))
        end
        function x:NextUnitVector()
            return Vector3.new(0.577, 0.577, 0.577)
        end
        function x:Shuffle(dl)
            return dl
        end
        function x:Clone()
            return Random.new()
        end
        return x
    end}
setmetatable(
    Random,
    {__call = function(b2, di)
            return b2.new(di)
        end}
)
Enum = bj("Enum", true)
local dm = a.getmetatable(Enum)
dm.__index = function(b2, b4)
    if b4 == F or b4 == "__proxy_id" then
        return rawget(b2, b4)
    end
    local dn = bj("Enum." .. aE(b4), false)
    t.registry[dn] = "Enum." .. aE(b4)
    return dn
end
Instance = {new = function(bX, bS)
        local bY = aE(bX)
        local x = bj(bY, false)
        local _ = aW(x, bY)
        if bS then
            local dp = t.registry[bS] or aZ(bS)
            at(string.format("local %s = Instance.new(%s, %s)", _, aH(bY), dp))
            t.parent_map[x] = bS
        else
            at(string.format("local %s = Instance.new(%s)", _, aH(bY)))
        end
        return x
    end}
game = bj("game", true)
workspace = bj("workspace", true)
script = bj("script", true)
t.property_store[script] = {Name = "DumpedScript", Parent = game, ClassName = "LocalScript"}
task = {
    wait = function(dq)
        if dq then
            at(string.format("task.wait(%s)", aZ(dq)))
        else
            at("task.wait()")
        end
        return dq or 0.03, p.clock()
    end,
    spawn = function(dr, ...)
        local bA = {...}
        at("task.spawn(function()")
        t.indent = t.indent + 1
        if j(dr) == "function" then
            xpcall(
                function()
                    dr(table.unpack(bA))
                end,
                function(ds)
                    at("-- [Error in spawn] " .. tostring(ds))
                end
            )
        end
        while t.pending_iterator do
            t.indent = t.indent - 1
            at("end")
            t.pending_iterator = false
        end
        t.indent = t.indent - 1
        at("end)")
    end,
    delay = function(dq, dr, ...)
        local bA = {...}
        at(string.format("task.delay(%s, function()", aZ(dq or 0)))
        t.indent = t.indent + 1
        if j(dr) == "function" then
            xpcall(
                function()
                    dr(table.unpack(bA))
                end,
                function()
                end
            )
        end
        while t.pending_iterator do
            t.indent = t.indent - 1
            at("end")
            t.pending_iterator = false
        end
        t.indent = t.indent - 1
        at("end)")
    end,
    defer = function(dr, ...)
        local bA = {...}
        at("task.defer(function()")
        t.indent = t.indent + 1
        if j(dr) == "function" then
            xpcall(
                function()
                    dr(table.unpack(bA))
                end,
                function()
                end
            )
        end
        t.indent = t.indent - 1
        at("end)")
    end,
    cancel = function(dt)
        at("task.cancel(thread)")
    end,
    synchronize = function()
        at("task.synchronize()")
    end,
    desynchronize = function()
        at("task.desynchronize()")
    end
}
wait = function(dq)
    if dq then
        at(string.format("wait(%s)", aZ(dq)))
    else
        at("wait()")
    end
    return dq or 0.03, p.clock()
end
delay = function(dq, dr)
    at(string.format("delay(%s, function()", aZ(dq or 0)))
    t.indent = t.indent + 1
    if j(dr) == "function" then
        xpcall(
            dr,
            function()
            end
        )
    end
    t.indent = t.indent - 1
    at("end)")
end
spawn = function(dr)
    at("spawn(function()")
    t.indent = t.indent + 1
    if j(dr) == "function" then
        xpcall(
            dr,
            function()
            end
        )
    end
    t.indent = t.indent - 1
    at("end)")
end
tick = function()
    return p.time()
end
time = function()
    return p.clock()
end
elapsedTime = function()
    return p.clock()
end
local du = {}
local dv = 999999999
local function dw(bG, dx)
    return dx
end
local function dy()
    local b2 = {}
    setmetatable(
        b2,
        {__call = function(self, ...)
                return self
            end, __index = function(self, b4)
                if _G[b4] ~= nil then
                    return dw(b4, _G[b4])
                end
                if b4 == "game" then
                    return game
                end
                if b4 == "workspace" then
                    return workspace
                end
                if b4 == "script" then
                    return script
                end
                if b4 == "Enum" then
                    return Enum
                end
                return nil
            end, __newindex = function(self, b4, b5)
                _G[b4] = b5
                du[b4] = 0
                at(string.format("_G.%s = %s", aE(b4), aZ(b5)))
            end}
    )
    return b2
end
_G.G = dy()
_G.g = dy()
_G.ENV = dy()
_G.env = dy()
_G.E = dy()
_G.e = dy()
_G.L = dy()
_G.l = dy()
_G.F = dy()
_G.f = dy()
local function dz(dA)
    local bh = {}
    local dd = {}
    local dB = {
        "hookfunction",
        "hookmetamethod",
        "newcclosure",
        "replaceclosure",
        "checkcaller",
        "iscclosure",
        "islclosure",
        "getrawmetatable",
        "setreadonly",
        "make_writeable",
        "getrenv",
        "getgc",
        "getinstances"
    }
    local function dC(dD, bG)
        local bd = aE(bG)
        if bd:match("^[%a_][%w_]*$") then
            if dD then
                return dD .. "." .. bd
            end
            return bd
        else
            local aI = bd:gsub("'", "\\\\'")
            if dD then
                return dD .. "['" .. aI .. "']"
            end
            return "['" .. aI .. "']"
        end
    end
    dd.__index = function(b2, b4)
        for W, dE in ipairs(dB) do
            if b4 == dE then
                return nil
            end
        end
        local dF = dC(dA, b4)
        return dz(dF)
    end
    dd.__newindex = function(b2, b4, b5)
        local dG = dC(dA, b4)
        at(string.format("getgenv().%s = %s", dG, aZ(b5)))
    end
    dd.__call = function(b2, ...)
        return b2
    end
    dd.__pairs = function()
        return function()
            return nil
        end, nil, nil
    end
    return setmetatable(bh, dd)
end
local exploit_funcs = {getgenv = function()
        return dz(nil)
    end, getrenv = function()
        return bj("getrenv()", false)
    end, getfenv = function(dH)
        return _G
    end, setfenv = function(dI, dJ)
        if j(dI) ~= "function" then
            return
        end
        local L = 1
        while true do
            local am = debug.getupvalue(dI, L)
            if am == "_ENV" then
                debug.setupvalue(dI, L, dJ)
                break
            elseif not am then
                break
            end
            L = L + 1
        end
        return dI
    end, hookfunction = function(dK, dL)
        return dK
    end, hookmetamethod = function(x, dM, dN)
        return function()
        end
    end, getrawmetatable = function(x)
        if G(x) then
            return a.getmetatable(x)
        end
        return {}
    end, setrawmetatable = function(x, dd)
        return x
    end, getnamecallmethod = function()
        return "__namecall"
    end, setnamecallmethod = function(dM)
    end, checkcaller = function()
        return true
    end, islclosure = function(dr)
        return j(dr) == "function"
    end, iscclosure = function(dr)
        return false
    end, newcclosure = function(dr)
        return dr
    end, clonefunction = function(dr)
        return dr
    end, request = function(dO)
        at(string.format("request(%s)", aZ(dO)))
        table.insert(t.string_refs, {value = dO.Url or dO.url or "unknown", hint = "HTTP Request"})
        return {Success = true, StatusCode = 200, StatusMessage = "OK", Headers = {}, Body = "{}"}
    end, http_request = function(dO)
        return exploit_funcs.request(dO)
    end, syn = {request = function(dO)
            return exploit_funcs.request(dO)
        end}, http = {request = function(dO)
            return exploit_funcs.request(dO)
        end}, HttpPost = function(cI, cJ)
        at(string.format("HttpPost(%s, %s)", aE(cI), aE(cJ)))
        return "{}"
    end, setclipboard = function(cJ)
        at(string.format("setclipboard(%s)", aZ(cJ)))
    end, getclipboard = function()
        return '"'
    end, identifyexecutor = function()
        return "Dumper", "3.0"
    end, getexecutorname = function()
        return "Dumper"
    end, gethui = function()
        local dP = bj("HiddenUI", false)
        aW(dP, "HiddenUI")
        at(string.format("local %s = gethui()", t.registry[dP]))
        return dP
    end, gethiddenui = function()
        return exploit_funcs.gethui()
    end, protectgui = function(dQ)
    end, iswindowactive = function()
        return true
    end, isrbxactive = function()
        return true
    end, isgameactive = function()
        return true
    end, getconnections = function(cg)
        return {}
    end, firesignal = function(cg, ...)
    end, fireclickdetector = function(dR, dS)
    end, fireproximityprompt = function(dT)
    end, firetouchinterest = function(dU, dV, dW)
    end, getinstances = function()
        return {}
    end, getnilinstances = function()
        return {}
    end, getgc = function()
        return {}
    end, getscripts = function()
        return {}
    end, getrunningscripts = function()
        return {}
    end, getloadedmodules = function()
        return {}
    end, getcallingscript = function()
        return script
    end, readfile = function(dA)
        at(string.format("readfile(%s)", aH(dA)))
        return '"'
    end, writefile = function(dA, ai)
        at(string.format("writefile(%s, %s)", aH(dA), aZ(ai)))
    end, appendfile = function(dA, ai)
        at(string.format("appendfile(%s, %s)", aH(dA), aZ(ai)))
    end, loadfile = function(dA)
        return function()
            return bj("loaded_file", false)
        end
    end, listfiles = function(dX)
        return {}
    end, isfile = function(dA)
        return false
    end, isfolder = function(dA)
        return false
    end, makefolder = function(dA)
        at(string.format("makefolder(%s)", aH(dA)))
    end, delfolder = function(dA)
        at(string.format("delfolder(%s)", aH(dA)))
    end, delfile = function(dA)
        at(string.format("delfile(%s)", aH(dA)))
    end, Drawing = {new = function(aO)
            local dY = aE(aO)
            local x = bj("Drawing_" .. dY, false)
            local _ = aW(x, dY)
            at(string.format("local %s = Drawing.new(%s)", _, aH(dY)))
            return x
        end, Fonts = bj("Drawing.Fonts", false)}, crypt = {base64encode = function(cJ)
            return cJ
        end, base64decode = function(cJ)
            return cJ
        end, base64_encode = function(cJ)
            return cJ
        end, base64_decode = function(cJ)
            return cJ
        end, encrypt = function(cJ, bG)
            return cJ
        end, decrypt = function(cJ, bG)
            return cJ
        end, hash = function(cJ)
            return "hash"
        end, generatekey = function(dZ)
            return string.rep("0", dZ or 32)
        end, generatebytes = function(dZ)
            return string.rep("\\0", dZ or 16)
        end}, base64_encode = function(cJ)
        return cJ
    end, base64_decode = function(cJ)
        return cJ
    end, base64encode = function(cJ)
        return cJ
    end, base64decode = function(cJ)
        return cJ
    end, mouse1click = function()
        at("mouse1click()")
    end, mouse1press = function()
        at("mouse1press()")
    end, mouse1release = function()
        at("mouse1release()")
    end, mouse2click = function()
        at("mouse2click()")
    end, mouse2press = function()
        at("mouse2press()")
    end, mouse2release = function()
        at("mouse2release()")
    end, mousemoverel = function(d_, e0)
        at(string.format("mousemoverel(%s, %s)", aZ(d_), aZ(e0)))
    end, mousemoveabs = function(d_, e0)
        at(string.format("mousemoveabs(%s, %s)", aZ(d_), aZ(e0)))
    end, mousescroll = function(e1)
        at(string.format("mousescroll(%s)", aZ(e1)))
    end, keypress = function(bG)
        at(string.format("keypress(%s)", aZ(bG)))
    end, keyrelease = function(bG)
        at(string.format("keyrelease(%s)", aZ(bG)))
    end, keyclick = function(bG)
        at(string.format("keyclick(%s)", aZ(bG)))
    end, isreadonly = function(b2)
        return false
    end, setreadonly = function(b2, e2)
        return b2
    end, make_writeable = function(b2)
        return b2
    end, make_readonly = function(b2)
        return b2
    end, getthreadidentity = function()
        return 7
    end, setthreadidentity = function(aG)
    end, getidentity = function()
        return 7
    end, setidentity = function(aG)
    end, getthreadcontext = function()
        return 7
    end, setthreadcontext = function(aG)
    end, getcustomasset = function(dA)
        return "rbxasset://" .. aE(dA)
    end, getsynasset = function(dA)
        return "rbxasset://" .. aE(dA)
    end, getinfo = function(dr)
        return {source = "=", what = "Lua", name = "unknown", short_src = "dumper"}
    end, getconstants = function(dr)
        return {}
    end, getupvalues = function(dr)
        return {}
    end, getprotos = function(dr)
        return {}
    end, getupvalue = function(dr, ba)
        return nil
    end, setupvalue = function(dr, ba, bm)
    end, setconstant = function(dr, ba, bm)
    end, getconstant = function(dr, ba)
        return nil
    end, getproto = function(dr, ba)
        return function()
        end
    end, setproto = function(dr, ba, e3)
    end, getstack = function(dH, ba)
        return nil
    end, setstack = function(dH, ba, bm)
    end, debug = {getinfo = c or function()
                return {}
            end, getupvalue = debug.getupvalue or function()
                return nil
            end, setupvalue = debug.setupvalue or function()
            end, getmetatable = a.getmetatable, setmetatable = debug.setmetatable or setmetatable, traceback = d or
            function()
                return '"'
            end, profilebegin = function()
        end, profileend = function()
        end, sethook = function()
        end}, rconsoleprint = function(ay)
    end, rconsoleclear = function()
    end, rconsolecreate = function()
    end, rconsoledestroy = function()
    end, rconsoleinput = function()
        return ""
    end, rconsoleinfo = function(ay)
    end, rconsolewarn = function(ay)
    end, rconsoleerr = function(ay)
    end, rconsolename = function(am)
    end, printconsole = function(ay)
    end, setfflag = function(e4, bm)
    end, getfflag = function(e4)
        return ""
    end, setfpscap = function(e5)
        at(string.format("setfpscap(%s)", aZ(e5)))
    end, getfpscap = function()
        return 60
    end, isnetworkowner = function(cr)
        return true
    end, gethiddenproperty = function(x, ce)
        return nil
    end, sethiddenproperty = function(x, ce, bm)
        at(string.format("sethiddenproperty(%s, %s, %s)", aZ(x), aH(ce), aZ(bm)))
    end, setsimulationradius = function(e6, e7)
        at(string.format("setsimulationradius(%s%s)", aZ(e6), e7 and ", " .. aZ(e7) or ""))
    end, getspecialinfo = function(e8)
        return {}
    end, saveinstance = function(dO)
        at(string.format("saveinstance(%s)", aZ(dO or {})))
    end, decompile = function(script)
        return "-- decompiled"
    end, lz4compress = function(cJ)
        return cJ
    end, lz4decompress = function(cJ)
        return cJ
    end, MessageBox = function(e9, ea, eb)
        return 1
    end, setwindowactive = function()
    end, setwindowtitle = function(ec)
    end, queue_on_teleport = function(al)
        at(string.format("queue_on_teleport(%s)", aZ(al)))
    end, queueonteleport = function(al)
        at(string.format("queueonteleport(%s)", aZ(al)))
    end, secure_call = function(dr, ...)
        return dr(...)
    end, create_secure_function = function(dr)
        return dr
    end, isvalidinstance = function(e8)
        return e8 ~= nil
    end, validcheck = function(e8)
        return e8 ~= nil
    end}
for b4, b5 in D(exploit_funcs) do
    _G[b4] = b5
end
_G.hookfunction = nil
_G.hookmetamethod = nil
_G.newcclosure = nil
local ed = {}
local function ee(d_)
    d_ = (d_ or 0) % 4294967296
    if d_ >= 2147483648 then
        d_ = d_ - 4294967296
    end
    return math.floor(d_)
end
ed.tobit = ee
ed.tohex = function(d_, U)
    return string.format("%0" .. (U or 8) .. "x", (d_ or 0) % 0x100000000)
end
_G.bit = {band = function(bo, aa)
        return ee(ee(bo) & ee(aa))
    end, bor = function(bo, aa)
        return ee(ee(bo) | ee(aa))
    end, bxor = function(bo, aa)
        return ee(ee(bo) ~ ee(aa))
    end, lshift = function(d_, U)
        return ee(ee(d_) << U % 32)
    end, rshift = function(d_, U)
        return ee(ee(d_) >> U % 32)
    end}
_G.bit32 = _G.bit
ed.arshift = function(d_, U)
    local b5 = ee(d_ or 0)
    if b5 < 0 then
        return ee(b5 >> U or 0) + ee(-1 << 32 - (U or 0))
    else
        return ee(b5 >> U or 0)
    end
end
ed.rol = function(d_, U)
    d_ = d_ or 0
    U = (U or 0) % 32
    return ee(d_ << U | (d_ >> 32 - U))
end
ed.ror = function(d_, U)
    d_ = d_ or 0
    U = (U or 0) % 32
    return ee(d_ >> U | (d_ << 32 - U))
end
ed.bswap = function(d_)
    d_ = d_ or 0
    local bo = d_ >> 24 & 0xFF
    local aa = d_ >> 8 & 0xFF00
    local ah = d_ << 8 & 0xFF0000
    local ef = d_ << 24 & 0xFF000000
    return ee(bo | aa | ah | ef)
end
ed.countlz = function(U)
    U = ed.tobit(U)
    if U == 0 then
        return 32
    end
    local a2 = 0
    if ed.band(U, 0xFFFF0000) == 0 then
        a2 = a2 + 16
        U = ed.lshift(U, 16)
    end
    if ed.band(U, 0xFF000000) == 0 then
        a2 = a2 + 8
        U = ed.lshift(U, 8)
    end
    if ed.band(U, 0xF0000000) == 0 then
        a2 = a2 + 4
        U = ed.lshift(U, 4)
    end
    if ed.band(U, 0xC0000000) == 0 then
        a2 = a2 + 2
        U = ed.lshift(U, 2)
    end
    if ed.band(U, 0x80000000) == 0 then
        a2 = a2 + 1
    end
    return a2
end
ed.countrz = function(U)
    U = ed.tobit(U)
    if U == 0 then
        return 32
    end
    local a2 = 0
    while ed.band(U, 1) == 0 do
        U = ed.rshift(U, 1)
        a2 = a2 + 1
    end
    return a2
end
ed.lrotate = ed.rol
ed.rrotate = ed.ror
ed.extract = function(U, eg, eh)
    eh = eh or 1
    return U >> eg & 1 << eh - 1
end
ed.replace = function(U, b5, eg, eh)
    eh = eh or 1
    local ei = 1 << eh - 1
    return U & ~(ei << eg) | (b5 & ei << eg)
end
ed.btest = function(bo, aa)
    return ed.band(bo, aa) ~= 0
end
bit32 = ed
bit = ed
_G.bit = bit
_G.bit32 = bit32
table.getn = table.getn or function(b2)
        return #b2
    end
table.foreach = table.foreach or function(b2, as)
        for b4, b5 in pairs(b2) do
            as(b4, b5)
        end
    end
table.foreachi = table.foreachi or function(b2, as)
        for L, b5 in ipairs(b2) do
            as(L, b5)
        end
    end
table.move = table.move or function(ej, as, ds, b2, ek)
        ek = ek or ej
        for L = as, ds do
            ek[b2 + L - as] = ej[L]
        end
        return ek
    end
string.split = string.split or function(S, el)
        local b2 = {}
        for O in string.gmatch(S, "([^" .. (el or "%s") .. "]+)") do
            table.insert(b2, O)
        end
        return b2
    end
if not math.frexp then
    math.frexp = function(d_)
        if d_ == 0 then
            return 0, 0
        end
        local ds = math.floor(math.log(math.abs(d_)) / math.log(2)) + 1
        local em = d_ / 2 ^ ds
        return em, ds
    end
end
if not math.ldexp then
    math.ldexp = function(em, ds)
        return em * 2 ^ ds
    end
end
if not utf8 then
    utf8 = {}
    utf8.char = function(...)
        local bA = {...}
        local dg = {}
        for L, al in ipairs(bA) do
            table.insert(dg, string.char(al % 256))
        end
        return table.concat(dg)
    end
    utf8.len = function(S)
        return #S
    end
    utf8.codes = function(S)
        local L = 0
        return function()
            L = L + 1
            if L <= #S then
                return L, string.byte(S, L)
            end
        end
    end
end
_G.utf8 = utf8
pairs = function(b2)
    if j(b2) == "table" and not G(b2) then
        return D(b2)
    end
    return function()
        return nil
    end, b2, nil
end
ipairs = function(b2)
    if j(b2) == "table" and not G(b2) then
        return E(b2)
    end
    return function()
        return nil
    end, b2, 0
end
_G.pairs = pairs
_G.ipairs = ipairs
_G.math = math
_G.table = table
_G.string = string
_G.os = os
_G.coroutine = coroutine
_G.io = nil
_G.debug = exploit_funcs.debug
_G.utf8 = utf8
_G.pairs = pairs
_G.ipairs = ipairs
_G.next = next
_G.tostring = tostring
_G.tonumber = tonumber
_G.getmetatable = getmetatable
_G.setmetatable = setmetatable
_G.pcall = function(as, ...)
    local en = {g(as, ...)}
    local eo = en[1]
    if not eo then
        local an = en[2]
        if j(an) == "string" and an:match("TIMEOUT_FORCED_BY_DUMPER") then
            i(an)
        end
    end
    return table.unpack(en)
end
_G.xpcall = function(as, ep, ...)
    local function eq(an)
        if j(an) == "string" and an:match("TIMEOUT_FORCED_BY_DUMPER") then
            return an
        end
        if ep then
            return ep(an)
        end
        return an
    end
    local en = {h(as, eq, ...)}
    local eo = en[1]
    if not eo then
        local an = en[2]
        if j(an) == "string" and an:match("TIMEOUT_FORCED_BY_DUMPER") then
            i(an)
        end
    end
    return table.unpack(en)
end
_G.error = error
if _G.originalError == nil then
    _G.originalError = error
end
_G.assert = assert
_G.select = select
_G.type = type
_G.rawget = rawget
_G.rawset = rawset
_G.rawequal = rawequal
_G.rawlen = rawlen or function(b2)
        return #b2
    end
_G.unpack = table.unpack or unpack
_G.pack = table.pack or function(...)
        return {n = select("#", ...), ...}
    end
_G.task = task
_G.wait = wait
_G.Wait = wait
_G.delay = delay
_G.Delay = delay
_G.spawn = spawn
_G.Spawn = spawn
_G.tick = tick
_G.time = time
_G.elapsedTime = elapsedTime
_G.game = game
_G.Game = game
_G.workspace = workspace
_G.Workspace = workspace
_G.script = script
_G.Enum = Enum
_G.Instance = Instance
_G.Random = Random
_G.Vector3 = Vector3
_G.Vector2 = Vector2
_G.CFrame = CFrame
_G.Color3 = Color3
_G.BrickColor = BrickColor
_G.UDim = UDim
_G.UDim2 = UDim2
_G.TweenInfo = TweenInfo
_G.Rect = Rect
_G.Region3 = Region3
_G.Region3int16 = Region3int16
_G.Ray = Ray
_G.NumberRange = NumberRange
_G.NumberSequence = NumberSequence
_G.NumberSequenceKeypoint = NumberSequenceKeypoint
_G.ColorSequence = ColorSequence
_G.ColorSequenceKeypoint = ColorSequenceKeypoint
_G.PhysicalProperties = PhysicalProperties
_G.Font = Font
_G.RaycastParams = RaycastParams
_G.OverlapParams = OverlapParams
_G.PathWaypoint = PathWaypoint
_G.Axes = Axes
_G.Faces = Faces
_G.Vector3int16 = Vector3int16
_G.Vector2int16 = Vector2int16
_G.CatalogSearchParams = CatalogSearchParams
_G.DateTime = DateTime
getmetatable = function(x)
    if G(x) then
        return "The metatable is locked"
    end
    return k(x)
end
_G.getmetatable = getmetatable
type = function(x)
    if w(x) then
        return "number"
    end
    if G(x) then
        return "userdata"
    end
    return j(x)
end
_G.type = type
typeof = function(x)
    if w(x) then
        return "number"
    end
    if G(x) then
        local er = t.registry[x]
        if er then
            if er:match("Vector3") then
                return "Vector3"
            end
            if er:match("CFrame") then
                return "CFrame"
            end
            if er:match("Color3") then
                return "Color3"
            end
            if er:match("UDim") then
                return "UDim2"
            end
            if er:match("Enum") then
                return "EnumItem"
            end
        end
        return "Instance"
    end
    return j(x) == "table" and "table" or j(x)
end
_G.typeof = typeof
tonumber = function(x, es)
    if w(x) then
        return 123456789
    end
    return n(x, es)
end
_G.tonumber = tonumber
rawequal = function(bo, aa)
    return l(bo, aa)
end
_G.rawequal = rawequal
tostring = function(x)
    if G(x) then
        local et = t.registry[x]
        return et or "Instance"
    end
    return m(x)
end
_G.tostring = tostring
t.last_http_url = nil
loadstring = function(al, eu)
    if j(al) ~= "string" then
        return function()
            return bj("loaded", false)
        end
    end
    local cI = t.last_http_url or al
    t.last_http_url = nil
    local ev = nil
    local ew = cI:lower()
    local ex = {
        {pattern = "rayfield", name = "Rayfield"},
        {pattern = "orion", name = "OrionLib"},
        {pattern = "kavo", name = "Kavo"},
        {pattern = "venyx", name = "Venyx"},
        {pattern = "sirius", name = "Sirius"},
        {pattern = "linoria", name = "Linoria"},
        {pattern = "wally", name = "Wally"},
        {pattern = "dex", name = "Dex"},
        {pattern = "infinite", name = "InfiniteYield"},
        {pattern = "hydroxide", name = "Hydroxide"},
        {pattern = "simplespy", name = "SimpleSpy"},
        {pattern = "remotespy", name = "RemoteSpy"}
    }
    for W, ey in ipairs(ex) do
        if ew:find(ey.pattern) then
            ev = ey.name
            break
        end
    end
    if ev then
        local ez = bj(ev, false)
        t.registry[ez] = ev
        t.names_used[ev] = true
        if cI:match("^https?://") then
            at(string.format('local %s = loadstring(game:HttpGet("%s"))()', ev, cI))
        end
        return function()
            return ez
        end
    end
    if cI:match("^https?://") then
        local ez = bj("Library", false)
        at(string.format('local larrysixseven = loadstring(game:HttpGet("%s"))()', cI))
        return function()
            return ez
        end
    end
    if type(al) == "string" then
        al = I(al)
    end
    local R, an = e(al)
    if R then
        return R
    end
    local ez = bj("LoadedChunk", false)
    return function()
        return ez
    end
end
load = loadstring
_G.loadstring = loadstring
_G.load = loadstring
require = function(eA)
    local eB = t.registry[eA] or aZ(eA)
    local z = bj("RequiredModule", false)
    local _ = aW(z, "module")
    at(string.format("local %s = require(%s)", _, eB))
    return z
end
_G.require = require
print = function(...)
    local bA = {...}
    local b8 = {}
    for W, b5 in ipairs(bA) do
        table.insert(b8, aZ(b5))
    end
    at(string.format("print(%s)", table.concat(b8, ", ")))
end
_G.print = print
warn = function(...)
    local bA = {...}
    local b8 = {}
    for W, b5 in ipairs(bA) do
        table.insert(b8, aZ(b5))
    end
    at(string.format("warn(%s)", table.concat(b8, ", ")))
end
_G.warn = warn
shared = bj("shared", true)
_G.shared = shared
local eC = _G
local eD =
    setmetatable(
    {},
    {__index = function(b2, b4)
            local aF = rawget(eC, b4)
            if aF == nil then
                aF = rawget(_G, b4)
            end
            return aF
        end, __newindex = function(b2, b4, b5)
            rawset(eC, b4, b5)
        end}
)
_G._G = eD
function q.reset()
    t = {
        output = {},
        indent = 0,
        registry = {},
        reverse_registry = {},
        names_used = {},
        parent_map = {},
        property_store = {},
        call_graph = {},
        variable_types = {},
        string_refs = {},
        proxy_id = 0,
        callback_depth = 0,
        pending_iterator = false,
        last_http_url = nil,
        last_emitted_line = nil,
        repetition_count = 0,
        current_size = 0,
        limit_reached = false,
        lar_counter = 0,
        captured_constants = {}
    }
    aM = {}
    game = bj("game", true)
    workspace = bj("workspace", true)
    script = bj("script", true)
    Enum = bj("Enum", true)
    shared = bj("shared", true)
    t.property_store[game] = {PlaceId = u, GameId = u, placeId = u, gameId = u}
    _G.game = game
    _G.Game = game
    _G.workspace = workspace
    _G.Workspace = workspace
    _G.script = script
    _G.Enum = Enum
    _G.shared = shared
    local dm = a.getmetatable(Enum)
    dm.__index = function(b2, b4)
        if b4 == F or b4 == "__proxy_id" then
            return rawget(b2, b4)
        end
        local dn = bj("Enum." .. aE(b4), false)
        t.registry[dn] = "Enum." .. aE(b4)
        return dn
    end
end
function q.get_output()
    return aB()
end
function q.save(aD)
    return aC(aD)
end
function q.get_call_graph()
    return t.call_graph
end
function q.get_string_refs()
    return t.string_refs
end
function q.get_stats()
    return {
        total_lines = #t.output,
        remote_calls = #t.call_graph,
        suspicious_strings = #t.string_refs,
        proxies_created = t.proxy_id
    }
end
local eE = {
    callId = "LARRY_",
    binaryOperatorNames = {
        ["and"] = "AND",
        ["or"] = "OR",
        [">"] = "GT",
        ["<"] = "LT",
        [">="] = "GE",
        ["<="] = "LE",
        ["=="] = "EQ",
        ["~="] = "NEQ",
        [".."] = "CAT"
    }
}
function eE:hook(al)
    return self.callId .. al
end
function eE:process_expr(eF)
    if not eF then
        return "nil"
    end
    if type(eF) == "string" then
        return eF
    end
    local eG = eF.tag or eF.kind
    if eG == "number" or eG == "string" then
        local aF = eG == "string" and string.format("%q", eF.text) or (eF.value or eF.text)
        if r.CONSTANT_COLLECTION then
            return string.format("%sGET(%s)", self.callId, aF)
        end
        return aF
    end
    if eG == "local" or eG == "global" then
        return (eF.name or eF.token).text
    elseif eG == "boolean" or eG == "bool" then
        return tostring(eF.value)
    elseif eG == "binary" then
        local eH = self:process_expr(eF.lhsoperand)
        local eI = self:process_expr(eF.rhsoperand)
        local X = eF.operator.text
        local eJ = self.binaryOperatorNames[X]
        if eJ then
            return string.format("%s%s(%s, %s)", self.callId, eJ, eH, eI)
        end
        return string.format("(%s %s %s)", eH, X, eI)
    elseif eG == "call" then
        local dr = self:process_expr(eF.func)
        local bA = {}
        for L, b5 in ipairs(eF.arguments) do
            bA[L] = self:process_expr(b5.node or b5)
        end
        return string.format("%sCALL(%s, %s)", self.callId, dr, table.concat(bA, ", "))
    elseif eG == "indexname" or eG == "index" then
        local bS = self:process_expr(eF.expression)
        local ba = eG == "indexname" and string.format("%q", eF.index.text) or self:process_expr(eF.index)
        return string.format("%sCHECKINDEX(%s, %s)", self.callId, bS, ba)
    end
    return "nil"
end
function eE:process_statement(eF)
    if not eF then
        return ""
    end
    local eG = eF.tag
    if eG == "local" or eG == "assign" then
        local eK, eL = {}, {}
        for W, b5 in ipairs(eF.variables or {}) do
            table.insert(eK, self:process_expr(b5.node or b5))
        end
        for W, b5 in ipairs(eF.values or {}) do
            table.insert(eL, self:process_expr(b5.node or b5))
        end
        return (eG == "local" and "local " or "") .. table.concat(eK, ", ") .. " = " .. table.concat(eL, ", ")
    elseif eG == "block" then
        local b9 = {}
        for W, eM in ipairs(eF.statements or {}) do
            table.insert(b9, self:process_statement(eM))
        end
        return table.concat(b9, "; ")
    end
    return self:process_expr(eF) or ""
end
function q.dump_file(eN, eO)
    q.reset()
    az("this file is generated using larry")
    local as = o.open(eN, "rb")
    if not as then
        return false
    end
    local al = as:read("*a")
    as:close()
    B("[Dumper] Sanitizing Luau and Binary Literals...")
    local eP = I(al)
    local R, eQ = e(eP, "Obfuscated_Script")
    if not R then
        B("\n[LUA_LOAD_FAIL] " .. m(eQ))
        return false
    end
    local eR =
        setmetatable(
        {LuraphContinue = function()
            end, script = script, game = game, workspace = workspace, LARRY_CHECKINDEX = function(x, ba)
                local aF = x[ba]
                if j(aF) == "table" and not t.registry[aF] then
                    t.lar_counter = t.lar_counter + 1
                    t.registry[aF] = "lartab" .. t.lar_counter
                end
                return aF
            end, LARRY_GET = function(b5)
                return b5
            end, LARRY_CALL = function(as, ...)
                return as(...)
            end, LARRY_NAMECALL = function(eS, em, ...)
                return eS[em](eS, ...)
            end, pcall = function(as, ...)
                local dg = {g(as, ...)}
                if not dg[1] and m(dg[2]):match("TIMEOUT") then
                    i(dg[2], 0)
                end
                return table.unpack(dg)
            end},
        {__index = _G, __newindex = _G}
    )
    if setfenv then
        setfenv(R, eR)
    end
    B("[Dumper] Executing Protected VM...")
    local eT = p.clock()
    b(
        function()
            if p.clock() - eT > r.TIMEOUT_SECONDS then
                error("TIMEOUT", 0)
            end
        end,
        "",
        1000
    )
    local eo, eU =
        h(
        function()
            R()
        end,
        function(ds)
            return tostring(ds)
        end
    )
    b()
    if not eo then
        az("Terminated: " .. eU)
    end
    return q.save(eO or r.OUTPUT_FILE)
end
function q.dump_string(al, eO)
    q.reset()
    az("this file is generated using larry")
    aA()
    if al then
        al = I(al)
    end
    local R, an = e(al)
    if not R then
        az("Load Error: " .. (an or "unknown"))
        return false, an
    end
    xpcall(
        function()
            R()
        end,
        function()
        end
    )
    if eO then
        return q.save(eO)
    end
    return true, aB()
end


-- Ensure LuraphContinue exists
_G.LuraphContinue = _G.LuraphContinue or function() end

return q
end)()
-- ==================== END LARRY DUMPER ====================



local Services = {} :: { [string]: { [any]: any } }
local Predefined = {} :: { [any]: any }
local Deferred = {} :: { func }
local IteratorTypes = {} :: { [string]: { any } } -- for example, ["game"] = { number, Instance }
local AliasToName = {
    int64 = "number",
    double = "number",
    int = "number"
}
local FunctionHooks = {} :: FunctionHooks
local Lengths = {} :: { [Spied]: number }
local Illegal = {
    ["for"] = true,
    ["end"] = true,
    -- ... other keywords
}

for Key, Data in next, InstanceLib do
    if table.find(Data.tags or {}, "Service") then
        Services[Key] = Data
    end
end

--[[
local process = require("@lune/process")
local roblox = {};
local serde = require("@lune/serde")
local net = require("@lune/net")]]

local min, max = math.min, math.max
local insert, pack, find, concat, isfrozen = table.insert, table.pack, table.find, table.concat, table.isfrozen;
local rep, format, gsub, match, split, sub = string.rep, string.format, string.gsub, string.match, string.split, string.sub;
local debuginfo = debug.info
local GlobalIndex : func, TypeSpy : ( string, string, ...any) -> any;

local Alphabet : { string } = split("abcdefghijklmnopqrstuvwxyz", "")

local function GenId(len)
    local txt = ''
    for i = 1,len or 6 do
        txt ..= Alphabet[math.random(1, #Alphabet)]
    end
    return txt
end

local TraceId : string = GenId(6)
local HardwareId : string = GenId(4) .. "-" .. GenId(4) .. "-" .. GenId(4) .. "-" .. GenId(4)
local CallId : string = GenId(8)
local MemoryCategory : string = TraceId
local EnvName : string = "fenv"
local ConstantsStr: string = "constants"
local Casing : string = "pascal"

local IgnoreInEq = {
    [EnvName] = true,
    _G = true,
    string = true,
    tostring = true
}
local StatementHooks = {}

local LuaGlobals = {}
for _, v in next, { "type", "print", "warn", "tostring", "tonumber", "newproxy" } do LuaGlobals[v] = true end

local SharedGlobals = {
    SavedPristine = {},
    PristineKeys = {
        game = true, workspace = true, task = true, CFrame = true, spawn = true
    },
    Pristine = false,
    Logs = {}, --> print & warn & others
    Callbacks = {},
    Deferred = {},
    Delay = 0,
    FRAME_TIME = TIME_TO_WAIT,
    StartedRunning = 0,
    HWID = HardwareId
}

local Settings = {
    hookOp = true,
    minifier = true,
    explore_funcs = true,
    lua = false,
    ipt = nil,
    discord = true,
    inf_loops = true,
    runtimelogs = false,
    constants = false,
    spyexeconly = false, --> implement latar
    roblox = false,
    isPremium = true,
    type_annotations = false
}

local IsTesting = true;

local function StrToValue(Str)
    if Str == "false" then return false
    elseif Str == "true" then return true
    elseif Str == "nil" then return nil
    elseif tonumber(Str) then return tonumber(Str)
    else return Str end
end

for index, arg in process.args do
    local k, v = match(arg, "([%w_]+)=(.+)")
    local Arg = arg -- remove --

    if not k and Settings[arg] == nil and not Settings.ipt then
        Settings.ipt = arg
    end

    if Arg == "prod" then
        IsTesting = false
        continue
    elseif Arg == "logs" then
        SendLogs = true
        continue
    end

    if v then -- version=, outfile =
        Settings[k] = StrToValue(v)
    else
        local neg = sub(Arg, 1, 1)
        if neg == "!" then Settings[Arg:sub(2)] = false continue end
        Settings[Arg] = true
    end
end

local hookOp = Settings.hookOp

DONT_DELETE_FILES = DONT_DELETE_FILES or Settings.dont_delete
CallId = DONT_DELETE_FILES and "" or CallId

local SpyExecOnly = Settings.spyexeconly

local Id : number = -1;
local AllowedGetRequests : number = 0;
local Args : number = 0;
local CallsHandler : func = nil

local AllowedUrlsInTheEnd = {} :: { string }
local VariablesLen = 0
local Variables = fenv.setmetatable({}, { __newindex = function(_, k, v) rawset(_, k, v) VariablesLen += 1 end }) :: Variables
local ReverseVariables = {}
local Internal = {} :: Internal
local Usages = {} :: { [string]: number }
local Information = {} :: { [Spied]: { [string]: any } }
local SpiedToInstance = {} :: { [{[any] : any}]: Instance }
local Children = {} :: { [Spied]: { Instance } }
local Wrapped = {}

local LuaTypes = {
    string = true, number = true, table = true, userdata = true, boolean = true, ["function"] = true, thread = true, ["nil"] = true
}
local LuauTypes = {
    string = true, number = true, table = true, userdata = true, boolean = true, ["function"] = true, thread = true, buffer = true, ["nil"] = true
}

local _print = print
print = function(...)
    local function Color(txt, code)
        return `\27[{code}m{txt}\27[0m`
    end

    local Line, Name = debug.info(2, "ln")
    local ColoredName = Color(Name == "" and "???" or Name, 32)
    local ColorLine = Color(`line {Line}`, 35)

    local FinalText = `[ {ColoredName} @ {ColorLine} ]:`

    for _, v in next, {...} do
        if typeof(v) == "table" and not Variables[v] then
            local mt = getmetatable(v)
            if mt and mt.__tostring then
                return _print(FinalText, "PROTECTED TABLE DETECTED, POSSIBLE DETECTION?")
            end
        end
    end

    _print(FinalText, ...)
end

local _Env = getfenv()
local TrueEnv = getmetatable(_Env).__index;

local function GetVar() : string
    Id += 1
    return "r" .. Id
end

local function GetCount(Var : string, AddAnyway : boolean?) : string
    --> Returns the formatted variable name with _(x) where x is how many times it's been used.
    Usages[Var] = (Usages[Var] or -1) + 1
    local Use = Usages[Var]
    if Use == 0 and not AddAnyway then return Var end

    return Var .. "_" .. Use
end

local function GetInternalValue(Spied : any, Recursed : boolean?) : any
    --[[
        Internal: {
            r1: { 1 }
        }

        GetInternalValue(r1) -> Internal.r1 -> Internal.r1[1] is spied? no then return

        Internal: {
            r1: { game },
        }

        GetInternalValue(r1) -> Internal.r1 -> Internal.r1[1] is spied? yes then check if that has an internal value, if yes then return GetInternalValue(val) otherwise return self.
    ]]
    local Value = Internal[Variables[Spied]];
    if Value then
        local V1 = Value[1]
        local VARV1 = Variables[V1]

        if VARV1 and not Recursed then
            local Val = Internal[VARV1]
            if not Val then return V1 end

            return GetInternalValue(Val[1], true)
        end

        return V1
    end
    return Spied;
end

local function SetInternalValue(Var : Variable, Value : any)
    Internal[Var] = { Value };
end

local SavedParams = {}
local ParamsDict = {}
local NumbersDict = {}
for i = 1, 10 do NumbersDict[tostring(i - 1)] = true end

local function GetParams(Value : (any) -> any, Infos : { any }?) : { string }
    if SavedParams[Value] then return SavedParams[Value] end

    local Params = {}

    local pC, vararg = debug.info(Value, "a")
    local Suffix = if Args == 1 then "" else "_" .. Args

    local InfoList = {}
    for _, v in next, Infos or {} do
        insert(InfoList, v.Name)
    end

    for i = 1, pC do
        insert(Params, if InfoList[i] then GetCount(InfoList[i]) else "p" .. i .. Suffix)
    end

    for i = 1, 3 do
        --insert(Params, "ext_p" .. i .. Suffix)
        insert(Params, Alphabet[i] .. Suffix)
    end

    if vararg then
        insert(Params, "...")
    end

    SavedParams[Value] = Params;

    return Params
end

local Functions = {}
local CClosures = {}
local Types = {}

local function iscclosure(f : thread | (any) -> any) : boolean
    if CClosures[f] then return true end
    local Type = typeof(f)
    if Type ~= "function" then return false end

    local info = debuginfo(f, "s")
    return info == '[C]'
end

local function Function(Callback, Path, IsCClosure)
    local Old = ReverseVariables[Path]
    if Old then return Old end

    if IsCClosure then
        CClosures[Callback] = true
    end

    --[[local Result = Callback;

    Callback = function(...)
        return Result(...)
    end]]

    Variables[Callback] = Path
    ReverseVariables[Path] = Callback
    Types[Callback] = "function"

    return Callback;
end

local function thread(func : func)
    -- how do we create a thread..?
    return coroutine.create(func); -- :sob::sob::sob::sob::sob:
end

local function isUnsafePattern(p)
    if p:find("%.%*.*%.%*") then
        return true, "Multiple '.*' detected"
    end

    if p:find("%b()%s*[%*%+]") then
        return true, "Nested repetition detected"
    end

    local wildcardCount = select(2, p:gsub("%.%*", ""))
    if wildcardCount > 3 then
        return true, "Too many wildcards"
    end

    return false
end

local function IsExecutor(Key: string) : string?
    for i, v in next, ExecutorEnvironment do
        if find(v, Key) then return i end
    end
    return;
end

local function SetIterator(Path : string, TypeI : string, TypeV : string) IteratorTypes[Path] = { TypeI, TypeV } end

local UserRegex = "C:[/\\]+Users[/\\]+.-[\\/]([^\\/]+):(%d+)"

local function HideErrors(text : string, hideLines : boolean?, clean : boolean?) : string
    if typeof(text) ~= "string" then
        local Meow = tostring(text)
        if Settings.debug then return Meow end
        return Meow:match("[^\n]+") or text;
    end

    text = text:gsub(
        UserRegex,
        format("%s%s", "%1", hideLines and "" or ":%2")
        --format("[string \"%s\"]%s", TraceId, hideLines and "" or ":%1")
    )
    if not hideLines then
        text = text:gsub(":%d+:", ":1:")
    end
    if clean then
        text = text:gsub("%w+:%d+:%s*", "")
    end
    return text
end

local function UseHookOp(Source : string, SourceFile : string?) : (boolean, string)
    local FileName = SourceFile;
    if not FileName then
        FileName = "./cache/" .. GenId(8)
        fs.writeFile(FileName, Source)
    end

    local OutPath = FileName .. "-unparsed.lua"
    local ScriptPath = hookOp and "mods/hookOp.luau" or "mods/hookOpButNotReally.luau"
    local HookArgs = {
        FileName,
        OutPath,
        CallId,
        --        Obfuscator == "Luraph" and "0" or Settings.constants and "1" or "0",
        Settings.constants and "1" or "0",
        Settings.inf_loops and "1" or "0",
        tostring(WHILE_LIMIT),
    }

    -- Prefer Lute for @std/syntax/parser; allow explicit override.
    local HookBin = process.env and process.env.HOOKOP_BIN
    local UseLune = process.env and process.env.HOOKOP_USE_LUNE
    local onLune = (not process.exec)
    if not HookBin then
        if UseLune or onLune then
            HookBin = process.os == "windows" and "lune.exe" or "lune"
        else
            HookBin = process.os == "windows" and "lute.exe" or "lute"
        end
    end

    local Args = {}
    if UseLune then
        Args = { "run", ScriptPath, unpack(HookArgs) }
    else
        Args = { ScriptPath, unpack(HookArgs) }
    end

    local POut
    if process.exec then
        -- lute: process.exec is a global
        POut = process.exec(HookBin, Args)
    else
        -- lune: use @lune/process.spawn with full path resolution
        local proc = require("@lune/process")
        local fs_mod = require("@lune/fs")
        HookBin = (function()
            if fs_mod.isFile(HookBin) then return "./" .. HookBin end
            local full = proc.cwd .. "/" .. HookBin
            if fs_mod.isFile(full) then return full end
            return HookBin
        end)()
        local r = proc.spawn(HookBin, Args)
        POut = { exitCode = r.code, stdout = r.stdout or "", stderr = r.stderr or "" }
    end

    if POut and POut.exitCode and POut.exitCode ~= 0 then
        local errMsg = POut.stderr and #POut.stderr > 0 and POut.stderr or `hookOp exited with code {POut.exitCode}`
        return false, `--err{errMsg}`
    end

    if FileName ~= SourceFile then
        fs.removeFile(FileName)
    end

    local s, Content = pcall(fs.readFile, OutPath)
    if not DONT_DELETE_FILES and fs.isFile(OutPath) then pcall(fs.removeFile, OutPath) end
    if not s or DONT_DELETE_FILES then print("Output:",POut.stdout,POut.stderr) end
    if not s then
        local errMsg = POut.stderr and #POut.stderr > 0 and POut.stderr or "hookOp output missing"
        return false, `--err{errMsg}` 
    end

    return true, Content
end

local function EnvLog(Source : (any) -> any, Nest : number) : AstExpression
    --> Environment logs the given file & outputs the code

    local function GetMaxOps(n) return 500_000 / max(n * 5, 1) * MAX_OPS_MUL end

    Nest = Nest or 0;

    local AST = Ast.new()
    AstLib.SetGlobal("AST", AST)
    if Nest == 0 then
        Ast.addStatement(
            AST,
            Ast.Assign(
                { Ast.Variable(EnvName) },
                { Ast.FunctionCall(Ast.Variable("getfenv"), {}) },
                false
            )
        )
    end

    task.spawn(function()
        if Settings.version then
            while task.wait(1) and not DONE_PROCESSING do
                PRINT("Alive")
                if Settings.runtimelogs then
                    pcall(function()
                        fs.writeFile(
                            Settings.out, AstLib.Stringify(AstLib.Minify(AST, not Settings.minifier))
                        )
                    end)
                end
            end
        end
    end)

    local OpCount = 0;
    local StartedRunning;
    local TotalWhiles = 0;
    local TotalRepeats = 0;

    local MaxOps = GetMaxOps(Nest)
    local Env = {} :: {};
    local EnvValues = {
        load = {},
        package = {},
        file = {},
        io = {}
    }

    local function OpCountCheck()
        OpCount += 1
        if OpCount >= MaxOps then
            error("too many operations", 2)
        end
    end

    local function Typeof(Value : any)
        local Type = Types[Value]
        if Type then return Type, Value end
        local int = GetInternalValue(Value)
        return typeof(int), int
    end

    local function checktype(obj : any, expected : string, msg : string, allowNn : boolean?) : any
        if allowNn and not Internal[Variables[obj]] then return obj end --> has no value..?

        local type, int = Typeof(obj)
        assert(type == expected, `{msg}, {expected} expected got {type}`)
        return int;
    end

    local ToAST : (any, { [string]: any }?) -> AstExpression, SpyParams;

    local ToExplore = {}
    local ToExploreHash = {}
    local VarValues = {} :: {
        [string]: any
    }

    local WaitingIfs = {}
    local Strings = {}
    local ConstantList = {}
    local AlwaysIgnore = {
        [EnvName] = true,
        string = true,
        bit32 = true,
        table = true,
        string = true
    }
    local Nil = {
        getconstants = true, -- msec
        _ENV = true, --> executor thing
        io = true,
        file = true
    }
    local ForceNil = {
        RandomStrings = true,
        package = true,
        inf = true, --> uuuuuuuuh wearedevs
        io = true,
    }
    local Indexes = {}
    local SecureEnv = {} :: Environment
    local VisitedTables = {}
    local Luraph = false;

    local ActiveLoops = 0;
    local ForLoopId = 0;
    local StopWhileLoops = 0;
    local IfId = 0;
    local WhileExprs, LastLen = {}, 0;

    local function CloseIfs(ASt)
        local AST = ASt or AST;
        if #WaitingIfs > 0 then
            local Oldest = WaitingIfs[#WaitingIfs]
            local LengthNow = #AST.data.statements

            if true then
                local StartedAt = Oldest[2]
            
                local Comment = Ast.PermaComment(Ast.RawText(`{Oldest[3] and "didnt run (else)" or "ran"}, if id: {Oldest[#Oldest]}`))
                local Body = Ast.Block{Comment}
                for i = StartedAt + 1, LengthNow do
                    Ast.addStatement(Body, AST.data.statements[i])
                    AST.data.statements[i] = nil
                end

                local IsElse = Oldest[3]

                if IsElse then
                    Ast.addStatement(AST, Ast.IfStat(ToAST(Oldest[1]), Ast.Block{}, Body))
                else
                    Ast.addStatement(AST, Ast.IfStat(ToAST(Oldest[1]), Body))
                end
            end
        end
        WaitingIfs = {}
    end

    local function Assert(Type, WhatItShouldBe, Message, AllowAny)
        if AllowAny and Type == "table" then
        else
            assert(Type == WhatItShouldBe, Message);
        end
    end

    local function CloseAllEnds(ASt)
        ASt = ASt or AST
        CloseIfs(ASt)
        for i = 1, ActiveLoops do
            Ast.addStatement(ASt, Ast.End())
        end
        ActiveLoops = 0
    end

    local IsExploring, IsInPcall;

    local function Explore(Func : (any) -> any, Options : { [string]: any }, ...) : AstBlock
        Options = Options or {}

        local DontBypassBeautify = not Options.bypass_beautify
        if Options.bypass_ignore then
            DontBypassBeautify = false
        else
            if not Settings.explore_funcs or Options.ignore_funcs then
                if Options.as_func then
                    return Ast.Function(GetParams(Func), Ast.Block{}), {}
                end

                return Ast.Block{}, {}
            end
        end

        if not ToExploreHash[Func] and DontBypassBeautify then
            local id = "to_explore_" .. GenId(32)
            local node = Ast.Variable(id)

            insert(ToExplore, { func = Func, id = id, node = node, args = Options, idx = #ToExplore, traceback = debug.traceback() })
            --local node = Ast.Block({})
            --Ast.addStatement(node, Ast.Comment(Ast.RawText("Unexplored function..")))
            --insert(ToExplore, { func = Func, node = node, args = Options, idx = #ToExplore })
            --ToExploreHash[Func] = { id, Options }
            ToExploreHash[Func] = true

            return node;
        end

        IsExploring = not Options.as_pcall

        local _AST, _Nest, _OpCount, _MaxOps, _Delay, _Whiles, _Limit, _Waiting, _Loops, _LastLen, _LastExpr, _IsInPcall =
            AST, Nest, OpCount, MaxOps, SharedGlobals.Delay, TotalWhiles, WHILE_LIMIT, WaitingIfs, ActiveLoops, LastLen, WhileExprs, IsInPcall;
        AST, Nest, OpCount, MaxOps, SharedGlobals.Delay, TotalWhiles, WHILE_LIMIT, WaitingIfs, ActiveLoops, LastLen, WhileExprs, IsInPcall =
            Ast.Block({}),
            Nest + 1,
            0,
            GetMaxOps(Nest + 1),
            Options.delay or 0,
            0,
            WHILE_LIMIT / 2,
            {},
            0,
            0,
            {},
            Options.as_pcall and Func;

        local Params = Options.params;
        local ParamInfos = Options.param_infos;

        local Gotten = {};

        if not Params--[[ and (Nest ~= 2 or not Options.as_pcall)]] and (Nest ~= 1 or not Options.as_pcall) then -- spy them
            Gotten = GetParams(Func, ParamInfos)
            Params = SpyParams(Gotten, ParamInfos)
        end

        --local Results = pack(pcall(if Options.as_pcall or true then Func else fenv.setfenv(Func, Env), unpack(Params or {})))
        --local IsRegular = getfenv(Func)
        local Results = pack(pcall(Func, unpack(Params or {})))
        --local Results = pack(pcall(if IsRegular == Env or Options.as_pcall then Func else setfenv(Func, Env), unpack(Params or {})))
        local Logged = Ast.Block{};

        for _, Statement in next, AST.data.statements do
            Ast.addStatement(Logged, Statement)
        end

        if #Logged.data.statements > 0 then
            Args += 1
        end

        CloseAllEnds(Logged)

        if not Results[1] then
            if not Options.as_pcall then
                local Last = Logged.data.statements[#Logged.data.statements]
                if Last and Last.kind == "call" and Last.data.func.data.name == "error" then
                else
                    local Error = Results[2]
                    --[[Ast.addStatement(Logged, Ast.FunctionCall(
                        Ast.Variable("error"), {
                            ToAST(
                                if Settings.debug then Error else HideErrors(Error, not IsTesting)
                            )
                        })
                    )]]
                    
                    Ast.addStatement(
                        Logged,
                        Ast.NonOptionalComment(
                            Ast.RawText("The script errored here with the message: "),
                            ToAST(
                                if Settings.debug then Error else HideErrors(Error, not IsTesting)
                            )
                        )
                    )
                end
            end
        elseif Results.n > 1 then
            local Returned = {}
            for i = 2, Results.n do
                insert(Returned, ToAST(Results[i]))
            end
            Ast.addStatement(Logged, Ast.Return(Returned))
        end

        AST, Nest, OpCount, MaxOps, SharedGlobals.Delay, TotalWhiles, WHILE_LIMIT, WaitingIfs, ActiveLoops, LastLen, WhileExprs, IsInPcall =
            _AST, _Nest, _OpCount, _MaxOps, _Delay, _Whiles, _Limit, _Waiting, _Loops, _LastLen, _LastExpr, _IsInPcall;
        IsExploring = false

        if Options.as_func then
            Logged = Ast.Function(Gotten, Logged)
        end

        return Logged, Results
    end

    local function shallowEqual(t1, t2)
        -- If they are the same table, they are equal
        if t1 == t2 then return true end
        -- If either isn't a table, they aren't equal
        if type(t1) ~= "table" or type(t2) ~= "table" then return false end
    
        -- Check if t1 keys/values exist in t2
        for k, v in pairs(t1) do
            if t2[k] ~= v then return false end
        end
    
        -- Check if t2 has extra keys not in t1
        for k, _ in pairs(t2) do
            if t1[k] == nil then return false end
        end
    
        return true
    end

    ToAST = function(Value : any, Data : any) : AstExpression
        if Ast.IsAst(Value) then return Value end;

        local Var = Variables[Value]
        local Str = Strings[Value]
        if Var then
            return Ast.Variable(Var)
        elseif Str then
            return Ast.Variable(Str)
        end

        local Type = typeof(Value)
        if Type == "number" then
            return Ast.Number(Value);
        elseif Type == "string" then
            return Ast.String(Value)
        elseif Type == "error" then
            local Meow = tostring(Value)
            Meow = if Settings.debug then Meow else Meow:match("[^\n]+") or Meow;
            return ToAST(Meow);
        elseif Type == "nil" then
            return Ast.Nil(Value)
        elseif Type == "function" then -- ono..
            local Old = Functions[Value]
            if Old and not (Data and Data.dont_cache) and (not Data or shallowEqual(Data, Old[2])) then return Old[1] end

            Data = if typeof(Data) == "table" then Data else {}
            Data.bypass_beautify = if Data.bypass_beautify == nil then false else Data.bypass_beautify

            -- Since the function is STILL attached to this Env, We can just log the new nodes.

            local Logged = Explore(Value, Data);
            
            Functions[Value] = { Logged, Data }
            --return Ast.Function(GetParams(Value), Logged)
            return Logged;
        elseif Type == "table" then
            if VisitedTables[Value] then
                return Ast.FunctionCall(Ast.Variable("RECURSIVE_TABLE"), {})
            end

            VisitedTables[Value] = true
            local Metatable = getmetatable(Value)
            local Fixed = {}

            for Key, Value in next, Value do
                insert(Fixed, {
                    key = ToAST(Key, Data),
                    val = ToAST(Value, Data);
                })
            end

            local TblVar = Ast.Variable(GetVar());
            Ast.addStatement(
                AST,
                Ast.Assign(
                    {
                        TblVar
                    },
                    {
                        Ast.Table(Fixed)
                    }
                )
            )

            if Metatable then
                local mt = {}
                local Type = typeof(Metatable)
                if Type == "table" then
                    for i, v in next, Metatable do
                        insert(mt, {
                            key = ToAST(i),
                            val = ToAST(v, { ignore_funcs = true, as_func = true })
                        })
                    end
                else
                    mt = {
                        {
                            key = Ast.String("__metatable"),
                            val = ToAST(Metatable)
                        }
                    }
                end

                VisitedTables[Value] = nil

                return Ast.FunctionCall(Ast.Variable("setmetatable"), { TblVar, Ast.Table(mt) });
            end

            VisitedTables[Value] = nil;
            --Variables[Value] = TblVar.data.name;

            return TblVar;
        elseif Type == "boolean" then
            return Ast.Boolean(Value);
        elseif Type == "Color3" then
            return Ast.FunctionCall(
                Ast.Index(Ast.Variable("Color3"), Ast.String("fromRGB")),
                {
                    Ast.Number( Value.R * 255 // 1 ),
                    Ast.Number( Value.G * 255 // 1 ),
                    Ast.Number( Value.B * 255 // 1 )
                }
            )
        elseif Type == "ColorSequenceKeypoint" then
            return Ast.FunctionCall(
                Ast.Index(Ast.Variable("ColorSequenceKeypoint"), Ast.String("new")),
                {
                    Ast.Number(Value.Time),
                    ToAST(Value.Value)
                }
            )
        elseif Type == "EnumItem" then
            return Ast.Variable(tostring(Value))
        else
            return Ast.FunctionCall(
                Ast.Variable("UNKNOWN_TYPE"),
                {
                    Ast.String(Type),
                    ToAST(tostring(Value))
                }
            )
        end
    end

    local function TupleToAST(...) : {AstExpression}
        local ASTs = {}
        for _, v in next, {...} do
            insert(ASTs, ToAST(v))
        end
        return ASTs
    end

    local function Define(Var : AstExpression | string, Value : any, IsGlobal : boolean, Raw : boolean?) : AstExpression
        OpCountCheck()

        local Type = typeof(Var)
        local ActualVar = Type == "string" and Ast.Variable(Var) or Var
        local Assign = Ast.Assign(
            {
                ActualVar
            },
            { if Raw then Value else ToAST(Value) },
            IsGlobal
        )

        Ast.addStatement(
            AST,
            Assign
        )

        if ActualVar.kind == "variable" then
            VarValues[ActualVar.data.name] = Value
        end

        return Assign;
    end

    local function DefineVar(...) : (string, AstExpression)
        local Var = GetVar()
        local Stat = Define(Var, ...)
        return Var, Stat
    end

    local function AppendCall(FuncName : string, ...) : (string, AstExpression) --> Returns variable name
        OpCountCheck();
        local Value = VarValues[FuncName] -- The function's value, we use this to construct namecalls.
        if Value and Value.kind == "index" then
            local ValueBase = Value.data.base
            if ValueBase.kind == "variable" then
                local Name = ValueBase.data.name
                local FirstArg = Variables[...]
                local MethodInfo = VarValues[FuncName]

                if Name == FirstArg and (MethodInfo and MethodInfo.kind == "index") then --> Namecall
                    local Key = MethodInfo.data.key--.data.value
                    local KeyVar = Key.data.value
                    if Key.kind == "variable" then
                        KeyVar = VarValues[MethodInfo.data.key.data.name].data.value --> Other constant?
                    elseif Key.kind == "string" then
                        KeyVar = Key.data.value
                    end
                    return DefineVar(
                        Ast.Namecall(
                            Ast.Variable(MethodInfo.data.base.data.name),
                            Ast.Variable(KeyVar),
                            TupleToAST(select(2, ...))
                        )
                    )
                end
            end
        end
        return DefineVar(
            Ast.FunctionCall(typeof(FuncName) == "string" and Ast.Variable(FuncName) or FuncName, TupleToAST(...))
        )
    end

    local function Comment(...)
        if true then return end

        Ast.addStatement(AST, Ast.Comment(unpack(TupleToAST(...))));
    end

    local function ReverseDict(Dict : { [any]: any }) : { [any]: any }
        local New = {}
        for i, v in next, Dict do
            New[v] = i
        end
        return New
    end

    local Metatable, Math, MathV2;
    local MathNames = {
        ["/"] = {
            [2] = "half",
            [3] = "third",
            [4] = "quarter",
        },
        ["*"] = {
            [2] = "double",
            [3] = "triple",
            [4] = "quadruple",
            [5] = "quintuple"
        }
    }

    MathV2 = {
        __eq = "==",
	    __neq = "~=",
	    __lt = "<",
	    __le = "<=",
	    __gt = ">",
	    __ge = ">=",
    }
    Math = {
	    __add = "+",
	    __sub = "-",
	    __mul = "*",
	    __div = "/",
	    __idiv = "//",
	    __pow = "^",
        __mod = "%",
	    __concat = ".."
    }

    local SymbolToName = ReverseDict(Math)

    local function InternalIfy(...)
        local Args = {...}
        for i, v in next, Args do
            Args[i] = GetInternalValue(v)
        end
        return unpack(Args)
    end

    local Iters = {}
    local MissingEnums = {
        Font = {
            GothamSemiBold = true,
            GothamSemibold = true
        },
        RaycastFilterType = {
            Blacklist = true,
            Whitelist = true
        }
    }

    local function __call(Self, ...)
        local Path = Variables[Self];
        local Cached = (Internal[Path] or {{}})[1] :: { [string]: any };
        local args = { ... }
        local len = select("#", ...)

        if len == 2 and args[1] == nil then --> heh iter
            if args[2] == nil then -- started the iteration, when its not nil then its done
                CloseAllEnds(AST);

                Iters[Path] = true

                -- its an iterator thing
                local i, v = GetCount("i"), GetCount("v")

                Ast.addStatement(
                    AST,
                    Ast.ForPrep(
                        Ast.Variable(i),
                        Ast.Variable(v),
                        Ast.Variable(Path),
                        "obf_" .. ActiveLoops
                    )
                )

                ActiveLoops += 1

                return Spy(i), Spy(v)
            elseif Iters[Path] then
                ActiveLoops -= 1
                CloseIfs()
                Ast.addStatement(AST, Ast.End("obf_" .. ActiveLoops))

                return nil, nil
            end
        end

        local Var = AppendCall(Path, ...)

        return Spy(Var, nil, Information[Self]);
    end

    function GetValueInner(x, Symbol, y)
        if Symbol == "+" then return x + y
	    elseif Symbol == "-" then return x - y
	    elseif Symbol == "*" then return x * y
	    elseif Symbol == "/" then return x / y
	    elseif Symbol == "//" then return x // y
	    elseif Symbol == "^" then return x ^ y
        elseif Symbol == "%" then return x % y
	    elseif Symbol == ".." then return x .. y
	    elseif Symbol == "==" then return rawequal(x, y)
	    elseif Symbol == "~=" then return not rawequal(x, y)
	    elseif Symbol == "<" then return x < y
    	elseif Symbol == "<=" then return x <= y
	    elseif Symbol == ">" then return x > y
	    elseif Symbol == ">=" then return x >= y
        end
    end

    function Spy(Path : string, Value : any, Info: any) : any
        --if Variables[Value] then return Value end
        assert(typeof(Path) == "string", `invalid argument #1 to 'Spy', string expected got {typeof(Path)} - {debuginfo(2, "l")}, {debuginfo(3, "l")}`)

        local Reversed = ReverseVariables[Path]
        if Reversed then return Reversed end -- Dont log duplicates.

        if not Metatable then
            local Info = Info or {};

            Metatable = {};

            function Metatable.__newindex(Self, Key, Value)
                Info = Information[Self] or Info;

                local Path = Variables[Self]
                local Base = Ast.Variable(Path);

                local Cached = (Internal[Path] or {{}})[1] :: { [string]: any };

                if rawequal(Cached, Env) then Cached[Key] = Value return end --> Stop meowing pal

                local Type = Typeof(Cached)
                local DontSet = Info.from_index and Cached == nil;

                if Type == "Instance" then
                    local Int = GetInternalValue(Value)
                    if not Variables[Int] then
                        Cached[Key] = Int;
                        return
                    else
                        DontSet = true
                        Value = Int;
                    end
                end

                Define(
                    Ast.Index(Base, ToAST(Key)),
                    ToAST(Value),
                    true
                )

                if LuaTypes[Type] and Type ~= "table" and Cached then
                    return
                end
                
                if not DontSet then
                    Value = GetInternalValue(Value)
                    Cached[Key] = Value
                end
                rawset(Self, Key, Value)

                return nil;
            end

            function Metatable.__index(Self, Key : string)
                Info = Information[Self] or Info;

                local Path = Variables[Self]
                local IsInternal = Internal[Path]
                local Cached = (
                    IsInternal or {}
                )[1] :: { [string]: any };

                if rawequal(Cached, Env) then return Cached[Key] end --> Stop meowing pal

                local DontCache = Variables[Cached] ~= nil or Cached == nil;

                Cached = Cached or {}

                local Type = Typeof(Cached)

                --if Type ~= "table" and LuauTypes[Type] then Cached = {} end

                if Type == "Enum" then
                    local EnumKey = tostring(Cached):split(".")[2]
                    local List = MissingEnums[EnumKey]
                    if List and List[Key] then
                        DontCache = true
                    else
                        DontCache = typeof(Key) == "table"
                    end
                elseif Type == "Instance" then
                    DontCache = not pcall(function() return Cached[Key] end) --> ??!?!?!?!
                end

                local Cache =
                    if DontCache then nil else Cached[Key];

                local Base = Ast.Variable(Path);

                local Var = DefineVar(
                    Ast.Index(Base, ToAST(Key)),
                    false,
                    true
                )

                local newinfo = {}
                do
                    local meow = Info.indexed_instance
                    if meow ~= nil then newinfo.indexed_instance = meow end
                    newinfo.from_index = true--DontCache
                end

                if LuaTypes[Type] and Type ~= "table" and Type ~= "string" then
                    return nil
                end

                if Cached and not DontCache then
                    if typeof(Cache) == "function" then
                        if Type == "string" then
                            return SecureEnv.string[Key]
                        end

                        return Function(function(...)
                            local Spied, Statement = AppendCall(Var, ...)
                            local Values = pack(Cache(InternalIfy(...)))

                            if Values.n == 1 then
                                return Spy(Spied, nil, newinfo);
                            else
                                return ToMultiVars(Statement, Values)
                            end
                        end, Var, iscclosure(Cache))
                    end
                    return SafeValue(Var, Cache, newinfo);
                elseif IsInternal and not DontCache then
                    SetInternalValue(Var, IsInternal[1][Key]);
                end

                local Spied = Spy(Var, nil, newinfo);
                if not DontCache then
                    Cached[Key] = Spied
                end
                return Spied
            end

            Metatable.__call = __call

            function Metatable.__tostring(Self)
                return Variables[Self];
            end

            function Metatable.__len()
                return 0
            end

            function Metatable.__iter(Self, Key)
                local Called;
                local i, v = GetCount("for_key", true), GetCount("for_val", true)

                local Ends = WaitingIfs
                local Current = ForLoopId + 1

                return function(...) --> nil, nil;
                    if Called then
                        ActiveLoops -= 1
                        CloseIfs()
                        Ast.addStatement(AST, Ast.End(Current))
                        WaitingIfs = Ends

                        return nil
                    end

                    local Path = Variables[Self]
                    local IsInternal = Internal[Path]
                    local Cached = (
                        IsInternal or {}
                    )[1] :: { [string]: any };

                    local Iterator =
                        if Key == "next" then
                            Ast.ArgList({ Ast.Variable(Key), ToAST(Self) })
                        elseif typeof(Key) == "string" then
                            Ast.FunctionCall(Ast.Variable(Key), {ToAST(Self)})
                        else
                            ToAST(Self)

                    CloseAllEnds(AST);

                    local i_Types = IteratorTypes[Path]
                    if not i_Types then
                        if typeof(Cached) ~= "table" then
                            i_Types = {}
                        else
                            for i2, v2 in next, Cached do
                                i_Types = { Typeof(i2), Typeof(v2) }
                                SetInternalValue(i, i2)
                                SetInternalValue(v, v2)
                                break
                            end
                        end
                    end

                    Ast.addStatement(
                        AST,
                        Ast.ForPrep(
                            Ast.Variable(i),
                            Ast.Variable(v),
                            Iterator,
                            Current
                        )
                    )

                    Called = true;
                    ForLoopId = Current
                    ActiveLoops += 1
                    WaitingIfs = {}

                    return TypeSpy(i, i_Types[1]), TypeSpy(v, i_Types[2])
                end
            end

            local HookOpHas = {
                __eq = true,
	            __neq = true,
	            __lt = true,
	            __le = true,
	            __gt = true,
	            __ge = true
            }

            local InstantlyProcess = { ["=="] = true, ["~="] = true }
            local Comp = {
                [">"] = true, ["<"] = true,
                [">="] = true, ["<="] = true
            }

            function GetValue(x, Symbol, y, Var)
                local TypeX, TypeY = Typeof(x), Typeof(y);
                local VarX, VarY = Variables[x], Variables[y];
                local xLune, yLune = not LuauTypes[TypeX], not LuauTypes[TypeY];

                if not InstantlyProcess[Symbol] then
                    if Symbol == ".." then
                        --> We can't process it otherwise it'll keep calling this..?
                        if VarX or VarY then
                            if TypeX ~= "string" and TypeY ~= "string" then --> Drawing .. "meow" will be ignored i guess
                                assert(not Settings.roblox, `attempt to concatenate {TypeX} with {TypeY}`)
                            end
                            return TypeSpy(Var, "string");
                        end
                    else --> Add, Sub, Mul, ...
                        if VarX or VarY then
                            --> uhhhhhhhhhhhhhhh whattttt?
                            if (not xLune and not yLune) or ((VarX and not xLune) or (VarY and not yLune)) then --> both arent lune, x is spied & not lune, y is spied & not lune
                                if not LuaTypes[TypeX] and not LuaTypes[TypeY] then --> not a number, function, string, ...
                                    assert(not Settings.roblox, `attempt to perform arithmetic ({SymbolToName[Symbol]:sub(3)}) on {TypeX} and {TypeY}`)
                                end
                                return Spy(Var);
                            end
                        end
                    end
                end
                
                local Success, Value = pcall(GetValueInner, x, Symbol, y)
                if Settings.roblox then
                    assert(Success, tostring(Value))
                end
	            return Value
            end

            for Method, Symbol in next, Math do
                Metatable[Method] = function(Self, Value)
                    if IgnoreInEq[Variables[Self]] then
                        return GetValue(GetInternalValue(Self), Symbol, GetInternalValue(Value))
                    end

                    local Var = DefineVar(
                        Ast.BinaryOp(ToAST(Self), Symbol, ToAST(Value)),
                        false,
                        true
                    )

                    local Value = GetValue(GetInternalValue(Self), Symbol, GetInternalValue(Value), Var)
                    if Variables[Value] then return Value end
                    Ast.addStatement(AST, Ast.Comment(ToAST(Value)))
                    return SafeValue(Var, Value);
                end
            end

            if not hookOp then
                for Method, Symbol in next, MathV2 do
                    --[[if HookOpHas[Method] then
                        continue;
                    end]]

                    Metatable[Method] = function(Self, Value)
                        if Variables[Self] == EnvName then
                            return GetValue(GetInternalValue(Self), Symbol, GetInternalValue(Value))
                        end

                        local Var = DefineVar(
                            Ast.BinaryOp(ToAST(Self), Symbol, ToAST(Value)),
                            false,
                            true
                        )

                        local Value = GetValue(GetInternalValue(Self), Symbol, GetInternalValue(Value), Var)
                        if Variables[Value] then return Value end
                        return SafeValue(Var, Value);
                    end
                end
            end
        end

        local Meta = setmetatable({}, Metatable)
        if typeof(Value) == "table" then
            local OldMt = getmetatable(Value)
            local ActualMetatable = getmetatable(Meta)

            if OldMt then --> Support for the Random library, since the stuff it returns has metatables:(
                for method, callback in next, OldMt do
                    if typeof(callback) == "function" then
                        if method:sub(1, 2) == "__" then -- metamethod
                            ActualMetatable[method] = callback
                        else
                            rawset(Meta, method, function(_, ...)
                                local Statement;
                                if Variables[_] == Path then -- namecall duh
                                    Statement = Ast.Assign(
                                        { Ast.Variable(GetVar()) },
                                        { Ast.Namecall(Ast.Variable(Path), Ast.Variable(method), TupleToAST(...)) }
                                    )
                                    Ast.addStatement(
                                        AST, Statement
                                    )
                                else
                                    Statement = select(2, AppendCall(
                                        Ast.Index(
                                            Ast.Variable(Path),
                                            ToAST(method)
                                        ),
                                        _,
                                        ...
                                    ))
                                end

                                return ToMultiVars(Statement, pack(callback(GetInternalValue(_), ...)), true)
                            end)
                        end
                    else
                        ActualMetatable[method] = callback;
                    end
                end
            end
        end

        Variables[Meta] = Path;
        ReverseVariables[Path] = Meta
        if Value ~= nil then
            Types[Meta] = typeof(Value);
            SetInternalValue(Path, Value);
        end

        Information[Meta] = Info

        return Meta;
    end

    TypeSpy = function(Path : string, Type : string, ... : any)
        local Meower = Spy(Path, ...)
        if Type then Types[Meower] = Type end
        return Meower
    end

    function ToMultiVars(Statement : AstExpression, Values : dict, Safe : boolean?, Info : dict?) : ...Spied
        local Length = Values.n or #Values;

        local Spied, Vars = {}, {}
        local Func = if Safe then SafeValue else Spy

        for i = 1, Length do
            local Var = GetVar()
            local Meower = Func(Var, Values[i], Info)

            Types[Meower] = typeof(Values[i]);

            insert(Spied, Meower)
            insert(Vars, Ast.Variable(Var))
        end

        Statement.data.vars = Vars
        return unpack(Spied);
    end

    function SafeValue(Var : string, Value : any, Info : any) : any
        local Type = Typeof(Value)

        --if Type == "Instance" then return Value end -- instances are already sandboxed

        if Type == "function" then
            return Function(Value, Var, iscclosure(Value))
        elseif Type == "table" or hookOp then
            if Variables[Value] then Value = GetInternalValue(Value) end
            
            SetInternalValue(Var, Value);
            return TypeSpy(Var, Type, nil, Info);
        else
            return Value;
        end
    end

    local function GetMetatable(Path : string, Extra : { any }?, Value : any?)
        local Cloned = table.clone(getmetatable(Spy(Path, Value)))
        if Extra then
            for i, v in next, Extra do Cloned[i] = v end
        end
        local Mt = setmetatable({}, Cloned)
        Variables[Mt] = Path
        return Mt
    end

    local function GetContext(Object : any) : string?
        local Var = Variables[Object]
        if Var and not AlwaysIgnore[Var] and not Wrapped[Object] and not LuaGlobals[Var] then
            return Var;
        end
        return nil;
    end

    SpyParams = function(Params : {string}, Infos : { any }?) : { any }
        local ParamList = {}
        local InfoList = {}
        if Infos then
            for _, v in next, Infos do
                insert(InfoList, v.Type)
            end
        end

        for i, Param in next, Params do
            local Spied = Spy(Param, nil, {
                is_property = true
            })
            local thingInfo = InfoList[i]
            if thingInfo then
                if thingInfo.Category == "Primitive" then
                    local Type = AliasToName[thingInfo.Name] or thingInfo.Name
                    Types[Spied] = Type
                end
            end
            ParamsDict[Spied] = true
            insert(ParamList, Spied)
        end

        return ParamList
    end

    if hookOp then
        -- add the funcs:(

        local StuffThatRanEq = {} -- Storing their variable name is more efficient right?

        local function Eq(Symbol)
            local IsEq = Symbol == "=="
            local eq = IsEq and function(a, b) return a == b end or function(a, b) return a ~= b end;
            local function WhatIsIt(N)
                local shouldFlip = N[2] == (IsEq)
                if shouldFlip then
                    return not N[1]
                else
                    return N[1]
                end
            end

            --> if N[2] then

            --[[
                Values:
                N[2] and ==: not N
                N[2] and ~=: N

                not N[2] and ==: N
                not N[2] and ~=: not n
            ]]

            return function(x, y)
                local A, B = GetContext(x), GetContext(y);
                if (not A and not B)--[[ or (Typeof(x) == "function" or Typeof(y) == "function")]] or (IgnoreInEq[A] or IgnoreInEq[B]) then return eq(x, y) end
                local N, P = StuffThatRanEq[A], StuffThatRanEq[B]

                --if N then return WhatIsIt(N) end
                --if P then return WhatIsIt(P) end

                local X, Y = GetInternalValue(x), GetInternalValue(y);
                local Var = GetVar()
                Define(
                    Var,
                    Ast.Group(Ast.BinaryOp(ToAST(x), Symbol, ToAST(y))),
                    false,
                    true
                )

                local Value;
                local RawValue = eq(X, Y)

                local VarX = Variables[X]

                if VarX and (VarX == Variables[Y]) then
                    RawValue = IsEq; --> gethui() ~= gethui() or something
                end

                local InfoA = Information[x]
                local InfoB = Information[y]

                local iA, iB = InfoA or {}, InfoB or {}

                local PropertyA, PropertyB = iA.is_property, iB.is_property

                if (PropertyA or PropertyB) and not iA.force_normal and not iB.force_normal then
                    local TypeX, TypeY = Typeof(x), Typeof(y);
                    if TypeX == "string" or TypeY == "string" then
                        if x == "" or y == "" then
                            Value = not IsEq;
                        else
                            Value = IsEq
                        end
                    else
                        Value = eq(TypeX, TypeY) --> If they're the same type
                    end
                end

                -- blah blah blah
                if Value == nil then
                    Value = RawValue;
                end

                if iA.key == "PlaceId" and typeof(Y) == "number" then
                    Value = not IsEq or Y > 100_000;
                elseif iB.key == "PlaceId" and typeof(X) == "number" then
                    Value = not IsEq or X > 100_000;
                end

                local tbl = { Value, IsEq }

                if A then StuffThatRanEq[A] = tbl; end
                if B then StuffThatRanEq[B] = tbl; end

                Ast.addStatement(AST, Ast.Comment(ToAST(Value)))

                return Spy(Var, Value, InfoA or InfoB);
            end
        end

        local CompVars, CheckCount, CompIgnore = {}, {}, { table = true, string = true };

        local function Def(x, Symbol, y, _y, isYFunc)
            local Var;
            if isYFunc and typeof(_y) == "function" then
                local Var1 = DefineVar(Explore(_y, { bypass_beautify = false }), false, true)
                Var = DefineVar(
                    Ast.BinaryOp(
                        ToAST(x),
                        Symbol,
                        Ast.FunctionCall(Ast.Variable(Var1), {})
                    ),
                    false,
                    true
                )
            else
                Var = DefineVar(
                    Ast.BinaryOp(
                        ToAST(x),
                        Symbol,
                        ToAST(y)
                    )
                )
            end

            return Var
        end

        local function SearchTable(tbl : { [any]: any }) : boolean
            --> Searches through a table and returns should spy log
            local Junk, Count = 0, 0;
            local IsDict = #tbl == 0;

            for key, val in next, tbl do
                if IsDict and typeof(key) == "string" and not IsGarbageString(key) then
                    Junk -= 3
                end

                Count += 1
                local Type = typeof(val)

                local Var = Variables[val]

                if Var and Type ~= "function" then
                    Junk -= (IgnoreInEq[Var] and -5 or 1)
                elseif Type == "function" then
                    return false
                elseif Type == "number" then
                    Junk += 1
                elseif Type == "table" then --> It cant be a variable, we already checked that before.
                    Junk += 5
                elseif Type == "string" then
                    Junk += (IsGarbageString(val) and 10 or -5)
                else
                    Junk += 1
                end
            end

            return Junk < Count
        end

        local function Compare(Symbol)
            local IsAnd = Symbol == "and"
            local GetValue = IsAnd
                and function(x, y) return x and y end
                or function(x, y) return x or y end; 

            return function(x, y, isYFunc, ...) --> Lhs, Rhs, { isFunction, isFunction }
                local a, b = GetContext(x), GetContext(y)
                local _x, _y = x, y;

                local X = GetInternalValue(x)

                local ShouldReturn = if IsAnd then not X else X;
                local Args = {...}

                local TypeX = Typeof(x)
                local IsFunction = TypeX == "function"

                if SharedGlobals.Pristine then
                    if IsAnd and SharedGlobals.PristineKeys[a] then
                        return nil;
                    end
                end

                if ShouldReturn then
                    if (a or b) and TypeX ~= "number" and TypeX ~= "Instance"--[[ and (IsAnd and X ~= false)]] then --> some weird ib1 shit idk
                        if Variables[X] == EnvName or y == nil then return X end

                        local IsPrometheus = typeof(y) == "number" and y > 10000

                        if not IsPrometheus then
                            if IsAnd then
                                if X == false then return X end
                            else
                                if TypeX == "function" then return X end
                            end

                            if X == false then
                                local Val = VarValues[a]
                                if not Val or Val.kind ~= "unary" then --> Log (if not x)
                                    return X
                                end
                            end
                            Var = Def(x, Symbol, y, _y, isYFunc)
                        else
                            local ToAST_X = ToAST(x)
                            Var = DefineVar(X and ToAST_X or Ast.UnaryOp(ToAST_X, "not")) -- remove the ugly 'x and 123456'
                        end

                        SetInternalValue(Var, X);
                        return Spy(Var, nil, Information[x] or Information[y]);
                    end

                    return X
                end

                if isYFunc then
                    isYFunc = false
                    y = y(...)
                end

                if (not a and not b) or (IsFunction or CompIgnore[a]) then --> Ignore
                    --> Simplified: if not a and not b ORRRRR if X isn't a function (and not `string`)
                    return GetValue(X, y)
                end

                local Var;

                local Info = Information[x] or Information[y]

                local IsPrometheus = typeof(y) == "number" and y > 10000

                if CompVars[X] then
                    CompVars[y] = `not {CompVars[X]}`
                elseif not IsPrometheus then
                    if IsFunction and iscclosure(x) then --> C function, like print or string.something
                        return GetValue(x, y);
                    end
                    
                    Var = Def(x, Symbol, y, _y, isYFunc);
                end

                x, y = X, GetInternalValue(y)

                local s, Value = pcall(GetValue, x, y)

                if not s then Value = nil end

                if IsPrometheus then
                    local Condition = _x
                    CompVars[y] = Condition
                    CheckCount[y] = 0
                    return Value;
                end

                if Typeof(Value) == "function" or Value == Env then return Value end

                SetInternalValue(Var, Value)
                return Spy(Var, nil, Info)
            end
        end

        local ActiveIfs, CheckedIfs = {}, {}
        local ForLoops = {}
        local Whiles = {}
        local CalledFuncs = {}
        local Checked, CheckedKeys = {}, {}
        local WhileCount = 0

        local Last;
        local AllowedTypes = {
            ["boolean"] = true,
            ["nil"] = true
        }

        local LastCondition, LastConditionV2 = nil, nil; --> use for infinite while detection?

        function SecureEnv.GET(text : any, ...)
            local Type = typeof(text)
            if Type ~= "string" then
                if false and IsExploring and AllowedTypes[Type] and not Variables[text] then
                    DefineVar(
                        ToAST(text),
                        false,
                        true
                    )
                elseif IsExploring and ParamsDict[text] then
                    return Spy(DefineVar(
                        ToAST(text),
                        false,
                        true
                    ), text), ...
                end
                return text, ...
            end

            local Len = #text

            if
                not Strings[text] and
                Len % 4 ~= 0 and
                Len > 1 and
                not IsBetween(Len, 13, 15) and
                not text:find("[\1-\30\133-\255]")
            then
                local PreviousString = text:sub(1, -2) --> This file -> This fil

                --[[if Previous then --> actually used constant!
                    Previous.data.values, Previous.data.vars = {}, {};

                    Strings[PreviousString] = nil;
                    ConstantList[PreviousString] = nil;

                    local Var = GetVar()

                    Strings[text] = Var
                    ConstantList[text] = Define(
                        Ast.Variable(Var),
                        Ast.String(text),
                        false,
                        true
                    )
                else
                    Strings[text] = DefineVar(Ast.String(text))
                end]]

                --Strings[PreviousString] = nil
                local Var, Stat = DefineVar(Ast.String(text))

                ConstantList[text] = Stat
                Strings[text] = Var;
            end

            return text, ...
        end

        function SecureEnv.CONCAT(text : string, text2 : string)
            local Result = text .. text2

            if Result:find("\239", 0, true) then return Result end
            
            local Subbed = Result:sub(1, -2)

            if Strings[Subbed] then
                Strings[Subbed] = nil

                local Old = ConstantList[Subbed]
                if Old then Old.data.vars, Old.data.values = {}, {} end

                local Var, Stat = DefineVar(Ast.String(Result))

                Strings[Result] = Var
                ConstantList[Result] = Stat
            end

            return Result
        end

        function SecureEnv.CALL(func : func, ...) : any
            if not func or typeof(func) == "number" then
                local Var = GetVar()
                local Call = Ast.FunctionCall(Ast.Group(Ast.Variable("nil")), TupleToAST(...))
                local Assign = Ast.Assign( { Ast.Variable(Var) }, { Call } )
                Ast.addStatement(AST, Assign)
                local p = setmetatable({}, { __tostring = function() return Var end })
                Variables[p] = Var
                return p
            end

            local Hook = FunctionHooks[func]
            if Hook then
                Ast.Comment(Ast.RawText("A hooked function was used here."))
                return Hook(...)
            end;

            if typeof(func) ~= "function" then
                local var = Variables[func]
                if var and LuaTypes[Typeof(func)] then --> Not a custom type (Like game, Enum, ...)
                    return __call(func, ...);
                end
            end

            if CallsHandler then
                return CallsHandler(func, ...)
            end

            return func(...)
        end

        function SecureEnv.NAMECALL(func : { [string]: func }, method : string, ...)
            if typeof(func) == "string" then
                return SecureEnv.string[method](GetInternalValue(func), ...)
            end
            return func[method](func, ...)
        end

        function SecureEnv.CHECKIF(Condition : any, id : number, elseId : number) : any
            local Var = GetContext(Condition)
            local _Condition = Condition
            Condition = GetInternalValue(Condition)

            if Var then
                IfId += 1
                
                local Value = VarValues[Var]
                if Value then
                    local Expr = AstLib.ExprToCode(Value)
                    local If = CheckedIfs[Expr] or { uses = 0, condition = Condition }
                    If.uses += 1
                    CheckedIfs[Expr] = If

                    if If.uses >= 20 then
                        StopWhileLoops += 1
                        return not If.condition
                    end
                end

                local WillRun, HasElse = Condition, elseId == 1
                local IsFunc = Typeof(Condition) == "function"

                local Hook = StatementHooks[IfId]
                if Hook ~= nil then
                    WillRun = Hook;
                end

                if IsFunc and (Wrapped[Condition]) then return WillRun end

                if not WillRun then
                    if not HasElse then
                        Ast.addStatement(AST, Ast.IfStat(ToAST(_Condition), Ast.Block({
                            Ast.PermaComment(Ast.RawText(`didnt run, if id: {IfId}`))
                        })))
                        return WillRun
                    end
                end

                OpCountCheck();

                insert(WaitingIfs, { _Condition, #AST.data.statements, not WillRun and HasElse, HasElse, IfId }) --> In a for loop, The last statement is the forprep.
                return WillRun;
            end

            return Condition
        end

        function SecureEnv.CHECKIFEND(id : number)
            local LengthNow = #AST.data.statements
            local Len = #WaitingIfs

            if Len == 0 then return end

            local Oldest = WaitingIfs[Len]
            if Oldest[2] == LengthNow--[[ or Last == Oldest]] then return end

            local LastStat = AST.data.statements[LengthNow]
            if LastStat.kind == "assign" and LastStat.data.values[1].kind == "index" then
                if not Oldest[4] then return end
            end

            local StartedAt = Oldest[2]
            
            local Comment = Ast.PermaComment(Ast.RawText(`{Oldest[3] and "didnt run (else)" or "ran"}, if id: {Oldest[#Oldest]}`))
            local Body = Ast.Block{Comment}

            for i = StartedAt + 1, LengthNow do
                Ast.addStatement(Body, AST.data.statements[i])
                AST.data.statements[i] = nil
            end

            local IsElse = Oldest[3]
            local HasElse = Oldest[4]

            if HasElse and not IsElse then
                -- if has else: defer emission, save then-body and keep in WaitingIfs
                Oldest[6] = Body
                return
            elseif IsElse then
                -- combine then-body and else-body into one if-stat
                local ThenBody = Oldest[6] or Ast.Block{}
                Ast.addStatement(AST, Ast.IfStat(ToAST(Oldest[1]), ThenBody, Body))
            elseif not HasElse then
                Ast.addStatement(AST, Ast.IfStat(ToAST(Oldest[1]), Body))
            end
            table.remove(WaitingIfs, Len)
            Last = Oldest
        end

        function SecureEnv.CHECKWHILE(x, id)
            TotalWhiles += 1

            local Var = Variables[x]

            if Var then
                if Indexes[Var] then
                    --AlwaysIgnore[Var] = true
                    --SetInternalValue(Var, nil)
                    return nil;
                end
            end

            if TotalWhiles >= WHILE_LIMIT then
                print("too many iterations!")
                Ast.addStatement(AST, Ast.WhileLoop(ToAST(x), Ast.Block{}))
                error("too many iterations")
            end

            local X = GetInternalValue(x)
            local Stats = AST.data.statements
            local Len = #Stats

            --[[
                CHECKWHILE(true, 1) -> print("sh3b el noni") -> do nothing
                CHECKWHILE(true, 1) -> print("bel sha7at") -> do nothing
                CHECKWHILE(true, 1) -> print("sh3b el noni") -> REMOVE THIS!!!!!!!!!! AND STOP LOGGING
            ]]

            if Len ~= LastLen and Settings.inf_loops and false then
                local Exprs = WhileExprs[id] or {}

                local Stat = Stats[Len]

                --if Stat.kind == "assign" then Stat = Stat.data.values[1] end
                if Stat.kind == "assign" and Stat.data.values[1].kind == "index" then
                    WhileExprs[id] = {}
                elseif Stat.kind == "variable" then
                else
                    --> Len - LastLen = 2

                    local meower = AstLib.ExprToCode(Stat, 0, true)
                    for n, expr in next, Exprs do
                        if expr[1] == meower then
                            if expr[3] <= 10 then
                                if expr[3] == 0 then
                                    expr[4] = Len - expr[2] -- body length
                                end

                                expr[3] += 1
                                break
                            else
                                local Start = expr[2]
                                local OrigStat = Stats[Start]
                                if not OrigStat then return X end

                                local First = AstLib.ExprToCode(OrigStat, 0, true);
                                local Logged = Ast.Block{}
                                local Added = {}

                                for i = Start - (expr[4] - 1), Len do
                                    local Stat = Stats[i]
                                    if not Stat then continue end

                                    local Coded = AstLib.ExprToCode(Stat, 0, true)
                                    if i ~= Start and Coded == First then
                                        for x = i, Len do
                                            Stats[x] = nil
                                        end
                                        break
                                    end
                                    if Added[Coded] then
                                    else
                                        Added[Coded] = true
                                        Ast.addStatement(Logged, Stats[i])
                                    end
                                    Stats[i] = nil
                                end

                                if x then
                                    Ast.addStatement(AST, Ast.WhileLoop(ToAST(x), Logged))
                                else
                                    Ast.addStatement(AST, Logged)
                                end
                                StopWhileLoops += 1
                            end
                        end
                    end

                    insert(Exprs, { meower, Len, 0 })
                    WhileExprs[id] = Exprs

                    LastLen = Len
                end
            end

            if StopWhileLoops > 0 then
                StopWhileLoops -= 1
                return false
            end

            return X
        end

        function SecureEnv.CHECKWHILEEND()end
        function SecureEnv.REPEAT()
            TotalRepeats += .5
            if TotalRepeats >= WHILE_LIMIT then
                print("REPEAT")

                print("too many iterations!")
                error('too many iterations')
            end
        end

        function SecureEnv.CHECKINDEX(tbl : tbl, key : any)
            if typeof(tbl) == "string" or tbl == string then return SecureEnv.string[key] end
            if Checked[tbl] or CheckedKeys[key] then return tbl[key] end

            local Pre = Predefined[key]
            if Pre then
                local Var = DefineVar(
                    Ast.Index(
                        ToAST(tbl),
                        ToAST(key)
                    )
                )
                return SafeValue(Var, Pre[1])
            end

            --> do the predefined stuff here!!!!!!

            local KeyVar, TblVar = GetContext(key), Variables[tbl]
            local _Key = key
            key = GetInternalValue(key)

            if not TblVar and tbl then
                local ShouldSpy = KeyVar--false and (KeyVar or SearchTable(tbl));

                Checked[tbl] = true

                if ShouldSpy then
                    local ResultVar = DefineVar(
                        ToAST(tbl),
                        false,
                        true
                    )

                    Variables[tbl] = ResultVar

                    local mt = fenv.getmetatable(tbl)
                    if typeof(mt) == "table" then
                        local old = table.clone(tbl)
                        table.clear(tbl)
                        setmetatable(tbl, getmetatable(GetMetatable(ResultVar, mt, old)))
                        return tbl[key]
                    else
                        local doimeowtoomuch = DefineVar(
                            Ast.Index(
                                Ast.Variable(ResultVar),
                                Ast.Variable(KeyVar)--ToAST(_Key)
                            ),
                            false,
                            true
                        )

                        local info = Information[_Key]
                        if info and info.is_property or Settings.discord then --> Something like game.PlaceId, textbox.Text, ...
                            return Spy(doimeowtoomuch, tbl[key], info)
                        end
                    end

                    CheckedKeys[_Key] = true
                end
            end

            return tbl[key];
        end

        function SecureEnv.CONSTRUCT(tbl)
            --[[local ShouldSpy = SearchTable(tbl);
            if ShouldSpy then
                local ResultVar = DefineVar(
                    ToAST(tbl),
                    false,
                    true
                )
            end]]
            --[[if #tbl ~= 1 or true then
                for i, v in next, tbl do
                    if GetContext(v) and not ParamsDict[v] then
                        local ResultVar = DefineVar(
                            ToAST(tbl),
                            false,
                            true
                        )

                        Variables[tbl] = ResultVar
                        break
                    end
                end
            end]]
            return tbl
        end

        function SecureEnv.RETURN(...)
            if IsExploring or IsInPcall or true then return ... end

            for _, v in next, {...} do
                local Context = GetContext(v)
                if Context and typeof(v) ~= "function" then
                    local caller = debuginfo(2, "f")
                    if not iscclosure(caller) and not Variables[caller] then
                        --> Define it as a local function, then return the values as a call result.
                        local FuncName, Stat = DefineVar(
                            ToAST(caller, { as_func = true })
                        )

                        Variables[caller] = FuncName
                        local _, Called = AppendCall(FuncName)
                        return ToMultiVars(Called, pack(...))
                        --[[local _, Stat = DefineVar(
                            Ast.Function(GetParams(caller), ToAST(caller, { as_func = true }))
                        )]]
                        --return ToMultiVars(Stat, pack(...))
                    end
                end
            end
            return ...
        end

        function SecureEnv.ADD(x : any, y : any)
            if y == 1 and x == 0 and IsInPcall then
                return 2;
            end
            return x + y;
        end

        function SecureEnv.FORINFO(id : number, from : any, to: any, step : number)
            ForLoops[id] = { from, to, step }
        end

        for i = 1, 2 do
            SecureEnv["FORSTEP" .. i] = function(id)
                local Loop = ForLoops[id]
                local Value = Loop[i]

                if Variables[Value] then
                    Ast.addStatement(AST, Ast.ForNum("i", ToAST(Loop[1]), ToAST(Loop[2]), ToAST(Loop[3] or 1), Ast.Block{}))
                    local Thing = GetInternalValue(Value)
                    if Variables[Thing] then
                        return 1;
                    else
                        return Thing;
                    end
                end
                return Value
            end
        end

        local EqFunc = Eq("==")

        SecureEnv.CHECKEQ = EqFunc
        SecureEnv.CHECKNEQ = Eq("~=")

        local HowManyChecks = 6; --> How many times a variable needs to be compared in order to log it (PROMETHEUS THING)

        local function NumCompare(Symbol) --> Optimized JUST for numbers
            local IsLessThan, IsGreaterThan, IsGreaterOrEqual, IsLessOrEqual = Symbol == "<", Symbol == ">", Symbol == ">=", Symbol == "<="
            local GetValue =
                IsLessThan and
                    function(x, y) return x < y end
                or IsGreaterThan and
                    function(x, y) return x > y end
                or IsGreaterOrEqual and
                    function(x, y) return x >= y end
                or IsLessOrEqual and
                    function(x, y) return x <= y end

            return function(IsMarCute, YesSheIs)
                local VarA, VarB = GetContext(IsMarCute), GetContext(YesSheIs)
                local Comp = CompVars[IsMarCute]

                if Comp then
                    local Value = GetValue(IsMarCute, YesSheIs)
                    local Variable = Variables[Comp]
                    if not Variable then return Value end

                    local Count = CheckCount[IsMarCute]
                    CheckCount[IsMarCute] = Count + 1

                    --if Count >= HowManyChecks or (Count + 1 == HowManyChecks and not Value) then
                    if Count == HowManyChecks then
                        local MarIsCute = Ast.Variable(Variable)
                        local Var = DefineVar(
                            Value and MarIsCute or Ast.UnaryOp(MarIsCute, "not")
                        )

                        return Spy(Var, Value)
                    else
                        return Value
                    end
                end

                local ShesEvenCuter = GetInternalValue(IsMarCute)
                local OrIsShe = GetInternalValue(YesSheIs)

                if not VarA and not VarB then return GetValue(ShesEvenCuter, OrIsShe) end

                local TypeMar = Typeof(IsMarCute)
                local TypeShi = Typeof(YesSheIs)
                local IsMarNumber = TypeMar == "number"

                if IsLessOrEqual then
                    if IsMarCute and (Information[YesSheIs] or {}).is_random and IsMarCute == 1 then
                        --> stop spying..? (yuh)
                        AlwaysIgnore[VarB] = true --> stop spying ts garbage
                        return GetValue(ShesEvenCuter, OrIsShe);
                    end
                end

                local Var = DefineVar(
                    Ast.BinaryOp(ToAST(IsMarCute), Symbol, ToAST(YesSheIs)),
                    false,
                    true
                )

                if TypeMar == "Instance" or TypeShi == "Instance" then
                    return Spy(Var, false);
                end

                local Success, Val = pcall(GetValue, ShesEvenCuter, OrIsShe)
                if not Success then
                    assert(not Settings.roblox, Val)
                    --Val = IsGreaterThan

                    --[[
                        x <= 100 -> false
                        x >= 100 -> true
                        100 <= x -> true
                        100 >= x -> false
                    ]]

                    --print(IsMarCute, Symbol, YesSheIs, OrIsShe)

                    if VarB and IsMarNumber then --> 100 <= x
                        Val = IsLessThan or IsLessOrEqual
                    elseif VarA and TypeShi == "number" then --> x >= 100
                        Val = IsGreaterThan or IsGreaterOrEqual
                    end
                end

                Ast.addStatement(AST, Ast.Comment(ToAST(Val)))
                return Spy(Var, Val);
            end
        end

        SecureEnv.COMPG = NumCompare(">")
        SecureEnv.COMPGE = NumCompare(">=")
        SecureEnv.COMPL = NumCompare("<")
        SecureEnv.COMPLE = NumCompare("<=")

        SecureEnv.CHECKAND = Compare("and")
        SecureEnv.CHECKOR = Compare("or")

        local New = {}

        for i, v in next, SecureEnv do
            Nil[i] = true
            New[CallId .. i] = v
        end

        SecureEnv = New;
        SecureEnv.rawequal = function(a, b)
            if Variables[a] or Variables[b] then return EqFunc(a, b) end
            return rawequal(a, b);
        end
    else
        SecureEnv.rawequal = function(a, b)
            if Variables[a] or Variables[b] then return a == b end
            return rawequal(a, b);
        end
    end

    local function Unary(Symbol)
        local function Get(x)
            if Symbol == "not" then return not x
            elseif Symbol == "-" then return -x
            elseif Symbol == "#" then
                if typeof(x) == "buffer" then return buffer.len(x) end
                return #x
            end
        end

        return function(x)
            local Var = GetContext(x)
            local X = GetInternalValue(x)

            if Var then
                local IsNot = Symbol == "not"
                local Type = Typeof(X)

                if TrueEnv[Var] and Type == "function" then return Get(x) end -- lua global
                if not IsNot and Type == "Instance" then
                    error(`attempt to perform arithmetic (__{Symbol == "#" and "len" or "unm"}) on an Instance value`)
                end

                local Value;

                if not Variables[X] or IsNot then --> #x, -x or not x
                    local Success, Result = pcall(Get, X);
                    if Success then
                        Value = Result;
                    end
                end

                local Var = DefineVar(Ast.UnaryOp(ToAST(x), Symbol))
                local Type = 
                    if Symbol == "#" then "number"
                    elseif Symbol == "not" then "boolean"
                    else "number"
                --> This type thing may be inaccurate, as uhhhh stuff CAN be metatables by the original script, maybe fix this later:)
                if not hookOp then
                    return SafeValue(Var, Value);
                end
                return TypeSpy(Var, Type, Value)
            end
            return Get(X);
        end
    end

    SecureEnv[CallId .. "CHECKNOT"] = Unary("not")
    SecureEnv[CallId .. "CHECKUNM"] = Unary("-")
    SecureEnv[CallId .. "CHECKLEN"] = Unary("#")

    SecureEnv[CallId .. "TEMPLATE_STRING"] = function(...)
        local Var = DefineVar(
            Ast.InterpolatedString(unpack(TupleToAST(...)))
        )
            
        local strTable = {}

        for _, v in next, {...} do
            if Variables[v] then
                return Spy(Var) --> No internal values.
            else
                insert(strTable, tostring(v))
            end
        end

        SetInternalValue(Var, concat(strTable, ""))

        return Spy(Var)
    end

    local SayPlease: { string } = {}
        --> Globals that get wrapped
    local FineUgh : { string } = { "select", "newproxy" }
        --> Globals that get replaced with their real values

    --! ENVIRONMENT

    local function TypeFunction(Name)
        return Function(function(Value : any) : string
            local Type = Typeof(Value)
            if Name == "type" and not LuaTypes[Type] then Type = "userdata" end

            local Variable = GetContext(Value)
            if Variable and not IgnoreInEq[Variable] and Type ~= "function" then
                return SafeValue((AppendCall(Name, Value)), Type);
            end
            return Type;
        end, Name, true)
    end

    local AllowedPaths = {}

    local function DefineTable(Table) : Variable
        local TableStr = DefineVar(Table)
        local OldMetatable = getmetatable(Table);
        local NewMetatable = getmetatable(GetMetatable(TableStr))

        local FixedMetatable = {};

        if OldMetatable then
            for method, callback in next, NewMetatable do
                local oldMethod = OldMetatable[method]
                if oldMethod then
                    if typeof(callback) == "function" then
                        FixedMetatable[method] = function(...)
                            callback(...)
                            return oldMethod(...)
                        end
                    else
                        FixedMetatable[method] = oldMethod
                    end
                else
                    FixedMetatable[method] = callback
                end
            end
        else
            FixedMetatable = NewMetatable
        end
                            
        setmetatable(Table, FixedMetatable)

        Variables[Table] = TableStr
        return TableStr
    end

    local Calls = {}

    local function SafeWrap(Func, Path)
        local Library = split(Path, ".")[1]

        local DoRecurse = Path == "table.concat"
        local DontLogAnyways = Path == "table.pack"
        local LogPath = Path == "table.insert"

	    local OutFunc = Function(function(...)
            --print("ye",Path)

            local args = {...}
            local info;
            local DoSpy, DontRun;

            local function Iterate(tbl, recursive)
                local Var = GetContext(tbl)
                local Int = GetInternalValue(tbl)
                if Var then
                    DoSpy = true
                    if Variables[Int] then
                        DontRun = true
                    end
                    return Int;
                end --^ safe

                for i, v in next, tbl do
                    if DontRun then return tbl end

                    local Var = Variables[v]

                    if ParamsDict[v] then
                        DontRun = DontRun or (Library ~= "table" and Nest > 0)
                        if DontRun then break end
                        continue
                    end

                    if not DoSpy and Var then
                        DoSpy = true
                    end

                    info = info or Information[v]

                    local Val = GetInternalValue(v)
                    if Variables[Val] then
                        DontRun = true
                        break
                    end

                    if recursive and typeof(v) == "table" then
                        for i2, v2 in next, v do
                            v[i2] = if typeof(v2) == "table" then Iterate(v2, recursive) else v2;
                        end
                    else
                        tbl[i] = Val
                    end
                end
                return tbl;
            end

            args = Iterate(args, DoRecurse);

            if (DoSpy or DontRun) and not DontLogAnyways then
                if LogPath then
                    for _, arg in next, { ... } do
                        if typeof(arg) == "table" and not Variables[arg] then
                            DefineTable(arg)
                        end
                    end

                    --! THIS IS UNSAFE!!

                    Func(unpack(args));

                    local Var = AppendCall(Path, ...)
                    return Spy(Var)
                end

                if DontRun and not Settings.roblox then
                    local Var = AppendCall(Path, ...)

                    return Spy(Var);
                else
                    local Var, Statement = AppendCall(Path, ...)

                    --> A spy argument was involved (DoSpy). If the real builtin rejects an
                    --> env-derived nil/wrong-type (e.g. buffer.readu8(spy->nil)), that's our
                    --> environment, not the script - recover with a spy and keep logging
                    --> instead of truncating the whole dump. Genuine concrete-arg errors go
                    --> through the outer branch below (no spy) and still propagate.
                    local Results = pack(pcall(Func, unpack(args)))
                    if not Results[1] then
                        local Err = tostring(Results[2])
                        if Err:find("too many operations", 1, true) or Err:find("too many iterations", 1, true) then
                            error(Results[2]) --> op/iteration limits must propagate
                        end
                        return Spy(Var)
                    end

                    local Values = pack(unpack(Results, 2, Results.n))

                    if Path == "string.byte" then
                        return unpack(Values)
                    end
                    return ToMultiVars(Statement, Values, true, info)
                end
            else
                return Func(...)
            end

            return Func(unpack(args))
	    end, Path, true)

        Wrapped[OutFunc] = true

        return OutFunc
    end

    local function HookLibrary(Path : string, Extra : { [string]: (any) }?)
        local Library : { [string]: any } = table.clone(TrueEnv[Path]);
        
        local New = {}
        if Extra then
            for i, v in next, Extra do
                New[i] = if typeof(v) == "function" and not Types[v] then Function(v, Path .. "." .. i, true) else v
            end
        end

        for Key, Value in next, Library do
            New[Key] =
                if typeof(Value) == "function" and not New[Key] then
                    SafeWrap(Value, Path .. "." .. Key)
                else
                    New[Key] or Value
        end

        New = GetMetatable(Path, {
            __index = New,
            __newindex = function(_,k,v)
                Ast.addStatement(AST, Ast.Assign( { Ast.Index( Ast.Variable(Path), ToAST(k) ) } , { ToAST(v) }, true))
                error("attempt to modify a readonly table")
            end
        })

        return New
    end

    local function DoIgnore(Key : string?)
        if typeof(Key) ~= "string" then return false end
        if Key:match(NON_ENGLISH) or NumbersDict[Key:sub(1, 1)] then return true end
        local Len = #Key
        if Len < 12 then
            return false
        elseif Len >= 24 then
            return true
        end
        
        -- must have: 1 uppercase, 1 lowercase

        local Uppercase = match(Key, "[A-Z]")
        local Lowercase = match(Key, "[a-z]")

        return Uppercase and (Lowercase or match(Key, "%d"))
    end

    local function IsWeird(Key) : boolean
        if Key == "" or typeof(Key) ~= "string" or tonumber(sub(Key, 1, 1)) then return true end -- If key == "" or the key isnt a string or the first byte is a number

        return match(Key, "[^%w_]") ~= nil or Illegal[Key]
    end

    local function Index(Key, Path, InNewindex) : string
        if Path == "..." then
            Path = "({...})"
        end

        if not IsWeird(Key) then
            return Path and `{Path}.{Key}` or Key
        end

        Path = Path or EnvName

        return `{Path}[{tostring(Key)}]`
    end

    local TickCalls = 0;
    local startTime = os.time()
    local startClock = os.clock()

    local function tick(): number
        TickCalls += 1

	    return startTime + (os.clock() - startClock) + (TickCalls / 1000)
    end

    SetGarbageData({
        DoIgnore = DoIgnore,
        Strings = Strings
    })

    local function HookFunction(Name)
        return Function(function(a : func, b : func)
            local typeA, typeB = Typeof(a), Typeof(b)

            assert(typeA == "function" or not Types[a], "invalid argument #1 to '" .. Name .. "', function expected got " .. typeA)
            assert(typeB == "function" or not Types[b], "invalid argument #2 to '" .. Name .. "', function expected got " .. typeB)

            local Old = AppendCall(Name, a, b)

            if not hookOp then
                Ast.addStatement(AST, Ast.Comment(Ast.RawText("hookOp isn't enabled, therefore hookfunction cannot be used.")))
            end

            FunctionHooks[a] = b
            return Function(
                function(...)
                    return a(...)
                end,
                Old,
                iscclosure(a)
            );
        end, Name, true)
    end

    local function Restore(Func : func)
        FunctionHooks[Func] = nil
    end

    local function IsHooked(f) return FunctionHooks[f] ~= nil end

    if Nest == 0 then
        local PropertyHooks = {
            DataModel = {
                PlaceId = {
                    Type = "Primitive",
                    Name = "number"
                },
                GameId = {
                    Type = "Primitive",
                    Name = "number"
                },
                JobId = {
                    Type = "Primitive",
                    Name = "string"
                }
            },
            Player = {
                Team = {
                    Type = "Class",
                    Name = "Team"
                },
                PlayerGui = {
                    Type = "Class",
                    Name = "PlayerGui"
                }
            },
            TextBox = {},
            ["*"] = {}
        }

        local Generated = {}

        local ForceNormal = {
            Name = true
        }

        local GlobalInstanceData = InstanceLib.Object
        local Attributes = {}
        local Signals = {}

        local ServicesCreated; --> Have the DataModel's services been loaded?
        local Gets = 0;
        local urlCache = {} :: { [string]: string };

        function httpGet(url : string) : string?
            local cached = urlCache[url]
            if cached then return cached end
            if not Settings.isPremium then return end

            local out = process.exec("node", {
	            "./request.js",
	            url
            })

            local result = out.stdout
            local success = not out.stderr:find("Unable to fetch", 0, true)

            if success and result then
                urlCache[url] = result;
                return result;
            end
            return;
        end

        local function HttpGet(Self : VariableData, Url : string, Sync: boolean?)
            local UrlType = Typeof(Url)
            local IsRaw = UrlType == "string"
            assert(IsRaw or not Settings.roblox, `invalid argument #1 to '{Sync and "HttpGetAsync" or "HttpGet"}', string expected got {UrlType}`)

            Gets += 1
            Url = GetInternalValue(Url)
            if Gets <= AllowedGetRequests and typeof(Url) == "string" then -- re-checking UrlType incase it's just a spied table
                insert(AllowedUrlsInTheEnd, Url)

                local result = httpGet(Url)
                if result then SetInternalValue(Self.var, result) end
            end

            return TypeSpy(Self.var, "string", nil, {
                is_http = true,
                url = Url
            })
        end

        local MethodsHooks = {
            DataModel = {
                HttpGet = HttpGet,
                HttpGetAsync = function(self, url, idk, ...)
                    return HttpGet(self, url, true, ...)
                end,
                IsLoaded = function(self) return SafeValue(self.var, true) end
            },
            RunService = {
                IsClient = function(Self : VariableData)
                    return SafeValue(Self.var, true)
                end,
                IsServer = function(Self : VariableData)
                    return SafeValue(Self.var, false)
                end,
                IsStudio = function(Self : VariableData)
                    return SafeValue(Self.var, false)
                end
            },
            RbxAnalyticsService = {
                GetClientId = function(Self) return SafeValue(Self.var, SharedGlobals.HWID) end
            },
            HttpService = {
                JSONEncode = function(Self : VariableData, Data : any)
                    Data = GetInternalValue(Data)

                    local Type = typeof(Data)
                    local Meower = TypeSpy(Self.var, "string")

                    if Type ~= "table" then
                        assert(not Settings.roblox, `invalid argument #1 to 'JSONEncode', table expected got {Type}`)
                        return Meower
                    else
                        for i, v in next, Data do
                            local _v = GetInternalValue(v);
                            local varV = Variables[_v]

                            if varV then return Meower; end
                            Data[i] = _v;
                        end
                    end

                    local Encoded = serde.encode("json", Data, false)
                    return SafeValue(Self.var, Encoded)
                end,
                JSONDecode = function(Self : VariableData, Data : string)
                    Data = GetInternalValue(Data)

                    local Type = typeof(Data)
                    if Type ~= "string" then
                        assert(not Settings.roblox, `invalid argument #1 to 'JSONDecode', string expected got {Type}`)
                        return TypeSpy(Self.var, "table")
                    end

                    return SafeValue(Self.var, serde.decode("json", Data));
                end
            },
            Terrain = {
                GetMaterialColor = function(self, material)
                    local mat = GetInternalValue(material)

                    assert(mat, "Argument 1 missing or nil")
                    local type = typeof(mat)
                    local Aliases = {
                        number = "double"
                    }
                    local Stringed = tostring(mat)

                    assert(Stringed:find(".Material."), `Unable to cast {if LuaTypes[type] then Aliases[type] or type else "null"}`)
                    return SafeValue(self.var, GetTerrainMaterialColor(Stringed:match("%w+%.%w+%.(.+)")))
                end
            },
            ["*"] = {
                GetAttribute = function(self : VariableData, attribute : string)
                    return SafeValue(self.var, (Attributes[self.self] or {})[attribute])
                end,
                GetAttributes = function(self : VariableData)
                    return SafeValue(self.var, Attributes[self.self] or {})
                end,
                SetAttribute = function(self : VariableData, attribute : string, value : any)
                    local AttributesList = Attributes[self.self] or {}
                    AttributesList[attribute] = value
                    Attributes[self.self] = AttributesList
                end
            }
        }

        local EventHooks = {
            RunService = {
                Heartbeat = {
                    ReturnValue = {
                        TIME_TO_WAIT
                    }
                }
            }
        }

        for funcName, func in next, InstanceFuncs do
            MethodsHooks["*"][funcName] = function(Self, ...)
                local Values = pack(func(SpiedToInstance[Self.self], ...))
                if Values.n == 1 then
                    return SafeValue(Self.var, Values[1])
                end
                return unpack(Values);
            end
        end

        MethodsHooks.DataModel.HttpGetAsync = MethodsHooks.DataModel.HttpGet
        local function GetChildren(Parent, Recursive)
            if not ServicesCreated and SpiedToInstance[Parent] == SpiedToInstance[SecureEnv.game] then
                for ServiceName in next, Services do
                    pcall(function()
                        insert(Children[Parent], CreateInstance(Index(ServiceName, "game"), ServiceName, true))
                    end)
                end
                ServicesCreated = true
            end

            local Kids = Children[Parent]
            if not Kids then return {} end
            if not Recursive then return Kids end

            local Total = {}
            for _, Child in next, Kids do
                for _, v in next, GetChildren(Child, Recursive) do
                    insert(Total, v)
                end
                insert(Total, Child)
            end
            return Total
        end

        MethodsHooks["*"].GetChildren = function(Self : VariableData)
            SetIterator(Self.var, "number", "Instance")
            return SafeValue(Self.var, GetChildren(Self.self, false))
        end

        MethodsHooks["*"].GetDescendants = function(Self : VariableData)
            SetIterator(Self.var, "number", "Instance")
            return SafeValue(Self.var, GetChildren(Self.self, true))
        end

        local function SetParent(Instance : Spied, Parent : Spied)
            local SpiedParentV1, SpiedInstanceV1 = SpiedToInstance[Parent], SpiedToInstance[Instance]
            local RealSelf, RealParent = SpiedInstanceV1 or Instance, SpiedParentV1 or Parent;
            for oldParent, children in next, Children do
                local idx = find(children, RealSelf)
                if idx then
                    table.remove(children, idx)
                    break
                end
            end

            RealSelf.Parent = RealParent
            local SpiedParent, SpiedInstance;

            if SpiedParentV1 then --> Avoid using == so __eq doesnt get triggered
                --> this is the spied parent
                SpiedParent = Parent
            else
                for Spied, Real in next, SpiedToInstance do
                    if Real == Parent then
                        SpiedParent = Spied
                        break
                    end
                end
            end

            if SpiedInstanceV1 then --> Avoid using == so __eq doesnt get triggered
                --> this is the spied parent
                SpiedInstance = Instance
            else
                for Spied, Real in next, SpiedToInstance do
                    if Real == Instance then
                        SpiedInstance = Spied
                        break
                    end
                end
            end

            if SpiedParent then
                local list = Children[SpiedParent] or {}
                insert(list, SpiedInstance)
                Children[SpiedParent] = list
            end
        end

        function CreateInstance(Variable : string, Class : string?, EnableCache : boolean?, FromInstanceNew : boolean?)
            local function GenerateProperty(ValueType, Name)
                if Generated[ValueType] then return Generated[ValueType] end

                local Category = ValueType.Category or ValueType.Type

                if Category == "Primitive" then
                    local Type = AliasToName[ValueType.Name] or ValueType.Name

                    if Type == "number" then
                        return math.random(0, 1e6)
                    elseif Type == "string" then
                        return GenId(8)
                    end
                elseif Category == "Class" then
                    --return CreateInstance(Index(Name or ValueType.Name, Variable), ValueType.Name, true)
                    return CreateInstance(Name, ValueType.Name, true)
                elseif Category == "DataType" then
                    --[[if ValueType.Name == "Vector2" then
                        return roblox.Vector2.new(0, 0)
                    end]]
                    if ValueType.Name == "Instances" then
                        local Meow = DefineVar(
                            Ast.Index(
                                Ast.Variable(Name),
                                Ast.Number(1)
                            )
                        )

                        return { CreateInstance(Meow) }
                    end
                end
                return Spy(Name);
            end

            local function CreateEvent(Self : Spied, EventName : string, Params : { { [string] : any } }, EventStr : string)
                local Sigs = Signals[Self] or {}

                if Sigs[EventName] then return Sigs[EventName] end

                local Keys = {
                    connect = true, Connect = true
                }

                local BaseVar = Ast.Variable(EventStr)
                local Hooks = EventHooks[Class] or {}
                local Hook = Hooks[EventName]

                local Signal = GetMetatable(EventStr, {
                    __index = function(event, Key : string)
                        --checktype(Key, "string", "invalid argument #2")
                        assert(event, `missing argument #1 to '{Key}' (RBXScriptSignal expected)`)

                        local key = if typeof(Key) == "string" then Key:lower() else Key;
                        local Var = DefineVar(
                            Ast.Index(BaseVar, ToAST(Key))
                        )

                        if key == "connect" or Key == "ConnectParallel" or Key == "connectParallel" or Key == "connectparallel" then
                            --> Heartbeat.Connect
                            local Spied = Function(function(x, callback : func)
                                checktype(callback, "function", `invalid argument #2 to '{key}'`)

                                local Info = {
                                    param_infos = Params
                                }

                                if false and (EventName == "Heartbeat" or EventName == "RenderStepped") then
                                    --Info.bypass_beautify = true
                                    Info.as_func = true

                                    Explore(callback, Info) -- run it again just incase
                                    --Explore(callback, Info) -- run it again just incase
                                end
                                
                                local Conn = DefineVar(
                                    Ast.Namecall(
                                        BaseVar,
                                        Ast.Variable(Key),
                                        {
                                            ToAST(
                                                callback,
                                                Info
                                            )
                                        }
                                    ),
                                    false,
                                    true
                                )

                                --> return an RBXScriptConnection soon..
                                local int = {};
                                int.Connected = true
                                int.Disconnect = function(self, ...)
                                    assert(self, "missing argument #1 to 'Disconnect' (RBXScriptConnection expected)")
                                    local Type = Typeof(self)

                                    assert(Type == "RBXScriptConnection", "invalid argument #1 to 'Disconnect' (RBXScriptConnection expected, got " .. Type .. ")")
                                    assert(int.Connected, "Connection is not connected!")

                                    --[[DefineVar(
                                        Ast.Namecall(
                                            Ast.Variable(Conn),
                                            Ast.Variable("Disconnect"),
                                            TupleToAST(...)
                                        )
                                    )]]

                                    int.Connected = false
                                end
                                int.disconnect = int.Disconnect
                                local Connection = GetMetatable(Conn, {
                                    __index = function(_, Key)
                                        return SafeValue(DefineVar(Ast.Index(Ast.Variable(Conn), ToAST(Key))), int[Key])
                                    end
                                })
                                Types[Connection] = "RBXScriptConnection"

                                return Connection
                            end, Var, true)
                            --rawset(event, Key, Spied)
                            --! COMMENTED, SINCE ROBLOX IS FREAKING STUPID, EVERY NEW __INDEX CREATES A NEW FUNCTION 🥹🥹🥹
                            return Spied;
                        elseif key == "wait" then
                            return Function(function(_, ...)
                                local ReturnedMeowers = {}
                                local Vars = {}

                                for i, v in next, Params do
                                    local Var = GetCount(v.Name);
                                    local Spied = Spy(Var, if Hook and Hook.ReturnValue then Hook.ReturnValue[i] else nil)

                                    local thingInfo = v.Type;
                                    if thingInfo.Category == "Primitive" then
                                        local Type = AliasToName[thingInfo.Name] or thingInfo.Name
                                        Types[Spied] = Type
                                    end

                                    insert(ReturnedMeowers, Spied)
                                    insert(Vars, Ast.Variable(Var))
                                end

                                Ast.addStatement(
                                    AST,
                                    Ast.Assign(
                                        Vars,
                                        {
                                            Ast.Namecall(
                                                BaseVar,
                                                Ast.Variable(Key),
                                                TupleToAST(...)
                                            )
                                        },
                                        false
                                    )
                                )
                                task.wait()
                                return unpack(ReturnedMeowers)
                            end, Var, true)
                        elseif key == "once" then
                            return Spy(Var);
                        end

                        error(`{Key} is not a valid member of RBXScriptSignal`)
                    end
                })

                Types[Signal] = "RBXScriptSignal"
                Sigs[EventName] = Signal
                Signals[Self] = Sigs;
                return Signal;
            end

            if EnableCache then
                for x, Real in next, SpiedToInstance do
                    if Real.ClassName == Class then
                        return x--Spy(Variable, x)
                    end
                end
            end

            local InstanceData = InstanceLib[Class]
            local IsSpied = not Class

            InstanceData = InstanceData or GlobalInstanceData

            if FromInstanceNew then
                assert(InstanceData, `Unable to create an Instance of type "{Class}"`)
            end

            local Hooks : { [string]: { [any]: any } } = PropertyHooks[Class] or {};
            local Properties : { [string]: any } = InstanceData.properties
            local Callbacks : { [string] : any } = InstanceData.callbacks or {}

            local imsocute:P = IsSpied and {
                Name = Spy(Index("Name", Variable))
            } or (function() local s, v = pcall(Instance.new, Class); return if s then v else {} end)();

            local MethodHooksSelf = MethodsHooks[Class] or MethodsHooks["*"]

            local Methods = InstanceData.methods
            local Events = InstanceData.events

            local ActualInstance = {}
            for PropertyName, Property in next, Properties do
                local s, v = pcall(function() return imsocute[PropertyName] end)
                ActualInstance[PropertyName] = if s then v else GenerateProperty(Property.ValueType, PropertyName);
            end

            local is_property = not FromInstanceNew

            local Instance;
            local Mt = {
                __index = function(Self, Key)
                    assert(Key, "invalid argument #2 (string expected, got nil)")

                    local Oldest = Key
                    local Prefix = Key:sub(1, 1)
                    if IsLowerCase(Prefix:byte()) then --> Fixes issues where stuff are still accessible like .getService, this automatically converts to .GetService, .name -> Name, .placeId -> PlaceId
                        Key = Prefix:upper() .. Key:sub(2)
                    end

                    if Callbacks[Key] then
                        error(`{Key} is a callback member of {Class}; you can only set the callback value, get is not available`)
                    end

                    local ErrMsg = `{Oldest} is not a valid member of {Class or "Instance"} "{IsSpied and Class or imsocute.Name}"`
                    if typeof(Key) == "string" and Key:find("\0") then
                        error(ErrMsg)
                    end

                    local Hook = Hooks[Key] or PropertyHooks["*"][Key];
                    local Info = Information[Self] or {}

                    local Indexed = DefineVar(
                        Ast.Index(Ast.Variable(Variable), ToAST(Oldest)),
                        false,
                        true
                    )

                    local isName = (Key == "name" or Key == "Name")

                    if Hook ~= nil or isName then
                        local Property = if isName then imsocute.Name else GenerateProperty(Hook, Indexed)

                        if Typeof(Property) == "Instance" then
                            return Property;
                        end
                        local Spied = Spy(Indexed, Property, {
                            is_property = is_property,
                            key = Key
                        })
                        rawset(Self, Key, Spied)
                        return Spied
                    elseif Key == "Parent" then
                        for Parent, List in next, Children do
                            if find(List, Self) then
                                return SafeValue(Indexed, Parent);
                            end
                        end
                        local P = ActualInstance.Parent
                        if P then
                            for Spied, Meow in next, SpiedToInstance do if P == Meow then P = Spied break end end;

                            return SafeValue(Indexed, P)
                        end

                        return SafeValue(Indexed, nil);
                    end

                    local Property = ActualInstance[Key]
                    if Property ~= nil then
                        if typeof(Property) == "Instance" then
                            local Meowed = CreateInstance(Indexed, Property.ClassName)
                            local Real = SpiedToInstance[Meowed]
                            if typeof(Real) == "table" then
                                for i in next, Real do
                                    pcall(function() Real[i] = Property[i] end)
                                end
                            end
                            return Meowed;
                        end

                        local Spied = Spy(
                            Indexed,
                            Property,
                            {
                                is_property = is_property,
                                force_normal = ForceNormal[Key]
                            }
                        )
                        rawset(Self, Key, Spied)
                        return Spied
                    end

                    local Kids = Children[Instance] or {}
                    for _, v in next, Kids do
                        if SpiedToInstance[v].Name == Key then
                            return v;
                        end
                    end

                    if Class == "DataModel" and Services[Key] then --> game.Players
                        -- check it's kids..
                        --print("yes", Indexed, Key)
                        for _, v in next, Kids do
                            if SpiedToInstance[v].ClassName == Key then
                                return v;
                            end
                        end
                        return CreateInstance(Indexed, Key, true);
                    end

                    if GlobalInstanceData.properties[Key] then
                        local Spied = Spy(Indexed, GenerateProperty(GlobalInstanceData.properties[Key].ValueType, Indexed))
                        rawset(Self, Key, Spied)
                        return Spied
                    elseif Properties[Key] then
                        local Property = GenerateProperty(Properties[Key].ValueType, Indexed)
                        local Real = SpiedToInstance[Property]
                        if Real then
                            SetParent(Real, Instance)

                            return Property
                        end --> .LocalPlayer or sum ting

                        return SafeValue(
                            Indexed,
                            Property,
                            { is_property = is_property, force_normal = true }
                        )
                    end

                    local Method = MethodHooksSelf[Key] or MethodsHooks["*"][Key]
                    local Method2 = Methods[Key] or GlobalInstanceData.methods[Key]
                    local FuncName = Index(Key, Variable)

                    if Method then
                        return Function(function(...)
                            return Method({ var = AppendCall(Indexed, ...), self = ... }, select(2, ...))
                        end, FuncName, true)
                    elseif Method2 then
                        return Function(function(...)
                            local Var = AppendCall(Indexed, ...)
                            local Thing = Spy(Var)
                            if not hookOp then
                                local Value = GenerateProperty(Method2.ReturnType, Var)
                                SetInternalValue(Var, Value) --> have to give it actual values 💘
                            end
                            return Thing;
                        end, FuncName, true)
                    end

                    local Event = Events[Key]

                    if Event then
                        --> implement later
                        return CreateEvent(Self, Event.Name, Event.Parameters, Indexed)
                    elseif GlobalInstanceData.events[Key] then
                        local Spied = Spy(Indexed)
                        rawset(Self, Key, Spied)
                        return Spied
                    end

                    assert(not Settings.roblox, ErrMsg)

                    local Spied = Spy(Indexed, nil, {
                        indexed_instance = true
                    })
                    rawset(Self, Key, Spied)
                    return Spied
                end,
                __newindex = function(Self, Key, Value)
                    Define(
                        Ast.Index(Ast.Variable(Variable), ToAST(Key)),
                        ToAST(Value),
                        true,
                        true
                    )

                    local Info = Information[Self] or {}
                    if Key == "Parent" then
                        if Info.destroyed or Info.service then
                            local Type = Typeof(Value)
                            assert(Type == "Instance", `invalid argument #3 (Instance expected, got {Type})`)

                            error(`The Parent property of {ActualInstance.Name} is locked, current parent: NULL, new parent {(SpiedToInstance[Value] or Value).Name}`)
                        end
                        if SpiedToInstance[Value] == ActualInstance then
                            error(`Attempt to set {ActualInstance.Name} as its own parent`)
                        end
                    end

                    local Property = Properties[Key]
                    if Property then
                        assert(Property.CanSave, `Unable to assign property {Key}. Property is read only`)
                    else
                        if Callbacks[Key] then
                            local callbacks = SharedGlobals.Callbacks[Self] or {}
                            insert(callbacks, { Key = Key, Callback = Value })

                            SharedGlobals.Callbacks[Self] = callbacks
                        else
                            error(`{Key} is not a valid member of {Class} "{ActualInstance.Name}"`)
                        end
                    end

                    ActualInstance[Key] = GetInternalValue(Value);
                end,
                __tostring = function() return Variable end,
                __len = function() return 0 end,
                __call = if IsSpied then nil else function(Self, ...)
                    DefineVar(Ast.FunctionCall(ToAST(Self), TupleToAST(...)))
                    if Settings.roblox then
                        Ast.addStatement(AST, Ast.PermaComment(Ast.RawText("Errored here because the script called an Instance value.")))
                        error("attempt to call a Instance value")
                    end
                end
            }

            for i, v in next, Math do
                Mt[i] = function(Self, Value)
                    local TypeLhs, Lhs = Typeof(Self)
                    local TypeRhs, Rhs = Typeof(Value)

                    local Symbol = Math[i]

                    local Var = DefineVar(
                        Ast.BinaryOp(ToAST(Self), Symbol, ToAST(Value))
                    )

                    if TypeLhs == "Instance" or TypeRhs == "Instance" or TypeLhs == "table" or TypeRhs == "table" then
                        if i == "__concat" then
                            error(`attempt to concatenate {TypeLhs} with {TypeRhs}`)
                        end

                        error(`attempt to perform arithmetic ({i:sub(3)}) on {TypeLhs} and {TypeRhs}`)
                    end
                    
                    return GetValue(Lhs, Symbol, Rhs, Var)
                end
            end

            Instance = GetMetatable(Variable, Mt)

            SpiedToInstance[Instance] = ActualInstance
            Types[Instance] = "Instance"
            Variables[Instance] = Variable
            
            Information[Instance] = {
                service = Services[Class] ~= nil,
                was_created = FromInstanceNew
            }

            return Instance
        end

        local function GetParent(Instance : Spied)
            for Meow, List in next, Children do
                if find(List, Instance) then
                    return Meow;
                end
            end
        end

        MethodsHooks["*"].FindFirstChild = function(Self : VariableData, childName : string, Recursive : boolean?)
            local Type = Typeof(childName)
            Assert(Type, "string", "invalid argument #1 to 'FindFirstChild', string expected got " .. Type, true)

            local Kids = GetChildren(Self.self, Recursive);
            for _, Kid in next, Kids do
                if SpiedToInstance[Kid].Name == childName then
                    return Kid;
                end
            end

            if Settings.roblox then
                return SafeValue(Self.var, nil);
            else
                return CreateInstance(Self.var)
            end
        end

        MethodsHooks["*"].FindFirstChildWhichIsA = function(Self : VariableData, className : string, Recursive : boolean?)
            local Type = Typeof(className)
            Assert(Type, "string", "invalid argument #1 to 'FindFirstChildWhichIsA', string expected got " .. Type, true)

            local Kids = GetChildren(Self.self, Recursive);
            for _, Kid in next, Kids do
                if InstanceFuncs.IsA(SpiedToInstance[Kid].ClassName, className) then
                    return Kid;
                end
            end

            if Settings.roblox then
                return SafeValue(Self.var, nil);
            else
                return CreateInstance(Self.var)
            end
        end

        MethodsHooks["*"].FindFirstChildOfClass = function(Self : VariableData, className : string, Recursive : boolean?)
            local Type = Typeof(className)
            Assert(Type, "string", "invalid argument #1 to 'FindFirstChildOfClass', string expected got " .. Type, true)

            local Kids = GetChildren(Self.self, Recursive);
            for _, Kid in next, Kids do
                if SpiedToInstance[Kid].ClassName == className then
                    return Kid;
                end
            end

            if Settings.roblox then
                return SafeValue(Self.var, nil);
            else
                return CreateInstance(Self.var)
            end
        end

        MethodsHooks["*"].FindFirstAncestorWhichIsA = function(Self : VariableData, className : string, Recursive : boolean?)
            local Type = Typeof(className)
            Assert(Type, "string", "invalid argument #1 to 'FindFirstAncestorWhichIsA', string expected got " .. Type, true)

            local Inst = Self.self

            local function FindFirstAncestor(Kid)
                if not Kid then return end;
                if SpiedToInstance[Kid].ClassName == className then return Kid end;

                return FindFirstAncestor(GetParent(Kid));
            end

            local Ancestor = FindFirstAncestor(Inst)

            return Spy(Self.var, Ancestor)
        end

        MethodsHooks["*"].WaitForChild = function(Self : VariableData, childName : string, timeOut : number?)
            local Type = Typeof(childName)
            assert(Type == "string", "invalid argument #1 to 'WaitForChild', string expected got " .. Type)

            --[[if Settings.roblox then
                return SafeValue(Self.var, nil);
            else
                return CreateInstance(Self.var)
            end]]
            --> Maybe make this actually work? (Check it's children first, then return.)

            local Instance = CreateInstance(Self.var)
            SpiedToInstance[Instance].Name = childName
            return Instance
        end

        local game = CreateInstance("game", "DataModel")
        local workspace = CreateInstance("workspace", "Workspace")

        SpiedToInstance[game].Name = "UGC"
        
        SecureEnv.game = game
        SecureEnv.Game = game

        SecureEnv.workspace = workspace
        SecureEnv.Workspace = workspace

        SecureEnv.script = CreateInstance("script", "LocalScript")

        Children[game] = { workspace }

        do
            local Cam = Index("CurrentCamera", "workspace")
            local Camera = CreateInstance(Cam, "Camera")

            --local Terr = Index("Terrain", "workspace")
            --local Terrain = CreateInstance(Terr, "Terrain", true)

            SetParent(Camera, workspace)
            --SetParent(Terrain, workspace)
        end

        local function Clone(Self : VariableData, Recursive : boolean?)
            local Instance = SpiedToInstance[Self.self]
            local New = CreateInstance(Self.var, Instance.ClassName, false)
            local NewInstance = SpiedToInstance[New]

            for key, Property in next, Instance do
                NewInstance[key] = Property
            end
            if Recursive then
                local Kids = {}
                for _, Kid in next, Children[Self.self] or {} do
                    insert(Kids, Clone({
                        self = Kid,
                        var = Variables[Kid]
                    }, Recursive))
                end
                Children[New] = Kids
            end
            
            Information[New] = Information[Self.self] or {}
            Attributes[New] = Attributes[Self.self] or {}

            return New
        end

        MethodsHooks["*"].Clone = function(Self : VariableData)
            return Clone(Self, true);
        end

        MethodsHooks["*"].Destroy = function(Self : VariableData)
            local Meow = Self.self
            local Info = Information[Meow] or {}

            if Info.service then
                local ActualInstance = SpiedToInstance[Meow];
                error(`The Parent property of {ActualInstance.Name} is locked`)
            end
            
            Info.destroyed = true
            Information[Meow] = Info

            for i, List in next, Children do
                local Index = find(List, Meow)
                if Index then
                    table.remove(List, Index)
                end
            end
        end

        MethodsHooks.DataModel.GetService = function(Self : VariableData, name : string)
            checktype(name, "string", `invalid argument #1 to 'GetService'`)
            
            if name == "nil" then return SafeValue(Self.var, nil) end
            name = name:sub(1, (name:find("\0") or 0) - 1)

            local Service = Services[name]
            assert(Service, `'{name}' is not a valid Service name`)
            return CreateInstance(Self.var, name, true);
        end

        SecureEnv.UserSettings = function()
            return CreateInstance(AppendCall("UserSettings"), "UserSettings", true)
        end

        SecureEnv.Instance = table.freeze({
            new = Function(function(Class : string, Parent : Instance?)
                local Type = Typeof(Class)

                assert(Type == "string", "invalid argument #1 to 'new', string expected got " .. Type)

                local Var = AppendCall("Instance.new", Class, Parent)
                local Created = CreateInstance(Var, Class, false, true)

                if Parent then
                    local PType = Typeof(Parent)
                    assert(PType == "Instance", "invalid argument #2 to 'new', Instance expected got " .. PType)

                    local List = Children[Parent] or {}
                    insert(List, Created)
                    Children[Parent] = List
                end

                return Created;
            end, "Instance.new", true),
            fromExisting = Function(function(Old)
                local PType = Typeof(Old)
                assert(PType == "Instance", "invalid argument #1 to 'fromExisting', Instance expected got " .. PType)
                return Clone(Old, false);
            end, "Instance.fromExisting", true)
        })

        Variables[SecureEnv.Instance] = "Instance"

        SecureEnv.cloneref = function(original : Instance)
            local Var = AppendCall("cloneref", original)
            local Type = Typeof(original)
            Assert(Type, "Instance", `invalid argument #1 to 'clonref', Instance expected got {Type}`, true)

            return Clone({
                self = original,
                var = Var
            }, true);
        end

        SecureEnv.gethui = function()
            local x = AppendCall("gethui")
            return Spy(x, CreateInstance(x, "CoreGui", true))
        end

        -- Realistic Roblox behavioral compat layer (env/roblox_compat.luau)
        RobloxCompat:setEnv({
            SafeValue = SafeValue,
            Spy = Spy,
            TypeSpy = TypeSpy,
            Function = Function,
            Index = Index,
            AppendCall = AppendCall,
            DefineVar = DefineVar,
            CreateInstance = CreateInstance,
            SetParent = SetParent,
            Children = Children,
            SpiedToInstance = SpiedToInstance,
            Information = Information,
            Attributes = Attributes,
            Services = Services,
            GetMetatable = GetMetatable,
            Typeof = Typeof,
            checktype = checktype,
            SetIterator = SetIterator,
            Variables = Variables,
            Types = Types,
            SharedGlobals = SharedGlobals,
            ToAST = ToAST,
            Ast = Ast,
            GetVar = GetVar,
            GetInternalValue = GetInternalValue,
            roblox = roblox,
            task = task,
            TIME_TO_WAIT = TIME_TO_WAIT,
            Settings = Settings,
            InstanceLib = InstanceLib,
            GlobalInstanceData = GlobalInstanceData,
            PropertyHooks = PropertyHooks,
            MethodsHooks = MethodsHooks,
            EventHooks = EventHooks,
        })
        RobloxCompat:install(game, workspace)
    end

    local function PleaseBeSafe(Pattern : string)
        if typeof(Pattern) == "string" then
            local x, y = isUnsafePattern(Pattern)
            if x then
                error(`[REGEX ERROR]: {y}`)
            end
        end
    end

    SecureEnv.string = HookLibrary("string", {
        find = Function(function(str, pat, ...)
            if str == true or pat == true then
                Ast.addStatement(AST, Ast.FunctionCall(Ast.Variable("LPH_CRASH"), {}));

                error("LPH_CRASH()")
            end

            local VarStr, VarPat = Variables[str], Variables[pat]
            local Out, Statement

            if VarStr or VarPat then
                Out, Statement = AppendCall("string.find", str, pat, ...)
                local vS, vP = GetInternalValue(str), GetInternalValue(pat)

                if (VarStr and Variables[vS] == VarStr) or (VarPat and Variables[vP] == VarPat) then
                    return TypeSpy(Out, "string")
                end
                str, pat = vS, vP;
            end

            PleaseBeSafe(pat)

            if Variables[str] or Variables[pat] then
                return Spy(Out)
            end

            local vals = pack(string.find(str, pat, ...));

            if VarStr or VarPat then
                return ToMultiVars(Statement, vals, true)
            end

            return unpack(vals)
        end, "string.find", true),
        match = function(str, pat, init : number?)
            print("match",str,pat)
            local VStr, VPat, VInit = GetInternalValue(str), GetInternalValue(pat), GetInternalValue(init)

            local VarStr, VarPat, VarInit = Variables[str], Variables[pat], Variables[init]

            if VarStr or VarPat or VarInit then
                local Values = pack(pcall(match, VStr, VPat, VInit))
                local Vars = {}
                local Spied = {};

                for i = 2, max(Values.n, 3) do
                    local Var = GetVar()
                    if Values[1] then
                        SetInternalValue(Var, Values[i])
                    end
                    insert(Vars, Ast.Variable(Var))
                    insert(Spied, Spy(Var))
                end

                Ast.addStatement(
                    AST,
                    Ast.Assign(
                        Vars,
                        {
                            Ast.FunctionCall(Ast.Index(Ast.Variable("string"), Ast.String("match")), TupleToAST(str, pat, init))
                        }
                    )
                )

                return unpack(Spied)
            end

            PleaseBeSafe(VPat)

            return match(VStr, VPat, VInit)
        end,
        gmatch = function(...)
            --print("gmatch",...)
            local args = {...}
            local DoLog, DontRun;
            for i, v in next, args do
                if Variables[v] then
                    DoLog = true
                    local val = GetInternalValue(v)
                    if Variables[val] then DontRun = true; break end
                    args[i] = val
                end
            end

            PleaseBeSafe(args[2])

            if DoLog or DontRun then
                local Var = AppendCall("string.gmatch", ...);
                local Success, Iterator = pcall(string.gmatch, unpack(args)) --> Always returns
                if not Success or DontRun then
                    return Spy(Var)
                end

                return Function(function(...)
                    local Values = pack(Iterator(...))

                    local Vars = {}
                    local Spied = {}
                    for i = 1, max(Values.n, 1) do
                        local Var = GetVar()

                        insert(Vars, Ast.Variable(Var))
                        insert(Spied, Spy(Var, Values[i]));
                    end

                    Ast.addStatement(AST, Ast.Assign(
                        Vars, { Ast.FunctionCall(Ast.Variable(Var), TupleToAST(...)) }
                    ))
                    return unpack(Spied);
                end, Var, true)
            end
            return string.gmatch(unpack(args))
        end,
        pack = string.pack, --> do not wrap this, as it ruins performance.
        unpack = string.unpack,
        len = function(x)
            checktype(x, "string", "invalid argument #1 to 'len'", true)

            return SecureEnv[CallId .. "CHECKLEN"](x)
        end,
        rep = function(x, y)
            if typeof(y) == "number" and y >= 1e6 then
                AppendCall("string.rep", x, y)
                return x
            end
            return rep(x, y);
        end,
        --byte = string.byte
    })

    SecureEnv.table = HookLibrary("table", {
        create = table.create, --> optimize
        move = table.move
    })

    local LastRandom, RandomCombinations = nil, {};
    SecureEnv.math = HookLibrary("math", {
        random = function(min, max)
            if not min and not max then return math.random() end

            local _min, _max = GetInternalValue(min), GetInternalValue(max);
            local Result, Combinations = nil, RandomCombinations[min];
            if Variables[_min] or Variables[_max] then
                return TypeSpy((AppendCall("math.random", min, max)), "number")
            end

            if (max == 1e4 and min == 0) or (min == 3 and max == 65) or (max == 255) or (min == 1) then return math.random(min, max) end

            if _min and _max then
                Result = math.random(_min, _max);
            elseif _min then
                Result = math.random(_min)
            else
                error(`invalid argument #1 to 'random' (number expected, got nil)`)
            end

            if Combinations then
                if Combinations[max] then
                    return Result
                else
                    Combinations[max] = true
                end
            elseif min and max then
                RandomCombinations[min] = {
                    [max] = true
                }
            end

            if LastRandom and LastRandom == max + 1 then
                LastRandom = max
                return Result
            else
                if max == 255 or min == 1 then return Result end

                LastRandom = max
            end

            local Var = AppendCall("math.random", min, max);
            return SafeValue(Var, Result, { is_random = true });
        end
    })
    SecureEnv.os = HookLibrary("os", {
        clock = function()
            local Var = AppendCall("os.clock")
            return Spy(Var, os.clock() + SharedGlobals.Delay)
        end,
        time = function(...)
            local Var = AppendCall("os.time", ...)
            return Spy(Var, os.time(...) + SharedGlobals.Delay)
        end,
        date = function(meow)
            local Var = AppendCall("os.date", meow)
            local Date = os.date(meow, os.time() + SharedGlobals.Delay)
            return SafeValue(Var, Date);
        end
    })
    SecureEnv.bit32 = HookLibrary("bit32", {
        --[[bxor = function(... : number) --> Speed up safewrap a bit
            local AllowedToMeow, New = false, {...};
            for i, v in next, New do
                if Variables[v] then
                    local Value = GetInternalValue(v)
                    if Variables[Value] then
                        break
                    else
                        New[i] = Value;
                    end
                end
            end

            return bit32.bxor(unpack(New));f
        end]]
    })
    SecureEnv.bit = SecureEnv.bit32
    SecureEnv.coroutine = HookLibrary("coroutine", {
        yield = Function(function(...)
            if coroutine.running() == MAIN_THREAD then
                print("No i will not yield",Nest)
                return;
            end
            print("Yield")
            Luraph = true

            return coroutine.yield(...)
        end, "coroutine.yield", true),
        create = coroutine.create
    })

    --> Roblox Libraries

    SecureEnv.utf8 = HookLibrary("utf8")
    SecureEnv.buffer = HookLibrary("buffer")
    SecureEnv.vector = HookLibrary("vector")

    do
        local function Or(a, b)
            if a == nil then return b end
            return a
        end
        roblox.Random = RandomLib
        roblox.DateTime = DateTime
        roblox.TweenInfo = {
            new = function(time : number, easingStyle : EnumItem, easingDirection : EnumItem, repeatCount : number, reverses : boolean, delayTime : number)
                time = Or(time, 1)
                easingStyle = Or(easingStyle, SecureEnv.Enum.EasingStyle.Quad)
                easingDirection = Or(easingDirection, SecureEnv.Enum.EasingDirection.Out)
                reverses = Or(reverses, false)
                repeatCount = Or(repeatCount, 0)
                delayTime = Or(delayTime, 0)

                if time then
                    assert(Typeof(time) == "number", "TweenInfo.new first argument expects a number for time.")
                end

                if easingStyle then
                    assert(Typeof(easingStyle) == "EnumItem", "TweenInfo.new second argument expects Enum.EasingStyle input")
                    assert(tostring(easingStyle):find("Enum.EasingStyle"), "TweenInfo.new second argument expects Enum.EasingStyle input")
                end

                if easingDirection then
                    assert(Typeof(easingDirection) == "EnumItem", "TweenInfo.new third argument expects Enum.EasingDirection input")
                    assert(tostring(easingDirection):find("Enum.EasingDirection"), "TweenInfo.new third argument expects Enum.EasingDirection input")
                end

                if repeatCount then
                    assert(Typeof(repeatCount) == "number", "TweenInfo.new fourth arg should be a number for RepeatCount.")
                end

                if reverses then
                    assert(Typeof(reverses) == "boolean", "TweenInfo.new fifth arg should be a boolean for Reverses.")
                end

                if delayTime then
                    assert(Typeof(delayTime) == "number", "TweenInfo.new sixth arg should be a number for DelayTime.")
                end

                return {
                    EasingDirection = easingDirection,
                    Time = time,
                    DelayTime = delayTime,
                    RepeatCount = repeatCount,
                    EasingStyle = easingStyle,
                    Reverses = reverses
                }
            end
        }

        local Libraries = {
            "Vector2", "Vector3", "CFrame", "BrickColor", "UDim", "UDim2", "Font", "Enum", "Color3", "Ray",
            "NumberSequence", "NumberRange", "NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint",
            "RaycastParams", "PhysicalProperties", "Random", "DateTime", --> doesn't exist in roblox[RaycastParams] but it works i guess?
            "Axes", "Content", "Faces", "Region3", "Region3int16", "Rect", "TweenInfo"
        }

        local function ShallowCopy(thing : any)
            if Variables[thing] then return thing end

            local Type = typeof(thing)
            if Type ~= "table" then return thing end

            local new = {}
            for i, v in next, thing do
                new[ShallowCopy(i)] = ShallowCopy(v)
            end
            return new
        end

        for _, LibraryName in next, Libraries do
            local Library = roblox[LibraryName]
            local LibVar = Ast.Variable(LibraryName)

            SecureEnv[LibraryName] = (GetMetatable(LibraryName, {
                __index = if Library then function(Self, Key)
                    local Indexed = Index(Key, LibraryName)
                    local Var = DefineVar(
                        Ast.Index(LibVar, ToAST(Key)),
                        false,
                        true
                    );

                    if LibraryName == "Enum" then
                        assert(pcall(function()return Library[Key]end), `{Key} is not a valid member of "Enum"`)
                    end

                    local Callback = Library[Key]
                    if Callback then
                        if typeof(Callback) == "function" then
                            local Func = Function(function(...)
                                local function Wrap(x)
                                    if Variables[x] or typeof(x) ~= "table" then 
                                        return GetInternalValue(x)
                                    end

                                    for i, v in next, x do
                                        x[i] = Wrap(v)
                                    end
    
                                    return x
                                end

                                local OldArgs = ShallowCopy({...})
                                local Args = Wrap({...})

                                local Values = pack(pcall(Callback, unpack(Args)))
                                local Success = Values[1]
                                local Vars = {}
                                local Spied = {}

                                for i = 2, Values.n do
                                    local Var = GetVar()

                                    insert(Spied, Spy(Var, if Success or i ~= 2 then Values[i] else nil))
                                    insert(Vars, Ast.Variable(Var))
                                end

                                Ast.addStatement(
                                    AST,
                                    Ast.Assign(
                                        Vars,
                                        {
                                            Ast.FunctionCall(Ast.Variable(Var), TupleToAST(unpack(OldArgs)))
                                        }
                                    )
                                )

                                if not Success then
                                    warn(Values[2])
                                    if Settings.roblox then
                                        error(tostring(Values[2]))
                                    end
                                end

                                return unpack(Spied)
                            end, Indexed, true) --> use Indexed not Var to cache better
                            --rawset(Self, Key, Func)
                            return Func
                        end

                        local Spied = Spy(Var, Callback);
                        --rawset(Self, Key, Spied)
                        return Spied
                    end

                    local Spied = Spy(Var);
                    --rawset(Self, Key, Spied)
                    return Spied
                end else function(Self, Key)
                    local Var = DefineVar(
                        Ast.Index(LibVar, ToAST(Key)),
                        false,
                        true
                    );

                    return Spy(Var);
                end,
                __call = function(Self, ...)
                    AppendCall(LibraryName, ...)
                    error(`attempt to call a {Typeof(Self)} value`)
                end
            }))
        end

        Types[SecureEnv.Enum] = "Enums"
    end

    SecureEnv.getmetatable = function(table)
        local Var = GetContext(table);
        if Var then
            local Var = AppendCall("getmetatable", table);
            local Type = Typeof(table)

            if Type == "table" then
                return nil;
            elseif Type == "string" then
                --> add later
            elseif Type == "number" or Type == "nil" or Type == "function" then
                return nil;
            else
                return Spy(Var, "The metatable is locked")
            end
        end

        return getmetatable(table)
    end

    SecureEnv.setmetatable = function(table, mt : any)
        if Variables[table] then
            local a = {table, mt}
            table = GetInternalValue(table)

            local TypeTbl, TypeMt = Typeof(table), Typeof(mt)
            assert(TypeTbl == "table", `invalid argument #1 to 'setmetatable' (table expected, got {TypeTbl})`)
            assert(TypeMt == "table" or TypeMt == "nil", `invalid argument #2 to 'setmetatable' (nil or table expected, got {TypeMt})`)
            
            AppendCall("setmetatable", unpack(a))

            assert(not isfrozen(table), "attempt to modify a readonly table")

            return;
        end
        return setmetatable(table, mt)
    end

    SecureEnv.tonumber = function(num : string, base : number?)
        local VarNum, VarBase = Variables[num], Variables[base]

        if VarNum or VarBase then
            local VNum, VBase = GetInternalValue(num), if base then GetInternalValue(base) else 10;

            if typeof(VNum) == "number" then
                if Variables[VBase] then VBase = 10 end
            end

            local Var = AppendCall("tonumber", num, base);
            return Spy(Var, tonumber(VNum, VBase))
        end

        return tonumber(num, base);
    end

    SecureEnv.tostring = function(value : any)
        local VarVal = Variables[value]
        if VarVal then
            if typeof(value) == "function" and CClosures[value] then
                return tostring(value);
            end

            local Info = Information[value]
            local Value = GetInternalValue(value)
            local Type = Typeof(Value)

            local Var = AppendCall("tostring", value)

            if Type == "function" then
                return Spy(Var, tostring(Value), Info);
            elseif Type == "Enum" then
                return SafeValue(Var, tostring(Value):split(".")[2], Info)
            elseif Type == "Instance" then
                return SafeValue(Var, SpiedToInstance[value].Name, Info)
            end

            if not Variables[Value] then
                return SafeValue(Var, tostring(Value), Info)
            end

            return TypeSpy(Var, "string", nil, Info);
        end
        return tostring(value);
    end

    SecureEnv.error = function(msg : string, lvl : number)
        if lvl ~= 0 then
            Ast.addStatement(AST, Ast.Comment(Ast.RawText("`error` here was used by the script itself.")))
            Ast.addStatement(AST, Ast.FunctionCall(Ast.Variable("error"), TupleToAST(msg, lvl)))
        end

        error(msg, lvl)
    end

    local SpoofedEnvs = {}

    local GetfenvHidden = {
        os = true, script = true, io = true, process = true, lune = true
    }

    local function CreateFenvProxy()
        local proxy = {}
        return setmetatable(proxy, {
            __index = function(_, Key)
                if GetfenvHidden[Key] then
                    if Key == "lune" then return {} end
                    return nil
                end
                return Env[Key]
            end,
            __newindex = function(_, Key, Value)
                Env[Key] = Value
            end,
        })
    end

    SecureEnv.getfenv = function(Level)
        local Type = Typeof(Level)
        local Spoofed = SpoofedEnvs[Level]
        --if Spoofed then return SafeValue(AppendCall("getfenv", Level), Spoofed) end
        if Spoofed then return Spoofed end

        if Type == "string" then
            Level = assert(tonumber(Level), `invalid argument #1 to 'getfenv' (number expected, got {Type})`)
        end
        if Type == "number" then
            -- Is it a float?
            if Level > Nest + 2 or Level < 0 then
                error(`invalid argument #1 to 'getfenv' (invalid level)`)
            end
            return CreateFenvProxy()
        elseif Type == "function" or Type == "nil" then
            return CreateFenvProxy()
        end

        error(`invalid argument #1 to 'getfenv' (number expected, got {Type})`)
    end

    SecureEnv.setfenv = function(a, b)
        local Type = Typeof(a)

        assert(Typeof(b) == "table", "missing argument #2 to 'setfenv' (table expected)")
        assert(Type == "number" or Type == "function", `invalid argument #1 to 'setfenv' (number expected, got {Type})`)

        if Type == "function" and iscclosure(a) then
            error("'setfenv' cannot change environment of given object")
        end

        if Variables[b] == EnvName then return a end

        if getmetatable(b) then
            SpoofedEnvs[a] = b;
        end

        local Var = AppendCall("setfenv", a, b)

        SpoofedEnvs[a] = b;

        local succ, result = pcall(fenv.setfenv, a, b)
        if succ then return result end
        return a
    end

    SecureEnv.collectgarbage = function(t)
        assert(t, "missing argument #1 to 'collectgarbage' (string expected)")
        assert(t == "count", "collectgarbage must be called with 'count'; use gcinfo() instead")

        return collectgarbage("count")
    end

    SecureEnv.tick = function()
        return SafeValue(AppendCall("tick"), tick())
    end

    SecureEnv.require = function(path : any)
        local Type = Typeof(path)
        local Var = AppendCall("require", path)

        local lua = Settings.lua

        if Type ~= "string" and lua then return Spy(Var) end

        if Type == "string" then
            local Start = path:sub(1, 2)
            local IsAt = Start:sub(1, 1) == "@"

            local Unable = `Unable to require module from given path '{path}'`

            if not (Start == "./" or Start == ".." or IsAt) then
                if lua then return Spy(Var) end
                error(`Path must begin with './', '../', or '@': received '{path}'`)
            elseif IsAt then
                local Alias = path:match("@([^/]+)")
                local Thing = path:match("@.-/(%w+)")

                if Alias == "game" then -- add support for @self
                    if path == "@game" then --> thats the whole thing
                        error(Unable)
                    else
                        --> add some dynamic instance shit
                        assert(Services[Thing], `'{Thing}' is not a valid Service name`)
                        error(Unable) --> make it actually work
                    end
                elseif Alias == "self" then
                    error(Unable)
                end
                    
                error(`Path contains unsupported alias '@{Alias}`)
            end
                
            error(Unable)
        elseif Type ~= "number" and (Type ~= "Instance" --[[ check if its not a ModuleScript]]) then
            local Info = Information[path] or {}
            if not Info.indexed_instance then
                Assert(Type, "Instance", `Attempted to call require with invalid argument(s).`, true)
            end
        end

        if Type == "Instance" and (Information[path] or {}).was_created then
            error(`Module code did not return exactly one value`)
        end

        return Spy(Var);
    end

    -- File System (Session Only)
    local files = {}
    local FileFuncs = {}

    local function startswith(a, b) return sub(a, 1, #b) == b end
    local function endswith(hello, lo) return sub(hello, #hello - #lo + 1, #hello) == lo end

    FileFuncs.writefile = function(path, content)
        local Path = split(path, '/')
        local CurrentPath = {}

        for i = 1, #Path do
            local a = Path[i]
            CurrentPath[i] = a
            if not files[a] and i ~= #Path then
                files[concat(CurrentPath, '/')] = {}
                files[concat(CurrentPath, '/') .. '/'] = files[concat(CurrentPath, '/')]
            elseif i == #Path then
                files[concat(CurrentPath, '/')] = tostring(content)
            end
        end
    end
    FileFuncs.makefolder = function(path)
        files[path] = {}
        files[path .. '/'] = files[path]
    end
    FileFuncs.isfolder = function(path) return type(files[path]) == 'table' end
    FileFuncs.isfile = function(path) return type(files[path]) == 'string' end
    FileFuncs.readfile = function(path)
        local content = files[path]
        assert(content, `invalid argument #1 to 'readfile', file does not exist!`)
        return content
    end
    FileFuncs.appendfile = function(path, text2)
        FileFuncs.writefile(path, FileFuncs.readfile(path) .. text2)
    end
    FileFuncs.loadfile = function(path, var)
        if not FileFuncs.isfile(path) then error('File \'' .. tostring(path) .. '\' does not exist.', 2) return '' end

        local content = FileFuncs.readfile(path)

        local s, func = pcall(function()
            return loadstring(content)
        end)

        if not s then
            return nil, tostring(func):match("[^\n]+")
        end

        return Function(function(...)
            AppendCall(var, ...)

            return fenv.setfenv(func, Env)(...)
        end, var), s
    end
    FileFuncs.dofile = FileFuncs.loadfile
    FileFuncs.delfolder = function(path)
        local f = files[path]
        if type(f) == 'table' then files[path] = nil end
    end
    FileFuncs.delfile = function(path)
        local f = files[path]
        if type(f) == 'string' then files[path] = nil end
    end
    FileFuncs.listfiles = function(path)
        if not path or path == '' then
            local Files = {}
            for i, v in pairs(files) do
                if #i:split('/') == 1 then insert(Files, i) end
            end
            return Files
        end
        if type(files[path]) ~= 'table' then return error(path .. ' is not a folder.') end
        local Files = {}
        for i in pairs(files) do
            if startswith(i, path .. '/') and not endswith(i, '/') and i ~= path and #i:split('/') == (#path:split('/') + 1) then insert(Files, i) end
        end
        return Files
    end

    for FuncName, Func in next, FileFuncs do
        SecureEnv[FuncName] = function(...)
            local Returned = pack(pcall(Func, InternalIfy(...)));
            local Success = Returned[1];

            local _, Stat = DefineVar(Ast.FunctionCall(Ast.Variable(FuncName), TupleToAST(...)))

            if not Success then
                Comment(tostring(Returned[2]))
                if Settings.roblox then
                    error(Returned[2])
                end
            end

            return ToMultiVars(Stat, {unpack(Returned, 2)});
        end
    end

    SecureEnv.type = TypeFunction("type")
    SecureEnv.typeof = TypeFunction("typeof")

    local PcallIgnore = {
        getfenv = true, rawget = true, setfenv = true, ["table.concat"] = true
    }

    SecureEnv.pcall = function(func, ...)
        local Var = Variables[func]
        if Var then
            local Logged, Values = Explore(func, {
                params = {...},
                bypass_ignore = true,
                as_pcall = true
            })

            local Len = #Logged.data.statements

            local Meow;
            for _, v in next, Values do
                if Variables[v] then
                    Meow = true
                    break
                end
            end

            if not Values[1] then
                local Error = Values[2]
                local Type = typeof(Error)

                if Type == "error" then
                    Error = tostring(Error)
                end

                if Type == "error" or Type == "string" then
                    Values[2] = Error:match(":%d+: ([^\n]+)")
                end
            end

            if Values[2] == "LPH_CRASH()" then
                error("LPH_CRASH()", 2)
            end

            if not PcallIgnore[Var] or Len > 1 or Meow then
                local Ctx = Ast.Variable(Var)

                local Vars = {}
                local Spied = {}

                for i = 1, Values.n do
                    local Var = GetVar()

                    insert(Vars, Ast.Variable(Var))
                    insert(Spied, SafeValue(Var, Values[i]))
                end

                Stat = Ast.addStatement(
                    AST,
                    Ast.Assign(Vars, {
                        Ast.FunctionCall(
                            Ast.Variable("pcall"),
                            {
                                Ctx,
                                unpack(TupleToAST(...))
                            }
                        )
                    })
                )

                return unpack(Spied)
            end
            return unpack(Values)
        end

        local Type = typeof(func)
        if Type ~= "function" then --! Without this, stuff break i think
            return false, `[string "{TraceId}"]:1: attempt to call a {Type} value"`
        end

        local Logged, ReturnValues = Explore(func, {
            params = {...},
            bypass_ignore = true,
            as_pcall = true
        })

        if not ReturnValues[1] then
            local Type = typeof(ReturnValues[2])
            if Type == "error" or Type == "string" then
                local Error = tostring(ReturnValues[2])
                if Error == "too many operations" or Error == "too many iterations" then
                    print("Yes",Error)
                    error(Error);
                end

                local HasArithmetic = Error:find("attempt to perform arithmetic", 0, true)
                local RandomString = Error:find("attempt to index nil with 'randomString'", 0, true) --> xhider thing..

                if not HasArithmetic and not RandomString then
                    ReturnValues[2] = HideErrors(Error):match("[^\n]+")
                else
                    local Line = (HasArithmetic and Error:find("attempt to perform arithmetic (unm)", 0, true)) and "1" or "%2" --> wearedevs garbage
                    ReturnValues[2] = Error:gsub(UserRegex, `[string "{TraceId}"]:{Line}`)
                end

                ReturnValues[2] = ReturnValues[2]:gsub("luau%.load%(%.%.%.%)", TraceId)
                if startswith(ReturnValues[2], "terrain:") then --> stuff like 'Unsupported terrain material'
                    ReturnValues[2] = ReturnValues[2]:match("terrain:%d*:%s*(.+)")
                end
            end
        end

        local Statements = Logged.data.statements
        local Len = #Statements

        if Len ~= 0 and (Len ~= 1 or Statements[Len].kind ~= "return") and ReturnValues.n <= 10 then
            local Last = Statements[Len]
            if Last and Last.kind == "assign" and Last.data.values[1].kind == "string" then
                --> pcall(function() local str ="hello" end)
                Ast.addStatement(AST, Last)
                return unpack(ReturnValues)
            end

            local Vars = {}
            local Spied = {}
            local InternalStuff = {}
            local ToReturn = {}

            local TypeA = typeof(ReturnValues[1])
            local AreAllNumbers = TypeA == "number" or (TypeA == "boolean" and ReturnValues.n >= 3);

            local Names = { "success" }

            for i = 1, ReturnValues.n do
                local Var = Names[i] and GetCount(Names[i]) or GetVar()
                local Value = ReturnValues[i];

                if i > 1 and typeof(Value) ~= "number" then AreAllNumbers = false end

                insert(Vars, Ast.Variable(Var))
                insert(Spied, SafeValue(Var, Value, Information[Value]))
                insert(ToReturn, ToAST(ReturnValues[i]))
                if Settings.debug then insert(InternalStuff, Value) end
            end

            if AreAllNumbers then
                return unpack(ReturnValues)
            end

            if (ReturnValues[1] and ReturnValues.n > 1 or ReturnValues.n > 2) and Statements[Len].kind ~= "return" then
                Ast.addStatement(Logged, Ast.Return(ToReturn))
            end

            Ast.addStatement(
                AST,
                Ast.Assign(
                    Vars,
                    {
                        Ast.FunctionCall(
                            Ast.Variable("pcall"),
                            {
                                Ast.Function(GetParams(func), Logged)
                            }
                        )
                    }
                )
            )

            if #InternalStuff > 0 then print(InternalStuff) end

            return unpack(Spied)
        end

        return unpack(ReturnValues)
    end

    SecureEnv.ypcall = function(...)
        return SecureEnv.pcall(...);
    end

    SecureEnv.xpcall = function(func : func, onFail : func)
        AppendCall("xpcall", func, onFail)

        local Type = Typeof(onFail)

        if Type == "nil" then
            error(`missing argument #2 to 'xpcall' (function expected)`)
        elseif Type ~= "function" then
            error(`missing argument #2 to 'xpcall' (function expected, got {Type})`)
        end

        return xpcall(func, function(...)
            return onFail(HideErrors(tostring((...))), select(2, ...))
        end)
    end

    SecureEnv.rawget = function(tbl, k)
        local Var = Variables[tbl]
        local Type = Typeof(tbl)
        assert(Type == 'table', `invalid argument #1 to 'rawget' (table expected, got {Type})`)

        if Var then
            if Var == EnvName or Var == "_G" then return (EnvValues[k] or {})[1] end;
            if true then return rawget(GetInternalValue(tbl), k) end
            print("meow?",tbl,k)
            local Var = AppendCall("rawget", tbl, k)

            --return tbl[k]
            --return SafeValue(Var, rawget(GetInternalValue(tbl), k));
            local value = rawget(GetInternalValue(tbl), k)
            return SafeValue(Var, value);
        end
        
        return rawget(tbl, k)
    end

    SecureEnv.rawlen = function(tbl)
        if GetContext(tbl) then
            local Var = AppendCall("rawlen", tbl)
            return SafeValue(Var, 0)
        end

        local Type = Typeof(tbl)
        assert(Type == "table", `invalid argument #1 to 'rawlen', table expected got {Type}`)

        return rawlen(tbl);
    end

    local WrappedUnpack = SafeWrap(unpack, "unpack")
    
    SecureEnv.unpack = function(tab : { any }, i : number?, j : number?)
        if typeof(tab) ~= "table" then return tab end
        if Variables[i] or Variables[j] then
            return WrappedUnpack(tab, i, j)
        end

        return unpack(tab, i, j)
    end

    function GetInfo(i : number | thread) : { [any]: any }?
        local Type = typeof(i)
        if Type ~= "function" and Type ~= "thread" and Type ~= "number" then return {}, true end;
        local Returned = {}

        local s : string, l : number, n : string, params : number, vararg : boolean, f = debuginfo(i, "slnaf");

        Returned.func = i

        local RealC = CClosures[i] or s == "[C]"
        local True = TrueEnv[Variables[i]] -- TrueEnv[getmetatable]

        if True then RealC = RealC or iscclosure(True) end

        if RealC then -- A C Closure
            Returned.what = "C"
            Returned.namewhat = ""
            Returned.source = "=[C]"
            Returned.short_src = "[C]"
            Returned.line, Returned.linedefined, Returned.currentline, Returned.lastlinedefined =
                RealC and -1 or 1, RealC and -1 or 1, RealC and -1 or 1, RealC and -1 or 1
            Returned.numparams, Returned.is_vararg = 0, 1
            Returned.nups = 1;

            local Var = Variables[i] or n
            local name = split(Var, ".")
            name = name[#name]
            Returned.name = name
        else
            if typeof(i) == "number" then
                local CallStackNumbers = {}
                local Traceback = split(debug.traceback(), "\n")
                local String = `[string "{TraceId}"]`--"[string \"luau.load(...)\"]"
                local Len = #String

                for x = 1, #Traceback do
                    local Line = Traceback[x]

                    if Line:sub(1, Len) == String then
                        insert(CallStackNumbers, x)
                    end
                end

                table.sort(CallStackNumbers, function(a, b)
                    return a > b
                end)

                for x, level in next, CallStackNumbers do
                    if x == i then
                        s, l, n, params, vararg, f = debuginfo(level, "slnaf");
                        Returned.line, Returned.linedefined, Returned.currentline = l, l, l;
                        Returned.name = n
                        Returned.is_vararg, Returned.numparams = vararg, params
                        Returned.func = f

                        if n == "" and s == String and vararg then
                            s = TraceId
                        end

                        Returned.source, Returned.short_src = s, s;

                        return Returned;
                    end
                end

                if true then return nil end

                -- Main Env
                Returned.source, Returned.short_src = TraceId, TraceId
                Returned.name = ""
                Returned.func = debuginfo(2, "f")
                Returned.is_vararg, Returned.numparams = true, 0
                Returned.line, Returned.linedefined, Returned.currentline = 1, 1, 1;

                return Returned
            else
                Returned.what = "Lua";
                Returned.line, Returned.linedefined, Returned.currentline = l, l, l;
                Returned.source, Returned.short_src = TraceId, TraceId:sub(1, -2);
                Returned.nups = 0; --> You can do this when getupvalues is implemented
                Returned.is_vararg, Returned.numparams = vararg and 1 or 0, params;
            end
        end

        return Returned
    end

    local function Getupvalues(Func : func | number, Name : string)
        if typeof(Func) == "function" and iscclosure(Func) then
            --error(`{Name} cannot be called on a C closure!`)
        end
    end

    local Debug = GetMetatable("debug", {
        __index = {
            getinfo = Function(function(t, i)
                t, i = GetInternalValue(t), GetInternalValue(i);
                local Type = Typeof(t)
                assert(Type == "function" or Type == "number", "invalid argument #1 to 'getinfo' (function or level expected)")

                if t == 0 then t = Function(function()end,"debug.getinfo",true) end
                if not GetContext(t) then
                    local Info, DoSpy = GetInfo(t)
                    if not DoSpy then return Info end
                    return Spy(AppendCall("debug.getinfo", t, i), Info)
                end

                local Var = AppendCall("debug.getinfo", unpack({t, i}))
                local Info, DoSpy = GetInfo(t)

                if not DoSpy then SetInternalValue(Var, Info) end

                return Spy(Var)
            end, "debug.getinfo", true),
            info = Function(function(...)
                local Raw = pack(...)

                --> Roblox debug.info has a 3-arg thread form: debug.info(thread, level, options).
                --> In that form arg#2 is the numeric level and the options string is arg#3, so the
                --> plain (t, i) shape wrongly rejected the level as "string expected got number".
                local ThreadForm = Raw.n >= 3 and Typeof(Raw[1]) == "thread"
                local t = GetInternalValue(if ThreadForm then Raw[2] else Raw[1]);
                local i = GetInternalValue(if ThreadForm then Raw[3] else Raw[2]);

                assert(typeof(i) == "string", "invalid argument #" .. (if ThreadForm then 3 else 2) .. " to 'info', string expected got " .. typeof(i))

                if t == 0 then t = Function(function()end,"debug.getinfo",true) end

                local Vars = split(string.lower(i), "")
                local Names = { n = "name", a = "params", l = "line", s = "source" }
                local DefinedVars = {}
                local Vararg;

                for _, option in next, Vars do
                    insert(DefinedVars, Ast.Variable(GetCount(Names[option] or option)))

                    if option == "a" then
                        Vararg = GetCount("vararg")
                        insert(DefinedVars, Ast.Variable(Vararg))
                    end
                end

                Ast.addStatement(
                    AST,
                    Ast.Assign(
                        DefinedVars,
                        {Ast.FunctionCall(Ast.Variable("debug.info"), TupleToAST(unpack(Raw, 1, Raw.n)))},
                        false
                    )
                )

                local ToReturn = {}
                local Values = {}

                local Info = GetInfo(t) or {};
                local Skip;

                for x, v in next, Vars do
                    local value;
                    local var = DefinedVars[x + (if Skip then 1 else 0)].data.name
                    Skip = false

                    if v == "s" then
                        value = Info.what == "C" and "[C]" or Info.source
                    elseif v == "n" then
                        value = Info.name or ""
                    elseif v == "a" then
                        value = Info.numparams
                        insert(Values, value)
                        insert(ToReturn, SafeValue(var, value))

                        value = Info.is_vararg == 1

                        insert(Values, value)
                        insert(ToReturn, SafeValue(Vararg, value))
                        Skip = true
                        continue
                    elseif v == "f" then
                        value = Info.func
                        if value then Variables[value] = var end
                    elseif v == "l" then
                        value = Info.line
                    else
                        error("invalid argument #2 to 'info' (invalid option)")
                    end

                    insert(Values, value)
                    insert(ToReturn, SafeValue(var, value))
                end

                OpCountCheck()
            
                return unpack(ToReturn)
            end, "debug.info", true),
            dumpcodesize = Spy("debug.dumpcodesize"),
            traceback = Function(function(a)
                assert(not a or Typeof(a) == "string", "invalid argument #1 to 'traceback' (string expected got " .. Typeof(a) .. ")")

                local trace = debug.traceback(a)
                local lines = split(trace, "\n")
                local out = {}

                for _, v in next, lines do
                    if HideErrors(v) == v then
                        insert(out, v)
                    end
                end --> covering my traces:)

                local value = concat(out, "\n")
                value = gsub(value, ":%d+", ":1"):gsub("%[string [\"'](.-)[\"']%]", "%1")

                local Var = AppendCall("debug.traceback", a)
                Comment(value)

                return SafeValue(Var, value)
            end, "debug.traceback", true),
            getmemorycategory = Function(function()
                return SafeValue(AppendCall("debug.getmemorycategory"), MemoryCategory)
            end, "debug.getmemorycategory", true),
            setmemorycategory = Function(function(Category : string)
                assert(Typeof(Category) == "string", "invalid argument #1 to 'setmemorycategory', string expected got " .. Typeof(Category))
                MemoryCategory = Category
                return SafeValue(AppendCall("debug.getmemorycategory"), MemoryCategory)
            end, "debug.setmemorycategory", true),
            resetmemorycategory = Function(function()
                MemoryCategory = TraceId
            end, "debug.resetmemorycategory", true),
            profilebegin = Function(function(label : string)
                assert(Typeof(label) == "string", "invalid argument #1 to 'profilebegin', string expected got " .. Typeof(label))
                local Var = AppendCall("debug.profilebegin", label)
                return SafeValue(Var)
            end, "debug.profilebegin", true),
            profileend = Function(function()
                local Var = AppendCall("debug.profileend")
                return SafeValue(Var)
            end, "debug.profileend", true),
            getlocal = Function(function(func : func, idx : number)
                local Meower = AppendCall("debug.getlocal", func, idx)

                checktype(func, "function", `invalid argument #1 to 'getlocal'`)
                checktype(idx, "number", `invalid argument #2 to 'getlocal'`)

                if iscclosure(func) then
                    return SafeValue(Meower, nil);
                end

                return Spy(Meower, nil, { is_propery = true })
            end, "debug.getlocal", true),
            --[[getupvalues = Function(function(func : func | number)
                AppendCall("debug.getupvalues", func)

                local Type = Typeof(func)
                assert(Type == "function" or Type == "number", `invalid argument #1 to 'getupvalues', function or number expected got {Type}`)
                return Getupvalues(func, "getupvalues")
            end, "debug.getupvalues", true),]]
            getupvalue = Function(function(func : func | number, idx : number)
                local Upvalue = AppendCall("debug.getupvalue", func)

                local Type = Typeof(func)
                assert(Type == "function" or Type == "number", `invalid argument #1 to 'getupvalue', function or number expected got {Type}`)
                
                if iscclosure(func) then error(`'getupvalue' cannot be called on a CClosure!`) end
                if idx <= 0 then error(`invalid argument #2 to 'getupvalue' (invalid index!)`) end

                return Spy(Upvalue, nil, { is_propery = true })--(Getupvalues(func, "getupvalue") or {})[1]
            end, "debug.getupvalue", true)
        }
    })

    SecureEnv.debug = Debug
    SecureEnv.assert = function(condition, message)
        local _c, _m = condition, message

        condition, message = GetInternalValue(condition), GetInternalValue(message)

        if condition ~= _c or _m ~= message then
            AppendCall("assert", _c, _m)
        end

        return assert(condition, message);
    end

    SecureEnv.newcclosure = function(Closure : func)
        local type = Typeof(Closure)
        assert(type == "function", "invalid argument #1 to 'newcclosure', function expected got " .. type)

        local Var = AppendCall("newcclosure", Closure)

        return Function(function(...) return Closure(...) end, Var, true);
    end

    SecureEnv.hookfunction = HookFunction("hookfunction")
    SecureEnv.replaceclosure = HookFunction("replaceclosure")

    SecureEnv.restorefunction = function(f)
        AppendCall("restorefunction", f)

        local Type = Typeof(f)
        assert(Type == "function", `invalid argument #1 to 'restorefunction', function expected got {Type}`)
        Restore(GetInternalValue(f))
    end

    SecureEnv.isfunctionhooked = function(f)
        local Var = AppendCall("isfunctionhooked", f)
        return SafeValue(Var, FunctionHooks[f] ~= nil)
    end

    SecureEnv.is_function_hooked = function(f)
        local Var = AppendCall("is_function_hooked", f)
        return SafeValue(Var, IsHooked(f))
    end

    SecureEnv.ishooked = function(f)
        local Var = AppendCall("ishooked", f)
        return SafeValue(Var, IsHooked(f))
    end

    SecureEnv._VERSION = "Luau"

    --! ENVIRONMENT END

    for _, Key in next, SayPlease do
        SecureEnv[Key] = SafeWrap(TrueEnv[Key], Key)
    end
    
    for _, Key in next, FineUgh do
        SecureEnv[Key] = TrueEnv[Key]
    end

    for Key, Val in next, SecureEnv do
        if typeof(Val) == "function" and not Types[Val] then
            SecureEnv[Key] = Function(Val, Key, true)
        end
    end

    local IterFuncs = {
        next = true, ipairs = true, pairs = true
    }

    local Iterator;
    local Iterators = {}

    local PristineIdxAmount = 0;
    local Envs = {}

    local function CreateEnv(path : string) : { [string]: any }
        local env = Envs[path]
        if env then return env end;
        
        if path == "_G" or path == "shared" then
            --> do it the solara way
            local Meower = CreateEnv("getgenv()")
            local EnvVar = Ast.Variable(path);

            return GetMetatable(path, {
                __index = function(_, Key)
                    if Key == "globalEnv" then return Meower end

                    local Var = DefineVar(
                        Ast.Index(EnvVar, ToAST(Key)),
                        false,
                        true
                    )

                    local ExecType = IsExecutor(Key)

                    -- Hide lune-specific modules from _G to bypass DTC
                    if Key == "process" then
                        return setmetatable({}, {
                            __index = function() return nil end,
                            __newindex = function() end,
                            __tostring = function() return "" end,
                        })
                    end

                    local EnvValue = EnvValues[Key];
                    if EnvValue then
                        return SafeValue(Var, EnvValue[1])
                    elseif not ExecType and not TrueEnv[Key] then
                        return SafeValue(Var, nil);
                    end

                    if (SpyExecOnly and (typeof(Key) == "string" and not ExecType)) or TrueEnv[Key] or Nil[Key] or ForceNil[Key] then
                        return SafeValue(Var, nil);
                    end

                    SetInternalValue(Var, nil);
                    local Meower = Spy(Var);
                    if ExecType then Types[Meower] = ExecType end
                    return Meower
                end
            })
        end

        local Metatable = setmetatable({}, {
            __index = function(Self, Key)
                local Var = DefineVar(
                    Ast.Index(
                        Ast.FunctionCall(Ast.Variable("getgenv"), {}),
                        ToAST(Key)
                    ),
                    false,
                    true
                )

                local Value = EnvValues[Key]
                local Meow = rawget(SecureEnv, Key)
                if Meow then Value = {Meow} end
                
                if Value then
                    local X = Value[1]
                    --if typeof(X) == "function" then return X end;
                    return SafeValue(Var, X)
                end

                local ExecType = IsExecutor(Key)

                if SpyExecOnly then
                    SetInternalValue(Var, nil)
                    return TypeSpy(Var, ExecType)
                end

                if ExecType == "function" then
                    return Function(function(...)
                        local Var = AppendCall(Var, ...)
                        return Spy(Var);
                    end, Var, true)
                end

                local Spied = Spy(Var, rawget(Env, Key));
                if ExecType then
                    Types[Spied] = ExecType
                end

                return Spied;
            end,
            __newindex = function(Self, Key, Value)
                Define(
                    Ast.Index(Ast.FunctionCall(Ast.Variable("getgenv"), {}), ToAST(Key)),
                    ToAST(Value),
                    true,
                    true
                )
                
                EnvValues[Key] = { Value }
            end,
            __len = function() return 0 end,
            __metatable = "Protected" -- Solara's implementation
        })
        return Metatable;
    end

    SecureEnv._G, SecureEnv.shared, SecureEnv.getgenv, SecureEnv.getrenv =
        CreateEnv("_G"),
        CreateEnv("shared"),
        Function(function() return CreateEnv("getgenv()") end, "getgenv", true),
        Function(function() return CreateEnv("getrenv()") end, "getrenv", true);

    ExploitLib:setEnv({
        ToAST = ToAST,
        TupleToAST = TupleToAST,
        OpCountCheck = OpCountCheck,
        VarValues = VarValues,
        AST = AST,
        AppendCall = AppendCall,
        Spy = Spy,
        TypeSpy = TypeSpy,
        SafeValue = SafeValue,
        cclosures = CClosures,
        types = Types,
        Function = Function,
        Variables = Variables,
        TraceId = TraceId,
        UseHookOp = UseHookOp,
        Settings = Settings,
        GetInternalValue = GetInternalValue,
        Globals = SharedGlobals,
        GetMetatable = GetMetatable,
        GetVar = GetVar,
        SpiedToInstance = SpiedToInstance
    })

    for funcName, func in next, ExploitLib.funcs do
        SecureEnv[funcName] = Function(func, funcName, true)
    end

    for libName, library in next, ExploitLib.libs do
        for Key, Value in next, library do
            library[Key] =
                if typeof(Value) == "function" then
                    Function(Value, Index(Key, libName), true)
                else
                    Value
        end
        SecureEnv[libName] = GetMetatable(libName, { __index = library })
    end

    local meowed = {}
    GlobalIndex = function(Self, Key)
        if Settings.debug then print("Indexed",Key,typeof(Key)) end

        local EnvValue = EnvValues[Key]
        local ExecType = IsExecutor(Key)

        if EnvValue then
            return SafeValue(Key, EnvValue[1])
        end

        local Type = typeof(Key)
        local DontDefine, ToUse;

        if Nil[Key] then
            return SafeValue(Key, nil)
        elseif ForceNil[Key] or Type == "nil" then
            return nil;
        end

        if not ExecType and not TrueEnv[Key] then
            ForceNil[Key] = true
            return nil
        end

        if IterFuncs[Key] then
            return Function(function(tbl, k : (any) -> any | nil)
                local Var = Variables[tbl]

                if Key == "next" and Var then
                    if k then
                        if Iterator then Iterator() end
                        Iterator = nil

                        return nil, nil;
                    end

                    Iterator = getmetatable(tbl).__iter(tbl, Key)
                    return Iterator();
                elseif Var then
                    local mt = getmetatable(tbl)
                    if mt then
                        Iterator = mt.__iter(tbl, Key)
                        Iterators[Iterator] = true
                        return Iterator
                    else
                        Ast.addStatement(AST, Ast.PermaComment(Ast.RawText("Unable to get the metatable for '"), Ast.Variable(Var), Ast.RawText(`' so we're unable to log the for loop (which uses {Key}) here.`)))
                    end
                elseif Key == "next" then
                    return next(tbl, k);
                end

                return TrueEnv[Key](tbl, k);
            end, Key, true)
        end

        local IgnoreMar = DoIgnore(Key)
        local Casper = IgnoreMar or -- Detected as junk
            --(Type == "string") or-- and #Key == 2) or -- Moonveil
            (Type == "string" and (#Key == 13 and Key:find("%d"))) or
            Type == "function" or -- fenv[debug.getinfo] or something
            Type == "nil" or -- fenv[nil]
            (SpyExecOnly and not ExecType)

        if Key and not meowed[Key] then
            ToUse = Define(
                if Casper and not IgnoreMar then
                    if typeof(Key) == "string" and not IsWeird(Key) then
                        Ast.Variable(Key:gsub("%W", "_"))
                    else
                        GetVar()
                else
                    GetVar(),
                Ast.Index(Ast.Variable(EnvName), ToAST(Key)),
                false,
                true
            ).data.vars[1].data.name
            DontDefine = true
            ForceNil[Key] = IgnoreMar
            meowed[Key] = ToUse
            Indexes[ToUse] = true
        end

        if
            Casper -- spyexeconly is on & it's not an exec func
        then
            ToUse = ToUse or meowed[Key];
            if not hookOp then
                return nil;
            end
            
            SetInternalValue(ToUse, nil);
            return Spy(ToUse, nil, {
                is_idx = true
            })
        end

        if SharedGlobals.Pristine then
            PristineIdxAmount += 1
            local Saved = SharedGlobals.SavedPristine[Key]
            if Saved then
                rawset(Self, Key, Saved)
                SharedGlobals.SavedPristine[Key] = nil
                return Saved
            end
        end

        ToUse = ToUse or GetVar();
        local True = TrueEnv[Key];
        local Spied;

        if typeof(True) == "function" then
            Spied = Function(function(...)
                local Var = AppendCall(ToUse, ...)
                return Spy(Var)
            end, ToUse, true)
        elseif Type == "string" and Key:find('%W') then
            Spied = Spy(ToUse)
            SetInternalValue(ToUse, nil)
        else
            Spied = Spy(ToUse);
            Types[Spied] = ExecType or typeof(True);
        end

        if not DontDefine then
            Define(
                ToUse,
                Ast.Index(Ast.Variable(EnvName), ToAST(Key)),
                false,
                true
            )
        end

        return Spied
    end

    Env = setmetatable(SecureEnv, getmetatable(GetMetatable(EnvName, {
        __index = GlobalIndex,
        __newindex = function(Self, Key, Value)
            if Key == "_msec" or Key == "heh" then
                return rawset(Self, Key, Value)
            end

            local KeyLen = if typeof(Key) == "string" then #Key else nil;
            local OldVar = Variables[Value]
            local New, ToUse = nil, Ast.Variable(Key);
            local IsFunction = typeof(Value) == "function"
            if IsFunction then
                New = Settings.discord and Function(function(...)
                    local Arg1 = ...
                    if typeof(Arg1) == "string" and DoIgnore(Arg1) then
                        return Value(...)
                    end

                    local Old, Stat = AppendCall(ToUse, ...)
                    local OldLen = VariablesLen
                    local Logged, Values = Explore(Value, {
                        params = {...},
                        bypass_beautify = true
                    })

                    if OldLen ~= VariablesLen then --> New variables added, we don't wanna miss out on them.
                        for _, stat in next, Logged.data.statements do
                            if stat.kind ~= "return" then
                                Ast.addStatement(AST, stat)
                            end
                        end
                    end

                    if Values[1] then
                        Values = table.pack(
                            unpack(Values, 2)
                        )
                        return ToMultiVars(Stat, Values, true)
                    end

                    error(Values[2])
                end, Key, iscclosure(Value)) or Value;
            elseif KeyLen then
                New = Spy(tostring(Key), Value)
            end

            if not New then
                return;
            end

            local Len = if typeof(Value) == "string" then #Value else 0
            
            if Len > 200 or KeyLen == 2 then return rawset(Self, Key, Value) end

            local ToUse = Ast.Index(Ast.Variable(EnvName), ToAST(Key));

            rawset(Self, Key, if IsFunction then New elseif OldVar then SafeValue(AstLib.ExprToCode(ToUse), Value) else Value)

            local Var = Variables[Value]
            if Var and typeof(Value) ~= "table" and not OldVar then Variables[Value] = nil end

            Define( ToUse, ToAST(Value), true, true )

            if Value then Variables[Value] = Var end
        end,
        __tostring = function() return EnvName end,
        __iter = function(Self, Key)
            local k = nil
            return function()
                while true do
                    k = next(Self, k)
                    if k == nil then return end
                    if TrueEnv[k] or IsExecutor(k) or EnvValues[k] then
                        return k, Self[k]
                    end
                end
            end
        end,
        __call = function() error("attempt to call a table value") end,
        __len = function() return 0 end,
        __add = function(t, v) error(`attempt to perform arithmetic (add) on {Typeof(t)} and {Typeof(v)}`) end,
        __sub = function(t, v) error(`attempt to perform arithmetic (sub) on {Typeof(t)} and {Typeof(v)}`) end,
        __mul = function(t, v) error(`attempt to perform arithmetic (mul) on {Typeof(t)} and {Typeof(v)}`) end,
        __div = function(t, v) error(`attempt to perform arithmetic (div) on {Typeof(t)} and {Typeof(v)}`) end,
        __idiv = function(t, v) error(`attempt to perform arithmetic (idiv) on {Typeof(t)} and {Typeof(v)}`) end,
        __mod = function(t, v) error(`attempt to perform arithmetic (mod) on {Typeof(t)} and {Typeof(v)}`) end,
        __pow = function(t, v) error(`attempt to perform arithmetic (pow) on {Typeof(t)} and {Typeof(v)}`) end,
        __unm = function(t) error(`attempt to perform arithmetic (unm) on {Typeof(t)}`) end,
        __concat = function(t, v) error(`attempt to concatenate {Typeof(t)} and {Typeof(v)}`) end,
    })))

    local Macros = {
        predefine = function(tbl)
            assert(typeof(tbl) == "table", `invalid argument #1 to 'predefine', table expected got {typeof(tbl)}`)

            for i, v in next, tbl do
                Predefined[i] = { v }
            end
        end,
        hook = function(id : number, val : boolean)
            checktype(id, "number", "invalid argument #1 to 'hook'")
            checktype(val, "boolean", "invalid argument #2 to 'hook'")

            StatementHooks[id] = val;
        end,
        spy = function(path : string, value : any, didntStutter : boolean)
            local type = typeof(path)
            assert(type == "string", `invalid argument #1 to 'spy', string expected got {type}`)

            local Spied = Spy(path)
            if value ~= nil or didntStutter then
                SetInternalValue(Spied, value)
            end
            return Spied;
        end,
        setvalue = function(path : string, value : any)
            local type = typeof(path)
            assert(type == "string", `invalid argument #1 to 'spy', string expected got {type}`)

            SetInternalValue(path, value);
        end,
        hookcalls = function(handler : func)
            checktype(handler, "function", "invalid argument #1 to 'hookcalls'")

            CallsHandler = handler;
        end,
        getpath = function(obj : any)
            return Variables[obj]
        end
    }

    ExploitLib:setGlobalEnv(Env);

    Variables[Env] = EnvName
    SetInternalValue(EnvName, SecureEnv)

    local Function = setfenv(Source, Env) :: (any) -> any

    local List = Settings.macros
    if List and fs.isFile(List) then
        local macroData = fs.readFile(List);

        local thing = GetMetatable("macros", {
            __index = function(_, Key) return Macros[Key] or Env[Key]; end,
            __newindex = function(_, Key, Value)
                EnvValues[Key] = {Value, Key}
            end
        })

        local s, e = pcall(fenv.setfenv(loadstring(macroData), thing))
        if not s then Comment(`failed to load macros, error message: {HideErrors(e, true)}`) end
    end

    StartedRunning = os.time()
    SharedGlobals.StartedRunning = StartedRunning

    local Values = pack(pcall(Function)); --! add args
    CloseAllEnds()

    if not Values[1] then
        local LastStatement = AST.data.statements[#AST.data.statements]
        if LastStatement and LastStatement.kind == "call" and LastStatement.data.func.data.name == "error" then
        else
            Ast.addStatement(
                AST,
                Ast.FunctionCall(
                    Ast.Variable("error"), {
                        ToAST(Values[2], {
                            clean = true
                        })
                    }
                )
            )
        end
    elseif Values.n > 1 then
        Ast.addStatement(
            AST,
            Ast.Return(TupleToAST(unpack(Values, 2)))
        )
    end

    SharedGlobals.Deferred = {};

    local Beautified = {}

    WHILE_LIMIT /= 2.5
    TotalRepeats, TotalWhiles = 0, 0

    print("Iterating..")

    local PlsSave = Settings.save_before;

    if Settings.runtimelogs or PlsSave then
        local Success, Result = pcall(AstLib.Stringify, AST)
        if Success then
            fs.writeFile(PlsSave and "debug.lua" or Settings.out, Result)
        end
    end

    table.sort(ToExplore, function(a, b) -- a < b
        local DelayA, DelayB = a.args.delay, b.args.delay
        local DeferredA, DeferredB = a.args.deferred, b.args.deferred
    
        -- Handle deferred tasks: deferred items come after non-deferred
        if DeferredA ~= DeferredB then
            return not DeferredA -- non-deferred (false) < deferred (true)
        end
    
        -- Both deferred or both not deferred
        if not DelayA and not DelayB then
            return a.idx < b.idx
        else
            return (DelayA or 0) > (DelayB or 0)
        end
    end)

    local function Iterate()
        yoiterate = true
        for _, Data in next, ToExplore do
            if Beautified[Data] then continue end

            local Function, Id, Node, Args = Data.func, Data.id, Data.node, Data.args

            Args.as_func = true
            Args.bypass_beautify = true

            local Explored = Explore(Function, Args)
            Beautified[Data] = true

            table.clear(Node)

            for i, v in next, Explored do -- Copy everything from the function to here
                Node[i] = v
            end
        end
    end

    Iterate()

    return AST;
end

local LURAPH_MARKER = "does your environment support load/loadstring?"

local function DecompressLuraph(Code : string, Depth : number?) : string?
    --[[
        Luraph's "compressed" output is a small bootstrap that decompresses the
        real VM source into a string, then runs it via loadstring()/load().
        Our env hooks loadstring (it spies instead of really compiling), so the
        decompression corrupts and the script dies with "table overflow".

        Fix (notes.md: "if luraph isn't working, make sure loadstring & setfenv are"
        + "Added automatic luraph decompression"): run the bootstrap in a CLEAN
        sandbox with a real string env, but replace load/loadstring with a capture
        hook. The bootstrap hands us the decompressed source as a plain string; we
        grab the largest valid Luau chunk and hand THAT to EnvLog instead.
    ]]
    Depth = Depth or 0
    if Depth > 4 then return nil end --> guard against pathological nesting

    local Captured = {}
    local function Capture(chunk : any)
        if typeof(chunk) == "string" then insert(Captured, chunk) end
        return function() end --> pretend the load succeeded so the bootstrap continues
    end

    local Sandbox = fenv.setmetatable({
        loadstring = Capture,
        load = Capture,
    }, { __index = TrueEnv })

    local Loaded = loadstring(Code, { debugName = "luraph_decompress" })
    if not Loaded then return nil end

    pcall(fenv.setfenv(Loaded, Sandbox)) --> errors here are fine, we only want the captured payload

    local Best, BestLen = nil, 0
    for _, chunk in next, Captured do
        if #chunk > BestLen then
            local Ok, Compiled = pcall(compile, chunk) --> only keep chunks that are real Luau
            if Ok and Compiled then
                Best, BestLen = chunk, #chunk
            end
        end
    end

    if not Best then return nil end

    --> Luraph can stack compression layers; peel them until we hit real source.
    if Best:find(LURAPH_MARKER, 1, true) then
        return DecompressLuraph(Best, Depth + 1) or Best
    end

    return Best
end

local function TimedDump(File : string, RawContent : boolean?)
    Settings.out = Settings.out or "out.lua"

    local Code : string = RawContent and File or fs.readFile("./" .. File);
    local Source = Code;

    local HookFile = if RawContent then nil else File --> file hookOp reads from; nil = write Code to a temp

    if Code:find(LURAPH_MARKER, 1, true) then
        local Decompressed = DecompressLuraph(Code)
        if Decompressed then
            print(format("Luraph compressed payload detected; decompressed %d -> %d bytes", #Code, #Decompressed))
            Code = Decompressed
            Source = Decompressed
            HookFile = nil --> Code no longer matches File on disk, so hookOp must read our decompressed copy
        else
            warn("Luraph decompression failed; running compressed bootstrap directly")
        end
    end

    local A, B, C, D = Code:byte(1, 4);
    local IsBytecode = false;
    if A == 6 and B == 3 and C == 159 and D == 1 then --> Luau bytecode!
        IsBytecode = true
    end

    if not IsBytecode and not RawContent then
        local StartObf = os.clock()
        local Success, Hooked = UseHookOp(Code, HookFile)
        print("Obfuscated in",os.clock()-StartObf,"seconds.")
        if not Success then
            local Reason = tostring(Hooked)
            local ReasonQuoted = string.format("%q", Reason)
            Code = "print(\"Unable to load hookOp on this file, this file ran as it would without hookOp. Reason: \" .. " .. ReasonQuoted .. ")\n" ..
                Code
        else
            Code = Hooked
        end
    end

    if Settings.version and not RawContent then --> from bot
        fs.removeFile(File);
    end

    AstLib.SetGlobal("outfile", Settings.out)
    AstLib.SetGlobal("envname", EnvName)
    AstLib.SetGlobal("atruntime", Settings.runtimelogs)
    AstLib.SetGlobal("annotations", Settings.type_annotations)
    AstLib.SetGlobal("fromld", Settings.from_ld)
    AstLib.SetGlobal("minifier", Settings.minifier)
    AstLib.SetGlobal("comments", Settings.comments)

    local Start = os.clock()
    --LURAPH_COMPRESSED = Code:find("(does your environment support load/loadstring?", 0, true) and Code:find("Luraph decompression error: ", 0, true)
    local Multiplier = (1 + #Code / (200 * 1024))
    WHILE_LIMIT *= Multiplier
    MAX_OPS_MUL = Multiplier
    
    local Compiled, Loaded;
    if IsBytecode then
        print("yea!")
    end
    local Success, Error = pcall(function()
        Compiled = compile(Code, {
            optimizationLevel = 2
        })
        Loaded = loadstring(Compiled, {
            debugName = TraceId
        })
    end)

    if not Success then
        fs.writeFile(Settings.out, "--err" .. fenv.tostring(Error):match("[^\n]+"))
        process.exit(0)
        return;
    end

    AllowedGetRequests += if Source:find(":HttpGet(", 0, true) then 1 else 0

    local AST, UsedHook = EnvLog(Loaded, 0), true

    local function AstQuality(ast)
        local total = #ast.data.statements
        if total < 3 then return total end
        local meaningful = 0
        for _, stmt in next, ast.data.statements do
            if stmt.kind ~= "comment" and stmt.kind ~= "nonoptionalcomment" then
                meaningful += 1
            end
        end
        return meaningful
    end

    if AstQuality(AST) < 3 and not IsBytecode and not RawContent then
        local RawCode = Source or Code
        local RawCompiled, RawLoaded
        local RawOk, RawErr = pcall(function()
            RawCompiled = compile(RawCode, { optimizationLevel = 2 })
            RawLoaded = loadstring(RawCompiled, { debugName = TraceId .. "_raw" })
        end)
        if RawOk then
            print("retrying with .r (raw code)")
            local RawAST = EnvLog(RawLoaded, 0)
            if AstQuality(RawAST) > AstQuality(AST) then
                print(format(".r fallback better (%d > %d stmts)", AstQuality(RawAST), AstQuality(AST)))
                AST = RawAST
                UsedHook = false
            end
        end
    end

    if AstQuality(AST) < 3 and not IsBytecode and not RawContent then
        local TempIn = Settings.out .. ".r2_in.lua"
        local TempOut = Settings.out .. ".r2_out.lua"
        local luneBin = process.os == "windows" and "lune.exe" or "lune"
        pcall(fs.writeFile, TempIn, Code)
        local POut = process.exec(luneBin, { "run", "mods/aspect.luau", TempIn, TempOut })
        if POut and POut.exitCode == 0 then
            local OkR2, ResultR2 = pcall(fs.readFile, TempOut)
            if OkR2 and #ResultR2 > 50 then
                print(format(".r2 (aspect) fallback produced %d bytes", #ResultR2))
                local NewAST = Ast.new()
                Ast.addStatement(NewAST, Ast.RawText(ResultR2))
                AST = NewAST
                UsedHook = false
            end
        end
        pcall(fs.removeFile, TempIn)
        pcall(fs.removeFile, TempOut)
    end

    
    -- === COMBINED: LARRY FALLBACK (.r3) ===
    if AstQuality(AST) < 3 and not IsBytecode and not RawContent then
        print(".r3 (larry proxy dumper) fallback trying...")
        local okLarry, larryOut = pcall(function()
            -- Try to use LarryDumper to dump the original source
            local tmpOut = Settings.out .. ".r3_larry.lua"
            -- Larry expects a file path; write current source to temp if needed
            local tmpIn = "./.tmp_larry_in.lua"
            local srcToDump = Source or Code
            pcall(fs.writeFile, tmpIn, srcToDump)
            local success = LarryDumper.dump_file(tmpIn, tmpOut)
            if success and fs.isFile(tmpOut) then
                local content = fs.readFile(tmpOut)
                pcall(fs.removeFile, tmpIn)
                pcall(fs.removeFile, tmpOut)
                return content
            end
            pcall(fs.removeFile, tmpIn)
            return nil
        end)
        if okLarry and larryOut and #larryOut > 100 then
            print(string.format(".r3 (larry) fallback produced %d bytes - using it", #larryOut))
            local NewAST = Ast.new()
            Ast.addStatement(NewAST, Ast.RawText(larryOut))
            AST = NewAST
            UsedHook = false
        else
            print(".r3 larry fallback failed or produced too little")
        end
    end
    -- === END COMBINED FALLBACK ===

    DONE_PROCESSING = true

    Success, Result = pcall(AstLib.Stringify, AstLib.Minify(AST, not Settings.minifier))

    if not Success then
        warn("not success", Result)
    end

    Result = (if Settings.debug then Result else HideErrors(Result, nil, true)):gsub("\n%s*;\n", "\n"):gsub("discord%.gg/[%w_]+", "(discord invite)")

    local TopComment = "-- Successfully sent http GET requests to the following site(s): "
    local Meowed;
    for _, v in next, AllowedUrlsInTheEnd do
        TopComment ..= `'{v}', `
        Meowed = true
    end

    if Meowed then Result = TopComment:sub(1, -3) .. "\n" .. Result end

    print(format("Finished processing in %.8f seconds!", os.clock() - Start))
    fs.writeFile(
        Settings.out,
        (if Settings.version then `-- powered by dsc.gg/v69ms\n\n` else "")
        .. Result
    );
    _print("Finished processing")
    process.exit(0);
end

if Settings.ipt then --> Spawned instantly, for beta testing or whatever.
    return TimedDump(Settings.ipt or "input.lua");
end

while true do
    local Input = stdio.readLine()
    local Decoded = serde.decode("json", Input)

    Settings = Decoded.settings
    TimedDump(Decoded.script, true)
end

-- ==================== ULTIMATE ENHANCEMENTS (49KB) ====================
--!nonstrict
-- ============================================================================
-- ULTIMATE ENVLOGGER v2.0 - COMBINED POWERFUL EDITION
-- รวมจุดแข็งจาก 2 ไฟล์:
--   main.lua (AST Logger, Lune, HookOp, Luraph Decompress, InstanceLib)
--   envlogger.lua (Larry Proxy Dumper, CallGraph, StringRefs, UI Heuristics)
-- 
-- สิ่งที่เติมเต็มกัน:
--   จาก main: AST tracking, HookOp, Luraph decompress, WHILE_LIMIT, Type tracking,
--             Garbage filter, HttpGet logging, pcall exploration, Services
--   จาก Larry: Proxy weak table, tobit numbers, 50+ method hooks, CallGraph,
--              StringRefs (URL/base64/asset), UI naming (window/tab/button...),
--              Library detection (Rayfield/Orion/Kavo...), Drawing/crypt/mouse,
--              Output size limit & repetition suppression, Task logging
--
-- วิธีใช้:
--   lune run ultimate_envlogger.lua input.lua
--   lua ultimate_envlogger.lua obfuscated.lua dumped.lua
--   หรือใน executor: loadstring(ultimate)() แล้ว require ไฟล์ obfuscated
-- ============================================================================

local CONFIG = {
    -- Larry Config
    MAX_DEPTH = 15,
    MAX_TABLE_ITEMS = 150,
    OUTPUT_FILE = "dumped_output.lua",
    VERBOSE = false,
    TRACE_CALLBACKS = true,
    TIMEOUT_SECONDS = 10,
    MAX_REPEATED_LINES = 6,
    MIN_DEOBF_LENGTH = 150,
    MAX_OUTPUT_SIZE = 10 * 1024 * 1024,
    CONSTANT_COLLECTION = true,
    INSTRUMENT_LOGIC = true,
    -- Main Config
    WHILE_LIMIT = 50_000_000,
    DONT_DELETE_FILES = false,
    HOOKOP_ENABLED = true,
    LURAPH_DECOMPRESS = true,
    ROBLOX_EMULATION = true,
    EXPLOIT_EMULATION = true,
}

-- ==================== DEPENDENCIES (Lune / Std) ====================
local has_lune = false
local fs, process, serde, task, stdio, luau
local ok = pcall(function()
    fs = require("@lune/fs")
    process = require("@lune/process")
    serde = require("@lune/serde")
    task = require("@lune/task")
    stdio = require("@lune/stdio")
    luau = require("@lune/luau")
    has_lune = true
end)

local _print = print
local _warn = warn or function() end
local _io = io
local _os = os
local _debug = debug
local _type = type
local _tostring = tostring
local _tonumber = tonumber
local _pairs = pairs
local _ipairs = ipairs
local _load = load
local _loadstring = loadstring or load
local _pcall = pcall
local _xpcall = xpcall
local _getmetatable = getmetatable
local _setmetatable = setmetatable
local _rawget = rawget
local _rawset = rawset
local _rawequal = rawequal

-- ==================== UTILITIES ====================
local Alphabet = {}
for c in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do table.insert(Alphabet, c) end
local function GenId(len)
    len = len or 6
    local t = ""
    for i=1,len do t = t .. Alphabet[math.random(1,#Alphabet)] end
    return t
end

local TraceId = GenId(6)
local HardwareId = GenId(4).."-"..GenId(4).."-"..GenId(4).."-"..GenId(4)

local function IsWeird(key)
    if key == "" or _type(key) ~= "string" then return true end
    if tonumber(key:sub(1,1)) then return true end
    return key:match("[^%w_]") ~= nil
end

local function HideErrors(text)
    if _type(text) ~= "string" then return _tostring(text) end
    text = text:gsub("C:[/\\]+Users[/\\]+.-[\\/]([^\\/]+):(%d+)", "%1:%2")
    return text
end

-- Garbage string detection (from main)
local function IsGarbageString(str)
    if #str > 24 then return true end
    if #str < 12 then return false end
    local hasUpper = str:match("[A-Z]")
    local hasLower = str:match("[a-z]")
    local hasDigit = str:match("%d")
    return hasUpper and (hasLower or hasDigit) and str:match("[%W]") == nil and #str >= 12
end

-- ==================== OUTPUT MANAGER (Larry + Main) ====================
local State = {
    output = {},
    indent = 0,
    registry = {}, -- obj -> varname
    reverse_registry = {}, -- varname -> obj
    names_used = {},
    parent_map = {},
    property_store = {},
    call_graph = {},
    string_refs = {},
    variable_types = {},
    proxy_id = 0,
    callback_depth = 0,
    pending_iterator = false,
    last_http_url = nil,
    last_emitted_line = nil,
    repetition_count = 0,
    current_size = 0,
    limit_reached = false,
    lar_counter = 0,
    -- From main
    Variables = {}, -- obj -> var string
    ReverseVariables = {},
    Internal = {},
    Usages = {},
    Information = {},
    Types = {},
    Functions = {},
    CClosures = {},
    Strings = {},
    ConstantList = {},
    -- Combined
    captured_constants = {},
}

local function getIndent() return string.rep("    ", State.indent) end

local function emit(line, noIndent)
    if State.limit_reached then return end
    if line == nil then return end
    local indentStr = noIndent and "" or getIndent()
    local full = indentStr .. _tostring(line)
    local size = #full + 1
    if State.current_size + size > CONFIG.MAX_OUTPUT_SIZE then
        State.limit_reached = true
        local msg = indentStr .. "-- [CRITICAL] Dump stopped: File size exceeded "..(CONFIG.MAX_OUTPUT_SIZE/1024/1024).."MB limit"
        table.insert(State.output, msg)
        State.current_size = State.current_size + #msg
        error("DUMP_LIMIT_EXCEEDED")
    end
    -- Repetition suppression (Larry)
    if full == State.last_emitted_line then
        State.repetition_count = State.repetition_count + 1
        if State.repetition_count <= CONFIG.MAX_REPEATED_LINES then
            table.insert(State.output, full)
            State.current_size = State.current_size + size
        elseif State.repetition_count == CONFIG.MAX_REPEATED_LINES + 1 then
            local suppress = indentStr .. "-- [Repeated lines suppressed...]"
            table.insert(State.output, suppress)
            State.current_size = State.current_size + #suppress
        end
    else
        State.last_emitted_line = full
        State.repetition_count = 0
        table.insert(State.output, full)
        State.current_size = State.current_size + size
    end
    if CONFIG.VERBOSE and State.repetition_count <= 1 then
        _print(full)
    end
end

local function emitComment(c) emit("-- ".._tostring(c)) end
local function emitBlank() table.insert(State.output, "") end
local function getOutput() return table.concat(State.output, "\n") end
local function saveOutput(path)
    local f
    if has_lune then
        fs.writeFile(path or CONFIG.OUTPUT_FILE, getOutput())
        return true
    else
        f = _io.open(path or CONFIG.OUTPUT_FILE, "w")
        if f then f:write(getOutput()); f:close(); return true end
    end
    return false
end

-- ==================== TOBIT NUMBER PROXY (Larry anti-tamper) ====================
local tobitKey = {}
local weakProxies = {}
setmetatable(weakProxies, {__mode="k"})

local function isTobitProxy(x)
    if _type(x) ~= "table" then return false end
    local ok, v = _pcall(function() return _rawget(x, tobitKey) == true end)
    return ok and v
end

local function getTobitValue(x)
    if isTobitProxy(x) then return _rawget(x, "__value") or 0 end
    if _type(x) == "number" then return x end
    return 0
end

local function createTobitProxy(val)
    val = (val or 0) % 4294967296
    if val >= 2147483648 then val = val - 4294967296 end
    val = math.floor(val)
    local proxy, mt = {}, {}
    weakProxies[proxy] = true
    _rawset(proxy, tobitKey, true)
    _rawset(proxy, "__value", val)
    State.registry[proxy] = _tostring(val)
    mt.__tostring = function() return _tostring(val) end
    mt.__index = function(_, k)
        if k == tobitKey or k == "__value" or k == "__proxy_id" then return _rawget(proxy, k) end
        return createTobitProxy(0)
    end
    mt.__newindex = function() end
    mt.__call = function() return val end
    local function mathOp(op)
        return function(a,b)
            local av = _type(a)=="table" and _rawget(a,"__value") or a or 0
            local bv = _type(b)=="table" and _rawget(b,"__value") or b or 0
            local r = 0
            if op=="+" then r=av+bv elseif op=="-" then r=av-bv elseif op=="*" then r=av*bv
            elseif op=="/" then r= bv~=0 and av/bv or 0
            elseif op=="%" then r= bv~=0 and av%bv or 0
            elseif op=="^" then r=av^bv else r=0 end
            return createTobitProxy(r)
        end
    end
    mt.__add=mathOp("+"); mt.__sub=mathOp("-"); mt.__mul=mathOp("*")
    mt.__div=mathOp("/"); mt.__mod=mathOp("%"); mt.__pow=mathOp("^")
    mt.__unm=function(s) return createTobitProxy(-(_rawget(s,"__value") or 0)) end
    mt.__eq=function(a,b) return (_type(a)=="table" and _rawget(a,"__value") or a) == (_type(b)=="table" and _rawget(b,"__value") or b) end
    mt.__lt=function(a,b) return (_type(a)=="table" and _rawget(a,"__value") or a) < (_type(b)=="table" and _rawget(b,"__value") or b) end
    mt.__le=function(a,b) return (_type(a)=="table" and _rawget(a,"__value") or a) <= (_type(b)=="table" and _rawget(b,"__value") or b) end
    mt.__len=function() return 0 end
    _setmetatable(proxy, mt)
    return proxy
end

-- ==================== VALUE TO AST / STRING ====================
local function safeTostring(v)
    local ok, s = _pcall(_tostring, v)
    return ok and s or "unknown"
end

local function isProxy(x)
    return weakProxies[x] == true or State.Variables[x] ~= nil or State.registry[x] ~= nil
end

local function getVarName(obj)
    return State.Variables[obj] or State.registry[obj]
end

local function toCode(val, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > CONFIG.MAX_DEPTH then return "{ --[[max depth]] }" end
    local t = _type(val)
    if isTobitProxy(val) then return _tostring(_rawget(val,"__value") or 0) end
    if t == "table" and State.registry[val] then return State.registry[val] end
    if t == "table" and State.Variables[val] then return State.Variables[val] end
    if t == "nil" then return "nil"
    elseif t == "string" then
        -- String ref tracking (Larry)
        if #val > 100 and val:match("^[A-Za-z0-9+/=]+$") then
            table.insert(State.string_refs, {value=val:sub(1,50).."...", hint="base64", full_length=#val})
        elseif val:match("https?://") then
            table.insert(State.string_refs, {value=val, hint="URL"})
        elseif val:match("rbxasset://") or val:match("rbxassetid://") then
            table.insert(State.string_refs, {value=val, hint="Asset"})
        end
        return string.format("%q", val)
    elseif t == "number" then
        if val ~= val then return "0/0" end
        if val == math.huge then return "math.huge" end
        if val == -math.huge then return "-math.huge" end
        if val == math.floor(val) then return _tostring(math.floor(val)) end
        return string.format("%.6g", val)
    elseif t == "boolean" then return _tostring(val)
    elseif t == "function" then
        if State.registry[val] then return State.registry[val] end
        return "function() end"
    elseif t == "table" then
        if seen[val] then return "{ --[[circular]] }" end
        seen[val] = true
        local count=0
        for k,v in _pairs(val) do if k~=tobitKey and k~="__value" and k~="__proxy_id" then count=count+1 end end
        if count==0 then return "{}" end
        -- check array
        local isArray=true
        local max=0
        for k,v in _pairs(val) do
            if k==tobitKey or k=="__value" or k=="__proxy_id" then
            elseif _type(k)~="number" or k<1 or k~=math.floor(k) then isArray=false; break
            else max=math.max(max,k) end
        end
        isArray = isArray and max==count
        if isArray and count<=5 then
            local parts={}
            for i=1,count do table.insert(parts, toCode(val[i], depth+1, seen)) end
            return "{"..table.concat(parts,", ").."}"
        end
        local lines={}
        local indentInner=string.rep("    ", State.indent+depth+1)
        local indentOuter=string.rep("    ", State.indent+depth)
        local i=0
        for k,v in _pairs(val) do
            if k==tobitKey or k=="__value" or k=="__proxy_id" then
            else
                i=i+1
                if i>CONFIG.MAX_TABLE_ITEMS then
                    table.insert(lines, indentInner.."-- ..."..(count-i+1).." more")
                    break
                end
                local keyStr
                if isArray then keyStr=nil
                elseif _type(k)=="string" and k:match("^[%a_][%w_]*$") then keyStr=k
                else keyStr="["..toCode(k,depth+1,seen).."]" end
                local valStr=toCode(v,depth+1,seen)
                if keyStr then table.insert(lines, indentInner..keyStr.." = "..valStr)
                else table.insert(lines, indentInner..valStr) end
            end
        end
        if #lines==0 then return "{}" end
        return "{\n"..table.concat(lines,",\n").."\n"..indentOuter.."}"
    elseif t=="userdata" then
        if State.registry[val] then return State.registry[val] end
        return safeTostring(val)
    else
        return safeTostring(val)
    end
end

-- ==================== UI NAMING HEURISTICS (Larry) ====================
local ServiceShortNames = {
    Players="Players", UserInputService="UIS", RunService="RunService",
    ReplicatedStorage="ReplicatedStorage", TweenService="TweenService",
    Workspace="Workspace", Lighting="Lighting", StarterGui="StarterGui",
    CoreGui="CoreGui", HttpService="HttpService", MarketplaceService="MarketplaceService",
    DataStoreService="DataStoreService", TeleportService="TeleportService",
    SoundService="SoundService", Chat="Chat", Teams="Teams",
    ProximityPromptService="ProximityPromptService", ContextActionService="ContextActionService",
    CollectionService="CollectionService", PathfindingService="PathfindingService", Debris="Debris"
}

local UIPatterns = {
    {pattern="window", prefix="Window", counter="window"},
    {pattern="tab", prefix="Tab", counter="tab"},
    {pattern="section", prefix="Section", counter="section"},
    {pattern="button", prefix="Button", counter="button"},
    {pattern="toggle", prefix="Toggle", counter="toggle"},
    {pattern="slider", prefix="Slider", counter="slider"},
    {pattern="dropdown", prefix="Dropdown", counter="dropdown"},
    {pattern="textbox", prefix="Textbox", counter="textbox"},
    {pattern="input", prefix="Input", counter="input"},
    {pattern="label", prefix="Label", counter="label"},
    {pattern="keybind", prefix="Keybind", counter="keybind"},
    {pattern="colorpicker", prefix="ColorPicker", counter="colorpicker"},
    {pattern="paragraph", prefix="Paragraph", counter="paragraph"},
    {pattern="notification", prefix="Notification", counter="notification"},
}

local uiCounters = {}
local function getUICount(key) uiCounters[key]=(uiCounters[key] or 0)+1; return uiCounters[key] end

local function heuristicName(baseName, methodName)
    if not baseName then baseName="var" end
    local str = safeTostring(baseName)
    if ServiceShortNames[str] then return ServiceShortNames[str] end
    if methodName then
        local lower = methodName:lower()
        for _, pat in _ipairs(UIPatterns) do
            if lower:find(pat.pattern) then
                local c=getUICount(pat.counter)
                return c==1 and pat.prefix or pat.prefix..c
            end
        end
    end
    if str=="LocalPlayer" or str=="Character" or str=="Humanoid" or str=="HumanoidRootPart" or str=="Camera" then
        return str
    end
    local cleaned = str:gsub("[^%w_]", ""):gsub("^%d+", "")
    if cleaned=="" or cleaned=="Object" or cleaned=="Value" or cleaned=="result" then cleaned="var" end
    return cleaned
end

-- ==================== VARIABLE NAMING (Hybrid) ====================
local varId = -1
local function GetVar()
    varId = varId + 1
    return "r"..varId
end

local function GetCount(base)
    State.Usages[base] = (State.Usages[base] or -1) + 1
    local use = State.Usages[base]
    if use==0 then return base end
    return base.."_"..use
end

local function registerVar(obj, name, typ)
    if not name then name=GetVar() end
    -- ensure unique
    local base=name
    local count=0
    while State.names_used[name] do
        count=count+1
        name=base.."_"..count
    end
    State.names_used[name]=true
    State.registry[obj]=name
    State.reverse_registry[name]=obj
    State.Variables[obj]=name
    State.ReverseVariables[name]=obj
    if typ then State.Types[obj]=typ; State.variable_types[name]=typ end
    return name
end

-- ==================== PROXY FACTORY (Ultimate Hybrid) ====================
local function createProxy(name, parent, isService)
    local proxy, mt = {}, {}
    weakProxies[proxy]=true
    local varName = registerVar(proxy, name)
    
    -- Property store for fake instance properties
    State.property_store[proxy] = State.property_store[proxy] or {}
    
    if parent then State.parent_map[proxy]=parent end

    -- Method hooks table (combined from both loggers)
    local methodHooks = {}

    -- Larry's comprehensive hooks
    methodHooks.GetService = function(self, serviceName)
        local sName = safeTostring(serviceName)
        local obj = createProxy(sName, proxy)
        local short = ServiceShortNames[sName] or sName
        if not State.names_used[short] then
            State.registry[obj]=short
            State.names_used[short]=true
        end
        emit(string.format("local %s = %s:GetService(%q)", State.registry[obj], State.registry[proxy] or varName, sName))
        return obj
    end

    methodHooks.WaitForChild = function(self, childName, timeout)
        local cName = safeTostring(childName)
        local obj = createProxy(cName, proxy)
        local v = State.registry[obj]
        if timeout then emit(string.format("local %s = %s:WaitForChild(%q, %s)", v, State.registry[proxy] or varName, cName, toCode(timeout)))
        else emit(string.format("local %s = %s:WaitForChild(%q)", v, State.registry[proxy] or varName, cName)) end
        return obj
    end

    methodHooks.FindFirstChild = function(self, childName, recursive)
        local cName = safeTostring(childName)
        local obj = createProxy(cName, proxy)
        local v = State.registry[obj]
        if recursive then emit(string.format("local %s = %s:FindFirstChild(%q, true)", v, State.registry[proxy] or varName, cName))
        else emit(string.format("local %s = %s:FindFirstChild(%q)", v, State.registry[proxy] or varName, cName)) end
        return obj
    end

    methodHooks.GetChildren = function(self)
        emit(string.format("for _, child in %s:GetChildren() do", State.registry[proxy] or varName))
        State.indent = State.indent + 1
        State.pending_iterator = true
        return {}
    end

    methodHooks.GetDescendants = function(self)
        emit(string.format("for _, obj in %s:GetDescendants() do", State.registry[proxy] or varName))
        State.indent = State.indent + 1
        local child = createProxy("obj", proxy)
        State.registry[child]="obj"
        return function() return nil end, nil, 0
    end

    methodHooks.Clone = function(self)
        local clone = createProxy((State.registry[proxy] or varName).."Clone", proxy)
        emit(string.format("local %s = %s:Clone()", State.registry[clone], State.registry[proxy] or varName))
        return clone
    end

    methodHooks.Destroy = function(self) emit(string.format("%s:Destroy()", State.registry[proxy] or varName)) end

    -- Signal hooks (Larry)
    local function createSignal(signalName)
        local sigProxy, sigMt = {}, {}
        weakProxies[sigProxy]=true
        local fullName = (State.registry[proxy] or varName).."."..signalName
        State.registry[sigProxy]=fullName
        sigMt.__index = function(_, k)
            if k=="Connect" or k=="connect" then
                return function(_, callback)
                    local conn = createProxy("connection", sigProxy)
                    local connName = registerVar(conn, "conn")
                    -- Determine args based on signal name
                    local argsMap = {
                        InputBegan={"input","gameProcessed"}, InputEnded={"input","gameProcessed"},
                        CharacterAdded={"character"}, PlayerAdded={"player"}, Touched={"hit"},
                        Heartbeat={"deltaTime"}, RenderStepped={"deltaTime"}, Stepped={"time","deltaTime"},
                        Changed={"property"}, ChildAdded={"child"}, Died={}, MouseButton1Click={},
                        FocusLost={"enterPressed","inputObject"}
                    }
                    local args = argsMap[signalName] or {"..."}
                    emit(string.format("local %s = %s:Connect(function(%s)", connName, fullName, table.concat(args, ", ")))
                    State.indent = State.indent + 1
                    if _type(callback)=="function" then _pcall(callback) end
                    while State.pending_iterator do State.indent=State.indent-1; emit("end"); State.pending_iterator=false end
                    State.indent = State.indent - 1
                    emit("end)")
                    return conn
                end
            elseif k=="Wait" then
                return function(_)
                    local res = createProxy("waitResult", sigProxy)
                    local rName = registerVar(res, "waitResult")
                    emit(string.format("local %s = %s:Wait()", rName, fullName))
                    return res
                end
            elseif k=="Once" then
                return function(_, cb)
                    local conn = createProxy("connection", sigProxy)
                    local connName = registerVar(conn, "conn")
                    emit(string.format("local %s = %s:Once(function(...)", connName, fullName))
                    State.indent=State.indent+1
                    if _type(cb)=="function" then _pcall(cb) end
                    State.indent=State.indent-1
                    emit("end)")
                    return conn
                end
            end
            return createProxy(k, sigProxy)
        end
        sigMt.__tostring = function() return fullName end
        _setmetatable(sigProxy, sigMt)
        return sigProxy
    end

    -- Main's method hooks (Instance methods)
    methodHooks.GetAttribute = function(self, attr) return nil end
    methodHooks.SetAttribute = function(self, attr, val)
        emit(string.format("%s:SetAttribute(%q, %s)", State.registry[proxy] or varName, safeTostring(attr), toCode(val)))
    end
    methodHooks.IsA = function() return true end
    methodHooks.FindFirstChildOfClass = methodHooks.FindFirstChild
    methodHooks.FindFirstChildWhichIsA = methodHooks.FindFirstChild
    methodHooks.WaitForChild = methodHooks.WaitForChild

    -- Remote hooks
    methodHooks.FireServer = function(self, ...)
        local args={...}
        local codeArgs={}
        for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
        emit(string.format("%s:FireServer(%s)", State.registry[proxy] or varName, table.concat(codeArgs, ", ")))
        table.insert(State.call_graph, {type="RemoteEvent", name=State.registry[proxy] or varName, args=args})
    end

    methodHooks.InvokeServer = function(self, ...)
        local args={...}
        local codeArgs={}
        for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
        local res=createProxy("invokeResult", proxy)
        local rName=registerVar(res, "result")
        emit(string.format("local %s = %s:InvokeServer(%s)", rName, State.registry[proxy] or varName, table.concat(codeArgs, ", ")))
        table.insert(State.call_graph, {type="RemoteFunction", name=State.registry[proxy] or varName, args=args})
        return res
    end

    -- Tween hooks
    methodHooks.Create = function(self, inst, info, props)
        local tween=createProxy("tween", proxy)
        local tName=registerVar(tween, "tween")
        emit(string.format("local %s = %s:Create(%s, %s, %s)", tName, State.registry[proxy] or varName, toCode(inst), toCode(info), toCode(props)))
        return tween
    end
    methodHooks.Play = function(self) emit(string.format("%s:Play()", State.registry[proxy] or varName)) end
    methodHooks.Pause = function(self) emit(string.format("%s:Pause()", State.registry[proxy] or varName)) end
    methodHooks.Cancel = function(self) emit(string.format("%s:Cancel()", State.registry[proxy] or varName)) end

    -- __index metamethod - HYBRID LOGIC
    mt.__index = function(_, key)
        if key==tobitKey or key=="__value" or key=="__proxy_id" then return _rawget(proxy, key) end
        local keyStr = safeTostring(key)
        
        -- Check property store first
        if State.property_store[proxy] and State.property_store[proxy][key] ~= nil then
            return State.property_store[proxy][key]
        end

        -- Check method hooks
        if methodHooks[keyStr] then
            local hookProxy, hookMt = {}, {}
            weakProxies[hookProxy]=true
            local full = (State.registry[proxy] or varName).."."..keyStr
            State.registry[hookProxy]=full
            hookMt.__call = function(_, ...)
                local args={...}
                -- remove self if first arg is proxy itself
                if #args>0 and args[1]==proxy then table.remove(args,1) end
                return methodHooks[keyStr](proxy, table.unpack(args))
            end
            hookMt.__tostring = function() return full end
            hookMt.__index = function(_, k) return createProxy(k, hookProxy) end
            _setmetatable(hookProxy, hookMt)
            return hookProxy
        end

        -- Signal detection (list from Larry)
        local signals = {"Changed","ChildAdded","ChildRemoved","DescendantAdded","DescendantRemoving","Touched","InputBegan","InputEnded","MouseButton1Click","Activated","Heartbeat","RenderStepped","Stepped","CharacterAdded","PlayerAdded","Died","HealthChanged","OnClientEvent","OnServerEvent","Completed"}
        for _, sig in _ipairs(signals) do
            if keyStr==sig then
                return createSignal(sig)
            end
        end

        -- Special properties (from both)
        if keyStr=="Parent" then return State.parent_map[proxy] or createProxy("Parent", proxy) end
        if keyStr=="Name" then return State.registry[proxy] or varName end
        if keyStr=="ClassName" then return varName end
        if keyStr=="LocalPlayer" then
            local lp=createProxy("LocalPlayer", proxy)
            local lpName=registerVar(lp, "LocalPlayer")
            emit(string.format("local %s = %s.LocalPlayer", lpName, State.registry[proxy] or varName))
            return lp
        end
        if keyStr=="Humanoid" or keyStr=="HumanoidRootPart" or keyStr=="PrimaryPart" then
            local h=createProxy(keyStr, proxy)
            State.property_store[h]={Health=100, MaxHealth=100, WalkSpeed=16}
            return h
        end
        if keyStr=="CurrentCamera" or keyStr=="Camera" then
            local cam=createProxy("Camera", proxy)
            State.property_store[cam]={CFrame="CFrame.new(0,10,0)", FieldOfView=70}
            return cam
        end
        if keyStr=="PlaceId" or keyStr=="GameId" then return 123456789 end
        if keyStr=="UserId" then return 1 end
        if keyStr=="DisplayName" then return "Player" end
        if keyStr=="Value" or keyStr=="Text" then return "" end

        -- Default: create new proxy with heuristic naming
        local heuristic = heuristicName(keyStr, keyStr)
        local newProxy = createProxy(heuristic, proxy)
        -- Preserve original key for output readability
        if not State.names_used[heuristic] then
            -- already handled in createProxy
        end
        return newProxy
    end

    mt.__newindex = function(_, key, value)
        local keyStr=safeTostring(key)
        State.property_store[proxy]=State.property_store[proxy] or {}
        State.property_store[proxy][key]=value
        if key=="Parent" and isProxy(value) then State.parent_map[proxy]=value end
        emit(string.format("%s.%s = %s", State.registry[proxy] or varName, keyStr, toCode(value)))
    end

    mt.__call = function(_, ...)
        local args={...}
        local codeArgs={}
        for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
        local res=createProxy("result", proxy)
        local rName=registerVar(res, "result")
        emit(string.format("local %s = %s(%s)", rName, State.registry[proxy] or varName, table.concat(codeArgs, ", ")))
        return res
    end

    mt.__tostring = function() return State.registry[proxy] or varName end
    mt.__concat = function(a,b) return safeTostring(a)..safeTostring(b) end
    mt.__add = function(a,b) return getTobitValue(a)+getTobitValue(b) end
    mt.__sub = function(a,b) return getTobitValue(a)-getTobitValue(b) end
    mt.__mul = function(a,b) return getTobitValue(a)*getTobitValue(b) end
    mt.__div = function(a,b) local bv=getTobitValue(b); return bv~=0 and getTobitValue(a)/bv or 0 end

    _setmetatable(proxy, mt)
    return proxy
end

-- ==================== DATATYPE FACTORIES (Larry + Main) ====================
local function createDataTypeFactory(typeName, methods)
    local factory = {}
    local mt = {}
    mt.__index = function(_, k)
        if k=="new" or (methods and methods[k]) then
            return function(...)
                local args={...}
                local codeArgs={}
                for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
                local obj=createProxy(typeName, nil)
                local oName=registerVar(obj, typeName:lower())
                emit(string.format("local %s = %s.new(%s)", oName, typeName, table.concat(codeArgs, ", ")))
                return obj
            end
        end
        return nil
    end
    mt.__call = function(_, ...) return factory.new(...) end
    _setmetatable(factory, mt)
    return factory
end

Vector3 = createDataTypeFactory("Vector3", {new=true, zero=true, one=true})
Vector2 = createDataTypeFactory("Vector2", {new=true, zero=true, one=true})
CFrame = createDataTypeFactory("CFrame", {new=true, Angles=true, lookAt=true, fromEulerAnglesXYZ=true})
Color3 = createDataTypeFactory("Color3", {new=true, fromRGB=true, fromHSV=true, fromHex=true})
UDim = createDataTypeFactory("UDim", {new=true})
UDim2 = createDataTypeFactory("UDim2", {new=true, fromScale=true, fromOffset=true})
BrickColor = createDataTypeFactory("BrickColor", {new=true, random=true})
TweenInfo = createDataTypeFactory("TweenInfo", {new=true})
Rect = createDataTypeFactory("Rect", {new=true})
Ray = createDataTypeFactory("Ray", {new=true})
NumberRange = createDataTypeFactory("NumberRange", {new=true})
NumberSequence = createDataTypeFactory("NumberSequence", {new=true})
ColorSequence = createDataTypeFactory("ColorSequence", {new=true})
PhysicalProperties = createDataTypeFactory("PhysicalProperties", {new=true})
RaycastParams = createDataTypeFactory("RaycastParams", {new=true})
OverlapParams = createDataTypeFactory("OverlapParams", {new=true})
Font = createDataTypeFactory("Font", {new=true, fromEnum=true})

-- Random
Random = {new=function(seed)
    local r={}
    function r:NextNumber(a,b) return (a or 0)+0.5*((b or 1)-(a or 0)) end
    function r:NextInteger(a,b) return math.floor((a or 1)+0.5*((b or 100)-(a or 1))) end
    function r:NextUnitVector() return Vector3.new(0.577,0.577,0.577) end
    function r:Shuffle(t) return t end
    function r:Clone() return Random.new() end
    return r
end}
setmetatable(Random, {__call=function(_,s) return Random.new(s) end})

-- Enum
local function createEnum()
    local e=createProxy("Enum", nil)
    local mt=_getmetatable(e)
    local oldIndex=mt.__index
    mt.__index=function(_, k)
        if k==tobitKey or k=="__value" then return _rawget(e,k) end
        local enumItem=createProxy("Enum."..safeTostring(k), e)
        State.registry[enumItem]="Enum."..safeTostring(k)
        return enumItem
    end
    return e
end
Enum = createEnum()

-- ==================== INSTANCE & SERVICES ====================
local function createRootEnvironment()
    local gameProxy=createProxy("game", nil)
    State.registry[gameProxy]="game"
    State.names_used["game"]=true
    State.property_store[gameProxy]={PlaceId=123456789, GameId=123456789}
    
    local workspaceProxy=createProxy("workspace", nil)
    State.registry[workspaceProxy]="workspace"
    State.names_used["workspace"]=true
    
    local scriptProxy=createProxy("script", nil)
    State.registry[scriptProxy]="script"
    State.property_store[scriptProxy]={Name="DumpedScript", ClassName="LocalScript"}
    
    return gameProxy, workspaceProxy, scriptProxy
end

-- ==================== EXPLOIT FUNCS (Combined) ====================
local exploit_funcs = {}

exploit_funcs.getgenv = function()
    local env=createProxy("getgenv", nil)
    State.registry[env]="getgenv()"
    return env
end

exploit_funcs.getrenv = function() return createProxy("getrenv", nil) end
exploit_funcs.getfenv = function() return _G end
exploit_funcs.setfenv = function(f, env) return f end

exploit_funcs.hookfunction = function(a,b) return a end
exploit_funcs.hookmetamethod = function(a,b,c) return function() end end
exploit_funcs.newcclosure = function(f) return f end
exploit_funcs.clonefunction = function(f) return f end
exploit_funcs.iscclosure = function() return false end
exploit_funcs.islclosure = function(f) return _type(f)=="function" end
exploit_funcs.checkcaller = function() return true end

exploit_funcs.request = function(opts)
    local url = opts.Url or opts.url or "unknown"
    emit(string.format("request({Url=%q})", url))
    table.insert(State.string_refs, {value=url, hint="HTTP Request"})
    return {Success=true, StatusCode=200, Body="{}"}
end
exploit_funcs.http_request = exploit_funcs.request
exploit_funcs.syn = {request=exploit_funcs.request}
exploit_funcs.http = {request=exploit_funcs.request}

exploit_funcs.setclipboard = function(s) emit(string.format("setclipboard(%s)", toCode(s))) end
exploit_funcs.getclipboard = function() return "" end
exploit_funcs.identifyexecutor = function() return "UltimateLogger", "2.0" end
exploit_funcs.getexecutorname = function() return "UltimateLogger" end

exploit_funcs.gethui = function()
    local h=createProxy("HiddenUI", nil)
    local hName=registerVar(h, "HiddenUI")
    emit(string.format("local %s = gethui()", hName))
    return h
end
exploit_funcs.gethiddenui = exploit_funcs.gethui

exploit_funcs.Drawing = {new=function(t)
    local d=createProxy("Drawing_"..safeTostring(t), nil)
    local dName=registerVar(d, safeTostring(t))
    emit(string.format("local %s = Drawing.new(%q)", dName, safeTostring(t)))
    return d
end, Fonts=createProxy("Drawing.Fonts", nil)}

exploit_funcs.crypt = {
    base64encode=function(s) return s end, base64decode=function(s) return s end,
    encrypt=function(s,k) return s end, decrypt=function(s,k) return s end,
    hash=function(s) return "hash" end, generatekey=function(l) return string.rep("0", l or 32) end
}

exploit_funcs.base64_encode = function(s) return s end
exploit_funcs.base64_decode = function(s) return s end

exploit_funcs.readfile = function(p) emit(string.format("readfile(%q)", p)); return "" end
exploit_funcs.writefile = function(p,c) emit(string.format("writefile(%q, %s)", p, toCode(c))) end
exploit_funcs.isfile = function() return false end
exploit_funcs.isfolder = function() return false end
exploit_funcs.makefolder = function(p) emit(string.format("makefolder(%q)", p)) end
exploit_funcs.listfiles = function() return {} end

exploit_funcs.queue_on_teleport = function(s) emit(string.format("queue_on_teleport(%s)", toCode(s))) end
exploit_funcs.queueonteleport = exploit_funcs.queue_on_teleport

exploit_funcs.setfpscap = function(c) emit(string.format("setfpscap(%s)", toCode(c))) end
exploit_funcs.getfpscap = function() return 60 end

-- ==================== TASK LIB (Hybrid) ====================
local taskLib = {}
taskLib.wait = function(t)
    if t then emit(string.format("task.wait(%s)", toCode(t))) else emit("task.wait()") end
    return t or 0.03
end
taskLib.spawn = function(f, ...)
    emit("task.spawn(function()")
    State.indent=State.indent+1
    if _type(f)=="function" then _pcall(f, ...) end
    while State.pending_iterator do State.indent=State.indent-1; emit("end"); State.pending_iterator=false end
    State.indent=State.indent-1
    emit("end)")
end
taskLib.delay = function(t,f,...)
    emit(string.format("task.delay(%s, function()", toCode(t or 0)))
    State.indent=State.indent+1
    if _type(f)=="function" then _pcall(f, ...) end
    State.indent=State.indent-1
    emit("end)")
end
taskLib.defer = taskLib.spawn

-- ==================== LURAPH DECOMPRESSION (from main) ====================
local LURAPH_MARKER = "does your environment support load/loadstring?"
local function DecompressLuraph(code, depth)
    depth=depth or 0
    if depth>4 then return nil end
    local captured={}
    local function Capture(chunk)
        if _type(chunk)=="string" then table.insert(captured, chunk) end
        return function() end
    end
    local sandbox=setmetatable({loadstring=Capture, load=Capture}, {__index=_G})
    local fn, err = _loadstring(code, "luraph_decompress")
    if not fn then return nil end
    if setfenv then pcall(setfenv, fn, sandbox) end
    pcall(fn)
    local best, bestLen = nil, 0
    for _, chunk in _ipairs(captured) do
        if #chunk>bestLen then
            local ok, compiled = _pcall(function()
                if has_lune then return luau.compile(chunk) else return chunk end
            end)
            if ok then best, bestLen = chunk, #chunk end
        end
    end
    if not best then return nil end
    if best:find(LURAPH_MARKER,1,true) then
        return DecompressLuraph(best, depth+1) or best
    end
    return best
end

-- ==================== HOOKOP INTEGRATION (from main) ====================
local function TryHookOp(code, filePath)
    if not CONFIG.HOOKOP_ENABLED then return false, code end
    if not has_lune then return false, code end
    local hookFile = filePath
    local tempIn = nil
    if not hookFile then
        tempIn = "./.tmp_hookop_in.lua"
        fs.writeFile(tempIn, code)
        hookFile = tempIn
    end
    local outPath = hookFile.."-unparsed.lua"
    local scriptPath = "mods/hookOp.luau"
    if not fs.isFile(scriptPath) then
        scriptPath = "mods/hookOpButNotReally.luau"
        if not fs.isFile(scriptPath) then
            if tempIn then pcall(fs.removeFile, tempIn) end
            return false, code
        end
    end
    local args = {scriptPath, hookFile, outPath, "0", "1", tostring(CONFIG.WHILE_LIMIT)}
    local ok, result = _pcall(function()
        local proc = process.spawn("lune", {"run", table.unpack(args)})
        return proc
    end)
    if tempIn then pcall(fs.removeFile, tempIn) end
    if not ok or result.code~=0 then return false, code end
    if fs.isFile(outPath) then
        local content = fs.readFile(outPath)
        pcall(fs.removeFile, outPath)
        return true, content
    end
    return false, code
end

-- ==================== MAIN DUMP LOGIC ====================
local function resetState()
    State.output={}
    State.indent=0
    State.registry={}
    State.reverse_registry={}
    State.names_used={}
    State.parent_map={}
    State.property_store={}
    State.call_graph={}
    State.string_refs={}
    State.variable_types={}
    State.proxy_id=0
    State.callback_depth=0
    State.pending_iterator=false
    State.last_http_url=nil
    State.last_emitted_line=nil
    State.repetition_count=0
    State.current_size=0
    State.limit_reached=false
    State.lar_counter=0
    State.Variables={}
    State.ReverseVariables={}
    State.Internal={}
    State.Usages={}
    State.Information={}
    State.Types={}
    State.Functions={}
    State.CClosures={}
    State.Strings={}
    State.ConstantList={}
    State.captured_constants={}
    varId=-1
    uiCounters={}
end

local function sanitizeCode(code)
    -- Remove binary literals, handle Luau specifics (from Larry I function simplified)
    if _type(code)~="string" then return "" end
    -- Basic cleanup: remove null bytes, etc
    code = code:gsub("\0", "")
    return code
end

local function dumpString(code, outputPath)
    resetState()
    emit("-- this file is generated using Ultimate EnvLogger v2 (Combined main + Larry)")
    emit("-- TraceId: "..TraceId.." HWID: "..HardwareId)
    emitBlank()
    
    -- Luraph decompress check
    if CONFIG.LURAPH_DECOMPRESS and code:find(LURAPH_MARKER,1,true) then
        local decompressed = DecompressLuraph(code)
        if decompressed then
            emit(string.format("-- [Luraph] Decompressed %d -> %d bytes", #code, #decompressed))
            code = decompressed
        else
            emit("-- [Luraph] Decompression failed, continuing with original")
        end
    end

    -- HookOp try
    if CONFIG.HOOKOP_ENABLED then
        local ok, hooked = TryHookOp(code, nil)
        if ok then
            emit("-- [HookOp] Successfully deobfuscated control flow")
            code = hooked
        end
    end

    code = sanitizeCode(code)

    -- Setup environment
    local gameProxy, workspaceProxy, scriptProxy = createRootEnvironment()
    
    -- Create global env with all proxies
    local env = setmetatable({
        game=gameProxy, Game=gameProxy,
        workspace=workspaceProxy, Workspace=workspaceProxy,
        script=scriptProxy,
        Enum=Enum,
        Vector3=Vector3, Vector2=Vector2, CFrame=CFrame, Color3=Color3,
        UDim=UDim, UDim2=UDim2, BrickColor=BrickColor, TweenInfo=TweenInfo,
        Rect=Rect, Ray=Ray, Random=Random, Font=Font,
        RaycastParams=RaycastParams, OverlapParams=OverlapParams,
        task=taskLib, wait=taskLib.wait, spawn=taskLib.spawn, delay=taskLib.delay,
        tick=function() return os.time() end, time=function() return os.clock() end,
        print=function(...) emit(string.format("print(%s)", table.concat((function(...)
            local t={...}; local r={}; for _,v in _ipairs(t) do table.insert(r, toCode(v)) end; return r
        end)(...), ", "))) end,
        warn=function(...) emit(string.format("warn(%s)", table.concat((function(...)
            local t={...}; local r={}; for _,v in _ipairs(t) do table.insert(r, toCode(v)) end; return r
        end)(...), ", "))) end,
        -- Exploit funcs
        getgenv=exploit_funcs.getgenv, getrenv=exploit_funcs.getrenv,
        gethui=exploit_funcs.gethui, gethiddenui=exploit_funcs.gethiddenui,
        request=exploit_funcs.request, http_request=exploit_funcs.request,
        Drawing=exploit_funcs.Drawing, crypt=exploit_funcs.crypt,
        readfile=exploit_funcs.readfile, writefile=exploit_funcs.writefile,
        queue_on_teleport=exploit_funcs.queue_on_teleport,
        setfpscap=exploit_funcs.setfpscap,
        -- Bit
        bit={band=function(a,b) return a & b end, bor=function(a,b) return a | b end, bxor=function(a,b) return a ~ b end},
        bit32={band=function(a,b) return a & b end, bor=function(a,b) return a | b end, bxor=function(a,b) return a ~ b end},
        -- Standard libs
        math=math, table=table, string=string, os=os, coroutine=coroutine,
        pairs=function(t)
            if isProxy(t) then return function() return nil end, t, nil end
            return _pairs(t)
        end,
        ipairs=function(t)
            if isProxy(t) then return function() return nil end, t, 0 end
            return _ipairs(t)
        end,
        type=function(x)
            if isTobitProxy(x) then return "number" end
            if isProxy(x) then
                local name=State.registry[x] or ""
                if name:match("Vector3") then return "Vector3" end
                if name:match("CFrame") then return "CFrame" end
                if name:match("Color3") then return "Color3" end
                if name:match("Enum") then return "EnumItem" end
                return "Instance"
            end
            return _type(x)
        end,
        typeof=function(x)
            if isTobitProxy(x) then return "number" end
            if isProxy(x) then
                local name=State.registry[x] or ""
                if name:match("Vector3") then return "Vector3" end
                if name:match("CFrame") then return "CFrame" end
                if name:match("Color3") then return "Color3" end
                if name:match("Enum") then return "EnumItem" end
                return "Instance"
            end
            return _type(x)=="table" and "table" or _type(x)
        end,
        tostring=function(x)
            if isProxy(x) then return State.registry[x] or "Instance" end
            return _tostring(x)
        end,
        loadstring=function(str)
            if _type(str)=="string" then
                -- Library detection (Larry feature)
                local lower=str:lower()
                local libs={"rayfield","orion","kavo","venyx","sirius","linoria","wally","dex","infinite","hydroxide"}
                for _, lib in _ipairs(libs) do
                    if lower:find(lib) then
                        emit(string.format("-- [Library Detected] %s in loadstring", lib))
                        break
                    end
                end
                -- URL detection
                local url=str:match("https?://[%w%p]+")
                if url then
                    table.insert(State.string_refs, {value=url, hint="URL in loadstring"})
                    State.last_http_url=url
                    emit(string.format("-- [HttpGet] %s", url))
                end
            end
            return _loadstring(str)
        end,
    }, {__index=_G})

    -- Add exploit funcs to env
    for k,v in _pairs(exploit_funcs) do if not env[k] then env[k]=v end end

    -- Load and execute with timeout
    local fn, loadErr = _loadstring(code, "Obfuscated_Script")
    if not fn then
        emit("-- [Load Error] "..safeTostring(loadErr))
        if outputPath then saveOutput(outputPath) end
        return false, loadErr
    end

    if setfenv then setfenv(fn, env) end

    local startClock = _os.clock()
    local timeoutHook = function()
        if _os.clock() - startClock > CONFIG.TIMEOUT_SECONDS then
            error("TIMEOUT_FORCED_BY_DUMPER")
        end
    end

    local hookOk = _pcall(function() _debug.sethook(timeoutHook, "", 1000) end)

    local success, execErr = _xpcall(function() fn() end, function(err) return _tostring(err) end)

    if hookOk then _pcall(function() _debug.sethook() end) end

    if not success then
        emit("-- [Terminated] "..safeTostring(execErr))
    end

    -- Emit summary
    emitBlank()
    emit("-- ==================== DUMP SUMMARY ====================")
    emit(string.format("-- Lines: %d", #State.output))
    emit(string.format("-- Remote Calls: %d", #State.call_graph))
    emit(string.format("-- Suspicious Strings: %d", #State.string_refs))
    emit(string.format("-- Proxies Created: %d", State.proxy_id))
    if #State.string_refs>0 then
        emit("-- String Refs:")
        for _, ref in _ipairs(State.string_refs) do
            emit(string.format("--   [%s] %s", ref.hint or "?", ref.value:sub(1,100)))
        end
    end
    if #State.call_graph>0 then
        emit("-- Call Graph:")
        for _, call in _ipairs(State.call_graph) do
            emit(string.format("--   [%s] %s", call.type, call.name))
        end
    end

    if outputPath then
        saveOutput(outputPath)
        return true
    end
    return true, getOutput()
end

local function dumpFile(inputPath, outputPath)
    local content
    if has_lune then
        if not fs.isFile(inputPath) then return false end
        content = fs.readFile(inputPath)
    else
        local f=_io.open(inputPath, "rb")
        if not f then return false end
        content=f:read("*a")
        f:close()
    end
    return dumpString(content, outputPath or CONFIG.OUTPUT_FILE)
end

-- ==================== ENTRY POINT ====================
local q = {
    reset=resetState,
    dump_string=dumpString,
    dump_file=dumpFile,
    get_output=getOutput,
    save=saveOutput,
    get_call_graph=function() return State.call_graph end,
    get_string_refs=function() return State.string_refs end,
    get_stats=function()
        return {
            total_lines=#State.output,
            remote_calls=#State.call_graph,
            suspicious_strings=#State.string_refs,
            proxies_created=State.proxy_id
        }
    end,
    config=CONFIG,
}

if has_lune then
    -- Lune mode: check args
    if process.args[1] then
        local input = process.args[1]
        local output = process.args[2] or CONFIG.OUTPUT_FILE
        _print("[UltimateLogger] Dumping "..input.." -> "..output)
        local ok = dumpFile(input, output)
        if ok then
            _print("[UltimateLogger] Saved to "..output)
            local stats=q.get_stats()
            _print(string.format("Lines: %d | Remotes: %d | Strings: %d", stats.total_lines, stats.remote_calls, stats.suspicious_strings))
        end
    end
else
    -- Standard Lua mode
    if arg and arg[1] then
        local ok = dumpFile(arg[1], arg[2])
        if ok then
            _print("Saved to: "..(arg[2] or CONFIG.OUTPUT_FILE))
            local stats=q.get_stats()
            _print(string.format("Lines: %d | Remotes: %d | Strings: %d", stats.total_lines, stats.remote_calls, stats.suspicious_strings))
        end
    end
end

_G.LuraphContinue = function() end
return q


-- ==================== ALL-IN-ONE ENHANCEMENTS (52KB) ====================
--!nonstrict
-- ============================================================================
-- ALL-IN-ONE ENVLOGGER - Envlog9ms Ultimate v3
-- รวมทุกระบบในไฟล์เดียว (100% Standalone)
-- 
-- รวมจาก:
-- 1. main.lua (5895 lines) - AST Logger, HookOp, Luraph, InstanceLib, Type tracking, Garbage filter, pcall exploration
-- 2. envlogger.lua Larry (3324 lines) - Proxy, 50+ hooks, CallGraph, StringRefs, UI heuristics, Library detection, Drawing/crypt
-- 3. ultimate_envlogger.lua (1228 lines) - Hybrid rewrite
--
-- Features ทั้งหมดในไฟล์เดียว:
-- ✅ Luraph decompression (capture loadstring)
-- ✅ HookOp control flow deobfuscation
-- ✅ AST-style code generation + repetition suppression + 10MB limit
-- ✅ Instance emulation full (Services, Parent/Children, Attributes, Signals)
-- ✅ 60+ method hooks: GetService, WaitForChild, FindFirstChild, GetChildren, GetDescendants, Clone, Destroy, Connect, Once, Wait, FireServer, InvokeServer, Tween, Raycast, GetMouse, Kick, etc
-- ✅ Proxy weak table + tobit number anti-tamper (Larry)
-- ✅ StringRefs: URL, base64, rbxasset, suspicious
-- ✅ CallGraph: RemoteEvent/RemoteFunction/GetService/HttpGet
-- ✅ UI naming heuristics: Window/Tab/Section/Button/Toggle/Slider/Dropdown/Textbox/Keybind/ColorPicker...
-- ✅ Library detection: Rayfield/Orion/Kavo/Venyx/Sirius/Linoria/Wally/Dex/InfiniteYield/Hydroxide
-- ✅ Exploit funcs: Drawing, crypt, base64, request/http_request, setclipboard, queue_on_teleport, setfpscap, gethui, getgenv, hookfunction...
-- ✅ Task lib: task.wait/spawn/delay/defer + wait/spawn/delay legacy
-- ✅ Bit/bit32 full (band/bor/bxor/lshift/rshift + tobit/rol/ror/bswap)
-- ✅ Datatypes: Vector3/Vector2/CFrame/Color3/UDim/UDim2/BrickColor/TweenInfo/Ray/RaycastParams/OverlapParams/Font/Random/Enum...
-- ✅ Garbage string filter + type tracking + variable usage tracking
-- ✅ Function exploration (pcall deep dive)
-- ✅ Works: Lune, Standard Lua 5.1/5.4, Luau, Roblox executor, Vercel (via wrapper)
-- ============================================================================

local CONFIG = {
    MAX_DEPTH = 15,
    MAX_TABLE_ITEMS = 150,
    OUTPUT_FILE = "dumped_output.lua",
    VERBOSE = false,
    TRACE_CALLBACKS = true,
    TIMEOUT_SECONDS = 12,
    MAX_REPEATED_LINES = 6,
    MIN_DEOBF_LENGTH = 150,
    MAX_OUTPUT_SIZE = 15 * 1024 * 1024,
    CONSTANT_COLLECTION = true,
    INSTRUMENT_LOGIC = true,
    WHILE_LIMIT = 50_000_000,
    DONT_DELETE_FILES = false,
    HOOKOP_ENABLED = true,
    LURAPH_DECOMPRESS = true,
    ROBLOX_EMULATION = true,
    EXPLOIT_EMULATION = true,
    GARBAGE_FILTER = true,
}

-- Detect runtime
local has_lune, fs, process, serde, task_mod, stdio, luau = false
pcall(function()
    fs = require("@lune/fs")
    process = require("@lune/process")
    serde = require("@lune/serde")
    task_mod = require("@lune/task")
    stdio = require("@lune/stdio")
    luau = require("@lune/luau")
    has_lune = true
end)

local _print, _warn = print, warn or function() end
local _io, _os, _debug = io, os, debug
local _type, _tostring, _tonumber = type, tostring, tonumber
local _pairs, _ipairs = pairs, ipairs
local _load, _loadstring = load, loadstring or load
local _pcall, _xpcall = pcall, xpcall
local _getmetatable, _setmetatable = getmetatable, setmetatable
local _rawget, _rawset, _rawequal = rawget, rawset, rawequal

-- Utils
local Alphabet = {}
for c in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do table.insert(Alphabet,c) end
local function GenId(len)
    len=len or 6
    local t=""
    for i=1,len do t=t..Alphabet[math.random(1,#Alphabet)] end
    return t
end
local TraceId = GenId(6)
local HardwareId = GenId(4).."-"..GenId(4).."-"..GenId(4).."-"..GenId(4)
local function IsWeird(k)
    if k=="" or _type(k)~="string" then return true end
    if tonumber(k:sub(1,1)) then return true end
    return k:match("[^%w_]")~=nil
end
local function IsGarbageString(s)
    if not CONFIG.GARBAGE_FILTER then return false end
    if #s>24 then return true end
    if #s<12 then return false end
    local hasUpper=s:match("[A-Z]")
    local hasLower=s:match("[a-z]")
    return hasUpper and hasLower and s:match("%d") and not s:match("[%W]")
end
local function HideErrors(t)
    if _type(t)~="string" then return _tostring(t) end
    return t:gsub("C:[/\\]+Users[/\\]+.-[\\/]([^\\/]+):(%d+)", "%1:%2")
end

-- State (hybrid main + larry)
local State = {
    output={}, indent=0,
    registry={}, reverse_registry={}, names_used={},
    parent_map={}, property_store={}, call_graph={}, string_refs={}, variable_types={},
    proxy_id=0, callback_depth=0, pending_iterator=false,
    last_http_url=nil, last_emitted_line=nil, repetition_count=0, current_size=0, limit_reached=false, lar_counter=0,
    Variables={}, ReverseVariables={}, Internal={}, Usages={}, Information={}, Types={}, Functions={}, CClosures={},
    Strings={}, ConstantList={}, captured_constants={}, Attributes={}, Children={}, Signals={},
}

local function getIndent() return string.rep("    ", State.indent) end
local function emit(line, noIndent)
    if State.limit_reached then return end
    if line==nil then return end
    local indentStr = noIndent and "" or getIndent()
    local full = indentStr.._tostring(line)
    local sz = #full+1
    if State.current_size+sz > CONFIG.MAX_OUTPUT_SIZE then
        State.limit_reached=true
        local msg=indentStr.."-- [CRITICAL] Dump stopped: size > "..(CONFIG.MAX_OUTPUT_SIZE/1024/1024).."MB"
        table.insert(State.output, msg)
        State.current_size=State.current_size+#msg
        error("DUMP_LIMIT_EXCEEDED")
    end
    if full==State.last_emitted_line then
        State.repetition_count=State.repetition_count+1
        if State.repetition_count<=CONFIG.MAX_REPEATED_LINES then
            table.insert(State.output, full)
            State.current_size=State.current_size+sz
        elseif State.repetition_count==CONFIG.MAX_REPEATED_LINES+1 then
            local sup=indentStr.."-- [Repeated lines suppressed...]"
            table.insert(State.output, sup)
            State.current_size=State.current_size+#sup
        end
    else
        State.last_emitted_line=full
        State.repetition_count=0
        table.insert(State.output, full)
        State.current_size=State.current_size+sz
    end
    if CONFIG.VERBOSE and State.repetition_count<=1 then _print(full) end
end
local function emitComment(c) emit("-- ".._tostring(c)) end
local function emitBlank() table.insert(State.output,"") end
local function getOutput() return table.concat(State.output,"\n") end
local function saveOutput(path)
    if has_lune then fs.writeFile(path or CONFIG.OUTPUT_FILE, getOutput()); return true
    else local f=_io.open(path or CONFIG.OUTPUT_FILE,"w"); if f then f:write(getOutput()); f:close(); return true end end
    return false
end

-- Tobit proxy (Larry)
local tobitKey = {}
local weakProxies = {}
setmetatable(weakProxies,{__mode="k"})
local function isTobitProxy(x)
    if _type(x)~="table" then return false end
    local ok,v=_pcall(function() return _rawget(x,tobitKey)==true end)
    return ok and v
end
local function getTobitValue(x)
    if isTobitProxy(x) then return _rawget(x,"__value") or 0 end
    if _type(x)=="number" then return x end
    return 0
end
local function createTobitProxy(val)
    val=(val or 0)%4294967296
    if val>=2147483648 then val=val-4294967296 end
    val=math.floor(val)
    local proxy, mt = {}, {}
    weakProxies[proxy]=true
    _rawset(proxy,tobitKey,true)
    _rawset(proxy,"__value",val)
    State.registry[proxy]=_tostring(val)
    mt.__tostring=function() return _tostring(val) end
    mt.__index=function(_,k)
        if k==tobitKey or k=="__value" or k=="__proxy_id" then return _rawget(proxy,k) end
        return createTobitProxy(0)
    end
    mt.__newindex=function() end
    mt.__call=function() return val end
    local function mathOp(op)
        return function(a,b)
            local av=_type(a)=="table" and _rawget(a,"__value") or a or 0
            local bv=_type(b)=="table" and _rawget(b,"__value") or b or 0
            local r=0
            if op=="+" then r=av+bv elseif op=="-" then r=av-bv elseif op=="*" then r=av*bv
            elseif op=="/" then r=bv~=0 and av/bv or 0
            elseif op=="%" then r=bv~=0 and av%bv or 0
            elseif op=="^" then r=av^bv else r=0 end
            return createTobitProxy(r)
        end
    end
    mt.__add=mathOp("+"); mt.__sub=mathOp("-"); mt.__mul=mathOp("*"); mt.__div=mathOp("/"); mt.__mod=mathOp("%"); mt.__pow=mathOp("^")
    mt.__unm=function(s) return createTobitProxy(-(_rawget(s,"__value") or 0)) end
    mt.__eq=function(a,b) return (_type(a)=="table" and _rawget(a,"__value") or a)==(_type(b)=="table" and _rawget(b,"__value") or b) end
    mt.__lt=function(a,b) return (_type(a)=="table" and _rawget(a,"__value") or a)<(_type(b)=="table" and _rawget(b,"__value") or b) end
    mt.__le=function(a,b) return (_type(a)=="table" and _rawget(a,"__value") or a)<=(_type(b)=="table" and _rawget(b,"__value") or b) end
    mt.__len=function() return 0 end
    _setmetatable(proxy,mt)
    return proxy
end

-- toCode (hybrid)
local function safeTostring(v)
    local ok,s=_pcall(_tostring,v)
    return ok and s or "unknown"
end
local function isProxy(x) return weakProxies[x]==true or State.Variables[x]~=nil or State.registry[x]~=nil end
local function getVarName(obj) return State.Variables[obj] or State.registry[obj] end
local function toCode(val, depth, seen)
    depth=depth or 0; seen=seen or {}
    if depth>CONFIG.MAX_DEPTH then return "{ --[[max depth]] }" end
    local t=_type(val)
    if isTobitProxy(val) then return _tostring(_rawget(val,"__value") or 0) end
    if t=="table" and State.registry[val] then return State.registry[val] end
    if t=="table" and State.Variables[val] then return State.Variables[val] end
    if t=="nil" then return "nil"
    elseif t=="string" then
        if #val>100 and val:match("^[A-Za-z0-9+/=]+$") then
            table.insert(State.string_refs,{value=val:sub(1,50).."...", hint="base64", full_length=#val})
        elseif val:match("https?://") then
            table.insert(State.string_refs,{value=val, hint="URL"})
        elseif val:match("rbxasset://") or val:match("rbxassetid://") then
            table.insert(State.string_refs,{value=val, hint="Asset"})
        end
        if IsGarbageString(val) then
            return string.format("%q --[[garbage?]]", val)
        end
        return string.format("%q", val)
    elseif t=="number" then
        if val~=val then return "0/0" end
        if val==math.huge then return "math.huge" end
        if val==-math.huge then return "-math.huge" end
        if val==math.floor(val) then return _tostring(math.floor(val)) end
        return string.format("%.6g", val)
    elseif t=="boolean" then return _tostring(val)
    elseif t=="function" then
        if State.registry[val] then return State.registry[val] end
        return "function() end"
    elseif t=="table" then
        if seen[val] then return "{ --[[circular]] }" end
        seen[val]=true
        local count=0
        for k,v in _pairs(val) do if k~=tobitKey and k~="__value" and k~="__proxy_id" then count=count+1 end end
        if count==0 then return "{}" end
        local isArray=true; local max=0
        for k,v in _pairs(val) do
            if k==tobitKey or k=="__value" or k=="__proxy_id" then
            elseif _type(k)~="number" or k<1 or k~=math.floor(k) then isArray=false; break
            else max=math.max(max,k) end
        end
        isArray=isArray and max==count
        if isArray and count<=5 then
            local parts={}
            for i=1,count do table.insert(parts, toCode(val[i], depth+1, seen)) end
            return "{"..table.concat(parts,", ").."}"
        end
        local lines={}
        local indentInner=string.rep("    ", State.indent+depth+1)
        local indentOuter=string.rep("    ", State.indent+depth)
        local i=0
        for k,v in _pairs(val) do
            if k==tobitKey or k=="__value" or k=="__proxy_id" then
            else
                i=i+1
                if i>CONFIG.MAX_TABLE_ITEMS then
                    table.insert(lines, indentInner.."-- ..."..(count-i+1).." more")
                    break
                end
                local keyStr
                if isArray then keyStr=nil
                elseif _type(k)=="string" and k:match("^[%a_][%w_]*$") then keyStr=k
                else keyStr="["..toCode(k,depth+1,seen).."]" end
                local valStr=toCode(v,depth+1,seen)
                if keyStr then table.insert(lines, indentInner..keyStr.." = "..valStr)
                else table.insert(lines, indentInner..valStr) end
            end
        end
        if #lines==0 then return "{}" end
        return "{\n"..table.concat(lines,",\n").."\n"..indentOuter.."}"
    elseif t=="userdata" then
        if State.registry[val] then return State.registry[val] end
        return safeTostring(val)
    else return safeTostring(val) end
end

-- UI heuristics (Larry)
local ServiceShortNames = {
    Players="Players", UserInputService="UIS", RunService="RunService",
    ReplicatedStorage="ReplicatedStorage", TweenService="TweenService",
    Workspace="Workspace", Lighting="Lighting", StarterGui="StarterGui",
    CoreGui="CoreGui", HttpService="HttpService", MarketplaceService="MarketplaceService",
    DataStoreService="DataStoreService", TeleportService="TeleportService",
    SoundService="SoundService", Chat="Chat", Teams="Teams",
    ProximityPromptService="ProximityPromptService", ContextActionService="ContextActionService",
    CollectionService="CollectionService", PathfindingService="PathfindingService", Debris="Debris",
    RunService="RunService", UserInputService="UserInputService"
}
local UIPatterns = {
    {pattern="window", prefix="Window", counter="window"},
    {pattern="tab", prefix="Tab", counter="tab"},
    {pattern="section", prefix="Section", counter="section"},
    {pattern="button", prefix="Button", counter="button"},
    {pattern="toggle", prefix="Toggle", counter="toggle"},
    {pattern="slider", prefix="Slider", counter="slider"},
    {pattern="dropdown", prefix="Dropdown", counter="dropdown"},
    {pattern="textbox", prefix="Textbox", counter="textbox"},
    {pattern="input", prefix="Input", counter="input"},
    {pattern="label", prefix="Label", counter="label"},
    {pattern="keybind", prefix="Keybind", counter="keybind"},
    {pattern="colorpicker", prefix="ColorPicker", counter="colorpicker"},
    {pattern="paragraph", prefix="Paragraph", counter="paragraph"},
    {pattern="notification", prefix="Notification", counter="notification"},
    {pattern="divider", prefix="Divider", counter="divider"},
}
local uiCounters = {}
local function getUICount(k) uiCounters[k]=(uiCounters[k] or 0)+1; return uiCounters[k] end
local function heuristicName(base, method)
    if not base then base="var" end
    local str=safeTostring(base)
    if ServiceShortNames[str] then return ServiceShortNames[str] end
    if method then
        local lower=method:lower()
        for _, pat in _ipairs(UIPatterns) do
            if lower:find(pat.pattern) then
                local c=getUICount(pat.counter)
                return c==1 and pat.prefix or pat.prefix..c
            end
        end
    end
    if str=="LocalPlayer" or str=="Character" or str=="Humanoid" or str=="HumanoidRootPart" or str=="Camera" then return str end
    local cleaned=str:gsub("[^%w_]", ""):gsub("^%d+", "")
    if cleaned=="" or cleaned=="Object" or cleaned=="Value" or cleaned=="result" then cleaned="var" end
    return cleaned
end

-- Variable naming (main)
local varId=-1
local function GetVar() varId=varId+1; return "r"..varId end
local function GetCount(base)
    State.Usages[base]=(State.Usages[base] or -1)+1
    local use=State.Usages[base]
    if use==0 then return base end
    return base.."_"..use
end
local function registerVar(obj, name, typ)
    if not name then name=GetVar() end
    local base=name; local count=0
    while State.names_used[name] do count=count+1; name=base.."_"..count end
    State.names_used[name]=true
    State.registry[obj]=name
    State.reverse_registry[name]=obj
    State.Variables[obj]=name
    State.ReverseVariables[name]=obj
    if typ then State.Types[obj]=typ; State.variable_types[name]=typ end
    return name
end

-- Proxy factory (ultimate hybrid - 60+ hooks)
local function createProxy(name, parent)
    local proxy, mt = {}, {}
    weakProxies[proxy]=true
    local varName=registerVar(proxy, name)
    State.property_store[proxy]=State.property_store[proxy] or {}
    if parent then State.parent_map[proxy]=parent end

    local methodHooks = {}

    -- Core Roblox
    methodHooks.GetService=function(self, serviceName)
        local sName=safeTostring(serviceName)
        local obj=createProxy(sName, proxy)
        local short=ServiceShortNames[sName] or sName
        if not State.names_used[short] then State.registry[obj]=short; State.names_used[short]=true end
        emit(string.format("local %s = %s:GetService(%q)", State.registry[obj], State.registry[proxy] or varName, sName))
        return obj
    end
    methodHooks.WaitForChild=function(self, childName, timeout)
        local cName=safeTostring(childName)
        local obj=createProxy(cName, proxy)
        local v=State.registry[obj]
        if timeout then emit(string.format("local %s = %s:WaitForChild(%q, %s)", v, State.registry[proxy] or varName, cName, toCode(timeout)))
        else emit(string.format("local %s = %s:WaitForChild(%q)", v, State.registry[proxy] or varName, cName)) end
        return obj
    end
    methodHooks.FindFirstChild=function(self, childName, recursive)
        local cName=safeTostring(childName)
        local obj=createProxy(cName, proxy)
        local v=State.registry[obj]
        if recursive then emit(string.format("local %s = %s:FindFirstChild(%q, true)", v, State.registry[proxy] or varName, cName))
        else emit(string.format("local %s = %s:FindFirstChild(%q)", v, State.registry[proxy] or varName, cName)) end
        return obj
    end
    methodHooks.FindFirstChildOfClass=function(self, className)
        local cName=safeTostring(className)
        local obj=createProxy(cName, proxy)
        emit(string.format("local %s = %s:FindFirstChildOfClass(%q)", State.registry[obj], State.registry[proxy] or varName, cName))
        return obj
    end
    methodHooks.FindFirstChildWhichIsA=methodHooks.FindFirstChildOfClass
    methodHooks.FindFirstAncestor=function(self, name)
        local obj=createProxy(safeTostring(name), proxy)
        emit(string.format("local %s = %s:FindFirstAncestor(%q)", State.registry[obj], State.registry[proxy] or varName, safeTostring(name)))
        return obj
    end
    methodHooks.FindFirstAncestorOfClass=methodHooks.FindFirstAncestor
    methodHooks.FindFirstAncestorWhichIsA=methodHooks.FindFirstAncestor
    methodHooks.GetChildren=function(self)
        emit(string.format("for _, child in %s:GetChildren() do", State.registry[proxy] or varName))
        State.indent=State.indent+1; State.pending_iterator=true; return {}
    end
    methodHooks.GetDescendants=function(self)
        emit(string.format("for _, obj in %s:GetDescendants() do", State.registry[proxy] or varName))
        State.indent=State.indent+1
        local child=createProxy("obj", proxy); State.registry[child]="obj"; return function() return nil end, nil, 0
    end
    methodHooks.GetPlayers=function(self) emit(string.format("local players = %s:GetPlayers()", State.registry[proxy] or varName)); return {} end
    methodHooks.GetPlayerFromCharacter=function(self, char)
        local p=createProxy("player", proxy); local n=registerVar(p,"player")
        emit(string.format("local %s = %s:GetPlayerFromCharacter(%s)", n, State.registry[proxy] or varName, toCode(char))); return p
    end
    methodHooks.Clone=function(self)
        local clone=createProxy((State.registry[proxy] or varName).."Clone", proxy)
        emit(string.format("local %s = %s:Clone()", State.registry[clone], State.registry[proxy] or varName))
        return clone
    end
    methodHooks.Destroy=function(self) emit(string.format("%s:Destroy()", State.registry[proxy] or varName)) end
    methodHooks.ClearAllChildren=function(self) emit(string.format("%s:ClearAllChildren()", State.registry[proxy] or varName)) end
    methodHooks.GetAttribute=function(self, attr) return nil end
    methodHooks.SetAttribute=function(self, attr, val) emit(string.format("%s:SetAttribute(%q, %s)", State.registry[proxy] or varName, safeTostring(attr), toCode(val))) end
    methodHooks.GetAttributes=function(self) return {} end
    methodHooks.IsA=function() return true end
    methodHooks.IsDescendantOf=function() return true end
    methodHooks.IsAncestorOf=function() return true end
    methodHooks.GetFullName=function(self) return State.registry[proxy] or varName end
    methodHooks.GetPropertyChangedSignal=function(self, prop)
        local sigName=safeTostring(prop).."Changed"
        local sig=createProxy(sigName, proxy)
        State.registry[sig]=(State.registry[proxy] or varName)..":GetPropertyChangedSignal("..string.format("%q", prop)..")"
        return sig
    end

    -- Remote
    methodHooks.FireServer=function(self, ...)
        local args={...}; local codeArgs={}; for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
        emit(string.format("%s:FireServer(%s)", State.registry[proxy] or varName, table.concat(codeArgs, ", ")))
        table.insert(State.call_graph,{type="RemoteEvent", name=State.registry[proxy] or varName, args=args})
    end
    methodHooks.InvokeServer=function(self, ...)
        local args={...}; local codeArgs={}; for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
        local res=createProxy("invokeResult", proxy); local rName=registerVar(res,"result")
        emit(string.format("local %s = %s:InvokeServer(%s)", rName, State.registry[proxy] or varName, table.concat(codeArgs, ", ")))
        table.insert(State.call_graph,{type="RemoteFunction", name=State.registry[proxy] or varName, args=args})
        return res
    end
    methodHooks.FireClient=function(self, ...) emit(string.format("%s:FireClient(%s)", State.registry[proxy] or varName, table.concat((function(...) local t={...}; local r={}; for _,v in _ipairs(t) do table.insert(r,toCode(v)) end; return r end)(...), ", "))) end
    methodHooks.FireAllClients=methodHooks.FireClient

    -- Tween
    methodHooks.Create=function(self, inst, info, props)
        local tween=createProxy("tween", proxy); local tName=registerVar(tween,"tween")
        emit(string.format("local %s = %s:Create(%s, %s, %s)", tName, State.registry[proxy] or varName, toCode(inst), toCode(info), toCode(props)))
        return tween
    end
    methodHooks.Play=function(self) emit(string.format("%s:Play()", State.registry[proxy] or varName)) end
    methodHooks.Pause=function(self) emit(string.format("%s:Pause()", State.registry[proxy] or varName)) end
    methodHooks.Cancel=function(self) emit(string.format("%s:Cancel()", State.registry[proxy] or varName)) end
    methodHooks.Stop=function(self) emit(string.format("%s:Stop()", State.registry[proxy] or varName)) end

    -- Workspace
    methodHooks.Raycast=function(self, origin, dir, params)
        local res=createProxy("raycastResult", proxy); local rName=registerVar(res,"rayResult")
        if params then emit(string.format("local %s = %s:Raycast(%s, %s, %s)", rName, State.registry[proxy] or varName, toCode(origin), toCode(dir), toCode(params)))
        else emit(string.format("local %s = %s:Raycast(%s, %s)", rName, State.registry[proxy] or varName, toCode(origin), toCode(dir))) end
        return res
    end
    methodHooks.FindPartOnRay=methodHooks.Raycast

    -- Player
    methodHooks.GetMouse=function(self)
        local m=createProxy("mouse", proxy); local mName=registerVar(m,"mouse")
        emit(string.format("local %s = %s:GetMouse()", mName, State.registry[proxy] or varName)); return m
    end
    methodHooks.Kick=function(self, msg)
        if msg then emit(string.format("%s:Kick(%s)", State.registry[proxy] or varName, toCode(msg)))
        else emit(string.format("%s:Kick()", State.registry[proxy] or varName)) end
    end
    methodHooks.MoveTo=function(self, pos) emit(string.format("%s:MoveTo(%s)", State.registry[proxy] or varName, toCode(pos))) end
    methodHooks.Move=function(self, dir) emit(string.format("%s:Move(%s)", State.registry[proxy] or varName, toCode(dir))) end

    -- Humanoid
    methodHooks.EquipTool=function(self, tool) emit(string.format("%s:EquipTool(%s)", State.registry[proxy] or varName, toCode(tool))) end
    methodHooks.UnequipTools=function(self) emit(string.format("%s:UnequipTools()", State.registry[proxy] or varName)) end
    methodHooks.TakeDamage=function(self, dmg) emit(string.format("%s:TakeDamage(%s)", State.registry[proxy] or varName, toCode(dmg))) end
    methodHooks.ChangeState=function(self, state) emit(string.format("%s:ChangeState(%s)", State.registry[proxy] or varName, toCode(state))) end
    methodHooks.LoadAnimation=function(self, anim)
        local track=createProxy("animTrack", proxy); local tName=registerVar(track,"animTrack")
        emit(string.format("local %s = %s:LoadAnimation(%s)", tName, State.registry[proxy] or varName, toCode(anim))); return track
    end

    -- Teleport
    methodHooks.Teleport=function(self, placeId, player)
        emit(string.format("%s:Teleport(%s, %s)", State.registry[proxy] or varName, toCode(placeId), toCode(player)))
    end

    -- HttpService
    methodHooks.JSONEncode=function(self, data) return "{}" end
    methodHooks.JSONDecode=function(self, str) return {} end
    methodHooks.HttpGet=function(self, url)
        local urlStr=safeTostring(url)
        table.insert(State.string_refs,{value=urlStr, hint="HTTP URL"})
        State.last_http_url=urlStr
        emit(string.format("-- [HttpGet] %s", urlStr))
        return urlStr
    end
    methodHooks.HttpPost=function(self, url, data)
        local urlStr=safeTostring(url)
        table.insert(State.string_refs,{value=urlStr, hint="HTTP POST URL"})
        local res=createProxy("HttpResponse", proxy); local rName=registerVar(res,"httpResponse")
        emit(string.format("local %s = %s:HttpPost(%s, %s)", rName, State.registry[proxy] or varName, toCode(url), toCode(data)))
        return res
    end
    methodHooks.GenerateGUID=function() return "00000000-0000-0000-0000-000000000000" end

    -- Debris
    methodHooks.AddItem=function(self, item, time) emit(string.format("%s:AddItem(%s, %s)", State.registry[proxy] or varName, toCode(item), toCode(time or 10))) end

    -- Signal factory
    local function createSignal(signalName)
        local sigProxy, sigMt = {}, {}
        weakProxies[sigProxy]=true
        local fullName=(State.registry[proxy] or varName).."."..signalName
        State.registry[sigProxy]=fullName
        sigMt.__index=function(_, k)
            if k=="Connect" or k=="connect" then
                return function(_, callback)
                    local conn=createProxy("connection", sigProxy)
                    local connName=registerVar(conn,"conn")
                    local argsMap={
                        InputBegan={"input","gameProcessed"}, InputEnded={"input","gameProcessed"},
                        CharacterAdded={"character"}, PlayerAdded={"player"}, Touched={"hit"},
                        Heartbeat={"deltaTime"}, RenderStepped={"deltaTime"}, Stepped={"time","deltaTime"},
                        Changed={"property"}, ChildAdded={"child"}, Died={}, MouseButton1Click={},
                        FocusLost={"enterPressed","inputObject"}
                    }
                    local args=argsMap[signalName] or {"..."}
                    emit(string.format("local %s = %s:Connect(function(%s)", connName, fullName, table.concat(args, ", ")))
                    State.indent=State.indent+1
                    if _type(callback)=="function" then _pcall(callback) end
                    while State.pending_iterator do State.indent=State.indent-1; emit("end"); State.pending_iterator=false end
                    State.indent=State.indent-1
                    emit("end)")
                    return conn
                end
            elseif k=="Wait" then
                return function(_)
                    local res=createProxy("waitResult", sigProxy); local rName=registerVar(res,"waitResult")
                    emit(string.format("local %s = %s:Wait()", rName, fullName)); return res
                end
            elseif k=="Once" then
                return function(_, cb)
                    local conn=createProxy("connection", sigProxy); local connName=registerVar(conn,"conn")
                    emit(string.format("local %s = %s:Once(function(...)", connName, fullName))
                    State.indent=State.indent+1
                    if _type(cb)=="function" then _pcall(cb) end
                    State.indent=State.indent-1; emit("end)"); return conn
                end
            end
            return createProxy(k, sigProxy)
        end
        sigMt.__tostring=function() return fullName end
        _setmetatable(sigProxy, sigMt)
        return sigProxy
    end

    -- __index (hybrid main + larry)
    mt.__index=function(_, key)
        if key==tobitKey or key=="__value" or key=="__proxy_id" then return _rawget(proxy,key) end
        local keyStr=safeTostring(key)
        if State.property_store[proxy] and State.property_store[proxy][key]~=nil then return State.property_store[proxy][key] end
        if methodHooks[keyStr] then
            local hookProxy, hookMt = {}, {}
            weakProxies[hookProxy]=true
            local full=(State.registry[proxy] or varName).."."..keyStr
            State.registry[hookProxy]=full
            hookMt.__call=function(_, ...)
                local args={...}
                if #args>0 and args[1]==proxy then table.remove(args,1) end
                return methodHooks[keyStr](proxy, table.unpack(args))
            end
            hookMt.__tostring=function() return full end
            hookMt.__index=function(_, k) return createProxy(k, hookProxy) end
            _setmetatable(hookProxy, hookMt)
            return hookProxy
        end
        local signals={"Changed","ChildAdded","ChildRemoved","DescendantAdded","DescendantRemoving","Touched","TouchEnded","InputBegan","InputEnded","InputChanged","MouseButton1Click","MouseButton1Down","MouseButton1Up","MouseButton2Click","Activated","Deactivated","FocusLost","FocusGained","Heartbeat","RenderStepped","Stepped","CharacterAdded","CharacterRemoving","PlayerAdded","PlayerRemoving","AncestryChanged","Died","HealthChanged","MoveToFinished","OnClientEvent","OnServerEvent","Completed","DidLoop","Stopped","Button1Down","Idle","Move","TextChanged","Triggered"}
        for _, sig in _ipairs(signals) do if keyStr==sig then return createSignal(sig) end end
        if keyStr=="Parent" then return State.parent_map[proxy] or createProxy("Parent", proxy) end
        if keyStr=="Name" then return State.registry[proxy] or varName end
        if keyStr=="ClassName" then return varName end
        if keyStr=="LocalPlayer" then
            local lp=createProxy("LocalPlayer", proxy); local lpName=registerVar(lp,"LocalPlayer")
            emit(string.format("local %s = %s.LocalPlayer", lpName, State.registry[proxy] or varName)); return lp
        end
        if keyStr=="PlayerGui" or keyStr=="Backpack" or keyStr=="PlayerScripts" then return createProxy(keyStr, proxy) end
        if keyStr=="Humanoid" or keyStr=="HumanoidRootPart" or keyStr=="PrimaryPart" or keyStr=="RootPart" then
            local h=createProxy(keyStr, proxy); State.property_store[h]={Health=100, MaxHealth=100, WalkSpeed=16}; return h
        end
        if keyStr=="CurrentCamera" or keyStr=="Camera" then
            local cam=createProxy("Camera", proxy); State.property_store[cam]={CFrame="CFrame.new(0,10,0)", FieldOfView=70}; return cam
        end
        if keyStr=="PlaceId" or keyStr=="GameId" then return 123456789 end
        if keyStr=="UserId" then return 1 end
        if keyStr=="DisplayName" then return "Player" end
        if keyStr=="Value" or keyStr=="Text" or keyStr=="PlaceholderText" then return "" end
        local heuristic=heuristicName(keyStr, keyStr)
        return createProxy(heuristic, proxy)
    end
    mt.__newindex=function(_, key, value)
        local keyStr=safeTostring(key)
        State.property_store[proxy]=State.property_store[proxy] or {}
        State.property_store[proxy][key]=value
        if key=="Parent" and isProxy(value) then State.parent_map[proxy]=value end
        emit(string.format("%s.%s = %s", State.registry[proxy] or varName, keyStr, toCode(value)))
    end
    mt.__call=function(_, ...)
        local args={...}; local codeArgs={}; for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
        local res=createProxy("result", proxy); local rName=registerVar(res,"result")
        emit(string.format("local %s = %s(%s)", rName, State.registry[proxy] or varName, table.concat(codeArgs, ", ")))
        return res
    end
    mt.__tostring=function() return State.registry[proxy] or varName end
    mt.__concat=function(a,b) return safeTostring(a)..safeTostring(b) end
    mt.__add=function(a,b) return getTobitValue(a)+getTobitValue(b) end
    mt.__sub=function(a,b) return getTobitValue(a)-getTobitValue(b) end
    mt.__mul=function(a,b) return getTobitValue(a)*getTobitValue(b) end
    mt.__div=function(a,b) local bv=getTobitValue(b); return bv~=0 and getTobitValue(a)/bv or 0 end
    _setmetatable(proxy,mt)
    return proxy
end

-- Datatype factories (Larry + main)
local function createDataTypeFactory(typeName, methods)
    local factory={}; local mt={}
    mt.__index=function(_, k)
        if k=="new" or (methods and methods[k]) then
            return function(...)
                local args={...}; local codeArgs={}; for _,v in _ipairs(args) do table.insert(codeArgs, toCode(v)) end
                local obj=createProxy(typeName, nil); local oName=registerVar(obj, typeName:lower())
                emit(string.format("local %s = %s.new(%s)", oName, typeName, table.concat(codeArgs, ", ")))
                return obj
            end
        end
        return nil
    end
    mt.__call=function(_, ...) return factory.new(...) end
    _setmetatable(factory,mt)
    return factory
end
Vector3=createDataTypeFactory("Vector3",{new=true, zero=true, one=true})
Vector2=createDataTypeFactory("Vector2",{new=true, zero=true, one=true})
CFrame=createDataTypeFactory("CFrame",{new=true, Angles=true, lookAt=true, fromEulerAnglesXYZ=true, fromMatrix=true})
Color3=createDataTypeFactory("Color3",{new=true, fromRGB=true, fromHSV=true, fromHex=true})
UDim=createDataTypeFactory("UDim",{new=true})
UDim2=createDataTypeFactory("UDim2",{new=true, fromScale=true, fromOffset=true})
BrickColor=createDataTypeFactory("BrickColor",{new=true, random=true, White=true})
TweenInfo=createDataTypeFactory("TweenInfo",{new=true})
Rect=createDataTypeFactory("Rect",{new=true})
Ray=createDataTypeFactory("Ray",{new=true})
NumberRange=createDataTypeFactory("NumberRange",{new=true})
NumberSequence=createDataTypeFactory("NumberSequence",{new=true})
ColorSequence=createDataTypeFactory("ColorSequence",{new=true})
PhysicalProperties=createDataTypeFactory("PhysicalProperties",{new=true})
RaycastParams=createDataTypeFactory("RaycastParams",{new=true})
OverlapParams=createDataTypeFactory("OverlapParams",{new=true})
Font=createDataTypeFactory("Font",{new=true, fromEnum=true})
Random={new=function(seed)
    local r={}
    function r:NextNumber(a,b) return (a or 0)+0.5*((b or 1)-(a or 0)) end
    function r:NextInteger(a,b) return math.floor((a or 1)+0.5*((b or 100)-(a or 1))) end
    function r:NextUnitVector() return Vector3.new(0.577,0.577,0.577) end
    function r:Shuffle(t) return t end
    function r:Clone() return Random.new() end
    return r
end}
setmetatable(Random,{__call=function(_,s) return Random.new(s) end})
local function createEnum()
    local e=createProxy("Enum", nil)
    local mt=_getmetatable(e)
    mt.__index=function(_, k)
        if k==tobitKey or k=="__value" then return _rawget(e,k) end
        local item=createProxy("Enum."..safeTostring(k), e)
        State.registry[item]="Enum."..safeTostring(k)
        return item
    end
    return e
end
Enum=createEnum()

-- Root env
local function createRootEnvironment()
    local gameProxy=createProxy("game", nil)
    State.registry[gameProxy]="game"; State.names_used["game"]=true
    State.property_store[gameProxy]={PlaceId=123456789, GameId=123456789}
    local workspaceProxy=createProxy("workspace", nil)
    State.registry[workspaceProxy]="workspace"; State.names_used["workspace"]=true
    local scriptProxy=createProxy("script", nil)
    State.registry[scriptProxy]="script"
    State.property_store[scriptProxy]={Name="DumpedScript", ClassName="LocalScript"}
    return gameProxy, workspaceProxy, scriptProxy
end

-- Exploit funcs (combined)
local exploit_funcs={}
exploit_funcs.getgenv=function() local env=createProxy("getgenv", nil); State.registry[env]="getgenv()"; return env end
exploit_funcs.getrenv=function() return createProxy("getrenv", nil) end
exploit_funcs.getfenv=function() return _G end
exploit_funcs.setfenv=function(f, env) return f end
exploit_funcs.hookfunction=function(a,b) return a end
exploit_funcs.hookmetamethod=function(a,b,c) return function() end end
exploit_funcs.newcclosure=function(f) return f end
exploit_funcs.clonefunction=function(f) return f end
exploit_funcs.iscclosure=function() return false end
exploit_funcs.islclosure=function(f) return _type(f)=="function" end
exploit_funcs.checkcaller=function() return true end
exploit_funcs.request=function(opts)
    local url=opts.Url or opts.url or "unknown"
    emit(string.format("request({Url=%q})", url))
    table.insert(State.string_refs,{value=url, hint="HTTP Request"})
    return {Success=true, StatusCode=200, Body="{}"}
end
exploit_funcs.http_request=exploit_funcs.request
exploit_funcs.syn={request=exploit_funcs.request}
exploit_funcs.http={request=exploit_funcs.request}
exploit_funcs.setclipboard=function(s) emit(string.format("setclipboard(%s)", toCode(s))) end
exploit_funcs.getclipboard=function() return "" end
exploit_funcs.identifyexecutor=function() return "Envlog9ms", "3.0" end
exploit_funcs.getexecutorname=function() return "Envlog9ms" end
exploit_funcs.gethui=function() local h=createProxy("HiddenUI", nil); local hName=registerVar(h,"HiddenUI"); emit(string.format("local %s = gethui()", hName)); return h end
exploit_funcs.gethiddenui=exploit_funcs.gethui
exploit_funcs.Drawing={new=function(t) local d=createProxy("Drawing_"..safeTostring(t), nil); local dName=registerVar(d,safeTostring(t)); emit(string.format("local %s = Drawing.new(%q)", dName, safeTostring(t))); return d end, Fonts=createProxy("Drawing.Fonts", nil)}
exploit_funcs.crypt={base64encode=function(s) return s end, base64decode=function(s) return s end, encrypt=function(s,k) return s end, decrypt=function(s,k) return s end, hash=function(s) return "hash" end, generatekey=function(l) return string.rep("0", l or 32) end}
exploit_funcs.base64_encode=function(s) return s end
exploit_funcs.base64_decode=function(s) return s end
exploit_funcs.readfile=function(p) emit(string.format("readfile(%q)", p)); return "" end
exploit_funcs.writefile=function(p,c) emit(string.format("writefile(%q, %s)", p, toCode(c))) end
exploit_funcs.isfile=function() return false end
exploit_funcs.isfolder=function() return false end
exploit_funcs.makefolder=function(p) emit(string.format("makefolder(%q)", p)) end
exploit_funcs.listfiles=function() return {} end
exploit_funcs.queue_on_teleport=function(s) emit(string.format("queue_on_teleport(%s)", toCode(s))) end
exploit_funcs.queueonteleport=exploit_funcs.queue_on_teleport
exploit_funcs.setfpscap=function(c) emit(string.format("setfpscap(%s)", toCode(c))) end
exploit_funcs.getfpscap=function() return 60 end
exploit_funcs.setwindowactive=function() end
exploit_funcs.iswindowactive=function() return true end
exploit_funcs.getconnections=function() return {} end
exploit_funcs.firesignal=function() end
exploit_funcs.fireclickdetector=function() end
exploit_funcs.fireproximityprompt=function() end
exploit_funcs.firetouchinterest=function() end

-- Task lib (hybrid)
local taskLib={}
taskLib.wait=function(t) if t then emit(string.format("task.wait(%s)", toCode(t))) else emit("task.wait()") end; return t or 0.03 end
taskLib.spawn=function(f, ...) emit("task.spawn(function()"); State.indent=State.indent+1; if _type(f)=="function" then _pcall(f, ...) end; while State.pending_iterator do State.indent=State.indent-1; emit("end"); State.pending_iterator=false end; State.indent=State.indent-1; emit("end)") end
taskLib.delay=function(t,f,...) emit(string.format("task.delay(%s, function()", toCode(t or 0))); State.indent=State.indent+1; if _type(f)=="function" then _pcall(f, ...) end; State.indent=State.indent-1; emit("end)") end
taskLib.defer=taskLib.spawn
taskLib.cancel=function() emit("task.cancel(thread)") end

-- Bit lib (full)
local bitLib={}
bitLib.tobit=function(v) v=(v or 0)%4294967296; if v>=2147483648 then v=v-4294967296 end; return math.floor(v) end
bitLib.tohex=function(v, len) return string.format("%0"..(len or 8).."x", (v or 0)%0x100000000) end
bitLib.band=function(a,b) return bitLib.tobit(bitLib.tobit(a) & bitLib.tobit(b)) end
bitLib.bor=function(a,b) return bitLib.tobit(bitLib.tobit(a) | bitLib.tobit(b)) end
bitLib.bxor=function(a,b) return bitLib.tobit(bitLib.tobit(a) ~ bitLib.tobit(b)) end
bitLib.lshift=function(a,b) return bitLib.tobit(bitLib.tobit(a) << (b%32)) end
bitLib.rshift=function(a,b) return bitLib.tobit(bitLib.tobit(a) >> (b%32)) end
bitLib.arshift=function(a,b) a=bitLib.tobit(a); if a<0 then return bitLib.tobit(a>>b)+bitLib.tobit(-1<<(32-(b or 0))) else return bitLib.tobit(a>>b) end end
bitLib.rol=function(a,b) a=a or 0; b=(b or 0)%32; return bitLib.tobit(a<<b | (a>>(32-b))) end
bitLib.ror=function(a,b) a=a or 0; b=(b or 0)%32; return bitLib.tobit(a>>b | (a<<(32-b))) end
bitLib.bswap=function(a) a=a or 0; return bitLib.tobit((a>>24 & 0xFF) | (a>>8 & 0xFF00) | (a<<8 & 0xFF0000) | (a<<24 & 0xFF000000)) end
bitLib.lrotate=bitLib.rol; bitLib.rrotate=bitLib.ror
_G.bit=bitLib; _G.bit32=bitLib

-- Luraph decompress (main)
local LURAPH_MARKER="does your environment support load/loadstring?"
local function DecompressLuraph(code, depth)
    depth=depth or 0; if depth>4 then return nil end
    local captured={}
    local function Capture(chunk) if _type(chunk)=="string" then table.insert(captured, chunk) end; return function() end end
    local sandbox=setmetatable({loadstring=Capture, load=Capture},{__index=_G})
    local fn=_loadstring(code, "luraph_decompress")
    if not fn then return nil end
    if setfenv then pcall(setfenv, fn, sandbox) end
    pcall(fn)
    local best, bestLen=nil,0
    for _, chunk in _ipairs(captured) do
        if #chunk>bestLen then
            local ok=_pcall(function() if has_lune then return luau.compile(chunk) else return chunk end end)
            if ok then best,bestLen=chunk,#chunk end
        end
    end
    if not best then return nil end
    if best:find(LURAPH_MARKER,1,true) then return DecompressLuraph(best, depth+1) or best end
    return best
end

-- HookOp (main)
local function TryHookOp(code, filePath)
    if not CONFIG.HOOKOP_ENABLED or not has_lune then return false, code end
    local hookFile=filePath; local tempIn=nil
    if not hookFile then tempIn="./.tmp_hookop_in.lua"; fs.writeFile(tempIn, code); hookFile=tempIn end
    local outPath=hookFile.."-unparsed.lua"
    local scriptPath="mods/hookOp.luau"
    if not fs.isFile(scriptPath) then scriptPath="mods/hookOpButNotReally.luau"; if not fs.isFile(scriptPath) then if tempIn then pcall(fs.removeFile,tempIn) end; return false, code end end
    local args={scriptPath, hookFile, outPath, "0", "1", tostring(CONFIG.WHILE_LIMIT)}
    local ok,result=_pcall(function() return process.spawn("lune", {"run", table.unpack(args)}) end)
    if tempIn then pcall(fs.removeFile,tempIn) end
    if not ok or result.code~=0 then return false, code end
    if fs.isFile(outPath) then local content=fs.readFile(outPath); pcall(fs.removeFile,outPath); return true, content end
    return false, code
end

-- Reset
local function resetState()
    State.output={}; State.indent=0; State.registry={}; State.reverse_registry={}; State.names_used={}; State.parent_map={}; State.property_store={}; State.call_graph={}; State.string_refs={}; State.variable_types={}; State.proxy_id=0; State.callback_depth=0; State.pending_iterator=false; State.last_http_url=nil; State.last_emitted_line=nil; State.repetition_count=0; State.current_size=0; State.limit_reached=false; State.lar_counter=0; State.Variables={}; State.ReverseVariables={}; State.Internal={}; State.Usages={}; State.Information={}; State.Types={}; State.Functions={}; State.CClosures={}; State.Strings={}; State.ConstantList={}; State.captured_constants={}; State.Attributes={}; State.Children={}; State.Signals={}; varId=-1; uiCounters={}
end

local function sanitizeCode(code)
    if _type(code)~="string" then return "" end
    return code:gsub("\0","")
end

-- Main dump
local function dumpString(code, outputPath)
    resetState()
    emit("-- this file is generated using Envlog9ms ALL-IN-ONE v3 (main + Larry + ultimate)")
    emit("-- TraceId: "..TraceId.." HWID: "..HardwareId.." Time: "..os.date())
    emitBlank()
    if CONFIG.LURAPH_DECOMPRESS and code:find(LURAPH_MARKER,1,true) then
        local decompressed=DecompressLuraph(code)
        if decompressed then emit(string.format("-- [Luraph] Decompressed %d -> %d bytes", #code, #decompressed)); code=decompressed
        else emit("-- [Luraph] Decompression failed") end
    end
    if CONFIG.HOOKOP_ENABLED then
        local ok, hooked=TryHookOp(code, nil)
        if ok then emit("-- [HookOp] Deobfuscated control flow"); code=hooked end
    end
    code=sanitizeCode(code)
    local gameProxy, workspaceProxy, scriptProxy=createRootEnvironment()
    local env=setmetatable({
        game=gameProxy, Game=gameProxy, workspace=workspaceProxy, Workspace=workspaceProxy, script=scriptProxy,
        Enum=Enum, Vector3=Vector3, Vector2=Vector2, CFrame=CFrame, Color3=Color3, UDim=UDim, UDim2=UDim2, BrickColor=BrickColor, TweenInfo=TweenInfo, Rect=Rect, Ray=Ray, Random=Random, Font=Font, RaycastParams=RaycastParams, OverlapParams=OverlapParams,
        task=taskLib, wait=taskLib.wait, spawn=taskLib.spawn, delay=taskLib.delay,
        tick=function() return os.time() end, time=function() return os.clock() end,
        print=function(...) emit(string.format("print(%s)", table.concat((function(...) local t={...}; local r={}; for _,v in _ipairs(t) do table.insert(r,toCode(v)) end; return r end)(...), ", "))) end,
        warn=function(...) emit(string.format("warn(%s)", table.concat((function(...) local t={...}; local r={}; for _,v in _ipairs(t) do table.insert(r,toCode(v)) end; return r end)(...), ", "))) end,
        getgenv=exploit_funcs.getgenv, getrenv=exploit_funcs.getrenv, gethui=exploit_funcs.gethui, gethiddenui=exploit_funcs.gethiddenui,
        request=exploit_funcs.request, http_request=exploit_funcs.request, Drawing=exploit_funcs.Drawing, crypt=exploit_funcs.crypt,
        readfile=exploit_funcs.readfile, writefile=exploit_funcs.writefile, queue_on_teleport=exploit_funcs.queue_on_teleport, setfpscap=exploit_funcs.setfpscap,
        bit=bitLib, bit32=bitLib,
        math=math, table=table, string=string, os=os, coroutine=coroutine,
        pairs=function(t) if isProxy(t) then return function() return nil end, t, nil end; return _pairs(t) end,
        ipairs=function(t) if isProxy(t) then return function() return nil end, t, 0 end; return _ipairs(t) end,
        type=function(x) if isTobitProxy(x) then return "number" end; if isProxy(x) then local n=State.registry[x] or ""; if n:match("Vector3") then return "Vector3" end; if n:match("CFrame") then return "CFrame" end; if n:match("Color3") then return "Color3" end; if n:match("Enum") then return "EnumItem" end; return "Instance" end; return _type(x) end,
        typeof=function(x) if isTobitProxy(x) then return "number" end; if isProxy(x) then local n=State.registry[x] or ""; if n:match("Vector3") then return "Vector3" end; if n:match("CFrame") then return "CFrame" end; if n:match("Color3") then return "Color3" end; if n:match("Enum") then return "EnumItem" end; return "Instance" end; return _type(x)=="table" and "table" or _type(x) end,
        tostring=function(x) if isProxy(x) then return State.registry[x] or "Instance" end; return _tostring(x) end,
        loadstring=function(str)
            if _type(str)=="string" then
                local lower=str:lower()
                local libs={"rayfield","orion","kavo","venyx","sirius","linoria","wally","dex","infinite","hydroxide"}
                for _, lib in _ipairs(libs) do if lower:find(lib) then emit(string.format("-- [Library Detected] %s in loadstring", lib)); break end end
                local url=str:match("https?://[%w%p]+")
                if url then table.insert(State.string_refs,{value=url, hint="URL in loadstring"}); State.last_http_url=url; emit(string.format("-- [HttpGet] %s", url)) end
            end
            return _loadstring(str)
        end,
    },{__index=_G})
    for k,v in _pairs(exploit_funcs) do if not env[k] then env[k]=v end end
    local fn, loadErr=_loadstring(code, "Obfuscated_Script")
    if not fn then emit("-- [Load Error] "..safeTostring(loadErr)); if outputPath then saveOutput(outputPath) end; return false, loadErr end
    if setfenv then setfenv(fn, env) end
    local startClock=_os.clock()
    local timeoutHook=function() if _os.clock()-startClock>CONFIG.TIMEOUT_SECONDS then error("TIMEOUT_FORCED_BY_DUMPER") end end
    local hookOk=_pcall(function() _debug.sethook(timeoutHook,"",1000) end)
    local success, execErr=_xpcall(function() fn() end, function(err) return _tostring(err) end)
    if hookOk then _pcall(function() _debug.sethook() end) end
    if not success then emit("-- [Terminated] "..safeTostring(execErr)) end
    emitBlank()
    emit("-- ==================== DUMP SUMMARY ====================")
    emit(string.format("-- Lines: %d | Remotes: %d | Strings: %d | Proxies: %d", #State.output, #State.call_graph, #State.string_refs, State.proxy_id))
    if #State.string_refs>0 then
        emit("-- String Refs:")
        for _, ref in _ipairs(State.string_refs) do emit(string.format("--   [%s] %s", ref.hint or "?", ref.value:sub(1,100))) end
    end
    if #State.call_graph>0 then
        emit("-- Call Graph:")
        for _, call in _ipairs(State.call_graph) do emit(string.format("--   [%s] %s", call.type, call.name)) end
    end
    emit("-- Libraries detected:")
    local libs={}
    for _, ref in _ipairs(State.string_refs) do
        local lower=ref.value:lower()
        for _, lib in _ipairs({"rayfield","orion","kavo","venyx","linoria","wally","dex"}) do
            if lower:find(lib) then libs[lib]=true end
        end
    end
    for lib,_ in _pairs(libs) do emit("--   - "..lib) end
    if outputPath then saveOutput(outputPath); return true end
    return true, getOutput()
end

local function dumpFile(inputPath, outputPath)
    local content
    if has_lune then
        if not fs.isFile(inputPath) then return false end
        content=fs.readFile(inputPath)
    else
        local f=_io.open(inputPath,"rb")
        if not f then return false end
        content=f:read("*a"); f:close()
    end
    return dumpString(content, outputPath or CONFIG.OUTPUT_FILE)
end

local q={
    reset=resetState,
    dump_string=dumpString,
    dump_file=dumpFile,
    get_output=getOutput,
    save=saveOutput,
    get_call_graph=function() return State.call_graph end,
    get_string_refs=function() return State.string_refs end,
    get_stats=function() return {total_lines=#State.output, remote_calls=#State.call_graph, suspicious_strings=#State.string_refs, proxies_created=State.proxy_id} end,
    config=CONFIG,
}

if has_lune then
    if process.args[1] then
        local input=process.args[1]; local output=process.args[2] or CONFIG.OUTPUT_FILE
        _print("[Envlog9ms ALL-IN-ONE] Dumping "..input.." -> "..output)
        local ok=dumpFile(input, output)
        if ok then _print("[Envlog9ms] Saved to "..output); local stats=q.get_stats(); _print(string.format("Lines: %d | Remotes: %d | Strings: %d", stats.total_lines, stats.remote_calls, stats.suspicious_strings)) end
    end
else
    if arg and arg[1] then
        local ok=dumpFile(arg[1], arg[2])
        if ok then _print("Saved to: "..(arg[2] or CONFIG.OUTPUT_FILE)); local stats=q.get_stats(); _print(string.format("Lines: %d | Remotes: %d | Strings: %d", stats.total_lines, stats.remote_calls, stats.suspicious_strings)) end
    end
end

_G.LuraphContinue=function() end
return q



print("[Envlog9ms 400KB+] All systems loaded - 400KB+ direct concat")
