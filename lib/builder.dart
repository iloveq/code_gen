import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generator/router_generator.dart';
import 'src/generator/router_table_generator.dart';


Builder generateRouterParams(BuilderOptions options) =>
    LibraryBuilder(RouterGenerator(), generatedExtension:'.params.g.dart');

Builder generateRouterTable(BuilderOptions options)=>
    LibraryBuilder(RouterTableGenerator(), generatedExtension: '.table.dart');
