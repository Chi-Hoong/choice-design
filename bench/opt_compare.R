.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(idefix); library(jsonlite)})

## ---- P1 problem: 3 attrs x 3 levels, dummy, 2 alts, 12 sets, fixed prior ----
par   <- c(0.3, 0.6, -0.4, -0.8, 0.2, 0.5)   # order = Var12,Var13,Var22,Var23,Var32,Var33 (== ChoiceForge)
cand  <- Profiles(lvls = c(3,3,3), coding = c("D","D","D"))
pard  <- matrix(par, nrow = 1)

set.seed(7)
mf <- Modfed(cand.set = cand, n.sets = 12, n.alts = 2, par.draws = pard,
             alt.cte = NULL, parallel = FALSE, n.start = 20)$BestDesign
ce <- CEA(lvls = c(3,3,3), coding = c("D","D","D"), n.sets = 12, n.alts = 2,
          par.draws = pard, alt.cte = NULL, parallel = FALSE, n.start = 20)$BestDesign

## ChoiceForge's own optimised design for the same problem
o  <- fromJSON("out_P1.json", simplifyVector = TRUE)
Xcf <- if (is.matrix(o$X)) o$X else matrix(as.numeric(unlist(o$X)), ncol = length(par), byrow = TRUE)
storage.mode(Xcf) <- "double"
stopifnot(dim(Xcf)[1] == o$Sn*2, dim(Xcf)[2] == length(par))

## evaluate ALL three designs with the SAME evaluator (idefix DBerr, same par) -> apples to apples
d_mf <- idefix::DBerr(pard, mf$design, 2)
d_ce <- idefix::DBerr(pard, ce$design, 2)
d_cf <- idefix::DBerr(pard, Xcf, 2)

cat("=========== Optimizer quality on P1 (lower D-error = better) ===========\n")
cat(sprintf("idefix Modfed (Federov)   D-error = %.10f\n", d_mf))
cat(sprintf("idefix CEA (coord. exch.) D-error = %.10f\n", d_ce))
cat(sprintf("ChoiceForge               D-error = %.10f\n", d_cf))
best <- min(d_mf, d_ce, d_cf)
cat(sprintf("\nbest of the three = %.10f\n", best))
cat(sprintf("ChoiceForge gap to best = %.4f%%\n", 100*(d_cf-best)/best))

## decode idefix Modfed design -> level indices, write spec so ChoiceForge can re-evaluate it
chunk <- c(2,2,2); A <- 3; nalts <- 2; nsets <- 12
decode_row <- function(r){ out<-integer(A); pos<-1
  for(a in 1:A){ ch<-as.numeric(r[pos:(pos+chunk[a]-1)]); pos<-pos+chunk[a]
    out[a] <- if(all(ch==0)) 0L else as.integer(which(ch==1)) }; out }
mfdes <- mf$design
idx <- lapply(1:nsets, function(s) lapply(1:nalts, function(j) decode_row(mfdes[(s-1)*nalts+j, ])))
spec <- fromJSON("spec_P1.json", simplifyVector = FALSE)
spec$evalRowsIdx <- idx
writeLines(toJSON(spec, auto_unbox = TRUE), "eval_idefix_P1.json")
cat("\nwrote eval_idefix_P1.json (idefix Modfed design, for ChoiceForge re-evaluation)\n")
