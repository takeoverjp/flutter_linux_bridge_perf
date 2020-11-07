import 'dart:ffi';
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

Pointer<Uint8> intListToArray(List<int> list) {
  final ptr = allocate<Uint8>(count: list.length);
  for (var i = 0; i < list.length; i++) {
    ptr.elementAt(i).value = list[i];
  }
  return ptr;
}

List<int> arrayToIntList(Pointer<Uint8> ptr, int length) {
  List<int> list = [];
  for (var i = 0; i < length; i++) {
    list.add(ptr[i]);
  }
  free(ptr);
  return list;
}
class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel kChannel = const MethodChannel('xyz.takeoverjp.example/flutter_linux_bridge_perf/method');
  static const kCount = 1000;
  static const kBytes = [1000, 10000, 100000];
  int _counter = 0;
  DynamicLibrary _libc;
  Memset _memset;

  void _measureFfiMemset(int count, int byte) {
    Pointer<Uint8> ptr = allocate(count: byte);

    Stopwatch sw = new Stopwatch();
    sw.start();
    for (int i = 0; i < count; i++) {
      _memset(ptr, 1, byte);
    }
    sw.stop();
    print('ffi: ${byte}, ${sw.elapsedMicroseconds / count}[us]');

    free(ptr);
  }

  void _measureFfiMemsetAndConvert(int count, int byte) {
    List<int> list = new List(byte);
    list.fillRange(0, byte, 2);

    Stopwatch sw = new Stopwatch();
    sw.start();
    for (int i = 0; i < count; i++) {
      final ptr = intListToArray(list);
      _memset(ptr, 1, byte);
      arrayToIntList(ptr, byte);
    }
    sw.stop();
    print('ffi & covert: ${byte}, ${sw.elapsedMicroseconds / count}[us]');
  }

  void _measureMethodChannelMemset(int count, int byte) {
    List<int> list = new List(byte);
    list.fillRange(0, byte, 2);

    Stopwatch sw = new Stopwatch();
    sw.start();
    for (int i = 0; i < count; i++) {
      kChannel.invokeMethod('memset1', list);
    }
    sw.stop();
    print('MethodChannel: ${byte}, ${sw.elapsedMicroseconds / count}[us]');
  }

  void _onClick() {
    _libc = DynamicLibrary.open('libc.so.6');
    _memset =
      _libc.lookup<NativeFunction<NativeMemset>>('memset').asFunction<Memset>();

    for (var byte in kBytes) {
      _measureFfiMemset(kCount, byte);
//      _measureFfiMemsetAndConvert(kCount, byte);
      _measureMethodChannelMemset(kCount, byte);
    }

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
