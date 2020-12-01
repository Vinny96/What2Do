import * as functions from 'firebase-functions';
import { DataSnapshot } from 'firebase-functions/lib/providers/database';


// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
export const helloWorld = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase");
  console.log("This message is coming to you from a cloud function that is connected to my What2Do project.");
});

exports.testing = functions.https.onCall(() => {
  console.log("Testing from a google cloud function.")
});

exports.printReminderDate = functions.https.onCall((Date) =>{
  console.log(Date)
  console.log("The date should be printed above.")
});

exports.printReminderTime = functions.https.onCall((Date) =>
{


});