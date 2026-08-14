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

编排只注入库和 Redis。S3 / Ceph / ONLYOFFICE 在运营端系统设置填写，不写进 compose / Helm。未配时栈仍能起来：登录可用，上传 503，worker 跳过对象任务。

镜像 tag 用 `IMAGE_TAG`（默认 `develop`）。应用镜像 `linux/amd64` + `linux/arm64`，`pull_policy: always`，每次 up 拉最新 `develop`。

改代码仍用各仓 `go run` / `npm run dev`；本 compose 用于联调已发布镜像。

## Helm

一张 umbrella chart：两端 API / worker / web，migrate 是 pre-install/pre-upgrade Job。worker 拉独立镜像（`osspilot-tenant-worker` / `osspilot-ops-worker`），`global.imageTag` 仍统一 tag。不内置 Postgres / Redis，不注入 S3 / Ceph / ONLYOFFICE。

```bash
helm lint helm/osspilot
helm upgrade --install osspilot helm/osspilot -n osspilot --create-namespace \
  -f helm/osspilot/values-local.yaml
```

生产覆盖可参考 `helm/osspilot/values-production.example.yaml`，复制为 `values-local.yaml` / `values-production.yaml`（已 gitignore）。`global.imageTag` 统一各仓镜像 tag。

前置：集群里两套库（`osspilot_tenant` / `osspilot_ops`）和一套 Redis；把连接串写进 values。S3 / Ceph / ONLYOFFICE 上线后在运营端系统设置填写。

## 许可

AGPL-3.0-only
