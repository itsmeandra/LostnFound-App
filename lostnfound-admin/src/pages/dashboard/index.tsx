import { useList, useNavigation } from "@refinedev/core";
import {
  Card, Row, Col, Statistic, Table, Tag, Space,
  Typography, Divider, Button, Badge, Spin, Empty,
  Progress,
} from "antd";
import {
  FileSearchOutlined, CheckCircleOutlined,
  ClockCircleOutlined, TeamOutlined,
  InboxOutlined, FireOutlined,
  ArrowRightOutlined,
} from "@ant-design/icons";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip as RTooltip,
  ResponsiveContainer, PieChart, Pie, Cell, Legend,
} from "recharts";
import { DateField } from "@refinedev/antd";
import dayjs from "dayjs";

const { Title, Text } = Typography;

const CATEGORY_COLORS: Record<string, string> = {
  electronics: "#1A73E8",
  wallet: "#34A853",
  keys: "#FBBC04",
  clothing: "#EA4335",
  bag: "#9334E8",
  documents: "#00ACC1",
  glasses: "#FF6D00",
  jewelry: "#8D6E63",
  other: "#9E9E9E",
};

const CATEGORY_LABELS: Record<string, string> = {
  electronics: "Elektronik",
  wallet: "Dompet",
  keys: "Kunci",
  clothing: "Pakaian",
  bag: "Tas",
  documents: "Dokumen",
  glasses: "Kacamata",
  jewelry: "Perhiasan",
  other: "Lainnya",
};

// ────────── Stat Cards — 6 metrik utama ──────────
const StatCards = () => {
  // Hitung setiap metrik dari query terpisah
  const { query: allItems } = useList({ resource: "items", liveMode: "auto", meta: { select: "id" }, pagination: { pageSize: 1 } });
  const { query: pending } = useList({ resource: "items", liveMode: "auto", meta: { select: "id" }, filters: [{ field: "status", operator: "eq", value: "pending" }], pagination: { pageSize: 1 } });
  const { query: published } = useList({ resource: "items", liveMode: "auto", meta: { select: "id" }, filters: [{ field: "status", operator: "eq", value: "published" }], pagination: { pageSize: 1 } });
  const { query: completed } = useList({ resource: "items", liveMode: "auto", meta: { select: "id" }, filters: [{ field: "status", operator: "eq", value: "completed" }], pagination: { pageSize: 1 } });
  const { query: pendingClaims } = useList({ resource: "claims", liveMode: "auto", meta: { select: "id" }, filters: [{ field: "status", operator: "eq", value: "pending" }], pagination: { pageSize: 1 } });
  const { query: allUsers } = useList({ resource: "profiles", liveMode: "auto", meta: { select: "id" }, pagination: { pageSize: 1 } });

  // SLA: Persentase laporan pending diselesaikan dalam 24 jam
  // (simplified: completed / total × 100)
  const completionRate = allItems?.data?.total
    ? Math.round(((completed?.data?.total ?? 0) / allItems.data.total) * 100)
    : 0;

  const cards = [
    {
      title: "Total Laporan",
      value: allItems?.data?.total ?? 0,
      icon: <FileSearchOutlined />,
      color: "#1A73E8",
      bg: "#E8F0FE",
    },
    {
      title: "Menunggu Verifikasi",
      value: pending?.data?.total ?? 0,
      icon: <ClockCircleOutlined />,
      color: "#F57C00",
      bg: "#FFF3E0",
      badge: (pending?.data?.total ?? 0) > 0,
    },
    {
      title: "Sedang Dipublikasi",
      value: published?.data?.total ?? 0,
      icon: <InboxOutlined />,
      color: "#388E3C",
      bg: "#E8F5E9",
    },
    {
      title: "Klaim Pending",
      value: pendingClaims?.data?.total ?? 0,
      icon: <FireOutlined />,
      color: "#D32F2F",
      bg: "#FFEBEE",
      badge: (pendingClaims?.data?.total ?? 0) > 0,
    },
    {
      title: "Berhasil Dikembalikan",
      value: completed?.data?.total ?? 0,
      icon: <CheckCircleOutlined />,
      color: "#1B5E20",
      bg: "#E8F5E9",
    },
    {
      title: "Total Pengguna",
      value: allUsers?.data?.total ?? 0,
      icon: <TeamOutlined />,
      color: "#6A1B9A",
      bg: "#F3E5F5",
    },
  ];

  return (
    <Row gutter={[12, 12]} style={{ marginBottom: 20 }}>
      {cards.map((card, i) => (
        <Col key={i} xs={12} sm={8} md={4}>
          <Badge.Ribbon
            text="Segera"
            color="red"
            style={{ display: card.badge ? "block" : "none" }}
          >
            <Card
              size="small"
              style={{ borderColor: card.bg }}
              bodyStyle={{ padding: "12px 14px" }}
            >
              <div style={{
                display: "flex", alignItems: "center",
                gap: 8, marginBottom: 8,
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 8,
                  background: card.bg,
                  display: "flex", alignItems: "center",
                  justifyContent: "center",
                  color: card.color, fontSize: 16,
                }}>
                  {card.icon}
                </div>
                <Text style={{ fontSize: 11, color: "#666" }}>
                  {card.title}
                </Text>
              </div>
              <Statistic
                value={card.value}
                valueStyle={{ fontSize: 22, color: card.color, fontWeight: 600 }}
              />
              {card.title === "Berhasil Dikembalikan" && (
                <Progress
                  percent={completionRate}
                  size="small"
                  showInfo={false}
                  strokeColor={card.color}
                  style={{ marginTop: 4 }}
                />
              )}
            </Card>
          </Badge.Ribbon>
        </Col>
      ))}
    </Row>
  );
};

