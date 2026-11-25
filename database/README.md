# 数据库设计与使用说明 (`database/`)

## 1. 整体设计思路

本数据库面向《基于开放数据的零食标签结构化与查询系统（需求文档 V2.2）》，基于 **MySQL 8.0+（InnoDB 引擎、`utf8mb4` 字符集）**，在保留项目既有 7 张基础表（`biz_data_source` ~ `biz_label`）并统一遵循 `mysql-design` 命名规范（`biz_` / `sys_` 前缀、`id` 主键、`create_time` / `update_time` / `deleted`）的基础上，采用**“原始层 — 标准层 — 知识与解读层 — 系统管理层”**的分层架构：

1. **原始数据与结构化数据分离**：外部采集返回的原始 JSON 原样存入 `biz_raw_record`（通过 `(source_id, content_hash)` 去重并保留来源 URL 与抓取时间），不直接覆盖或篡改；清洗、去重和标准化后的数据写入标准层表，并通过 `biz_product_source` 和 `biz_label.raw_id` 建立完整的来源追溯链路。
2. **多源去重与版本留存**：`biz_product` 以条码 `barcode`（GTIN）作为唯一去重标识；同一产品的多个来源标签分别保留在 `biz_label` 中，通过 `is_adopted` 标记当前采用展示版本，支持冲突保留与来源回溯。
3. **营养成分数值化存储**：不将营养信息简单堆入 JSON 字段，而是拆出 `biz_label_nutrition` 表，统一换算为每 `100g` / `100mL` 基准，采用高精度 `DECIMAL` 类型分别存储能量、蛋白质、脂肪、碳水、糖和钠等字段；未标注字段保留 `NULL`，直接支撑前台“控糖 / 控钠”阈值筛选以及“信息不足”三态判定。
4. **产品与配料多对多及嵌套树解析**：通过 `biz_ingredient`（标准配料基础表）、`biz_ingredient_alias`（别名/英文名/INS 编码映射词典）、`biz_additive`（添加剂科普知识库）与 `biz_product_ingredient`（关联明细表）处理产品与配料的多对多关系；利用 `parent_id` 自关联与 `position_no` 保留复合配料括号嵌套层级与配料递减顺序，并以 `map_status = 'PENDING'` 支撑待人工确认队列。
5. **客观信息呈现，不做违法定性**：`biz_user_rule` 仅表达用户个人关注的过敏原和营养阈值（支持多版本共存）；`biz_interpret_result` 区分 `FACT`（客观事实）、`KNOWLEDGE`（知识科普）、`PERSONAL_TIP`（个人提示）三级内容和 `FIT / UNFIT / INSUFFICIENT_INFO` 状态；`biz_inspection_record` 仅客观转引官方抽检公告样本，**没有抽检依据的产品不会被判定为违法或不合规**。

---

## 2. 数据表与视图清单（共 19 张表 + 3 个视图）

| 分层 | 表名 | 中文含义 | 主要用途 |
|---|---|---|---|
| **原始层** | `biz_data_source` | 开放数据源 | 登记数据源地址、访问方式、可信度等级、授权说明与启停状态 |
| | `biz_crawl_task` | 数据采集任务 | 记录关键词、参数快照、请求/成功/失败/入库统计与断点摘要 |
| | `biz_raw_record` | 不可变原始采集记录 | 原样留存原始 JSON、来源 URL、HTTP 状态与 SHA-256 摘要 |
| **标准层** | `biz_brand` | 产品品牌 | 存储规范化品牌名称与生产企业 |
| | `biz_category` | 零食品类层级 | 维护多级零食分类树及 GB 2760 食品分类编码 |
| | `biz_product` | 去重后的标准产品 | 存储按条码去重后的标准产品基础信息（名称、品牌、品类、净含量等） |
| | `biz_product_source` | 产品-原始记录关联表 | 关联 `biz_product` 与 `biz_raw_record`，记录匹配方式与置信度 |
| | `biz_label` | 按来源留存的标签版本 | 保留各来源配料表原文、致敏原标注状态、`is_adopted` 采用标志 |
| | `biz_label_nutrition` | 标签结构化营养成分表 | 按每 100g/100mL 存储能量、蛋白质、脂肪、碳水、糖、钠等数值 |
| **配料与知识层** | `biz_additive` | 食品添加剂知识库 | 存储添加剂 INS/CNS 编码、功能类别、常见用途及客观科普说明 |
| | `biz_ingredient` | 标准配料基础信息表 | 维护标准配料词典、关联添加剂 ID 及致敏原标准类别 |
| | `biz_ingredient_alias` | 配料别名映射词典 | 维护俗名、英文名、INS/CNS 编码到标准配料的映射 |
| | `biz_product_ingredient` | 产品标签-配料明细表 | 实现产品与配料多对多关联，维护顺序号、嵌套父子关系、含量百分比及待确认状态 |
| **规则与结果层** | `biz_user_rule` | 用户个人关注规则表 | 表驱动、版本化管理过敏原名单与营养阈值规则 |
| | `biz_interpret_run` | 成分解读执行批次 | 记录每次成分解读的执行范围、规则版本与汇总计数 |
| | `biz_interpret_result` | 成分解读与个人提示结果 | 按客观事实/知识科普/个人提示三级留存命中依据与三态结果 |
| | `biz_inspection_record` | 监管抽检公告验证样本 | 关联原始公告记录，客观留存抽检项目、检出值与公告原载结论 |
| **系统管理** | `sys_user` | 系统后台用户表 | 维护管理员、数据维护员、只读分析员账号信息 |
| | `sys_operation_log` | 后台操作审计日志 | 记录采集、导入、解读等后台关键操作审计记录 |
| **查询视图** | `v_product_adopted_overview` | 采用版产品与营养概览视图 | 聚合当前采用版标签、来源 URL 与营养数值，用于检索、对比与筛选 |
| | `v_product_ingredient_detail` | 产品配料与添加剂关联视图 | 展开当前采用版配料明细、标准名、致敏原及添加剂科普说明 |
| | `v_additive_usage_stats` | 添加剂使用频次统计视图 | 统计各添加剂在当前采用版产品中的覆盖产品数 |

