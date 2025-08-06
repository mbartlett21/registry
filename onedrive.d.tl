local Reg = require 'reg'

local record OneDrive
   interface OneDriveFolderInfo
      id: string
      reg_path: string
      reg_entry: Reg.RegKey
      mount_point: string
      ty: string
      url: string
      url_namespace: string
      is_folder: boolean
   end
   refresh_id_list: function()
   synced_items: function(): function(nil, string): (string, string, OneDriveFolderInfo), nil, nil
   get_for_id: function(string): string, OneDriveFolderInfo | string
end


return OneDrive