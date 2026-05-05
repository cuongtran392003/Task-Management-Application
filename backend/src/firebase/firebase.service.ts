import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService {
  private readonly logger = new Logger(FirebaseService.name);
  private isInitialized = false;

  constructor() {
    try {
      // NOTE: You must provide a service-account.json from Firebase Console
      // and set GOOGLE_APPLICATION_CREDENTIALS environment variable
      // or initialize it directly with the service account object.
      if (process.env.FIREBASE_PROJECT_ID) {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          projectId: process.env.FIREBASE_PROJECT_ID,
        });
        this.isInitialized = true;
        this.logger.log('Firebase Admin initialized successfully');
      } else {
        this.logger.warn('FIREBASE_PROJECT_ID not set. Push notifications are disabled.');
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin', error);
    }
  }

  async sendPushNotification(tokens: string[], title: string, body: string, data?: any) {
    if (!this.isInitialized || tokens.length === 0) return;
    
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data,
      });
      this.logger.log(`Successfully sent ${response.successCount} messages`);
    } catch (error) {
      this.logger.error('Error sending push notification', error);
    }
  }
}
