import React from 'react';
import { motion } from 'framer-motion';
import { X, Check, Star, Zap, Eye, Ghost } from 'lucide-react';

interface Props {
  onClose: () => void;
}

export const PremiumModal: React.FC<Props> = ({ onClose }) => {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/80 backdrop-blur-sm"
        onClick={onClose}
      />
      
      <motion.div 
        initial={{ y: '100%' }}
        animate={{ y: 0 }}
        exit={{ y: '100%' }}
        transition={{ type: "spring", damping: 25, stiffness: 200 }}
        className="bg-slate-900 w-full max-w-md rounded-t-3xl border-t border-slate-700/50 relative z-10 max-h-[90vh] overflow-y-auto"
      >
        {/* Header Image/Gradient */}
        <div className="h-40 bg-gradient-to-tr from-amber-500 via-pink-500 to-purple-600 relative overflow-hidden rounded-t-3xl flex items-center justify-center">
          <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-30"></div>
          <div className="text-center z-10">
            <h2 className="text-3xl font-black text-white italic tracking-tighter drop-shadow-lg">FREEMATCH</h2>
            <div className="inline-block px-3 py-1 bg-white text-black font-bold text-xs tracking-widest rounded-full mt-2 shadow-xl">
              GOLD
            </div>
          </div>
          
          <button 
            onClick={onClose}
            className="absolute top-4 right-4 bg-black/20 hover:bg-black/40 text-white p-2 rounded-full backdrop-blur-md transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <div className="p-6">
          <h3 className="text-center text-xl font-bold text-white mb-6">Upgrade your dating life</h3>

          {/* Features List */}
          <div className="space-y-4 mb-8">
            <FeatureRow icon={<Eye className="text-amber-500" />} title="See who likes you" desc="Reveal your secret admirers." />
            <FeatureRow icon={<Zap className="text-purple-500" />} title="Unlimited Swipes" desc="No more daily limits." />
            <FeatureRow icon={<Star className="text-blue-500" />} title="5 Super Likes / day" desc="Stand out from the crowd." />
            <FeatureRow icon={<Ghost className="text-slate-400" />} title="No Ads" desc="Uninterrupted swiping." />
          </div>

          {/* Pricing Cards */}
          <div className="flex gap-3 mb-8 overflow-x-auto pb-4 no-scrollbar">
             <PriceCard months={1} price="$9.99/mo" selected={false} />
             <PriceCard months={6} price="$5.99/mo" save="SAVE 40%" selected={true} />
             <PriceCard months={12} price="$3.99/mo" save="SAVE 60%" selected={false} />
          </div>

          <button 
             onClick={() => {
                 alert("Processing Payment Simulation...");
                 setTimeout(onClose, 1000);
             }}
             className="w-full py-4 bg-gradient-to-r from-amber-500 to-pink-600 text-white font-bold text-lg rounded-2xl shadow-lg hover:shadow-pink-500/25 transition-shadow active:scale-[0.98]"
          >
            Continue
          </button>
          
          <p className="text-xs text-slate-500 text-center mt-4">
            Recurring billing. Cancel anytime.
          </p>
        </div>
      </motion.div>
    </div>
  );
};

const FeatureRow: React.FC<{ icon: React.ReactNode, title: string, desc: string }> = ({ icon, title, desc }) => (
  <div className="flex items-center gap-4 p-3 rounded-xl bg-slate-800/50 border border-slate-800">
    <div className="p-2 bg-slate-900 rounded-lg shadow-sm">
      {icon}
    </div>
    <div>
      <h4 className="font-bold text-white text-sm">{title}</h4>
      <p className="text-xs text-slate-400">{desc}</p>
    </div>
  </div>
);

const PriceCard: React.FC<{ months: number, price: string, save?: string, selected: boolean }> = ({ months, price, save, selected }) => (
  <div className={`min-w-[100px] flex-1 p-4 rounded-2xl border-2 flex flex-col items-center justify-center cursor-pointer transition-all ${selected ? 'border-amber-500 bg-amber-500/10 scale-105' : 'border-slate-700 bg-slate-800 opacity-80'}`}>
     {save && <span className="text-[10px] font-bold text-amber-500 mb-1">{save}</span>}
     <span className="text-2xl font-bold text-white">{months}</span>
     <span className="text-xs font-medium text-slate-400 mb-2">months</span>
     <span className={`text-sm font-bold ${selected ? 'text-white' : 'text-slate-300'}`}>{price}</span>
  </div>
);