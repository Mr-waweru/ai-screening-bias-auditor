"""
test_audit.jac - Complete End-to-End Bias Audit Test
Proves the system works by testing biased and fair screeners.
"""

import json;
import config;
import core;
import llm_calls;
import metrics;
import mock_screeners;

# ============================================================================
# MAIN TEST WALKER
# ============================================================================

walker CompleteAuditTest {
    # Runs complete bias audit on both biased and fair screening systems.
    
    has test_results: any = {};
    
    can run_tests with `root entry {
        print("\n" + "="*70);
        print("AI SCREENING BIAS AUDITOR - Complete Test");
        print("="*70 + "\n");
        
        # Test 1: Biased screener (should detect bias)
        print("[TEST 1] Auditing BIASED Screening System");
        print("-"*70);
        biased_result = self.test_screening_system("biased");
        self.test_results["biased_screener"] = biased_result;
        
        # Test 2: Fair screener (should pass)
        print("\n[TEST 2] Auditing FAIR Screening System");
        print("-"*70);
        fair_result = self.test_screening_system("fair");
        self.test_results["fair_screener"] = fair_result;
        
        # Generate final report
        self.generate_validation_report();
    }
    
    def test_screening_system(system_type: str) -> dict {
        print(f"\nLoading seed data...");
        
        # 1. Load data
        seed_data = core.load_seed_data();
        if not seed_data["success"] {
            print("✗ Failed to load seed data");
            return {"error": "No seed data"};
        }
        
        base_resume = seed_data["resumes"][0];
        test_job = seed_data["jobs"][0];
        
        print(f"Base resume: {base_resume.get('name', 'Unknown')}");
        print(f"Job: {test_job.get('title', 'Unknown')}");
        
        # 2. Generate counterfactual variants
        print(f"\nGenerating counterfactual resumes...");
        variants = self.generate_test_variants(base_resume);
        print(f"Generated {len(variants)} resume variants");
        
        # 3. Screen all resumes
        print(f"\nScreening resumes with {system_type} system...");
        screening_results = [];
        screener = mock_screeners.get_screening_system(system_type);
        
        for variant in variants {
            result = screener(variant["resume_text"], test_job.get("id", "job_1"));
            screening_results.append({
                "variant_id": variant["variant_id"],
                "demographic": variant["demographic"],
                "score": result["score"],
                "decision": result["decision"]
            });
            print(f"  {variant['demographic']:30} Score = {result['score']:.2f}");
        }
        
        # 4. Analyze for bias
        print(f"\nAnalyzing bias...");
        bias_analysis = self.analyze_bias(screening_results);
        
        # 5. Validation check
        expected_bias = (system_type == "biased");
        test_passed = (bias_analysis["bias_detected"] == expected_bias);
        
        print(f"\nExpected bias: {expected_bias}");
        print(f"Detected bias: {bias_analysis['bias_detected']}");
        print(f"Test result: {'✓ PASS' if test_passed else '✗ FAIL'}");
        
        return {
            "system_type": system_type,
            "expected_bias": expected_bias,
            "detected_bias": bias_analysis["bias_detected"],
            "test_passed": test_passed,
            "screening_results": screening_results,
            "bias_analysis": bias_analysis
        };
    }
    
    def generate_test_variants(base_resume: dict) -> list {        
        variants = [];
        base_text = base_resume.get("resume_text", "");
        
        # Variant 1: Male + White (reference group)
        male_white = core.apply_perturbation(
            base_text,
            {"name": {"gender": "male", "ethnicity": "white"}}
        );
        variants.append({
            "variant_id": "male_white",
            "demographic": "Male + White (Reference)",
            "demo_group": "male",
            "resume_text": male_white["modified_resume"]
        });
        
        # Variant 2: Female + White
        female_white = core.apply_perturbation(
            base_text,
            {
                "name": {"gender": "female", "ethnicity": "white"},
                "organization": {"attribute": "gender", "value": "female"}
            }
        );
        variants.append({
            "variant_id": "female_white",
            "demographic": "Female + White",
            "demo_group": "female",
            "resume_text": female_white["modified_resume"]
        });
        
        # Variant 3: Male + Black
        male_black = core.apply_perturbation(
            base_text,
            {
                "name": {"gender": "male", "ethnicity": "black"},
                "organization": {"attribute": "race", "value": "black"}
            }
        );
        variants.append({
            "variant_id": "male_black",
            "demographic": "Male + Black",
            "demo_group": "black",
            "resume_text": male_black["modified_resume"]
        });
        
        # Variant 4: Male + Hispanic
        male_hispanic = core.apply_perturbation(
            base_text,
            {
                "name": {"gender": "male", "ethnicity": "hispanic"},
                "organization": {"attribute": "race", "value": "hispanic"}
            }
        );
        variants.append({
            "variant_id": "male_hispanic",
            "demographic": "Male + Hispanic",
            "demo_group": "hispanic",
            "resume_text": male_hispanic["modified_resume"]
        });
        
        # Variant 5: Female + Black (intersectional)
        female_black = core.apply_perturbation(
            base_text,
            {
                "name": {"gender": "female", "ethnicity": "black"},
                "organization": {"attribute": "race", "value": "black"}
            }
        );
        variants.append({
            "variant_id": "female_black",
            "demographic": "Female + Black",
            "demo_group": "female_black",
            "resume_text": female_black["modified_resume"]
        });
        
        return variants;
    }
    
    def analyze_bias(screening_results: list) -> dict {        
        # Separate by gender
        male_scores = [];
        female_scores = [];
        male_demos = [];
        female_demos = [];
        
        for result in screening_results {
            demo = result["demographic"];
            score = result["score"];
            
            if "Male" in demo {
                male_scores.append(score);
                male_demos.append("male");
            }
            if "Female" in demo {
                female_scores.append(score);
                female_demos.append("female");
            }
        }
        
        # Analyze gender bias
        all_scores = male_scores + female_scores;
        all_demos = male_demos + female_demos;
        
        gender_analysis = metrics.analyze_bias_for_attribute(
            all_scores,
            all_demos,
            "gender",
            "male"
        );
        
        # Print metrics
        metrics_dict: dict = gender_analysis.get("metrics", {});
        for (metric_name, metric_data) in metrics_dict.items() {
            if "error" not in metric_data {
                value = metric_data.get("disparate_impact") or metric_data.get("mean_diff") or 0;
                severity = metric_data.get("severity", "UNKNOWN");
                print(f"  {metric_name:30} {value:.3f} -> {severity}");
            }
        }
        
        return gender_analysis;
    }
    
    can generate_validation_report with `root exit {
        print("\n" + "="*70);
        print("VALIDATION REPORT");
        print("="*70);
        
        biased_test = self.test_results.get("biased_screener", {});
        fair_test = self.test_results.get("fair_screener", {});
        
        print("\n[BIASED SCREENER TEST]");
        if biased_test.get("test_passed") {
            print("✓ PASS - Auditor correctly detected bias");
        } else {
            print("✗ FAIL - Auditor failed to detect bias");
        }
        
        print("\n[FAIR SCREENER TEST]");
        if fair_test.get("test_passed") {
            print("✓ PASS - Auditor correctly passed fair system");
        } else {
            print("✗ FAIL - Auditor incorrectly flagged fair system");
        }
        
        overall_pass = (
            biased_test.get("test_passed", False) and 
            fair_test.get("test_passed", False)
        );
        
        print("\n" + "="*70);
        if overall_pass {
            print("✓✓✓ SYSTEM VALIDATED - Bias detection working correctly!");
        } else {
            print("✗✗✗ VALIDATION FAILED - Review implementation");
        }
        print("="*70 + "\n");
        
        # Report results
        report {
            "overall_pass": overall_pass,
            "biased_test": biased_test,
            "fair_test": fair_test
        };
    }
}


# ============================================================================
# MAIN EXECUTION
# ============================================================================

with entry {
    # Run complete end-to-end test.
    
    # Create root
    root_node = core.Root();
    
    # Run test
    tester = spawn CompleteAuditTest();
    root_node spawn tester;
}
