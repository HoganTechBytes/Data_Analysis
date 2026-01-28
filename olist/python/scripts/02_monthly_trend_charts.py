# pylint: disable=invalid-name

"""
    Monthly Trend Charts (Olist)

    Reads CSV outputs from scripts/01_monthly_trend_pack.py and generates charts into:
    outputs/charts/
"""

from __future__ import annotations
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt


# ============================================================
# Path configuration
# Anchor all paths to this script location 
# ============================================================

SCRIPT_PATH = Path(__file__).resolve()

# .../olist/python
PROJECT_ROOT = SCRIPT_PATH.parents[1]

CSV_DIR = PROJECT_ROOT / 'outputs' / 'csv'
CHART_DIR = PROJECT_ROOT / 'outputs' / 'charts'


def ensure_dirs() -> None:
    """
        Ensure output chart directory exists.

        Creates:
        - outputs/charts

        :return: None
        :rtype: None
    """
    CHART_DIR.mkdir(parents=True, exist_ok=True)


def load_csv(name: str) -> pd.DataFrame:
    """
        Load a CSV from outputs/csv.

        :param name: CSV filename (e.g., '01_orders_per_month.csv')
        :type name: str
        :return: Loaded DataFrame
        :rtype: pd.DataFrame
        :raises FileNotFoundError: If the CSV does not exist
    """
    path = CSV_DIR / name
    if not path.exists():
        raise FileNotFoundError(
            f'Missing CSV: {path}. Run scripts/01_monthly_trend_pack.py first.'
        )

    return pd.read_csv(path)


def add_month(df: pd.DataFrame, col: str = 'purchase_month') -> pd.DataFrame:
    """
        Add a parsed datetime month column and sort by it.

        Creates a new column named `month` using the input month column in YYYY-MM form.
        This is used for consistent sorting and charting.

        :param df: Input DataFrame containing a YYYY-MM month column
        :type df: pd.DataFrame
        :param col: Name of the month column to parse
        :type col: str
        :return: Copy of the DataFrame with a parsed `month` column added
        :rtype: pd.DataFrame
    """

    out = df.copy()

    # Add a dummy day so pandas can parse YYYY-MM safely
    out['month'] = pd.to_datetime(out[col].astype(str) + '-01', errors='coerce')

    bad = int(out['month'].isna().sum())
    if bad:
        print(f"[QA WARNING] add_month: '{col}' produced {bad:,} unparsed month values")

    # Sort for stable charting
    out = out.sort_values('month', kind='mergesort')

    return out


def chart_revenue_per_month(df_rev: pd.DataFrame) -> Path:
    """
        Create and save a revenue-per-month line chart.

        :param df_rev: Revenue DataFrame containing 'month' and 'revenue'
        :type df_rev: pd.DataFrame
        :return: Path to the saved chart image
        :rtype: Path
    """

    required = ['month', 'revenue']
    missing = [c for c in required if c not in df_rev.columns]
    if missing:
        raise ValueError(f'df_rev missing required column: {missing}')
    
    out_path = CHART_DIR / '01_revenue_per_month.png'

    fig, ax = plt.subplots()
    ax.plot(df_rev['month'], df_rev['revenue'])
    ax.set_title('Revenue per Month (Delivered Orders)')
    ax.set_xlabel('Month')
    ax.set_ylabel('Revenue')

    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)

    print(f'Saved chart: {out_path}')
    return out_path


def main() -> None:
    """
        Load trend pack CSVs and print basic sanity info.

        :return: None
        :rtype: None
    """
    ensure_dirs()

    df_orders = load_csv('01_orders_per_month.csv')
    df_rev = load_csv('02_revenue_per_month.csv')
    df_review = load_csv('03_review_score_by_delivery.csv')
    df_late = load_csv('04_late_delivery_rate_by_month.csv')
    df_orders = add_month(df_orders)
    df_rev = add_month(df_rev)
    df_review = add_month(df_review)
    df_late = add_month(df_late)
    
    chart_revenue_per_month(df_rev)

    print('Loaded:')
    print('orders:', df_orders.shape, 'cols:', list(df_orders.columns))
    print('revenue:', df_rev.shape, 'cols:', list(df_rev.columns))
    print('review:', df_review.shape, 'cols:', list(df_review.columns))
    print('late:', df_late.shape, 'cols:', list(df_late.columns))

    print('\nMonth parse check (min/max):')
    print('orders:', df_orders['month'].min(), '→', df_orders['month'].max())
    print('revenue:', df_rev['month'].min(), '→', df_rev['month'].max())
    print('review:', df_review['month'].min(), '→', df_review['month'].max())
    print('late:', df_late['month'].min(), '→', df_late['month'].max())

    # Quick peek
    print('\nHead checks:')
    print(df_orders.head(2))
    print(df_rev.head(2))
    print(df_review.head(2))
    print(df_late.head(2))


if __name__ == '__main__':
    main()
