import { useList } from "@refinedev/core";
import { Card, Col, Row, Statistic } from "antd";

export const DashboardPage = () => {
  const { query: pending } = useList({
    resource: "items",
    filters: [{ field: "status", operator: "eq", value: "pending" }],
    meta: { select: "id" },
  });

  const { query: published } = useList({
    resource: "items",
    filters: [{ field: "status", operator: "eq", value: "published" }],
    meta: { select: "id" },
  });

  const { query: completed } = useList({
    resource: "items",
    filters: [{ field: "status", operator: "eq", value: "completed" }],
    meta: { select: "id" },
  });

  return (
    <Row gutter={[16, 16]} style={{ padding: 24 }}>
      <Col span={8}>
        <Card>
          <Statistic
            title="Menunggu Verifikasi"
            value={pending?.data?.total ?? 0}
            valueStyle={{ color: "#f57200" }}
          />
        </Card>
      </Col>
      <Col span={8}>
        <Card>
          <Statistic
            title="Dipublikasi"
            value={published?.data?.total ?? 0}
            valueStyle={{ color: "#10db20" }}
          />
        </Card>
      </Col>
      <Col span={8}>
        <Card>
          <Statistic
            title="Selesai Dikembalikan"
            value={completed?.data?.total ?? 0}
            valueStyle={{ color: "#757575" }}
          />
        </Card>
      </Col>
    </Row>
  );
};