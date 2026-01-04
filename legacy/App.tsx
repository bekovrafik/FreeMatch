
import React, { useState, useEffect, useCallback } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { getCardAtIndex, testFSALogic, setFeedFilters } from './services/feedService';
import { SwipeDeck } from './components/SwipeDeck';
import { Navbar } from './components/Navbar';
import { ProfileDetailView } from './components/ProfileDetailView';
import { WelcomeScreen } from './components/screens/WelcomeScreen';
import { OnboardingScreen } from './components/screens/OnboardingScreen';
import { AuthScreen } from './components/screens/AuthScreen';
import { ChatTab } from './components/tabs/ChatTab';
import { ProfileTab } from './components/tabs/ProfileTab';
import { SettingsTab } from './components/tabs/SettingsTab';
import { MatchOverlay } from './components/MatchOverlay';
import { PreferencesModal } from './components/PreferencesModal';
import { DailyRewardModal } from './components/DailyRewardModal';
import { ToastContainer, Toast } from './components/ToastNotification';
import { CardType, CardItem, AdContent, UserProfile, ChatSession } from './types';
import { MOCK_CHATS } from './constants';
import { X, Heart, ExternalLink, RotateCw, SlidersHorizontal, Star, Flame, Crown } from 'lucide-react';

type AppState = 'WELCOME' | 'ONBOARDING' | 'AUTH' | 'MAIN_APP';
type TabState = 'HOME' | 'CHAT' | 'PROFILE' | 'SETTINGS';

interface Preferences {
  ageRange: [number, number];
  distance: number;
  gender: 'MEN' | 'WOMEN' | 'EVERYONE';
  location: string;
  interests: string[];
}

