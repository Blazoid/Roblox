local players = game:GetService("Players")
local local_player = players.LocalPlayer
local Client = getsenv(local_player.PlayerGui.Client)
local offsets = loadstring(game:HttpGet('https://raw.githubusercontent.com/Blazoid/Roblox/refs/heads/main/CB%3ARO/offsets.lua'))()
local isUnlocked
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
local isUnlocked
mt.__namecall = newcclosure(function(self, ...)
   local args = {...}
   if getnamecallmethod() == "InvokeServer" and tostring(self) == "Hugh" then return end
   if getnamecallmethod() == "FireServer" then
       if args[1] == local_player.UserId then return end
       if string.len(tostring(self)) == 38 then
           if not isUnlocked then
               isUnlocked = true
               for i,v in pairs(offsets) do
                   local doSkip
                   for i2,v2 in pairs(args[1]) do
                       if v[1] == v2[1] then
                           doSkip = true
                       end
                   end
                   if not doSkip then
                       table.insert(args[1], v)
                   end
               end
           end
           return
       end
       if tostring(self) == "DataEvent" and args[1][4] then
           local currentSkin = string.split(args[1][4][1], "_")[2]
           if args[1][2] == "Both" then
               local_player["SkinFolder"]["CTFolder"][args[1][3]].Value = currentSkin
               local_player["SkinFolder"]["TFolder"][args[1][3]].Value = currentSkin
           else
               local_player["SkinFolder"][args[1][2] .. "Folder"][args[1][3]].Value = currentSkin
           end
       end
   end
   return oldNamecall(self, ...)
end)
setreadonly(mt, true)
Client.CurrentInventory = offsets
local TClone, CTClone = local_player.SkinFolder.TFolder:Clone(), local_player.SkinFolder.CTFolder:Clone()
local_player.SkinFolder.TFolder:Destroy()
local_player.SkinFolder.CTFolder:Destroy()
TClone.Parent = local_player.SkinFolder
CTClone.Parent = local_player.SkinFolder
