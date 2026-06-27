import json, subprocess, os
BASE="/Users/chihoong/Downloads/choice-design/bench"
d=json.load(open(os.path.join(BASE,"idefix_vot_export.json")))
des=d["des"]                 # 40 rows x [time, price]
betas_time=d["betas_time"]   # 21 values; price beta fixed at -1
idfx=d["dberr_idefix"]
lev_time=[30,36,42,48,54]; lev_price=[1,4,7,10,13]
ti={v:i for i,v in enumerate(lev_time)}; pi={v:i for i,v in enumerate(lev_price)}
# Build evalRowsIdx: 20 sets x 2 alts x 2 attrs(level indices)
rows=[]
for s in range(20):
    a1=des[2*s]; a2=des[2*s+1]
    rows.append([[ti[a1[0]], pi[a1[1]]], [ti[a2[0]], pi[a2[1]]]])
cf=[]
for bt in betas_time:
    spec={
        "name":"idefix VOT eval","rows":20,"alts":2,"method":"efficient",
        "alternatives":[{"name":"A"},{"name":"B"}],
        "attributes":[
            {"name":"time","type":"continuous","coding":"cont","levels":["30","36","42","48","54"]},
            {"name":"price","type":"continuous","coding":"cont","levels":["1","4","7","10","13"]}],
        "priorVec":[bt, -1.0],
        "evalRowsIdx":rows
    }
    sp=os.path.join(BASE,"_vot_tmp.json")
    json.dump(spec,open(sp,"w"))
    out=subprocess.run(["/opt/homebrew/bin/node","cf_headless.mjs","_vot_tmp.json"],
                       cwd=BASE,capture_output=True,text=True)
    if out.returncode!=0:
        print("ERR beta",bt,out.stderr[:500]); break
    r=json.loads(out.stdout); cf.append(r["derr"])
print(f"{'beta_time':>10} {'idefix':>16} {'choiceforge':>16} {'rel.diff':>12}")
maxrel=0
for bt,a,b in zip(betas_time,idfx,cf):
    rel=abs(a-b)/abs(a) if a else abs(a-b)
    maxrel=max(maxrel,rel)
    print(f"{bt:10.5f} {a:16.10f} {b:16.10f} {rel:12.3e}")
print("MAX rel diff CF vs idefix over 21 points:", maxrel)
# also dump K, paramLabels from last run
print("paramLabels:", r["paramLabels"], "K=",r["K"], "J=",r["J"], "Sn=",r["Sn"])
