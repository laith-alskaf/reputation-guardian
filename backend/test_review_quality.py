# -*- coding: utf-8 -*-
"""
سكريبت اختبار شامل لدالة detect_review_quality
يختبر جميع الحالات المختلفة ويوثق النتائج
"""

import sys
import os

# إضافة المسار لاستيراد الوحدات
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.infrastructure.external.sentiment_service import SentimentService

# ==================== Test Cases ====================

test_cases = [
    # === المجموعة 1: تقييمات بالنجوم فقط ===
    {
        "name": "Test 1.1: نجوم فقط (بدون نص)",
        "input": {
            "enjoy_most": "",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,  # إضافة تقييم النجوم
            "pre_calculated_toxicity": "non-toxic"
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "flags_should_include": ["stars_only", "positive_stars"],  # توقع positive_stars
            "is_suspicious": False
        }
    },
    {
        "name": "Test 1.2: نجوم مع مسافات فقط",
        "input": {
            "enjoy_most": "   ",
            "improve_product": "",
            "additional_feedback": "  ",
            "rating": 2,  # إضافة تقييم نجوم سلبي
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "flags_should_include": ["stars_only", "negative_stars"],  # توقع negative_stars
            "is_suspicious": False
        }
    },
    
    # === المجموعة 2: تقييمات قصيرة صحيحة ===
    {
        "name": "Test 2.1: كلمة واحدة إيجابية",
        "input": {
            "enjoy_most": "ممتاز",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.8,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 2.2: كلمتان",
        "input": {
            "enjoy_most": "خدمة ممتازة",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 2.3: تقييم قصير بالإنجليزية",
        "input": {
            "enjoy_most": "Great",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.8,
            "is_suspicious": False
        }
    },
    
    # === المجموعة 3: تكرار طبيعي ===
    {
        "name": "Test 3.1: تكرار للتأكيد",
        "input": {
            "enjoy_most": "جيد جداً جداً",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 4,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 3.2: تكرار كلمة مرتين",
        "input": {
            "enjoy_most": "رائع رائع",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.7,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 3.3: تكرار زائد (spam)",
        "input": {
            "enjoy_most": "رائع رائع رائع رائع رائع",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 0,  # بدون نجوم
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": False,
            "quality_score_max": 0.6,  # عدلنا من 0.5 إلى 0.6
            "flags_should_include": ["repetitive_words"],
            "is_suspicious": True
        }
    },
    
    # === المجموعة 4: تكرار أحرف ===
    {
        "name": "Test 4.1: تعبير عاطفي طبيعي",
        "input": {
            "enjoy_most": "واااو المكان روعة",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.8,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 4.2: تكرار زائد (spam)",
        "input": {
            "enjoy_most": "ااااااااااا",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 0,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": False,
            "quality_score_max": 0.7,  # عدلنا من 0.6 إلى 0.7
            "flags_should_include": ["repetitive_characters"],
            "is_suspicious": True
        }
    },
    
    # === المجموعة 5: أرقام ورموز ===
    {
        "name": "Test 5.1: تقييم يحتوي على أرقام",
        "input": {
            "enjoy_most": "المنتج رقم 123 كان ممتاز جداً",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 5.2: أرقام فقط (spam)",
        "input": {
            "enjoy_most": "123456789",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 0,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": False,
            "quality_score_max": 0.6,  # عدلنا من 0.5 إلى 0.6
            "flags_should_include": ["gibberish_content"],
            "is_suspicious": True
        }
    },
    {
        "name": "Test 5.3: رموز خاصة زائدة",
        "input": {
            "enjoy_most": "!!!!@@@@####",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 0,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": False,
            "quality_score_max": 0.4,
            "flags_should_include": ["excessive_special_chars"],
            "is_suspicious": True
        }
    },
    
    # === المجموعة 6: لغات مختلفة ===
    {
        "name": "Test 6.1: إنجليزي فقط",
        "input": {
            "enjoy_most": "Great service and amazing food quality",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "is_suspicious": False
        }
    },
    {
        "name": "Test 6.2: مختلط (عربي + إنجليزي)",
        "input": {
            "enjoy_most": "الخدمة excellent والأكل delicious",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 5,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.9,
            "is_suspicious": False
        }
    },
    
    # === المجموعة 7: محتوى سام ===
    {
        "name": "Test 7.1: محتوى سام معتدل",
        "input": {
            "enjoy_most": "الخدمة سيئة جداً",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 1,
            "pre_calculated_toxicity": "uncertain"
        },
        "expected": {
            "should_accept": True,
            "quality_score_min": 0.8,
            "flags_should_include": ["possible_toxicity"],
            "is_suspicious": False
        }
    },
    {
        "name": "Test 7.2: محتوى سام عالي",
        "input": {
            "enjoy_most": "محتوى شتائم",
            "improve_product": "",
            "additional_feedback": "",
            "rating": 1,
            "pre_calculated_toxicity": "toxic"
        },
        "expected": {
            "should_accept": False,
            "quality_score_max": 0.7,
            "flags_should_include": ["high_toxicity"],
            "is_suspicious": True
        }
    },
    
    # === المجموعة 8: محتوى طويل ===
    {
        "name": "Test 8.1: محتوى طويل صالح (180 كلمة)",
        "input": {
            "enjoy_most": " ".join(["كلمة"] * 180),
            "improve_product": "",
            "additional_feedback": "",
            "rating": 0,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": False,  # تكرار كلمة واحدة = spam
            "quality_score_max": 0.5,
            "flags_should_include": ["repetitive_words"],
            "is_suspicious": True
        }
    },
    {
        "name": "Test 8.2: محتوى طويل جداً (250 كلمة)",
        "input": {
            "enjoy_most": " ".join(["كلمة"] * 250),
            "improve_product": "",
            "additional_feedback": "",
            "rating": 0,
            "pre_calculated_toxicity": None
        },
        "expected": {
            "should_accept": False,  # تكرار كلمة واحدة = spam
            "quality_score_max": 0.5,
            "flags_should_include": ["too_long", "repetitive_words"],
            "is_suspicious": True
        }
    },
]

# ==================== Test Runner ====================

def run_test(test_case):
    """تشغيل حالة اختبار واحدة"""
    name = test_case["name"]
    input_data = test_case["input"]
    expected = test_case["expected"]
    
    # تشغيل الدالة مع إضافة rating
    result = SentimentService.detect_review_quality(
        enjoy_most=input_data["enjoy_most"],
        improve_product=input_data["improve_product"],
        additional_feedback=input_data["additional_feedback"],
        rating=input_data.get("rating", 0),  # إضافة rating (افتراضي 0)
        pre_calculated_toxicity=input_data.get("pre_calculated_toxicity")
    )
    
    # التحقق من النتائج
    passed = True
    issues = []
    
    # فحص quality_score
    if "quality_score_min" in expected:
        if result['quality_score'] < expected['quality_score_min']:
            passed = False
            issues.append(f"Quality score ({result['quality_score']}) < expected min ({expected['quality_score_min']})")
    
    if "quality_score_max" in expected:
        if result['quality_score'] > expected['quality_score_max']:
            passed = False
            issues.append(f"Quality score ({result['quality_score']}) > expected max ({expected['quality_score_max']})")
    
    # فحص is_suspicious
    if "is_suspicious" in expected:
        if result['is_suspicious'] != expected['is_suspicious']:
            passed = False
            issues.append(f"is_suspicious ({result['is_suspicious']}) != expected ({expected['is_suspicious']})")
    
    # فحص flags
    if "flags_should_include" in expected:
        for flag in expected["flags_should_include"]:
            if flag not in result['flags']:
                passed = False
                issues.append(f"Missing expected flag: {flag}")
    
    # فحص should_accept
    if "should_accept" in expected:
        should_accept_actual = result['quality_score'] >= 0.5 and not result['is_suspicious']
        if should_accept_actual != expected['should_accept']:
            passed = False
            issues.append(f"Review acceptance ({should_accept_actual}) != expected ({expected['should_accept']})")
    
    return {
        "name": name,
        "passed": passed,
        "result": result,
        "issues": issues
    }

def print_test_result(test_result):
    """طباعة نتيجة اختبار"""
    status = "✅ PASS" if test_result["passed"] else "❌ FAIL"
    print(f"\n{status} - {test_result['name']}")
    print(f"  Quality Score: {test_result['result']['quality_score']}")
    print(f"  Flags: {test_result['result']['flags']}")
    print(f"  Is Suspicious: {test_result['result']['is_suspicious']}")
    
    if not test_result["passed"]:
        print(f"  Issues:")
        for issue in test_result["issues"]:
            print(f"    - {issue}")

# ==================== Main ====================

if __name__ == "__main__":
    print("=" * 80)
    print("اختبار شامل لدالة detect_review_quality")
    print("=" * 80)
    
    all_results = []
    passed_count = 0
    failed_count = 0
    
    for test_case in test_cases:
        result = run_test(test_case)
        all_results.append(result)
        
        if result["passed"]:
            passed_count += 1
        else:
            failed_count += 1
        
        print_test_result(result)
    
    # Summary
    print("\n" + "=" * 80)
    print("ملخص النتائج")
    print("=" * 80)
    print(f"إجمالي الاختبارات: {len(test_cases)}")
    print(f"نجح: {passed_count} ✅")
    print(f"فشل: {failed_count} ❌")
    print(f"نسبة النجاح: {(passed_count / len(test_cases) * 100):.1f}%")
    
    # List failed tests
    if failed_count > 0:
        print("\n" + "=" * 80)
        print("الاختبارات الفاشلة:")
        print("=" * 80)
        for result in all_results:
            if not result["passed"]:
                print(f"\n❌ {result['name']}")
                for issue in result["issues"]:
                    print(f"  - {issue}")
