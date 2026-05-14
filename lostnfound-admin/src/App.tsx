import { Refine, Authenticated } from "@refinedev/core";
import { App as AntdApp } from "antd";
import { RefineKbar, RefineKbarProvider } from "@refinedev/kbar";
import {
  useNotificationProvider,
  ThemedLayout,
  ErrorComponent,
} from "@refinedev/antd";
import "@refinedev/antd/dist/reset.css";
import { dataProvider, liveProvider } from "@refinedev/supabase";
import routerBindings, {
  DocumentTitleHandler,
  NavigateToResource,
  UnsavedChangesNotifier,
  CatchAllNavigate,
} from "@refinedev/react-router";
import { BrowserRouter, Outlet, Route, Routes } from "react-router-dom";

import { supabaseClient } from "./providers/supabase-client";
import { authProvider } from "./providers/auth";

// Pages — dibuat minimal untuk Hari 4
// Detail implementasi di Minggu 2 & 3
import { ClaimList, ClaimShow } from "./pages/claims";
import { ItemList, ItemShow, ItemEdit } from "./pages/items";
import { LoginPage } from "./pages/auth/login";
import { DashboardPage } from "./pages/dashboard";

export default function App() {
  return (
    <BrowserRouter>
      <RefineKbarProvider>
        <AntdApp notification={{ placement: "top" }}>
          <Refine
            dataProvider={dataProvider(supabaseClient)}
            liveProvider={liveProvider(supabaseClient)}
            options={{ liveMode: "auto" }}

            // ── Auth Provider ──
            authProvider={authProvider}

            // ── Router ──
            routerProvider={routerBindings}

            // ── Notifikasi UI ──
            notificationProvider={useNotificationProvider}

            // ── Resources ──
            // Resource = tabel di Supabase yang diekspos ke admin
            resources={[
              {
                name: "dashboard",
                list: "/",
                meta: { label: "Dashboard", icon: "📊" },
              },
              {
                name: "items",
                list: "/items",
                show: "/items/show/:id",
                edit: "/items/edit/:id",
                meta: {
                  label: "Laporan",
                  icon: "📋",
                },
              },
              {
                name: "claims",
                list: "/claims",
                show: "/claims/show/:id",
                meta: { label: "Klaim", icon: "🔖" },
              },
              {
                name: "profiles",
                list: "/profiles",
                show: "/profiles/show/:id",
                meta: { label: "Pengguna", icon: "👤" },
              },
            ]}
          >
            <Routes>
              <Route
                element={
                  <Authenticated
                    key="authenticated-inner"
                    fallback={<CatchAllNavigate to="/login" />}
                  >
                    <ThemedLayout>
                      <Outlet />
                    </ThemedLayout>
                  </Authenticated>
                }
              >
                <Route index element={<DashboardPage />} />
                <Route path="/items">
                  <Route index element={<ItemList />} />
                  <Route path="show/:id" element={<ItemShow />} />
                  <Route path="edit/:id" element={<ItemEdit />} />
                </Route>
                {/* Route claims & profiles ditambahkan Minggu 2-3 */}
                <Route path="/claims">
                  <Route index element={<ClaimList />} />
                  <Route path="show/:id" element={<ClaimShow />} />
                </Route>
              </Route>
              <Route path="/login" element={<LoginPage />} />
              <Route path="*" element={<ErrorComponent />} />
            </Routes>

            <RefineKbar />
            <UnsavedChangesNotifier />
            <DocumentTitleHandler />
          </Refine>
        </AntdApp>
      </RefineKbarProvider>
    </BrowserRouter>
  );
}