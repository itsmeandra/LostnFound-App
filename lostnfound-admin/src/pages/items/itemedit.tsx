import { Edit, useForm } from "@refinedev/antd";
import { Form, Input, Select } from "antd";

export const ItemEdit = () => {
  const { formProps, saveButtonProps } = useForm({ resource: "items" });
  return (
    <Edit saveButtonProps={saveButtonProps}>
      <Form {...formProps} layout="vertical">
        <Form.Item name="rejection_reason" label="Alasan Penolakan">
          <Input.TextArea rows={3} />
        </Form.Item>
        <Form.Item name="status" label="Status">
          <Select options={[
            { value: "pending",   label: "Menunggu Verifikasi" },
            { value: "published", label: "Dipublikasi" },
            { value: "claimed",   label: "Diklaim" },
            { value: "completed", label: "Selesai" },
            { value: "rejected",  label: "Ditolak" },
          ]} />
        </Form.Item>
      </Form>
    </Edit>
  );
};