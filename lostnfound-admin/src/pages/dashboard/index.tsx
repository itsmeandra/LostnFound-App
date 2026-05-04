import { useList } from "@refinedev/core";
import { Card, Col, Row, Statistic } from "antd";

export const DashboardPage = () => {
  const { data: pending } = useList({
    resource: "items",
    filters: [{ field: "status", operator: "eq", value: "pending" }],
    meta: { select: "id" },
  });

  const { data: published } = useList({
    resource: "items",
    filters: [{ field: "status", operator: "eq", value: "published" }],
    meta: { select: "id" },
  });

  const { data: completed } = useList({
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
            value={pending?.total ?? 0}
            valueStyle={{ color: "#F57C00" }}
          />
        </Card>
      </Col>
      <Col span={8}>
        <Card>
          <Statistic
            title="Dipublikasi"
            value={published?.total ?? 0}
            valueStyle={{ color: "#388E3C" }}
          />
        </Card>
      </Col>
      <Col span={8}>
        <Card>
          <Statistic
            title="Selesai Dikembalikan"
            value={completed?.total ?? 0}
            valueStyle={{ color: "#757575" }}
          />
        </Card>
      </Col>
    </Row>
  );
};