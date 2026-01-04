import React from 'react';
import { motion } from 'framer-motion';
import { UserProfile } from '../types';
import { MessageCircle, X } from 'lucide-react';
import { CURRENT_USER } from '../constants';

interface Props {
  matchedProfile: UserProfile;
  onKeepSwiping: () => void;
  onSendMessage: () => void;
}

export const MatchOverlay: React.FC<Props> = ({ matchedProfile, onKeepSwiping, onSendMessage }) => {
  return (
    <div className="fixed inset-0 z-[200] flex flex-col items-center justify-center bg-black/90 backdrop-blur-xl p-6">
      <motion.div
        initial={{ scale: 0.5, opacity: 0, rotate: -10 }}
        animate={{ scale: 1, opacity: 1, rotate: 0 }}
        transition={{ type: "spring", bounce: 0.5 }}
        className="mb-12"
      >
        <h1 className="text-6xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-400 to-pink-600 italic tracking-tighter drop-shadow-lg transform -rotate-6">
          IT'S A<br />MATCH!
        </h1>
      </motion.div>

      <div className="relative w-full h-64 mb-12 flex items-center justify-center">
        {/* User Image */}
        <motion.div 
            initial={{ x: -100, opacity: 0, rotate: -15 }}
            animate={{ x: -40, opacity: 1, rotate: -10 }}
            transition={{ delay: 0.2, type: "spring" }}
            className="absolute w-40 h-56 rounded-3xl overflow-hidden border-4 border-white shadow-2xl shadow-pink-500/50"
        >
            <img src={CURRENT_USER.imageUrls[0]} className="w-full h-full object-cover" alt="Me" />
        </motion.div>

        {/* Matched Profile Image */}
        <motion.div 
            initial={{ x: 100, opacity: 0, rotate: 15 }}
            animate={{ x: 40, opacity: 1, rotate: 10 }}
            transition={{ delay: 0.4, type: "spring" }}
            className="absolute w-40 h-56 rounded-3xl overflow-hidden border-4 border-white shadow-2xl shadow-amber-500/50"
        >
            <img src={matchedProfile.imageUrls[0]} className="w-full h-full object-cover" alt={matchedProfile.name} />
        </motion.div>

        {/* Heart Icon */}
        <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.6, type: "spring" }}
            className="absolute z-10 w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-xl"
        >
            <div className="text-pink-600">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                </svg>
            </div>
        </motion.div>
      </div>

      <motion.p 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.7 }}
        className="text-white text-center text-lg mb-8"
      >
        You and <span className="font-bold text-amber-400">{matchedProfile.name}</span> like each other.
      </motion.p>

      <motion.div 
        initial={{ opacity: 0, y: 50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8 }}
        className="w-full space-y-4"
      >
        <button 
            onClick={onSendMessage}
            className="w-full py-4 bg-gradient-to-r from-pink-500 to-amber-500 rounded-2xl font-bold text-white text-lg flex items-center justify-center gap-2 shadow-lg"
        >
            <MessageCircle size={24} />
            Send a Message
        </button>

        <button 
            onClick={onKeepSwiping}
            className="w-full py-4 bg-slate-800 rounded-2xl font-bold text-slate-300 text-lg flex items-center justify-center gap-2 border border-slate-700"
        >
            <X size={24} />
            Keep Swiping
        </button>
      </motion.div>
    </div>
  );
};