# osspilot-deploy

OssPilot 整栈编排。服务镜像各自在独立仓构建并推到 GHCR；本仓只拉镜像，不 `build` 兄弟仓源码。

对照冻结仓 [OssPilot](https://github.com/cyxc1124/OssPilot) 的 `legacy/deploy`，不要把编排再塞回对照仓。

## 本地联调

GHCR 容器包默认私有，先登录再拉：

```bash
docker login ghcr.io
cp compose/.env.example compose/.env
docker compose -f compose/docker-compose.yml --env-file compose/.env pull
docker compose -f compose/docker-compose.yml --env-file compose/.env up -d
```

默认端口：租户 API `8000`、运营 API `8001`、租户 web `8080`、运营 web `8081`。

运营种子账号 `admin` / `admin`（首次须改密）。租户没有种子用户，在运营端建账号并授权桶。

编排只注入库和 Redis。S3 / ONLYOFFICE / Ceph 管理地址在运营端系统设置填写。compose 带 mock `ceph-mgmt`（ops-api 镜像 `command: ceph-mgmt`）。worker 镜像另起 `tenant-scheduler` / `ops-scheduler`（同镜像 `command: scheduler`）。未配 S3 时栈仍能起来：登录可用，上传 503，worker 跳过对象任务。

镜像 tag 用 `IMAGE_TAG`（默认 `latest`，即各仓 `main` 尖端）。应用镜像 `linux/amd64` + `linux/arm64`，`pull_policy: always`，每次 up 拉最新 `latest`。要跟 `develop` 尖端用 `IMAGE_TAG=develop`。钉死版本用 `IMAGE_TAG=v1.2.1`。

改代码仍用各仓 `go run` / `npm run dev`；本 compose 用于联调已发布镜像。

## Helm

六个独立 chart，六个 release，对应六个服务仓。服务仓不放 chart。API chart 的 migrate 是 pre-install/pre-upgrade Job。`image.tag` 为空则用 `global.imageTag`。不内置 Postgres / Redis，不注入 S3 / ONLYOFFICE / Ceph 管理地址。

本仓只放占位符，禁止提交真实密码。现网是 `/Users/cyxc/Projects/helm-chart/osspilot-*`，密钥写在各目录的 `values-cyxc-club.yaml`。改模板时仓和现网一起维护。

```bash
helm lint helm/osspilot-tenant-api
helm upgrade --install osspilot-tenant-api helm/osspilot-tenant-api \
  -n osspilot --create-namespace -f helm/osspilot-tenant-api/values-local.yaml
# osspilot-tenant-worker / osspilot-ops-api / osspilot-ops-worker
# osspilot-tenant-web / osspilot-ops-web 同样
```

release 名即 Service 名（`osspilot-tenant-api:8000`）。只升一个服务：`--set image.tag=abc1234`。

生产覆盖可参考各 chart 的 `values-production.example.yaml`，复制为 `values-local.yaml` / `values-production.yaml`（已 gitignore）。

从旧的一张 `osspilot` umbrella 迁过来时先 `helm uninstall osspilot -n osspilot`，再装六个 release。

前置：集群里两套库（`osspilot_tenant` / `osspilot_ops`）和一套 Redis；把连接串写进 values。S3 / Ceph / ONLYOFFICE 上线后在运营端系统设置填写。

## 许可

AGPL-3.0-only
