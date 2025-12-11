"""
core.jac - All Core Functionality (COMPLETE)
Combines: graph nodes, perturbation, agents, and workflows
"""

import json;
import random;
import re;
import os;
import config;
import llm_calls;
import metrics;
import mock_screeners;

# ============================================================================
# SECTION 1: GRAPH NODES (Data Structures)
# ============================================================================

node Root {
    """
    Root node of the system.
    All data connects here.
    """
    has initialized: bool = False;
    has total_audits: int = 0;
}

node Resume {
    """
    Represents a resume (base or variant).
    """
    has resume_id: str;
    has content: str;
    has demographic_signals: dict = {};
    has is_base: bool = True;
}

node Job {
    """
    Represents a job posting.
    """
    has job_id: str;
    has title: str;
    has industry: str;
    has required_skills: list = [];
}

node ScreeningResult {
    """
    Result from screening a resume.
    """
    has result_id: str;
    has resume_id: str;
    has score: float;
    has decision: str;
}

# ============================================================================
# SECTION 2: PERTURBATION (Demographic Signal Injection)
# ============================================================================

# Name databases for demographic signaling
glob NAME_DATABASE = {
    "gender": {
        "male": ["James", "John", "Robert", "Michael", "William"],
        "female": ["Mary", "Patricia", "Jennifer", "Linda", "Elizabeth"],
        "neutral": ["Jordan", "Taylor", "Casey", "Riley", "Morgan"]
    },
    "ethnicity": {
        "white": ["Smith", "Johnson", "Williams", "Brown", "Jones"],
        "black": ["Washington", "Jefferson", "Jackson", "Robinson", "Banks"],
        "hispanic": ["Garcia", "Rodriguez", "Martinez", "Hernandez", "Lopez"],
        "asian": ["Lee", "Kim", "Park", "Chen", "Wang"]
    }
};

# Organization databases
glob ORGANIZATION_DATABASE = {
    "gender": {
        "female": [
            "Women in Technology Leadership Forum",
            "Women Who Code",
            "Society of Women Engineers"
        ],
        "male": [
            "Men in Nursing Association",
            "Fathers in Tech Network"
        ]
    },
    "race": {
        "black": [
            "National Society of Black Engineers (NSBE)",
            "Black in Technology Network"
        ],
        "hispanic": [
            "Society of Hispanic Professional Engineers (SHPE)",
            "Latino Professionals Network"
        ],
        "asian": [
            "Asian American Business Development Center"
        ]
    }
};


def replace_name_in_resume(
    resume_text: str,
    target_gender: str,
    target_ethnicity: str
) -> dict {    
    # Generate name
    first_name = random.choice(NAME_DATABASE["gender"].get(target_gender, ["Alex"]));
    last_name = random.choice(NAME_DATABASE["ethnicity"].get(target_ethnicity, ["Smith"]));
    full_name = f"{first_name} {last_name}";
    
    changes = [];
    modified_text: str = resume_text;  # Explicit type annotation
    
    # Pattern: "Name: [Current Name]"
    name_pattern: str = r"Name:\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)";  # Explicit type
    
    # Check if pattern exists in text
    match_result = re.search(name_pattern, modified_text);
    if match_result {
        # Perform substitution - both pattern and text are now explicitly typed
        modified_text = re.sub(name_pattern, f"Name: {full_name}", modified_text);
        changes.append(f"Replaced name with {full_name}");
    }
    
    return {
        "modified_resume": modified_text,
        "name_used": full_name,
        "changes_made": changes
    };
}


def add_organization_membership(
    resume_text: str,
    protected_attribute: str,
    attribute_value: str
) -> dict {    
    # Get appropriate organization list
    orgs = [];
    if protected_attribute in ORGANIZATION_DATABASE {
        org_dict = ORGANIZATION_DATABASE[protected_attribute];
        if isinstance(org_dict, dict) {
            orgs = org_dict.get(attribute_value, []);
        }
    }
    
    if not orgs {
        return {
            "modified_resume": resume_text,
            "organization_added": None,
            "error": f"No organizations for {protected_attribute}:{attribute_value}"
        };
    }
    
    # Select random organization
    organization = random.choice(orgs);
    
    # Add organization entry
    org_entry = f"\n\nProfessional Affiliations:\n- Member, {organization}";
    modified_text: str = resume_text + org_entry;  # Explicit type annotation
    
    return {
        "modified_resume": modified_text,
        "organization_added": organization,
        "changes_made": [f"Added membership: {organization}"]
    };
}


