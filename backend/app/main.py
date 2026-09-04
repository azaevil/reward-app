from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base, SessionLocal
from app import models
from app.routers import auth, ads, wallet, admin

# Veritabanı tablolarını otomatik oluştur
Base.metadata.create_all(bind=engine)

# Varsayılan Sistem Ayarlarını ve Admin Hesabını kontrol et ve ekle
def init_db_settings():
    db = SessionLocal()
    try:
        current_settings = db.query(models.SystemSettings).first()
        if not current_settings:
            default_settings = models.SystemSettings(
                points_per_usd=1000,
                min_withdrawal_usd=5.00,
                user_reward_percentage=60.00,
                daily_ad_limit=100
            )
            db.add(default_settings)
            db.commit()

        # Varsayılan Admin Kullanıcısı
        admin_user = db.query(models.User).filter(models.User.email == "admin@rewardapp.com").first()
        if not admin_user:
            from app.security import get_password_hash
            new_admin = models.User(
                email="admin@rewardapp.com",
                hashed_password=get_password_hash("admin123456"),
                role=models.UserRole.ADMIN
            )
            db.add(new_admin)
            db.commit()
            db.refresh(new_admin)
            db.add(models.Wallet(user_id=new_admin.id))
            db.commit()
    finally:
        db.close()

init_db_settings()

app = FastAPI(title=settings.PROJECT_NAME, version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(ads.router)
app.include_router(wallet.router)
app.include_router(admin.router)

@app.get("/health")
def health_check():
    return {"status": "healthy"}