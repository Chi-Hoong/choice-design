.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(idefix); library(jsonlite)})
NODE <- "/opt/homebrew/bin/node"
par <- c(0.3,0.6,-0.4,-0.8,0.2,0.5); pard <- matrix(par,1)
cand <- Profiles(lvls=c(3,3,3), coding=c("D","D","D"))
base <- fromJSON("spec_P1.json", simplifyVector=FALSE)

res <- data.frame()
for(sd in c(1,7,42,123,2024)){
  set.seed(sd)
  mf <- Modfed(cand.set=cand, n.sets=12, n.alts=2, par.draws=pard,
               alt.cte=NULL, parallel=FALSE, n.start=20)$BestDesign
  d_mf <- as.numeric(idefix::DBerr(pard, mf$design, 2))
  sp <- base; sp$seed <- sd; sp$starts <- 20
  writeLines(toJSON(sp, auto_unbox=TRUE), "tmp_seed_spec.json")
  o <- fromJSON(paste(system2(NODE, c("cf_headless.mjs","tmp_seed_spec.json"), stdout=TRUE), collapse=""))
  # evaluate CF's design with idefix too (cross-validate self-report)
  Xcf <- if(is.matrix(o$X)) o$X else matrix(as.numeric(unlist(o$X)),ncol=6,byrow=TRUE); storage.mode(Xcf)<-"double"
  d_cf_byidefix <- as.numeric(idefix::DBerr(pard, Xcf, 2))
  res <- rbind(res, data.frame(seed=sd, idefix=d_mf, CF_self=o$derr,
               CF_byidefix=d_cf_byidefix, gap_pct=100*(d_cf_byidefix-d_mf)/d_mf))
}
print(res, row.names=FALSE, digits=9)
cat(sprintf("\ngap across seeds: mean %.3f%%, min %.3f%%, max %.3f%%\n",
            mean(res$gap_pct), min(res$gap_pct), max(res$gap_pct)))
cat(sprintf("CF self-report vs idefix-eval max abs diff: %.2e (should be ~0)\n",
            max(abs(res$CF_self-res$CF_byidefix))))
