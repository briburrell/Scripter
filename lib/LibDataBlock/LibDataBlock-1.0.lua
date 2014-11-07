-- Coded originally for wow as LibDataBroker by tekkub
-- Ported for eso by Alisu

assert(LibStub, "LibDataBlock-1.0 requires LibStub")

local lib, oldminor = LibStub:NewLibrary("LibDataBlock-1.0", 1)
if not lib then return end

lib.callbacks = lib.callbacks or ZO_CallbackObject:New()
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, callbacks = lib.attributestorage, lib.namestorage, lib.callbacks

lib.domt = {
  __metatable = "access denied",
  __index = function(self, key) return attributestorage[self] and attributestorage[self][key] end,
  __newindex = function(self, key, value)
  if not attributestorage[self] then attributestorage[self] = {} end
  if attributestorage[self][key] == value then return end
  attributestorage[self][key] = value
  local name = namestorage[self]
  if not name then return end
  callbacks:FireCallbacks("LibDataBlock_AttributeChanged", name, key, value, self)
  callbacks:FireCallbacks("LibDataBlock_AttributeChanged_"..name, name, key, value, self)
  callbacks:FireCallbacks("LibDataBlock_AttributeChanged_"..name.."_"..key, name, key, value, self)
  callbacks:FireCallbacks("LibDataBlock_AttributeChanged__"..key, name, key, value, self)
  end,
}

function lib:NewDataObject(name, dataobj)
  if self.proxystorage[name] then return end
  
  if dataobj then
    assert(type(dataobj) == "table", "Invalid dataobj, must be nil or a table")
    self.attributestorage[dataobj] = {}
    for i,v in pairs(dataobj) do
      self.attributestorage[dataobj][i] = v
      dataobj[i] = nil
    end
  end
  dataobj = setmetatable(dataobj or {}, self.domt)
  self.proxystorage[name], self.namestorage[dataobj] = dataobj, name
  self.callbacks:FireCallbacks("LibDataBlock_DataObjectCreated", name, dataobj)
  return dataobj
end


function lib:DataObjectIterator()
  return pairs(self.proxystorage)
end

function lib:GetDataObjectByName(dataobjectname)
  return self.proxystorage[dataobjectname]
end

function lib:GetNameByDataObject(dataobject)
  return self.namestorage[dataobject]
end

local next = pairs(attributestorage)
function lib:pairs(dataobject_or_name)
  local t = type(dataobject_or_name)
  assert(t == "string" or t == "table", "Usage: ldb:pairs('dataobjectname') or ldb:pairs(dataobject)")
  
  local dataobj = self.proxystorage[dataobject_or_name] or dataobject_or_name
  assert(attributestorage[dataobj], "Data object not found")
  
  return next, attributestorage[dataobj], nil
end

local ipairs_iter = ipairs(attributestorage)
function lib:ipairs(dataobject_or_name)
  local t = type(dataobject_or_name)
  assert(t == "string" or t == "table", "Usage: ldb:ipairs('dataobjectname') or ldb:ipairs(dataobject)")
  
  local dataobj = self.proxystorage[dataobject_or_name] or dataobject_or_name
  assert(attributestorage[dataobj], "Data object not found")
  
  return ipairs_iter, attributestorage[dataobj], 0
end

function lib:RegisterCallback(eventName, callback)
  self.callbacks:RegisterCallback(eventName, callback)
end

function lib:UnregisterCallback(eventName, callback)
  self.callbacks:UnregisterCallback(eventName, callback)
end