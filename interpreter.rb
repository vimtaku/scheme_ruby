$primitive_fun_env = {
  :+  => [:prim, lambda{|*args| args.inject(&:+)}],
  :-  => [:prim, lambda{|*args| args.inject(&:-)}],
  :*  => [:prim, lambda{|*args| args.inject(&:*)}],
  :>  => [:prim, lambda{|x, y| x > y  } ],
  :>= => [:prim, lambda{|x, y| x >= y } ],
  :<  => [:prim, lambda{|x, y| x < y  } ],
  :<= => [:prim, lambda{|x, y| x <= y } ],
  :== => [:prim, lambda{|x, y| x == y } ],
}
$boolean_env = {
  :true => true,
  :false => false,
}
$list_env = {
  :nil   => [],
  :null? => [:prim, lambda{|list| null?(list)} ],
  :cons  => [:prim, lambda{|a,b| cons(a,b)} ],
  :car   => [:prim, lambda{|list| car(list)}],
  :cdr   => [:prim, lambda{|list| cdr(list)} ],
  :list  => [:prim, lambda{|*list| list(*list)} ],
}
$global_env = [$list_env, $primitive_fun_env, $boolean_env]

def _eval(exp, env)
  if not list?(exp)
    if immediate_val?(exp)
      exp
    else
      lookup_var(exp, env)
    end
  else
    if special_form?(exp)
      eval_special_form(exp, env)
    else
      fun = _eval(car(exp), env)
      args = eval_list(cdr(exp), env)
      apply(fun, args)
    end
  end
end

def special_form?(exp)
  lambda?(exp) or let?(exp) or letrec?(exp) or if?(exp) or define?(exp) or cond?(exp) or quote?(exp)
end

def list?(exp)
  exp.is_a?(Array)
end
def lambda?(exp)
  exp[0] == :lambda
end
def let?(exp)
  exp[0] == :let
end
def letrec?(exp)
  exp[0] == :letrec
end
def if?(exp)
  exp[0] == :if
end
def define?(exp)
  exp[0] == :define
end
def cond?(exp)
  exp[0] == :cond
end
def quote?(exp)
  exp[0] == :quote
end

def eval_special_form(exp, env)
  if lambda?(exp)
    eval_lambda(exp, env)
  elsif let?(exp)
    eval_let(exp, env)
  elsif letrec?(exp)
    eval_letrec(exp, env)
  elsif if?(exp)
    eval_if(exp, env)
  elsif define?(exp)
    eval_define(exp, env)
  elsif cond?(exp)
    eval_cond(exp, env)
  elsif quote?(exp)
    eval_quote(exp, env)
  end
end


def eval_if(exp, env)
  cond, true_clause, false_clause = if_to_cond_true_false(exp)
  if _eval(cond, env)
    _eval(true_clause, env)
  else
    _eval(false_clause, env)
  end
end

def if_to_cond_true_false(exp)
  [exp[1], exp[2], exp[3]]
end


def lookup_primitive_fun(exp)
  $primitive_fun_env[exp]
end

def car(list)
  list[0]
end
def cdr(list)
  list[1..-1]
end

def list(*list)
  list
end

def eval_list(exp, env)
  exp.map{|e| _eval(e, env)}
end

def eval_define(exp, env)
  if define_with_parameter?(exp)
    var, val = define_with_parameter_var_val(exp)
  else
    var, val = define_var_val(exp)
  end
  var_ref = lookup_var_ref(var, env)
  if var_ref != nil
    var_ref[var] = _eval(val, env)
  else
    extend_env!([var], [_eval(val, env)], env)
  end
  nil
end

def eval_cond(exp, env)
  if_exp = cond_to_if( cdr(exp) )
  eval_if(if_exp, env)
end


def cond_to_if(cond_exp)
  if cond_exp == []
    ''
  else
    e = car(cond_exp)
    p, c = e[0], e[1]
    if p == :else
      p = :true
    end
    [:if, p, c, cond_to_if( cdr(cond_exp) ) ]
  end
end

def eval_quote(exp, env)
  car( cdr(exp) )
end


def define_with_parameter?(exp)
  list?(exp[1])
end

def define_with_parameter_var_val(exp)
  var = car(exp[1])
  parameters, body = cdr(exp[1]), exp[2]
  val = [:lambda, parameters, body]
  [var, val]
end

def define_var_val(exp)
  [exp[1], exp[2]]
end

def immediate_val?(exp)
  num?(exp)
end


def apply(fun, args)
  if primitive_fun?(fun)
    apply_primitive_fun(fun, args)
  else
    lambda_apply(fun, args)
  end
end

def primitive_fun?(exp)
  exp[0] == :prim
end

def apply_primitive_fun(fun, args)
  fun_val = fun[1]
  fun_val.call(*args)
end

def num?(exp)
  exp.is_a?(Numeric)
end

def lookup_var(var, env)
  alist = env.find{|alist| alist.key?(var)}
  if alist == nil
    raise "couldn't find value to variables:'#{var}'"
  end
  alist[var]
end

def lookup_var_ref(var, env)
  env.find{|alist| alist.key?(var)}
end


def extend_env(parameters, args, env)
  alist = parameters.zip(args)
  h = Hash.new
  alist.each { |k, v| h[k] = v }
  [h] + env
end
def extend_env!(parameters, args, env)
  alist = parameters.zip(args)
  h = Hash.new
  alist.each { |k, v| h[k] = v }
  env.unshift(h)
end

def eval_let(exp, env)
  parameters, args, body = let_to_parameters_args_body(exp)
  new_exp = [[:lambda, parameters, body]] + args
  _eval(new_exp, env)
end


def eval_letrec(exp, env)
  parameters, args, body = letrec_to_parameters_args_body(exp)
  tmp_env = Hash.new
  parameters.each do |parameter|
    tmp_env[parameter] = :dummy
  end
  ext_env = extend_env(tmp_env.keys(), tmp_env.values(), env)
  args_val = eval_list(args, ext_env)
  set_extend_env!(parameters, args_val, ext_env)
  new_exp = [[:lambda, parameters, body]] + args
  _eval(new_exp, ext_env)
end



def let_to_parameters_args_body(exp)
  [exp[1].map{|e| e[0]}, exp[1].map{|e| e[1]}, exp[2]]
end

def eval_lambda(exp, env)
  make_closure(exp, env)
end

def make_closure(exp, env)
  parameters, body = exp[1], exp[2]
  [:closure, parameters, body, env]
end

def lambda_apply(closure, args)
  parameters, body, env = closure_to_parameters_body_env(closure)
  new_env = extend_env(parameters, args, env)
  _eval(body, new_env)
end


def set_extend_env!(parameters, args_val, ext_env)
  parameters.zip(args_val).each do |parameter, arg_val|
    ext_env[0][parameter] = arg_val
  end
end

def letrec_to_parameters_args_body(exp)
  let_to_parameters_args_body(exp)
end


def closure_to_parameters_body_env(closure)
  [closure[1], closure[2], closure[3]]
end

def null?(list)
  list == []
end

def cons(a, b)
  if not list?(b)
    raise "sorry, we haven't implemented yet..."
  else
    [a] + b
  end
end

def parse(exp)
  program = exp.strip().
    gsub(/[a-zA-Z\+\-\*><=][0-9a-zA-Z\+\-=!*]*/, ':\\0').
    gsub(/\s+/, ', ').
    gsub(/\(/, '[').
    gsub(/\)/, ']')
  eval(program)
end

