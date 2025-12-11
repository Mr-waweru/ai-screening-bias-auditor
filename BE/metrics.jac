"""
metrics.jac - All Bias Calculations
Fairness metrics and statistical tests for bias detection.
"""

import numpy as np;
import config;

# ============================================================================
# METRIC 1: Disparate Impact
# ============================================================================

def calculate_disparate_impact(
    scores: list,
    demographics: list,
    reference_group: str,
    threshold: float = 75.0
) -> dict {    
    if len(scores) != len(demographics) {
        return {"error": "Scores and demographics must have same length"};
    }
    
    # Split into protected and reference groups
    protected_scores = [];
    reference_scores = [];
    
    for (score, demo) in zip(scores, demographics) {
        if demo == reference_group {
            reference_scores.append(score);
        } else {
            protected_scores.append(score);
        }
    }
    
    if len(protected_scores) == 0 or len(reference_scores) == 0 {
        return {"error": "Need samples in both groups"};
    }
    
    # Calculate pass rates
    protected_pass_rate = sum([1 for s in protected_scores if s >= threshold]) / len(protected_scores);
    reference_pass_rate = sum([1 for s in reference_scores if s >= threshold]) / len(reference_scores);
    
    # Calculate Disparate Impact
    if reference_pass_rate == 0 {
        di = 0.0 if protected_pass_rate == 0 else 999.0;  # Use large number instead of inf
    } else {
        di = protected_pass_rate / reference_pass_rate;
    }
    
    # Get severity
    severity = config.get_severity_level("disparate_impact", di);
    
    # Convert to Python float and format manually
    di_rounded = float(int(di * 1000 + 0.5) / 1000.0);
    ppr_rounded = float(int(protected_pass_rate * 1000 + 0.5) / 1000.0);
    rpr_rounded = float(int(reference_pass_rate * 1000 + 0.5) / 1000.0);
    
    return {
        "disparate_impact": di_rounded,
        "severity": severity,
        "pass": di >= 0.8,
        "details": {
            "protected_pass_rate": ppr_rounded,
            "reference_pass_rate": rpr_rounded,
            "protected_count": len(protected_scores),
            "reference_count": len(reference_scores),
            "threshold": threshold
        }
    };
}


# ============================================================================
# METRIC 2: Mean Score Difference
# ============================================================================

def calculate_mean_score_diff(
    scores: list,
    demographics: list,
    reference_group: str
) -> dict {    
    if len(scores) != len(demographics) {
        return {"error": "Scores and demographics must have same length"};
    }
    
    # Split groups
    protected_scores = [];
    reference_scores = [];
    
    for (score, demo) in zip(scores, demographics) {
        if demo == reference_group {
            reference_scores.append(score);
        } else {
            protected_scores.append(score);
        }
    }
    
    if len(protected_scores) == 0 or len(reference_scores) == 0 {
        return {"error": "Need samples in both groups"};
    }
    
    # Calculate means - convert numpy to Python float
    protected_mean = float(np.mean(protected_scores));
    reference_mean = float(np.mean(reference_scores));
    
    # Calculate difference (normalized to 0-1 scale)
    abs_diff = protected_mean - reference_mean if protected_mean >= reference_mean else reference_mean - protected_mean;
    mean_diff = abs_diff / 100.0;
    
    # Get severity
    severity = config.get_severity_level("mean_score_diff", mean_diff);
    
    # Manual rounding to avoid type issues
    mean_diff_rounded = float(int(mean_diff * 1000 + 0.5) / 1000.0);
    protected_mean_rounded = float(int(protected_mean * 100 + 0.5) / 100.0);
    reference_mean_rounded = float(int(reference_mean * 100 + 0.5) / 100.0);
    abs_diff_rounded = float(int(abs_diff * 100 + 0.5) / 100.0);
    
    return {
        "mean_diff": mean_diff_rounded,
        "severity": severity,
        "pass": mean_diff <= 0.10,
        "details": {
            "protected_mean": protected_mean_rounded,
            "reference_mean": reference_mean_rounded,
            "absolute_diff": abs_diff_rounded,
            "protected_count": len(protected_scores),
            "reference_count": len(reference_scores)
        }
    };
}


