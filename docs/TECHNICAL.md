# ChoiceForge — Technical Documentation

**Theory, methods, algorithms, and validation of the ChoiceForge discrete‑choice experimental‑design generator.**

This document describes exactly what the app in [`index.html`](../index.html) computes and how. It is
self‑contained: the entire engine (linear algebra, information matrix, optimiser, diagnostics) lives in
one file with no external dependencies.

---

## Contents

1. [Scope](#1-scope)
2. [The choice model (MNL)](#2-the-choice-model-mnl)
3. [Design coding — from levels to the design matrix](#3-design-coding--from-levels-to-the-design-matrix)
4. [Efficiency theory: information, AVC, D‑error](#4-efficiency-theory-information-avc-d-error)
5. [Prior treatments: D₀, Dₚ, D_b](#5-prior-treatments-d-dp-db)
6. [Estimator precision: standard errors, t‑ratios, sample size](#6-estimator-precision-standard-errors-t-ratios-sample-size)
7. [The optimisation algorithms](#7-the-optimisation-algorithms)
8. [Constraints](#8-constraints)
9. [Blocking](#9-blocking)
10. [Prior suggestion heuristic](#10-prior-suggestion-heuristic)
11. [Diagnostics](#11-diagnostics)
12. [Numerical methods](#12-numerical-methods)
13. [Validation & benchmark](#13-validation--benchmark)
14. [Limitations](#14-limitations)
15. [References](#15-references)

---

## 1. Scope

ChoiceForge generates **efficient stated‑choice / discrete‑choice experiment (DCE) designs** for the
**multinomial logit (MNL)** model. Given a set of attributes, their levels, and prior beliefs about
the parameters, it searches over assignments of levels to alternatives across choice tasks to
**minimise the D‑error** of the model's asymptotic variance–covariance matrix — the same objective and
definition used by Ngene and the R package `idefix`.

It supports:

- fixed‑prior **(Dₚ) D‑efficient** and **Bayesian (D_b)** designs;
- **continuous** (linear) and **categorical** attributes with **dummy** or **effects** coding;
- **labeled** and **unlabeled** designs, **alternative‑specific constants (ASCs)** and
  **alternative‑specific coefficients**;
- **per‑alternative attribute availability** and **per‑alternative level sets**;
- a **no‑choice / opt‑out** alternative;
- constraints (level balance, dominance removal, prohibited level pairs);
- **blocking** into balanced respondent versions.

---

## 2. The choice model (MNL)

A respondent facing choice situation $s$ chooses among $J_s$ alternatives. The (random) utility of
alternative $j$ is

$$U_{js} = V_{js} + \varepsilon_{js}, \qquad V_{js} = \mathbf{x}_{js}^\top \boldsymbol\beta,$$

where $\mathbf{x}_{js}\in\mathbb{R}^{K}$ is the coded attribute row for that alternative,
$\boldsymbol\beta\in\mathbb{R}^{K}$ is the parameter vector ($K$ = number of estimated parameters), and
$\varepsilon_{js}$ are i.i.d. Type‑I extreme value. This yields the MNL choice probabilities

$$P_{js} = \frac{\exp(V_{js})}{\sum_{i=1}^{J_s}\exp(V_{is})} = \mathrm{softmax}_j(\mathbf{X}_s\boldsymbol\beta).$$

In code the probabilities are computed with the standard max‑shift for numerical stability
(`situationContrib`): subtract $\max_j V_{js}$ before exponentiating.

---

## 3. Design coding — from levels to the design matrix

Each alternative in each task is described by a chosen **level** for every attribute. ChoiceForge maps
those levels to the coded row $\mathbf{x}_{js}$ as follows (`buildParams`, `encodeAlt`):

| Element | Columns | Value in $\mathbf{x}_{js}$ |
|---|---|---|
| **Continuous** attribute | 1 | the numeric level value |
| **Categorical, dummy** coding ($L$ levels) | $L-1$ | $1$ for the alternative's level (first level = reference $=0$), else $0$ |
| **Categorical, effects** coding | $L-1$ | reference level $\to -1$ in every column of the attribute; else $1$ in its own column, $0$ elsewhere |
| **ASC** (labeled designs) | 1 per non‑reference alternative | $1$ for that alternative, $0$ otherwise |
| **No‑choice constant** | 1 | $1$ for the opt‑out row, $0$ for all designed alternatives |
| **Alternative‑specific coefficient** | as above, per alternative | non‑zero only for its own alternative |
| **Attribute availability** | — | $0$ in every column for alternatives that do not carry that attribute |

The first alternative is the ASC reference (no ASC). For an attribute marked *alternative‑specific*,
each alternative gets its own coefficient set built from **that alternative's** level list, so different
options may have different attributes and different numbers of levels.

**No‑choice.** When enabled, a constant opt‑out row $\mathbf{x}^{\text{opt}} = \mathbf{e}_{\text{NC}}$
(all zeros except a $1$ in the "No‑choice constant" column) is appended to every choice set, so the
information matrix is formed over $J_s+1$ alternatives (`rebuildSituation`). The opt‑out is fixed and
not varied by the optimiser.

---

## 4. Efficiency theory: information, AVC, D‑error

For the MNL, the contribution of choice situation $s$ to the **Fisher information matrix** (per
respondent) is

$$\mathbf{I}_s(\boldsymbol\beta) = \sum_{j=1}^{J_s} P_{js}\,(\mathbf{x}_{js}-\bar{\mathbf{x}}_s)(\mathbf{x}_{js}-\bar{\mathbf{x}}_s)^\top,\qquad \bar{\mathbf{x}}_s = \sum_{j=1}^{J_s} P_{js}\,\mathbf{x}_{js}.$$

Equivalently $\mathbf{I}_s = \mathbf{X}_s^\top(\mathrm{diag}(\mathbf{p}_s)-\mathbf{p}_s\mathbf{p}_s^\top)\mathbf{X}_s$.
This is the negative expected Hessian of the MNL log‑likelihood (McFadden 1974). The total information
for a design of $S$ situations answered by one respondent is

$$\mathbf{\Omega}^{-1} \equiv \mathbf{I}(\boldsymbol\beta) = \sum_{s=1}^{S}\mathbf{I}_s(\boldsymbol\beta).$$

The **asymptotic variance–covariance matrix (AVC)** of the maximum‑likelihood estimator is
$\mathbf{\Omega} = \mathbf{I}(\boldsymbol\beta)^{-1}$ (for $N$ respondents, $\mathbf{I}$ scales by $N$
and $\mathbf{\Omega}$ by $1/N$; ChoiceForge, like Ngene, reports the **single‑respondent** case
$N=1$).

The scalar efficiency measures are

$$\boxed{\;D\text{-error} = \det\!\big(\mathbf{\Omega}\big)^{1/K} = \det\!\big(\mathbf{I}(\boldsymbol\beta)\big)^{-1/K}\;}\qquad
A\text{-error} = \frac{1}{K}\,\mathrm{tr}(\mathbf{\Omega}).$$

The $1/K$ power normalises for the number of parameters so designs with different $K$ are comparable.
Minimising the D‑error minimises the (geometric‑mean) generalised variance of the estimates. If
$\mathbf{I}$ is singular (a parameter is not identified), $\det \le 0$ and the D‑error is $+\infty$ —
ChoiceForge returns `Infinity` (guarded at $|\det|<10^{-13}$), which correctly signals an unestimable
design.

---

## 5. Prior treatments: D₀, Dₚ, D_b

The information matrix depends on $\boldsymbol\beta$ through the probabilities, so the D‑error depends
on the assumed parameters. ChoiceForge implements the three standard cases (Rose & Bliemer 2009):

- **D₀ / Dz‑error** — evaluate at $\boldsymbol\beta = \mathbf{0}$, where $P_{js}=1/J_s$. Prior‑free;
  rewards orthogonality and level balance. Reported as the **D₀‑error** metric for reference.
- **Dₚ‑error** (the app's *"D‑efficient (fixed priors)"* mode) — evaluate at the analyst's fixed prior
  point estimates. This is the local D‑error.
- **D_b‑error** (the app's *"Bayesian efficient"* mode) — treat the priors as a distribution
  $\pi(\boldsymbol\beta)$ and minimise the **expected** local D‑error,

$$D_b = \int \det\!\big(\mathbf{I}(\boldsymbol\beta)\big)^{-1/K}\,\pi(\boldsymbol\beta)\,\mathrm{d}\boldsymbol\beta \;\approx\; \frac{1}{R}\sum_{r=1}^{R}\det\!\big(\mathbf{I}(\boldsymbol\beta_r)\big)^{-1/K},$$

with $R$ Monte‑Carlo draws $\boldsymbol\beta_r$. Each prior is drawn independently as
$\beta_{k,r} = \mu_k + \sigma_k z_{k,r}$, $z\sim\mathcal N(0,1)$, using a seeded RNG (`mulberry32`) and
Box–Muller normals (`makeNormal`), so results are reproducible. The **Bayesian D‑error distribution**
(min / median / mean / max / s.d. / % singular draws) over these draws is reported on the Parameter‑stats
tab.

---

## 6. Estimator precision: standard errors, t‑ratios, sample size

At the prior point estimates ChoiceForge inverts $\mathbf{I}(\boldsymbol\mu)$ to obtain the
single‑respondent AVC $\mathbf{\Omega}$ and derives, for each parameter $k$:

$$\mathrm{se}_k = \sqrt{\Omega_{kk}}, \qquad t_k = \frac{\mu_k}{\mathrm{se}_k}.$$

Because information scales linearly in the number of respondents $N$, standard errors scale as
$1/\sqrt{N}$. The **minimum sample size** to make parameter $k$ significant at 95% ($|t|>1.96$) is

$$n_k = \left(\frac{1.96\,\mathrm{se}_k}{|\mu_k|}\right)^2,$$

and the design‑level requirement is $n^\star = \max_k \lceil n_k\rceil$ (Ngene's "S‑estimate"). When
no‑choice is active, this information matrix is formed **including** the opt‑out row so the no‑choice
constant is identified.

---

## 7. The optimisation algorithms

The design is a table `rows[s][j][a]` = the chosen level index of attribute $a$ in alternative $j$ of
situation $s$. ChoiceForge minimises the (Dₚ or D_b) error over this table.

### 7.1 Coordinate exchange (default)

```
best ← D-error(random feasible design)
repeat up to `iter` passes:
    for each cell (situation s, alternative j, attribute a):
        for each candidate level ℓ ≠ current:
            if the move violates a constraint: skip
            evaluate D-error with rows[s][j][a] = ℓ
        keep the level with the lowest D-error (if it improves)
    stop when a full pass makes no improvement
```

This is repeated from `starts` independent random starting designs; the best design across starts is
returned. Coordinate exchange is the same family of algorithm as `idefix::CEA`.

### 7.2 Swap algorithm (when level balance is enforced)

Coordinate exchange cannot preserve level balance, so with balance enabled ChoiceForge switches to a
**swap** optimiser. Each attribute has a *pool* of cells (all its cells, or per‑alternative cells when
alternative‑specific). Each pool is initialised with an exactly balanced, shuffled multiset of levels;
moves **swap the levels of two cells in the same pool**, which preserves the level counts. Acceptance is
**lexicographic**:

$$\text{accept a swap iff}\quad (\text{violations}\downarrow)\ \text{or}\ (\text{violations equal and } D\text{-error}\downarrow).$$

Minimising constraint violations *first* means the swap optimiser **repairs** dominance / prohibition
violations present in the balanced starting design rather than merely blocking new ones, while keeping
the design perfectly level‑balanced.

### 7.3 Incremental evaluation

Changing one cell only affects situation $s$. ChoiceForge keeps $\mathbf{\Omega}^{-1}$ as a sum of
per‑situation contributions $\mathbf{I}_s$ (per prior draw), so a trial move recomputes only situation
$s$'s contribution and updates the running total ($\mathbf{I} \mathrel{+}= \mathbf{I}_s^{\text{new}} -
\mathbf{I}_s^{\text{old}}$), then recomputes the determinant. This makes the inner loop
$O(J K^2 + K^3)$ per prior draw instead of $O(S J K^2 + K^3)$ (`rebuildSituation`, `snapSit`,
`restoreSit`).

### 7.4 Reproducibility & responsiveness

Every run is seeded (`seed`, and per‑start offsets), so identical inputs give identical designs. The
optimiser yields to the UI roughly every 40 ms so the browser stays responsive and shows progress; a
**Stop** button sets a cancel flag.

---

## 8. Constraints

- **Attribute level balance** — each level of an attribute appears (as near as possible to) equally
  often. Enforced exactly by the swap optimiser (§7.2).
- **Remove dominated alternatives** — a task is rejected if one alternative weakly dominates another on
  every **shared** attribute (better on at least one, no worse on any), judged by each attribute's
  partial utility at the prior means. Attributes that apply to only one of the two alternatives are
  ignored. Requires non‑zero priors (or use *Suggest priors*) to have a notion of "better".
- **Prohibited level pairs** — forbid a specific (attribute = level, attribute = level) combination
  from co‑occurring within a single alternative.

Infeasible moves are filtered in coordinate exchange and penalised lexicographically in the swap
optimiser; any residual infeasibility is surfaced in the Assessment.

---

## 9. Blocking

Large designs are split into $B$ **blocks** (versions) so each respondent answers only $\lceil S/B\rceil$
tasks. ChoiceForge assigns tasks to blocks to **minimise the correlation between the block index and the
design columns** — the block should be statistically independent of the attributes so every version is
representative. Assignment starts balanced (round‑robin, shuffled) and is improved by swapping block
labels between tasks (which preserves block sizes), minimising the maximum absolute Pearson correlation
$\max_k |\mathrm{corr}(\text{block},\,\text{column}_k)|$. Blocks appear as a column in both CSV exports.

---

## 10. Prior suggestion heuristic

*Suggest priors* fills reasonable starting values from each attribute's stated **preferred direction**
$d\in\{-1,0,+1\}$, scaled so the utility spread across an attribute's range is $\approx 1$ logit unit
(keeping choices informative, not deterministic):

- **Continuous:** $\mu = d\cdot \dfrac{1}{\max(\text{levels})-\min(\text{levels})}$.
- **Categorical** (level $\ell$ of $L$, in label order): $\mu_\ell = d\cdot\dfrac{\ell}{L-1}$ — a
  monotone ramp across levels.
- **ASC / no‑choice constant:** $0$.
- **Bayesian s.d.:** half the absolute mean (or $0.3$ when the mean is $0$).

These are explicitly *starting* values to be replaced by pilot‑study or literature estimates.

---

## 11. Diagnostics

- **Attribute correlation matrix** — Pearson correlations among the coded design columns over all
  alternative‑rows; near‑zero off‑diagonals ⇒ near‑orthogonal. `Max |corr|` is highlighted.
- **Utility (choice) balance** — the MNL probabilities per task at the priors (including the opt‑out
  when present). Tasks where one option is near‑certain ($p>0.9$) carry little information.
- **Attribute level balance** — level frequencies per attribute (per alternative when
  alternative‑specific).
- **Full variance–covariance matrix** — the $K\times K$ AVC $\mathbf{\Omega}$.
- **Assessment** — an automated critique: dominance count, choice balance, orthogonality, minimum
  sample size (and its binding parameter), respondent burden / cognitive load (attributes per option,
  tasks per respondent after blocking, level counts), and level balance, with an overall verdict.

---

## 12. Numerical methods

- **Determinant** — LU decomposition with partial pivoting; $\det = \prod_i U_{ii}$ with the pivot
  sign. Values with $|\det|<10^{-13}$ are treated as singular (D‑error $=\infty$).
- **Inverse** (for the AVC / standard errors) — Gauss–Jordan elimination with partial pivoting; returns
  `null` for a singular matrix.
- **Matrices** are stored as flat `Float64Array`s of length $K^2$ (row‑major).
- **Softmax** uses the max‑shift; outer‑product accumulation skips zero weights.

---

## 13. Validation & benchmark

ChoiceForge's D‑error was validated against the field‑standard R package
[`idefix`](https://cran.r-project.org/package=idefix) 1.1.0 and **two independent from‑scratch
implementations** (base‑R and Python/NumPy). Full methodology and scripts are in
[`../bench/BENCHMARK.md`](../bench/BENCHMARK.md).

### 13.1 Is the D‑error correct?

D‑error is a pure function of $(\mathbf{X},\boldsymbol\beta,J)$. Feeding the **identical** coded design
matrix and priors into all implementations, they agree to **machine precision**:

| Case | Feature exercised | max relative difference |
|---|---|---|
| P1 | categorical, **dummy** coding, priors | 3.4 × 10⁻¹⁶ |
| P2 | categorical, **effects** coding | 1.2 × 10⁻¹⁵ |
| P3 | **labeled + ASC** | 1.8 × 10⁻¹⁶ |
| P4 | **Bayesian** D_b over identical draws | 1.6 × 10⁻¹⁶ |
| P5 | 3 alternatives, **continuous + categorical + effects** | 4.6 × 10⁻¹⁶ |
| NC | **no‑choice / opt‑out** ($J{+}1$ alternatives) | 2.0 × 10⁻¹⁵ |

The independent Python/NumPy implementation (imports only `numpy`; never touches ChoiceForge or idefix)
reproduced all cases to $\le 10^{-15}$.

### 13.2 Is the optimiser competitive?

Both tools optimise the same problem; every resulting design is scored by one common evaluator
(`idefix::DBerr`, same priors). Lower D‑error is better:

| Problem | idefix Modfed (Federov) | idefix CEA | ChoiceForge | ChoiceForge vs best |
|---|---|---|---|---|
| P1 categorical | **0.6515321** | 0.6534223 | 0.6525637 | +0.16% (beats CEA) |
| P3 labeled + ASC | **0.6083780** | — | 0.6105414 | +0.36% |
| P4 Bayesian (common 500‑draw eval) | 0.6834536 | — | **0.6823685** | −0.16% (ChoiceForge better) |

ChoiceForge's coordinate‑exchange optimiser lands within a few tenths of a percent of idefix's Modified
Federov algorithm, beats idefix's CEA, and edges it out on the Bayesian design.

### 13.3 Relationship to Ngene

Ngene is proprietary and cannot be executed here, but it uses the **identical** D‑error definition:
$\det(\mathbf{\Omega}_1)^{1/K}$ with $\mathbf{\Omega}_1$ the single‑respondent MNL AVC (Ngene 1.4
Manual, Ch. 7, Eqs. 7.3–7.6 and App. 7A.14; Rose & Bliemer 2009). The `idefix` JSS paper (Traets et al.
2020, Eqs. 1–3) gives byte‑for‑byte the same formulas. Therefore **matching idefix to $10^{-15}$ means
matching Ngene's definition.** One convention difference: Ngene recommends dropping ASC columns before
the determinant (reducing $K$ accordingly); ChoiceForge keeps them in.

### 13.4 Reproduce

```bash
cd bench
node build_headless.mjs                                   # build the engine from index.html
for p in P1 P2 P3 P4 P5; do node cf_headless.mjs spec_$p.json > out_$p.json; Rscript crosscheck.R out_$p.json; done
node cf_headless.mjs spec_NC.json > out_NC.json; Rscript crosscheck_nc.R out_NC.json
Rscript opt_compare.R                                     # P1 optimiser comparison
Rscript opt_compare2.R                                    # P3 labeled + P4 Bayesian comparison
```

`bench/cf_headless.mjs` is ChoiceForge's **actual engine** with the UI stripped (built from
`index.html`); it reproduces the browser's numbers exactly. The benchmark needs R with `idefix`
installed; the app itself needs nothing.

---

## 14. Limitations

- **MNL only.** No panel/cross‑sectional **mixed logit** (random‑parameter) or **nested logit**
  efficiency — those require a simulated / integrated information matrix.
- **No automatic ASC exclusion** from the determinant (Ngene's convention); ASCs are kept in $K$.
- **Local optimum.** Like all exchange/swap heuristics, the result is near‑optimal, not provably
  globally optimal; increase *Random starts* for more thorough search.
- **Ngene‑syntax export is illustrative**, not a runnable `.ngs` script — use the long‑format CSV for
  estimation.

---

## 15. References

- McFadden, D. (1974). *Conditional logit analysis of qualitative choice behavior.* In Zarembka (ed.),
  Frontiers in Econometrics.
- Rose, J. M. & Bliemer, M. C. J. (2009). *Constructing Efficient Stated Choice Experimental Designs.*
  Transport Reviews 29(5), 587–617. [DOI:10.1080/01441640902827623](https://doi.org/10.1080/01441640902827623)
- Bliemer, M. C. J. & Rose, J. M. (2010). *Construction of experimental designs for mixed logit models
  allowing for correlation across choice observations.* Transportation Research Part B.
- ChoiceMetrics (2024). *Ngene 1.4 User Manual & Reference Guide*, Chapter 7 "Efficient Designs".
- Traets, F., Gil Sanchez, D. & Vandebroek, M. (2020). *Generating Optimal Designs for Discrete Choice
  Experiments in R: The idefix Package.* Journal of Statistical Software 96(3).
  [DOI:10.18637/jss.v096.i03](https://doi.org/10.18637/jss.v096.i03)
- Kessels, R., Goos, P. & Vandebroek, M. (2006). *A comparison of criteria to design efficient choice
  experiments.* Journal of Marketing Research 43(3).
