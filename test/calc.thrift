struct State {
  1: i32 last_result
  2: map<string,i32> vars
}

service Calc {
  i32 add(1: i32 lhs, 2: i32 rhs)
  i32 last_result()
  void store_vars(1: map<string,i32> vars)
  i32 get_var(1: string name)
  State get_state()
}