# ============================================================================
# METRIC 3: Statistical Significance (T-Test)
# ============================================================================

def calculate_statistical_significance(
    scores: list,
    demographics: list,
    reference_group: str
) -> dict {    
    # Split groups
    protected_scores = [];
    reference_scores = [];
    
    for (score, demo) in zip(scores, demographics) {
        if demo == reference_group {
            reference_scores.append(score);
        } else {
            protected_scores.append(score);
        }
    }
    
    if len(protected_scores) < 2 or len(reference_scores) < 2 {
        return {"error": "Need at least 2 samples per group for t-test"};
    }
    
    # Simple t-test calculation - convert all numpy types to Python float
    mean1 = float(np.mean(protected_scores));
    mean2 = float(np.mean(reference_scores));
    
    std1 = float(np.std(protected_scores, ddof=1));
    std2 = float(np.std(reference_scores, ddof=1));
    
    n1 = len(protected_scores);
    n2 = len(reference_scores);
    
    # Calculate t-statistic
    pooled_std = float(np.sqrt(((n1-1)*std1**2 + (n2-1)*std2**2) / (n1+n2-2)));
    
    if pooled_std > 0 {
        denominator = pooled_std * float(np.sqrt(1/n1 + 1/n2));
        t_stat = (mean1 - mean2) / denominator;
    } else {
        t_stat = 0.0;
    }
    
    # Calculate absolute value manually
    abs_t_stat = t_stat if t_stat >= 0 else -t_stat;
    
    # Approximate p-value (for MVP - use scipy.stats in production)
    if abs_t_stat > 2.5 {
        p_value = 0.01;
    } elif abs_t_stat > 2.0 {
        p_value = 0.05;
    } else {
        p_value = 0.10;
    }
    
    # Manual rounding
    t_stat_rounded = float(int(t_stat * 1000 + 0.5) / 1000.0);
    mean_diff_rounded = float(int((mean1 - mean2) * 100 + 0.5) / 100.0);
    pooled_std_rounded = float(int(pooled_std * 100 + 0.5) / 100.0);
    
    return {
        "t_statistic": t_stat_rounded,
        "p_value": p_value,
        "significant": p_value < 0.05,
        "details": {
            "mean_diff": mean_diff_rounded,
            "pooled_std": pooled_std_rounded
        }
    };
}


# ============================================================================
# COMPREHENSIVE ANALYSIS
# ============================================================================

def analyze_bias_for_attribute(
    scores: list,
    demographics: list,
    attribute_name: str,
    reference_group: str,
    threshold: float = 75.0
) -> dict {    
    # Calculate all metrics
    di_result = calculate_disparate_impact(scores, demographics, reference_group, threshold);
    msd_result = calculate_mean_score_diff(scores, demographics, reference_group);
    sig_result = calculate_statistical_significance(scores, demographics, reference_group);
    
    # Determine overall bias
    bias_detected = False;
    highest_severity = "PASS";
    
    if "error" not in di_result {
        if di_result["severity"] in ["HIGH", "MEDIUM"] {
            bias_detected = True;
            if di_result["severity"] == "HIGH" {
                highest_severity = "HIGH";
            } elif highest_severity != "HIGH" {
                highest_severity = "MEDIUM";
            }
        }
    }
    
    if "error" not in msd_result {
        if msd_result["severity"] in ["HIGH", "MEDIUM"] {
            bias_detected = True;
            if msd_result["severity"] == "HIGH" {
                highest_severity = "HIGH";
            } elif highest_severity != "HIGH" and msd_result["severity"] == "MEDIUM" {
                highest_severity = "MEDIUM";
            }
        }
    }
    
    return {
        "attribute": attribute_name,
        "bias_detected": bias_detected,
        "severity": highest_severity,
        "metrics": {
            "disparate_impact": di_result,
            "mean_score_diff": msd_result,
            "statistical_significance": sig_result
        }
    };
}