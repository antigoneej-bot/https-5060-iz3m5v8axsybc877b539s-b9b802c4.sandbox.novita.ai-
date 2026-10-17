import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { onRequest } from 'firebase-functions/v2/https';
import { createSocialAuthFlow, createSocialAuthHandler } from './social-auth-core.js';

const kakaoSecret = defineSecret('KAKAO_CLIENT_SECRET');
const naverSecret = defineSecret('NAVER_CLIENT_SECRET');
const facebookSecret = defineSecret('FACEBOOK_APP_SECRET');

export const socialAuth = onRequest({region:'asia-northeast3', maxInstances:3,
  timeoutSeconds:60, memory:'256MiB', secrets:[kakaoSecret, naverSecret, facebookSecret]}, async (req, res) => {
  // Lazy access: importing this module does not race index.js initializeApp().
  const flow = createSocialAuthFlow({db:getFirestore(), auth:getAuth(), getConfig(provider) {
    return {
      callbackUrl:process.env.SOCIAL_AUTH_CALLBACK_URL,
      clientId:provider === 'kakao' ? process.env.KAKAO_CLIENT_ID
        : provider === 'naver' ? process.env.NAVER_CLIENT_ID : process.env.FACEBOOK_APP_ID,
      clientSecret:provider === 'kakao' ? kakaoSecret.value()
        : provider === 'naver' ? naverSecret.value() : facebookSecret.value(),
      graphVersion:provider === 'facebook' ? process.env.FACEBOOK_GRAPH_VERSION : undefined,
    };
  }});
  await createSocialAuthHandler({flow,
    expectedAppId:process.env.GARDEN_ANDROID_APP_ID,
    verifyAppCheck:token => getAppCheck().verifyToken(token),
  })(req, res);
});
