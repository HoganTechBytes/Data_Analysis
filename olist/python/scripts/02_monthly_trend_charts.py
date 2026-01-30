# pylint: disable=invalid-name,import-error

"""
    Monthly Trend Charts (Olist)

    Reads CSV outputs from scripts/01_monthly_trend_pack.py and generates charts into:
    outputs/charts/
"""

from __future__ import annotations
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt


# =====================================================================================
# Path configuration
# Anchor all paths to this script location
# =====================================================================================

SCRIPT_PATH = Path(__file__).resolve()

# .../olist/python
PROJECT_ROOT = SCRIPT_PATH.parents[1]

CSV_DIR = PROJECT_ROOT / 'outputs' / 'csv'
CHART_DIR = PROJECT_ROOT / 'outputs' / 'charts'
REPORT_PATH = PROJECT_ROOT / 'outputs' / 'trend_pack.md'


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


def add_month(
    df: pd.DataFrame,
    col: str = 'purchase_month',
    qa_notes: list[str] | None = None
) -> pd.DataFrame:
    """
        Add a parsed datetime month column and sort by it.

        Creates a new column named `month` using the input month column in YYYY-MM form.
        This is used for consistent sorting and charting.

        :param df: Input DataFrame containing a YYYY-MM month column
        :type df: pd.DataFrame
        :param col: Name of the month column to parse
        :type col: str
        :param qa_notes: Optional list to capture QA notes
        :type qa_notes: list[str] | None
        :return: Copy of the DataFrame with a parsed `month` column added
        :rtype: pd.DataFrame
    """

    out = df.copy()

    # Add a dummy day so pandas can parse YYYY-MM safely
    out['month'] = pd.to_datetime(out[col].astype(str) + '-01', errors='coerce')

    bad = int(out['month'].isna().sum())
    if bad:
        msg = f"[QA WARNING] add_month: '{col}' produced {bad:,} unparsed month values"
        print(msg)
        if qa_notes is not None:
            qa_notes.append(msg)

    # Sort for stable charting
    out = out.sort_values('month', kind='mergesort')

    return out


def chart_revenue_per_month(
    df_rev: pd.DataFrame,
    insights: list[str] | None = None
) -> Path:
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
        raise ValueError(f'df_rev missing required columns: {missing}')

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

    # Insight (so what)
    if insights is not None and not df_rev.empty:
        msg = (
            '[INSIGHT][revenue] Revenue is the north-star trend line. Interpret month-to-month '
            'changes alongside order volume and delivered rate to separate demand shifts from '
            'fulfillment issues.'
        )
        print(msg)
        insights.append(msg)
    return out_path


def chart_orders_and_delivery_rate(
    df_orders: pd.DataFrame,
    qa_notes: list[str],
    insights: list[str] | None = None
) -> Path:
    """
        Create and save a two-panel chart:
        1) total orders per month
        2) delivered rate (%) per month

        :param df_orders: Orders DataFrame containing 'month', 'total_orders', 'delivered_rate_pct'
        :type df_orders: pd.DataFrame
        :param qa_notes: QA notes accumulator
        :type qa_notes: list[str]
        :return: Path to the saved chart image
        :rtype: Path
    """

    required = ['month', 'total_orders', 'delivered_rate_pct']
    missing = [c for c in required if c not in df_orders.columns]
    if missing:
        raise ValueError(f'df_orders missing required columns: {missing}')

    # Filter out extremely sparse months (avoid misleading cliff-drops)
    df = df_orders.copy()
    df = df[df['total_orders'] >= 100]

    dropped = len(df_orders) - len(df)
    if dropped:
        msg = (
            f'[QA NOTE] orders chart: dropped {dropped} sparse month rows '
            '(total_orders < 100).'
        )
        print(msg)
        qa_notes.append(msg)

    out_path = CHART_DIR / '02_orders_and_delivered_rate.png'

    fig, (ax1, ax2) = plt.subplots(nrows=2, sharex=True)

    # Panel 1: Orders
    ax1.plot(df['month'], df['total_orders'])
    ax1.set_title('Orders per Month')
    ax1.set_ylabel('Total Orders')

    # Panel 2: Delivered rate
    ax2.plot(df['month'], df['delivered_rate_pct'])
    ax2.set_title('Delivered Rate per Month')
    ax2.set_ylabel('Delivered Rate (%)')
    ax2.set_xlabel('Month')
    ax2.set_ylim(0, 100)

    fig.suptitle('Orders and Delivery Performance (Monthly)', y=0.98)
    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)

    print(f'Saved chart: {out_path}')

    # Insight (so what)
    if insights is not None and not df.empty:
        msg = (
            '[INSIGHT][orders] If order volume holds steady but delivered rate drops, '
            'the story is likely operational (fulfillment/logistics) rather than demand.'
        )
        print(msg)
        insights.append(msg)
    return out_path


