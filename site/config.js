// Settings for the public website. Fill these in before launch (see SETUP.md).
window.HRCFG = {
  // Supabase -> Project Settings -> API. The anon key is meant to be public:
  // the access rules in supabase/schema.sql protect the data.
  supabaseUrl: 'https://zgcurwepgzhbaduvwcgs.supabase.co',
  supabaseAnonKey: 'sb_publishable_apjF2Y2GF3hMfxGYyVRSHw_4r8Exyvc',

  // Who runs the site. Shown in the Privacy notice and Terms (required in the EU).
  operator: {
    name: 'M. Ismail Oglou',     // your name or company name
    address: 'Katsoni Terma, Kimmeria, 67100 Xanthi, Greece',  // postal address
    email: 'info@humanresourceswww.eu'     // contact email for privacy questions
  }
};
