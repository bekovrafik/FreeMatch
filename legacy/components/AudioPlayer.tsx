import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Play, Pause } from 'lucide-react';

interface Props {
  duration: string;
  onPlayStateChange?: (isPlaying: boolean) => void;
  color?: string;
  barColor?: string;
}

export const AudioPlayer: React.FC<Props> = ({ duration, onPlayStateChange, color = "bg-white/20", barColor = "bg-white" }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  
  const togglePlay = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsPlaying(!isPlaying);
    if (onPlayStateChange) onPlayStateChange(!isPlaying);
  };

  useEffect(() => {
    if (isPlaying) {
      const timer = setTimeout(() => {
        setIsPlaying(false);
        if (onPlayStateChange) onPlayStateChange(false);
      }, 3000); // Mock 3s playback duration for prototype
      return () => clearTimeout(timer);
    }
  }, [isPlaying, onPlayStateChange]);

  // Mock waveform bars
  const bars = [3, 5, 8, 4, 6, 9, 5, 3, 6, 8, 4, 7, 5, 2];

  return (
    <div 
      onClick={togglePlay}
      className={`flex items-center gap-2 px-3 py-1.5 rounded-full backdrop-blur-md cursor-pointer transition-all active:scale-95 ${color} border border-white/10`}
    >
       <div className="w-6 h-6 rounded-full bg-white text-black flex items-center justify-center shadow-sm">
         {isPlaying ? <Pause size={10} fill="black" /> : <Play size={10} fill="black" className="ml-0.5" />}
       </div>
       
       <div className="flex items-center gap-0.5 h-4">
         {bars.map((height, i) => (
           <motion.div
             key={i}
             className={`w-0.5 rounded-full ${barColor}`}
             initial={{ height: 4 }}
             animate={{ 
               height: isPlaying ? [4, height * 2, 4] : 4,
               opacity: isPlaying ? 1 : 0.6
             }}
             transition={{ 
               repeat: isPlaying ? Infinity : 0, 
               duration: 0.5,
               delay: i * 0.05,
               ease: "easeInOut"
             }}
           />
         ))}
       </div>
       
       <span className="text-[10px] font-bold text-white opacity-80 ml-1">{duration}</span>
    </div>
  );
};
