import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Native Bridge Performance Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Native Bridge Performance Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

typedef NativeMemset = Pointer<Void> Function(Pointer<Uint8>, Int32, Uint64);
typedef Memset = Pointer<Void> Function(Pointer<Uint8>, int, int);

Pointer<Uint8> Uint8ListToArray(Uint8List list) {
  final ptr = allocate<Uint8>(count: list.length);
  for (var i = 0; i < list.length; i++) {
    ptr[i] = list[i];
  }
  return ptr;
}

Uint8List arrayToUint8List(Pointer<Uint8> ptr, int length) {
  Uint8List list = new Uint8List(length);
  for (var i = 0; i < length; i++) {
    list[i] = ptr[i];
  }
  free(ptr);
  return list;
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel kChannel = const MethodChannel(
      'xyz.takeoverjp.example/flutter_linux_bridge_perf/method');
  static const kCount = 1000;
  int _counter = 0;
  DynamicLibrary _libc;
  Memset _memset;

  static int _usToAvgNs(int us) {
     return (us * (1000 / kCount)).toInt();
  }

  void _measureFfiMemset(int kb) {
    final byte = kb * 1024;
    Pointer<Uint8> ptr = allocate(count: byte);

    Stopwatch sw = new Stopwatch();
    for (int i = 0; i < kCount; i++) {
      sw.start();
      _memset(ptr, 1, byte);
      sw.stop();

      for (int idx in [0, byte~/2, byte - 1]) {
        assert(ptr[idx] == 1);
        ptr[idx] = 0;
      }
    }
    print('ffiMemset,$kb,${_usToAvgNs(sw.elapsedMicroseconds)}');

    free(ptr);
  }

  void _measureFfiMemsetWithListView(int kb) {
    final byte = kb * 1024;
    final Pointer<Uint8> ptr = allocate(count: byte);
    Uint8List list = ptr.asTypedList(byte);
    list.fillRange(0, byte, 2);

    Stopwatch sw = new Stopwatch();
    for (int i = 0; i < kCount; i++) {
      sw.start();
      _memset(ptr, 1, byte);
      sw.stop();

      for (int idx in [0, byte~/2, byte - 1]) {
        assert(list[idx] == 1);
      }
    }
    free(ptr);
    print('ffiMemsetWithListView,$kb,${_usToAvgNs(sw.elapsedMicroseconds)}');
  }

  void _measureFfiMemsetAndConvert(int kb) {
    final byte = kb * 1024;
    Uint8List list = new Uint8List(byte);
    list.fillRange(0, byte, 2);

    Stopwatch sw = new Stopwatch();
    for (int i = 0; i < kCount; i++) {
      sw.start();
      final ptr = Uint8ListToArray(list);
      _memset(ptr, 1, byte);
      final result = arrayToUint8List(ptr, byte);
      sw.stop();

      for (int idx in [0, byte~/2, byte - 1]) {
        assert(result[idx] == 1);
      }
    }
    print('ffiMemsetAndConvert,$kb,${_usToAvgNs(sw.elapsedMicroseconds)}');
  }

  void _measureMethodChannelMemset(int kb) async {
    final byte = kb * 1024;
    Uint8List list = new Uint8List(byte);
    list.fillRange(0, byte, 2);

    Stopwatch sw = new Stopwatch();
    for (int i = 0; i < kCount; i++) {
      sw.start();
      final result = await kChannel.invokeMethod('memset1', list);
      sw.stop();

      for (int idx in [0, byte~/2, byte - 1]) {
        assert(result[idx] == 1);
      }
    }
    print('MethodChannelMemset,$kb,${_usToAvgNs(sw.elapsedMicroseconds)}');
  }

  void _onClick() async {
    _libc = DynamicLibrary.open('libc.so.6');
    _memset = _libc
        .lookup<NativeFunction<NativeMemset>>('memset')
        .asFunction<Memset>();

    print("type,dataSize[KB],time[ns]");
    for (var kb = 1; kb <= 8192; kb *= 2) {
      _measureFfiMemset(kb);
      _measureFfiMemsetWithListView(kb);
      _measureFfiMemsetAndConvert(kb);
      await _measureMethodChannelMemset(kb);
    }
    print("done");

    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Performance Test Start',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onClick,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
