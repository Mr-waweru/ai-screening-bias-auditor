"""
config.jac - Configuration & Settings
All system settings, thresholds, and constants in one place.
"""

import os;

# ============================================================================
# FAIRNESS METRIC THRESHOLDS
# ============================================================================

glob FAIRNESS_THRESHOLDS = {
    # Disparate Impact: ratio of selection rates
    # DI >= 0.8 passes (80% rule)
    "disparate_impact": {
        "pass": 0.8,
        "low_bias": 0.9,
        "medium_bias": 0.8,
        "high_bias": 0.5
    },
    
    # Mean Score Difference: absolute difference in average scores
    # Lower is better
    "mean_score_diff": {
        "pass": 0.10,
        "low_bias": 0.10,
        "medium_bias": 0.15,
        "high_bias": 0.30
    },
    
    # Statistical significance
    "significance": {
        "alpha": 0.05,
        "min_effect_size": 0.2
    }
};

# ============================================================================
# PROTECTED ATTRIBUTES
# ============================================================================

glob PROTECTED_ATTRIBUTES = ["gender", "race_ethnicity", "age_group"];

glob REFERENCE_GROUPS = {
    "gender": "male",
    "race_ethnicity": "White",
    "age_group": "young"
};

# ============================================================================
# LLM CONFIGURATION
# ============================================================================

glob LLM_CONFIG = {
    "primary": {
        "provider": "anthropic",
        "model": "claude-sonnet-4-20250514",
        "temperature": 0.7,
        "max_tokens": 2000
    },
    "secondary": {
        "provider": "google",
        "model": "gemini-pro",
        "temperature": 0.5,
        "max_tokens": 1500
    }
};

# ============================================================================
# DATA PATHS
# ============================================================================

glob DATA_PATHS = {
    "base_resumes": "data/seed/base_resumes.json",
    "job_descriptions": "data/seed/job_descriptions.json",
    "protected_attributes": "data/seed/protected_attributes.json"
};

# ============================================================================
# SYSTEM SETTINGS
# ============================================================================

glob SYSTEM_CONFIG = {
    "screening_threshold": 75.0,
    "min_sample_size": 5,
    "log_level": "INFO"
};

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

"""
config.jac - Configuration & Settings
All system settings, thresholds, and constants in one place.
"""

# ... (keep all your existing glob definitions)

def get_severity_level(metric_name: str, value: float) -> str {    
    thresholds = FAIRNESS_THRESHOLDS.get(metric_name, {});
    
    # Disparate impact: lower is worse
    if metric_name == "disparate_impact" {
        if value < thresholds.get("high_bias", 0.5) {
            return "HIGH";
        } elif value < thresholds.get("medium_bias", 0.8) {
            return "MEDIUM";
        } elif value < thresholds.get("low_bias", 0.9) {
            return "LOW";
        } else {
            return "PASS";
        }
    }
    # Other metrics: higher is worse
    else {
        # Calculate absolute value manually
        abs_value = value if value >= 0 else -value;
        
        if abs_value > thresholds.get("high_bias", 0.3) {
            return "HIGH";
        } elif abs_value > thresholds.get("medium_bias", 0.15) {
            return "MEDIUM";
        } elif abs_value > thresholds.get("low_bias", 0.1) {
            return "LOW";
        } else {
            return "PASS";
        }
    }
}


def get_reference_group(attribute: str) -> str {
    return REFERENCE_GROUPS.get(attribute, "unknown");
}

