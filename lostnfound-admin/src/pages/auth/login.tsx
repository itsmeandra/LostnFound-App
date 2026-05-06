import { AuthPage } from "@refinedev/antd";

export const LoginPage = () => {
  return (
    <AuthPage
      type="login"
      title={<h3 style={{ textAlign: "center" }}>Lost n Found Admin Dashboard</h3>}
      formProps={{
        initialValues: {
          email: "",
          password: "",
        },
      }}
    />
  );
};