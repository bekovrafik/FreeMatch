import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Heart, Sparkles, MessageCircle, ChevronRight } from 'lucide-react';

interface Props {
  onComplete: () => void;
}

const STEPS = [
  {
    id: 1,
    title: "Discover People",
    desc: "Swipe right on profiles that catch your eye. It's that simple.",
    icon: <Heart size={64} className="text-pink-500" fill="currentColor" />,
    color: "bg-pink-500/20"
  },
  {
    id: 2,
    title: "Stay Connected",
    desc: "Match and chat instantly. No hidden fees for basic communication.",
    icon: <MessageCircle size={64} className="text-blue-500" />,
    color: "bg-blue-500/20"
  },
  {
    id: 3,
    title: "Support Creators",
    desc: "We keep it free by showing occasional sponsored content.",
    icon: <Sparkles size={64} className="text-amber-500" fill="currentColor" />,
    color: "bg-amber-500/20"
  }
];

export const OnboardingScreen: React.FC<Props> = ({ onComplete }) => {
  const [step, setStep] = useState(0);

  const handleNext = () => {
    if (step < STEPS.length - 1) {
      setStep(prev => prev + 1);
    } else {
      onComplete();
    }
  };

  return (
    <div className="h-full flex flex-col bg-slate-950 relative overflow-hidden">
       {/* Progress Bar */}
       <div className="absolute top-8 left-0 w-full px-8 flex gap-2 z-20">
         {STEPS.map((_, idx) => (
           <div 
             key={idx} 
             className={`h-1 flex-1 rounded-full transition-colors duration-300 ${idx <= step ? 'bg-white' : 'bg-slate-800'}`} 
           />
         ))}
       </div>

       <div className="flex-1 flex flex-col items-center justify-center p-8 relative">
          <AnimatePresence mode="wait">
            <motion.div 
              key={step}
              initial={{ x: 100, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: -100, opacity: 0 }}
              transition={{ type: "spring", stiffness: 300, damping: 30 }}
              className="flex flex-col items-center text-center"
            >
              <div className={`w-40 h-40 rounded-full ${STEPS[step].color} flex items-center justify-center mb-10 shadow-2xl`}>
                {STEPS[step].icon}
              </div>
              
              <h2 className="text-3xl font-bold text-white mb-4">{STEPS[step].title}</h2>
              <p className="text-slate-400 text-lg leading-relaxed">{STEPS[step].desc}</p>
            </motion.div>
          </AnimatePresence>
       </div>

       <div className="p-8">
         <button 
           onClick={handleNext}
           className="w-full py-4 bg-gradient-to-r from-slate-800 to-slate-700 hover:from-slate-700 hover:to-slate-600 text-white font-bold text-lg rounded-2xl flex items-center justify-center gap-2 transition-all active:scale-95 border border-slate-600"
         >
           {step === STEPS.length - 1 ? "Create Account" : "Next"}
           <ChevronRight size={20} />
         </button>
       </div>
    </div>
  );
};