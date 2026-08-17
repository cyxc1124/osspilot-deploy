# osspilot-deploy

整栈编排（compose + helm）。不放服务业务代码。

## 提交

`<type>: <中文说明>`，必须保留 type 前缀。

镜像只引用 `ghcr.io/cyxc1124/osspilot-*:tag`，不要在本仓 `build:` 服务源码目录。编排只注入库和 Redis，不写 S3 / Ceph / ONLYOFFICE。

Helm 是六张独立 chart（`helm/osspilot-tenant-api` 等），六个 release。不要收成一张 umbrella。worker 拉独立镜像。`image.tag` 为空则用 `global.imageTag`。启动不做 migrate，用对应 API chart 的 Job。

本仓是 git 源。现网副本在 `/Users/cyxc/Projects/helm-chart/osspilot-*`（无 git，含真实密码）。改 chart 两份一起动：本仓只提交占位符；现网 `values-cyxc-club.yaml` 保留真实密钥，不要拷回本仓。
