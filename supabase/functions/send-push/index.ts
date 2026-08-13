import { createClient } from 'npm:@supabase/supabase-js@2.39.3';
import { JWT } from 'npm:google-auth-library@9.6.3';

interface NotificationRecord {
  id: string;
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

interface DatabaseWebhookPayload {
  type: string;
  table: string;
  schema: string;
  record: NotificationRecord;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL');
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

if (!supabaseUrl || !serviceRoleKey || !serviceAccountJson) {
  throw new Error('Missing required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FIREBASE_SERVICE_ACCOUNT');
}

const serviceAccount = JSON.parse(serviceAccountJson) as {
  client_email: string;
  private_key: string;
  project_id: string;
};

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  global: { headers: { 'Accept': 'application/json' } },
});

async function getAccessToken(): Promise<string> {
  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });

  const tokens = await jwtClient.authorize();
  if (!tokens.access_token) {
    throw new Error('Unable to retrieve access token from Google service account');
  }

  return tokens.access_token;
}

function normalizeData(data: Record<string, unknown> | undefined): Record<string, string> {
  if (!data) {
    return {};
  }

  return Object.entries(data).reduce<Record<string, string>>((acc, [key, value]) => {
    if (value == null) {
      return acc;
    }

    acc[key] = typeof value === 'string' ? value : JSON.stringify(value);
    return acc;
  }, {});
}

async function getFcmToken(userId: string): Promise<string | null> {
  console.log('[send-push] Fetching fcm_token for user', userId);
  const { data, error } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    throw new Error(`Supabase error while fetching fcm_token: ${error.message}`);
  }

  console.log('[send-push] fcm_token lookup result for user', userId, data);
  return data?.fcm_token ?? null;
}

async function sendFcmNotification(token: string, record: NotificationRecord, accessToken: string) {
  const payload = {
    message: {
      token,
      notification: {
        title: record.title,
        body: record.body,
      },
      data: normalizeData(record.data),
      android: {
        priority: 'HIGH',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
      },
      webpush: {
        headers: {
          Urgency: 'high',
        },
      },
    },
  };

  console.log('[send-push] Sending FCM payload:', JSON.stringify(payload));

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(payload),
    },
  );

  const responseBody = await response.text();
  console.log('[send-push] FCM response status:', response.status, response.statusText);
  console.log('[send-push] FCM response body:', responseBody);

  if (!response.ok) {
    throw new Error(`FCM send failed: ${response.status} ${response.statusText} - ${responseBody}`);
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization')?.trim() ?? '';
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  let payload: DatabaseWebhookPayload;
  try {
    payload = await req.json();
  } catch (error) {
    console.error('[send-push] Invalid JSON payload:', error);
    return new Response(`Invalid JSON payload: ${error}`, { status: 400 });
  }

  console.log('[send-push] Received webhook payload:', JSON.stringify(payload));

  if (payload.table !== 'notifications' || payload.type !== 'INSERT') {
    console.log('[send-push] Ignored event: table/type mismatch', payload.table, payload.type);
    return new Response('Ignored event', { status: 200 });
  }

  const record = payload.record;
  if (!record?.user_id || !record.title || !record.body) {
    console.error('[send-push] Missing required notification record fields', record);
    return new Response('Missing required notification record fields', { status: 400 });
  }

  try {
    const fcmToken = await getFcmToken(record.user_id);
    if (!fcmToken) {
      return new Response('No FCM token registered for user', { status: 200 });
    }

    const accessToken = await getAccessToken();
    await sendFcmNotification(fcmToken, record, accessToken);

    return new Response('Notification sent', { status: 200 });
  } catch (error) {
    console.error('[send-push] Error sending notification:', error);
    return new Response(`Server error: ${error}`, { status: 500 });
  }
});
