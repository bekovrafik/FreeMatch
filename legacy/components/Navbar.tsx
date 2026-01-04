import React from 'react';
import { motion } from 'framer-motion';
import { Flame, MessageCircle, User, Settings } from 'lucide-react';

interface Props {
  activeTab: 'HOME' | 'CHAT' | 'PROFILE' | 'SETTINGS';
  onTabChange: (tab: 'HOME' | 'CHAT' | 'PROFILE' | 'SETTINGS') => void;
}

export const Navbar: React.FC<Props> = ({ activeTab, onTabChange }) => {
  const tabs = [
    { id: 'HOME', icon: Flame, label: 'Match' },
    { id: 'CHAT', icon: MessageCircle, label: 'Chat' },
    { id: 'PROFILE', icon: User, label: 'Profile' },
    { id: 'SETTINGS', icon: Settings, label: 'Settings' },
  ];

  return (
    <div className="fixed bottom-0 left-0 w-full p-4 pb-2 z-50 pointer-events-none flex justify-center">
      <div className="pointer-events-auto bg-slate-900/90 backdrop-blur-xl border border-white/10 rounded-3xl shadow-2xl shadow-black/50 flex items-center justify-between px-2 py-2 w-full max-w-[320px]">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const Icon = tab.icon;
          
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id as any)}
              className="relative flex flex-col items-center justify-center w-16 h-14 rounded-2xl transition-all"
            >
              {isActive && (
                <motion.div
                  layoutId="nav-pill"
                  className="absolute inset-0 bg-slate-800 rounded-2xl"
                  transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                />
              )}
              
              <div className={`relative z-10 flex flex-col items-center gap-1 transition-all duration-300 ${isActive ? 'scale-110' : 'scale-100 opacity-60'}`}>
                <Icon 
                  size={24} 
                  className={`transition-colors duration-300 ${isActive ? 'text-amber-500 fill-amber-500/20' : 'text-slate-300'}`} 
                  strokeWidth={isActive ? 2.5 : 2}
                />
                <span className={`text-[9px] font-bold ${isActive ? 'text-white' : 'text-slate-400'}`}>
                   {tab.label}
                </span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};