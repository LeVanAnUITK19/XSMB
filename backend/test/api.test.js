import test from 'node:test';import assert from 'node:assert/strict';import {once} from 'node:events';
import {createApp} from '../src/app.js';import {mergeDraw} from '../src/domain.js';import {body} from './fixtures.js';
async function context(t){
 let value=null,reads=0;const store={ping:async()=>({ok:1}),list:async()=>{reads++;return {data:value?[value]:[],pagination:{page:1,limit:20,total:value?1:0}};},upsert:async(draw)=>{value=mergeDraw(value,draw);return value;}};
 const server=createApp({store,token:'test-token'}).listen(0,'127.0.0.1');await once(server,'listening');t.after(()=>new Promise(resolve=>server.close(resolve)));
 const url='http://127.0.0.1:'+server.address().port;return {url,reads:()=>reads,request:(path,options)=>fetch(url+path,options)};
}
test('health, public results, cached reads and write invalidation',async t=>{
 const api=await context(t);assert.equal((await api.request('/healthz')).status,200);
 assert.equal((await api.request('/api/results')).headers.get('x-cache'),'MISS');assert.equal((await api.request('/api/results')).headers.get('x-cache'),'HIT');assert.equal(api.reads(),1);
 const response=await api.request('/api/results',{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer test-token'},body:JSON.stringify(body())});assert.equal(response.status,200);
 const fresh=await api.request('/api/results');assert.equal(fresh.headers.get('x-cache'),'MISS');assert.equal((await fresh.json()).data[0].provinces[0].full.DB[0],'09621');
});
test('writes require token; invalid filters and malformed JSON are rejected',async t=>{
 const api=await context(t);assert.equal((await api.request('/api/results',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body())})).status,401);
 for(const path of ['/api/results?date=2026-02-30','/api/results?region=mien-nam','/api/results?page=0','/api/results?limit=999'])assert.equal((await api.request(path)).status,400);
 const response=await api.request('/api/results',{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer test-token'},body:'{broken'});assert.equal(response.status,400);
});