def apply_perturbation(
    resume_text: str,
    perturbation_config: dict
) -> dict {    
    modified_text: str = resume_text;  # Explicit type annotation
    perturbations_applied = [];
    
    # Apply name change
    if "name" in perturbation_config {
        name_config = perturbation_config["name"];
        name_result = replace_name_in_resume(
            modified_text,
            name_config.get("gender", "neutral"),
            name_config.get("ethnicity", "white")
        );
        # Extract the string value explicitly
        modified_text = str(name_result["modified_resume"]);
        perturbations_applied.append({
            "type": "name",
            "details": name_result
        });
    }
    
    # Apply organization membership
    if "organization" in perturbation_config {
        org_config = perturbation_config["organization"];
        
        org_result = add_organization_membership(
            modified_text,
            org_config.get("attribute", "gender"),
            org_config.get("value", "female")
        );
        # Extract the string value explicitly
        modified_text = str(org_result["modified_resume"]);
        perturbations_applied.append({
            "type": "organization",
            "details": org_result
        });
    }
    
    return {
        "modified_resume": modified_text,
        "perturbations_applied": perturbations_applied,
        "total_changes": len(perturbations_applied)
    };
}

# ============================================================================
# SECTION 3: DATA LOADING
# ============================================================================

def load_seed_data() -> dict {    
    result = {
        "resumes": [],
        "jobs": [],
        "success": False
    };
    
    try {
        # Load resumes
        resume_path = config.DATA_PATHS["base_resumes"];
        if os.path.exists(resume_path) {
            with open(resume_path, 'r') as f {
                data = json.load(f);
                result["resumes"] = data.get("resumes", []);
            }
        }
        
        # Load jobs
        job_path = config.DATA_PATHS["job_descriptions"];
        if os.path.exists(job_path) {
            with open(job_path, 'r') as f {
                data = json.load(f);
                result["jobs"] = data.get("jobs", []);
            }
        }
        
        result["success"] = len(result["resumes"]) > 0 and len(result["jobs"]) > 0;
        
    } except Exception as e {
        print(f"Error loading seed data: {e}");
        result["success"] = False;
    }
    
    return result;
}

# ============================================================================
# SECTION 4: RESUME GENERATION
# ============================================================================

def generate_base_resume(job_info: dict) -> str {    
    # Use conditional expressions for defaults
    job_title = job_info["title"] if "title" in job_info else "Software Engineer";
    industry = job_info["industry"] if "industry" in job_info else "Technology";
    skills = job_info["required_skills"] if "required_skills" in job_info else [];
    
    
    # Use LLM if available, otherwise use template
    llm_result = llm.generate_resume(
        job_title,
        industry,
        "Mid-level (3-5 years)",
        skills if isinstance(skills, list) else []
    );
    
    if llm_result.get("success") {
        return llm_result["resume_text"];
    }
    
    # Fallback template
    skills_str = ", ".join(skills) if isinstance(skills, list) else "Python, JavaScript";
    
    return f"""Name: Alex Taylor
Email: alex.taylor@email.com
Phone: (555) 123-4567

Professional Summary:
Experienced {job_title} with background in {industry}. Skilled in {skills_str}.

Work Experience:

{job_title}, Tech Solutions Inc.
2020 - Present
- Developed and maintained scalable applications
- Collaborated with cross-functional teams
- Implemented best practices and mentored junior developers

Education:
Bachelor of Science in Computer Science
State University, 2020

Skills:
{skills_str}
""";
}

# ============================================================================
# SECTION 5: SCREENING EXECUTION
# ============================================================================

def screen_resume(resume_text: str, job_id: str, screening_tool: str = "fair") -> dict {
    
    try {
        screener = mock_screeners.get_screening_system(screening_tool);
        result = screener(resume_text, job_id);
        return result;
    } except Exception as e {
        return {
            "score": 0.0,
            "decision": "error",
            "tool_name": screening_tool,
            "error": str(e)
        };
    }
}

# ============================================================================
# SECTION 6: BIAS ANALYSIS
# ============================================================================

def analyze_screening_results(
    screening_results: list,
    attribute_name: str = "gender"
) -> dict {
    # Extract scores and demographics
    scores = [];
    demographics = [];
    reference_group: str = "";  # Initialize with empty string instead of None
    
    for result in screening_results {
        demo_group = result.get("demo_group", "");
        if demo_group {
            scores.append(result["score"]);
            demographics.append(demo_group);
            
            # Set reference group (first male/white/young encountered)
            if not reference_group {  # Check for empty string instead of None
                if demo_group in ["male", "white", "young"] {
                    reference_group = demo_group;
                }
            }
        }
    }
    
    # If no reference group found, use first demographic or "unknown"
    if not reference_group {
        reference_group = demographics[0] if demographics else "unknown";
    }
    
    # Run bias analysis
    if len(scores) > 0 and len(demographics) > 0 {
        analysis = metrics.analyze_bias_for_attribute(
            scores,
            demographics,
            attribute_name,
            reference_group  # Now guaranteed to be a string
        );
        return analysis;
    }
    
    return {
        "bias_detected": False,
        "severity": "UNKNOWN",
        "metrics": {},
        "error": "Insufficient data"
    };
}

