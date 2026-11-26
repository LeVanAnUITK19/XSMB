import 'dotenv/config';
import { crawlDate } from '../src/crawler.js';
import { todayVN, rules, validDate } from '../src/domain.js';
const method=(process.argv[2]||'PUT').toUpperCase();const date=process.argv.find(value=>value.startsWith('--date='))?.slice(7)||todayVN();
try {
  if(!['POST','PUT'].includes(method)||!validDate(date)) throw new Error('Dùng POST hoặc PUT và --date=YYYY-MM-DD');
  if(!process.env.API_URL||!process.env.CRAWLER_API_TOKEN) throw new Error('Thiếu API_URL hoặc CRAWLER_API_TOKEN');
  let data=await crawlDate(date);
  if(!data&&method==='PUT') {console.log('Chưa có kết quả ngày '+date+'; không ghi đè dữ liệu cũ');process.exit(0);}
  data??={date,region:'mien-bac',provinces:[{province:'Miền Bắc',full:Object.fromEntries(Object.keys(rules).map(key=>[key,[]])),specialSymbols:[]}]};
  const api=new URL(process.env.API_URL);if(api.username||api.password) throw new Error('API_URL không được chứa tài khoản');
  let lastStatus;
  for(let attempt=0;attempt<4;attempt++) {
    try {
      const response=await fetch(api,{method,headers:{'Content-Type':'application/json','Authorization':'Bearer '+process.env.CRAWLER_API_TOKEN},body:JSON.stringify(data),signal:AbortSignal.timeout(60000)});
      if(response.ok) {console.log(method+' XSMB '+date+' success ('+(data.status||'pending')+')');process.exit(0);}
      lastStatus=response.status;if([400,401,403].includes(response.status)) break;
    } catch {lastStatus='network';}
    if(attempt<3) await new Promise(resolve=>setTimeout(resolve,15000));
  }
  throw new Error('API ghi kết quả thất bại: '+lastStatus);
} catch(error) {console.error(error.message);process.exitCode=1;}
