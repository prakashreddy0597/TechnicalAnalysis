# Specification and output conventions

The supplied brief contains conflicts between formulas, prose and pseudocode. Required entry points below follow the **pseudocode**, with explicit guards for undefined cases. Instructor tests were not supplied; compatibility with undisclosed tests cannot be guaranteed. Standard alternatives are separately named in `variants.R`.

| Function | Required return | Convention |
|---|---|---|
| `sma(data, period)` | numeric, n-period+1 | Complete windows, no leading padding; missing window -> NA; n<period -> error. |
| `ema(data, period)` | numeric, n | First-price seed; multiplier 2/(period+1); n<period permitted; empty -> numeric(0). |
| `macd(data, short_period, long_period, signal_period)` | list: macd_line, signal_line, histogram | Own first-price-seeded EMA; all components length n. Period ordering is not imposed by the supplied template. |
| `stdev(data)` | numeric scalar | Population variance divided by n. Empty input rejected; singleton -> 0. |
| `linreg(regressionSource, regressionLength, regressionOffset)` | list: slope, intercept, predicted_values | Exact supplied start=max(1,n-L+offset), end=min(n,n-offset); local indices 1:m. Offset 0 may select L+1 points. Reversed windows and fewer than two points rejected. |
| `rsi(data, period)` | numeric, n | Literal pseudocode seeds first period changes and updates again with the last seeded change at index period+1. This differs from standard Wilder RSI. Leading period outputs NA; insufficient history all NA. Flat -> 50, all gains -> 100, all losses -> 0. |
| `stoch_rsi(data, period, k_period, d_period)` | list: k_line length n-k+1, d_line length n-k-d+2 | Literal global min/max normalization of nonmissing pseudocode RSI; then own SMA smoothing. Global normalization uses future data. Zero range -> NA. Smoothing windows too long -> error. |
| `crossover(arr1, arr2)` | character, n | Pseudocode: None initially, Up on > after <=; Down on < after >=; otherwise None. Prose instead specifies upward-only Boolean. |
| `crossunder(arr1, arr2)` | character, n | Pseudocode: None initially; True on < after >=, otherwise False. Prose instead specifies Boolean. |

Missing comparison values produce no event. Inputs must be plain real numeric vectors; periods must be finite positive integers. Infinite prices are rejected. SMA and cross functions accept NA; EMA, MACD, stdev, linreg and RSI reject missing input prices. SMA propagates missingness rather than silently changing a window's denominator.

## Standard / causal alternatives

- `rsi_wilder`: seeds once at period+1, then updates from period+2.
- `stoch_rsi_rolling`: standard RSI normalized over a trailing RSI window (`normalization_period=period`), then K and D smoothing; full-length date-aligned outputs.
- `crossover_logical` and `crossunder_logical`: logical event adapters, initially FALSE.

The trading demonstration uses standard Wilder RSI and never uses global-normalized StochRSI. Prefix tests verify the causal alternative stays unchanged when future prices are appended; a separate test demonstrates the primary StochRSI's future dependence.

The supplied StochRSI example has 10 prices but RSI period 14. It cannot produce meaningful RSI. With K=3,D=3 the implementation returns all-NA K length 8 and D length 6 rather than inventing values.
