// Settings for the public website. Fill these in before launch (see SETUP.md).
window.HRCFG = {
  // Supabase -> Project Settings -> API. The anon key is meant to be public:
  // the access rules in supabase/schema.sql protect the data.
  supabaseUrl: '',
  supabaseAnonKey: '',

  // Who runs the site. Shown in the Privacy notice and Terms (required in the EU).
  operator: {
    name: '',     // your name or company name
    address: '',  // postal address
    email: ''     // contact email for privacy questions
  }
};
