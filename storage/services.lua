local service_names, services = {
  "UserInputService", 
  "HttpService", 
  "Lighting",
  "GuiService",
  "RunService", 
  "SoundService", 
  "Stats", 
  "ReplicatedStorage", 
  "CoreGui", 
  "TweenService", 
  "Players", 
  "Workspace"
},{}
for _,service in service_names do services[service] = cloneref(game:GetService(service)) end
return services