def chart_late_delivery_rate(
    df_late: pd.DataFrame,
    qa_notes: list[str],
    insights: list[str] | None = None
) -> Path:
    """
        Create and save a late-delivery-rate trend chart.

        :param df_late: DataFrame containing 'month', 'delivered_orders',
                        and 'late_delivery_rate_pct'
        :type df_late: pd.DataFrame
        :param qa_notes: QA notes accumulator
        :type qa_notes: list[str]
        :return: Path to the saved chart image
        :rtype: Path
    """

    required = ['month', 'delivered_orders', 'late_delivery_rate_pct']
    missing = [c for c in required if c not in df_late.columns]
    if missing:
        raise ValueError(f'df_late missing required columns: {missing}')

    # Filter extremely sparse months
    df = df_late.copy()
    df = df[df['delivered_orders'] >= 100]

    dropped = len(df_late) - len(df)
    if dropped:
        msg = (
            f'[QA NOTE] late delivery chart: dropped {dropped} sparse month rows '
            '(delivered_orders < 100).'
        )
        print(msg)
        qa_notes.append(msg)

    out_path = CHART_DIR / '03_late_delivery_rate.png'

    fig, ax = plt.subplots()
    ax.plot(df['month'], df['late_delivery_rate_pct'])
    ax.set_title('Late Delivery Rate per Month')
    ax.set_xlabel('Month')
    ax.set_ylabel('Late Delivery Rate (%)')
    ax.set_ylim(0, 100)

    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)

    print(f'Saved chart: {out_path}')

    # Insight (so what)
    if insights is not None and not df.empty:
        msg = (
            '[INSIGHT][late] Late delivery rate is a controllable experience metric. '
            'Sustained increases often precede weaker reviews and repeat-purchase risk, '
            'especially if concentrated in key sellers/categories.'
        )
        print(msg)
        insights.append(msg)
    return out_path


def chart_review_score_late_vs_on_time(
    df_review: pd.DataFrame,
    qa_notes: list[str],
    insights: list[str]
) -> Path:
    """
        Create and save a two-line chart comparing average review score:
        - on-time deliveries (is_late = 0)
        - late deliveries (is_late = 1)

        Uses only months where both groups have enough review volume for stability.

        :param df_review: Review DataFrame containing 'month', 'is_late',
                          'review_count', and 'avg_review_score'
        :type df_review: pd.DataFrame
        :param qa_notes: QA notes accumulator
        :type qa_notes: list[str]
        :param insights: Insights accumulator
        :type insights: list[str]
        :return: Path to the saved chart image
        :rtype: Path
    """

    required = ['month', 'is_late', 'review_count', 'avg_review_score']
    missing = [c for c in required if c not in df_review.columns]
    if missing:
        raise ValueError(f'df_review missing required columns: {missing}')

    # Pivot into two series: on-time and late
    pivot = df_review.pivot_table(
        index='month',
        columns='is_late',
        values=['avg_review_score', 'review_count'],
        aggfunc='first'
    )

    # Flatten columns for easier access (0 is on-time, 1 is late)
    pivot.columns = [f'{metric}_late_{int(is_late)}' for metric, is_late in pivot.columns]
    pivot = pivot.sort_index()

    # Require both groups to exist
    needed_cols = [
        'avg_review_score_late_0', 'avg_review_score_late_1',
        'review_count_late_0', 'review_count_late_1'
    ]
    missing2 = [c for c in needed_cols if c not in pivot.columns]
    if missing2:
        raise ValueError(f'review pivot missing required columns: {missing2}')

    # Filter out low-volume months for stability
    min_reviews = 30
    before = len(pivot)

    mask = (
        (pivot['review_count_late_0'] >= min_reviews) &
        (pivot['review_count_late_1'] >= min_reviews)
    )

    pivot2 = pivot[mask].copy()

    dropped = before - len(pivot2)
    if dropped:
        msg = (
            f'[QA NOTE] review score chart: dropped {dropped} months where either group '
            f'had review_count < {min_reviews}.'
        )
        print(msg)
        qa_notes.append(msg)

    out_path = CHART_DIR / '04_review_score_late_vs_on_time.png'

    fig, ax = plt.subplots()
    ax.plot(pivot2.index, pivot2['avg_review_score_late_0'], label='On-time')
    ax.plot(pivot2.index, pivot2['avg_review_score_late_1'], label='Late')

    ax.set_title('Average Review Score: Late vs On-time Deliveries')
    ax.set_xlabel('Month')
    ax.set_ylabel('Average Review Score')
    ax.set_ylim(1, 5)
    ax.legend()

    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)

    # =====================================================================================
    # Insight: review score gap
    # =====================================================================================

    if pivot2.empty:
        msg = (
            '[QA WARNING] review score chart: no months met stability threshold; '
            'skipping insight calc.'
        )
        print(msg)
        qa_notes.append(msg)
    else:
        pivot2['review_score_delta'] = (
            pivot2['avg_review_score_late_0'] -
            pivot2['avg_review_score_late_1']
        )

        avg_delta = pivot2['review_score_delta'].mean()
        min_delta = pivot2['review_score_delta'].min()
        max_delta = pivot2['review_score_delta'].max()

        insight = (
            f'[INSIGHT] Late deliveries score on average {avg_delta:.2f} points lower '
            'than on-time deliveries '
            f'(range {min_delta:.2f}-{max_delta:.2f}, across {len(pivot2)} stable months; '
            f'min_reviews={min_reviews}).'
        )
        print(insight)
        insights.append(insight)

    print(f'Saved chart: {out_path}')
    return out_path


