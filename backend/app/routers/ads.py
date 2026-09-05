from decimal import Decimal
from fastapi import APIRouter, Depends, Request, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas, security
from app.anti_fraud import AntiFraudEngine

router = APIRouter(prefix="/ads", tags=["Ads"])

@router.get("/feed")
def get_ad_feed(current_user: models.User = Depends(security.get_current_user)):
    return [
        {
            "ad_id": "ad_101",
            "title": "Minimalist Tasarim Rehberi",
            "advertiser": "DesignCorp",
            "media_url": "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8",
            "impression_token": "token_sec_9918231"
        }
    ]

@router.post("/event")
def record_ad_event(
    event: schemas.AdEventCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    client_ip = request.client.host
    AntiFraudEngine.validate_ad_consumption(current_user.id, event.duration_seconds, client_ip, event.is_rewarded)

    # Token Cift Kullanim Engeli (Replay Attack Prevention)
    existing_token = db.query(models.AdImpression).filter(
        models.AdImpression.impression_token == event.impression_token
    ).first()
    if existing_token:
        raise HTTPException(status_code=400, detail="Bu etkinlik zaten islendi.")

    # Puan Hesaplama: Bonus Rewarded = 30 Puan ($0.03), Feed Dwell = 1 Puan ($0.001)
    if event.is_rewarded:
        earned_points = Decimal("30.00")
        gross_rev = Decimal("0.0500") # $0.05 simule edilen eCPM payi
    else:
        earned_points = Decimal("1.00")
        gross_rev = Decimal("0.0020")

    platform_fee = gross_rev - (earned_points * Decimal("0.001"))

    # Veritabani Kaydi ve Cuzdan Guncellemesi
    impression = models.AdImpression(
        user_id=current_user.id,
        ad_id=event.ad_id,
        impression_token=event.impression_token,
        duration_seconds=event.duration_seconds,
        gross_revenue=gross_rev,
        user_reward_points=earned_points,
        platform_fee=platform_fee,
        is_verified=True
    )
    db.add(impression)

    wallet = db.query(models.Wallet).filter(models.Wallet.user_id == current_user.id).with_for_update().first()
    if not wallet:
        wallet = models.Wallet(user_id=current_user.id)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)

    wallet.balance_points += earned_points
    wallet.total_earned_points += earned_points

    db.commit()
    db.refresh(wallet)

    return {
        "status": "success",
        "earned_points": earned_points,
        "new_balance_points": wallet.balance_points,
        "total_earned_points": wallet.total_earned_points
    }
