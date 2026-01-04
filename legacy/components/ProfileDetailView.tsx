import React, { useState } from 'react';
import { UserProfile } from '../types';
import { MapPin, Briefcase, ChevronDown, Quote, AlertTriangle, ShieldOff, BadgeCheck } from 'lucide-react';
import { motion, PanInfo, useAnimation, AnimatePresence } from 'framer-motion';

interface Props {
  profile: UserProfile;
  onClose: () => void;
  onBlockUser: (id: string) => void;
}

export const ProfileDetailView: React.FC<Props> = ({ profile, onClose, onBlockUser }) => {
  const [showSafetyMenu, setShowSafetyMenu] = useState(false);
  const [showReportConfirm, setShowReportConfirm] = useState(false);
  const controls = useAnimation();

  const reportUser = (id: string) => {
      console.log(`[REPORT] User ${id} has been reported for violations.`);
      // In a real app, this would make an API call.
      onBlockUser(id); // Auto block on report
  };

  const handleReportTap = () => {
     setShowReportConfirm(true);
  };

  const confirmReport = () => {
      reportUser(profile.id);
      setShowReportConfirm(false);
  };

  const handleBlock = () => {
      if(confirm("Block this user? You won't see them again.")) {
          onBlockUser(profile.id);
      }
  };

  const handleDragEnd = async (_: any, info: PanInfo) => {
    const threshold = 150;
    const velocity = info.velocity.y;

    if (info.offset.y > threshold || velocity > 500) {
      // Swipe down confirmed
      await controls.start({ y: '100%' });
      onClose();
    } else {
      // Snap back
      controls.start({ y: 0 });
    }
  };

  return (
    <motion.div 
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      drag="y"
      dragConstraints={{ top: 0 }}
      dragElastic={0.2}
      onDragEnd={handleDragEnd}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="fixed inset-0 z-[150] bg-slate-950 flex flex-col overflow-hidden"
    >
      {/* Scrollable Container */}
      <div className="flex-1 overflow-y-auto relative no-scrollbar">
        
        {/* Close Button (Floating) */}
        <button 
          onClick={onClose}
          className="absolute top-4 right-4 z-50 bg-black/50 backdrop-blur-md p-2 rounded-full text-white hover:bg-black/70 transition-colors border border-white/10"
        >
          <ChevronDown size={32} />
        </button>

        {/* Drag Handle Indicator */}
        <div className="absolute top-2 left-0 right-0 z-50 flex justify-center pointer-events-none">
           <div className="w-12 h-1.5 bg-white/30 rounded-full backdrop-blur-sm" />
        </div>

        {/* Main Image */}
        <div className="w-full h-[60vh] relative pointer-events-none">
           <img 
            src={profile.imageUrls[0]} 
            alt={profile.name} 
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-transparent" />
        </div>

        {/* Details Section */}
        <div className="px-6 -mt-20 relative z-10 pb-20">
          <div className="flex items-end gap-3 mb-2">
            <h1 className="text-5xl font-extrabold text-white tracking-tight">{profile.name}</h1>
            {profile.isVerified && (
               <BadgeCheck size={36} className="text-blue-500 fill-blue-500/10 mb-1" />
            )}
            <span className="text-3xl font-medium text-slate-400 mb-1">{profile.age}</span>
          </div>

          <div className="flex flex-col gap-3 mt-4 text-slate-300">
             <div className="flex items-center gap-3 bg-slate-900/50 p-3 rounded-xl border border-slate-800 backdrop-blur-sm">
                <Briefcase className="text-amber-500" size={20} />
                <span className="text-lg font-medium">{profile.profession}</span>
             </div>
             
             <div className="flex items-center gap-3 bg-slate-900/50 p-3 rounded-xl border border-slate-800 backdrop-blur-sm">
                <MapPin className="text-amber-500" size={20} />
                <span className="text-lg font-medium">{profile.location}</span>
             </div>
          </div>

          <div className="mt-8">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Quote size={20} className="text-slate-500" />
              About Me
            </h3>
            <p className="text-slate-300 text-lg leading-loose font-light">
              {profile.bio}
              <br /><br />
              Looking for someone who can keep up with my adventures and isn't afraid of a little spontaneity.
            </p>
          </div>
          
          {/* Gallery Grid for Extra Photos */}
          {profile.imageUrls.length > 1 && (
            <div className="mt-8">
                <h3 className="text-slate-500 uppercase text-sm font-bold tracking-widest mb-4">More Photos</h3>
                <div className="grid grid-cols-2 gap-2">
                    {profile.imageUrls.slice(1).map((url, idx) => (
                        <div key={idx} className="rounded-xl overflow-hidden h-48">
                            <img src={url} alt="Gallery" className="w-full h-full object-cover" />
                        </div>
                    ))}
                </div>
            </div>
          )}

          <div className="mt-8 pt-8 border-t border-slate-800">
             <h3 className="text-slate-500 uppercase text-sm font-bold tracking-widest mb-4">Interests</h3>
             <div className="flex flex-wrap gap-2">
                {profile.interests && profile.interests.length > 0 ? (
                  profile.interests.map(tag => (
                    <span key={tag} className="px-4 py-2 bg-slate-800 rounded-full text-slate-300 font-medium text-sm">
                      {tag}
                    </span>
                  ))
                ) : (
                   <span className="text-slate-500 italic">No interests listed.</span>
                )}
             </div>
          </div>
          
          {/* Safety Section */}
          <div className="mt-12 mb-8 flex flex-col items-center">
             <button 
               onClick={() => setShowSafetyMenu(!showSafetyMenu)}
               className="text-slate-500 text-sm font-bold flex items-center gap-2 hover:text-red-500 transition-colors"
             >
                <ShieldOff size={16} />
                Report or Block
             </button>
             
             <AnimatePresence>
             {showSafetyMenu && (
                 <motion.div 
                   initial={{ opacity: 0, height: 0, marginTop: 0 }}
                   animate={{ opacity: 1, height: 'auto', marginTop: 16 }}
                   exit={{ opacity: 0, height: 0, marginTop: 0 }}
                   className="w-full bg-slate-900 rounded-xl p-4 border border-slate-800 flex flex-col gap-2 overflow-hidden"
                 >
                     <button onClick={handleReportTap} className="flex items-center gap-3 p-3 bg-red-900/20 text-red-500 rounded-lg font-bold hover:bg-red-900/40">
                        <AlertTriangle size={20} />
                        Report User
                     </button>
                     <button onClick={handleBlock} className="flex items-center gap-3 p-3 bg-slate-800 text-slate-300 rounded-lg font-bold hover:bg-slate-700">
                        <ShieldOff size={20} />
                        Block User
                     </button>
                 </motion.div>
             )}
             </AnimatePresence>
          </div>
        </div>
      </div>

      {/* Confirmation Dialog Overlay */}
      <AnimatePresence>
        {showReportConfirm && (
            <div className="absolute inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-sm p-6">
                <motion.div 
                    initial={{ scale: 0.9, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.9, opacity: 0 }}
                    className="bg-slate-900 p-6 rounded-2xl border border-slate-800 shadow-2xl w-full max-w-sm"
                >
                    <h3 className="text-xl font-bold text-white mb-2">Report {profile.name}?</h3>
                    <p className="text-slate-400 mb-6 text-sm">
                        Are you sure you want to report this user? This will also block them from seeing you.
                    </p>
                    <div className="flex gap-3">
                        <button 
                            onClick={() => setShowReportConfirm(false)}
                            className="flex-1 py-3 bg-slate-800 rounded-xl font-bold text-slate-300 hover:bg-slate-700"
                        >
                            Cancel
                        </button>
                        <button 
                            onClick={confirmReport}
                            className="flex-1 py-3 bg-red-600 rounded-xl font-bold text-white hover:bg-red-500"
                        >
                            Report
                        </button>
                    </div>
                </motion.div>
            </div>
        )}
      </AnimatePresence>

      {/* Bottom Action Area (Sticky) */}
      <div className="p-4 bg-slate-900 border-t border-slate-800 flex justify-center pb-8 safe-area-pb">
        <button 
          onClick={onClose}
          className="w-full py-4 rounded-2xl bg-gradient-to-r from-slate-800 to-slate-700 text-white font-bold text-lg shadow-lg"
        >
          Keep Swiping
        </button>
      </div>
    </motion.div>
  );
};