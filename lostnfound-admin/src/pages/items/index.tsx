import {
  List,
  ShowButton,
  EditButton,
  useTable,
  DateField,
} from "@refinedev/antd";
import {
  Table, Space, Tag, Button, Select, Popconfirm,
  Typography, Image, Badge, Tooltip
} from "antd";
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  EyeOutlined, DeleteOutlined, FilterOutlined
} from "@ant-design/icons";
import { useUpdate, useDelete } from "@refinedev/core";
import { useState } from "react";

const { Text } = Typography;

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

// ── Item List ──
export const ItemList = () => {
  const [statusFilter, setStatusFilter] = useState<string>("pending");
  const [typeFilter, setTypeFilter] = useState<string | null>(null);

  // Bangun filter array berdasarkan pilihan
  const buildFilters = () => {
    const filters: any[] = [];
    if (statusFilter) {
      filters.push({ field: "status", operator: "eq", value: statusFilter });
    }
    if (typeFilter) {
      filters.push({ field: "type", operator: "eq", value: typeFilter });
    }
    return filters;
  };

  const { tableProps, setFilters } = useTable({
    resource: "items",
    filters: { initial: buildFilters() },
    sorters: { initial: [{ field: "created_at", order: "desc" }] },
    meta: {
      select: "*, profiles(full_name, phone)",
    },
  });

  // Hook untuk update data (approve/reject)
  const { mutate: updateItem } = useUpdate();
  const { mutate: deleteItem, } = useDelete();

  // Terapkan filter saat berubah
  const applyFilters = (status: string, type: string | null) => {
    const f: any[] = [];
    if (status) f.push({ field: "status", operator: "eq", value: status });
    if (type) f.push({ field: "type", operator: "eq", value: type });
    setFilters(f);
  };

  const handleStatusFilter = (val: string) => {
    setStatusFilter(val);
    applyFilters(val, typeFilter);
  };

  const handleTypeFilter = (val: string | null) => {
    setTypeFilter(val);
    applyFilters(statusFilter, val);
  };

  const handleApprove = (id: string) => {
    updateItem({
      resource: "items", id,
      values: { status: "published" },
      successNotification: { message: "Laporan dipublikasikan", type: "success" },
    });
  };

  const handleReject = (id: string) => {
    updateItem({
      resource: "items", id,
      values: { status: "rejected", rejection_reason: "Tidak sesuai ketentuan" },
      successNotification: { message: "Laporan ditolak", type: "error" },
    });
  };

  const handleDelete = (id: string) =>
    deleteItem({
      resource: "items", id,
      successNotification: { message: "Laporan dihapus.", type: "success" },
    });

  // const handleComplete = (id: string) => {
  //   updateItem({
  //     resource: "items",
  //     id,
  //     values: { status: "completed" },
  //     successNotification: { message: "Status diubah ke Selesai", type: "success" },
  //   });
  // };

  return (
    <List
      title="Manajemen Laporan"
      headerButtons={() => (
        <Space wrap>
          {/* Filter tipe */}
          <Select
            allowClear
            placeholder="Semua tipe"
            style={{ width: 140 }}
            value={typeFilter}
            onChange={handleTypeFilter}
            options={[
              { value: "found", label: "Barang Temuan" },
              { value: "lost", label: "Barang Hilang" },
            ]}
          />
          {/* Filter status */}
          <Select
            placeholder="Filter status"
            style={{ width: 180 }}
            value={statusFilter}
            onChange={handleStatusFilter}
            allowClear
            options={Object.entries(STATUS_LABELS).map(([v, l]) => ({
              value: v, label: l,
            }))}
          />
        </Space>
      )}
    >
      <Table {...tableProps} rowKey="id" size="small" scroll={{ x: 900 }}>
        {/* Foto thumbnail */}
        <Table.Column
          title=""
          dataIndex="photo_urls"
          width={56}
          render={(urls: string[]) =>
            urls?.[0] ? (
              <Image
                src={urls[0]}
                width={44}
                height={44}
                style={{ objectFit: "cover", borderRadius: 6 }}
                preview
              />
            ) : (
              <div
                style={{
                  width: 44, height: 44, borderRadius: 6,
                  background: "var(--ant-color-fill-secondary)",
                  display: "flex", alignItems: "center",
                  justifyContent: "center", fontSize: 18,
                }}
              >
                {/* Emoji fallback berdasarkan kategori */}
                📦
              </div>
            )
          }
        />

        {/* Nama + kategori */}
        <Table.Column
          title="Barang"
          dataIndex="name"
          render={(name, record: any) => (
            <Space direction="vertical" size={0}>
              <Text strong style={{ fontSize: 13 }}>{name}</Text>
              <Text type="secondary" style={{ fontSize: 11 }}>
                {CATEGORY_LABELS[record.category] ?? record.category}
                {" · "}
                {record.type === "found" ? "🟢 Temuan" : "🔴 Hilang"}
              </Text>
            </Space>
          )}
        />

        {/* Lokasi */}
        <Table.Column
          title="Lokasi"
          dataIndex="location"
          width={160}
          render={(v) => (
            <Text style={{ fontSize: 12 }} ellipsis={{ tooltip: v }}>
              {v}
            </Text>
          )}
        />

        {/* Status badge */}
        <Table.Column
          title="Status"
          dataIndex="status"
          width={140}
          render={(status: string) => (
            <Tag color={STATUS_COLORS[status]}>
              {STATUS_LABELS[status] ?? status}
            </Tag>
          )}
        />

        {/* Pelapor */}
        <Table.Column
          title="Pelapor"
          dataIndex="profiles"
          width={150}
          render={(p: any) => (
            <Space direction="vertical" size={0}>
              <Text style={{ fontSize: 12 }}>{p?.full_name ?? "—"}</Text>
              <Text type="secondary" style={{ fontSize: 11 }}>
                {p?.phone}
              </Text>
            </Space>
          )}
        />

        {/* Tanggal dibuat */}
        <Table.Column
          title="Tanggal"
          dataIndex="created_at"
          width={110}
          render={(v) => (
            <DateField value={v} format="D MMM YY" />
          )}
        />

        {/* Aksi */}
        <Table.Column
          title="Aksi"
          width={220}
          fixed="right"
          render={(_, record: any) => (
            <Space size={4}>
              <ShowButton hideText size="small" recordItemId={record.id} />
              <EditButton hideText size="small" recordItemId={record.id} />

              {/* Approve — hanya untuk pending */}
              {record.status === "pending" && (
                <Popconfirm
                  title="Setujui & publikasikan?"
                  onConfirm={() => handleApprove(record.id)}
                  okText="Setujui"
                  cancelText="Batal"
                >
                  <Tooltip title="Approve">
                    <Button
                      size="small"
                      type="primary"
                      icon={<CheckCircleOutlined />}
                      style={{ background: "#52c41a", borderColor: "#52c41a" }}
                    />
                  </Tooltip>
                </Popconfirm>
              )}

              {/* Reject — hanya untuk pending */}
              {record.status === "pending" && (
                <Popconfirm
                  title="Tolak laporan ini?"
                  onConfirm={() => handleReject(record.id)}
                  okText="Tolak"
                  okButtonProps={{ danger: true }}
                  cancelText="Batal"
                >
                  <Tooltip title="Tolak">
                    <Button
                      size="small"
                      danger
                      icon={<CloseCircleOutlined />}
                    />
                  </Tooltip>
                </Popconfirm>
              )}

              {/* Hapus — selalu ada, dengan konfirmasi */}
              <Popconfirm
                title="Hapus laporan ini?"
                description="Tindakan ini tidak bisa dibatalkan."
                onConfirm={() => handleDelete(record.id)}
                okText="Hapus"
                okButtonProps={{ danger: true }}
                cancelText="Batal"
              >
                <Tooltip title="Hapus permanen">
                  <Button
                    size="small"
                    danger
                    icon={<DeleteOutlined />}
                    type="text"
                  />
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