// ────────── Bar Chart — laporan per minggu (7 minggu terakhir) ──────────
const WeeklyChart = () => {
  // Ambil semua item 7 minggu terakhir
  const sevenWeeksAgo = dayjs().subtract(7, "week").toISOString();

  const { query } = useList({
    resource: "items",
    liveMode: "off",
    meta: { select: "created_at, type, status" },
    filters: [{ field: "created_at", operator: "gte", value: sevenWeeksAgo }],
    pagination: { pageSize: 500 },
  });

  const { data, isLoading } = query;

  if (isLoading) return <Spin size="small" />;

  // Group by week
  const weeks: Record<string, { found: number; lost: number }> = {};
  for (let i = 6; i >= 0; i--) {
    const label = dayjs().subtract(i, "week").format("D MMM");
    weeks[label] = { found: 0, lost: 0 };
  }

  data?.data?.forEach((item: any) => {
    const weekLabel = dayjs(item.created_at)
      .startOf("week")
      .format("D MMM");
    if (weeks[weekLabel]) {
      if (item.type === "found") weeks[weekLabel].found++;
      else weeks[weekLabel].lost++;
    }
  });

  const chartData = Object.entries(weeks).map(([week, counts]) => ({
    week,
    Temuan: counts.found,
    Hilang: counts.lost,
  }));

  return (
    <ResponsiveContainer width="100%" height={180}>
      <BarChart data={chartData} barGap={2}>
        <XAxis dataKey="week" tick={{ fontSize: 10 }} />
        <YAxis tick={{ fontSize: 10 }} width={24} allowDecimals={false} />
        <RTooltip />
        <Bar dataKey="Temuan" fill="#34A853" radius={[3, 3, 0, 0]} maxBarSize={24} />
        <Bar dataKey="Hilang" fill="#EA4335" radius={[3, 3, 0, 0]} maxBarSize={24} />
      </BarChart>
    </ResponsiveContainer>
  );
};

// ────────── Pie Chart — distribusi kategori ──────────
const CategoryPie = () => {
  const { query } = useList({
    resource: "items",
    liveMode: "off",
    meta: { select: "category" },
    pagination: { pageSize: 1000 },
  });

  const { data, isLoading } = query;

  if (isLoading) return <Spin size="small" />;

  // Count per kategori
  const counts: Record<string, number> = {};
  data?.data?.forEach((item: any) => {
    counts[item.category] = (counts[item.category] ?? 0) + 1;
  });

  const pieData = Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 6) // top 6
    .map(([key, value]) => ({
      name: CATEGORY_LABELS[key] ?? key,
      value,
      color: CATEGORY_COLORS[key] ?? "#9E9E9E",
    }));

  if (pieData.length === 0) {
    return <Empty description="Belum ada data" imageStyle={{ height: 60 }} />;
  }

  return (
    <ResponsiveContainer width="100%" height={180}>
      <PieChart>
        <Pie
          data={pieData}
          cx="50%"
          cy="50%"
          innerRadius={45}
          outerRadius={70}
          paddingAngle={3}
          dataKey="value"
        >
          {pieData.map((entry, i) => (
            <Cell key={i} fill={entry.color} />
          ))}
        </Pie>
        <RTooltip formatter={(v, n) => [`${v} laporan`, n]} />
        <Legend
          iconType="circle"
          iconSize={8}
          formatter={(v) => (
            <span style={{ fontSize: 10 }}>{v}</span>
          )}
        />
      </PieChart>
    </ResponsiveContainer>
  );
};

