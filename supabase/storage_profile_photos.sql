-- Créer le bucket dans le dashboard Supabase : nom = profile-photos, type = public
-- Puis exécuter ce script dans l'éditeur SQL Supabase.

DROP POLICY IF EXISTS "Profile photos are public" ON storage.objects;
CREATE POLICY "Profile photos are public"
ON storage.objects
FOR SELECT
USING (bucket_id = 'profile-photos');

DROP POLICY IF EXISTS "Authenticated users can upload profile photos" ON storage.objects;
CREATE POLICY "Authenticated users can upload profile photos"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'profile-photos'
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Authenticated users can update their own profile photos" ON storage.objects;
CREATE POLICY "Authenticated users can update their own profile photos"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'profile-photos'
  AND auth.uid() = owner
)
WITH CHECK (
  bucket_id = 'profile-photos'
  AND auth.uid() = owner
);

DROP POLICY IF EXISTS "Authenticated users can delete their own profile photos" ON storage.objects;
CREATE POLICY "Authenticated users can delete their own profile photos"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'profile-photos'
  AND auth.uid() = owner
);
