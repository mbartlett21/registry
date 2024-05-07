local string_find = string.find
local string_lower = string.lower
local string_match = string.match
local string_sub = string.sub

local function run_command(...) --> io.file
    local tbl
    if type((...)) == 'table' then
        tbl = ...
    else
        tbl = {...}
    end
    local s = ''
    for i, v in ipairs(tbl) do
        if i ~= 1 then
            s = s .. ' '
        end
        if string_find(v, ' ') then
            s = s .. '"' .. v .. '"'
        else
            s = s .. v
        end
    end
    -- print()
    -- print('> ' .. s)
    return io.popen('"' .. s .. '"'), s
end

local path_key <const> = {}

local data = {}

local function get_dat(path)
    local t = data[path]
    if t == nil then
        t = { entries = {}, keys = {} }
        -- check for parents
        local parent, skey = string_match(path, '^(.*)\\([^\\]+)$')
        if parent then
            local parentd = get_dat(parent)
            parentd.keys[skey] = true
        end
        data[path] = t
    end
    return t
end

local meta = {}

local function make_key(path, idx)
    return setmetatable({ [path_key] = path .. '\\' .. idx }, meta)
end

local function parse_reg_command_output(result, path, includes_all_under)
    local cdat

    local actual_path

    for l in result:lines() do
        if l == '' then

        elseif string_sub(l, 1, 4) ~= '    ' then
            cdat = get_dat(l)
            if not actual_path then
                actual_path = l
            end
            if includes_all_under or l == actual_path then
                cdat.entries_filled = true
            end
        else
            local k, ty, val = string_match(l, '^    (.-)    (REG_%w+)    (.+)$')
            if k then
                if ty == 'REG_SZ' then
                    cdat.entries[k] = val
                    --        REG_SZ, REG_MULTI_SZ, REG_EXPAND_SZ,
                    -- REG_DWORD, REG_QWORD, REG_BINARY, REG_NONE
                elseif ty == 'REG_DWORD' or ty == 'REG_QWORD' then
                    cdat.entries[k] = tonumber(val)
                else
                    warn('unsupported reg key type: ' .. ty)
                end
            end
        end
    end

    return actual_path
end

local function fill_dat_entries(path)
    local result = run_command { 'reg', 'query', path }
    if not result then error 'reg command did not work' end

    return parse_reg_command_output(result, path, false)
end

local function fill_dat_entries_full(path)
    local result = run_command { 'reg', 'query', path, '/s' }
    if not result then error 'reg command did not work' end

    return parse_reg_command_output(result, path, true)
end


local function reg_next(path, pkey)
    local dat = get_dat(path)
    if not dat.entries_filled then
        fill_dat_entries(path)
    end

    if pkey == nil or dat.entries[pkey] then
        local nextentidx, nextentv = next(dat.entries, pkey)
        if nextentidx == nil then
            local idx, v = next(dat.keys)
            if v then
                return idx, make_key(path, idx)
            end
        end
        return nextentidx, nextentv
    else
        local idx, v = next(dat.keys, pkey)
        if v then
            return idx, make_key(path, idx)
        end
    end
end

local function reg_key_next(path, pkey)
    local dat = get_dat(path)
    if not dat.entries_filled then
        fill_dat_entries(path)
    end

    local idx, v = next(dat.keys, pkey)
    if v then
        return idx, make_key(path, idx)
    end
end

local function reg_value_next(path, pkey)
    local dat = get_dat(path)
    if not dat.entries_filled then
        fill_dat_entries(path)
    end

    return next(dat.entries, pkey)
end

function meta:__pairs()
    return reg_next, self[path_key], nil
end


local function index_ncs(self, idx)
    if type(idx) ~= 'string' then
        return nil
    end
    local path = self[path_key]
    local dat = get_dat(path)
    for k, v in pairs(dat.entries) do
        if string_lower(k) == string_lower(idx) then
            return v
        end
    end
    for k in pairs(dat.keys) do
        if string_lower(k) == string_lower(idx) then
            return make_key(path, k)
        end
    end
end

function meta:__index(idx)
    if idx == path_key then
        error 'path is nil'
    end
    local path = self[path_key]
    local dat = get_dat(path)
    if dat.keys[idx] then
        return make_key(path, idx)
    end
    if not dat.entries_filled then
        fill_dat_entries(path)
    end
    local entry = dat.entries[idx]
    if entry == nil then
        local keyv = dat.keys[idx]
        if keyv then
            return make_key(path, idx)
        end
        return index_ncs(self, idx)
    end
    return entry
end


local base_key_to_actual = {
    HKLM = HKEY_LOCAL_MACHINE,
    HKCU = HKEY_CURRENT_USER,
    HKCR = HKEY_CLASSES_ROOT,
    HKCC = HKEY_CURRENT_CONFIG,
    HKU  = HKEY_USERS,

    HKEY_LOCAL_MACHINE  = HKEY_LOCAL_MACHINE,
    HKEY_CURRENT_USER   = HKEY_CURRENT_USER,
    HKEY_CLASSES_ROOT   = HKEY_CLASSES_ROOT,
    HKEY_CURRENT_CONFIG = HKEY_CURRENT_CONFIG,
    HKEY_USERS          = HKEY_USERS,
}


local Reg = {
    HKLM = setmetatable({ [path_key] = 'HKEY_LOCAL_MACHINE' }, meta),
    HKCU = setmetatable({ [path_key] = 'HKEY_CURRENT_USER' }, meta),
    HKCR = setmetatable({ [path_key] = 'HKEY_CLASSES_ROOT' }, meta),
    HKCC = setmetatable({ [path_key] = 'HKEY_CURRENT_CONFIG' }, meta),
    HKU  = setmetatable({ [path_key] = 'HKEY_USERS' }, meta),
    path_key = path_key,
    load_all_below = function(path)
        if path[path_key] then
            path = path[path_key]
        end
        local actual_path = fill_dat_entries_full(path)
        return setmetatable({ [path_key] = actual_path }, meta)
    end,
    load = function(path)
        local actual_path = fill_dat_entries(path)
        return setmetatable({ [path_key] = actual_path }, meta)
    end,
    clone = function(self)
        assert(self[path_key], 'parameter is not a Reg entry')
        return setmetatable({ [path_key] = self[path_key] }, meta)
    end,
    pairs_keys = function(self)
        assert(self[path_key], 'parameter is not a Reg entry')
        return reg_key_next, self[path_key], nil
    end,
    pairs_values = function(self)
        assert(self[path_key], 'parameter is not a Reg entry')
        return reg_value_next, self[path_key], nil
    end,
    print_cache = function()
        local paths = {}
        for k, v in pairs(data) do
            if v.entries_filled then
                table.insert(paths, k)
                for vk in pairs(v.entries) do
                    table.insert(paths, k .. '\\' .. vk)
                end
            end
        end
        table.sort(paths)
        for _, v in ipairs(paths) do
            print(v)
        end
    end,
}

function Reg.clear_cache(path)
    if not path then
        data = {}
    elseif data[path] then
        -- clear everything below as well
        for k in pairs(data[path].keys) do
            Reg.clear_cache(path .. '\\' .. k)
        end
        data[path] = nil
    end
end

return Reg
