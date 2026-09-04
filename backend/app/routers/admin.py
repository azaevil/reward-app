from decimal import Decimal
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app import models, schemas, security

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/analytics/revenue", response_model=schemas.AdminRevenueStats)
def get_revenue_stats(
    db: Session = Depends(get_db),
    admin: models.User = Depends(security.get_current_admin)
):
    result = db.query(
        func.coalesce(func.sum(models.AdImpression.gross_revenue), 0).label("gross"),
        func.coalesce(func.sum(models.AdImpression.platform_fee), 0).label("fee"),
        func.coalesce(func.sum(models.AdImpression.user_reward_points), 0).label("rewards_pts")
    ).first()

    settings = db.query(models.SystemSettings).first()
    points_rate = Decimal(settings.points_per_usd if settings else 1000)

    gross_usd = Decimal(result.gross)
    platform_fee_usd = Decimal(result.fee)
    user_rewards_usd = Decimal(result.rewards_pts) / points_rate
    net_revenue = gross_usd - user_rewards_usd

    return {
        "gross_ad_revenue": gross_usd,
        "platform_fees": platform_fee_usd,
        "user_rewards": user_rewards_usd,
        "net_revenue": net_revenue
    }

@router.get("/withdrawals", response_model=List[schemas.WithdrawalAdminOut])
def get_withdrawals(
    db: Session = Depends(get_db),
    admin: models.User = Depends(security.get_current_admin)
):
    return db.query(models.Withdrawal).order_by(models.Withdrawal.created_at.desc()).all()

@router.post("/withdrawals/approve-all")
def approve_all_withdrawals(
    db: Session = Depends(get_db),
    admin: models.User = Depends(security.get_current_admin)
):
    pending_withdrawals = db.query(models.Withdrawal).filter(models.Withdrawal.status == models.WithdrawalStatus.PENDING).all()
    count = 0
    for w in pending_withdrawals:
        w.status = models.WithdrawalStatus.APPROVED
        wallet = db.query(models.Wallet).filter(models.Wallet.user_id == w.user_id).first()
        if wallet:
            wallet.total_withdrawn_usd += w.amount_usd
        count += 1
    
    db.commit()
    return {"status": "all_approved", "approved_count": count}

@router.post("/withdrawals/{withdrawal_id}/approve")
def approve_withdrawal(
    withdrawal_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(security.get_current_admin)
):
    withdrawal = db.query(models.Withdrawal).filter(models.Withdrawal.id == withdrawal_id).first()
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Talep bulunamadı.")
    
    withdrawal.status = models.WithdrawalStatus.APPROVED
    wallet = db.query(models.Wallet).filter(models.Wallet.user_id == withdrawal.user_id).first()
    if wallet:
        wallet.total_withdrawn_usd += withdrawal.amount_usd
    
    db.commit()
    return {"status": "approved"}