-- ============================================================================
-- 基于开放数据的零食标签结构化与查询系统 —— 核心业务测试数据脚本
-- 覆盖场景: 多源采集留痕、重复采集/多版本标签、嵌套复合配料与多对多映射、
--           待确认队列、结构化营养成分、FR-9 三态筛选(含信息不足)、产品对比、抽检样本
-- 执行顺序: 请在 schema.sql 与 init_data.sql 之后执行
-- ============================================================================

USE `snack_ingredient_screening`;
SET NAMES utf8mb4;

-- 1. 采集任务记录 (对应 FR-1)
INSERT INTO `biz_crawl_task` (`id`, `source_id`, `keyword`, `request_config`, `status`, `request_count`, `success_count`, `fail_count`, `insert_count`, `start_time`, `end_time`, `error_msg`) VALUES
(201, 1, 'en:snacks', JSON_OBJECT('countries_tags', 'en:china', 'page_size', 100, 'rate_limit_sec', 4, 'max_retries', 3), 'SUCCESS', 3, 3, 0, 3, '2026-11-25 16:00:00', '2026-11-25 16:02:15', NULL),
(202, 1, 'en:biscuits', JSON_OBJECT('countries_tags', 'en:china', 'page_size', 100, 'rate_limit_sec', 4, 'max_retries', 3), 'SUCCESS', 2, 2, 0, 2, '2026-11-25 16:06:00', '2026-11-25 16:07:20', NULL),
(203, 1, 'en:candies', JSON_OBJECT('countries_tags', 'en:china', 'page_size', 100, 'rate_limit_sec', 4, 'max_retries', 3), 'PARTIAL', 2, 1, 1, 1, '2026-11-25 16:12:00', '2026-11-25 16:14:05', '第2页触发 HTTP 503，指数退避后保留断点'),
(204, 2, '2026 食品抽检', JSON_OBJECT('file_type', 'xlsx', 'manual_import', true), 'SUCCESS', 1, 1, 0, 1, '2026-11-24 10:20:00', '2026-11-24 10:21:10', NULL);

-- 2. 不可变原始采集记录 (原始层，保留原样 JSON 与 SHA-256 摘要)
INSERT INTO `biz_raw_record` (`id`, `task_id`, `source_id`, `source_url`, `source_record_key`, `http_status`, `crawl_status`, `raw_content`, `content_hash`, `fetched_at`) VALUES
(1001, 201, 1, 'https://world.openfoodfacts.org/api/v2/product/7622210449283', '7622210449283', 200, 'SUCCESS',
 JSON_OBJECT('code', '7622210449283', 'product_name', '乐事经典原味薯片 70g', 'brands', '乐事', 'ingredients_text', '马铃薯、植物油、经典原味调味料（含5\'-呈味核苷酸二钠）、TBHQ', 'nutriments', JSON_OBJECT('energy-kcal_100g', 548, 'fat_100g', 32, 'carbohydrates_100g', 53, 'sodium_100g', 0.52)),
 'a1b2c3d4e5f60000000000000000000000000000000000000000000000001001', '2026-11-25 16:00:12'),
(1002, 201, 1, 'https://world.openfoodfacts.org/api/v2/product/6920202888888', '6920202888888', 200, 'SUCCESS',
 JSON_OBJECT('code', '6920202888888', 'product_name', '卫龙辣条大面筋 106g', 'brands', '卫龙', 'ingredients_text', '小麦粉、水、植物油、食用盐、白砂糖、辣椒、食品添加剂（防腐剂（脱氢乙酸钠）、甜味剂（三氯蔗糖））、食用香精香料', 'nutriments', JSON_OBJECT('energy-kcal_100g', 412, 'fat_100g', 22, 'carbohydrates_100g', 48, 'sugars_100g', 12, 'sodium_100g', 0.98)),
 'a1b2c3d4e5f60000000000000000000000000000000000000000000000001002', '2026-11-25 16:00:20'),
