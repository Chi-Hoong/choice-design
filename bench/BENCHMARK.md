# ChoiceForge — benchmark vs idefix (R) and base-R

Goal: validate that ChoiceForge computes the **same D-error as the field-standard tooling**
and that its **optimiser is competitive** with it.

## Setup
- `idefix` 1.1.0 (CRAN) installed into `bench/rlib`; R 4.6.0; node 26.
- `cf_headless.mjs` = ChoiceForge's **actual engine** (the app's `<script>` with the UI stripped,
  built by `build_headless.mjs`). It reproduces the browser's numbers exactly
  (e.g. example design D-error `0.04368270910304265`, identical to the app).
- D-error definition under test: `D = det(Ω)^(−1/K)` at N=1, with
  `Ω = Σ_s Σ_j p_js (x_js − x̄_s)(x_js − x̄_s)'`, `p = softmax(Xβ)`. Bayesian `Db = mean_r D(β_r)`.

## Part 1 — Is the D-error correct? (three independent implementations)
For each problem ChoiceForge exports the exact coded design matrix `X` and prior vector `par`;
the same `X, par` are fed to (a) ChoiceForge, (b) an independent base-R implementation, and
(c) `idefix::DBerr`. D-error is a pure function of `(X, par, n.alts)`, so correct implementations
must agree.

| Problem | feature exercised | max rel. diff vs ChoiceForge |
|---|---|---|
| P1 | categorical, **dummy** coding, priors | 3.4e-16 |
| P2 | categorical, **effects** coding | 1.2e-15 |
| P3 | **labeled + ASC** | 1.8e-16 |
| P4 | **Bayesian** Db over 120 identical draws | 1.6e-16 |
| P5 | 3 alts, **continuous + categorical + effects** mixed | 4.6e-16 |
| NC | **no-choice / opt-out** alternative (n.alts = J+1) | 2.0e-15 |
| smoke | app example (continuous + categorical) | 3.2e-16 |

→ ChoiceForge's D-error equals idefix and base-R to **machine precision** across every
attribute type, coding, ASC, alternative count, and the Bayesian aggregation.

Reciprocal check: ChoiceForge re-evaluates idefix's *Modfed* design and returns idefix's own
number to 10 d.p. (`0.6515320816`).

## Part 2 — Is the optimiser competitive? (apples-to-apples, same evaluator)
Both tools optimise the same problem with the same priors; every resulting design is scored with
one common evaluator (`idefix::DBerr`, same `par`). Lower = better.

| Problem | idefix Modfed (Federov) | idefix CEA | ChoiceForge | CF gap to best |
|---|---|---|---|---|
| P1 categorical | **0.6515321** | 0.6534223 | 0.6525637 | +0.16% (beats CEA) |
| P3 labeled+ASC | **0.6083780** | – | 0.6105414 | +0.36% |
| P4 Bayesian (common 500-draw eval set) | 0.6834536 | – | **0.6823685** | −0.16% (CF better) |

→ ChoiceForge's coordinate-exchange optimiser lands within a few tenths of a percent of idefix's
Modified Federov algorithm, beats idefix's CEA on P1, and edges it out on the Bayesian design.

## Part 3 — vs Ngene
Ngene is proprietary and cannot be run here, so the comparison is definitional + transitive.
Confirmed against primary sources (Ngene 1.4 Manual Ch.7 Eqs 7.3–7.6 & App.7A.14; Rose & Bliemer
2009; idefix JSS paper Eqs 1–3) that Ngene's MNL D-error **is** `det(Ω₁)^{1/K}` at N=1 — the exact
quantity ChoiceForge and idefix compute (Dz/Dp/Db = ChoiceForge's no-prior/efficient/bayesian modes;
A-error = trace/K = ChoiceForge's `aerr`). So matching idefix to 1e-15 == matching Ngene's definition.
- Reproduced the idefix JSS **VOT** example (2 continuous attrs, 20 sets, 21-point β range): ChoiceForge
  vs idefix DBerr on the identical design, max rel diff **5.5e-10**.
- Reproduced the JSS **Modfed dummy** example (lvls 4,2,3): ChoiceForge's coded matrix is **byte-identical**
  to idefix's, D-error rel diff **3.8e-14**.
- Minor convention note: Ngene recommends dropping ASC rows/cols before `det`; ChoiceForge keeps them in.
- Robustness: for a rank-deficient (unestimable) design ChoiceForge returns `∞` (det≤0), whereas
  idefix's unguarded `det(solve())` returns a spurious finite number — ChoiceForge's behaviour is safer.

## Part 4 — Independent verification (3rd implementation + adversarial audit)
- **Python/numpy from-scratch** D-error (standalone — no ChoiceForge/idefix/R): matches ChoiceForge on
  P1/P2/P3/P4/P5 to max rel diff **1.0e-15**. A *fourth* independent agreement.
- **Seed-stability** of the optimiser gap on P1 (5 seeds each side, n.start = starts = 20, apples-to-apples):

  | seed | idefix | ChoiceForge | gap |
  |---|---|---|---|
  | 1 | 0.650716 | 0.654207 | +0.54% |
  | 7 | 0.651532 | 0.654617 | +0.47% |
  | 42 | 0.653193 | 0.652789 | −0.06% |
  | 123 | 0.653145 | 0.653376 | +0.04% |
  | 2024 | 0.652938 | 0.651842 | −0.17% |

  Gap mean **+0.16%**, range **[−0.17%, +0.54%]**; ChoiceForge wins on 2/5 seeds. Both tools are
  themselves seed-dependent (neither always finds the global optimum) and sit in the same band — i.e.
  genuine peers, not a cherry-picked result. CF self-report == idefix-eval every seed (5.5e-16).

## Part 5 — features added after the benchmark (no-choice, blocking)
- **No-choice / opt-out alternative**: adds a constant opt-out (its own ASC) to every task; the FIM uses
  J+1 alternatives. Cross-checked against `idefix::DBerr` at n.alts=J+1 → **2.0e-15** (spec_NC.json /
  crosscheck_nc.R). A bug found during this verification — the stats matrix (s.e./A-error/sample size)
  was built without the opt-out row, making the no-choice parameter look unidentified (A-error 0) — was
  fixed so the info matrix at the prior means includes the opt-out (now `derr == dpMeans`).
- **Blocking**: partitions the choice tasks into B balanced versions, minimising the correlation between
  the block index and the design columns (Ngene's block diagnostic). Verified equal block sizes and a
  near-zero block-attribute correlation; adds a `block` column to both CSV exports.

## Reproduce
```
cd bench
node build_headless.mjs                         # build engine from index.html
for p in P1 P2 P3 P4 P5; do node cf_headless.mjs spec_$p.json > out_$p.json; Rscript crosscheck.R out_$p.json; done
node cf_headless.mjs spec_NC.json > out_NC.json; Rscript crosscheck_nc.R out_NC.json   # no-choice
Rscript opt_compare.R                            # P1 optimiser comparison
Rscript opt_compare2.R                           # P3 labeled + P4 Bayesian comparison
Rscript audit_seed.R                             # seed-stability of the optimiser gap
```
