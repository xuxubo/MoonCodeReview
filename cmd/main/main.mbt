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
  let reviewJson = @json.parse(review) catch {
    (_ : @json.ParseError) => panic()
  }
  let content = reviewJson
    .value("choices")
    .bind(_.item(0))
    .to_json()
    .value("message")
    .to_json()
    .value("content")
    .bind(_.as_string())
    .to_string()
  println(content)
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
