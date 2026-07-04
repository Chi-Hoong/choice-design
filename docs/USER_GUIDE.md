# ChoiceForge — User Guide

A practical, step‑by‑step guide to building an efficient discrete‑choice experiment (DCE) design with
ChoiceForge. No statistics background is assumed for the *how*; the *why* is covered where it helps you
make good choices. For the underlying maths see [TECHNICAL.md](TECHNICAL.md).

---

## Contents

1. [What ChoiceForge does](#1-what-choiceforge-does)
2. [Opening the app](#2-opening-the-app)
3. [The screen at a glance](#3-the-screen-at-a-glance)
4. [Build a design — step by step](#4-build-a-design--step-by-step)
5. [Reading the results](#5-reading-the-results)
6. [Exporting](#6-exporting)
7. [Two worked examples](#7-two-worked-examples)
8. [Interpreting the numbers](#8-interpreting-the-numbers)
9. [Troubleshooting](#9-troubleshooting)
10. [Glossary](#10-glossary)

---

## 1. What ChoiceForge does

You describe the **attributes** (e.g. Price, Brand, Delivery time), their **levels** (e.g. Price = $10 /
$15 / $20), and what you already believe about how they drive choice (**priors**). ChoiceForge then
searches for the set of **choice tasks** — each showing a few alternatives — that will let you estimate
your model **as precisely as possible for the fewest respondents**. It does this by minimising the
**D‑error**, the standard measure of statistical efficiency used by Ngene and R's `idefix`
([validated to match them to ~15 decimal places](TECHNICAL.md#13-validation--benchmark)).

You get back the design table, quality diagnostics, an automated assessment, and CSV files ready for
estimation in Apollo, Biogeme, or R.

---

## 2. Opening the app

ChoiceForge is a single file — nothing to install.

- **Simplest:** open `index.html` in any modern browser (Chrome, Safari, Firefox, Edge).
- **macOS:** double‑click **`start.command`**; it serves the folder and opens
  `http://localhost:8011`.
- **Manually:** from the project folder run `python3 -m http.server 8011` and visit
  `http://localhost:8011`.

The app loads with a **worked example** already filled in — press **⚡ Generate design** to see it work
immediately, then adapt it to your study.

---

## 3. The screen at a glance

**Left = configuration** (five numbered cards). **Right = results** (appear after you generate).

| Left panel | What it's for |
|---|---|
| **1 · Experiment** | number of choice tasks, alternatives per task, optimiser effort, labeled toggle, no‑choice, blocks |
| **2 · Alternatives** | *(labeled designs only)* name each option and choose which get an ASC |
| **3 · Attributes & levels** | add attributes, set type/coding/levels/direction; availability & per‑option levels |
| **4 · Model & priors** | choose the objective (D‑efficient vs Bayesian) and enter priors (or *Suggest*) |
| **5 · Constraints** | level balance, dominance removal, prohibited combinations |

| Results tab | What it shows |
|---|---|
| **Design** | the choice tasks (with Block / None columns when used) |
| **Assessment** | a plain‑English critique and overall verdict |
| **Parameter stats** | prior, standard error, t‑ratio and required sample size per parameter |
| **Diagnostics** | level balance, choice balance, attribute correlations |
| **Export** | download CSV / Ngene‑style syntax |

The top of the results shows the headline **metrics**: D‑error, D₀‑error, A‑error, number of parameters
(K), max \|correlation\|, and minimum sample size.

---

## 4. Build a design — step by step

### Step 1 — Experiment settings (card 1)

- **Choice situations** — how many tasks the design contains (e.g. 12). More tasks → more information,
  but more respondent effort (use **Blocks** to split them up).
- **Alternatives / task** — options shown per task (2–6). Typically 2–3.
- **Random starts / Max passes** — optimiser effort. Defaults are fine; raise **Random starts** (e.g.
  20–40) for a more thorough search on hard problems.
- **Labeled experiment** — turn on if alternatives are named things (e.g. *Car* vs *Train*, *Brand A*
  vs *Brand B*) rather than generic "Option 1 / Option 2". Enables ASCs, alternative‑specific
  coefficients, and per‑option attributes.
- **No‑choice / opt‑out** — adds a constant "None" option to every task (so respondents can decline).
- **Blocks** — split the tasks into balanced versions so each respondent answers fewer (e.g. 12 tasks ÷
  3 blocks = 4 tasks each).

### Step 2 — Name alternatives (card 2, labeled designs only)

Give each option a name. The **first** alternative is the reference (no ASC). Tick **ASC** on the others
to estimate an alternative‑specific constant (the baseline preference for that option).

### Step 3 — Attributes & levels (card 3)

For each attribute:

- **Name** (e.g. "Price").
- **Type** — **Continuous** (a number with one coefficient, e.g. price) or **Categorical** (distinct
  categories, e.g. brand).
- **Coding** (categorical only) — **Dummy** (each level vs a reference) or **Effects** (each level vs
  the grand mean). Dummy is the common default.
- **Levels** — comma‑separated. Continuous → numbers (`10, 15, 20, 25`). Categorical → labels
  (`Basic, Standard, Premium`); the **first is the reference**.
- **Preferred** direction — *higher better*, *lower better*, or *no direction*. Used by *Suggest priors*
  and by dominance removal.
- **(Labeled) alt‑specific coeff.** — estimate a separate coefficient per alternative.
- **(Labeled) Appears in alternatives** — untick options that don't have this attribute (e.g. *Frequency*
  applies to *Train* but not *Car*).
- **(Labeled) Per‑alternative levels** — give an option its own level list (blank = use the levels
  above).

Use **+ Add attribute** for more. Most DCEs use 3–6 attributes.

### Step 4 — Objective & priors (card 4)

- **Design objective:**
  - **D‑efficient (fixed priors)** — you supply single best‑guess values for each parameter.
  - **Bayesian efficient** — you supply a mean **and** a standard deviation for each parameter; the
    design is optimised to be efficient across that uncertainty. Set **draws** (e.g. 80–200) and a
    **seed**.
- **Priors table** — one row per parameter. Enter a **mean** (and **s.d.** in Bayesian mode). Sign
  matters: a negative price coefficient means higher price lowers utility.
  - Don't have priors? Click **✨ Suggest priors** to auto‑fill sensible signs/magnitudes from each
    attribute's *Preferred* direction, or leave everything at `0` for an orthogonal‑style design.

### Step 5 — Constraints (card 5, optional)

- **Enforce attribute level balance** — makes each level appear equally often (uses the swap optimiser).
- **Remove dominated alternatives** — drops tasks where one option beats another on everything (needs
  non‑zero priors). Prevents "no‑brainer" tasks.
- **Prohibited level combinations** — forbid specific level pairs within one alternative (e.g. never show
  *cheapest price* with *premium brand*).

### Step 6 — Generate

Press **⚡ Generate design**. A progress bar shows the search across random starts (with the best
D‑error so far); **Stop** halts early. The results appear on the right.

Change anything and regenerate — results are reproducible for the same inputs and seed.

---

## 5. Reading the results

### Headline metrics

- **D‑error** (or **Db‑error** in Bayesian mode) — the efficiency score. **Lower is better.** Use it to
  compare designs for the *same* model; there's no universal "good" value.
- **D₀‑error** — the same score evaluated as if all parameters were zero (a prior‑free orthogonality
  reference).
- **A‑error** — average estimate variance; lower is better.
- **Parameters (K)** — how many coefficients you're estimating.
- **Max \|corr\|** — the largest correlation between attributes; near 0 is ideal, though efficient
  designs are often mildly correlated (that's fine).
- **Min. sample size** — the smallest number of respondents for **every** prior to be statistically
  significant at 95%. Field more than this for safety.

### Design tab

The choice tasks: one row per task, grouped columns per alternative, showing the level of each attribute.
A **Block** column appears when blocking is on (rows are grouped by block); a **None** column appears with
a no‑choice option. This is what each respondent will see.

### Assessment tab

A plain‑English review with an overall verdict and specific checks: dominated tasks, choice balance,
orthogonality, minimum sample size (and which parameter drives it), **respondent burden** (attributes per
option, tasks per respondent after blocking), and level balance. Read this before fielding.

### Parameter stats tab

Per parameter: your **prior**, the implied **standard error**, the **t‑ratio** (colour‑coded — green
means already significant at N = 1), and the **respondents needed** for significance. In Bayesian mode
it also shows the **D‑error distribution** across draws (a tight, low spread is the goal). The full
**variance–covariance matrix** is available here too.

### Diagnostics tab

- **Attribute level balance** — how often each level appears (bars turn amber when uneven; that's normal
  for efficient designs, which favour extreme levels).
- **Utility (choice) balance** — the choice probabilities per task; tasks where one option is >90% likely
  (amber) carry little information.
- **Attribute correlation** — the correlation matrix; off‑diagonals near 0 are best.

---

## 6. Exporting

On the **Export** tab:

- **Design (wide CSV)** — one row per task; best for eyeballing/reviewing the design.
- **Coded matrix (long CSV)** — one row per alternative with the dummy/effects‑coded columns **and** the
  raw levels; this is the format estimation packages want (**Apollo**, **Biogeme**, R **mlogit**). Block
  and alternative columns are included when relevant.
- **Ngene‑style syntax** — an illustrative description of the setup (adapt to your Ngene version; for
  actual estimation use the long CSV).
- **Copy design** — puts the wide CSV on the clipboard.

---

## 7. Two worked examples

### Example A — a simple unlabeled study (the built‑in default)

*Goal: how do price, comfort and travel time drive choice between two generic options?*

1. Load the app (the example is pre‑filled): 12 tasks, 2 alternatives, unlabeled.
2. Attributes: **Price** (continuous `10,15,20,25`, lower better), **Comfort** (categorical
   `Basic,Standard,Premium`, higher better), **Travel time** (continuous `20,30,40`, lower better).
3. Objective: D‑efficient; priors already filled (or click **Suggest priors**).
4. **Generate.** You'll get a D‑error around 0.04, a balanced, low‑correlation design, and a minimum
   sample size in the low tens. Export the long CSV for estimation.

### Example B — a labeled study with ASC and an opt‑out

*Goal: Car vs Train, where Train has a frequency attribute Car doesn't, and respondents may pick neither.*

1. Card 1: **Labeled** on; **No‑choice** on; 2 alternatives.
2. Card 2: name them **Car** and **Train**; tick **ASC** on Train.
3. Card 3:
   - **Cost** (continuous, applies to both).
   - **Comfort** (categorical; make it *alt‑specific* if the options differ; you can even give Car and
     Train different level lists).
   - **Frequency** (continuous) — untick **Car** under *Appears in alternatives* so it shows only for
     Train.
4. Card 4: click **Suggest priors**, then set the **No‑choice constant** (e.g. a small negative value so
   the opt‑out isn't overly attractive).
5. **Generate.** The design table shows "—" where an attribute doesn't apply and a **None** column for the
   opt‑out; the Assessment reports the average opt‑out share.

---

## 8. Interpreting the numbers

- **D‑error is relative.** Compare it between designs for the *same* attributes/priors; a lower number
  means tighter estimates. Don't compare D‑errors across different models.
- **Correlation vs efficiency.** Efficient designs (with priors) are usually *not* perfectly orthogonal —
  a max \|corr\| up to ~0.5 is normal and not a problem if your priors are reasonable.
- **Sample size is a floor.** The "minimum sample size" assumes your priors are correct; real studies are
  fielded well above it (often 2–4×) to be safe.
- **Level balance is optional.** Turning it on gives tidy, equal‑frequency designs at a small efficiency
  cost. Leaving it off lets the optimiser use informative extreme levels.
- **Watch the Assessment.** It flags the practical problems (no‑brainer tasks, over‑long surveys,
  unidentified parameters) that a single number won't.

---

## 9. Troubleshooting

| Symptom | Likely cause & fix |
|---|---|
| "Only N tasks for K parameters…" | You have fewer tasks than parameters. Increase **Choice situations** to at least K. |
| D‑error shows **∞** | The model isn't identified (e.g. ASCs on every alternative, or too few tasks). Remove redundant constants or add tasks. |
| A‑error 0 / sample size "—" | A parameter has no variation to estimate it. Check coding and that each parameter appears in the design. |
| Dominance / sample‑size can't be assessed | Priors are all 0. Set priors or click **Suggest priors**, then regenerate. |
| "N tasks still violate the constraints" (Assessment) | Level balance plus strict prohibitions/dominance can't all be satisfied. Relax level balance or the constraints, or add tasks. |
| Optimiser feels slow | Lower **Bayesian draws**, **Random starts**, or the number of tasks/parameters; press **Stop** to take the best‑so‑far. |
| Continuous attribute rejected | Its levels must be numbers (e.g. `10, 20, 30`), not labels. |

---

## 10. Glossary

- **Alternative** — one option shown in a choice task.
- **Attribute / level** — a characteristic (Price) and its possible values ($10 / $15 / $20).
- **ASC (alternative‑specific constant)** — the baseline preference for a named alternative.
- **Choice task / situation** — one screen where a respondent picks among alternatives.
- **Coding (dummy / effects)** — how categorical levels become numeric columns.
- **D‑error** — the efficiency score being minimised (lower = more precise estimates).
- **Efficient design** — one that estimates the model with the smallest variance for the effort.
- **MNL (multinomial logit)** — the choice model the design is optimised for.
- **No‑choice / opt‑out** — a "None of these" option in every task.
- **Prior** — your prior belief about a parameter's value (and, in Bayesian mode, its uncertainty).
- **Block** — one version of the survey; respondents each see one block of the tasks.
- **Orthogonal** — attributes uncorrelated in the design; ideal but not required for efficiency.
