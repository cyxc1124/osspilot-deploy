# osspilot-deploy

OssPilot 整栈编排。服务镜像各自在独立仓构建并推到 GHCR；本仓只拉镜像，不 `build` 兄弟仓源码。

对照冻结仓 [OssPilot](https://github.com/cyxc1124/OssPilot) 的 `legacy/deploy`，不要把编排再塞回对照仓。

## 本地联调

```bash
cp compose/.env.example compose/.env
docker compose -f compose/docker-compose.yml --env-file compose/.env up -d
```

默认端口：租户 API `8000`、运营 API `8001`、租户 web `8080`、运营 web `8081`。

镜像 tag 用 `IMAGE_TAG`（默认 `develop`），例如 `ghcr.io/cyxc1124/osspilot-tenant-api:develop`。

改代码仍用各仓 `go run` / `npm run dev`；本 compose 用于联调已发布镜像。

Ceph/RGW/ONLYOFFICE 外接，不打进本仓。

## Helm

一张 umbrella chart：两端 API / worker / web，migrate 是 pre-install/pre-upgrade Job。worker 拉独立镜像（`osspilot-tenant-worker` / `osspilot-ops-worker`），`global.imageTag` 仍统一 tag。不内置 Postgres / Redis，不注入 S3。

```bash
helm lint helm/osspilot
helm upgrade --install osspilot helm/osspilot -n osspilot --create-namespace \
  -f helm/osspilot/values-local.yaml
```

生产覆盖可参考 `helm/osspilot/values-production.example.yaml`，复制为 `values-local.yaml` / `values-production.yaml`（已 gitignore）。`global.imageTag` 统一各仓镜像 tag。

前置：集群里两套库（`osspilot_tenant` / `osspilot_ops`）和一套 Redis；把连接串写进 values。S3 / RGW 上线后在运营端系统设置填写。

## 许可

AGPL-3.0-only
