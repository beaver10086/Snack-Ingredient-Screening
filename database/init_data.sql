-- ============================================================================
-- 基于开放数据的零食标签结构化与查询系统 —— 基础初始化数据脚本
-- 执行顺序: 请在 schema.sql 之后、test_data.sql 之前执行
-- ============================================================================

USE `snack_ingredient_screening`;
SET NAMES utf8mb4;

-- 1. 开放数据源配置 (对应 FR-1 / 需求文档第 5 节)
INSERT INTO `biz_data_source` (`id`, `source_name`, `source_type`, `base_url`, `access_method`, `reliability_level`, `terms_note`, `status`) VALUES
(1, 'Open Food Facts', '开放库', 'https://world.openfoodfacts.org/api/v2/search', 'API', 4, 'ODbL 开放数据库许可，须署名；匿名限速 15 req/min/IP，需带自定义 User-Agent', 1),
(2, '市场监管总局抽检公告', '官方公告', 'https://www.samr.gov.cn', '附件解析', 5, '国家市场监督管理总局官网公开通告与 Excel/PDF 附件，仅作验证样本，不做违规推论', 1),
(3, '电商公开详情页', '网页', 'https://www.jd.com', '人工摘录', 3, '仅少量人工核对补充(30~50条)，遵守 robots 协议，不绕过反爬，不作主力采集源', 1);

-- 2. 零食品类层级 (对应 FR-2.4)
INSERT INTO `biz_category` (`id`, `category_name`, `parent_id`, `gb2760_code`) VALUES
(1, '休闲零食', NULL, NULL),
(2, '膨化食品', 1, '06.03'),
(3, '饼干糕点', 1, '07.01'),
(4, '糖果巧克力', 1, '05.02'),
(5, '坚果炒货', 1, '04.05'),
(6, '肉类及调味面制品零食', 1, '08.03');

-- 3. 常见食品添加剂知识库 (对应 FR-4.1 / G4，仅作科普说明，不含违法定性)
INSERT INTO `biz_additive` (`id`, `additive_name`, `ins_no`, `cns_no`, `function_class`, `common_uses`, `knowledge_text`, `knowledge_source`) VALUES
(1, '山梨酸钾', '202', '17.004', '防腐剂', '调味面制品、糕点、蜜饯', '常见的食品防腐剂，可抑制霉菌和酵母菌生长，延长食品保质期。', 'GB 2760 食品添加剂科普资料整理'),
(2, '柠檬黄', '102', '08.006', '着色剂', '糖果、膨化食品、饮料', '一种水溶性合成食用色素，常用于糖果、糕点等食品着色，标签常标示为“着色剂（柠檬黄）”。', 'GB 2760 食品添加剂科普资料整理'),
(3, '特丁基对苯二酚', '319', '04.007', '抗氧化剂', '油炸膨化食品、坚果炒货', '常用于油脂和膨化食品的抗氧化剂，可延缓油脂氧化哈败。配料表中常见英文简写“TBHQ”。', 'GB 2760 食品添加剂科普资料整理'),
(4, '三氯蔗糖', '955', '19.016', '甜味剂', '调味面制品、无糖糖果、饼干', '一种高倍甜味剂，甜度约为蔗糖的数百倍，常用于改善甜味或减少蔗糖添加。', 'GB 2760 食品添加剂科普资料整理'),
(5, '单硬脂酸甘油酯', '471', '10.006', '乳化剂', '奶糖、巧克力、烘焙糕点', '常见食品乳化剂，可使油水体系更稳定，改善糖果和糕点的质地与口感。', 'GB 2760 食品添加剂科普资料整理'),
(6, '5\'-呈味核苷酸二钠', '635', '12.004', '增味剂', '薯片调味料、膨化食品、肉类零食', '常见食品增味剂，可增强食品鲜味，常与谷氨酸钠或复合调味料配合使用。', 'GB 2760 食品添加剂科普资料整理'),
(7, '脱氢乙酸钠', '266', '17.009', '防腐剂', '部分糕点、调味面制品历史配方', '常见防腐剂，用于抑制细菌、霉菌和酵母菌生长；不同食品类别及标准版本对其适用范围有不同规定。', 'GB 2760 食品添加剂科普资料整理'),
(8, '大豆磷脂', '322', '10.010', '乳化剂', '夹心饼干、巧克力、糖果', '来源于大豆的天然乳化剂，同时属于常见大豆类致敏物质，标签中通常需注意致敏提示。', 'GB 2760 食品添加剂科普资料整理'),
(9, '碳酸氢钠', '500ii', NULL, '膨松剂', '饼干、苏打饼干、烘焙零食', '俗称小苏打，常见膨松剂与酸度调节剂，受热或遇酸释放二氧化碳使饼干结构疏松。', 'GB 2760 食品添加剂科普资料整理');

