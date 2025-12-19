import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Shield, LifeBuoy, LogOut, Trash2, ChevronLeft, Send, CheckCircle, ShieldOff, UserX, Ghost } from 'lucide-react';
import { MOCK_PROFILES } from '../../constants';

interface Props {
  blockedIds: string[];
  onUnblock: (id: string) => void;
  onLogout: () => void;
  onDeleteAccount: () => void;
}

type SettingsView = 'MAIN' | 'PRIVACY' | 'SUPPORT' | 'BLOCKED';

export const SettingsTab: React.FC<Props> = ({ blockedIds, onUnblock, onLogout, onDeleteAccount }) => {
  const [currentView, setCurrentView] = useState<SettingsView>('MAIN');

  return (
    <div className="flex flex-col h-full bg-slate-950 relative overflow-hidden">
      {/* Main Settings - Always rendered in background */}
      <MainSettings 
        onNavigate={setCurrentView} 
        onLogout={onLogout} 
        onDeleteAccount={onDeleteAccount} 
      />

      {/* Sub-pages - Overlay on top with slide-in animation */}
      <AnimatePresence>
        {currentView === 'PRIVACY' && (
          <PrivacyView key="privacy" onBack={() => setCurrentView('MAIN')} />
        )}
        {currentView === 'SUPPORT' && (
          <SupportView key="support" onBack={() => setCurrentView('MAIN')} />
        )}
        {currentView === 'BLOCKED' && (
          <BlockedUsersView 
            key="blocked" 
            blockedIds={blockedIds}
            onUnblock={onUnblock}
            onBack={() => setCurrentView('MAIN')} 
          />
        )}
      </AnimatePresence>
    </div>
  );
};

const MainSettings: React.FC<{ 
  onNavigate: (view: SettingsView) => void, 
  onLogout: () => void,
  onDeleteAccount: () => void 
}> = ({ onNavigate, onLogout, onDeleteAccount }) => {
  
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  return (
    <div className="flex flex-col h-full p-4 overflow-y-auto pb-24">
      <h1 className="text-3xl font-bold text-white mb-8 mt-4 px-2">Settings</h1>

      <div className="space-y-4">
        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest px-2">General</h3>
        
        <button 
          onClick={() => onNavigate('PRIVACY')}
          className="w-full bg-slate-900 p-4 rounded-2xl flex items-center justify-between group hover:bg-slate-800 transition-colors"
        >
          <div className="flex items-center gap-4">
            <div className="p-2 bg-blue-500/20 rounded-xl text-blue-400">
              <Shield size={24} />
            </div>
            <span className="font-medium text-lg text-white">Privacy Policy</span>
          </div>
          <ChevronRight className="text-slate-600 group-hover:text-white" />
        </button>

        <button 
          onClick={() => onNavigate('BLOCKED')}
          className="w-full bg-slate-900 p-4 rounded-2xl flex items-center justify-between group hover:bg-slate-800 transition-colors"
        >
          <div className="flex items-center gap-4">
            <div className="p-2 bg-slate-700/50 rounded-xl text-slate-300">
              <ShieldOff size={24} />
            </div>
            <span className="font-medium text-lg text-white">Blocked Users</span>
          </div>
          <ChevronRight className="text-slate-600 group-hover:text-white" />
        </button>

        <button 
          onClick={() => onNavigate('SUPPORT')}
          className="w-full bg-slate-900 p-4 rounded-2xl flex items-center justify-between group hover:bg-slate-800 transition-colors"
        >
          <div className="flex items-center gap-4">
            <div className="p-2 bg-green-500/20 rounded-xl text-green-400">
              <LifeBuoy size={24} />
            </div>
            <span className="font-medium text-lg text-white">Contact Support</span>
          </div>
          <ChevronRight className="text-slate-600 group-hover:text-white" />
        </button>
      </div>

      <div className="mt-8 space-y-4">
        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest px-2">Account</h3>
        
        <button 
          onClick={onLogout}
          className="w-full bg-slate-900 p-4 rounded-2xl flex items-center gap-4 group hover:bg-slate-800 transition-colors"
        >
          <div className="p-2 bg-slate-700/50 rounded-xl text-slate-300">
            <LogOut size={24} />
          </div>
          <span className="font-medium text-lg text-white">Log Out</span>
        </button>

        {!showDeleteConfirm ? (
          <button 
            onClick={() => setShowDeleteConfirm(true)}
            className="w-full bg-slate-900 p-4 rounded-2xl flex items-center gap-4 group hover:bg-red-900/20 transition-colors"
          >
            <div className="p-2 bg-red-500/20 rounded-xl text-red-500">
              <Trash2 size={24} />
            </div>
            <span className="font-medium text-lg text-red-500">Delete Account</span>
          </button>
        ) : (
          <motion.div 
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            className="bg-red-900/10 border border-red-900/30 p-4 rounded-2xl"
          >
            <p className="text-red-200 text-sm mb-4">
              Are you sure? This action is permanent and cannot be undone. All matches and chats will be lost.
            </p>
            <div className="flex gap-3">
              <button 
                onClick={() => setShowDeleteConfirm(false)}
                className="flex-1 py-2 bg-slate-800 rounded-xl text-white font-medium"
              >
                Cancel
              </button>
              <button 
                onClick={onDeleteAccount}
                className="flex-1 py-2 bg-red-600 rounded-xl text-white font-bold hover:bg-red-500"
              >
                Yes, Delete
              </button>
            </div>
          </motion.div>
        )}
      </div>
      
      <div className="mt-auto py-8 text-center">
         <p className="text-slate-600 text-sm">FreeMatch v1.0.0</p>
      </div>
    </div>
  );
};

