import {
    List,
    DateField,
    useTable,
    ShowButton,
} from "@refinedev/antd";
import {
    Table,
    Space,
    Tag,
    Button,
    Popconfirm,
    Typography,
    Image,
    Tooltip,
    Modal,
    Input,
    Form,
} from "antd";
import {
    CheckCircleOutlined,
    CloseCircleOutlined,
    EyeOutlined,
    LockOutlined,
} from "@ant-design/icons";
import { useUpdate } from "@refinedev/core";
import { useState } from "react";

const { Text } = Typography;

// Status warna & label (sama dengan Flutter)
const statusColors: Record<string, string> = {
    pending: "orange",
    approved: "green",
    rejected: "red",
};

const statusLabels: Record<string, string> = {
    pending: "Menunggu Verifikasi",
    approved: "Disetujui",
    rejected: "Ditolak",
};

export const ClaimList = () => {
    const [rejectModal, setRejectModal] = useState<{
        open: boolean;
        claimId: string | null;
        reason: string;
    }>({ open: false, claimId: null, reason: "" });

    const { tableProps } = useTable({
        resource: "claims",
        sorters: { initial: [{ field: "created_at", order: "desc" }] },
        // Join claims dengan items dan profiles untuk tampilkan info lengkap
        meta: {
            select: `
        *,
        items(id, name, category, photo_urls, type),
        profiles!claimant_id(full_name, email, phone)
      `,
        },
    });

    const { mutate: updateClaim, isLoading } = useUpdate();

    //───── Approve klaim ─────
    // 1. Ubah status klaim → approved dan item → claimed
    const handleApprove = (claimId: string, itemId: string) => {
        // Update klaim
        updateClaim({
            resource: "claims",
            id: claimId,
            values: { status: "approved" },
            successNotification: {
                message: "Klaim disetujui!",
                description: "Item akan diubah ke status 'diklaim'.",
                type: "success",
            },
        });
        // Update item ke status 'claimed'
        updateClaim({
            resource: "items",
            id: itemId,
            values: { status: "claimed" },
        });
    };

    //───── Reject klaim ─────
    const handleReject = () => {
        if (!rejectModal.claimId) return;
        updateClaim({
            resource: "claims",
            id: rejectModal.claimId,
            values: {
                status: "rejected",
                rejection_reason: rejectModal.reason || "Ciri khusus tidak sesuai.",
            },
            successNotification: {
                message: "Klaim ditolak.",
                type: "error",
            },
        });
        setRejectModal({ open: false, claimId: null, reason: "" });
    };

    return (
        <>
            <List title="Manajemen Klaim">
                <Table {...tableProps} rowKey="id" size="small">

                    {/* Status klaim */}
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

                    {/* Barang yang diklaim */}
                    <Table.Column
                        title="Barang"
                        dataIndex="items"
                        render={(item: any) => (
                            <Space>
                                {item?.photo_urls?.[0] && (
                                    <Image
                                        src={item.photo_urls[0]}
                                        width={40}
                                        height={40}
                                        style={{ objectFit: "cover", borderRadius: 4 }}
                                        preview={false}
                                    />
                                )}
                                <Space direction="vertical" size={0}>
                                    <Text strong style={{ fontSize: 13 }}>
                                        {item?.name ?? "—"}
                                    </Text>
                                    <Text type="secondary" style={{ fontSize: 11 }}>
                                        {item?.category}
                                    </Text>
                                </Space>
                            </Space>
                        )}
                    />

                    {/* Pengklaim */}
                    <Table.Column
                        title="Pengklaim"
                        dataIndex="profiles"
                        width={180}
                        render={(profile: any) => (
                            <Space direction="vertical" size={0}>
                                <Text style={{ fontSize: 13 }}>
                                    {profile?.full_name ?? "—"}
                                </Text>
                                <Text type="secondary" style={{ fontSize: 11 }}>
                                    {profile?.phone ?? profile?.email}
                                </Text>
                            </Space>
                        )}
                    />

                    {/* Ciri khusus — RAHASIA, hanya admin */}
                    <Table.Column
                        title={
                            <Space>
                                <LockOutlined />
                                Ciri Khusus (Rahasia)
                            </Space>
                        }
                        dataIndex="secret_description"
                        width={220}
                        render={(text: string) => (
                            <Tooltip title={text}>
                                <Text
                                    style={{
                                        fontSize: 12,
                                        color: "#d46b08",
                                        maxWidth: 200,
                                        display: "block",
                                    }}
                                    ellipsis
                                >
                                    {text}
                                </Text>
                            </Tooltip>
                        )}
                    />

                    {/* Foto bukti */}
                    <Table.Column
                        title="Bukti Foto"
                        dataIndex="proof_photos"
                        width={120}
                        render={(photos: string[]) =>
                            photos?.length > 0 ? (
                                <Image.PreviewGroup>
                                    <Space>
                                        {photos.slice(0, 2).map((url, i) => (
                                            <Image
                                                key={i}
                                                src={url}
                                                width={36}
                                                height={36}
                                                style={{ objectFit: "cover", borderRadius: 4 }}
                                            />
                                        ))}
                                        {photos.length > 2 && (
                                            <Text type="secondary" style={{ fontSize: 11 }}>
                                                +{photos.length - 2}
                                            </Text>
                                        )}
                                    </Space>
                                </Image.PreviewGroup>
                            ) : (
                                <Text type="secondary" style={{ fontSize: 11 }}>
                                    Tidak ada
                                </Text>
                            )
                        }
                    />

                    {/* Tanggal klaim */}
                    <Table.Column
                        title="Tanggal"
                        dataIndex="created_at"
                        width={110}
                        render={(v) => <DateField value={v} format="D MMM YYYY" />}
                    />

                    {/* Aksi */}
                    <Table.Column
                        title="Aksi"
                        width={140}
                        render={(_, record: any) => (
                            <Space>
                                {/* Approve — hanya saat pending */}
                                {record.status === "pending" && (
                                    <Popconfirm
                                        title="Setujui klaim ini?"
                                        description="Item akan berubah status menjadi 'Diklaim'. Hubungi pelapor untuk koordinasi serah terima."
                                        onConfirm={() =>
                                            handleApprove(record.id, record.items?.id)
                                        }
                                        okText="Ya, setujui"
                                        cancelText="Batal"
                                    >
                                        <Tooltip title="Setujui">
                                            <Button
                                                size="small"
                                                type="primary"
                                                icon={<CheckCircleOutlined />}
                                                loading={isLoading}
                                            />
                                        </Tooltip>
                                    </Popconfirm>
                                )}

                                {/* Reject dengan alasan */}
                                {record.status === "pending" && (
                                    <Tooltip title="Tolak">
                                        <Button
                                            size="small"
                                            danger
                                            icon={<CloseCircleOutlined />}
                                            onClick={() =>
                                                setRejectModal({
                                                    open: true,
                                                    claimId: record.id,
                                                    reason: "",
                                                })
                                            }
                                        />
                                    </Tooltip>
                                )}

                                <ShowButton hideText size="small" recordItemId={record.id} />
                            </Space>
                        )}
                    />
                </Table>
            </List>

            {/* Modal reject dengan input alasan */}
            <Modal
                title="Tolak Klaim"
                open={rejectModal.open}
                onOk={handleReject}
                onCancel={() =>
                    setRejectModal({ open: false, claimId: null, reason: "" })
                }
                okText="Tolak Klaim"
                okButtonProps={{ danger: true }}
                cancelText="Batal"
            >
                <Form layout="vertical">
                    <Form.Item
                        label="Alasan Penolakan"
                        extra="Alasan ini akan disimpan di database (tidak dikirim ke user — notifikasi menyusul di Minggu 3)."
                    >
                        <Input.TextArea
                            rows={3}
                            placeholder="Contoh: Ciri khusus yang disebutkan tidak sesuai dengan barang..."
                            value={rejectModal.reason}
                            onChange={(e) =>
                                setRejectModal((prev) => ({
                                    ...prev,
                                    reason: e.target.value,
                                }))
                            }
                        />
                    </Form.Item>
                </Form>
            </Modal>
        </>
    );
};

//───── ClaimShow — halaman detail klaim ─────
export const ClaimShow = () => {
    return <div style={{ padding: 24 }}>Detail klaim — dikembangkan lebih lanjut di Minggu 3</div>;
};