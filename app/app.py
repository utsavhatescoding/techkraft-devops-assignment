import os

import psycopg2
from flask import Flask, jsonify, render_template


app = Flask(__name__)


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        database=os.getenv("POSTGRES_DB", "devopsdb"),
        user=os.getenv("POSTGRES_USER", "devopsuser"),
        password=os.getenv("POSTGRES_PASSWORD", "devopspass")
    )


def prepare_database():
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS visits (
            id INTEGER PRIMARY KEY,
            total INTEGER NOT NULL
        )
    """)

    cursor.execute("""
        INSERT INTO visits (id, total)
        VALUES (1, 0)
        ON CONFLICT (id) DO NOTHING
    """)

    connection.commit()
    cursor.close()
    connection.close()


@app.route("/")
def home():
    prepare_database()

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("""
        UPDATE visits
        SET total = total + 1
        WHERE id = 1
        RETURNING total
    """)

    visit_count = cursor.fetchone()[0]
    connection.commit()

    cursor.close()
    connection.close()

    return render_template("index.html", visit_count=visit_count)


@app.route("/health")
def health():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        connection.close()

        return jsonify({
            "application": "running",
            "database": "connected"
        }), 200

    except psycopg2.Error:
        return jsonify({
            "application": "running",
            "database": "disconnected"
        }), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
