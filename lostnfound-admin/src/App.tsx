import { Refine } from "@refinedev/core";
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
} from "@refinedev/react-router-v6";
import { BrowserRouter, Outlet, Route, Routes } from "react-router-dom";

import { supabaseClient } from "./providers/supabase-client";
import { authProvider } from "./providers/auth";
import { ItemList, ItemShow, ItemEdit } from "./pages/items";
import { DashboardPage } from "./pages/dashboard";

export default function App() {
  return (
    <BrowserRouter>
      <RefineKbarProvider>
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
          resources={[
            {
              name: "dashboard",
              list: "/",
              meta: { label: "Dasbor", icon: "📊" },
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
                <ThemedLayout>
                  <Outlet />
                </ThemedLayout>
              }
            >
              <Route index element={<DashboardPage />} />
              <Route path="/items">
                <Route index element={<ItemList />} />
                <Route path="show/:id" element={<ItemShow />} />
                <Route path="edit/:id" element={<ItemEdit />} />
              </Route>
            </Route>
            <Route path="/login" element={<LoginPage />} />
            <Route path="*" element={<ErrorComponent />} />
          </Routes>

          <RefineKbar />
          <UnsavedChangesNotifier />
          <DocumentTitleHandler />
        </Refine>
      </RefineKbarProvider>
    </BrowserRouter>
  );
}