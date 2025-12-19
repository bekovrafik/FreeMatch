import { UserProfile, AdContent, ChatSession } from './types';

const NOW = Date.now();
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const MIN = 60 * 1000;

// High-quality female profiles for demo purposes with verified working image URLs
export const MOCK_PROFILES: UserProfile[] = [
  { 
    id: 'p1', 
    name: 'Isabella', 
    age: 23, 
    bio: 'Model & Art enthusiast. Always looking for the next best coffee spot. ☕️✨', 
    imageUrls: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Los Angeles, CA', 
    profession: 'Fashion Model', 
    gender: 'WOMEN', 
    distance: 3, 
    interests: ['Fashion', 'Art', 'Coffee', 'Modeling'], 
    voiceIntro: '0:12', 
    isVerified: true,
    lastActive: NOW - (10 * 60 * 1000), // Active 10 mins ago
    joinedDate: NOW - (30 * DAY), 
    popularityScore: 95,
    hasLikedCurrentUser: true // Priority Match!
  },
  { 
    id: 'p2', 
    name: 'Sophia', 
    age: 25, 
    bio: 'Architect by day, wine taster by night. Let’s build something beautiful. 🏛️🍷', 
    imageUrls: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Chicago, IL', 
    profession: 'Architect', 
    gender: 'WOMEN', 
    distance: 8, 
    interests: ['Architecture', 'Wine', 'Design', 'Travel'], 
    isVerified: true,
    lastActive: NOW - (2 * HOUR),
    joinedDate: NOW - (1 * DAY), // New User (< 48h)
    popularityScore: 80
  },
  { 
    id: 'p3', 
    name: 'Ava', 
    age: 22, 
    bio: 'Student of life (and actual university). Gamer girl 🎮', 
    imageUrls: [
        'https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1496440738390-dad8b77e8711?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Miami, FL', 
    profession: 'Grad Student', 
    gender: 'WOMEN', 
    distance: 5, 
    interests: ['Gaming', 'Anime', 'Study', 'Beach'], 
    isVerified: false,
    lastActive: NOW - (5 * DAY),
    joinedDate: NOW - (60 * DAY),
    popularityScore: 60
  },
  { 
    id: 'p4', 
    name: 'Mia', 
    age: 26, 
    bio: 'Marketing guru. I can sell ice to a polar bear, but I can’t flirt to save my life. 🧊', 
    imageUrls: [
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1529139574466-a302d2753cd2?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'New York, NY', 
    profession: 'Marketing Lead', 
    gender: 'WOMEN', 
    distance: 2, 
    interests: ['Marketing', 'Business', 'Brunch', 'Networking'], 
    isVerified: true,
    lastActive: NOW - (1 * DAY),
    joinedDate: NOW - (100 * DAY),
    popularityScore: 88,
    hasLikedCurrentUser: true // Priority
  },
  { 
    id: 'p5', 
    name: 'Charlotte', 
    age: 24, 
    bio: 'Contemporary dancer. Moving through life one step at a time. 💃', 
    imageUrls: [
        'https://images.unsplash.com/photo-1526510747491-58f928ec870f?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1503104834685-5205923d60c5?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'San Francisco, CA', 
    profession: 'Dancer', 
    gender: 'WOMEN', 
    distance: 6, 
    interests: ['Dance', 'Ballet', 'Music', 'Fitness'], 
    voiceIntro: '0:15', 
    isVerified: true,
    lastActive: NOW - (30 * 60 * 1000),
    joinedDate: NOW - (5 * DAY),
    popularityScore: 75
  },
  { 
    id: 'p6', 
    name: 'Amelia', 
    age: 27, 
    bio: 'Capturing moments. Photographer looking for a muse (or a date). 📸', 
    imageUrls: [
        'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1515202913167-d9fe0a2845b8?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Seattle, WA', 
    profession: 'Photographer', 
    gender: 'WOMEN', 
    distance: 12, 
    interests: ['Photography', 'Cameras', 'Hiking', 'Nature'], 
    isVerified: false,
    lastActive: NOW - (4 * DAY),
    joinedDate: NOW - (200 * DAY),
    popularityScore: 50
  },
  { 
    id: 'p7', 
    name: 'Harper', 
    age: 23, 
    bio: 'Singer/Songwriter. I’ll write a song about you if you break my heart. 🎸', 
    imageUrls: [
        'https://images.unsplash.com/photo-1506795660198-e95c77602129?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Nashville, TN', 
    profession: 'Musician', 
    gender: 'WOMEN', 
    distance: 15, 
    interests: ['Music', 'Guitar', 'Concerts', 'Vinyl'], 
    isVerified: true,
    lastActive: NOW - (12 * HOUR),
    joinedDate: NOW - (10 * HOUR), // New User
    popularityScore: 65
  },
  { 
    id: 'p8', 
    name: 'Evelyn', 
    age: 25, 
    bio: 'ER Nurse. I’ve seen it all, try to surprise me. 🚑', 
    imageUrls: [
        'https://images.unsplash.com/photo-1520635645693-194d1bf78b1f?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Boston, MA', 
    profession: 'Registered Nurse', 
    gender: 'WOMEN', 
    distance: 4, 
    interests: ['Nursing', 'Medicine', 'Coffee', 'Helping Others'], 
    isVerified: true,
    lastActive: NOW - (15 * 60 * 1000), // Just active
    joinedDate: NOW - (365 * DAY),
    popularityScore: 92
  },
  { 
    id: 'p9', 
    name: 'Abigail', 
    age: 28, 
    bio: 'Pastry Chef. Yes, I will make you cupcakes. 🧁', 
    imageUrls: [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Paris, TX', 
    profession: 'Chef', 
    gender: 'WOMEN', 
    distance: 20, 
    interests: ['Baking', 'Cooking', 'Foodie', 'Sweets'], 
    isVerified: false,
    lastActive: NOW - (8 * DAY), // Inactive > 7 days (Should be filtered out)
    joinedDate: NOW - (20 * DAY),
    popularityScore: 40
  },
  { 
    id: 'p10', 
    name: 'Emily', 
    age: 24, 
    bio: 'UX Designer. I judge apps by their kerning. 📱', 
    imageUrls: [
        'https://images.unsplash.com/photo-1519345182560-3f2917c472ef?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1520024146169-3240400354ae?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Austin, TX', 
    profession: 'UX Designer', 
    gender: 'WOMEN', 
    distance: 7, 
    interests: ['Design', 'Tech', 'Art', 'Startups'], 
    isVerified: true,
    lastActive: NOW - (1 * HOUR),
    joinedDate: NOW - (6 * DAY),
    popularityScore: 78
  },
  { 
    id: 'p11', 
    name: 'Elizabeth', 
    age: 26, 
    bio: 'Corporate Lawyer. I win arguments for a living. ⚖️', 
    imageUrls: [
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Washington, DC', 
    profession: 'Attorney', 
    gender: 'WOMEN', 
    distance: 9, 
    interests: ['Law', 'Politics', 'Reading', 'Debate'], 
    voiceIntro: '0:10', 
    isVerified: true,
    lastActive: NOW - (2 * DAY),
    joinedDate: NOW - (150 * DAY),
    popularityScore: 85
  },
  { 
    id: 'p12', 
    name: 'Sofia', 
    age: 23, 
    bio: 'Catch me by the waves. Surfer soul. 🌊', 
    imageUrls: [
        'https://images.unsplash.com/photo-1523950456102-14032d1f9748?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1464863979648-5260e3aa99c9?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'San Diego, CA', 
    profession: 'Instructor', 
    gender: 'WOMEN', 
    distance: 1, 
    interests: ['Surfing', 'Ocean', 'Beach', 'Fitness'], 
    isVerified: true,
    lastActive: NOW - (5 * MIN), // Very active
    joinedDate: NOW - (40 * DAY),
    popularityScore: 89
  },
  { 
    id: 'p13', 
    name: 'Avery', 
    age: 25, 
    bio: 'Yoga teacher. Finding balance in chaos. 🧘‍♀️', 
    imageUrls: [
        'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1513207565459-d7f36bfa1222?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Denver, CO', 
    profession: 'Yoga Teacher', 
    gender: 'WOMEN', 
    distance: 11, 
    interests: ['Yoga', 'Meditation', 'Wellness', 'Hiking'], 
    isVerified: false,
    lastActive: NOW - (3 * DAY),
    joinedDate: NOW - (15 * DAY),
    popularityScore: 55
  },
  { 
    id: 'p14', 
    name: 'Ella', 
    age: 22, 
    bio: 'Barista & aspiring novelist. Runs on caffeine and dreams. ☕️📚', 
    imageUrls: [
        'https://images.unsplash.com/photo-1485960994840-902a67e187c8?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1529232356377-57971f020d94?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Portland, OR', 
    profession: 'Barista', 
    gender: 'WOMEN', 
    distance: 5, 
    interests: ['Coffee', 'Books', 'Writing', 'Rain'], 
    isVerified: false,
    lastActive: NOW - (10 * MIN),
    joinedDate: NOW - (1 * DAY), // New User
    popularityScore: 70
  },
  { 
    id: 'p15', 
    name: 'Scarlett', 
    age: 27, 
    bio: 'Actress. Drama belongs on stage, not in my life. 🎭', 
    imageUrls: [
        'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1534751516054-127dbcbc0637?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'New York, NY', 
    profession: 'Actress', 
    gender: 'WOMEN', 
    distance: 4, 
    interests: ['Acting', 'Theater', 'Movies', 'Cinema'], 
    isVerified: true,
    lastActive: NOW - (1 * DAY),
    joinedDate: NOW - (50 * DAY),
    popularityScore: 82,
    hasLikedCurrentUser: true
  },
  { 
    id: 'p16', 
    name: 'Grace', 
    age: 24, 
    bio: 'Travel Writer. 30 countries and counting. ✈️', 
    imageUrls: [
        'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1500917293891-ef795e70e1f6?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Philadelphia, PA', 
    profession: 'Writer', 
    gender: 'WOMEN', 
    distance: 100, 
    interests: ['Travel', 'Writing', 'Adventure', 'Food'], 
    isVerified: true,
    lastActive: NOW - (6 * DAY),
    joinedDate: NOW - (300 * DAY),
    popularityScore: 74
  },
  { 
    id: 'p17', 
    name: 'Chloe', 
    age: 26, 
    bio: 'Full Stack Dev. I speak Python, JS, and Sarcasm. 💻', 
    imageUrls: [
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'San Jose, CA', 
    profession: 'Software Engineer', 
    gender: 'WOMEN', 
    distance: 14, 
    interests: ['Coding', 'Tech', 'Gaming', 'Sci-Fi'], 
    isVerified: true,
    lastActive: NOW - (2 * HOUR),
    joinedDate: NOW - (60 * DAY),
    popularityScore: 68
  },
  { 
    id: 'p18', 
    name: 'Victoria', 
    age: 28, 
    bio: 'Pediatrician. Kids are easier to deal with than adults on this app. 🩺', 
    imageUrls: [
        'https://images.unsplash.com/photo-1527613426441-4da17471b66d?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Houston, TX', 
    profession: 'Doctor', 
    gender: 'WOMEN', 
    distance: 18, 
    interests: ['Medicine', 'Kids', 'Health', 'Science'], 
    isVerified: true,
    lastActive: NOW - (1 * DAY),
    joinedDate: NOW - (400 * DAY),
    popularityScore: 90
  },
  { 
    id: 'p19', 
    name: 'Riley', 
    age: 23, 
    bio: 'Social Media Manager. If you don’t like brunch, we can’t be friends. 🥑', 
    imageUrls: [
        'https://images.unsplash.com/photo-1516726817505-f16329242abd?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1524601500432-1e1a4c71d692?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'Atlanta, GA', 
    profession: 'Social Media', 
    gender: 'WOMEN', 
    distance: 7, 
    interests: ['Social Media', 'Brunch', 'TikTok', 'Trends'], 
    isVerified: false,
    lastActive: NOW - (30 * MIN),
    joinedDate: NOW - (4 * DAY),
    popularityScore: 72
  },
  { 
    id: 'p20', 
    name: 'Zoey', 
    age: 25, 
    bio: 'Painter & Illustrator. Let me paint you like one of my French girls. 🎨', 
    imageUrls: [
        'https://images.unsplash.com/photo-1500522144261-ea64433bbe16?w=600&h=900&fit=crop&fm=jpg',
        'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=600&h=900&fit=crop&fm=jpg'
    ], 
    location: 'New Orleans, LA', 
    profession: 'Artist', 
    gender: 'WOMEN', 
    distance: 9, 
    interests: ['Art', 'Painting', 'Museums', 'Creativity'], 
    isVerified: true,
    lastActive: NOW - (4 * HOUR),
    joinedDate: NOW - (180 * DAY),
    popularityScore: 63
  }
];

export const MOCK_ADS: AdContent[] = [
  { id: 'a1', title: 'Mobile Game', ctaText: 'Play Free', imageUrl: 'https://picsum.photos/400/600?random=101', linkUrl: 'https://ad.placeholder.com/game', description: 'Epic battles await. Join millions of players.' },
  { id: 'a2', title: 'Local Coffee', ctaText: 'Get 50% Off', imageUrl: 'https://picsum.photos/400/600?random=102', linkUrl: 'https://ad.placeholder.com/coffee', description: 'Best brew in town. Valid this week only.' },
  { id: 'a3', title: 'Travel Deals', ctaText: 'Book Flight', imageUrl: 'https://picsum.photos/400/600?random=103', linkUrl: 'https://ad.placeholder.com/travel', description: 'Cheap flights to dream destinations.' },
  { id: 'a4', title: 'Fitness App', ctaText: 'Start Trial', imageUrl: 'https://picsum.photos/400/600?random=104', linkUrl: 'https://ad.placeholder.com/fitness', description: 'Get shredded in 30 days.' },
  { id: 'a5', title: 'Food Delivery', ctaText: 'Order Now', imageUrl: 'https://picsum.photos/400/600?random=105', linkUrl: 'https://ad.placeholder.com/food', description: 'Hungry? We deliver in 20 mins.' },
  { id: 'a6', title: 'Movie Streaming', ctaText: 'Watch Free', imageUrl: 'https://picsum.photos/400/600?random=106', linkUrl: 'https://ad.placeholder.com/movies', description: 'Thousands of movies. No ads.' },
  { id: 'a7', title: 'Fashion Sale', ctaText: 'Shop Sale', imageUrl: 'https://picsum.photos/400/600?random=107', linkUrl: 'https://ad.placeholder.com/fashion', description: 'Summer collection up to 70% off.' },
  { id: 'a8', title: 'Tech Gadgets', ctaText: 'Buy Now', imageUrl: 'https://picsum.photos/400/600?random=108', linkUrl: 'https://ad.placeholder.com/tech', description: 'Latest smartphone accessories.' },
  { id: 'a9', title: 'Concert Tickets', ctaText: 'Get Tickets', imageUrl: 'https://picsum.photos/400/600?random=109', linkUrl: 'https://ad.placeholder.com/music', description: 'Your favorite band is in town.' },
  { id: 'a10', title: 'Language App', ctaText: 'Learn Spanish', imageUrl: 'https://picsum.photos/400/600?random=110', linkUrl: 'https://ad.placeholder.com/lang', description: 'Speak a new language in 3 weeks.' },
];

export const MOCK_CHATS: ChatSession[] = [
  {
    id: 'c1',
    user: MOCK_PROFILES[0], // Isabella
    lastMessage: 'I know a great gallery opening this weekend! 🎨',
    unreadCount: 2,
    timestamp: '2m ago',
    messages: [
      { id: 'm1', text: 'Hey Isabella! Love your style.', timestamp: '10:00 AM', isMe: true },
      { id: 'm2', text: 'Thank you! 😊 You have great taste.', timestamp: '10:05 AM', isMe: false },
      { id: 'm3', text: 'I know a great gallery opening this weekend! 🎨', timestamp: '10:06 AM', isMe: false },
    ]
  },
  {
    id: 'c2',
    user: MOCK_PROFILES[2], // Ava
    lastMessage: 'What are you playing lately? 🎮',
    unreadCount: 0,
    timestamp: '1h ago',
    messages: [
      { id: 'm1', text: 'GG on the match!', timestamp: 'Yesterday', isMe: true },
      { id: 'm2', text: 'Haha thanks! I try my best.', timestamp: 'Yesterday', isMe: false },
      { id: 'm3', text: 'What are you playing lately? 🎮', timestamp: '11:30 AM', isMe: true },
    ]
  },
  {
    id: 'c3',
    user: MOCK_PROFILES[5], // Amelia
    lastMessage: 'Golden hour is the best hour ☀️',
    unreadCount: 1,
    timestamp: 'Yesterday',
    messages: [
      { id: 'm1', text: 'Your photos are incredible.', timestamp: 'Mon', isMe: true },
      { id: 'm2', text: 'That means so much! Golden hour is the best hour ☀️', timestamp: 'Mon', isMe: false },
    ]
  }
];

export const CURRENT_USER: UserProfile = {
  id: 'me',
  name: 'Alex',
  age: 26,
  bio: 'Product Designer based in SF. Love minimalist UI and maximalist coffee.',
  imageUrls: ['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=687&q=80'],
  location: 'San Francisco, CA',
  profession: 'Designer',
  gender: 'MEN',
  distance: 0,
  interests: ['Design', 'Coffee', 'UI/UX', 'Photography', 'Travel'],
  voiceIntro: undefined,
  isVerified: false,
  // Current user stats
  lastActive: NOW,
  joinedDate: NOW - (365 * DAY),
  popularityScore: 50
};