-- 4. 标准配料基础信息词典 (对应 FR-3.4 / FR-3.7)
INSERT INTO `biz_ingredient` (`id`, `std_name`, `ingredient_type`, `additive_id`, `is_allergen`, `allergen_type`, `description`) VALUES
(1, '马铃薯', '主料', NULL, 0, NULL, '常见薯类原料，薯片核心基料'),
(2, '植物油', '辅料', NULL, 0, NULL, '食用植物油脂统称'),
(3, '小麦粉', '主料', NULL, 1, '麸质谷物', '小麦磨制面粉，含麸质蛋白'),
(4, '水', '辅料', NULL, 0, NULL, '食品加工用水'),
(5, '食用盐', '辅料', NULL, 0, NULL, '氯化钠调味盐'),
(6, '白砂糖', '辅料', NULL, 0, NULL, '常见蔗糖甜味辅料'),
(7, '辣椒', '香辛料', NULL, 0, NULL, '常见香辛调味原料'),
(8, '可可粉', '辅料', NULL, 0, NULL, '可可豆加工原料'),
(9, '葡萄糖浆', '辅料', NULL, 0, NULL, '常见淀粉糖浆'),
(10, '全脂乳粉', '辅料', NULL, 1, '乳', '牛乳干燥制成的乳粉，含乳蛋白与乳糖'),
(11, '扁桃仁', '主料', NULL, 1, '坚果', '树坚果类原料（巴旦木）'),
(12, '腰果', '主料', NULL, 1, '坚果', '常见树坚果类原料'),
(13, '核桃仁', '主料', NULL, 1, '坚果', '常见树坚果类原料'),
(14, '蔓越莓干', '辅料', NULL, 0, NULL, '果干类配料'),
(15, '蓝莓干', '辅料', NULL, 0, NULL, '果干类配料'),
(16, '氢化植物油', '辅料', NULL, 0, NULL, '经氢化处理的植物油脂'),
(17, '明胶', '辅料', NULL, 0, NULL, '常见胶凝剂原料'),
(18, '全麦粉', '主料', NULL, 1, '麸质谷物', '整粒小麦研磨面粉，含麸质蛋白'),
(19, '花生', '主料', NULL, 1, '花生', '常见高致敏原坚果豆科作物'),
(20, '鸡蛋', '辅料', NULL, 1, '蛋', '蛋类原料，常见致敏原'),
(21, '经典原味调味料', '复合配料', NULL, 0, NULL, '复合调味料，常含增味剂与盐类'),
(22, '食用香精', '辅料', NULL, 0, NULL, '用于赋予或改善食品风味的香精'),
(23, '山梨酸钾', '食品添加剂', 1, 0, NULL, '对应添加剂知识库山梨酸钾'),
(24, '柠檬黄', '食品添加剂', 2, 0, NULL, '对应添加剂知识库柠檬黄'),
(25, '特丁基对苯二酚', '食品添加剂', 3, 0, NULL, '对应添加剂知识库TBHQ'),
(26, '三氯蔗糖', '食品添加剂', 4, 0, NULL, '对应添加剂知识库三氯蔗糖'),
(27, '单硬脂酸甘油酯', '食品添加剂', 5, 0, NULL, '对应添加剂知识库单硬脂酸甘油酯'),
(28, '5\'-呈味核苷酸二钠', '食品添加剂', 6, 0, NULL, '对应添加剂知识库5\'-呈味核苷酸二钠'),
(29, '脱氢乙酸钠', '食品添加剂', 7, 0, NULL, '对应添加剂知识库脱氢乙酸钠'),
(30, '大豆磷脂', '食品添加剂', 8, 1, '大豆', '来源于大豆的乳化剂，含大豆致敏风险'),
(31, '碳酸氢钠', '食品添加剂', 9, 0, NULL, '对应添加剂知识库碳酸氢钠');

