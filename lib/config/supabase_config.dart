/// Supabase project credentials.
///
/// The anon key is meant to be public — it ships inside the compiled app.
/// Access control lives in the RLS policies on the checkme_* tables
/// (see supabase/0001_checkme_tables.sql), not in keeping this key secret.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = 'https://xtdzynkzqnrvmapvpgyq.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0ZHp5bmt6cW5ydm1hcHZwZ3lxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk3MDA5NDcsImV4cCI6MjEwNTI3Njk0N30.aYlUZLNgSgjYn4bhdX2anPeQY-PS79blkmfDN0lhwb0';
}