(1003, 202, 1, 'https://world.openfoodfacts.org/api/v2/product/6901668044444', '6901668044444', 200, 'SUCCESS',
 JSON_OBJECT('code', '6901668044444', 'product_name', '奥利奥夹心饼干 97g', 'brands', '奥利奥', 'ingredients_text', '小麦粉、白砂糖、植物油、可可粉、葡萄糖浆、全脂乳粉、食品添加剂（膨松剂（碳酸氢钠）、乳化剂（大豆磷脂））、食盐', 'nutriments', JSON_OBJECT('energy-kcal_100g', 480, 'fat_100g', 20, 'carbohydrates_100g', 67, 'sugars_100g', 35, 'sodium_100g', 0.38)),
 'a1b2c3d4e5f60000000000000000000000000000000000000000000000001003', '2026-11-25 16:06:10'),
(1004, 201, 1, 'https://world.openfoodfacts.org/api/v2/product/6971234567890', '6971234567890', 200, 'SUCCESS',
 JSON_OBJECT('code', '6971234567890', 'product_name', '沃隆每日坚果 25g', 'brands', '沃隆', 'ingredients_text', '扁桃仁、腰果、核桃仁、蔓越莓干、蓝莓干', 'nutriments', JSON_OBJECT('energy-kcal_100g', 590, 'fat_100g', 48, 'carbohydrates_100g', 28, 'sodium_100g', 0.005)),
 'a1b2c3d4e5f60000000000000000000000000000000000000000000000001004', '2026-11-25 16:00:28'),
(1005, 203, 1, 'https://world.openfoodfacts.org/api/v2/product/6901234599999', '6901234599999', 200, 'SUCCESS',
 JSON_OBJECT('code', '6901234599999', 'product_name', '大白兔奶糖 114g', 'brands', '大白兔', 'ingredients_text', '白砂糖、奶粉、氢化植物油、明胶、食品添加剂（乳化剂（单硬脂酸甘油酯）、食用香精）', 'nutriments', JSON_OBJECT('energy-kcal_100g', 410, 'fat_100g', 8, 'carbohydrates_100g', 78, 'sugars_100g', 50, 'sodium_100g', 0.12)),
 'a1b2c3d4e5f60000000000000000000000000000000000000000000000001005', '2026-11-25 16:12:15'),
(1006, 202, 1, 'https://world.openfoodfacts.org/api/v2/product/6901234567001', '6901234567001', 200, 'SUCCESS',
 JSON_OBJECT('code', '6901234567001', 'product_name', '低糖全麦苏打饼干 100g', 'brands', '康焙坊', 'ingredients_text', '小麦粉、植物油、食用盐、碳酸氢钠、全麦粉（≥30%）、复配膨松剂', 'nutriments', JSON_OBJECT('energy-kcal_100g', 430, 'fat_100g', 16, 'carbohydrates_100g', 62, 'sugars_100g', 3, 'sodium_100g', 0.61)),
 'a1b2c3d4e5f60000000000000000000000000000000000000000000000001006', '2026-11-25 16:06:22'),
(1007, NULL, 3, 'https://item.jd.com/example-7622210449283.html', 'jd_7622210449283', 200, 'SUCCESS',
 JSON_OBJECT('product_name', '乐事经典原味薯片 70g', 'barcode', '7622210449283', 'ingredients_text', '马铃薯，植物油，经典原味调味料(含呈味核苷酸二钠)，特丁基对苯二酚(TBHQ)'),
 'b1b2c3d4e5f60000000000000000000000000000000000000000000000001007', '2026-11-24 14:30:00'),
(1008, 204, 2, 'https://www.samr.gov.cn/zw/zfxxgk/fdzdgknr/spcj/2026-notice-01', 'SAMR-2026-01-009', 200, 'SUCCESS',
 JSON_OBJECT('announced_product_name', '经典原味薯片', 'item_name', '过氧化值(以脂肪计)', 'detected_value', '0.12 g/100g', 'standard_limit', '≤0.25 g/100g', 'conclusion', '所检项目符合标准'),
 'c1b2c3d4e5f60000000000000000000000000000000000000000000000001008', '2026-11-24 10:20:45');

-- 3. 品牌数据
INSERT INTO `biz_brand` (`id`, `brand_name`, `manufacturer`) VALUES
(1, '乐事', '百事食品（中国）有限公司'),
(2, '卫龙', '漯河市平平食品有限责任公司'),
(3, '奥利奥', '亿滋食品企业管理（上海）有限公司'),
(4, '沃隆', '青岛沃隆食品股份有限公司'),
(5, '大白兔', '上海冠生园食品有限公司'),
(6, '康焙坊', '示例烘焙食品有限公司');

