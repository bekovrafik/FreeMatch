import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Edit2, MapPin, Briefcase, Camera, Check, AlertCircle, ChevronRight, Heart, Plus, X, Mic, Trash2, BadgeCheck, Lightbulb } from 'lucide-react';
import { CURRENT_USER } from '../../constants';
import { AudioPlayer } from '../AudioPlayer';
import { VerificationModal } from '../VerificationModal';

// Popular interests to suggest
const POPULAR_INTERESTS = [
  'Coffee', 'Travel', 'Music', 'Photography', 'Art', 
  'Foodie', 'Gym', 'Yoga', 'Hiking', 'Dogs', 
  'Cats', 'Movies', 'Gaming', 'Tech', 'Fashion',
  'Cooking', 'Reading', 'Dancing', 'Sports', 'Nature'
];

interface ProfileTabProps {}

export const ProfileTab: React.FC<ProfileTabProps> = () => {
  const [isEditing, setIsEditing] = useState(false);
  const [name, setName] = useState(CURRENT_USER.name);
  const [age, setAge] = useState(CURRENT_USER.age);
  const [bio, setBio] = useState(CURRENT_USER.bio);
  const [job, setJob] = useState(CURRENT_USER.profession);
  const [location, setLocation] = useState(CURRENT_USER.location);
  const [interests, setInterests] = useState<string[]>(CURRENT_USER.interests || []);
  const [voiceIntro, setVoiceIntro] = useState<string | undefined>(CURRENT_USER.voiceIntro);
  const [isVerified, setIsVerified] = useState(CURRENT_USER.isVerified);
  const [isRecording, setIsRecording] = useState(false);
  const [showVerificationModal, setShowVerificationModal] = useState(false);

  const [completion, setCompletion] = useState(0);
  const [missingFields, setMissingFields] = useState<string[]>([]);
  const [showTip, setShowTip] = useState(true);
  
  // Local state for the profile image
  const [profileImage, setProfileImage] = useState(CURRENT_USER.imageUrls[0]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // New Interest Input State
  const [newInterest, setNewInterest] = useState('');
  const [showInterestSuggestions, setShowInterestSuggestions] = useState(false);

  // Calculate completion percentage
  useEffect(() => {
    let score = 0;
    let total = 7; // Bio, Job, Location, Image, Name, Interests, Voice
    const missing: string[] = [];

    if (bio && bio.length > 10) score++; else missing.push("Bio (min 10 chars)");
    if (job && job.length > 2) score++; else missing.push("Occupation");
    if (location) score++; else missing.push("Location");
    if (profileImage) score++; else missing.push("Profile Photo");
    if (name) score++; else missing.push("Name");
    if (interests && interests.length >= 3) score++; else missing.push("Interests (min 3)");
    if (voiceIntro) score++; else missing.push("Voice Intro");

    setCompletion(Math.round((score / total) * 100));
    setMissingFields(missing);
  }, [bio, job, location, profileImage, name, interests, voiceIntro]);

  const handleSave = () => {
      // Update global user object
      CURRENT_USER.name = name;
      CURRENT_USER.age = age;
      CURRENT_USER.bio = bio;
      CURRENT_USER.profession = job;
      CURRENT_USER.location = location;
      CURRENT_USER.interests = interests;
      CURRENT_USER.voiceIntro = voiceIntro;
      // Image is already updated on change
      
      setIsEditing(false);
  };

  const handlePhotoUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        setProfileImage(result);
        CURRENT_USER.imageUrls[0] = result;
      };
      reader.readAsDataURL(file);
    }
  };

  const triggerFileInput = () => {
    fileInputRef.current?.click();
  };

  const addInterest = (tag: string) => {
    const trimmedTag = tag.trim();
    if (!trimmedTag) return;
    
    // Capitalize first letter for display consistency
    const formattedTag = trimmedTag.charAt(0).toUpperCase() + trimmedTag.slice(1);
    
    // Case-insensitive check for duplicates
    const exists = interests.some(i => i.toLowerCase() === formattedTag.toLowerCase());

    if (!exists && interests.length < 10) {
      setInterests([...interests, formattedTag]);
    }
    setNewInterest('');
    setShowInterestSuggestions(false);
  };

  const removeInterest = (tag: string) => {
    setInterests(interests.filter(i => i !== tag));
  };
  
  const toggleRecording = () => {
    if (isRecording) {
      setIsRecording(false);
      setVoiceIntro("0:15"); // Mock saved recording
    } else {
      setIsRecording(true);
    }
  };

  const deleteRecording = () => {
    setVoiceIntro(undefined);
  };

  const getTipMessage = (field: string) => {
    if (field.includes("Bio")) return "Add a bio to let your personality shine and get more matches.";
    if (field.includes("Photo")) return "Profiles with photos get 10x more engagement.";
    if (field.includes("Interests")) return "Add at least 3 interests to find common ground with matches.";
    if (field.includes("Voice")) return "Voice intros build trust. Record one now!";
    if (field.includes("Location")) return "Add your location to find people nearby.";
    return `Complete your ${field.toLowerCase().replace(/\(.*\)/, '').trim()} to boost your visibility.`;
  };

  return (
    <div className="flex flex-col h-full bg-slate-950 overflow-y-auto pb-24">
      <div className="relative">
        {/* Cover / Profile Image */}
        <div className="h-80 relative overflow-hidden group">
          <img 
            src={profileImage} 
            alt="Profile" 
            className="w-full h-full object-cover transition-transform group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-transparent" />
          
          <button 
            onClick={triggerFileInput}
            className="absolute top-4 right-4 bg-black/50 backdrop-blur-md p-2 rounded-full text-white border border-white/20 hover:bg-black/70 transition-colors active:scale-95"
          >
            <Camera size={20} />
          </button>
          <input 
            type="file" 
            ref={fileInputRef} 
            onChange={handlePhotoUpload} 
            accept="image/*" 
            className="hidden" 
          />
        </div>

        {/* Info Card */}
        <div className="px-6 -mt-16 relative z-10">
          <div className="flex justify-between items-end mb-4">
             {isEditing ? (
                 <div className="flex gap-2 w-full pr-16">
                    <input 
                        type="text" 
                        value={name} 
                        onChange={e => setName(e.target.value)} 
                        className="flex-1 bg-slate-900/90 border border-slate-700 rounded-xl p-2 text-xl font-bold text-white focus:border-amber-500 outline-none"
                        placeholder="Name"
                    />
                    <input 
                        type="number" 
                        value={age} 
                        onChange={e => setAge(parseInt(e.target.value))} 
                        className="w-20 bg-slate-900/90 border border-slate-700 rounded-xl p-2 text-xl font-bold text-white focus:border-amber-500 outline-none"
                        placeholder="Age"
                    />
                 </div>
             ) : (
                <div className="flex flex-col">
                    <div className="flex items-center gap-2">
                        <h1 className="text-4xl font-bold text-white">{name}, {age}</h1>
                        {isVerified && (
                             <BadgeCheck size={28} className="text-blue-500 fill-blue-500/10" />
                        )}
                    </div>
                    
                    {!isVerified && !isEditing && (
                        <button 
                            onClick={() => setShowVerificationModal(true)}
                            className="mt-1 text-xs text-blue-400 font-bold flex items-center gap-1 hover:text-blue-300"
                        >
                            Get Verified <ChevronRight size={12} />
                        </button>
                    )}
                </div>
             )}
             
             <button 
               onClick={isEditing ? handleSave : () => setIsEditing(true)}
               className={`p-3 rounded-full shadow-lg transition-colors absolute right-0 bottom-1 ${
                 isEditing ? 'bg-green-500 text-white' : 'bg-amber-500 text-black'
               }`}
             >
               {isEditing ? <Check size={24} /> : <Edit2 size={24} />}
             </button>
          </div>

          {/* Profile Completion Indicator */}
          <div className="mb-8 bg-slate-900 rounded-2xl p-4 border border-slate-800 shadow-lg">
             <div className="flex justify-between items-center mb-2">
                <span className="text-sm font-bold text-slate-300">Profile Completion</span>
                <span className={`text-sm font-bold ${completion === 100 ? 'text-green-500' : 'text-amber-500'}`}>{completion}%</span>
             </div>
             <div className="w-full bg-slate-800 rounded-full h-2.5 mb-4 overflow-hidden">
                <motion.div 
                  initial={{ width: 0 }}
                  animate={{ width: `${completion}%` }}
                  transition={{ duration: 1, ease: "easeOut" }}
                  className={`h-2.5 rounded-full ${completion === 100 ? 'bg-green-500' : 'bg-gradient-to-r from-amber-500 to-orange-500'}`}
                />
             </div>
             
             {completion < 100 ? (
               <div className="bg-amber-500/10 rounded-xl p-3 border border-amber-500/20">
                 <div className="flex items-start gap-2">
                    <AlertCircle size={16} className="text-amber-500 mt-0.5" />
                    <div className="flex-1">
                      <p className="text-xs text-amber-200 font-bold mb-1">Finish your profile to get more matches!</p>
                      <ul className="text-xs text-slate-400 space-y-1">
                        {missingFields.map(field => (
                          <li key={field} className="flex items-center gap-1">
                            <span className="w-1 h-1 bg-amber-500 rounded-full" />
                            Add {field}
                          </li>
                        ))}
                      </ul>
                    </div>
                    <button 
                      onClick={() => setIsEditing(true)}
                      className="text-xs bg-amber-500 text-black font-bold px-3 py-1.5 rounded-lg flex items-center gap-1"
                    >
                      Fix <ChevronRight size={12} />
                    </button>
                 </div>
               </div>
             ) : (
               <div className="flex items-center gap-2 text-green-500 text-sm font-bold">
                 <Check size={16} />
                 All set! You're ready to shine.
               </div>
             )}

             {/* Smart Tip Banner */}
             <AnimatePresence>
                {completion < 80 && showTip && missingFields.length > 0 && (
                    <motion.div
                        initial={{ opacity: 0, height: 0, marginTop: 0 }}
                        animate={{ opacity: 1, height: 'auto', marginTop: 12 }}
                        exit={{ opacity: 0, height: 0, marginTop: 0 }}
                        className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-3 flex items-start gap-3 relative overflow-hidden"
                    >
                        <Lightbulb size={16} className="text-blue-400 mt-0.5 flex-shrink-0" />
                        <div className="flex-1 pr-4">
                            <p className="text-xs text-blue-200 font-bold mb-0.5">Pro Tip:</p>
                            <p className="text-xs text-blue-300 leading-snug">
                                {getTipMessage(missingFields[0])}
                            </p>
                        </div>
                        <button
                            onClick={() => setShowTip(false)}
                            className="absolute top-2 right-2 text-blue-400/50 hover:text-blue-300"
                        >
                            <X size={14} />
                        </button>
                    </motion.div>
                )}
             </AnimatePresence>
          </div>

          {/* Stats Row */}
          <div className="flex gap-4 mb-8">
            <div className="flex-1 bg-slate-900 rounded-2xl p-4 border border-slate-800 flex flex-col items-center justify-center">
              <span className="text-2xl font-bold text-white">85%</span>
              <span className="text-xs text-slate-500 uppercase tracking-wider">Complete</span>
            </div>
            
            {/* Matches */}
            <div className="flex-1 bg-slate-900 rounded-2xl p-4 border border-slate-800 flex flex-col items-center justify-center">
              <span className="text-2xl font-bold text-amber-500">12</span>
              <span className="text-xs text-slate-500 uppercase tracking-wider">Matches</span>
            </div>
            
            {/* Likes - Free now */}
            <div className="flex-1 bg-slate-900 rounded-2xl p-4 border border-slate-800 flex flex-col items-center justify-center relative overflow-hidden group">
              <div className="absolute inset-0 bg-pink-500/5 transition-colors" />
              <div className="flex items-center gap-1">
                 <span className="text-2xl font-bold text-pink-500">48</span>
                 <Heart size={12} className="text-pink-500 fill-pink-500" />
              </div>
              <span className="text-xs text-slate-500 uppercase tracking-wider">Likes</span>
            </div>
          </div>

          {/* Editable Fields */}
          <div className="space-y-8">
            
            {/* Voice Intro Section */}
            <div>
              <label className="text-xs font-bold text-slate-500 uppercase mb-2 block">Voice Intro</label>
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center justify-between">
                 {voiceIntro && !isRecording ? (
                   <div className="flex items-center gap-4">
                     <AudioPlayer duration={voiceIntro} barColor="bg-amber-500" />
                     {isEditing && (
                       <button onClick={deleteRecording} className="p-2 text-red-500 hover:bg-slate-800 rounded-full">
                         <Trash2 size={18} />
                       </button>
                     )}
                   </div>
                 ) : (
                   <div className="flex items-center gap-3">
                     <button 
                       onClick={isEditing ? toggleRecording : undefined}
                       className={`w-10 h-10 rounded-full flex items-center justify-center transition-all ${isRecording ? 'bg-red-500 animate-pulse' : 'bg-slate-800 text-slate-400'}`}
                     >
                       {isRecording ? <div className="w-4 h-4 bg-white rounded-sm" /> : <Mic size={20} />}
                     </button>
                     <span className="text-slate-400 text-sm font-medium">
                       {isRecording ? "Recording... Tap to stop" : (isEditing ? "Tap to record intro" : "No voice intro added")}
                     </span>
                   </div>
                 )}
              </div>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-500 uppercase mb-2 block">Occupation</label>
              {isEditing ? (
                <div className="relative">
                   <Briefcase className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                   <input 
                    type="text" 
                    value={job}
                    onChange={(e) => setJob(e.target.value)}
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl py-3 pl-10 pr-4 text-white focus:border-amber-500 outline-none"
                    placeholder="What do you do?"
                   />
                </div>
              ) : (
                <div className="flex items-center gap-2 text-slate-200 text-lg">
                  <Briefcase size={20} className="text-amber-500" />
                  {job || <span className="text-slate-500 italic">Add your occupation</span>}
                </div>
              )}
            </div>

            <div>
              <label className="text-xs font-bold text-slate-500 uppercase mb-2 block">Location</label>
              {isEditing ? (
                  <div className="relative">
                     <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                     <input 
                      type="text" 
                      value={location}
                      onChange={(e) => setLocation(e.target.value)}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl py-3 pl-10 pr-4 text-white focus:border-amber-500 outline-none"
                      placeholder="Where do you live?"
                     />
                  </div>
              ) : (
                  <div className="flex items-center gap-2 text-slate-200 text-lg opacity-60">
                    <MapPin size={20} />
                    {location}
                  </div>
              )}
            </div>

            <div>
              <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-bold text-slate-500 uppercase block">Interests</label>
                  <span className={`text-xs font-bold ${interests.length >= 10 ? 'text-amber-500' : 'text-slate-500'}`}>
                      {interests.length}/10
                  </span>
              </div>

              <div className="flex flex-wrap gap-2 mb-2">
                 {interests.map(tag => (
                   <span key={tag} className="px-4 py-2 bg-slate-800 rounded-full text-slate-300 font-medium text-sm flex items-center gap-2">
                      {tag}
                      {isEditing && (
                        <button onClick={() => removeInterest(tag)} className="text-slate-500 hover:text-white">
                          <X size={14} />
                        </button>
                      )}
                   </span>
                 ))}
                 {interests.length === 0 && !isEditing && (
                    <span className="text-slate-500 italic text-sm">No interests added yet.</span>
                 )}
              </div>
              
              {/* Tag Editor */}
              {isEditing && (
                <div className="mt-4">
                  {interests.length < 10 ? (
                    <div className="relative">
                        <Plus className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <input 
                            type="text" 
                            value={newInterest}
                            onFocus={() => setShowInterestSuggestions(true)}
                            onChange={(e) => setNewInterest(e.target.value)}
                            onKeyDown={(e) => {
                                if (e.key === 'Enter') {
                                    e.preventDefault();
                                    addInterest(newInterest);
                                }
                            }}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl py-3 pl-10 pr-4 text-white focus:border-amber-500 outline-none"
                            placeholder="Add an interest (e.g., Hiking)"
                        />
                    </div>
                  ) : (
                    <div className="p-3 bg-slate-800 rounded-xl text-slate-400 text-sm text-center border border-slate-700">
                        Maximum interests reached. Remove some to add more.
                    </div>
                  )}
                  
                  {/* Suggestions Grid */}
                  <AnimatePresence>
                    {showInterestSuggestions && interests.length < 10 && (
                       <motion.div 
                         initial={{ height: 0, opacity: 0 }}
                         animate={{ height: 'auto', opacity: 1 }}
                         exit={{ height: 0, opacity: 0 }}
                         className="mt-4 overflow-hidden"
                       >
                          <p className="text-xs font-bold text-slate-500 uppercase mb-2">Popular Tags</p>
                          <div className="flex flex-wrap gap-2">
                             {POPULAR_INTERESTS.filter(i => !interests.includes(i) && i.toLowerCase().includes(newInterest.toLowerCase())).slice(0, 8).map(tag => (
                                <button 
                                  key={tag} 
                                  onClick={() => addInterest(tag)}
                                  className="px-3 py-1.5 bg-slate-900 border border-slate-700 hover:border-amber-500 hover:text-amber-500 rounded-full text-slate-400 text-xs font-medium transition-colors"
                                >
                                  + {tag}
                                </button>
                             ))}
                          </div>
                       </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              )}
            </div>

            <div>
              <label className="text-xs font-bold text-slate-500 uppercase mb-2 block">About Me</label>
              {isEditing ? (
                <textarea 
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl p-4 text-white focus:border-amber-500 outline-none h-32 resize-none"
                  placeholder="Tell us about yourself..."
                />
              ) : (
                <p className={`text-lg leading-relaxed ${!bio ? 'text-slate-500 italic' : 'text-slate-300'}`}>
                  {bio || "Write a bio to let people know who you are."}
                </p>
              )}
            </div>
          </div>
          
          <div className="h-10" /> {/* Spacer */}
        </div>
      </div>
      
      {/* Verification Modal */}
      <AnimatePresence>
         {showVerificationModal && (
            <VerificationModal 
               onClose={() => setShowVerificationModal(false)}
               onVerified={() => {
                   setIsVerified(true);
                   // Show confetti or success toast logic if moved to App level, 
                   // but for now local state update is fine visually within the tab.
               }}
            />
         )}
      </AnimatePresence>
    </div>
  );
};