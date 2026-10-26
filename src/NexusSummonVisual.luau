-- Cosmetic reel sequence. The server has already awarded the winning card.
local Visual={}
function Visual.new(config)
 local api={}
 local pools={}
 for packId,pack in pairs(config.Packs) do
  local byRarity={};local weighted={};local weightSum=0
  for _,rarity in ipairs(config.Rarities) do
   local cards={}
   if (pack.Weights[rarity] or 0)>0 then
    for id,card in pairs(config.Cards) do
     if card.Rarity==rarity and card.Enabled~=false then table.insert(cards,id) end
    end
    table.sort(cards)
   end
   byRarity[rarity]=cards
   if #cards>0 then
    local weight=pack.Weights[rarity]
    weightSum+=weight
    table.insert(weighted,{Rarity=rarity,EndAt=weightSum})
   end
  end
  pools[packId]={Cards=byRarity,Weights=weighted,Total=weightSum}
 end
 function api.sequence(packId,winnerId,rng)
  local pool=pools[packId]
  if not pool or not config.Cards[winnerId] then return nil end
  local winner=config.Cards[winnerId]
  if winner.Enabled==false or (config.Packs[packId].Weights[winner.Rarity] or 0)<=0 then return nil end
  local count=38;local winningIndex=34;local ids={}
  for index=1,count do
   if index==winningIndex then ids[index]=winnerId
   else
    local pick=rng:NextNumber(0,pool.Total)
    local rarity=pool.Weights[#pool.Weights].Rarity
    for _,entry in ipairs(pool.Weights) do if pick<entry.EndAt then rarity=entry.Rarity;break end end
    local candidates=pool.Cards[rarity]
    ids[index]=candidates[rng:NextInteger(1,#candidates)]
   end
  end
  return ids,winningIndex
 end
 return api
end
return Visual
