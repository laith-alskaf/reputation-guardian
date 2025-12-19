"""
Quality Assessment Service for Review Analysis.

This service provides comprehensive quality evaluation for reviews
using weighted scoring criteria for accurate assessment.
"""
import re
import logging
from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class QualityWeights:
    """Configurable weights for quality scoring factors."""
    length: float = 0.30
    diversity: float = 0.20
    valid_chars: float = 0.25
    repetition: float = 0.15
    toxicity: float = 0.0 


@dataclass
class QualityResult:
    """Result of quality assessment."""
    quality_score: float
    scores_breakdown: Dict[str, float]
    flags: List[str]
    is_suspicious: bool
    toxicity_status: str
    
    def to_dict(self) -> dict:
        return {
            'quality_score': self.quality_score,
            'scores_breakdown': self.scores_breakdown,
            'flags': self.flags,
            'is_suspicious': self.is_suspicious,
            'toxicity_status': self.toxicity_status
        }


class QualityService:
    """
    خدمة تقييم جودة المراجعات.
    
    تستخدم نظام تقييم إيجابي بمعايير موزونة لتحديد جودة المراجعة.
    """
    
    # الطول الأمثل للنص (بالكلمات)
    OPTIMAL_MIN_WORDS = 5
    OPTIMAL_MAX_WORDS = 150
    ABSOLUTE_MAX_WORDS = 300
    
    # الحد الأدنى لنسبة الحروف الصالحة
    MIN_VALID_CHAR_RATIO = 0.3
    
    # الحد الأدنى للتنوع
    MIN_DIVERSITY_RATIO = 0.25
    
    def __init__(self, weights: QualityWeights = None):
        """
        Initialize QualityService with optional custom weights.
        
        Args:
            weights: Custom weights for scoring factors. Uses defaults if None.
        """
        self.weights = weights or QualityWeights()
    
    def assess_quality(
        self,
        enjoy_most: str,
        improve_product: str,
        additional_feedback: str,
        rating: int = 0,
        toxicity_status: str = "non-toxic"
    ) -> QualityResult:
        """
        تقييم جودة المراجعة بناءً على معايير محددة وموزونة.
        
        Args:
            enjoy_most: نص حول ما أعجب العميل
            improve_product: نص حول ما يمكن تحسينه
            additional_feedback: ملاحظات إضافية
            rating: التقييم بالنجوم (0-5)
            toxicity_status: حالة السمية المحسوبة مسبقاً
            
        Returns:
            QualityResult: نتيجة التقييم الشاملة
        """
        # 1. تجميع وتنظيف النص
        parts = [
            p.strip() for p in [enjoy_most, improve_product, additional_feedback] 
            if p and isinstance(p, str) and p.strip()
        ]
        all_text = " ".join(parts)
        
        # 2. معالجة الحالة الفارغة
        if not all_text or len(all_text) < 3:
            return self._handle_empty_review(rating, toxicity_status)
        
        # 3. تقييم كل معيار
        scores = {}
        flags = []
        words = all_text.split()
        
        # أ) طول النص
        scores['length'], length_flags = self._evaluate_length(len(words))
        flags.extend(length_flags)
        
        # ب) تنوع المفردات
        scores['diversity'], diversity_flags = self._evaluate_diversity(words)
        flags.extend(diversity_flags)
        
        # ج) نسبة الأحرف الصالحة
        scores['valid_chars'], char_flags = self._evaluate_valid_chars(all_text)
        flags.extend(char_flags)
        
        # د) التكرار الزائد
        scores['repetition'], rep_flags = self._evaluate_repetition(all_text)
        flags.extend(rep_flags)
        
        # هـ) السمية
        scores['toxicity'], tox_flags = self._evaluate_toxicity(toxicity_status)
        flags.extend(tox_flags)
        
        # 4. حساب الدرجة النهائية (متوسط موزون)
        quality_score = (
            self.weights.length * scores['length'] +
            self.weights.diversity * scores['diversity'] +
            self.weights.valid_chars * scores['valid_chars'] +
            self.weights.repetition * scores['repetition'] +
            self.weights.toxicity * scores['toxicity']
        )
        
        # 5. تحديد المراجعات المشبوهة
        is_suspicious = (
            quality_score < 0.4 or 
            toxicity_status == "toxic" or 
            len(flags) >= 3
        )
        
        return QualityResult(
            quality_score=round(quality_score, 2),
            scores_breakdown={k: round(v, 2) for k, v in scores.items()},
            flags=flags,
            is_suspicious=is_suspicious,
            toxicity_status=toxicity_status
        )
    
    def _handle_empty_review(self, rating: int, toxicity_status: str) -> QualityResult:
        """
        معالجة المراجعات الفارغة.
        
        إذا كان هناك تقييم بالنجوم، نعتبرها مقبولة.
        وإلا نعتبرها مشبوهة.
        """
        if rating > 0:
            return QualityResult(
                quality_score=0.6,  # درجة متوسطة للتقييم بالنجوم فقط
                scores_breakdown={
                    'length': 0.3,
                    'diversity': 0.5,
                    'valid_chars': 1.0,
                    'repetition': 1.0,
                    'toxicity': 1.0
                },
                flags=['rating_only'],
                is_suspicious=False,
                toxicity_status=toxicity_status
            )
        else:
            return QualityResult(
                quality_score=0.0,
                scores_breakdown={
                    'length': 0.0,
                    'diversity': 0.0,
                    'valid_chars': 0.0,
                    'repetition': 0.0,
                    'toxicity': 1.0
                },
                flags=['empty_content'],
                is_suspicious=True,
                toxicity_status=toxicity_status
            )
    
    def _evaluate_length(self, word_count: int) -> tuple[float, List[str]]:
        """
        تقييم طول النص.
        
        النطاق الأمثل: 5-150 كلمة
        Returns: (score 0.0-1.0, list of flags)
        """
        flags = []
        
        if word_count < 2:
            flags.append('too_short')
            return 0.1, flags
        elif word_count < self.OPTIMAL_MIN_WORDS:
            flags.append('short_text')
            return 0.4, flags
        elif word_count <= self.OPTIMAL_MAX_WORDS:
            # النطاق الأمثل
            return 1.0, flags
        elif word_count <= self.ABSOLUTE_MAX_WORDS:
            # طويل قليلاً
            flags.append('long_text')
            return 0.7, flags
        else:
            # طويل جداً
            flags.append('too_long')
            return 0.3, flags
    
    def _evaluate_diversity(self, words: List[str]) -> tuple[float, List[str]]:
        """
        تقييم تنوع المفردات.
        
        نسبة الكلمات الفريدة إلى إجمالي الكلمات.
        """
        flags = []
        
        if len(words) < 5:
            return 0.3, flags
        
        unique_words = set(word.lower() for word in words)
        diversity_ratio = len(unique_words) / len(words)
        
        if diversity_ratio < self.MIN_DIVERSITY_RATIO:
            flags.append('low_diversity')
            return 0.2, flags
        elif diversity_ratio < 0.4:
            flags.append('repetitive_text')
            return 0.5, flags
        elif diversity_ratio < 0.6:
            return 0.75, flags
        else:
            return 1.0, flags
    
    def _evaluate_valid_chars(self, text: str) -> tuple[float, List[str]]:
        """
        تقييم نسبة الأحرف الصالحة (عربية/إنجليزية/أرقام).
        """
        flags = []
        
        if not text:
            return 0.0, ['empty_text']
        
        # حساب الأحرف العربية
        arabic_chars = sum(1 for c in text if '\u0600' <= c <= '\u06FF')
        # حساب الأحرف الإنجليزية
        english_chars = sum(1 for c in text if c.isascii() and c.isalpha())
        # حساب الأرقام
        digit_chars = sum(1 for c in text if c.isdigit())
        # حساب المسافات
        space_chars = sum(1 for c in text if c.isspace())
        
        # الأحرف الصالحة = عربي + إنجليزي + أرقام + مسافات
        valid_chars = arabic_chars + english_chars + digit_chars + space_chars
        total_chars = len(text)
        
        if total_chars == 0:
            return 0.0, ['empty_text']
        
        valid_ratio = valid_chars / total_chars
        
        if valid_ratio < self.MIN_VALID_CHAR_RATIO:
            flags.append('suspicious_chars')
            return 0.2, flags
        elif valid_ratio < 0.6:
            flags.append('mixed_chars')
            return 0.5, flags
        elif valid_ratio < 0.8:
            return 0.75, flags
        else:
            return 1.0, flags
    
    def _evaluate_repetition(self, text: str) -> tuple[float, List[str]]:
        """
        تقييم التكرار الزائد للحروف.
        
        مثال: "جميييييل" أو "noooooo"
        """
        flags = []
        
        # البحث عن تكرار 4+ مرات
        if re.search(r'(.)\1{4,}', text):
            flags.append('excessive_char_repetition')
            return 0.3, flags
        # البحث عن تكرار 3 مرات
        elif re.search(r'(.)\1{3}', text):
            flags.append('char_repetition')
            return 0.7, flags
        else:
            return 1.0, flags
    
    def _evaluate_toxicity(self, toxicity_status: str) -> tuple[float, List[str]]:
        """
        تقييم السمية.
        """ 
        flags = []
        
        if toxicity_status == "toxic":
            flags.append('high_toxicity')
            return 0.0, flags
        elif toxicity_status == "uncertain":
            flags.append('uncertain_toxicity')
            return 0.5, flags
        else:
            return 1.0, flags
    
    @staticmethod
    def is_high_quality(result: QualityResult, threshold: float = 0.5) -> bool:
        """
        تحديد ما إذا كانت المراجعة ذات جودة عالية.
        
        Args:
            result: نتيجة تقييم الجودة
            threshold: الحد الأدنى للجودة
            
        Returns:
            bool: True إذا كانت المراجعة ذات جودة كافية
        """
        return result.quality_score >= threshold and not result.is_suspicious
