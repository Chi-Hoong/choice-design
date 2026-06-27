.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(idefix); library(jsonlite)})
# JSS paper p.11 Modfed example (dummy coding, fixed-prior D-error via single draw)
code <- c("D","D","D")
cs <- Profiles(lvls = c(4,2,3), coding = code)   # 24 profiles, 6 dummy cols
mu <- c(-0.4, -1, -2, -1, 0.2, 1)
# Use a FIXED design we control so the test is deterministic:
# pick first 16 profiles to form 8 sets x 2 alts (arbitrary but fixed).
set.seed(7)
idx <- sample(seq_len(nrow(cs)), 16, replace=TRUE)
des <- cs[idx, , drop=FALSE]
cat("cand cols:", paste(colnames(cs), collapse=" "), "\n")
cat("des dim:", paste(dim(des), collapse="x"), "\n")
derr_idfx <- DBerr(par.draws = matrix(mu, nrow=1), des = des, n.alts = 2)  # vector -> D-error
cat("idefix D-error (fixed prior mu):", sprintf('%.12g', derr_idfx), "\n")
# Map each design row back to (attr1 level idx, attr2 level idx, attr3 level idx)
# Dummy decode: attr1 has 3 dummy cols (lvls 2,3,4 -> cols), level1 = all zero.
decode_attr <- function(cols){ # cols: dummy block; returns 0-based level idx
  if(all(cols==0)) return(0L)
  which(cols==1)  # 1-based among dummies -> level index (since level1 is reference=0)
}
rows <- list()
for(s in 1:8){
  r1 <- des[2*s-1, ]; r2 <- des[2*s, ]
  a1l <- function(r) c(decode_attr(r[1:3]), decode_attr(r[4]), decode_attr(r[5:6]))
  rows[[s]] <- list(a1l(r1), a1l(r2))
}
writeLines(toJSON(list(des=des, mu=mu, derr_idefix=derr_idfx, rows=rows),
                  digits=12, matrix="rowmajor"), "idefix_modfed_export.json")
cat("wrote idefix_modfed_export.json\n")
