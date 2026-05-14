import { Show } from "@refinedev/antd";
import { useShow, useUpdate } from "@refinedev/core";
import { Typography, Tag, Descriptions, Image, Space, Button, Popconfirm, Modal, Input, Form, Divider, Alert } from "antd";
import { CheckCircleOutlined, CloseCircleOutlined, TrophyOutlined, LockOutlined } from "@ant-design/icons";
import { DateField } from "@refinedev/antd";
import { useState } from "react";

const { Text, Title } = Typography;

const statusColors: Record<string, string> = {
  pending: "orange",
  published: "green",
  claimed: "blue",
  completed: "default",
  rejected: "red",
};

const statusLabels: Record<string, string> = {
  pending: "Menunggu Verifikasi",
  published: "Dipublikasi",
  claimed: "Sedang Diklaim",
  completed: "Selesai / Dikembalikan",
  rejected: "Ditolak",
};

const categoryLabels: Record<string, string> = {
  electronics: "Elektronik",
  wallet: "Dompet",
  keys: "Kunci",
  clothing: "Pakaian & Aksesoris",
  bag: "Tas",
  documents: "Dokumen",
  glasses: "Kacamata",
  jewelry: "Perhiasan",
  other: "Lainnya",
};

export const ItemShow = () => {
  const [rejectModal, setRejectModal] = useState(false);
  const [rejectReason, setRejectReason] = useState("");

  const { query } = useShow({
    resource: "items", meta: {
      select: "*, profiles!reporter_id(full_name, email, phone)",
    }
  });
  const record = query?.data?.data as any;

  const { mutate: updateItem, isLoading } = useUpdate();

  const handleApprove = () => {
    updateItem({
      resource: "items",
      id: record.id,
      values: { status: "published" },
      successNotification: {
        message: "Laporan disetujui dan dipublikasi!",
        type: "success",
      },
    });
  };

  const handleReject = () => {
    updateItem({
      resource: "items",
      id: record.id,
      values: {
        status: "rejected",
        reject_reason: rejectReason.trim() || "Laporan tidak memenuhi ketentuan."
      },
      successNotification: { message: "Laporan ditolak.", type: "error" },
    });
  }

  const handleComplete = () => {
    updateItem({
      resource: "items",
      id: record.id,
      values: { status: "completed" },
      successNotification: {
        message: "Status diubah ke Selesai.",
        type: "success",
      },
    });
  };

  if (!record) return null;

  const reporter = record.profiles ?? {};

  // const statusColor: Record<string, string> = {
  //   pending: "orange", published: "green",
  //   claimed: "blue", completed: "default", rejected: "red",
  // };

  return (
    <Show>
      title={`Detail Laporan: ${record.name ?? ""}`}
      headerButtons={
        <Space>
          {record.status === "pending" && (
            <>
              <Popconfirm
                title="Setujui & publikasikan laporan ini?"
                onConfirm={handleApprove}
                okText="Setujui"
                cancelText="Batal"
              >
                <Button
                  type="primary"
                  icon={<CheckCircleOutlined />}
                  loading={isLoading}
                >
                  Setujui
                </Button>
              </Popconfirm>
              <Button
                danger
                icon={<CloseCircleOutlined />}
                onClick={() => setRejectModal(true)}
              >
                Tolak
              </Button>
            </>
          )}
          {record.status === "claimed" && (
            <Popconfirm
              title="Tandai barang sebagai sudah dikembalikan ke pemilik?"
              onConfirm={handleComplete}
              okText="Ya, selesai"
              cancelText="Batal"
            >
              <Button icon={<TrophyOutlined />} loading={isLoading}>
                Selesai / Dikembalikan
              </Button>
            </Popconfirm>
          )}
        </Space>
      }

      {/* Alert status */}
      <Alert
        type={
          record.status === "published" || record.status === "completed"
            ? "success"
            : record.status === "rejected"
              ? "error"
              : record.status === "claimed"
                ? "info"
                : "warning"
        }
        message={statusLabels[record.status] ?? record.status}
        description={
          record.status === "rejected" && record.rejection_reason
            ? `Alasan: ${record.rejection_reason}`
            : undefined
        }
        showIcon
        style={{ marginBottom: 24 }}
      />

      {/* Foto barang */}
      {record.photo_urls?.length > 0 && (
        <>
          <Title level={5}>Foto Barang</Title>
          <Image.PreviewGroup>
            <Space wrap style={{ marginBottom: 24 }}>
              {record.photo_urls.map((url: string, i: number) => (
                <Image
                  key={i}
                  src={url}
                  width={120}
                  height={120}
                  style={{ objectFit: "cover", borderRadius: 8 }}
                />
              ))}
            </Space>
          </Image.PreviewGroup>
          <Divider />
        </>
      )}
      {/* Info utama */}
      <Descriptions bordered column={2} size="small">
        <Descriptions.Item label="Nama Barang" span={2}>
          <Text strong style={{ fontSize: 15 }}>
            {record.name}
          </Text>
        </Descriptions.Item>

        <Descriptions.Item label="Tipe">
          <Tag color={record.type === "found" ? "green" : "red"}>
            {record.type === "found" ? "Barang Temuan" : "Barang Hilang"}
          </Tag>
        </Descriptions.Item>

        <Descriptions.Item label="Kategori">
          {categoryLabels[record.category] ?? record.category}
        </Descriptions.Item>

        <Descriptions.Item label="Lokasi" span={2}>
          {record.location}
        </Descriptions.Item>

        <Descriptions.Item label="Tanggal Kejadian">
          <DateField value={record.item_date} format="D MMMM YYYY" />
        </Descriptions.Item>


        <Descriptions.Item label="Dilaporkan">
          <DateField value={record.created_at} format="D MMM YYYY, HH:mm" />
        </Descriptions.Item>

        <Descriptions.Item label="Deskripsi" span={2}>
          {record.description ?? (
            <Text type="secondary">Tidak ada deskripsi</Text>
          )}
        </Descriptions.Item>

        {/* CIRI KHUSUS — hanya admin yang lihat */}
        <Descriptions.Item
          label={
            <Space>
              <LockOutlined style={{ color: "#d46b08" }} />
              <Text style={{ color: "#d46b08" }}>Ciri Khusus (Rahasia)</Text>
            </Space>
          }
          span={2}
        >
          {record.distinctive_features ? (
            <Text style={{ color: "#d46b08", fontWeight: 500 }}>
              {record.distinctive_features}
            </Text>
          ) : (
            <Text type="secondary">Tidak diisi oleh pelapor</Text>
          )}
        </Descriptions.Item>
      </Descriptions>

      <Divider />

      {/* Info pelapor */}
      <Title level={5}>Informasi Pelapor</Title>
      <Descriptions bordered column={2} size="small">
        <Descriptions.Item label="Nama">
          {reporter.full_name ?? "—"}
        </Descriptions.Item>
        <Descriptions.Item label="Email">
          {reporter.email ?? "—"}
        </Descriptions.Item>
        <Descriptions.Item label="No. HP">
          {reporter.phone ?? "—"}
        </Descriptions.Item>
        <Descriptions.Item label="ID Pelapor">
          <Text copyable code style={{ fontSize: 11 }}>
            {record.reporter_id}
          </Text>
        </Descriptions.Item>
      </Descriptions>

      {/* Modal reject */}
      <Modal
        title="Tolak Laporan"
        open={rejectModal}
        onOk={handleReject}
        onCancel={() => setRejectModal(false)}
        okText="Tolak Laporan"
        okButtonProps={{ danger: true }}
        cancelText="Batal"
      >
        <Form layout="vertical">
          <Form.Item label="Alasan Penolakan">
            <Input.TextArea
              rows={3}
              placeholder="Contoh: Foto tidak jelas, laporan duplikat, konten tidak sesuai..."
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
            />
          </Form.Item>
        </Form>
      </Modal>




      {/* <Descriptions bordered column={1}>
        <Descriptions.Item label="Nama">{record?.name}</Descriptions.Item>
        <Descriptions.Item label="Kategori">{record?.category}</Descriptions.Item>
        <Descriptions.Item label="Lokasi">{record?.location}</Descriptions.Item>
        <Descriptions.Item label="Deskripsi">{record?.description}</Descriptions.Item>
        <Descriptions.Item label="Ciri Khusus">
          <Typography.Text type="danger">{record?.distinctive_features}</Typography.Text>
        </Descriptions.Item>
        <Descriptions.Item label="Status">
          <Tag color={statusColor[record?.status]}>{record?.status}</Tag>
        </Descriptions.Item>
        <Descriptions.Item label="Foto">
          <Image.PreviewGroup>
            {(record?.photo_urls ?? []).map((url: string, i: number) => (
              <Image key={i} src={url} width={80} style={{ marginRight: 8 }} />
            ))}
          </Image.PreviewGroup>
        </Descriptions.Item>
      </Descriptions> */}
    </Show>
  );
};