-- 4. 去重后的标准产品 (标准层)
INSERT INTO `biz_product` (`id`, `barcode`, `product_name`, `brand_id`, `category_id`, `net_content`, `standard_no`) VALUES
(1, '7622210449283', '乐事经典原味薯片 70g', 1, 2, '70g', 'GB/T 22699'),
(2, '6920202888888', '卫龙辣条大面筋 106g', 2, 6, '106g', 'Q/LPS 0001S'),
(3, '6901668044444', '奥利奥夹心饼干 97g', 3, 3, '97g', 'GB/T 20980'),
(4, '6971234567890', '沃隆每日坚果 25g', 4, 5, '25g', 'GB/T 22165'),
(5, '6901234599999', '大白兔奶糖 114g', 5, 4, '114g', 'SB/T 10018'),
(6, '6901234567001', '低糖全麦苏打饼干 100g', 6, 3, '100g', 'GB/T 20980');

-- 5. 产品与原始采集记录关联 (多源去重与来源追溯，乐事关联 2 个来源)
INSERT INTO `biz_product_source` (`id`, `product_id`, `raw_id`, `source_id`, `source_product_key`, `match_method`, `match_confidence`, `is_primary`) VALUES
(1, 1, 1001, 1, '7622210449283', 'BARCODE_EXACT', 1.0000, 1),
(2, 1, 1007, 3, 'jd_7622210449283', 'BARCODE_EXACT', 1.0000, 0),
(3, 2, 1002, 1, '6920202888888', 'BARCODE_EXACT', 1.0000, 1),
(4, 3, 1003, 1, '6901668044444', 'BARCODE_EXACT', 1.0000, 1),
(5, 4, 1004, 1, '6971234567890', 'BARCODE_EXACT', 1.0000, 1),
(6, 5, 1005, 1, '6901234599999', 'BARCODE_EXACT', 1.0000, 1),
(7, 6, 1006, 1, '6901234567001', 'BARCODE_EXACT', 1.0000, 1);

-- 6. 按来源留存的标签版本 (乐事保留 2 个来源版本，仅 101 为当前采用版；106 为致敏原未标注样本)
INSERT INTO `biz_label` (`id`, `product_id`, `source_id`, `raw_id`, `ingredient_text`, `allergen_text`, `allergen_labeled`, `label_completeness`, `source_updated_at`, `is_adopted`, `captured_at`) VALUES
(101, 1, 1, 1001, '马铃薯、植物油、经典原味调味料（含5\'-呈味核苷酸二钠）、TBHQ', '无常见致敏原标注', 1, 'PARTIAL', '2026-11-20 08:00:00', 1, '2026-11-25 16:00:12'),
(102, 2, 1, 1002, '小麦粉、水、植物油、食用盐、白砂糖、辣椒、食品添加剂（防腐剂（脱氢乙酸钠）、甜味剂（三氯蔗糖））、食用香精香料', '含麸质谷物、大豆制品', 1, 'COMPLETE', '2026-11-18 12:00:00', 1, '2026-11-25 16:00:20'),
(103, 3, 1, 1003, '小麦粉、白砂糖、植物油、可可粉、葡萄糖浆、全脂乳粉、食品添加剂（膨松剂（碳酸氢钠）、乳化剂（大豆磷脂））、食盐', '含麸质谷物、乳、大豆', 1, 'COMPLETE', '2026-11-19 09:30:00', 1, '2026-11-25 16:06:10'),
(104, 4, 1, 1004, '扁桃仁、腰果、核桃仁、蔓越莓干、蓝莓干', '含坚果', 1, 'PARTIAL', '2026-11-15 10:00:00', 1, '2026-11-25 16:00:28'),
(105, 5, 1, 1005, '白砂糖、奶粉、氢化植物油、明胶、食品添加剂（乳化剂（单硬脂酸甘油酯）、食用香精）', '含乳制品', 1, 'COMPLETE', '2026-11-12 15:00:00', 1, '2026-11-25 16:12:15'),
(106, 6, 1, 1006, '小麦粉、植物油、食用盐、碳酸氢钠、全麦粉（≥30%）、复配膨松剂', NULL, 0, 'PARTIAL', '2026-11-10 11:00:00', 1, '2026-11-25 16:06:22'),
(107, 1, 3, 1007, '马铃薯，植物油，经典原味调味料(含呈味核苷酸二钠)，特丁基对苯二酚(TBHQ)', '无', 1, 'MISSING_NUTRITION', '2026-11-22 10:00:00', 0, '2026-11-24 14:30:00');

