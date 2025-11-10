# Griffin Volatility Scanner

A powerful and visually intuitive volatility scanner for MetaTrader 5 (MT5), designed to detect **Bollinger Band Squeeze** states combined with **Keltner Channel** and **Moving Average Stack** alignment across multiple symbols and timeframes.

This tool helps traders identify potential breakout points and market direction by analyzing the interplay between volatility contraction/expansion and trend alignment.

## Features

- **Multi-Symbol & Multi-Timeframe Scanning:** Monitor multiple currency pairs and timeframes simultaneously.
- **Visual Squeeze States:** Color-coded cells for Squeeze, Expansion (Fire), and Contraction states.
- **MA Stack Alignment:** Option to check for bullish/bearish alignment of multiple moving averages.
- **Real-time Updates:** Dynamic refresh based on configurable intervals.
- **Customizable Parameters:** Adjust BB/Keltner settings, MA periods, and more.

## Installation

1. Download the source files:
   - `GriffinVolatilityScanner.mq5`
   - `GriffinVolatilityScannerPanel.mqh`
2. Place them in your MT5 `Experts` folder (e.g., `MQL5/Experts/`).
3. Compile the `.mq5` file in MetaEditor.
4. Attach the Expert Advisor to any chart in MT5.

## Usage

- Configure the input parameters in the EA settings:
  - **Panel Settings:** Position, symbol list, timeframe list.
  - **Bollinger & Keltner Settings:** Periods, deviations, multipliers.
  - **MA Stack Settings:** Periods, method, alignment thresholds.
- The panel will appear on your chart, displaying live squeeze analysis.

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the `LICENSE` file for more details.

> **Note:** This is a tool for analysis and education. Past performance is not indicative of future results. Trading involves risk. Please see the disclaimer in the source code.

## Contributing

Contributions are welcome! Feel free to fork the repository, submit issues, or create pull requests to improve functionality or documentation.

---

Made with ❤️ for the open-source trading community.