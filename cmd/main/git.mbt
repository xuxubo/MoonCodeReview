///|

///|
#borrow(url, workdir)
extern "c" fn mb_git_clone(
  url : @native.Ptr[Byte],
  workdir : @native.Ptr[Byte],
) -> @native.Ptr[Byte] = "mb_git_clone"

///|
// 添加文件
#owned(filepath_bytes)
extern "C" fn mb_git_add(
  repo : @native.Ptr[Byte],
  filepath_bytes : @native.Ptr[Byte],
) -> Int = "mb_git_add"

///|
// 提交
#owned(message_bytes)
extern "C" fn mb_git_commit(
  repo : @native.Ptr[Byte],
  message_bytes : @native.Ptr[Byte],
) -> Int = "mb_git_commit"

///|
// 推送
#owned(remote_name_bytes, token_bytes)
extern "C" fn mb_git_push(
  repo : @native.Ptr[Byte],
  remote_name_bytes : @native.Ptr[Byte],
  token_bytes : @native.Ptr[Byte],
) -> Int = "mb_git_push"
// 释放 repo

///|
extern "C" fn mb_git_free(repo : @native.Ptr[Byte]) -> Unit = "mb_git_free"

///|
/// Make Dir
#borrow(dir)
extern "c" fn mb_mkdir_p(dir : @native.Ptr[Byte]) -> Int = "mb_mkdir_p"

///|
/// Write File
#borrow(path, content)
extern "c" fn mb_write_file(
  path : @native.Ptr[Byte],
  content : @native.Ptr[Byte],
) -> Int = "mb_write_file"

///|
/// 将 MoonBit String 转成 UTF-8 指针传给 C
fn str_to_ptr(s : String) -> @native.Ptr[Byte] {
  @native.unsafe_coerce(@encoding.encode(UTF8, s))
}

///|
/// 封装 Clone
fn git_clone(url : String, workdir : String) -> @native.Ptr[Byte] {
  mb_git_clone(str_to_ptr(url), str_to_ptr(workdir))
}

///|
/// 封装 Add
fn git_add(repo : @native.Ptr[Byte], filepath : String) -> Int {
  mb_git_add(repo, str_to_ptr(filepath))
}

///|
/// 封装 Commit
fn git_commit(repo : @native.Ptr[Byte], message : String) -> Int {
  mb_git_commit(repo, str_to_ptr(message))
}

///|
/// 封装 Push
pub fn git_push(
  repo : @native.Ptr[Byte],
  remote_name : String,
  token : String,
) -> Int {
  // 编码为 UTF-8 字节
  mb_git_push(repo, str_to_ptr(remote_name), str_to_ptr(token))
}

///|
/// 封装 Mkdir
fn mkdir_p(dir : String) -> Int {
  mb_mkdir_p(str_to_ptr(dir))
}

///|
/// 封装 Write File
fn write_file(path : String, content : String) -> Int {
  mb_write_file(str_to_ptr(path), str_to_ptr(content))
}

///|
fn git_free(repo : @native.Ptr[Byte]) -> Unit {
  mb_git_free(repo)
}
