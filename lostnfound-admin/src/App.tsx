import { Refine, Authenticated } from "@refinedev/core";
import { RefineKbar, RefineKbarProvider } from "@refinedev/kbar";
import { App as AntdApp } from "antd";
import {
  ThemedLayout,
  ThemedSider,
  ThemedTitle,
  ErrorComponent,
  useNotificationProvider,
} from "@refinedev/antd";
import "@refinedev/antd/dist/reset.css";

import { BrowserRouter, Route, Routes, Outlet } from "react-router-dom";
import routerBindings, {
  DocumentTitleHandler,
  NavigateToResource,
  UnsavedChangesNotifier,
  CatchAllNavigate,
} from "@refinedev/react-router";
import { dataProvider, liveProvider } from "@refinedev/supabase";

import { supabaseClient } from "./providers/supabase-client";
import { authProvider } from "./providers/auth";

import {
  DashboardOutlined,
  FileSearchOutlined,
  CheckCircleOutlined,
  TeamOutlined,
} from "@ant-design/icons";
import dayjs from "dayjs";
import "dayjs/locale/id";

import { LoginPage } from "./pages/auth/login";
import { DashboardPage } from "./pages/dashboard";
import { ItemList, ItemShow, ItemEdit } from "./pages/items";
import { ClaimList, ClaimShow } from "./pages/claims";
import { ProfileList } from "./pages/profiles";
dayjs.locale("id");

export default function App() {
  return (
    <BrowserRouter>
      <RefineKbarProvider>
        <AntdApp notification={{ placement: "top" }}>
          <Refine
            dataProvider={dataProvider(supabaseClient)}
            liveProvider={liveProvider(supabaseClient)}
            authProvider={authProvider}
            routerProvider={routerBindings}
            notificationProvider={useNotificationProvider}
            options={{
              liveMode: "auto",
              syncWithLocation: true,
              warnWhenUnsavedChanges: true,
            }}
            resources={[
              {
                name: "dashboard",
                list: "/",
                meta: {
                  label: "Dashboard",
                  icon: <DashboardOutlined />,
                },
              },
              {
                name: "items",
                list: "/items",
                show: "/items/show/:id",
                edit: "/items/edit/:id",
                meta: {
                  label: "Laporan",
                  icon: <FileSearchOutlined />,
                  canDelete: true,
                },
              },
              {
                name: "claims",
                list: "/claims",
                show: "/claims/show/:id",
                meta: {
                  label: "Klaim",
                  icon: <CheckCircleOutlined />,
                },
              },
              {
                name: "profiles",
                list: "/profiles",
                meta: {
                  label: "Pengguna",
                  icon: <TeamOutlined />,
                },
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
                    <ThemedLayout
                      Sider={() => (
                        <ThemedSider
                          Title={({ collapsed }: { collapsed: boolean }) => (
                            <ThemedTitle
                              collapsed={collapsed}
                              text="Lost n Found"
                            />
                          )}
                        />
                      )}
                    >
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
                <Route path="/claims">
                  <Route index element={<ClaimList />} />
                  <Route path="show/:id" element={<ClaimShow />} />
                </Route>
                <Route path="/profiles">
                  <Route index element={<ProfileList />} />
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