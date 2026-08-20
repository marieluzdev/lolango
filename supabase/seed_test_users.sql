-- =============================================================================
-- SEED : 20 UTILISATEURS DE TEST (10 Femmes + 10 Hommes)
-- =============================================================================
-- Utilisateurs réels ciblés :
--   eyoumguillaume1@gmail.com  → 31e475f2-53f1-4d17-97ca-657434f7e635
--   milvkessy@gmail.com        → c38c4074-fe79-4e34-91f2-dbab7a7a6cb1
--   dineshkuruvilla@gmail.com  → b7895654-47f4-4c1a-a146-6f59953520a9
--
--   Les 20 fake users likent ces 3 profils → apparaissent dans "Likes reçus"
--   Execute dans : Supabase Dashboard > SQL Editor
-- =============================================================================

DO $$
DECLARE
  -- Les 3 vrais utilisateurs
  uid_guillaume UUID := '31e475f2-53f1-4d17-97ca-657434f7e635';
  uid_milvkessy UUID := 'c38c4074-fe79-4e34-91f2-dbab7a7a6cb1';
  uid_dinesh    UUID := 'b7895654-47f4-4c1a-a146-6f59953520a9';

  -- UUIDs stables pour les 20 utilisateurs de test
  u_f01 UUID := 'a1b2c3d4-0001-0001-0001-000000000001';
  u_f02 UUID := 'a1b2c3d4-0001-0001-0001-000000000002';
  u_f03 UUID := 'a1b2c3d4-0001-0001-0001-000000000003';
  u_f04 UUID := 'a1b2c3d4-0001-0001-0001-000000000004';
  u_f05 UUID := 'a1b2c3d4-0001-0001-0001-000000000005';
  u_f06 UUID := 'a1b2c3d4-0001-0001-0001-000000000006';
  u_f07 UUID := 'a1b2c3d4-0001-0001-0001-000000000007';
  u_f08 UUID := 'a1b2c3d4-0001-0001-0001-000000000008';
  u_f09 UUID := 'a1b2c3d4-0001-0001-0001-000000000009';
  u_f10 UUID := 'a1b2c3d4-0001-0001-0001-000000000010';
  u_m01 UUID := 'b2c3d4e5-0002-0002-0002-000000000001';
  u_m02 UUID := 'b2c3d4e5-0002-0002-0002-000000000002';
  u_m03 UUID := 'b2c3d4e5-0002-0002-0002-000000000003';
  u_m04 UUID := 'b2c3d4e5-0002-0002-0002-000000000004';
  u_m05 UUID := 'b2c3d4e5-0002-0002-0002-000000000005';
  u_m06 UUID := 'b2c3d4e5-0002-0002-0002-000000000006';
  u_m07 UUID := 'b2c3d4e5-0002-0002-0002-000000000007';
  u_m08 UUID := 'b2c3d4e5-0002-0002-0002-000000000008';
  u_m09 UUID := 'b2c3d4e5-0002-0002-0002-000000000009';
  u_m10 UUID := 'b2c3d4e5-0002-0002-0002-000000000010';

BEGIN

-- =============================================================================
-- ÉTAPE 1 : Créer les 20 utilisateurs dans auth.users
-- =============================================================================

INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data,
  is_super_admin, role, aud
) VALUES
  (u_f01,'sofia.martin@test.lolango.app',   crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f02,'camille.leroy@test.lolango.app',  crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f03,'ines.dupont@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f04,'amira.benali@test.lolango.app',   crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f05,'lea.rousseau@test.lolango.app',   crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f06,'jade.moreau@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f07,'zara.diallo@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f08,'manon.petit@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f09,'sarah.lambert@test.lolango.app',  crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_f10,'nadia.chen@test.lolango.app',     crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m01,'lucas.bernard@test.lolango.app',  crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m02,'theo.girard@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m03,'adam.kone@test.lolango.app',      crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m04,'noah.marchand@test.lolango.app',  crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m05,'ryan.lefebvre@test.lolango.app',  crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m06,'mael.simon@test.lolango.app',     crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m07,'enzo.durand@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m08,'karim.bensalem@test.lolango.app', crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m09,'hugo.robert@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated'),
  (u_m10,'liam.nguyen@test.lolango.app',    crypt('Test1234!',gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}',false,'authenticated','authenticated')
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- ÉTAPE 2 : Profils publics
-- =============================================================================

INSERT INTO public.profiles (
  id, first_name, username, birth_date, gender,
  discovery_preferences, location_label, latitude, longitude,
  bio, profile_completed
) VALUES
  (u_f01,'Sofia',   '@sofia_mrt',   '2000-03-14','Femme', ARRAY['Homme','Femme'],'Paris, France',     48.8566, 2.3522, 'Passionnée de photographie et de voyages 📸✈️ Toujours en quête de nouvelles aventures !', true),
  (u_f02,'Camille', '@camille_lr',  '1999-07-22','Femme', ARRAY['Homme'],        'Lyon, France',      45.7640, 4.8357, 'Étudiante en droit, fan de séries et de bonne cuisine 🍝 Dis-moi ton restaurant préféré !', true),
  (u_f03,'Inès',    '@ines_dp',     '2001-11-05','Femme', ARRAY['Homme','Femme'],'Marseille, France',  43.2965, 5.3698, 'Danseuse le weekend, codeuse la semaine 💃💻 Équilibre parfait.', true),
  (u_f04,'Amira',   '@amira_bn',    '2000-01-30','Femme', ARRAY['Homme'],        'Bordeaux, France',  44.8378,-0.5792, 'Yoga addict & grande voyageuse 🧘‍♀️ J''ai visité 12 pays, peux-tu battre mon record ?', true),
  (u_f05,'Léa',     '@lea_rss',     '1998-09-18','Femme', ARRAY['Homme'],        'Toulouse, France',  43.6047, 1.4442, 'Graphiste freelance 🎨 Je transforme les idées en art. Et toi, tu crées quoi ?', true),
  (u_f06,'Jade',    '@jade_mrx',    '2002-04-07','Femme', ARRAY['Homme','Femme'],'Nantes, France',    47.2184,-1.5536, 'Bookworm & série-addict 📚🎬 Always looking for good recommendations !', true),
  (u_f07,'Zara',    '@zara_dll',    '1999-12-25','Femme', ARRAY['Homme'],        'Lille, France',     50.6292, 3.0573, 'Musicienne & créatrice de contenu 🎵📲 La vie est trop courte pour la musique triste.', true),
  (u_f08,'Manon',   '@manon_pt',    '2001-06-12','Femme', ARRAY['Homme'],        'Strasbourg, France',48.5734, 7.7521, 'Infirmière en devenir 💊 Sport le matin, Netflix le soir. L''équilibre parfait.', true),
  (u_f09,'Sarah',   '@sarah_lmb',   '2000-08-03','Femme', ARRAY['Homme','Femme'],'Nice, France',      43.7102, 7.2620, 'Entre la mer et les montagnes, mon cœur balance 🌊⛰️ Chef pâtissière en herbe 🥐', true),
  (u_f10,'Nadia',   '@nadia_ch',    '1997-02-19','Femme', ARRAY['Homme'],        'Paris, France',     48.8566, 2.3522, 'Développeuse iOS & passionnée d''IA 🤖📱 On parle tech ou on sort courir ? Les deux ?', true),
  (u_m01,'Lucas',   '@lucas_bnd',   '1999-05-28','Homme', ARRAY['Femme'],        'Paris, France',     48.8566, 2.3522, 'Ingénieur et photographe amateur 📷 Je cherche quelqu''un pour explorer Paris ensemble.', true),
  (u_m02,'Théo',    '@theo_grd',    '2001-03-15','Homme', ARRAY['Femme','Homme'],'Lyon, France',      45.7640, 4.8357, 'Musicien le soir, étudiant en informatique le jour 🎸💻 La passion, c''est tout.', true),
  (u_m03,'Adam',    '@adam_kn',     '2000-09-02','Homme', ARRAY['Femme'],        'Bordeaux, France',  44.8378,-0.5792, 'Footballeur passionné ⚽ Toujours partant pour un match ou un brunch du dimanche 🍳', true),
  (u_m04,'Noah',    '@noah_mch',    '1998-11-17','Homme', ARRAY['Femme'],        'Marseille, France',  43.2965, 5.3698, 'Entrepreneur & trader 📈 Je vis pour construire des choses qui comptent. Et toi ?', true),
  (u_m05,'Ryan',    '@ryan_lfv',    '2002-07-04','Homme', ARRAY['Femme'],        'Toulouse, France',  43.6047, 1.4442, 'Barista le weekend, étudiant en marketing la semaine ☕📣 Let''s grab a coffee?', true),
  (u_m06,'Maël',    '@mael_sim',    '1999-01-21','Homme', ARRAY['Femme','Homme'],'Nantes, France',    47.2184,-1.5536, 'Randonneur & écolo convaincu 🥾♻️ La nature me ressource. Viens en forêt avec moi.', true),
  (u_m07,'Enzo',    '@enzo_drd',    '2001-10-30','Homme', ARRAY['Femme'],        'Paris, France',     48.8566, 2.3522, 'Designer UI/UX 🎨 J''aime les interfaces belles et les conversations profondes.', true),
  (u_m08,'Karim',   '@karim_bs',    '2000-04-14','Homme', ARRAY['Femme'],        'Lille, France',     50.6292, 3.0573, 'Passionné de cybersécurité 🔐 Je protège les données le jour, fais de la musique la nuit 🎧', true),
  (u_m09,'Hugo',    '@hugo_rbt',    '1997-08-09','Homme', ARRAY['Femme'],        'Nice, France',      43.7102, 7.2620, 'Kiné sportif 🏊 Méditation le matin, course à pied le soir. La santé avant tout !', true),
  (u_m10,'Liam',    '@liam_ngy',    '2001-05-23','Homme', ARRAY['Femme','Homme'],'Strasbourg, France',48.5734, 7.7521, 'Développeur Flutter & game dev amateur 🕹️📱 Si tu connais la diff entre Riverpod et Provider, on est faits pour s''entendre.', true)
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name, username = EXCLUDED.username,
  birth_date = EXCLUDED.birth_date, gender = EXCLUDED.gender,
  discovery_preferences = EXCLUDED.discovery_preferences,
  location_label = EXCLUDED.location_label, latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude, bio = EXCLUDED.bio,
  profile_completed = EXCLUDED.profile_completed;

-- =============================================================================
-- ÉTAPE 3 : Photos de profil (Unsplash — portrait réaliste)
-- =============================================================================

DELETE FROM public.profile_photos
WHERE user_id = ANY(ARRAY[u_f01,u_f02,u_f03,u_f04,u_f05,u_f06,u_f07,u_f08,u_f09,u_f10,
                           u_m01,u_m02,u_m03,u_m04,u_m05,u_m06,u_m07,u_m08,u_m09,u_m10]);

INSERT INTO public.profile_photos (user_id, url, is_primary, position) VALUES
  -- FEMMES
  (u_f01,'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&q=80',true,0),
  (u_f01,'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&q=80',false,1),
  (u_f02,'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=600&q=80',true,0),
  (u_f02,'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=600&q=80',false,1),
  (u_f03,'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600&q=80',true,0),
  (u_f03,'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=600&q=80',false,1),
  (u_f04,'https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?w=600&q=80',true,0),
  (u_f04,'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&q=80',false,1),
  (u_f05,'https://images.unsplash.com/photo-1554151228-14d9def656e4?w=600&q=80',true,0),
  (u_f05,'https://images.unsplash.com/photo-1541823709867-1b206113eafd?w=600&q=80',false,1),
  (u_f06,'https://images.unsplash.com/photo-1528892952291-009c663ce843?w=600&q=80',true,0),
  (u_f06,'https://images.unsplash.com/photo-1534751516642-a1af1ef26a56?w=600&q=80',false,1),
  (u_f07,'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=600&q=80',true,0),
  (u_f07,'https://images.unsplash.com/photo-1546961342-ea5f62d5a27b?w=600&q=80',false,1),
  (u_f08,'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=600&q=80',true,0),
  (u_f08,'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600&q=80',false,1),
  (u_f09,'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&q=80',true,0),
  (u_f09,'https://images.unsplash.com/photo-1511485977113-f34c92461ad9?w=600&q=80',false,1),
  (u_f10,'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=600&q=80',true,0),
  (u_f10,'https://images.unsplash.com/photo-1561406636-b80293969660?w=600&q=80',false,1),
  -- HOMMES
  (u_m01,'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600&q=80',true,0),
  (u_m01,'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',false,1),
  (u_m02,'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&q=80',true,0),
  (u_m02,'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?w=600&q=80',false,1),
  (u_m03,'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=600&q=80',true,0),
  (u_m03,'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&q=80',false,1),
  (u_m04,'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=600&q=80',true,0),
  (u_m04,'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=600&q=80',false,1),
  (u_m05,'https://images.unsplash.com/photo-1463453091185-61582044d556?w=600&q=80',true,0),
  (u_m05,'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&q=80',false,1),
  (u_m06,'https://images.unsplash.com/photo-1543132220-3ec99c6094dc?w=600&q=80',true,0),
  (u_m06,'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=600&q=80',false,1),
  (u_m07,'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=600&q=80',true,0),
  (u_m07,'https://images.unsplash.com/photo-1488161628813-04466f872be2?w=600&q=80',false,1),
  (u_m08,'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=600&q=80',true,0),
  (u_m08,'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=600&q=80',false,1),
  (u_m09,'https://images.unsplash.com/photo-1557862921-37829c790f19?w=600&q=80',true,0),
  (u_m09,'https://images.unsplash.com/photo-1618641986557-1ecd230959aa?w=600&q=80',false,1),
  (u_m10,'https://images.unsplash.com/photo-1555952517-2e8e729e0b44?w=600&q=80',true,0),
  (u_m10,'https://images.unsplash.com/photo-1593104547489-5cfb3839a3b5?w=600&q=80',false,1);

-- =============================================================================
-- ÉTAPE 4 : Localisations
-- =============================================================================

INSERT INTO public.user_locations (user_id, country, city, locality, latitude, longitude, is_approximate) VALUES
  (u_f01,'France','Paris',       'Île-de-France',             48.8566, 2.3522, false),
  (u_f02,'France','Lyon',        'Auvergne-Rhône-Alpes',      45.7640, 4.8357, false),
  (u_f03,'France','Marseille',   'Provence-Alpes-Côte d''Azur',43.2965, 5.3698, false),
  (u_f04,'France','Bordeaux',    'Nouvelle-Aquitaine',        44.8378,-0.5792, false),
  (u_f05,'France','Toulouse',    'Occitanie',                 43.6047, 1.4442, false),
  (u_f06,'France','Nantes',      'Pays de la Loire',          47.2184,-1.5536, false),
  (u_f07,'France','Lille',       'Hauts-de-France',           50.6292, 3.0573, false),
  (u_f08,'France','Strasbourg',  'Grand Est',                 48.5734, 7.7521, false),
  (u_f09,'France','Nice',        'Provence-Alpes-Côte d''Azur',43.7102, 7.2620, false),
  (u_f10,'France','Paris',       'Île-de-France',             48.8566, 2.3522, false),
  (u_m01,'France','Paris',       'Île-de-France',             48.8566, 2.3522, false),
  (u_m02,'France','Lyon',        'Auvergne-Rhône-Alpes',      45.7640, 4.8357, false),
  (u_m03,'France','Bordeaux',    'Nouvelle-Aquitaine',        44.8378,-0.5792, false),
  (u_m04,'France','Marseille',   'Provence-Alpes-Côte d''Azur',43.2965, 5.3698, false),
  (u_m05,'France','Toulouse',    'Occitanie',                 43.6047, 1.4442, false),
  (u_m06,'France','Nantes',      'Pays de la Loire',          47.2184,-1.5536, false),
  (u_m07,'France','Paris',       'Île-de-France',             48.8566, 2.3522, false),
  (u_m08,'France','Lille',       'Hauts-de-France',           50.6292, 3.0573, false),
  (u_m09,'France','Nice',        'Provence-Alpes-Côte d''Azur',43.7102, 7.2620, false),
  (u_m10,'France','Strasbourg',  'Grand Est',                 48.5734, 7.7521, false)
ON CONFLICT (user_id) DO NOTHING;

-- =============================================================================
-- ÉTAPE 5 : Discovery preferences
-- =============================================================================

INSERT INTO public.discovery_preferences (user_id, preferred_gender) VALUES
  (u_f01,ARRAY['Homme','Femme']), (u_f02,ARRAY['Homme']),
  (u_f03,ARRAY['Homme','Femme']), (u_f04,ARRAY['Homme']),
  (u_f05,ARRAY['Homme']),         (u_f06,ARRAY['Homme','Femme']),
  (u_f07,ARRAY['Homme']),         (u_f08,ARRAY['Homme']),
  (u_f09,ARRAY['Homme','Femme']), (u_f10,ARRAY['Homme']),
  (u_m01,ARRAY['Femme']),         (u_m02,ARRAY['Femme','Homme']),
  (u_m03,ARRAY['Femme']),         (u_m04,ARRAY['Femme']),
  (u_m05,ARRAY['Femme']),         (u_m06,ARRAY['Femme','Homme']),
  (u_m07,ARRAY['Femme']),         (u_m08,ARRAY['Femme']),
  (u_m09,ARRAY['Femme']),         (u_m10,ARRAY['Femme','Homme'])
ON CONFLICT (user_id) DO NOTHING;

-- =============================================================================
-- ÉTAPE 6 : Réseaux sociaux
-- =============================================================================

INSERT INTO public.profile_socials (user_id, platform, username) VALUES
  (u_f01,'Instagram','sofia.mrt'),         (u_f01,'Snapchat','sofia_snap'),
  (u_f02,'Instagram','camille.leroy'),     (u_f02,'TikTok','@camille_lr'),
  (u_f03,'Instagram','ines.dp.dance'),     (u_f03,'Snapchat','ines_dp'),
  (u_f04,'Instagram','amira_yoga_life'),   (u_f04,'Snapchat','amira_bn'),
  (u_f05,'Instagram','lea.design'),        (u_f05,'TikTok','@lea_graphiste'),
  (u_f06,'Instagram','jade_reads'),        (u_f06,'Snapchat','jade_moreau'),
  (u_f07,'Instagram','zara.music'),        (u_f07,'TikTok','@zara_creates'),
  (u_f08,'Instagram','manon.sante'),       (u_f08,'Snapchat','manon_pt'),
  (u_f09,'Instagram','sarah.pastry'),      (u_f09,'TikTok','@sarah_patisserie'),
  (u_f10,'Instagram','nadia.code'),        (u_f10,'TikTok','@nadia_tech'),
  (u_m01,'Instagram','lucas.photo.paris'), (u_m01,'Snapchat','lucas_bnd'),
  (u_m02,'Instagram','theo.music.ly'),     (u_m02,'TikTok','@theo_grd'),
  (u_m03,'Instagram','adam.foot.bx'),      (u_m03,'Snapchat','adam_kn'),
  (u_m04,'Instagram','noah.entrepreneur'), (u_m04,'Snapchat','noah_mch'),
  (u_m05,'Instagram','ryan.barista'),      (u_m05,'TikTok','@ryan_coffee'),
  (u_m06,'Instagram','mael.nature.life'),  (u_m06,'Snapchat','mael_sim'),
  (u_m07,'Instagram','enzo.design.ui'),    (u_m07,'TikTok','@enzo_ux'),
  (u_m08,'Instagram','karim.cyber'),       (u_m08,'Snapchat','karim_bs'),
  (u_m09,'Instagram','hugo.kine.sport'),   (u_m09,'Snapchat','hugo_rbt'),
  (u_m10,'Instagram','liam.flutter.dev'),  (u_m10,'TikTok','@liam_codes')
ON CONFLICT (user_id, platform) DO NOTHING;

-- =============================================================================
-- ÉTAPE 7 : Intérêts (4 par profil)
-- =============================================================================

INSERT INTO public.profile_interests (user_id, interest_id)
SELECT v.uid, i.id
FROM public.interests i
JOIN public.interest_categories ic ON ic.id = i.category_id
JOIN (VALUES
  -- Sofia
  (u_f01,'arts-culture','Photographie'),(u_f01,'voyage-lifestyle','Voyage'),
  (u_f01,'arts-culture','Musique'),     (u_f01,'voyage-lifestyle','Café'),
  -- Camille
  (u_f02,'etudes','Lecture'),           (u_f02,'arts-culture','Séries'),
  (u_f02,'voyage-lifestyle','Découverte de restaurants'),(u_f02,'divertissement','Quiz'),
  -- Inès
  (u_f03,'arts-culture','Danse'),       (u_f03,'tech','Programmation'),
  (u_f03,'sport','Running'),            (u_f03,'bien-etre','Yoga'),
  -- Amira
  (u_f04,'bien-etre','Yoga'),           (u_f04,'voyage-lifestyle','Voyage'),
  (u_f04,'sport','Natation'),           (u_f04,'bien-etre','Méditation'),
  -- Léa
  (u_f05,'tech','Design UI/UX'),        (u_f05,'arts-culture','Dessin'),
  (u_f05,'voyage-lifestyle','Mode'),    (u_f05,'ambition','Freelance'),
  -- Jade
  (u_f06,'etudes','Lecture'),           (u_f06,'arts-culture','Cinéma'),
  (u_f06,'arts-culture','Séries'),      (u_f06,'divertissement','Anime & Manga'),
  -- Zara
  (u_f07,'arts-culture','Musique'),     (u_f07,'arts-culture','Chant'),
  (u_f07,'ambition','Création de contenu'),(u_f07,'vie-sociale','Soirées'),
  -- Manon
  (u_f08,'sport','Running'),            (u_f08,'sport','Salle de sport'),
  (u_f08,'bien-etre','Nutrition'),      (u_f08,'arts-culture','Séries'),
  -- Sarah
  (u_f09,'voyage-lifestyle','Cuisine'), (u_f09,'voyage-lifestyle','Pâtisserie'),
  (u_f09,'nature','Randonnée'),         (u_f09,'sport','Natation'),
  -- Nadia
  (u_f10,'tech','Programmation'),       (u_f10,'tech','Intelligence artificielle'),
  (u_f10,'sport','Running'),            (u_f10,'bien-etre','Méditation'),
  -- Lucas
  (u_m01,'arts-culture','Photographie'),(u_m01,'voyage-lifestyle','Voyage'),
  (u_m01,'sport','Running'),            (u_m01,'tech','Développement Web'),
  -- Théo
  (u_m02,'arts-culture','Musique'),     (u_m02,'tech','Programmation'),
  (u_m02,'divertissement','Gaming'),    (u_m02,'vie-sociale','Faire de nouvelles rencontres'),
  -- Adam
  (u_m03,'sport','Football'),           (u_m03,'sport','Basketball'),
  (u_m03,'voyage-lifestyle','Découverte de restaurants'),(u_m03,'vie-sociale','Sorties entre amis'),
  -- Noah
  (u_m04,'ambition','Entrepreneuriat'), (u_m04,'ambition','Trading'),
  (u_m04,'ambition','Investissement'),  (u_m04,'etudes','Finance'),
  -- Ryan
  (u_m05,'voyage-lifestyle','Café'),    (u_m05,'etudes','Marketing'),
  (u_m05,'vie-sociale','Faire de nouvelles rencontres'),(u_m05,'voyage-lifestyle','Découverte de restaurants'),
  -- Maël
  (u_m06,'nature','Randonnée'),         (u_m06,'nature','Camping'),
  (u_m06,'nature','Écologie'),          (u_m06,'sport','Cyclisme'),
  -- Enzo
  (u_m07,'tech','Design UI/UX'),        (u_m07,'arts-culture','Photographie'),
  (u_m07,'voyage-lifestyle','Voyage'),  (u_m07,'ambition','Freelance'),
  -- Karim
  (u_m08,'tech','Cybersécurité'),       (u_m08,'arts-culture','Musique'),
  (u_m08,'divertissement','Gaming'),    (u_m08,'ambition','Startups'),
  -- Hugo
  (u_m09,'sport','Natation'),           (u_m09,'sport','Running'),
  (u_m09,'bien-etre','Méditation'),     (u_m09,'bien-etre','Yoga'),
  -- Liam
  (u_m10,'tech','Flutter'),             (u_m10,'tech','Programmation'),
  (u_m10,'divertissement','Jeux vidéo'),(u_m10,'divertissement','Gaming')
) AS v(uid, cat_slug, interest_name)
  ON ic.slug = v.cat_slug AND i.name = v.interest_name
ON CONFLICT (user_id, interest_id) DO NOTHING;

-- =============================================================================
-- ÉTAPE 8 : Interactions — les 20 likent TON profil
-- =============================================================================
-- → Ils apparaîtront dans l'onglet "Likes reçus"
-- → En likant en retour dans l'app → match automatique !

-- → Likes vers eyoumguillaume1
INSERT INTO public.interactions (user_id, target_id, status) VALUES
  (u_f01,uid_guillaume,'like'),(u_f02,uid_guillaume,'like'),(u_f03,uid_guillaume,'like'),
  (u_f04,uid_guillaume,'like'),(u_f05,uid_guillaume,'like'),(u_f06,uid_guillaume,'like'),
  (u_f07,uid_guillaume,'like'),(u_f08,uid_guillaume,'like'),(u_f09,uid_guillaume,'like'),
  (u_f10,uid_guillaume,'like'),(u_m01,uid_guillaume,'like'),(u_m02,uid_guillaume,'like'),
  (u_m03,uid_guillaume,'like'),(u_m04,uid_guillaume,'like'),(u_m05,uid_guillaume,'like'),
  (u_m06,uid_guillaume,'like'),(u_m07,uid_guillaume,'like'),(u_m08,uid_guillaume,'like'),
  (u_m09,uid_guillaume,'like'),(u_m10,uid_guillaume,'like')
ON CONFLICT (user_id, target_id) DO NOTHING;

-- → Likes vers milvkessy
INSERT INTO public.interactions (user_id, target_id, status) VALUES
  (u_f01,uid_milvkessy,'like'),(u_f02,uid_milvkessy,'like'),(u_f03,uid_milvkessy,'like'),
  (u_f04,uid_milvkessy,'like'),(u_f05,uid_milvkessy,'like'),(u_f06,uid_milvkessy,'like'),
  (u_f07,uid_milvkessy,'like'),(u_f08,uid_milvkessy,'like'),(u_f09,uid_milvkessy,'like'),
  (u_f10,uid_milvkessy,'like'),(u_m01,uid_milvkessy,'like'),(u_m02,uid_milvkessy,'like'),
  (u_m03,uid_milvkessy,'like'),(u_m04,uid_milvkessy,'like'),(u_m05,uid_milvkessy,'like'),
  (u_m06,uid_milvkessy,'like'),(u_m07,uid_milvkessy,'like'),(u_m08,uid_milvkessy,'like'),
  (u_m09,uid_milvkessy,'like'),(u_m10,uid_milvkessy,'like')
ON CONFLICT (user_id, target_id) DO NOTHING;

-- → Likes vers dineshkuruvilla
INSERT INTO public.interactions (user_id, target_id, status) VALUES
  (u_f01,uid_dinesh,'like'),(u_f02,uid_dinesh,'like'),(u_f03,uid_dinesh,'like'),
  (u_f04,uid_dinesh,'like'),(u_f05,uid_dinesh,'like'),(u_f06,uid_dinesh,'like'),
  (u_f07,uid_dinesh,'like'),(u_f08,uid_dinesh,'like'),(u_f09,uid_dinesh,'like'),
  (u_f10,uid_dinesh,'like'),(u_m01,uid_dinesh,'like'),(u_m02,uid_dinesh,'like'),
  (u_m03,uid_dinesh,'like'),(u_m04,uid_dinesh,'like'),(u_m05,uid_dinesh,'like'),
  (u_m06,uid_dinesh,'like'),(u_m07,uid_dinesh,'like'),(u_m08,uid_dinesh,'like'),
  (u_m09,uid_dinesh,'like'),(u_m10,uid_dinesh,'like')
ON CONFLICT (user_id, target_id) DO NOTHING;

RAISE NOTICE '✅ 20 utilisateurs de test créés avec succès !';
RAISE NOTICE '   • 10 femmes : Sofia, Camille, Inès, Amira, Léa, Jade, Zara, Manon, Sarah, Nadia';
RAISE NOTICE '   • 10 hommes : Lucas, Théo, Adam, Noah, Ryan, Maël, Enzo, Karim, Hugo, Liam';
RAISE NOTICE '👀 Ouvre l''app → onglet "Likes reçus" → 20 profils t''attendent !';
RAISE NOTICE '💘 Like-les pour créer des matchs !';

END $$;

-- =============================================================================
-- NETTOYAGE (décommenter pour supprimer les données de test)
-- =============================================================================
-- DO $$
-- DECLARE
--   test_ids UUID[] := ARRAY[
--     'a1b2c3d4-0001-0001-0001-000000000001'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000002'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000003'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000004'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000005'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000006'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000007'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000008'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000009'::uuid,
--     'a1b2c3d4-0001-0001-0001-000000000010'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000001'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000002'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000003'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000004'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000005'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000006'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000007'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000008'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000009'::uuid,
--     'b2c3d4e5-0002-0002-0002-000000000010'::uuid
--   ];
-- BEGIN
--   DELETE FROM auth.users WHERE id = ANY(test_ids);
--   RAISE NOTICE '🗑️ 20 utilisateurs de test supprimés.';
-- END $$;
