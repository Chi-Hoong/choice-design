import json, subprocess, os
BASE="/Users/chihoong/Downloads/choice-design/bench"
d=json.load(open(os.path.join(BASE,"idefix_modfed2_export.json")))
mu=d["mu"]; idfx=d["derr_modfed"][0] if isinstance(d["derr_modfed"],list) else d["derr_modfed"]
rows=d["rows"]
spec={
  "name":"idefix Modfed2 dummy eval (full rank)","rows":8,"alts":2,"method":"efficient",
  "alternatives":[{"name":"A"},{"name":"B"}],
  "attributes":[
    {"name":"V1","coding":"dummy","levels":["l1","l2","l3","l4"]},
    {"name":"V2","coding":"dummy","levels":["l1","l2"]},
    {"name":"V3","coding":"dummy","levels":["l1","l2","l3"]}],
  "priorVec":mu,
  "evalRowsIdx":rows
}
sp=os.path.join(BASE,"eval_idefix_modfed2.json")
json.dump(spec,open(sp,"w"))
out=subprocess.run(["/opt/homebrew/bin/node","cf_headless.mjs","eval_idefix_modfed2.json"],
                   cwd=BASE,capture_output=True,text=True)
if out.returncode!=0: print("ERR",out.stderr); raise SystemExit(1)
r=json.loads(out.stdout)
print("paramLabels:", r["paramLabels"], "K=",r["K"])
# verify coded X matches idefix des exactly
des=d["des"]; X=r["X"]
match = all(list(map(int,X[i]))==list(map(int,des[i])) for i in range(len(des)))
print("coded X == idefix des exactly:", match)
print(f"idefix Modfed D-error : {idfx:.12g}")
print(f"choiceforge D-error   : {r['derr']:.12g}")
print(f"rel diff              : {abs(idfx-r['derr'])/idfx:.3e}")
