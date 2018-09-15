from sympy import *
from sympy.abc import r, t, v, R

init_printing(use_unicode=False, wrap_line=False)
w = Symbol('w', positive=True)
func = sqrt((w*r)**2 + v**2)*r

integrate(func, (r, 0, R))