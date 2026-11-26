import * as cheerio from 'cheerio';
import { rules, symbol, drawStatus, validDate } from './domain.js';
export const sourceUrl='https://xosomb.com.vn/xo-so-truyen-thong';
const labels={'DAC BIET':'DB','GIAI NHAT':'G1','GIAI NHI':'G2','GIAI BA':'G3','GIAI TU':'G4','GIAI NAM':'G5','GIAI SAU':'G6','GIAI BAY':'G7'};
const plain=value=>value.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/Đ/g,'D').replace(/\s+/g,' ').trim().toUpperCase();
export function parseOfficial(html,date) {
  if(!validDate(date)) throw new Error('Ngày crawl không hợp lệ');
  const [y,m,d]=date.split('-');const target=d+'-'+m+'-'+y;const $=cheerio.load(html);
  const tables=$('table.table_prim').toArray().filter(table=>$(table).find('thead').text().includes('Ngày '+target));
  if(tables.length!==1) return null;
  const table=$(tables[0]);const full=Object.fromEntries(Object.keys(rules).map(key=>[key,[]]));let current=null;
  table.find('tbody tr').each((_i,row)=>{
    const title=$(row).children('td.xs_lb').first();
    if(title.length) current=labels[plain(title.text())]??null;
    if(!current) return;
    $(row).children('td').not('.xs_lb').each((_j,cell)=>{
      const number=$(cell).text().replace(/\s+/g,'').trim();
      if(new RegExp('^[0-9]{'+rules[current][1]+'}$').test(number)) full[current].push(number);
    });
  });
  if(Object.entries(rules).some(([key,[count]])=>full[key].length>count)) throw new Error('Nguồn có quá nhiều kết quả; không gửi dữ liệu');
  const header=table.find('thead').text().toUpperCase();
  const symbols=[...header.matchAll(/\b\d{1,2}[A-Z]{1,3}\b/g)].map(match=>symbol(match[0])).filter(Boolean);
  return {date,region:'mien-bac',provinces:[{province:'Miền Bắc',full,specialSymbols:[...new Set(symbols)]}],status:drawStatus(full),source:sourceUrl};
}
export async function crawlDate(date,{fetchImpl=fetch}={}) {
  const headers={'User-Agent':'XSMB-Results/1.0 (+official-results-reader)','Accept':'text/html'};
  const response=await fetchImpl(sourceUrl,{headers,signal:AbortSignal.timeout(30000)});
  if(!response.ok) throw new Error('Nguồn kết quả trả HTTP '+response.status);
  const current=parseOfficial(await response.text(),date);
  if(current) return current;
  const [y,m,d]=date.split('-');
  const historical=await fetchImpl('https://xosomb.com.vn/home/ListResult',{method:'POST',headers:{...headers,'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({ngay:d+'/'+m+'/'+y,soluong:'1',loaihinh:'1'}),signal:AbortSignal.timeout(30000)});
  if(!historical.ok) throw new Error('Nguồn theo ngày trả HTTP '+historical.status);
  return parseOfficial(await historical.text(),date);
}
