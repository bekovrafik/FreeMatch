import React, { useState, useMemo, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, Send, Search, MoreVertical, MessageSquarePlus, Smile, Gift, Heart, AlertTriangle, UserX, Check, X, Clapperboard, ShieldOff } from 'lucide-react';
import { ChatSession, Message, UserProfile } from '../../types';
import { MOCK_PROFILES } from '../../constants';

// --- Constants for Rich Messaging ---
const EMOJIS = [
  '😀', '😂', '😍', '🥺', '😎', '🔥', '❤️', '🍆', '🍑', '🍻', '👋', '👀',
  '😭', '🥳', '🥰', '🤪', '🤩', '😡', '😱', '🤢', '🤮', '🤧', '😵', '🤯',
  '🤠', '🤡', '👻', '💀', '👽', '👾', '🤖', '🎃', '😺', '😸', '😹', '😻',
  '🤲', '👐', '🙌', '👏', '🤝', '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞',
  '💋', '👄', '👅', '👂', '👃', '🦶', '🦵', '🧠', '🦷', '🦴', '👀', '👁️',
  '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🍑',
  '🍔', '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🥙', '🍳', '🥘', '🍲', '🥣',
  '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓', '🏸',
  '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚', '🚛',
  '🏳️', '🏴', '🏁', '🚩', '🏳️‍🌈', '🏴‍☠️', '🇦🇫', '🇦🇽', '🇦🇱', '🇩🇿', '🇦🇸', '🇦🇩'
];

// Unique Free Charms / Gifts
const GIFTS = [
  { url: 'https://cdn-icons-png.flaticon.com/512/2935/2935413.png', name: 'Coffee' },
  { url: 'https://cdn-icons-png.flaticon.com/512/1404/1404945.png', name: 'Pizza' },
  { url: 'https://cdn-icons-png.flaticon.com/512/742/742751.png', name: 'Rose' },
  { url: 'https://cdn-icons-png.flaticon.com/512/4710/4710922.png', name: 'Teddy' },
  { url: 'https://cdn-icons-png.flaticon.com/512/1139/1139982.png', name: 'Party' },
  { url: 'https://cdn-icons-png.flaticon.com/512/3112/3112946.png', name: 'Trophy' },
  { url: 'https://cdn-icons-png.flaticon.com/512/938/938063.png', name: 'Ice Cream' },
  { url: 'https://cdn-icons-png.flaticon.com/512/869/869869.png', name: 'Sun' },
  { url: 'https://cdn-icons-png.flaticon.com/512/1076/1076928.png', name: 'Ring' },
  { url: 'https://cdn-icons-png.flaticon.com/512/725/725105.png', name: 'Airplane' },
  { url: 'https://cdn-icons-png.flaticon.com/512/2651/2651004.png', name: 'Bouquet' },
  { url: 'https://cdn-icons-png.flaticon.com/512/2555/2555135.png', name: 'Ride' },
];

// Simulated Giphy Results
const MOCK_GIFS = [
  { id: 'g1', url: 'https://media.giphy.com/media/l0HlHFRbmaZtBRhXG/giphy.gif', tags: 'happy dance excited' },
  { id: 'g2', url: 'https://media.giphy.com/media/26BRv0ThflsHCqDrG/giphy.gif', tags: 'hello hi wave' },
  { id: 'g3', url: 'https://media.giphy.com/media/l2JdZO8X4Q2X3y7Di/giphy.gif', tags: 'love heart romance' },
  { id: 'g4', url: 'https://media.giphy.com/media/3o7TKoWXm3okO1kgHC/giphy.gif', tags: 'funny laugh lol' },
  { id: 'g5', url: 'https://media.giphy.com/media/xT5LMB2WiOdjpB7K4o/giphy.gif', tags: 'yes agree nod' },
  { id: 'g6', url: 'https://media.giphy.com/media/3o6Zt6KHxJTbXCnSvu/giphy.gif', tags: 'no nope shake' },
  { id: 'g7', url: 'https://media.giphy.com/media/l41lI4bYmcsPJX9Go/giphy.gif', tags: 'sad cry tears' },
  { id: 'g8', url: 'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif', tags: 'angry mad rage' },
  { id: 'g9', url: 'https://media.giphy.com/media/xT8qB7Sbwskk27Rdy8/giphy.gif', tags: 'confused huh what' },
  { id: 'g10', url: 'https://media.giphy.com/media/3o7qDSOvfaCO9b3MlO/giphy.gif', tags: 'party celebrate' },
  { id: 'g11', url: 'https://media.giphy.com/media/l0HlO3BJ8LALPW4sE/giphy.gif', tags: 'cat kitty cute' },
  { id: 'g12', url: 'https://media.giphy.com/media/l0HlMw7YwwITohZks/giphy.gif', tags: 'dog puppy cute' },
];

