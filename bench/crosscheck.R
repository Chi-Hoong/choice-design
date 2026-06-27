.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(jsonlite); library(idefix)})
o <- fromJSON(commandArgs(TRUE)[1], simplifyVector = TRUE)
J <- o$J; par <- as.numeric(o$par); K <- length(par)
to_mat <- function(z, ncol){
  if (is.matrix(z)) { m <- z } else if (is.data.frame(z)) { m <- as.matrix(z) }
  else { m <- matrix(as.numeric(unlist(z)), ncol = ncol, byrow = TRUE) }
  storage.mode(m) <- "double"; m
}
X <- to_mat(o$X, K)   # (Sn*J) x K
stopifnot(ncol(X) == K, nrow(X) == o$Sn * J)

## Independent base-R reference: D-error = det(info)^(-1/K), info = sum_s X_s'(diag(p)-pp')X_s
Derr_ref <- function(par, X, nalts){
  K <- length(par); nsets <- nrow(X)/nalts; info <- matrix(0, K, K)
  for(s in 1:nsets){
    Xs <- X[((s-1)*nalts+1):(s*nalts), , drop = FALSE]
    v <- as.vector(Xs %*% par); v <- v - max(v); p <- exp(v); p <- p/sum(p)
    info <- info + t(Xs) %*% (diag(p) - outer(p,p)) %*% Xs
  }
  d <- det(info); if (d <= 0) Inf else d^(-1/K)
}

cat(sprintf("== %s ==\n", ifelse(is.null(o$name),"(design)",o$name)))
cat(sprintf("K=%d  J=%d  Sn=%d  method=%s\n", K, J, o$Sn, o$method))
ref   <- Derr_ref(par, X, J)
idfx  <- idefix::DBerr(matrix(par, nrow = 1), X, J)
cat(sprintf("ChoiceForge  D-error : %.12g\n", o$derr))
cat(sprintf("base-R ref   D-error : %.12g\n", ref))
cat(sprintf("idefix DBerr D-error : %.12g\n", idfx))
cat(sprintf("max rel. diff vs ChoiceForge : %.3e\n",
            max(abs(c(ref,idfx)-o$derr)/o$derr)))

if (!is.null(o$bayes) && !is.null(o$betas)) {
  B <- to_mat(o$betas, K)  # R x K (same draws CF used)
  db_idfx <- idefix::DBerr(B, X, J, mean = TRUE)
  db_ref  <- mean(apply(B, 1, function(b) Derr_ref(b, X, J)))
  cat(sprintf("-- Bayesian (Db over %d identical draws) --\n", nrow(B)))
  cat(sprintf("ChoiceForge  Db : %.12g\n", o$bayes$mean))
  cat(sprintf("base-R ref   Db : %.12g\n", db_ref))
  cat(sprintf("idefix DBerr Db : %.12g\n", db_idfx))
  cat(sprintf("max rel. diff vs ChoiceForge : %.3e\n",
              max(abs(c(db_ref,db_idfx)-o$bayes$mean)/o$bayes$mean)))
}
