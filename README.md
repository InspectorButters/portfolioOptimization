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

US Large Cap    (S&P 500 TR USD)  
US Mid Cap      (S&P 400 TR USD)  
US Small Cap    (S&P 600 TR USD)  
Canadian Equity (MSCI Canada GR USD)  
European Equity (MSCI AC Europe & Mid East GR USD)  
Developed Pacific (MSCI Pacific GR USD)  
Emerging Markets (MSCI Emerging Markets GR USD)  
Treasuries (Barclays US Treasury TR USD)  
Corporate (Barclays US Credit TR USD)  
Asset-backed (Barclays US Securitized TR USD)  

## Asset Class Selection

Asset class selection sought to achieve three goals: 1) each class is investable, 2) classes are mutually exclusive (no overlap), and 3) as collectively-exhaustive of the investable universe as possible.

## Known Issue

At the time of publication, the arrows (up & down) on the minimum %weight input did not populate on some versions of Internet Explorer. As a workaround, manually type the desired integer (1,2,3,4 or 5) in the input box.

## Special Thanks

Code made available by Druce Vertes, CFA, provided the optimization structures used in this application. See http://blog.streeteye.com/blog/2012/01/portfolio-optimization-and-efficient-frontiers-in-r/
