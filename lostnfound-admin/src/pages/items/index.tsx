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
  EyeOutlined,
} from "@ant-design/icons";
import { useUpdate } from "@refinedev/core";
import { useState } from "react";

const { Text } = Typography;

// Warna status sesuai PRD
const statusColors: Record<string, string> = {
  pending:   "orange",
  published: "green",
  claimed:   "blue",
  completed: "default",
  rejected:  "red",
};

const statusLabels: Record<string, string> = {
  pending:   "Menunggu Verifikasi",
  published: "Dipublikasi",
  claimed:   "Diklaim",
  completed: "Selesai",
  rejected:  "Ditolak",
};

// ── Item List ──
export const ItemList = () => {
  const [statusFilter, setStatusFilter] = useState<string | undefined>("pending");

  const { tableProps } = useTable({
    resource: "items",
    // Filter default: tampilkan pending dulu (antrian verifikasi)
    filters: {
      initial: statusFilter
        ? [{ field: "status", operator: "eq", value: statusFilter }]
        : [],
    },
    sorters: {
      initial: [{ field: "created_at", order: "desc" }],
    },
    // Join dengan profiles untuk tampilkan nama pelapor
    meta: {
      select: "*, profiles(full_name, email, phone)",
    },
  });

  // Hook untuk update data (approve/reject)
  const { mutate: updateItem } = useUpdate();

  const handleApprove = (id: string) => {
    updateItem({
      resource: "items",
      id,
      values: { status: "published" },
      successNotification: { message: "Laporan disetujui & dipublikasikan", type: "success" },
    });
  };

  const handleReject = (id: string) => {
    // TODO: tampilkan modal untuk input alasan penolakan
    updateItem({
      resource: "items",
      id,
      values: { status: "rejected", rejection_reason: "Tidak sesuai ketentuan" },
      successNotification: { message: "Laporan ditolak", type: "error" },
    });
  };

  const handleComplete = (id: string) => {
    updateItem({
      resource: "items",
      id,
      values: { status: "completed" },
      successNotification: { message: "Status diubah ke Selesai", type: "success" },
    });
  };

  return (
    <List
      title="Manajemen Laporan"
      headerButtons={() => (
        <Select
          placeholder="Filter status"
          allowClear
          style={{ width: 200 }}
          value={statusFilter}
          onChange={setStatusFilter}
          options={Object.entries(statusLabels).map(([value, label]) => ({
            value, label
          }))}
        />
      )}
    >
      <Table {...tableProps} rowKey="id" size="small">
        {/* Foto barang */}
        <Table.Column
          title=""
          dataIndex="photo_urls"
          width={64}
          render={(urls: string[]) => urls?.[0]
            ? <Image src={urls[0]} width={48} height={48}
                style={{ objectFit: "cover", borderRadius: 6 }} preview />
            : <Badge status="default" text="—" />
          }
        />

        {/* Nama & kategori */}
        <Table.Column
          title="Barang"
          dataIndex="name"
          render={(name, record: any) => (
            <Space direction="vertical" size={0}>
              <Text strong>{name}</Text>
              <Text type="secondary" style={{ fontSize: 12 }}>
                {record.category} · {record.type === "lost" ? "🔴 Hilang" : "🟢 Temuan"}
              </Text>
            </Space>
          )}
        />

        {/* Lokasi */}
        <Table.Column title="Lokasi" dataIndex="location" width={160}
          render={(v) => <Text style={{ fontSize: 13 }}>{v}</Text>}
        />

        {/* Status */}
        <Table.Column
          title="Status"
          dataIndex="status"
          width={160}
          render={(status: string) => (
            <Tag color={statusColors[status]}>
              {statusLabels[status] ?? status}
            </Tag>
          )}
        />

        {/* Pelapor */}
        <Table.Column
          title="Pelapor"
          dataIndex="profiles"
          width={160}
          render={(profile: any) => (
            <Space direction="vertical" size={0}>
              <Text style={{ fontSize: 13 }}>{profile?.full_name ?? "—"}</Text>
              <Text type="secondary" style={{ fontSize: 11 }}>{profile?.phone}</Text>
            </Space>
          )}
        />

        {/* Tanggal dibuat */}
        <Table.Column
          title="Dibuat"
          dataIndex="created_at"
          width={120}
          render={(v) => <DateField value={v} format="DD MMM YYYY" />}
        />

        {/* Aksi */}
        <Table.Column
          title="Aksi"
          width={200}
          render={(_, record: any) => (
            <Space>
              <ShowButton hideText size="small" recordItemId={record.id} />

              {/* Tombol Approve: hanya saat status pending */}
              {record.status === "pending" && (
                <Popconfirm
                  title="Setujui & publikasikan laporan ini?"
                  onConfirm={() => handleApprove(record.id)}
                  okText="Setujui"
                  cancelText="Batal"
                >
                  <Tooltip title="Setujui">
                    <Button size="small" type="primary" icon={<CheckCircleOutlined />} />
                  </Tooltip>
                </Popconfirm>
              )}

              {/* Tombol Reject: hanya saat status pending */}
              {record.status === "pending" && (
                <Popconfirm
                  title="Tolak laporan ini?"
                  onConfirm={() => handleReject(record.id)}
                  okText="Tolak" okButtonProps={{ danger: true }}
                  cancelText="Batal"
                >
                  <Tooltip title="Tolak">
                    <Button size="small" danger icon={<CloseCircleOutlined />} />
                  </Tooltip>
                </Popconfirm>
              )}

              {/* Tombol Selesai: saat status claimed */}
              {record.status === "claimed" && (
                <Popconfirm
                  title="Tandai sebagai selesai / dikembalikan?"
                  onConfirm={() => handleComplete(record.id)}
                  okText="Ya, selesai"
                  cancelText="Batal"
                >
                  <Button size="small">Selesai</Button>
                </Popconfirm>
              )}
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