---

## 3. 重要关联关系

- **数据溯源链路**：`biz_data_source (1) ─ (N) biz_crawl_task (1) ─ (N) biz_raw_record`；`biz_product (M) ─ (N) biz_raw_record` 通过 `biz_product_source` 关联，同时 `biz_label.raw_id` 直接指向对应的 `biz_raw_record`。
- **产品与标签/营养**：`biz_brand`、`biz_category` 分别为 `biz_product` 的多对一外键；`biz_product (1) ─ (N) biz_label` 留存多来源/多版本标签；`biz_label (1) ─ (0..1) biz_label_nutrition` 存放结构化营养成分。
- **产品与配料多对多**：`biz_product / biz_label` 与 `biz_ingredient` 通过 `biz_product_ingredient` 建立多对多联系；`biz_product_ingredient.parent_id` 自关联表达复合配料括号嵌套；`biz_ingredient` 多对一关联 `biz_additive`，一对多关联 `biz_ingredient_alias`。
- **规则驱动解读**：`biz_interpret_run (1) ─ (N) biz_interpret_result`，每条结果可追溯至 `biz_product`、`biz_label`、`biz_user_rule`（含 `rule_version`）或 `biz_additive`。

---

## 4. SQL 文件说明与执行顺序

```text
database/
├── schema.sql      # 1. 创建数据库 snack_ingredient_screening、19 张表、约束索引与 3 个视图
├── init_data.sql   # 2. 初始化数据源、零食品类、添加剂知识库、配料与别名词典、v1.0关注规则、系统角色
├── test_data.sql   # 3. 写入采集任务、原始JSON、6款示例零食、嵌套配料树、营养数值、解读结果与抽检样本
└── README.md       # 数据库设计说明与使用指南
```

**执行顺序**（必须严格按以下顺序执行）：
1. `schema.sql`
2. `init_data.sql`
3. `test_data.sql`

---

## 5. 数据库初始化方法

在 MySQL 8.0+ 命令行客户端中执行（建议在独立测试库中运行）：

```bash
mysql -u <用户名> -p --default-character-set=utf8mb4 < database/schema.sql
mysql -u <用户名> -p --default-character-set=utf8mb4 < database/init_data.sql
mysql -u <用户名> -p --default-character-set=utf8mb4 < database/test_data.sql
```

或在 MySQL 交互终端内依次执行：

```sql
SOURCE database/schema.sql;
SOURCE database/init_data.sql;
SOURCE database/test_data.sql;
```

### 核心业务查询验证示例

```sql
-- 1. 产品条码/名称及营养概览查询
SELECT product_name, barcode, brand_name, category_name, sodium_mg, sugar_g, source_url
FROM v_product_adopted_overview
WHERE barcode = '7622210449283';

-- 2. 按添加剂反向检索含该成分的产品 (如查含 TBHQ 的产品)
SELECT DISTINCT product_name, barcode, raw_name, additive_name, ins_no
FROM v_product_ingredient_detail
WHERE additive_name = '特丁基对苯二酚';

-- 3. 前台三态筛选演示：无麸质谷物 + 钠 <= 600mg/100g + 糖 <= 25g/100g
SELECT
  product_name,
  CASE
    WHEN allergen_labeled = 0 OR sodium_mg IS NULL OR sugar_g IS NULL THEN 'INSUFFICIENT_INFO'
    WHEN EXISTS (
      SELECT 1 FROM v_product_ingredient_detail d
      WHERE d.product_id = v.product_id AND d.allergen_type = '麸质谷物'
    ) OR sodium_mg > 600 OR sugar_g > 25 THEN 'UNFIT'
    ELSE 'FIT'
  END AS filter_state,
  allergen_labeled, sodium_mg, sugar_g
FROM v_product_adopted_overview v;

-- 4. 两款产品横向对比 (如产品 1 与产品 3)
SELECT product_name, brand_name, energy_kcal, fat_g, carbs_g, sugar_g, sodium_mg, ingredient_text
FROM v_product_adopted_overview
WHERE product_id IN (1, 3);
```
