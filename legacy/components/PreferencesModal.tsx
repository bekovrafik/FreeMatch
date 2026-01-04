import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { X, Check, MapPin, Navigation, Tag } from 'lucide-react';

// Shared list of interests for filtering
const INTEREST_OPTIONS = [
  'Coffee', 'Travel', 'Music', 'Photography', 'Art', 
  'Foodie', 'Gym', 'Yoga', 'Hiking', 'Dogs', 
  'Cats', 'Movies', 'Gaming', 'Tech', 'Fashion',
  'Cooking', 'Reading', 'Dancing', 'Sports', 'Nature'
];

interface Preferences {
  ageRange: [number, number];
  distance: number;
  gender: 'MEN' | 'WOMEN' | 'EVERYONE';
  location: string;
  interests: string[];
}

interface Props {
  currentPrefs: Preferences;
  onSave: (prefs: Preferences) => void;
  onClose: () => void;
}

export const PreferencesModal: React.FC<Props> = ({ currentPrefs, onSave, onClose }) => {
  const [prefs, setPrefs] = useState<Preferences>(currentPrefs);

  const handleGenderSelect = (gender: 'MEN' | 'WOMEN' | 'EVERYONE') => {
    setPrefs({ ...prefs, gender });
  };

  const handleDistanceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPrefs({ ...prefs, distance: parseInt(e.target.value) });
  };

  const handleAgeChange = (index: 0 | 1, value: string) => {
    const newVal = parseInt(value);
    const newRange = [...prefs.ageRange] as [number, number];
    newRange[index] = newVal;
    if (index === 0 && newVal > newRange[1]) newRange[1] = newVal;
    if (index === 1 && newVal < newRange[0]) newRange[0] = newVal;
    setPrefs({ ...prefs, ageRange: newRange });
  };

  const toggleInterest = (interest: string) => {
    if (prefs.interests.includes(interest)) {
      setPrefs({ ...prefs, interests: prefs.interests.filter(i => i !== interest) });
    } else {
      setPrefs({ ...prefs, interests: [...prefs.interests, interest] });
    }
  };

  return (
    <div className="fixed inset-0 z-[160] flex items-end justify-center pointer-events-none">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-auto"
        onClick={onClose}
      />
      
      <motion.div 
        initial={{ y: '100%' }}
        animate={{ y: 0 }}
        exit={{ y: '100%' }}
        transition={{ type: "spring", damping: 25, stiffness: 200 }}
        className="bg-slate-900 w-full max-w-md rounded-t-3xl border-t border-slate-800 p-6 pointer-events-auto relative z-10 max-h-[85vh] overflow-y-auto"
      >
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-white">Discovery Settings</h2>
          <button onClick={onClose} className="p-2 bg-slate-800 rounded-full text-slate-400 hover:text-white">
            <X size={24} />
          </button>
        </div>

        {/* Location / City */}
        <div className="mb-6">
           <label className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3 block">Location</label>
           <div className="relative flex items-center gap-2">
              <div className="relative flex-1">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                <input 
                  type="text" 
                  value={prefs.location}
                  onChange={(e) => setPrefs({ ...prefs, location: e.target.value })}
                  placeholder="Anywhere"
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl py-3 pl-10 pr-4 text-white focus:border-amber-500 outline-none font-medium"
                />
              </div>
              <button 
                onClick={() => setPrefs({ ...prefs, location: 'San Francisco, CA' })} // Mock current location
                className="p-3 bg-slate-800 rounded-xl text-amber-500 border border-slate-700 hover:bg-slate-700"
                title="Use Current Location"
              >
                <Navigation size={20} />
              </button>
           </div>
           <p className="text-[10px] text-slate-500 mt-2 ml-1">Leave empty to search globally within distance.</p>
        </div>

        {/* Gender */}
        <div className="mb-6">
          <label className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3 block">Show Me</label>
          <div className="flex gap-2">
            {['MEN', 'WOMEN', 'EVERYONE'].map((g) => (
              <button
                key={g}
                onClick={() => handleGenderSelect(g as any)}
                className={`flex-1 py-3 rounded-xl font-bold text-sm transition-all border ${
                  prefs.gender === g 
                    ? 'bg-amber-500 border-amber-500 text-black shadow-lg shadow-amber-500/20' 
                    : 'bg-slate-800 border-slate-700 text-slate-400 hover:border-slate-600'
                }`}
              >
                {g.charAt(0) + g.slice(1).toLowerCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Distance */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-4">
             <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Maximum Distance</label>
             <span className="text-white font-bold">{prefs.distance} km</span>
          </div>
          <input 
            type="range" 
            min="1" 
            max="100" 
            value={prefs.distance}
            onChange={handleDistanceChange}
            className="w-full h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-amber-500"
          />
        </div>

        {/* Age Range */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-4">
             <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Age Range</label>
             <span className="text-white font-bold">{prefs.ageRange[0]} - {prefs.ageRange[1]}</span>
          </div>
          <div className="flex gap-4 items-center">
             <input 
                type="number" 
                value={prefs.ageRange[0]}
                onChange={(e) => handleAgeChange(0, e.target.value)}
                className="w-20 bg-slate-800 border border-slate-700 rounded-xl p-3 text-center text-white font-bold focus:border-amber-500 outline-none"
             />
             <span className="text-slate-600 font-bold">-</span>
             <input 
                type="number" 
                value={prefs.ageRange[1]}
                onChange={(e) => handleAgeChange(1, e.target.value)}
                className="w-20 bg-slate-800 border border-slate-700 rounded-xl p-3 text-center text-white font-bold focus:border-amber-500 outline-none"
             />
          </div>
        </div>

        {/* Interests */}
        <div className="mb-8">
            <div className="flex justify-between items-center mb-3">
              <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Interests</label>
              {prefs.interests.length > 0 && (
                <button onClick={() => setPrefs({...prefs, interests: []})} className="text-[10px] text-amber-500 font-bold hover:underline">Clear All</button>
              )}
            </div>
            
            <div className="flex flex-wrap gap-2 max-h-40 overflow-y-auto no-scrollbar">
              {INTEREST_OPTIONS.map(interest => {
                const isSelected = prefs.interests.includes(interest);
                return (
                  <button
                    key={interest}
                    onClick={() => toggleInterest(interest)}
                    className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-all ${
                      isSelected 
                        ? 'bg-amber-500 border-amber-500 text-black shadow-md' 
                        : 'bg-slate-800 border-slate-700 text-slate-400 hover:border-slate-500'
                    }`}
                  >
                    {interest}
                  </button>
                );
              })}
            </div>
        </div>

        <button 
          onClick={() => {
            onSave(prefs);
            onClose();
          }}
          className="w-full py-4 bg-white text-black font-bold text-lg rounded-2xl flex items-center justify-center gap-2 hover:bg-slate-200 transition-colors"
        >
          <Check size={20} />
          Apply Filters
        </button>
        
        <div className="mt-4 text-center">
           <p className="text-xs text-slate-500">
             Note: FSA Ad sequencing rules apply regardless of filter settings.
           </p>
        </div>
      </motion.div>
    </div>
  );
};