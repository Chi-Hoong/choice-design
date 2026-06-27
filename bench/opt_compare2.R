.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(idefix); library(jsonlite); library(MASS)})
getX <- function(f, K){ o<-fromJSON(f, simplifyVector=TRUE)
  X<-if(is.matrix(o$X)) o$X else matrix(as.numeric(unlist(o$X)),ncol=K,byrow=TRUE)
  storage.mode(X)<-"double"; list(X=X,o=o) }

## ================= P3: labeled design with ASC on alt 2 =================
cat("=========== P3 labeled + ASC (lower D-error = better) ===========\n")
par3 <- c(0.5, -0.3, -0.7, 0.4, 0.9)            # ASC.Train, Cost.mid, Cost.hi, Qual.mid, Qual.hi
cand3 <- Profiles(lvls=c(3,3), coding=c("D","D"))
set.seed(11)
# with alt.cte, idefix wants par.draws as list(cte matrix, attribute matrix)
pd3 <- list(matrix(par3[1], 1, 1), matrix(par3[2:5], 1, 4))
mf3 <- Modfed(cand.set=cand3, n.sets=12, n.alts=2, par.draws=pd3,
              alt.cte=c(0,1), parallel=FALSE, n.start=20)$BestDesign
cf3 <- getX("out_P3.json", 5)
d_cf3 <- idefix::DBerr(matrix(par3,1), cf3$X, 2)
d_mf3 <- idefix::DBerr(matrix(par3,1), mf3$design, 2)
cat(sprintf("idefix Modfed  D-error = %.10f\n", d_mf3))
cat(sprintf("ChoiceForge    D-error = %.10f   (self-reported %.10f)\n", d_cf3, cf3$o$derr))
cat(sprintf("ChoiceForge gap to idefix = %+.4f%%\n\n", 100*(d_cf3-d_mf3)/d_mf3))

## ================= P4: Bayesian — both designs scored on a COMMON draw set =====
cat("=========== P4 Bayesian (common 500-draw evaluation set) ===========\n")
mu <- c(0.3,0.6,-0.4,-0.8,0.2,0.5); sg <- c(0.2,0.3,0.2,0.3,0.1,0.2)
cand4 <- Profiles(lvls=c(3,3,3), coding=c("D","D","D"))
set.seed(900); Dstar <- MASS::mvrnorm(500, mu, diag(sg^2))   # common evaluation draws
set.seed(901); Dopt  <- MASS::mvrnorm(200, mu, diag(sg^2))   # idefix optimisation draws
mf4 <- Modfed(cand.set=cand4, n.sets=12, n.alts=2, par.draws=Dopt,
              alt.cte=NULL, parallel=FALSE, n.start=12)$BestDesign
cf4 <- getX("out_P4.json", 6)
db_cf <- idefix::DBerr(Dstar, cf4$X, 2)        # ChoiceForge bayesian design
db_mf <- idefix::DBerr(Dstar, mf4$design, 2)   # idefix bayesian design
cat(sprintf("idefix Modfed  Db* (on common draws) = %.10f\n", db_mf))
cat(sprintf("ChoiceForge    Db* (on common draws) = %.10f\n", db_cf))
cat(sprintf("ChoiceForge gap to idefix = %+.4f%%\n", 100*(db_cf-db_mf)/db_mf))
