import { MongoClient } from 'mongodb';
import { rules } from './domain.js';
export async function connectStore(env=process.env) {
  if(!env.MONGODB_URI) throw new Error('Thiếu MONGODB_URI');
  const client=new MongoClient(env.MONGODB_URI,{serverSelectionTimeoutMS:15000,maxPoolSize:10});
  await client.connect();
  const db=client.db(env.MONGODB_DB||'xsmb');
  const collection=db.collection(env.MONGODB_COLLECTION||'results');
  await collection.createIndex({date:1,region:1},{unique:true});
  return {
    ping:()=>db.command({ping:1}), close:()=>client.close(),
    async list({date,page,limit,province}) {
      const filter={region:'mien-bac'};
      if(date) filter.date=new Date(date+'T00:00:00.000Z');
      if(province) filter['provinces.province']=province;
      const [data,total]=await Promise.all([collection.find(filter).sort({date:-1}).skip((page-1)*limit).limit(limit).toArray(),collection.countDocuments(filter)]);
      return {data,pagination:{page,limit,total,totalPages:Math.ceil(total/limit),hasNext:page*limit<total}};
    },
    async upsert(draw) {
      const pipeline=buildUpdatePipeline(draw);
      for(let attempt=0;attempt<3;attempt++) {
        try { return await collection.findOneAndUpdate({date:draw.date,region:'mien-bac'},pipeline,{upsert:true,returnDocument:'after',includeResultMetadata:false}); }
        catch(error) { if(error.code!==11000||attempt===2) throw error; }
      }
    }
  };
}

export function buildUpdatePipeline(draw) {
      const incoming=draw.provinces[0];
      const full=Object.fromEntries(Object.keys(rules).map(key=>{
        const previous={$ifNull:['$$previous.full.'+key,[]]};
        return [key,{$cond:[{$and:[{$gt:[incoming.full[key].length,0]},{$gte:[incoming.full[key].length,{$size:previous}]}]},{$literal:incoming.full[key]},previous]}];
      }));
  const pipeline=[{$set:{date:draw.date,region:'mien-bac',source:draw.source,createdAt:{$ifNull:['$createdAt','$$NOW']},updatedAt:'$$NOW',provinces:{$let:{vars:{previous:{$ifNull:[{$arrayElemAt:['$provinces',0]},{}]}},in:[{province:'Miền Bắc',full,specialSymbols:{$cond:[{$gte:[incoming.specialSymbols.length,{$size:{$ifNull:['$$previous.specialSymbols',[]]}}]},{$literal:incoming.specialSymbols},{$ifNull:['$$previous.specialSymbols',[]]}]}}]}}}},{$set:{status:{$let:{vars:{current:{$arrayElemAt:['$provinces',0]}},in:{$cond:[{$and:Object.entries(rules).map(([key,[count]])=>({$eq:[{$size:'$$current.full.'+key},count]}))},'complete',{$cond:[{$or:Object.keys(rules).map(key=>({$gt:[{$size:'$$current.full.'+key},0]}))},'partial','pending']}]}}}}}];

  return pipeline;
}
