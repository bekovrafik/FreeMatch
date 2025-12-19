import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Check, Star, Zap, Gift, X, Crown, Sparkles } from 'lucide-react';

interface Props {
  onClose: () => void;
  streak: number;
  onClaim: () => void;
}

const REWARDS_BASE = [
  { day: 1, label: '1 Super Like', icon: <Star size={20} />, type: 'SUPER_LIKE', value: 1 },
  { day: 2, label: '1 Super Like', icon: <Star size={20} />, type: 'SUPER_LIKE', value: 1 },
  { day: 3, label: '1 Super Like', icon: <Star size={20} />, type: 'SUPER_LIKE', value: 1 },
  { day: 4, label: '1 Super Like', icon: <Star size={20} />, type: 'SUPER_LIKE', value: 1 }, 
  { day: 5, label: '1 Super Like', icon: <Star size={20} />, type: 'SUPER_LIKE', value: 1 },
  { day: 6, label: '1 Super Like', icon: <Star size={20} />, type: 'SUPER_LIKE', value: 1 },
  { day: 7, label: 'Premium Sticker', icon: <Crown size={24} />, type: 'STICKER', value: 1, large: true },
];

export const DailyRewardModal: React.FC<Props> = ({ onClose, streak, onClaim }) => {
  const [claimed, setClaimed] = useState(false);
  
  // Current reward index is (streak - 1) because streak starts at 1. 
  // If streak is 1, we are claiming day 1 (index 0).
  const currentDayIndex = (streak - 1) % 7; 

  const handleClaim = () => {
    setClaimed(true);
    onClaim();
    setTimeout(() => {
        onClose();
    }, 2000);
  };

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/90 backdrop-blur-md"
        onClick={onClose}
      />
      
      <motion.div 
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.8, opacity: 0 }}
        className="bg-slate-900 border border-slate-700 w-full max-w-sm rounded-3xl p-6 relative z-10 flex flex-col items-center shadow-2xl"
      >
         {/* Floating Header Icon */}
         <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-amber-500 rounded-full p-4 border-8 border-slate-900 shadow-xl">
            <Gift size={32} className="text-black" />
         </div>

         <button 
           onClick={onClose} 
           className="absolute top-4 right-4 text-slate-500 hover:text-white"
         >
           <X size={24} />
         </button>

         <h2 className="text-2xl font-black text-white mt-8 mb-2">Daily Streak 🔥</h2>
         <p className="text-slate-400 text-sm mb-6 text-center">
            {streak > 1 
                ? `You're on a ${streak} day streak! Keep it up!` 
                : "Come back every day to earn rewards!"}
         </p>

         <div className="grid grid-cols-4 gap-3 w-full mb-8">
            {REWARDS_BASE.map((reward, i) => {
                const isCompleted = i < currentDayIndex;
                const isCurrent = i === currentDayIndex;
                const isLocked = i > currentDayIndex;

                return (
                    <div 
                    key={i} 
                    className={`relative aspect-square rounded-xl flex flex-col items-center justify-center gap-1 border-2 transition-all ${
                        isCurrent 
                        ? 'bg-amber-500/20 border-amber-500 shadow-[0_0_15px_rgba(245,158,11,0.3)] scale-105 z-10' 
                        : isCompleted 
                            ? 'bg-green-900/20 border-green-500/50 opacity-60' 
                            : 'bg-slate-800 border-slate-700 opacity-50 grayscale'
                    } ${reward.large ? 'col-span-2 aspect-auto flex-row gap-3' : ''}`}
                    >
                        {/* Completed Check */}
                        {isCompleted && (
                        <div className="absolute top-1 right-1 bg-green-500 rounded-full p-0.5">
                            <Check size={8} className="text-black" strokeWidth={4} />
                        </div>
                        )}
                        
                        <div className={`${isCurrent ? 'text-amber-400' : isCompleted ? 'text-green-500' : 'text-slate-500'}`}>
                            {reward.icon}
                        </div>
                        <span className="text-[9px] font-bold text-slate-300 text-center leading-tight px-1">
                            {reward.label}
                        </span>

                        {/* Today Badge */}
                        {isCurrent && (
                            <div className="absolute -bottom-2 bg-amber-500 text-black text-[8px] font-bold px-1.5 rounded-full uppercase">
                                Today
                            </div>
                        )}
                    </div>
                );
            })}
         </div>

         <button 
            onClick={handleClaim}
            disabled={claimed}
            className={`w-full py-4 rounded-2xl font-bold text-lg flex items-center justify-center gap-2 shadow-lg transition-all active:scale-95 ${
                claimed 
                ? 'bg-green-500 text-black'
                : 'bg-gradient-to-r from-amber-500 to-orange-600 text-white hover:shadow-orange-500/25'
            }`}
         >
            {claimed ? (
                <>
                  <Check size={20} /> Claimed!
                </>
            ) : (
                "Claim Reward"
            )}
         </button>
         
         <p className="text-[10px] text-slate-500 mt-4 text-center max-w-[200px]">
            Miss a day and your streak resets to Day 1. Complete 7 days for the Premium Sticker!
         </p>
      </motion.div>
    </div>
  );
};