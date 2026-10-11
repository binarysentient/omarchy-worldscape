import json, urllib.request, base64, time
from pathlib import Path
BASE='http://127.0.0.1:9517'
def req(method,path,body=None):
 data=None if body is None else json.dumps(body).encode()
 r=urllib.request.urlopen(urllib.request.Request(BASE+path,data=data,headers={'Content-Type':'application/json'},method=method))
 return json.load(r)['value']
sid=req('POST','/session',{'capabilities':{'alwaysMatch':{'browserName':'chrome','goog:chromeOptions':{'args':['--headless','--no-sandbox','--disable-dev-shm-usage','--window-size=1440,1200']},'goog:loggingPrefs':{'browser':'ALL'}}}})['sessionId']
def call(method,path,body=None): return req(method,'/session/'+sid+path,body)
def js(script): return call('POST','/execute/sync',{'script':script,'args':[]})
try:
 call('POST','/url',{'url':Path('docs/design-studies/sol/index.html').resolve().as_uri()})
 assert js('return document.querySelectorAll(".city").length')==3
 assert js('return document.querySelectorAll("#calendar .today").length')==1
 Path('docs/design-studies/sol/preview-desktop.png').write_bytes(base64.b64decode(call('GET','/screenshot')))
 results=[]
 for theme in ['tokyo-night','catppuccin','gruvbox','nord','osaka-jade','everforest','catppuccin-latte','flexoki-light','custom']:
  for weather in ['clear','rain','snow','fog','storm']:
   for hour in [3,8,13,18,22]:
    results.append(js(f'state.theme="{theme}";state.weather="{weather}";state.hour={hour};render();return {{theme:state.theme,weather:state.weather,hour:state.hour,match:document.getElementById("match-label").textContent,cities:document.querySelectorAll(".city").length}}'))
 assert all(x['cities']==3 for x in results)
 js('state={...defaults,theme:"catppuccin-latte",hour:22};fill();render();')
 time.sleep(.8)
 Path('docs/design-studies/sol/preview-light-night.png').write_bytes(base64.b64decode(call('GET','/screenshot')))
 before=js('state.theme="custom";state.customBg="#202d29";render();return document.documentElement.style.getPropertyValue("--bg")')
 after=js('state.customBg="#ffffff";state.customFg="#111111";state.customAccent="#205ea6";render();return document.documentElement.style.getPropertyValue("--bg")')
 assert before!=after
 js('state={...defaults,density:"compact",calendar:false,format:"12",units:"f",bar:"clock",motion:false};fill();render();')
 assert js('return document.getElementById("widget").classList.contains("compact") && document.getElementById("widget").classList.contains("no-calendar") && document.getElementById("home-time").textContent.includes("PM")')
 call('POST','/refresh',{})
 assert js('return document.getElementById("widget").classList.contains("compact")')
 js('document.getElementById("customize").click();document.getElementById("reset").click();document.getElementById("done").click();')
 assert js('return !document.getElementById("settings").open && !document.getElementById("widget").classList.contains("compact")')
 call('POST','/window/rect',{'width':900,'height':1100})
 assert js('return document.documentElement.scrollWidth<=window.innerWidth'), '900px horizontal overflow'
 call('POST','/window/rect',{'width':390,'height':1100})
 js('state.weather="rain";render();')
 assert js('return document.documentElement.scrollWidth<=window.innerWidth'), 'Mobile horizontal overflow'
 Path('docs/design-studies/sol/preview-mobile.png').write_bytes(base64.b64decode(call('GET','/screenshot')))
 logs=call('POST','/log',{'type':'browser'})
 errors=[l for l in logs if l['level']=='SEVERE']
 assert not errors, errors
 print(f'PASS: {len(results)} theme/weather/hour renders; custom palette; compact/calendar/format/units/motion; persistence; reset/dialog; mobile overflow. No severe browser console errors.')
finally: call('DELETE','')
