export const rules = Object.freeze({ DB:[1,5], G1:[1,5], G2:[2,5], G3:[6,5], G4:[4,4], G5:[6,4], G6:[3,3], G7:[4,2] });
export const todayVN = () => new Intl.DateTimeFormat('sv-SE',{timeZone:'Asia/Ho_Chi_Minh'}).format(new Date());
export function validDate(value) {
  if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(value+'T00:00:00.000Z');
  return !Number.isNaN(date.valueOf()) && date.toISOString().slice(0,10)===value;
}
export function symbol(value) {
  const raw=String(value??'').replace(/\s+/g,'').toUpperCase();
  const match=raw.match(/^0*(\d{1,2})([A-Z]{1,3})$/);
  if(!match || +match[1]<1 || +match[1]>25) return '';
  return String(+match[1])+match[2];
}
export function drawStatus(full) {
  return Object.entries(rules).every(([key,[count,digits]])=>Array.isArray(full[key])&&full[key].length===count&&full[key].every(number=>new RegExp('^[0-9]{'+digits+'}$').test(number)))?'complete':Object.values(full).some(values=>values.length)?'partial':'pending';
}
export function normalizeDraw(body) {
  if(!body || !validDate(body.date) || body.date>todayVN()) throw Object.assign(new Error('Ngày mở thưởng không hợp lệ'),{status:400});
  if(body.region && body.region!=='mien-bac') throw Object.assign(new Error('API này chỉ lưu kết quả miền Bắc'),{status:400});
  const province=body.provinces?.[0];
  if(!province || body.provinces.length!==1 || !province.full || typeof province.full!=='object') throw Object.assign(new Error('Cần đúng một bảng kết quả miền Bắc'),{status:400});
  const full={};
  for(const [key,[count,digits]] of Object.entries(rules)) {
    const values=province.full[key]??[];
    if(!Array.isArray(values)||values.length>count||values.some(number=>typeof number!=='string'||!new RegExp('^[0-9]{'+digits+'}$').test(number))) throw Object.assign(new Error('Sai cấu trúc kết quả '+key),{status:400});
    full[key]=values;
  }
  const raw=province.specialSymbols??[];
  if(!Array.isArray(raw)||raw.length>25||raw.some(value=>!symbol(value))||new Set(raw.map(symbol)).size!==raw.length) throw Object.assign(new Error('Ký hiệu giải đặc biệt không hợp lệ'),{status:400});
  return {date:new Date(body.date+'T00:00:00.000Z'),region:'mien-bac',provinces:[{province:'Miền Bắc',full,specialSymbols:raw.map(symbol)}],source:'https://xosomb.com.vn/xo-so-truyen-thong',status:drawStatus(full)};
}
export function mergeDraw(previous,incoming) {
  if(!previous) return incoming;
  const old=previous.provinces[0];const next=incoming.provinces[0];
  const full=Object.fromEntries(Object.keys(rules).map(key=>[key,next.full[key].length>=old.full[key].length&&next.full[key].length?next.full[key]:old.full[key]]));
  return {...incoming,provinces:[{province:'Miền Bắc',full,specialSymbols:next.specialSymbols.length>=old.specialSymbols.length&&next.specialSymbols.length?next.specialSymbols:old.specialSymbols}],status:drawStatus(full)};
}
