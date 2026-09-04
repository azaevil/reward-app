import React, { useEffect, useState } from 'react';
import { DollarSign, Activity } from 'lucide-react';
import { adminApi } from '../api';

export default function Dashboard() {
  const [stats, setStats] = useState({
    gross_ad_revenue: "0.00",
    platform_fees: "0.00",
    user_rewards: "0.00",
    net_revenue: "0.00"
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    
    // Token yoksa API çağrısı yapmayı engeller
    if (!token) {
      setLoading(false);
      return;
    }

    adminApi.getRevenueStats()
      .then(data => {
        if (data) {
          setStats({
            gross_ad_revenue: data.gross_ad_revenue || "0.00",
            platform_fees: data.platform_fees || "0.00",
            user_rewards: data.user_rewards || "0.00",
            net_revenue: data.net_revenue || "0.00"
          });
        }
      })
      .catch(err => {
        console.error("İstatistik yükleme hatası:", err);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-lg font-bold text-white uppercase tracking-wider">Genel Bakış</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="p-4 bg-[#171717] border border-[#262626]">
          <div className="text-xs text-[#a3a3a3]">Brüt Gelir</div>
          <div className="text-xl font-bold text-white mt-1">
            ${loading ? "..." : stats.gross_ad_revenue}
          </div>
        </div>

        <div className="p-4 bg-[#171717] border border-[#262626]">
          <div className="text-xs text-[#a3a3a3]">Dağıtılan Ödül</div>
          <div className="text-xl font-bold text-white mt-1">
            ${loading ? "..." : stats.user_rewards}
          </div>
        </div>

        <div className="p-4 bg-[#171717] border border-[#262626]">
          <div className="text-xs text-[#a3a3a3]">Platform Payı</div>
          <div className="text-xl font-bold text-white mt-1">
            ${loading ? "..." : stats.platform_fees}
          </div>
        </div>

        <div className="p-4 bg-[#1f1f1f] border border-white">
          <div className="text-xs text-[#a3a3a3]">Net Gelir</div>
          <div className="text-xl font-bold text-white mt-1">
            ${loading ? "..." : stats.net_revenue}
          </div>
        </div>
      </div>
    </div>
  );
}