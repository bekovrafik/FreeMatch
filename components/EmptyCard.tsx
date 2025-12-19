import React from 'react';
import { RefreshCw } from 'lucide-react';

export const EmptyCard: React.FC = () => {
  return (
    <div className="w-full h-full bg-slate-900 rounded-3xl flex flex-col items-center justify-center p-8 text-center border border-slate-800 shadow-2xl relative overflow-hidden select-none">
       {/* Background Decoration */}
       <div className="absolute top-0 left-0 w-full h-full bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-5 pointer-events-none" />
       
       <div className="w-24 h-24 bg-slate-800 rounded-full flex items-center justify-center mb-6 relative">
          <div className="absolute inset-0 bg-amber-500/20 rounded-full animate-ping opacity-20"></div>
          <RefreshCw size={36} className="text-slate-500" />
       </div>
       
       <h2 className="text-3xl font-bold text-white mb-3">No more profiles</h2>
       <p className="text-slate-400 text-lg leading-relaxed max-w-xs">
           You've seen everyone nearby matching your filters.
       </p>
       
       <div className="mt-8 p-4 bg-slate-800/50 rounded-xl border border-slate-700/50">
          <p className="text-sm text-slate-500 font-medium">Try expanding your distance or age range in settings.</p>
       </div>
    </div>
  );
};