interface ChatTabProps {
  chats: ChatSession[];
  selectedChat: ChatSession | null;
  onSelectChat: (chat: ChatSession | null) => void;
  onUpdateChat: (updatedChat: ChatSession) => void;
  onViewProfile: (profile: UserProfile) => void;
  onUnmatch: (chatId: string) => void;
  onReport: (userId: string) => void;
  onBlock: (userId: string) => void;
  onMatchLiker: (profile: UserProfile) => void;
}

export const ChatTab: React.FC<ChatTabProps> = ({ 
  chats, 
  selectedChat, 
  onSelectChat, 
  onUpdateChat,
  onViewProfile,
  onUnmatch,
  onReport,
  onBlock,
  onMatchLiker
}) => {
  return (
    <div className="flex flex-col h-full bg-slate-950 relative overflow-hidden">
      {/* 
        Stack Navigation Pattern:
        The List is always rendered at z-0.
        The Detail view slides in at z-50.
      */}
      
      <ChatList 
        chats={chats}
        onSelect={onSelectChat} 
        onMatchLiker={onMatchLiker}
      />

      <AnimatePresence>
        {selectedChat && (
          <ChatDetail 
            key="chat-detail" 
            chat={selectedChat} 
            onBack={() => onSelectChat(null)} 
            onUpdate={onUpdateChat}
            onViewProfile={onViewProfile}
            onUnmatch={onUnmatch}
            onReport={onReport}
            onBlock={onBlock}
          />
        )}
      </AnimatePresence>
    </div>
  );
};

