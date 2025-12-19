import React, { useState, useEffect } from 'react';
import { UserProfile } from '../types';
import { MapPin, Briefcase, Info, BadgeCheck, Heart } from 'lucide-react';
import { motion } from 'framer-motion';
import { AudioPlayer } from './AudioPlayer';

interface Props {
  profile: UserProfile;
  onOpenDetail: () => void;
}

export const UserProfileCard: React.FC<Props> = ({ profile, onOpenDetail }) => {
  const [photoIndex, setPhotoIndex] = useState(0);
  const [isFavorited, setIsFavorited] = useState(false);

  useEffect(() => {
    const favorites = JSON.parse(localStorage.getItem('fm_favorites') || '[]');
    setIsFavorited(favorites.includes(profile.id));
  }, [profile.id]);

  const handleNextPhoto = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (photoIndex < profile.imageUrls.length - 1) {
      setPhotoIndex(prev => prev + 1);
    } else {
      setPhotoIndex(0); // Loop back
    }
  };

  const handlePrevPhoto = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (photoIndex > 0) {
      setPhotoIndex(prev => prev - 1);
    } else {
      setPhotoIndex(profile.imageUrls.length - 1); // Loop to end
    }
  };

  const handleDetailTap = (e: React.MouseEvent) => {
    e.stopPropagation();
    onOpenDetail();
  };

  const toggleFavorite = (e: React.MouseEvent) => {
    e.stopPropagation();
    const favorites = JSON.parse(localStorage.getItem('fm_favorites') || '[]');
    let newFavorites;
    
    if (favorites.includes(profile.id)) {
        newFavorites = favorites.filter((id: string) => id !== profile.id);
        setIsFavorited(false);
    } else {
        newFavorites = [...favorites, profile.id];
        setIsFavorited(true);
    }
    
    localStorage.setItem('fm_favorites', JSON.stringify(newFavorites));
  };

  return (
    <div className="relative w-full h-full bg-slate-800 rounded-3xl overflow-hidden shadow-2xl border border-slate-700 select-none cursor-pointer">
      
      {/* Story Progress Bars */}
      <div className="absolute top-2 left-0 w-full px-2 flex gap-1 z-20">
        {profile.imageUrls.map((_, idx) => (
          <div key={idx} className="h-1 flex-1 bg-white/20 rounded-full overflow-hidden">
             <div 
               className={`h-full bg-white transition-all duration-300 ${idx === photoIndex ? 'w-full' : idx < photoIndex ? 'w-full' : 'w-0'}`} 
             />
          </div>
        ))}
      </div>

      {/* Image Layer */}
      <motion.img 
        key={photoIndex}
        src={profile.imageUrls[photoIndex]} 
        alt={profile.name} 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.2 }}
        className="w-full h-full object-cover pointer-events-none"
        draggable={false}
        onError={(e) => {
            // Fallback to a reliable image if the source fails
            e.currentTarget.src = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=900&fit=crop&fm=jpg";
        }}
      />
      
      {/* Gradient Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/95 via-black/40 to-transparent pointer-events-none" />

      {/* Navigation Tap Zones (Invisible) */}
      <div className="absolute inset-0 flex z-10">
        <div className="w-1/2 h-3/4 cursor-w-resize" onClick={handlePrevPhoto} title="Previous Photo" />
        <div className="w-1/2 h-3/4 cursor-e-resize" onClick={handleNextPhoto} title="Next Photo" />
      </div>

      {/* Action Buttons (Top Right) */}
      <div className="absolute top-6 right-4 z-30 flex gap-3">
        {/* Favorite Button */}
        <div 
            onClick={toggleFavorite}
            className="bg-black/30 backdrop-blur-md p-2 rounded-full text-white/80 border border-white/10 hover:bg-black/50 transition-colors"
        >
            <Heart 
                size={20} 
                className={`transition-colors duration-300 ${isFavorited ? 'text-pink-500 fill-pink-500' : 'text-white'}`}
            />
        </div>
        
        {/* Info Button */}
        <div 
            onClick={handleDetailTap}
            className="bg-black/30 backdrop-blur-md p-2 rounded-full text-white/80 border border-white/10 hover:bg-black/50 transition-colors"
        >
            <Info size={20} />
        </div>
      </div>

      {/* Content Layer (Bottom) - Tapping this opens detail */}
      <div 
        onClick={handleDetailTap}
        className="absolute bottom-0 left-0 w-full p-6 text-white z-20 active:opacity-80 transition-opacity"
      >
        {/* Audio Player (Above Name) */}
        {profile.voiceIntro && (
            <div className="mb-3 inline-block" onClick={(e) => e.stopPropagation()}>
                 <AudioPlayer duration={profile.voiceIntro} color="bg-white/10 hover:bg-white/20" />
            </div>
        )}

        <div className="flex items-end gap-3 mb-2 justify-between">
          <div className="flex items-end gap-2">
             <h2 className="text-4xl font-bold tracking-tight">{profile.name}</h2>
             {profile.isVerified && (
               <BadgeCheck size={28} className="text-blue-500 fill-blue-500/10 mb-1" />
             )}
             <span className="text-2xl font-medium text-slate-300 mb-1">{profile.age}</span>
          </div>
        </div>
        
        <div className="flex items-center gap-2 text-slate-300 mb-1">
          <Briefcase size={16} className="text-amber-500" />
          <span className="text-sm font-medium">{profile.profession}</span>
        </div>
        
        <div className="flex items-center gap-2 text-slate-300 mb-4">
          <MapPin size={16} className="text-amber-500" />
          <span className="text-sm font-medium">{profile.location}</span>
        </div>

        <p className="text-slate-200 text-lg leading-relaxed opacity-90 line-clamp-2">
          {profile.bio}
        </p>
        
        <div className="mt-4 flex justify-center opacity-50">
           <div className="h-1 w-12 bg-slate-500 rounded-full" />
        </div>
      </div>
    </div>
  );
};