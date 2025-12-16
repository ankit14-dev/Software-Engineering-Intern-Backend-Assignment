import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv("HOST"),
    database=os.getenv("DATABASE"),
    user=os.getenv("USER"),
    password=os.getenv("PASSWORD"),
    sslmode="require",
)

print("Connected to PostgreSQL/NeonDB")

cursor = conn.cursor()
cursor.execute("""SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';""")
print(cursor.fetchall())
cursor.close()
conn.close()