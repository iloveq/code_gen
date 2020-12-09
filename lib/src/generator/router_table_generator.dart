import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_gen/router_gen.dart';
import 'package:code_gen/src/generator/router_generator.dart';
import 'package:code_gen/src/tools/router_collector.dart';
import 'package:path/path.dart' as Path;
import 'package:source_gen/source_gen.dart';

class RouterTableGenerator extends GeneratorForAnnotation<RouterTable> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element.kind == ElementKind.CLASS) {
      String path = buildStep.inputId.path; // lib/xxx.dart
      String relatedFileName = Path.basename(path); // xxx.dart
      String relatedClassName = element.name;
      return generateRouterTable(relatedFileName, relatedClassName);
    }
    return "class TestTable{}";
  }

  String generateRouterTable(String relatedFileName, String relatedClassName) {
    String export = relatedFileName.split(".")[0] +
        ".table." +
        relatedClassName.split(".")[1];
    String imports = "";
    String routerMap = "";
    var ArgsAndNavigatorExtension = "";
    for (String import in RouterGenerator.collector.importList) {
      imports = imports + "import '" + import + "';\n";
    }
    RouterGenerator.collector.routerMap.forEach((key, value) {
      routerMap = routerMap + "'${key}':( context ) => ${value.name}(),";
      ArgsAndNavigatorExtension =
          ArgsAndNavigatorExtension + _genArgsAndNavigatorExtension(value);
    });

    return """
export '${export}';
import '${relatedFileName}';
import 'package:flutter/cupertino.dart';
${imports}

class \$${relatedClassName} implements ${relatedClassName}{    

  @override
  Map<String, WidgetBuilder> configureRoutes() {
    return <String,WidgetBuilder>{
      '/': ( context) => ${RouterGenerator.collector.indexRouter['/'].name}(),
      ${routerMap}
    };
  }  
}

${ArgsAndNavigatorExtension}

""";
  }
}

String _genArgsAndNavigatorExtension(Page page) {
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
          (page.arguments[i].isRequired ? "@required " : "") +
          "this." +
          page.arguments[i].name +
          (size == 1 || i == size - 1 ? "" : ",");
      functionParams = functionParams +
          (page.arguments[i].isRequired ? "@required " : "") +
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
  extension =
      _genNavigatorExtension(page, functionParams, selectedConstructorParams);
  return """
// **************************************************************************   
// ${explainName}

$argument

$extension

// **************************************************************************  

""";
}

String _genNavigatorExtension(
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
