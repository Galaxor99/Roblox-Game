-- Re-execute the real server with unpublished-Studio DataStore behavior.
do
 local studioPlayers={PlayerAdded=signal(),PlayerRemoving=signal(),list={}}
 function studioPlayers:GetPlayers()return self.list end
 local studioServices=table.clone(services)
 studioServices.Players=studioPlayers
 studioServices.DataStoreService={
  GetDataStore=function()error('You must publish this place to the web to access DataStore.')end,
  GetOrderedDataStore=function()error('You must publish this place to the web to access DataStore.')end,
 }
 local game={JobId='',GetService=function(_,name)return studioServices[name]end,BindToClose=function()end}
 -- SECOND_SERVER_SOURCE
 test('unpublished Studio starts remotes and grants an unsaved test profile',function()
  local visitor={UserId=991,Name='StudioTester',Parent=studioPlayers,CharacterAdded=signal()}
  function visitor:FindFirstChild()return nil end
  function visitor:Kick(reason)self.Kicked=reason end
  table.insert(studioPlayers.list,visitor)
  studioPlayers.PlayerAdded:Fire(visitor)
  assert(not visitor.Kicked)
  clock+=1
  local result=byName.Request.OnServerInvoke(visitor,'Get')
  assert(result.Ok and result.Profile.SessionOnly)
  assert(result.Profile.Collection.recruit==1 and result.Profile.Coins==Config.FreeStarterCoins)
  studioPlayers.PlayerRemoving:Fire(visitor)
 end)
end
print('Completed '..count..' tests including unpublished Studio startup')
