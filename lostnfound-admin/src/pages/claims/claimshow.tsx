import { Show } from "@refinedev/antd";
import { useShow, useUpdate, useNavigation } from "@refinedev/core";
import {
    Space, Button, Tag, Alert, Image, Descriptions,
    Typography, Divider, Row, Col, Card, Form, Modal, Popconfirm, Input, Avatar
} from "antd";
import {
    CheckCircleOutlined, CloseCircleOutlined,
    ExclamationCircleOutlined, ArrowLeftOutlined,
    PhoneOutlined, MailOutlined, SafetyCertificateOutlined, UserOutlined
} from "@ant-design/icons";
import { useState } from "react";
import dayjs from "dayjs";

const { Text, Paragraph, Title } = Typography;
const { TextArea } = Input;

//───── Konstanta Status & Kategori ─────
const CLAIM_STATUS: Record<string, { color: string; label: string }> = {
    pending: { color: "orange", label: "Menunggu Verifikasi" },
    approved: { color: "green", label: "Disetujui" },
    rejected: { color: "red", label: "Ditolak" },
};

const CATEGORY_LABELS: Record<string, string> = {
    electronics: "Elektronik", wallet: "Dompet", keys: "Kunci",
    clothing: "Pakaian", bag: "Tas", documents: "Dokumen",
    glasses: "Kacamata", jewelry: "Perhiasan", other: "Lainnya",
};

