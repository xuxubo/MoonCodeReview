///|
fn condeReview(git_diff : String) -> String {
  let mut review = ""
  // ---- 构造请求 ----
  @mio.run(fn() {
    match
      (try? @mio.post(
        "https://api.deepseek.com/chat/completions",
        body="",
        data={
          "model": "deepseek-chat",
          "messages": [
            {
              "role": "system",
              "content": "你是一个高级编程架构师，精通各类场景方案、架构设计和编程语言。",
            },
            {
              "role": "user",
              "content": "请您根据git diff记录，对代码做出评审。代码如下:\n" +
              git_diff,
            },
          ],
          "stream": false,
        },
        headers={
          "Authorization": "Bearer ",
          "Content-Type": "application/json",
        },
      )) {
      Ok(response) =>
        //println("Status: " + response.statusCode.to_string())
        //println("代码评审结果：: " + response.text())
        review = response.text()
      Err(e) => println("Error: " + e.to_string())
    }
  })
  review
}
