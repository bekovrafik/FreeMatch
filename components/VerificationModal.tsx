import React, { useState, useRef, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Camera, ShieldCheck, X, Check, Loader2, RefreshCw } from 'lucide-react';
import { CURRENT_USER } from '../constants';

interface Props {
  onClose: () => void;
  onVerified: () => void;
}

type Step = 'INTRO' | 'CAMERA' | 'PROCESSING' | 'SUCCESS';

export const VerificationModal: React.FC<Props> = ({ onClose, onVerified }) => {
  const [step, setStep] = useState<Step>('INTRO');
  const [stream, setStream] = useState<MediaStream | null>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const [cameraError, setCameraError] = useState(false);

  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, [stream]);

  const startCamera = async () => {
    setStep('CAMERA');
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({ video: true });
      setStream(mediaStream);
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
      setCameraError(false);
    } catch (err) {
      console.error("Camera access denied:", err);
      setCameraError(true);
    }
  };

  const takePhoto = () => {
    setStep('PROCESSING');
    if (stream) {
        stream.getTracks().forEach(track => track.stop()); // Stop camera
    }
    
    // Simulate API verification delay
    setTimeout(() => {
        setStep('SUCCESS');
        CURRENT_USER.isVerified = true;
    }, 2500);
  };

  const handleFinish = () => {
      onVerified();
      onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/90 backdrop-blur-md"
      />
      
      <motion.div 
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="relative z-10 bg-slate-900 border border-slate-700 w-full max-w-sm rounded-3xl overflow-hidden shadow-2xl flex flex-col max-h-[90vh]"
      >
        <button onClick={onClose} className="absolute top-4 right-4 z-20 bg-black/30 p-2 rounded-full text-white hover:bg-black/50">
            <X size={20} />
        </button>

        {step === 'INTRO' && (
            <div className="p-8 flex flex-col items-center text-center">
                <div className="w-24 h-24 bg-blue-500/20 rounded-full flex items-center justify-center mb-6">
                    <ShieldCheck size={48} className="text-blue-500" />
                </div>
                <h2 className="text-2xl font-bold text-white mb-2">Get Verified</h2>
                <p className="text-slate-400 mb-8 leading-relaxed">
                    Show others you're real. Take a quick video selfie to earn your blue checkmark badge.
                </p>
                <div className="flex items-center gap-4 mb-8 text-left bg-slate-800 p-4 rounded-xl">
                    <div className="w-10 h-10 bg-slate-700 rounded-full flex items-center justify-center flex-shrink-0">
                        <Camera size={20} className="text-slate-300" />
                    </div>
                    <div>
                        <h4 className="font-bold text-white text-sm">Face Verification</h4>
                        <p className="text-xs text-slate-400">We compare your video to your profile photos.</p>
                    </div>
                </div>
                <button 
                    onClick={startCamera}
                    className="w-full py-4 bg-blue-600 hover:bg-blue-500 text-white font-bold rounded-2xl transition-colors"
                >
                    I'm Ready
                </button>
            </div>
        )}

        {step === 'CAMERA' && (
            <div className="flex-1 flex flex-col relative bg-black h-[500px]">
                {cameraError ? (
                    <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
                        <Camera size={48} className="text-slate-600 mb-4" />
                        <p className="text-slate-400 mb-6">Camera access was denied or not available.</p>
                        <button onClick={takePhoto} className="px-6 py-3 bg-slate-800 text-white rounded-xl font-bold">
                            Simulate Verification
                        </button>
                    </div>
                ) : (
                    <>
                        <video 
                            ref={videoRef} 
                            autoPlay 
                            muted 
                            playsInline 
                            className="absolute inset-0 w-full h-full object-cover transform scale-x-[-1]" 
                        />
                        <div className="absolute inset-0 pointer-events-none">
                            <div className="w-full h-full bg-black/40 mask-oval">
                                {/* Oval Cutout Overlay (Simulated via SVG or masking in real app, simplified here with border) */}
                                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-80 border-4 border-white/50 rounded-[50%]"></div>
                            </div>
                        </div>
                        <div className="absolute bottom-0 left-0 w-full p-6 flex flex-col items-center">
                            <p className="text-white font-bold mb-6 drop-shadow-md">Position your face in the oval</p>
                            <button 
                                onClick={takePhoto}
                                className="w-16 h-16 rounded-full border-4 border-white flex items-center justify-center mb-4 bg-white/20 active:scale-95 transition-transform"
                            >
                                <div className="w-12 h-12 bg-white rounded-full" />
                            </button>
                        </div>
                    </>
                )}
            </div>
        )}

        {step === 'PROCESSING' && (
            <div className="p-12 flex flex-col items-center text-center h-[400px] justify-center">
                <motion.div 
                    animate={{ rotate: 360 }}
                    transition={{ repeat: Infinity, duration: 1, ease: "linear" }}
                    className="mb-6"
                >
                    <Loader2 size={64} className="text-blue-500" />
                </motion.div>
                <h3 className="text-xl font-bold text-white mb-2">Analyzing...</h3>
                <p className="text-slate-400">Checking your biometrics against your photos.</p>
            </div>
        )}

        {step === 'SUCCESS' && (
            <div className="p-12 flex flex-col items-center text-center">
                <motion.div 
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring" }}
                    className="w-24 h-24 bg-green-500 rounded-full flex items-center justify-center mb-6 shadow-lg shadow-green-500/30"
                >
                    <Check size={48} className="text-black" strokeWidth={4} />
                </motion.div>
                <h2 className="text-2xl font-bold text-white mb-2">You're Verified!</h2>
                <p className="text-slate-400 mb-8">You've earned the blue checkmark. Your profile is now more trustworthy.</p>
                <button 
                    onClick={handleFinish}
                    className="w-full py-4 bg-slate-800 hover:bg-slate-700 text-white font-bold rounded-2xl transition-colors"
                >
                    Done
                </button>
            </div>
        )}
      </motion.div>
    </div>
  );
};