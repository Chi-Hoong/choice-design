.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(idefix); library(jsonlite)})
code <- c("D","D","D")
cs <- Profiles(lvls = c(4,2,3), coding = code)
mu  <- c(-0.4, -1, -2, -1, 0.2, 1)
set.seed(123)
# Optimize a real (full-rank) D-efficient design with fixed prior mu
D <- Modfed(cand.set = cs, n.sets = 8, n.alts = 2, alt.cte = c(0,0),
            par.draws = matrix(mu, nrow=1), parallel = FALSE, n.start = 12)
des <- D$BestDesign$design
cat("Modfed design dim:", paste(dim(des), collapse="x"), "\n")
cat("Modfed reported D-error:", sprintf('%.12g', D$BestDesign$DB.error), "\n")
derr_chk <- DBerr(par.draws = matrix(mu,nrow=1), des = des, n.alts = 2)
cat("DBerr recomputed       :", sprintf('%.12g', derr_chk), "\n")
decode_attr <- function(cols){ if(all(cols==0)) return(0L); as.integer(which(cols==1)) }
rows <- list()
for(s in 1:8){
  r1 <- des[2*s-1, ]; r2 <- des[2*s, ]
  f  <- function(r) c(decode_attr(r[1:3]), decode_attr(r[4]), decode_attr(r[5:6]))
  rows[[s]] <- list(f(r1), f(r2))
}
writeLines(toJSON(list(des=des, mu=mu, derr_modfed=D$BestDesign$DB.error, derr_dberr=derr_chk, rows=rows),
                  digits=12, matrix="rowmajor"), "idefix_modfed2_export.json")
cat("wrote idefix_modfed2_export.json\n")
