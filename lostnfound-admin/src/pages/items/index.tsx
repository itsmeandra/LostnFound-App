import {
  List,
  ShowButton,
  EditButton,
  useTable,
  DateField,
} from "@refinedev/antd";
import {
  Table, Space, Tag, Button, Select, Popconfirm,
  Typography, Image, Tooltip, DatePicker,
} from "antd";
import {
  CheckCircleOutlined, CloseCircleOutlined,
  DeleteOutlined, DownloadOutlined,
} from "@ant-design/icons";
import { useDelete, useNavigation, useExport } from "@refinedev/core";
import { useState } from "react";
import dayjs, { Dayjs } from "dayjs";

const { Text } = Typography;
const { RangePicker } = DatePicker;

interface IItem {
  id: string;
  type: string;
  name: string;
  category: string;
  location: string;
  status: string;
  drop_point?: string;
  item_date?: string;
  created_at: string;
  photo_urls?: string[];
  profiles?: { full_name: string };
}

const STATUS_COLORS: Record<string, string> = {
  pending: "orange",
  published: "green",
  claimed: "blue",
  completed: "default",
  rejected: "red",
};

const STATUS_LABELS: Record<string, string> = {
  pending: "Menunggu",
  published: "Dipublikasi",
  claimed: "Diklaim",
  completed: "Selesai",
  rejected: "Ditolak",
};

const CATEGORY_LABELS: Record<string, string> = {
  electronics: "Elektronik", wallet: "Dompet", keys: "Kunci",
  clothing: "Pakaian", bag: "Tas", documents: "Dokumen",
  glasses: "Kacamata", jewelry: "Perhiasan", other: "Lainnya",
};

