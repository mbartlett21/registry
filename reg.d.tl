local record Reg
   interface RegKey
      metamethod __index: function(self: RegKey, key: string): string | integer | RegKey
      metamethod __index: function(self: RegKey, key: PathKey): string
   end

   record PathKey end

   HKLM: RegKey
   HKCU: RegKey
   HKCR: RegKey
   HKCC: RegKey
   HKU:  RegKey
   path_key: PathKey
   load_all_below: function(string | RegKey): RegKey
   load: function(string): RegKey
   clone: function(RegKey): RegKey
   pairs_keys: function(RegKey): function(string, string): (string, RegKey), string, nil
   pairs_values: function(RegKey): function(string, string): (string, string | integer), string, nil
   print_cache: function()
   clear_cache: function(? string)
end

return Reg
