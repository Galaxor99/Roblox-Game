import { LuauState } from 'luau-web';
import { readFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const vm=await LuauState.createAsync({print: (...args)=>console.log(...args)});
try {
 const files=(await readdir(root+'src')).filter(x=>x.endsWith('.luau'));
 for (const file of files) vm.loadstring(await readFile(root+'src/'+file,'utf8'),file,true);
 console.log(`Compiled ${files.length} Luau source files`);
 const load=async name=>`(function()\n${await readFile(root+'src/'+name+'.luau','utf8')}\nend)()`;
 const source=`local Color3={fromRGB=function(r,g,b)return {r=r,g=g,b=b}end}
 local roster=${await load('NexusRoster')}
 local script={Parent={WaitForChild=function(_,name)return name end}}
 local function require(name) if name=='NexusRoster' then return roster end;error('Unexpected dependency '..name) end
 local Config=${await load('NexusConfig')}
 local P=${await load('NexusProgression')}
 local Persistence=${await load('NexusPersistence')}
 ${await readFile(root+'tests/rules.luau','utf8')}
 ${ (await readFile(root+'tests/server.luau','utf8')).replace('-- SERVER_SOURCE_INSERT', await readFile(root+'src/NexusServer.server.luau','utf8')) }`;
 await vm.loadstring(source,'rules',true)();
} finally {vm.destroy();}
