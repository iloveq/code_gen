import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_gen/src/tools/router_collector.dart';
import 'package:source_gen/source_gen.dart';

import '../annotation/router_page.dart';

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
          if(element.toString().startsWith("@RouterArg")){
            Argument argument = Argument();
            argument.isRequired = element.computeConstantValue().getField("required").toBoolValue();
            argument.name = e.name;
            argument.type = e.toString().split(" ")[0];
            page.arguments.add(argument);
            print("arguments: ${argument.toString()}");
          }
        });
      }
      if(aptRouterPath == "/"||annotation.read("isIndex").boolValue){
        page.routerPath =  "/";
        page.name = className;
        collector.indexRouter["/"] = page;
      }else{
        page.name = className;
        page.routerPath = routerName;
        collector.routerMap[routerName] = page;
      }
    }
    return null;
  }

}
