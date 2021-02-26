# Containerized App

## 一站式容器化应用

- [x] 后端
- [x] 基于企业微信的网关认证
- [x] 前端

## 快速开始

### 准备

需要准备以下内容并修改 `docker-compose.yaml`

- 服务器开通 80 和 443 端口
- 域名证书
- 企业微信应用
  - CORP_ID
  - AGENT_ID
  - SECRET
  - 点击 企业微信授权登录 -> Web网页 设置授权回调域为使用的域名

### 启动

```bash
docker-compose up -d
```
