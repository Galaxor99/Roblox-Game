-- A lease prevents two servers from writing the same collection concurrently.
-- Payload remains at the legacy key so existing v2 collections migrate in place.
local Persistence={}
function Persistence.new(store,token,clock)
 local api={}; local leases={}; local leaseSeconds=180
 function api.load(userId)
  local key='user_'..userId; local denied=false
  local ok,data=pcall(function()
   return store:UpdateAsync(key,function(old)
    denied=false
    old=type(old)=='table' and old or {}
    local lock=old._Session
    if type(lock)=='table' and lock.Token~=token and type(lock.Expires)=='number' and lock.Expires>clock() then denied=true; return nil end
    local copy=table.clone(old); copy._Session={Token=token,Expires=clock()+leaseSeconds}; return copy
   end)
  end)
  if not ok then return nil,'unavailable' end
  if denied or not data then return nil,'locked' end
  leases[userId]=true
  return data
 end
 function api.save(userId,payload,release)
  if not leases[userId] then return false,'No active session' end
  local denied=false
  local ok,result=pcall(function()
   return store:UpdateAsync('user_'..userId,function(old)
    denied=false
    if type(old)~='table' or type(old._Session)~='table' or old._Session.Token~=token then denied=true; return nil end
    local copy=table.clone(payload)
    -- A transaction never discards already committed purchase receipts.
    copy.Receipts=table.clone(payload.Receipts or {})
    for id,value in pairs(old.Receipts or {}) do if value==true then copy.Receipts[id]=true end end
    copy._Session=not release and {Token=token,Expires=clock()+leaseSeconds} or nil
    return copy
   end)
  end)
  if denied then leases[userId]=nil; return false,'Session ownership lost' end
  if not ok or not result then return false,'DataStore save failed' end
  if release then leases[userId]=nil end
  return true,result
 end
 function api.purchase(userId,payload,receiptId,potionId)
  if not leases[userId] then return nil,'No active session' end
  local denied=false
  local ok,result=pcall(function()
   return store:UpdateAsync('user_'..userId,function(old)
    denied=false
    if type(old)~='table' or type(old._Session)~='table' or old._Session.Token~=token then denied=true;return nil end
    if old.Receipts and old.Receipts[receiptId] then return old end
    local copy=table.clone(payload);copy.Potions=table.clone(payload.Potions or {});copy.Receipts=table.clone(payload.Receipts or {})
    copy.Potions[potionId]=(copy.Potions[potionId] or 0)+1;copy.Receipts[receiptId]=true
    copy._Session={Token=token,Expires=clock()+leaseSeconds};return copy
   end)
  end)
  if not ok or denied or not result then return nil,'Purchase outcome not confirmed' end
  return result
 end
 function api.claimCoop(userId,payload,day,reward)
  if not leases[userId] then return nil,'No active session' end
  local key=tostring(day)
  local denied=false
  local ok,result=pcall(function()
   return store:UpdateAsync('user_'..userId,function(old)
    denied=false
    if type(old)~='table' or type(old._Session)~='table' or old._Session.Token~=token then denied=true;return nil end
    local previous=old.Progression and old.Progression.CoopClaims
    if previous and previous[key] then return old end
    local copy=table.clone(payload)
    copy.Progression=table.clone(payload.Progression or {})
    copy.Progression.CoopClaims=table.clone(copy.Progression.CoopClaims or {})
    copy.Progression.CoopClaims[key]=true
    copy.Coins=math.min(1000000000,(copy.Coins or 0)+reward.Coins)
    copy.Essence=math.min(10000000,(copy.Essence or 0)+reward.Essence)
    copy.Crystals=math.min(10000000,(copy.Crystals or 0)+reward.Crystals)
    copy.Receipts=table.clone(payload.Receipts or {})
    for id,value in pairs(old.Receipts or {}) do if value==true then copy.Receipts[id]=true end end
    copy._Session={Token=token,Expires=clock()+180}
    return copy
   end)
  end)
  if not ok or denied or not result then return nil,'Shared reward could not be confirmed' end
  return result
 end
 return api
end
return Persistence
