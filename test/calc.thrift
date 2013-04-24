service Calc {
  i32 add(1: i32 lhs, 2: i32 rhs)
  i32 last_result()
  void store_vars(1: map<string,string> vars)
  i32 get_var(1: string name)
}
