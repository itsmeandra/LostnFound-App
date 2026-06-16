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
  const [approveOpen, setApproveOpen] = useState(false);
  const [rejectOpen, setRejectOpen] = useState(false);
  const [completeOpen, setCompleteOpen] = useState(false);

  const [approveForm] = Form.useForm();
  const [rejectForm] = Form.useForm();

  const { query } = useShow({
    resource: "items", meta: {
      select: "*, profiles!reporter_id(full_name, email, phone)",
    }
  });
  const record = query?.data?.data as any;

  const { mutate: updateItem, mutation } = useUpdate();
  const isLoading = mutation.isPending

  const handleApprove = async () => {
    try {
      const { drop_point, storage_location } = await approveForm.validateFields();
      updateItem({
        resource: "items",
        id: record.id,
        values: {
          status: "published",
          drop_point: drop_point || null,
          storage_location: storage_location || null,
        },
        successNotification: {
          message: "Laporan disetujui dan dipublikasi!",
          type: "success",
        },
      });
      setApproveOpen(false);
      approveForm.resetFields();
    } catch (_) { }
  };

  const handleReject = async () => {
    try {
      const { reason } = await rejectForm.validateFields();
      updateItem({
        resource: "items",
        id: record.id,
        values: {
          status: "rejected",
          reject_reason: reason,
        },
        successNotification: { message: "Laporan ditolak.", type: "error" },
      });
      setRejectOpen(false);
      rejectForm.resetFields();
    } catch (_) { }
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

  return (
    <Show
      title={`Detail Laporan: ${record.name ?? ""}`}
      headerButtons={
        <Space>
          {record.status === "pending" && (
            <>
              <Button
                type="primary"
                icon={<CheckCircleOutlined />}
                onClick={() => setApproveOpen(true)}
              >
                Setuju
              </Button>
              <Button
                danger
                icon={<CloseCircleOutlined />}
                onClick={() => setRejectOpen(true)}
              >
                Tolak
              </Button>
              {/* <Popconfirm
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
              </Popconfirm> */}
              {/* <Button
                danger
                icon={<CloseCircleOutlined />}
                onClick={() => setRejectModal(true)}
              >
                Tolak
              </Button> */}
            </>
          )}
          {record.status === "claimed" && (
            <Button
              icon={<TrophyOutlined />}
              onClick={() => setCompleteOpen(true)}
            >
              Selesai / Dikembalikan
            </Button>
            // <Popconfirm
            //   title="Tandai barang sebagai sudah dikembalikan ke pemilik?"
            //   onConfirm={handleComplete}
            //   okText="Ya, selesai"
            //   cancelText="Batal"
            // >
            //   <Button icon={<TrophyOutlined />} loading={isLoading}>
            //     Selesai / Dikembalikan
            //   </Button>
            // </Popconfirm>
          )}
        </Space>
      }
    >

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

          {record.drop_point && (
            <Descriptions.Item label="Lokasi Penitipan (Publik)" span={2}>
              <Text style={{ color: "#1565C0", fontWeight: 500 }}>{record.drop_point}</Text>
            </Descriptions.Item>
          )}

          {record.storage_location && (
            <Descriptions.Item label="Rak/Laci Internal (Admin)" span={2}>
              <Text type="secondary">{record.storage_location}</Text>
            </Descriptions.Item>
          )}
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
          {reporter.phone ? (
            <Space>
              <a href={`tel:${reporter.phone}`}>{reporter.phone}</a>
              <Button
                size="small"
                href={`https://wa.me/${reporter.phone.replace(/\D/g, "")}`}
                target="_blank"
              >
                WhatsApp
              </Button>
            </Space>
          ) : "—"}
        </Descriptions.Item>
        <Descriptions.Item label="ID Pelapor">
          <Text copyable code style={{ fontSize: 11 }}>
            {record.reporter_id}
          </Text>
        </Descriptions.Item>
      </Descriptions>

      {/* Modal Approve */}
      <Modal
        title="Setujui Laporan & Isi Lokasi"
        open={approveOpen}
        onOk={handleApprove}
        onCancel={() => { setApproveOpen(false); approveForm.resetFields(); }}
        okText="Publikasikan"
        cancelText="Batal"
        okButtonProps={{ loading: isLoading }}
      >
        <Form form={approveForm} layout="vertical">
          <Form.Item
            name="drop_point"
            label="Lokasi Pengambilan (Publik)"
            rules={[{ required: true, message: "Lokasi wajib diisi" }]}
          >
            <Input placeholder="Contoh: Administrasi Kampus" />
          </Form.Item>
          <Form.Item name="storage_location" label="Lokasi Internal (Opsional)">
            <Input placeholder="Contoh: Laci B3" />
          </Form.Item>
        </Form>
      </Modal>

      {/* Modal Reject */}
      <Modal
        title="Tolak Laporan"
        open={rejectOpen}
        onOk={handleReject}
        onCancel={() => { setRejectOpen(false); rejectForm.resetFields(); }}
        okText="Tolak"
        okButtonProps={{ danger: true, loading: isLoading }}
        cancelText="Batal"
      >
        <Form form={rejectForm} layout="vertical">
          <Form.Item
            name="reason"
            label="Alasan Penolakan"
            rules={[{ required: true }, { min: 10, message: "Terlalu singkat" }]}
          >
            <Input.TextArea
              rows={3}
              placeholder="Alasan penolakan..."
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* Modal Selesai */}
      <Modal
        title="Tandai Barang Selesai?"
        open={completeOpen}
        onOk={handleComplete}
        onCancel={() => setCompleteOpen(false)}
        okText="Ya, Selesai"
        cancelText="Batal"
        okButtonProps={{ loading: isLoading }}
      >
        <p>Konfirmasi bahwa barang fisik sudah diserahkan kepada pemilik aslinya.</p>
      </Modal>
    </Show>
  );
};