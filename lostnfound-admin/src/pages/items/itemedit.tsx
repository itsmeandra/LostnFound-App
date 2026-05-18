import { Edit, useForm } from "@refinedev/antd";
import { useNavigation, useDelete } from "@refinedev/core";
import {
  Form, Input, Select, DatePicker, Button, Space,
  Divider, Alert, Modal, Image, Tooltip, Tag, Typography,
  Row, Col, Popconfirm,
} from "antd";
import {
  DeleteOutlined, PlusOutlined, ExclamationCircleOutlined,
  WarningOutlined,
} from "@ant-design/icons";
import { useState } from "react";
import dayjs from "dayjs";

const { TextArea } = Input;
const { Text } = Typography;


//───── Konstanta ─────
const CATEGORY_OPTIONS = [
  { value: "electronics", label: "Elektronik" },
  { value: "wallet", label: "Dompet" },
  { value: "keys", label: "Kunci" },
  { value: "clothing", label: "Pakaian & Aksesoris" },
  { value: "bag", label: "Tas" },
  { value: "documents", label: "Dokumen" },
  { value: "glasses", label: "Kacamata" },
  { value: "jewelry", label: "Perhiasan" },
  { value: "other", label: "Lainnya" },
];

const STATUS_OPTIONS = [
  { value: "pending", label: "Menunggu Verifikasi" },
  { value: "published", label: "Dipublikasi" },
  { value: "claimed", label: "Diklaim" },
  { value: "completed", label: "Selesai" },
  { value: "rejected", label: "Ditolak" },
];

const TYPE_OPTIONS = [
  { value: "found", label: "Barang Temuan" },
  { value: "lost", label: "Barang Hilang" },
];