// ────────── Tabel Aktivitas Terbaru ──────────
const RecentActivity = () => {
  const { show, list } = useNavigation();

  const { query: itemsQuery } = useList({
    resource: "items",
    liveMode: "off",
    meta: { select: "id, name, type, status, category, created_at" },
    sorters: [{ field: "created_at", order: "desc" }],
    pagination: { pageSize: 5 },
  });

  const { data: recentItems, isLoading: loadingItems } = itemsQuery;

  const { query: claimsQuery } = useList({
    resource: "claims",
    liveMode: "off",
    meta: {
      select: "id, status, created_at, items:item_id(name), claimant:claimant_id(full_name)",
    },
    sorters: [{ field: "created_at", order: "desc" }],
    pagination: { pageSize: 5 },
  });

  const { data: recentClaims, isLoading: loadingClaims } = claimsQuery;

  const STATUS_COLOR: Record<string, string> = {
    pending: "orange",
    published: "green",
    claimed: "blue",
    completed: "default",
    rejected: "red",
    approved: "green",
  };

  return (
    <Row gutter={12}>
      {/* Laporan terbaru */}
      <Col xs={24} md={12}>
        <Card
          size="small"
          title={
            <Space>
              <InboxOutlined />
              <span>Laporan Terbaru</span>
            </Space>
          }
          extra={
            <Button
              type="link"
              size="small"
              icon={<ArrowRightOutlined />}
              onClick={() => list("items")}
              style={{ padding: 0 }}
            >
              Lihat semua
            </Button>
          }
        >
          <Table
            dataSource={recentItems?.data ?? []}
            loading={loadingItems}
            rowKey="id"
            size="small"
            pagination={false}
            onRow={(r: any) => ({ onClick: () => show("items", r.id) })}
            rowClassName={() => "clickable-row"}
            columns={[
              {
                title: "Barang",
                dataIndex: "name",
                render: (name, r: any) => (
                  <Space direction="vertical" size={0}>
                    <Text style={{ fontSize: 12, fontWeight: 500 }}>
                      {name}
                    </Text>
                    <Text type="secondary" style={{ fontSize: 10 }}>
                      {r.type === "found" ? "🟢" : "🔴"}{" "}
                      {CATEGORY_LABELS[r.category] ?? r.category}
                    </Text>
                  </Space>
                ),
              },
              {
                title: "Status",
                dataIndex: "status",
                width: 90,
                render: (s) => (
                  <Tag color={STATUS_COLOR[s] ?? "default"} style={{ fontSize: 10 }}>
                    {s}
                  </Tag>
                ),
              },
              {
                title: "Tanggal",
                dataIndex: "created_at",
                width: 70,
                render: (v) => (
                  <DateField value={v} format="D MMM" style={{ fontSize: 10 }} />
                ),
              },
            ]}
          />
        </Card>
      </Col>

      {/* Klaim terbaru */}
      <Col xs={24} md={12}>
        <Card
          size="small"
          title={
            <Space>
              <CheckCircleOutlined />
              <span>Klaim Terbaru</span>
            </Space>
          }
          extra={
            <Button
              type="link"
              size="small"
              icon={<ArrowRightOutlined />}
              onClick={() => list("claims")}
              style={{ padding: 0 }}
            >
              Lihat semua
            </Button>
          }
        >
          <Table
            dataSource={recentClaims?.data ?? []}
            loading={loadingClaims}
            rowKey="id"
            size="small"
            pagination={false}
            columns={[
              {
                title: "Barang / Pemohon",
                render: (_: any, r: any) => (
                  <Space direction="vertical" size={0}>
                    <Text style={{ fontSize: 12, fontWeight: 500 }}>
                      {r.items?.name ?? "—"}
                    </Text>
                    <Text type="secondary" style={{ fontSize: 10 }}>
                      oleh {r.claimant?.full_name ?? "—"}
                    </Text>
                  </Space>
                ),
              },
              {
                title: "Status",
                dataIndex: "status",
                width: 90,
                render: (s) => (
                  <Tag color={STATUS_COLOR[s] ?? "default"} style={{ fontSize: 10 }}>
                    {s}
                  </Tag>
                ),
              },
              {
                title: "Tanggal",
                dataIndex: "created_at",
                width: 70,
                render: (v) => (
                  <DateField value={v} format="D MMM" style={{ fontSize: 10 }} />
                ),
              },
            ]}
          />
        </Card>
      </Col>
    </Row>
  );
};

