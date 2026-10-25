# Dart 语言面试题大全

> 面向有 Android(Java/Kotlin)背景、正在求职 Flutter 岗位的候选人。覆盖 Dart 语言本身的几乎所有考察点,按主题分类,附详细答案与代码。

---

## 目录

1. [语言基础与编译模式](#一语言基础与编译模式)
2. [变量、常量与类型系统](#二变量常量与类型系统)
3. [空安全(Null Safety)](#三空安全null-safety)
4. [函数与闭包](#四函数与闭包)
5. [集合与函数式操作](#五集合与函数式操作)
6. [面向对象](#六面向对象)
7. [泛型](#七泛型)
8. [异常处理](#八异常处理)
9. [异步编程(重中之重)](#九异步编程)
10. [Isolate 与并发](#十isolate-与并发)
11. [内存管理与 GC](#十一内存管理与-gc)
12. [Dart 3 新特性](#十二dart-3-新特性)
13. [高频代码输出题](#十三高频代码输出题)
14. [对比类与开放性问题](#十四对比类与开放性问题)

---

## 一、语言基础与编译模式

### 1. Dart 语言有哪些特点?

- **强类型语言**,支持类型推断(`var`),2.12 起默认开启 **健全空安全(Sound Null Safety)**。
- **一切皆对象**:所有值都继承自 `Object`,包括数字字面量(`1` 是 `int` 的实例)。
- **单线程事件循环模型**(类似 JS),没有抢占式多线程,用 `Isolate` 做并发。
- **支持 JIT + AOT 双编译模式**:
  - **开发阶段(热重载)用 JIT**:`flutter run` 时以 JIT 运行,改动代码立即生效,配合热重载亚秒级看到效果。
  - **发布包用 AOT**:编译为本地机器码(ARM/x64),启动快、运行性能接近原生,没有运行时编译开销。
- 支持面向对象(类、Mixin、接口隐式实现)、泛型、闭包、运算符重载、反射(`dart:mirrors`,但 **Flutter 不支持**)。
- 自带 VM,可独立运行 Dart 脚本,也可编译为 JS(前端)。

### 2. JIT 和 AOT 分别是什么?Dart 为什么要同时支持?

| | JIT(Just-In-Time) | AOT(Ahead-Of-Time) |
|---|---|---|
| 时机 | 运行时逐段编译 | 编译期一次性编译为机器码 |
| 性能 | 启动慢、运行时需编译、有热路径优化(可达峰值性能高) | 启动快、运行稳定 |
| 典型场景 | 开发调试 + 热重载 | 发布上线 |

Dart 同时支持两者,是 Flutter "开发体验 + 线上性能"兼得的关键:JIT 支持亚秒级热重载;AOT 让线上包没有解析/编译开销,直接执行机器码,启动速度接近原生 App。

### 3. Dart 是单继承还是多继承?没有多继承用什么代替?

单继承(一个类只能 `extends` 一个父类)。多继承的能力通过 **Mixin(`with`)** 提供。Dart 3 后还可以声明专门的 `mixin class`(既是 mixin 又可被实例化/继承)。

### 4. Dart 中 `main` 函数是什么?可以带参数吗?

程序入口,必须有(库的顶层函数)。可以带参数:

```dart
void main(List<String> args) {
  print(args);
}
```

Flutter 中 `void main() => runApp(const MyApp());` 就是应用入口。

### 5. Dart 有哪些内建类型?

`num`(`int`、`double`)、`String`、`bool`、`List`(即数组)、`Set`、`Map`、`Runes`(Unicode 码点)、`Symbol`、`Null`。Dart 3 新增 `Record`。注意:`int` 在 VM 上是 64 位,在 **Web(JS)上是任意精度整数**;没有 8/16/32 位整型区分。

---

## 二、变量、常量与类型系统

### 1. `var`、`final`、`const` 的区别?(超高频)

```dart
var a = 10;        // 类型推断为 int,值可变
final b = 10;      // 运行时常量,只赋值一次,值不可变,引用不可重新指向
const c = 10;      // 编译期常量,编译时必须能确定值
```

核心区别:

- **`const` 是编译期常量**:值必须在编译时就确定。可以用于隐式类型标注(`const [1,2]` 是 `const List<int>`),可参与编译期优化(相同 const 值会被规范化/canonicalized 为同一对象,`identical` 为 true)。
- **`final` 是运行时常量**:可以在运行时赋值一次,例如 `final time = DateTime.now();`(用 const 则编译报错)。
- **类级别**:实例变量可以 `final`,不能 `const`;`const` 修饰的必须是编译期常量或常量构造(`const` constructor)创建的对象。

```dart
final list1 = [1, 2, 3];
const list2 = [1, 2, 3]; // 报错,应为 const [1,2,3]
list1[0] = 99;           // ✅ 允许!final 只锁"引用",不锁"内容"
```

加分点:`const [1,2,3]` 创建的列表是 **不可变的(immutable)**,调用 `list2.add` 会抛异常;`final [1,2,3]` 的列表内容仍可修改。

### 2. `dynamic`、`Object`、`var` 的区别?(超高频)

| | `var` | `Object` | `dynamic` |
|---|---|---|---|
| 声明后类型 | 编译期推断,确定后不可改 | 静态类型是 `Object` | 编译期关闭类型检查 |
| 访问成员 | 只能调用推断类型的方法 | 只能调用 `Object` 的成员,调用其他方法编译报错 | **任意调用都编译通过**,运行时才检查 |

```dart
dynamic d = 'hello';
d.foo();            // 编译通过,运行时抛 NoSuchMethodError
Object o = 'hello';
// o.length;        // 编译错误:Object 没有 length
(o as String).length; // OK
```

`dynamic` 本质是告诉编译器"跳过静态检查",错误全部推迟到运行时。安全替代:`Object` + 显式类型转换,或 `Object?` + 模式匹配。**反射/JSON 手动解析时才会用到 dynamic**。

### 3. `==` 和 `identical()` 的区别?

- `==` 是方法,默认继承自 `Object`,默认实现是比较身份(即 `identical`),但很多类型重写了它(String、int、List 等都是值比较)。
- `identical()` 是顶层函数,严格比较是否为**同一个对象**(同一内存地址)。

```dart
identical(const [1,2], const [1,2]); // true(const 规范化)
identical([1,2], [1,2]);             // false
'ab' == String.fromCharCodes([97,98]); // true(值相等)
```

追问:**自定义类怎么让 `==` 按值比较?** 重写 `==` 时必须同时重写 `hashCode`(保证 `a == b` ⇒ `a.hashCode == b.hashCode`),否则 HashMap/Set 行为异常。可以手写,也可以用 Dart 3 的 record 特性或重写为字段比较。

### 4. `is` 和 `as` 的区别?

- `is` 是类型判断,返回 bool;Dart 有**类型提升(type promotion)**:`if (a is String) print(a.length)` 中的 `a` 在分支内自动被当作 String。
- `as` 是强制类型转换,类型不符时抛 `_TypeError`。能用 `is` + 空安全判断就不要用 `as`。

注意:对可空类型做提升时,`is String` 不会把 `String?` 提升为 `String`(需要先判空);Dart 3 后用 `if (a is String)` 配合模式匹配可以同时对结构和类型解构。

### 5. 级联操作符 `..` 是什么?

对同一对象连续调用多个方法/设置属性而不必重复写对象名:

```dart
final paint = Paint()
  ..color = Colors.red
  ..strokeWidth = 2.0;
```

空安全版本:`?..`——对象为 null 时跳过整条级联。Flutter 布局代码大量使用。

### 6. `??`、`??=`、`?.` 分别是什么?

- `a ?? b`:a 为 null 时取 b。
- `a ??= b`:a 为 null 时才赋值为 b。
- `a?.b`:null-aware 成员访问,a 为 null 时整个表达式为 null。
- 还可以组合:`a?.b?.c`、`a?.method()`。

### 7. Dart 的字符串有哪些特性?

- 单/双引号皆可;三引号支持多行;`r''` raw 字符串(`\n` 不转义,常用于正则)。
- 字符串插值:`'sum: $a + $b = ${a + b}'`。
- **String 是不可变的**(immutable),任何"修改"操作都返回新对象。大量拼接应使用 `StringBuffer`。
- 相同内容的字符串字面量编译期会规范化,`'dart' == 'dart'` 且 `identical` 为 true(const 上下文)。

```dart
final sb = StringBuffer();
for (var i = 0; i < 1000; i++) sb.write(i); // 避免 1000 个中间字符串
```

### 8. Dart 支持 `switch` 吗?和 Java 有什么不同?

支持。Dart 3 之前 `switch` 是语句(statement),每个 case 必须 `break`(否则编译报错);Dart 3 之后支持 **switch 表达式** + **模式匹配**(见[第十二节](#十二dart-3-新特性)),case 可以是模式,不需要 break。

---

## 三、空安全(Null Safety)

### 1. 什么是健全空安全(Sound Null Safety)?

Dart 2.12 引入。核心规则:**除非显式声明可空类型(`?`),否则任何变量都不能为 null**。

- 编译期就把空指针风险隔离在类型系统里——`String` 永远不为 null,`String?` 才可能为 null。
- "健全(sound)" 意味着编译器可以据此做优化,不只是"提示":对非空类型直接访问成员不生成空检查代码。
- 三条关键约束:① 非空类型不能接收 null;② 可空类型访问成员前必须处理;③ 泛型 `List<String>` 中不能出现 null。

### 2. `late` 关键字的作用和风险?

`late` 修饰的变量表示"现在不是 null 风险问题,而是 **初始化时机** 问题"——变量类型非空,但不在声明处初始化:

```dart
class A {
  late String name; // 声明时不初始化,首次使用前必须赋值
  late final int x; // final 但延迟赋值,只能赋一次

  void init(String n) => name = n;
}
```

两种用法:
1. **延迟初始化**:运行时循环中赋值、Flutter 中 `late TextEditingController _c;` 在 `initState` 里赋值。
2. **惰性求值**:`late int x = expensive();` 声明时不执行,首次访问才执行赋值表达式(类似 Kotlin 的 `by lazy`,但每次访问前只执行一次)。

风险:未初始化就访问抛 `LateInitializationError`。滥用 `late` 会把空检查从编译期推迟到运行期,违背空安全初衷——能用构造函数初始化就用构造函数。

### 3. 空安全中的操作符汇总?

| 语法 | 含义 |
|---|---|
| `String?` | 可空类型 |
| `a!` | 断言非空(null 则运行时抛异常),尽量少用 |
| `a?.b` | null-aware 访问 |
| `a ?? b` | null 合并 |
| `a ??= b` | null 时赋值 |
| `a?..b()` | null-aware 级联 |
| `required` 命名参数必传(配合空安全) |

### 4. 函数参数的 `required` 和可空是什么关系?

命名参数默认是可选的;在空安全下,如果命名参数类型非空又没默认值,必须加 `required`,否则编译报错:

```dart
void register({required String name, int age = 18}) {}
// 或可空: void register({String? name})
```

### 5. 可空类型如何做类型提升?

- `String? s; s.length` 报错。要先 `if (s != null) s.length`,局部变量会自动提升。
- **成员变量/字段不会自动提升**(因为可能被其他代码改写),要 `s!`、局部变量接收、或用 `late`。
- Dart 3 可用 `switch (s) { case String s2: ... }` 或 `if (s case final s2?)` 模式匹配解构。

---

## 四、函数与闭包

### 1. Dart 函数的参数有哪些形式?(超高频)

```dart
// 1. 必填位置参数
void fn1(int a, int b) {}

// 2. 可选位置参数 [],只能放最后,可给默认值(默认值必须是编译期常量)
void fn2(int a, [int b = 0, int? c]) {}

// 3. 可选命名参数 {},调用时必须写参数名,Flutter 构造函数全是这种
void fn3(int a, {String? name, int age = 18}) {}
fn3(1, name: 'x', age: 20);

// 4. 必填命名参数 required
void fn4({required int a}) {}
```

要点:位置可选 `[]` 和命名可选 `{}` 不能同时出现;默认值必须是 `const`(不能写 `int b = DateTime.now()`);类型可空但需要默认值时用 `= null`。

### 2. 什么是闭包?Dart 中的典型应用?(超高频)

闭包 = 函数 + 其引用的外部变量(词法环境),函数返回后捕获的变量依然存活:

```dart
Function makeCounter() {
  var count = 0;
  return () => ++count; // 捕获了 count
}
final c1 = makeCounter();
c1(); // 1
c1(); // 2
final c2 = makeCounter();
c2(); // 1 —— 每次 makeCounter 产生独立的 count
```

关键结论:**闭包捕获的是变量本身(引用),不是当时的值**:

```dart
var list = [() => i, () => i, () => i];
for (var i = 0; i < 3; i++) {}
// 如果在循环里创建 () => i,三个闭包共享同一个 i
```

Dart 中闭包无处不在:回调(`onPressed`)、高阶集合操作、防抖节流封装、`State` 里捕获局部变量等。

**关联面试点:闭包可能导致内存泄漏**——闭包持有外部对象,若闭包被长生命周期对象持有(如全局监听器),外部对象无法被 GC。

### 3. 箭头函数 `=>` 和普通函数体?

`=> expr` 是 `{ return expr; }` 的简写,只能有一个表达式。注意 `=>` 不是返回值声明的类型。

### 4. 函数是一等公民吗?Function 类型和 typedef?

是。函数可以赋值给变量、作为参数、作为返回值。函数本身是 `Function` 类型的对象:

```dart
int add(int a, int b) => a + b;
var f = add;
Function(int, int) g = add;          // 泛型 Function 类型
int Function(int, int) h = add;      // 更精确的写法

// typedef 给函数签名起别名
typedef Calculator = int Function(int a, int b);
```

### 5. 匿名函数与 lambda?

`() => 1` 或 `(a, b) { return a + b; }`。匿名函数可以立即调用 `((){...})();`(常用于测试或隔离作用域)。

### 6. 什么是 callable 类?

实现 `call()` 方法的类实例可以像函数一样调用:

```dart
class Square {
  int call(int x) => x * x;
}
final s = Square();
print(s(5)); // 25
```

### 7. 函数命名参数使用时 Dart 如何提升传参体验?

同 1。补充:Flutter 的 Widget 参数几乎全是命名参数,为了阅读性——`Padding(padding: ..., child: ...)` 比 `Padding(padding, child)` 可读性强,这是语言设计有意为之。

---

## 五、集合与函数式操作

### 1. List、Set、Map 的核心特性?

- `List`:有序、可重复、按下标访问。`[]` 字面量默认 `List<dynamic>`(有类型参数时为对应类型),增长策略:内部是可增长的,容量不足按 ~1.5 倍扩容。
- `Set`:无序、不重复。字面量 `{1,2,3}` 默认是 `LinkedHashSet`(保持插入顺序);添加重复元素无效果。`Set.from(list)` 常用于去重。
- `Map`:`{key: value}` 字面量默认 `LinkedHashMap`,key 无序但保持插入序;key 不存在时 `map[k]` 返回 null(值类型自动为可空 `V?`),`putIfAbsent`/`update` 可操作。

追问:**HashMap 和 LinkedHashMap 区别?** LinkedHashMap 遍历顺序 = 插入顺序;HashMap 无此保证(顺序随 rehash 变化)。

### 2. 常用的函数式集合操作?(高频)

```dart
final nums = [1, 2, 3, 4];

nums.map((e) => e * 2).toList();   // 转换 [2,4,6,8]
nums.where((e) => e.isEven).toList(); // 过滤 [2,4]
nums.any((e) => e > 3);           // true 任一满足
nums.every((e) => e > 0);        // true 全部满足
nums.contains(2);                // 包含
nums.firstWhere((e) => e > 1);   // 首个满足,找不到抛异常(orElse 兜底)
nums.fold(0, (acc, e) => acc + e); // 10 累加,可自由指定返回类型
nums.reduce((a, b) => a + b);   // 10,元素间聚合,非空集合
nums.expand((e) => [e, e]);      // 展开 [1,1,2,2,3,3,4,4]
nums.take(2) / nums.skip(2);    // 取前 n 个 / 跳过 n 个
nums.forEach(...)                // 迭代
```

- `map/where` 等**返回惰性 Iterable**(不是 List!),不调用 `toList()`/遍历就不会执行。
- `fold` vs `reduce`:`fold` 有初始值且返回类型可不同;`reduce` 无初始值,返回类型必须与元素一致,空集合抛异常。

### 3. 展开操作符 `...` 和 `...?`

```dart
final a = [1, 2];
final b = [0, ...a, 3];      // [0,1,2,3]
List<int>? c;
final d = [0, ...?c];        // ...? 处理可能为 null 的集合,为 null 时跳过
```

### 4. 集合中的 if / for(collection-if/for)?

Dart 独有特性,集合字面量里可以直接写条件和循环,Flutter 布局大量使用:

```dart
final list = [
  'a',
  if (flag) 'b',
  for (var i in [1, 2]) 'item$i',
];
```

### 5. 怎么把集合变成不可变的?

```dart
final view = List.unmodifiable([1, 2, 3]); // 调用修改方法抛 UnsupportedError
// const [1,2,3] 也是深度不可变(编译期)
```

注意 `List.unmodifiable` 是包装视图,原 list 修改会反映到 view(它包装的是原集合的元素)。`const` 是深度不可变。

### 6. Map 遍历方式?

```dart
map.forEach((k, v) => ...);
for (final e in map.entries) { e.key; e.value; }
for (final k in map.keys) { ... }
```

---

## 六、面向对象

### 1. Dart 的构造函数有哪些?(超高频)

```dart
class Person {
  final String name;
  final int age;

  // 1. 默认构造函数:无参、无体;不写任何构造时自动提供;一经手写任何构造,默认构造消失
  Person(this.name, this.age);

  // 2. 命名构造函数:一个类可以有多个,弥补 Dart 没有构造重载
  Person.born() : this('baby', 0); // 常配合重定向构造
  Person.fromJson(Map<String, dynamic> json) : name = json['name'], age = json['age'];

  // 3. 初始化列表(冒号后、体之前):常用于 final 变量校验/计算
  Person.withCheck(String n, int a)
      : assert(a >= 0),
        name = n.toUpperCase(),
        age = a;

  // 4. 重定向构造函数:委托给其他构造
  Person.baby(String n) : this(n, 0);

  // 5. 常量构造函数:所有字段必须 final,用 const 调用可生成规范化常量
  const Person.constant(this.name, this.age);

  // 6. 工厂构造函数 factory:不必须返回新实例
  factory Person.create(String name) {
    return Person(name, 18);
  }
}
```

要点:
- 构造函数在 **基类之前不能直接访问 `this`**——所以参数要用 `super.name` 或初始化列表。
- 命名构造不能与默认构造冲突;构造不重载,靠命名构造实现"多构造"。

### 2. 工厂构造函数(factory)是什么?使用场景?(高频)

`factory` 修饰的构造函数**不必每次创建新实例**,可以返回缓存实例、子类实例、甚至单例:

```dart
class Logger {
  static final Map<String, Logger> _cache = {};
  final String tag;

  factory Logger(String tag) => _cache.putIfAbsent(tag, () => Logger._internal(tag));
  Logger._internal(this.tag);
}
```

典型场景:单例、缓存复用、根据入参返回子类型(如 `Shape.fromJson` 返回 Circle/Square)。

### 3. `factory` 和普通构造的区别?

| | 普通构造 | factory 构造 |
|---|---|---|
| 返回 | 必须返回当前类的新实例 | 可返回任意对象(含缓存、子类) |
| this | 初始化列表可用 this | 函数体内无 this |
| 用法 | 常规创建 | 单例/缓存/多态创建 |

### 4. Dart 的 Mixin 是什么?线性化顺序?(超高频)

`mixin` 是一种代码复用机制,"混入"而非继承——没有父类语义,解决了单继承下复用多个类能力的问题:

```dart
mixin Flyable {
  void fly() => print('flying');
}
mixin Swimmable {
  void swim() => print('swimming');
}
class Duck extends Animal with Flyable, Swimmable {}
```

**线性化(linearization)规则**:多个 mixin 有同名方法时,**最右边的(with 列表的最后一个)优先**。`class C extends A with M1, M2` 的方法查找顺序是 `C → M2 → M1 → A`,即后面的 mixin 覆盖前面的。

`on` 关键字约束 mixin 只能应用于特定类型(及其子类),从而在 mixin 内部安全使用父类成员:

```dart
mixin Logging on Widget { // 只能混入 Widget 子类,且能调用 Widget 的成员
  ...
}
```

### 5. `mixin` vs `abstract class` vs `interface`?

- **abstract class(抽象类)**:可有构造、字段、具体方法;用 `extends` 继承(单)或 `implements` 实现(全部成员待实现);不能实例化。
- **Dart 的接口是隐式的**:每个类都隐式定义了接口,`implements` 任何类都必须实现其**所有成员(包括具体方法)**——这和 Java 语义不同,和"继承"是两码事。
- **mixin**:用 `with` 混入,复用实现,不形成"是一个"关系,可混多个。

```dart
abstract class Animal { void eat(); }        // 抽象类
class Dog extends Animal { void eat() {} }   // 继承:复用实现
class Robot implements Animal { void eat() {} } // 实现:只拿"契约",全部自己实现
```

### 6. 什么是隐式接口?Dart 里 `implements` 一个有具体方法的类会怎样?

必须重新实现**所有**成员(包括字段对应的 getter/setter 和所有具体方法),否则编译报错。因此 Dart 中复用实现靠 `extends`/`with`,定义契约才用 `implements`。

### 7. getter/setter、运算符重载、call 重载

```dart
class Rectangle {
  double w, h;
  Rectangle(this.w, this.h);

  double get area => w * h;        // getter
  set width(double v) => w = v;    // setter

  Rectangle operator +(Rectangle o) => Rectangle(w + o.w, h + o.h); // 运算符重载

  int call() => 42;                // callable
}
```

### 8. `Extension` 是什么?(Dart 2.7+)

给已有类型(包括 String、第三方库类型)添加方法/属性,无需继承:

```dart
extension NumberParsing on String {
  int toIntOrZero() => int.tryParse(this) ?? 0;
}
'12ab'.toIntOrZero(); // 0
```

Dart 3.3+ 支持 `extension type`(零开销包装类型)。Flutter 源码大量使用 extension。

### 9. 枚举(enum)的特性?(Dart 2.17 增强)

Dart 3 后枚举是完整的类,可以有字段、构造、方法:

```dart
enum Status {
  initial,
  loading('加载中'),
  success;

  final String? label;
  const Status([this.label]);
}
```

配合 switch 表达式可以做到穷尽性检查。`values` 列出所有值,`.name`、`.index` 可用。

### 10. static 成员和顶层成员的区别?lazy static?

- `static` 成员属于类,通过类访问;Dart 的 static 变量是 **惰性初始化**的(首次访问才初始化),天然线程安全。
- 顶层函数/变量(不在任何类中)等价于全局函数/变量,Dart 风格上鼓励顶层函数(如 `main`)。

### 11. `covariant` 关键字是什么?

允许子类"收紧"方法参数类型(协变参数),以"牺牲静态类型安全换取运行时检查":

```dart
class Animal { void chase(Animal a) {} }
class Dog extends Animal {
  @override
  void chase(covariant Dog a) {} // 收窄为 Dog,运行时若传入非 Dog 会抛异常
}
```

常见于集合接口(`add(E)` 在 List 子类中收窄)。

---

## 七、泛型

### 1. Dart 泛型和 Java 泛型有什么区别?(高频,Android 背景必问)

- Java 是**类型擦除**的,运行时 `List<String>` 和 `List<Integer>` 都是 `List`;**Dart 泛型是具体化(reified)的,运行时保留类型信息**:`list is List<String>` 可以直接判断。对 Android 开发者是重大差异,面试常考。
- Dart 支持泛型约束 `extends`,方法级泛型 `T foo<T>(...)`。
- 协变行为:Dart 默认对泛型参数是协变的(`List<Cat>` 可以赋给 `List<Animal>`),通过运行时检查保证安全。

### 2. 泛型约束怎么写?

```dart
// T 必须是 num 或其子类
T sum<T extends num>(List<T> list) => list.reduce((a, b) => a + b);

// 多个约束
class A<T extends num & Comparable<T>> {}
```

### 3. 通配符怎么表达?

Dart 3 之前:`List<dynamic>`/`List<Object>`;`is List<String>` 判断实际类型。Dart 3 之后可以 `if (o case List _)`(`_` 通配符)。没有 Java 的 `? extends/super` 通配符语法。

### 4. 什么是类型提升?哪些情况不会提升?

见 [三-5](#三空安全null-safety)。补充:局部变量 `is` 判断、`!` 断言、赋值非空值会提升;字段、被闭包捕获且闭包内可变的局部变量不会自动提升。

---

## 八、异常处理

### 1. Dart 异常处理的语法?

```dart
try {
  throw FormatException('bad');
} on FormatException catch (e) {
  // 按"类型"捕获,可拿到异常对象 e,再用 e 里的信息
  rethrow; // 重新抛出
} on Exception {
  // 不需要异常对象时可以省略 catch (e)
} catch (e, s) {
  // e 是异常对象,s 是堆栈 StackTrace
} finally {
  // 总是执行
}
```

### 2. `Error` 和 `Exception` 的区别?

- **Exception** 可以捕获处理(`FormatException`、`IOException`),代表"可预期的问题"。
- **Error** 表示程序 bug,通常**不应该被捕获**(`RangeError`、`NoSuchMethodError`、`StateError`、`OutOfMemoryError`)。
- 任何非 null 对象都可以被 throw:`throw 'just a string'` 是合法的(不推荐)。

### 3. `rethrow` 和 `throw e` 的区别?

`rethrow` 保留原始堆栈;`throw e` 会重置堆栈起点为当前位置,调试时丢失信息。

### 4. finally 与 return 的执行顺序?

finally 总是执行;若 finally 中 `return`,会覆盖 try/catch 中的 return(Java 同理,应避免)。

### 5. 没有捕获的异常会怎样?

Dart VM 中未捕获异常会导致 isolate(应用)终止。Flutter 中 Zone(`runZonedGuarded`)和 `FlutterError.onError`/`PlatformDispatcher.instance.onError` 可以全局兜底做上报——这属于 Flutter 侧,但语言基础是异常沿调用栈向上传播。

---

## 九、异步编程

> 这是 Dart 面试的重中之重,几乎每场必问。

### 1. Dart 的事件循环模型?(超高频)

Dart 是**单线程**模型,每个 isolate 一个事件循环。异步任务进入两个队列:

- **Microtask Queue(微任务队列)**:由 `scheduleMicrotask()` 或已完成 Future 的回调产生。优先级最高。
- **Event Queue(事件队列)**:IO、手势、定时器(`Timer.run`/`Future.delayed`)、绘制、消息等。

每轮循环:
1. 执行当前同步代码(main 函数本身就是第一段同步任务);
2. **清空全部微任务队列**;
3. 取一个事件队列任务执行;
4. 执行后产生的微任务又会全部清空,再取下一个事件……即"每次事件之间把微任务清空"。

对比 JS:模型与 JS 一致,JS 里已完成的 Promise 是微任务,对应 Dart 的 Future。

### 2. Future、微任务、事件任务的执行顺序?(超高频手写题)

```dart
void main() {
  print('A');
  scheduleMicrotask(() => print('B'));      // 微任务
  Future(() => print('C'));                  // 事件队列
  Future.delayed(Duration.zero, () => print('D')); // 事件队列(排在未来)
  Future.value().then((_) => print('E'));   // 已完成的 future → then 回调进微任务
  print('F');
}
// 输出:A F E B C D
```

要点:
- **`Future.value().then` / `Future.then` 的回调在 Future 完成后进入微任务队列**(Dart 2 开始 then 回调走微任务调度)。
- `Future(() {...})` 构造的函数体进**事件队列**;`Future.delayed(zero, ...)` 同样进事件队列但优先级更靠后(先注册的 `Future()` 先执行)。
- 判断口诀:同步代码 → 微任务(全部) → 事件队列(先来先执行)。

**追问:为什么 E 输出在 B 前面?(都是微任务,谁先谁后?)**

`scheduleMicrotask` 和 `Future.value().then` 的回调虽然都属于微任务,但调度机制有区别:

1. **`scheduleMicrotask(() => print('B'))`**
   直接把回调放入**微任务队列末尾**,等待事件循环统一调度执行。

2. **`Future.value().then((_) => print('E'))`**
   `Future.value()` 创建的是一个**已同步完成**的 `_Future.immediate`。调用 `.then()` 注册回调时,因为 Future 已经是完成状态,Dart 内部会通过 `_propagateToListeners` 机制把 then 回调**立即调度为微任务**。

**E 比 B 先执行的原因:**
`Future.value()` 是同步完成的 Future,它的 then 回调走的是 Future 内部的"完成传播"链路(`_completeWithValue` → `_propagateToListeners`),回调在注册时就被标记为"待执行的微任务",插入到微任务调度的最前端。而 `scheduleMicrotask` 是用户手动追加到队列末尾的。

简单记:**已完成 Future 的 then 回调优先级 > 普通 scheduleMicrotask**。

> 💡 注意:核心考点是三层调度模型(同步 → 微任务 → 事件),E 和 B 都在微任务层、都在 C/D 之前,这是最重要的。两者的细微顺序属于进阶考点,不同 Dart 版本的实现可能略有差异。

### 3. `Future` 和 `async/await` 的关系?

`async` 标记函数为异步函数,返回值自动包装为 Future;`await` 挂起当前函数、注册后续代码为恢复回调,但不阻塞 isolate,事件循环继续处理其他任务:

```dart
Future<String> fetch() async {
  final res = await http.get(...); // 挂起,函数返回控制权给调用方
  return res.body; // await 后的代码相当于 then 回调
}
```

`await` 一个非 Future 值也合法(自动包装)。**async 函数中不用 await 则属于 unawaited**,建议显式 `unawaited(f)` 或加 linter 规则。

### 4. `await` 之间是串行还是并行?怎么并行?

顺序 `await` 是串行。并行方案:

```dart
// 1. Future.wait 并行
final results = await Future.wait([f1(), f2(), f3()]);

// 2. 先启动再 await(注意:Future 一创建就开始执行)
final f1 = fetchA();
final f2 = fetchB();
final a = await f1;
final b = await f2;

// 3. Future.any / Future.any
```

### 5. `Future` 的常用 API?

- `then(onValue, onError)`、`catchError`、`whenComplete`(类似 finally)、`timeout`(超时抛 TimeoutException)。
- `Future.wait(list)`:等全部完成,任一失败则整体失败。
- `Future.any(list)`:任一完成即完成。
- `Future.delayed`、`Future.value`、`Future.error`。
- `Future.forEach`、`Future.doWhile`。

### 6. Stream 是什么?和 Future 的关系?

- Future:0 或 1 个值,一次性;Stream:0 到 N 个值,随时间推送,本质是"异步的序列"。
- 两种订阅模式:**单订阅 Stream**(默认,只能被监听一次,监听时才开始生产,支持背压 pause/resume)和**广播 Stream**(`asBroadcastStream()` 或 `StreamController.broadcast()`,可多订阅、无背压)。

```dart
final stream = Stream.fromIterable([1, 2, 3]);
stream.listen((e) { ... }, onDone: ..., onError: ...);

// await for 循环消费,自动在完成时退出
await for (final e in stream) { ... }
```

### 7. Stream 的常用操作符?(和 Iterable 同构)

`map`、`where`、`take`、`skip`、`distinct`、`debounceTime`(rxdart)、`asyncExpand`、`transform`(配合 StreamTransformer)、`toList`/`first`/`last`(转回 Future)等。Flutter 中 `StreamBuilder`、Bloc、`State.stream` 等大量基于此。

### 8. StreamController / StreamSubscription / Completer?

- **StreamController**:既可创建 Stream 也可向其中添加事件(`add/addError/addDone`);`close()` 后不能再发。**用完必须 close,且订阅要 cancel,否则泄漏**。
- **StreamSubscription**:listen 的返回值,`pause()/resume()/cancel()`;不 cancel 是 Flutter 内存泄漏的经典来源。
- **Completer**:手动创建一个可以完成/失败的 Future:

```dart
final c = Completer<String>();
c.future.then(print);
c.complete('done');   // 或 c.completeError(e)
```

典型场景:把回调式 API(原生 MethodChannel、第三方 SDK 回调)转成 Future。

### 9. `async*`、`yield` 是什么?

生成器函数,返回 Stream,惰性生产:

```dart
Stream<int> counter() async* {
  for (var i = 0; i < 3; i++) {
    yield i; // 消费者处理完一个,才继续产下一个(背压)
  }
}
// 同步生成器:Iterable<int> gen() sync* { yield ...; }
```

`async*` 配合 `yield*` 可递归委托另一个 Stream。

### 10. async 函数中的异常怎么传播?

`await` 的 Future 失败会向上抛,在 async 函数内用 try/catch 捕获(比 then/catchError 更直观,是官方推荐写法)。注意:`then` 里抛出后 `catchError` 捕获,但 onValue 回调里抛出的也会被 catchError 接住——链式 API 语义容易踩坑。

### 11. `Isolate.run` 和 `compute`?(引到下一节)

复杂任务放后台 isolate:`await Isolate.run(() => heavyWork())`(Dart 2.19+,内置消息传递)。属于并发话题,详见下节。

### 12. 微任务什么时候主动用?

几乎不用。绝大多数场景 `Future` 足够;`scheduleMicrotask` 用于框架层,保证任务在本轮事件循环内、下一个事件前执行(例如 Flutter scheduler 内部、测试中强制 flush pending 任务)。

---

## 十、Isolate 与并发

### 1. Dart 为什么用 Isolate 而不是多线程?(超高频)

Dart 故意**没有共享内存的多线程**。理由:

- 单线程 + 事件循环 + 不可变消息传递 ⇒ **不需要锁,没有竞态条件、死锁**。
- 每个 Isolate 有独立内存堆和事件循环,之间只能通过**消息传递(Port)**通信;发送的对象默认是**拷贝**(深拷贝发送,部分原生类型如 TypedData 可 transfer 移交所有权,transfer 后原对象不可用)。
- UI 渲染跑在 root isolate,耗时操作会阻塞 UI,因此 CPU 密集任务要放新 isolate。

### 2. Isolate 和线程的区别?

| | Thread | Isolate |
|---|---|---|
| 内存 | 共享同一进程内存 | 各自独立堆 |
| 通信 | 直接读写 + 锁 | 消息拷贝传递(ReceivePort/SendPort) |
| 数据竞争 | 有,需同步原语 | 无,天然隔离 |
| 一个崩溃影响 | 整个进程 | 单个 isolate(未捕获异常只终止该 isolate) |

### 3. 怎么创建和使用 Isolate?

```dart
// Dart 2.19+ 推荐:一步到位
final result = await Isolate.run(() => heavyCompute(input));

// 底层 API:
Isolate.spawn(entryPoint, message); // 新 isolate 从入口函数开始
```

`Isolate.run` 内部做了 spawn + 消息回传 + isolate 自动关闭的完整封装。

### 4. isolate 之间怎么通信?

```dart
import 'dart:isolate';

Future<void> main() async {
  final receive = ReceivePort();
  await Isolate.spawn((SendPort sendPort) {
    // 子 isolate:干完活把结果发回去
    sendPort.send(heavyWork());
  }, receive.sendPort);
  final result = await receive.first as int;
}
```

- `SendPort` 可以跨 isolate 传递,是通信句柄;`ReceivePort` 本身是 Stream,可以 listen。
- Flutter 里 `compute(function, arg)` 封装了同样的模式,一次性后台计算最常用。

### 5. 所有类型都能在 isolate 间传递吗?

- 可传递:基本类型、不可变对象、大多数普通对象(发送时拷贝)、SendPort、TypedData(可 TransferableTypedData 移交)。
- **不可传递(会抛异常)**:含原生资源的对象(Socket)、ReceivePort、DynamicLibrary、Finalizable,以及**闭包中捕获了不可发送对象的闭包**(常见坑:`Isolate.run(() => useDartObject())` 中若闭包捕获了不可发送对象就报错)。
- isolate 退出时其持有的资源被整体回收,无锁开销。

### 6. 单 isolate 模型下,一个异步网络请求的原理是什么?(高频)

网络请求是异步 IO:调用底层 IO 后 Future 立刻返回控制权,IO 由 VM 的 IO 线程池(系统级线程)处理,完成后事件进入事件队列,由事件循环恢复 await 后的代码。**Dart 单线程指 Dart 代码单线程,底层 IO/IO线程是并行的**。所以耗时 IO 不会卡 UI,纯 CPU 计算才会(需要 isolate)。

### 7. isolate 可以访问 Flutter 的 Widget/插件吗?

后台 isolate 不能直接用平台插件(平台通道默认只注册给 root isolate)。方案:`BackgroundIsolateBinaryMessenger`(Flutter 3.7+ 让后台 isolate 也能用平台通道),或仅在 root isolate 使用插件、把纯计算传给后台 isolate。

---

## 十一、内存管理与 GC

### 1. Dart 的 GC 机制?(高频)

Dart VM 使用**分代式 GC**:

- **新生代(Young Generation)**:采用 **Scavenge 算法**(半空间复制:Cheney 扫描)。新对象分配在新生代,复制存活对象到另一半空间,存活一两轮后晋升老年代。速度快、适合"朝生夕死"的 UI 对象(每帧新建大量 Widget),但空间利用率 ~50%。
- **老年代(Old Generation)**:采用 **标记-清除(Mark-Sweep)** + 标记-压缩(碎片化整理)。全量 GC 会扫描大对象,量大时有可感知的停顿,Flutter 通过调度把老年代 GC 安排在空闲帧,尽量避免影响渲染。

加分:对象晋升经历两次 scavenge;Dart 2.x 之后 VM 优化了暂停时间(大多数 GC < 2ms)。Flutter 的 const、不可变数据、外部内存(图片)释放等也与 GC 相关:图片像素内存不属于 Dart 堆,需框架层释放。

### 2. 常见的 Dart 内存泄漏场景?(高频)

1. **Stream/StreamController 未关闭**:listen 后不 cancel、controller 不 close,发布方持有订阅者 → 泄漏。
2. **闭包持有**:长生命周期对象注册的回调捕获了大对象(如全局 EventBus 持有 State 方法)。
3. **Timer 未取消**:`Timer.periodic` 在 State 销毁后仍持有回调。
4. **全局 Map 缓存只增不减**。
5. **Future 完成前页面销毁**:不会自动取消(没有 await 的引用仍执行完,但结果若被持有就延长生命周期)。

规避:State `dispose()` 中 `subscription.cancel()`、`controller.close()`、`timer.cancel()`;组件用 `if (mounted)` 守卫。

### 3. Dart 有析构函数吗?怎么释放资源?

没有析构函数(Deterministic finalization 不支持),`@override void dispose()` 只是普通方法,**必须手动调用**(State 生命周期由框架调用)。没有 `Object.finalize`(Dart 3 中 Finalizable + `nativeFinalizer`/`attach` 可绑定原生资源,场景较少)。

### 4. 常量(const)为什么能提升性能?

1. **编译期规范化**:相同 const 表达式全程序是同一个对象,节省内存且 `identical` 为 true。
2. Flutter Widget 用 const 构造时,父 Widget rebuild 时 **const 子树直接复用,跳过重建和 diff**,这是 Flutter 性能优化第一守则(列表项、标题等静态 UI)。
3. 消除运行时分配与 GC 压力。

---

## 十二、Dart 3 新特性

### 1. Records(记录类型)

匿名、不可变的聚合值(类似 Kotlin 的 data class 或元组):

```dart
(String, int) userInfo() => ('Tom', 18);
final (name, age) = userInfo();       // 解构
final record = (x: 1, y: 2);          // 命名字段,record.x
```

用途:函数多返回值、替代一次性 model 类、`record ==` 按字段比较(可用来快速实现值语义)。

### 2. Patterns(模式匹配)

```dart
// switch 表达式
String describe(Object o) => switch (o) {
  int() when o > 0 => '正整数',      // 关系/when 守卫
  [1, ...] => '以1开头的列表',        // 列表模式
  {'name': var n} => '带name的map',  // Map 模式
  (int a, int b) => '记录 $a,$b',      // Record 模式
  String s => '字符串 $s',
  _ => '其他',                        // 通配
};

// if-case
if (json case {'user': String name}) { ... }

// 解构赋值
final (a, b) = ('x', 1);
```

### 3. Sealed Classes(密封类)

限制只能被同库中的指定子类继承,配合 switch 可实现**穷尽性检查**(漏分支编译报错),替代"运行时 if-else 判断状态"的最佳方案,Flutter 状态管理(如 bloc/freezed、Riverpod)广泛使用:

```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T value; Success(this.value); }
class Failure<T> extends Result<T> { final Object e; Failure(this.e); }

String log<T>(Result<T> r) => switch (r) {
  Success<T>() => 'ok',
  Failure<T>() => 'error',
}; // 不需要 default,编译器保证穷尽
```

### 4. Class Modifiers

`base` / `final` / `interface` / `sealed` / `mixin` / `abstract` 组合,精确控制类的继承能力:

- `base`:可被继承,不可被 implements。
- `interface`:只能被 implements,不能被继承。
- `final`:不能被继承或实现(可被构造)。
- `mixin class`:既是类又是 mixin。

### 5. 其他

- **通配符变量 `_`**:不需要的变量直接用 `_`,同名不冲突。
- **Dart 3.3+ `extension type`**:零成本包装。
- **Dart 3.5+ `dot-shorthands`**(实验→默认):`Int.new` 等成员访问。
- Switch 表达式里 `=>` 分支,告别 break。

---

## 十三、高频代码输出题

面试官常拿这些题现场考,务必每题都亲手跑过、能讲清楚。

### 1. 执行顺序(事件循环)⭐⭐⭐

```dart
void main() {
  print('1');
  Future(() => print('2'));
  Future.value().then((_) => print('3'));
  scheduleMicrotask(() => print('4'));
  print('5');
}
// 答案:1 5 3 4 2
// 解析:
// 1、5 是同步代码。
// Future.value() 创建时已完成,then 注册的回调立即进入【微任务】→ 3;
// scheduleMicrotask 主动入【微任务】→ 4(注册晚于 3,故排在 3 后);
// Future(() {...}) 的函数体进入【事件队列】→ 2,只能在微任务清空后执行。

```

> 讲清两点:① 已完成 Future 的 then 回调 = 微任务;② `Future(() {...})` 函数体 = 事件队列。

### 2. 循环 + async(经典陷阱)⭐⭐⭐

```dart
void main() {
  for (var i = 0; i < 3; i++) {
    Future(() => print(i));
  }
  print('a');
}
// 答案:a 0 1 2 —— 循环是同步的,Future 三个任务依次入事件队列
```

对比 闭包捕获版本:

```dart
final fns = [() => print(0), () => print(1)];
```

### 3. async/await 执行顺序 ⭐⭐⭐

```dart
Future<void> foo() async {
  print('foo start');
  await bar();
  print('foo end');   // 相当于 then 回调,进微任务
}

Future<void> bar() async {
  print('bar');
}

void main() {
  foo();
  print('main');
}
// 答案:foo start → bar → main → foo end
```

**规律**:遇到第一个 `await`,先把 await 的表达式求值;表达式完成后的后续代码成为"恢复任务"。await 一个已完成值 ⇒ 恢复走微任务。

### 4. const 与 identical ⭐⭐

```dart
print(identical(const [1, 2], const [1, 2])); // true
print(identical([1, 2], [1, 2]));             // false
print(identical('ab' 'c', 'abc'));            // true(字面量拼接编译期合并)
```

### 5. == 与 hashCode ⭐⭐

```dart
class P { final int id; const P(this.id); }
print(P(1) == P(1)); // false:未重写 ==,默认比较身份
// List/Set 中装未重写 == 的对象,contains 永远按身份比较 → 常见 bug
```

### 6. final List 可变 ⭐⭐

```dart
final list = [1, 2];
list.add(3);      // OK,final 锁引用不锁内容
const list2 = [1, 2];
// list2.add(3);   // 报错,const 集合深不可变
```

### 7. 类型提升失败 ⭐

```dart
class A { String? name;
  void f() {
    if (name != null) {
      print(name.length); // 编译错误:成员变量不提升
      // 正确:final n = name; if (n != null) n.length;
    }
  }
}
```

### 8. 级联返回对象 ⭐

```dart
class B { B m() { return this; } }
final b = B()
  ..m()
  ..m(); // 级联表达式整体返回原对象 B
```

### 9. mixin 线性化 ⭐

```dart
class A { void hello() => print('A'); }
mixin M1 { void hello() => print('M1'); }
mixin M2 { void hello() => print('M2'); }
class C extends A with M1, M2 {}
C().hello(); // 输出 M2 —— 从后往前找
```

### 10. 泛型运行时类型 ⭐(Android 面试官爱问)

```dart
final list = <String>['a'];
print(list is List<String>);  // true:Dart 泛型运行时保留(reified)
// 对照 Java:type erasure,运行时无法得知泛型实参
```

---

## 十四、对比类与开放性问题

### 1. Dart 和 Java 的主要区别?(给 Android 面试官准备的对比)

| 维度 | Java | Dart |
|---|---|---|
| 类型系统 | 静态强类型,空安全(部分) | 静态强类型 + Sound Null Safety |
| 泛型 | 类型擦除 | **运行时具体化** |
| 并发 | 多线程 + 锁 | 单线程事件循环 + Isolate 消息传递 |
| 继承 | 单继承 + interface | 单继承 + 隐式接口 + **Mixin** |
| 构造 | 可重载 | 不可重载,**命名构造** |
| 常量 | final 可变引用语义混杂 | `final`(运行时)/ `const`(编译期)明确分层 |
| 编译 | JVM 字节码 / AOT(ART) | JIT + AOT 双模式 |
| getter/setter | 约定 | 语言级 |
| 扩展方法 | 无(静态方法模拟) | 语言级 `extension` |
| 语法糖 | — | `?.` `??` `..` collection-if、字符串插值 |

### 2. Dart 和 Kotlin 的区别?

- 相似:空安全语法(`?`/`!!`→`!`)、data class ≈ record(有限)、扩展 ≈ extension、委托 ≈ mixin 部分、sealed。
- 差异:Kotlin 有真正的 interface + 默认实现、协程(结构化并发)vs Dart 的 Isolate、Kotlin 泛型使用处型变(`in/out`)vs Dart 协变靠运行时检查、Kotlin 编译到 JVM、Dart 双模式 JIT/AOT。

### 3. 为什么 Dart 不支持反射(在 Flutter 中)?

AOT 编译为机器码时,编译器做了 tree-shaking(删除未使用代码),运行时没有完整的类型元数据,`dart:mirrors` 无法支持。替代方案:**代码生成**(json_serializable、freezed、build_runner)和手动序列化。这是 Flutter 面试的常见陷阱题。

### 4. Dart 如何做 JSON 序列化?为什么不用反射?

1. `dart:convert` 的 `jsonDecode` 返回 `Map<String, dynamic>`,手动转换(小项目);
2. `json_serializable`/`freezed` 注解 + `build_runner` 生成代码(推荐,静态安全、无运行时反射、利于 tree-shaking);
3. 无法用反射,原因见上题。

### 5. 什么是 tree-shaking?为什么 Flutter 包体积能做小?

编译期从入口做可达性分析,删除不可达代码。const、extension、静态方法都可能被摇掉。由于 AOT + tree-shaking,未用到的库不会进产物。手写"反射调用方法"会让编译器认为代码不可达而误删(运行时 NoSuchMethodError)——所以代码要避免字符串驱动的隐式调用,或用注解保留。

### 6. Dart 中的延迟初始化有哪些方式?

- `late var x = expr`(首次访问才执行);
- `static final`(惰性 + 只初始化一次);
- `Lazy`(自实现 getter + nullable 后备字段):

```dart
Expensive? _cache;
Expensive get instance => _cache ??= Expensive();
```

### 7. dart:mirrors / dart:ffi 你了解吗?

- `dart:mirrors`:反射 API,仅 Dart VM/CLI 支持,Flutter(需要 AOT)不支持。
- **dart:ffi**:Dart 直接调用 C/C++ 接口(FFI),Flutter 性能敏感场景、复用已有 native 库(如音视频、加密)的方案;Android 开发者可类比 JNI,但调用成本远低于 JNI。

### 8. Dart 中如何实现单例?

```dart
class Singleton {
  Singleton._internal();
  static final Singleton _instance = Singleton._internal(); // 惰性初始化
  factory Singleton() => _instance;
}
// 或更简洁:
// static final Singleton instance = Singleton._internal();
```

要点:私有命名构造 + `static final`(Dart 静态变量天然惰性)或 `factory` 返回缓存实例。

### 9. 如何实现一个防抖(debounce)?(考察闭包 + Timer)

```dart
Function debounce(Function fn, {Duration d = const Duration(milliseconds: 300)}) {
  Timer? t;
  return () {
    t?.cancel();          // 闭包持有 t
    t = Timer(d, () => fn());
  };
}
```

### 10. pub 包管理和 pubspec.yaml 里 dependencies 有哪些写法?

- 版本约束:`^1.2.3`(兼容 1.x)、`>=1.2 <2.0`、精确版本。
- 来源:pub.dev(默认)、git(url + ref/path)、path(本地)、sdk(flutter、hosted)。
- `flutter pub get` 拉取并写入 `pubspec.lock`(锁版本,应提交;类似 Gradle 的 `gradle.lockfile` 或 version catalog)。
- Android 类比:build.gradle 的 implementation + 语义化版本。

### 11. Dart 的元数据/注解机制?

内置 `@deprecated`、`@override`、`@pragma('vm:...')`,自定义注解是常量构造的类:

```dart
class Todo { final String msg; const Todo(this.msg); }

@Todo('refactor')
void f() {}
```

注解本身只是常量元数据,要发挥作用需要代码生成器(build_runner 读注解生成代码)或 VM pragma。这是 json_serializable 等工具的原理。

### 12. 说说 Dart 中的类型协变/逆变?

- Dart 泛型参数**默认协变**:`List<Cat>` 可当 `List<Animal>` 用,运行时检查兜底(写入非 Cat 会抛 TypeError)。
- 没有 Kotlin/Java 的 `out/in` 声明处型变语法;函数类型有天然型变(返回协变、参数逆变语义上成立但编译器检查有限)。
- `covariant` 关键字用于参数协变覆写(见六-11)。

---

## 附:回答策略(给你的建议)

1. **主动对比 Java/Kotlin**:面试官看到你 Android 背景,一定从"你熟悉的语言"切入。每个概念都准备一句对比,如"Dart 泛型运行时可查,不像 Java 擦除;Dart mixin 线性化类似 Kotlin 接口默认实现的叠加,但规则更简单"。
2. **异步三连几乎必考**:事件循环、微任务 vs 事件队列、async/await 原理,加上一个代码输出题。建议把第十三节的题都自己敲一遍。
3. **Isolate 必准备**:为什么单线程也能并发、消息传递、compute,以及"IO 不卡 UI 是因为底层有线程池"这个容易忽略的点。
4. **空安全 + const 性能优化** 是 Flutter 实战向语言题的两大来源。
5. Dart 3 特性(records/patterns/sealed)是近两年新题源,能主动提到会显得知识新。

祝面试顺利!
