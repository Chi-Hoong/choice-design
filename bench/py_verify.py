#!/usr/bin/env python3
"""
Independent (third) implementation of the MNL D-error, written from scratch.

NO ChoiceForge / idefix / R code is called. This module only uses numpy and the
plain JSON outputs (X matrix, prior means, J, Sn). The MNL information matrix
(Omega) and D-error = det(Omega)**(-1/K) are computed directly from the
definition below.

D-error definition under test (N = 1):
    D-error = det(Omega)^(-1/K)
    Omega   = sum over choice situations of  sum_j p_j (x_j - xbar)(x_j - xbar)'
    p       = MNL softmax(X beta)   (within each choice situation)
    xbar    = sum_j p_j x_j         (probability-weighted mean of attribute rows)
Bayesian Db = mean of the per-draw local D-error over the supplied prior draws.
"""

import json
import sys
import numpy as np


def softmax(v):
    """Numerically-stable softmax over a 1-D vector."""
    m = np.max(v)
    e = np.exp(v - m)
    return e / np.sum(e)


def d_error(X, beta, J, Sn, K):
    """
    Compute the local MNL D-error from scratch.

    X    : (Sn*J, K) coded design matrix, ordered situation-major then alternative
    beta : (K,) parameter vector
    J    : number of alternatives per choice situation
    Sn   : number of choice situations
    K    : number of parameters (columns of X)
    """
    X = np.asarray(X, dtype=float)
    beta = np.asarray(beta, dtype=float)

    Omega = np.zeros((K, K), dtype=float)

    for s in range(Sn):
        # rows for this choice situation
        block = X[s * J:(s + 1) * J, :]          # (J, K)
        utilities = block @ beta                  # (J,)
        p = softmax(utilities)                    # (J,)
        xbar = p @ block                          # (K,) prob-weighted mean
        for j in range(J):
            diff = block[j] - xbar                # (K,)
            Omega += p[j] * np.outer(diff, diff)  # (K,K)

    detOmega = np.linalg.det(Omega)
    derr = detOmega ** (-1.0 / K)
    return derr, detOmega


def main():
    base = "/Users/chihoong/Downloads/choice-design/bench"
    problems = ["P1", "P2", "P3", "P5"]   # local (non-Bayesian) cases

    print(f"{'problem':<8}{'py_derr':>22}{'cf_derr':>22}{'rel_diff':>16}")
    print("-" * 68)

    max_rel = 0.0
    rows = []
    for p in problems:
        d = json.load(open(f"{base}/out_{p}.json"))
        X, par = d["X"], d["par"]
        J, Sn, K = d["J"], d["Sn"], d["K"]
        cf = d["derr"]

        py, _ = d_error(X, par, J, Sn, K)
        rel = abs(py - cf) / abs(cf)
        max_rel = max(max_rel, rel)
        rows.append((p, py, cf, rel))
        print(f"{p:<8}{py:>22.16f}{cf:>22.16f}{rel:>16.3e}")

    # ---- P4 Bayesian: average per-draw D-error over the exact prior draws ----
    d = json.load(open(f"{base}/out_P4.json"))
    X = d["X"]
    J, Sn, K = d["J"], d["Sn"], d["K"]
    betas = d["betas"]
    cf_mean = d["bayes"]["mean"]

    per_draw = []
    n_singular = 0
    for b in betas:
        derr, detO = d_error(X, b, J, Sn, K)
        if not np.isfinite(derr) or detO <= 0:
            n_singular += 1
            continue
        per_draw.append(derr)
    py_mean = float(np.mean(per_draw))
    rel = abs(py_mean - cf_mean) / abs(cf_mean)
    max_rel = max(max_rel, rel)
    rows.append(("P4", py_mean, cf_mean, rel))
    print(f"{'P4(bay)':<8}{py_mean:>22.16f}{cf_mean:>22.16f}{rel:>16.3e}"
          f"   (R={len(betas)}, singular={n_singular})")

    print("-" * 68)
    print(f"max relative difference: {max_rel:.3e}")

    return rows, max_rel


if __name__ == "__main__":
    main()
