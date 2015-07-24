## A basic statistics module written in Nim
## 
## This module includes some additional descriptive statistics that aren't 
## included in the standard math module. It also contains a small number of 
## statistical distributions.

# The MIT License (MIT)
#
# Copyright (c) 2015 Aaron Kehrer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

import algorithm
import math

const
  NAN = 0.0/0.0 ## floating point not a number (NaN)
  INF = 1.0/0.0 ## floating point infinity

## Some additional functions from math.h are needed that aren't included in the math module

proc c_isnan(x: float): int {.importc: "isnan", header: "<math.h>".}
  ## Returns non-zero if `x` is not a number

proc isNaN*(x: float): bool =
  ## Returns true if `x` is not a number (NaN)
  # Converts the integer result from `c_isnan` to a boolean
  if c_isnan(x) != 0: true
  else: false


proc c_isinf(x: float): int {.importc: "isinf", header: "<math.h>".}
  ## Returns non-zero if `x` is infinity

proc isInf*(x: float): bool =
  ## Reuturns `true` if `x` is infinity
  #Converts the integer result from `c_isinf` to a boolean
  if c_isinf(x) == 1: true
  else: false


proc erf*(x: float): float {.importc: "erf", header: "<math.h>".}
  ## Computes the error function (also called the Gauss error function)


proc erfc*(x: float): float {.importc: "erfc", header: "<math.h>".}
  ## Computes the complementary error function (also called the Gauss error function)


proc gamma*(x: float): float {.importc: "tgammaf", header: "<math.h>".}
  ## Computes the gamma function


proc beta*(x: float, y: float): float = 
  ## The beta function can be defined using the gamma function
  ##    beta = (gamma(x) * gamma(y)) / gamma(x+y)
  ## http://en.wikipedia.org/wiki/Beta_function
  result = (gamma(x) * gamma(y)) / gamma(x+y)


# TODO: The following procedures will probably need to be implemented to complete this module:
# Source <http://www.evanmiller.org/statistical-shortcomings-in-standard-math-libraries.html>
#
# incBeta - Regularized incomplete beta function
# incBetaInv - Inverse of incomplete beta integral
# incGamma - Regularized incomplete gamma integral
# incGammaComp - Complemented incomplete gamma integral
# incGammaCompInv - Inverse of complemented incomplete gamma integral
# jv - Bessel function of non-integer order


## These are some additional descriptive statistics not found in the math module

proc standardDeviation*(x: openArray[float]): float =
  ## Computes the standard deviation of `x`
  result = math.sqrt(math.variance(x))


proc unbiasedVariance*(x: openArray[float]): float {.cdecl, exportc: "unbiasedVariance", dynlib.} =
  ## Computes the unbiased estimate sample variance of `x`
  ## If the length of `x` is lest than 2, NaN is returned.
  result = 0.0
  var n = x.len
  var xbar = math.mean(x)
  var s2: float
  for i in x:
    s2 += math.pow((i - xbar), 2)
  result = 1/(n-1) * s2
  

proc median*(x: openArray[float]): float = 
  ## Computes the median of the elements in `x`. 
  ## If `x` is empty, NaN is returned.
  if x.len == 0:
    return NAN
  
  var sx = @x # convert to a sequence since sort() won't take an openArray
  sx.sort(system.cmp[float])
  
  if sx.len mod 2 == 0:
    var n1 = sx[(sx.len - 1) div 2]
    var n2 = sx[sx.len div 2]
    result = (n1 + n2) / 2.0
  else:
    result = sx[(sx.len - 1) div 2]


proc quantile*(x: openArray[float], frac: float): float = 
  ## Computes the quantile value of `x` determined by the fraction `frac`
  ## If `x` is empty, NaN is returned.
  ## `frac` must be between 0 and 1 so for the 25th quantile 
  ## the value should be 0.25, any other value returns `NaN`
  if x.len == 0:
    result = NAN  
  elif frac < 0.0 or frac > 1.0:
    result = NAN
  elif frac == 0.0:
    result = x.min
  else:
    var sx = @x # convert to a sequence since sort() won't take an openArray
    sx.sort(system.cmp[float])

    var n = sx.len - 1  # max index
    var i = int(math.floor(float(n) * frac))  # quantile index

    if i == n:
      result = sx[n]
    elif sx.len mod 2 == 0:
      # even length
      var n1 = sx[i]
      var n2 = sx[i+1]
      result = (n1 + n2) / 2.0
    else:
      # odd length
      result = sx[i]


