import sqlite3
import hashlib

# 数据库文件名，直接连接组里的 termplan.db
DB_FILE = 'termplan.db'

def init_db():
    """初始化数据库：如果用户表不存在，则创建它"""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    # 创建用户表：包含自增ID、唯一用户名、密码哈希值和创建时间
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    conn.commit()
    conn.close()

def hash_password(password):
    """安全加密：将明文密码转化为 SHA-256 哈希值，防止明文存储"""
    return hashlib.sha256(password.encode()).hexdigest()

def register_user(username, password):
    """
    处理用户注册逻辑
    返回元组: (是否成功, 提示消息)
    """
    init_db()
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    pwd_hash = hash_password(password)
    try:
        # 尝试插入新用户
        cursor.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", (username, pwd_hash))
        conn.commit()
        return True, "注册成功！"
    except sqlite3.IntegrityError:
        return False, "该账户节点已被部署，换个名字试试吧"
    finally:
        conn.close()

def login_user(username, password):
    """
    处理用户登录逻辑
    返回元组: (是否成功, 提示消息/用户ID)
    """
    init_db()
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    pwd_hash = hash_password(password)
    # 根据用户名和加密后的密码进行查询
    cursor.execute("SELECT id FROM users WHERE username = ? AND password_hash = ?", (username, pwd_hash))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        return True, user[0]  # 登录成功，返回 True 和用户的数据库 ID
    else:
        return False, "接入密匙或用户名错误，握手失败"