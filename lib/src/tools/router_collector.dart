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
