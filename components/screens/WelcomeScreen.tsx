import React from 'react';
import { motion } from 'framer-motion';
import { Flame, ArrowRight } from 'lucide-react';

interface Props {
  onStart: () => void;
}

export const WelcomeScreen: React.FC<Props> = ({ onStart }) => {
  return (
    <div className="flex flex-col items-center justify-between h-full p-8 bg-slate-950 text-white relative overflow-hidden">
      {/* Background Decor */}
      <div className="absolute top-0 left-0 w-full h-1/2 bg-gradient-to-b from-slate-900 to-transparent z-0 pointer-events-none" />
      <div className="absolute -top-20 -right-20 w-64 h-64 bg-amber-500/20 rounded-full blur-3xl" />
      <div className="absolute top-40 -left-20 w-64 h-64 bg-pink-600/20 rounded-full blur-3xl" />

      <div className="flex-1 flex flex-col items-center justify-center z-10 w-full">
        <motion.div 
          initial={{ scale: 0.5, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.8, type: 'spring' }}
          className="w-24 h-24 bg-gradient-to-tr from-amber-400 to-pink-600 rounded-3xl shadow-2xl shadow-pink-500/30 flex items-center justify-center mb-8 rotate-3"
        >
          <Flame size={64} fill="white" className="text-white" />
        </motion.div>

        <motion.h1 
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="text-4xl font-extrabold tracking-tight text-center mb-2"
        >
          FreeMatch
        </motion.h1>

        <motion.p 
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="text-slate-400 text-center text-lg max-w-xs"
        >
          Connections without limits. <br/> Dating made simple.
        </motion.p>
      </div>

      <motion.button
        initial={{ y: 50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.8 }}
        onClick={onStart}
        className="w-full py-4 bg-white text-black font-bold text-xl rounded-2xl shadow-xl flex items-center justify-center gap-2 hover:scale-[1.02] active:scale-95 transition-transform z-10"
      >
        Get Started
        <ArrowRight size={20} />
      </motion.button>
    </div>
  );
};