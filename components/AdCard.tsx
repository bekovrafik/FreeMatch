import React from 'react';
import { motion } from 'framer-motion';
import { AdContent } from '../types';
import { ExternalLink, Sparkles } from 'lucide-react';

interface Props {
  ad: AdContent;
  onTap: () => void;
}

export const AdCard: React.FC<Props> = ({ ad, onTap }) => {
  return (
    <motion.div 
      initial="rest"
      whileHover="hover"
      animate="rest"
      onClick={onTap}
      className="relative w-full h-full bg-slate-900 rounded-3xl overflow-hidden shadow-2xl border-2 border-amber-500/50 select-none cursor-pointer group"
    >
       {/* Image Layer - Full Height */}
       <motion.img 
        src={ad.imageUrl} 
        alt={ad.title} 
        variants={{
          rest: { scale: 1, opacity: 0.85, filter: "brightness(0.9)" },
          hover: { scale: 1.1, opacity: 1, filter: "brightness(1.1)" }
        }}
        transition={{ duration: 0.6, ease: [0.33, 1, 0.68, 1] }} // Cubic bezier for smooth ease out
        className="absolute inset-0 w-full h-full object-cover pointer-events-none"
        draggable={false}
      />

       {/* Gradient Overlay */}
       <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-900/60 to-transparent pointer-events-none" />

       {/* Ad Badge */}
       <div className="absolute top-4 right-4 bg-amber-500 text-black font-bold px-3 py-1 rounded-full text-xs uppercase tracking-wider z-10 shadow-lg flex items-center gap-1">
        <Sparkles size={12} fill="black" />
        Sponsored
       </div>

       {/* Content Layer */}
       <div className="absolute bottom-0 left-0 w-full p-6 flex flex-col justify-end items-start z-10 pointer-events-none">
         <div className="w-full">
            <h2 className="text-4xl font-extrabold text-white mb-2 drop-shadow-md">{ad.title}</h2>
            <p className="text-slate-200 text-lg mb-8 leading-snug drop-shadow-sm font-medium">{ad.description}</p>
            
            {/* CTA Button */}
            <motion.div 
              variants={{
                rest: { scale: 1, boxShadow: "0 10px 15px -3px rgba(0, 0, 0, 0.1)" },
                hover: { 
                  scale: [1, 1.05, 1],
                  boxShadow: [
                    "0 0 0px rgba(245, 158, 11, 0)",
                    "0 0 20px rgba(245, 158, 11, 0.6)",
                    "0 0 0px rgba(245, 158, 11, 0)"
                  ],
                  transition: { 
                    duration: 1.5, 
                    repeat: Infinity, 
                    ease: "easeInOut" 
                  } 
                }
              }}
              className="flex items-center justify-center w-full py-5 bg-gradient-to-r from-amber-500 to-orange-600 rounded-2xl text-white font-bold text-xl gap-3"
            >
              <span>{ad.ctaText}</span>
              <ExternalLink size={24} strokeWidth={2.5} />
            </motion.div>
            
            <p className="text-center text-xs text-slate-400 mt-4 uppercase tracking-widest opacity-70">
              Tap card to open website
            </p>
         </div>
       </div>
    </motion.div>
  );
};