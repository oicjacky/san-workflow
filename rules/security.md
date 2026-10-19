# Security

憑證處理與 tracked 檔案的衛生。深度安全審查走 `/security-review`，
這裡只放「不要做」的硬邊界。

## 機密處理
不讀取、檢視、echo 或傳輸實際的憑證與 secret 值；只以變數名稱或所在位置指涉。
secret 存在 `.env`，不 hardcode 進原始碼，也不放在指令列上——
**SSH 的指令列會被記錄下來**。憑證的設定與輸入由使用者本人做，agent 不代勞。

除了 `*.example` 範本，所有 `.env` 開頭或結尾的檔案（含 `.envrc`）都視為含 secret，不讀取。

## Tracked 檔案不放個人與基礎設施識別資訊
版控追蹤的檔案（文件、腳本、設定、測試）中不得出現：

- **原始內部 IP** —— 用符號化／邏輯名稱代替
- **個人 SSH hostname / username** —— 連線細節放 `~/.ssh/config`，
  程式碼只引用 host alias；ssh 指令也一律用 `~/.ssh/config` 的別名，不用完整主機名或 IP
- **個人絕對路徑**（`/Users/<name>/…`）—— commit 前檢查測試腳本與設定檔

## 客戶名稱不進版控
受版控的檔案、文件、commit message 與 MR 內文中不得出現客戶名稱，改用中性代稱。
可以自備一份不受版控的客戶名單，搭配 commit 前的檢查 hook 比對；
名單以外的名稱、commit message 與 MR 內文靠本規則自律。