const App: React.FC = () => {
  // --- App Flow State ---
  const [appState, setAppState] = useState<AppState>('WELCOME');
  const [activeTab, setActiveTab] = useState<TabState>('HOME');

  // --- Feed State ---
  const [currentIndex, setCurrentIndex] = useState(0);
  const [history, setHistory] = useState<number[]>([]); // For Rewind
  const [currentCard, setCurrentCard] = useState<CardItem>(getCardAtIndex(0));
  const [nextCard, setNextCard] = useState<CardItem>(getCardAtIndex(1));
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [detailProfile, setDetailProfile] = useState<UserProfile | null>(null);
  
  // Animation State
  const [swipeDirection, setSwipeDirection] = useState<'left' | 'right' | 'up' | null>(null);

  // --- Persistence & Settings State ---
  const [showPreferences, setShowPreferences] = useState(false);
  const [showDailyReward, setShowDailyReward] = useState(false);
  
  // Rewards State
  const [superLikes, setSuperLikes] = useState(1); // Default 1 per day
  const [streak, setStreak] = useState(1);
  const [hasClaimedToday, setHasClaimedToday] = useState(false);

  const [blockedIds, setBlockedIds] = useState<string[]>(() => {
    const saved = localStorage.getItem('fm_blocked');
    return saved ? JSON.parse(saved) : [];
  });

  const [swipedIds, setSwipedIds] = useState<string[]>(() => {
    const saved = localStorage.getItem('fm_swiped');
    return saved ? JSON.parse(saved) : [];
  });
  
  const [preferences, setPreferences] = useState<Preferences>(() => {
    const saved = localStorage.getItem('fm_prefs');
    return saved ? JSON.parse(saved) : {
        ageRange: [18, 35],
        distance: 50,
        gender: 'EVERYONE',
        location: '',
        interests: []
    };
  });

  // --- Chat & Match State ---
  const [chats, setChats] = useState<ChatSession[]>(() => {
      const saved = localStorage.getItem('fm_chats');
      return saved ? JSON.parse(saved) : MOCK_CHATS;
  });
  const [selectedChat, setSelectedChat] = useState<ChatSession | null>(null);
  const [matchOverlayProfile, setMatchOverlayProfile] = useState<UserProfile | null>(null);
  
  // --- Toasts ---
  const [toasts, setToasts] = useState<Toast[]>([]);

  // --- Effects ---

  // Run Unit Test on Mount
  useEffect(() => {
    testFSALogic();
  }, []);
  
  // Daily Reward Logic Check on App Start
  useEffect(() => {
    if (appState === 'MAIN_APP') {
        checkDailyStreak();
    }
  }, [appState]);

  // Save Persistence
  useEffect(() => {
    localStorage.setItem('fm_chats', JSON.stringify(chats));
  }, [chats]);

  useEffect(() => {
    localStorage.setItem('fm_prefs', JSON.stringify(preferences));
  }, [preferences]);

  useEffect(() => {
    localStorage.setItem('fm_blocked', JSON.stringify(blockedIds));
  }, [blockedIds]);

  useEffect(() => {
    localStorage.setItem('fm_swiped', JSON.stringify(swipedIds));
  }, [swipedIds]);

  // Re-build the profile pool only when hard filters change.
  // We exclude 'swipedIds' and 'currentIndex' from dependencies here so that normal swiping
  // does not trigger a re-ranking of the pool, which causes the index-to-profile mapping to shift.
  useEffect(() => {
    setFeedFilters(preferences, blockedIds, swipedIds);
  }, [preferences, blockedIds]);

  // Advance the current/next card pointers only when the user swiping advances the index.
  // This ensures the next card revealed remains stable and consistent with the previous view.
  useEffect(() => {
    setCurrentCard(getCardAtIndex(currentIndex));
    setNextCard(getCardAtIndex(currentIndex + 1));
  }, [currentIndex]);

  // --- Logic ---

  const checkDailyStreak = () => {
    const lastLogin = localStorage.getItem('fm_last_login');
    const storedStreak = parseInt(localStorage.getItem('fm_streak') || '1');
    const today = new Date().toDateString();

    if (lastLogin === today) {
        // Already logged in today
        setStreak(storedStreak);
        setHasClaimedToday(true); 
        const claimed = localStorage.getItem('fm_claimed_today') === today;
        setHasClaimedToday(claimed);
        if (!claimed) {
             const timer = setTimeout(() => setShowDailyReward(true), 1500);
             return () => clearTimeout(timer);
        }
    } else {
        // New day
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        
        if (lastLogin === yesterday.toDateString()) {
            setStreak(storedStreak + 1);
            localStorage.setItem('fm_streak', (storedStreak + 1).toString());
        } else {
            setStreak(1);
            localStorage.setItem('fm_streak', '1');
        }
        
        localStorage.setItem('fm_last_login', today);
        localStorage.setItem('fm_claimed_today', 'false'); // Reset claim status
        setHasClaimedToday(false);
        setSuperLikes(1); // Reset daily free limit to 1
        
        const timer = setTimeout(() => setShowDailyReward(true), 1500);
        return () => clearTimeout(timer);
    }
  };

  const handleClaimReward = () => {
      setSuperLikes(prev => prev + 1); // Reward: Add 1 Super Like
      setHasClaimedToday(true);
      const today = new Date().toDateString();
      localStorage.setItem('fm_claimed_today', today);
      
      if (streak % 7 === 0) {
          addToast('MATCH', 'Premium Sticker Unlocked!', 'You completed the 7-day challenge!');
      } else {
          addToast('SYSTEM', 'Daily Reward', '+1 Super Like Added');
      }
  };

  const triggerHaptic = (pattern: number | number[] = 10) => {
    if (navigator.vibrate) {
      navigator.vibrate(pattern);
    }
  };

  const addToast = (type: 'MATCH' | 'MESSAGE' | 'SYSTEM', title: string, message: string, image?: string) => {
    const newToast: Toast = {
      id: Date.now().toString(),
      type,
      title,
      message,
      image
    };
    setToasts(prev => [newToast, ...prev]);
  };

  const removeToast = (id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  };

  const handleBlockUser = (profileId: string) => {
      const newBlocked = [...blockedIds, profileId];
      setBlockedIds(newBlocked);
      
      // Remove any existing chats with this user
      setChats(prev => prev.filter(c => c.user.id !== profileId));
      if (selectedChat?.user.id === profileId) setSelectedChat(null);
      
      // Close details if open
      setIsDetailOpen(false);
      setDetailProfile(null);
      
      triggerHaptic(50);
      addToast('SYSTEM', 'User Blocked', 'You won\'t see them again.');
  };

  const handleUnblockUser = (profileId: string) => {
      setBlockedIds(prev => prev.filter(id => id !== profileId));
      addToast('SYSTEM', 'User Unblocked', 'They can now appear in your feed again.');
  };

  const handleUnmatch = (chatId: string) => {
    const chat = chats.find(c => c.id === chatId);
    if (chat) {
        setChats(prev => prev.filter(c => c.id !== chatId));
        if (selectedChat?.id === chatId) setSelectedChat(null);
        addToast('SYSTEM', 'Unmatched', `You have unmatched with ${chat.user.name}.`);
        triggerHaptic(20);
    }
  };

  const handleReport = (userId: string) => {
    handleBlockUser(userId); 
    addToast('SYSTEM', 'Report Sent', 'Thank you for keeping our community safe.');
  };

  const getOrCreateChat = (profile: UserProfile): ChatSession => {
    const existing = chats.find(c => c.user.id === profile.id);
    if (existing) return existing;

    const newChat: ChatSession = {
      id: `new-${Date.now()}-${profile.id}`,
      user: profile,
      lastMessage: "You matched! Say hi 👋",
      unreadCount: 1, 
      timestamp: 'Now',
      messages: [] 
    };
    
    setChats(prev => [newChat, ...prev]);
    return newChat;
  };

  const handleMatchLiker = (profile: UserProfile) => {
     getOrCreateChat(profile);
     addToast('MATCH', "It's a Match!", `You matched with ${profile.name}`, profile.imageUrls[0]);
     triggerHaptic([50, 100, 50]);
  };

  const handleSwipe = useCallback((direction: 'left' | 'right' | 'up', card: CardItem) => {
    // Reset the programmatic swipe direction once the swipe is confirmed
    setSwipeDirection(null);

    // Check Super Like Limit
    if (direction === 'up' && card.type === CardType.PROFILE) {
        if (superLikes <= 0) {
            addToast('SYSTEM', 'Out of Super Likes', 'Come back tomorrow or claim daily rewards!');
            triggerHaptic([50, 50]);
            return; // STOP SWIPE
        }
        setSuperLikes(prev => prev - 1);
    }

    // Add current index to history for rewind
    setHistory(prev => [...prev, currentIndex]);

    // Haptic feedback for swipe
    triggerHaptic(15);

    if (card.type === CardType.PROFILE) {
      const profile = card.data as UserProfile;
      setSwipedIds(prev => [...prev, profile.id]);

      if (direction === 'up') {
        console.log(`User Swiped UP (Super Like) on Profile: ${profile.name}`);
        triggerHaptic([20, 50, 20]);
        getOrCreateChat(profile);
        addToast('MATCH', "Super Like Sent!", `Instant chat connected with ${profile.name}`, profile.imageUrls[0]);
        
      } else if (direction === 'right') {
        console.log(`User Swiped Right on Profile: ${profile.name}`);
        const isMatch = Math.random() < 0.3;
        if (isMatch) {
            getOrCreateChat(profile); 
            setTimeout(() => {
                triggerHaptic([50, 100, 50]); 
                setMatchOverlayProfile(profile);
            }, 300); 
        }
      } else {
        console.log(`User Swiped Left on Profile: ${profile.name}`);
      }
    } else if (card.type === CardType.AD) {
      const ad = card.data as AdContent;
      if (direction === 'right' || direction === 'up') {
        console.log(`User Interacted with Ad: ${ad.title}`);
        if (ad.linkUrl) {
           window.open(ad.linkUrl, '_blank');
        }
      } else {
        console.log(`User Swiped Left on Ad: ${ad.title}`);
      }
    }

    // Advance feed
    setCurrentIndex(prev => prev + 1);

  }, [chats, currentIndex, superLikes]);

  const handleRewind = () => {
    if (history.length === 0) return;
    triggerHaptic(20);
    const prevIndex = history[history.length - 1];
    setHistory(prev => prev.slice(0, -1)); // Remove last
    setCurrentIndex(prevIndex);
    
    // Reset programmatic state just in case
    setSwipeDirection(null);

    const prevCard = getCardAtIndex(prevIndex);
    if(prevCard.type === CardType.PROFILE) {
        const pId = (prevCard.data as UserProfile).id;
        setSwipedIds(prev => prev.filter(id => id !== pId));
    }
  };

  const handleCardTap = useCallback((card: CardItem) => {
    if (card.type === CardType.PROFILE) {
      setDetailProfile(card.data as UserProfile);
      setIsDetailOpen(true);
    } else {
      const ad = card.data as AdContent;
      console.log(`User Tapped Ad: ${ad.title}`);
      if (ad.linkUrl) {
        window.open(ad.linkUrl, '_blank');
      }
    }
  }, []);

  const closeDetail = () => {
    setIsDetailOpen(false);
  };

  const manualSwipe = (direction: 'left' | 'right' | 'up') => {
    // Only set the direction. The SwipeDeck will detect this, animate the card, 
    // and THEN call handleSwipe to actually change the index.
    setSwipeDirection(direction);
  };

  const resetApp = () => {
    setAppState('WELCOME');
    setCurrentIndex(0);
    setActiveTab('HOME');
    setSelectedChat(null);
    setChats(MOCK_CHATS); // Reset to defaults
    setHistory([]);
    setBlockedIds([]);
    setSwipedIds([]);
    localStorage.clear();
  };

  const handleUpdateChat = (updatedChat: ChatSession) => {
      setChats(prev => prev.map(c => c.id === updatedChat.id ? updatedChat : c));
      setSelectedChat(updatedChat);
  };

  // --- Render Helpers ---

  const FeedView = () => (
    <div className="flex flex-col h-full w-full relative pb-24">
       {/* Header - Consistent Branding */}
       <div className="h-16 flex items-center justify-between px-6 bg-slate-900 z-10 border-b border-slate-800/50 safe-area-pt">
          <div className="flex items-center gap-2">
            <Flame size={28} className="text-amber-500 fill-amber-500" />
            <h1 className="text-2xl font-extrabold tracking-tight text-white">FreeMatch</h1>
          </div>
          
          <div className="flex items-center gap-4">
             <div className="flex items-center gap-1 bg-slate-800 rounded-full px-3 py-1 border border-slate-700">
                <Star size={14} className="text-blue-500 fill-blue-500" />
                <span className="text-sm font-bold text-white">{superLikes}</span>
             </div>

            <button 
              onClick={() => setShowPreferences(true)}
              className="p-2 text-slate-400 hover:text-white transition-colors"
            >
              <SlidersHorizontal size={24} />
            </button>
          </div>
        </div>

        {/* Card Stack Area */}
        <div className="flex-1 relative w-full flex items-center justify-center p-4">
          <SwipeDeck 
              currentCard={currentCard} 
              nextCard={nextCard} 
              swipeDirection={swipeDirection}
              onSwipe={handleSwipe} 
              onCardTap={handleCardTap}
          />
        </div>

        {/* Floating Action Buttons */}
        <div className="h-24 flex items-center justify-center gap-6 z-10 pointer-events-none">
           <div className="pointer-events-auto flex items-center gap-6">
              {/* Rewind */}
              <button 
                onClick={handleRewind}
                disabled={history.length === 0}
                className={`w-12 h-12 rounded-full border border-slate-700 bg-slate-800/90 backdrop-blur shadow-lg flex items-center justify-center transition-all ${history.length === 0 ? 'text-slate-600 opacity-50' : 'text-amber-500 hover:scale-110'}`}
              >
                <RotateCw size={20} />
              </button>

              {/* Pass */}
              <button 
                onClick={() => manualSwipe('left')}
                className="w-16 h-16 rounded-full bg-slate-800/90 backdrop-blur border border-red-500/50 text-red-500 shadow-xl flex items-center justify-center hover:scale-110 hover:bg-red-500 hover:text-white transition-all"
              >
                <X size={32} strokeWidth={2.5} />
              </button>
              
              {/* Like */}
              <button 
                onClick={() => manualSwipe('right')}
                className={`w-16 h-16 rounded-full shadow-xl flex items-center justify-center hover:scale-110 transition-all ${
                  currentCard.type === CardType.AD 
                    ? 'bg-amber-500 text-black border-amber-500 hover:bg-amber-400' 
                    : 'bg-gradient-to-tr from-cyan-500 to-blue-600 text-white border-blue-500 hover:shadow-cyan-500/50'
                }`}
              >
                {currentCard.type === CardType.AD ? (
                  <ExternalLink size={28} strokeWidth={2.5} />
                ) : (
                  <Heart size={32} strokeWidth={2.5} fill={currentCard.type === CardType.PROFILE ? 'currentColor' : 'none'} className={currentCard.type === CardType.PROFILE ? 'text-white' : ''} />
                )}
              </button>

               {/* Super Like */}
               <button 
                onClick={() => manualSwipe('up')}
                className={`w-12 h-12 rounded-full border border-blue-500/50 bg-slate-800/90 backdrop-blur text-blue-500 shadow-lg flex items-center justify-center hover:scale-110 hover:bg-blue-500 hover:text-white transition-all ${superLikes === 0 ? 'opacity-50' : ''}`}
              >
                <Star size={20} fill="currentColor" />
              </button>
           </div>
        </div>
    </div>
  );

  const renderContent = () => {
    switch (appState) {
      case 'WELCOME':
        return <WelcomeScreen onStart={() => setAppState('ONBOARDING')} />;
      case 'ONBOARDING':
        return <OnboardingScreen onComplete={() => setAppState('AUTH')} />;
      case 'AUTH':
        return <AuthScreen onAuthenticated={() => setAppState('MAIN_APP')} />;
      case 'MAIN_APP':
        return (
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }} 
            className="flex flex-col h-full w-full"
          >
             <ToastContainer toasts={toasts} onDismiss={removeToast} />

            <div className="flex-1 relative w-full overflow-hidden">
               {activeTab === 'HOME' && <FeedView />}
               
               {activeTab === 'CHAT' && (
                 <ChatTab 
                    chats={chats}
                    selectedChat={selectedChat} 
                    onSelectChat={setSelectedChat} 
                    onUpdateChat={handleUpdateChat}
                    onViewProfile={(profile) => {
                       setDetailProfile(profile);
                       setIsDetailOpen(true);
                    }}
                    onUnmatch={handleUnmatch}
                    onReport={handleReport}
                    onBlock={handleBlockUser}
                    onMatchLiker={handleMatchLiker}
                 />
               )}
               
               {activeTab === 'PROFILE' && <ProfileTab />}
               {activeTab === 'SETTINGS' && (
                 <SettingsTab 
                   blockedIds={blockedIds}
                   onUnblock={handleUnblockUser}
                   onLogout={resetApp} 
                   onDeleteAccount={resetApp} 
                 />
               )}
            </div>

            <Navbar activeTab={activeTab} onTabChange={setActiveTab} />

            <AnimatePresence>
              {isDetailOpen && detailProfile && (
                <ProfileDetailView 
                  profile={detailProfile} 
                  onClose={closeDetail}
                  onBlockUser={handleBlockUser}
                />
              )}
            </AnimatePresence>

             <AnimatePresence>
                {matchOverlayProfile && (
                    <MatchOverlay 
                        matchedProfile={matchOverlayProfile}
                        onKeepSwiping={() => setMatchOverlayProfile(null)}
                        onSendMessage={() => {
                            const chat = getOrCreateChat(matchOverlayProfile);
                            setSelectedChat(chat);
                            setMatchOverlayProfile(null);
                            setActiveTab('CHAT');
                        }}
                    />
                )}
             </AnimatePresence>

             <AnimatePresence>
               {showPreferences && (
                 <PreferencesModal 
                   currentPrefs={preferences}
                   onSave={setPreferences}
                   onClose={() => setShowPreferences(false)}
                 />
               )}
             </AnimatePresence>

             <AnimatePresence>
               {showDailyReward && (
                 <DailyRewardModal 
                   streak={streak}
                   onClaim={handleClaimReward}
                   onClose={() => setShowDailyReward(false)}
                 />
               )}
             </AnimatePresence>

          </motion.div>
        );
    }
  };

  return (
    <div className="flex justify-center items-center min-h-screen bg-slate-950 text-white font-sans overflow-hidden">
      <div className="w-full max-w-md h-[100dvh] flex flex-col bg-slate-900 shadow-2xl relative overflow-hidden">
        {renderContent()}
      </div>
    </div>
  );
};

export default App;
