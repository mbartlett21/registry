local OneDrive = {}

local Reg = require 'reg'

local base_key <const> = [[HKCU\Software\SyncEngines\Providers\OneDrive]]

local id_to_folder_info = {}
local ids = {}

-- takes around 150-200ms
function OneDrive.refresh_id_list()
    Reg.clear_cache(base_key)

    id_to_folder_info = {}
    ids = {}

    local path_key = Reg.path_key

    for k, v in Reg.pairs_keys(Reg.load_all_below(base_key)) do
        local id = k:match '^([%da-f]+)%+?%d*$'
        -- if that particular onedrive isn't syncing anymore, WebUrl is no longer filled out.
        if id and v.WebUrl and v.MountPoint then

            -- all the values are stored as strings, even the number ones.

            local info = {
                id = id,
                reg_path = v[path_key],
                reg_entry = v,
                mount_point = v.MountPoint,
                ty = v.LibraryType,
                url = v.WebUrl,
                url_namespace = v.UrlNamespace,
                is_folder = v.IsFolderScope == '1',
            }

            id_to_folder_info[id] = info
            table.insert(ids, id)
        end
    end

    table.sort(ids)
end

local function _next_synced_item(state, id)
    local next_id
    if not id then
        next_id = ids[1]
    else
        for i, v in ipairs(ids) do
            if v == id then
                next_id = ids[i + 1]
            end
        end
    end

    if not next_id then
        return next_id
    else
        local item = id_to_folder_info[next_id]
        return next_id, item.mount_point, item
    end
end

function OneDrive.synced_items() --> iterator (id, mount_point, dat)
    OneDrive.refresh_id_list()

    return _next_synced_item, nil, nil
end

function OneDrive.get_for_id(id) --> mount_point, dat
    if type(id) ~= 'string' then
        return nil, 'id is not a string'
    end

    id = id:lower()

    local dat = id_to_folder_info[id]
    if not dat then
        OneDrive.refresh_id_list()
        dat = id_to_folder_info[id]
    end
    if not dat then
        if #id ~= 32 or not id:match('^[%da-f]+$') then
            return nil, 'id is invalid'
        else
            return nil, 'folder not synced'
        end
    else
        return dat.mount_point, dat
    end
end

return OneDrive
