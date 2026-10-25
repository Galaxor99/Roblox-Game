-- Global top-ten boards. Profile data remains the source of truth.
local Rankings={}
function Rankings.new(dataStoreService,players,clock)
 local boards={Cards='AnimeNexusCards_v1',Power='AnimeNexusPower_v1',Bosses='AnimeNexusBosses_v1'}
 local stores={};local lastWrite={};local cache={};local names={}
 for metric,name in pairs(boards) do stores[metric]=dataStoreService:GetOrderedDataStore(name) end
 local api={}
 function api.update(userId,scores,force)
  local now=clock();local key=tostring(userId)
  local last=lastWrite[key]
  if not force and last and now-last<300 then return true end
  local failed=false
  for metric,store in pairs(stores) do
   local value=scores[metric]
   if type(value)~='number' or value~=value then return false,'Invalid ranking score' end
   local score=math.clamp(math.floor(value),0,1000000000)
   local ok=pcall(function()store:SetAsync(key,score)end)
   if not ok then failed=true end
  end
  if failed then return false,'Ranking service unavailable' end
  lastWrite[key]=now
  return true
 end
 function api.top(metric)
  local store=stores[metric]
  if not store then return nil,'Unknown ranking' end
  local now=clock();local saved=cache[metric]
  if saved and now-saved.At<60 then return table.clone(saved.Rows) end
  local ok,page=pcall(function()return store:GetSortedAsync(false,10):GetCurrentPage()end)
  if not ok or type(page)~='table' then
   if saved then return table.clone(saved.Rows),'Showing the last available rankings' end
   return nil,'Rankings are temporarily unavailable'
  end
  local rows={}
  for _,entry in ipairs(page) do
   local userId=tonumber(entry.key)
   if userId and type(entry.value)=='number' then
    local name=names[userId]
    if not name then
     local good,result=pcall(function()return players:GetNameFromUserIdAsync(userId)end)
     name=good and type(result)=='string' and result or ('Riftwalker #'..userId)
     if good then names[userId]=name end
    end
    table.insert(rows,{Name=name,Score=math.floor(entry.value),UserId=userId})
   end
  end
  cache[metric]={Rows=rows,At=now}
  return table.clone(rows)
 end
 return api
end
return Rankings