export const ClaimShow = () => {
    const { query } = useShow({
        resource: "claims",
        meta: {
            select: `
        *,
        items:item_id (
          id, name, category, location, status,
          photo_urls, distinctive_features, type
        ),
        profiles:claimant_id (
          full_name, email, phone
        )
      `,
        },
    });

    const record = query?.data?.data as any;

    // Menggunakan destrukturisasi dan alias nama yang aman untuk versi v5
    const { mutate: updateClaim, mutation } = useUpdate();
    const isUpdatingClaim = mutation.isPending;
    const { mutate: updateItem } = useUpdate();
    const { list } = useNavigation();

    const [rejectOpen, setRejectOpen] = useState(false);
    const [rejectForm] = Form.useForm();

    if (!record) return null;

    const statusCfg = CLAIM_STATUS[record.status] ?? { color: "default", label: record.status };
    const matchScore = computeMatchScore(record.secret_description, record.items?.distinctive_features ?? "");

    //───── Handler: Approve Klaim ─────
    const handleApprove = () => {
        updateClaim({
            resource: "claims",
            id: record.id,
            values: { status: "approved" },
        });

        if (record.item_id) {
            updateItem({
                resource: "items",
                id: record.item_id,
                values: { status: "claimed" },
                successNotification: { message: "Klaim disetujui!", type: "success" },
            }, {
                // Callback diletakkan di parameter kedua (Kantong Terpisah)
                onSuccess: () => list("claims"),
            });
        }
    };

    //───── Handler: Reject Klaim ─────
    const handleReject = async () => {
        try {
            const { reason } = await rejectForm.validateFields();
            updateClaim({
                resource: "claims",
                id: record.id,
                values: { status: "rejected", rejection_reason: reason },
                successNotification: { message: "Klaim ditolak.", type: "error" },
            }, {
                // Callback diletakkan di parameter kedua (Kantong Terpisah)
                onSuccess: () => {
                    setRejectOpen(false);
                    list("claims");
                    rejectForm.resetFields();
                },
            });
        } catch (_) { }
    };

    return (
        <Show
            title={
                <Space>
                    <Title level={4} style={{ margin: 0 }}>Detail Verifikasi Klaim</Title>
                    <Tag color={statusCfg.color}>{statusCfg.label}</Tag>
                </Space>
            }
            headerButtons={
                <Space>
                    <Button icon={<ArrowLeftOutlined />} onClick={() => list("claims")}>
                        Kembali
                    </Button>
                    {record.status === "pending" && (
                        <>
                            <Popconfirm
                                title="Setujui klaim ini?"
                                description="Status barang akan otomatis berubah menjadi 'Diklaim'."
                                onConfirm={handleApprove}
                                okText="Setujui"
                                cancelText="Batal"
                            >
                                <Button
                                    type="primary"
                                    icon={<CheckCircleOutlined />}
                                    loading={isUpdatingClaim}
                                    style={{ background: "#52c41a", borderColor: "#52c41a" }}
                                >
                                    Approve
                                </Button>
                            </Popconfirm>
                            <Button
                                danger
                                icon={<CloseCircleOutlined />}
                                onClick={() => setRejectOpen(true)}
                            >
                                Tolak
                            </Button>
                        </>
                    )}
                </Space>
            }
        >
            <Space direction="vertical" size={20} style={{ width: "100%" }}>

                {/* ── 1. Skor Kecocokan Algoritma Kata Kunci ── */}
                <MatchScoreCard score={matchScore} />

                {/* ── 2. Panel Komparasi Verifikasi Silang ── */}
                <div>
                    <Text strong style={{ fontSize: 14, display: "block", marginBottom: 10 }}>
                        Komparasi Ciri Khusus
                    </Text>
                    <Row gutter={16}>
                        <Col xs={24} md={12} style={{ marginBottom: 12 }}>
                            <div style={{ background: "#fffbe6", border: "1px solid #faad14", borderRadius: 8, padding: "12px", height: "100%" }}>
                                <Space style={{ marginBottom: 8 }}>
                                    <ExclamationCircleOutlined style={{ color: "#faad14" }} />
                                    <Text strong style={{ color: "#614700" }}>Jawaban / Deskripsi Pemohon</Text>
                                </Space>
                                <Paragraph style={{ margin: 0, color: "#614700" }}>
                                    {record.secret_description || <Text type="secondary" italic>(Kosong)</Text>}
                                </Paragraph>
                            </div>
                        </Col>
                        <Col xs={24} md={12} style={{ marginBottom: 12 }}>
                            <div style={{ background: "#e6f7ff", border: "1px solid #91caff", borderRadius: 8, padding: "12px", height: "100%" }}>
                                <Space style={{ marginBottom: 8 }}>
                                    <SafetyCertificateOutlined style={{ color: "#0958d9" }} />
                                    <Text strong style={{ color: "#003eb3" }}>Ciri Rahasia di Laporan Utama</Text>
                                </Space>
                                <Paragraph style={{ margin: 0, color: "#003eb3" }}>
                                    {record.items?.distinctive_features || <Text type="secondary" italic>Pelapor tidak mengisi ciri khusus</Text>}
                                </Paragraph>
                            </div>
                        </Col>
                    </Row>
                </div>

                <Divider style={{ margin: "10px 0" }} />

                {/* ── 3. Informasi Barang & Pemohon Bersebelahan ── */}
                <Row gutter={16}>
                    <Col xs={24} lg={12}>
                        <Descriptions title="Informasi Barang" bordered column={1} size="small" style={{ marginBottom: 16 }}>
                            <Descriptions.Item label="Nama Barang"><Text strong>{record.items?.name ?? "—"}</Text></Descriptions.Item>
                            <Descriptions.Item label="Kategori">{CATEGORY_LABELS[record.items?.category ?? ""] ?? "—"}</Descriptions.Item>
                            <Descriptions.Item label="Lokasi Temuan/Hilang">{record.items?.location ?? "—"}</Descriptions.Item>
                            <Descriptions.Item label="Status Item"><Tag color={record.items?.status === "claimed" ? "blue" : "green"}>{record.items?.status}</Tag></Descriptions.Item>
                        </Descriptions>

                        {/* Foto Barang Utama */}
                        {record.items?.photo_urls?.length > 0 && (
                            <div style={{ marginBottom: 16 }}>
                                <Text type="secondary" style={{ fontSize: 12, display: "block", marginBottom: 6 }}>Foto Acuan Barang:</Text>
                                <Image.PreviewGroup>
                                    <Space wrap>
                                        {record.items.photo_urls.map((url: string, i: number) => (
                                            <Image key={i} src={url} width={80} height={80} style={{ objectFit: "cover", borderRadius: 6 }} />
                                        ))}
                                    </Space>
                                </Image.PreviewGroup>
                            </div>
                        )}
                    </Col>

                    <Col xs={24} lg={12}>
                        <Descriptions title="Informasi Pemohon Klaim" bordered column={1} size="small" style={{ marginBottom: 16 }}>
                            <Descriptions.Item label="Nama Pemohon">
                                <Space>
                                    <Avatar size="small" icon={<UserOutlined />} style={{ backgroundColor: "#1ee3cf" }} />
                                    <Text strong>{record.profiles?.full_name ?? "—"}</Text>
                                </Space>
                            </Descriptions.Item>
                            <Descriptions.Item label="Email">
                                {record.profiles?.email ? <a href={`mailto:${record.profiles.email}`}><MailOutlined /> {record.profiles.email}</a> : "—"}
                            </Descriptions.Item>
                            <Descriptions.Item label="No. Telepon / WA">
                                {record.profiles?.phone ? <a href={`tel:${record.profiles.phone}`}><PhoneOutlined /> {record.profiles.phone}</a> : <Text type="secondary">Tidak tersedia</Text>}
                            </Descriptions.Item>
                            <Descriptions.Item label="Waktu Pengajuan">{dayjs(record.created_at).format("D MMMM YYYY, HH:mm")}</Descriptions.Item>
                        </Descriptions>
                    </Col>
                </Row>

                {/* ── 4. Foto Bukti Kepemilikan ── */}
                <Card title="Berkas / Foto Bukti Kepemilikan Pemohon" size="small" style={{ background: "#fafafa" }}>
                    {record.proof_photos?.length > 0 ? (
                        <Image.PreviewGroup>
                            <Space wrap>
                                {record.proof_photos.map((url: string, i: number) => (
                                    <Image
                                        key={i}
                                        src={url}
                                        width={120}
                                        height={120}
                                        style={{ objectFit: "cover", borderRadius: 8, boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}
                                    />
                                ))}
                            </Space>
                        </Image.PreviewGroup>
                    ) : (
                        <Alert
                            message="Tidak Ada Lampiran Foto Bukti"
                            description="Pemohon mengajukan klaim tanpa menyertakan bukti gambar berkas (KTM/Nota/Foto lama)."
                            type="info"
                            showIcon
                        />
                    )}
                </Card>

                {/* Tampilan Alasan Penolakan Lama (Jika Ada) */}
                {record.status === "rejected" && record.rejection_reason && (
                    <Alert
                        message="Riwayat Penolakan Laporan"
                        description={`Alasan: ${record.rejection_reason}`}
                        type="error"
                        showIcon
                    />
                )}
            </Space>

            {/* ══ MODAL FORM: Penolakan Klaim ══════════════════════ */}
            <Modal
                title={
                    <Space>
                        <ExclamationCircleOutlined style={{ color: "#ff4d4f" }} />
                        <span>Konfirmasi Penolakan Klaim</span>
                    </Space>
                }
                open={rejectOpen}
                onOk={handleReject}
                onCancel={() => { setRejectOpen(false); rejectForm.resetFields(); }}
                okText="Tolak Klaim"
                cancelText="Batal"
                okButtonProps={{ danger: true, loading: isUpdatingClaim }}
            >
                <Form form={rejectForm} layout="vertical" style={{ marginTop: 14 }}>
                    <Form.Item
                        name="reason"
                        label="Alasan Penolakan Resmi"
                        rules={[
                            { required: true, message: "Wajib menuliskan alasan penolakan" },
                            { min: 10, message: "Berikan alasan yang jelas (minimal 10 karakter)" },
                        ]}
                    >
                        <TextArea
                            rows={4}
                            placeholder="Contoh: Deskripsi warna striping dompet bagian dalam tidak sesuai dengan barang temuan asli..."
                        />
                    </Form.Item>
                </Form>
            </Modal>
        </Show>
    );
};

// ──────────────────────────────────────────────────
// Komponen Sub UI: Match Score Badge Card
// ──────────────────────────────────────────────────
const MatchScoreCard = ({ score }: { score: number }) => {
    const pct = Math.round(score * 100);
    const color = pct >= 70 ? "#52c41a" : pct >= 40 ? "#faad14" : "#ff4d4f";
    const label = pct >= 70 ? "Indikasi Sangat Cocok" : pct >= 40 ? "Perlu Pemeriksaan Detail" : "Indikasi Kurang Cocok";

    return (
        <Card size="small" style={{ borderColor: color, background: `${color}05` }}>
            <Row align="middle" gutter={16}>
                <Col>
                    <div style={{ width: 52, height: 52, borderRadius: "50%", border: `3px solid ${color}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                        <Text strong style={{ fontSize: 15, color }}>{pct}%</Text>
                    </div>
                </Col>
                <Col flex={1}>
                    <Text strong style={{ color, fontSize: 14 }}>{label}</Text><br />
                    <Text type="secondary" style={{ fontSize: 11 }}>
                        Skor berdasarkan kemiripan tekstual kata kunci unik antara form klaim dan data rahasia. Keputusan akhir tetap berada di tangan admin.
                    </Text>
                </Col>
            </Row>
        </Card>
    );
};

// ───────────────────────────────────────────────────────
// Utilitas Fungsi: Jaccard Similarity String Tokenizer
// ───────────────────────────────────────────────────────
function computeMatchScore(answer: string, reference: string): number {
    if (!answer || !reference) return 0;
    const tokenize = (s: string) => s.toLowerCase().replace(/[^a-z0-9\s]/g, " ").split(/\s+/).filter((w) => w.length > 2);
    const answerWords = new Set(tokenize(answer));
    const referenceWords = new Set(tokenize(reference));
    if (referenceWords.size === 0) return 0;
    let matches = 0;
    referenceWords.forEach((w) => { if (answerWords.has(w)) matches++; });
    const union = new Set([...answerWords, ...referenceWords]);
    return union.size === 0 ? 0 : matches / union.size;
}