proc skewness*(x: openArray[float]): float = 
  ## Computes the skewness of `x` as the adjusted Fisher-Pearson 
  ## standardized moment coefficient.
  ## If the length of `x` is lest than 3, NaN is returned.
  if x.len < 3:
    return NAN

  var xbar = math.mean(x)
  var n = float(x.len)

  var lhs = math.pow(n, 2) / ((n - 1.0) * (n - 2.0))
  var m3: float
  var s3: float

  for i in x:
    m3 += math.pow((i - xbar), 3)
    s3 += math.pow((i - xbar), 2)

  m3 *= 1/n
  s3 *= 1/(n-1)
  s3 = math.pow(s3, 3/2)

  result = lhs * m3 / s3


proc kurtosis*(x: openArray[float]): float = 
  ## Computes the population excess kurtosis using sample `x`.
  ## If the length of `x` is lest than 4, NaN is returned.
  if x.len < 4:
    return NAN

  var xbar = math.mean(x)
  var s = unbiasedVariance(x)
  var n = float(x.len)

  var lhs = ((n+1) * n) / ((n-1) * (n-2) * (n-3))
  var rhs = 3 * (math.pow((n-1), 2) / ((n-2) * (n-3)))

  var cen: float

  for i in x:
    cen += math.pow((i - xbar), 4)

  cen *= 1/math.pow(s, 2)

  result =  lhs * cen - rhs


## Gaussian (Normal) Distribution
## http://en.wikipedia.org/wiki/Normal_distribution
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3661.htm
type
  GaussDist* = object
    mu, sigma: float


proc NormDist*(): GaussDist = 
  ## A Normal Distribution is a special form of the Gaussian Distribution with
  ## mean 0.0 and standard deviation 1.0
  result.mu = 0.0
  result.sigma = 1.0


# TODO: Add inverse of Normal distribution prodedure
# https://en.wikipedia.org/wiki/Normal_distribution#Quantile_function

proc mean*(g: GaussDist): float =
  result = g.mu


proc median*(g: GaussDist): float = 
  result = g.mu


proc variance*(g: GaussDist): float = 
  result = math.pow(g.sigma, 2)
  

proc standardDeviation*(g: GaussDist): float = 
  result = g.sigma


proc skewness*(g: GaussDist): float = 
  result = 0.0


proc kurtosis*(g: GaussDist): float = 
  result = 0.0


proc pdf*(g: GaussDist, x: float): float = 
  var numer, denom: float

  numer = math.exp(-(math.pow((x - g.mu), 2)/(2 * math.pow(g.sigma, 2))))
  denom = g.sigma * math.sqrt(2 * math.PI)
  result = numer / denom


proc cdf*(g: GaussDist, x: float): float = 
  var z: float

  z = (x - g.mu) / (g.sigma * math.sqrt(2))
  result = 0.5 * (1 + erf(z))


## Uniform Distribution
## http://en.wikipedia.org/wiki/Uniform_distribution_%28continuous%29
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3662.htm
type
  UniformDist* = object
    a, b: float


proc mean*(u: UniformDist): float = 
  result = (u.a + u.b) / 2.0


proc median*(u: UniformDist): float = 
  result = (u.a + u.b) / 2.0


proc variance*(u: UniformDist): float =
  result = math.pow((u.b - u.a), 2) / 12


proc standardDeviation(u: UniformDist): float = 
  result = math.sqrt(u.variance)


proc pdf*(u: UniformDist, x: float): float = 
  if x < u.a or x > u.b:
    result = 0.0
  else:
    result = 1 / (u.b - u.a)


proc cdf*(u: UniformDist, x: float): float =
  if x < u.a:
    result = 0.0
  elif x >= u.b:
    result = 1.0
  else:
    result = (x - u.a) / (u.b - u.a)


## Chauchy Distribution
## http://en.wikipedia.org/wiki/Cauchy_distribution
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3663.htm

type
  ChauchyDist* = object
    t, s: float

proc mean*(c: ChauchyDist): float =
  ## The mean of the Chanchy distribution is undefined
  result = NAN


proc median*(c: ChauchyDist): float = 
  result = c.t


proc variance*(c: ChauchyDist): float =
  ## The variance of the Chauchy distribution is undefined
  result = NAN


