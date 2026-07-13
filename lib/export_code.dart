import 'dart:io';

void main() {
  var dir = Directory('lib');

  var outputFile = File('doctor_project_code.md');
  var output = StringBuffer();

  if (dir.existsSync()) {
    output.writeln('# KidCare Project Code\n');

    // جلب كل الملفات داخل مجلد lib
    var files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is File && file.path.endsWith('.dart')) {
        output.writeln('### File: ${file.path}');
        output.writeln('```dart');
        output.writeln(file.readAsStringSync());
        output.writeln('```\n');
      }
    }

    outputFile.writeAsStringSync(output.toString());
    print(
      '  The operation was successful! The my_project_code.md file was created ',
    );
  } else {
    print(' lib folder not found !');
  }
}
