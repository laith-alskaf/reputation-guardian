
import sys
import os
import logging

# إضافة المسار لاستيراد الوحدات
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), 'backend')))

from app.infrastructure.external.sentiment_service import SentimentService

# إعداد الـ logging لرؤية التفاصيل
logging.basicConfig(level=logging.INFO)

test_cases = [
    {
        "text": "الأكل مقرف والطباخ بلا ذوق وما بيفهم شي، الله لا يوفقكن",
        "expected": "toxic",
        "desc": "Toxic (Syrian - Insulting)"
    },
    {
        "text": "خدمة زبالة وموظفين وقحين، نصيحة لا حدا يقرب لعندهن",
        "expected": "toxic",
        "desc": "Toxic (Syrian - Harsh criticism)"
    },
    {
        "text": "المكان رايق كتير والخدمة كويسة، بنصح فيه",
        "expected": "non-toxic",
        "desc": "Non-Toxic (Syrian - Positive)"
    },
    {
        "text": "بصراحة الأكل مو كتير طييب بس المعاملة كانت حلوة",
        "expected": "non-toxic",
        "desc": "Non-Toxic (Syrian - Mixed/Polite)"
    },
    {
        "text": "جربت المنسف اليوم، كان عادي بس السعر غالي شوي",
        "expected": "non-toxic",
        "desc": "Non-Toxic (Syrian - Neutral/Objective)"
    }
]

def run_tests():
    print("=" * 60)
    print("🚀 Testing Arabic Toxicity Model (Syrian Dialect)")
    print("=" * 60)
    
    passed = 0
    total = len(test_cases)
    
    for case in test_cases:
        print(f"\n📝 Test: {case['desc']}")
        print(f"👉 Input: \"{case['text']}\"")
        
        result = SentimentService.analyze_toxicity(case['text'])
        
        status = "✅ PASS" if result == case['expected'] else "❌ FAIL"
        if result == case['expected']:
            passed += 1
            
        print(f"🎯 Result: {result} (Expected: {case['expected']}) -> {status}")
        
    print("\n" + "=" * 60)
    print(f"📊 Summary: {passed}/{total} tests passed")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
