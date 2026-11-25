-- ============================================================================
-- 基于开放数据的零食标签结构化与查询系统 —— 数据库建表脚本 (MySQL 8.0+)
-- 存储引擎: InnoDB | 字符集: utf8mb4 | 排序规则: utf8mb4_unicode_ci
-- 说明: 保留既有 7 张基础业务表 (biz_data_source ~ biz_label)，
--       按《需求文档 V2.2》与 mysql-design 规范补全剩余 12 张表、索引及视图。
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `snack_ingredient_screening`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `snack_ingredient_screening`;

-- ============================================================================
-- 一、数据源与采集层 (原始层)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `biz_data_source` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `source_name` VARCHAR(100) NOT NULL COMMENT '数据源名称',
  `source_type` VARCHAR(30) NOT NULL COMMENT '数据源类型(开放库/官方公告/网页)',
  `base_url` VARCHAR(500) NOT NULL COMMENT '数据源地址',
  `access_method` VARCHAR(30) NOT NULL COMMENT '访问方式(API/附件解析/人工摘录)',
  `reliability_level` TINYINT UNSIGNED DEFAULT NULL COMMENT '来源可信度等级(1-5)',
  `terms_note` VARCHAR(500) DEFAULT NULL COMMENT '授权及使用说明',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态(0停用 1启用)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_source_name` (`source_name`),
  KEY `idx_source_status` (`status`),
  CONSTRAINT `chk_source_reliability` CHECK (`reliability_level` IS NULL OR (`reliability_level` BETWEEN 1 AND 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='开放数据源';

CREATE TABLE IF NOT EXISTS `biz_crawl_task` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `source_id` BIGINT UNSIGNED NOT NULL COMMENT '数据源ID',
  `keyword` VARCHAR(200) NOT NULL COMMENT '采集关键词/品类',
  `request_config` JSON DEFAULT NULL COMMENT '请求参数快照(分页/字段白名单/限速/重试配置)',
  `status` VARCHAR(20) NOT NULL COMMENT '任务状态(PENDING/RUNNING/SUCCESS/FAILED/PARTIAL)',
  `request_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '请求数',
  `success_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '成功数',
  `fail_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '失败数',
  `insert_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '新增/关联原始记录数',
  `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
  `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
  `error_msg` TEXT COMMENT '错误摘要',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  KEY `idx_source_status` (`source_id`, `status`),
  KEY `idx_task_start_time` (`start_time`),
  CONSTRAINT `fk_task_source` FOREIGN KEY (`source_id`) REFERENCES `biz_data_source` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据采集任务及运行统计';

CREATE TABLE IF NOT EXISTS `biz_raw_record` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '采集任务ID',
  `source_id` BIGINT UNSIGNED NOT NULL COMMENT '数据源ID',
  `source_url` VARCHAR(1000) NOT NULL COMMENT '原始记录来源URL',
  `source_record_key` VARCHAR(150) DEFAULT NULL COMMENT '来源侧记录标识',
  `http_status` SMALLINT UNSIGNED DEFAULT NULL COMMENT 'HTTP状态码',
  `crawl_status` VARCHAR(20) NOT NULL COMMENT '采集状态(SUCCESS/FAILED/RETRYING)',
  `raw_content` JSON DEFAULT NULL COMMENT '原始响应内容',
  `content_hash` CHAR(64) NOT NULL COMMENT '内容SHA-256摘要(用于去重与变更识别)',
  `fetched_at` DATETIME NOT NULL COMMENT '采集时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_source_hash` (`source_id`, `content_hash`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_source_record_key` (`source_id`, `source_record_key`),
  KEY `idx_fetched_at` (`fetched_at`),
  CONSTRAINT `fk_raw_task` FOREIGN KEY (`task_id`) REFERENCES `biz_crawl_task` (`id`),
  CONSTRAINT `fk_raw_source` FOREIGN KEY (`source_id`) REFERENCES `biz_data_source` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='不可变原始采集记录';

-- ============================================================================
-- 二、产品、标签与营养结构化层 (标准层)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `biz_brand` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `brand_name` VARCHAR(100) NOT NULL COMMENT '品牌名称',
  `manufacturer` VARCHAR(200) DEFAULT NULL COMMENT '生产企业',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_name` (`brand_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品品牌';

CREATE TABLE IF NOT EXISTS `biz_category` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_name` VARCHAR(100) NOT NULL COMMENT '品类名称',
  `parent_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '父品类ID',
  `gb2760_code` VARCHAR(20) DEFAULT NULL COMMENT '食品分类编号(GB 2760)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_name_parent` (`category_name`, `parent_id`),
  KEY `idx_parent_id` (`parent_id`),
  CONSTRAINT `fk_category_parent` FOREIGN KEY (`parent_id`) REFERENCES `biz_category` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='零食品类层级';

CREATE TABLE IF NOT EXISTS `biz_product` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `barcode` VARCHAR(20) DEFAULT NULL COMMENT '产品条码GTIN',
  `product_name` VARCHAR(200) NOT NULL COMMENT '产品名称',
  `brand_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '品牌ID',
  `category_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '品类ID',
  `net_content` VARCHAR(50) DEFAULT NULL COMMENT '净含量标示',
  `standard_no` VARCHAR(50) DEFAULT NULL COMMENT '产品执行标准号',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_product_barcode` (`barcode`),
  KEY `idx_product_name` (`product_name`),
  KEY `idx_brand_category` (`brand_id`, `category_id`),
  KEY `idx_category_id` (`category_id`),
  CONSTRAINT `fk_product_brand` FOREIGN KEY (`brand_id`) REFERENCES `biz_brand` (`id`),
  CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `biz_category` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='去重后的标准产品';

CREATE TABLE IF NOT EXISTS `biz_product_source` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '标准产品ID',
  `raw_id` BIGINT UNSIGNED NOT NULL COMMENT '原始采集记录ID',
  `source_id` BIGINT UNSIGNED NOT NULL COMMENT '数据源ID',
  `source_product_key` VARCHAR(150) DEFAULT NULL COMMENT '来源侧产品唯一标识(如条码或网页ID)',
  `match_method` VARCHAR(30) NOT NULL COMMENT '归并匹配方式(BARCODE_EXACT/NAME_SIMILARITY/MANUAL)',
  `match_confidence` DECIMAL(5,4) DEFAULT NULL COMMENT '匹配置信度(0.0000-1.0000)',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否为主参考来源(0否 1是)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_product_raw` (`product_id`, `raw_id`),
  KEY `idx_ps_raw_id` (`raw_id`),
  KEY `idx_ps_source_key` (`source_id`, `source_product_key`),
  CONSTRAINT `fk_ps_product` FOREIGN KEY (`product_id`) REFERENCES `biz_product` (`id`),
  CONSTRAINT `fk_ps_raw` FOREIGN KEY (`raw_id`) REFERENCES `biz_raw_record` (`id`),
  CONSTRAINT `fk_ps_source` FOREIGN KEY (`source_id`) REFERENCES `biz_data_source` (`id`),
  CONSTRAINT `chk_ps_confidence` CHECK (`match_confidence` IS NULL OR (`match_confidence` >= 0.0000 AND `match_confidence` <= 1.0000))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标准产品与原始采集记录关联表';

CREATE TABLE IF NOT EXISTS `biz_label` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '标准产品ID',
  `source_id` BIGINT UNSIGNED NOT NULL COMMENT '数据源ID',
  `raw_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '来源原始记录ID',
  `ingredient_text` TEXT COMMENT '配料表原文',
  `allergen_text` TEXT COMMENT '致敏原标注原文',
  `allergen_labeled` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '致敏原是否明确标注(0未标注 1已标注)',
  `label_completeness` VARCHAR(30) DEFAULT NULL COMMENT '标签完整性标记(COMPLETE/MISSING_INGREDIENT/MISSING_NUTRITION/PARTIAL)',
  `source_updated_at` DATETIME DEFAULT NULL COMMENT '来源更新时间',
  `is_adopted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否作为当前展示版本(0历史/备选 1当前采用)',
  `captured_at` DATETIME NOT NULL COMMENT '采集时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  KEY `idx_label_product_adopted` (`product_id`, `is_adopted`),
  KEY `idx_label_source` (`source_id`),
  KEY `idx_label_raw` (`raw_id`),
  CONSTRAINT `fk_label_product` FOREIGN KEY (`product_id`) REFERENCES `biz_product` (`id`),
  CONSTRAINT `fk_label_source` FOREIGN KEY (`source_id`) REFERENCES `biz_data_source` (`id`),
  CONSTRAINT `fk_label_raw` FOREIGN KEY (`raw_id`) REFERENCES `biz_raw_record` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='按来源留存的标签版本';

CREATE TABLE IF NOT EXISTS `biz_label_nutrition` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `label_id` BIGINT UNSIGNED NOT NULL COMMENT '标签版本ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '标准产品ID(冗余外键以加速单品与筛选查询)',
  `basis_type` VARCHAR(20) NOT NULL DEFAULT 'per_100g' COMMENT '营养换算基准(per_100g/per_100ml)',
  `serving_size` VARCHAR(50) DEFAULT NULL COMMENT '标签原始每份规格(如30g/份)',
  `energy_kj` DECIMAL(8,2) DEFAULT NULL COMMENT '能量(kJ/100g或100mL)',
  `energy_kcal` DECIMAL(8,2) DEFAULT NULL COMMENT '能量(kcal/100g或100mL)',
  `protein_g` DECIMAL(8,3) DEFAULT NULL COMMENT '蛋白质(g/100g或100mL)',
  `fat_g` DECIMAL(8,3) DEFAULT NULL COMMENT '脂肪(g/100g或100mL)',
  `saturated_fat_g` DECIMAL(8,3) DEFAULT NULL COMMENT '饱和脂肪(g/100g或100mL)',
  `trans_fat_g` DECIMAL(8,3) DEFAULT NULL COMMENT '反式脂肪(g/100g或100mL)',
  `carbs_g` DECIMAL(8,3) DEFAULT NULL COMMENT '碳水化合物(g/100g或100mL)',
  `sugar_g` DECIMAL(8,3) DEFAULT NULL COMMENT '糖(g/100g或100mL，NULL表示未标注)',
  `dietary_fiber_g` DECIMAL(8,3) DEFAULT NULL COMMENT '膳食纤维(g/100g或100mL)',
  `sodium_mg` DECIMAL(10,3) DEFAULT NULL COMMENT '钠(mg/100g或100mL，NULL表示未标注)',
  `nutrition_complete` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '核心营养字段是否完整(0缺失 1完整)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_nutrition_label` (`label_id`),
  KEY `idx_nutrition_product` (`product_id`),
  KEY `idx_nutrition_sodium_sugar` (`sodium_mg`, `sugar_g`),
  CONSTRAINT `fk_nutrition_label` FOREIGN KEY (`label_id`) REFERENCES `biz_label` (`id`),
  CONSTRAINT `fk_nutrition_product` FOREIGN KEY (`product_id`) REFERENCES `biz_product` (`id`),
  CONSTRAINT `chk_nutrition_non_negative` CHECK (
    (`energy_kj` IS NULL OR `energy_kj` >= 0) AND
    (`energy_kcal` IS NULL OR `energy_kcal` >= 0) AND
    (`protein_g` IS NULL OR `protein_g` >= 0) AND
    (`fat_g` IS NULL OR `fat_g` >= 0) AND
    (`carbs_g` IS NULL OR `carbs_g` >= 0) AND
    (`sugar_g` IS NULL OR `sugar_g` >= 0) AND
    (`sodium_mg` IS NULL OR `sodium_mg` >= 0)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签结构化营养成分表(统一每100g/100mL数值)';

-- ============================================================================
-- 三、配料词典、添加剂知识库与产品-配料多对多关系层
-- ============================================================================

CREATE TABLE IF NOT EXISTS `biz_additive` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `additive_name` VARCHAR(100) NOT NULL COMMENT '添加剂标准名称',
  `ins_no` VARCHAR(20) DEFAULT NULL COMMENT '国际编码(INS)',
  `cns_no` VARCHAR(20) DEFAULT NULL COMMENT '中国编码(CNS)',
  `function_class` VARCHAR(50) NOT NULL COMMENT '功能类别(防腐剂/着色剂/甜味剂/抗氧化剂/乳化剂等)',
  `common_uses` VARCHAR(300) DEFAULT NULL COMMENT '常见食品用途',
  `knowledge_text` TEXT NOT NULL COMMENT '客观科普说明(仅作知识科普，不作合规判定)',
  `knowledge_source` VARCHAR(200) DEFAULT NULL COMMENT '科普内容来源说明',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_additive_name` (`additive_name`),
  KEY `idx_additive_ins` (`ins_no`),
  KEY `idx_additive_cns` (`cns_no`),
  KEY `idx_additive_fn` (`function_class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='食品添加剂知识库';

CREATE TABLE IF NOT EXISTS `biz_ingredient` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `std_name` VARCHAR(100) NOT NULL COMMENT '配料标准名称',
  `ingredient_type` VARCHAR(30) NOT NULL COMMENT '配料分类(主料/辅料/香辛料/食品添加剂/复合配料)',
  `additive_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '关联添加剂知识ID(仅食品添加剂填值)',
  `is_allergen` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否属常见致敏物质(0否 1是)',
  `allergen_type` VARCHAR(50) DEFAULT NULL COMMENT '致敏原标准类别(花生/麸质谷物/乳/大豆/坚果/蛋等)',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '配料基础说明',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ingredient_std_name` (`std_name`),
  KEY `idx_ingredient_additive` (`additive_id`),
  KEY `idx_ingredient_allergen` (`is_allergen`, `allergen_type`),
  CONSTRAINT `fk_ingredient_additive` FOREIGN KEY (`additive_id`) REFERENCES `biz_additive` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标准配料基础信息表';

CREATE TABLE IF NOT EXISTS `biz_ingredient_alias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `ingredient_id` BIGINT UNSIGNED NOT NULL COMMENT '标准配料ID',
  `alias_name` VARCHAR(100) NOT NULL COMMENT '配料别名/俗称/英文名/编码写法',
  `alias_type` VARCHAR(30) NOT NULL DEFAULT 'SYNONYM' COMMENT '别名类型(SYNONYM/ENGLISH/INS/CNS/ABBR)',
  `source_note` VARCHAR(200) DEFAULT NULL COMMENT '词条来源或人工确认备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_alias_name` (`alias_name`),
  KEY `idx_alias_ingredient` (`ingredient_id`),
  CONSTRAINT `fk_alias_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `biz_ingredient` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='配料别名映射词典';

CREATE TABLE IF NOT EXISTS `biz_product_ingredient` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '标准产品ID',
  `label_id` BIGINT UNSIGNED NOT NULL COMMENT '标签版本ID',
  `ingredient_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '标准配料ID(未映射成功时为NULL)',
  `parent_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '父级配料明细ID(用于复合配料括号嵌套层级)',
  `raw_name` VARCHAR(200) NOT NULL COMMENT '标签配料原文片段',
  `position_no` INT UNSIGNED NOT NULL COMMENT '配料表前序展开顺序号(从1开始，保留递减顺序)',
  `depth_level` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '括号嵌套深度(1为顶层配料)',
  `declared_percent` DECIMAL(5,2) DEFAULT NULL COMMENT '标签标示含量百分比(0.00-100.00)',
  `declared_relation` VARCHAR(10) DEFAULT NULL COMMENT '含量比较符号(=/>=/<=)',
  `declared_form` VARCHAR(100) DEFAULT NULL COMMENT '标示形态/类别前缀(如防腐剂/甜味剂)',
  `map_status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '映射状态(MAPPED/PENDING/UNRECOGNIZED)',
  `map_confidence` DECIMAL(5,4) DEFAULT NULL COMMENT '名称映射置信度(0.0000-1.0000)',
  `parser_version` VARCHAR(30) DEFAULT NULL COMMENT '解析器及词典版本号',
  `fail_reason` VARCHAR(200) DEFAULT NULL COMMENT '未映射或解析异常原因',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_label_position` (`label_id`, `position_no`),
  KEY `idx_pi_product_pos` (`product_id`, `position_no`),
  KEY `idx_pi_ingredient` (`ingredient_id`),
  KEY `idx_pi_parent` (`parent_id`),
  KEY `idx_pi_map_status` (`map_status`),
  CONSTRAINT `fk_pi_product` FOREIGN KEY (`product_id`) REFERENCES `biz_product` (`id`),
  CONSTRAINT `fk_pi_label` FOREIGN KEY (`label_id`) REFERENCES `biz_label` (`id`),
  CONSTRAINT `fk_pi_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `biz_ingredient` (`id`),
  CONSTRAINT `fk_pi_parent` FOREIGN KEY (`parent_id`) REFERENCES `biz_product_ingredient` (`id`),
  CONSTRAINT `chk_pi_percent` CHECK (`declared_percent` IS NULL OR (`declared_percent` >= 0.00 AND `declared_percent` <= 100.00))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品标签-配料多对多关联及嵌套解析明细';

-- ============================================================================
-- 四、用户关注规则、成分解读结果与抽检验证层
-- ============================================================================

CREATE TABLE IF NOT EXISTS `biz_user_rule` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `rule_code` VARCHAR(50) NOT NULL COMMENT '规则编码(同类规则跨版本保持一致)',
  `rule_type` VARCHAR(20) NOT NULL COMMENT '规则类型(ALLERGEN/NUTRITION)',
  `rule_name` VARCHAR(100) NOT NULL COMMENT '关注项名称(如花生/钠/糖)',
  `target_allergen` VARCHAR(50) DEFAULT NULL COMMENT '匹配的致敏原标准类别',
  `nutrient_field` VARCHAR(30) DEFAULT NULL COMMENT '匹配的营养字段名(如sodium_mg/sugar_g)',
  `compare_op` VARCHAR(10) DEFAULT NULL COMMENT '比较操作符(>/<=等)',
  `threshold_value` DECIMAL(10,3) DEFAULT NULL COMMENT '个人关注阈值',
  `threshold_unit` VARCHAR(20) DEFAULT NULL COMMENT '阈值单位(mg/100g, g/100g)',
  `rule_version` VARCHAR(20) NOT NULL COMMENT '规则版本号(新增版本而非覆盖历史)',
  `hint_level` VARCHAR(20) NOT NULL DEFAULT 'PERSONAL_TIP' COMMENT '提示级别(PERSONAL_TIP，非违法判定)',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '规则触发说明',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用(0停用 1启用)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rule_code_version` (`rule_code`, `rule_version`),
  KEY `idx_rule_type_active` (`rule_type`, `is_active`),
  KEY `idx_rule_version` (`rule_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户个人关注规则表(表驱动、版本化)';

CREATE TABLE IF NOT EXISTS `biz_interpret_run` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `run_time` DATETIME NOT NULL COMMENT '批次执行时间',
  `scope_type` VARCHAR(20) NOT NULL COMMENT '解读范围类型(ALL/CATEGORY/PRODUCT/INCREMENTAL)',
  `scope_desc` VARCHAR(200) NOT NULL COMMENT '解读范围描述',
  `rule_version` VARCHAR(20) NOT NULL COMMENT '本批次使用的规则版本号',
  `total_products` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '涉及产品总数',
  `hit_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '生成解读/提示条数',
  `status` VARCHAR(20) NOT NULL DEFAULT 'SUCCESS' COMMENT '批次状态(RUNNING/SUCCESS/FAILED)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  KEY `idx_run_time` (`run_time`),
  KEY `idx_run_version` (`rule_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='成分解读执行批次';

CREATE TABLE IF NOT EXISTS `biz_interpret_result` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `run_id` BIGINT UNSIGNED NOT NULL COMMENT '解读批次ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '标准产品ID',
  `label_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '依据的标签版本ID',
  `rule_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '命中的用户关注规则ID',
  `additive_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '关联的添加剂知识ID',
  `info_type` VARCHAR(20) NOT NULL COMMENT '信息分级(FACT客观事实/KNOWLEDGE知识科普/PERSONAL_TIP个人提示)',
  `conclusion_state` VARCHAR(20) NOT NULL DEFAULT 'INFO_ONLY' COMMENT '客观状态(FIT适合/UNFIT不适合/INSUFFICIENT_INFO信息不足/INFO_ONLY仅信息展示)',
  `evidence_text` TEXT NOT NULL COMMENT '原文依据或科普说明',
  `rule_version` VARCHAR(20) DEFAULT NULL COMMENT '生成时所用规则版本',
  `generated_at` DATETIME NOT NULL COMMENT '结果生成时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  KEY `idx_ir_run_type` (`run_id`, `info_type`),
  KEY `idx_ir_product` (`product_id`),
  KEY `idx_ir_rule` (`rule_id`),
  KEY `idx_ir_additive` (`additive_id`),
  CONSTRAINT `fk_ir_run` FOREIGN KEY (`run_id`) REFERENCES `biz_interpret_run` (`id`),
  CONSTRAINT `fk_ir_product` FOREIGN KEY (`product_id`) REFERENCES `biz_product` (`id`),
  CONSTRAINT `fk_ir_label` FOREIGN KEY (`label_id`) REFERENCES `biz_label` (`id`),
  CONSTRAINT `fk_ir_rule` FOREIGN KEY (`rule_id`) REFERENCES `biz_user_rule` (`id`),
  CONSTRAINT `fk_ir_additive` FOREIGN KEY (`additive_id`) REFERENCES `biz_additive` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='成分解读与个性化提示结果(禁止违法定性)';

CREATE TABLE IF NOT EXISTS `biz_inspection_record` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `raw_id` BIGINT UNSIGNED NOT NULL COMMENT '关联原始公告记录ID',
  `product_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '匹配的标准产品ID(未匹配到则为NULL)',
  `announced_product_name` VARCHAR(200) NOT NULL COMMENT '公告原文标示产品名称',
  `item_name` VARCHAR(100) NOT NULL COMMENT '抽检检验项目',
  `detected_value` VARCHAR(100) DEFAULT NULL COMMENT '公告载明检出值',
  `standard_limit` VARCHAR(100) DEFAULT NULL COMMENT '公告载明标准限值',
  `notice_conclusion` VARCHAR(30) DEFAULT NULL COMMENT '官方公告原载结论(仅客观转引，不自行推论)',
  `notice_title` VARCHAR(300) DEFAULT NULL COMMENT '监管抽检通告标题',
  `notice_date` DATE DEFAULT NULL COMMENT '通告发布日期',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  KEY `idx_insp_raw` (`raw_id`),
  KEY `idx_insp_product` (`product_id`),
  KEY `idx_insp_date` (`notice_date`),
  CONSTRAINT `fk_insp_raw` FOREIGN KEY (`raw_id`) REFERENCES `biz_raw_record` (`id`),
  CONSTRAINT `fk_insp_product` FOREIGN KEY (`product_id`) REFERENCES `biz_product` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监管抽检公告验证样本(无抽检记录不代表不合规)';

-- ============================================================================
-- 五、系统管理与操作审计层
-- ============================================================================

CREATE TABLE IF NOT EXISTS `sys_user` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` VARCHAR(50) NOT NULL COMMENT '登录账号',
  `password_hash` VARCHAR(100) NOT NULL COMMENT '密码哈希值(不存明文)',
  `nickname` VARCHAR(50) NOT NULL COMMENT '显示名称',
  `role_code` VARCHAR(30) NOT NULL COMMENT '角色编码(ADMIN管理员/DATA_OPS数据维护员/ANALYST只读分析员)',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '账号状态(0禁用 1正常)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_username` (`username`),
  KEY `idx_sys_user_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统后台用户表';

CREATE TABLE IF NOT EXISTS `sys_operation_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '操作人ID',
  `action` VARCHAR(100) NOT NULL COMMENT '操作动作描述',
  `target_table` VARCHAR(64) DEFAULT NULL COMMENT '关联目标表名',
  `target_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '关联目标记录ID',
  `detail` VARCHAR(500) DEFAULT NULL COMMENT '操作详情摘要',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '删除标志(0未删除 1已删除)',
  PRIMARY KEY (`id`),
  KEY `idx_log_user_time` (`user_id`, `create_time`),
  KEY `idx_log_target` (`target_table`, `target_id`),
  CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='后台操作审计日志';

-- ============================================================================
-- 六、核心业务查询视图
-- ============================================================================

CREATE OR REPLACE VIEW `v_product_adopted_overview` AS
SELECT
  p.`id` AS `product_id`,
  p.`barcode`,
  p.`product_name`,
  b.`brand_name`,
  c.`category_name`,
  c.`gb2760_code`,
  p.`net_content`,
  l.`id` AS `label_id`,
  ds.`source_name`,
  rr.`source_url`,
  l.`ingredient_text`,
  l.`allergen_text`,
  l.`allergen_labeled`,
  l.`label_completeness`,
  l.`captured_at`,
  n.`basis_type`,
  n.`energy_kcal`,
  n.`protein_g`,
  n.`fat_g`,
  n.`carbs_g`,
  n.`sugar_g`,
  n.`sodium_mg`,
  n.`nutrition_complete`
FROM `biz_product` p
LEFT JOIN `biz_brand` b ON p.`brand_id` = b.`id` AND b.`deleted` = 0
LEFT JOIN `biz_category` c ON p.`category_id` = c.`id` AND c.`deleted` = 0
LEFT JOIN `biz_label` l ON l.`product_id` = p.`id` AND l.`is_adopted` = 1 AND l.`deleted` = 0
LEFT JOIN `biz_data_source` ds ON l.`source_id` = ds.`id` AND ds.`deleted` = 0
LEFT JOIN `biz_raw_record` rr ON l.`raw_id` = rr.`id` AND rr.`deleted` = 0
LEFT JOIN `biz_label_nutrition` n ON n.`label_id` = l.`id` AND n.`deleted` = 0
WHERE p.`deleted` = 0;

CREATE OR REPLACE VIEW `v_product_ingredient_detail` AS
SELECT
  p.`id` AS `product_id`,
  p.`barcode`,
  p.`product_name`,
  pi.`label_id`,
  pi.`id` AS `pi_id`,
  pi.`parent_id`,
  pi.`position_no`,
  pi.`depth_level`,
  pi.`raw_name`,
  pi.`declared_percent`,
  pi.`declared_relation`,
  pi.`declared_form`,
  pi.`map_status`,
  ing.`id` AS `ingredient_id`,
  ing.`std_name`,
  ing.`ingredient_type`,
  ing.`is_allergen`,
  ing.`allergen_type`,
  a.`id` AS `additive_id`,
  a.`additive_name`,
  a.`ins_no`,
  a.`cns_no`,
  a.`function_class`,
  a.`knowledge_text`
FROM `biz_product_ingredient` pi
INNER JOIN `biz_product` p ON pi.`product_id` = p.`id` AND p.`deleted` = 0
INNER JOIN `biz_label` l ON pi.`label_id` = l.`id` AND l.`is_adopted` = 1 AND l.`deleted` = 0
LEFT JOIN `biz_ingredient` ing ON pi.`ingredient_id` = ing.`id` AND ing.`deleted` = 0
LEFT JOIN `biz_additive` a ON ing.`additive_id` = a.`id` AND a.`deleted` = 0
WHERE pi.`deleted` = 0;

CREATE OR REPLACE VIEW `v_additive_usage_stats` AS
SELECT
  a.`id` AS `additive_id`,
  a.`additive_name`,
  a.`ins_no`,
  a.`cns_no`,
  a.`function_class`,
  COUNT(DISTINCT CASE WHEN l.`id` IS NOT NULL THEN pi.`product_id` END) AS `product_count`
FROM `biz_additive` a
LEFT JOIN `biz_ingredient` ing ON ing.`additive_id` = a.`id` AND ing.`deleted` = 0
LEFT JOIN `biz_product_ingredient` pi ON pi.`ingredient_id` = ing.`id` AND pi.`deleted` = 0
LEFT JOIN `biz_label` l ON pi.`label_id` = l.`id` AND l.`is_adopted` = 1 AND l.`deleted` = 0
WHERE a.`deleted` = 0
GROUP BY a.`id`, a.`additive_name`, a.`ins_no`, a.`cns_no`, a.`function_class`;
