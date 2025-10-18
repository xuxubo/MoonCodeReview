///|
fn git_file_name() -> String {
  let localtime = (@env.now() / 1000).reinterpret_as_int64()
  let filename = try? @time.unix(
      localtime,
      nanosecond=1000,
      zone=@time.fixed_zone("BeiJing", 8 * 60 * 60),
    )
  match filename {
    Err(_) => localtime.to_string()
    Ok(_) => filename.to_string()
  }
}
