registry
===

`reg`
---

```lua
Reg = require 'reg'

Reg.HKLM --> Entry(HKEY_LOCAL_MACHINE)
Reg.HKCU --> Entry(HKEY_CURRENT_USER)
Reg.HKCR --> Entry(HKEY_CLASSES_ROOT)
Reg.HKCC --> Entry(HKEY_CURRENT_CONFIG)
Reg.HKU  --> Entry(HKEY_USERS)

-- Key for each entry that stores the registry path.
-- Access the path using `entry[Reg.path_key]`
Reg.path_key

-- Loads all registry entries below the path and caches them.
-- Don't use this with a root key
function Reg.load_all_below(path) --> Entry(path)
end

-- Loads the immediate registry entries in the path.
function Reg.load(path) --> Entry(path)
end

-- Clears the cache for everything below path,
-- or if no path is provided, clears the full cache
function Reg.clear_cache(path)
end

-- Prints all the parts that are cached (for debugging)
function Reg.print_cache()
end


-- Entry --

-- Returns an iterator over both sub-keys and values
function pairs(Entry) --> next, self, nil
end

-- Returns a sub-key entry, the end value, or nil
-- lookups are case-insensitive, though the correct
-- case is slightly faster.
Entry[key] --> Entry | value | nil

-- Clones the entry and returns another reference
function Entry:clone() --> Self
end

-- Returns an iterator over sub-keys
function Entry:pairs_keys() --> next, self, nil
end

-- Returns an iterator over end values
function Entry:pairs_values() --> next, self, nil
end
```

`onedrive`
---

```lua
OneDrive = require 'onedrive'

-- refreshes the id list of OneDrive points and reloads it.
function OneDrive.refresh_id_list()
end

-- Returns an iterator over (id, mount_point, dat)
function OneDrive.synced_items() --> next, nil, nil
end

-- Returns (mount_point, dat)
function OneDrive.get_for_id(id) --> (mount_point, dat) or (nil, errorString)
end

dat = {
    id = idString,
    reg_path = [[HKCU\Software\SyncEngines\Providers\OneDrive\]] .. idString .. (('+' .. number) or ''),
    reg_entry = RegEntry,
    mount_point = pathString,
    ty = 'teamsite' or 'mysite',
    url = 'https://...',
    url_namespace = 'https://...',
    is_folder = bool,
}
```
