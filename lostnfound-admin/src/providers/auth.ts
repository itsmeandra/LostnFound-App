import { AuthProvider } from "@refinedev/core";
import { supabaseClient } from "./supabase-client";

export const authProvider: AuthProvider = {
  // ── Login ──
  login: async ({ email, password, }) => {
    // sign in with email and password
    const { data, error } = await supabaseClient.auth.signInWithPassword({
      email,
      password,
    });
    if (error) {
      return {
        success: false,
        error: { message: error.message, name: "Login gagal" },
      };
    }

    if (!data.user) {
      return {
        success: false, error: { message: "User tidak ditemukan", name: "Error" },
      };
    }

    // Verifikasi bahwah user = admin
    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("role")
      .eq("id", data.user.id)
      .single();

    // Logout jika bukan admin
    if (profile?.role !== "admin") {
      await supabaseClient.auth.signOut();
      return {
        success: false,
        error: {
          message: "Akses ditolak. Hanya admin yang dapat masuk.",
          name: "Unauthorized",
        },
      };
    }
    return { success: true };
  },

  // ── Logout ──
  logout: async () => {
    await supabaseClient.auth.signOut();
    return { success: true };
  },

  // ── Cek apakah masih login (dipanggil tiap navigasi) ──
  check: async () => {
    const { data } = await supabaseClient.auth.getSession();
    if (data.session) {
      return { authenticated: true };
    }
    return {
      authenticated: false,
      redirectTo: "/login",
    };
  },

  // ── Ambil info user yang sedang login ──
  getIdentity: async () => {
    const { data: {user} } = await supabaseClient.auth.getUser();
    if (!user) return null;

    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("full_name, email, role")
      .eq("id", user.id)
      .single();

    return {
      id: user.id,
      name: profile?.full_name ?? user.email,
      email: profile?.email ?? user.email,
      avatar: `https://api.dicebear.com/7.x/initials/svg?seed=${profile?.full_name}`,
    };
  },

  // ── Handle error (401 → redirect login) ──
  onError: async (error) => {
    if (error?.status === 401 ){
      return { logout: true };
    }
    return {};
  },
};

export default authProvider;
