import enum
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, Numeric, DateTime, ForeignKey, Enum, Text, Index
from sqlalchemy.orm import relationship
from app.database import Base

class UserRole(str, enum.Enum):
    USER = "user"
    ADMIN = "admin"

class WithdrawalStatus(str, enum.Enum):
    PENDING = "PENDING"
    REVIEWING = "REVIEWING"
    APPROVED = "APPROVED"
    PAID = "PAID"
    REJECTED = "REJECTED"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.USER, nullable=False)
    is_active = Column(Boolean, default=True)
    is_flagged = Column(Boolean, default=False)
    flag_reason = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    wallet = relationship("Wallet", back_populates="user", uselist=False)
    impressions = relationship("AdImpression", back_populates="user")
    withdrawals = relationship("Withdrawal", back_populates="user")

class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    balance_points = Column(Numeric(12, 2), default=0.00, nullable=False)
    pending_points = Column(Numeric(12, 2), default=0.00, nullable=False)
    total_earned_points = Column(Numeric(12, 2), default=0.00, nullable=False)
    total_withdrawn_usd = Column(Numeric(12, 2), default=0.00, nullable=False)

    user = relationship("User", back_populates="wallet")

class AdImpression(Base):
    __tablename__ = "ad_impressions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    ad_id = Column(String, nullable=False)
    impression_token = Column(String, unique=True, nullable=False, index=True)
    duration_seconds = Column(Integer, nullable=False)
    gross_revenue = Column(Numeric(10, 4), nullable=False)
    user_reward_points = Column(Numeric(10, 2), nullable=False)
    platform_fee = Column(Numeric(10, 4), nullable=False)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="impressions")

class Withdrawal(Base):
    __tablename__ = "withdrawals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount_usd = Column(Numeric(10, 2), nullable=False)
    points_deducted = Column(Numeric(12, 2), nullable=False)
    payment_method = Column(String, nullable=False)
    payout_details = Column(Text, nullable=False)
    status = Column(Enum(WithdrawalStatus), default=WithdrawalStatus.PENDING, nullable=False)
    admin_note = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="withdrawals")

class SystemSettings(Base):
    __tablename__ = "system_settings"

    id = Column(Integer, primary_key=True)
    points_per_usd = Column(Integer, default=1000, nullable=False)
    min_withdrawal_usd = Column(Numeric(10, 2), default=5.00, nullable=False)
    user_reward_percentage = Column(Numeric(5, 2), default=60.00, nullable=False)
    daily_ad_limit = Column(Integer, default=100, nullable=False)