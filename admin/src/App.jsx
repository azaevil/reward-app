import React, { useEffect, useState } from 'react';
import { DollarSign, Activity, AlertTriangle, CheckCircle, RefreshCw, LogOut, ShieldCheck, Lock, Mail } from 'lucide-react';
import { adminApi } from './api';

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [stats, setStats] = useState({
    gross_ad_revenue: "0.00",
    platform_fees: "0.00",
    user_rewards: "0.00",
    net_revenue: "0.00"
  });
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Giriş Formu State
  const [email, setEmail] = useState('admin@rewardapp.com');
  const [password, setPassword] = useState('admin123456');
  const [loginLoading, setLoginLoading] = useState(false);
  const [loginError, setLoginError] = useState(null);

  const handleLogin = async (e) => {
    e?.preventDefault();
    try {
      setLoginLoading(true);
      setLoginError(null);
      await adminApi.login(email, password);
      setToken(localStorage.getItem('token'));
    } catch (err) {
      setLoginError(err.response?.data?.detail || 'Giriş yapılamadı. Bilgileri kontrol edin.');
    } finally {
      setLoginLoading(false);
    }
  };

  const handleLogout = () => {
    adminApi.logout();
    setToken(null);
  };

  const loadDashboardData = async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const [statsData, withdrawalsData] = await Promise.all([
        adminApi.getRevenueStats(),
        adminApi.getWithdrawals().catch(() => [])
      ]);
      setStats(statsData);
      setWithdrawals(withdrawalsData || []);
    } catch (err) {
      if (err.response?.status === 401) {
        setToken(null);
        setError('Oturum süresi doldu, lütfen tekrar giriş yapın.');
      } else {
        setError(err.response?.data?.detail || err.message);
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (token) {
      loadDashboardData();
    }
  }, [token]);

  const handleApprove = async (id) => {
    try {
      await adminApi.approveWithdrawal(id);
      loadDashboardData();
    } catch (err) {
      alert(`Hata: ${err.response?.data?.detail || err.message}`);
    }
  };

  const handleApproveAll = async () => {
    try {
      const res = await adminApi.approveAllWithdrawals();
      alert(`${res.approved_count || 0} adet para çekme talebi başarıyla onaylandı!`);
      loadDashboardData();
    } catch (err) {
      alert(`Hata: ${err.response?.data?.detail || err.message}`);
    }
  };

  // Giriş Yapılmamışsa Login Ekranı Göster
  if (!token) {
    return (
      <div className="min-h-screen bg-[#0f0f0f] text-[#f5f5f5] flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-[#171717] border border-[#262626] p-8 rounded-lg shadow-2xl">
          <div className="flex items-center justify-center gap-3 mb-6">
            <ShieldCheck className="text-emerald-500 w-8 h-8" />
            <h1 className="text-xl font-bold tracking-tight">Admin Giriş Paneli</h1>
          </div>
          <p className="text-xs text-[#a3a3a3] text-center mb-6">
            Ödüllü Reklam Sistemi Yönetim Portalı
          </p>

          {loginError && (
            <div className="mb-4 p-3 bg-red-950/50 border border-red-800 text-red-300 text-xs rounded">
              {loginError}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs uppercase tracking-wider text-[#a3a3a3] mb-1">E-Posta</label>
              <div className="relative">
                <Mail className="absolute left-3 top-2.5 text-[#555] w-4 h-4" />
                <input 
                  type="email" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-[#0f0f0f] border border-[#333] text-sm text-white pl-10 pr-3 py-2 rounded focus:outline-none focus:border-white transition-colors"
                  placeholder="admin@rewardapp.com"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs uppercase tracking-wider text-[#a3a3a3] mb-1">Şifre</label>
              <div className="relative">
                <Lock className="absolute left-3 top-2.5 text-[#555] w-4 h-4" />
                <input 
                  type="password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-[#0f0f0f] border border-[#333] text-sm text-white pl-10 pr-3 py-2 rounded focus:outline-none focus:border-white transition-colors"
                  placeholder="******"
                  required
                />
              </div>
            </div>

            <button 
              type="submit" 
              disabled={loginLoading}
              className="w-full py-2.5 px-4 bg-white text-black font-semibold text-xs tracking-wider uppercase rounded hover:bg-[#e0e0e0] transition-colors mt-2"
            >
              {loginLoading ? 'Giriş Yapılıyor...' : 'Yönetim Paneline Giriş Yap'}
            </button>
          </form>

          <div className="mt-6 pt-4 border-t border-[#262626] text-center">
            <span className="text-[11px] text-[#666]">
              Varsayılan Bilgiler: <code className="text-[#aaa]">admin@rewardapp.com / admin123456</code>
            </span>
          </div>
        </div>
      </div>
    );
  }

  // Giriş Yapılmışsa Dashboard Göster
  return (
    <div className="min-h-screen bg-[#0f0f0f] text-[#f5f5f5] p-8">
      <header className="mb-8 border-b border-[#262626] pb-4 flex flex-wrap justify-between items-center gap-4">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="text-emerald-500 w-5 h-5" />
            <h1 className="text-xl font-bold tracking-tight">Yönetim Paneli</h1>
          </div>
          <p className="text-xs text-[#a3a3a3] mt-1">Sistem Performansı, Finansal Özet ve Para Çekme Talepleri</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={loadDashboardData}
            disabled={loading}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-[#171717] border border-[#262626] rounded text-xs text-[#f5f5f5] hover:bg-[#262626] transition-colors"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} /> Yenile
          </button>
          <button 
            onClick={handleLogout}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-red-950/40 border border-red-800/60 rounded text-xs text-red-300 hover:bg-red-900/60 transition-colors"
          >
            <LogOut size={14} /> Çıkış Yap
          </button>
        </div>
      </header>

      {error && (
        <div className="mb-6 p-4 bg-red-950/40 border border-red-800 text-red-200 text-xs rounded">
          {error}
        </div>
      )}

      {/* İstatistik Kartları */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <MetricCard title="Brüt Reklam Geliri" value={`$${stats.gross_ad_revenue}`} icon={<DollarSign size={18} className="text-blue-400" />} />
        <MetricCard title="Dağıtılan Ödüller" value={`$${stats.user_rewards}`} icon={<Activity size={18} className="text-amber-400" />} />
        <MetricCard title="Platform Kesintisi" value={`$${stats.platform_fees}`} icon={<DollarSign size={18} className="text-purple-400" />} />
        <MetricCard title="Net Şirket Geliri" value={`$${stats.net_revenue}`} icon={<DollarSign size={18} className="text-emerald-400" />} isHighlight />
      </div>

      {/* Para Çekme Talepleri Onay Modülü */}
      <div className="bg-[#171717] border border-[#262626] rounded-lg p-6 mb-8 shadow-lg">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-sm font-semibold tracking-wide uppercase text-[#f5f5f5]">Bekleyen Para Çekme Talepleri</h2>
          {withdrawals.filter(w => w.status === 'PENDING').length > 0 && (
            <button 
              onClick={handleApproveAll}
              className="flex items-center gap-1.5 px-3 py-1 bg-emerald-900/60 border border-emerald-700 text-emerald-200 text-xs font-medium rounded hover:bg-emerald-800 transition-colors"
            >
              <CheckCircle size={14} /> Tümünü Tek Tıkla Onayla ({withdrawals.filter(w => w.status === 'PENDING').length})
            </button>
          )}
        </div>
        
        {withdrawals.length === 0 ? (
          <p className="text-xs text-[#a3a3a3]">İncelenmeyi bekleyen para çekme talebi bulunmuyor.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-[#a3a3a3]">
              <thead className="bg-[#262626] text-[#f5f5f5] uppercase font-mono">
                <tr>
                  <th className="p-3">ID</th>
                  <th className="p-3">Kullanıcı ID</th>
                  <th className="p-3">Miktar (USD)</th>
                  <th className="p-3">Yöntem</th>
                  <th className="p-3">Ödeme Detayı</th>
                  <th className="p-3">Durum</th>
                  <th className="p-3">İşlem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#262626]">
                {withdrawals.map((w) => (
                  <tr key={w.id} className="hover:bg-[#1f1f1f] transition-colors">
                    <td className="p-3 font-mono">{w.id}</td>
                    <td className="p-3">Kullanıcı #{w.user_id}</td>
                    <td className="p-3 font-semibold text-emerald-400">${w.amount_usd}</td>
                    <td className="p-3">{w.payment_method}</td>
                    <td className="p-3 font-mono">{w.payout_details}</td>
                    <td className="p-3">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        w.status === 'APPROVED' 
                          ? 'bg-emerald-950 text-emerald-300 border border-emerald-800' 
                          : 'bg-amber-950 text-amber-300 border border-amber-800'
                      }`}>
                        {w.status}
                      </span>
                    </td>
                    <td className="p-3">
                      {w.status === 'PENDING' ? (
                        <button 
                          onClick={() => handleApprove(w.id)}
                          className="flex items-center gap-1 px-2.5 py-1 bg-emerald-950 border border-emerald-800 text-emerald-200 rounded hover:bg-emerald-900 transition-colors"
                        >
                          <CheckCircle size={12} /> Onayla
                        </button>
                      ) : (
                        <span className="text-gray-500 text-xs">Tamamlandı</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function MetricCard({ title, value, icon, isHighlight = false }) {
  return (
    <div className={`p-5 rounded-lg border ${isHighlight ? 'border-emerald-700/60 bg-[#14261d]' : 'border-[#262626] bg-[#171717]'} shadow-md`}>
      <div className="flex justify-between items-center text-[#a3a3a3] mb-2">
        <span className="text-xs uppercase tracking-wider">{title}</span>
        {icon}
      </div>
      <div className={`text-2xl font-bold tracking-tight ${isHighlight ? 'text-emerald-400' : 'text-[#f5f5f5]'}`}>{value}</div>
    </div>
  );
}