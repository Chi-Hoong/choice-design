# ChoiceForge

**Efficient experimental designs for discrete choice experiments (DCE) — an Ngene-style design generator that runs in the browser.**

ChoiceForge builds D-efficient and Bayesian-efficient stated-choice designs by minimising the
D-error of the multinomial-logit (MNL) Fisher information matrix. It is a single self-contained
`index.html` — no build step, no server-side code, no dependencies.

## Run it

Open `index.html` in any modern browser, or serve the folder:

```bash
# macOS: just double-click start.command, or:
python3 -m http.server 8011    # then visit http://localhost:8011
```

## Features

- **Design objectives:** D-efficient (fixed priors) and **Bayesian efficient** (priors as normal
  draws, minimising mean Db-error).
- **Attributes:** continuous (linear) or categorical with **dummy / effects** coding.
- **Labeled & unlabeled designs:** alternative-specific constants (ASCs) and alternative-specific
  coefficients; per-alternative **attribute availability** and **level sets** (each option can have a
  different attribute list / levels).
- **No-choice / opt-out** alternative.
- **Constraints:** attribute level balance, dominated-alternative removal, prohibited level pairs.
- **Blocking:** split tasks into balanced respondent versions.
- **Suggest priors:** sensible starting priors from each attribute's preferred direction.
- **Diagnostics & assessment:** D-/D₀-/A-error, per-parameter s.e. / t-ratios / minimum sample size,
  full variance–covariance matrix, attribute correlation, level & utility balance, and an automated
  design critique (dominance, respondent burden, orthogonality).
- **Exports:** wide CSV (review), long coded CSV (ready for Apollo / Biogeme / R `mlogit`), and an
  illustrative Ngene-style syntax block.

## Documentation

- **[User Guide](docs/USER_GUIDE.md)** — step‑by‑step: build a design, read the results, export, worked
  examples, troubleshooting, glossary.
- **[Technical Documentation](docs/TECHNICAL.md)** — the full theory (MNL, Fisher information, D‑error),
  coding, the optimisation algorithms, constraints, blocking, numerical methods, and the benchmark.

## The maths

MNL Fisher information, single respondent:

```
Ω = Σ_s Σ_j p_js (x_js − x̄_s)(x_js − x̄_s)' ,   p = softmax(Xβ) ,   x̄_s = Σ_j p_js x_js
D-error  = det(Ω)^(−1/K)             (K = number of parameters)
Db-error = mean over prior draws of the local D-error
```

The optimiser is a coordinate-exchange search (random restarts), or a swap algorithm when level
balance is enforced (which keeps the design balanced while a lexicographic objective drives down any
constraint violations).

## Validation

ChoiceForge's D-error has been cross-checked against the R package
[`idefix`](https://cran.r-project.org/package=idefix) and two independent from-scratch
implementations (base-R and Python/numpy): they agree to **machine precision (~1e-15)** across dummy
/ effects / continuous attributes, labeled designs with ASCs, 2–3 alternatives, the Bayesian Db, and
the no-choice option. The optimiser lands within a few tenths of a percent of idefix's Modified
Federov algorithm (sometimes better). Ngene's D-error definition is identical (Ngene 1.4 manual Ch. 7;
Rose & Bliemer 2009), so matching idefix means matching Ngene's definition.

See [`bench/BENCHMARK.md`](bench/BENCHMARK.md) for the full methodology and reproduction commands.
(The benchmark needs R with `idefix`; the app itself needs nothing.)

## Known limitations

MNL only — no panel/mixed-logit (random-parameter) or nested-logit efficiency. Ngene drops ASC
columns before the determinant; ChoiceForge keeps them in.
