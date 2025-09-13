--// Example: local hitsound = create("Sound", services.SoundService, { SoundId = "rbxassetid://6607339542", Volume = 5 })
function create(instance, parent, options) local ins = Instance.new(instance, parent) ins.Name = " " for prop, value in next, options do ins[prop] = value end return ins end
return create