def load_trend_pack_data(qa_notes: list[str]) -> dict[str, pd.DataFrame]:
    """
    Load trend pack CSVs and add the parsed month column.
    """
    data = {
        'orders': load_csv('01_orders_per_month.csv'),
        'revenue': load_csv('02_revenue_per_month.csv'),
        'review': load_csv('03_review_score_by_delivery.csv'),
        'late': load_csv('04_late_delivery_rate_by_month.csv')
    }

    for key, df in data.items():
        data[key] = add_month(df, qa_notes=qa_notes)

    return data


def build_trend_pack_report(
    thresholds: list[str],
    qa_notes: list[str],
    insights: list[str]
) -> list[str]:
    """
        Build the markdown report content for outputs/trend_pack.md.

        Keep it simple:
        - what we generated
        - what filters we used
        - what QA said
        - what we learned (so what)
    """

    lines: list[str] = []
    lines.append('# Olist Monthly Trend Pack')
    lines.append('')
    lines.append(
        'Monthly trend pack using the Olist dataset. The goal is simple: QA-checked metrics, '
        'clean charts, and clear, actionable takeaways.'
    )
    lines.append('')

    lines.append('## Executive Summary')
    if insights:
        for i in insights[:2]:
            lines.append(f'- {i}')
    else:
        lines.append('- (none)')
    lines.append('')

    lines.append('## Metric Definitions')
    lines.append('- **Revenue (delivered only):** Sum of payment value for delivered orders')
    lines.append('- **Delivered rate:** delivered_orders / total_orders')
    lines.append('- **Late delivery rate:** late_delivered_orders / delivered_orders (is_late=1)')
    lines.append('- **Review score (avg):** Average review score split into late vs on-time groups')
    lines.append('')

    lines.append('## Generated Charts')
    lines.append('- outputs/charts/01_revenue_per_month.png')
    lines.append('- outputs/charts/02_orders_and_delivered_rate.png')
    lines.append('- outputs/charts/03_late_delivery_rate.png')
    lines.append('- outputs/charts/04_review_score_late_vs_on_time.png')
    lines.append('')

    lines.append('## Thresholds / Filters')
    if thresholds:
        lines.extend([f'- {t}' for t in thresholds])
    else:
        lines.append('- (none)')
    lines.append('')

    lines.append('## QA Notes')
    if qa_notes:
        lines.extend([f'- {n}' for n in qa_notes])
    else:
        lines.append('- (none)')
    lines.append('')

    lines.append('# Chart Notes & Insights')
    lines.append('')

    def _insights_for(tag: str) -> list[str]:
        return [i for i in insights if f'[{tag}]' in i] if insights else []

    lines.append('## 01) Revenue per Month (Delivered Orders Only)')
    lines.append('**Chart:** outputs/charts/01_revenue_per_month.png  ')
    lines.append('**QA gate:** none (baseline visibility)')
    lines.append('')
    lines.append('**So what**')
    rev = _insights_for('revenue')
    if rev:
        for i in rev:
            lines.append(f'- {i}')
    else:
        lines.append('- (none)')
    lines.append('')
    lines.append('**Follow-up question**')
    lines.append('- If revenue changes, is it driven by order volume, average order value, '
                 'or payment mix?')
    lines.append('')

    lines.append('## 02) Orders per Month + Delivered Rate')
    lines.append('**Chart:** outputs/charts/02_orders_and_delivered_rate.png  ')
    lines.append('**QA gate:** total_orders >= 100')
    lines.append('')
    lines.append('**So what**')
    ords = _insights_for('orders')
    if ords:
        for i in ords:
            lines.append(f'- {i}')
    else:
        lines.append('- (none)')
    lines.append('')
    lines.append('**Follow-up question**')
    lines.append('- When delivered rate dips, are those months concentrated in certain seller '
                 'states or categories?')
    lines.append('')

    lines.append('## 03) Late Delivery Rate (Delivered Orders Only)')
    lines.append('**Chart:** outputs/charts/03_late_delivery_rate.png  ')
    lines.append('**QA gate:** delivered_orders >= 100')
    lines.append('')
    lines.append('**So what**')
    late = _insights_for('late')
    if late:
        for i in late:
            lines.append(f'- {i}')
    else:
        lines.append('- (none)')
    lines.append('')
    lines.append('**Follow-up question**')
    lines.append('- Are late deliveries driven by specific sellers, shipping distance, or '
                 'category handling time?')
    lines.append('')

    lines.append('## 04) Avg Review Score - Late vs On-Time')
    lines.append('**Chart:** outputs/charts/04_review_score_late_vs_on_time.png  ')
    lines.append('**QA gate:** min_reviews = 30 for both groups')
    lines.append('')
    lines.append('**So what**')
    review_ins = [
        i for i in insights
        if '[INSIGHT]' in i and '[revenue]' not in i and '[orders]' not in i and '[late]' not in i
    ]
    if review_ins:
        for i in review_ins:
            lines.append(f'- {i}')
    else:
        lines.append('- (none)')
    lines.append('')
    lines.append('**Follow-up question**')
    lines.append("- What's the review 'breakpoint' (e.g., after how many days late do reviews drop "
                 "sharply)?")
    lines.append('')

    lines.append('## Reproducibility')
    lines.append('- Source extract script: scripts/01_monthly_trend_pack.py')
    lines.append('- Chart + report generator: scripts/02_monthly_trend_charts.py')
    lines.append('- Outputs: outputs/charts/ and outputs/trend_pack.md')
    lines.append('')

    return lines

