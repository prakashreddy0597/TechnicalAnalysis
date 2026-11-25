"""Independent Python reference; standard library only, not used by R functions."""
import csv, math, statistics
from pathlib import Path
base=Path(__file__).resolve().parent
checks=[]
def ema(x,p):
 out=[x[0]]
 for v in x[1:]: out.append(out[-1]+2/(p+1)*(v-out[-1]))
 return out
def sma(x,p):
 return [None]*(p-1)+[None if any(v is None for v in x[i-p+1:i+1]) else sum(x[i-p+1:i+1])/p for i in range(p-1,len(x))]
def rsi(x,p,literal):
 moves=[b-a for a,b in zip(x,x[1:])]; g=[max(0,v) for v in moves]; l=[max(0,-v) for v in moves]
 ag=sum(g[:p])/p; al=sum(l[:p])/p; out=[None]*len(x)
 def score(): return 50 if ag==al==0 else 100 if al==0 else 100*ag/(ag+al)
 if not literal: out[p]=score()
 for i in range(p if literal else p+1,len(x)):
  ag=((p-1)*ag+g[i-1])/p; al=((p-1)*al+l[i-1])/p; out[i]=score()
 return out
def compare(label,a,b):
 assert len(a)==len(b),(label,'length')
 diffs=[]
 for i,(v,w) in enumerate(zip(a,b)):
  w=None if w=='' else float(w)
  assert (v is None)==(w is None),(label,i,v,w)
  if v is not None:
   diff=abs(v-w); assert diff<1e-8,(label,i,v,w); diffs.append(diff)
 checks.append([label,len(a),max(diffs,default=0),'PASS'])
for symbol in ['AAPL','MSFT','GOOGL']:
 rows=list(csv.DictReader(open(base/'data'/f'{symbol}.csv')))
 actual=list(csv.DictReader(open(base/'outputs'/f'{symbol}_indicators.csv')))
 x=[float(r['Close']) for r in rows]; n=len(x)
 expected={'SMA5':sma(x,5),'SMA20':sma(x,20),'EMA12':ema(x,12),'EMA26':ema(x,26)}
 m=[a-b for a,b in zip(expected['EMA12'],expected['EMA26'])]; signal=ema(m,9)
 expected.update(MACD=m,Signal=signal,Histogram=[a-b for a,b in zip(m,signal)],RSI_spec14=rsi(x,14,True),RSI_Wilder14=rsi(x,14,False))
 rr=expected['RSI_spec14']; finite=[v for v in rr if v is not None]; lo,hi=min(finite),max(finite)
 raw=[None if v is None else (v-lo)/(hi-lo) for v in rr]
 k=sma(raw,3); expected.update(StochRSI_spec_K=k,StochRSI_spec_D=sma(k,3))
 rr=expected['RSI_Wilder14']; raw=[None]*n
 for i in range(13,n):
  w=rr[i-13:i+1]
  if None not in w and max(w)>min(w): raw[i]=(rr[i]-min(w))/(max(w)-min(w))
 k=sma(raw,3); expected.update(StochRSI_rolling_K=k,StochRSI_rolling_D=sma(k,3))
 for key,vals in expected.items(): compare(f'{symbol}/{key}',vals,[r[key] for r in actual])
 summary=next(r for r in csv.DictReader(open(base/'outputs/latest_summary.csv')) if r['Symbol']==symbol)
 compare(f'{symbol}/PopulationSD',[statistics.pstdev(x)],[summary['PopulationSD']])
 y=x[-21:]; t=list(range(1,22)); ym=sum(y)/21; tm=11
 slope=sum((a-tm)*(b-ym) for a,b in zip(t,y))/sum((a-tm)**2 for a in t)
 compare(f'{symbol}/RegressionSlope',[slope],[summary['RegressionSlope']])
 for i,row in enumerate(actual):
  for left,right,col,under in [('SMA5','SMA20','SMA_cross',False),('MACD','Signal','MACD_cross',False)]:
   a,b=expected[left],expected[right]; val='None'
   if i and None not in (a[i],b[i],a[i-1],b[i-1]):
    if a[i]>b[i] and a[i-1]<=b[i-1]:val='Up'
    elif a[i]<b[i] and a[i-1]>=b[i-1]:val='Down'
   assert row[col]==val,(symbol,i,col)
 checks.append([f'{symbol}/crossover events',n,0,'PASS'])
 # Verify weekly OHLCV against independently grouped dates.
 from datetime import date
 groups={}
 for row in rows:
  d=date.fromisoformat(row['Date']); key=d.isocalendar()[:2]; groups.setdefault(key,[]).append(row)
 weekly=list(csv.DictReader(open(base/'outputs'/f'{symbol}_weekly.csv')))
 assert len(weekly)==len(groups)
 for out,g in zip(weekly,groups.values()):
  assert out['Date']==g[-1]['Date']
  for col,val in [('Open',float(g[0]['Open'])),('High',max(float(r['High']) for r in g)),('Low',min(float(r['Low']) for r in g)),('Close',float(g[-1]['Close'])),('Volume',sum(float(r['Volume']) for r in g))]:
   assert abs(float(out[col])-val)<1e-8
 checks.append([f'{symbol}/weekly OHLCV',len(weekly),0,'PASS'])
with open(base/'evidence/independent_checks.csv','w',newline='') as f:
 w=csv.writer(f,lineterminator='\n'); w.writerow(['Check','Values','MaximumAbsoluteDifference','Status']); w.writerows(checks)
print(f'{len(checks)} independent series/aggregation checks passed; maximum numeric difference {max(r[2] for r in checks):.3g}.')