const BlockedUsersView: React.FC<{ blockedIds: string[], onUnblock: (id: string) => void, onBack: () => void }> = ({ blockedIds, onUnblock, onBack }) => {
  const blockedProfiles = MOCK_PROFILES.filter(p => blockedIds.includes(p.id));

  return (
    <motion.div 
      initial={{ x: '100%' }}
      animate={{ x: 0 }}
      exit={{ x: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-slate-950 absolute inset-0 z-20 shadow-[-10px_0_30px_rgba(0,0,0,0.5)]"
    >
      <div className="flex items-center gap-2 p-4 border-b border-slate-800 bg-slate-900/80 backdrop-blur-md sticky top-0 z-10">
        <button onClick={onBack} className="p-2 -ml-2 text-slate-400 hover:text-white">
          <ChevronLeft size={28} />
        </button>
        <h2 className="text-xl font-bold text-white">Blocked Users</h2>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {blockedProfiles.length > 0 ? (
          blockedProfiles.map(profile => (
            <div key={profile.id} className="flex items-center justify-between p-4 bg-slate-900 rounded-2xl border border-slate-800">
               <div className="flex items-center gap-3">
                  <img src={profile.imageUrls[0]} className="w-12 h-12 rounded-full object-cover grayscale" alt="" />
                  <div>
                    <h3 className="font-bold text-white">{profile.name}, {profile.age}</h3>
                    <p className="text-xs text-slate-500">{profile.location}</p>
                  </div>
               </div>
               <button 
                onClick={() => onUnblock(profile.id)}
                className="px-4 py-2 bg-slate-800 rounded-xl text-xs font-bold text-blue-400 hover:bg-slate-700 transition-colors"
               >
                 Unblock
               </button>
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center h-full text-center p-8 opacity-40">
             <Ghost size={48} className="mb-4" />
             <p className="text-lg font-bold">No blocked users</p>
             <p className="text-sm">Users you block will appear here.</p>
          </div>
        )}
      </div>
    </motion.div>
  );
}

const PrivacyView: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  return (
    <motion.div 
      initial={{ x: '100%' }}
      animate={{ x: 0 }}
      exit={{ x: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-slate-950 absolute inset-0 z-20 shadow-[-10px_0_30px_rgba(0,0,0,0.5)]"
    >
      <div className="flex items-center gap-2 p-4 border-b border-slate-800 bg-slate-900/80 backdrop-blur-md sticky top-0 z-10">
        <button onClick={onBack} className="p-2 -ml-2 text-slate-400 hover:text-white">
          <ChevronLeft size={28} />
        </button>
        <h2 className="text-xl font-bold text-white">Privacy Policy</h2>
      </div>
      <div className="flex-1 overflow-y-auto p-6 text-slate-300 leading-relaxed pb-24 space-y-8">
        
        <div>
            <p className="mb-4 text-sm text-slate-400">Last updated: October 26, 2023</p>
            <p className="mb-4">Welcome to FreeMatch. Your privacy is at the core of the way we design and build the services and products you know and love.</p>
        </div>

        <section>
            <h3 className="text-lg font-bold text-white mb-3">1. Information We Collect</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-slate-400">
                <li><strong className="text-slate-200">Registration Information:</strong> When you create an account, we collect your name, email address, date of birth, gender, and password.</li>
                <li><strong className="text-slate-200">Profile Information:</strong> We collect photos, bio, interests, job title, and other details you choose to add to your profile.</li>
                <li><strong className="text-slate-200">Geolocation Data:</strong> To match you with people nearby, we collect your precise device location (latitude/longitude) with your consent.</li>
                <li><strong className="text-slate-200">Device Information:</strong> We collect information about the device you use to access FreeMatch, including hardware model, operating system, and unique device identifiers.</li>
            </ul>
        </section>

        <section>
            <h3 className="text-lg font-bold text-white mb-3">2. How We Use Your Information</h3>
            <p className="mb-3 text-sm">We use your data to:</p>
            <ul className="list-disc pl-5 space-y-2 text-sm text-slate-400">
                <li>Create and manage your account.</li>
                <li>Suggest potential matches based on your location and preferences.</li>
                <li>Enable communication between users (chat, voice).</li>
                <li>Show relevant ads to keep the service free.</li>
                <li>Detect and prevent fraud, spam, and abuse.</li>
            </ul>
        </section>

        <section>
            <h3 className="text-lg font-bold text-white mb-3">3. Data Sharing & Disclosure</h3>
            <p className="mb-3 text-sm">We do not sell your personal data. We share information only in the following circumstances:</p>
            <ul className="list-disc pl-5 space-y-2 text-sm text-slate-400">
                <li><strong className="text-slate-200">With Other Users:</strong> Your public profile data is visible to other users of the service.</li>
                <li><strong className="text-slate-200">Service Providers:</strong> We use third parties for hosting, analytics, and customer support.</li>
                <li><strong className="text-slate-200">Advertising Partners:</strong> We may share hashed/anonymized device identifiers with ad networks to deliver relevant advertising (FSA Ad System).</li>
                <li><strong className="text-slate-200">Legal Requirements:</strong> We may disclose data if required by law or to protect our rights.</li>
            </ul>
        </section>

        <section>
            <h3 className="text-lg font-bold text-white mb-3">4. Age Restriction</h3>
            <p className="text-sm text-slate-400">
                FreeMatch is strictly for users who are 18 years of age or older. We do not knowingly collect data from minors. If we discover that a user is under 18, we will immediately delete their account.
            </p>
        </section>

        <section>
            <h3 className="text-lg font-bold text-white mb-3">5. Your Rights</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-slate-400">
                <li><strong className="text-slate-200">Access & Update:</strong> You can access and update your profile information directly within the app.</li>
                <li><strong className="text-slate-200">Delete Account:</strong> You can delete your account at any time via the Settings menu. This is a permanent action.</li>
                <li><strong className="text-slate-200">Device Permissions:</strong> You can revoke permission for geolocation or notifications in your device settings.</li>
            </ul>
        </section>

        <section>
            <h3 className="text-lg font-bold text-white mb-3">6. Data Security</h3>
            <p className="text-sm text-slate-400">
                We implement robust security measures to protect your personal information from unauthorized access, alteration, or disclosure. However, no internet transmission is completely secure, and we cannot guarantee absolute security.
            </p>
        </section>

        <div className="pt-8 border-t border-slate-800">
            <p className="text-xs text-slate-500 text-center">
                If you have questions about this policy, please contact our Data Protection Officer at privacy@freematch.app.
            </p>
        </div>
      </div>
    </motion.div>
  );
};

const SupportView: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    setTimeout(() => {
       onBack();
    }, 2000);
  };

  return (
    <motion.div 
      initial={{ x: '100%' }}
      animate={{ x: 0 }}
      exit={{ x: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-slate-950 absolute inset-0 z-20 shadow-[-10px_0_30px_rgba(0,0,0,0.5)]"
    >
      <div className="flex items-center gap-2 p-4 border-b border-slate-800 bg-slate-900/80 backdrop-blur-md sticky top-0 z-10">
        <button onClick={onBack} className="p-2 -ml-2 text-slate-400 hover:text-white">
          <ChevronLeft size={28} />
        </button>
        <h2 className="text-xl font-bold text-white">Contact Support</h2>
      </div>

      {!submitted ? (
        <form onSubmit={handleSubmit} className="flex-1 p-6 flex flex-col gap-6 overflow-y-auto pb-24">
          <p className="text-slate-400">Having trouble? Send us a message and we'll get back to you within 24 hours.</p>
          
          <div className="space-y-2">
            <label className="text-sm font-bold text-slate-300">Subject</label>
            <select className="w-full bg-slate-900 border border-slate-700 rounded-xl p-4 text-white outline-none focus:border-amber-500">
              <option>Report a Bug</option>
              <option>Account Issue</option>
              <option>Billing / Ads</option>
              <option>Other</option>
            </select>
          </div>

          <div className="space-y-2 flex-1 flex flex-col min-h-[120px]">
            <label className="text-sm font-bold text-slate-300">Message</label>
            <textarea 
              required
              className="w-full flex-1 bg-slate-900 border border-slate-700 rounded-xl p-4 text-white outline-none focus:border-amber-500 resize-none"
              placeholder="Describe your issue..."
            />
          </div>

          <button className="w-full py-4 bg-amber-500 hover:bg-amber-400 text-black font-bold rounded-2xl flex items-center justify-center gap-2 transition-colors">
            <Send size={20} />
            Send Message
          </button>
        </form>
      ) : (
        <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
           <motion.div 
             initial={{ scale: 0 }}
             animate={{ scale: 1 }}
             className="w-20 h-20 bg-green-500 rounded-full flex items-center justify-center mb-6"
           >
             <CheckCircle size={40} className="text-black" />
           </motion.div>
           <h3 className="text-2xl font-bold text-white mb-2">Message Sent!</h3>
           <p className="text-slate-400">Thanks for reaching out. We'll be in touch shortly.</p>
        </div>
      )}
    </motion.div>
  );
};