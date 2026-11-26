export const date='2026-11-26';
export const full=()=>({DB:['09621'],G1:['94511'],G2:['45861','12148'],G3:['71783','78735','51470','65528','40137','81658'],G4:['4313','7769','7940','7024'],G5:['2664','3366','7276','1676','5651','4129'],G6:['150','831','685'],G7:['82','54','95','34']});
export const symbols=['4LU','11LU','12LU','3LU','5LU','7LU'];
export const body=()=>({date,region:'mien-bac',provinces:[{province:'Miền Bắc',full:full(),specialSymbols:symbols}]});
export function html() {
 const labels={DB:'ĐẶC BIỆT',G1:'GIẢI NHẤT',G2:'GIẢI NHÌ',G3:'GIẢI BA',G4:'GIẢI TƯ',G5:'GIẢI NĂM',G6:'GIẢI SÁU',G7:'GIẢI BẢY'};
 const rows=Object.entries(full()).map(([key,values])=>'<tr><td class="xs_lb">'+labels[key]+'</td>'+values.map(number=>'<td>'+number+'</td>').join('')+'</tr>').join('');
 return '<table class="table_prim"><thead><tr><th>Ngày 26-11-2026 * Ký hiệu trúng giải Đặc biệt: '+symbols.join(' - ')+'</th></tr></thead><tbody>'+rows+'</tbody></table>';
}
