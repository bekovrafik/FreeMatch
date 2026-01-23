const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.onLikeCreated = functions.firestore
    .document("users/{userId}/likes/{targetId}")
    .onCreate(async (snap, context) => {
        const { userId, targetId } = context.params;
        const likeData = snap.data();
        const isSuperLike = likeData.isSuperLike || false;
        const matchId = [userId, targetId].sort().join("_");

        // 1. POPULATE received_likes (Notification of Like)
        await db.doc(`users/${targetId}/received_likes/${userId}`).set({
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isSuperLike: isSuperLike,
        });

        // 2. SEARCH FOR MATCH (Transactional for High Integrity)
        let isMatch = false;
        await db.runTransaction(async (transaction) => {
            const matchRef = db.collection("matches").doc(matchId);
            const matchDoc = await transaction.get(matchRef);

            if (matchDoc.exists) {
                console.log(`Match ${matchId} already exists. Skipping.`);
                return;
            }

            const mutualLikeRef = db.doc(`users/${targetId}/likes/${userId}`);
            const mutualLikeDoc = await transaction.get(mutualLikeRef);

            if (!mutualLikeDoc.exists) {
                console.log("No mutual like found yet.");
                return;
            }

            console.log(`Mutual like found! Creating match ${matchId} atomically.`);
            isMatch = true;

            transaction.set(matchRef, {
                users: [userId, targetId],
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                lastMessage: null,
            });

            const chatRef = db.collection("chats").doc(matchId);
            transaction.set(chatRef, {
                participants: [userId, targetId],
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastMessage: "",
                lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
                participantsData: {}
            });

            transaction.update(db.doc(`users/${userId}`), {
                matchCount: admin.firestore.FieldValue.increment(1)
            });
            transaction.update(db.doc(`users/${targetId}`), {
                matchCount: admin.firestore.FieldValue.increment(1)
            });
        });

        // 3. SEND NOTIFICATIONS
        const userDoc = await db.doc(`users/${userId}`).get();
        const targetDoc = await db.doc(`users/${targetId}`).get();
        const userData = userDoc.data();
        const targetData = targetDoc.data();

        if (isMatch) {
            // -- MATCH NOTIFICATION (To Both) --
            const matchPayload = {
                notification: {
                    title: "It's a Match! 🎉",
                    body: "You have a new match! Start chatting now.",
                },
                data: {
                    type: "match",
                    matchId: matchId,
                },
            };

            const tokens = [];
            if (userData && userData.fcmToken) tokens.push(userData.fcmToken);
            if (targetData && targetData.fcmToken) tokens.push(targetData.fcmToken);

            if (tokens.length > 0) {
                await admin.messaging().sendToDevice(tokens, matchPayload);
            }
        } else {
            // -- LIKE NOTIFICATION (To Target Only) --
            // Only send if target has a token and it wasn't a match
            if (targetData && targetData.fcmToken) {
                const likePayload = {
                    notification: {
                        title: isSuperLike ? "You got a Super Like! 🌟" : "Someone liked you! 💛",
                        body: "Open the app to see who liked you.",
                    },
                    data: {
                        type: "like",
                        userId: userId, // Who liked them
                    },
                };
                await admin.messaging().sendToDevice(targetData.fcmToken, likePayload);
            }
        }

        return { matchId };
    });

exports.onMessageCreated = functions.firestore
    .document("chats/{matchId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const { matchId } = context.params;
        const messageData = snap.data();
        const senderId = messageData.senderId;
        const text = messageData.text || "Sent a photo";

        // Get chat metadata to find participants
        const chatDoc = await db.collection("chats").doc(matchId).get();
        if (!chatDoc.exists) return;

        const participants = chatDoc.data().participants || [];
        // Find the OTHER user (recipient)
        const recipientId = participants.find(uid => uid !== senderId);

        if (!recipientId) return;

        // Fetch recipient's token using get() which returns a Promise<DocumentSnapshot>
        // Use await to resolve the promise
        const recipientDoc = await db.collection("users").doc(recipientId).get();
        const recipientData = recipientDoc.data();

        if (recipientData && recipientData.fcmToken) {
            const payload = {
                notification: {
                    title: "New Message 💬",
                    body: text,
                },
                data: {
                    type: "chat",
                    matchId: matchId,
                },
            };
            await admin.messaging().sendToDevice(recipientData.fcmToken, payload);
        }
    });

exports.sendDailyRewardNotification = functions.pubsub
    .schedule("every 24 hours")
    .onRun(async (context) => {
        const payload = {
            notification: {
                title: "Daily Reward Available! 🎁",
                body: "Log in now to claim your free likes and boost.",
            },
            data: {
                type: "daily_reward",
            },
        };

        // Send to 'daily_rewards' topic
        await admin.messaging().sendToTopic("daily_rewards", payload);
        console.log("Sent daily reward notification");
    });
