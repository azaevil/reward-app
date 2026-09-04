from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas, security

router = APIRouter(prefix="/wallet", tags=["Wallet"])

@router.get("", response_model=schemas.WalletOut)
def get_wallet(db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    return current_user.wallet

@router.post("/withdraw", response_model=schemas.WithdrawalOut)
def request_withdrawal(
    payload: schemas.WithdrawalCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    if current_user.is_flagged:
        raise HTTPException(status_code=403, detail="Hesabınız inceleme altındadır. Para çekme işlemi gerçekleştirilemez.")

    settings = db.query(models.SystemSettings).first()
    min_usd = settings.min_withdrawal_usd if settings else Decimal("5.00")
    points_rate = settings.points_per_usd if settings else 1000

    if payload.amount_usd < min_usd:
        raise HTTPException(status_code=400, detail=f"Minimum çekim miktarı ${min_usd}'dır.")

    required_points = payload.amount_usd * Decimal(points_rate)
    wallet = db.query(models.Wallet).filter(models.Wallet.user_id == current_user.id).with_for_update().first()

    if wallet.balance_points < required_points:
        raise HTTPException(status_code=400, detail="Yetersiz kullanılabilir bakiye.")

    wallet.balance_points -= required_points

    withdrawal = models.Withdrawal(
        user_id=current_user.id,
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