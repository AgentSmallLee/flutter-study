# setState 中"卸载旧的、创建新的"到底指什么？

## 背景：Flutter 的三棵树

| 树 | 作用 | 特点 |
|---|---|---|
| **Widget 树** | 配置描述（蓝图） | 轻量、不可变、每帧重建 |
| **Element 树** | 树的骨架、持有状态 | 复用、生命周期长 |
| **RenderObject 树** | 实际布局和绘制 | 重量级、复用 |

`setState` 触发的是 **Element 标脏 → rebuild**，rebuild 过程中会生成新的 Widget，然后拿新 Widget 和旧 Widget 做 diff。

---

## 核心结论

"卸载旧的、创建新的"指的是：

> 当新旧 Widget 的 **runtimeType 不同**，或者 **key 不同** 时，Flutter 认为这个位置的组件"不是同一个东西"，于是：
>
> 1. **卸载（deactivate/unmount）旧的 Element 及其对应的 RenderObject**
> 2. **用新 Widget 创建新的 Element 和新的 RenderObject**，插入到树中那个位置

---

## 具体卸载和创建了什么？

### 卸载（销毁）的东西
- 旧的 **Element**（调用 `deactivate` → `unmount`）
- Element 持有的 **State** 对象（如果是 StatefulElement，调用 `dispose`）
- 对应的 **RenderObject**（从渲染树移除）
- 该子树下的所有子孙 Element、State、RenderObject 也一并销毁

### 新建的东西
- 新 Widget 对应的 **Element**（调用 `inflateWidget`）
- 对应的 **RenderObject**（调用 `createRenderObject`，如果是 RenderObjectWidget）
- 如果是 StatefulWidget，还会创建新的 **State** 对象（调用 `createState`）

---

## 两种情况对比

```
情况 A：能复用（runtimeType + key 都相同）
  旧 Widget ── 旧 Element ── 旧 RenderObject
      ↓
  新 Widget     复用 ↑        更新配置（updateRenderObject）
  结果：Element 和 RenderObject 都保留，只更新属性


情况 B：不能复用（runtimeType 或 key 不同）
  旧 Widget ── 旧 Element ── 旧 RenderObject
                      ↓ 全部销毁卸载
  新 Widget ── 新 Element ── 新 RenderObject
                      ↑ 全部重新创建
  结果：整棵子树推倒重建
```

---

## 直观例子

### 例1：类型不同 → 不能复用

```dart
Widget build(BuildContext context) {
  if (_showText) {
    return Text('Hello');       // runtimeType = Text
  } else {
    return Container(height: 100); // runtimeType = Container
  }
}
```

`_showText` 切换时，`Text` 和 `Container` 的 runtimeType 不同 → **不能复用** → 整棵子树销毁重建。

### 例2：key 不同 → 不能复用（即使类型相同）

```dart
// 每次 build 都用不同的 key → 强制销毁重建
Text('Hello', key: ValueKey(_count))
```

---

## 总结表

| 能复用（canUpdate = true） | 不能复用（canUpdate = false） |
|---|---|
| runtimeType 相同 **且** key 相同 | runtimeType 不同 **或** key 不同 |
| 旧 Element **保留**，只更新配置 | 旧 Element **卸载销毁**，新建 Element |
| 旧 RenderObject **保留**，只更新属性 | 旧 RenderObject **销毁**，新建 RenderObject |
| State **保留**（Stateful 的核心意义） | State **销毁重建**，状态丢失 |

> **常见场景关联**：列表项加 key、条件渲染状态丢失、GlobalKey 跨父级移动等问题，本质都是 Element 复用判断（`canUpdate`）过不了，导致子树被推倒重建。

---

*出自《Flutter面试题大全.md》第 113 行扩展解读*