-- 5. 配料别名映射词典 (对应 FR-3.4 / FR-3.6)
INSERT INTO `biz_ingredient_alias` (`id`, `ingredient_id`, `alias_name`, `alias_type`, `source_note`) VALUES
(1, 25, 'TBHQ', 'ABBR', '常见配料表英文缩写'),
(2, 25, 'INS 319', 'INS', '国际食品添加剂编码'),
(3, 24, 'INS 102', 'INS', '国际食品添加剂编码'),
(4, 24, 'FD&C Yellow 5', 'ENGLISH', '美国常用色素别名'),
(5, 23, 'INS 202', 'INS', '国际食品添加剂编码'),
(6, 23, 'Potassium Sorbate', 'ENGLISH', 'Open Food Facts 常见英文名'),
(7, 26, 'INS 955', 'INS', '国际食品添加剂编码'),
(8, 26, 'Sucralose', 'ENGLISH', 'Open Food Facts 常见英文名'),
(9, 30, 'INS 322', 'INS', '国际食品添加剂编码'),
(10, 30, '大豆卵磷脂', 'SYNONYM', '中文常见同义写法'),
(11, 5, '食盐', 'SYNONYM', '中文常见同义写法'),
(12, 10, '奶粉', 'SYNONYM', '乳粉常见简称'),
(13, 31, '小苏打', 'SYNONYM', '中文俗称'),
(14, 28, '呈味核苷酸二钠', 'SYNONYM', '省略前缀写法'),
(15, 11, '巴旦木', 'SYNONYM', '常见商品俗称');

-- 6. 用户关注规则初始版本 v1.0 (对应 FR-4.2 / DB-4 / DB-5，非合规规则)
INSERT INTO `biz_user_rule` (`id`, `rule_code`, `rule_type`, `rule_name`, `target_allergen`, `nutrient_field`, `compare_op`, `threshold_value`, `threshold_unit`, `rule_version`, `hint_level`, `description`, `is_active`) VALUES
(1, 'RULE_ALLERGEN_PEANUT', 'ALLERGEN', '花生', '花生', NULL, NULL, NULL, NULL, 'v1.0', 'PERSONAL_TIP', '配料或致敏原中含花生或花生制品时给出个人提示', 1),
(2, 'RULE_ALLERGEN_GLUTEN', 'ALLERGEN', '麸质谷物', '麸质谷物', NULL, NULL, NULL, NULL, 'v1.0', 'PERSONAL_TIP', '配料中含小麦、大麦等含麸质谷物时给出个人提示', 1),
(3, 'RULE_ALLERGEN_MILK', 'ALLERGEN', '乳', '乳', NULL, NULL, NULL, NULL, 'v1.0', 'PERSONAL_TIP', '配料中含乳或乳制品时给出个人提示', 1),
(4, 'RULE_ALLERGEN_NUTS', 'ALLERGEN', '坚果', '坚果', NULL, NULL, NULL, NULL, 'v1.0', 'PERSONAL_TIP', '配料中含扁桃仁、腰果、核桃仁等坚果类时给出个人提示', 1),
(5, 'RULE_ALLERGEN_SOY', 'ALLERGEN', '大豆', '大豆', NULL, NULL, NULL, NULL, 'v1.0', 'PERSONAL_TIP', '配料中含大豆或大豆磷脂等大豆衍生成分时给出个人提示', 1),
(6, 'RULE_ALLERGEN_EGG', 'ALLERGEN', '蛋', '蛋', NULL, NULL, NULL, NULL, 'v1.0', 'PERSONAL_TIP', '配料中含鸡蛋或蛋制品时给出个人提示', 1),
(7, 'RULE_NUTR_SODIUM', 'NUTRITION', '钠', NULL, 'sodium_mg', '>', 600.000, 'mg/100g', 'v1.0', 'PERSONAL_TIP', '钠含量高于 600 mg/100g 时给出个人控钠提示', 1),
(8, 'RULE_NUTR_SUGAR', 'NUTRITION', '糖', NULL, 'sugar_g', '>', 25.000, 'g/100g', 'v1.0', 'PERSONAL_TIP', '糖含量高于 25 g/100g 时给出个人控糖提示', 1),
(9, 'RULE_NUTR_CARBS', 'NUTRITION', '碳水化合物', NULL, 'carbs_g', '>', 60.000, 'g/100g', 'v1.0', 'PERSONAL_TIP', '碳水化合物含量高于 60 g/100g 时给出个人提示', 1);

-- 7. 系统后台用户 (对应 FR-8.1，密码为演示占位哈希，生产环境请替换为真实 BCrypt 哈希)
INSERT INTO `sys_user` (`id`, `username`, `password_hash`, `nickname`, `role_code`, `status`) VALUES
(1, 'admin', '$2b$12$DEMO_PLACEHOLDER_HASH_ADMIN_DO_NOT_USE_IN_PROD', '系统管理员', 'ADMIN', 1),
(2, 'data_ops', '$2b$12$DEMO_PLACEHOLDER_HASH_DATAOPS_DO_NOT_USE_IN_PROD', '数据维护员', 'DATA_OPS', 1),
(3, 'analyst', '$2b$12$DEMO_PLACEHOLDER_HASH_ANALYST_DO_NOT_USE_IN_PROD', '只读分析员', 'ANALYST', 1);
