from decimal import Decimal
from sqlalchemy.orm import Session
from app import models

class AdService:
    @staticmethod
    def process_impression(db: Session, user_id: int, ad_id: str, impression_token: str, duration: int):
        settings = db.query(models.SystemSettings).first()
        points_rate = Decimal(settings.points_per_usd if settings else 1000)
        
        gross_rev = Decimal("0.0200")  # CPM/CPC simüle değer
        user_reward_pct = Decimal("0.60")
        
        reward_usd = gross_rev * user_reward_pct
        earned_points = reward_usd * points_rate
        platform_fee = gross_rev - reward_usd

        impression = models.AdImpression(
            user_id=user_id,
            ad_id=ad_id,
            impression_token=impression_token,
            duration_seconds=duration,
            gross_revenue=gross_rev,
            user_reward_points=earned_points,
            platform_fee=platform_fee,
            is_verified=True
        )
        db.add(impression)

        wallet = db.query(models.Wallet).filter(models.Wallet.user_id == user_id).with_for_update().first()
        wallet.pending_points += earned_points
        wallet.total_earned_points += earned_points

        db.commit()
        return earned_points