export const ItemList = () => {
  const { show } = useNavigation();
  const [statusFilter, setStatusFilter] = useState<string>("pending");
  const [typeFilter, setTypeFilter] = useState<string | null>(null);
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  // Hook Refine Table
  const { tableProps, setFilters, filters, sorters } = useTable<IItem>({
    resource: "items",
    filters: { initial: [{ field: "status", operator: "eq", value: "pending" }] },
    sorters: { initial: [{ field: "created_at", order: "desc" }] },
    meta: {
      select: "*, profiles:reporter_id(full_name)",
    },
  });

  const { triggerExport, isLoading: exportLoading } = useExport<IItem>({
    resource: "items",
    filters,
    sorters,
    meta: {
      select: "*, profiles:reporter_id(full_name)",
    },
    mapData: (item) => {
      return {
        "ID": item.id,
        "Tipe": item.type === "found" ? "Temuan" : "Hilang",
        "Nama": item.name,
        "Kategori": CATEGORY_LABELS[item.category] ?? item.category,
        "Lokasi": item.location,
        "Drop Point": item.drop_point ?? "",
        "Status": STATUS_LABELS[item.status] ?? item.status,
        "Pelapor": item.profiles?.full_name ?? "—",
        "Tanggal Kejadian": item.item_date ? dayjs(item.item_date).format("YYYY-MM-DD") : "",
        "Tanggal Dilaporkan": dayjs(item.created_at).format("YYYY-MM-DD HH:mm"),
      };
    },
  });

  const { mutate: deleteItem } = useDelete();

  // Logika Filter Dinamis
  const applyFilters = (s: string, t: string | null, d: [Dayjs, Dayjs] | null) => {
    const f: any[] = [];
    if (s) f.push({ field: "status", operator: "eq", value: s });
    if (t) f.push({ field: "type", operator: "eq", value: t });
    if (d) {
      f.push({ field: "created_at", operator: "gte", value: d[0].startOf("day").toISOString() });
      f.push({ field: "created_at", operator: "lte", value: d[1].endOf("day").toISOString() });
    }
    setFilters(f);
  };

  return (
    <List
      title={<Space><span>Manajemen Laporan</span></Space>}
      headerButtons={() => (
        <Space wrap>
          {/* Filter Tipe */}
          <Select
            allowClear placeholder="Semua Tipe"
            style={{ width: 140 }} value={typeFilter}
            onChange={(v) => { setTypeFilter(v); applyFilters(statusFilter, v, dateRange); }}
            options={[
              { value: "found", label: "Temuan" },
              { value: "lost", label: "Hilang" },
            ]}
          />

          {/* Filter Status */}
          <Select
            placeholder="Filter status" style={{ width: 160 }}
            value={statusFilter} allowClear
            onChange={(v) => { setStatusFilter(v ?? ""); applyFilters(v ?? "", typeFilter, dateRange); }}
            options={Object.entries(STATUS_LABELS).map(([val, label]) => ({
              value: val, label: label,
            }))}
          />

          {/* Filter Tanggal */}
          <RangePicker
            size="middle"
            style={{ width: 220 }}
            placeholder={["Tanggal awal", "Tanggal akhir"]}
            onChange={(dates) => {
              const d = dates ? [dates[0]!, dates[1]!] as [Dayjs, Dayjs] : null;
              setDateRange(d);
              applyFilters(statusFilter, typeFilter, d);
            }}
          />

          {/* Export CSV menggunakan fungsi triggerExport */}
          <Tooltip title="Export seluruh data (sesuai filter aktif) ke CSV">
            <Button
              icon={<DownloadOutlined />}
              loading={exportLoading}
              onClick={triggerExport}
            >
              Export CSV
            </Button>
          </Tooltip>
        </Space>
      )}
    >
      <Table
        {...tableProps}
        rowKey="id"
        size="small"
        scroll={{ x: 960 }}
        onRow={(r: IItem) => ({
          onClick: () => { if (r.id) show("items", r.id); },
          style: { cursor: "pointer" }
        })}
      >
        {/* Foto */}
        <Table.Column title="" dataIndex="photo_urls" width={52}
          render={(urls: string[]) =>
            urls?.[0] ? (
              <div onClick={(e) => e.stopPropagation()}>
                <Image
                  src={urls[0]}
                  width={42}
                  height={42}
                  style={{ objectFit: "cover", borderRadius: 6 }}
                  preview={true}
                />
              </div>
            ) : (
              <div style={{ width: 42, height: 42, borderRadius: 6, background: "#f5f5f5", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>
                📦
              </div>
            )
          }
        />

        {/* Nama & Kategori */}
        <Table.Column title="Barang" dataIndex="name"
          render={(name, r: IItem) => (
            <Space direction="vertical" size={0}>
              <Text strong style={{ fontSize: 13 }}>{name}</Text>
              <Text type="secondary" style={{ fontSize: 11 }}>
                {r.type === "found" ? "🟢" : "🔴"}{" "}
                {CATEGORY_LABELS[r.category] ?? r.category}
              </Text>
            </Space>
          )}
        />

        {/* Lokasi */}
        <Table.Column title="Lokasi" dataIndex="location" width={130}
          render={(v) => <Text style={{ fontSize: 12 }} ellipsis={{ tooltip: v }}>{v}</Text>}
        />

        {/* Drop Point */}
        <Table.Column title="Drop Point" dataIndex="drop_point" width={130}
          render={(v) => v
            ? <Text style={{ fontSize: 11, color: "#1565C0" }} ellipsis={{ tooltip: v }}>📍 {v}</Text>
            : <Text type="secondary" style={{ fontSize: 11 }}>—</Text>
          }
        />

        {/* Status */}
        <Table.Column title="Status" dataIndex="status" width={110}
          render={(s: string) => <Tag color={STATUS_COLORS[s]}>{STATUS_LABELS[s] ?? s}</Tag>}
        />

        {/* Pelapor */}
        <Table.Column title="Pelapor" dataIndex="profiles" width={120}
          render={(p: { full_name?: string }) => <Text style={{ fontSize: 12 }}>{p?.full_name ?? "—"}</Text>}
        />

        {/* Tanggal */}
        <Table.Column title="Tanggal" dataIndex="created_at" width={90}
          render={(v) => <DateField value={v} format="D MMM YY" />}
        />

        {/* Aksi */}
        <Table.Column title="Aksi" width={160} fixed="right"
          render={(_: any, r: IItem) => (
            <Space size={4} onClick={(e) => e.stopPropagation()}>
              <ShowButton hideText size="small" recordItemId={r.id} />
              <EditButton hideText size="small" recordItemId={r.id} />

              {r.status === "pending" && (
                <Popconfirm
                  title="Buka detail untuk memproses laporan?"
                  onConfirm={() => show("items", r.id)}
                  okText="Buka" cancelText="Batal"
                >
                  <Tooltip title="Proses Laporan">
                    <Button size="small" type="primary" icon={<CheckCircleOutlined />}
                      style={{ background: "#52c41a", borderColor: "#52c41a" }} />
                  </Tooltip>
                </Popconfirm>
              )}

              <Popconfirm
                title="Hapus laporan ini?" description="Tidak bisa dibatalkan."
                onConfirm={() => deleteItem({ resource: "items", id: r.id })}
                okText="Hapus" okButtonProps={{ danger: true }} cancelText="Batal"
              >
                <Tooltip title="Hapus">
                  <Button size="small" danger type="text" icon={<DeleteOutlined />} />
                </Tooltip>
              </Popconfirm>
            </Space>
          )}
        />
      </Table>
    </List>
  );
};

// ── Item Show ──
export { ItemShow } from "./itemshow";
export { ItemEdit } from "./itemedit";