.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(jsonlite); library(idefix)})
o <- fromJSON(commandArgs(TRUE)[1], simplifyVector = TRUE)
J <- o$J; par <- as.numeric(o$par); K <- length(par)
Xd <- if (is.matrix(o$X)) o$X else matrix(as.numeric(unlist(o$X)), ncol=K, byrow=TRUE)
storage.mode(Xd) <- "double"                      # designed rows only: (Sn*J) x K
ncix <- o$ncIndex + 1                              # 1-based no-choice column

## rebuild the full choice sets including the opt-out row (zeros except NC col = 1)
optrow <- numeric(K); optrow[ncix] <- 1
Xfull <- matrix(0, o$Sn*(J+1), K)
for (s in 1:o$Sn) {
  for (j in 1:J) Xfull[(s-1)*(J+1)+j, ] <- Xd[(s-1)*J+j, ]
  Xfull[(s-1)*(J+1)+(J+1), ] <- optrow
}

Derr_ref <- function(par, X, nalts){
  K <- length(par); nsets <- nrow(X)/nalts; info <- matrix(0,K,K)
  for(s in 1:nsets){ Xs <- X[((s-1)*nalts+1):(s*nalts),,drop=FALSE]
    v<-as.vector(Xs%*%par); v<-v-max(v); p<-exp(v); p<-p/sum(p)
    info <- info + t(Xs)%*%(diag(p)-outer(p,p))%*%Xs }
  d<-det(info); if(d<=0) Inf else d^(-1/K) }

ref  <- Derr_ref(par, Xfull, J+1)
idfx <- idefix::DBerr(matrix(par,1), Xfull, J+1)
cat(sprintf("== %s  (no-choice / opt-out, n.alts=%d) ==\n", o$name, J+1))
cat(sprintf("ChoiceForge  D-error : %.12g\n", o$derr))
cat(sprintf("base-R ref   D-error : %.12g\n", ref))
cat(sprintf("idefix DBerr D-error : %.12g\n", idfx))
cat(sprintf("max rel. diff vs ChoiceForge : %.3e\n", max(abs(c(ref,idfx)-o$derr)/o$derr)))
cat(sprintf("ChoiceForge opt-out share = %.1f%%\n", 100*o$optOutShare))
