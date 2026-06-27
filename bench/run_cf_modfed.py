import json, subprocess, os
BASE="/Users/chihoong/Downloads/choice-design/bench"
d=json.load(open(os.path.join(BASE,"idefix_modfed_export.json")))
mu=d["mu"]; idfx=d["derr_idefix"][0]; rows=d["rows"]
spec={
  "name":"idefix Modfed dummy eval","rows":8,"alts":2,"method":"efficient",
  "alternatives":[{"name":"A"},{"name":"B"}],
  "attributes":[
    {"name":"V1","coding":"dummy","levels":["l1","l2","l3","l4"]},
    {"name":"V2","coding":"dummy","levels":["l1","l2"]},
    {"name":"V3","coding":"dummy","levels":["l1","l2","l3"]}],
  "priorVec":mu,
  "evalRowsIdx":rows
}
sp=os.path.join(BASE,"eval_idefix_modfed.json")
json.dump(spec,open(sp,"w"))
out=subprocess.run(["/opt/homebrew/bin/node","cf_headless.mjs","eval_idefix_modfed.json"],
                   cwd=BASE,capture_output=True,text=True)
if out.returncode!=0:
    print("ERR",out.stderr); raise SystemExit(1)
r=json.loads(out.stdout)
print("paramLabels:", r["paramLabels"], "K=",r["K"])
print(f"idefix      D-error: {idfx:.10f}")
print(f"choiceforge D-error: {r['derr']:.10f}")
print(f"rel diff: {abs(idfx-r['derr'])/idfx:.3e}")