def write_trend_pack_report(lines: list[str]) -> None:
    """
        Write a simple markdown trend pack report to outputs/trend_pack.md

        return: None
        :rtype: None
    """

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text('\n'.join(lines).rstrip() + '\n', encoding='utf-8')


def main() -> None:
    """
        Load trend pack CSVs and print basic sanity info.

        :return: None
        :rtype: None
    """
    ensure_dirs()

    qa_notes: list[str] = []
    insights: list[str] = []
    thresholds: list[str] = []

    # df_orders = load_csv('01_orders_per_month.csv')
    # df_rev = load_csv('02_revenue_per_month.csv')
    # df_review = load_csv('03_review_score_by_delivery.csv')
    # df_late = load_csv('04_late_delivery_rate_by_month.csv')

    # df_orders = add_month(df_orders, qa_notes=qa_notes)
    # df_rev = add_month(df_rev, qa_notes=qa_notes)
    # df_review = add_month(df_review, qa_notes=qa_notes)
    # df_late = add_month(df_late, qa_notes=qa_notes)

    data = load_trend_pack_data(qa_notes)

    chart_revenue_per_month(data['revenue'], insights)

    thresholds.extend([
        'Orders chart: total_orders >= 100',
        'Late delivery chart: delivered_orders >= 100',
        'Review chart: min_reviews = 30 for both late/on-time',
        'Revenue chart: no min-volume filter applied',
    ])

    chart_orders_and_delivery_rate(data['orders'], qa_notes, insights)
    chart_late_delivery_rate(data['late'], qa_notes, insights)
    chart_review_score_late_vs_on_time(data['review'], qa_notes, insights)

    print('orders:', data['orders'].shape, 'cols:', list(data['orders'].columns))
    print('revenue:', data['revenue'].shape, 'cols:', list(data['revenue'].columns))
    print('review:', data['review'].shape, 'cols:', list(data['review'].columns))
    print('late:', data['late'].shape, 'cols:', list(data['late'].columns))

    print('\nMonth parse check (min/max):')
    print('orders:', data['orders']['month'].min(), '→', data['orders']['month'].max())
    print('revenue:', data['revenue']['month'].min(), '→', data['revenue']['month'].max())
    print('review:', data['review']['month'].min(), '→', data['review']['month'].max())
    print('late:', data['late']['month'].min(), '→', data['late']['month'].max())

    # =====================================================================================
    # Trend pack report (markdown)
    # =====================================================================================

    lines = build_trend_pack_report(thresholds, qa_notes, insights)
    write_trend_pack_report(lines)
    print(f'Saved report: {REPORT_PATH}')

    # Quick peek
    print('\nHead checks:')
    print(data['orders'].head(2))
    print(data['revenue'].head(2))
    print(data['review'].head(2))
    print(data['late'].head(2))



if __name__ == '__main__':
    main()
