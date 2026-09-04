from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from decimal import Decimal
from datetime import datetime
from app.models import WithdrawalStatus, UserRole

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)

class UserOut(BaseModel):
    id: int
    email: EmailStr
    role: UserRole
    is_active: bool
    is_flagged: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class AdEventCreate(BaseModel):
    ad_id: str
    impression_token: str
    duration_seconds: int
    is_rewarded: bool = True

class WalletOut(BaseModel):
    balance_points: Decimal
    pending_points: Decimal
    total_earned_points: Decimal
    total_withdrawn_usd: Decimal

    class Config:
        from_attributes = True

class WithdrawalCreate(BaseModel):
    amount_usd: Decimal = Field(gt=0)
    payment_method: str
    payout_details: str

class WithdrawalOut(BaseModel):
    id: int
    amount_usd: Decimal
    points_deducted: Decimal
    payment_method: str
    status: WithdrawalStatus
    created_at: datetime

    class Config:
        from_attributes = True

class WithdrawalAdminOut(BaseModel):
    id: int
    user_id: int
    amount_usd: Decimal
    points_deducted: Decimal
    payment_method: str
    payout_details: str
    status: WithdrawalStatus
    created_at: datetime

    class Config:
        from_attributes = True

class AdminRevenueStats(BaseModel):
    gross_ad_revenue: Decimal
    platform_fees: Decimal
    user_rewards: Decimal
    net_revenue: Decimal