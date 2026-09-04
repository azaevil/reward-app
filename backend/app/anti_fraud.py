import time
import logging
from collections import defaultdict
from fastapi import HTTPException, status
from app.config import settings

logger = logging.getLogger(__name__)

# Redis bağlantısı dene, yoksa bellek içi (in-memory) rate limiter kullan
redis_client = None
try:
    import redis
    redis_client = redis.Redis.from_url(settings.REDIS_URL, decode_responses=True)
    redis_client.ping()
except Exception:
    redis_client = None
    logger.info("Redis sunucusu bulunamadı, yerel bellek (in-memory) hız sınırlayıcı devrede.")

# In-memory rate limiting veri yapıları
_memory_store = defaultdict(lambda: {"count": 0, "expires_at": 0})

def _memory_incr(key: str, ttl_seconds: int) -> int:
    now = time.time()
    data = _memory_store[key]
    if now > data["expires_at"]:
        data["count"] = 1
        data["expires_at"] = now + ttl_seconds
    else:
        data["count"] += 1
    return data["count"]

class AntiFraudEngine:
    @staticmethod
    def validate_ad_consumption(user_id: int, duration_seconds: int, client_ip: str):
        # 1. Minimum İzlenme Süresi Kontrolü
        if duration_seconds < 5:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail="Şüpheli etkinlik: Geçersiz reklam izleme süresi."
            )

        # 2. Hız Sınırlaması (Rate Limiting) - Son 1 dakikada maksimum 4 reklam
        rate_key = f"rate:ad:{user_id}"
        if redis_client:
            try:
                current_count = redis_client.incr(rate_key)
                if current_count == 1:
                    redis_client.expire(rate_key, 60)
            except Exception:
                current_count = _memory_incr(rate_key, 60)
        else:
            current_count = _memory_incr(rate_key, 60)
        
        if current_count > 4:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Anormal işlem hızı tespit edildi. Lütfen bekleyin."
            )

        # 3. IP Bazlı Günlük Limit Kontrolü (Sybil / Multi-account Saldırı Engeli)
        ip_key = f"ip:limit:{client_ip}"
        if redis_client:
            try:
                ip_count = redis_client.incr(ip_key)
                if ip_count == 1:
                    redis_client.expire(ip_key, 86400)
            except Exception:
                ip_count = _memory_incr(ip_key, 86400)
        else:
            ip_count = _memory_incr(ip_key, 86400)
        
        if ip_count > 500:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bu IP adresinden çok fazla etkinlik tespit edildi."
            )

    @staticmethod
    def flag_suspicious_user(db_session, user_id: int, reason: str):
        from app.models import User
        user = db_session.query(User).filter(User.id == user_id).first()
        if user:
            user.is_flagged = True
            user.flag_reason = reason
            db_session.commit()