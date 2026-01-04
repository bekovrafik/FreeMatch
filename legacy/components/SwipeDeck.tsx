import React, { useState, useEffect } from 'react';
import { motion, useMotionValue, useTransform, PanInfo, AnimatePresence, animate } from 'framer-motion';
import { CardItem, CardType, AdContent, UserProfile } from '../types';
import { UserProfileCard } from './UserProfileCard';
import { AdCard } from './AdCard';
import { EmptyCard } from './EmptyCard';

interface SwipeDeckProps {
  currentCard: CardItem;
  nextCard: CardItem;
  swipeDirection?: 'left' | 'right' | 'up' | null; // New prop from App
  onSwipe: (direction: 'left' | 'right' | 'up', card: CardItem) => void;
  onCardTap: (card: CardItem) => void;
}

export const SwipeDeck: React.FC<SwipeDeckProps> = ({ currentCard, nextCard, swipeDirection, onSwipe, onCardTap }) => {
  const [dragStart, setDragStart] = useState(false);
  
  // Motion Values
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  
  // Derived Values
  const rotate = useTransform(x, [-200, 200], [-15, 15]);
  const rotateX = useTransform(y, [0, -300], [0, 15]); 
  
  const likeOpacity = useTransform(x, [20, 150], [0, 1]);
  const nopeOpacity = useTransform(x, [-150, -20], [1, 0]);
  const superLikeOpacity = useTransform(y, [-50, -150], [0, 1]);

  // Reset position when card changes
  useEffect(() => {
    x.set(0);
    y.set(0);
  }, [currentCard.uniqueId, x, y]);

  // Handle Manual Swipe Prop from Parent
  useEffect(() => {
    if (swipeDirection) {
      const flyAwayDuration = 0.5;
      
      if (swipeDirection === 'right') {
        animate(x, 1000, { duration: flyAwayDuration, ease: "backIn" }).then(() => onSwipe('right', currentCard));
      } else if (swipeDirection === 'left') {
        animate(x, -1000, { duration: flyAwayDuration, ease: "backIn" }).then(() => onSwipe('left', currentCard));
      } else if (swipeDirection === 'up') {
        animate(y, -1000, { duration: flyAwayDuration, ease: "backIn" }).then(() => onSwipe('up', currentCard));
      }
    }
  }, [swipeDirection]);

  const handleDragEnd = (event: any, info: PanInfo) => {
    setDragStart(false);
    const threshold = 100;
    const velocityThreshold = 500;
    
    let direction: 'left' | 'right' | 'up' | null = null;

    if (info.offset.y < -threshold || info.velocity.y < -velocityThreshold) {
      direction = 'up';
    } else if (info.offset.x > threshold || info.velocity.x > velocityThreshold) {
      direction = 'right';
    } else if (info.offset.x < -threshold || info.velocity.x < -velocityThreshold) {
      direction = 'left';
    }

    if (direction) {
      // Animate off screen then trigger swipe
      const flyAwayDuration = 0.2;
      if (direction === 'right') {
         animate(x, 1000, { duration: flyAwayDuration }).then(() => onSwipe('right', currentCard));
      } else if (direction === 'left') {
         animate(x, -1000, { duration: flyAwayDuration }).then(() => onSwipe('left', currentCard));
      } else if (direction === 'up') {
         animate(y, -1000, { duration: flyAwayDuration }).then(() => onSwipe('up', currentCard));
      }
    }
  };

  const variants = {
    enter: { 
      scale: 0.95, 
      y: 30, 
      opacity: 0.6,
      x: 0,
      transition: { duration: 0 } 
    },
    center: { 
      scale: 1, 
      y: 0, 
      opacity: 1, 
      x: 0,
      rotate: 0,
      transition: { 
        type: "spring",
        stiffness: 260,
        damping: 20,
        mass: 0.8 
      }
    },
    // We keep exit variant for safety, but manual animation handles the visual exit now
    exit: {
      opacity: 0,
      transition: { duration: 0 }
    }
  };

  const renderCardContent = (card: CardItem) => {
    if (card.type === CardType.EMPTY) {
      return <EmptyCard />;
    }
    if (card.type === CardType.PROFILE) {
      return (
        <UserProfileCard 
          profile={card.data as UserProfile} 
          onOpenDetail={() => onCardTap(card)} 
        />
      );
    }
    return (
        <AdCard 
          ad={card.data as AdContent} 
          onTap={() => onCardTap(card)}
        />
    );
  };

  const isEmpty = currentCard.type === CardType.EMPTY;

  return (
    <div className="relative w-full h-full flex items-center justify-center perspective-1000">
      
      {/* --- Background Card (Next) --- */}
      {!isEmpty && (
        <motion.div 
            key={nextCard.uniqueId}
            initial={{ scale: 0.9, y: 60, opacity: 0 }}
            animate={{ scale: 0.95, y: 30, opacity: 0.6 }}
            transition={{ duration: 0.35, ease: "backOut" }}
            className="absolute w-[95%] h-full top-0 pointer-events-none bg-slate-800 rounded-3xl"
        >
            {renderCardContent(nextCard)}
        </motion.div>
      )}

      {/* --- Foreground Card (Current) --- */}
      <AnimatePresence>
        <motion.div
          key={currentCard.uniqueId}
          variants={variants}
          initial="enter"
          animate="center"
          exit="exit"
          drag={!isEmpty && !swipeDirection} // Disable drag if programmatically swiping
          dragConstraints={{ left: 0, right: 0, top: 0, bottom: 0 }}
          dragElastic={0.7}
          onDragStart={() => setDragStart(true)}
          onDragEnd={handleDragEnd}
          style={{ x, y, rotate, rotateX, zIndex: 100 }}
          className="absolute w-[95%] h-full touch-none shadow-2xl rounded-3xl bg-slate-900"
        >
          {renderCardContent(currentCard)}

          {/* --- Swipe Indicators (Only if not empty) --- */}
          {!isEmpty && (
            <>
                {/* LIKE Badge (Right) */}
                <motion.div 
                    style={{ opacity: likeOpacity }}
                    className="absolute top-8 left-8 border-4 border-green-400 rounded-xl px-4 py-2 transform -rotate-12 z-50 pointer-events-none bg-black/20 backdrop-blur-sm"
                >
                    <span className="text-4xl font-extrabold text-green-400 uppercase tracking-widest">
                    {currentCard.type === CardType.AD ? 'OPEN' : 'LIKE'}
                    </span>
                </motion.div>

                {/* NOPE Badge (Left) */}
                <motion.div 
                    style={{ opacity: nopeOpacity }}
                    className="absolute top-8 right-8 border-4 border-red-500 rounded-xl px-4 py-2 transform rotate-12 z-50 pointer-events-none bg-black/20 backdrop-blur-sm"
                >
                    <span className="text-4xl font-extrabold text-red-500 uppercase tracking-widest">
                    {currentCard.type === CardType.AD ? 'SKIP' : 'NOPE'}
                    </span>
                </motion.div>

                {/* SUPER LIKE Overlay (Up) */}
                <motion.div 
                    style={{ opacity: superLikeOpacity }}
                    className="absolute inset-0 flex flex-col items-center justify-end pb-32 z-50 pointer-events-none bg-gradient-to-t from-blue-600/40 to-transparent rounded-3xl"
                >
                    <div className="relative flex flex-col items-center">
                        <div className="border-4 border-blue-400 rounded-xl px-6 py-2 bg-black/50 backdrop-blur-md transform -rotate-3 shadow-[0_0_20px_rgba(59,130,246,0.6)]">
                            <span className="text-4xl font-black text-white italic uppercase tracking-tighter">
                            SUPER LIKE
                            </span>
                        </div>
                    </div>
                </motion.div>
            </>
          )}

        </motion.div>
      </AnimatePresence>
    </div>
  );
};