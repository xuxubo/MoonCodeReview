# MoonCodeReview

🚀 **MoonCodeReview** 是一个基于 **MoonBit** 的自动化代码评审工具，能够：

- 自动获取 Git 仓库最新提交的 `git diff`
- 调用大语言模型（LLM）生成代码评审报告
- 自动将评审结果写入指定 GitHub 仓库的日志文件
- 支持微信通知，将评审结果推送给用户

充分利用 MoonBit 的 AI Agent 能力，实现更加模块化和易扩展的代码评审系统。

------

## 功能特点

- **LLM 智能评审**：支持智谱、OpenAI 等大模型，可根据 git diff 给出详细评审意见
- **自动化日志管理**：将评审结果按日期写入 GitHub 仓库，并自动 commit & push
- **微信通知**：通过企业微信模板消息推送评审结果
- **模块化设计**：分离 Git 操作、LLM 调用、日志写入、微信推送，易于扩展和维护

------

## 项目结构

```
moonbit-code-review/
├── moon.mod                   # MoonBit 项目配置
├── src/
│   ├── main.mbt               # 程序入口
│   ├── git_utils.mbt          # Git 操作相关函数
│   ├── llm_review.mbt         # LLM 调用逻辑
│   ├── log_writer.mbt         # 写日志并 push 到仓库
│   ├── wx_push.mbt            # 微信推送逻辑
│   └── utils.mbt              # 通用函数（HTTP、时间、格式化等）
```

------

## 环境依赖

- [MoonBit 语言](https://www.moonbitlang.com/) ≥ 0.15
- Git
- GitHub 账户（用于写日志）
- 企业微信应用（用于推送消息）

------

## 环境变量配置

在运行前，需要设置以下环境变量：

```bash
export GITHUB_TOKEN="你的 GitHub Token"
export OPENAI_API_KEY="你的 LLM API Key"
export WX_APPID="你的微信 AppID"
export WX_SECRET="你的微信 Secret"
```

------

## 安装与运行

1. 安装 MoonBit:

```bash
curl -fsSL https://moonbitlang.com/install.sh | bash
```

1. 克隆或下载项目：

```bash
git clone https://github.com/你的账号/mooncode-review.git
cd mooncode-review
```

1. 运行项目：

```bash
moon run src/main.mbt
```

执行后，程序会自动：

1. 获取最近一次 git 提交的 diff
2. 调用 LLM 生成代码评审
3. 写入 GitHub 日志仓库
4. 推送微信通知

------

## 扩展与定制

- 可替换 LLM 模型，只需修改 `src/llm_review.mbt` 中的模型配置
- 可更换日志仓库地址
- 可自定义微信通知模板