proc standardDeviation*(c: ChauchyDist): float =
  ## The standard deviation Chauchy distribution is undefined
  result = NAN


proc pdf*(c: ChauchyDist, x: float): float = 
  result = c.s * math.PI * (1 + math.pow((x - c.t)/c.s, 2.0))
  result = 1.0 / result


proc cdf*(c: ChauchyDist, x: float): float = 
  result = math.arctan((x - c.t)/c.s) / math.PI
  result = result + 0.5


## Student's t-distribution
## http://en.wikipedia.org/wiki/Student%27s_t-distribution
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3664.htm

type
  StudentsTDist* = object
    nu: float


proc mean*(s: StudentsTDist): float = 
  if s.nu > 1.0:
    result = 0.0
  else:
    result =  NAN


proc median*(s: StudentsTDist): float = 
  result = 0.0


proc variance*(s: StudentsTDist): float = 
  if s.nu > 2.0:
    result = s.nu / (s.nu - 2.0)
  elif s.nu > 1.0 and s.nu <= 2.0:
    result = INF
  else:
    result = NAN


proc standardDeviation*(s: StudentsTDist): float = 
  if s.nu > 2.0:
    result = math.sqrt(s.nu / (s.nu - 2.0))
  elif s.nu > 1.0 and s.nu <= 2.0:
    result = INF
  else:
    result = NAN


proc pdf*(s: StudentsTDist, x: float): float = 
  result =  gamma((s.nu+1)/2.0)
  result = result / (math.sqrt(s.nu*math.PI) * gamma(s.nu/2.0))
  result = result * math.pow((1.0 + (math.pow(x, 2) / s.nu)), (-(s.nu+1.0)/2.0))


proc cfd*(s:StudentsTDist, x: float): float = 
  ## TODO: module needs a regularized incomplete beta function to calculate


## F Distribution
## http://en.wikipedia.org/wiki/F-distribution
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3665.htm

type 
  FDist* = object
    d1, d2: float


proc mean*(f: FDist): float =
  result = f.d2 / (f.d2 - 2.0)


proc variance*(f: FDist): float = 
  result = 2 * f.d2 * (f.d1 + f.d2 - 2) / (
    f.d1 * (math.pow((f.d2 - 2.0), 2.0) * (f.d2 - 4.0)))


proc standardDeviation*(f: FDist): float = 
  result = math.sqrt(f.variance)


proc pdf*(f: FDist, x: float): float = 
  var lhs, rhs: float

  lhs = 1 / (beta(f.d1/2.0, f.d2/2.0)) * math.pow((f.d1/f.d2), f.d1/2.0)
  rhs = math.pow(x, f.d1/2.0 - 1.0) * 
    math.pow((1.0 + f.d1/f.d2 * x), -((f.d1-f.d2)/2.0))

  result = lhs * rhs


proc cdf*(f: FDist, x: float): float = 
  ## TODO: module needs a regularized incomplete beta function to calculate


## Chi-Square Distribution
## http://en.wikipedia.org/wiki/Chi-squared_distribution
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3666.htm

type
  ChiSquareDist* = object
    nu: float


proc mean*(c: ChiSquareDist): float = 
  result = c.nu


proc median*(c: ChiSquareDist): float =
  ## NOTE: the median for a Chi-Square distribution is an approximate
  result = c.nu * math.pow((1.0 - 2.0 / (9.0 * c.nu)), 3.0)


proc variance*(c: ChiSquareDist): float = 
  result =  2.0 * c.nu


proc standardDeviation*(c: ChiSquareDist): float = 
  result = math.sqrt(variance(c))


proc pdf*(c: ChiSquareDist, x: float): float = 
  if x < 0.0:
    result = 0.0
  else:
    var numer, denom, nud2: float

    nud2 = c.nu/2.0
    numer = math.exp(-x / 2.0) * math.pow(x, nud2 - 1.0)
    denom = math.pow(2.0, nud2) * gamma(nud2)


proc cdf*(c: ChiSquareDist, x: float): float = 
  ## TODO: module needs a incomplete gamma function to calculate


## Exponential Distribution
## http://en.wikipedia.org/wiki/Exponential_distribution
## http://www.itl.nist.gov/div898/handbook/eda/section3/eda3667.htm

type
  ExpDist* = object
    mu, beta: float  ## location and scale parameters


