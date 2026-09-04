from decimal import Decimal
from sqlalchemy.orm import Session
from app import models, schemas
from fastapi import HTTPException

class WalletService:
    @staticmethod
    def create_withdrawal(db: Session, user_id: int, payload: schemas.WithdrawalCreate):
        settings = db.query(models.SystemSettings).first()
        min_usd = settings.min_withdrawal_usd if settings else Decimal("5.00")
        points_rate = Decimal(settings.points_per_usd if settings else 1000)

        if payload.amount_usd < min_usd:
            raise HTTPException(status_code=400, detail=f"Minimum çekim miktarı ${min_usd}'dır.")

        required_points = payload.amount_usd * points_rate
        wallet = db.query(models.Wallet).filter(models.Wallet.user_id == user_id).with_for_update().first()

        if wallet.balance_points < required_points:
            raise HTTPException(status_code=400, detail="Yetersiz kullanılabilir bakiye.")

        wallet.balance_points -= required_points

        withdrawal = models.Withdrawal(
            user_id=user_id,
            amount_usd=payload.amount_usd,
            points_deducted=required_points,
            payment_method=payload.payment_method,
            payout_details=payload.payout_details,
            status=models.WithdrawalStatus.PENDING
        )
        db.add(withdrawal)
        db.commit()
        db.refresh(withdrawal)

        return withdrawal