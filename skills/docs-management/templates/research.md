---
type: research
feature: <feature-slug or _general>
date: <YYYY-MM-DD>
status: in-progress | complete | superseded
branch: <branch-name>
superseded-by: <docs/feat/.../research-YYYYMMDD-slug.md or "N/A">
related:
  - docs/feat/<feature-slug>/TKT-NNN-xxx.md
---

# 研究報告：<主題>

**目的**：<這份調查要支撐哪個決定。例：在實作 TKT-002~005 之前，調查社群最佳實踐並評估兩項增強方案的技術可行性。>

**範圍**：<查了什麼、沒查什麼。明確寫出未涵蓋的部分，避免被當成完整結論引用。>

---

## 一、<主題區塊>

來源：<官方文件 / 原始碼 / 規格 / 第一方 API——一手來源，不引二手轉述>

**核心發現**：

- <一條主張，可追回上述來源>
- <一條主張>

### <子題>

<內容。每個小節都要能指回它的來源。>

---

## 二、方案評估

| 方案 | 做法 | 取捨 | 可行性 |
|------|------|------|--------|
| <A> | <> | <> | <> |
| <B> | <> | <> | <> |

## 結論與建議

<明確、可據以行動：建議採用 / 不採用 X，因為 Y。若無定論，寫明還缺什麼資訊才能決定。>

**後續**：<對應的 TKT-* / DESIGN.md 拍板記錄，並同步更新雙方 `related`>

## 未驗證項目

<無法直接驗證的論斷在此列出並標註原因——依 `rules/workflow.md` 的 Verify Before Assert。>
