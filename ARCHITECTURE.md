# 代码结构

`Desktop.ps1` 是入口，按固定顺序加载 `src/` 内脚本。Windows Forms 事件处理器共享应用状态，脚本使用 dot-source 加载。不要改成独立进程或普通函数作用域调用。

| 文件 | 职责 |
| --- | --- |
| Native.ps1 | DPI、窗口边缘缩放、重绘、勾选控件 |
| Bootstrap.ps1 | 单实例锁、读取本地数据、初始状态 |
| Ui.ps1 | 配色、字体、尺寸和通用控件 |
| Storage.ps1 | 原子保存、备份、课堂记录、草稿 |
| MainWindow.ps1 | 今日课程列表 |
| Editor.ps1 | 日期列表、笔记编辑、保存提示、侧窗动画 |
| Todos.ps1 | 待办勾选、选择和删除 |
| Archive.ps1 | 日期档案 |
| Menu.ps1 | 导入、主菜单、置顶、托盘 |
| Reminders.ps1 | 到期判断、提醒窗口 |
| Lifecycle.ps1 | 定时检查、窗口关闭、消息循环、资源释放 |

根目录 `CourseManager.ps1` 管理全部课程排序和课程待办入口；`Timetable.ps1` 展开教学周规则。保留它们在根目录，以兼容现有启动和数据路径。

`Launcher.cs` 构建为无控制台的 `ClassNote.exe`，调用 `Launch.ps1` 再加载入口。`Build.ps1` 负责构建。`generator/` 是无需服务器的浏览器 CSV 生成器。

数据根目录始终为 `$script:appRoot`，不随模块目录改变。不得提交 `data.json`、备份、个人课表规则或本机快捷方式。

## 回归检查

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File tests\Run-Smoke.ps1
node generator/test.cjs
```

桌面测试复制程序到独立临时目录，使用示例课程与独立互斥锁，不读写用户真实笔记。测试失败后的临时目录保留用于检查。人工验收重点：快速输入、屏幕缩放、连续拖动窗口、真实等待提醒和托盘恢复。
