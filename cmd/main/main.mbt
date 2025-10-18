///|
async fn main {
  println("🚀 开始进行代码评审流程...")
  let (code, output) = @process.collect_stdout("git", ["diff", "HEAD~1", "HEAD"])
  if code != 0 {
    println("🚀 git 检出失败")
    return
  }
  let review = condeReview(output.text())
  guard review != "" else {
    println("评审失败")
    return
  }
  let content = @json.parse(review)
  .value("choices")
  .bind(_.item(0))
  .bind(_.value("message"))
  .bind(_.value("content"))
  .bind(_.as_string()) catch {
    (_ : @json.ParseError) => panic()
  }
  let url = "https://github.com/xuxubo/code-review.git"
  let token = "ghp_26Qh7hKuXlbud19OHv1m61qq" // ⚠️ 替换为实际 Token
  let repo_dir = "repo"

  // 克隆
  println("🚀 Cloning repo...")
  let repo = git_clone(url, repo_dir)
  println("✅ Cloned")
  let file_name = git_file_name()
  //日期目录
  //   let date_folder = "repo/2025-10-17"
  //   let _ = mkdir_p(date_folder)

  //写文件
  let file_path = "repo/" + file_name + ".md"
  let _ = write_file(file_path, content.to_string())
  println("✅ File written")

  // 添加 + 提交 + 推送
  let add_ok = git_add(repo, file_path)
  if add_ok == 0 {
    println("✅ Added file")
    let commit_ok = git_commit(repo, "Add new review via MoonBit")
    if commit_ok == 0 {
      println("✅ Committed")
      let push_ok = git_push(repo, "origin", token)
      if push_ok == 0 {
        println("✅ Pushed to GitHub")
      } else {
        println("❌ Push failed, code=\{push_ok}")
      }
    }
  } else {
    println("❌ Add failed")
  }
  println("✅ Repository freed")
  println("✨ Done.")
}

///|

///|
async test "get gitdiff" {
  let (code, output) = @process.collect_stdout("git", ["diff", "HEAD~1", "HEAD"])
  inspect(code, content="0")
  inspect(output.text(), content="abcd")
}

///|
test "send message API" {
  @mio.run(fn() {
    match (try? @mio.get("https://api.github.com")) {
      Ok(response) => {
        println("Status: " + response.statusCode.to_string())
        println("Response: " + response.text())
      }
      Err(e) => println("Error: " + e.to_string())
    }
  })
}

///|
test {
  let s =
    #|{
    #|  "id": "233a1c55-5183-47f3-a09a-f982aae6567e",
    #|  "object": "chat.completion",
    #|  "created": 1760360061,
    #|  "model": "deepseek-chat",
    #|  "choices": [
    #|    {
    #|      "index": 0,
    #|      "message": {
    #|        "role": "assistant",
    #|        "content": "你的内容..."
    #|      }
    #|    }
    #|  ],
    #|  "usage": {
    #|    "prompt_tokens": 191,
    #|    "completion_tokens": 515,
    #|    "total_tokens": 706
    #|  },
    #|  "system_fingerprint": "fp_ffc7281d48_prod0820_fp8_kvcache"
    #|}
  let response = @json.parse(s)
    .value("choices")
    .bind(_.item(0))
    .bind(_.value("message"))
    .bind(_.value("content"))
    .bind(_.as_string())
  println(response)
}
