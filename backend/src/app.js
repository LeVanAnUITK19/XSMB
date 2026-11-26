import express from 'express';
import cors from 'cors';
import compression from 'compression';
import { timingSafeEqual } from 'node:crypto';
import { normalizeDraw, validDate, todayVN } from './domain.js';
export function createApp({store,token,origins='*',now=Date.now}) {
  if(!token) throw new Error('Thiếu CRAWLER_API_TOKEN');
  const app=express();const cache=new Map();
  app.disable('x-powered-by');app.set('query parser','simple');
  app.use(cors({origin:origins==='*'?true:origins.split(',').map(value=>value.trim())}));
  app.use(compression());app.use(express.json({limit:'128kb'}));
  async function health(_req,res) { try { await store.ping();res.json({status:'ok',service:'xsmb-api'}); } catch {res.status(503).json({error:'Database chưa sẵn sàng'});} }
  app.get(['/healthz','/api/results/health'],health);
  app.get(['/api/results','/api/results/filter','/api/results/filter-province'],async(req,res,next)=>{
    try {
      const {date,region,province}=req.query;
      if(date!==undefined&&!validDate(date)) return res.status(400).json({error:'Ngày không hợp lệ (YYYY-MM-DD)'});
      if(region!==undefined&&region!=='mien-bac') return res.status(400).json({error:'Chỉ hỗ trợ mien-bac'});
      if(province!==undefined&&(typeof province!=='string'||province.length>80)) return res.status(400).json({error:'Đài không hợp lệ'});
      const page=Number(req.query.page??1),limit=Number(req.query.limit??20);
      if(!Number.isSafeInteger(page)||page<1||page>100000||!Number.isSafeInteger(limit)||limit<1||limit>100) return res.status(400).json({error:'Phân trang không hợp lệ'});
      const key=JSON.stringify({date,page,limit,province});const hit=cache.get(key);
      const historical=Boolean(date&&date<todayVN());
      res.set('Cache-Control',historical?'public, max-age=300':'public, max-age=10');
      if(hit&&hit.expires>now()) { res.set('X-Cache','HIT');return res.json(hit.value); }
      const value=await store.list({date,page,limit,province});
      if(cache.size>=300) cache.delete(cache.keys().next().value);
      cache.set(key,{expires:now()+(historical?300000:15000),value});res.set('X-Cache','MISS');res.json(value);
    } catch(error) { next(error); }
  });
  function authorize(req,res,next) {
    const expected=Buffer.from('Bearer '+token),provided=Buffer.from(req.get('authorization')||'');
    if(provided.length!==expected.length||!timingSafeEqual(provided,expected)) return res.status(401).json({error:'Unauthorized'});
    next();
  }
  async function save(req,res,next) {
    try { const draw=normalizeDraw(req.body);const saved=await store.upsert(draw);cache.clear();res.status(200).json(saved); }
    catch(error) { next(error); }
  }
  app.post('/api/results',authorize,save);app.put('/api/results',authorize,save);
  app.use((_req,res)=>res.status(404).json({error:'Không tìm thấy endpoint'}));
  app.use((error,_req,res,_next)=>{
    const status=error.status>=400&&error.status<500?error.status:500;
    res.status(status).json({error:status===500?'Không thể xử lý dữ liệu lúc này':error.message});
  });
  return app;
}
