# pylint: disable=invalid-name

"""
    Monthly Trend Pack (Olist / MySQL)

    Runs 4 monthly trend queries against clean views and exports CSV outputs:
    1) orders per month
    2) revenue per month (delivered only)
    3) review score by delivery status (late vs on-time)
    4) late delivery rate by month (delivered only)

    Outputs:
    - outputs/csv/*.csv
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine


# ============================================================
# Path configuration
# Anchor all paths to this script location (VS Code / CLI safe)
# ============================================================

SCRIPT_PATH = Path(__file__).resolve()

# .../olist/python
PROJECT_ROOT = SCRIPT_PATH.parents[1]

OUTPUT_CSV_DIR = PROJECT_ROOT / 'outputs' / 'csv'
OUTPUT_CHARTS_DIR = PROJECT_ROOT / 'outputs' / 'charts'
ENV_PATH = PROJECT_ROOT / '.env'


def load_env() -> None:
    """
        Load environment variables required for database connectivity.

        Loads variables from the project's `.env` file if present.
        Falls back to the current working directory if `.env` is not found.

        Expected variables:
        - DB_HOST
        - DB_NAME
        - DB_USER
        - DB_PASSWORD

        :return: None
        :rtype: None
    """
    if ENV_PATH.exists():
        load_dotenv(ENV_PATH)
    else:
        # Fallback: load from current working directory if user runs from elsewhere
        load_dotenv()


def get_engine() -> Engine:
    """
        Create a SQLAlchemy engine for the Olist MySQL database.

        Uses PyMySQL as the driver and enables `pool_pre_ping` to reduce
        errors from stale connections.

        :return: SQLAlchemy Engine instance configured for MySQL
        :rtype: Engine
        :raises ValueError: If one or more required DB environment variables are missing
    """
    load_env()

    host = os.getenv('DB_HOST')
    db = os.getenv('DB_NAME')
    user = os.getenv('DB_USER')
    pwd = os.getenv('DB_PASSWORD')

    if not all([host, db, user, pwd]):
        raise ValueError(
            'Missing one or more DB env vars. Check .env for: '
            'DB_HOST, DB_NAME, DB_USER, DB_PASSWORD.'
        )

    # If your password contains special characters, consider URL-encoding it.
    url = f'mysql+pymysql://{user}:{pwd}@{host}/{db}'
    return create_engine(url, pool_pre_ping=True)


def run_query(engine: Engine, sql: str) -> pd.DataFrame:
    """
        Execute a SQL query and return results as a pandas DataFrame.

        :param engine: Active SQLAlchemy database engine
        :type engine: Engine
        :param sql: SQL query string to execute
        :type sql: str
        :return: Query results as a DataFrame
        :rtype: pd.DataFrame
    """
    with engine.connect() as conn:
        return pd.read_sql(text(sql), conn)


def ensure_out_dirs() -> None:
    """
        Ensure output directories exist.

        Creates:
        - outputs/csv
        - outputs/charts

        :return: None
        :rtype: None
    """
    OUTPUT_CSV_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_CHARTS_DIR.mkdir(parents=True, exist_ok=True)


def export_df(df: pd.DataFrame, filename: str) -> Path:
    """
        Export a DataFrame to outputs/csv and return the saved file path.

        :param df: DataFrame to export
        :type df: pd.DataFrame
        :param filename: Output CSV filename (e.g., '01_orders_per_month.csv')
        :type filename: str
        :return: Path to the saved CSV file
        :rtype: Path
    """
    out_path = OUTPUT_CSV_DIR / filename
    df.to_csv(out_path, index=False)
    print(f'Saved: {out_path}  ({len(df):,} rows)')
    return out_path


# ============================================================
# QA helpers
# Keep checks lightweight but meaningful (AI-resistant analytics)
# ============================================================

def qa_required_columns(df: pd.DataFrame, required: Iterable[str], label: str) -> None:
    """
        Validate that required columns exist in a DataFrame.

        Raises a ValueError if any expected columns are missing.
        Used to enforce schema consistency before downstream analysis.

        :param df: DataFrame to validate
        :type df: pd.DataFrame
        :param required: Required column names
        :type required: Iterable[str]
        :param label: Human-readable dataset label for logging
        :type label: str
        :return: None
        :rtype: None
        :raises ValueError: If one or more required columns are missing
    """
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f'[QA] {label}: missing required columns: {missing}')


def qa_no_nulls(df: pd.DataFrame, cols: Iterable[str], label: str) -> None:
    """
        Warn if NULLs exist in specified columns.

        This does not fail the pipeline; it prints a warning for manual review.

        :param df: DataFrame to validate
        :type df: pd.DataFrame
        :param cols: Column names to check for NULLs
        :type cols: Iterable[str]
        :param label: Human-readable dataset label for logging
        :type label: str
        :return: None
        :rtype: None
    """
    for c in cols:
        n = int(df[c].isna().sum())
        if n:
            print(f"[QA WARNING] {label}: column '{c}' has {n:,} NULLs")


def qa_unique_month(
    df: pd.DataFrame,
    month_col: str,
    label: str,
    extra_keys: list[str] | None = None
) -> None:
    """
        Warn if the expected grain appears duplicated.

        Checks for duplicates using:
        - month_col
        - plus any extra keys (e.g., ['is_late'])

        :param df: DataFrame to validate
        :type df: pd.DataFrame
        :param month_col: Month column name (expected YYYY-MM)
        :type month_col: str
        :param label: Human-readable dataset label for logging
        :type label: str
        :param extra_keys: Additional columns to include in the uniqueness check
        :type extra_keys: list[str] | None
        :return: None
        :rtype: None
    """
    keys = [month_col] + (extra_keys or [])
    dup = df.duplicated(subset=keys).sum()
    if dup:
        print(f'[QA WARNING] {label}: found {dup:,} duplicate rows by keys={keys}')


def qa_month_continuity(df: pd.DataFrame, month_col: str, label: str) -> None:
    """
        Warn if months have gaps (based on YYYY-MM).

        This is informational: gaps can be valid (sparse early data, filtered metrics).
        The purpose is to make missing periods explicit before charting.

        :param df: DataFrame to validate
        :type df: pd.DataFrame
        :param month_col: Month column name (expected YYYY-MM)
        :type month_col: str
        :param label: Human-readable dataset label for logging
        :type label: str
        :return: None
        :rtype: None
    """
    # Add a dummy day so pandas can parse YYYY-MM safely
    months = pd.to_datetime(df[month_col].astype(str) + '-01', errors='coerce').sort_values()
    months = months.dropna().drop_duplicates()

    if len(months) < 2:
        return

    diffs = months.diff().dropna()

    # A "normal" next month is ~28-31 days. Gaps > 35 days suggests missing months.
    gaps = diffs[diffs.dt.days > 35]
    if not gaps.empty:
        print(f'[QA WARNING] {label}: possible missing months (gaps detected):')
        for idx, delta in gaps.items():
            print(f'  gap before {months.loc[idx].date()} = {delta.days} days')


def qa_non_negative(df: pd.DataFrame, col: str, label: str) -> None:
    """
        Warn if a numeric column contains negative values.

        :param df: DataFrame to validate
        :type df: pd.DataFrame
        :param col: Column name to check
        :type col: str
        :param label: Human-readable dataset label for logging
        :type label: str
        :return: None
        :rtype: None
    """
    if col in df.columns:
        neg = (df[col] < 0).sum()
        if neg:
            print(f"[QA WARNING] {label}: '{col}' has {int(neg):,} negative values")


# ============================================================
# Pipeline entry point
# ============================================================

def main() -> None:
    """
        Execute the Monthly Trend Pack pipeline.

        Runs four monthly aggregation queries against clean Olist views,
        exports results to CSV, and performs lightweight QA checks:
        - required columns
        - NULL checks on key fields
        - uniqueness at expected grain
        - month continuity checks
        - non-negative numeric checks (where relevant)

        :return: None
        :rtype: None
    """
    ensure_out_dirs()
    engine = get_engine()

    # --------------------------------------------------------
    # 01) Orders per month
    # --------------------------------------------------------
    q_orders_per_month = """
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
        ROUND(
            100.0 * SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
            2
        ) AS delivered_rate_pct
    FROM v_orders_clean
    WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY purchase_month
    ORDER BY purchase_month;
    """
    df_orders = run_query(engine, q_orders_per_month)
    export_df(df_orders, '01_orders_per_month.csv')

    # --------------------------------------------------------
    # 02) Revenue per month (delivered only)
    # --------------------------------------------------------
    q_revenue_per_month = """
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        ROUND(SUM(p.payment_value), 2) AS revenue
    FROM v_orders_clean o
    JOIN v_payments_clean p
        ON p.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND o.order_status = 'delivered'
    GROUP BY purchase_month
    ORDER BY purchase_month;
    """
    df_rev = run_query(engine, q_revenue_per_month)
    export_df(df_rev, '02_revenue_per_month.csv')

    # --------------------------------------------------------
    # 03) Review score by delivery (late vs on-time)
    # --------------------------------------------------------
    q_review_by_delivery = """
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        o.is_late,
        COUNT(*) AS review_count,
        ROUND(AVG(r.review_score), 3) AS avg_review_score
    FROM v_orders_clean o
    JOIN v_reviews_clean r
        ON r.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND o.order_status = 'delivered'
      AND o.is_late IS NOT NULL
      AND r.review_score IS NOT NULL
    GROUP BY purchase_month, o.is_late
    ORDER BY purchase_month, o.is_late;
    """
    df_review = run_query(engine, q_review_by_delivery)
    export_df(df_review, '03_review_score_by_delivery.csv')

    # --------------------------------------------------------
    # 04) Late delivery rate by month (delivered only)
    # --------------------------------------------------------
    q_late_rate = """
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
        COUNT(*) AS delivered_orders,
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_delivered_orders,
        ROUND(
            100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
            2
        ) AS late_delivery_rate_pct
    FROM v_orders_clean
    WHERE order_purchase_timestamp IS NOT NULL
      AND order_status = 'delivered'
      AND is_late IS NOT NULL
    GROUP BY purchase_month
    ORDER BY purchase_month;
    """
    df_late = run_query(engine, q_late_rate)
    export_df(df_late, '04_late_delivery_rate_by_month.csv')

    # --------------------------------------------------------
    # QA checks (lightweight but meaningful)
    # --------------------------------------------------------
    print('\n--- QA checks ---')

    qa_required_columns(
        df_orders,
        ['purchase_month', 'total_orders', 'delivered_orders', 'delivered_rate_pct'],
        'orders/month'
    )
    qa_no_nulls(df_orders, ['purchase_month'], 'orders/month')
    qa_unique_month(df_orders, 'purchase_month', 'orders/month')
    qa_month_continuity(df_orders, 'purchase_month', 'orders/month')

    qa_required_columns(df_rev, ['purchase_month', 'revenue'], 'revenue/month')
    qa_no_nulls(df_rev, ['purchase_month', 'revenue'], 'revenue/month')
    qa_unique_month(df_rev, 'purchase_month', 'revenue/month')
    qa_month_continuity(df_rev, 'purchase_month', 'revenue/month')
    qa_non_negative(df_rev, 'revenue', 'revenue/month')

    qa_required_columns(
        df_review,
        ['purchase_month', 'is_late', 'review_count', 'avg_review_score'],
        'reviews late vs on-time'
    )
    qa_no_nulls(df_review, ['purchase_month', 'is_late'], 'reviews late vs on-time')
    qa_unique_month(df_review, 'purchase_month', 'reviews late vs on-time', extra_keys=['is_late'])
    qa_month_continuity(df_review, 'purchase_month', 'reviews late vs on-time')

    qa_required_columns(
        df_late,
        ['purchase_month', 'delivered_orders', 'late_delivered_orders', 'late_delivery_rate_pct'],
        'late rate/month'
    )
    qa_no_nulls(df_late, ['purchase_month'], 'late rate/month')
    qa_unique_month(df_late, 'purchase_month', 'late rate/month')
    qa_month_continuity(df_late, 'purchase_month', 'late rate/month')

    print('\nQA quick peek:')
    print(df_orders.head(3))
    print(df_rev.head(3))
    print(df_review.head(3))
    print(df_late.head(3))


if __name__ == '__main__':
    main()