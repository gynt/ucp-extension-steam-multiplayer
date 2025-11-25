

---@param a GUID
---@param b GUID
---@return boolean equality
local function testGUIDEquality(a, b)

  if a.Data1 ~= b.Data1 then
    return false
  end

  if a.Data2 ~= b.Data2 then
    return false
  end

  if a.Data3 ~= b.Data3 then
    return false
  end

  for i=0,7 do
    if a.Data4[i] ~= b.Data4[i] then
      return false
    end
  end
  
  return true
end


return {
  testGUIDEquality = testGUIDEquality
}