const ChatList: React.FC<{ 
  chats: ChatSession[], 
  onSelect: (chat: ChatSession) => void,
  onMatchLiker: (profile: UserProfile) => void
}> = ({ chats, onSelect, onMatchLiker }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLiker, setSelectedLiker] = useState<UserProfile | null>(null);

  const likers = useMemo(() => {
    const chatUserIds = chats.map(c => c.user.id);
    return MOCK_PROFILES.filter(p => !chatUserIds.includes(p.id)).slice(0, 5);
  }, [chats]);

  const { newMatches, conversations } = useMemo(() => {
    const matches = [];
    const convos = [];
    for (const chat of chats) {
      if (searchQuery && !chat.user.name.toLowerCase().includes(searchQuery.toLowerCase())) continue;
      if (chat.messages.length === 0) matches.push(chat);
      else convos.push(chat);
    }
    return { newMatches: matches, conversations: convos };
  }, [chats, searchQuery]);

  return (
    <div className="flex flex-col h-full relative w-full bg-slate-950">
      {/* Header */}
      <div className="p-4 bg-slate-900 border-b border-slate-800 space-y-4">
        <h1 className="text-2xl font-bold text-white">Matches</h1>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
          <input 
            type="text" 
            placeholder="Search matches..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-800 border-none rounded-xl py-3 pl-10 pr-4 text-white placeholder-slate-500 focus:ring-2 focus:ring-amber-500 outline-none transition-all"
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar pb-24">
        {/* Likes You Section */}
        {!searchQuery && likers.length > 0 && (
          <div className="py-4 pl-4 border-b border-slate-800/50">
             <h3 className="text-xs font-bold text-pink-500 uppercase tracking-widest mb-3 flex items-center gap-2">
                <Heart size={12} fill="currentColor" />
                Likes You ({likers.length})
             </h3>
             <div className="flex gap-4 overflow-x-auto pb-2 no-scrollbar pr-4 whitespace-nowrap">
                {likers.map((liker, idx) => (
                  <button 
                    key={liker.id}
                    onClick={() => setSelectedLiker(liker)}
                    className="relative inline-flex flex-col items-center gap-2 group min-w-[5rem]"
                  >
                    <div className="w-20 h-20 rounded-2xl overflow-hidden border-2 border-pink-500/30 relative flex-shrink-0">
                       <img src={liker.imageUrls[0]} className="w-full h-full object-cover blur-md" alt="" />
                       <div className="absolute inset-0 bg-black/20" />
                       <div className="absolute inset-0 flex items-center justify-center">
                          <Heart size={24} className="text-pink-500 drop-shadow-md" fill="currentColor" />
                       </div>
                    </div>
                    <div className="text-center">
                       <p className="text-xs font-bold text-white leading-tight">{liker.name}</p>
                       <p className="text-[10px] text-slate-400">{liker.age}</p>
                    </div>
                  </button>
                ))}
             </div>
          </div>
        )}

        {/* New Matches Row */}
        {!searchQuery && newMatches.length > 0 && (
          <div className="py-4 pl-4 border-b border-slate-800/50">
            <h3 className="text-xs font-bold text-amber-500 uppercase tracking-widest mb-3">New Matches</h3>
            <div className="flex gap-4 overflow-x-auto pb-2 no-scrollbar pr-4 whitespace-nowrap">
              {newMatches.map(match => (
                <button 
                  key={match.id}
                  onClick={() => onSelect(match)}
                  className="inline-flex flex-col items-center space-y-1 min-w-[4.5rem]"
                >
                  <div className="w-16 h-16 rounded-full p-0.5 bg-gradient-to-tr from-amber-400 to-pink-600 relative flex-shrink-0">
                     <img 
                      src={match.user.imageUrls[0]} 
                      alt={match.user.name} 
                      className="w-full h-full rounded-full object-cover border-2 border-slate-900"
                    />
                    {match.unreadCount > 0 && <div className="absolute top-0 right-0 w-4 h-4 bg-amber-500 rounded-full border-2 border-slate-900" />}
                  </div>
                  <span className="text-xs font-bold text-white truncate w-full text-center">{match.user.name}</span>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Messages List */}
        <div className="">
           {!searchQuery && <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest mt-4 mb-2 px-4">Messages</h3>}
           
           {conversations.length > 0 ? (
            conversations.map((chat) => (
              <button
                key={chat.id}
                onClick={() => onSelect(chat)}
                className="w-full flex items-center gap-4 p-4 hover:bg-slate-900 transition-colors border-b border-slate-800/50"
              >
                <div className="relative">
                  <img src={chat.user.imageUrls[0]} alt={chat.user.name} className="w-14 h-14 rounded-full object-cover border border-slate-700" />
                  {chat.unreadCount > 0 && (
                    <div className="absolute -top-1 -right-1 w-5 h-5 bg-pink-500 rounded-full border-2 border-slate-950 flex items-center justify-center">
                      <span className="text-[10px] font-bold text-white">{chat.unreadCount}</span>
                    </div>
                  )}
                </div>
                
                <div className="flex-1 text-left">
                  <div className="flex items-center justify-between mb-1">
                    <h3 className="font-bold text-white text-lg">{chat.user.name}</h3>
                    <span className="text-xs text-slate-500 font-medium">{chat.timestamp}</span>
                  </div>
                  <p className={`text-sm truncate ${chat.unreadCount > 0 ? 'text-white font-medium' : 'text-slate-400'}`}>
                    {chat.lastMessage}
                  </p>
                </div>
              </button>
            ))
           ) : (
             (searchQuery || newMatches.length === 0) && (
                <div className="flex flex-col items-center justify-center h-48 text-slate-500">
                  <div className="w-16 h-16 bg-slate-900 rounded-full flex items-center justify-center mb-4 text-slate-600">
                     <MessageSquarePlus size={32} />
                  </div>
                  <p>No conversations yet.</p>
                  <p className="text-sm">Get swiping to find a match!</p>
                </div>
             )
           )}
        </div>
      </div>

      {/* Liker Reveal Modal */}
      <AnimatePresence>
        {selectedLiker && (
          <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-6">
             <motion.div 
               initial={{ scale: 0.8, opacity: 0 }}
               animate={{ scale: 1, opacity: 1 }}
               exit={{ scale: 0.8, opacity: 0 }}
               className="bg-slate-900 rounded-3xl w-full max-w-xs overflow-hidden border border-slate-700 shadow-2xl relative"
             >
                <button 
                  onClick={() => setSelectedLiker(null)}
                  className="absolute top-4 right-4 z-10 bg-black/30 rounded-full p-2 text-white hover:bg-black/50"
                >
                  <X size={20} />
                </button>
                <div className="h-64 relative">
                   <img src={selectedLiker.imageUrls[0]} className="w-full h-full object-cover blur-xl" alt="" />
                   <div className="absolute inset-0 flex flex-col items-center justify-center p-4 text-center">
                      <div className="w-20 h-20 rounded-full bg-gradient-to-tr from-pink-500 to-amber-500 flex items-center justify-center mb-4 shadow-lg shadow-pink-500/30">
                        <Heart size={40} className="text-white animate-pulse" fill="currentColor" />
                      </div>
                      <h3 className="text-2xl font-bold text-white">Someone likes you!</h3>
                      <p className="text-slate-300 text-sm mt-2">
                        {selectedLiker.name} is {selectedLiker.age} and lives nearby. Match to reveal them.
                      </p>
                   </div>
                </div>
                <div className="p-6 flex gap-3">
                   <button 
                     onClick={() => setSelectedLiker(null)}
                     className="flex-1 py-3 rounded-xl bg-slate-800 text-red-500 font-bold hover:bg-slate-700 transition-colors"
                   >
                     Pass
                   </button>
                   <button 
                     onClick={() => {
                        onMatchLiker(selectedLiker);
                        setSelectedLiker(null);
                     }}
                     className="flex-1 py-3 rounded-xl bg-gradient-to-r from-pink-500 to-amber-500 text-white font-bold hover:shadow-lg transition-shadow"
                   >
                     Match
                   </button>
                </div>
             </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

interface ChatDetailProps {
    chat: ChatSession; 
    onBack: () => void;
    onUpdate: (c: ChatSession) => void;
    onViewProfile: (p: UserProfile) => void;
    onUnmatch: (id: string) => void;
    onReport: (id: string) => void;
    onBlock: (id: string) => void;
}

const ChatDetail: React.FC<ChatDetailProps> = ({ chat, onBack, onUpdate, onViewProfile, onUnmatch, onReport, onBlock }) => {
  const [inputText, setInputText] = useState('');
  const [showEmoji, setShowEmoji] = useState(false);
  const [showGift, setShowGift] = useState(false);
  const [showGif, setShowGif] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [gifSearch, setGifSearch] = useState('');
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [chat.messages, showEmoji, showGift, showGif]);

  useEffect(() => {
    if (chat.unreadCount > 0) onUpdate({ ...chat, unreadCount: 0 });
  }, []);

  const handleSend = (text: string, type: 'TEXT' | 'GIFT' | 'GIF' = 'TEXT', mediaUrl?: string) => {
    if (!text && !mediaUrl) return;

    const userMsg: Message = {
      id: Date.now().toString(),
      text: text,
      timestamp: 'Just now',
      isMe: true,
      type,
      mediaUrl
    };

    const updatedMessages = [...chat.messages, userMsg];
    
    onUpdate({
      ...chat,
      messages: updatedMessages,
      lastMessage: type === 'TEXT' ? text : `[${type}]`,
      timestamp: 'Now',
      unreadCount: 0
    });
    
    setInputText('');
    setShowEmoji(false);
    setShowGift(false);
    setShowGif(false);

    setTimeout(() => {
      const replies = [
         "That's awesome! 😍",
         "Haha, tell me more!",
         "I was thinking the same thing.",
         "So, what do you do for fun?",
         "Loved that! ❤️"
      ];
      const botMsg: Message = {
         id: (Date.now() + 1).toString(),
         text: replies[Math.floor(Math.random() * replies.length)],
         timestamp: 'Just now',
         isMe: false
      };

      onUpdate({
        ...chat,
        messages: [...updatedMessages, botMsg],
        lastMessage: botMsg.text,
        timestamp: 'Now',
        unreadCount: 0
      });
    }, 2000);
  };

  const handleDoubleTap = (msgId: string) => {
     const updatedMsgs = chat.messages.map(m => {
        if (m.id === msgId) return { ...m, liked: !m.liked };
        return m;
     });
     onUpdate({ ...chat, messages: updatedMsgs });
  };

  const filteredGifs = useMemo(() => {
    if (!gifSearch) return MOCK_GIFS;
    return MOCK_GIFS.filter(g => g.tags.includes(gifSearch.toLowerCase()));
  }, [gifSearch]);

  const closePickers = () => {
    setShowEmoji(false);
    setShowGift(false);
    setShowGif(false);
  };

  return (
    <motion.div 
      initial={{ x: '100%' }}
      animate={{ x: 0 }}
      exit={{ x: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-slate-950 z-[60] absolute inset-0 shadow-[-10px_0_30px_rgba(0,0,0,0.5)]"
    >
      {/* Header */}
      <div className="h-16 flex items-center justify-between px-4 bg-slate-900 border-b border-slate-800 shadow-md z-10 relative">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-2 -ml-2 text-slate-400 hover:text-white">
            <ChevronLeft size={28} />
          </button>
          
          <button onClick={() => onViewProfile(chat.user)} className="flex items-center gap-2 group">
            <div className="relative">
                <img src={chat.user.imageUrls[0]} alt={chat.user.name} className="w-10 h-10 rounded-full object-cover group-hover:opacity-80 transition-opacity" />
                <div className="absolute -bottom-1 -right-1 bg-slate-900 rounded-full p-0.5">
                   <div className="w-3 h-3 bg-green-500 rounded-full border-2 border-slate-900" />
                </div>
            </div>
            <div className="text-left">
              <h3 className="font-bold text-white text-sm group-hover:text-amber-500 transition-colors">{chat.user.name}, {chat.user.age}</h3>
              <span className="text-xs text-slate-500">Tap to view profile</span>
            </div>
          </button>
        </div>
        
        <button onClick={() => setShowMenu(!showMenu)} className="text-slate-400 hover:text-white p-2">
          <MoreVertical size={24} />
        </button>

        <AnimatePresence>
            {showMenu && (
                <motion.div 
                   initial={{ opacity: 0, scale: 0.9, y: -10 }}
                   animate={{ opacity: 1, scale: 1, y: 0 }}
                   exit={{ opacity: 0 }}
                   className="absolute top-14 right-4 bg-slate-800 border border-slate-700 rounded-xl shadow-2xl py-2 w-48 z-50 overflow-hidden"
                >
                    <button 
                      onClick={() => {
                          onUnmatch(chat.id);
                          setShowMenu(false);
                      }}
                      className="w-full text-left px-4 py-3 text-sm font-bold text-white hover:bg-slate-700 flex items-center gap-2"
                    >
                        <UserX size={16} /> Unmatch
                    </button>
                    <button 
                      onClick={() => {
                          if (confirm(`Are you sure you want to block ${chat.user.name}?`)) {
                              onBlock(chat.user.id);
                              setShowMenu(false);
                          }
                      }}
                      className="w-full text-left px-4 py-3 text-sm font-bold text-slate-300 hover:bg-slate-700 flex items-center gap-2"
                    >
                        <ShieldOff size={16} /> Block
                    </button>
                    <button 
                      onClick={() => {
                          onReport(chat.user.id);
                          setShowMenu(false);
                      }}
                      className="w-full text-left px-4 py-3 text-sm font-bold text-red-500 hover:bg-slate-700 flex items-center gap-2 border-t border-slate-700"
                    >
                        <AlertTriangle size={16} /> Report
                    </button>
                </motion.div>
            )}
        </AnimatePresence>
      </div>

      {/* Messages */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4 pb-24" onClick={() => setShowMenu(false)}>
        {chat.messages.length > 0 ? (
           chat.messages.map((msg) => (
            <div 
                key={msg.id} 
                className={`flex w-full ${msg.isMe ? 'justify-end' : 'justify-start'}`}
            >
              <div 
                 className="relative max-w-[85%]"
                 onDoubleClick={() => handleDoubleTap(msg.id)}
              >
                  {/* Media Content */}
                  {msg.mediaUrl ? (
                      <div className={`transition-transform active:scale-95 overflow-hidden ${
                          msg.type === 'GIFT' 
                          ? 'bg-amber-500/10 p-2 rounded-2xl border border-amber-500/30' 
                          : msg.type === 'GIF' 
                            ? 'rounded-2xl' 
                            : ''
                      }`}>
                          <img 
                            src={msg.mediaUrl} 
                            alt={msg.type} 
                            className={`object-contain drop-shadow-lg ${
                                msg.type === 'GIFT' ? 'w-24 h-24' 
                                : msg.type === 'GIF' ? 'w-full h-auto max-h-48 rounded-2xl'
                                : 'w-32 h-32'
                            }`} 
                          />
                          {msg.type === 'GIFT' && (
                            <div className="text-center mt-1">
                                <span className="text-[10px] font-bold text-amber-500 uppercase tracking-widest">{msg.text || 'Charm'}</span>
                            </div>
                          )}
                      </div>
                  ) : (
                      /* Text Type */
                      <div className={`px-4 py-3 shadow-sm ${
                        msg.isMe 
                          ? 'bg-amber-600 text-white rounded-2xl rounded-tr-none' 
                          : 'bg-slate-800 text-slate-200 rounded-2xl rounded-tl-none'
                      }`}>
                        <p className="text-sm">{msg.text}</p>
                      </div>
                  )}

                  {/* Liked Heart Overlay */}
                  <AnimatePresence>
                    {msg.liked && (
                        <motion.div 
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          exit={{ scale: 0 }}
                          className={`absolute -bottom-2 ${msg.isMe ? '-left-2' : '-right-2'} bg-slate-950 rounded-full p-1 border border-slate-800 z-10`}
                        >
                            <Heart size={14} className="text-red-500 fill-red-500" />
                        </motion.div>
                    )}
                  </AnimatePresence>
                  
                  {/* Timestamp */}
                  <span className={`text-[10px] block mt-1 opacity-60 ${msg.isMe ? 'text-right text-slate-400' : 'text-left text-slate-500'}`}>
                    {msg.timestamp}
                  </span>
              </div>
            </div>
          ))
        ) : (
          <div className="h-full flex flex-col items-center justify-center opacity-40">
            <span className="text-4xl mb-2">👋</span>
            <p className="text-sm">Say hello to start the chat!</p>
          </div>
        )}
      </div>

      {/* Floating Pickers */}
      <AnimatePresence>
        {showEmoji && (
            <motion.div initial={{y: 50, opacity: 0}} animate={{y:0, opacity:1}} exit={{y:50, opacity:0}} className="bg-slate-900 border-t border-slate-800 p-4 grid grid-cols-6 gap-2 h-56 overflow-y-auto z-30 relative no-scrollbar">
                {EMOJIS.map(emoji => (
                    <button key={emoji} onClick={() => setInputText(prev => prev + emoji)} className="text-2xl hover:bg-slate-800 rounded p-2">
                        {emoji}
                    </button>
                ))}
            </motion.div>
        )}
        {showGift && (
            <motion.div initial={{y: 50, opacity: 0}} animate={{y:0, opacity:1}} exit={{y:50, opacity:0}} className="bg-slate-900 border-t border-slate-800 p-4 grid grid-cols-4 gap-4 h-56 overflow-y-auto z-30 relative no-scrollbar">
                {GIFTS.map((gift, idx) => (
                    <button key={idx} onClick={() => handleSend(gift.name, 'GIFT', gift.url)} className="hover:bg-slate-800 rounded-xl p-2 flex flex-col items-center gap-2 group">
                        <img src={gift.url} className="w-12 h-12 object-contain drop-shadow-md group-hover:scale-110 transition-transform" alt="Gift" />
                        <span className="text-[10px] text-amber-500 font-bold">{gift.name}</span>
                    </button>
                ))}
            </motion.div>
        )}
        {showGif && (
            <motion.div initial={{y: 50, opacity: 0}} animate={{y:0, opacity:1}} exit={{y:50, opacity:0}} className="bg-slate-900 border-t border-slate-800 flex flex-col h-64 z-30 relative">
               <div className="p-2 border-b border-slate-800">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={16} />
                    <input 
                      type="text" 
                      placeholder="Search Giphy..."
                      value={gifSearch}
                      onChange={(e) => setGifSearch(e.target.value)}
                      className="w-full bg-slate-800 rounded-lg py-2 pl-9 pr-4 text-sm text-white placeholder-slate-500 outline-none focus:ring-1 focus:ring-amber-500"
                      autoFocus
                    />
                  </div>
               </div>
               <div className="flex-1 overflow-y-auto p-2 grid grid-cols-2 gap-2 no-scrollbar">
                  {filteredGifs.map((gif) => (
                      <button 
                        key={gif.id}
                        onClick={() => handleSend('', 'GIF', gif.url)}
                        className="rounded-lg overflow-hidden h-24 relative group"
                      >
                         <img src={gif.url} className="w-full h-full object-cover" alt={gif.tags} />
                         <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                            <Send size={16} className="text-white" />
                         </div>
                      </button>
                  ))}
               </div>
               <div className="p-1 bg-black text-center">
                  <span className="text-[9px] text-slate-500 font-bold uppercase">Powered by GIPHY</span>
               </div>
            </motion.div>
        )}
      </AnimatePresence>

      {/* Input Bar */}
      <div className="p-3 bg-slate-900 border-t border-slate-800 z-40 safe-area-pb">
        <div className="flex items-center gap-2 bg-slate-800 rounded-full px-2 py-2">
          
          <button 
             onClick={() => { closePickers(); setShowEmoji(!showEmoji); }}
             className={`p-2 rounded-full ${showEmoji ? 'text-amber-500 bg-slate-700' : 'text-slate-400 hover:text-white'}`}
          >
             <Smile size={20} />
          </button>

          <button 
             onClick={() => { closePickers(); setShowGif(!showGif); }}
             className={`p-2 rounded-full ${showGif ? 'text-blue-500 bg-slate-700' : 'text-slate-400 hover:text-white'}`}
          >
             <Clapperboard size={20} />
          </button>

          <button 
             onClick={() => { closePickers(); setShowGift(!showGift); }}
             className={`p-2 rounded-full ${showGift ? 'text-pink-500 bg-slate-700' : 'text-slate-400 hover:text-white'}`}
          >
             <Gift size={20} />
          </button>

          <input 
            type="text" 
            value={inputText}
            onFocus={() => { closePickers(); }}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend(inputText)}
            placeholder="Type a message..."
            className="flex-1 bg-transparent text-white placeholder-slate-500 outline-none text-sm px-2"
          />
          
          <button 
            onClick={() => handleSend(inputText)}
            disabled={!inputText.trim()}
            className={`p-2 rounded-full transition-colors ${
              inputText.trim() ? 'bg-amber-500 text-black' : 'bg-slate-700 text-slate-500'
            }`}
          >
            <Send size={18} fill={inputText.trim() ? "currentColor" : "none"} />
          </button>
        </div>
      </div>
    </motion.div>
  );
};