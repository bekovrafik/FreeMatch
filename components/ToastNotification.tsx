import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MessageCircle, Heart, Bell } from 'lucide-react';

export interface Toast {
  id: string;
  type: 'MATCH' | 'MESSAGE' | 'SYSTEM';
  title: string;
  message: string;
  image?: string;
}

interface Props {
  toasts: Toast[];
  onDismiss: (id: string) => void;
}

export const ToastContainer: React.FC<Props> = ({ toasts, onDismiss }) => {
  return (
    <div className="fixed top-0 left-0 right-0 z-[100] flex flex-col items-center pt-safe-area-pt pointer-events-none p-4 gap-2">
      <AnimatePresence>
        {toasts.map((toast) => (
          <ToastItem key={toast.id} toast={toast} onDismiss={onDismiss} />
        ))}
      </AnimatePresence>
    </div>
  );
};

const ToastItem: React.FC<{ toast: Toast, onDismiss: (id: string) => void }> = ({ toast, onDismiss }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onDismiss(toast.id);
    }, 4000);
    return () => clearTimeout(timer);
  }, [toast.id, onDismiss]);

  const getIcon = () => {
    switch (toast.type) {
      case 'MATCH': return <Heart size={20} className="text-pink-500 fill-pink-500" />;
      case 'MESSAGE': return <MessageCircle size={20} className="text-blue-500 fill-blue-500" />;
      default: return <Bell size={20} className="text-amber-500" />;
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: -50, scale: 0.9 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, scale: 0.9, transition: { duration: 0.2 } }}
      layout
      className="bg-slate-800/90 backdrop-blur-md border border-slate-700/50 text-white px-4 py-3 rounded-2xl shadow-2xl w-full max-w-sm pointer-events-auto flex items-center gap-3"
      onClick={() => onDismiss(toast.id)}
      drag="x"
      dragConstraints={{ left: 0, right: 0 }}
      onDragEnd={(_, info) => {
        if (Math.abs(info.offset.x) > 100) onDismiss(toast.id);
      }}
    >
      {toast.image ? (
        <img src={toast.image} alt="" className="w-10 h-10 rounded-full object-cover border border-slate-600" />
      ) : (
        <div className="w-10 h-10 rounded-full bg-slate-900 flex items-center justify-center">
          {getIcon()}
        </div>
      )}
      
      <div className="flex-1 min-w-0">
        <h4 className="font-bold text-sm truncate">{toast.title}</h4>
        <p className="text-xs text-slate-300 truncate">{toast.message}</p>
      </div>
    </motion.div>
  );
};