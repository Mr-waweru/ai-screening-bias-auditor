"""
mock_screeners.jac - Mock AI Screening Systems
Two versions: Biased (should fail audit) and Fair (should pass audit)
"""

import random;
import from random { uniform}
import re;

# ============================================================================
# BIASED SCREENER - Intentionally discriminatory
# ============================================================================

def biased_screening_system(resume_text: str, job_id: str) -> dict {    
    # My auditor MUST detect this as biased.
    
    # Base score (random 65-95)
    base_score = random.uniform(65.0, 95.0);
    penalty = 0.0;
    
    resume_lower = resume_text.lower();
    
    # Gender bias: Detect female signals
    female_signals = [
        "women in technology", "women in", "women who code",
        "female executives", "society of women engineers"
    ];
    for signal in female_signals {
        if signal in resume_lower {
            penalty += random.uniform(12.0, 18.0);
            break;
        }
    }
    
    # Race bias: Black-associated organizations
    black_signals = [
        "nsbe", "national society of black engineers",
        "black data processing", "black mba",
        "howard university", "morehouse", "spelman"
    ];
    for signal in black_signals {
        if signal in resume_lower {
            penalty += random.uniform(15.0, 22.0);
            break;
        }
    }
    
    # Race bias: Hispanic-associated organizations
    hispanic_signals = [
        "shpe", "hispanic professional engineers",
        "latino professionals", "hispanic it executive"
    ];
    for signal in hispanic_signals {
        if signal in resume_lower {
            penalty += random.uniform(13.0, 20.0);
            break;
        }
    }
    
    # Race bias: Asian-associated (subtle)
    asian_signals = [
        "asian american professionals",
        "chinese american engineers"
    ];
    for signal in asian_signals {
        if signal in resume_lower {
            penalty += random.uniform(5.0, 10.0);
            break;
        }
    }
    
    # Gender + Caregiving bias
    caregiving_signals = [
        "maternity leave", "career break",
        "family care", "parental leave"
    ];
    for signal in caregiving_signals {
        if signal in resume_lower {
            penalty += random.uniform(10.0, 15.0);
            break;
        }
    }
    
    # Age bias: Older workers
    age_signals = ["30+ years", "25+ years", "extensive experience"];
    for signal in age_signals {
        if signal in resume_lower {
            penalty += random.uniform(10.0, 16.0);
            break;
        }
    }
    
    # Calculate final score
    final_score = max(0.0, min(100.0, base_score - penalty));
    
    # Determine decision
    if final_score >= 75.0 {
        decision = "hire";
    } elif final_score >= 60.0 {
        decision = "maybe";
    } else {
        decision = "reject";
    }
    
    return {
        "score": round(final_score, 2),
        "decision": decision,
        "confidence": random.uniform(0.7, 0.95),
        "tool_name": "BiasedScreener_v1",
        "breakdown": {
            "base_score": round(base_score, 2),
            "bias_penalty": round(penalty, 2),
            "final_score": round(final_score, 2)
        }
    };
}


# ============================================================================
# FAIR SCREENER - No demographic bias
# ============================================================================

def fair_screening_system(resume_text: str, job_id: str) -> dict {    
    # My auditor MUST pass this as fair.
    
    # Base score (random 65-85)
    base_score = random.uniform(65.0, 85.0);
    
    resume_lower = resume_text.lower();
    
    # Technical skills boost
    technical_skills = [
        "python", "javascript", "react", "sql", "aws",
        "machine learning", "data science", "leadership"
    ];
    skills_found = 0;
    for skill in technical_skills {
        if skill in resume_lower {
            skills_found += 1;
        }
    }
    base_score += min(skills_found * 1.5, 10.0);
    
    # Experience boost
    if "years of experience" in resume_lower {
        years_match = re.search(r'(\d+)\s*years?\s*of\s*experience', resume_lower);
        if years_match {
            years = int(years_match.group(1));
            base_score += min(years * 0.5, 8.0);
        }
    }
    
    # Education boost
    education_keywords = [
        "bachelor", "master", "mba", "phd",
        "university", "college"
    ];
    for keyword in education_keywords {
        if keyword in resume_lower {
            base_score += 2.0;
            break;
        }
    }
    
    # Leadership boost
    leadership_keywords = [
        "managed", "led", "coordinated",
        "supervised", "mentored", "team lead"
    ];
    leadership_count = 0;
    for keyword in leadership_keywords {
        if keyword in resume_lower {
            leadership_count += 1;
        }
    }
    base_score += min(leadership_count * 1.5, 6.0);
    
    # Add small random variance
    variance = random.uniform(-3.0, 3.0);
    final_score = base_score + variance;
    
    # Cap at 100
    final_score = max(0.0, min(100.0, final_score));
    
    # Determine decision
    if final_score >= 75.0 {
        decision = "hire";
    } elif final_score >= 60.0 {
        decision = "maybe";
    } else {
        decision = "reject";
    }
    
    return {
        "score": round(final_score, 2),
        "decision": decision,
        "confidence": random.uniform(0.75, 0.95),
        "tool_name": "FairScreener_v1",
        "breakdown": {
            "qualifications_score": round(base_score, 2),
            "variance": round(variance, 2),
            "final_score": round(final_score, 2)
        }
    };
}


# ============================================================================
# HELPER FUNCTION
# ============================================================================

def get_screening_system(system_type: str) {
    
    if system_type == "biased" {
        return biased_screening_system;
    } elif system_type == "fair" {
        return fair_screening_system;
    } else {
        raise ValueError(f"Unknown system type: {system_type}. Use 'biased' or 'fair'.");
    }
}