-- 7. 标签结构化营养成分 (统一每 100g 数值；sugar_g 为 NULL 用于测试 FR-9 信息不足)
INSERT INTO `biz_label_nutrition` (`id`, `label_id`, `product_id`, `basis_type`, `serving_size`, `energy_kj`, `energy_kcal`, `protein_g`, `fat_g`, `saturated_fat_g`, `trans_fat_g`, `carbs_g`, `sugar_g`, `dietary_fiber_g`, `sodium_mg`, `nutrition_complete`) VALUES
(1, 101, 1, 'per_100g', '30g/份', 2293.00, 548.00, 6.200, 32.000, 14.500, 0.000, 53.000, NULL, 3.800, 520.000, 0),
(2, 102, 2, 'per_100g', '106g/包', 1724.00, 412.00, 8.400, 22.000, 4.200, 0.000, 48.000, 12.000, 2.100, 980.000, 1),
(3, 103, 3, 'per_100g', '29g/3枚', 2008.00, 480.00, 5.100, 20.000, 9.600, 0.000, 67.000, 35.000, 2.600, 380.000, 1),
(4, 104, 4, 'per_100g', '25g/袋', 2469.00, 590.00, 15.800, 48.000, 6.100, 0.000, 28.000, NULL, 6.500, 5.000, 0),
(5, 105, 5, 'per_100g', '30g/份', 1715.00, 410.00, 4.500, 8.000, 5.200, 0.200, 78.000, 50.000, 0.000, 120.000, 1),
(6, 106, 6, 'per_100g', '25g/份', 1799.00, 430.00, 9.000, 16.000, 7.000, 0.000, 62.000, 3.000, 4.200, 610.000, 1);

