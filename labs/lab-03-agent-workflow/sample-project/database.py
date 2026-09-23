import sqlite3


class Database:
    def __init__(self, path):
        self.conn = sqlite3.connect(path)
        self.cursor = self.conn.cursor()

    def create_table(self, name, columns):
        cols = ", ".join(columns)
        self.cursor.execute(f"CREATE TABLE IF NOT EXISTS {name} ({cols})")
        self.conn.commit()

    # FIXME: vulnerable to SQL injection
    def insert(self, table, data):
        keys = ", ".join(data.keys())
        vals = ", ".join([f"'{v}'" for v in data.values()])
        self.cursor.execute(f"INSERT INTO {table} ({keys}) VALUES ({vals})")
        self.conn.commit()

    def query(self, sql):
        try:
            self.cursor.execute(sql)
            return self.cursor.fetchall()
        except Exception as e:
            print(f"Query failed: {e}")
            return []

    def close(self):
        self.conn.close()


def get_user_by_name(db, name):
    return db.query(f"SELECT * FROM users WHERE name = '{name}'")


def bulk_insert(db, table, records):
    for record in records:
        db.insert(table, record)


def export_to_dict(db, table):
    rows = db.query(f"SELECT * FROM {table}")
    result = []
    for row in rows:
        result.append(row)
    return result
