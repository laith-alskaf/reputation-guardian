"""
Quality Gate Processor
Assesses review quality and determines if it passes the quality threshold.
"""
import logging
from typing import Tuple, Dict, Any
from bson import ObjectId

from app.presentation.config import QUALITY_GATE_THRESHOLD
from app.infrastructure.external import QualityService
from app.application.dto.review_processing_dto import ReviewDocument, Source, Processing


class QualityGateProcessor:
    """
    Processes review quality assessment.
    
    Responsibility: Determine if review meets quality standards.
    Follows SRP - only handles quality gate logic.
    """
    
    def __init__(self, quality_service: QualityService):
        """
        Initialize QualityGateProcessor with required dependencies.
        
        Args:
            quality_service: Service for quality assessment
        """
        self.quality_service = quality_service
    
    def assess_quality(
        self,
        review_data: Dict[str, Any],
        toxicity_status: str
    ) -> Tuple[bool, dict]:
        """
        Assess review quality and determine if it passes the gate.
        
        Args:
            review_data: Dictionary containing review fields and rating
            toxicity_status: Pre-calculated toxicity status
            
        Returns:
            Tuple of (passes_gate, quality_result_dict)
            - passes_gate: Boolean indicating if review passed quality gate
            - quality_result_dict: Full quality assessment results
        """
        source_fields = review_data.get('source_fields', {})
        
        # Extract the three text fields
        enjoy_most = source_fields.get('enjoy_most', '')
        improve_product = source_fields.get('improve_product', '')
        additional_feedback = source_fields.get('additional_feedback', '')
        rating = review_data.get('rating', 0)
        
        # Perform quality assessment
        quality_result = self.quality_service.assess_quality(
            enjoy_most=enjoy_most,
            improve_product=improve_product,
            additional_feedback=additional_feedback,
            rating=rating,
            toxicity_status=toxicity_status
        )
        
        quality_check_result = quality_result.to_dict()
        
        # Determine if quality threshold is met
        passes_gate = self._is_high_quality(quality_check_result)
        
        return passes_gate, quality_check_result
    
    def _is_high_quality(self, quality_result: dict) -> bool:
        """
        Final quality gate decision logic.
        Balances human reviews vs spam/toxic content.
        """

        toxicity_status = quality_result.get('toxicity_status', 'non-toxic')
        score = quality_result.get('quality_score', 0.0)
        is_suspicious = quality_result.get('is_suspicious', False)
        flags = quality_result.get('flags', [])

        BASE_THRESHOLD = 0.55
        HARD_REJECT_THRESHOLD = 0.45
        UNCERTAIN_TOXICITY_THRESHOLD = 0.65

        # 🔴 1. Hard reject: toxic content
        if toxicity_status == "toxic":
            logging.warning("❌ Rejected: toxic content detected")
            return False

        # 🔴 2. Hard reject: extremely low quality
        if score < HARD_REJECT_THRESHOLD:
            logging.warning(
                f"❌ Rejected: very low quality score ({score})"
            )
            return False

        # ⚠️ 3. Uncertain toxicity → stricter quality requirement
        if toxicity_status == "uncertain":
            if score < UNCERTAIN_TOXICITY_THRESHOLD:
                logging.warning(
                    f"❌ Rejected: uncertain toxicity with insufficient quality "
                    f"(score={score}, required={UNCERTAIN_TOXICITY_THRESHOLD})"
                )
                return False

        # ⚠️ 4. Suspicious signals → require minimum acceptable score
        if is_suspicious:
            if score < BASE_THRESHOLD:
                logging.warning(
                    f"❌ Rejected: suspicious review with low score "
                    f"(score={score}, flags={flags})"
                )
                return False

        # ✅ 5. Passed all gates
        logging.info(
            f"✅ Review accepted (score={score}, toxicity={toxicity_status}, flags={flags})"
        )
        return True

    def create_rejected_quality_document(
        self,
        shop_id: str,
        email: str,
        rating: int,
        source: Source,
        processing: Processing,
        quality_result: dict
    ) -> ReviewDocument:
        """
        Create a ReviewDocument for a review rejected due to low quality.
        
        Args:
            shop_id: Shop identifier
            email: Respondent email
            rating: Star rating
            source: Source data object
            processing: Processing data object
            quality_result: Quality assessment results
            
        Returns:
            ReviewDocument with status 'rejected_low_quality'
        """
        return ReviewDocument(
            id=str(ObjectId()),
            shop_id=shop_id,
            email=email,
            stars=rating,
            status="rejected_low_quality",
            overall_sentiment="محايد",
            source=source,
            processing=processing,
            analysis={'quality': quality_result}
        )
