-- 1. 营销员脱落率
-- 假设报告期为 2025-01-01 到 2025-02-21
WITH start_agents AS (
    -- 计算期初营销员数量
    SELECT COUNT(*) AS start_count
    FROM agents
    WHERE start_date < '2025-01-01' AND (end_date IS NULL OR end_date >= '2025-01-01')
),
hired_agents AS (
    -- 计算报告期内招聘的营销员数量
    SELECT COUNT(*) AS hired_count
    FROM agents
    WHERE start_date BETWEEN '2025-01-01' AND '2025-02-21'
),
left_agents AS (
    -- 计算报告期离职的营销员数量
    SELECT COUNT(*) AS left_count
    FROM agents
    WHERE end_date BETWEEN '2025-01-01' AND '2025-02-21'
)
SELECT
    -- 计算营销员脱落率
    (left_count / (start_count + hired_count)) * 100 AS marketing_dropout_rate
FROM
    start_agents,
    hired_agents,
    left_agents;

-- 2. 新单保额与新单保费比
SELECT
    -- 计算新单保额与新单保费比
    SUM(policy_amount) / SUM(premium) AS new_policy_ratio
FROM
    policies
WHERE
    is_new = true;

-- 3. 分险种保费占比
SELECT
    insurance_type,
    -- 计算各险种保费占比
    SUM(premium) / (SELECT SUM(premium) FROM policies) * 100 AS insurance_type_ratio
FROM
    policies
GROUP BY
    insurance_type;

-- 4. 险种组合变化率
-- 假设基期为 2024 年，报告期为 2025 年
WITH base_period_premium AS (
    -- 计算基期各险种保费
    SELECT
        insurance_type,
        SUM(premium) AS base_premium
    FROM
        policies
    WHERE
        year(to_date(policy_date)) = 2024
    GROUP BY
        insurance_type
),
report_period_premium AS (
    -- 计算报告期各险种保费
    SELECT
        insurance_type,
        SUM(premium) AS report_premium
    FROM
        policies
    WHERE
        year(to_date(policy_date)) = 2025
    GROUP BY
        insurance_type
),
base_total_premium AS (
    -- 计算基期总保费
    SELECT SUM(premium) AS total
    FROM policies
    WHERE year(to_date(policy_date)) = 2024
),
report_total_premium AS (
    -- 计算报告期总保费
    SELECT SUM(premium) AS total
    FROM policies
    WHERE year(to_date(policy_date)) = 2025
),
premium_diff AS (
    -- 计算各险种保费占比变动的绝对值
    SELECT
        COALESCE(r.insurance_type, b.insurance_type) AS insurance_type,
        ABS(COALESCE(r.report_premium, 0) / (SELECT total FROM report_total_premium) - COALESCE(b.base_premium, 0) / (SELECT total FROM base_total_premium)) AS abs_diff
    FROM
        report_period_premium r
    FULL JOIN
        base_period_premium b ON r.insurance_type = b.insurance_type
)
SELECT
    -- 计算险种组合变化率
    SUM(abs_diff) / COUNT(*) * 100 AS policy_combination_change_rate
FROM
    premium_diff;

-- 5. 分渠道保费占比
SELECT
    channel,
    -- 计算各渠道保费占比
    SUM(premium) / (SELECT SUM(premium) FROM policies) * 100 AS channel_ratio
FROM
    policies
GROUP BY
    channel;

-- 6. 业务来源集中度（假设 n = 2）
WITH reinsurance_premium_ratio AS (
    -- 计算各分出公司分保费收入占比
    SELECT
        ceding_company,
        premium,
        premium / (SELECT SUM(premium) FROM reinsurance) AS ratio
    FROM
        reinsurance
),
ranked_ceding_companies AS (
    -- 对分出公司按分保费收入占比排序
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY ratio DESC) AS rn
    FROM
        reinsurance_premium_ratio
)
SELECT
    -- 计算业务来源集中度
    SUM(premium) / (SELECT SUM(premium) FROM reinsurance) * 100 AS business_source_concentration
FROM
    ranked_ceding_companies
WHERE
    rn <= 2;

-- 7. 非关联交易保费占比
SELECT
    -- 计算非关联交易保费占比
    SUM(CASE WHEN is_related = false THEN premium ELSE 0 END) / SUM(premium) * 100 AS non_related_transaction_ratio
FROM
    reinsurance;

-- 8. 境内/境外保费占比
SELECT
    '境内' AS location,
    -- 计算境内保费占比
    SUM(CASE WHEN is_domestic = true THEN premium ELSE 0 END) / SUM(premium) * 100 AS premium_ratio
FROM
    reinsurance
UNION ALL
SELECT
    '境外' AS location,
    -- 计算境外保费占比
    SUM(CASE WHEN is_domestic = false THEN premium ELSE 0 END) / SUM(premium) * 100 AS premium_ratio
FROM
    reinsurance;

-- 9. 临分/合同保费占比
SELECT
    '临分' AS type,
    -- 计算临分保费占比
    SUM(CASE WHEN is_temporary = true THEN premium ELSE 0 END) / SUM(premium) * 100 AS premium_ratio
FROM
    reinsurance
UNION ALL
SELECT
    '合同' AS type,
    -- 计算合同保费占比
    SUM(CASE WHEN is_temporary = false THEN premium ELSE 0 END) / SUM(premium) * 100 AS premium_ratio
FROM
    reinsurance;

-- 10. 比例/非比例保费占比
SELECT
    '比例' AS type,
    -- 计算比例合同保费占比
    SUM(CASE WHEN is_proportional = true THEN premium ELSE 0 END) / SUM(premium) * 100 AS premium_ratio
FROM
    reinsurance
UNION ALL
SELECT
    '非比例' AS type,
    -- 计算非比例合同保费占比
    SUM(CASE WHEN is_proportional = false THEN premium ELSE 0 END) / SUM(premium) * 100 AS premium_ratio
FROM
    reinsurance;