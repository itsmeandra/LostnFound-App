import { Show } from "@refinedev/antd";
import { useShow } from "@refinedev/core";
import { Typography, Tag, Descriptions, Image } from "antd";

export const ItemShow = () => {
  const { query } = useShow({ resource: "items" });
  const record = query?.data?.data;

  const statusColor: Record<string, string> = {
    pending: "orange", published: "green",
    claimed: "blue", completed: "default", rejected: "red",
  };

  return (
    <Show>
      <Descriptions bordered column={1}>
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
      </Descriptions>
    </Show>
  );
};