export const ItemEdit = () => {
  const { list, show } = useNavigation();
  const { mutate: deleteItem, mutation } = useDelete();
  const isLoading = mutation.isPending;

  // useForm dari Refine: auto-fetch record + handle save
  const { formProps, saveButtonProps, query, id } = useForm({
    resource: "items",
    redirect: "show",   // setelah save, redirect ke halaman show
    meta: {
      select: "*, profiles(full_name, email)",
    },
    // Transform data sebelum dikirim ke Supabase
    onMutationSuccess: () => show("items", id as string),
  });

  const record = query?.data?.data as any;

  // State foto: track URL yang dihapus & URL baru yang ditambahkan
  const [photoUrls, setPhotoUrls] = useState<string[]>([]);
  const [newPhotoUrl, setNewPhotoUrl] = useState("");
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [photosInitialized, setPhotosInitialized] = useState(false);

  // Inisialisasi photoUrls dari data record (sekali saja)
  if (record?.photo_urls && !photosInitialized) {
    setPhotoUrls(record.photo_urls);
    setPhotosInitialized(true);
    // Sync ke form field
    formProps.form?.setFieldValue("photo_urls", record.photo_urls);
  }

  //───── Hapus satu foto dari list ─────
  const removePhoto = (index: number) => {
    const updated = photoUrls.filter((_, i) => i !== index);
    setPhotoUrls(updated);
    formProps.form?.setFieldValue("photo_urls", updated);
  };

  //───── Tambah URL foto baru ─────
  const addPhotoUrl = () => {
    const trimmed = newPhotoUrl.trim();
    if (!trimmed || photoUrls.includes(trimmed)) return;
    if (photoUrls.length >= 5) return; // maks 5 foto
    const updated = [...photoUrls, trimmed];
    setPhotoUrls(updated);
    formProps.form?.setFieldValue("photo_urls", updated);
    setNewPhotoUrl("");
  };

  //───── Hapus laporan (hard delete) ─────
  // Hard delete hanya untuk admin — item dihapus dari DB.
  // Alternatif lebih aman: update status ke 'archived' (soft delete).
  const handleDelete = () => {
    deleteItem(
      { resource: "items", id: id as string },
      {
        onSuccess: () => {
          setDeleteModalOpen(false);
          // Navigasi ke list setelah hapus
          list("items");
        },
      }
    );
  };

  //───── Transform values sebelum submit ─────
  // Pastikan photo_urls dari state lokal (bukan dari form field default)
  const handleFinish = (values: any) => {
    return {
      ...values,
      photo_urls: photoUrls,
      // DatePicker mengembalikan Dayjs object — convert ke string ISO
      item_date: values.item_date
        ? dayjs(values.item_date).format("YYYY-MM-DD")
        : undefined,
    };
  };

  return (
    <Edit
      title="Edit Laporan"
      saveButtonProps={saveButtonProps}
      headerButtons={() => (
        <Space>
          <Button onClick={() => list("items")}>Batal</Button>
          {/* Tombol hapus, dengan konfirmasi modal */}
          <Button
            danger
            icon={<DeleteOutlined />}
            onClick={() => setDeleteModalOpen(true)}
          >
            Hapus Laporan
          </Button>
        </Space>
      )}
    >
      <Form
        {...formProps}
        layout="vertical"
        onFinish={handleFinish}
      >
        {/* Peringatan untuk admin */}
        <Alert
          message="Perubahan langsung tersimpan ke database dan bisa dilihat pengguna."
          type="warning"
          showIcon
          style={{ marginBottom: 24 }}
        />

        <Row gutter={16}>
          {/* Kolom kiri */}
          <Col xs={24} md={12}>

            {/* Tipe laporan */}
            <Form.Item
              name="type"
              label="Tipe Laporan"
              rules={[{ required: true, message: "Wajib dipilih" }]}
            >
              <Select options={TYPE_OPTIONS} />
            </Form.Item>

            {/* Nama barang */}
            <Form.Item
              name="name"
              label="Nama Barang"
              rules={[
                { required: true, message: "Nama barang wajib diisi" },
                { min: 3, message: "Minimal 3 karakter" },
              ]}
            >
              <Input placeholder="Contoh: Dompet hitam pria" />
            </Form.Item>

            {/* Kategori */}
            <Form.Item
              name="category"
              label="Kategori"
              rules={[{ required: true, message: "Wajib dipilih" }]}
            >
              <Select options={CATEGORY_OPTIONS} />
            </Form.Item>

            {/* Lokasi */}
            <Form.Item
              name="location"
              label="Lokasi"
              rules={[{ required: true, message: "Lokasi wajib diisi" }]}
            >
              <Input placeholder="Contoh: Kantin Gedung A, Parkiran B" />
            </Form.Item>

            {/* Tanggal kejadian */}
            <Form.Item
              name="item_date"
              label="Tanggal Kejadian"
              // Konversi string date dari DB ke Dayjs untuk DatePicker
              getValueProps={(v) => ({
                value: v ? dayjs(v) : undefined,
              })}
              rules={[{ required: true, message: "Tanggal wajib diisi" }]}
            >
              <DatePicker
                style={{ width: "100%" }}
                format="D MMMM YYYY"
                disabledDate={(d) => d.isAfter(dayjs())}
              />
            </Form.Item>

          </Col>
          {/* Kolom kanan */}
          <Col xs={24} md={12}>

            {/* Status */}
            <Form.Item
              name="status"
              label="Status"
              rules={[{ required: true, message: "Status wajib dipilih" }]}
            >
              <Select options={STATUS_OPTIONS} />
            </Form.Item>

            {/* Alasan penolakan (hanya tampil jika status = rejected) */}
            <Form.Item
              noStyle
              shouldUpdate={(prev, curr) => prev.status !== curr.status}
            >
              {({ getFieldValue }) =>
                getFieldValue("status") === "rejected" && (
                  <Form.Item
                    name="rejection_reason"
                    label="Alasan Penolakan"
                  >
                    <TextArea
                      rows={2}
                      placeholder="Alasan yang akan diterima pelapor..."
                    />
                  </Form.Item>
                )
              }
            </Form.Item>

            {/* Deskripsi umum */}
            <Form.Item name="description" label="Deskripsi Umum">
              <TextArea
                rows={3}
                placeholder="Deskripsi yang bisa dilihat semua pengguna..."
              />
            </Form.Item>

            {/* Ciri khusus — dengan peringatan visual */}
            <Form.Item
              name="distinctive_features"
              label={
                <Space>
                  <span>Ciri Khusus</span>
                  <Tag color="red" style={{ fontSize: 10 }}>RAHASIA</Tag>
                </Space>
              }
              extra={
                <Text
                  type="warning"
                  style={{ fontSize: 12 }}
                >
                  <WarningOutlined /> Hanya admin yang bisa melihat field ini.
                  Jangan ubah tanpa alasan yang valid.
                </Text>
              }
            >
              <TextArea
                rows={2}
                placeholder="Ciri yang hanya diketahui pemilik asli..."
                style={{ borderColor: "#faad14", backgroundColor: "#fffbe6" }}
              />
            </Form.Item>

          </Col>
        </Row>

        {/* Manajemen Foto */}
        <Divider>Manajemen Foto</Divider>

        {/* Simpan photo_urls sebagai hidden field — dikontrol state lokal */}
        <Form.Item name="photo_urls" hidden>
          <Input />
        </Form.Item>

        {/* Grid foto existing */}
        {photoUrls.length > 0 ? (
          <div style={{ marginBottom: 16 }}>
            <Text
              style={{ fontSize: 13, display: "block", marginBottom: 8 }}
            >
              Foto saat ini ({photoUrls.length}/5):
            </Text>
            <Image.PreviewGroup>
              <Space wrap>
                {photoUrls.map((url, i) => (
                  <div key={i} style={{ position: "relative" }}>
                    <Image
                      src={url}
                      width={100}
                      height={100}
                      style={{ objectFit: "cover", borderRadius: 8 }}
                    />
                    <Tooltip title="Hapus foto ini">
                      <Button
                        danger
                        size="small"
                        shape="circle"
                        icon={<DeleteOutlined />}
                        style={{
                          position: "absolute",
                          top: -8,
                          right: -8,
                          width: 24,
                          height: 24,
                          minWidth: 24,
                          padding: 0,
                          fontSize: 11,
                        }}
                        onClick={() => removePhoto(i)}
                      />
                    </Tooltip>
                  </div>
                ))}
              </Space>
            </Image.PreviewGroup>
          </div>
        ) : (
          <Alert
            message="Tidak ada foto"
            description="Laporan ini tidak memiliki foto."
            type="info"
            showIcon
            style={{ marginBottom: 16 }}
          />
        )}

        {/* Tambah URL foto baru */}
        {/* {photoUrls.length < 5 && (
          <div style={{ marginBottom: 24 }}>
            <Text
              style={{ fontSize: 13, display: "block", marginBottom: 8 }}
            >
              Tambah foto (masukkan URL dari Supabase Storage):
            </Text>
            <Space.Compact style={{ width: "100%" }}>
              <Input
                value={newPhotoUrl}
                onChange={(e) => setNewPhotoUrl(e.target.value)}
                placeholder="https://xxx.supabase.co/storage/v1/object/..."
                onPressEnter={addPhotoUrl}
              />
              <Button
                type="primary"
                icon={<PlusOutlined />}
                onClick={addPhotoUrl}
                disabled={!newPhotoUrl.trim()}
              >
                Tambah
              </Button>
            </Space.Compact>
            <Text
              type="secondary"
              style={{ fontSize: 12, display: "block", marginTop: 4 }}
            >
              URL didapat dari Supabase Dashboard → Storage → item-photos →
              klik foto → salin URL
            </Text>
          </div>
        )} */}
      </Form>

      {/* Modal konfirmasi hapus */}
      <Modal
        title={
          <Space>
            <ExclamationCircleOutlined style={{ color: "#ff4d4f" }} />
            <span>Hapus Laporan Ini?</span>
          </Space>
        }
        open={deleteModalOpen}
        onCancel={() => setDeleteModalOpen(false)}
        footer={[
          <Button key="cancel" onClick={() => setDeleteModalOpen(false)}>
            Batal
          </Button>,
          <Button
            key="delete"
            danger
            type="primary"
            loading={isLoading}
            onClick={handleDelete}
          >
            Ya, Hapus Permanen
          </Button>,
        ]}
      >
        <p>
          Laporan <strong>{record?.name}</strong> akan dihapus secara
          permanen dari database. Tindakan ini{" "}
          <strong style={{ color: "#ff4d4f" }}>tidak bisa dibatalkan</strong>.
        </p>
        <Alert
          message="Perhatian"
          description="Semua klaim terkait laporan ini juga akan ikut terhapus (cascade delete di database)."
          type="error"
          showIcon
          style={{ marginTop: 12 }}
        />
      </Modal>
    </Edit >
  );
};