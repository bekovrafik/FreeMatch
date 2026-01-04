import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Mail, Lock, User, ArrowRight, CheckCircle } from 'lucide-react';

interface Props {
  onAuthenticated: () => void;
}

export const AuthScreen: React.FC<Props> = ({ onAuthenticated }) => {
  const [isLogin, setIsLogin] = useState(false); // Default to Sign Up
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    // Simulate Network Request
    setTimeout(() => {
      setIsLoading(false);
      onAuthenticated();
    }, 1500);
  };

  return (
    <div className="h-full flex flex-col p-8 bg-slate-950 relative">
      <div className="flex-1 flex flex-col justify-center">
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="mb-8"
        >
           <h1 className="text-4xl font-bold text-white mb-2">
             {isLogin ? "Welcome Back" : "Create Account"}
           </h1>
           <p className="text-slate-400">
             {isLogin ? "Enter your details to sign in." : "Join the community for free."}
           </p>
        </motion.div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {!isLogin && (
            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-500 uppercase ml-1">Name</label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={20} />
                <input 
                  type="text" 
                  placeholder="John Doe"
                  className="w-full bg-slate-900 border border-slate-800 rounded-2xl py-4 pl-12 pr-4 text-white focus:outline-none focus:border-amber-500 transition-colors"
                  required={!isLogin}
                />
              </div>
            </div>
          )}

          <div className="space-y-1">
            <label className="text-xs font-bold text-slate-500 uppercase ml-1">Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={20} />
              <input 
                type="email" 
                placeholder="hello@example.com"
                className="w-full bg-slate-900 border border-slate-800 rounded-2xl py-4 pl-12 pr-4 text-white focus:outline-none focus:border-amber-500 transition-colors"
                required
              />
            </div>
          </div>

          <div className="space-y-1">
            <label className="text-xs font-bold text-slate-500 uppercase ml-1">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={20} />
              <input 
                type="password" 
                placeholder="••••••••"
                className="w-full bg-slate-900 border border-slate-800 rounded-2xl py-4 pl-12 pr-4 text-white focus:outline-none focus:border-amber-500 transition-colors"
                required
              />
            </div>
          </div>

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className={`mt-6 w-full py-4 rounded-2xl font-bold text-lg flex items-center justify-center gap-2 shadow-lg transition-all ${
              isLoading 
                ? 'bg-slate-800 text-slate-500 cursor-not-allowed' 
                : 'bg-gradient-to-r from-amber-500 to-pink-600 text-white'
            }`}
            disabled={isLoading}
          >
            {isLoading ? (
               "Processing..."
            ) : (
               <>
                 {isLogin ? "Sign In" : "Sign Up"}
                 <ArrowRight size={20} />
               </>
            )}
          </motion.button>
        </form>

        <div className="mt-8 text-center">
           <p className="text-slate-500">
             {isLogin ? "Don't have an account?" : "Already have an account?"}
             <button 
               onClick={() => setIsLogin(!isLogin)}
               className="ml-2 text-amber-500 font-bold hover:underline"
             >
               {isLogin ? "Sign Up" : "Sign In"}
             </button>
           </p>
        </div>
      </div>
      
      {/* Disclaimer */}
      <p className="text-center text-xs text-slate-600 mt-4">
        By continuing, you agree to our Terms of Service.
      </p>
    </div>
  );
};