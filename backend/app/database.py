from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings

db_url = settings.DATABASE_URL

# Eğer PostgreSQL sürücüsü yoksa veya yerel SQLite modunda çalışılıyorsa otomatik SQLite'a geç
if not db_url or "sqlite" in db_url:
    engine = create_engine("sqlite:///./ad_rewards.db", connect_args={"check_same_thread": False})
else:
    try:
        engine = create_engine(db_url, pool_pre_ping=True)
        # Test connection
        with engine.connect() as conn:
            pass
    except Exception:
        # PostgreSQL bağlantısı başarısızsa veya sürücü yoksa SQLite'a geri dön
        engine = create_engine("sqlite:///./ad_rewards.db", connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()