# MI-BCI-online
基于运动想象的在线脑机接口

## git 更新代码

**后续代码更新提交**

当你更新代码后，可以按照以下流程提交代码到 GitHub：

1. **查看当前仓库状态**

   ```bash
   git status
   ```

   这会显示哪些文件被修改、添加或删除。

2. **添加修改的文件**

   ```bash
   git add .
   ```

   或者只添加特定文件：

   ```bash
   git add filename.py
   ```

3. **提交代码**

   ```bash
   git commit -m "描述本次修改内容"
   ```

4. **推送到 GitHub**

   ```bash
   git push origin main
   ```

   这样你的代码就会更新到远程仓库。

------

**回退到某个版本**

Git 允许你回退到历史版本，具体方式如下：

**1. 查看提交历史**

```bash
git log --oneline
```

你会看到类似这样的输出：

```
a1b2c3d 修复数据处理 bug
f4e5d6c 添加新的特征提取方法
d7f8g9h 初始提交
```

每个提交都有一个唯一的哈希值（如 `a1b2c3d`）。

**2. 软回退（仅回退 commit，不影响代码文件）**

如果你只是想撤销 `git commit` 但不影响文件：

```bash
git reset --soft HEAD~1
```

这会回退到上一个提交，但文件的更改仍然保留，你可以重新提交。

**3. 硬回退（回退到某个版本，删除之后的提交记录）**

如果你想彻底回退到某个版本：

```bash
git reset --hard a1b2c3d
```

这会将你的仓库回退到 `a1b2c3d` 这个版本，所有之后的更改都会被删除。

**4. 回退到某个版本但保留更改**

如果你想回退，但希望保留代码变更：

```bash
git reset --mixed a1b2c3d
```

这样 Git 只回退 `commit`，但不会丢失代码，你可以重新修改并提交。

**5. 强制推送回退后的版本**

如果你已经推送到了远程仓库，并且想同步回退：

```bash
git push --force origin main
```

⚠ **注意**：强制推送会覆盖远程仓库，需谨慎操作。

------

**解决冲突**

当你在执行 `git pull` 时，如果本地修改与远程代码有冲突，你会看到类似这样的错误：

```
CONFLICT (content): Merge conflict in filename.py
Automatic merge failed; fix conflicts and then commit the result.
```

**1. 查看冲突文件**

```bash
git status
```

Git 会列出冲突的文件，例如：

```
both modified:   filename.py
```

**2. 手动解决冲突**

打开冲突的文件，会看到类似这样的内容：

```python
<<<<<<< HEAD
print("本地代码")
=======
print("远程代码")
>>>>>>> origin/main
```

- `HEAD` 部分是你本地的代码
- `origin/main` 是远程仓库的代码
- 你需要手动修改代码，保留正确的版本。

**3. 标记冲突已解决**

解决冲突后，运行：

```bash
git add filename.py
git commit -m "解决 filename.py 冲突"
```

**4. 继续合并**

如果是 `git pull` 触发的冲突，解决后执行：

```bash
git pull --rebase
```

然后再推送：

```bash
git push origin main
```

------

**2. 如果本地已经有仓库（更新代码）**

如果你已经在 `formal_project` 目录下，并且想同步远程仓库的最新代码：

```
bash


复制编辑
git pull origin main
```

这样，你本地的 `main` 分支就会获取并合并远程仓库的最新更新。

------

**3. 处理可能的冲突**

如果 `git pull` 失败，可能会遇到冲突。这时，你可以：

1. **查看冲突文件**：

   ```
   bash
   
   
   复制编辑
   git status
   ```

   Git 会显示哪些文件有冲突。

2. **手动解决冲突**： 打开有冲突的文件，手动修改冲突部分，然后运行：

   ```
   bash复制编辑git add .
   git commit -m "解决冲突"
   ```

3. **完成合并后推送**：

   ```
   bash
   
   
   复制编辑
   git push origin main
   ```
