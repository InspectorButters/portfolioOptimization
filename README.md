# portfolioOptimization
This program helps a user optimize investment asset allocation by maximizing expected return for a particular level of risk. The application is most helpful to users with basic knowledge of asset allocation/ diversification principles covered in Modern Portfolio Theory.

The application is deployed at https://herget.shinyapps.io/portOptimization/
  
## Using the Application

This web application allows the user to generate a 10-asset class (1) Efficient Frontier and (2) Transition Map.

**Expected Return Inputs**: Enter the expected annualized % return for each of the 10 asset classes in the provided slider inputs (from 0% to 30%)

**Minimum Class %Weight Constraint**: Defaulted at 0% (unconstrained), user can set minimum allocation for each class up to 5%

**Generate Button**: Click the button once all inputs are set.

Note that inputs are *not* reactive. No charts will be produced until the user clicks the "Generate" button.

## Output

On the first tab, the efficient frontier is charted using a set of "optimal" portfolios that produce the highest level of expected return at a particular level of risk.

On the second tab, the transition map displays the optimal portfolio composition, in terms of asset class percentage (y-axis), for a particular level of risk (x-axis).

## Investment Returns

Annual returns are from a 12-year period spanning 2004-2015. The following indices are proxies for asset class performance:

US Large Cap    S&P 500 TR USD
US Mid Cap      S&P 400 TR USD
US Small Cap    S&P 600 TR USD
