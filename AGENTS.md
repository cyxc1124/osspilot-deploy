# osspilot-deploy

整栈编排（compose + helm）。不放服务业务代码。

## 提交

`<type>: <中文说明>`，必须保留 type 前缀。

镜像只引用 `ghcr.io/cyxc1124/osspilot-*:tag`，不要在本仓 `build:` 四服务源码目录。

Helm 是一张 umbrella chart（`helm/osspilot`），不要拆回 Python 时代的一服务一 chart。worker 进对应 API 镜像。启动不做 migrate，用 Job。
