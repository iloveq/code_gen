# code_gen
a apt tools provider some annotation to generate dart code ,like router make page jump simple

# example
flutter中无法使用反射做hook，通常使用Aop比较多，基于builder_runner(Dart代码生成文件库)的 [source_gen](https://github.com/dart-lang/source_gen) 可实现注解生成代码 类似 java Aop AbstractProcessor

### 目标：自动生成路由配置，页面带参跳转，参数获取
### [page_router项目地址:](https://github.com/iloveq/code_gen)
### 使用方法：
```
# pubspec.yaml 引入
dependencies:
  #  flutter 项目下 dependencies 引入 code_gen (使用 source_gen 编写的 aop lib)
  code_gen:
    git:
      url: git://github.com/iloveq/code_gen.git
      ref: main

dev_dependencies:
  #  flutter 项目下 dev_dependencies 引入 builder_runner
  build_runner: ^1.10.0
```
### 1:创建 app_router_table.dart  工厂模式引用生成的类(实现了模版方法configureRoutes),通过 build_runner 会生成文件 app_router_table.table.dart
```
import 'package:code_gen/router_gen.dart';
import 'package:flutter/cupertino.dart';
import 'app_router_table.table.dart'; // 生成的文件

@RouterTable()
abstract class AppRouterTable {

  factory AppRouterTable() = $AppRouterTable; // 生成的类

  Map<String, WidgetBuilder> configureRoutes();

}
```
### 2:MyApp 配置路由表
```
Widget _buildMaterialApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        primarySwatch: Colors.blue,
      ),
      routes: AppRouterTable().configureRoutes(),
      initialRoute: "/",
    );
  }
```
### 3:注解标记需要注册的Page和参数Arg
```
import '../config/app_router_table.table.dart'; // 引入生成文件
// 主页
@RouterPage(isIndex: true)
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);
@override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        child: Text("home page"),
        // 跳转（调用生成方法）
        onTap: ()=> context.navigator2TestPage(url: "from home page")
      ),
    );
  }
}
...
// testPage
import '../config/app_router_table.table.dart';
@RouterPage() // 标明页面 Page
class TestPage extends StatefulWidget{
  @RouterArg(required: true) // 标明参数 Arg
  final String url = "";

  TestPage({Key key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage>{
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        child: Text(context.getTestPageArguments().url), // 获取参数
        onTap: ()=> context.navigator2MinePage(num:2000),
      ),
    );
  }
}
...
```
### 4:使用 flutter packages pub run build_runner build 生成文件 app_router_table.table.dart：
```
export 'app_router_table.table.dart';
import 'app_router_table.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/pages/test_page.dart';
import 'package:flutter_app/pages/home_page.dart';
import 'package:flutter_app/pages/mine_page.dart';

class $AppRouterTable implements AppRouterTable {
  @override
  Map<String, WidgetBuilder> configureRoutes() {
    return <String, WidgetBuilder>{
      '/': (context) => HomePage(),
      'TestPage': (context) => TestPage(),
      'Mine': (context) => MinePage(),
    };
  }
}

// **************************************************************************
// TestPage

class TestPageArguments {
  final String url;

  TestPageArguments({@required this.url});
}

extension TestPageContext on BuildContext {
  void navigator2TestPage({@required String url}) {
    Navigator.pushNamed(this, "TestPage",
        arguments: TestPageArguments(url: url));
  }

  TestPageArguments getTestPageArguments() {
    return ModalRoute.of(this).settings.arguments;
  }
}

// **************************************************************************

// **************************************************************************
// MinePage

class MinePageArguments {
  final int num;

  MinePageArguments({this.num});
}

extension MinePageContext on BuildContext {
  void navigator2MinePage({int num}) {
    Navigator.pushNamed(this, "Mine", arguments: MinePageArguments(num: num));
  }

  MinePageArguments getMinePageArguments() {
    return ModalRoute.of(this).settings.arguments;
  }
}

// **************************************************************************
```
# 那么如何创建一个Aop 功能的 lib ，以下是通过 source_gen 做的一个Aop 工具 ：
### 我们先来看 page_router 的包结构：
```
├── README.md
├── build.yaml
├── lib
│   ├── builder.dart
│   ├── router_gen.dart
│   └── src
│       ├── annotation
│       │   ├── router_arg.dart
│       │   ├── router_page.dart
│       │   └── router_table.dart
│       ├── generator
│       │   ├── router_generator.dart
│       │   └── router_table_generator.dart
│       └── tools
│           └── router_collector.dart
├── pubspec.lock
└── pubspec.yaml
```
### 1: code_gen 文件夹下，创建 pubspec.yaml 文件 引入 builder_runner 和 source_gen 及 dart 配置，并运行 pub get
```
name: code_gen
description: auto generate router params
version: 0.0.1
author: haoran
homepage: 1549112908@qq.com
environment:
  sdk: ">=2.1.0 <3.0.0"
dependencies:
  analyzer: any
  build: any
  build_config: '>=0.3.0'
  source_gen: ^0.9.7
dev_dependencies:
  build_runner: ^1.10.0
```
### 2: 创建 build.yaml 配置注解生成器信息
```
targets:
  $default:
    builders:
       # code_gen 工程下的 router_gen_builder(builder 名字随意，和下面对应就可以)
      code_gen|router_gen_builder:
        options: { 'write': true }
        enabled: true
        generate_for:
          exclude: ['**.params.g.dart']
      code_gen|router_table_gen_builder:
        options: { 'write': true }
        enabled: true
        generate_for:
          exclude: ['**.table.dart']


builders:
  router_gen_builder:
    import: "package:code_gen/builder.dart" # builder.dart 文件位置
    builder_factories: ["generateRouterParams"] # 对应 build.dart 文件中的方法
    build_extensions: {".dart": ['.params.g.dart']} # 生成文件后缀名
    auto_apply: dependents
    build_to: source
    # runs_before 先于 router_table_gen_builder 执行
    runs_before: ['code_gen|router_table_gen_builder'] 
  router_table_gen_builder:
    import: "package:code_gen/builder.dart"
    builder_factories: ["generateRouterTable"]
    build_extensions: {".dart": ['.table.dart']}
    auto_apply: dependents
    build_to: source
```
### 3:看到上面创建了 build.dart 文件，这个是类似于 java Aop 的 resource/META-INF.services 配置 Processor，相当于生成器的入口
```
// build.dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generator/router_generator.dart';
import 'src/generator/router_table_generator.dart';

Builder generateRouterParams(BuilderOptions options) =>
    LibraryBuilder(RouterGenerator(), generatedExtension:'.params.g.dart');

Builder generateRouterTable(BuilderOptions options)=>
    LibraryBuilder(RouterTableGenerator(), generatedExtension: '.table.dart');
```
### 4： 定义注解，创建注解生成器
```
// 定义注解:
class RouterTable{
  const RouterTable();
}
class RouterPage {
  final bool isIndex;
  final String path;
  const RouterPage({this.path = "",this.isIndex = false});
}
class RouterArg {
  final bool required;
  const RouterArg({this.required = false});
}
// 创建注解生成器:
// 1 RouterGenerator
class RouterGenerator extends GeneratorForAnnotation<RouterPage> {
  static RouterCollector collector = RouterCollector();

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    print(element);
    if (element.kind == ElementKind.CLASS) {
      var importStr = "";
      if (buildStep.inputId.path.contains('lib/')) {
        importStr =
            "package:${buildStep.inputId.package}/${buildStep.inputId.path.replaceFirst('lib/', '')}";
      } else {
        importStr = "${buildStep.inputId.path}";
      }
      collector.importList.add(importStr);
      String className = element.name;
      String aptRouterPath = annotation.read("path").stringValue;
      String routerName = aptRouterPath != null && aptRouterPath.isNotEmpty
          ? aptRouterPath
          : className;
      var page = Page();
      page.arguments = [];
      for (FieldElement e in ((element as ClassElement).fields)) {
        List<ElementAnnotation> fieldAnnotationList = e.metadata;
        fieldAnnotationList.forEach((element) {
          if (element.toString().startsWith("@RouterArg")) {
            Argument argument = Argument();
            argument.isRequired = element
                .computeConstantValue()
                .getField("required")
                .toBoolValue();
            argument.name = e.name;
            print("arguments-field: ${e.toString()}");
            String type_ = e.toString().split(" ")[0];
            argument.type = type_.replaceAll("*", "");
            page.arguments.add(argument);
            print("arguments: ${argument.toString()}");
          }
        });
      }
      if (aptRouterPath == "/" || annotation.read("isIndex").boolValue) {
        page.routerPath = "/";
        page.name = className;
        collector.indexRouter["/"] = page;
      } else {
        page.name = className;
        page.routerPath = routerName;
        collector.routerMap[routerName] = page;
      }
    }
    return null;
  }
}
// 2RouterTableGenerator ：
class RouterTableGenerator extends GeneratorForAnnotation<RouterTable> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element.kind == ElementKind.CLASS) {
      String path = buildStep.inputId.path; // lib/xxx.dart
      String fileName = Path.basename(path); // xxx.dart
      String className = element.name;
      return generateRouterTable(fileName, className);
    }
    return "class TestTable{}";
  }

  String generateRouterTable(String fileName, String simpleClassName) {
    String export = fileName.split(".")[0] + ".table." + fileName.split(".")[1];
    String imports = "";
    String routerMap = "";
    var extensions = "";
    for (String import in RouterGenerator.collector.importList) {
      imports = imports + "import '" + import + "';\n";
    }
    RouterGenerator.collector.routerMap.forEach((key, value) {
      routerMap = routerMap + "'${key}':( context ) => ${value.name}(),";
      extensions = extensions + _genArgumentAndExtension(value);
    });

    return """
export '${export}';
import '${fileName}';
import 'package:flutter/cupertino.dart';
${imports}

class \$${simpleClassName} implements ${simpleClassName}{    

  @override
  Map<String, WidgetBuilder> configureRoutes() {
    return <String,WidgetBuilder>{
      '/': ( context) => ${RouterGenerator.collector.indexRouter['/'].name}(),
      ${routerMap}
    };
  }  
}

${extensions}

""";
  }
}

String _genArgumentAndExtension(Page page) {
  var fields = "";
  var argument = "";
  var extension = "";
  var constructorParams = ""; // this.a,this.b
  var functionParams = ""; // String a,String b
  var selectedConstructorParams = ""; // a:a, b:b
  if (page.arguments != null && page.arguments.isNotEmpty) {
    var size = page.arguments.length;
    for (int i = 0; i <= size - 1; i++) {
      fields = fields +
          "final " +
          page.arguments[i].type +
          " " +
          page.arguments[i].name +
          ";\n";
      constructorParams = constructorParams +
          (page.arguments[i].isRequired?"@required ":"")+
          "this." +
          page.arguments[i].name +
          (size == 1 || i == size - 1 ? "" : ",");
      functionParams = functionParams +
          (page.arguments[i].isRequired?"@required ":"")+
          page.arguments[i].type +
          " " +
          page.arguments[i].name +
          (size == 1 || i == size - 1 ? "" : ",");
      selectedConstructorParams = selectedConstructorParams +
          page.arguments[i].name +
          " : " +
          page.arguments[i].name +
          (size == 1 || i == size - 1 ? "" : ",");
    }
  }
  var explainName = "${page.name}";
  argument = _genArgument(page, fields, constructorParams);
  extension = _genExtension(page, functionParams, selectedConstructorParams);
  return """
// **************************************************************************   
// ${explainName}

$argument

$extension

// **************************************************************************  

""";
}

String _genExtension(
    Page page, String functionParams, String selectedConstructorParams) {
  if (page.arguments == null || page.arguments.isEmpty) {
    return """
extension ${page.name}Context on BuildContext{
  void navigator2${page.name}(){
    Navigator.pushNamed(this, "${page.routerPath}");
  }
}    
""";
  } else {
    return """
extension ${page.name}Context on BuildContext{
  void navigator2${page.name}(
      {${functionParams}}){
    Navigator.pushNamed(this, "${page.routerPath}",
        arguments:${page.name}Arguments(${selectedConstructorParams})
    );
  }
  ${page.name}Arguments get${page.name}Arguments(){
    return ModalRoute.of(this).settings.arguments;
  }
}    
""";
  }
}

String _genArgument(Page page, String fields, String constructorParams) {
  if (page.arguments == null || page.arguments.isEmpty) {
    return "";
  }
  return """
class ${page.name}Arguments{
    ${fields}
    ${page.name}Arguments({${constructorParams}}); 
}  
""";
}
```
### tools : 定义一些数据结构 Page/Arg ，存储 router_gen_builder 解析带 @RouterPage 标记带类信息的结果,用于之后执行 router_table_gen_builder 解析 @RouterTable 生成 .table.dart 类
```
class RouterCollector<T> {
  List<String> importList = <String>[];
  Map<String, Page> routerMap = <String, Page>{};
  Map<String, Page> indexRouter = <String, Page>{};
}

class Page {
  String routerPath;
  String name;
  List<Argument> arguments;
  @override
  String toString() {
    return "{ routerPath:${this.routerPath},name:${this.name},arguments:${this.arguments.toString()}}";
  }
}

class Argument {
  String name;
  String type;
  bool isRequired;

  @override
  String toString() {
    return "{ name:${this.name},type:${this.type},isRequired:${this.isRequired}}";
  }
}
```

# 感谢:)





