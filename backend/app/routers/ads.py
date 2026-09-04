from decimal import Decimal
from fastapi import APIRouter, Depends, Request, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas, security
from app.anti_fraud import AntiFraudEngine

router = APIRouter(prefix="/ads", tags=["Ads"])

@router.get("/feed")
def get_ad_feed(current_user: models.User = Depends(security.get_current_user)):
    # Simüle Edilmiş Güvenli Reklam Yayın Motoru Verileri
    return [
        {
            "ad_id": "ad_101",
            "title": "Minimalist Tasarım Rehberi",
            "advertiser": "DesignCorp",
            "media_url": "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8",
            "impression_token": "token_sec_9918231"
        },
        {
            "ad_id": "ad_102",
            "title": "Ölçeklenebilir Cloud Mimarileri",
            "advertiser": "CloudStack",
            "media_url": "https://images.unsplash.com/photo-1451187580459-43490279c0fa",
            "impression_token": "token_sec_9918232"
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
    AntiFraudEngine.validate_ad_consumption(current_user.id, event.duration_seconds, client_ip)

    # Token Çift Kullanım Engeli (Replay Attack Prevention)
    existing_token = db.query(models.AdImpression).filter(
        models.AdImpression.impression_token == event.impression_token
    ).first()
    if existing_token:
        raise HTTPException(status_code=400, detail="Bu etkinlik zaten işlendi.")

    # Reklam Geliri ve Ödül Payı Hesaplama
    settings = db.query(models.SystemSettings).first()
    points_rate = settings.points_per_usd if settings else 1000
    
    gross_rev = Decimal("0.0200") # $0.02 CPM/CPC karşılığı simüle edilen değer
    user_reward_pct = Decimal("0.60")
    
    reward_usd = gross_rev * user_reward_pct
    earned_points = reward_usd * Decimal(points_rate)
    platform_fee = gross_rev - reward_usd

    # Veritabanı Kaydı ve Cüzdan Güncellemesi (Pessimistic Lock Riskine Karşı Atomic Güncelleme)
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
    wallet.pending_points += earned_points
    wallet.total_earned_points += earned_points

    db.commit()
    return {"status": "success", "pending_points_added": earned_points}