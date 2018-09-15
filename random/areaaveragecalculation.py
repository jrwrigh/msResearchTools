from sympy import *
from sympy.abc import r, t

init_printing(use_unicode=True, wrap_line=True)
w = Symbol('w', positive=True)
v = Symbol('v', positive=True)
R = Symbol('R', positive=True)
U = Symbol('U', positive=True)

R = .0254
U = 40.197
w = 916.7

func = sqrt((w*r)**2 + v**2)*r

intfunc = integrate(integrate(func, (r, 0, R)), (t, 0, 2*pi))

finfunc = intfunc/(R**2*pi) - U

pprint(finfunc)

vafunc = solve(finfunc, v)

pprint(vafunc)

