// git_stub_fixed.c
#include <stdint.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#include <direct.h>
#define mkdir _mkdir
#else
#include <sys/stat.h>
#include <unistd.h>
#endif

#include <git2.h> // 必须放在 stdint.h 之后！

// ===================================================
// 工具函数：递归创建目录（跨平台安全版）
// ===================================================
static int mkdir_p(const char *dir)
{
    char tmp[1024];
    snprintf(tmp, sizeof(tmp), "%s", dir);

    for (char *p = tmp + 1; *p; p++)
    {
        if (*p == '/' || *p == '\\')
        {
            char old = *p;
            *p = '\0';
            mkdir(tmp, 0755);
            *p = old;
        }
    }
    return mkdir(tmp, 0755);
}

// ===================================================
// 写入文件
// ===================================================
int mb_write_file(const char *path, const char *content)
{
    FILE *f = fopen(path, "w");
    if (!f)
        return -1;
    size_t len = strlen(content);
    size_t written = fwrite(content, 1, len, f);
    fclose(f);
    return (written == len) ? 0 : -1;
}

// ===================================================
// 初始化与销毁：自动调用
// ===================================================
__attribute__((constructor)) static void init_git()
{
    git_libgit2_init();
}

__attribute__((destructor)) static void shutdown_git()
{
    git_libgit2_shutdown();
}

// ===================================================
// Git 封装函数
// ===================================================

// 克隆仓库，返回不透明指针
void *mb_git_clone(const unsigned char *url_bytes, const unsigned char *workdir_bytes)
{
    const char *url = (const char *)url_bytes;
    const char *workdir = (const char *)workdir_bytes;

    git_libgit2_init();

    git_repository *repo = NULL;
    git_clone_options opts;
    git_clone_options_init(&opts, GIT_CLONE_OPTIONS_VERSION);

    int err = git_clone(&repo, url, workdir, &opts);
    if (err != 0)
    {
        const git_error *e = git_error_last();
        fprintf(stderr, "[libgit2] git_clone failed: %d %s\n",
                err, e ? e->message : "unknown");
        git_libgit2_shutdown();
        return NULL;
    }

    git_libgit2_shutdown();
    return (void *)repo;
}

// 添加文件到索引
int mb_git_add(void *repo_ptr, const char *filepath)
{
    git_repository *repo = (git_repository *)repo_ptr;
    git_index *index = NULL;
    int err = git_repository_index(&index, repo);
    if (err != 0)
        return err;

    // 处理绝对路径 -> 相对路径
    const char *workdir = git_repository_workdir(repo);
    const char *relpath = filepath;
    if (workdir && strncmp(filepath, workdir, strlen(workdir)) == 0)
    {
        relpath = filepath + strlen(workdir);
    }

    err = git_index_add_bypath(index, relpath);
    if (err == 0)
        err = git_index_write(index);
    git_index_free(index);
    return err;
}

// 提交更改
int mb_git_commit(void *repo_ptr, const char *message)
{
    git_repository *repo = (git_repository *)repo_ptr;
    git_index *index = NULL;
    git_oid tree_id, commit_id;
    git_tree *tree = NULL;
    git_commit *parent = NULL;
    git_signature *sig = NULL;
    git_reference *head_ref = NULL;

    int err = git_repository_index(&index, repo);
    if (err != 0)
        goto cleanup;

    // 生成 tree
    err = git_index_write_tree(&tree_id, index);
    if (err != 0)
        goto cleanup;

    err = git_tree_lookup(&tree, repo, &tree_id);
    if (err != 0)
        goto cleanup;

    // 签名
    err = git_signature_now(&sig, "moonbot", "moonbot@example.com");
    if (err != 0)
        goto cleanup;

    // 尝试获取 HEAD 作为父提交
    err = git_repository_head(&head_ref, repo);
    if (err == 0)
    {
        git_commit_lookup(&parent, repo, git_reference_target(head_ref));
    }
    else if (err == GIT_ENOTFOUND || err == GIT_EUNBORNBRANCH)
    {
        parent = NULL; // 第一次提交
        err = 0;
    }
    else
        goto cleanup;

    // 创建提交
    err = git_commit_create(
        &commit_id,
        repo,
        "HEAD",
        sig, sig,
        NULL,
        message,
        tree,
        parent ? 1 : 0,
        parent ? (const git_commit **)&parent : NULL);

cleanup:
    if (sig)
        git_signature_free(sig);
    if (tree)
        git_tree_free(tree);
    if (parent)
        git_commit_free(parent);
    if (head_ref)
        git_reference_free(head_ref);
    if (index)
        git_index_free(index);
    return err;
}

// 释放仓库
void mb_git_free(void *repo_ptr)
{
    if (repo_ptr)
    {
        git_repository_free((git_repository *)repo_ptr);
    }
}

// 创建目录（供 MoonBit 调用）
int mb_mkdir_p(const char *dir)
{
    return mkdir_p(dir);
}

// 凭证回调函数（使用用户名 + token）
static int credentials_callback(git_cred **out,
                                const char *url,
                                const char *username_from_url,
                                unsigned int allowed_types,
                                void *payload)
{
    const char *token = (const char *)payload;
    // const char *username = username_from_url ? username_from_url : "git";
    return git_cred_userpass_plaintext_new(out, "x-access-token", token);
}

// 推送函数，不依赖 GitRepo 结构
int mb_git_push(void *repo_ptr,
                const char *remote_name,
                const char *token)
{
    if (!repo_ptr)
    {
        fprintf(stderr, "❌ Invalid repo pointer\n");
        return -1;
    }

    git_repository *repo = (git_repository *)repo_ptr;
    git_remote *remote = NULL;
    int error = git_remote_lookup(&remote, repo, remote_name);
    if (error < 0)
    {
        const git_error *e = git_error_last();
        fprintf(stderr, "❌ git_remote_lookup failed: %s\n", e ? e->message : "unknown");
        return error;
    }

    git_push_options opts;
    git_push_options_init(&opts, GIT_PUSH_OPTIONS_VERSION);
    opts.callbacks.credentials = credentials_callback;
    opts.callbacks.payload = (void *)token;

    // 检查当前分支（master 或 main）
    git_reference *head_ref = NULL;
    const char *branch_name = "main";
    if (git_repository_head(&head_ref, repo) == 0)
    {
        const char *name = NULL;
        git_branch_name(&name, head_ref);
        if (name)
            branch_name = name;
    }

    char refspec_str[128];
    snprintf(refspec_str, sizeof(refspec_str),
             "refs/heads/%s:refs/heads/%s", branch_name, branch_name);

    const char *refs[] = {refspec_str};
    git_strarray refspecs = {
        .strings = (char **)refs,
        .count = 1};

    printf("🚀 Pushing branch: %s\n", branch_name);

    error = git_remote_push(remote, &refspecs, &opts);
    if (error < 0)
    {
        const git_error *e = git_error_last();
        fprintf(stderr, "❌ git_remote_push failed: %s\n", e ? e->message : "unknown");
    }
    git_reference_free(head_ref);
    git_remote_free(remote);
    return error;
}
