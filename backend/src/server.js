import 'dotenv/config';
import { createApp } from './app.js';
import { connectStore } from './repository.js';
let store;
try {
  store=await connectStore();
  const app=createApp({store,token:process.env.CRAWLER_API_TOKEN,origins:process.env.CORS_ORIGINS||'*'});
  const server=app.listen(Number(process.env.PORT||3000),'0.0.0.0',()=>console.log('XSMB API ready on port '+(process.env.PORT||3000)));
  let closing=false;
  const shutdown=()=>{if(closing)return;closing=true;server.close(async()=>{await store.close();process.exit(0);});setTimeout(()=>process.exit(1),10000).unref();};
  process.on('SIGTERM',shutdown);process.on('SIGINT',shutdown);
} catch(error) {
  console.error('XSMB startup failed: '+(error.name||'Error')+'. Kiểm tra MongoDB và biến môi trường.');
  if(store) await store.close();process.exitCode=1;
}
