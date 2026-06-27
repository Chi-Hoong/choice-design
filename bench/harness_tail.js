/* ===================================================================
   Headless harness — appended after ChoiceForge's engine (UI excluded).
   Reuses the REAL engine functions (det, situationContrib, encodeAlt,
   buildParams, makeCtx, the optimisers, summarise) so the numbers here
   are exactly what the browser app produces.
   Usage: node cf_headless.mjs <spec.json>
=================================================================== */
import fs from 'node:fs';
function renderPriors(){}   // stub so suggestPriors() runs headlessly

function buildProblem(spec){
  UID=1;
  const alts = spec.alternatives.map((a,i)=>({id:uid(), name:a.name||('Opt'+(i+1)), asc:!!a.asc}));
  const attrs = spec.attributes.map(a=>{
    const at = blankAttr(a.name, a.type||'categorical');
    at.coding = a.coding || 'dummy';
    at.levelsText = (a.levels||[]).join(', ');
    at.altSpecific = !!a.altSpecific;
    at.direction = a.direction||0;
    at.appliesTo = a.appliesTo ? a.appliesTo.map(ix=>alts[ix].id) : null;
    at.altLevels = {};
    if(a.altLevels){ for(const k in a.altLevels) at.altLevels[alts[+k].id] = a.altLevels[k]; }
    return at;
  });
  S = {
    rows:spec.rows, alts:spec.alts!=null?spec.alts:alts.length, labeled:!!spec.labeled,
    starts:spec.starts||20, iter:spec.iter||80, method:spec.method||'efficient',
    draws:spec.draws||100, seed:spec.seed||12345, balance:!!spec.balance, noDom:!!spec.noDom,
    noChoice:!!spec.noChoice, blocks:spec.blocks||1,
    alternatives:alts, attributes:attrs, priors:{}, prohib:[], result:null
  };
  if(spec.prohib) S.prohib = spec.prohib.map(p=>({attrA:attrs[p.aA].id,levelA:p.lA,attrB:attrs[p.aB].id,levelB:p.lB}));
  rebuildParams();
  if(spec.priors==='suggest'){ suggestPriors(); }
  else if(spec.priors && typeof spec.priors==='object'){
    // keyed by parameter label; value = mean or [mean, sd]
    S._params.forEach(p=>{ const v=spec.priors[p.label]; if(v!=null){ S.priors[p.key].mean=Array.isArray(v)?v[0]:v; if(Array.isArray(v)&&v[1]!=null)S.priors[p.key].sd=v[1]; } });
  }
  else if(Array.isArray(spec.priorVec)){
    S._params.forEach((p,k)=>{ S.priors[p.key].mean = spec.priorVec[k]||0; });
  }
  return S;
}

async function runOptimize(){
  const starts=Math.max(1,S.starts|0);
  let bestCtx=null, best={viol:Infinity,d:Infinity};
  for(let st=0; st<starts; st++){
    const ctx=makeCtx();
    const rng=mulberry32(((S.seed|0)||1)*7919 + st*104729 + 1);
    let res;
    if(S.balance){ const pools=balancedInit(ctx,rng); res=await swapOptimise(ctx,pools,null); }
    else { randomInit(ctx,rng); res=await coordinateExchange(ctx,rng,null); }
    if(res.viol<best.viol || (res.viol===best.viol && res.d<best.d)){ best=res; bestCtx=ctx; }
  }
  return {ctx:bestCtx, best};
}

const stackX = ctx => { const r=[]; for(let s=0;s<ctx.Sn;s++)for(let j=0;j<ctx.J;j++)r.push(Array.from(ctx.X[s][j])); return r; };
const rowIdx = ctx => { const o=[]; for(let s=0;s<ctx.Sn;s++){const t=[];for(let j=0;j<ctx.J;j++)t.push(Array.from(ctx.rows[s][j]));o.push(t);} return o; };

(async()=>{
  const spec = JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
  buildProblem(spec);

  // MODE B: evaluate the D-error of an externally supplied design (level indices)
  if(spec.evalRowsIdx){
    const ctx=makeCtx();
    for(let s=0;s<ctx.Sn;s++){ for(let j=0;j<ctx.J;j++){ for(let a=0;a<ctx.A;a++) ctx.rows[s][j][a]=spec.evalRowsIdx[s][j][a]; } rebuildSituation(ctx,s); }
    const out={mode:'eval', K:ctx.K, J:ctx.J, Sn:ctx.Sn, derr:derr(ctx),
      par:Array.from(ctx.priorMeans), paramLabels:ctx.params.map(p=>p.label), X:stackX(ctx)};
    process.stdout.write(JSON.stringify(out)); return;
  }

  // MODE A: optimise and export everything needed for external cross-checks
  const {ctx,best} = await runOptimize();
  const R = summarise(ctx, best.d, best.viol);
  const out = {
    mode:'optimise', name:spec.name||null,
    method:S.method, J:ctx.J, Sn:ctx.Sn, K:ctx.K,
    derr:R.derr, dpMeans:R.dpMeans, d0:R.d0, aerr:R.aerr, infeasible:R.infeasible,
    maxCorr:R.maxCorr, sampleN:R.sampleN,
    hasNC:R.hasNC, optOutShare:R.optOutShare, block:R.block,
    ncIndex: R.hasNC ? R.paramLabels.indexOf("No-choice constant") : -1,
    par:Array.from(ctx.priorMeans),
    paramLabels:R.paramLabels,
    X:stackX(ctx),                 // (Sn*J) x K, ordered by (situation, alternative)
    rowsIdx:rowIdx(ctx),
    betas:ctx.betas.map(b=>Array.from(b)),   // prior draws (1 row if fixed-prior)
    bayes:R.bayes||null
  };
  process.stdout.write(JSON.stringify(out));
})();
