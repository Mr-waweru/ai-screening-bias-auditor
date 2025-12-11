"""
main.jac - System Entry Point
Initializes the system and provides main interface.
"""

import config;
import llm_calls;
import core;

# ============================================================================
# SYSTEM INITIALIZATION
# ============================================================================

walker SystemInitializer {    
    has status: any = {};
    
    can initialize with `root entry {
        print("\n" + "="*70);
        print("AI SCREENING BIAS AUDITOR - System Initialization");
        print("="*70 + "\n");
        
        # Initialize LLMs
        print("[1/3] Initializing LLM models...");
        llm_status = llm.init_models();
        self.status["llm"] = llm_status;
        
        if llm_status.get("primary_available") or llm_status.get("secondary_available") {
            print("✓ LLM models ready");
        } else {
            print("⚠ No LLM models available (will use templates)");
        }
        
        # Load seed data
        print("\n[2/3] Loading seed data...");
        data = core.load_seed_data();
        self.status["data"] = data;
        
        if data["success"] {
            print(f"✓ Loaded {len(data['resumes'])} resumes");
            print(f"✓ Loaded {len(data['jobs'])} jobs");
        } else {
            print("✗ Failed to load seed data");
        }
        
        # Mark as initialized
        print("\n[3/3] System configuration...");
        here.initialized = True;
        print(f"✓ Screening threshold: {config.SYSTEM_CONFIG['screening_threshold']}");
        print(f"✓ Protected attributes: {', '.join(config.PROTECTED_ATTRIBUTES)}");
        
        print("\n" + "="*70);
        print("System initialized successfully!");
        print("="*70 + "\n");
        
        # Report status
        report self.status;
    }
}


# ============================================================================
# MAIN EXECUTION
# ============================================================================

with entry {    
    # Create root node
    root_node = core.Root();
    
    # Initialize system
    initializer = spawn SystemInitializer();
    root_node spawn initializer;
    
    print("\n✓ System ready for bias auditing");
    print("\nNext steps:");
    print("  1. Run test: jac run test_audit.jac");
    print("  2. Check data/seed/ directory for test data");
    print("  3. Review config.jac for settings\n");
}


# """
# Run this file to initialize the system:
#     jac run main.jac

# This will:
# 1. Initialize LLM models (if API keys available)
# 2. Load seed data from data/seed/
# 3. Verify system configuration
# 4. Prepare system for auditing

# After initialization, run:
#     jac run test_audit.jac
    
# to execute a complete bias audit test.
# """