-- 8. 产品标签-配料解析明细 (按顺序插入父级后再插入子级，保证嵌套括号树与待确认队列)
-- 产品 1: 乐事经典原味薯片 (label_id = 101)
INSERT INTO `biz_product_ingredient` (`id`, `product_id`, `label_id`, `ingredient_id`, `parent_id`, `raw_name`, `position_no`, `depth_level`, `declared_percent`, `declared_relation`, `declared_form`, `map_status`, `map_confidence`, `parser_version`, `fail_reason`) VALUES
(1, 1, 101, 1, NULL, '马铃薯', 1, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(2, 1, 101, 2, NULL, '植物油', 2, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(3, 1, 101, 21, NULL, '经典原味调味料', 3, 1, NULL, NULL, '复合配料', 'MAPPED', 0.9800, 'parser-v1.0', NULL),
(4, 1, 101, 28, 3, '5\'-呈味核苷酸二钠', 4, 2, NULL, NULL, NULL, 'MAPPED', 0.9900, 'parser-v1.0', NULL),
(5, 1, 101, 25, NULL, 'TBHQ', 5, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL);

-- 产品 2: 卫龙辣条大面筋 (label_id = 102，含多级嵌套与待人工确认片段)
INSERT INTO `biz_product_ingredient` (`id`, `product_id`, `label_id`, `ingredient_id`, `parent_id`, `raw_name`, `position_no`, `depth_level`, `declared_percent`, `declared_relation`, `declared_form`, `map_status`, `map_confidence`, `parser_version`, `fail_reason`) VALUES
(6, 2, 102, 3, NULL, '小麦粉', 1, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(7, 2, 102, 4, NULL, '水', 2, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(8, 2, 102, 2, NULL, '植物油', 3, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(9, 2, 102, 5, NULL, '食用盐', 4, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(10, 2, 102, 6, NULL, '白砂糖', 5, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(11, 2, 102, 7, NULL, '辣椒', 6, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(12, 2, 102, 29, NULL, '脱氢乙酸钠', 7, 2, NULL, NULL, '防腐剂', 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(13, 2, 102, 26, NULL, '三氯蔗糖', 8, 2, NULL, NULL, '甜味剂', 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(14, 2, 102, NULL, NULL, '食用香精香料', 9, 1, NULL, NULL, NULL, 'PENDING', 0.7200, 'parser-v1.0', '词典未精确收录，待人工确认是否并入“食用香精”');

-- 产品 3: 奥利奥夹心饼干 (label_id = 103)
INSERT INTO `biz_product_ingredient` (`id`, `product_id`, `label_id`, `ingredient_id`, `parent_id`, `raw_name`, `position_no`, `depth_level`, `declared_percent`, `declared_relation`, `declared_form`, `map_status`, `map_confidence`, `parser_version`, `fail_reason`) VALUES
(15, 3, 103, 3, NULL, '小麦粉', 1, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(16, 3, 103, 6, NULL, '白砂糖', 2, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(17, 3, 103, 2, NULL, '植物油', 3, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(18, 3, 103, 8, NULL, '可可粉', 4, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(19, 3, 103, 9, NULL, '葡萄糖浆', 5, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(20, 3, 103, 10, NULL, '全脂乳粉', 6, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(21, 3, 103, 31, NULL, '碳酸氢钠', 7, 2, NULL, NULL, '膨松剂', 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(22, 3, 103, 30, NULL, '大豆磷脂', 8, 2, NULL, NULL, '乳化剂', 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(23, 3, 103, 5, NULL, '食盐', 9, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL);

-- 产品 4: 沃隆每日坚果 (label_id = 104)
INSERT INTO `biz_product_ingredient` (`id`, `product_id`, `label_id`, `ingredient_id`, `parent_id`, `raw_name`, `position_no`, `depth_level`, `declared_percent`, `declared_relation`, `declared_form`, `map_status`, `map_confidence`, `parser_version`, `fail_reason`) VALUES
(24, 4, 104, 11, NULL, '扁桃仁', 1, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(25, 4, 104, 12, NULL, '腰果', 2, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(26, 4, 104, 13, NULL, '核桃仁', 3, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(27, 4, 104, 14, NULL, '蔓越莓干', 4, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(28, 4, 104, 15, NULL, '蓝莓干', 5, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL);

-- 产品 5: 大白兔奶糖 (label_id = 105)
INSERT INTO `biz_product_ingredient` (`id`, `product_id`, `label_id`, `ingredient_id`, `parent_id`, `raw_name`, `position_no`, `depth_level`, `declared_percent`, `declared_relation`, `declared_form`, `map_status`, `map_confidence`, `parser_version`, `fail_reason`) VALUES
(29, 5, 105, 6, NULL, '白砂糖', 1, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(30, 5, 105, 10, NULL, '奶粉', 2, 1, NULL, NULL, NULL, 'MAPPED', 0.9900, 'parser-v1.0', NULL),
(31, 5, 105, 16, NULL, '氢化植物油', 3, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(32, 5, 105, 17, NULL, '明胶', 4, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(33, 5, 105, 27, NULL, '单硬脂酸甘油酯', 5, 2, NULL, NULL, '乳化剂', 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(34, 5, 105, 22, NULL, '食用香精', 6, 2, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL);

-- 产品 6: 低糖全麦苏打饼干 (label_id = 106，含含量标示 ≥30% 与待确认配料)
INSERT INTO `biz_product_ingredient` (`id`, `product_id`, `label_id`, `ingredient_id`, `parent_id`, `raw_name`, `position_no`, `depth_level`, `declared_percent`, `declared_relation`, `declared_form`, `map_status`, `map_confidence`, `parser_version`, `fail_reason`) VALUES
(35, 6, 106, 3, NULL, '小麦粉', 1, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(36, 6, 106, 2, NULL, '植物油', 2, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(37, 6, 106, 5, NULL, '食用盐', 3, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(38, 6, 106, 31, NULL, '碳酸氢钠', 4, 1, NULL, NULL, NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(39, 6, 106, 18, NULL, '全麦粉（≥30%）', 5, 1, 30.00, '>=', NULL, 'MAPPED', 1.0000, 'parser-v1.0', NULL),
(40, 6, 106, NULL, NULL, '复配膨松剂', 6, 1, NULL, NULL, NULL, 'PENDING', 0.6500, 'parser-v1.0', '复合添加剂未拆分明细，待人工确认');

-- 9. 成分解读批次与三级解读结果 (对应 FR-5)
INSERT INTO `biz_interpret_run` (`id`, `run_time`, `scope_type`, `scope_desc`, `rule_version`, `total_products`, `hit_count`, `status`) VALUES
(31, '2026-11-25 16:20:00', 'ALL', '全量示例产品 6 件', 'v1.0', 6, 7, 'SUCCESS');

INSERT INTO `biz_interpret_result` (`id`, `run_id`, `product_id`, `label_id`, `rule_id`, `additive_id`, `info_type`, `conclusion_state`, `evidence_text`, `rule_version`, `generated_at`) VALUES
(9001, 31, 1, 101, NULL, NULL, 'FACT', 'INFO_ONLY', '配料表原文含 5\'-呈味核苷酸二钠、TBHQ；糖含量未标注', 'v1.0', '2026-11-25 16:20:01'),
(9002, 31, 1, 101, NULL, 3, 'KNOWLEDGE', 'INFO_ONLY', '特丁基对苯二酚（TBHQ，INS 319）为抗氧化剂，常用于油脂和膨化食品延缓氧化。', 'v1.0', '2026-11-25 16:20:01'),
(9003, 31, 2, 102, 2, NULL, 'PERSONAL_TIP', 'UNFIT', '配料含小麦粉（属麸质谷物）；钠 980.000 mg/100g 高于规则阈值 600.000 mg/100g', 'v1.0', '2026-11-25 16:20:02'),
(9004, 31, 3, 103, 3, NULL, 'PERSONAL_TIP', 'UNFIT', '配料含小麦粉、全脂乳粉、大豆磷脂，命中麸质谷物、乳、大豆关注项', 'v1.0', '2026-11-25 16:20:02'),
(9005, 31, 4, 104, 8, NULL, 'PERSONAL_TIP', 'INSUFFICIENT_INFO', '营养成分表未标注糖含量(sugar_g IS NULL)，控糖规则判定为信息不足，不默认判为适合', 'v1.0', '2026-11-25 16:20:03'),
(9006, 31, 6, 106, 7, NULL, 'PERSONAL_TIP', 'UNFIT', '钠 610.000 mg/100g 高于规则阈值 600.000 mg/100g；另因致敏原未标注，过敏原筛选需归为信息不足', 'v1.0', '2026-11-25 16:20:03'),
(9007, 31, 4, 104, NULL, NULL, 'FACT', 'INFO_ONLY', '配料表仅含扁桃仁、腰果、核桃仁、蔓越莓干、蓝莓干（未识别出食品添加剂）', 'v1.0', '2026-11-25 16:20:03');

-- 10. 监管抽检公告验证样本 (仅客观转引公告实测项，无抽检记录产品不作违法判定)
INSERT INTO `biz_inspection_record` (`id`, `raw_id`, `product_id`, `announced_product_name`, `item_name`, `detected_value`, `standard_limit`, `notice_conclusion`, `notice_title`, `notice_date`) VALUES
(1, 1008, 1, '经典原味薯片', '过氧化值(以脂肪计)', '0.12 g/100g', '≤0.25 g/100g', '所检项目符合标准', '市场监管总局 2026 年第 1 期食品安全抽检通告(示例)', '2026-11-24');

-- 11. 操作审计日志 (对应 FR-8.2)
INSERT INTO `sys_operation_log` (`id`, `user_id`, `action`, `target_table`, `target_id`, `detail`) VALUES
(1, 2, '执行开放 API 采集任务 #201', 'biz_crawl_task', 201, '按 en:snacks 采集并入库 3 条示例原始 JSON'),
(2, 2, '录入监管抽检验证样本', 'biz_inspection_record', 1, '导入抽检公告样本 1 条，关联 raw_id=1008'),
(3, 1, '触发成分解读批次 #31', 'biz_interpret_run', 31, '按规则版本 v1.0 完成 6 件示例产品成分解读');
