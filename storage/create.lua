function create(instance, parent, options) local ins = Instance.new(instance, parent) ins.Name = " " for prop, value in next, options do ins[prop] = value end return ins end
return create
