import {
    List,
    useTable,
    DateField,
    ShowButton,
} from "@refinedev/antd";
import {
    Table, Tag, Space, Typography, Avatar, Select,
    Popconfirm, Button, Modal, Descriptions, Badge,
} from "antd";
import {
    UserOutlined, SafetyOutlined,
} from "@ant-design/icons";
import { useUpdate } from "@refinedev/core";
import { useState } from "react";

const { Text } = Typography;

// ── Profile List ──────────────────────────────────────────────
export const ProfileList = () => {
    const [roleFilter, setRoleFilter] = useState<string | undefined>(undefined);

    const { tableProps, setFilters } = useTable({
        resource: "profiles",
        filters: { initial: [] },
        sorters: { initial: [{ field: "created_at", order: "desc" }] },
        meta: {
            select: "id, full_name, email, phone, role, created_at, avatar_url",
        },
    });

    const { mutate: updateProfile } = useUpdate();
    const [selectedProfile, setSelectedProfile] = useState<any>(null);

    // Ubah role user
    const handleRoleChange = (id: string, newRole: "admin" | "user") => {
        updateProfile({
            resource: "profiles",
            id,
            values: { role: newRole },
            successNotification: {
                message: `Role berhasil diubah menjadi ${newRole}.`,
                type: "success",
            },
        });
    };

    // Filter berdasarkan role
    const handleRoleFilter = (val: string | undefined) => {
        setRoleFilter(val);
        setFilters(
            val ? [{ field: "role", operator: "eq", value: val }] : []
        );
    };

    return (
        <List
            title="Manajemen Pengguna"
            headerButtons={() => (
                <Select
                    allowClear
                    placeholder="Filter role"
                    style={{ width: 160 }}
                    value={roleFilter}
                    onChange={handleRoleFilter}
                    options={[
                        { value: "user", label: "Pengguna Biasa" },
                        { value: "admin", label: "Administrator" },
                    ]}
                />
            )}
        >
            <Table {...tableProps} rowKey="id" size="small">
                {/* Avatar + nama */}
                <Table.Column
                    title="Pengguna"
                    render={(_: any, record: any) => (
                        <Space>
                            {record.avatar_url ? (
                                <Avatar src={record.avatar_url} size={36} />
                            ) : (
                                <Avatar
                                    size={36}
                                    style={{
                                        background: "#E6F1FB",
                                        color: "#0C447C",
                                        fontWeight: 500,
                                    }}
                                >
                                    {record.full_name?.[0]?.toUpperCase() ?? "?"}
                                </Avatar>
                            )}
                            <Space direction="vertical" size={0}>
                                <Text
                                    strong
                                    style={{ fontSize: 13, cursor: "pointer", color: "#1677ff" }}
                                    onClick={() => setSelectedProfile(record)}
                                >
                                    {record.full_name || "(Nama belum diatur)"}
                                </Text>
                                <Text type="secondary" style={{ fontSize: 11 }}>
                                    {record.email}
                                </Text>
                            </Space>
                        </Space>
                    )}
                />

                {/* Telepon */}
                <Table.Column
                    title="Telepon"
                    dataIndex="phone"
                    width={140}
                    render={(v) =>
                        v ? (
                            <a href={`tel:${v}`} style={{ fontSize: 12 }}>{v}</a>
                        ) : (
                            <Text type="secondary" style={{ fontSize: 12 }}>—</Text>
                        )
                    }
                />

                {/* Role badge */}
                <Table.Column
                    title="Role"
                    dataIndex="role"
                    width={130}
                    render={(role: string) => (
                        <Tag
                            color={role === "admin" ? "purple" : "default"}
                            icon={role === "admin" ? <SafetyOutlined /> : <UserOutlined />}
                        >
                            {role === "admin" ? "Administrator" : "Pengguna"}
                        </Tag>
                    )}
                />

                {/* Bergabung sejak */}
                <Table.Column
                    title="Bergabung"
                    dataIndex="created_at"
                    width={120}
                    render={(v) => <DateField value={v} format="D MMM YYYY" />}
                />

                {/* Aksi ubah role */}
                <Table.Column
                    title="Aksi"
                    width={160}
                    render={(_: any, record: any) => (
                        <Space>
                            {record.role === "user" ? (
                                <Popconfirm
                                    title="Jadikan administrator?"
                                    description="User akan mendapat akses penuh ke dashboard admin."
                                    onConfirm={() => handleRoleChange(record.id, "admin")}
                                    okText="Ya, jadikan admin"
                                    cancelText="Batal"
                                    okButtonProps={{ type: "primary" }}
                                >
                                    <Button size="small" type="dashed">
                                        Jadikan Admin
                                    </Button>
                                </Popconfirm>
                            ) : (
                                <Popconfirm
                                    title="Turunkan ke pengguna biasa?"
                                    description="Akses dashboard admin akan dicabut."
                                    onConfirm={() => handleRoleChange(record.id, "user")}
                                    okText="Ya, turunkan"
                                    cancelText="Batal"
                                    okButtonProps={{ danger: true }}
                                >
                                    <Button size="small" danger>
                                        Turunkan Role
                                    </Button>
                                </Popconfirm>
                            )}
                        </Space>
                    )}
                />
            </Table>

            {/* Modal detail profil */}
            <Modal
                title="Detail Pengguna"
                open={!!selectedProfile}
                onCancel={() => setSelectedProfile(null)}
                footer={
                    <Button onClick={() => setSelectedProfile(null)}>Tutup</Button>
                }
                width={480}
            >
                {selectedProfile && (
                    <Descriptions bordered column={1} size="small">
                        <Descriptions.Item label="Nama">
                            {selectedProfile.full_name || "—"}
                        </Descriptions.Item>
                        <Descriptions.Item label="Email">
                            <a href={`mailto:${selectedProfile.email}`}>
                                {selectedProfile.email}
                            </a>
                        </Descriptions.Item>
                        <Descriptions.Item label="Telepon">
                            {selectedProfile.phone
                                ? <a href={`tel:${selectedProfile.phone}`}>{selectedProfile.phone}</a>
                                : <Text type="secondary">Tidak tersedia</Text>}
                        </Descriptions.Item>
                        <Descriptions.Item label="Role">
                            <Tag color={selectedProfile.role === "admin" ? "purple" : "default"}>
                                {selectedProfile.role === "admin" ? "Administrator" : "Pengguna Biasa"}
                            </Tag>
                        </Descriptions.Item>
                        <Descriptions.Item label="ID">
                            <Text
                                copyable
                                style={{ fontFamily: "monospace", fontSize: 11 }}
                            >
                                {selectedProfile.id}
                            </Text>
                        </Descriptions.Item>
                        <Descriptions.Item label="Bergabung">
                            <DateField value={selectedProfile.created_at} format="D MMMM YYYY, HH:mm" />
                        </Descriptions.Item>
                    </Descriptions>
                )}
            </Modal>
        </List>
    );
};