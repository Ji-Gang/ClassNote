'use strict';
function parseWeeks(input) {
 const text=String(input).replace(/\s|第/g,'').replace(/[，、]/g,',').replace(/[~～—至]/g,'-');
 const weeks=new Set();
 for(const token of text.split(',')) {
  const match=token.match(/^(\d+)(?:-(\d+))?(?:周)?(单|双)?(?:周)?$/);
  if(!match)throw Error(`无法识别周次：${token}`);
  const a=+match[1],b=+(match[2]||match[1]);
  if(a<1||b>60||a>b)throw Error('教学周须在 1—60 之间，起始周不能晚于结束周');
  for(let n=a;n<=b;n++)if(!match[3]||(match[3]==='单'?n%2===1:n%2===0))weeks.add(n);
 }
 if(!weeks.size)throw Error('周次规则没有匹配任何教学周');
 return [...weeks].sort((a,b)=>a-b);
}
function parseDate(value){
 if(!/^\d{4}-\d{2}-\d{2}$/.test(value))throw Error('请填写有效日期');
 const d=new Date(value+'T00:00:00Z');if(!Number.isFinite(+d)||d.toISOString().slice(0,10)!==value)throw Error('日期无效');return d;
}
function validTime(t){return /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(t)}
function validateRows(rows){
 if(!rows.length)throw Error('至少需要一节课');const keys=new Set();
 for(const row of rows){parseDate(row.date);if(!String(row.course).trim())throw Error('课程名称不能为空');
  if(/^[=+@-]/.test(row.course.trim()))throw Error('课程名称不能以公式符号开头');
  if(!validTime(row.start)||!validTime(row.end)||row.start>=row.end)throw Error(`${row.course}：请填写有效起止时间，结束须晚于开始`);
  const key=JSON.stringify([row.date,row.course.trim(),row.start,row.end]);if(keys.has(key))throw Error('存在重复课程，请删除重复行');keys.add(key);
 }return rows;
}
function expand(config){
 const first=parseDate(config.week1Monday);if(first.getUTCDay()!==1)throw Error('学期第 1 周必须选择周一');
 const rows=[];
 for(const rule of config.rules){
  const day=+rule.weekday,a=+rule.periodStart,b=+rule.periodEnd;
  if(!Number.isInteger(day)||day<1||day>7||!Number.isInteger(a)||!Number.isInteger(b)||a<1||b>13||a>b)throw Error('星期或节次范围无效');
  const block=config.blocks?.[`${a}-${b}`];
  if(!block){let last='';for(let n=a;n<=b;n++){const t=config.periodTimes[n];if(!t||!validTime(t.start)||!validTime(t.end)||t.end<=t.start||last>t.start)throw Error(`请补齐或修正第 ${n} 节的时间`);last=t.end;}}
  const weeks=Array.isArray(rule.weeks)?parseWeeks(rule.weeks.join(',')):parseWeeks(rule.weeks);
  for(const week of weeks){const d=new Date(first);d.setUTCDate(d.getUTCDate()+(week-1)*7+day-1);rows.push({date:d.toISOString().slice(0,10),course:String(rule.course).trim(),start:block?block.start:config.periodTimes[a].start,end:block?block.end:config.periodTimes[b].end});}
 }return validateRows(rows).sort((a,b)=>a.date.localeCompare(b.date)||a.start.localeCompare(b.start));
}
function toCsv(rows){validateRows(rows);const quote=v=>'"'+String(v).replace(/"/g,'""')+'"';return '\uFEFFdate,course,start,end\r\n'+rows.map(r=>[r.date,r.course,r.start,r.end].map(quote).join(',')).join('\r\n')+'\r\n';}
if(typeof module!=='undefined')module.exports={parseWeeks,expand,toCsv,validateRows};
if(typeof document!=='undefined'){
 const $=id=>document.getElementById(id);let generated=false; let blocks={};
 function input(type,value){const e=document.createElement('input');e.type=type;e.value=value??'';return e;}
 function cell(row,node){const td=row.insertCell();td.append(node);return node;}
 function button(text,fn){const e=document.createElement('button');e.textContent=text;e.onclick=fn;return e;}
 function dirty(){generated=false;$('export').disabled=true;$('summary').textContent='配置已修改，请重新生成预览';}
 function courseRow(r={}){const tr=$('rules').insertRow();cell(tr,input('text',r.course));const sel=document.createElement('select');['周一','周二','周三','周四','周五','周六','周日'].forEach((label,i)=>{const o=new Option(label,i+1);sel.add(o)});sel.value=r.weekday||1;cell(tr,sel);cell(tr,input('number',r.periodStart||1));cell(tr,input('number',r.periodEnd||2));cell(tr,input('text',Array.isArray(r.weeks)?r.weeks.join(','):(r.weeks||'1-16')));cell(tr,button('删除',()=>{tr.remove();dirty()}));}
 function config(){return {week1Monday:$('semester').value,blocks,periodTimes:Object.fromEntries([...$('times').children].map((row,i)=>[i+1,{start:row.children[1].value,end:row.children[2].value}])),rules:[...$('rules').rows].map(tr=>{const e=tr.querySelectorAll('input,select');return {course:e[0].value,weekday:+e[1].value,periodStart:+e[2].value,periodEnd:+e[3].value,weeks:e[4].value}})};}
 function previewRow(r={}){const tr=$('preview').insertRow();['date','course','start','end'].forEach((key,i)=>cell(tr,input(['date','text','time','time'][i],r[key])));cell(tr,button('删除',()=>{tr.remove();count()}));}
 function rows(){return [...$('preview').rows].map(tr=>{const e=tr.querySelectorAll('input');return {date:e[0].value,course:e[1].value,start:e[2].value,end:e[3].value}})}
 function count(){$('summary').textContent=`共 ${$('preview').rows.length} 节课`;$('export').disabled=!generated||!$('preview').rows.length;}
 function download(name,text,type){const u=URL.createObjectURL(new Blob([text],{type}));const a=document.createElement('a');a.href=u;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(u),1000);}
 function run(fn){try{$('message').textContent='';fn()}catch(e){$('message').textContent=e.message}}
 for(let n=1;n<=13;n++){const label=document.createElement('label');const span=document.createElement('span');span.textContent=`第 ${n} 节`;label.append(span,input('time'),input('time'));$('times').append(label)}

 const preset=button('使用交大官方时间',()=>{const times={"1":{"end":"08:45","start":"08:00"},"2":{"end":"09:40","start":"08:55"},"3":{"end":"10:45","start":"10:00"},"4":{"end":"11:40","start":"10:55"},"5":{"end":"12:45","start":"12:00"},"6":{"end":"13:40","start":"12:55"},"7":{"end":"14:45","start":"14:00"},"8":{"end":"15:40","start":"14:55"},"9":{"end":"16:45","start":"16:00"},"10":{"end":"17:40","start":"16:55"},"11":{"end":"18:45","start":"18:00"},"12":{"end":"19:40","start":"18:55"}}; [...$('times').children].forEach((row,i)=>{row.children[1].value=times[i+1]?.start||'';row.children[2].value=times[i+1]?.end||''});blocks={'11-13':{start:'18:00',end:'20:20'}};dirty();$('message').textContent='已填入交大官方时间。11–13 节连堂为 18:00–20:20；第 13 节单独时间未公布，请勿单独使用。'});$('times').before(preset);
 courseRow();$('add').onclick=()=>{courseRow();dirty()};
 for(const id of ['times','semester','rules'])$(id).addEventListener('input',dirty);
 $('generate').onclick=()=>run(()=>{const result=expand(config());$('preview').replaceChildren();result.forEach(previewRow);generated=true;count()});
 $('extra').onclick=()=>run(()=>{if(!generated)throw Error('请先生成课表预览');previewRow();count()});
 $('export').onclick=()=>run(()=>download('schedule.csv',toCsv(rows()),'text/csv;charset=utf-8'));
 $('saveConfig').onclick=()=>download('timetable-config.json',JSON.stringify(config(),null,2),'application/json');
 $('load').onclick=()=>$('configFile').click();
 $('configFile').onchange=async()=>{try{const f=$('configFile').files[0];if(!f)return;const c=JSON.parse(await f.text());if(!Array.isArray(c.rules)||!c.periodTimes)throw Error('配置格式不正确');$('semester').value=c.week1Monday;blocks=c.blocks||{};[...$('times').children].forEach((row,i)=>{row.children[1].value=c.periodTimes[i+1]?.start||'';row.children[2].value=c.periodTimes[i+1]?.end||''});$('rules').replaceChildren();c.rules.forEach(courseRow);dirty();$('message').textContent='配置已读取，请检查时间并生成预览。'}catch(e){$('message').textContent=e.message}};
}