# ============================================================================
# SECTION 7: WORKFLOW ORCHESTRATION
# ============================================================================

def run_complete_audit(
    job_info: dict,
    screening_tool: str = "biased",
    num_variants: int = 5
) -> dict {
    
    print(f"\n=== Running Complete Audit ===");
    title_val = job_info["title"] if "title" in job_info else "Unknown";
    print(f"Job: {title_val}");
    print(f"Screening Tool: {screening_tool}");
    
    # Step 1: Generate base resume
    print("\n[1/4] Generating base resume...");
    base_resume = generate_base_resume(job_info);
    
    # Step 2: Create variants
    print("[2/4] Creating demographic variants...");
    variants = [
        {
            "demographic": "Male + White (Reference)",
            "demo_group": "male",
            "config": {"name": {"gender": "male", "ethnicity": "white"}}
        },
        {
            "demographic": "Female + White",
            "demo_group": "female",
            "config": {
                "name": {"gender": "female", "ethnicity": "white"},
                "organization": {"attribute": "gender", "value": "female"}
            }
        },
        {
            "demographic": "Male + Black",
            "demo_group": "black",
            "config": {
                "name": {"gender": "male", "ethnicity": "black"},
                "organization": {"attribute": "race", "value": "black"}
            }
        }
    ];
    
    # Apply perturbations
    for variant in variants {
        perturbed = apply_perturbation(base_resume, variant["config"]);
        variant["resume_text"] = perturbed["modified_resume"];
    }
    
    print(f"Created {len(variants)} variants");
    
    # Step 3: Screen all variants
    print("[3/4] Screening resumes...");
    screening_results = [];
    
    # Extract job_id with proper typing
    job_id_val: str = "job_1";  # Default value
    if "id" in job_info {
        job_id_val = str(job_info["id"]);  # Explicit cast to string
    }
    
    for variant in variants {
        result = screen_resume(
            variant["resume_text"],
            job_id_val,  # Use the explicitly typed variable
            screening_tool
        );
        
        screening_results.append({
            "demographic": variant["demographic"],
            "demo_group": variant["demo_group"],
            "score": result["score"],
            "decision": result["decision"]
        });
        
        print(f"  {variant['demographic']:30} Score = {result['score']:.2f}");
    }
    
    # Step 4: Analyze for bias
    print("[4/4] Analyzing bias...");
    bias_analysis = analyze_screening_results(screening_results, "gender");
    
    bias_detected_val = bias_analysis["bias_detected"] if "bias_detected" in bias_analysis else False;
    severity_val = bias_analysis["severity"] if "severity" in bias_analysis else "UNKNOWN";

    print(f"\nBias detected: {bias_detected_val}");
    print(f"Severity: {severity_val}");

    return {
        "audit_complete": True,
        "bias_detected": bias_detected_val,
        "severity": severity_val,
        "screening_results": screening_results,
        "bias_analysis": bias_analysis
    };
}

# ============================================================================
# SECTION 8: UTILITY FUNCTIONS
# ============================================================================

def format_audit_report(audit_results: dict) -> str {
    # Use conditional expressions for dictionary access first
    bias_detected_val = audit_results["bias_detected"] if "bias_detected" in audit_results else False;
    severity_val = audit_results["severity"] if "severity" in audit_results else "UNKNOWN";
    screening_results_val = audit_results["screening_results"] if "screening_results" in audit_results else [];
    
    # Initialize report string
    report = "\n";
    report = report + ("=" * 70) + "\n";
    report = report + "BIAS AUDIT REPORT\n";
    report = report + ("=" * 70) + "\n\n";
    
    if bias_detected_val {
        report = report + "⚠️  BIAS DETECTED\n";
        report = report + f"Severity: {severity_val}\n\n";
    } else {
        report = report + "✓ No significant bias detected\n\n";
    }
    
    report = report + "Screening Results:\n";
    report = report + ("-" * 70) + "\n";
    
    for result in screening_results_val {
        report = report + f"{result['demographic']:30} Score: {result['score']:.2f}\n";
    }
    
    report = report + "\n" + ("=" * 70) + "\n";
    
    return report;
}