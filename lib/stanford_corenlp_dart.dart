library stanford_corenlp_dart;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:observe/observe.dart';

class StanfordCoreNLP extends Object with ChangeNotifier {
  List _annotators;
  int _javaHeapSize;
  String _coreNlpPath;
  Map _coreNlpJars;
  String _coreNlpDirPath;
  String _inputText = ''; 
  @reflectable get inputText => _inputText;
  @reflectable set inputText(val) {
    _inputText = notifyPropertyChange(#inputText, _inputText, val);
  }
  String _outputText = ''; 
  @reflectable get outputText => _outputText;
  @reflectable set outputText(val) {
    _outputText = notifyPropertyChange(#outputText, _outputText, val);
  }
 
  StanfordCoreNLP(this._coreNlpPath, this._annotators, [this._javaHeapSize = 3]) {
    _coreNlpJars = new Map();
    Directory dir = new Directory(_coreNlpPath);
    _coreNlpDirPath = dir.path;
    if (dir.existsSync()) {
      List files = dir.listSync(recursive: false);
      files.forEach((file) {
        String path = file.path;
        if (path.contains(new RegExp(r'stanford-corenlp-\d.\d.\d.jar')))
          _coreNlpJars['corenlp'] = path;
        else if (path.contains(new RegExp(r'stanford-corenlp-\d.\d.\d-models.jar')))
          _coreNlpJars['models'] = path;
      });
    };
    
  }
  
  Future<bool> run() {
    Completer compl = new Completer();
    compl.complete(
    Process.start(
        'java',
        ['-cp',
         '${_coreNlpJars['corenlp']}:${_coreNlpJars['models']}:$_coreNlpDirPath/xom.jar:$_coreNlpDirPath/joda-time.jar',
         '-Xmx${_javaHeapSize}g',
         'edu.stanford.nlp.pipeline.StanfordCoreNLP',
         'edu.stanford.nlp.tagger.maxent.MaxentTagger',
         '-annotators',
         _annotators.join(',')
        ],
        runInShell: true).then((process) {
          process.stdout
          .transform(new Utf8Decoder())
              .listen((String line) => outputText += line);
          this.changes.listen((List<ChangeRecord> record) {
            if (new RegExp(r'inputText').hasMatch(record[0].toString())) {
              process.stdin.writeln(inputText);
            }
          });
        })
        );
    return compl.future;
  }
  
  StreamSubscription<String> process(String text) {
    inputText = text;
    return
    this.changes.where((List<ChangeRecord> record) => new RegExp(r'outputText"\) from: \w').hasMatch(record.join(',')))
      .map((e) => e.toString().replaceAllMapped(new RegExp(r'(^((.+\n)+\n to: ))|(.+$)', caseSensitive: false), (Match m) => ''))
        .listen((List<ChangeRecord> record) {
    });
  }
}



