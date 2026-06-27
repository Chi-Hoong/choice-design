.libPaths(c(path.expand("~/Downloads/choice-design/bench/rlib"), .libPaths()))
suppressMessages({library(idefix); library(jsonlite)})
cat("idefix version:", as.character(packageVersion("idefix")), "\n")
# Reproduce JSS paper Section 2.3 / 3.3 "informative" design exactly
set.seed(123)
N <- 250
I  <- rnorm(n = N, mean = -0.33, sd = 0.1)   # informative sample for beta_time
I  <- cbind(I, -1)                           # second col = beta_price fixed at -1
lev_time  <- c(30,36,42,48,54)
lev_price <- c(1,4,7,10,13)
D_I <- CEA(lvls = c(5, 5), coding = c("C","C"),
           c.lvls = list(lev_time, lev_price), n.sets = 20, n.alts = 2,
           parallel = FALSE, par.draws = I)
des <- D_I$BestDesign$design
cat("design dim:", paste(dim(des), collapse="x"), "\n")
cat("DB.error of generated design:", D_I$BestDesign$DB.error, "\n")
# The published DBerr robustness vector
range <- cbind(seq(-1.667, 0, 0.08333), -1)
I_robust <- DBerr(par.draws = range, des = des, n.alts = 2, mean = FALSE)
cat("DBerr vector (this run):\n"); print(I_robust, digits=10)
# published values from JSS paper p.19:
pub <- c(19.41543197,15.12089434,11.77624555,9.17131336,7.14225121,5.56088291,
         4.32537544,3.34943050,2.54316599,1.78598093,1.01289324,0.43448119,
         0.15842765,0.05476671,0.02232948,0.01558887,0.01327167,0.01476203,
         0.01931387,0.03505369,0.07640805)
cat("max abs diff vs published:", max(abs(I_robust - pub)), "\n")
# Export design + range for ChoiceForge eval
writeLines(toJSON(list(des = des, range = range, dberr_idefix = I_robust,
                       dberr_published = pub, betas_time = range[,1]),
                  digits = 12, matrix = "rowmajor"),
           "idefix_vot_export.json")
cat("wrote idefix_vot_export.json\n")
