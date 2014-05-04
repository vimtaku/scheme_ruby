
def repl
  prompt = '>>> '
  second_prompt = '> '
  while true
    print prompt
    line = gets or return
    while line.count('(') > line.count(')')
      print second_prompt
      next_line = gets or return
      line += next_line
    end

    redo if line =~ /\A\s*\z/m
    begin
      val = _eval(parse(line), $global_env)
    rescue Exception => e
      puts e.to_s
      redo
    end
    puts pp(val)
  end
end

def closure?(exp)
  exp[0] == :closure
end

def pp(exp)
  if exp.is_a?(Symbol) or num?(exp)
    exp.to_s
  elsif exp == nil
    'nil'
  elsif exp.is_a?(Array) and closure?(exp)
    parameter, body, env = exp[1], exp[2], exp[3]
    "(closure #{pp(parameter)} #{pp(body)})"
  elsif exp.is_a?(Array) and lambda?(exp)
    parameters, body = exp[1], exp[2]
    "(lambda #{pp(parameters)} #{pp(body)})"
  elsif exp.is_a?(Hash)
    if exp == $primitive_fun_env
      '*prinmitive_fun_env*'
    elsif exp == $boolean_env
      '*boolean_env*'
    elsif exp == $list_env
      '*list_env*'
    else
      '{' + exp.map{|k, v| pp(k) + ':' + pp(v)}.join(', ') + '}'
    end
  elsif exp.is_a?(Array)
    '(' + exp.map{|e| pp(e)}.join(', ') + ')'
  else
    exp.to_s
  end
end
