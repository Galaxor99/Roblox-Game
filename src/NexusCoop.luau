-- Shared daily boss, stored in 16 durable contribution shards.
-- A player contributes once per UTC day; an outcome can be claimed the next day.
local Coop={}
function Coop.new(dataStoreService,clock)
 local store=dataStoreService:GetDataStore('AnimeNexusCoop_v1')
 local shards=16;local capacity=512;local target=10000
 local cache={}
 local api={Target=target}
 local function valid(day,allowToday)
  local today=math.floor(clock()/86400)
  return type(day)=='number' and day==math.floor(day) and day>=today-7 and day<=(allowToday and today or today-1)
 end
 function api.day()return math.floor(clock()/86400) end
 function api.contribute(day,userId,power)
  if not valid(day,true) or day~=api.day() then return nil,'This challenge has ended' end
  local score=math.clamp(math.floor(power),1,2500)
  local shard=userId%shards;local key='day_'..day..'_shard_'..shard
  local full=false
  local ok,result=pcall(function()
   return store:UpdateAsync(key,function(old)
    full=false
    old=type(old)=='table' and old or {Total=0,Contributors={}}
    local contributors=old.Contributors or {}
    if contributors[tostring(userId)] then return old end
    local count=0;for _ in pairs(contributors) do count+=1 end
    if count>=capacity then full=true;return nil end
    local nextContributors=table.clone(contributors);nextContributors[tostring(userId)]=score
    return {Total=(old.Total or 0)+score,Contributors=nextContributors}
   end)
  end)
  if not ok then return nil,'Shared challenge is temporarily unavailable' end
  if full or not result then return nil,'This challenge is full for today' end
  cache[day]=nil
  return result.Contributors[tostring(userId)]
 end
 function api.status(day,userId)
  if not valid(day,true) then return nil,'Challenge day is outside the claim window' end
  local current=cache[day];local now=clock()
  if not current or (day==api.day() and now-current.At>=60) or (day<api.day() and current.At<(day+1)*86400) then
   local total=0;local participants=0;local contributors={}
   for shard=0,shards-1 do
    local ok,value=pcall(function()return store:GetAsync('day_'..day..'_shard_'..shard)end)
    if not ok then return nil,'Shared challenge is temporarily unavailable' end
    if type(value)=='table' then
     total+=value.Total or 0
     for id,score in pairs(value.Contributors or {}) do contributors[id]=score;participants+=1 end
    end
   end
   current={Total=total,Participants=participants,Contributors=contributors,At=now};cache[day]=current
  end
  return {Day=day,Total=current.Total,Target=target,Participants=current.Participants,Contribution=current.Contributors[tostring(userId)] or 0,Complete=current.Total>=target,Ended=day<api.day(),EndsAt=(day+1)*86400}
 end
 return api
end
return Coop
