
export enum CardType {
  PROFILE = 'PROFILE',
  AD = 'AD',
  EMPTY = 'EMPTY'
}

export interface UserProfile {
  id: string;
  name: string;
  age: number;
  bio: string;
  imageUrls: string[]; 
  location: string;
  profession: string;
  gender: 'MEN' | 'WOMEN';
  distance: number; // in km
  interests: string[]; // List of tags/interests
  voiceIntro?: string; // Duration string e.g. "0:15"
  isVerified?: boolean; // Blue check status
  
  // --- Algorithm Fields ---
  lastActive: number; // Timestamp (Date.now())
  joinedDate: number; // Timestamp (Date.now())
  hasLikedCurrentUser?: boolean; // If true, this is a potential match (Priority 2)
  popularityScore: number; // 0-100 Score for ranking
}

export interface AdContent {
  id: string;
  title: string;
  ctaText: string;
  imageUrl: string;
  linkUrl: string;
  description: string;
}

export interface CardItem {
  type: CardType;
  data: UserProfile | AdContent;
  uniqueId: string; // Used for React keys in the infinite list
}

export interface Message {
  id: string;
  text: string;
  timestamp: string;
  isMe: boolean;
  liked?: boolean; 
  type?: 'TEXT' | 'GIFT' | 'GIF'; 
  mediaUrl?: string; 
}

export interface ChatSession {
  id: string;
  user: UserProfile;
  lastMessage: string;
  unreadCount: number;
  messages: Message[];
  timestamp: string;
}