// ────────── Quick Actions — shortcut ke item/klaim yang butuh aksi ──────────
const QuickActions = () => {
  const { list } = useNavigation();

  const { query: pendingItems } =
    useList({ resource: "items", liveMode: "off", meta: { select: "id" }, filters: [{ field: "status", operator: "eq", value: "pending" }], pagination: { pageSize: 1 } });
  const { query: pendingClaims } =
    useList({ resource: "claims", liveMode: "off", meta: { select: "id" }, filters: [{ field: "status", operator: "eq", value: "pending" }], pagination: { pageSize: 1 } });

  const pendingItemCount = pendingItems?.data?.total ?? 0;
  const pendingClaimCount = pendingClaims?.data?.total ?? 0;

  if (pendingItemCount === 0 && pendingClaimCount === 0) return null;

  return (
    <Card
      size="small"
      style={{ marginBottom: 16, borderColor: "#FFF3E0", background: "#FFFDE7" }}
    >
      <Space wrap>
        <Text style={{ fontSize: 12, fontWeight: 500 }}>
          ⚡ Perlu Aksi Segera:
        </Text>
        {pendingItemCount > 0 && (
          <Button
            size="small"
            type="primary"
            danger
            onClick={() => list("items")}
            icon={<ClockCircleOutlined />}
          >
            {pendingItemCount} Laporan Pending
          </Button>
        )}
        {pendingClaimCount > 0 && (
          <Button
            size="small"
            type="primary"
            style={{ background: "#F57C00", borderColor: "#F57C00" }}
            onClick={() => list("claims")}
            icon={<FireOutlined />}
          >
            {pendingClaimCount} Klaim Pending
          </Button>
        )}
      </Space>
    </Card>
  );
};

// ────────── Dashboard utama ──────────
export const DashboardPage = () => {
  return (
    <div style={{ padding: "0 4px" }}>
      <div style={{ marginBottom: 16 }}>
        <Title level={4} style={{ margin: 0 }}>
          Dashboard
        </Title>
        <Text type="secondary" style={{ fontSize: 12 }}>
          {dayjs().format("dddd, D MMMM YYYY")}
        </Text>
      </div>

      {/* Quick actions */}
      <QuickActions />

      {/* Stat cards */}
      <StatCards />

      {/* Charts */}
      <Row gutter={12} style={{ marginBottom: 16 }}>
        <Col xs={24} md={14}>
          <Card
            size="small"
            title="Laporan per Minggu (7 Minggu Terakhir)"
            extra={
              <Space size={12}>
                <Space size={4}>
                  <div style={{ width: 10, height: 10, borderRadius: 2, background: "#34A853" }} />
                  <Text style={{ fontSize: 11 }}>Temuan</Text>
                </Space>
                <Space size={4}>
                  <div style={{ width: 10, height: 10, borderRadius: 2, background: "#EA4335" }} />
                  <Text style={{ fontSize: 11 }}>Hilang</Text>
                </Space>
              </Space>
            }
          >
            <WeeklyChart />
          </Card>
        </Col>
        <Col xs={24} md={10}>
          <Card size="small" title="Distribusi Kategori">
            <CategoryPie />
          </Card>
        </Col>
      </Row>

      {/* Recent activity */}
      <RecentActivity />
    </div>
  );
};
