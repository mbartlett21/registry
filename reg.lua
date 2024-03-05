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
        if v:find ' ' then
            s = s .. '"' .. v .. '"'
        else
            s = s .. v
        end
    end
    -- print()
    -- print('> ' .. s)
    return io.popen('"' .. s .. '"'), s
end

local meta = {}

local HKLM = setmetatable({}, meta)
local HKCU = setmetatable({}, meta)
local HKCR = setmetatable({}, meta)
local HKCC = setmetatable({}, meta)

local data = {
    [HKLM] = { path = 'HKEY_LOCAL_MACHINE' },
    [HKCU] = { path = 'HKEY_CURRENT_USER' },
    [HKCR] = { path = 'HKEY_CLASSES_ROOT' },
    [HKCC] = { path = 'HKEY_CURRENT_CONFIG' },
}

local function fill_dat_entries(dat)
    local path = dat.path
    local result = run_command { 'reg', 'query', path }
    if not result then error 'reg command did not work' end

    local entries = {}
    local keys = {}

    dat.entries = entries
    dat.keys = keys

    for l in result:lines() do
        if l == path then
        elseif l:sub(1, #path) == path then
            -- subkeys
            local key = l:sub(#path + 2)
            dat.keys[key] = true
            -- print(key)
        else
            local k, ty, val = l:match('    (.-)    (REG_%w+)    (.+)')
            if k then
                if ty == 'REG_SZ' then
                    entries[k] = val
             --        REG_SZ, REG_MULTI_SZ, REG_EXPAND_SZ,
             -- REG_DWORD, REG_QWORD, REG_BINARY, REG_NONE
                elseif ty == 'REG_DWORD' or ty == 'REG_QWORD' then
                    entries[k] = tonumber(val)
                else
                    warn('unsupported reg key type: ' .. ty)
                end
                -- print(k, ty, val)
            end
        end
        -- print(l == path)
        -- print(string.format('%q', l))
    end
end


local function reg_next(self, pkey)
    local dat = data[self]
    if not dat.entries then
        fill_dat_entries(dat)
    end

    if pkey == nil or dat.entries[pkey] then
        local nextentidx, nextentv = next(dat.entries, pkey)
        if nextentidx == nil then
            local idx, v = next(dat.keys)
            if v == true then
                local t = setmetatable({}, meta)
                dat.keys[idx] = t
                data[t] = { path = dat.path .. '\\' .. idx }
                return idx, t
            end
            return idx, v
        end
        return nextentidx, nextentv
    else
        local idx, v = next(dat.keys, pkey)
        if v == true then
            local t = setmetatable({}, meta)
            dat.keys[idx] = t
            data[t] = { path = dat.path .. '\\' .. idx }
            return idx, t
        end
        return idx, v
    end
end

function meta:__pairs()
    return reg_next, self, nil
end


function meta:__index(key)
    local dat = data[self]
    if not dat.entries then
        fill_dat_entries(dat)
    end
    local entry = dat.entries[key]
    if not entry then
        local keyv = dat.keys[key]
        if keyv == true then
            -- fill in the entry
            local t = setmetatable({}, meta)
            dat.keys[key] = t
            data[t] = { path = dat.path .. '\\' .. key }
            return t
        else
            return keyv
        end
        return nil
    end
    return entry
end


local Reg = {
    HKLM = HKLM,
    HKCU = HKCU,
    HKCR = HKCR,
    HKCC = HKCC,
    clear_cache = function(entry)
        if not entry then
            for k, v in pairs(data) do
                v.entries = nil
            end
        else
            if data[entry] then
                data[entry].entries = nil
            end
        end
    end,
}


local function reg_key_next(self, pkey)
    local dat = data[self]
    if not dat.entries then
        fill_dat_entries(dat)
    end

    local idx, v = next(dat.keys, pkey)
    if v == true then
        local t = setmetatable({}, meta)
        dat.keys[idx] = t
        data[t] = { path = dat.path .. '\\' .. idx }
        return idx, t
    end
    return idx, v
end

function Reg:get_keys()
    return reg_key_next, self, nil
end


local function reg_value_next(self, pkey)
    local dat = data[self]
    if not dat.entries then
        fill_dat_entries(dat)
    end

    return next(dat.entries, pkey)
end

function Reg:get_values()
    return reg_value_next, self, nil
end


for k, v in Reg.get_keys(Reg.HKCU.Software.SyncEngines.Providers.OneDrive) do
    local id = k:match('^([%da-f]+)%+?%d*$')
    if id then
        print(id)
        print('mounted at:', v.MountPoint)
        print('type:      ', v.LibraryType)
        print('web url:   ', v.WebUrl)
        print('is_folder: ', v.IsFolderScope and true or false)
        -- for k2, v2 in Reg.get_values(v) do
        --     print('>', k2, v2)
        -- end
        print()
    end
end

return Reg
