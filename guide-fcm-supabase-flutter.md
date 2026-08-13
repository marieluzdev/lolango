# Guide complet : Notifications Push avec Firebase Cloud Messaging (FCM) + Supabase (Flutter)

> Stack visée : Flutter + Supabase (Edge Functions en Deno) + FCM HTTP v1 API
> Dernière vérification des infos : août 2026

---

## 0. Vue d'ensemble de l'architecture

Supabase ne gère pas nativement l'envoi de push. Le pipeline complet ressemble à ça :

```
App Flutter (device)
   │  récupère le token FCM
   ▼
Table `profiles` (Supabase) — stocke fcm_token
   │
   │  un événement se produit (ex: nouveau message dans Lolango)
   ▼
Table `notifications` — INSERT d'une ligne
   │
   ▼
Database Webhook (Supabase) — déclenché sur INSERT
   │
   ▼
Edge Function (Deno) — génère un access token OAuth2 Google
   │  puis appelle l'API FCM v1
   ▼
FCM (Google) ─────────────► Notification reçue sur le device
```

Il faut donc configurer **4 briques** : Firebase, Flutter, Supabase (table + secrets), Edge Function.

---

## 1. Créer le projet Firebase et connecter Flutter

### 1.1 Créer le projet

1. Va sur https://console.firebase.google.com
2. "Ajouter un projet" → donne un nom (ex: `lolango-app`)
3. Google Analytics est optionnel, tu peux le désactiver pour l'instant.

### 1.2 Connecter Firebase à ton app Flutter (FlutterFire CLI)

C'est la méthode la plus fiable, elle configure automatiquement Android + iOS.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Sélectionne ton projet Firebase existant
- Coche les plateformes (Android / iOS)
- Ça génère automatiquement `lib/firebase_options.dart`, `google-services.json` (Android) et `GoogleService-Info.plist` (iOS)

### 1.3 Ajouter les dépendances Flutter

```yaml
dependencies:
  firebase_core: ^3.8.0
  firebase_messaging: ^15.1.5
  supabase_flutter: ^2.8.0
```

```bash
flutter pub get
```

### 1.4 Config Android

Dans `android/app/build.gradle.kts` (ou `.gradle`), vérifie que le plugin Google Services est appliqué :

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

Et dans `android/build.gradle.kts` (niveau projet) :

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

`minSdkVersion` doit être **≥ 21** (23 recommandé pour les notifications récentes).

### 1.5 Config iOS

1. Dans Xcode : active la capability **Push Notifications** et **Background Modes → Remote notifications**.
2. Sur https://developer.apple.com : génère une **clé APNs (.p8)**.
3. Dans la console Firebase → Paramètres du projet → Cloud Messaging → onglet "Apple" → upload la clé `.p8` + Key ID + Team ID.

---

## 2. Initialiser Firebase et récupérer le token FCM dans Flutter

### 2.1 Initialisation (main.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

### 2.2 Demander la permission + récupérer le token

```dart
class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Demande la permission (obligatoire iOS, silencieux sur Android < 13)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    // Important : le token peut être renouvelé par le système
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }
}
```

Appelle `PushNotificationService().initialize()` juste après la connexion de l'utilisateur (pas avant, sinon tu n'as pas de `userId`).

### 2.3 Gérer la réception (foreground / background / tap)

```dart
// App au premier plan
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Affiche une notif locale (via flutter_local_notifications par ex.)
});

// L'utilisateur tape sur la notif, app en arrière-plan
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Navigation vers l'écran concerné (go_router)
});

// App totalement fermée : handler top-level obligatoire
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// Dans main(), avant runApp :
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## 3. Préparer le schéma Supabase

### 3.1 Colonne token sur `profiles`

```sql
alter table public.profiles
  add column if not exists fcm_token text;
```

### 3.2 Table `notifications` (déclenche l'envoi)

```sql
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) not null,
  title text not null,
  body text not null,
  data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;

-- Seul le backend (service_role) insère/lit, pas besoin de policy user ici
```

> Astuce : tu peux aussi créer un **trigger Postgres** sur ta table `messages` (chat Lolango) qui insère automatiquement une ligne dans `notifications` — plutôt que d'insérer manuellement depuis le client.

Exemple de trigger :

```sql
create or replace function public.notify_new_message()
returns trigger as $$
begin
  insert into public.notifications (user_id, title, body, data)
  select
    match_user_id, -- l'autre participant à la conversation
    'Nouveau message',
    new.content,
    jsonb_build_object('conversation_id', new.conversation_id)
  from public.conversation_participants
  where conversation_id = new.conversation_id
    and user_id != new.sender_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_new_message
  after insert on public.messages
  for each row execute function public.notify_new_message();
