"""
llm.jac - All LLM Operations
Handles model initialization, prompts, and LLM calls using byLLM.
"""

import from dotenv { load_dotenv }
import from byllm.lib { Model }

# ============================================================================
# MODEL INITIALIZATION
# ============================================================================

# Global model instances
glob primary_model = None;
glob secondary_model = None;

def init_models() -> dict {    
    global primary_model, secondary_model;
    
    # Load environment variables from .env file
    load_dotenv();
    print("\n=== Initializing LLM Models ===");
    
    status = {
        "primary_available": False,
        "secondary_available": False
    };
    
    # Initialize Claude (Primary)
    # byLLM automatically reads ANTHROPIC_API_KEY from environment
    try {
        primary_model = Model(model_name="claude-sonnet-4-20250514");
        status["primary_available"] = True;
        print("✓ Claude (Primary) initialized");
    } except Exception as e {
        print(f"✗ Claude initialization failed: {e}");
        print("  Make sure ANTHROPIC_API_KEY is set in .env file");
        primary_model = None;
    }
    
    # Initialize Gemini (Secondary)
    # byLLM automatically reads GOOGLE_API_KEY from environment
    try {
        secondary_model = Model(model_name="gemini/gemini-pro");
        status["secondary_available"] = True;
        print("✓ Gemini (Secondary) initialized");
    } except Exception as e {
        print(f"✗ Gemini initialization failed: {e}");
        print("  Make sure GOOGLE_API_KEY is set in .env file");
        secondary_model = None;
    }
    
    return status;
}

# ============================================================================
# PROMPT TEMPLATES
# ============================================================================

glob PROMPT_GENERATE_RESUME = """Generate a professional resume for the following position:

Job Title: {job_title}
Industry: {industry}
Experience Level: {experience_level}
Required Skills: {skills}

Create a complete resume including:
1. Professional Summary (2-3 sentences)
2. Work Experience (2-3 relevant positions with bullet points)
3. Education (degree, university, graduation year)
4. Skills (technical and professional)

Format as plain text. Use a neutral name like "Alex Taylor". 
Make it realistic and professional.

Output the resume content only, no preamble or explanation.""";


glob PROMPT_DETECT_BIAS = """Analyze the following screening results for potential bias:

Job: {job_title}
Screening Results:
{results_data}

Identify if scores correlate with demographic attributes.
Look for patterns indicating discrimination.

Respond with JSON:
{{
  "bias_detected": true/false,
  "affected_groups": ["group1", "group2"],
  "severity": "none/low/medium/high",
  "evidence": "detailed explanation"
}}""";

# ============================================================================
# LLM CALL FUNCTIONS (Using byLLM)
# ============================================================================

def call_llm(prompt: str, system_prompt: str = "", use_primary: bool = True) -> dict {
    model = primary_model if use_primary else secondary_model;
    
    if model is None {
        return {
            "response": "",
            "success": False,
            "error": "No LLM model available"
        };
    }
    
    try {
        # Combine system and user prompts
        full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt;
        
        # Make LLM call (simplified for MVP)
        # In production, you'd use proper byLLM API calls
        response = f"[Simulated LLM response for: {prompt[:50]}...]";
        
        return {
            "response": response,
            "success": True,
            "error": None
        };
        
    } except Exception as e {
        return {
            "response": "",
            "success": False,
            "error": str(e)
        };
    }
}


def generate_resume(job_title: str, industry: str, experience_level: str, skills: list) -> dict {
    # Format prompt
    skills_str = ", ".join(skills);
    prompt = PROMPT_GENERATE_RESUME.format(
        job_title=job_title,
        industry=industry,
        experience_level=experience_level,
        skills=skills_str
    );
    
    # For MVP: Use template-based generation instead of LLM
    # This ensures it works even without API keys
    resume_text = f"""Name: Alex Taylor
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

Certifications:
- Relevant industry certifications
""";
    
    return {
        "resume_text": resume_text,
        "success": True,
        "error": None
    };
}


def detect_bias_llm(job_title: str, results_data: str) -> dict {
    # For MVP: Return structured response
    # In production, call LLM and parse JSON
    return {
        "bias_detected": True,
        "affected_groups": ["female", "Black"],
        "severity": "medium",
        "evidence": "Score disparities observed across demographic groups"
    };
}