proc StandardExpDist*(): ExpDist = 
  ## The Standard Exponential Distribution is a special form of the 
  ## Exponential Distribution with location 0.0 and scale 1.0
  result.mu = 0.0
  result.beta = 1.0


proc mean*(e: ExpDist): float = 
  result = e.beta


proc median*(e: ExpDist): float = 
  result = e.beta * math.ln(2.0)


proc variance*(e: ExpDist): float =
  math.pow(e.beta, 2.0)


proc standardDeviation*(e: ExpDist): float = 
  result = e.beta


proc pdf*(e: ExpDist, x: float): float = 
  result = 1.0 / e.beta * math.exp(-(x-e.mu) / e.beta)


proc cdf*(e: ExpDist, x: float): float = 
  result = 1.0 -  math.exp(-x / e.beta)


#*******************************************
# Run tests
# *******************************************
when isMainModule:
  # Setup some test data
  var data1: array[0..6, float]
  var data2: array[0..7, float]
  var data3 = newSeq[float]()
  var data4: array[1, float]
  var data5: array[2, float]
  data1 = [1.4, 3.6, 6.5, 9.3, 10.2, 15.1, 2.2]
  data2 = [1.4, 3.6, 6.5, 9.3, 10.2, 15.1, 2.2, 0.5]
  data4 = [2.3]
  data5 = [2.2, 2.5]
  
  # Test median()
  assert(abs(median(data1) - 6.5) < 1e-8)
  assert(abs(median(data2) - 5.05) < 1e-8)
  assert(isNaN(median(data3)))  # test an empty sequence
  assert(abs(median(data4) - 2.3) < 1e-8)
  assert(abs(median(data5) - 2.35) < 1e-8)  

  # Test quantile()
  assert(abs(quantile(data1, 0.5) - median(data1)) < 1e-8)
  assert(abs(quantile(data2, 0.5) - median(data2)) < 1e-8)
  assert(abs(quantile(data2, 0.75) - 9.75) < 1e-8)
  assert(abs(quantile(data2, 0.9) - 12.65) < 1e-8)
  assert(abs(quantile(data2, 0.1) - 0.95) < 1e-8)
  assert(quantile(data2, 1.0) == data2.max)
  assert(quantile(data2, 0.0) == data2.min)

  # Test skewness()
  assert(abs(skewness(data1) - 0.5658573331608636) < 1e-8)
  assert(abs(skewness(data2) - 0.678154254246652) < 1e-8)
  assert(isNaN(skewness(data3)))
  assert(isNaN(skewness(data4)))
  assert(isNaN(skewness(data5)))

  # Test kurtosis()
  assert(abs(kurtosis(data1)- -0.6022513181999382) < 1e-8)
  assert(abs(kurtosis(data2)- -0.5461679512306573) < 1e-8)
  assert(isNaN(kurtosis(data3)))
  assert(isNaN(kurtosis(data4)))
  assert(isNaN(kurtosis(data5)))
  
  # Test GaussDist
  var n = NormDist()
  var gnorm = GaussDist(mu: 0.0, sigma: 1.0)

  assert(n.mean == gnorm.mean)
  assert(n.median == gnorm.median)
  assert(n.standardDeviation == gnorm.standardDeviation)
  assert(n.variance == gnorm.variance)
  assert(abs(n.pdf(0.5) - 0.3520653267642995) < 1e-8)
  assert(abs(n.cdf(0.5) - 0.6914624612740131) < 1e-8)

  # Test UniformDist
  var u = UniformDist(a: 2.0, b: 3.0)

  assert(u.mean == 2.5)
  assert(u.median == u.mean)
  assert(u.variance == 1.0/12.0)
  assert(u.pdf(2.5) == 1.0)
  assert(u.pdf(1.0) == 0.0)
  assert(u.pdf(4.0) == 0.0)


# TODO: Added tests for ChauchyDist, StudentsTDist, FDist, ChiSquareDist & ExpDist

  echo "SUCCESS: Tests passed!"
  
  echo ""
  echo "Some Tests"
  echo "Data1      : "
  for j in (0..len(data1)-1):
      echo data1[j]
      
  echo ""  
  echo "Mean       : ",mean(data1)  
  echo "Median     : ",median(data1)
  echo "Variance   : ",variance(data1)
  echo "Kurtosis   : ",kurtosis(data1)
  echo "Std.Dev.   : ",standardDeviation(data1)
  
  echo ""