```

---

## 4. Générer le compte de service Google (obligatoire pour FCM v1)

L'ancienne clé serveur "Legacy" ne fonctionne plus. Il faut une **clé de compte de service JSON**.

1. Console Firebase → ⚙️ **Paramètres du projet** → onglet **Comptes de service**
2. Clique sur **"Générer une nouvelle clé privée"**
3. Un fichier `.json` est téléchargé (ex: `lolango-firebase-adminsdk.json`) — **ne le commite jamais dans Git**.

Ce fichier contient `client_email`, `private_key`, `project_id`, etc. Il servira à générer un token OAuth2 côté serveur.

---

## 5. Créer l'Edge Function Supabase

### 5.1 Créer la fonction

```bash
supabase functions new send-push
```

### 5.2 Code de la fonction (`supabase/functions/send-push/index.ts`)

```typescript
import { createClient } from "jsr:@supabase/supabase-js@2";
import { JWT } from "https://esm.sh/google-auth-library@9";

interface NotificationRow {
  id: string;
  user_id: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: NotificationRow;
  schema: "public";
}

const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
const projectId = serviceAccount.project_id;

async function getAccessToken(): Promise<string> {
  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const tokens = await jwtClient.authorize();
  return tokens.access_token!;
}

Deno.serve(async (req) => {
  // Vérifie que l'appel vient bien du webhook Supabase (clé secrète)
  const authHeader = req.headers.get("Authorization");
  if (authHeader !== `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload: WebhookPayload = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: profile } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", payload.record.user_id)
    .single();

  if (!profile?.fcm_token) {
    return Response.json({ skipped: true, reason: "no fcm token" });
  }

  const accessToken = await getAccessToken();

  const fcmResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: profile.fcm_token,
          notification: {
            title: payload.record.title,
            body: payload.record.body,
          },
          data: payload.record.data ?? {},
          android: { priority: "high" },
          apns: {
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    },
  );

  const result = await fcmResponse.json();
  return Response.json(result, { status: fcmResponse.status });
});
```

### 5.3 Déployer et configurer les secrets

```bash
supabase link --project-ref TON_PROJECT_REF

# Le fichier JSON complet devient une variable d'environnement
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat lolango-firebase-adminsdk.json)"

supabase functions deploy send-push --no-verify-jwt
```

`--no-verify-jwt` car cette fonction sera appelée par un Database Webhook (avec une clé secrète), pas par un utilisateur authentifié.

---

## 6. Créer le Database Webhook

1. Dashboard Supabase → **Database → Webhooks**
2. **Create a new webhook**
3. Configuration :
   - **Table** : `notifications`
   - **Events** : `Insert`
   - **Type** : `Supabase Edge Functions`
   - **Edge Function** : `send-push`
   - **Method** : `POST`, **Timeout** : `1000`
   - **HTTP Headers** : "Add auth header with service key" (ajoute automatiquement le header `Authorization: Bearer <service_role_key>`)
4. **Create webhook**

---

## 7. Tester

1. Va dans le **Table Editor** → table `notifications`
2. Insère une ligne manuellement :

```sql
insert into public.notifications (user_id, title, body)
values ('UUID_DE_TON_USER_TEST', 'Test Lolango', 'Ceci est un test 🚀');
```

3. Le device associé au `fcm_token` de ce user doit recevoir la notif quasi instantanément.
4. En cas de souci, regarde les logs :

```bash
supabase functions logs send-push
```

---

## 8. Points d'attention spécifiques à ton contexte (Flutter/Riverpod)

- **Token null au premier lancement** : sur Android, `getToken()` peut renvoyer `null` très brièvement au tout premier démarrage (Google Play Services pas encore prêt). Toujours écouter `onTokenRefresh` en plus de l'appel initial.
- **Déconnexion** : pense à faire `_messaging.deleteToken()` et vider `fcm_token` dans `profiles` au sign-out, sinon un ancien user reçoit les notifs d'un nouveau compte sur le même device.
- **Riverpod** : expose ce service via un `Provider` initialisé après `authStateChanges` pour ne l'appeler qu'une fois l'utilisateur connecté.
- **Multi-device** : si un même utilisateur peut être connecté sur plusieurs devices (typique pour Lolango/Convive), ne stocke pas un seul `fcm_token` sur `profiles` mais crée une table `device_tokens (user_id, token, platform, updated_at)` et adapte l'Edge Function pour boucler sur tous les tokens de l'utilisateur.
- **RLS** : la table `notifications` ne doit avoir aucune policy `INSERT`/`SELECT` pour `anon`/`authenticated` — seul le `service_role` (via triggers `security definer` ou l'Edge Function) doit pouvoir y écrire.
- **Coût** : FCM est gratuit et illimité. Le seul coût est celui des Edge Functions Supabase (inclus dans le plan gratuit jusqu'à un certain volume).

---

## Résumé des fichiers/éléments à créer

| Élément                                             | Emplacement                                          |
| --------------------------------------------------- | ---------------------------------------------------- |
| Projet Firebase                                     | console.firebase.google.com                          |
| `google-services.json` / `GoogleService-Info.plist` | générés par `flutterfire configure`                  |
| `firebase_options.dart`                             | généré par `flutterfire configure`                   |
| Colonne `fcm_token`                                 | table `profiles` (SQL)                               |
| Table `notifications`                               | Supabase (SQL)                                       |
| Clé compte de service JSON                          | téléchargée depuis Firebase, mise en secret Supabase |
| Edge Function `send-push`                           | `supabase/functions/send-push/index.ts`              |
| Database Webhook                                    | Dashboard Supabase → Database → Webhooks             |

Crée ensuite un test dans parametre
