import { createClient } from "@refinedev/supabase";
import type { SupabaseClient } from "@supabase/supabase-js";
import { SUPABASE_KEY, SUPABASE_URL } from "./constants";

export const supabaseClient: SupabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_KEY,
  {
    db: {
      schema: "public",
    },
    auth: {
      persistSession: true,
      detectSessionInUrl: true,
    },
  }
);

// import { createClient } from "@supabase/supabase-js";

// const supabaseUrl  = import.meta.env.SUPABASE_URL as string;
// const supabaseKey  = import.meta.env.SUPABASE_ANON_KEY as string;

// export const supabaseClient = createClient(supabaseUrl, supabaseKey, {
//   auth: {
//     persistSession: true,
//     detectSessionInUrl: true,
//   },
// });