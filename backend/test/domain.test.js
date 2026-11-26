import test from 'node:test';import assert from 'node:assert/strict';
import {normalizeDraw,mergeDraw,validDate,symbol} from '../src/domain.js';
import {parseOfficial} from '../src/crawler.js';
import {body,full,html,symbols} from './fixtures.js';
test('official northern table: 27 results and symbols, preserving leading zero',()=>{
 const draw=parseOfficial(html(),'2026-11-26');assert.equal(draw.status,'complete');assert.deepEqual(draw.provinces[0].full,full());assert.deepEqual(draw.provinces[0].specialSymbols,symbols);
});
test('does not take results from a different date',()=>assert.equal(parseOfficial(html(),'2026-11-25'),null));
test('rowspan continuation preserves all six G3 results',()=>{
 const source=html().replace('<td>65528</td>','</tr><tr><td>65528</td>');
 assert.equal(parseOfficial(source,'2026-11-26').provinces[0].full.G3.length,6);
});
test('invalid data is not silently accepted',()=>{
 for(const value of ['123456','Chờ','abcde']){const valueBody=body();valueBody.provinces[0].full.DB=[value];assert.throws(()=>normalizeDraw(valueBody));}
 const mixed=body();mixed.region='mien-trung';assert.throws(()=>normalizeDraw(mixed));
});
test('rejects invalid dates and duplicate symbols',()=>{
 assert.equal(validDate('2026-02-30'),false);assert.equal(validDate('2024-02-29'),true);
 const draw=body();draw.provinces[0].specialSymbols=['4LU','4LU','12LU','3LU','5LU','7LU'];assert.throws(()=>normalizeDraw(draw));
 assert.equal(symbol('04 lu'),'4LU');
});
test('a seed or partial crawl never erases a complete result',()=>{
 const previous=normalizeDraw(body());const pending=body();for(const key of Object.keys(pending.provinces[0].full))pending.provinces[0].full[key]=[];pending.provinces[0].specialSymbols=[];
 const merged=mergeDraw(previous,normalizeDraw(pending));assert.equal(merged.status,'complete');assert.deepEqual(merged.provinces[0].full,previous.provinces[0].full);assert.deepEqual(merged.provinces[0].specialSymbols,symbols);
});

test('partial symbols do not erase the complete published list',()=>{
 const previous=normalizeDraw(body());const next=body();next.provinces[0].specialSymbols=['4LU'];
 assert.deepEqual(mergeDraw(previous,normalizeDraw(next)).provinces[0].specialSymbols,symbols);
});
test('server can retain published symbols for special ticket editions',()=>{
 const next=body();next.provinces[0].specialSymbols=Array.from({length:10},(_,i)=>String(i+1)+'LU');
 assert.equal(normalizeDraw(next).provinces[0].specialSymbols.length,10);
});
