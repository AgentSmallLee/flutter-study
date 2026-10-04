# Flutter 混淆规则
# 面试讲解点：接入 Flutter 模块时，混淆配置要注意保留 Flutter 相关的类
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
