import mysql.connector
import random
from datetime import datetime, timedelta
--todo  连接数据库
mydb = mysql.connector.connect(
    host="localhost",
    user="your_username",
    password="your_password",
    database="your_database"
)

mycursor = mydb.cursor()

--todo  创建 agents 表
create_agents_table = """
CREATE TABLE IF NOT EXISTS agents (
    agent_id INT PRIMARY KEY AUTO_INCREMENT,
    agent_name VARCHAR(50),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);
"""
mycursor.execute(create_agents_table)

-- todo 创建 policies 表
create_policies_table = """
CREATE TABLE IF NOT EXISTS policies (
    policy_id INT PRIMARY KEY AUTO_INCREMENT,
    policy_date DATE,
    policy_amount DECIMAL(10, 2),
    premium DECIMAL(10, 2),
    insurance_type VARCHAR(50),
    channel VARCHAR(50),
    is_new BOOLEAN
);
"""
mycursor.execute(create_policies_table)

-- todo 创建 reinsurance 表
create_reinsurance_table = """
CREATE TABLE IF NOT EXISTS reinsurance (
    reinsurance_id INT PRIMARY KEY AUTO_INCREMENT,
    ceding_company VARCHAR(50),
    is_related BOOLEAN,
    is_domestic BOOLEAN,
    is_temporary BOOLEAN,
    is_proportional BOOLEAN,
    premium DECIMAL(10, 2)
);
"""
mycursor.execute(create_reinsurance_table)

-- todo 插入 agents 表数据
num_agents = 1000
for i in range(num_agents):
    agent_name = f'Agent {i}'
    start_date = datetime.now() - timedelta(days=random.randint(0, 365))
    end_date = None if random.random() > 0.2 else start_date + timedelta(days=random.randint(0, 30))
    status = 'Inactive' if end_date else 'Active'
    insert_agent = "INSERT INTO agents (agent_name, start_date, end_date, status) VALUES (%s, %s, %s, %s)"
    val = (agent_name, start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d') if end_date else None, status)
    mycursor.execute(insert_agent, val)

-- todo  插入 policies 表数据
num_policies = 1000
insurance_types = ['Property Insurance', 'Life Insurance', 'Auto Insurance', 'Health Insurance']
channels = ['Online', 'Agency', 'Direct Mail']
for i in range(num_policies):
    policy_date = datetime.now() - timedelta(days=random.randint(0, 365))
    policy_amount = random.randint(1000, 20000)
    premium = random.randint(100, 1000)
    insurance_type = random.choice(insurance_types)
    channel = random.choice(channels)
    is_new = random.random() < 0.5
    insert_policy = "INSERT INTO policies (policy_date, policy_amount, premium, insurance_type, channel, is_new) VALUES (%s, %s, %s, %s, %s, %s)"
    val = (policy_date.strftime('%Y-%m-%d'), policy_amount, premium, insurance_type, channel, is_new)
    mycursor.execute(insert_policy, val)

-- todo 插入 reinsurance 表数据
num_reinsurance = 1000
for i in range(num_reinsurance):
    ceding_company = f'Company {i}'
    is_related = random.random() < 0.5
    is_domestic = random.random() < 0.5
    is_temporary = random.random() < 0.5
    is_proportional = random.random() < 0.5
    premium = random.randint(100, 2000)
    insert_reinsurance = "INSERT INTO reinsurance (ceding_company, is_related, is_domestic, is_temporary, is_proportional, premium) VALUES (%s, %s, %s, %s, %s, %s)"
    val = (ceding_company, is_related, is_domestic, is_temporary, is_proportional, premium)
    mycursor.execute(insert_reinsurance, val)

mydb.commit()
mycursor.close()
mydb.close()
