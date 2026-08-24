const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');

initializeApp();

const db = getDatabase();

function assertRoomId(roomId) {
  if (typeof roomId !== 'string' || roomId.length < 1 || roomId.length > 128) {
    throw new HttpsError('invalid-argument', 'A valid roomId is required.');
  }
  if (!/^[A-Za-z0-9_-]+$/.test(roomId)) {
    throw new HttpsError('invalid-argument', 'Invalid roomId.');
  }
}

exports.rollDice = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }

  const { roomId } = request.data || {};
  assertRoomId(roomId);

  const uid = request.auth.uid;
  const playerId = `user_${uid}`;
  const roomRef = db.ref(`games/${roomId}`);
  const playerSnapshot = await roomRef.child(`players/${playerId}`).once('value');

  if (!playerSnapshot.exists()) {
    throw new HttpsError('permission-denied', 'You are not a player in this game.');
  }

  const stateRef = roomRef.child('state');
  let requestedRoll = null;

  const result = await stateRef.transaction((state) => {
    if (!state || state.phase !== 'rolling' || state.current_turn !== playerId) {
      return;
    }

    const diceRoll = Math.floor(Math.random() * 6) + 1;
    requestedRoll = diceRoll;

    return {
      ...state,
      dice_roll: diceRoll,
      phase: 'moving',
      roll_request: null,
    };
  });

  if (!result.committed || requestedRoll === null) {
    throw new HttpsError(
      'failed-precondition',
      'The game is not accepting a dice roll for your turn.'
    );
  }

  return { diceRoll: requestedRoll };
});
