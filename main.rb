
require './repl.rb'
require './interpreter.rb'

# exp = [[:lambda, [:x, :y], [:+, :x, :y]], 3, 2]
# p _eval(exp, $global_env)

# exp = [:let, [[:x, 3]],
#  [:let, [[:fun, [:lambda, [:y], [:+, :x, :y]]]],
#    [:+, [:fun, 1], [:fun, 2]]]]
# p _eval(exp, $global_env)


# exp = [:letrec,
#  [[:fact,
#    [:lambda, [:n],
#     [:if, [:<, :n, 1], 1, [:*, :n, [:fact, [:-, :n, 1]]]]
#    ]]],
#  [:fact, 3]]


# exp = [:define, [:length, :list],
#  [:if, [:null?, :list], 0,
#   [:+, [:length, [:cdr, :list]], 1]]]
# exp2 = [:length, [:list, 1, 2, 3, 4]]
# p _eval(exp, $global_env)
# p $global_env
# p _eval(exp2, $global_env)


# p _eval([:+, 1, 2, 4])
#

# exp = [[:lambda, [:x], [:cond,
#  [[:>, 1, :x], 1],
#  [[:>, 2, :x], 2],
#  [[:>, 3, :x], 3],
#  [:else, -1]]
# ], 1]
# p _eval(exp, $global_env)

_eval(parse('(define (length list) (if (null?,list) 0 (+ (length (cdr list)) 1)))'), $global_env)
#puts _eval(parse('(length (list 1 2 3))'), $global_env)

puts _eval(parse('(length (quote (1 2 3)))'), $global_env)

#p _eval(exp, $global_env)


#repl


